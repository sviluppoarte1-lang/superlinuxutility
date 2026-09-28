import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/config/app_build.dart';
import 'package:super_linux_utility/services/license_service.dart';
import 'license_activation_dialog.dart';
import 'services_screen.dart';
import 'startup_apps_screen.dart';
import 'cleanup_screen.dart';
import 'installed_apps_screen.dart';
import 'system_monitor_screen.dart';
import 'grub_editor_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';
import 'disk_analyzer_screen.dart';
import 'recovery_screen.dart';
import 'smart_monitor_screen.dart';
import 'tweaks_screen.dart';
import 'device_manager_screen.dart';
import 'driver_manager_screen.dart';
import 'app_update_dialog.dart';
import 'battery_screen.dart';
import 'services_guide_dialog.dart';
import 'tray_task_manager_dialog.dart';
import 'dart:io';
import '../services/app_memory_maintenance.dart';
import '../services/battery_service.dart';
import '../services/clipboard_history_service.dart';
import '../services/tray_service.dart';
import '../services/recovery_service.dart';
import '../services/shutdown_scheduler_service.dart';
import '../services/password_storage.dart';
import '../services/cleanup_service.dart';
import '../services/ram_cleanup_service.dart';
import '../services/app_self_update_service.dart';
import '../utils/update_check_report_formatter.dart';
import '../utils/update_preview_helper.dart';
import '../widgets/updates_apply_progress_view.dart';
import '../widgets/tab_page_no_keep_alive.dart';
import '../widgets/feature_icon.dart';

class HomeScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;
  final Function(Locale?)? onLocaleChanged;
  final Function(String?, double)? onFontChanged;
  
  const HomeScreen({super.key, this.onThemeModeChanged, this.onLocaleChanged, this.onFontChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isAdvancedMode = false;
  bool _isLoading = true;
  bool _licenseActivated = false;
  Timer? _updateCheckTimer;
  Timer? _updateCheckInitialTimer;
  Timer? _ramCleanupTimer;
  static const String _keyUpdateCheckIntervalMinutes = 'update_check_interval_minutes';
  static const String _keyLastUpdateCheckTs = 'last_update_check_ts';
  /// Default per nuove installazioni: controllo ogni ora (0 = mai, se scelto).
  static const int _defaultUpdateCheckMinutes = 60;
  /// Dopo un check fallito riprova dopo questi minuti (non a fine intervallo).
  static const int _failedCheckRetryMinutes = 10;
  static const int _standardTabCount = 14;
  static const int _advancedTabCount = 15;

  @override
  void initState() {
    super.initState();
    AppMemoryMaintenance.onMainWindowHiddenToTray = _releaseMainUiForTray;
    _initializeController();
    if (Platform.isLinux) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initTray());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _showServicesGuide());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startUpdateCheckTimer());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRamCleanupTimer());
    // Cronologia appunti: monitoraggio sempre attivo mentre l'app è in esecuzione
    // (anche ridotta a icona nel tray). Accesso alla cronologia solo dal tray.
    if (Platform.isLinux) {
      ClipboardHistoryService.startMonitoring();
      // Governor automatico batteria se abilitato nelle impostazioni.
      BatteryService.getGovernorAutoEnabled().then((v) {
        if (v) BatteryService.startAcMonitor();
      });
    }
  }

  Future<void> _startRamCleanupTimer() async {
    _ramCleanupTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt(RamCleanupService.prefKeyIntervalMinutes) ??
        RamCleanupService.intervalDisabled;
    if (interval <= 0) return;
    _ramCleanupTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _onRamCleanupTick());
  }

  Future<void> _onRamCleanupTick() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = prefs.getInt(RamCleanupService.prefKeyIntervalMinutes) ??
        RamCleanupService.intervalDisabled;
    if (interval <= 0) return;
    final last = prefs.getInt(RamCleanupService.prefKeyLastRunTs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last > 0 && now - last < interval * 60 * 1000) return;
    try {
      final result = await RamCleanupService.cleanupRam();
      await prefs.setInt(RamCleanupService.prefKeyLastRunTs, now);
    } catch (_) {}
  }

  /// Intervallo effettivo: default 60 min se mai configurato, altrimenti il
  /// valore salvato (0 = disattivato esplicitamente dall'utente).
  static int _resolveUpdateCheckInterval(SharedPreferences prefs) {
    if (!prefs.containsKey(_keyUpdateCheckIntervalMinutes)) {
      return _defaultUpdateCheckMinutes;
    }
    return prefs.getInt(_keyUpdateCheckIntervalMinutes) ?? 0;
  }

  Future<void> _startUpdateCheckTimer() async {
    _updateCheckTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final interval = _resolveUpdateCheckInterval(prefs);
    if (interval <= 0) return;
    _updateCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) => _onUpdateCheckTick());
    _updateCheckInitialTimer?.cancel();
    _updateCheckInitialTimer =
        Timer(const Duration(seconds: 15), () => _onUpdateCheckTick());
  }

  Future<void> _onUpdateCheckTick() async {
    final prefs = await SharedPreferences.getInstance();
    final interval = _resolveUpdateCheckInterval(prefs);
    if (interval <= 0) return;
    final last = prefs.getInt(_keyLastUpdateCheckTs) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (last > 0 && now - last < interval * 60 * 1000) return;
    // 1) Auto-update dell'app isolato: un suo errore non deve mai bloccare
    // il controllo degli aggiornamenti di sistema (bug precedente).
    try {
      final autoAppUpdateEnabled = prefs.getBool(SettingsScreen.keyAutoAppUpdateFromGithub) ?? true;
      if (autoAppUpdateEnabled) {
        final appUpdateResult = await AppSelfUpdateService.checkAndAutoUpdateFromGithub();
        if (!mounted) return;
        if (appUpdateResult['updated'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((appUpdateResult['message'] ?? 'Application updated. Please restart the app.').toString()),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('SuperLinuxUtility: auto app-update failed: $e');
    }
    // 2) Controllo aggiornamenti di sistema.
    try {
      final result = await RecoveryService.checkForUpdates();
      if (result['success'] == true) {
        await prefs.setInt(_keyLastUpdateCheckTs, now);
      } else {
        // Fallito: riprova tra poco invece di aspettare l'intervallo intero.
        final retryMs = _failedCheckRetryMinutes * 60 * 1000;
        final stamped = now - interval * 60 * 1000 + retryMs;
        await prefs.setInt(
            _keyLastUpdateCheckTs, stamped < now ? stamped : now);
        debugPrint(
            'SuperLinuxUtility: system update check failed: ${result['error']}');
      }
      if (!mounted) return;
      final installable = result['updateCount'] as int? ?? 0;
      // Non notificare se ci sono solo aggiornamenti phased (non installabili); sì se misti o solo installabili.
      if (installable > 0) {
        final summary = result['summaryPackageCount'] as int? ?? installable;
        _showUpdatesAvailableDialog(result, summary);
      }
    } catch (e) {
      debugPrint('SuperLinuxUtility: system update check error: $e');
    }
  }

  Future<void> _showUpdatesAvailableDialog(Map<String, dynamic> result, int count) async {
    if (!mounted) return;
    TrayService.showWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final apply = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.green),
              const SizedBox(width: 8),
              Text(l10n.updatesAvailableDialogTitle),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.updatesAvailableDialogMessage(count)),
                const SizedBox(height: 12),
                UpdatePreviewHelper.previewBlock(
                  ctx,
                  l10n,
                  result,
                  heading: l10n.updatesAvailableDetectedListHeading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.postpone),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.download, size: 20),
              label: Text(l10n.applyNow),
            ),
          ],
        ),
      );
      if (apply == true && mounted) {
        _showTrayCheckUpdatesDialogWithResult(result);
      }
    });
  }

  void _showTrayCheckUpdatesDialogWithResult(Map<String, dynamic> initialResult) {
    if (!mounted) return;
    TrayService.showWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => TrayCheckUpdatesDialog(initialResult: initialResult),
      );
    });
  }

  Future<void> _showServicesGuide() async {
    if (!mounted) return;
    await showServicesGuideIfNeeded(context);
  }

  /// Cambio lingua dalle impostazioni: aggiorna il locale globale e, al
  /// frame successivo (dopo il rebuild con la nuova lingua), le etichette
  /// del menu tray — altrimenti il tray resterebbe nella lingua precedente.
  void _handleLocaleChanged(Locale? locale) {
    widget.onLocaleChanged?.call(locale);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initTray();
    });
  }

  void _initTray() {
    if (!mounted || !TrayService.isInitialized) return;
    final l10n = AppLocalizations.of(context)!;
    TrayService.setLabels(TrayMenuLabels(
      checkUpdates: l10n.trayCheckUpdates,
      cleanTempFilesAndCache: l10n.trayCleanTempFilesAndCache,
      system: l10n.traySystem,
      cpuGpuTemp: l10n.trayCpuGpuTemp,
      diskUsage: l10n.trayDiskUsage,
      memoryUsage: l10n.trayMemoryUsage,
      smartHealth: l10n.traySmartHealth,
      clipboard: l10n.trayClipboard,
      shutdownTimer: l10n.trayShutdownTimer,
      showMainWindow: l10n.trayShowMainWindow,
      cpuGpuUsage: l10n.trayCpuGpuUsage,
      battery: l10n.trayBattery,
      batteryHealth: l10n.trayBatteryHealth,
      chargeLimit: l10n.trayChargeLimit,
      powerProfile: l10n.trayPowerProfile,
      settings: l10n.traySettings,
      exit: l10n.trayExit,
    ));
    TrayService.setCallbacks(TrayCallbacks(
      onShowMainWindow: () => TrayService.showWindow(),
      onCheckUpdates: () => TrayService.launchStandaloneProcess(['--check-updates']),
      onShowCheckUpdatesDialog: () => TrayService.launchStandaloneProcess(['--check-updates']),
      onCleanTempFiles: () => _goToTab(2),
      onShowCleanCacheDialog: () => _showTrayCleanCacheDialog(),
      onShowCpuGpuTemp: () => _goToTab(4),
      onShowDiskUsage: () => _goToTab(5),
      onShowSmartHealth: () => _goToTab(6),
      onShowTaskManagerDialog: () => TrayService.launchStandaloneProcess(['--task-manager']),
      onShowShutdownTimerDialog: () => _showTrayShutdownTimerDialog(),
      onShowCpuGpuUsage: () => _goToTab(4),
      onShowClipboard: () => TrayService.launchStandaloneProcess(['--clipboard']),
      onShowBattery: () => _goToBatteryTab(),
      onShowSettings: () => _goToSettingsTab(),
      showSnackbar: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    ));
  }

  void _goToSettingsTab() {
    final count = _tabController?.length ?? 0;
    if (count >= 2) {
      _goToTab(count - 2);
    } else {
      _goToTab(0);
    }
  }

  /// Scheda Batteria: indice 9 in standard, 10 in advanced (Grub
  /// occupa indice 9 in advanced).
  void _goToBatteryTab() {
    _goToTab(_isAdvancedMode ? 10 : 9);
  }

  void _showTrayCheckUpdatesDialog() {
    if (!mounted) return;
    TrayService.showWindow();
    // Mostra subito il dialog di aggiornamento sistema (con caricamento)
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const TrayCheckUpdatesDialog(),
    );
    // Controlla GitHub in background e notifica via SnackBar se trovato
    _checkGitHubUpdateInBackground();
  }

  Future<void> _checkGitHubUpdateInBackground() async {
    final updateInfo = await AppSelfUpdateService.checkForUpdate();
    if (!mounted || updateInfo == null) return;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New version ${updateInfo["latestVersion"]} available!'),
        action: SnackBarAction(label: 'Update', onPressed: () {
          showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AppUpdateDialog(updateInfo: updateInfo),
          );
        }),
        duration: const Duration(seconds: 10),
      ),
    );
  }

  void _showTrayShutdownTimerDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => _TrayShutdownTimerDialog(),
    );
  }

  void _showTrayCleanCacheDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => _TrayCleanCacheDialog(),
    );
  }

  void _showTrayTaskManagerDialog() {
    if (!mounted) return;
    TrayService.showWindow();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        builder: (ctx) => const TrayTaskManagerDialog(),
      );
    });
  }

  void _goToTab(int index) {
    TrayService.showWindow();
    if (_tabController != null && index < _tabController!.length) {
      _tabController!.animateTo(index);
    }
  }

  Future<void> _initializeController() async {
    _tabController?.dispose();
    _tabController = null;
    final prefs = await SharedPreferences.getInstance();
    final bool effectiveAdvanced;
    if (isStandardBuild) {
      effectiveAdvanced = false;
    } else if (isPersonalBuild) {
      effectiveAdvanced = true;
      _licenseActivated = true;
    } else {
      _licenseActivated = await isActivated();
      effectiveAdvanced = _licenseActivated && (prefs.getBool('advancedMode') ?? false);
    }
    final tabCount = effectiveAdvanced ? _advancedTabCount : _standardTabCount;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
    );
    setState(() {
      _isAdvancedMode = effectiveAdvanced;
      _isLoading = false;
    });
  }

  Future<void> _openLicenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => LicenseActivationDialog(
        onActivated: () {},
      ),
    );
    if (result == true && mounted) await _initializeController();
  }

  Future<void> _setMode(bool advanced) async {
    if (_isAdvancedMode == advanced) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advancedMode', advanced);
    
    final currentIndex = _tabController?.index ?? 0;
    _tabController?.dispose();
    
    final tabCount = advanced ? _advancedTabCount : _standardTabCount;
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: currentIndex < tabCount ? currentIndex : 0,
    );
    setState(() {
      _isAdvancedMode = advanced;
    });
  }

  void _releaseMainUiForTray() {
    if (!mounted || _tabController == null || _isLoading) return;
    if (_tabController!.index != 0) {
      _tabController!.index = 0;
    }
  }

  @override
  void dispose() {
    AppMemoryMaintenance.onMainWindowHiddenToTray = null;
    _updateCheckTimer?.cancel();
    _ramCleanupTimer?.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  static const _servicesIcon = FeatureIconData(
    icon: Icons.speed, color: Colors.blue,
  );
  static const _startupAppsIcon = FeatureIconData(
    icon: Icons.apps, color: Colors.green,
  );
  static const _cleanupIcon = FeatureIconData(
    icon: Icons.cleaning_services, color: Colors.orange,
  );
  static const _installedAppsIcon = FeatureIconData(
    icon: Icons.inventory_2, color: Colors.purple,
  );
  static const _monitorIcon = FeatureIconData(
    icon: Icons.monitor, color: Colors.red,
  );
  static const _diskAnalyzerIcon = FeatureIconData(
    icon: Icons.analytics, color: Colors.teal,
  );
  static const _smartIcon = FeatureIconData(
    icon: Icons.health_and_safety, color: Colors.amber,
  );
  static const _settingsIcon = FeatureIconData(
    icon: Icons.settings, color: Colors.blueGrey,
  );
  static const _infoIcon = FeatureIconData(
    icon: Icons.info, color: Colors.indigo,
  );
  static const _grubIcon = FeatureIconData(
    icon: Icons.edit, color: Colors.deepOrange,
  );
  static const _recoveryIcon = FeatureIconData(
    icon: Icons.healing, color: Colors.cyan,
  );
  static const _batteryIcon = FeatureIconData(
    icon: Icons.battery_charging_full, color: Colors.green,
  );
  static const _tweaksIcon = FeatureIconData(
    icon: Icons.tune, color: Colors.pink,
  );
  static const _deviceManagerIcon = FeatureIconData(
    icon: Icons.devices_other, color: Colors.teal,
  );
  static const _driverManagerIcon = FeatureIconData(
    icon: Icons.download, color: Colors.cyan,
  );

  List<Widget> _buildTabViews() {
    Widget page(Widget child) => TabPageNoKeepAlive(child: child);

    final views = <Widget>[
      page(const ServicesScreen()),
      page(const StartupAppsScreen()),
      page(const CleanupScreen()),
      page(const InstalledAppsScreen()),
      page(const SystemMonitorScreen()),
      page(const DiskAnalyzerScreen()),
      page(const SmartMonitorScreen()),
      page(const DeviceManagerScreen()),
      page(const DriverManagerScreen()),
      page(const RecoveryScreen()),
      page(const BatteryScreen()),
    ];

    if (_isAdvancedMode) {
      views.insert(9, page(const GrubEditorScreen()));
    }

    views.add(page(TweaksScreen(isAdvanced: _isAdvancedMode)));
    views.add(page(SettingsScreen(
      onThemeModeChanged: widget.onThemeModeChanged,
      onLocaleChanged: _handleLocaleChanged,
      onFontChanged: widget.onFontChanged,
      onUpdateCheckPolicyChanged: _startUpdateCheckTimer,
      onRamCleanupPolicyChanged: _startRamCleanupTimer,
    )));
    views.add(page(InfoScreen(
      onLicenseActivated: isAdvancedBuild ? _initializeController : null,
    )));

    return views;
  }

  List<_NavEntry> _navEntries() {
    final l10n = AppLocalizations.of(context)!;
    final entries = <_NavEntry>[
      _NavEntry(_servicesIcon, l10n.tabServices),
      _NavEntry(_startupAppsIcon, l10n.tabStartupApps),
      _NavEntry(_cleanupIcon, l10n.tabCleanup),
      _NavEntry(_installedAppsIcon, l10n.tabInstalledApps),
      _NavEntry(_monitorIcon, l10n.tabMonitor),
      _NavEntry(_diskAnalyzerIcon, l10n.tabDiskAnalyzer),
      _NavEntry(_smartIcon, l10n.tabSmart),
      _NavEntry(_deviceManagerIcon, l10n.tabDeviceManager),
      _NavEntry(_driverManagerIcon, l10n.tabDriverManager),
      _NavEntry(_recoveryIcon, l10n.tabRecovery),
      _NavEntry(_batteryIcon, l10n.tabBattery),
    ];

    if (_isAdvancedMode) {
      entries.insert(9, _NavEntry(_grubIcon, l10n.tabGrub));
    }

    entries.add(_NavEntry(_tweaksIcon, l10n.tabTweaks));
    entries.add(_NavEntry(_settingsIcon, l10n.tabSettings));
    entries.add(_NavEntry(_infoIcon, l10n.tabInfo));

    return entries;
  }

  Widget _buildSidebar() {
    final entries = _navEntries();
    final selectedIndex = _tabController?.index ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: isSelected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.6)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _tabController?.animateTo(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            FeatureIcon(data: entry.icon, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStandardBuild)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          AppLocalizations.of(context)!.modeStandard,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.system_update,
                            size: 20, color: Colors.blue),
                        tooltip: AppLocalizations.of(context)!.appCheckForUpdates,
                        onPressed: _showTrayCheckUpdatesDialog,
                      ),
                    ],
                  )
                else if (isPersonalBuild)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Personal / Test',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  )
                else if (!_licenseActivated)
                  ElevatedButton.icon(
                    onPressed: _openLicenseDialog,
                    icon: const Icon(Icons.lock_open, size: 18),
                    label: Text(AppLocalizations.of(context)!.licenseActivatePremium),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  )
                else ...[
                  ElevatedButton.icon(
                    onPressed: () => _setMode(false),
                    icon: const Icon(Icons.dashboard, size: 18),
                    label: Text(AppLocalizations.of(context)!.modeStandard),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_isAdvancedMode
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _setMode(true),
                    icon: const Icon(Icons.build, size: 18),
                    label: Text(AppLocalizations.of(context)!.modeAdvanced),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAdvancedMode
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: TabBarView(
              controller: _tabController!,
              children: _buildTabViews(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavEntry {
  final FeatureIconData icon;
  final String label;
  const _NavEntry(this.icon, this.label);
}

class TrayCheckUpdatesDialog extends StatefulWidget {
  final Map<String, dynamic>? initialResult;

  const TrayCheckUpdatesDialog({this.initialResult});

  @override
  State<TrayCheckUpdatesDialog> createState() => TrayCheckUpdatesDialogState();
}

class TrayCheckUpdatesDialogState extends State<TrayCheckUpdatesDialog> {
  bool _loading = true;
  bool _applyingUpdates = false;
  Map<String, dynamic>? _result;
  double _applyProgress = 0;
  String? _applyStatus;
  String _applyLog = '';
  List<String> _applyPendingPackages = [];
  List<String> _installableLabels = [];
  List<String> _rawUpdates = [];
  Set<int> _selectedIndices = {};
  Set<int> _kernelIndices = {};
  String _checkStatus = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
      _loading = false;
      _initSelection();
    } else {
      _runCheck();
    }
  }

  void _initSelection() {
    final raw = _result?['updates'];
    _rawUpdates = raw is List ? raw.map((e) => e.toString()).toList() : [];
    final labels = _result?['updateInstallableLabels'] as List? ?? [];
    _installableLabels = labels.map((e) => e.toString()).toList();

    // Identifica indici dei pacchetti kernel
    final kernelRaws = _result?['kernelUpdates'] as List? ?? [];
    _kernelIndices = {};
    for (int i = 0; i < _rawUpdates.length; i++) {
      final rawName = _rawUpdates[i].trim().split(RegExp(r'\s+')).first;
      if (kernelRaws.contains(rawName)) {
        _kernelIndices.add(i);
      }
    }

    // Seleziona tutto tranne i kernel (l'utente deve scegliere esplicitamente)
    _selectedIndices = Set.from(List.generate(
      _installableLabels.length,
      (i) => i,
    ))..removeAll(_kernelIndices);
  }

  Future<void> _runCheck() async {
    setState(() => _checkStatus = 'Restoring repositories...');
    // Run check asynchronously: update status while waiting
    Future.delayed(const Duration(milliseconds: 50)).then((_) {
      if (mounted) setState(() => _checkStatus = 'Checking for updates...');
    });
    final result = await RecoveryService.checkForUpdates();
    if (mounted) {
      setState(() {
        _loading = false;
        _result = result;
        _initSelection();
      });
    }
  }

  void _toggleSelectAll() {
    // Se tutti i non-kernel sono già selezionati → deseleziona tutti
    // Altrimenti → seleziona tutti i non-kernel
    final allNonKernelSelected = _kernelIndices.length + _selectedIndices.length >= _installableLabels.length;
    if (allNonKernelSelected) {
      setState(() {
        _selectedIndices = Set<int>.from(_kernelIndices);
      });
    } else {
      setState(() {
        _selectedIndices = Set.from(List.generate(_installableLabels.length, (i) => i))
          ..removeAll(_kernelIndices);
      });
    }
  }

  String _sourceForIndex(int i) {
    if (i >= _rawUpdates.length) return '';
    final raw = _rawUpdates[i];
    // Flatpak ref: app/org.name/x86_64/stable
    if (raw.startsWith('app/') || raw.startsWith('runtime/') || raw.startsWith('system/')) return 'Flatpak';
    // DNF: package.arch  version  repo
    if (RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]*\.[a-zA-Z]+\s+').hasMatch(raw)) return 'DNF';
    // Pacman: package-name  version -> version (Arch/Manjaro/EndeavourOS)
    if (raw.contains(RegExp(r'\s+\S+\s+->\s+'))) return 'Pacman';
    // APT: simple name or name/repo version
    if (raw.contains('/') || !raw.contains(' ')) return 'APT';
    // Snap: name  version
    if (raw.contains(RegExp(r'\s+\d+\.\d+'))) return 'Snap';
    return 'APT';
  }

  Color _colorForSource(String source) {
    switch (source) {
      case 'APT': return Colors.blue;
      case 'DNF': return Colors.orange;
      case 'Pacman': return Colors.purple;
      case 'Snap': return Colors.red;
      case 'Flatpak': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _performUpdates() async {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedIndices.isEmpty) return;

    final allSelected = _selectedIndices.length == _installableLabels.length;
    final pending = allSelected
        ? List<String>.from(_rawUpdates)
        : _selectedIndices.map((i) => _rawUpdates[i]).toList();

    final expectedCount = (_result?['updateCount'] as int?) ?? pending.length;
    final confirm = allSelected || _selectedIndices.length <= 1
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.recoveryPerformUpdates),
              content: Text('${AppLocalizations.of(context)!.recoveryPerformUpdatesConfirm} (${_selectedIndices.length} ${AppLocalizations.of(context)!.updateCheckSummaryPackageCount(_selectedIndices.length).split(' ').last})'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.confirm)),
              ],
            ),
          );
    if (confirm != true || !mounted) return;

    setState(() {
      _applyingUpdates = true;
      _applyProgress = 0;
      _applyStatus = null;
      _applyLog = '';
      _applyPendingPackages = List<String>.from(pending);
    });
    try {
      final result = await RecoveryService.performUpdates(
        expectedPackageCount: expectedCount,
        selectedUpdates: allSelected ? null : pending,
        onOutput: (data) {
          if (!mounted) return;
          setState(() {
            _applyLog += data;
            if (_applyLog.length > 12000) {
              _applyLog = _applyLog.substring(_applyLog.length - 12000);
            }
          });
        },
        onProgress: (p, label) {
          if (!mounted) return;
          setState(() {
            _applyProgress = p;
            _applyStatus = label;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _applyingUpdates = false;
        if (result['success'] == true) {
          _result = {
            'success': true,
            'updateCount': 0,
            'summaryPackageCount': 0,
            'updateReport': <String, dynamic>{},
            'updates': <String>[],
            'updateInstallableLabels': <String>[],
            'updatePhasedLabels': <String>[],
          };
        }
      });
      final message = result['success'] == true ? l10n.recoveryCheckUpdatesComplete : (result['error']?.toString() ?? result['message']?.toString() ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _applyingUpdates = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasUpdates = _result != null &&
        _result!['success'] == true &&
        (_result!['updateCount'] as int? ?? 0) > 0;
    final reportMap = _result?['updateReport'] as Map<String, dynamic>?;
    final detailText = _result?['success'] == true
        ? UpdateCheckReportFormatter.format(l10n, reportMap)
        : '';
    final legacyOutput = _result?['output'] as String?;
    final boxText = detailText.isNotEmpty
        ? detailText
        : (legacyOutput?.isNotEmpty == true ? legacyOutput! : '');
    final showDetailBox = boxText.isNotEmpty;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          const SizedBox(width: 8),
          Text(l10n.trayCheckUpdates),
        ],
      ),
      content: SizedBox(
        width: _applyingUpdates ? 520 : 480,
        child: _loading || _applyingUpdates
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: _loading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          if (_checkStatus.isNotEmpty)
                            Text(_checkStatus,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      )
                    : UpdatesApplyProgressView(
                        progress: _applyProgress,
                        statusLabel: _applyStatus,
                        pendingPackages: _applyPendingPackages,
                        logText: _applyLog.isEmpty ? null : _applyLog,
                        maxPackagesHeight: 120,
                        maxLogHeight: 140,
                      ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_result != null) ...[
                      Text(
                        _result!['success'] == true
                            ? l10n.recoveryCheckUpdatesComplete
                            : l10n.recoveryCheckUpdatesError(_result!['error']?.toString() ?? ''),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _result!['success'] == true ? Colors.green : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      if (_result!['updateCount'] != null ||
                          _result!['summaryPackageCount'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.updateCheckSummaryPackageCount(
                            (_result!['summaryPackageCount'] as int?) ??
                                (_result!['updateCount'] as int? ?? 0),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (_result!['success'] == true && _installableLabels.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(l10n.updatesCheckPreviewHeading,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _toggleSelectAll,
                              child: Text(
                                l10n.selectAll,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                            const SizedBox(height: 4),
                            if (_kernelIndices.isNotEmpty)
                              Text(
                                '${_kernelIndices.length} aggiornament${_kernelIndices.length == 1 ? 'o' : 'i'} kernel non selezionat${_kernelIndices.length == 1 ? 'o' : 'i'} (richiede riavvio)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.deepOrange.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _installableLabels.length,
                            itemBuilder: (ctx, i) {
                              final label = _installableLabels[i];
                              final checked = _selectedIndices.contains(i);
                              final isKernel = _kernelIndices.contains(i);
                              final source = isKernel ? 'KERNEL' : _sourceForIndex(i);
                              final sourceColor = isKernel ? Colors.deepOrange : _colorForSource(source);
                              return CheckboxListTile(
                                dense: true,
                                value: checked,
                                onChanged: (v) {
                                  if (isKernel && v == true) {
                                    // Chiede conferma per kernel
                                    showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Aggiornamento kernel'),
                                        content: const Text(
                                          'L\'aggiornamento del kernel richiede un riavvio del sistema. '
                                          'Proseguire?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text(AppLocalizations.of(context)!.cancel),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text(AppLocalizations.of(context)!.confirm),
                                          ),
                                        ],
                                      ),
                                    ).then((confirm) {
                                      if (confirm == true && mounted) {
                                        setState(() {
                                          if (v == true) {
                                            _selectedIndices.add(i);
                                          } else {
                                            _selectedIndices.remove(i);
                                          }
                                        });
                                      }
                                    });
                                  } else {
                                    setState(() {
                                      if (v == true) {
                                        _selectedIndices.add(i);
                                      } else {
                                        _selectedIndices.remove(i);
                                      }
                                    });
                                  }
                                },
                                title: Row(
                                  children: [
                                    if (isKernel) ...[
                                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.deepOrange),
                                      const SizedBox(width: 4),
                                    ],
                                    Flexible(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  ],
                                ),
                                subtitle: Text(source, style: TextStyle(
                                  fontSize: 11,
                                  color: sourceColor,
                                  fontWeight: isKernel ? FontWeight.bold : FontWeight.normal,
                                )),
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                              );
                            },
                          ),
                        ),
                      ],
                      if (hasUpdates && _selectedIndices.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _performUpdates,
                          icon: const Icon(Icons.download),
                          label: Text('${l10n.recoveryPerformUpdates} (${_selectedIndices.length})'),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (showDetailBox) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            boxText,
                            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _applyingUpdates ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _TrayCleanCacheDialog extends StatefulWidget {
  @override
  State<_TrayCleanCacheDialog> createState() => _TrayCleanCacheDialogState();
}

class _TrayCleanCacheDialogState extends State<_TrayCleanCacheDialog> {
  bool _loading = false;
  bool? _success;
  String? _message;

  Future<void> _runCleanup() async {
    setState(() { _loading = true; _success = null; _message = null; });
    try {
      final result = await CleanupService.dropLinuxCache();
      if (mounted) {
        setState(() {
          _loading = false;
          _success = result['success'] == true;
          _message = result['message']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _success = false;
          _message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cleaning_services),
          const SizedBox(width: 8),
          Text(l10n.trayCleanLinuxCache),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.cleanupLinuxCacheDesc,
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85)),
            ),
            if (_loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_success != null && !_loading) ...[
              const SizedBox(height: 16),
              Text(
                _success! ? l10n.cleanupLinuxCacheSuccess : l10n.cleanupLinuxCacheError,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _success! ? Colors.green : Theme.of(context).colorScheme.error,
                ),
              ),
              if (_message != null && _message!.isNotEmpty && !_success!) ...[
                const SizedBox(height: 8),
                SelectableText(_message!, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (_success == null && !_loading)
          FilledButton.icon(
            onPressed: _runCleanup,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.cleanupLinuxCache),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _TrayShutdownTimerDialog extends StatefulWidget {
  @override
  State<_TrayShutdownTimerDialog> createState() => _TrayShutdownTimerDialogState();
}

class _TrayShutdownTimerDialogState extends State<_TrayShutdownTimerDialog> {
  bool _isLoading = false;
  bool _systemdAvailable = false;
  Map<String, Map<String, dynamic>> _timerStatuses = {};
  String _selectedScheduleType = 'daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 22, minute: 0);
  Set<int> _selectedDaysOfWeek = {};
  int? _selectedDayOfMonth;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSystemd();
    _loadTimerStatuses();
  }

  Future<void> _checkSystemd() async {
    final available = await ShutdownSchedulerService.isSystemdAvailable();
    if (mounted) setState(() => _systemdAvailable = available);
  }

  Future<void> _loadTimerStatuses() async {
    if (!_systemdAvailable) return;
    setState(() => _isLoading = true);
    try {
      final timers = await ShutdownSchedulerService.getAllTimers();
      final statuses = <String, Map<String, dynamic>>{};
      for (final t in timers) statuses[t['type'] as String] = t;
      for (final type in ['daily', 'weekly', 'monthly']) {
        if (!statuses.containsKey(type)) {
          statuses[type] = await ShutdownSchedulerService.getTimerStatus(type);
        }
      }
      if (mounted) setState(() { _timerStatuses = statuses; _isLoading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _createTimer() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await PasswordStorage.hasPassword()) {
      setState(() => _error = l10n.shutdownPasswordRequired);
      return;
    }
    if (_selectedScheduleType == 'weekly' && _selectedDaysOfWeek.isEmpty) {
      setState(() => _error = l10n.shutdownWeeklyDaysRequired);
      return;
    }
    if (_selectedScheduleType == 'monthly' && _selectedDayOfMonth == null) {
      setState(() => _error = l10n.shutdownMonthlyDayRequired);
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      final existing = _timerStatuses[_selectedScheduleType];
      if (existing != null && existing['exists'] == true) {
        await ShutdownSchedulerService.removeShutdownTimer(_selectedScheduleType);
      }
      await ShutdownSchedulerService.createShutdownTimer(
        scheduleType: _selectedScheduleType,
        time: timeStr,
        daysOfWeek: _selectedScheduleType == 'weekly' ? _selectedDaysOfWeek.toList() : null,
        dayOfMonth: _selectedScheduleType == 'monthly' ? _selectedDayOfMonth : null,
      );
      await _loadTimerStatuses();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shutdownTimerCreated), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeTimer(String scheduleType) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirm),
        content: Text(l10n.shutdownRemoveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      await ShutdownSchedulerService.removeShutdownTimer(scheduleType);
      await _loadTimerStatuses();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.shutdownTimerRemoved), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getScheduleTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'daily': return l10n.shutdownScheduleDaily;
      case 'weekly': return l10n.shutdownScheduleWeekly;
      case 'monthly': return l10n.shutdownScheduleMonthly;
      default: return type;
    }
  }

  String _getDayName(int day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 0: return l10n.shutdownDaySunday;
      case 1: return l10n.shutdownDayMonday;
      case 2: return l10n.shutdownDayTuesday;
      case 3: return l10n.shutdownDayWednesday;
      case 4: return l10n.shutdownDayThursday;
      case 5: return l10n.shutdownDayFriday;
      case 6: return l10n.shutdownDaySaturday;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.schedule),
          const SizedBox(width: 8),
          Text(l10n.tabShutdownScheduler),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: !_systemdAvailable
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 12),
                  Text(l10n.shutdownSystemdRequired, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(l10n.shutdownSystemdRequiredDesc, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8))),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontSize: 12)),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(l10n.shutdownActiveTimers, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ..._timerStatuses.entries.map((e) {
                      final type = e.key;
                      final status = e.value;
                      if (status['exists'] != true) return const SizedBox.shrink();
                      final nextRun = status['nextRun'] as String?;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(status['active'] == true ? Icons.check_circle : Icons.schedule, color: status['active'] == true ? Colors.green : null, size: 20),
                          title: Text(_getScheduleTypeName(type), style: const TextStyle(fontSize: 13)),
                          subtitle: nextRun != null ? Text('${l10n.shutdownNextRun}: $nextRun', style: const TextStyle(fontSize: 11)) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: _isLoading ? null : () => _removeTimer(type),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(l10n.shutdownCreateTimer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(l10n.shutdownScheduleType, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    const SizedBox(height: 4),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'daily', label: Text(l10n.shutdownScheduleDaily)),
                        ButtonSegment(value: 'weekly', label: Text(l10n.shutdownScheduleWeekly)),
                        ButtonSegment(value: 'monthly', label: Text(l10n.shutdownScheduleMonthly)),
                      ],
                      selected: {_selectedScheduleType},
                      onSelectionChanged: (s) => setState(() { _selectedScheduleType = s.first; _selectedDaysOfWeek.clear(); _selectedDayOfMonth = null; }),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.access_time, size: 20),
                      title: Text(l10n.shutdownSelectTime),
                      subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _selectedTime);
                        if (picked != null) setState(() => _selectedTime = picked);
                      },
                    ),
                    if (_selectedScheduleType == 'weekly') ...[
                      Text(l10n.shutdownSelectDays, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: List.generate(7, (i) => FilterChip(
                          label: Text(_getDayName(i)),
                          selected: _selectedDaysOfWeek.contains(i),
                          onSelected: (sel) => setState(() { if (sel) _selectedDaysOfWeek.add(i); else _selectedDaysOfWeek.remove(i); }),
                        )),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (_selectedScheduleType == 'monthly') ...[
                      Text(l10n.shutdownSelectDayOfMonth, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: _selectedDayOfMonth,
                        decoration: InputDecoration(labelText: l10n.shutdownDayOfMonth, border: const OutlineInputBorder(), isDense: true),
                        items: List.generate(31, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                        onChanged: (v) => setState(() => _selectedDayOfMonth = v),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createTimer,
                      icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add, size: 20),
                      label: Text(l10n.shutdownCreateTimer),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.close)),
      ],
    );
  }
}

