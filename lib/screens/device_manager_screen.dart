import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/device_info.dart';
import '../services/device_manager_service.dart';
import '../services/password_storage.dart';

class DeviceManagerScreen extends StatefulWidget {
  const DeviceManagerScreen({super.key});

  @override
  State<DeviceManagerScreen> createState() => _DeviceManagerScreenState();
}

class _DeviceManagerScreenState extends State<DeviceManagerScreen> {
  List<DeviceCategory> _categories = [];
  bool _loading = true;
  String? _error;
  bool _showDisabled = true;
  String _filterText = '';
  DeviceInfo? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await DeviceManagerService.getAllDevices();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleDevice(DeviceInfo device) async {
    if (!device.canDisable) {
      _showSnackBar(context, AppLocalizations.of(context)!.deviceManagerCannotDisable, isError: true);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final enable = !device.enabled;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(enable ? Icons.power_settings_new : Icons.power_off,
            color: enable ? Colors.green : Colors.orange, size: 40),
        title: Text(enable ? l10n.deviceManagerEnable : l10n.deviceManagerDisable),
        content: Text(enable ? l10n.deviceManagerConfirmEnable : l10n.deviceManagerConfirmDisable),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: enable ? Colors.green : Colors.orange),
              child: Text(enable ? l10n.deviceManagerEnable : l10n.deviceManagerDisable)),
        ],
      ),
    );
    if (confirmed != true) return;

    // Check password
    final hasPassword = await PasswordStorage.getPassword();
    if (hasPassword == null || hasPassword.isEmpty) {
      if (mounted) _showSnackBar(context, l10n.deviceManagerNoSudo, isError: true);
      return;
    }

    final result = await DeviceManagerService.toggleDevice(device, enable);
    if (mounted) {
      final success = result['success'] == true;
      _showSnackBar(context,
          success ? l10n.deviceManagerToggleSuccess(enable ? l10n.deviceManagerEnable.toLowerCase() : l10n.deviceManagerDisable.toLowerCase()) : l10n.deviceManagerToggleError(enable ? l10n.deviceManagerEnable.toLowerCase() : l10n.deviceManagerDisable.toLowerCase()),
          isError: !success);
      if (success) _loadDevices();
    }
  }

  void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showProperties(DeviceInfo device) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (ctx, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.deviceManagerProperties, style: theme.textTheme.titleLarge),
            ]),
            const SizedBox(height: 16),
            _propRow(l10n.deviceManagerStatus, device.enabled ? l10n.deviceManagerEnabled : l10n.deviceManagerDisabled, device.enabled ? Colors.green : Colors.red),
            if (!device.enabled && device.bus != 'block') _propRow(l10n.deviceManagerPersistent, '✓', Colors.orange),
            if (device.bus != null) _propRow(l10n.deviceManagerBus, device.bus!),
            if (device.vendor != null && device.vendor!.isNotEmpty) _propRow(l10n.deviceManagerVendor, device.vendor!),
            if (device.driver != null && device.driver!.isNotEmpty) _propRow(l10n.deviceManagerDriver, device.driver!),
            if (device.vendorId != null) _propRow('Vendor ID', '0x${device.vendorId}'),
            if (device.deviceId != null) _propRow('Device ID', '0x${device.deviceId}'),
            if (device.details != null && device.details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(l10n.deviceManagerDetails, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...device.details!.split(' | ').map((d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(d, style: theme.textTheme.bodyMedium),
              )),
            ],
            if (!device.canDisable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.lock, size: 16, color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.deviceManagerCannotDisable, style: TextStyle(color: theme.colorScheme.onErrorContainer))),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                label: Text(l10n.deviceManagerClose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor))),
        ],
      ),
    );
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
          // Header
          Row(children: [
            Icon(Icons.devices_other, size: 28, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Text(l10n.deviceManagerTitle, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            // Search
            SizedBox(
              width: 220,
              child: TextField(
                decoration: InputDecoration(
                  hintText: '${l10n.deviceManagerAllDevices}...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (v) => setState(() => _filterText = v.toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            // Show disabled toggle
            FilterChip(
              label: Text(l10n.deviceManagerShowDisabled, style: const TextStyle(fontSize: 12)),
              selected: _showDisabled,
              onSelected: (v) => setState(() => _showDisabled = v),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.deviceManagerRefresh,
              icon: const Icon(Icons.refresh),
              onPressed: _loadDevices,
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: _loading
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l10n.deviceManagerLoading),
                  ]))
                : _error != null
                    ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(onPressed: _loadDevices, icon: const Icon(Icons.refresh), label: Text(l10n.deviceManagerRefresh)),
                      ]))
                    : _buildDeviceTree(theme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTree(ThemeData theme, AppLocalizations l10n) {
    // Filter categories and devices
    final filteredCats = <DeviceCategory>[];
    for (final cat in _categories) {
      final filteredDevices = cat.devices.where((d) {
        if (!_showDisabled && !d.enabled) return false;
        if (_filterText.isNotEmpty) {
          final search = '${d.name} ${d.vendor ?? ''} ${d.driver ?? ''} ${d.bus ?? ''}'.toLowerCase();
          if (!search.contains(_filterText)) return false;
        }
        return true;
      }).toList();
      if (filteredDevices.isNotEmpty) {
        filteredCats.add(DeviceCategory(name: cat.name, icon: cat.icon, devices: filteredDevices));
      }
    }

    if (filteredCats.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.devices_other, size: 64, color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 16),
        Text(l10n.deviceManagerEmpty, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
      ]));
    }

    final totalDevices = filteredCats.fold<int>(0, (s, c) => s + c.devices.length);
    final enabledCount = filteredCats.fold<int>(0, (s, c) => s + c.devices.where((d) => d.enabled).length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$totalDevices ${l10n.deviceManagerAllDevices.toLowerCase()} · $enabledCount ${l10n.deviceManagerEnabled.toLowerCase()} · ${totalDevices - enabledCount} ${l10n.deviceManagerDisabled.toLowerCase()}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        // Device tree
        Expanded(
          child: ListView.builder(
            itemCount: filteredCats.length,
            itemBuilder: (context, catIndex) {
              final cat = filteredCats[catIndex];
              return _DeviceCategoryTile(
                category: cat,
                selectedDevice: _selectedDevice,
                onToggle: _toggleDevice,
                onSelect: (d) => setState(() => _selectedDevice = d),
                onProperties: _showProperties,
                l10n: l10n,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceCategoryTile extends StatefulWidget {
  final DeviceCategory category;
  final DeviceInfo? selectedDevice;
  final Function(DeviceInfo) onToggle;
  final Function(DeviceInfo) onSelect;
  final Function(DeviceInfo) onProperties;
  final AppLocalizations l10n;

  const _DeviceCategoryTile({
    required this.category,
    required this.selectedDevice,
    required this.onToggle,
    required this.onSelect,
    required this.onProperties,
    required this.l10n,
  });

  @override
  State<_DeviceCategoryTile> createState() => _DeviceCategoryTileState();
}

class _DeviceCategoryTileState extends State<_DeviceCategoryTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = widget.category;
    final enabledCount = cat.devices.where((d) => d.enabled).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Text(cat.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        '${cat.devices.length} ${widget.l10n.deviceManagerAllDevices.toLowerCase()} · $enabledCount ${widget.l10n.deviceManagerEnabled.toLowerCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                      ),
                    ],
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.outline),
              ]),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...cat.devices.map((device) => _DeviceTile(
              device: device,
              isSelected: widget.selectedDevice?.id == device.id,
              onToggle: () => widget.onToggle(device),
              onSelect: () => widget.onSelect(device),
              onProperties: () => widget.onProperties(device),
              l10n: widget.l10n,
            )),
          ],
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceInfo device;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onSelect;
  final VoidCallback onProperties;
  final AppLocalizations l10n;

  const _DeviceTile({
    required this.device,
    required this.isSelected,
    required this.onToggle,
    required this.onSelect,
    required this.onProperties,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProblem = !device.enabled && device.canDisable;
    final icon = _deviceIcon(device);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        onDoubleTap: onProperties,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Status icon
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: device.enabled ? theme.colorScheme.primary : theme.colorScheme.outline),
                  if (hasProblem)
                    Positioned(right: -2, bottom: -2, child: Icon(Icons.warning, size: 12, color: Colors.orange)),
                ],
              ),
              const SizedBox(width: 12),
              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name, style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: device.enabled ? null : theme.colorScheme.outline,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (device.driver != null && device.driver!.isNotEmpty)
                      Text('${l10n.deviceManagerDriver}: ${device.driver}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: device.enabled
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      device.enabled ? l10n.deviceManagerEnabled : l10n.deviceManagerDisabled,
                      style: TextStyle(fontSize: 11, color: device.enabled ? Colors.green[700] : Colors.red[700], fontWeight: FontWeight.w600),
                    ),
                    if (!device.enabled && device.bus != 'block') ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock_reset, size: 11, color: Colors.orange[700]),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Properties button
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                tooltip: l10n.deviceManagerProperties,
                onPressed: onProperties,
                visualDensity: VisualDensity.compact,
              ),
              // Toggle button
              if (device.canDisable)
                IconButton(
                  icon: Icon(device.enabled ? Icons.pause_circle_outline : Icons.play_circle_outline, size: 20),
                  tooltip: device.enabled ? l10n.deviceManagerDisable : l10n.deviceManagerEnable,
                  onPressed: onToggle,
                  visualDensity: VisualDensity.compact,
                  color: device.enabled ? Colors.orange : Colors.green,
                )
              else
                IconButton(
                  icon: const Icon(Icons.lock_outline, size: 18),
                  tooltip: l10n.deviceManagerCannotDisable,
                  onPressed: null,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _deviceIcon(DeviceInfo device) {
    final cat = device.category.toLowerCase();
    final name = device.name.toLowerCase();
    if (cat.contains('display') || name.contains('vga') || name.contains('3d') || name.contains('gpu') || name.contains('radeon') || name.contains('nvidia') || name.contains('intel') && name.contains('graphics')) {
      return Icons.desktop_windows;
    }
    if (cat.contains('network') || name.contains('ethernet') || name.contains('wifi') || name.contains('wireless') || name.contains('bluetooth')) {
      return Icons.wifi;
    }
    if (cat.contains('sound') || cat.contains('audio') || name.contains('audio') || name.contains('sound')) {
      return Icons.volume_up;
    }
    if (cat.contains('usb')) {
      return Icons.usb;
    }
    if (cat.contains('storage') || cat.contains('disk') || name.contains('sata') || name.contains('nvme') || name.contains('raid')) {
      return Icons.storage;
    }
    if (cat.contains('processor') || name.contains('cpu') || name.contains('processor')) {
      return Icons.memory;
    }
    if (cat.contains('input') || name.contains('keyboard') || name.contains('mouse') || name.contains('hid')) {
      return Icons.keyboard;
    }
    if (cat.contains('multimedia') || name.contains('camera') || name.contains('video') || name.contains('webcam')) {
      return Icons.videocam;
    }
    return Icons.device_hub;
  }
}
