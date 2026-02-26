import 'dart:async';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/installed_app.dart';
import '../services/app_manager.dart';

class InstalledAppsScreen extends StatefulWidget {
  const InstalledAppsScreen({super.key});

  @override
  State<InstalledAppsScreen> createState() => _InstalledAppsScreenState();
}

class _InstalledAppsScreenState extends State<InstalledAppsScreen> with AutomaticKeepAliveClientMixin {
  List<InstalledApp> _apps = [];
  List<InstalledApp> _filteredApps = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  PackageManager? _selectedPackageManager;
  Timer? _searchDebounceTimer;
  
  // Memoization
  String? _cachedSearchQuery;
  PackageManager? _cachedPackageManager;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _apps = [];
      _filteredApps = [];
    });

    try {
      // Carica le app in modo incrementale per mostrare progresso
      final aptApps = <InstalledApp>[];
      final snapApps = <InstalledApp>[];
      final flatpakApps = <InstalledApp>[];
      final gnomeApps = <InstalledApp>[];
      
      // Carica in parallelo
      await Future.wait([
        AppManager.getAptApps().then((apps) {
          aptApps.addAll(apps);
        }),
        AppManager.getSnapApps().then((apps) {
          snapApps.addAll(apps);
        }),
        AppManager.getFlatpakApps().then((apps) {
          flatpakApps.addAll(apps);
        }),
        AppManager.getGnomeApps().then((apps) {
          gnomeApps.addAll(apps);
        }),
      ]);
      
      final allApps = [...aptApps, ...snapApps, ...flatpakApps, ...gnomeApps];
      
      setState(() {
        _apps = allApps;
        _filteredApps = allApps;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _applyFilters() {
    // Memoization: riutilizza se i parametri non sono cambiati
    if (_cachedSearchQuery == _searchQuery && 
        _cachedPackageManager == _selectedPackageManager &&
        _filteredApps.isNotEmpty) {
      return;
    }
    
    setState(() {
      _filteredApps = _apps.where((app) {
        // Filtro per package manager
        if (_selectedPackageManager != null && app.packageManager != _selectedPackageManager) {
          return false;
        }
        
        // Filtro per ricerca
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return app.name.toLowerCase().contains(query) ||
              (app.description?.toLowerCase().contains(query) ?? false);
        }
        
        return true;
      }).toList();
      
      _cachedSearchQuery = _searchQuery;
      _cachedPackageManager = _selectedPackageManager;
    });
  }

  Future<void> _removeApp(InstalledApp app) async {
    // Controlla le dipendenze solo quando necessario (prima della rimozione)
    InstalledApp appWithDeps = app;
    if (app.packageManager == PackageManager.apt && 
        (app.dependencies.isEmpty && app.reverseDependencies.isEmpty)) {
      // Mostra dialog di caricamento mentre controlla dipendenze
      if (!mounted) return;
      final navigator = Navigator.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.checkingDependencies),
                ],
              ),
            ),
          ),
        ),
      );
      
      try {
        appWithDeps = await AppManager.checkAppDependencies(app);
      } finally {
        if (mounted) {
          navigator.pop(); // Chiudi dialog di caricamento
        }
      }
    }
    
    // Mostra avviso se necessario
    if (!mounted) return;
    final warning = appWithDeps.warningMessage;
    if (warning != null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.warning),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(warning),
              const SizedBox(height: 16),
              if (appWithDeps.reverseDependencies.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.packagesDependingOnThis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...appWithDeps.reverseDependencies.take(5).map((dep) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text('• $dep'),
                    )),
                if (appWithDeps.reverseDependencies.length > 5)
                  Text('... e altri ${appWithDeps.reverseDependencies.length - 5}'),
              ],
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.areYouSure,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)!.remove,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    } else {
      // Conferma normale
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmRemoval),
          content: Text(AppLocalizations.of(context)!.removeAppQuestion(app.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                AppLocalizations.of(context)!.remove,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    // Mostra dialog di progresso
    if (!mounted) return;
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.removing),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final success = await AppManager.removeApp(appWithDeps);
      
      if (mounted) {
        navigator.pop(); // Chiudi dialog di progresso
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'App ${app.name} rimossa con successo'
                  : 'Errore durante la rimozione di ${app.name}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        if (success) {
          _loadApps();
        }
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Chiudi dialog di progresso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPackageManagerName(PackageManager pm) {
    switch (pm) {
      case PackageManager.apt:
        return 'APT';
      case PackageManager.snap:
        return 'Snap';
      case PackageManager.flatpak:
        return 'Flatpak';
      case PackageManager.gnome:
        return 'GNOME';
    }
  }

  IconData _getPackageManagerIcon(PackageManager pm) {
    switch (pm) {
      case PackageManager.apt:
        return Icons.inventory;
      case PackageManager.snap:
        return Icons.circle;
      case PackageManager.flatpak:
        return Icons.apps;
      case PackageManager.gnome:
        return Icons.desktop_windows;
    }
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
                          labelText: AppLocalizations.of(context)!.searchApp,
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          // Debouncing per la ricerca
                          _searchDebounceTimer?.cancel();
                          _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              setState(() {
                                _searchQuery = value;
                              });
                              _applyFilters();
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _loadApps,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(AppLocalizations.of(context)!.all),
                        selected: _selectedPackageManager == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedPackageManager = null;
                            });
                            _applyFilters();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ...PackageManager.values.map((pm) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getPackageManagerName(pm)),
                            selected: _selectedPackageManager == pm,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPackageManager = selected ? pm : null;
                              });
                              _applyFilters();
                            },
                          ),
                        );
                      }),
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
          if (_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Caricamento app installate...\n${_apps.length} app trovate',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _filteredApps.isEmpty
                  ? const SizedBox.shrink() // Mostra elenco vuoto invece del messaggio
                  : ListView.builder(
                      itemCount: _filteredApps.length,
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getPackageManagerIcon(app.packageManager),
                              color: app.canSafelyRemove
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                            title: Text(
                              app.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (app.version != null)
                                  Text('${AppLocalizations.of(context)!.versionLabel} ${app.version}'),
                                if (app.description != null && app.description!.isNotEmpty)
                                  Text(app.description!),
                                Text(
                                  'Gestore: ${_getPackageManagerName(app.packageManager)}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (!app.canSafelyRemove && app.warningMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orange),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              app.warningMessage!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Rimuovi', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'remove') {
                                  _removeApp(app);
                                }
                              },
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

