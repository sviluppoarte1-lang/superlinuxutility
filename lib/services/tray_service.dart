import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/services/app_memory_maintenance.dart';
import 'single_instance_service.dart';
import 'battery_service.dart';
import 'smart_service.dart';
import 'system_monitor.dart';
import '../models/system_info.dart';

class TrayMenuLabels {
  final String checkUpdates;
  final String cleanTempFilesAndCache;
  final String system;
  final String cpuGpuTemp;
  final String diskUsage;
  final String memoryUsage;
  final String smartHealth;
  final String clipboard;
  final String battery;
  final String batteryHealth;
  final String chargeLimit;
  final String powerProfile;
  final String shutdownTimer;
  final String showMainWindow;
  final String cpuGpuUsage;
  final String settings;
  final String exit;
  const TrayMenuLabels({
    required this.checkUpdates,
    required this.cleanTempFilesAndCache,
    required this.system,
    required this.cpuGpuTemp,
    required this.diskUsage,
    required this.memoryUsage,
    required this.smartHealth,
    required this.clipboard,
    required this.battery,
    required this.batteryHealth,
    required this.chargeLimit,
    required this.powerProfile,
    required this.shutdownTimer,
    required this.showMainWindow,
    required this.cpuGpuUsage,
    required this.settings,
    required this.exit,
  });
}

class TrayCallbacks {
  final void Function()? onShowMainWindow;
  final void Function()? onCheckUpdates;
  final void Function()? onShowCheckUpdatesDialog;
  final void Function()? onCleanTempFiles;
  final void Function()? onShowCpuGpuTemp;
  final void Function()? onShowDiskUsage;
  final void Function()? onShowTaskManagerDialog;
  final void Function()? onShowSmartHealth;
  final void Function()? onShowShutdownTimerDialog;
  final void Function()? onShowCleanCacheDialog;
  final void Function()? onShowCpuGpuUsage;
  final void Function()? onShowClipboard;
  final void Function()? onShowBattery;
  final void Function()? onShowSettings;
  final void Function(String message)? showSnackbar;

  TrayCallbacks({
    this.onShowMainWindow,
    this.onCheckUpdates,
    this.onShowCheckUpdatesDialog,
    this.onCleanTempFiles,
    this.onShowCpuGpuTemp,
    this.onShowDiskUsage,
    this.onShowTaskManagerDialog,
    this.onShowSmartHealth,
    this.onShowShutdownTimerDialog,
    this.onShowCleanCacheDialog,
    this.onShowCpuGpuUsage,
    this.onShowClipboard,
    this.onShowBattery,
    this.onShowSettings,
    this.showSnackbar,
  });
}

class TrayService {
  static const String prefKeySystemTrayEnabled = 'system_tray_enabled';
  static const String prefKeyCloseToTray = 'close_to_tray';
  static const String prefKeyStartMinimized = 'start_minimized';
  static const String prefKeyStartAtLogin = 'start_at_login';

  static SystemTray? _systemTray;
  static AppWindow? _appWindow;
  static TrayCallbacks? _callbacks;
  static TrayMenuLabels? _labels;
  static bool _initialized = false;
  static String? _lastError;
  /// Icone colorate a tema per le voci del menu (asset PNG 32px).
  static const String _iconUpdates = 'assets/icons/tray/tray_updates.png';
  static const String _iconClean = 'assets/icons/tray/tray_clean.png';
  static const String _iconSystem = 'assets/icons/tray/tray_system.png';
  static const String _iconTemp = 'assets/icons/tray/tray_temp.png';
  static const String _iconUsage = 'assets/icons/tray/tray_usage.png';
  static const String _iconMemory = 'assets/icons/tray/tray_memory.png';
  static const String _iconDisk = 'assets/icons/tray/tray_disk.png';
  static const String _iconSmart = 'assets/icons/tray/tray_smart.png';
  static const String _iconClipboard = 'assets/icons/tray/tray_clipboard.png';
  static const String _iconBattery = 'assets/icons/tray/tray_battery.png';
  static const String _iconCharge = 'assets/icons/tray/tray_charge.png';
  static const String _iconGovernor = 'assets/icons/tray/tray_governor.png';
  static const String _iconShutdown = 'assets/icons/tray/tray_shutdown.png';
  static const String _iconShow = 'assets/icons/tray/tray_show.png';
  static const String _iconSettings = 'assets/icons/tray/tray_settings.png';
  static const String _iconExit = 'assets/icons/tray/tray_exit.png';
  static Timer? _menuUpdateTimer;
  static bool _menuRefreshInFlight = false;
  static bool _smartRefreshInFlight = false;
  /// Aggiornamento tray: 10s riduce CPU rispetto al precedente 5s.
  static const Duration _menuStatsInterval = Duration(seconds: 10);
  /// Cache resultati per evitare subprocess ripetute quando i valori non cambiano.
  static Map<String, dynamic>? _cachedDiskUsage;
  static int _diskUsageCacheTs = 0;
  static const int _diskUsageCacheMs = 30000; // 30s
  /// Cooldown per query SMART (ogni 60s, non ogni tick).
  static int _lastSmartRefreshTs = 0;
  static const int _smartCooldownMs = 60000; // 60s
  static String _tempLabel = '';
  static String _usageLabel = '';
  static String _diskUsageLabel = '';
  static String _memoryUsageLabel = '';
  static String _smartHealthLabel = '';
  /// Esito SMART per l'emoji dinamica (true=💚, false=❤️, null=🤍).
  static bool? _smartOk;
  static String _batteryLabel = '';
  static String _chargeLimitLabel = '';
  static String _powerProfileLabel = '';
  /// Emoji colorate prefisse alle voci (stesso trucco di system_backup: il
  /// testo passa su qualsiasi renderer, anche dove le `image:` PNG vengono
  /// ignorate come su Cinnamon).
  static const String _eUpdates = '🔄';
  static const String _eClean = '🧹';
  static const String _eSystem = '💻';
  static const String _eTemp = '🌡️';
  static const String _eUsage = '⚡';
  static const String _eMemory = '🧠';
  static const String _eDisk = '💽';
  static const String _eClipboard = '📋';
  static const String _eBattery = '🔋';
  static const String _eCharge = '⚡';
  static const String _ePower = '🚀';
  static const String _eShutdown = '⏳';
  static const String _eShow = '🖥️';
  static const String _eSettings = '⚙️';
  static const String _eExit = '🚪';
  // Cache labels per evitare rebuild menu se non cambiati
  static String _prevTempLabel = '';
  static String _prevUsageLabel = '';
  static String _prevDiskLabel = '';
  static String _prevMemoryLabel = '';
  static String _prevSmartLabel = '';
  static String _prevBatteryLabel = '';
  static String _prevChargeLabel = '';
  static String _prevPowerLabel = '';
  static bool _menuDirty = true;

  static bool get isInitialized => _initialized;
  static String? get lastError => _lastError;

  static TrayCallbacks? get callbacks => _callbacks;

  static void setCallbacks(TrayCallbacks c) {
    _callbacks = c;
  }

  static void setLabels(TrayMenuLabels labels) {
    _labels = labels;
    _menuDirty = true;
    _buildMenuWithStats();
    _startMenuUpdateTimer();
  }

  /// Etichette del menu tray nella lingua salvata dall'utente (o, se mai
  /// scelta, in quella di sistema).
  ///
  /// Usate finché HomeScreen non impone quelle localizzate dal contesto:
  /// il menu del tray non deve mai apparire in italiano se l'utente ha
  /// scelto un'altra lingua.
  static Future<TrayMenuLabels> labelsForSavedLocale() async {
    var locale = PlatformDispatcher.instance.locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale');
      if (code != null && code.isNotEmpty) locale = Locale(code);
    } catch (_) {}
    try {
      final l = await AppLocalizations.delegate.load(locale);
      return TrayMenuLabels(
        checkUpdates: l.trayCheckUpdates,
        cleanTempFilesAndCache: l.trayCleanTempFilesAndCache,
        system: l.traySystem,
        cpuGpuTemp: l.trayCpuGpuTemp,
        diskUsage: l.trayDiskUsage,
        memoryUsage: l.trayMemoryUsage,
        smartHealth: l.traySmartHealth,
        clipboard: l.trayClipboard,
        battery: l.trayBattery,
        batteryHealth: l.trayBatteryHealth,
        chargeLimit: l.trayChargeLimit,
        powerProfile: l.trayPowerProfile,
        shutdownTimer: l.trayShutdownTimer,
        showMainWindow: l.trayShowMainWindow,
        cpuGpuUsage: l.trayCpuGpuUsage,
        settings: l.traySettings,
        exit: l.trayExit,
      );
    } catch (_) {
      return _fallbackItalianLabels;
    }
  }

  static Future<String?> _getTrayIconPath() async {
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/super_linux_utility_tray_icon.png';
      final file = File(path);
      try {
        final data = await rootBundle.load('assets/icons/icon.png');
        await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        return path;
      } catch (_) {
        if (await file.exists()) return path;
        const base64Png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        await file.writeAsBytes(base64Decode(base64Png));
        return path;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<bool> init({bool force = false}) async {
    if (!Platform.isLinux) return false;
    if (_initialized && !force) return true;
    _lastError = null;
    try {
      final iconPath = await _getTrayIconPath();
      _appWindow = AppWindow();
      _systemTray = SystemTray();
      await _systemTray!.initSystemTray(
        title: '',
        iconPath: iconPath ?? '',
      );
      // Menu iniziale già nella lingua salvata dall'utente: finché HomeScreen
      // non fornisce le etichette dal contesto, non si deve vedere l'italiano
      // (o qualsiasi altra lingua diversa da quella scelta).
      _labels ??= await labelsForSavedLocale();
      _menuDirty = true;
      await _buildMenuWithStats();
      _startMenuUpdateTimer();
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          showWindow();
        }
      });
      _initialized = true;
      return true;
    } catch (e) {
      _lastError = e.toString();
      _initialized = false;
      return false;
    }
  }

  static void _startMenuUpdateTimer() {
    _menuUpdateTimer?.cancel();
    if (!_initialized || _systemTray == null) return;
    _refreshMenuStats();
    _menuUpdateTimer = Timer.periodic(_menuStatsInterval, (_) {
      _refreshMenuStats();
    });
  }

  static Future<void> _refreshMenuStats() async {
    if (_menuRefreshInFlight) return;
    _menuRefreshInFlight = true;
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Disco: cache 30s per evitare subprocess df ripetute
      final needDisk = _cachedDiskUsage == null || (now - _diskUsageCacheTs) >= _diskUsageCacheMs;
      final results = await Future.wait([
        SystemMonitor.getTrayLightweightStats(),
        SystemMonitor.getCpuTemperature(),
        if (needDisk) SystemMonitor.getHomeDiskUsage() else Future.value(_cachedDiskUsage),
        SystemMonitor.getMemoryFromFreeForTray(),
        BatteryService.getBatteryHealth(),
        BatteryService.getCurrentGovernor(),
      ]);
      final stats = results[0] as TrayCpuGpuStats;
      final cpuTemp = results[1] as double?;
      final homeDisk = results[2] as Map<String, dynamic>?;
      final memFree = results[3] as Map<String, dynamic>?;
      final batt = results[4] as BatteryHealth;
      final governor = results[5] as String;
      if (needDisk && homeDisk != null) {
        _cachedDiskUsage = homeDisk;
        _diskUsageCacheTs = now;
      }
      final cpuUsage = stats.cpuUsagePercent;
      final gpuUsage = stats.gpuUsagePercent;
      final gpuTemp = stats.gpuTemp;
      final cpuStr = cpuTemp != null ? '${cpuTemp.toStringAsFixed(0)}°C' : '-';
      final gpuStr = gpuTemp != null ? '${gpuTemp.toStringAsFixed(0)}°C' : '-';
      _tempLabel = 'CPU: $cpuStr | GPU: $gpuStr';
      String u = '${cpuUsage.toStringAsFixed(0)}%';
      if (gpuUsage != null) u += ' | ${gpuUsage.toStringAsFixed(0)}%';
      _usageLabel = u;
      if (homeDisk != null) {
        final p = (homeDisk['usedPercent'] as num).toStringAsFixed(0);
        _diskUsageLabel = '$p% (${homeDisk['usedStr']}/${homeDisk['totalStr']})';
      } else {
        _diskUsageLabel = '';
      }
      if (memFree != null) {
        final pct = (memFree['usedPercent'] as num).toStringAsFixed(0);
        _memoryUsageLabel = '$pct% (${memFree['usedStr']} / ${memFree['totalStr']})';
      } else {
        _memoryUsageLabel = '';
      }
      if (batt.present) {
        _batteryLabel = '${batt.percent}%';
        _chargeLimitLabel = batt.chargeEndThreshold != null
            ? '${batt.chargeEndThreshold}%'
            : '';
        _powerProfileLabel = governor;
      } else {
        _batteryLabel = '';
        _chargeLimitLabel = '';
        _powerProfileLabel = '';
      }
      // Tooltip live con statistiche istantanee (non ricostruisce il menu).
      try {
        final memPct = memFree != null
            ? ' • RAM ${(memFree['usedPercent'] as num).toStringAsFixed(0)}%'
            : '';
        await _systemTray?.setToolTip(
          'CPU $cpuStr • GPU $gpuStr$memPct',
        );
      } catch (_) {}
      // Ricostruisce subito il menu se le label sono cambiate: le statistiche
      // CPU/GPU/RAM devono restare istantanee (ogni 10s).
      final labelsChanged = _tempLabel != _prevTempLabel ||
          _usageLabel != _prevUsageLabel ||
          _diskUsageLabel != _prevDiskLabel ||
          _memoryUsageLabel != _prevMemoryLabel ||
          _smartHealthLabel != _prevSmartLabel ||
          _batteryLabel != _prevBatteryLabel ||
          _chargeLimitLabel != _prevChargeLabel ||
          _powerProfileLabel != _prevPowerLabel ||
          _menuDirty;
      if (labelsChanged) {
        _prevTempLabel = _tempLabel;
        _prevUsageLabel = _usageLabel;
        _prevDiskLabel = _diskUsageLabel;
        _prevMemoryLabel = _memoryUsageLabel;
        _prevSmartLabel = _smartHealthLabel;
        _prevBatteryLabel = _batteryLabel;
        _prevChargeLabel = _chargeLimitLabel;
        _prevPowerLabel = _powerProfileLabel;
        _menuDirty = false;
        await _buildMenuWithStats();
      }
      // SMART: cooldown 60s per evitare query sudo frequenti
      if ((now - _lastSmartRefreshTs) >= _smartCooldownMs) {
        _lastSmartRefreshTs = now;
        _refreshSmartLabels();
      }
    } catch (_) {} finally {
      _menuRefreshInFlight = false;
    }
  }

  static Future<void> _refreshSmartLabels() async {
    if (_smartRefreshInFlight) return;
    _smartRefreshInFlight = true;
    try {
      final disks = await SmartService.scanDisks();
      if (disks.isNotEmpty) {
        final info = await SmartService.getSmartInfo(disks.first, immediate: false);
        if (info != null) {
          _smartOk = info.overallHealthPassed;
          _smartHealthLabel = info.overallHealthPassed ? '✓ PASSED' : '✗ FAILED';
          if (info.temperature != null) {
            _smartHealthLabel += ' (${info.temperature}°C)';
          }
        } else {
          _smartOk = null;
          _smartHealthLabel = '';
        }
      } else {
        _smartOk = null;
        _smartHealthLabel = '';
      }
    } catch (_) {
      _smartOk = null;
      _smartHealthLabel = '';
    } finally {
      _smartRefreshInFlight = false;
    }
    if (_smartHealthLabel != _prevSmartLabel) {
      _prevSmartLabel = _smartHealthLabel;
      await _buildMenuWithStats();
    }
  }

  static Future<void> destroy() async {
    _menuUpdateTimer?.cancel();
    _menuUpdateTimer = null;
    if (!_initialized) return;
    try {
      await _systemTray?.destroy();
    } catch (_) {}
    _systemTray = null;
    _appWindow = null;
    _initialized = false;
  }

  /// Ultima risorsa (niente preferenza lingua e lingua di sistema ignota):
  /// etichette hardcoded in italiano.
  static const TrayMenuLabels _fallbackItalianLabels = TrayMenuLabels(
    checkUpdates: 'Verifica aggiornamenti di sistema',
    cleanTempFilesAndCache: 'Pulisci file temporanei e cache',
    system: 'Sistema',
    cpuGpuTemp: 'Temperatura CPU, GPU',
    diskUsage: 'Uso del disco',
    memoryUsage: 'Uso memoria RAM',
    smartHealth: 'Salute disco (SMART)',
    clipboard: 'Appunti',
    battery: 'Batteria',
    batteryHealth: 'Salute batteria',
    chargeLimit: 'Limite carica',
    powerProfile: 'Profilo energia',
    shutdownTimer: 'Spegnimento automatico',
    showMainWindow: 'Visualizza schermata principale',
    cpuGpuUsage: 'Uso CPU, GPU',
    settings: 'Impostazioni',
    exit: 'Esci',
  );

  static Future<void> _buildMenuWithStats() async {
    if (_systemTray == null) return;
    final l = _labels ?? _fallbackItalianLabels;
    final tempLabel = _tempLabel.isEmpty ? l.cpuGpuTemp : '${l.cpuGpuTemp}: $_tempLabel';
    final usageLabel = _usageLabel.isEmpty ? l.cpuGpuUsage : '${l.cpuGpuUsage}: $_usageLabel';
    final diskLabel = _diskUsageLabel.isEmpty ? l.diskUsage : '${l.diskUsage}: $_diskUsageLabel';
    final memoryLabel = _memoryUsageLabel.isEmpty ? l.memoryUsage : '${l.memoryUsage}: $_memoryUsageLabel';
    final smartLabel = _smartHealthLabel.isEmpty ? l.smartHealth : '${l.smartHealth}: $_smartHealthLabel';
    final smartEmoji = _smartOk == null ? '🤍' : (_smartOk! ? '💚' : '❤️');
    final battLabel = _batteryLabel.isEmpty ? l.batteryHealth : '${l.batteryHealth}: $_batteryLabel';
    final limitLabel = _chargeLimitLabel.isEmpty ? l.chargeLimit : '${l.chargeLimit}: $_chargeLimitLabel';
    final profileLabel = _powerProfileLabel.isEmpty ? l.powerProfile : '${l.powerProfile}: $_powerProfileLabel';
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: '$_eUpdates ${l.checkUpdates}', image: _iconUpdates, onClicked: (_) {
        _callbacks?.onShowCheckUpdatesDialog?.call();
      }),
      MenuItemLabel(
          label: '$_eClean ${l.cleanTempFilesAndCache}',
          image: _iconClean,
          onClicked: (_) => _onCleanTempFiles()),
      SubMenu(label: '$_eSystem ${l.system}', image: _iconSystem, children: [
        MenuItemLabel(label: '$_eTemp $tempLabel', image: _iconTemp, onClicked: (_) {
          _callbacks?.onShowCpuGpuTemp?.call();
          showWindow();
        }),
        MenuItemLabel(label: '$_eUsage $usageLabel', image: _iconUsage, onClicked: (_) {
          _callbacks?.onShowCpuGpuUsage?.call();
          showWindow();
        }),
        MenuItemLabel(label: '$_eMemory $memoryLabel', image: _iconMemory, onClicked: (_) {
          _callbacks?.onShowTaskManagerDialog?.call();
        }),
        MenuItemLabel(label: '$_eDisk $diskLabel', image: _iconDisk, onClicked: (_) {
          _callbacks?.onShowDiskUsage?.call();
          showWindow();
        }),
        MenuItemLabel(label: '$smartEmoji $smartLabel', image: _iconSmart, onClicked: (_) {
          _callbacks?.onShowSmartHealth?.call();
          showWindow();
        }),
      ]),
      MenuItemLabel(label: '$_eClipboard ${l.clipboard}', image: _iconClipboard, onClicked: (_) {
        // Processo separato: NON mostrare la main window.
        _callbacks?.onShowClipboard?.call();
      }),
      SubMenu(label: '$_eBattery ${l.battery}', image: _iconBattery, children: [
        MenuItemLabel(label: '$_eBattery $battLabel', image: _iconBattery, onClicked: (_) {
          _callbacks?.onShowBattery?.call();
          showWindow();
        }),
        MenuItemLabel(label: '$_eCharge $limitLabel', image: _iconCharge, onClicked: (_) {
          _callbacks?.onShowBattery?.call();
          showWindow();
        }),
        MenuItemLabel(label: '$_ePower $profileLabel', image: _iconGovernor, onClicked: (_) {
          _callbacks?.onShowBattery?.call();
          showWindow();
        }),
      ]),
      MenuItemLabel(label: '$_eShutdown ${l.shutdownTimer}', image: _iconShutdown, onClicked: (_) => _onShutdownTimer()),
      MenuSeparator(),
      MenuItemLabel(
        label: '$_eShow ${l.showMainWindow}',
        image: _iconShow,
        onClicked: (_) {
          _callbacks?.onShowMainWindow?.call();
          showWindow();
        },
      ),
      MenuItemLabel(label: '$_eSettings ${l.settings}', image: _iconSettings, onClicked: (_) {
        _callbacks?.onShowSettings?.call();
        showWindow();
      }),
      MenuSeparator(),
      MenuItemLabel(label: '$_eExit ${l.exit}', image: _iconExit, onClicked: (_) async {
        await releaseSingleInstanceLock();
        _onExit();
      }),
    ]);
    await _systemTray!.setContextMenu(menu);
  }

  static void _onExit() {
    SystemNavigator.pop();
  }

  static void _onShutdownTimer() {
    showWindow();
    _callbacks?.onShowShutdownTimerDialog?.call();
  }

  /// Lancia un processo standalone per una utility (es. task manager, check updates).
  /// Il nuovo processo mostra solo la schermata richiesta senza la finestra principale.
  static Future<void> launchStandaloneProcess(List<String> args) async {
    try {
      final executable = Platform.resolvedExecutable;
      final mode = args.contains('--task-manager')
          ? 'task-manager'
          : args.contains('--clipboard')
              ? 'clipboard'
              : 'check-updates';
      await Process.start(
        executable,
        [],
        environment: {'SUPER_LINUX_UTILITY_MODE': mode},
        mode: ProcessStartMode.normal,
      );
    } catch (e) {
      debugPrint('Failed to launch standalone process: $e');
    }
  }

  /// Se true, la CleanupScreen eseguirà la pulizia al primo frame (apertura da tray).
  static bool runCleanupWhenScreenShown = false;

  static void _onCleanTempFiles() {
    runCleanupWhenScreenShown = true;
    _callbacks?.onCleanTempFiles?.call();
  }

  static void showWindow() {
    _showWindowWithRetry();
  }

  /// Mostra la finestra con retry per gestire Cinnamon/XWayland dove la finestra
  /// potrebbe non essere ancora mappata quando il callback tray arriva.
  /// Sequenza: restore (toglie minimizzato/nascosto) -> show -> focus, così la
  /// finestra finisce sempre in primo piano.
  static void _showWindowWithRetry({int attempt = 0}) {
    try {
      windowManager.restore();
    } catch (_) {}
    try {
      windowManager.show();
      windowManager.focus();
    } catch (_) {}
    _appWindow?.show();
    // Su Cinnamon, a volte serve un secondo tentativo dopo un breve ritardo
    // perché il window manager potrebbe non aver ancora mappato la finestra.
    if (attempt < 2) {
      Future<void>.delayed(Duration(milliseconds: 150 + attempt * 100), () {
        if (_appWindow != null) {
          try {
            windowManager.restore();
          } catch (_) {}
          try {
            windowManager.show();
            windowManager.focus();
          } catch (_) {}
          _appWindow?.show();
        }
      });
    }
  }

  static void hideWindow() {
    try {
      windowManager.hide();
    } catch (_) {}
    _appWindow?.hide();
    AppMemoryMaintenance.notifyMainWindowHiddenToTray();
  }
}
