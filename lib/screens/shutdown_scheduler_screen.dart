import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/shutdown_scheduler_service.dart';
import '../services/password_storage.dart';

class ShutdownSchedulerScreen extends StatefulWidget {
  const ShutdownSchedulerScreen({super.key});

  @override
  State<ShutdownSchedulerScreen> createState() => _ShutdownSchedulerScreenState();
}

class _ShutdownSchedulerScreenState extends State<ShutdownSchedulerScreen> {
  bool _isLoading = false;
  bool _systemdAvailable = false;
  Map<String, Map<String, dynamic>> _timerStatuses = {};
  
  // Form state
  String _selectedScheduleType = 'daily';
  TimeOfDay _selectedTime = const TimeOfDay(hour: 22, minute: 0);
  Set<int> _selectedDaysOfWeek = {};
  int? _selectedDayOfMonth;

  @override
  void initState() {
    super.initState();
    _checkSystemd();
    _loadTimerStatuses();
  }

  Future<void> _checkSystemd() async {
    final available = await ShutdownSchedulerService.isSystemdAvailable();
    setState(() {
      _systemdAvailable = available;
    });
  }

  Future<void> _loadTimerStatuses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final timers = await ShutdownSchedulerService.getAllTimers();
      final statuses = <String, Map<String, dynamic>>{};
      
      for (final timer in timers) {
        statuses[timer['type'] as String] = timer;
      }
      
      // Carica anche i timer che potrebbero non essere attivi
      for (final type in ['daily', 'weekly', 'monthly']) {
        if (!statuses.containsKey(type)) {
          final status = await ShutdownSchedulerService.getTimerStatus(type);
          statuses[type] = status;
        }
      }
      
      setState(() {
        _timerStatuses = statuses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createTimer() async {
    // Verifica password
    final hasPassword = await PasswordStorage.hasPassword();
    if (!hasPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shutdownPasswordRequired),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Valida i parametri
    if (_selectedScheduleType == 'weekly' && _selectedDaysOfWeek.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shutdownWeeklyDaysRequired),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_selectedScheduleType == 'monthly' && _selectedDayOfMonth == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shutdownMonthlyDayRequired),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final timeStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      
      // Rimuovi il timer esistente se presente
      final existingStatus = _timerStatuses[_selectedScheduleType];
      if (existingStatus != null && existingStatus['exists'] == true) {
        await ShutdownSchedulerService.removeShutdownTimer(_selectedScheduleType);
      }
      
      // Crea il nuovo timer
      await ShutdownSchedulerService.createShutdownTimer(
        scheduleType: _selectedScheduleType,
        time: timeStr,
        daysOfWeek: _selectedScheduleType == 'weekly' ? _selectedDaysOfWeek.toList() : null,
        dayOfMonth: _selectedScheduleType == 'monthly' ? _selectedDayOfMonth : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shutdownTimerCreated),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadTimerStatuses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeTimer(String scheduleType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirm),
        content: Text(AppLocalizations.of(context)!.shutdownRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ShutdownSchedulerService.removeShutdownTimer(scheduleType);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.shutdownTimerRemoved),
            backgroundColor: Colors.green,
          ),
        );
      }

      await _loadTimerStatuses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getScheduleTypeName(String type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'daily':
        return l10n.shutdownScheduleDaily;
      case 'weekly':
        return l10n.shutdownScheduleWeekly;
      case 'monthly':
        return l10n.shutdownScheduleMonthly;
      default:
        return type;
    }
  }

  String _getDayName(int day) {
    final l10n = AppLocalizations.of(context)!;
    switch (day) {
      case 0:
        return l10n.shutdownDaySunday;
      case 1:
        return l10n.shutdownDayMonday;
      case 2:
        return l10n.shutdownDayTuesday;
      case 3:
        return l10n.shutdownDayWednesday;
      case 4:
        return l10n.shutdownDayThursday;
      case 5:
        return l10n.shutdownDayFriday;
      case 6:
        return l10n.shutdownDaySaturday;
      default:
        return '';
    }
  }
  
  Future<void> _editTimer(String scheduleType) async {
    try {
      final details = await ShutdownSchedulerService.getTimerDetails(scheduleType);
      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context)!.error}: Timer non trovato'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Popola il form con i dettagli esistenti
      setState(() {
        _selectedScheduleType = details['type'] as String? ?? scheduleType;
        
        final timeStr = details['time'] as String?;
        if (timeStr != null) {
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            _selectedTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 22,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        
        if (details['daysOfWeek'] != null) {
          _selectedDaysOfWeek = Set<int>.from(details['daysOfWeek'] as List);
        } else {
          _selectedDaysOfWeek.clear();
        }
        
        _selectedDayOfMonth = details['dayOfMonth'] as int?;
      });
      
      // Scrolla al form e mostra messaggio
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.shutdownEditTimer}: ${_getScheduleTypeName(scheduleType)}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabShutdownScheduler),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_systemdAvailable
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    l10n.shutdownSystemdRequired,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.shutdownSystemdRequiredDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        l10n.shutdownInfoTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.shutdownInfoDescription,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Timer attivi
          if (_timerStatuses.isNotEmpty) ...[
            Text(
              l10n.shutdownActiveTimers,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._timerStatuses.entries.map((entry) {
              final type = entry.key;
              final status = entry.value;
              final exists = status['exists'] == true;
              final active = status['active'] == true;
              final nextRun = status['nextRun'] as String?;
              
              if (!exists) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    active ? Icons.check_circle : Icons.error_outline,
                    color: active ? Colors.green : Colors.orange,
                  ),
                  title: Text(_getScheduleTypeName(type)),
                  subtitle: nextRun != null
                      ? Text('${l10n.shutdownNextRun}: $nextRun')
                      : Text(l10n.shutdownStatusInactive),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editTimer(type),
                        color: Colors.blue,
                        tooltip: l10n.shutdownEditTimer,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeTimer(type),
                        color: Colors.red,
                      ),
                    ],
                  ),
                  onTap: () => _editTimer(type),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          
          // Form per creare nuovo timer
          Text(
            l10n.shutdownCreateTimer,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tipo di programmazione
                  Text(
                    l10n.shutdownScheduleType,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'daily',
                        label: Text(l10n.shutdownScheduleDaily),
                      ),
                      ButtonSegment(
                        value: 'weekly',
                        label: Text(l10n.shutdownScheduleWeekly),
                      ),
                      ButtonSegment(
                        value: 'monthly',
                        label: Text(l10n.shutdownScheduleMonthly),
                      ),
                    ],
                    selected: {_selectedScheduleType},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedScheduleType = newSelection.first;
                        _selectedDaysOfWeek.clear();
                        _selectedDayOfMonth = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Selezione ora
                  Text(
                    l10n.shutdownTime,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(l10n.shutdownSelectTime),
                    subtitle: Text(
                      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    onTap: _selectTime,
                  ),
                  const SizedBox(height: 16),
                  
                  // Giorni della settimana (solo per weekly)
                  if (_selectedScheduleType == 'weekly') ...[
                    Text(
                      l10n.shutdownSelectDays,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(7, (index) {
                        final day = index;
                        final isSelected = _selectedDaysOfWeek.contains(day);
                        return FilterChip(
                          label: Text(_getDayName(day)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDaysOfWeek.add(day);
                              } else {
                                _selectedDaysOfWeek.remove(day);
                              }
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Giorno del mese (solo per monthly)
                  if (_selectedScheduleType == 'monthly') ...[
                    Text(
                      l10n.shutdownSelectDayOfMonth,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedDayOfMonth,
                      decoration: InputDecoration(
                        labelText: l10n.shutdownDayOfMonth,
                        border: const OutlineInputBorder(),
                      ),
                      items: List.generate(31, (index) {
                        final day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text('$day'),
                        );
                      }),
                      onChanged: (value) {
                        setState(() {
                          _selectedDayOfMonth = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Pulsante crea
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createTimer,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(l10n.shutdownCreateTimer),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
            ),
    );
  }
}
