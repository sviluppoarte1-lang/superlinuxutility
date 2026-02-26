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
import 'kernel_list_screen.dart';
import 'info_screen.dart';
import 'settings_screen.dart';
import 'disk_analyzer_screen.dart';
import 'recovery_screen.dart';
import 'shutdown_scheduler_screen.dart';
import 'dart:io';
import '../services/tray_service.dart';
import '../services/recovery_service.dart';
import '../services/shutdown_scheduler_service.dart';
import '../services/password_storage.dart';
import '../services/cleanup_service.dart';

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

  static const int _standardTabCount = 8;
  static const int _advancedTabCount = 11;

  @override
  void initState() {
    super.initState();
    _initializeController();
    if (Platform.isLinux) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initTray());
    }
  }

  void _initTray() {
    if (!mounted || !TrayService.isInitialized) return;
    final l10n = AppLocalizations.of(context)!;
    TrayService.setLabels(TrayMenuLabels(
      checkUpdates: l10n.trayCheckUpdates,
      cleanLinuxCache: l10n.trayCleanLinuxCache,
      removeTempFiles: l10n.trayRemoveTempFiles,
      cpuGpuTemp: l10n.trayCpuGpuTemp,
      diskUsage: l10n.trayDiskUsage,
      memoryUsage: l10n.trayMemoryUsage,
      shutdownTimer: l10n.trayShutdownTimer,
      showMainWindow: l10n.trayShowMainWindow,
      cpuGpuUsage: l10n.trayCpuGpuUsage,
      exit: l10n.trayExit,
    ));
    TrayService.setCallbacks(TrayCallbacks(
      onShowMainWindow: () => TrayService.showWindow(),
      onCheckUpdates: () => _goToTab(8),
      onShowCheckUpdatesDialog: () => _showTrayCheckUpdatesDialog(),
      onCleanLinuxCache: () {},
      onShowCleanCacheDialog: () => _showTrayCleanCacheDialog(),
      onCleanTempFiles: () => _goToTab(2),
      onShowCpuGpuTemp: () => _goToTab(4),
      onShowDiskUsage: () => _goToTab(5),
      onShowMemoryUsage: () => _goToTab(4),
      onShowShutdownTimerDialog: () => _showTrayShutdownTimerDialog(),
      onShowCpuGpuUsage: () => _goToTab(4),
      showSnackbar: (msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        }
      },
    ));
  }

  void _showTrayCheckUpdatesDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TrayCheckUpdatesDialog(),
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

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  List<Widget> _buildTabs() {
    final l10n = AppLocalizations.of(context)!;
    final tabs = <Widget>[
      Tab(icon: const Icon(Icons.speed), text: l10n.tabServices),
      Tab(icon: const Icon(Icons.apps), text: l10n.tabStartupApps),
      Tab(icon: const Icon(Icons.cleaning_services), text: l10n.tabCleanup),
      Tab(icon: const Icon(Icons.inventory_2), text: l10n.tabInstalledApps),
      Tab(icon: const Icon(Icons.monitor), text: l10n.tabMonitor),
      Tab(icon: const Icon(Icons.analytics), text: l10n.tabDiskAnalyzer),
    ];

    if (_isAdvancedMode) {
      tabs.insert(6, Tab(icon: const Icon(Icons.edit), text: l10n.tabGrub));
      tabs.insert(7, Tab(icon: const Icon(Icons.memory), text: l10n.tabKernel));
      tabs.insert(8, Tab(icon: const Icon(Icons.healing), text: l10n.tabRecovery));
    }

    tabs.add(Tab(icon: const Icon(Icons.settings), text: l10n.tabSettings));
    tabs.add(Tab(icon: const Icon(Icons.info), text: l10n.tabInfo));

    return tabs;
  }

  List<Widget> _buildTabViews() {
    final views = <Widget>[
      const ServicesScreen(),
      const StartupAppsScreen(),
      const CleanupScreen(),
      const InstalledAppsScreen(),
      const SystemMonitorScreen(),
      const DiskAnalyzerScreen(),
    ];

    if (_isAdvancedMode) {
      views.insert(6, const GrubEditorScreen());
      views.insert(7, const KernelListScreen());
      views.insert(8, const RecoveryScreen());
    }

    views.add(SettingsScreen(
      onThemeModeChanged: widget.onThemeModeChanged,
      onLocaleChanged: widget.onLocaleChanged,
      onFontChanged: widget.onFontChanged,
    ));
    views.add(InfoScreen(
      onLicenseActivated: isAdvancedBuild ? _initializeController : null,
    ));

    return views;
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
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      AppLocalizations.of(context)!.modeStandard,
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
        bottom: TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabs: _buildTabs(),
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: _buildTabViews(),
      ),
    );
  }
}

class _TrayCheckUpdatesDialog extends StatefulWidget {
  @override
  State<_TrayCheckUpdatesDialog> createState() => _TrayCheckUpdatesDialogState();
}

class _TrayCheckUpdatesDialogState extends State<_TrayCheckUpdatesDialog> {
  bool _loading = true;
  bool _applyingUpdates = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _runCheck();
  }

  Future<void> _runCheck() async {
    final result = await RecoveryService.checkForUpdates();
    if (mounted) {
      setState(() {
        _loading = false;
        _result = result;
      });
    }
  }

  Future<void> _performUpdates() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recoveryPerformUpdates),
        content: Text(l10n.recoveryPerformUpdatesConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.confirm)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _applyingUpdates = true);
    try {
      final result = await RecoveryService.performUpdates();
      if (!mounted) return;
      setState(() {
        _applyingUpdates = false;
        if (result['success'] == true) {
          _result = {'success': true, 'updateCount': 0, 'output': _result?['output'] ?? ''};
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

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update),
          const SizedBox(width: 8),
          Text(l10n.trayCheckUpdates),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _loading || _applyingUpdates
            ? Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (_applyingUpdates) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.recoveryPerformUpdates,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8)),
                      ),
                    ],
                  ],
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
                      if (_result!['updateCount'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_result!['updateCount']} ${l10n.package}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (hasUpdates) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _performUpdates,
                          icon: const Icon(Icons.download),
                          label: Text(l10n.recoveryPerformUpdates),
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_result!['output'] != null && (_result!['output'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _result!['output'] as String,
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

