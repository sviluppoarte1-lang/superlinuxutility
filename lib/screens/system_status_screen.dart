import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/system_status_service.dart';

class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen> {
  KernelStatus? _kernel;
  SecurityStatus? _security;
  VirtualizationStatus? _virtualization;
  PrintersStatus? _printers;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      SystemStatusService.getKernelStatus(),
      SystemStatusService.getSecurityStatus(),
      SystemStatusService.getVirtualizationStatus(),
      SystemStatusService.getPrintersStatus(),
    ]);
    if (!mounted) return;
    setState(() {
      _kernel = results[0] as KernelStatus;
      _security = results[1] as SecurityStatus;
      _virtualization = results[2] as VirtualizationStatus;
      _printers = results[3] as PrintersStatus;
      _loading = false;
    });
  }

  String _locValue(AppLocalizations l10n, String raw) {
    switch (raw) {
      case 'enabled':
      case 'active':
      case 'yes':
      case '1':
        return l10n.statusEnabled;
      case 'disabled':
      case 'inactive':
      case 'no':
      case '0':
        return l10n.statusDisabled;
      case 'not available':
        return l10n.statusNotAvailable;
      case 'not installed':
        return l10n.statusNotInstalled;
      case 'unknown':
        return l10n.statusUnknown;
      case 'none':
        return l10n.statusNone;
      case 'enforcing':
        return l10n.statusEnforcing;
      case 'permissive':
        return l10n.statusPermissive;
      default:
        return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tabSystemStatus,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.statusReadOnlyNote,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.statusRefresh,
                onPressed: _loading ? null : _loadAll,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildStatusCard(l10n, colorScheme),
        ),
      ],
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section(
                  icon: Icons.memory,
                  color: colorScheme.primary,
                  title: l10n.statusTabKernel,
                  rows: [
                    _StatusRow(l10n.statusKernelVersion, _kernel!.version),
                    _StatusRow(l10n.statusKernelBuild, _kernel!.buildInfo),
                    _StatusRow(
                      l10n.statusCpuCount,
                      _kernel!.cpuCount > 0 ? _kernel!.cpuCount.toString() : l10n.statusUnknown,
                    ),
                    _StatusRow(l10n.statusThpMode, _locValue(l10n, _kernel!.thpMode)),
                    _StatusRow(l10n.statusZswap, _locValue(l10n, _kernel!.zswapStatus)),
                    _StatusRow(l10n.statusGovernor, _locValue(l10n, _kernel!.governor)),
                    _StatusRow(l10n.statusIoScheduler, _locValue(l10n, _kernel!.ioScheduler)),
                  ],
                ),
                const Divider(height: 24),
                _Section(
                  icon: Icons.security,
                  color: Colors.green,
                  title: l10n.statusTabSecurity,
                  rows: [
                    _StatusRow(l10n.statusAppArmor, _locValue(l10n, _security!.appArmor)),
                    _StatusRow(l10n.statusSelinux, _locValue(l10n, _security!.selinux)),
                    _StatusRow(l10n.statusSecureBoot, _locValue(l10n, _security!.secureBoot)),
                    _StatusRow(
                      l10n.statusFirewall,
                      _security!.firewallActive ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(l10n.statusFirewallBackend, _security!.firewallBackend),
                    _StatusRow(
                      l10n.statusSshService,
                      _security!.sshActive ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusRootSsh,
                      _security!.rootSshAllowed ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusAutoUpdates,
                      _security!.autoUpdatesEnabled ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                  ],
                ),
                const Divider(height: 24),
                _Section(
                  icon: Icons.developer_board,
                  color: Colors.orange,
                  title: l10n.statusTabVirtualization,
                  rows: [
                    _StatusRow(
                      l10n.statusCpuVirt,
                      _virtualization!.cpuVirtSupported ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusKvmModule,
                      _virtualization!.kvmModule == 'none'
                          ? l10n.statusNone
                          : _virtualization!.kvmModule,
                    ),
                    _StatusRow(
                      l10n.statusIommu,
                      _virtualization!.iommuEnabled ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusVfio,
                      _virtualization!.vfioLoaded ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusKsm,
                      _virtualization!.ksmRunning ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusDocker,
                      _virtualization!.dockerInstalled ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    _StatusRow(
                      l10n.statusLibvirt,
                      _virtualization!.libvirtInstalled ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                  ],
                ),
                const Divider(height: 24),
                _Section(
                  icon: Icons.print,
                  color: Colors.indigo,
                  title: l10n.statusTabPrinters,
                  rows: [
                    _StatusRow(
                      l10n.statusCupsService,
                      _printers!.cupsActive ? l10n.statusEnabled : l10n.statusDisabled,
                    ),
                    if (_printers!.printers.isEmpty)
                      _StatusRow(l10n.statusPrinters, l10n.statusNone)
                    else
                      ..._printers!.printers.map((pr) => _StatusRow(l10n.statusPrinters, pr)),
                    if (_printers!.drivers.isEmpty)
                      _StatusRow(l10n.statusPrinterDrivers, l10n.statusNone)
                    else
                      ..._printers!.drivers.map((d) => _StatusRow(l10n.statusPrinterDrivers, d)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<_StatusRow> rows;

  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...rows,
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatusRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
