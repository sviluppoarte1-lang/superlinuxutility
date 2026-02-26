import 'package:flutter/material.dart';
import 'dart:io';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/cleanup_service.dart';

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
  String? _error;
  Set<String> _excludedPaths = {};

  @override
  void initState() {
    super.initState();
    _loadExcludedPaths();
    _loadSizes();
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

  int _getTotalSize() {
    return _sizes.values.fold(0, (sum, size) => sum + size);
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
                  onPressed: _isCleaningCache ? null : _cleanLinuxCache,
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

