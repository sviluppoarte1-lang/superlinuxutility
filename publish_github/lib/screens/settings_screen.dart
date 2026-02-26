import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/password_storage.dart';
import '../services/font_service.dart';
import '../services/tray_service.dart';
import '../services/dependency_check_service.dart';
import '../services/window_close_to_tray.dart';
import '../services/autostart_service.dart';
import 'shutdown_scheduler_screen.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;
  final Function(Locale?)? onLocaleChanged;
  final Function(String?, double)? onFontChanged;
  
  const SettingsScreen({super.key, this.onThemeModeChanged, this.onLocaleChanged, this.onFontChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasPassword = false;
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.system;
  Locale? _currentLocale;
  String? _selectedFontFamily;
  double _selectedFontSize = 14.0;
  bool _systemTrayEnabled = true;
  bool _closeToTray = true;
  bool _startMinimized = false;
  bool _startAtLogin = false;
  bool? _trayDepsOk;
  bool _trayInstalling = false;

  @override
  void initState() {
    super.initState();
    _checkPassword();
    _loadThemeMode();
    _loadLocale();
    _loadFontSettings();
    _loadSystemTrayEnabled();
    _loadCloseToTray();
    _loadStartMinimized();
    _loadStartAtLogin();
    if (Platform.isLinux) _checkTrayDeps();
  }

  Future<void> _loadSystemTrayEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _systemTrayEnabled = prefs.getBool(TrayService.prefKeySystemTrayEnabled) ?? true;
    });
  }

  Future<void> _loadCloseToTray() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _closeToTray = prefs.getBool(TrayService.prefKeyCloseToTray) ?? true;
    });
  }

  Future<void> _loadStartMinimized() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _startMinimized = prefs.getBool(TrayService.prefKeyStartMinimized) ?? false;
    });
  }

  Future<void> _loadStartAtLogin() async {
    if (!Platform.isLinux) return;
    final enabled = await AutostartService.isStartAtLoginEnabled();
    if (mounted) setState(() => _startAtLogin = enabled);
  }

  Future<void> _setStartMinimized(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TrayService.prefKeyStartMinimized, value);
    setState(() => _startMinimized = value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? AppLocalizations.of(context)!.settingsStartMinimizedOn : AppLocalizations.of(context)!.settingsStartMinimizedOff)),
      );
    }
  }

  Future<void> _setStartAtLogin(bool value) async {
    final ok = await AutostartService.setStartAtLogin(value);
    if (!mounted) return;
    if (ok) {
      setState(() => _startAtLogin = value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(TrayService.prefKeyStartAtLogin, value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? AppLocalizations.of(context)!.settingsStartAtLoginOn : AppLocalizations.of(context)!.settingsStartAtLoginOff)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.settingsStartAtLoginError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setCloseToTray(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TrayService.prefKeyCloseToTray, value);
    setState(() => _closeToTray = value);
    await setCloseToTray(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? AppLocalizations.of(context)!.settingsCloseToTrayOn : AppLocalizations.of(context)!.settingsCloseToTrayOff)),
      );
    }
  }

  Future<void> _setSystemTrayEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TrayService.prefKeySystemTrayEnabled, value);
    setState(() => _systemTrayEnabled = value);
    if (Platform.isLinux) {
      if (value) {
        final ok = await DependencyCheckService.isSystemTraySupported();
        if (!ok) await DependencyCheckService.installSystemTrayDependencies();
        await TrayService.init();
      } else {
        await TrayService.destroy();
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value
              ? AppLocalizations.of(context)!.settingsTrayEnabled
              : AppLocalizations.of(context)!.settingsTrayDisabled),
        ),
      );
    }
  }

  Future<void> _checkTrayDeps() async {
    final ok = await DependencyCheckService.isSystemTraySupported();
    if (mounted) setState(() => _trayDepsOk = ok);
  }

  Future<void> _installTrayDeps() async {
    setState(() => _trayInstalling = true);
    final result = await DependencyCheckService.installSystemTrayDependencies();
    if (mounted) {
      setState(() => _trayInstalling = false);
      _checkTrayDeps();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true ? (result['message'] as String) : (result['message'] as String)),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (result['success'] == true && _systemTrayEnabled) {
        await TrayService.init(force: true);
      }
    }
  }
  
  Future<void> _loadFontSettings() async {
    final fontFamily = await FontService.getFontFamily();
    final fontSize = await FontService.getFontSize();
    setState(() {
      _selectedFontFamily = fontFamily;
      _selectedFontSize = fontSize;
    });
  }
  
  Future<void> _setFontFamily(String? fontFamily) async {
    await FontService.setFontFamily(fontFamily);
    setState(() {
      _selectedFontFamily = fontFamily;
    });
    widget.onFontChanged?.call(fontFamily, _selectedFontSize);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.fontRestartMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
  
  Future<void> _setFontSize(double fontSize) async {
    await FontService.setFontSize(fontSize);
    setState(() {
      _selectedFontSize = fontSize;
    });
    widget.onFontChanged?.call(_selectedFontFamily, fontSize);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.fontRestartMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString('locale');
    setState(() {
      _currentLocale = localeCode != null ? Locale(localeCode) : null;
    });
  }

  Future<void> _setLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale != null) {
      await prefs.setString('locale', locale.languageCode);
    } else {
      await prefs.remove('locale');
    }
    setState(() {
      _currentLocale = locale;
    });
    widget.onLocaleChanged?.call(locale);
    
    // Mostra messaggio che la lingua verrà applicata al riavvio
    if (mounted && locale != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.languageRestartMessage),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          duration: const Duration(seconds: 4),
        ),
      );
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

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString('theme_mode', modeString);
    setState(() {
      _themeMode = mode;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.themeRestartMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _checkPassword() async {
    final hasPassword = await PasswordStorage.hasPassword();
    setState(() {
      _hasPassword = hasPassword;
    });
  }

  Future<void> _savePassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordEmpty),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordMismatch),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await PasswordStorage.savePassword(_passwordController.text);
      setState(() {
        _hasPassword = true;
        _isLoading = false;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordSaved),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(
          AppLocalizations.of(context)!.settingsPasswordDesc,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await PasswordStorage.deletePassword();
      setState(() {
        _hasPassword = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settingsPasswordSaved),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.settingsPasswordTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _hasPassword
                          ? AppLocalizations.of(context)!.settingsPasswordSaved
                          : AppLocalizations.of(context)!.settingsPasswordDesc,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_hasPassword)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.settingsPasswordConfigured,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Inserisci la password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Conferma Password',
                        hintText: 'Reinserisci la password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _savePassword,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_hasPassword 
                                ? AppLocalizations.of(context)!.settingsPasswordUpdate 
                                : AppLocalizations.of(context)!.passwordSave),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (_hasPassword) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _deletePassword,
                              icon: const Icon(Icons.delete),
                              label: Text(AppLocalizations.of(context)!.settingsPasswordDelete),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.language, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.settingsLanguageTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.settingsLanguageDesc,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Locale>(
                      value: _currentLocale,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.settingsLanguageTitle,
                        border: const OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: Locale('it'),
                          child: Text('Italiano'),
                        ),
                        DropdownMenuItem(
                          value: Locale('en'),
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: Locale('fr'),
                          child: Text('Français'),
                        ),
                        DropdownMenuItem(
                          value: Locale('es'),
                          child: Text('Español'),
                        ),
                        DropdownMenuItem(
                          value: Locale('de'),
                          child: Text('Deutsch'),
                        ),
                        DropdownMenuItem(
                          value: Locale('pt'),
                          child: Text('Português'),
                        ),
                      ],
                      onChanged: (Locale? value) {
                        if (value != null) {
                          _setLocale(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.palette, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.settingsThemeTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RadioListTile<ThemeMode>(
                      title: Text(AppLocalizations.of(context)!.themeLight),
                      value: ThemeMode.light,
                      groupValue: _themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          _setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(AppLocalizations.of(context)!.themeDark),
                      value: ThemeMode.dark,
                      groupValue: _themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          _setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text(AppLocalizations.of(context)!.themeSystem),
                      subtitle: Text(AppLocalizations.of(context)!.themeSystemDesc),
                      value: ThemeMode.system,
                      groupValue: _themeMode,
                      onChanged: (ThemeMode? value) {
                        if (value != null) {
                          _setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.text_fields, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.settingsFontTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.settingsFontDesc,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFontFamily,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.fontFamily,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(AppLocalizations.of(context)!.fontDefault),
                        ),
                        ...FontService.availableFonts.map((font) => DropdownMenuItem<String>(
                          value: font,
                          child: Text(font),
                        )),
                      ],
                      onChanged: (String? value) {
                        _setFontFamily(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.fontSize,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _selectedFontSize,
                      min: 10.0,
                      max: 24.0,
                      divisions: 14,
                      label: '${_selectedFontSize.toStringAsFixed(0)}sp',
                      onChanged: (double value) {
                        _setFontSize(value);
                      },
                    ),
                    Text(
                      '${_selectedFontSize.toStringAsFixed(0)}sp',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (Platform.isLinux) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings_suggest, size: 32),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.settingsSystemTrayTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.settingsSystemTrayDesc,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                      if (_trayDepsOk != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _trayDepsOk! ? Icons.check_circle : Icons.warning_amber_rounded,
                              size: 20,
                              color: _trayDepsOk! ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _trayDepsOk!
                                  ? AppLocalizations.of(context)!.settingsTrayDepsOk
                                  : AppLocalizations.of(context)!.settingsTrayDepsMissing,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.settingsSystemTrayEnable,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _systemTrayEnabled,
                            onChanged: (value) => _setSystemTrayEnabled(value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.settingsCloseToTray,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _closeToTray,
                            onChanged: (value) => _setCloseToTray(value),
                          ),
                        ],
                      ),
                      Text(
                        AppLocalizations.of(context)!.settingsCloseToTrayDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.settingsStartMinimized,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _startMinimized,
                            onChanged: (value) => _setStartMinimized(value),
                          ),
                        ],
                      ),
                      Text(
                        AppLocalizations.of(context)!.settingsStartMinimizedDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      if (Platform.isLinux) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.settingsStartAtLogin,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Switch(
                              value: _startAtLogin,
                              onChanged: (value) => _setStartAtLogin(value),
                            ),
                          ],
                        ),
                        Text(
                          AppLocalizations.of(context)!.settingsStartAtLoginDesc,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                      if (_trayDepsOk == false) ...[
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _trayInstalling ? null : _installTrayDeps,
                          icon: _trayInstalling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(AppLocalizations.of(context)!.settingsTrayInstallDeps),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.power_settings_new, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.tabShutdownScheduler,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.shutdownInfoDescription,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShutdownSchedulerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings),
                      label: Text(AppLocalizations.of(context)!.shutdownOpenSettings),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, size: 32),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.settingsInfoTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.settingsInfoDesc,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• ${AppLocalizations.of(context)!.settingsInfoItem1}'),
                    Text('• ${AppLocalizations.of(context)!.settingsInfoItem2}'),
                    Text('• ${AppLocalizations.of(context)!.settingsInfoItem3}'),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.settingsPasswordSecurityMessage,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

