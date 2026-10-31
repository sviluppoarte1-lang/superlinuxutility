import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/tray_task_manager_dialog.dart';
import 'screens/clipboard_history_dialog.dart';
import 'screens/onboarding_screen.dart';
import 'screens/password_setup_screen.dart';

import 'services/ocs_url_service.dart';
import 'services/system_detector.dart';
import 'services/font_service.dart';
import 'services/single_instance_service.dart';
import 'services/tray_service.dart';
import 'services/dependency_check_service.dart';
import 'services/window_close_to_tray.dart';
import 'services/app_memory_maintenance.dart';
import 'utils/scrollbar_theme.dart';
import 'package:window_manager/window_manager.dart';

/// ─── Diagnosi di avvio ──────────────────────────────────────────────────────
/// In release `debugPrint` e' inaffidabile e le eccezioni native (segfault di
/// GTK/appindicator) non arrivano mai a Dart: ogni passaggio critico viene
/// tracciato su stdout E su file con flush. Se l'AppImage muore durante
/// l'avvio, l'ultima riga del file indica dove.
const String _kDiagLogFile = '/tmp/slu-startup.log';

void _diag(String message) {
  final line = '${DateTime.now().toIso8601String()} [pid $pid] $message';
  try {
    stdout.writeln('[SLU] $line');
  } catch (_) {}
  try {
    final f = File(_kDiagLogFile);
    if (f.existsSync() && f.lengthSync() > 262144) {
      f.writeAsStringSync('--- log oltre 256KB, azzerato ---\n');
    }
    f.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
  } catch (_) {}
}

/// Cattura le eccezioni Dart non gestite (in release finirebbero solo su
/// stderr, spesso invisibili con un doppio clic sull'AppImage).
void _installErrorLogging() {
  ui.PlatformDispatcher.instance.onError = (error, stack) {
    _diag('FATAL non gestita: $error\n$stack');
    return false; // stesso comportamento di default, ma con traccia su file
  };
  FlutterError.onError = (details) {
    _diag('FlutterError: ${details.exception}\n${details.stack}');
    FlutterError.presentError(details);
  };
}

/// Contesto di esecuzione utile per diagnosare crash su distro diverse
/// (Fedora/Wayland/AppImage): variabili XDG + /etc/os-release.
void _diagEnvironment() {
  const keys = [
    'APPDIR',
    'APPIMAGE',
    'SUPER_LINUX_UTILITY_MODE',
    'XDG_SESSION_TYPE',
    'WAYLAND_DISPLAY',
    'DISPLAY',
    'XDG_CURRENT_DESKTOP',
    'DESKTOP_SESSION',
    'GDK_BACKEND',
  ];
  final env = Platform.environment;
  final envDesc = keys.map((k) => '$k=${env[k] ?? '-'}').join(' ');
  _diag('env: $envDesc');
  _diag('exe=${Platform.resolvedExecutable} | ${Platform.operatingSystemVersion}');
  try {
    final osRelease = File('/etc/os-release');
    if (osRelease.existsSync()) {
      for (final l in osRelease.readAsLinesSync()) {
        if (l.startsWith('PRETTY_NAME=') || l.startsWith('VERSION_ID=')) {
          _diag('os-release $l');
        }
      }
    }
  } catch (e) {
    _diag('os-release non leggibile: $e');
  }
}


/// Rilascia il lock anche se il lifecycle `detached` non viene notificato (es. terminazione da WM).
void _registerSingleInstanceShutdownHooks() {
  if (!Platform.isLinux) return;
  try {
    ProcessSignal.sigterm.watch().listen((_) {
      releaseSingleInstanceLock();
    });
    ProcessSignal.sigint.watch().listen((_) {
      releaseSingleInstanceLock();
    });
  } catch (_) {}
}

/// Mostra la finestra principale se a livello C++ non è stata mai mappata
/// (avvio ridotto a icona senza tray pronto, o seconda istanza già in esecuzione).
/// Primo tentativo immediato + retry al primo frame: il plugin window_manager
/// potrebbe non essere ancora pronto subito dopo l'avvio.
Future<void> ensureWindowShown() async {
  _diag('ensureWindowShown: richiesta (trayInitialized=${TrayService.isInitialized})');
  Future<void> show(String phase) async {
    try {
      await windowManager.show();
      await windowManager.focus();
      _diag('ensureWindowShown[$phase]: show+focus OK');
    } catch (e) {
      _diag('ensureWindowShown[$phase]: show/focus fallito: $e');
    }
  }

  await show('immediato');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    show('primo-frame');
  });
}

void main() async {
  _installErrorLogging();
  _diag('=== Super Linux Utility: avvio ===');
  _diagEnvironment();
  WidgetsFlutterBinding.ensureInitialized();
  // Limita cache immagini decodificate (default Flutter molto alto → crescita RSS nel tempo).
  PaintingBinding.instance.imageCache.maximumSize = 40;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;

  // Modalità standalone: lancia solo la utility richiesta senza la finestra principale.
  final standaloneMode = Platform.environment['SUPER_LINUX_UTILITY_MODE'];
  if (standaloneMode == 'task-manager' ||
      standaloneMode == 'check-updates' ||
      standaloneMode == 'clipboard') {
    await _runStandalone(standaloneMode!);
    return;
  }

  if (Platform.isLinux) {
    try {
      await windowManager.ensureInitialized();
      // Icona finestra per dock/taskbar (assets/icons/icon.png del bundle).
      // Prova più percorsi: bundle standard, installazioni .deb, run sorgente.
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidates = <String>[
          '$exeDir/data/flutter_assets/assets/icons/icon.png',
          '/usr/share/super-linux-utility/data/flutter_assets/assets/icons/icon.png',
          '/usr/share/super-linux-utility-advanced/data/flutter_assets/assets/icons/icon.png',
          '/usr/share/super-linux-utility-personal/data/flutter_assets/assets/icons/icon.png',
          'assets/icons/icon.png',
        ];
        String? used;
        for (final p in candidates) {
          try {
            if (await File(p).exists()) {
              used = p;
              break;
            }
          } catch (_) {}
        }
        if (used != null) {
          await windowManager.setIcon(used);
          _diag('icona finestra impostata da $used');
        } else {
          _diag('icona finestra NON trovata '
              '(${candidates.length} percorsi provati, primo: ${candidates.first})');
        }
      } catch (e) {
        _diag('setIcon fallita: $e');
      }
    } catch (e) {
      _diag('windowManager.ensureInitialized/setIcon fallito: $e');
    }
  }

  final singleInstance = await isSingleInstance();
  _diag('singleInstance=$singleInstance');
  if (!singleInstance) {
    _diag('seconda istanza: niente tray, solo schermata "gia in esecuzione"');
    runApp(const _AlreadyRunningApp());
    return;
  }

  if (Platform.isLinux) {
    _registerSingleInstanceShutdownHooks();
    final prefs = await SharedPreferences.getInstance();
    final trayEnabled = prefs.getBool(TrayService.prefKeySystemTrayEnabled) ?? true;
    final skipTrayEnv = Platform.environment['SUPER_LINUX_UTILITY_NO_TRAY'] == '1' ||
        Platform.environment['SUPER_LINUX_UTILITY_NO_TRAY'] == 'true';
    // ATTENZIONE: in passato Fedora veniva saltata del tutto (_isFedora) per
    // segfault storici con appindicator. Ora la guardia è la rilevazione reale
    // delle librerie (isSystemTraySupported, fixata: prima era "sempre true"):
    //  - AppImage su Fedora → librerie bundled → supportata → init funziona;
    //  - Fedora nativo (no ayatana) → non supportata → si salta l'init SENZA
    //    tentativi crashogeni e SENZA installazioni silenziose all'avvio
    //    (si installa solo dai pulsanti delle Impostazioni).
    if (trayEnabled && !skipTrayEnv) {
      final supported = await DependencyCheckService.isSystemTraySupported();
      _diag('tray: isSystemTraySupported=$supported');
      if (supported) {
        try {
          await TrayService.init();
          _diag('tray: init terminato (isInitialized=${TrayService.isInitialized})');
        } catch (e, st) {
          _diag('tray: init ECCEZIONE $e\n$st');
        }
        if (!TrayService.isInitialized) {
          _diag('tray: init NON riuscito -> lastError=${TrayService.lastError ?? '(nullo)'}');
        }
      } else {
        _diag('tray: librerie appindicator assenti -> init saltato');
      }
    } else {
      _diag('tray: disabilitato (trayEnabled=$trayEnabled, skipTrayEnv=$skipTrayEnv)');
    }
    // Avvio ridotto a icona: la finestra non è mai stata mappata a livello C++
    // (my_application.cc). Se il tray NON è pronto l'app resterebbe invisibile:
    // in quel caso la finestra va mostrata qui (nessun flash: C++ non l'ha
    // mai mostrata, quindi non c'è nulla da nascondere).
    final startMinimized =
        prefs.getBool(TrayService.prefKeyStartMinimized) ?? false;
    _diag('startMinimized=$startMinimized trayInitialized=${TrayService.isInitialized}');
    if (startMinimized && !TrayService.isInitialized) {
      await ensureWindowShown();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => initWindowCloseToTray());
  }

  _diag('avvio completato: runApp(MyApp)');
  runApp(const MyApp());
}

class _AlreadyRunningApp extends StatefulWidget {
  const _AlreadyRunningApp();

  @override
  State<_AlreadyRunningApp> createState() => _AlreadyRunningAppState();
}

class _AlreadyRunningAppState extends State<_AlreadyRunningApp> {
  @override
  void initState() {
    super.initState();
    if (Platform.isLinux) {
      // Con avvio ridotto a icona la finestra della seconda istanza non viene
      // mappata a livello C++: va mostrata esplicitamente, altrimenti il
      // messaggio "applicazione già in esecuzione" resterebbe invisibile.
      _diag('seconda istanza (_AlreadyRunningApp): mostra la finestra');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensureWindowShown();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Linux Utility',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', ''),
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
        Locale('de', ''),
        Locale('pt', ''),
      ],
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 24),
                    Text(
                      _getAlreadyRunningMessage(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () => SystemNavigator.pop(),
                      child: Text(AppLocalizations.of(context)!.close),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _getAlreadyRunningMessage(BuildContext context) {
    try {
      return AppLocalizations.of(context)!.appAlreadyRunning;
    } catch (_) {
      return 'L\'applicazione è già in esecuzione.';
    }
  }
}

/// Lancia una finestra standalone per una utility (task manager, check updates,
/// cronologia appunti). Il processo è separato dalla finestra principale e
/// mostra solo la schermata richiesta.
Future<void> _runStandalone(String mode) async {
  _diag('modalita standalone: $mode');
  final isTaskManager = mode == 'task-manager';
  final isClipboard = mode == 'clipboard';
  final prefs = await SharedPreferences.getInstance();

  // Legge preferenza lingua (serve anche per il titolo finestra)
  final localeStr = prefs.getString('locale');
  Locale? locale;
  if (localeStr != null && localeStr.isNotEmpty) {
    locale = Locale(localeStr);
  }

  final title = _standaloneTitle(mode, localeStr);
  // Dimensioni INIZIALI (poi la _StandaloneDialogSizer rimpicciolisce la
  // finestra sul contenuto reale della dialog, evitando fasce vuote).
  final size = isTaskManager
      ? const Size(600, 600)
      : isClipboard
          ? const Size(688, 608)
          : const Size(560, 420);

  // Legge preferenza tema (chiave 'theme_mode' come il resto dell'app;
  // 'themeMode' è la vecchia chiave, mantenuta come fallback)
  final themeModeStr = prefs.getString('theme_mode') ?? prefs.getString('themeMode') ?? 'system';
  final themeMode = themeModeStr == 'dark'
      ? ThemeMode.dark
      : themeModeStr == 'light'
          ? ThemeMode.light
          : ThemeMode.system;

  // Configura finestra
  if (Platform.isLinux) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.waitUntilReadyToShow(
        WindowOptions(size: size),
        () async {
          await windowManager.setTitle('Super Linux Utility - $title');
          await windowManager.center();
          await windowManager.show();
          await windowManager.focus();
        },
      );
    } catch (_) {}
  }

  runApp(_StandaloneApp(
    themeMode: themeMode,
    locale: locale,
    mode: mode,
  ));
}

/// Titolo della finestra standalone nella lingua dell'utente.
/// Se la preferenza non è ancora salvata usa la lingua di sistema,
/// con fallback finale sull'italiano (lingua predefinita dell'app).
String _standaloneTitle(String mode, String? localeStr) {
  final sysLang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  final lang = (localeStr ?? sysLang).split('_').first.toLowerCase();
  const titles = <String, Map<String, String>>{
    'task-manager': {
      'it': 'Processi',
      'en': 'Processes',
      'fr': 'Processus',
      'es': 'Procesos',
      'de': 'Prozesse',
      'pt': 'Processos',
    },
    'check-updates': {
      'it': 'Aggiornamenti',
      'en': 'Updates',
      'fr': 'Mises à jour',
      'es': 'Actualizaciones',
      'de': 'Aktualisierungen',
      'pt': 'Atualizações',
    },
    'clipboard': {
      'it': 'Appunti',
      'en': 'Clipboard',
      'fr': 'Presse-papiers',
      'es': 'Portapapeles',
      'de': 'Zwischenablage',
      'pt': 'Área de transferência',
    },
  };
  return titles[mode]?[lang] ?? titles[mode]?['it'] ?? mode;
}

class _StandaloneApp extends StatelessWidget {
  final ThemeMode themeMode;
  final Locale? locale;
  final String mode;

  const _StandaloneApp({
    required this.themeMode,
    this.locale,
    required this.mode,
  });

  /// Tema delle finestre standalone (dialog dal tray). Lo sfondo dello
  /// Scaffold e il colore delle dialog sono lo STESSO colore (la card M3):
  /// la finestra non decorata è quindi un'unica card senza margini di colore
  /// diverso né sfondo nero attorno alla dialog.
  static ThemeData _standaloneTheme(Brightness brightness) {
    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final card = base.colorScheme.surfaceContainerHigh;
    return base.copyWith(
      scrollbarTheme: buildAppScrollbarTheme(brightness),
      scaffoldBackgroundColor: card,
      // Elevazione 0: niente ombra/elevazione attorno alla dialog, così la
      // finestra (senza decorazioni) è UNA card uniforme senza contorni.
      // insetPadding 0: la card occupa TUTTA la finestra (nessuna fascia
      // vuota ai lati); la finestra viene poi ridimensionata sul contenuto
      // dalla _StandaloneDialogSizer.
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Linux Utility',
      debugShowCheckedModeBanner: false,
      theme: _standaloneTheme(Brightness.light),
      darkTheme: _standaloneTheme(Brightness.dark),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', ''),
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
        Locale('de', ''),
        Locale('pt', ''),
      ],
      home: _StandaloneScreen(mode: mode),
    );
  }
}

/// Channel nativo (linux/runner/my_application.cc) per spostare con il
/// mouse le finestre standalone non decorate: `gtk_window_begin_move_drag`
/// con GDK_CURRENT_TIME, piu' affidabile del startDragging del plugin
/// window_manager su X11.
const MethodChannel _windowDragChannel =
    MethodChannel('com.superlinux.utility/window');

class _StandaloneScreen extends StatefulWidget {
  final String mode;
  const _StandaloneScreen({required this.mode});
  @override
  State<_StandaloneScreen> createState() => _StandaloneScreenState();
}

class _StandaloneScreenState extends State<_StandaloneScreen> {
  /// Puntatore globale a inizio trascinamento (per i delta del drag).
  Offset _dragOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dialog = widget.mode == 'task-manager'
          ? const TrayTaskManagerDialog()
          : widget.mode == 'clipboard'
              ? const ClipboardHistoryDialog()
              : const TrayCheckUpdatesDialog();
      // Le finestre standalone non hanno decorazioni/titlebar: l'unico modo
      // di spostarle e' trascinare con il mouse da un'area non interattiva
      // (header, sfondo, padding della card). I figli interattivi (liste,
      // bottoni, campi) entrano per primi nel gesture arena e vincono i
      // loro gesti: scroll e click restano invariati. startDragging() del
      // plugin window_manager chiama gtk_window_begin_move_drag (l'app gira
      // su X11: backend forzato in linux/runner/main.cc).
      // HitTestBehavior.opaque: il detector partecipa ai hit test anche sulle
      // aree di solo testo (header); i figli restano hit-testati per primi e
      // vincono comunque i loro gesti (scroll, click, selezione testo).
      // HitTestBehavior.opaque: il detector partecipa ai hit test anche sulle
      // aree di solo testo (header); i figli restano hit-testati per primi e
      // vincono comunque i loro gesti (scroll, click, selezione testo).
      // Il drag va al channel nativo (my_application.cc): il plugin
      // window_manager usa un timestamp non valido su X11 e mutter ignorava
      // la richiesta di move.
      final draggableDialog = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) {
          _dragOrigin = d.globalPosition;
          _windowDragChannel.invokeMethod('startDragging');
        },
        onPanUpdate: (d) {
          // Delta cumulati dal punto di inizio: il lato nativo prova prima il
          // move-grab del WM e, se la finestra non segue, muove la finestra
          // direttamente (fallback).
          _windowDragChannel.invokeMethod('dragMove', [
            d.globalPosition.dx - _dragOrigin.dx,
            d.globalPosition.dy - _dragOrigin.dy,
          ]);
        },
        child: dialog,
      );
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        // Barriera trasparente: il default (black54) scuriva tutto lo sfondo
        // della finestra standalone facendolo sembrare nero.
        barrierColor: Colors.transparent,
        // La sizer adatta la finestra alla card: niente spazio inutilizzato.
        // NB: la clipboard ha una ListView con figli flessibili (gli intrinsechi
        // ne ignorano l'altezza → restringerebbe la finestra a soli ~150px):
        // per quella modalità la finestra resta alla dimensione progettata.
        builder: (_) => widget.mode == 'clipboard'
            ? draggableDialog
            : _StandaloneDialogSizer(
                mode: widget.mode, child: draggableDialog),
      ).then((_) {
        if (mounted) SystemNavigator.pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Adatta la dimensione della finestra standalone (non decorata) alla card
/// della dialog: senza questo passaggio la finestra resta alla dimensione
/// iniziale e restano ampie fasce vuote ai lati (spazio inutile).
/// Controlla la size reale della card ogni 600ms e ridimensiona la finestra
/// (max 12 volte, con tolleranza di 4px per evitare micro-correzioni).
class _StandaloneDialogSizer extends StatefulWidget {
  final String mode;
  final Widget child;
  const _StandaloneDialogSizer({required this.mode, required this.child});

  @override
  State<_StandaloneDialogSizer> createState() => _StandaloneDialogSizerState();
}

class _StandaloneDialogSizerState extends State<_StandaloneDialogSizer> {
  final GlobalKey _cardKey = GlobalKey();
  Timer? _timer;
  bool _busy = false;
  int _resizes = 0;
  static const int _maxResizes = 12;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) => _sync());
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  Future<void> _sync() async {
    if (!mounted || _busy || _resizes >= _maxResizes) return;
    final ro = _cardKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;
    // La misurazione va fatta sugli INTRINSECHI: il primo RenderObject della
    // dialog è un Align che si espande a TUTTA la finestra (il card è il suo
    // figlio, centrato), quindi la size di layout darebbe la finestra stessa.
    // Gli intrinsechi delegano al contenuto reale (testo + padding della
    // dialog compresi), ottenendo la dimensione "huggata" della card.
    double w;
    double h;
    try {
      w = ro.getMaxIntrinsicWidth(double.infinity);
      h = ro.getMaxIntrinsicHeight(w);
    } catch (e) {
      _diag('sizer: intrinsechi non calcolabili: $e');
      return;
    }
    if (!w.isFinite || !h.isFinite || w < 100 || h < 60) return;
    // Clamp allo schermo: mai una finestra più grande del display. La
    // dimensione va presa dalla display fisica (PlatformDispatcher), NON da
    // View.of(context): quella è la view della finestra standalone e al suo
    // interno il clamp restringerebbe la finestra a ogni tick (loop di
    // rimpicciolimento fino a 0). displays[0] è la display primaria.
    final displays = ui.PlatformDispatcher.instance.displays;
    double sw = 1920, sh = 1080;
    if (displays.isNotEmpty) {
      final dpr = ui.PlatformDispatcher.instance.views.isNotEmpty
          ? ui.PlatformDispatcher.instance.views.first.devicePixelRatio
          : 1.0;
      sw = displays.first.size.width / dpr;
      sh = displays.first.size.height / dpr;
    }
    final target = Size(
      math.min(w, sw - 80),
      math.min(h, sh - 80),
    );
    _busy = true;
    try {
      // Confronto con la dimensione REALE della finestra: se un setSize non
      // viene applicato dal WM il prossimo tick riprova (niente assunzioni).
      final current = await windowManager.getSize();
      if ((current.width - target.width).abs() < 4 &&
          (current.height - target.height).abs() < 4) {
        return;
      }
      _resizes++;
      _diag('sizer: intrinsechi=${w.toStringAsFixed(0)}x${h.toStringAsFixed(0)} '
          'finestra=${current.width.toStringAsFixed(0)}x${current.height.toStringAsFixed(0)} '
          '-> target=${target.width.toStringAsFixed(0)}x${target.height.toStringAsFixed(0)}');
      await windowManager.setSize(target, animate: false);
      final after = await windowManager.getSize();
      _diag('sizer dopo setSize: ${after.width.toStringAsFixed(0)}x'
          '${after.height.toStringAsFixed(0)} (resizes=$_resizes)');
      await windowManager.center();
    } catch (e) {
      _diag('sizer setSize fallito: $e');
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _CardMeasurer hugga il figlio e ne misura la size REALE: il primo
    // RenderObject di una Dialog è un Align non-posizionato che si espande a
    // tutta la finestra, quindi senza questo wrapper la misurazione restituiva
    // la finestra stessa e il resize non partiva mai.
    return _CardMeasurer(key: _cardKey, child: widget.child);
  }
}

/// RenderBox che si dimensiona come il figlio (hug) e ne espone la size:
/// serve a misurare la card reale della dialog dentro la finestra standalone.
class _CardMeasurer extends SingleChildRenderObjectWidget {
  const _CardMeasurer({super.key, required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCardMeasurer();
}

class _RenderCardMeasurer extends RenderShiftedBox {
  _RenderCardMeasurer() : super(null);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(child.size);
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  String? _fontFamily;
  double _fontSize = 14.0;
  Timer? _memoryMaintenanceTimer;
  Timer? _autoRestartTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadThemeMode();
    _loadLocale();
    _loadFontSettings();
    _memoryMaintenanceTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => AppMemoryMaintenance.requestTrim(),
    );
    _autoRestartTimer = Timer.periodic(
      const Duration(minutes: 90),
      (_) => _performAutoRestart(),
    );
  }

  @override
  void dispose() {
    _memoryMaintenanceTimer?.cancel();
    _autoRestartTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Chiude e riapre l'app per liberare memoria accumulata.
  Future<void> _performAutoRestart() async {
    _diag('auto-restart periodico (90 min): rilascio tray/lock e riavvio');
    _memoryMaintenanceTimer?.cancel();
    _autoRestartTimer?.cancel();
    try {
      // Nascondi la finestra PRIMA di tutto: quando il tray viene distrutto,
      // il window manager potrebbe rendere la finestra visibile per un istante.
      try {
        await windowManager.hide();
      } catch (_) {}
      await releaseSingleInstanceLock();
      if (TrayService.isInitialized) {
        TrayService.destroy();
      }
      await Process.start(Platform.resolvedExecutable, []);
    } catch (_) {}
    await SystemNavigator.pop();
  }

  @override
  void didHaveMemoryPressure() {
    AppMemoryMaintenance.requestTrim();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      releaseSingleInstanceLock();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      AppMemoryMaintenance.requestTrim();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Linux Utility',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', ''),
        Locale('en', ''),
        Locale('fr', ''),
        Locale('es', ''),
        Locale('de', ''),
        Locale('pt', ''),
      ],
      locale: _locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.light,
        ).copyWith(
          inversePrimary: const Color(0xFFE8E8E8),
          surfaceContainerHighest: const Color(0xFFECECEC),
          surfaceContainerHigh: const Color(0xFFF2F2F2),
          surfaceContainerLow: const Color(0xFFF8F8F8),
          surfaceContainerLowest: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        scrollbarTheme: buildAppScrollbarTheme(Brightness.light),
        fontFamily: _fontFamily,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: _fontSize * 2.0, fontFamily: _fontFamily),
          displayMedium: TextStyle(fontSize: _fontSize * 1.75, fontFamily: _fontFamily),
          displaySmall: TextStyle(fontSize: _fontSize * 1.5, fontFamily: _fontFamily),
          headlineLarge: TextStyle(fontSize: _fontSize * 1.5, fontFamily: _fontFamily),
          headlineMedium: TextStyle(fontSize: _fontSize * 1.25, fontFamily: _fontFamily),
          headlineSmall: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          titleLarge: TextStyle(fontSize: _fontSize * 1.25, fontFamily: _fontFamily),
          titleMedium: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          titleSmall: TextStyle(fontSize: _fontSize, fontFamily: _fontFamily),
          bodyLarge: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          bodyMedium: TextStyle(fontSize: _fontSize, fontFamily: _fontFamily),
          bodySmall: TextStyle(fontSize: _fontSize * 0.875, fontFamily: _fontFamily),
          labelLarge: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          labelMedium: TextStyle(fontSize: _fontSize, fontFamily: _fontFamily),
          labelSmall: TextStyle(fontSize: _fontSize * 0.875, fontFamily: _fontFamily),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ).copyWith(
          inversePrimary: const Color(0xFF3A3A3A),
          surfaceContainerHighest: const Color(0xFF2A2A2A),
          surfaceContainerHigh: const Color(0xFF242424),
          surfaceContainerLow: const Color(0xFF1E1E1E),
          surfaceContainerLowest: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        scrollbarTheme: buildAppScrollbarTheme(Brightness.dark),
        fontFamily: _fontFamily,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: _fontSize * 2.0, fontFamily: _fontFamily),
          displayMedium: TextStyle(fontSize: _fontSize * 1.75, fontFamily: _fontFamily),
          displaySmall: TextStyle(fontSize: _fontSize * 1.5, fontFamily: _fontFamily),
          headlineLarge: TextStyle(fontSize: _fontSize * 1.5, fontFamily: _fontFamily),
          headlineMedium: TextStyle(fontSize: _fontSize * 1.25, fontFamily: _fontFamily),
          headlineSmall: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          titleLarge: TextStyle(fontSize: _fontSize * 1.25, fontFamily: _fontFamily),
          titleMedium: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          titleSmall: TextStyle(fontSize: _fontSize, fontFamily: _fontFamily),
          bodyLarge: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          bodyMedium: TextStyle(fontSize: _fontSize, fontFamily: _fontFamily),
          bodySmall: TextStyle(fontSize: _fontSize * 0.875, fontFamily: _fontFamily),
          labelLarge: TextStyle(fontSize: _fontSize * 1.1, fontFamily: _fontFamily),
          labelMedium: TextStyle(fontSize: _fontSize, fontFamily: _fontFamily),
          labelSmall: TextStyle(fontSize: _fontSize * 0.875, fontFamily: _fontFamily),
        ),
      ),
      themeMode: _themeMode,
      // NB: usare SOLO routes['/'] (home + routes['/'] insieme violano
      // l'assert di MaterialApp e la navigazione pushReplacementNamed('/').
      routes: {
        '/': (context) => InitialScreen(
          onThemeModeChanged: (mode) => setThemeMode(mode),
          onLocaleChanged: (locale) => setLocale(locale),
          onFontChanged: (fontFamily, fontSize) => setFont(fontFamily, fontSize),
        ),
        '/home': (context) => const HomeScreen(),
      },
      builder: (context, child) {
        return RepaintBoundary(child: child!);
      },
    );
  }

  Future<void> _loadFontSettings() async {
    final fontFamily = await FontService.getFontFamily();
    final fontSize = await FontService.getFontSize();
    setState(() {
      _fontFamily = fontFamily;
      _fontSize = fontSize;
    });
  }
  
  void setFont(String? fontFamily, double fontSize) async {
    if (mounted) {
      setState(() {
        _fontFamily = fontFamily;
        _fontSize = fontSize;
      });
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('theme_mode') ?? 'system';
    ThemeMode mode;
    if (themeModeString == 'light') {
      mode = ThemeMode.light;
    } else if (themeModeString == 'dark') {
      mode = ThemeMode.dark;
    } else {
      // Su Cinnamon/Linux, rileva preferenza tema da gsettings
      mode = await _detectSystemTheme();
    }
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  /// Rileva se il sistema usa tema scuro o chiaro.
  /// Fallback a ThemeMode.system se non rilevabile.
  static Future<ThemeMode> _detectSystemTheme() async {
    if (!Platform.isLinux) return ThemeMode.system;
    try {
      // Prova gsettings (GNOME/Cinnamon/Budgie)
      final result = await Process.run(
        'gsettings',
        ['get', 'org.gnome.desktop.interface', 'color-scheme'],
        runInShell: false,
      ).timeout(const Duration(seconds: 2));
      if (result.exitCode == 0) {
        final scheme = (result.stdout as String).trim().toLowerCase();
        if (scheme.contains('dark')) return ThemeMode.dark;
        if (scheme.contains('light') || scheme.contains('default')) return ThemeMode.light;
      }
      // Fallback: Cinnamon usa proprio schema
      final cinResult = await Process.run(
        'gsettings',
        ['get', 'org.cinnamon.desktop.interface', 'gtk-theme'],
        runInShell: false,
      ).timeout(const Duration(seconds: 2));
      if (cinResult.exitCode == 0) {
        final theme = (cinResult.stdout as String).trim().toLowerCase();
        if (theme.contains('dark')) return ThemeMode.dark;
      }
    } catch (_) {}
    return ThemeMode.system;
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale');
    if (localeCode != null) {
      setState(() {
        _locale = Locale(localeCode);
      });
    }
  }

  void setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString('theme_mode', modeString);
    if (mounted) {
      setState(() {
        _themeMode = mode;
      });
    }
  }

  void setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString('locale', locale.languageCode);
    } else {
      await prefs.remove('locale');
    }
    if (mounted) {
      setState(() {
        _locale = locale;
      });
    }
  }
}

class InitialScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeModeChanged;
  final Function(Locale?)? onLocaleChanged;
  final Function(String?, double)? onFontChanged;
  
  const InitialScreen({super.key, required this.onThemeModeChanged, this.onLocaleChanged, this.onFontChanged});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _showLanguageSelection = false;
  bool _showWarning = false;
  bool _showPasswordSetup = false;
  bool _isInstallingOcsUrl = false;
  SystemDetectionInfo? _systemInfo;

  @override
  void initState() {
    super.initState();
    _detectSystem();
    _checkInitialStatus();
  }

  Future<void> _detectSystem() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      if (mounted) {
        setState(() {
          _systemInfo = systemInfo;
        });
      }
    } catch (_) {}
  }

  Future<void> _checkInitialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final languageSelected = prefs.getBool('language_selected') ?? false;
    final warningAccepted = prefs.getBool('warning_accepted') ?? false;
    final passwordConfigured = prefs.getBool('password_configured') ?? false;
    
    setState(() {
      _showLanguageSelection = !languageSelected;
      _showWarning = languageSelected && !warningAccepted;
      _showPasswordSetup = languageSelected && warningAccepted && !passwordConfigured;
      _isLoading = false;
    });
    
    if (passwordConfigured && !_showLanguageSelection && !_showWarning && !_showPasswordSetup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndInstallOcsUrl();
      });
    }
  }

  Future<void> _checkAndInstallOcsUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final ocsUrlChecked = prefs.getBool('ocs_url_checked') ?? false;
    
    if (ocsUrlChecked) {
      return;
    }
    
    final isInstalled = await OcsUrlService.isOcsUrlInstalled();
    if (isInstalled) {
      await prefs.setBool('ocs_url_checked', true);
      return;
    }
    
    setState(() {
      _isInstallingOcsUrl = true;
    });
    
    try {
      final success = await OcsUrlService.installOcsUrl();
      if (success) {
        await prefs.setBool('ocs_url_checked', true);
        await prefs.setBool('ocs_url_installed', true);
      } else {
        await prefs.setBool('ocs_url_checked', true);
        await prefs.setBool('ocs_url_installed', false);
      }
    } catch (e) {
      await prefs.setBool('ocs_url_checked', true);
      await prefs.setBool('ocs_url_installed', false);
    } finally {
      if (mounted) {
        setState(() {
          _isInstallingOcsUrl = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isInstallingOcsUrl) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (_isInstallingOcsUrl) ...[
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.installingOcsUrl ?? 'Installazione ocs-url in corso...',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.installingOcsUrlDescription ?? 
                  'Questa operazione viene eseguita automaticamente al primo avvio.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_showLanguageSelection || _showWarning) {
      return OnboardingScreen(
        onLocaleChanged: widget.onLocaleChanged,
        systemInfo: _systemInfo,
        initialStep: _showLanguageSelection ? 0 : 1,
        onComplete: () {
          setState(() {
            _showLanguageSelection = false;
            _showWarning = false;
          });
          _checkInitialStatus();
        },
      );
    }

    if (_showPasswordSetup) {
      return PasswordSetupScreen(
        onThemeModeChanged: widget.onThemeModeChanged,
        onLocaleChanged: widget.onLocaleChanged,
      );
    }
    
    return HomeScreen(
      onThemeModeChanged: widget.onThemeModeChanged,
      onLocaleChanged: widget.onLocaleChanged,
      onFontChanged: widget.onFontChanged,
    );
  }
}
