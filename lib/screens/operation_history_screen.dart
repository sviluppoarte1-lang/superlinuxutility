import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/operation_history_service.dart';

class OperationHistoryScreen extends StatefulWidget {
  const OperationHistoryScreen({super.key});

  @override
  State<OperationHistoryScreen> createState() => _OperationHistoryScreenState();
}

class _OperationHistoryScreenState extends State<OperationHistoryScreen> {
  List<OperationRecord> _records = [];
  bool _loading = true;
  final Set<String> _restoring = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await OperationHistoryService.getOperations();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  String _actionLabel(AppLocalizations l10n, OperationRecord r) {
    switch (r.action) {
      case 'firewall_enable':
        return l10n.historyFirewallEnable;
      case 'firewall_disable':
        return l10n.historyFirewallDisable;
      case 'ssh_enable':
        return l10n.historySshEnable;
      case 'ssh_disable':
        return l10n.historySshDisable;
      case 'ssh_root_allow':
        return l10n.historyRootAllow;
      case 'ssh_root_deny':
        return l10n.historyRootDeny;
      case 'autoupdate_enable':
        return l10n.historyAutoUpdateEnable;
      case 'autoupdate_disable':
        return l10n.historyAutoUpdateDisable;
      case 'kernel_tweaks_apply':
        return l10n.historyKernelApply;
      case 'kernel_tweaks_reset':
        return l10n.historyKernelReset;
      default:
        return r.action;
    }
  }

  Future<void> _restore(OperationRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyRestoreTitle),
        content: Text(l10n.historyRestoreConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.postpone)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.historyRestore)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _restoring.add(record.id));
    try {
      final result = await OperationHistoryService.restoreOperation(record.id);
      if (!mounted) return;
      final ok = result['success'] as bool? ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _restoring.remove(record.id));
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.historyClearTitle),
        content: Text(l10n.historyClearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.postpone)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.historyClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await OperationHistoryService.clearHistory();
    if (mounted) await _load();
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
              const Icon(Icons.history, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tabOperationHistory,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      l10n.historySubtitle,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (_records.isNotEmpty)
                IconButton(
                  tooltip: l10n.historyClearAll,
                  onPressed: _loading ? null : _clearAll,
                  icon: const Icon(Icons.delete_outline, size: 20),
                ),
              IconButton(
                tooltip: l10n.statusRefresh,
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off,
                              size: 48, color: colorScheme.outlineVariant),
                          const SizedBox(height: 8),
                          Text(
                            l10n.historyEmpty,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      itemBuilder: (context, index) =>
                          _buildRecordCard(l10n, colorScheme, _records[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(
      AppLocalizations l10n, ColorScheme colorScheme, OperationRecord record) {
    final isRestoring = _restoring.contains(record.id);
    final canRestore = record.undoCommand != null && !record.restored;

    final (IconData icon, Color color) = record.category ==
            OperationHistoryService.categoryKernel
        ? (Icons.memory, Colors.deepPurple)
        : (Icons.security, Colors.green);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _actionLabel(l10n, record),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
                if (record.param != null && record.param!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      record.param!,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                Icon(
                  record.success ? Icons.check_circle : Icons.cancel,
                  color: record.success ? Colors.green : Colors.red,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${record.timestamp.toLocal()}',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
            if (record.undoCommand != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.undoCommand!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (canRestore) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: isRestoring ? null : () => _restore(record),
                  icon: isRestoring
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.undo, size: 16),
                  label: Text(l10n.historyRestore),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ] else if (record.restored) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    l10n.historyRestored,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
