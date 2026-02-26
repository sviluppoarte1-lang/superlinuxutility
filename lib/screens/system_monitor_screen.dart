import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/system_process.dart';
import '../models/system_info.dart';
import '../services/system_monitor.dart';

class SystemMonitorScreen extends StatefulWidget {
  const SystemMonitorScreen({super.key});

  @override
  State<SystemMonitorScreen> createState() => _SystemMonitorScreenState();
}

// Classe helper per raggruppare processi
class _ProcessGroup {
  final String baseName;
  final List<SystemProcess> processes;
  
  _ProcessGroup(this.baseName, this.processes);
  
  double get totalCpu => processes.fold(0.0, (sum, p) => sum + p.cpuPercent);
  int get totalMemory => processes.fold(0, (sum, p) => sum + p.memoryBytes);
  int get processCount => processes.length;
}

class _SystemMonitorScreenState extends State<SystemMonitorScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<SystemProcess> _processes = [];
  SystemInfo? _systemInfo;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  String _searchQuery = '';
  late TabController _tabController;
  Timer? _refreshTimer;
  Timer? _searchDebounceTimer;
  
  // Ordinamento
  String? _sortColumn;
  bool _sortAscending = false;
  
  // Memoization per processi filtrati
  List<SystemProcess>? _cachedFilteredProcesses;
  String? _cachedSearchQuery;
  String? _cachedSortColumn;
  bool? _cachedSortAscending;
  
  // Selezione multipla
  Set<int> _selectedPids = {};
  bool _isSelectionMode = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
    // Aggiorna automaticamente ogni 5 secondi (ridotto da 3 per ottimizzare)
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounceTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Ferma refresh quando non si è sulla tab Processi
    if (_tabController.index != 0) {
      _refreshTimer?.cancel();
    } else {
      _startAutoRefresh();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isRefreshing && _tabController.index == 0) {
        _refreshData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _refreshData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final processes = await SystemMonitor.getProcesses();
      final systemInfo = await SystemMonitor.getSystemInfo();

      if (mounted) {
        setState(() {
          _processes = processes;
          _systemInfo = systemInfo;
          _isRefreshing = false;
        });
        _invalidateCache();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }

  /// Estrae il nome base dell'applicazione per raggruppare processi correlati
  String _getBaseAppName(SystemProcess process) {
    String name = process.name.toLowerCase();
    
    // Rimuovi suffissi comuni
    final suffixes = ['-bin', '-esr', '-dev', '-stable', '-beta', '-alpha', '-snapshot', '-wrapper', '-helper', '-worker', '-renderer', '-gpu', '-plugin', '-extension'];
    for (final suffix in suffixes) {
      if (name.endsWith(suffix)) {
        name = name.substring(0, name.length - suffix.length);
        break;
      }
    }
    
    // Rimuovi estensioni
    if (name.contains('.')) {
      name = name.split('.').first;
    }
    
    // Rimuovi numeri alla fine (es. "firefox2" -> "firefox")
    name = name.replaceAll(RegExp(r'\d+$'), '');
    
    return name.isNotEmpty ? name : process.name.toLowerCase();
  }
  
  /// Raggruppa i processi per nome base dell'applicazione
  List<_ProcessGroup> _groupProcesses(List<SystemProcess> processes) {
    final Map<String, List<SystemProcess>> groups = {};
    
    for (final process in processes) {
      final baseName = _getBaseAppName(process);
      if (!groups.containsKey(baseName)) {
        groups[baseName] = [];
      }
      groups[baseName]!.add(process);
    }
    
    return groups.entries.map((e) => _ProcessGroup(e.key, e.value)).toList();
  }
  
  List<SystemProcess> get _filteredProcesses {
    // Memoization: riutilizza il risultato se i parametri non sono cambiati
    if (_cachedFilteredProcesses != null &&
        _cachedSearchQuery == _searchQuery &&
        _cachedSortColumn == _sortColumn &&
        _cachedSortAscending == _sortAscending) {
      return _cachedFilteredProcesses!;
    }
    
    List<SystemProcess> filtered;
    
    // Applica filtro ricerca
    if (_searchQuery.isEmpty) {
      filtered = List.from(_processes);
    } else {
      final query = _searchQuery.toLowerCase();
      filtered = _processes.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.command?.toLowerCase().contains(query) ?? false) ||
            p.user.toLowerCase().contains(query);
      }).toList();
    }
    
    // Applica ordinamento
    if (_sortColumn != null) {
      filtered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumn) {
          case 'cpu':
            comparison = a.cpuPercent.compareTo(b.cpuPercent);
            break;
          case 'memory':
            comparison = a.memoryBytes.compareTo(b.memoryBytes);
            break;
          case 'name':
            comparison = a.name.compareTo(b.name);
            break;
          case 'pid':
            comparison = a.pid.compareTo(b.pid);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    } else {
      // Ordinamento predefinito per CPU decrescente
      filtered.sort((a, b) => b.cpuPercent.compareTo(a.cpuPercent));
    }
    
    // Salva in cache
    _cachedFilteredProcesses = filtered;
    _cachedSearchQuery = _searchQuery;
    _cachedSortColumn = _sortColumn;
    _cachedSortAscending = _sortAscending;
    
    return filtered;
  }
  
  void _invalidateCache() {
    _cachedFilteredProcesses = null;
  }
  
  void _sortProcesses(String column) {
    setState(() {
      if (_sortColumn == column) {
        // Inverti la direzione se si clicca sulla stessa colonna
        _sortAscending = !_sortAscending;
      } else {
        // Nuova colonna, inizia con decrescente
        _sortColumn = column;
        _sortAscending = false;
      }
      _invalidateCache();
    });
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(force ? AppLocalizations.of(context)!.killForce : AppLocalizations.of(context)!.kill),
        content: Text(
          '${AppLocalizations.of(context)!.kill} ${process.name} (PID: ${process.pid})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.kill,
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
                  ? 'Processo ${process.name} terminato'
                  : 'Errore durante la terminazione del processo',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          _refreshData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _killMultipleProcesses(List<SystemProcess> processes, {bool force = false}) async {
    final count = processes.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(force ? AppLocalizations.of(context)!.killForce : AppLocalizations.of(context)!.kill),
        content: Text(
          '${AppLocalizations.of(context)!.kill} ${count == 1 ? AppLocalizations.of(context)!.processesSelected(count) : AppLocalizations.of(context)!.processesSelectedPlural(count)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              force ? AppLocalizations.of(context)!.terminateAllForce : AppLocalizations.of(context)!.terminateAll,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    int successCount = 0;
    int failCount = 0;
    
    for (final process in processes) {
      try {
        final success = await SystemMonitor.killProcess(process.pid, force: force);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }
    
    if (mounted) {
      setState(() {
        _selectedPids.clear();
        _isSelectionMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terminati: $successCount, Errori: $failCount',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        ),
      );
      _refreshData();
    }
  }
  
  void _toggleSelection(SystemProcess process) {
    setState(() {
      if (_selectedPids.contains(process.pid)) {
        _selectedPids.remove(process.pid);
      } else {
        _selectedPids.add(process.pid);
      }
      if (_selectedPids.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }
  
  void _toggleGroupSelection(_ProcessGroup group) {
    setState(() {
      final groupPids = group.processes.map((p) => p.pid).toSet();
      if (groupPids.every((pid) => _selectedPids.contains(pid))) {
        // Deseleziona tutti
        _selectedPids.removeAll(groupPids);
      } else {
        // Seleziona tutti
        _selectedPids.addAll(groupPids);
      }
      if (_selectedPids.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }
  
  bool _isGroupSelected(_ProcessGroup group) {
    final groupPids = group.processes.map((p) => p.pid).toSet();
    return groupPids.every((pid) => _selectedPids.contains(pid));
  }
  
  bool _isGroupPartiallySelected(_ProcessGroup group) {
    final groupPids = group.processes.map((p) => p.pid).toSet();
    return groupPids.any((pid) => _selectedPids.contains(pid)) && 
           !groupPids.every((pid) => _selectedPids.contains(pid));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Richiesto per AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.searchProcess,
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // Debouncing per la ricerca - evita rebuild ad ogni carattere
                          _searchDebounceTimer?.cancel();
                          _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              setState(() {
                                _searchQuery = value;
                                _invalidateCache();
                                if (value.isEmpty) {
                                  _isSelectionMode = false;
                                  _selectedPids.clear();
                                } else {
                                  _isSelectionMode = true;
                                }
                              });
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      onPressed: _isRefreshing ? null : _refreshData,
                      tooltip: 'Aggiorna',
                    ),
                  ],
                ),
                if (_isSelectionMode && _selectedPids.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${_selectedPids.length} processo${_selectedPids.length > 1 ? "i selezionati" : " selezionato"}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            final selected = _processes.where((p) => _selectedPids.contains(p.pid)).toList();
                            _killMultipleProcesses(selected);
                          },
                          icon: const Icon(Icons.stop, size: 18),
                          label: Text(AppLocalizations.of(context)!.kill),
                          style: TextButton.styleFrom(foregroundColor: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            final selected = _processes.where((p) => _selectedPids.contains(p.pid)).toList();
                            _killMultipleProcesses(selected, force: true);
                          },
                          icon: const Icon(Icons.delete, size: 18),
                          label: Text(AppLocalizations.of(context)!.killForce),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedPids.clear();
                              _isSelectionMode = false;
                            });
                          },
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: const Icon(Icons.memory), text: AppLocalizations.of(context)!.processes),
              Tab(icon: const Icon(Icons.info), text: AppLocalizations.of(context)!.system),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProcessesTab(),
                _buildSystemInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessesTab() {
    if (_isLoading && _processes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredProcesses;

    if (filtered.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.noProcessesFound),
      );
    }

    // Se c'è una ricerca attiva, mostra i processi raggruppati
    if (_searchQuery.isNotEmpty && _isSelectionMode) {
      final groups = _groupProcesses(filtered);
      groups.sort((a, b) => b.totalCpu.compareTo(a.totalCpu));
      
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: RepaintBoundary(
            child: DataTable(
              columns: [
                DataColumn(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.app, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _sortProcesses('name'),
                        child: _buildSortIcon('name'),
                      ),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.processes, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                DataColumn(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.cpuPercent, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _sortProcesses('cpu'),
                        child: _buildSortIcon('cpu'),
                      ),
                    ],
                  ),
                  numeric: true,
                ),
                DataColumn(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.memory, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _sortProcesses('memory'),
                        child: _buildSortIcon('memory'),
                      ),
                    ],
                  ),
                  numeric: true,
                ),
                const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: groups.map((group) {
                final isSelected = _isGroupSelected(group);
                final isPartiallySelected = _isGroupPartiallySelected(group);
                
                return DataRow(
                  selected: isSelected || isPartiallySelected,
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            tristate: true,
                            isError: isPartiallySelected,
                            onChanged: (_) => _toggleGroupSelection(group),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getCpuColor(group.totalCpu),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              group.baseName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(Text(_formatBytes(group.totalMemory))),
                    DataCell(
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'select_all',
                            child: Row(
                              children: [
                                const Icon(Icons.check_box, size: 18),
                                const SizedBox(width: 8),
                                Text('${AppLocalizations.of(context)!.selectAll} (${group.processCount})'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'kill',
                            child: Row(
                              children: [
                                const Icon(Icons.stop, color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.terminateAll),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'kill_force',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.terminateAllForce),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'select_all') {
                            _toggleGroupSelection(group);
                          } else if (value == 'kill') {
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
      );
    }

    // Vista normale con checkbox per selezione multipla
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: RepaintBoundary(
          child: DataTable(
          sortColumnIndex: _sortColumn == 'cpu' ? 2 : (_sortColumn == 'memory' ? 3 : null),
          sortAscending: _sortAscending,
          columns: [
            if (_isSelectionMode)
              const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _sortProcesses('name'),
                    child: _buildSortIcon('name'),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.pid, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _sortProcesses('pid'),
                    child: _buildSortIcon('pid'),
                  ),
                ],
              ),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.cpuPercent, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _sortProcesses('cpu'),
                    child: _buildSortIcon('cpu'),
                  ),
                ],
              ),
              numeric: true,
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.memory, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _sortProcesses('memory'),
                    child: _buildSortIcon('memory'),
                  ),
                ],
              ),
              numeric: true,
            ),
            DataColumn(label: Text(AppLocalizations.of(context)!.user, style: const TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filtered.map((process) {
            final isSelected = _selectedPids.contains(process.pid);
            return DataRow(
              selected: isSelected,
              cells: [
                if (_isSelectionMode)
                  DataCell(
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleSelection(process),
                    ),
                  ),
                DataCell(
                  Tooltip(
                    message: process.command ?? process.name,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getCpuColor(process.cpuPercent),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            process.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(Text('${process.pid}')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${process.cpuPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getCpuColor(process.cpuPercent),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(process.memoryFormatted)),
                DataCell(
                  Text(
                    process.user,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
                DataCell(
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, size: 18),
                    itemBuilder: (context) => [
                      if (_isSelectionMode)
                        PopupMenuItem(
                          value: 'select',
                          child: Row(
                            children: [
                              Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, size: 18),
                              const SizedBox(width: 8),
                              Text(isSelected ? 'Deseleziona' : 'Seleziona'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'kill',
                        child: Row(
                          children: [
                            const Icon(Icons.stop, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.kill),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'kill_force',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.killForce),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'select') {
                        _toggleSelection(process);
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
    );
  }

  Widget _buildSystemInfoTab() {
    if (_isLoading && _systemInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_systemInfo == null) {
      return Center(child: Text(AppLocalizations.of(context)!.cannotLoadSystemInfo));
    }

    final info = _systemInfo!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCpuCard(info.cpu),
          const SizedBox(height: 16),
          _buildMemoryCard(info.memory),
          const SizedBox(height: 16),
          _buildDisksCard(info.disks),
          if (info.gpu != null) ...[
            const SizedBox(height: 16),
            _buildGpuCard(info.gpu!),
          ],
        ],
      ),
    );
  }

  Widget _buildCpuCard(CpuInfo cpu) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CPU',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.model}: ${cpu.model}'),
            Text('${AppLocalizations.of(context)!.cores}: ${cpu.cores} | ${AppLocalizations.of(context)!.threads}: ${cpu.threads}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context)!.usage}: ${cpu.usagePercent.toStringAsFixed(1)}%'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: cpu.usagePercent / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCpuColor(cpu.usagePercent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(MemoryInfo memory) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Memoria',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.total}: ${memory.formatBytes(memory.totalBytes)}'),
            Text('${AppLocalizations.of(context)!.used}: ${memory.formatBytes(memory.usedBytes)}'),
            Text('${AppLocalizations.of(context)!.free}: ${memory.formatBytes(memory.freeBytes)}'),
            Text('${AppLocalizations.of(context)!.cache}: ${memory.formatBytes(memory.cachedBytes)}'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${AppLocalizations.of(context)!.usage}: ${memory.usagePercent.toStringAsFixed(1)}%'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: memory.usagePercent / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getMemoryColor(memory.usagePercent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (memory.swapTotalBytes > 0) ...[
              const SizedBox(height: 16),
              Text('${AppLocalizations.of(context)!.swap}: ${memory.formatBytes(memory.swapUsedBytes)} / ${memory.formatBytes(memory.swapTotalBytes)} (${memory.swapUsagePercent.toStringAsFixed(1)}%)'),
              LinearProgressIndicator(
                value: memory.swapUsagePercent / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getMemoryColor(memory.swapUsagePercent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisksCard(List<DiskInfo> disks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dischi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...disks.map((disk) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            disk.isExternal ? Icons.usb : Icons.storage,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${disk.device} (${disk.mountPoint})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (disk.isExternal)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Esterno',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${AppLocalizations.of(context)!.filesystem}: ${disk.fileSystem}'),
                      Text(
                        '${AppLocalizations.of(context)!.used}: ${disk.formatBytes(disk.usedBytes)} / ${disk.formatBytes(disk.totalBytes)} (${disk.usagePercent.toStringAsFixed(1)}%)',
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: disk.usagePercent / 100,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getDiskColor(disk.usagePercent),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGpuCard(GpuInfo gpu) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scheda Video',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('${AppLocalizations.of(context)!.model}: ${gpu.model}'),
            Text('${AppLocalizations.of(context)!.driver}: ${gpu.driver}'),
            if (gpu.usagePercent != null) ...[
              const SizedBox(height: 8),
              Text('${AppLocalizations.of(context)!.usage}: ${gpu.usagePercent!.toStringAsFixed(1)}%'),
              LinearProgressIndicator(
                value: gpu.usagePercent! / 100,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getCpuColor(gpu.usagePercent!),
                ),
              ),
            ],
            if (gpu.memoryTotalBytes != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.memory}: ${gpu.memoryUsedBytes != null ? _formatBytes(gpu.memoryUsedBytes!) : 'N/A'} / '
                '${_formatBytes(gpu.memoryTotalBytes!)}',
              ),
              if (gpu.memoryUsagePercent != null)
                LinearProgressIndicator(
                  value: gpu.memoryUsagePercent! / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getMemoryColor(gpu.memoryUsagePercent!),
                  ),
                ),
            ],
            if (gpu.temperature != null)
              Text('${AppLocalizations.of(context)!.temperature}: ${gpu.temperature!.toStringAsFixed(1)}${AppLocalizations.of(context)!.temperatureUnit}'),
          ],
        ),
      ),
    );
  }

  Color _getCpuColor(double percent) {
    if (percent < 50) return Colors.green;
    if (percent < 80) return Colors.orange;
    return Colors.red;
  }

  Color _getMemoryColor(double percent) {
    if (percent < 60) return Colors.green;
    if (percent < 85) return Colors.orange;
    return Colors.red;
  }

  Color _getDiskColor(double percent) {
    if (percent < 70) return Colors.green;
    if (percent < 90) return Colors.orange;
    return Colors.red;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}

