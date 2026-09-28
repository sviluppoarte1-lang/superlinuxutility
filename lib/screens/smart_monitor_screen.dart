import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/smart_info.dart';
import '../services/password_storage.dart';
import '../services/smart_service.dart';

class SmartMonitorScreen extends StatefulWidget {
  const SmartMonitorScreen({super.key});

  @override
  State<SmartMonitorScreen> createState() => _SmartMonitorScreenState();
}

class _SmartMonitorScreenState extends State<SmartMonitorScreen> {
  List<SmartDisk> _disks = [];
  SmartDisk? _selectedDisk;
  SmartInfo? _smartInfo;
  bool _loading = true;
  bool _loadingData = false;
  Timer? _refreshTimer;
  bool _smartctlAvailable = false;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    _initAndScan();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAndScan() async {
    setState(() => _loading = true);
    _smartctlAvailable = await SmartService.ensureSmartctlAvailable();
    final disks = await SmartService.scanDisks();
    if (mounted) {
      setState(() {
        _disks = disks;
        _loading = false;
        if (disks.isNotEmpty) {
          _selectDisk(disks.first);
        }
      });
    }
  }

  Future<void> _selectDisk(SmartDisk disk) async {
    setState(() {
      _selectedDisk = disk;
      _loadingData = true;
    });
    final info = await SmartService.getSmartInfo(disk, immediate: true);
    if (mounted) {
      setState(() {
        _smartInfo = info;
        _loadingData = false;
      });
    }
  }

  Widget _buildError(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64,
                color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.smartDataNotAvailable,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_smartctlAvailable) {
      return _buildNoSmartctl(theme, l10n);
    }

    if (_disks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64,
                color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(l10n.noSmartDisksFound,
                style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildDiskSelector(theme, l10n),
        if (_loadingData)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_smartInfo != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHealthCard(theme, l10n),
                  const SizedBox(height: 16),
                  _buildUsbInfoCard(theme, l10n),
                  const SizedBox(height: 16),
                  _buildDiskInfoCard(theme, l10n),
                  const SizedBox(height: 16),
                  if (_smartInfo!.attributes.isNotEmpty) ...[
                    _buildAttributesSection(theme, l10n),
                    const SizedBox(height: 16),
                  ],
                  _buildSelfTestSection(theme, l10n),
                ],
              ),
            ),
          )
        else
          Expanded(child: _buildError(theme, l10n)),
      ],
    );
  }

  Widget _buildNoSmartctl(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_circle, size: 80,
                color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(l10n.smartctlNotFound,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(l10n.smartctlInstallPrompt,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _installing ? null : _installSmartctl,
              icon: _installing
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(_installing
                  ? l10n.installing
                  : l10n.installSmartctl),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _installSmartctl() async {
    setState(() => _installing = true);
    // Reset cache forzato per permettere retry
    SmartService.resetSmartctlCache();
    final l10n = AppLocalizations.of(context)!;
    try {
      final hasPwd = await PasswordStorage.hasPassword();
      if (!hasPwd) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.smartSudoPasswordRequired),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() => _installing = false);
        return;
      }
      final result = await SmartService.ensureSmartctlAvailableDetailed();
      if (!mounted) return;
      if (result.success) {
        _smartctlAvailable = true;
        await _initAndScan();
      } else {
        if (mounted) {
          final errorMsg = SmartService.localizeError(l10n, result.error);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
        setState(() => _installing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.smartInstallError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _installing = false);
    }
  }

  Widget _buildDiskSelector(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<SmartDisk>(
              initialValue: _selectedDisk,
              decoration: InputDecoration(
                labelText: l10n.selectDisk,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.disc_full),
              ),
              items: _disks.map((disk) {
                return DropdownMenuItem(
                  value: disk,
                  child: Text('${disk.model} (${disk.device})',
                      overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (disk) {
                if (disk != null) _selectDisk(disk);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _loading ? null : _refreshDisks,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshDisks() async {
    SmartService.invalidateCache();
    setState(() => _loading = true);
    final disks = await SmartService.scanDisks();
    if (mounted) {
      setState(() {
        _disks = disks;
        _loading = false;
        _smartInfo = null;
        _selectedDisk = disks.isNotEmpty ? disks.first : null;
      });
      if (disks.isNotEmpty) {
        _selectDisk(disks.first);
      }
    }
  }

  Widget _buildHealthCard(ThemeData theme, AppLocalizations l10n) {
    final passed = _smartInfo!.overallHealthPassed;
    return Card(
      color: passed
          ? Colors.green.withValues(alpha: 0.15)
          : Colors.red.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              passed ? Icons.check_circle : Icons.error,
              size: 48,
              color: passed ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    passed ? l10n.smartHealthPassed : l10n.smartHealthFailed,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: passed ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  if (_smartInfo!.temperature != null)
                    Text(
                      '${l10n.temperature}: ${_smartInfo!.temperature}°C',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (_smartInfo!.powerOnHours != null)
                    Text(
                      '${l10n.powerOnHours}: ${_smartInfo!.powerOnHours}h',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (_smartInfo!.powerCycleCount != null)
                    Text(
                      '${l10n.powerCycleCount}: ${_smartInfo!.powerCycleCount}',
                      style: theme.textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsbInfoCard(ThemeData theme, AppLocalizations l10n) {
    final dt = _smartInfo!.disk.deviceType;
    if (dt != 'sat' && dt != 'usb') return const SizedBox.shrink();
    return Card(
      color: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.usb, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.smartUsbInfoTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700)),
                  const SizedBox(height: 4),
                  Text(l10n.smartUsbInfoBody,
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiskInfoCard(ThemeData theme, AppLocalizations l10n) {
    final d = _smartInfo!.disk;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.diskInformation,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
            const Divider(),
            _infoRow(l10n.model, d.model),
            _infoRow(l10n.serialNumber, d.serial ?? '-'),
            _infoRow(l10n.firmware, d.firmware ?? '-'),
            _infoRow(l10n.interface, d.displayInterface),
            _infoRow(l10n.smartAvailable,
                _smartInfo!.smartAvailable ? l10n.yes : l10n.no),
            _infoRow(l10n.smartEnabled,
                _smartInfo!.smartEnabled ? l10n.yes : l10n.no),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAttributesSection(ThemeData theme, AppLocalizations l10n) {
    final failedAttrs = _smartInfo!.attributes.where((a) => a.failed).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.smartAttributes,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_smartInfo!.attributes.length} ${l10n.attributes}'),
              ],
            ),
            if (failedAttrs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${l10n.failedAttributes}: ${failedAttrs.map((a) => a.name).join(", ")}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
            const Divider(),
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: [
                      DataColumn(label: Text(l10n.attributeId)),
                      DataColumn(label: Text(l10n.attributeName)),
                      DataColumn(label: Text(l10n.attributeValue),
                          numeric: true),
                      DataColumn(label: Text(l10n.attributeWorst),
                          numeric: true),
                      DataColumn(label: Text(l10n.attributeThreshold),
                          numeric: true),
                      DataColumn(label: Text(l10n.attributeRaw)),
                    ],
                    rows: _smartInfo!.attributes.map((attr) {
                      final isWarning = attr.value <= attr.threshold &&
                          attr.threshold > 0;
                      Color? rowColor;
                      if (attr.failed) {
                        rowColor = Colors.red.withValues(alpha: 0.1);
                      } else if (isWarning) {
                        rowColor = Colors.orange.withValues(alpha: 0.1);
                      } else if (attr.isCritical &&
                          attr.value < 100 &&
                          attr.value > attr.threshold) {
                        rowColor = Colors.yellow.withValues(alpha: 0.1);
                      }
                      return DataRow(
                        color: rowColor != null
                            ? WidgetStatePropertyAll(rowColor)
                            : null,
                        cells: [
                          DataCell(Text('#${attr.id}')),
                          DataCell(Text(attr.name)),
                          DataCell(Text(attr.value.toString()),
                              onTap: attr.failed
                                  ? () => _showAttributeDetail(attr)
                                  : null),
                          DataCell(Text(attr.worst.toString())),
                          DataCell(Text(attr.threshold.toString())),
                          DataCell(Text(attr.rawValue)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfTestSection(ThemeData theme, AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.selfTest,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _runSelfTest('short'),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.shortTest),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _runSelfTest('long'),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.longTest),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.selfTestHint,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Future<void> _runSelfTest(String type) async {
    if (_selectedDisk == null) return;
    final l10n = AppLocalizations.of(context)!;
    final disk = _selectedDisk!;
    try {
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.smartDataNotAvailable)),
          );
        }
        return;
      }
      final escaped = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');
      final r = await Process.run('bash', [
        '-c', 'printf "%s\\n" "$escaped" | sudo -S smartctl -t $type ${disk.smartctlArgs} 2>&1',
      ], runInShell: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r.exitCode == 0
                ? l10n.selfTestStarted
                : '${l10n.selfTestFailed}: ${r.stdout}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.selfTestFailed}: $e')),
        );
      }
    }
  }

  void _showAttributeDetail(SmartAttribute attr) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('#${attr.id} - ${attr.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.attributeValue}: ${attr.value}'),
            Text('${l10n.attributeWorst}: ${attr.worst}'),
            Text('${l10n.attributeThreshold}: ${attr.threshold}'),
            Text('${l10n.attributeRaw}: ${attr.rawValue}'),
            const SizedBox(height: 8),
            if (attr.failed)
              Text(l10n.attributeFailedWarning,
                  style: TextStyle(color: Colors.red.shade700,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}
