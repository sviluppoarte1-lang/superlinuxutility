import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/security_service.dart';
import '../services/system_status_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  SecurityStatus? _status;
  bool _loading = true;
  String? _busy; // key of the action currently running

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_status == null) setState(() => _loading = true);
    final s = await SystemStatusService.getSecurityStatus();
    if (!mounted) return;
    setState(() {
      _status = s;
      _loading = false;
    });
  }

  Future<void> _toggle({
    required String key,
    required bool current,
    required Future<Map<String, dynamic>> Function() onEnable,
    required Future<Map<String, dynamic>> Function() onDisable,
  }) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      final result = current ? await onDisable() : await onEnable();
      if (!mounted) return;
      final ok = result['success'] as bool? ?? false;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message']?.toString() ?? (ok ? 'OK' : 'Failed')),
        backgroundColor: ok ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    } finally {
      if (mounted) setState(() => _busy = null);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (_loading || _status == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final s = _status!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.security, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.tabSecurity,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(l10n.securitySubtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.statusRefresh,
              onPressed: _busy != null ? null : _load,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SecurityTile(
          l10n: l10n,
          icon: Icons.fireplace_outlined,
          color: Colors.orange,
          title: l10n.securityFirewall,
          description: l10n.securityFirewallDesc,
          active: s.firewallActive,
          statusText: s.firewallActive
              ? l10n.securityFirewallBackend(s.firewallBackend)
              : l10n.statusDisabled,
          busy: _busy == 'firewall',
          warning: !s.sudoAvailable
              ? 'Password sudo non salvata. Salvala nelle Impostazioni.'
              : null,
          onTap: () => _toggle(
            key: 'firewall',
            current: s.firewallActive,
            onEnable: SecurityService.enableFirewall,
            onDisable: SecurityService.disableFirewall,
          ),
        ),
        _SecurityTile(
          l10n: l10n,
          icon: Icons.terminal,
          color: Colors.blue,
          title: l10n.securitySsh,
          description: l10n.securitySshDesc,
          active: s.sshActive,
          statusText: s.sshActive ? l10n.statusEnabled : l10n.statusDisabled,
          busy: _busy == 'ssh',
          onTap: () => _toggle(
            key: 'ssh',
            current: s.sshActive,
            onEnable: SecurityService.enableSsh,
            onDisable: SecurityService.disableSsh,
          ),
        ),
        _SecurityTile(
          l10n: l10n,
          icon: Icons.admin_panel_settings,
          color: Colors.red,
          title: l10n.securityRootSsh,
          description: l10n.securityRootSshDesc,
          active: s.rootSshAllowed,
          statusText: s.rootSshAllowed
              ? l10n.securityRootAllowed
              : l10n.statusDisabled,
          busy: _busy == 'root',
          warning: !s.sudoAvailable
              ? 'Password sudo non salvata. Salvala nelle Impostazioni.'
              : null,
          onTap: () => _toggle(
            key: 'root',
            current: s.rootSshAllowed,
            onEnable: SecurityService.allowRootSsh,
            onDisable: SecurityService.denyRootSsh,
          ),
        ),
        _SecurityTile(
          l10n: l10n,
          icon: Icons.system_update_alt,
          color: Colors.teal,
          title: l10n.securityAutoUpdates,
          description: l10n.securityAutoUpdatesDesc,
          active: s.autoUpdatesEnabled,
          statusText:
              s.autoUpdatesEnabled ? l10n.statusEnabled : l10n.statusDisabled,
          busy: _busy == 'auto',
          onTap: () => _toggle(
            key: 'auto',
            current: s.autoUpdatesEnabled,
            onEnable: SecurityService.enableAutoUpdates,
            onDisable: SecurityService.disableAutoUpdates,
          ),
        ),
      ],
    );
  }
}

class _SecurityTile extends StatelessWidget {
  final AppLocalizations l10n;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final bool active;
  final String statusText;
  final bool busy;
  final String? warning;
  final VoidCallback onTap;

  const _SecurityTile({
    required this.l10n,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.active,
    required this.statusText,
    required this.busy,
    this.warning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active
              ? Colors.green.withValues(alpha: 0.3)
              : cs.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(description,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Checkbox(
                  value: active,
                  onChanged: busy ? null : (_) => onTap(),
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
