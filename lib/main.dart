import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/warning_screen.dart';
import 'screens/password_setup_screen.dart';
import 'screens/language_selection_screen.dart';
import 'services/ocs_url_service.dart';
import 'services/system_detector.dart';
import 'services/font_service.dart';
import 'services/single_instance_service.dart';
import 'services/tray_service.dart';
import 'services/dependency_check_service.dart';
import 'services/window_close_to_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Rileva se la distro è Fedora (evita init system tray per segfault noti con appindicator su Fedora/KDE).
Future<bool> _isFedora() async {
  try {
    final file = File('/etc/os-release');
    if (!await file.exists()) return false;
    final content = await file.readAsString();
    return content.contains('ID=fedora') || content.contains('ID="fedora"');
  } catch (_) {
    return false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux) {
    try {
      await windowManager.ensureInitialized();
    } catch (_) {}
  }

  final singleInstance = await isSingleInstance();
  if (!singleInstance) {
    runApp(const _AlreadyRunningApp());
    return;
  }

  if (Platform.isLinux) {
    final prefs = await SharedPreferences.getInstance();
    final trayEnabled = prefs.getBool(TrayService.prefKeySystemTrayEnabled) ?? true;
    final skipTrayEnv = Platform.environment['SUPER_LINUX_UTILITY_NO_TRAY'] == '1' ||
        Platform.environment['SUPER_LINUX_UTILITY_NO_TRAY'] == 'true';
    final isFedora = await _isFedora();
    if (trayEnabled && !skipTrayEnv && !isFedora) {
      final supported = await DependencyCheckService.isSystemTraySupported();
      if (!supported) {
        await DependencyCheckService.installSystemTrayDependencies();
      }
      await TrayService.init();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => initWindowCloseToTray());
  }

  runApp(const MyApp());
}

class _AlreadyRunningApp extends StatelessWidget {
  const _AlreadyRunningApp();

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  String? _fontFamily;
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _loadLocale();
    _loadFontSettings();
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
    setState(() {
      _themeMode = themeModeString == 'light'
          ? ThemeMode.light
          : themeModeString == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
    });
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
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
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
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
      home: InitialScreen(
        onThemeModeChanged: (mode) => setThemeMode(mode),
        onLocaleChanged: (locale) => setLocale(locale),
        onFontChanged: (fontFamily, fontSize) => setFont(fontFamily, fontSize),
      ),
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

    if (_showLanguageSelection) {
      return LanguageSelectionScreen(
        onThemeModeChanged: widget.onThemeModeChanged,
        onLocaleChanged: widget.onLocaleChanged,
      );
    }

    if (_showWarning) {
      return WarningScreen(
        onThemeModeChanged: widget.onThemeModeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        systemInfo: _systemInfo,
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
