import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/system_process.dart';
import '../services/system_monitor.dart';

/// Dialog mostrato dal tray quando si clicca su "Uso memoria RAM".
/// Mostra solo i processi (nessuna sezione System) con ricerca, ordinamento, dettagli e terminazione.
class TrayTaskManagerDialog extends StatefulWidget {
  const TrayTaskManagerDialog({super.key});

  @override
  State<TrayTaskManagerDialog> createState() => _TrayTaskManagerDialogState();
}

class _TrayTaskManagerDialogState extends State<TrayTaskManagerDialog> {
  List<SystemProcess> _processes = [];
  String _searchQuery = '';
  String _sortColumn = 'cpu';
  bool _sortAscending = false;
  bool _isLoading = true;
  String? _error;
  Timer? _searchDebounceTimer;
  List<SystemProcess>? _cachedFiltered;
  String _cachedSearchQuery = '';
  String _cachedSortColumn = '';
  bool _cachedSortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadProcesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cachedFiltered = null;
    });
    try {
      final list = await SystemMonitor.getProcesses();
      if (mounted) {
        setState(() {
          _processes = list;
          _isLoading = false;
          _invalidateCache();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _processes = [];
        });
      }
    }
  }

  List<SystemProcess> get _filteredProcesses {
    if (_cachedFiltered != null &&
        _cachedSearchQuery == _searchQuery &&
        _cachedSortColumn == _sortColumn &&
        _cachedSortAscending == _sortAscending) {
      return _cachedFiltered!;
    }
    var filtered = _processes;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.pid.toString().contains(q) ||
            p.user.toLowerCase().contains(q) ||
            (p.command?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    filtered = List.from(filtered);
    switch (_sortColumn) {
      case 'name':
        filtered.sort((a, b) => _sortAscending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
        break;
      case 'pid':
        filtered.sort((a, b) => _sortAscending
            ? a.pid.compareTo(b.pid)
            : b.pid.compareTo(a.pid));
        break;
      case 'cpu':
        filtered.sort((a, b) => _sortAscending
            ? a.cpuPercent.compareTo(b.cpuPercent)
            : b.cpuPercent.compareTo(a.cpuPercent));
        break;
      case 'memory':
        filtered.sort((a, b) => _sortAscending
            ? a.memoryBytes.compareTo(b.memoryBytes)
            : b.memoryBytes.compareTo(a.memoryBytes));
        break;
      case 'user':
        filtered.sort((a, b) => _sortAscending
            ? a.user.compareTo(b.user)
            : b.user.compareTo(a.user));
        break;
    }
    _cachedFiltered = filtered;
    _cachedSearchQuery = _searchQuery;
    _cachedSortColumn = _sortColumn;
    _cachedSortAscending = _sortAscending;
    return filtered;
  }

  void _invalidateCache() {
    _cachedFiltered = null;
  }

  void _sortProcesses(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = false;
      }
      _invalidateCache();
    });
  }

  Color _getCpuColor(double percent) {
    if (percent < 50) return Colors.green;
    if (percent < 80) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSortIcon(String column) {
    if (_sortColumn != column) {
      return const Icon(Icons.unfold_more, size: 16, color: Colors.grey);
    }
    return Icon(
      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
      size: 16,
      color: Theme.of(context).primaryColor,
    );
  }

  Future<void> _killProcess(SystemProcess process, {bool force = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(force ? l10n.killForce : l10n.kill),
        content: Text('${l10n.kill} ${process.name} (PID: ${process.pid})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.kill,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final success = await SystemMonitor.killProcess(process.pid, force: force);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '${process.name} (${process.pid}) ${l10n.kill}'
                  : 'Error terminating process',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadProcesses();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showProcessDetails(SystemProcess process) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(process.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(l10n.pid, '${process.pid}'),
              _detailRow(l10n.user, process.user),
              _detailRow(l10n.cpuPercent, '${process.cpuPercent.toStringAsFixed(1)}%'),
              _detailRow(l10n.memory, process.memoryFormatted),
              if (process.state.isNotEmpty) _detailRow('State', process.state),
              if (process.command != null && process.command!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${l10n.command}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                SelectableText(
                  process.command!,
                  style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _killProcess(process);
            },
            child: Text(l10n.kill, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.memory),
          const SizedBox(width: 8),
          Text(l10n.processes),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.75,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: l10n.searchProcess,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _searchDebounceTimer?.cancel();
                      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                        if (mounted) {
                          setState(() {
                            _searchQuery = value;
                            _invalidateCache();
                          });
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadProcesses,
                  tooltip: l10n.refresh,
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading && _processes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProcesses.isEmpty
                      ? Center(child: Text(l10n.noProcessesFound))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: [
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortProcesses('name'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        _buildSortIcon('name'),
                                      ],
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortProcesses('pid'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.pid, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        _buildSortIcon('pid'),
                                      ],
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortProcesses('cpu'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.cpuPercent, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        _buildSortIcon('cpu'),
                                      ],
                                    ),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortProcesses('memory'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.memory, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        _buildSortIcon('memory'),
                                      ],
                                    ),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortProcesses('user'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.user, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        _buildSortIcon('user'),
                                      ],
                                    ),
                                  ),
                                ),
                                const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: _filteredProcesses.map((process) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Tooltip(
                                        message: process.command ?? process.name,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: _getCpuColor(process.cpuPercent),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ConstrainedBox(
                                              constraints: const BoxConstraints(maxWidth: 180),
                                              child: Text(
                                                process.name,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () => _showProcessDetails(process),
                                    ),
                                    DataCell(Text('${process.pid}')),
                                    DataCell(
                                      Text(
                                        '${process.cpuPercent.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: _getCpuColor(process.cpuPercent),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(process.memoryFormatted)),
                                    DataCell(Text(process.user, style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'details',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.info_outline, size: 18),
                                                const SizedBox(width: 8),
                                                Text(l10n.details),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'kill',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.stop, color: Colors.orange, size: 18),
                                                const SizedBox(width: 8),
                                                Text(l10n.kill),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'kill_force',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.delete, color: Colors.red, size: 18),
                                                const SizedBox(width: 8),
                                                Text(l10n.killForce),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'details') {
                                            _showProcessDetails(process);
                                          } else if (value == 'kill') {
                                            _killProcess(process);
                                          } else if (value == 'kill_force') {
                                            _killProcess(process, force: true);
                                          }
                                        },
                                      ),
                                    ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
