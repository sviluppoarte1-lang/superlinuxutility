import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../models/systemd_service.dart';
import '../services/system_analyzer.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  List<SystemdService> _services = [];
  List<SystemdService> _slowServices = [];
  List<SystemdService> _disabledServices = [];
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Carica i servizi solo quando necessario (lazy loading)
      if (_tabController.index == 1 && _services.isEmpty && !_isAnalyzing) {
        _analyzeAllServices();
      }
    });
    _loadSlowServices();
    _loadDisabledServices();
    // NON caricare tutti i servizi all'avvio - solo quando necessario
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSlowServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final slowServices = await SystemAnalyzer.getSlowServices();
      setState(() {
        _slowServices = slowServices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDisabledServices() async {
    try {
      final disabledServices = await SystemAnalyzer.getDisabledServices();
      setState(() {
        _disabledServices = disabledServices;
      });
    } catch (e) {
      // Ignora errori silenziosamente per i servizi disabilitati
    }
  }

  Future<void> _analyzeAllServices() async {
    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final services = await SystemAnalyzer.analyzeSystemdServices();
      setState(() {
        _services = services;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _disableService(SystemdService service) async {
    try {
      final success = await SystemAnalyzer.disableService(service.name);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servizio ${service.name} disabilitato'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSlowServices();
          _loadDisabledServices();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante la disabilitazione'),
              backgroundColor: Colors.red,
            ),
          );
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

  Future<void> _enableService(SystemdService service) async {
    try {
      final success = await SystemAnalyzer.enableService(service.name);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servizio ${service.name} riabilitato'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSlowServices();
          _loadDisabledServices();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante la riabilitazione'),
              backgroundColor: Colors.red,
            ),
          );
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

  Future<void> _stopService(SystemdService service) async {
    try {
      final success = await SystemAnalyzer.stopService(service.name);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Servizio ${service.name} fermato'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSlowServices();
          _loadDisabledServices();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'arresto'),
              backgroundColor: Colors.red,
            ),
          );
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

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  Widget _buildServiceList(List<SystemdService> services, {bool showEnableOption = false}) {
    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            AppLocalizations.of(context)!.noServicesFound,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            leading: Icon(
              service.isSlow
                  ? Icons.warning
                  : service.isEnabled
                      ? Icons.check_circle
                      : Icons.block,
              color: service.isSlow
                  ? Colors.orange
                  : service.isEnabled
                      ? Colors.green
                      : Colors.grey,
            ),
            title: Text(
              service.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppLocalizations.of(context)!.status}: ${service.status}'),
                Text(
                  '${AppLocalizations.of(context)!.enabled}: ${service.isEnabled ? AppLocalizations.of(context)!.yes : AppLocalizations.of(context)!.no}',
                  style: TextStyle(
                    color: service.isEnabled ? Colors.green : Colors.grey,
                  ),
                ),
                if (service.bootTime != null)
                  Text(
                    '${AppLocalizations.of(context)!.startupTime}: ${_formatDuration(service.bootTime)}',
                    style: TextStyle(
                      color: service.isSlow ? Colors.orange : null,
                      fontWeight: service.isSlow ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                if (service.description != null)
                  Text(service.description!),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                if (showEnableOption && !service.isEnabled)
                  PopupMenuItem(
                    value: 'enable',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.reEnable),
                      ],
                    ),
                  ),
                if (service.isEnabled)
                  PopupMenuItem(
                    value: 'disable',
                    child: Row(
                      children: [
                        const Icon(Icons.block),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.disable),
                      ],
                    ),
                  ),
                if (service.isActive)
                  PopupMenuItem(
                    value: 'stop',
                    child: Row(
                      children: [
                        const Icon(Icons.stop),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.stop),
                      ],
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'disable') {
                  _disableService(service);
                } else if (value == 'enable') {
                  _enableService(service);
                } else if (value == 'stop') {
                  _stopService(service);
                }
              },
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Richiesto per AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () {
                      _loadSlowServices();
                      _loadDisabledServices();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.refresh),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _analyzeAllServices,
                    icon: const Icon(Icons.search),
                    label: Text(AppLocalizations.of(context)!.analyzeAll),
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
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                icon: const Icon(Icons.warning),
                text: AppLocalizations.of(context)!.servicesSlow,
              ),
              Tab(
                icon: const Icon(Icons.list),
                text: AppLocalizations.of(context)!.servicesAll,
              ),
              Tab(
                icon: const Icon(Icons.block),
                text: AppLocalizations.of(context)!.servicesDisabled,
              ),
            ],
          ),
          if (_isLoading || _isAnalyzing)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildServiceList(_slowServices),
                  _buildServiceList(_services),
                  _buildServiceList(_disabledServices, showEnableOption: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
