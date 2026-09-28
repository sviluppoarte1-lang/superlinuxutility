import 'package:flutter/material.dart';
import 'dart:io';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/cleanup_service.dart';
import '../services/advanced_cleanup_service.dart';
import '../services/ram_cleanup_service.dart';
import '../services/tray_service.dart';

class CleanupScreen extends StatefulWidget {
  const CleanupScreen({super.key});

  @override
  State<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends State<CleanupScreen> {
  Map<String, int> _sizes = {};
  Map<String, bool>? _cleanupResults;
  bool _isLoading = false;
  bool _isCleaning = false;
  bool _isCleaningCache = false;
  bool _isCleaningRam = false;
  RamStats? _ramStats;
  RamCleanupResult? _ramResult;
  String? _error;
  Set<String> _excludedPaths = {};
  // Pulizia avanzata (log + cache sviluppo)
  List<DevCacheInfo> _devCaches = [];
  Set<String> _devSelected = {};
  bool _devLoading = false;
  bool _devLoaded = false;
  bool _advCleaning = false;
  int? _journalBytes;
  bool _journalLoading = false;
  String? _journalLimit;
  String _vacuumTarget = '500M';
  String _limitTarget = '500M';
  bool _journalBusy = false;

  @override
  void initState() {
    super.initState();
    _loadExcludedPaths();
    _loadSizes();
    _loadRamStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (TrayService.runCleanupWhenScreenShown) {
        TrayService.runCleanupWhenScreenShown = false;
        _cleanupFromTray();
      }
    });
  }

  Future<void> _loadExcludedPaths() async {
    final excluded = await CleanupService.getExcludedPaths();
    setState(() {
      _excludedPaths = excluded;
    });
  }

  Future<void> _toggleExclude(String path) async {
    setState(() {
      if (_excludedPaths.contains(path)) {
        _excludedPaths.remove(path);
      } else {
        _excludedPaths.add(path);
      }
    });
    await CleanupService.setExcludedPaths(_excludedPaths);
    // Ricarica le dimensioni per aggiornare la lista
    await _loadSizes();
  }

  Future<void> _showAddExclusionDialog() async {
    final TextEditingController pathController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addExcludedFolder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.enterFolderPath),
            const SizedBox(height: 16),
            TextField(
              controller: pathController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.folderPath,
                hintText: '/path/to/folder',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final path = pathController.text.trim();
              if (path.isNotEmpty) {
                Navigator.pop(context, path);
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Normalizza il path
      String normalizedPath = result;
      if (!normalizedPath.startsWith('/')) {
        // Se è un path relativo, prova a risolvere
        final homeDir = Platform.environment['HOME'] ?? '';
        if (normalizedPath.startsWith('~')) {
          normalizedPath = normalizedPath.replaceFirst('~', homeDir);
        } else {
          normalizedPath = '$homeDir/$normalizedPath';
        }
      }
      
      // Verifica che il path esista
      final dir = Directory(normalizedPath);
      if (await dir.exists()) {
        setState(() {
          _excludedPaths.add(normalizedPath);
        });
        await CleanupService.setExcludedPaths(_excludedPaths);
        await _loadSizes();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.folderExcluded),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.folderNotFound),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadSizes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sizes = await CleanupService.getTempFilesSize();
      setState(() {
        _sizes = sizes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Esegue la pulizia quando la schermata è stata aperta dalla system tray (senza dialog).
  Future<void> _cleanupFromTray() async {
    setState(() {
      _isCleaning = true;
      _error = null;
      _cleanupResults = null;
    });

    try {
      final results = await CleanupService.cleanupTempFiles();
      if (mounted) {
        setState(() {
          _cleanupResults = results;
          _isCleaning = false;
        });
        await _loadSizes();
        final allSuccess = results.values.every((success) => success);
        final message = allSuccess
            ? (AppLocalizations.of(context)!.cleanupSuccess)
            : (AppLocalizations.of(context)!.cleanupPartialSuccess);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: allSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isCleaning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cleanup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.cleanupConfirmTitle),
        content: Text(
          AppLocalizations.of(context)!.cleanupConfirmMessage,
        ),
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
      _isCleaning = true;
      _error = null;
      _cleanupResults = null;
    });

    try {
      final results = await CleanupService.cleanupTempFiles();
      setState(() {
        _cleanupResults = results;
        _isCleaning = false;
      });

      // Ricarica le dimensioni dopo la pulizia
      await _loadSizes();

      if (mounted) {
        final allSuccess = results.values.every((success) => success);
        final failedPaths = results.entries
            .where((entry) => !entry.value)
            .map((entry) => entry.key)
            .toList();
        
        String message;
        if (allSuccess) {
          message = AppLocalizations.of(context)!.cleanupSuccess;
        } else {
          message = '${AppLocalizations.of(context)!.cleanupPartialSuccess}\n';
          if (failedPaths.isNotEmpty) {
            final shortPaths = failedPaths.map((p) {
              final parts = p.split('/');
              return parts.length > 1 ? '.../${parts.last}' : p;
            }).toList();
            message += '${AppLocalizations.of(context)!.foldersWithErrors} ${shortPaths.take(3).join(", ")}';
            if (shortPaths.length > 3) {
              message += ' ${AppLocalizations.of(context)!.andOthers(shortPaths.length - 3)}';
            }
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: allSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCleaning = false;
      });
    }
  }

  Future<void> _cleanLinuxCache() async {
    setState(() {
      _isCleaningCache = true;
      _error = null;
    });
    try {
      final result = await CleanupService.dropLinuxCache();
      if (mounted) {
        setState(() => _isCleaningCache = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? (AppLocalizations.of(context)!.cleanupLinuxCacheSuccess)
                  : (AppLocalizations.of(context)!.cleanupLinuxCacheError),
            ),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCleaningCache = false;
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.cleanupLinuxCacheError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRamStats() async {
    final stats = await RamCleanupService.getRamStats();
    if (mounted) {
      setState(() {
        _ramStats = stats;
      });
    }
  }

  Future<void> _cleanRam() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ramCleanupConfirmTitle),
        content: Text(
          l10n.ramCleanupConfirmMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.ramCleanup,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isCleaningRam = true;
      _error = null;
      _ramResult = null;
    });

    try {
      final result = await RamCleanupService.cleanupRam();
      if (mounted) {
        setState(() {
          _ramResult = result;
          _isCleaningRam = false;
          _ramStats = result.after;
        });
        final freed = result.freedBytes ?? 0;
        final message = freed > 0
            ? '${l10n.ramCleanupSuccess}: ${RamCleanupService.formatSize(freed)}'
            : l10n.ramCleanupSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: result.success ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCleaningRam = false;
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getTotalSize() {
    return _sizes.values.fold(0, (sum, size) => sum + size);
  }

  Future<void> _loadAdvanced() async {
    if (!mounted) return;
    setState(() {
      _devLoading = true;
      _journalLoading = true;
    });
    try {
      final dev = await AdvancedCleanupService.getDevCaches();
      final jb = await AdvancedCleanupService.getJournalBytes();
      final limit = await AdvancedCleanupService.getJournalSystemMaxUse();
      if (!mounted) return;
      setState(() {
        _devCaches = dev;
        _devLoaded = true;
        _devLoading = false;
        // Seleziona tutto di default (tranne kernel: prudenza).
        _devSelected = dev
            .where((d) => d.id != 'kernel-headers')
            .map((d) => d.id)
            .toSet();
        _journalBytes = jb;
        _journalLoading = false;
        _journalLimit = limit;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _devLoading = false;
          _journalLoading = false;
        });
      }
    }
  }

  Future<void> _cleanSelectedDev() async {
    if (_devSelected.isEmpty || !mounted) return;
    setState(() => _advCleaning = true);
    var okCount = 0;
    for (final id in _devSelected.toList()) {
      try {
        if (await AdvancedCleanupService.cleanDevCache(id)) okCount++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _advCleaning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(okCount == _devSelected.length
            ? AppLocalizations.of(context)!.advCleaned
            : AppLocalizations.of(context)!.advFailed),
        backgroundColor:
            okCount == _devSelected.length ? Colors.green : Colors.orange,
      ),
    );
    await _loadAdvanced();
    await _loadSizes();
  }

  Future<void> _vacuumJournal() async {
    if (!mounted) return;
    setState(() => _journalBusy = true);
    try {
      final ok =
          await AdvancedCleanupService.vacuumJournal(_vacuumTarget);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? AppLocalizations.of(context)!.advCleaned
              : AppLocalizations.of(context)!.advFailed),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      await _loadAdvanced();
    } finally {
      if (mounted) setState(() => _journalBusy = false);
    }
  }

  Future<void> _applyJournalLimit() async {
    if (!mounted) return;
    setState(() => _journalBusy = true);
    try {
      final ok = await AdvancedCleanupService.setJournalSystemMaxUse(
          _limitTarget);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? AppLocalizations.of(context)!.advCleaned
              : AppLocalizations.of(context)!.advFailed),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      await _loadAdvanced();
    } finally {
      if (mounted) setState(() => _journalBusy = false);
    }
  }

  String _devTitle(AppLocalizations l10n, String id) {
    switch (id) {
      case 'pip':
        return l10n.devPip;
      case 'cargo':
        return l10n.devCargo;
      case 'npm':
        return l10n.devNpm;
      case 'go':
        return l10n.devGo;
      case 'gradle':
        return l10n.devGradle;
      case 'docker':
        return l10n.devDocker;
      case 'kernel-headers':
        return l10n.devKernelHeaders;
      default:
        return id;
    }
  }

  Color _devColor(String id) {
    switch (id) {
      case 'pip':
        return Colors.blue;
      case 'cargo':
        return Colors.brown;
      case 'npm':
        return Colors.red;
      case 'go':
        return Colors.cyan;
      case 'gradle':
        return Colors.green;
      case 'docker':
        return Colors.indigo;
      case 'kernel-headers':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _devIcon(String id) {
    switch (id) {
      case 'pip':
        return Icons.code;
      case 'cargo':
        return Icons.construction;
      case 'npm':
        return Icons.javascript;
      case 'go':
        return Icons.play_arrow;
      case 'gradle':
        return Icons.build;
      case 'docker':
        return Icons.inventory;
      case 'kernel-headers':
        return Icons.memory;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loadSizes,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.of(context)!.refreshDimensions),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isCleaning || _isLoading) ? null : _cleanup,
                        icon: const Icon(Icons.cleaning_services),
                        label: Text(AppLocalizations.of(context)!.cleanupTempFiles),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _showAddExclusionDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(AppLocalizations.of(context)!.addExcludedFolder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _isCleaning || _isCleaningCache)
                      ? null
                      : _cleanLinuxCache,
                  icon: _isCleaningCache
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.memory),
                  label: Text(AppLocalizations.of(context)!.cleanupLinuxCache),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (_ramStats != null)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.speed, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.ramCleanupTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _RamStatItem(
                            label: AppLocalizations.of(context)!.ramUsed,
                            value: RamCleanupService.formatSize(
                              _ramStats!.usedBytes,
                            ),
                            valueColor: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _RamStatItem(
                            label: AppLocalizations.of(context)!.ramAvailable,
                            value: RamCleanupService.formatSize(
                              _ramStats!.availableBytes,
                            ),
                            valueColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _RamStatItem(
                            label: AppLocalizations.of(context)!.ramCache,
                            value: RamCleanupService.formatSize(
                              _ramStats!.cachedBytes,
                            ),
                            valueColor: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _RamStatItem(
                            label: AppLocalizations.of(context)!.ramSwap,
                            value: _ramStats!.hasSwap
                                ? '${RamCleanupService.formatSize(_ramStats!.swapUsedBytes)} / ${RamCleanupService.formatSize(_ramStats!.swapTotalBytes)}'
                                : AppLocalizations.of(context)!.ramSwapNone,
                            valueColor: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    if (_ramResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _ramResult!.freedBytes != null &&
                                      _ramResult!.freedBytes! > 0
                                  ? '${AppLocalizations.of(context)!.ramFreed}: ${RamCleanupService.formatSize(_ramResult!.freedBytes!)}'
                                  : AppLocalizations.of(context)!.ramCleanupSuccess,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _ramResult!.success
                                    ? Colors.green
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            if (_ramResult!.before != null &&
                                _ramResult!.after != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${AppLocalizations.of(context)!.ramBefore}: ${RamCleanupService.formatSize(_ramResult!.before!.usedBytes)}  →  ${AppLocalizations.of(context)!.ramAfter}: ${RamCleanupService.formatSize(_ramResult!.after!.usedBytes)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                            if (_ramResult!.stepsFailed.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${AppLocalizations.of(context)!.ramStepsFailed}: ${_ramResult!.stepsFailed.join(", ")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: (_isCleaningRam || _isCleaning || _isLoading)
                          ? null
                          : _cleanRam,
                      icon: _isCleaningRam
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cleaning_services),
                      label: Text(AppLocalizations.of(context)!.ramCleanup),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: ExpansionTile(
              leading: const Icon(Icons.cleaning_services,
                  size: 22, color: Colors.teal),
              title: Text(
                AppLocalizations.of(context)!.advCleanupTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onExpansionChanged: (expanded) {
                if (expanded && !_devLoaded && !_devLoading) {
                  _loadAdvanced();
                }
              },
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_devLoading || _journalLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        ..._devCaches.map((d) {
                          final selected =
                              _devSelected.contains(d.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            value: selected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _devSelected.add(d.id);
                                } else {
                                  _devSelected.remove(d.id);
                                }
                              });
                            },
                            secondary: Icon(
                              _devIcon(d.id),
                              color: _devColor(d.id),
                            ),
                            title: Text(
                              _devTitle(
                                  AppLocalizations.of(context)!,
                                  d.id),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${d.subtitle}\n${CleanupService.formatSize(d.sizeBytes)}',
                            ),
                            isThreeLine: true,
                          );
                        }),
                        if (_devCaches.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Text(AppLocalizations.of(context)!
                                .advEmpty),
                          ),
                        if (_devCaches.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: (_advCleaning ||
                                      _devSelected.isEmpty)
                                  ? null
                                  : _cleanSelectedDev,
                              icon: _advCleaning
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete_sweep),
                              label: Text(
                                  AppLocalizations.of(context)!
                                      .advCleanSelected),
                            ),
                          ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.article,
                                size: 22, color: Colors.brown),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!
                                  .journalTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.journalCurrentSize}: ${_journalBytes != null ? CleanupService.formatSize(_journalBytes!) : '—'}${_journalLimit != null ? ' • ${_journalLimit!}' : ''}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<
                                  String>(
                                value: _vacuumTarget,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!
                                          .journalVacuumTarget,
                                  border:
                                      const OutlineInputBorder(),
                                ),
                                items: const [
                                  '100M',
                                  '250M',
                                  '500M',
                                  '1G',
                                  '2G'
                                ]
                                    .map((s) =>
                                        DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(
                                        () => _vacuumTarget = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _journalBusy
                                  ? null
                                  : _vacuumJournal,
                              icon: const Icon(Icons.compress),
                              label: Text(
                                  AppLocalizations.of(context)!
                                      .journalVacuumNow),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<
                                  String>(
                                value: _limitTarget,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!
                                          .journalLimitLabel,
                                  border:
                                      const OutlineInputBorder(),
                                ),
                                items: const [
                                  '100M',
                                  '250M',
                                  '500M',
                                  '1G',
                                  '2G'
                                ]
                                    .map((s) =>
                                        DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(
                                        () => _limitTarget = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _journalBusy
                                  ? null
                                  : _applyJournalLimit,
                              icon: const Icon(Icons.save),
                              label: Text(
                                  AppLocalizations.of(context)!
                                      .journalLimitApply),
                            ),
                          ],
                        ),
                      ],
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
          if (_isLoading || _isCleaning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (_sizes.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.totalSpaceToFree,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              CleanupService.formatSize(_getTotalSize()),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sizes.length,
                      itemBuilder: (context, index) {
                        final entry = _sizes.entries.elementAt(index);
                        final path = entry.key;
                        final size = entry.value;
                        
                        // Formatta il path per la visualizzazione
                        String displayPath = path.replaceAll(
                          RegExp(r'^/home/[^/]+'),
                          '~',
                        );
                        
                        // Estrai il nome dell'app se possibile
                        String? appName;
                        if (path.contains('/.cache/') || path.contains('/.config/')) {
                          final parts = path.split('/');
                          for (var i = 0; i < parts.length; i++) {
                            if (parts[i] == '.cache' || parts[i] == '.config') {
                              if (i + 1 < parts.length) {
                                appName = parts[i + 1];
                                // Rimuovi prefissi comuni
                                appName = appName
                                    .replaceAll('google-', '')
                                    .replaceAll('microsoft-', '')
                                    .replaceAll('-cache', '')
                                    .replaceAll('cache', '');
                                break;
                              }
                            }
                          }
                        }
                        
                        // Usa il nome dell'app se disponibile, altrimenti il path
                        if (appName != null && appName.isNotEmpty) {
                          displayPath = appName;
                        }

                        final cleanupResult = _cleanupResults?[path];

                        final isExcluded = _excludedPaths.contains(path);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: isExcluded 
                              ? Theme.of(context).colorScheme.surfaceContainerHighest
                              : null,
                          child: ListTile(
                            leading: Icon(
                              cleanupResult == null
                                  ? Icons.folder
                                  : cleanupResult
                                      ? Icons.check_circle
                                      : Icons.error,
                              color: cleanupResult == null
                                  ? (isExcluded ? Colors.grey : Colors.blue)
                                  : cleanupResult
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            title: Text(
                              displayPath,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isExcluded ? TextDecoration.lineThrough : null,
                                color: isExcluded 
                                    ? Theme.of(context).textTheme.bodySmall?.color
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppLocalizations.of(context)!.size}: ${CleanupService.formatSize(size)}',
                                ),
                                if (isExcluded)
                                  Text(
                                    AppLocalizations.of(context)!.excluded,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isExcluded ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: isExcluded 
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).iconTheme.color?.withOpacity(0.6),
                                    size: 24,
                                  ),
                                  onPressed: () => _toggleExclude(path),
                                  tooltip: isExcluded 
                                      ? AppLocalizations.of(context)!.include
                                      : AppLocalizations.of(context)!.exclude,
                                ),
                                if (cleanupResult != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(
                                      cleanupResult
                                          ? Icons.check
                                          : Icons.close,
                                      color: cleanupResult
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RamStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _RamStatItem({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

