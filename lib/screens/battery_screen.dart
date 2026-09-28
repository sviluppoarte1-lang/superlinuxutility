import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/battery_service.dart';

/// Gestione alimentazione e batteria (solo notebook):
/// salute, soglie di carica e governor automatico.
class BatteryScreen extends StatefulWidget {
  const BatteryScreen({super.key});

  @override
  State<BatteryScreen> createState() => _BatteryScreenState();
}

class _BatteryScreenState extends State<BatteryScreen> {
  BatteryHealth? _health;
  bool _loading = true;
  Timer? _refreshTimer;

  double _endLimit = 80;
  double? _startLimit;
  bool _applyingThreshold = false;

  bool _governorAuto = false;
  String _acGovernor = BatteryService.defaultAcGovernor;
  String _batteryGovernor = BatteryService.defaultBatteryGovernor;
  String _currentGovernor = 'unknown';
  List<String> _availableGovernors = const [
    'performance',
    'powersave',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final h = await BatteryService.getBatteryHealth();
      final govAuto = await BatteryService.getGovernorAutoEnabled();
      final acGov = await BatteryService.getAcGovernor();
      final battGov = await BatteryService.getBatteryGovernor();
      final current = await BatteryService.getCurrentGovernor();
      final available = await BatteryService.getAvailableGovernors();
      if (!mounted) return;
      setState(() {
        _health = h;
        _loading = false;
        _governorAuto = govAuto;
        _acGovernor = acGov;
        _batteryGovernor = battGov;
        _currentGovernor = current;
        _availableGovernors = available;
        if (h.chargeEndThreshold != null) {
          _endLimit = h.chargeEndThreshold!.toDouble();
        }
        if (h.chargeStartThreshold != null) {
          _startLimit = h.chargeStartThreshold!.toDouble();
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statusText(AppLocalizations l10n, String raw) {
    switch (raw) {
      case 'Charging':
        return l10n.batteryCharging;
      case 'Discharging':
        return l10n.batteryDischarging;
      case 'Full':
        return l10n.batteryFull;
      default:
        return l10n.batteryUnknown;
    }
  }

  Future<void> _applyThresholds() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _applyingThreshold = true);
    try {
      await BatteryService.setChargeEndThreshold(_endLimit.round());
      if (_startLimit != null &&
          _health?.chargeStartThreshold != null) {
        await BatteryService.setChargeStartThreshold(_startLimit!.round());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.batteryApplied)),
      );
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.batteryFailed}: $e')),
      );
    } finally {
      if (mounted) setState(() => _applyingThreshold = false);
    }
  }

  Future<void> _setGovernorAuto(bool v) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await BatteryService.setGovernorAutoEnabled(v);
      if (!mounted) return;
      setState(() => _governorAuto = v);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.batteryApplied)),
      );
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.batteryFailed}: $e')),
      );
    }
  }

  Future<void> _setAcGovernor(String? v) async {
    if (v == null) return;
    await BatteryService.setAcGovernor(v);
    if (mounted) setState(() => _acGovernor = v);
  }

  Future<void> _setBatteryGovernor(String? v) async {
    if (v == null) return;
    await BatteryService.setBatteryGovernor(v);
    if (mounted) setState(() => _batteryGovernor = v);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final h = _health;
    if (h == null || !h.present) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerRow(l10n),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.battery_unknown,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    l10n.batteryNoBattery,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.batteryNoBatteryDesc,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _headerRow(l10n),
        const SizedBox(height: 16),
        _healthCard(l10n, h),
        const SizedBox(height: 16),
        _thresholdsCard(l10n, h),
        const SizedBox(height: 16),
        _governorCard(l10n, h),
      ],
    );
  }

  Widget _headerRow(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.battery_charging_full,
            size: 28, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.tabBattery,
            style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: l10n.batteryRefresh,
          icon: const Icon(Icons.refresh, color: Colors.blue),
          onPressed: () => _load(),
        ),
      ],
    );
  }

  Widget _healthCard(AppLocalizations l10n, BatteryHealth h) {
    final healthColor = (h.healthPercent ?? 100) >= 80
        ? Colors.green
        : (h.healthPercent ?? 100) >= 60
            ? Colors.orange
            : Colors.red;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    h.acOnline
                        ? Icons.power
                        : Icons.battery_std,
                    size: 32,
                    color: h.acOnline ? Colors.green : Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${h.percent}%',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_statusText(l10n, h.status)} • ${h.acOnline ? l10n.batteryAcOnline : l10n.batteryAcOffline}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (h.healthPercent != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: h.healthPercent! / 100,
                  minHeight: 8,
                  backgroundColor: healthColor.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                  '${l10n.batteryHealthPct}: ${h.healthPercent!.toStringAsFixed(0)}%'),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _stat(l10n.batteryCapacityNow,
                    h.energyNowWh?.toStringAsFixed(1), 'Wh'),
                _stat(l10n.batteryCapacityFull,
                    h.energyFullWh?.toStringAsFixed(1), 'Wh'),
                _stat(l10n.batteryCapacityDesign,
                    h.energyDesignWh?.toStringAsFixed(1), 'Wh'),
                _stat(l10n.batteryCycles,
                    h.cycleCount?.toString(), ''),
                _stat(l10n.batteryVoltage,
                    h.voltageV?.toStringAsFixed(2), 'V'),
                _stat(l10n.batteryPower,
                    h.powerW?.toStringAsFixed(1), 'W'),
                _stat(l10n.batteryTech, h.technology, ''),
                _stat(l10n.batteryStatus,
                    '${h.manufacturer ?? ''} ${h.model ?? ''}'.trim(), ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String? value, String unit) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text('$value${unit.isEmpty ? '' : ' $unit'}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _thresholdsCard(AppLocalizations l10n, BatteryHealth h) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.battery_saver,
                    size: 28, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.batteryThresholdsTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.batteryThresholdsDesc),
            const SizedBox(height: 8),
            if (h.thresholdNode == null)
              Text(
                l10n.batteryThresholdsUnsupported,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
              )
            else ...[
              Text(
                  '${l10n.batteryEndLimit}: ${_endLimit.round()}%'),
              Slider(
                value: _endLimit.clamp(20, 100),
                min: 20,
                max: 100,
                divisions: 16,
                label: '${_endLimit.round()}%',
                onChanged: (v) => setState(() => _endLimit = v),
              ),
              if (h.chargeStartThreshold != null &&
                  _startLimit != null) ...[
                Text(
                    '${l10n.batteryStartLimit}: ${_startLimit!.round()}%'),
                Slider(
                  value: _startLimit!.clamp(20, 100),
                  min: 20,
                  max: 100,
                  divisions: 16,
                  label: '${_startLimit!.round()}%',
                  onChanged: (v) => setState(() => _startLimit = v),
                ),
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed:
                    _applyingThreshold ? null : _applyThresholds,
                icon: _applyingThreshold
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(l10n.applyNow),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _governorCard(AppLocalizations l10n, BatteryHealth h) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speed, size: 28, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.batteryGovernorTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(l10n.batteryGovernorDesc),
            const SizedBox(height: 8),
            Text(
                '${l10n.batteryGovernorCurrent}: $_currentGovernor • ${h.acOnline ? l10n.batteryAcOnline : l10n.batteryAcOffline}'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.batteryGovernorAuto),
              value: _governorAuto,
              onChanged: _setGovernorAuto,
            ),
            if (_governorAuto) ...[
              DropdownButtonFormField<String>(
                value: _availableGovernors.contains(_acGovernor)
                    ? _acGovernor
                    : _availableGovernors.first,
                decoration: InputDecoration(
                  labelText: l10n.batteryGovernorOnAc,
                  border: const OutlineInputBorder(),
                ),
                items: _availableGovernors
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: _setAcGovernor,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _availableGovernors.contains(_batteryGovernor)
                    ? _batteryGovernor
                    : _availableGovernors.first,
                decoration: InputDecoration(
                  labelText: l10n.batteryGovernorOnBattery,
                  border: const OutlineInputBorder(),
                ),
                items: _availableGovernors
                    .map((g) =>
                        DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: _setBatteryGovernor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
