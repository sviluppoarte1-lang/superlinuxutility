import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/driver_manager_service.dart';
import '../services/password_storage.dart';

class DriverManagerScreen extends StatefulWidget {
  const DriverManagerScreen({super.key});

  @override
  State<DriverManagerScreen> createState() => _DriverManagerScreenState();
}

class _DriverManagerScreenState extends State<DriverManagerScreen> {
  DriverScanResult? _scanResult;
  bool _loading = false;
  String? _error;
  final Map<int, bool> _installing = {};
  bool _firmwareInstalling = false;

  @override
  void initState() {
    super.initState();
    _scanDrivers();
  }

  Future<void> _scanDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await DriverManagerService.scanDrivers();
    if (mounted) {
      setState(() {
        _scanResult = result;
        _loading = false;
        _error = result.error;
      });
    }
  }

  Future<void> _installDriver(int index) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save administrator password in Settings first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _installing[index] = true);
    final driver = _scanResult!.drivers[index];
    final result = await DriverManagerService.installDriver(driver);
    if (mounted) {
      setState(() => _installing[index] = false);
      if (result == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${driver.deviceName} installed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _scanDrivers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Installation failed: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _installFirmware() async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save administrator password in Settings first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _firmwareInstalling = true);
    final result = await DriverManagerService.installLinuxFirmware();
    if (mounted) {
      setState(() => _firmwareInstalling = false);
      if (result == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Linux firmware installed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firmware installation failed: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _applyFirmwareUpdate(FirmwareUpdate update) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save administrator password in Settings first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    setState(() => _firmwareInstalling = true);
    final result = await DriverManagerService.applyFirmwareUpdate(update);
    if (mounted) {
      setState(() => _firmwareInstalling = false);
      if (result == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(update.needsReboot
                ? 'Firmware updated. Reboot required.'
                : 'Firmware updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _scanDrivers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firmware update failed: $result'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.driverManagerTitle,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: l10n.driverManagerScan,
                onPressed: _loading ? null : _scanDrivers,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _scanDrivers,
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.driverManagerScan),
                            ),
                          ],
                        ),
                      )
                    : _buildResults(l10n, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n, ThemeData theme) {
    final drivers = _scanResult?.drivers ?? [];
    final firmwareUpdates = _scanResult?.firmwareUpdates ?? [];
    final available =
        drivers.where((d) => d.status == DriverStatus.available).toList();
    final installed =
        drivers.where((d) => d.status == DriverStatus.installed).toList();

    return ListView(
      children: [
        if (firmwareUpdates.isNotEmpty) ...[
          _buildSectionHeader(
            l10n.driverManagerFirmwareUpdates,
            Icons.system_update,
            Colors.orange,
            l10n,
          ),
          ...firmwareUpdates.map((fu) => _buildFirmwareCard(fu, l10n, theme)),
          const SizedBox(height: 12),
        ],
        _buildSectionHeader(
          '${l10n.driverManagerAvailableDrivers} (${available.length})',
          Icons.download,
          Colors.green,
          l10n,
        ),
        if (available.isEmpty)
          _buildEmptyCard(l10n.driverManagerAllDriversInstalled, theme)
        else
          ...available.asMap().entries.map(
              (e) => _buildDriverCard(e.value, e.key, l10n, theme, true)),
        const SizedBox(height: 12),
        _buildSectionHeader(
          '${l10n.driverManagerInstalledDrivers} (${installed.length})',
          Icons.check_circle,
          Colors.blue,
          l10n,
        ),
        if (installed.isEmpty)
          _buildEmptyCard(l10n.driverManagerNoDriversInstalled, theme)
        else
          ...installed.asMap().entries.map(
              (e) => _buildDriverCard(e.value, e.key, l10n, theme, false)),
        const SizedBox(height: 12),
        _buildFirmwarePackageCard(l10n, theme),
      ],
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, Color color, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: theme.colorScheme.outline)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverCard(
      DriverInfo driver, int index, AppLocalizations l10n, ThemeData theme,
      bool showInstall) {
    final isInstalling = _installing[index] ?? false;
    final categoryIcon = _categoryIcon(driver.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _categoryColor(driver.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(categoryIcon,
                  color: _categoryColor(driver.category), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver.deviceName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${driver.category} · ${driver.deviceId}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                  if (driver.currentDriver != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.driverManagerCurrentDriver}: ${driver.currentDriver}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                  if (driver.candidatePackages.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.driverManagerPackage}: ${driver.candidatePackages.first}',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            if (showInstall && driver.candidatePackages.isNotEmpty)
              ElevatedButton.icon(
                onPressed: isInstalling ? null : () => _installDriver(index),
                icon: isInstalling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download, size: 18),
                label: Text(l10n.driverManagerInstall),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              )
            else if (!showInstall)
              Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmwareCard(
      FirmwareUpdate fu, AppLocalizations l10n, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.orange.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.system_update, color: Colors.orange, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fu.deviceName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${fu.currentVersion} → ${fu.latestVersion}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.orange),
                  ),
                  if (fu.needsReboot)
                    Text(
                      l10n.driverManagerRebootRequired,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: _firmwareInstalling
                  ? null
                  : () => _applyFirmwareUpdate(fu),
              icon: _firmwareInstalling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update, size: 18),
              label: Text(l10n.driverManagerUpdate),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirmwarePackageCard(AppLocalizations l10n, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.memory, color: Colors.purple, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.driverManagerLinuxFirmware,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    l10n.driverManagerLinuxFirmwareDesc,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  _firmwareInstalling ? null : _installFirmware,
              icon: _firmwareInstalling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download, size: 18),
              label: Text(l10n.driverManagerInstall),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Graphics':
        return Colors.blue;
      case 'Network':
        return Colors.green;
      case 'Audio':
        return Colors.purple;
      case 'Storage':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'Graphics':
        return Icons.desktop_windows;
      case 'Network':
        return Icons.wifi;
      case 'Audio':
        return Icons.volume_up;
      case 'Storage':
        return Icons.storage;
      default:
        return Icons.device_hub;
    }
  }
}
