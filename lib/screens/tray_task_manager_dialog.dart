import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/system_process.dart';
import '../models/system_info.dart';
import '../services/system_monitor.dart';

class _ProcessGroup {
  final String baseName;
  final List<SystemProcess> processes;
  _ProcessGroup(this.baseName, this.processes);
  double get totalCpu => processes.fold(0.0, (s, p) => s + p.cpuPercent);
  int get totalMemory => processes.fold(0, (s, p) => s + p.memoryBytes);
  int get processCount => processes.length;
}

/// Dialog mostrato dal tray quando si clicca su "Uso memoria RAM".
/// Mostra solo i processi (nessuna sezione System) con ricerca, ordinamento, dettagli e terminazione.
class TrayTaskManagerDialog extends StatefulWidget {
  const TrayTaskManagerDialog({super.key});

  @override
  State<TrayTaskManagerDialog> createState() => _TrayTaskManagerDialogState();
}

class _TrayTaskManagerDialogState extends State<TrayTaskManagerDialog> {
  List<SystemProcess> _processes = [];
  SystemInfo? _systemInfo;
  String _searchQuery = '';
  String _sortColumn = 'cpu';
  bool _sortAscending = false;
  bool _isLoading = true;
  String? _error;
  Timer? _searchDebounceTimer;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  List<SystemProcess>? _cachedFiltered;
  String _cachedSearchQuery = '';
  String _cachedSortColumn = '';
  bool _cachedSortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadProcesses();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isRefreshing) _refreshSystemInfo();
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshSystemInfo() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final info = await SystemMonitor.getSystemInfo();
      if (mounted) setState(() { _systemInfo = info; });
    } catch (_) {}
    finally {
      _isRefreshing = false;
    }
  }

  Future<void> _loadProcesses() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _cachedFiltered = null;
    });
    try {
      final results = await Future.wait([
        SystemMonitor.getProcesses(),
        SystemMonitor.getSystemInfo(),
      ]);
      if (mounted) {
        setState(() {
          _processes = results[0] as List<SystemProcess>;
          _systemInfo = results[1] as SystemInfo;
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

  // Raggruppa per nome esatto
  List<_ProcessGroup> _groupProcesses(List<SystemProcess> processes) {
    final Map<String, List<SystemProcess>> groups = {};
    for (final p in processes) {
      final key = p.name.toLowerCase();
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(p);
    }
    return groups.entries.map((e) => _ProcessGroup(e.key, e.value)).toList();
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
      _sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
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

  Future<void> _killMultipleProcesses(List<SystemProcess> processes, {bool force = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final count = processes.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(force ? l10n.killForce : l10n.kill),
        content: Text(
          '${l10n.kill} ${count} process${count > 1 ? 'i' : 'o'} (${processes.first.name}${count > 1 ? '…' : ''})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              force ? l10n.terminateAllForce : l10n.terminateAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    int ok = 0, fail = 0;
    for (final p in processes) {
      try {
        if (await SystemMonitor.killProcess(p.pid, force: force)) ok++; else fail++;
      } catch (_) { fail++; }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terminati: $ok, Errori: $fail'),
          backgroundColor: fail == 0 ? Colors.green : Colors.orange,
        ),
      );
      _loadProcesses();
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static const List<Color> _coreColors = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFB8C00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFF4511E),
    Color(0xFF3949AB),
    Color(0xFFC0CA33),
    Color(0xFFD81B60),
    Color(0xFF00897B),
    Color(0xFF6D4C41),
    Color(0xFF546E7A),
    Color(0xFFFDD835),
    Color(0xFF5E35B1),
    Color(0xFF00BCD4),
  ];

  Widget _buildCpuHeaderBar() {
    final info = _systemInfo;
    if (info == null) return const SizedBox.shrink();
    final cpu = info.cpu;
    final speedText = cpu.currentSpeedMhz != null
        ? '${(cpu.currentSpeedMhz! / 1000).toStringAsFixed(2)} GHz'
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 10,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (speedText.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(speedText, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          if (cpu.coreUsage.isNotEmpty) ...[
            Text('Cores:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ...List.generate(cpu.coreUsage.length.clamp(0, 32), (i) {
              final u = cpu.coreUsage[i];
              final color = _coreColors[i % _coreColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.3), width: 0.5),
                ),
                child: Text(
                  'C$i: ${u.toStringAsFixed(0)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
                ),
              );
            }),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.memory, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Text('${_processes.length}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
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
            // Barra info CPU
            _buildCpuHeaderBar(),
            const SizedBox(height: 8),
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
                              columnSpacing: 12,
                              columns: [
                                DataColumn(
                                  label: GestureDetector(
                                    onTap: () => _sortProcesses('name'),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(l10n.app, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 4),
                                        _buildSortIcon('name'),
                                      ],
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(l10n.processes, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                                const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: () {
                                final groups = _groupProcesses(_filteredProcesses);
                                // Ordina i gruppi in base alla colonna selezionata
                                if (_sortColumn == 'cpu') {
                                  groups.sort((a, b) => _sortAscending
                                      ? a.totalCpu.compareTo(b.totalCpu)
                                      : b.totalCpu.compareTo(a.totalCpu));
                                } else if (_sortColumn == 'memory') {
                                  groups.sort((a, b) => _sortAscending
                                      ? a.totalMemory.compareTo(b.totalMemory)
                                      : b.totalMemory.compareTo(a.totalMemory));
                                } else if (_sortColumn == 'name') {
                                  groups.sort((a, b) => _sortAscending
                                      ? a.baseName.compareTo(b.baseName)
                                      : b.baseName.compareTo(a.baseName));
                                } else {
                                  groups.sort((a, b) => b.totalCpu.compareTo(a.totalCpu));
                                }
                                return groups;
                              }().map((group) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: _getCpuColor(group.totalCpu),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 160),
                                            child: Text(
                                              group.baseName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text('${group.processCount}')),
                                    DataCell(
                                      Text(
                                        '${group.totalCpu.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: _getCpuColor(group.totalCpu),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(_formatBytes(group.totalMemory))),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, size: 18),
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'kill',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.stop, color: Colors.orange, size: 18),
                                                const SizedBox(width: 8),
                                                Text(l10n.terminateAll),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'kill_force',
                                            child: Row(
                                              children: [
                                                const Icon(Icons.delete, color: Colors.red, size: 18),
                                                const SizedBox(width: 8),
                                                Text(l10n.terminateAllForce),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'kill') {
                                            _killMultipleProcesses(group.processes);
                                          } else if (value == 'kill_force') {
                                            _killMultipleProcesses(group.processes, force: true);
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
