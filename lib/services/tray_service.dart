import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:system_tray/system_tray.dart';
import 'package:flutter/services.dart';
import 'system_monitor.dart';

class TrayMenuLabels {
  final String checkUpdates;
  final String cleanTempFilesAndCache;
  final String cpuGpuTemp;
  final String diskUsage;
  final String memoryUsage;
  final String shutdownTimer;
  final String showMainWindow;
  final String cpuGpuUsage;
  final String exit;
  const TrayMenuLabels({
    required this.checkUpdates,
    required this.cleanTempFilesAndCache,
    required this.cpuGpuTemp,
    required this.diskUsage,
    required this.memoryUsage,
    required this.shutdownTimer,
    required this.showMainWindow,
    required this.cpuGpuUsage,
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
  final void Function()? onShowShutdownTimerDialog;
  final void Function()? onShowCleanCacheDialog;
  final void Function()? onShowCpuGpuUsage;
  final void Function(String message)? showSnackbar;

  TrayCallbacks({
    this.onShowMainWindow,
    this.onCheckUpdates,
    this.onShowCheckUpdatesDialog,
    this.onCleanTempFiles,
    this.onShowCpuGpuTemp,
    this.onShowDiskUsage,
    this.onShowTaskManagerDialog,
    this.onShowShutdownTimerDialog,
    this.onShowCleanCacheDialog,
    this.onShowCpuGpuUsage,
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
  static Timer? _menuUpdateTimer;
  static String _tempLabel = '';
  static String _usageLabel = '';
  static String _diskUsageLabel = '';
  static String _memoryUsageLabel = '';

  static bool get isInitialized => _initialized;
  static String? get lastError => _lastError;

  static TrayCallbacks? get callbacks => _callbacks;

  static void setCallbacks(TrayCallbacks c) {
    _callbacks = c;
  }

  static void setLabels(TrayMenuLabels labels) {
    _labels = labels;
    _buildMenuWithStats();
    _startMenuUpdateTimer();
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
      await _buildMenuWithStats();
      _startMenuUpdateTimer();
      _systemTray!.registerSystemTrayEventHandler((eventName) {
        if (eventName == kSystemTrayEventClick) {
          _appWindow?.show();
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
    _menuUpdateTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final info = await SystemMonitor.getSystemInfo();
        final cpuTemp = await SystemMonitor.getCpuTemperature();
        final homeDisk = await SystemMonitor.getHomeDiskUsage();
        final cpuUsage = info.cpu.usagePercent;
        final gpuUsage = info.gpu?.usagePercent;
        final gpuTemp = info.gpu?.temperature;
        final cpuStr = cpuTemp != null ? '${cpuTemp.toStringAsFixed(0)}°C' : '-';
        final gpuStr = gpuTemp != null ? '${gpuTemp.toStringAsFixed(0)}°C' : '-';
        _tempLabel = 'CPU: $cpuStr | GPU: $gpuStr';
        String u = '${cpuUsage.toStringAsFixed(0)}%';
        if (gpuUsage != null) u += ' | ${gpuUsage.toStringAsFixed(0)}%';
        _usageLabel = u;
        if (homeDisk != null) {
          final p = (homeDisk['usedPercent'] as num).toStringAsFixed(0);
          _diskUsageLabel = '${p}% (${homeDisk['usedStr']}/${homeDisk['totalStr']})';
        } else {
          _diskUsageLabel = '';
        }
        final memFree = await SystemMonitor.getMemoryFromFreeForTray();
        if (memFree != null) {
          final pct = (memFree['usedPercent'] as num).toStringAsFixed(0);
          _memoryUsageLabel = '${pct}% (${memFree['usedStr']} / ${memFree['totalStr']})';
        } else {
          _memoryUsageLabel = '';
        }
        await _buildMenuWithStats();
      } catch (_) {}
    });
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

  static Future<void> _buildMenuWithStats() async {
    if (_systemTray == null) return;
    final l = _labels ?? const TrayMenuLabels(
      checkUpdates: 'Verifica aggiornamenti di sistema',
      cleanTempFilesAndCache: 'Pulisci file temporanei e cache',
      cpuGpuTemp: 'Temperatura CPU, GPU',
      diskUsage: 'Uso del disco',
      memoryUsage: 'Uso memoria RAM',
      shutdownTimer: 'Spegnimento automatico',
      showMainWindow: 'Visualizza schermata principale',
      cpuGpuUsage: 'Uso CPU, GPU',
      exit: 'Esci',
    );
    final tempLabel = _tempLabel.isEmpty ? l.cpuGpuTemp : '${l.cpuGpuTemp}: $_tempLabel';
    final usageLabel = _usageLabel.isEmpty ? l.cpuGpuUsage : '${l.cpuGpuUsage}: $_usageLabel';
    final diskLabel = _diskUsageLabel.isEmpty ? l.diskUsage : '${l.diskUsage}: $_diskUsageLabel';
    final memoryLabel = _memoryUsageLabel.isEmpty ? l.memoryUsage : '${l.memoryUsage}: $_memoryUsageLabel';
    final menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: l.checkUpdates, onClicked: (_) => _onCheckUpdates()),
      MenuItemLabel(label: l.cleanTempFilesAndCache, onClicked: (_) => _onCleanTempFiles()),
      MenuItemLabel(label: tempLabel, onClicked: (_) {
        _callbacks?.onShowCpuGpuTemp?.call();
        _appWindow?.show();
      }),
      MenuItemLabel(label: diskLabel, onClicked: (_) {
        _callbacks?.onShowDiskUsage?.call();
        _appWindow?.show();
      }),
      MenuItemLabel(label: memoryLabel, onClicked: (_) {
        _callbacks?.onShowTaskManagerDialog?.call();
        _appWindow?.show();
      }),
      MenuItemLabel(label: l.shutdownTimer, onClicked: (_) => _onShutdownTimer()),
      MenuSeparator(),
      MenuItemLabel(
        label: l.showMainWindow,
        onClicked: (_) {
          _callbacks?.onShowMainWindow?.call();
          _appWindow?.show();
        },
      ),
      MenuItemLabel(label: usageLabel, onClicked: (_) {
        _callbacks?.onShowCpuGpuUsage?.call();
        _appWindow?.show();
      }),
      MenuSeparator(),
      MenuItemLabel(label: l.exit, onClicked: (_) => _onExit()),
    ]);
    await _systemTray!.setContextMenu(menu);
  }

  static void _onExit() {
    SystemNavigator.pop();
  }

  static void _onCheckUpdates() {
    _appWindow?.show();
    if (_callbacks?.onShowCheckUpdatesDialog != null) {
      _callbacks!.onShowCheckUpdatesDialog!();
    } else {
      _callbacks?.onCheckUpdates?.call();
    }
  }

  static void _onShutdownTimer() {
    _appWindow?.show();
    _callbacks?.onShowShutdownTimerDialog?.call();
  }

  /// Se true, la CleanupScreen eseguirà la pulizia al primo frame (apertura da tray).
  static bool runCleanupWhenScreenShown = false;

  static void _onCleanTempFiles() {
    runCleanupWhenScreenShown = true;
    _callbacks?.onCleanTempFiles?.call();
  }

  static void showWindow() {
    _appWindow?.show();
  }

  static void hideWindow() {
    _appWindow?.hide();
  }
}
