import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:process_run/process_run.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/disk_analyzer_service.dart';
import '../services/password_storage.dart';
import '../services/disk_cache_service.dart';

enum SortType { sizeAscending, sizeDescending, alphabetical }

class DiskAnalyzerScreen extends StatefulWidget {
  const DiskAnalyzerScreen({super.key});

  @override
  State<DiskAnalyzerScreen> createState() => _DiskAnalyzerScreenState();
}

class _DiskAnalyzerScreenState extends State<DiskAnalyzerScreen> {
  List<FileSystemItem> _currentItems = [];
  bool _isLoading = false;
  String? _error;
  String _currentPath = '';
  String _selectedBasePath = '';
  List<Map<String, String>> _mountedDisks = [];
  int _selectedDiskIndex = -1;
  Map<String, String>? _selectedDiskInfo;
  Map<String, int>? _selectedDiskBytes; // Spazio in bytes per il grafico
  List<Map<String, dynamic>> _directorySizes = []; // Dimensioni delle directory per il grafico
  
  // Navigazione
  final List<String> _pathHistory = [];
  int _historyIndex = -1;
  bool _showHiddenFiles = false;
  
  // Ordinamento
  SortType _currentSort = SortType.sizeDescending;
  
  // Cache
  bool _isGeneratingCache = false;
  bool _hasShownCacheMessage = false;
  bool _isChartLoading = false;
  /// Invalida aggiornamenti grafico du quando l'utente cambia cartella durante lo scan
  int _chartScanToken = 0;
  /// Evita burst di listDirectory+JSON quando si apre spesso la stessa cartella dalla cache
  int _dirListIncrementalToken = 0;

  @override
  void initState() {
    super.initState();
    _loadMountedDisks();
  }

  Future<void> _loadMountedDisks() async {
    // Il servizio getMountedDisks() già filtra correttamente i dischi:
    // - Esclude mount point di sistema (/boot, /sys, /proc, ecc.)
    // - Include dischi USB/esterni montati in /media, /mnt, /run/media
    // - Include dischi interni aggiuntivi montati manualmente
    final disks = await DiskAnalyzerService.getMountedDisks();
    setState(() {
      _mountedDisks = disks;
    });
  }

  Future<void> _loadDirectory(String path, {bool calculateSizes = false, bool skipHistory = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      // Reset del grafico durante il caricamento quando si naviga
      // skipHistory=true significa che è un caricamento iniziale o dalla cronologia, quindi non resettare
      // skipHistory=false significa che è una nuova navigazione, quindi resetta il grafico
      if (!skipHistory && _currentPath.isNotEmpty) {
        _directorySizes = [];
        _isGeneratingCache = true; // Mostra loading durante la navigazione
      }
    });

    try {
      // Normalizza i percorsi per la cache
      final normalizedPath = path.endsWith('/') && path.length > 1
          ? path.substring(0, path.length - 1)
          : path;
      final normalizedBasePath = _selectedBasePath.isNotEmpty
          ? (_selectedBasePath.endsWith('/') && _selectedBasePath.length > 1
              ? _selectedBasePath.substring(0, _selectedBasePath.length - 1)
              : _selectedBasePath)
          : '/';
      final diskPath = normalizedBasePath.isNotEmpty ? normalizedBasePath : '/';
      
      // Prova a caricare dalla cache solo se siamo nel disco base o in una sottocartella del disco base
      final isBasePath = normalizedPath == diskPath || normalizedPath.startsWith('$diskPath/');
      List<FileSystemItem> items = [];
      
      if (isBasePath && !calculateSizes) {
        // Prova a caricare dalla cache
        final cachedList = await DiskCacheService.loadDirectoryList(diskPath, path);
        if (cachedList != null && cachedList.isNotEmpty) {
          // Converti i dati dalla cache in FileSystemItem
          items = cachedList.map((item) {
            return FileSystemItem(
              path: item['path'] as String,
              name: item['name'] as String,
              size: item['size'] as int? ?? 0,
              isDirectory: item['isDirectory'] as bool? ?? false,
              modified: item['modified'] != null 
                  ? DateTime.tryParse(item['modified'] as String)
                  : null,
              mimeType: item['mimeType'] as String?,
            );
          }).toList();
          
          // Se abbiamo caricato dalla cache, aggiorna l'UI e calcola le dimensioni in background
          final virtualDirs = ['proc', 'sys', 'dev', 'run', 'tmp'];
          final filteredItems = items.where((item) {
            if (!_showHiddenFiles && item.name.startsWith('.')) {
              return false;
            }
            if (item.isDirectory) {
              final dirName = item.name.toLowerCase();
              if (virtualDirs.contains(dirName)) {
                return false;
              }
              if (item.path == '/proc' || item.path == '/sys' || item.path == '/dev' || 
                  item.path == '/run' || item.path == '/tmp' ||
                  item.path.startsWith('/proc/') || item.path.startsWith('/sys/') ||
                  item.path.startsWith('/dev/') || item.path.startsWith('/run/') ||
                  item.path.startsWith('/tmp/')) {
                return false;
              }
            }
            return true;
          }).toList();
          
          setState(() {
            _currentItems = filteredItems;
            _currentPath = path;
            _isLoading = false;
            _sortItems();
            if (!skipHistory) {
              if (_historyIndex < _pathHistory.length - 1) {
                _pathHistory.removeRange(_historyIndex + 1, _pathHistory.length);
              }
              _pathHistory.add(path);
              _historyIndex = _pathHistory.length - 1;
            }
          });
          
          // Calcola le dimensioni in background
          _calculateSizesInBackground(items, diskPath: diskPath, listPath: normalizedPath);
          // Aggiornamento incrementale differito (meno I/O ripetuto)
          _scheduleDirectoryListIncrementalRefresh(diskPath, normalizedPath);
          return;
        }
      }

      // Se non c'è cache: prima volta, carica dal filesystem e genera il file di cache
      items = await DiskAnalyzerService.listDirectory(path, calculateSizes: calculateSizes);
      
      // Directory virtuali da escludere (filesystem virtuali che non hanno dimensioni reali)
      final virtualDirs = ['proc', 'sys', 'dev', 'run', 'tmp'];
      
      // Filtra file nascosti e directory virtuali
      final filteredItems = items.where((item) {
        // Filtra file nascosti se necessario
        if (!_showHiddenFiles && item.name.startsWith('.')) {
          return false;
        }
        
        // Escludi directory virtuali
        if (item.isDirectory) {
          final dirName = item.name.toLowerCase();
          if (virtualDirs.contains(dirName)) {
            return false;
          }
          
          // Escludi anche se il percorso completo contiene queste directory
          if (item.path == '/proc' || item.path == '/sys' || item.path == '/dev' || 
              item.path == '/run' || item.path == '/tmp' ||
              item.path.startsWith('/proc/') || item.path.startsWith('/sys/') ||
              item.path.startsWith('/dev/') || item.path.startsWith('/run/') ||
              item.path.startsWith('/tmp/')) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      setState(() {
        _currentItems = filteredItems;
        _currentPath = path;
        _isLoading = false;
        
        // Ordina gli items
        _sortItems();
        
        // Aggiorna la cronologia solo se non è una navigazione dalla cronologia
        if (!skipHistory) {
          if (_historyIndex < _pathHistory.length - 1) {
            _pathHistory.removeRange(_historyIndex + 1, _pathHistory.length);
          }
          _pathHistory.add(path);
          _historyIndex = _pathHistory.length - 1;
        }
      });
      
      // Salva nella cache se siamo nel disco base o in una sottocartella
      final normalizedPathForCache = path.endsWith('/') && path.length > 1
          ? path.substring(0, path.length - 1)
          : path;
      final normalizedBasePathForCache = _selectedBasePath.isNotEmpty
          ? (_selectedBasePath.endsWith('/') && _selectedBasePath.length > 1
              ? _selectedBasePath.substring(0, _selectedBasePath.length - 1)
              : _selectedBasePath)
          : '/';
      final diskPathForCache = normalizedBasePathForCache.isNotEmpty ? normalizedBasePathForCache : '/';
      final isBasePathForCache = normalizedPathForCache == diskPathForCache || normalizedPathForCache.startsWith('$diskPathForCache/');
      if (isBasePathForCache) {
        _saveDirectoryListToCache(diskPathForCache, normalizedPathForCache, items);
      }
      
      // Se non abbiamo calcolato le dimensioni, calcolale in background
      if (!calculateSizes) {
        _calculateSizesInBackground(items, diskPath: diskPathForCache, listPath: normalizedPathForCache);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Salva la lista dei file/directory nella cache
  Future<void> _saveDirectoryListToCache(String diskPath, String directoryPath, List<FileSystemItem> items) async {
    try {
      final itemsData = _fileSystemItemsToMaps(items);
      await DiskCacheService.saveDirectoryList(diskPath, directoryPath, itemsData);
    } catch (e) {
      // Ignora errori di salvataggio cache
    }
  }

  void _scheduleDirectoryListIncrementalRefresh(String diskPath, String directoryPath) {
    final t = ++_dirListIncrementalToken;
    Future<void>(() async {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted || t != _dirListIncrementalToken) return;
      await _updateCacheIncrementalForPath(diskPath, directoryPath);
    });
  }

  /// Aggiorna la cache in modo incrementale (solo file/cartelle nuovi o cancellati). Non rigenera.
  Future<void> _updateCacheIncrementalForPath(String diskPath, String directoryPath) async {
    try {
      final currentItems = await DiskAnalyzerService.listDirectory(directoryPath, calculateSizes: false);
      final currentFromFs = _fileSystemItemsToMaps(currentItems);
      await DiskCacheService.updateDirectoryListIncremental(diskPath, directoryPath, currentFromFs);
    } catch (e) {
      // Ignora errori aggiornamento cache
    }
  }

  static List<Map<String, dynamic>> _fileSystemItemsToMaps(List<FileSystemItem> items) {
    return items.map((item) => {
      'path': item.path,
      'name': item.name,
      'size': item.size,
      'isDirectory': item.isDirectory,
      'modified': item.modified?.toIso8601String(),
      'mimeType': item.mimeType,
    }).toList();
  }

  /// Aggiorna la cache delle dimensioni in modo incrementale (solo cartelle nuove/cancellate).
  Future<void> _updateDirectorySizesCacheIncremental(String diskPath, List<Map<String, dynamic>> cachedSizes) async {
    try {
      final items = await DiskAnalyzerService.listDirectory(diskPath, calculateSizes: false);
      final topDirs = items.where((e) => e.isDirectory).map((e) => {'name': e.name, 'path': e.path}).toList();
      await DiskCacheService.updateDirectorySizesIncremental(diskPath, topDirs, cachedSizes);
    } catch (e) {
      // Ignora errori aggiornamento cache
    }
  }

  Future<void> _calculateSizesInBackground(
    List<FileSystemItem> items, {
    required String diskPath,
    required String listPath,
  }) async {
    // Filtra solo le directory che necessitano del calcolo della dimensione
    final directoriesToCalculate = items.where((item) {
      if (!_showHiddenFiles && item.name.startsWith('.')) {
        return false;
      }
      return item.isDirectory && item.size == 0;
    }).toList();

    if (directoriesToCalculate.isEmpty) {
      return;
    }

    final normListPath = DiskCacheService.normalizeListedDirectoryPath(listPath);

    // Calcola le dimensioni in parallelo (max 5 alla volta per non sovraccaricare)
    const maxConcurrent = 5;
    for (int i = 0; i < directoriesToCalculate.length; i += maxConcurrent) {
      final batch = directoriesToCalculate.skip(i).take(maxConcurrent).toList();

      final futures = batch.map((item) async {
        try {
          final size = await DiskAnalyzerService.getDirectorySize(item.path)
              .timeout(
                const Duration(seconds: 60),
                onTimeout: () => 0,
              );
          return {'item': item, 'size': size};
        } catch (e) {
          return {'item': item, 'size': 0};
        }
      });

      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          for (final result in results) {
            final item = result['item'] as FileSystemItem;
            final size = result['size'] as int;

            final index = _currentItems.indexWhere((el) => el.path == item.path);
            if (index >= 0) {
              _currentItems[index] = FileSystemItem(
                path: item.path,
                name: item.name,
                size: size,
                isDirectory: item.isDirectory,
                modified: item.modified,
                mimeType: item.mimeType,
              );
            }
          }
          _sortItems();
        });
      }
    }

    // Un solo salvataggio cache su disco: prima si riscritta il JSON ad ogni batch (lento + blocchi UI)
    if (mounted) {
      final stillSameDir =
          DiskCacheService.normalizeListedDirectoryPath(_currentPath) == normListPath;
      if (stillSameDir) {
        try {
          await DiskCacheService.updateDirectoryListSizes(
            diskPath,
            normListPath,
            _fileSystemItemsToMaps(_currentItems),
          );
        } catch (_) {}
      }
    }
  }

  void _selectBasePath(String path) async {
    _selectedBasePath = path;
    _selectedDiskIndex = -1;
    _pathHistory.clear();
    _historyIndex = -1;
    _hasShownCacheMessage = false; // Reset per nuovo disco
    
    // Verifica se esiste cache per questo disco
    final hasCache = await DiskCacheService.hasCache(path);
    
    // Carica prima le info base e mostra la directory subito
    final diskInfo = await _getDiskInfo(path);
    final diskBytes = await _getDiskBytes(path);
    setState(() {
      _selectedDiskInfo = diskInfo;
      _selectedDiskBytes = diskBytes;
      _directorySizes = []; // Reset per mostrare il loading
      _isGeneratingCache = !hasCache; // Mostra messaggio solo se non c'è cache
      _isChartLoading = true;
    });
    
    // Carica la directory subito (senza resettare il grafico qui, lo facciamo sopra)
    _loadDirectory(path, skipHistory: true);
    
    // Carica il grafico in background senza bloccare - assicurati che venga sempre caricato
    _loadDirectorySizesAsync(path).catchError((error) {
      // Se il caricamento fallisce, mantieni il grafico vuoto ma non bloccare
      if (mounted) {
        setState(() {
          _directorySizes = [];
          _isGeneratingCache = false;
          _isChartLoading = false;
        });
      }
    });
  }
  
  /// Carica le dimensioni delle directory in background con cache
  Future<void> _loadDirectorySizesAsync(String path) async {
    // Normalizza il percorso (rimuovi trailing slash se presente, tranne per root)
    final normalizedPath = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    
    // Determina se stiamo navigando nel disco base o in una sottocartella
    final normalizedBasePath = _selectedBasePath.isNotEmpty 
        ? (_selectedBasePath.endsWith('/') && _selectedBasePath.length > 1
            ? _selectedBasePath.substring(0, _selectedBasePath.length - 1)
            : _selectedBasePath)
        : '/';
    final isBasePath = normalizedPath == normalizedBasePath || (normalizedBasePath.isEmpty && normalizedPath == '/');
    
    // Se stiamo navigando in una sottocartella, non usare la cache del disco base
    // ma genera sempre i dati per la cartella corrente
    if (!isBasePath) {
      final chartToken = ++_chartScanToken;
      // Reset del flag per mostrare il loading durante la navigazione
      if (mounted) {
        setState(() {
          _directorySizes = [];
          _isGeneratingCache = true;
          _isChartLoading = true;
        });
      }
      
      // Genera i dati per la cartella corrente (senza cache)
      final directorySizes = await _getTopDirectories(
        normalizedPath,
        chartToken: chartToken,
        onPartial: (partial) {
          if (!mounted || chartToken != _chartScanToken) return;
          setState(() {
            _directorySizes = List<Map<String, dynamic>>.from(partial);
          });
        },
      );
      
      if (mounted) {
        setState(() {
          _directorySizes = directorySizes;
          _isGeneratingCache = false;
          _isChartLoading = false;
        });
      }
      return;
    }
    
    // Per il disco base, usa la cache
    final diskPath = normalizedBasePath.isNotEmpty ? normalizedBasePath : '/';
    
    // Prova a caricare dalla cache
    final cachedSizes = await DiskCacheService.loadDirectorySizes(diskPath);
    
    if (cachedSizes != null && cachedSizes.isNotEmpty) {
      // Usa la cache (aggiornamento incrementale in background, non rigenerazione)
      if (mounted) {
        setState(() {
          _directorySizes = cachedSizes;
          _isGeneratingCache = false;
          _isChartLoading = false;
          _hasShownCacheMessage = true;
        });
      }
      _updateDirectorySizesCacheIncremental(diskPath, cachedSizes);
      return;
    }
    
    // Se non c'è cache, genera e mostra il messaggio la prima volta
    if (!_hasShownCacheMessage && mounted) {
      setState(() {
        _isGeneratingCache = true;
        _isChartLoading = true;
        _hasShownCacheMessage = true;
      });
    }
    
    // Genera i dati (streaming + risultati parziali per il grafico)
    final chartToken = ++_chartScanToken;
    final directorySizes = await _getTopDirectories(
      normalizedPath,
      chartToken: chartToken,
      onPartial: (partial) {
        if (!mounted || chartToken != _chartScanToken) return;
        setState(() {
          _directorySizes = List<Map<String, dynamic>>.from(partial);
        });
      },
    );
    
    // Salva nella cache solo per il disco base
    await DiskCacheService.saveDirectorySizes(diskPath, directorySizes);
    
    if (mounted) {
      setState(() {
        _directorySizes = directorySizes;
        _isGeneratingCache = false;
        _isChartLoading = false;
      });
    }
  }

  void _selectExternalDisk(int index) async {
    if (index >= 0 && index < _mountedDisks.length) {
      final disk = _mountedDisks[index];
      final mountPoint = disk['mountPoint']!;
      _selectedDiskIndex = index;
      _selectedBasePath = mountPoint;
      _pathHistory.clear();
      _historyIndex = -1;
      _hasShownCacheMessage = false; // Reset per nuovo disco
      
      // Verifica se esiste cache per questo disco
      final hasCache = await DiskCacheService.hasCache(mountPoint);
      
      // Carica prima le info base e mostra la directory subito
      final diskBytes = await _getDiskBytes(mountPoint);
      setState(() {
        _selectedDiskInfo = {
          'used': disk['used'] ?? '',
          'available': disk['available'] ?? '',
          'size': disk['size'] ?? '',
        };
        _selectedDiskBytes = diskBytes;
        _directorySizes = []; // Reset per mostrare il loading
        _isGeneratingCache = !hasCache; // Mostra messaggio solo se non c'è cache
      });
      
      // Carica la directory subito (senza resettare il grafico qui, lo facciamo sopra)
      _loadDirectory(mountPoint, skipHistory: true);
      
      // Carica il grafico in background senza bloccare - assicurati che venga sempre caricato
      _loadDirectorySizesAsync(mountPoint).catchError((error) {
        // Se il caricamento fallisce, mantieni il grafico vuoto ma non bloccare
        if (mounted) {
          setState(() {
            _directorySizes = [];
            _isGeneratingCache = false;
          });
        }
      });
    }
  }

  void _navigateTo(String path) {
    _loadDirectory(path);
    // Aggiorna il grafico con le dimensioni delle sottocartelle
    _loadDirectorySizesAsync(path);
  }

  void _goBack() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
      });
      final path = _pathHistory[_historyIndex];
      _loadDirectory(path, skipHistory: true);
      // Aggiorna il grafico con le dimensioni delle sottocartelle
      _loadDirectorySizesAsync(path);
    }
  }

  void _goForward() {
    if (_historyIndex < _pathHistory.length - 1) {
      setState(() {
        _historyIndex++;
      });
      final path = _pathHistory[_historyIndex];
      _loadDirectory(path, skipHistory: true);
      // Aggiorna il grafico con le dimensioni delle sottocartelle
      _loadDirectorySizesAsync(path);
    }
  }

  void _goToRoot() {
    if (_selectedBasePath.isNotEmpty) {
      _loadDirectory(_selectedBasePath);
      // Aggiorna il grafico con le dimensioni delle sottocartelle
      _loadDirectorySizesAsync(_selectedBasePath);
    }
  }

  void _moveToTrash(FileSystemItem item) async {
    // Verifica se il percorso è nella root o in una sottocartella della root
    final isInRoot = _isInRootDirectory(item.path);
    
    // Se siamo nella root, mostra un avviso più severo
    if (isInRoot) {
      // Verifica che la password sia disponibile
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        // Richiedi la password se non è salvata
        final passwordResult = await _requestPasswordFromUser();
        if (passwordResult == null || passwordResult.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.passwordRequiredMessage,
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
      }
      
      // Mostra avviso per eliminazione dalla root
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.deleteFromRootWarning,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.deleteFromRootMessage(item.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                AppLocalizations.of(context)!.deletePermanently,
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // Elimina con sudo
        final success = await DiskAnalyzerService.moveToTrash(item.path, useSudo: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                    ? AppLocalizations.of(context)!.movedToTrash
                    : AppLocalizations.of(context)!.errorMovingToTrash,
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) {
            _loadDirectory(_currentPath);
            // Aggiorna il grafico
            _loadDirectorySizesAsync(_currentPath);
          }
        }
      }
    } else {
      // Comportamento normale per directory non-root
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.moveToTrash),
          content: Text(AppLocalizations.of(context)!.moveToTrashConfirm(item.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(
                AppLocalizations.of(context)!.move,
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        final success = await DiskAnalyzerService.moveToTrash(item.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success 
                    ? AppLocalizations.of(context)!.movedToTrash
                    : AppLocalizations.of(context)!.errorMovingToTrash,
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) {
            _loadDirectory(_currentPath);
            // Aggiorna il grafico
            _loadDirectorySizesAsync(_currentPath);
          }
        }
      }
    }
  }

  /// Verifica se un percorso è nella root o in una sottocartella della root
  bool _isInRootDirectory(String path) {
    // Percorsi che NON sono considerati root (directory utente)
    final userDirectories = [
      '/home',
      '/tmp',
      '/var/tmp',
    ];
    
    // Se il percorso inizia con una directory utente, non è root
    if (userDirectories.any((dir) => path.startsWith(dir))) {
      return false;
    }
    
    // Se il percorso inizia con / e non è una directory utente, è root
    // Escludi anche directory virtuali
    final virtualDirs = ['/proc', '/sys', '/dev', '/run'];
    if (virtualDirs.any((dir) => path.startsWith(dir))) {
      return false;
    }
    
    // Se il percorso inizia con / e non è /home o altre directory utente, è root
    return path.startsWith('/') && path != '/';
  }

  void _showPreview(FileSystemItem item) {
    if (item.isDirectory) return;
    
    showDialog(
      context: context,
      builder: (context) => _FilePreviewDialog(item: item),
    );
  }

  Future<void> _showRenameDialog(FileSystemItem item) async {
    final TextEditingController nameController = TextEditingController(text: item.name);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rename),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.newName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != item.name) {
                Navigator.pop(context, newName);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(AppLocalizations.of(context)!.rename),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final success = await DiskAnalyzerService.renameItem(item.path, result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                  ? AppLocalizations.of(context)!.renamedSuccessfully
                  : AppLocalizations.of(context)!.renameError,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          // Ricarica la directory
          final parent = Directory(item.path).parent.path;
          _loadDirectory(parent);
          // Aggiorna il grafico
          _loadDirectorySizesAsync(parent);
        }
      }
    }
  }

  Future<void> _showDetailsDialog(FileSystemItem item) async {
    final details = await DiskAnalyzerService.getItemDetails(item.path);
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.details),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _DetailRow(AppLocalizations.of(context)!.name, details['name']?.toString() ?? ''),
                _DetailRow(AppLocalizations.of(context)!.path, details['path']?.toString() ?? ''),
                _DetailRow(
                  AppLocalizations.of(context)!.size,
                  DiskAnalyzerService.formatSize(details['size'] as int? ?? 0),
                ),
                if (details['totalSize'] != null)
                  _DetailRow(
                    AppLocalizations.of(context)!.totalSize,
                    DiskAnalyzerService.formatSize(details['totalSize'] as int),
                  ),
                if (details['type'] != null)
                  _DetailRow(
                    AppLocalizations.of(context)!.type,
                    details['type'] == 'directory' 
                        ? AppLocalizations.of(context)!.directory
                        : AppLocalizations.of(context)!.file,
                  ),
                if (details['mimeType'] != null)
                  _DetailRow(AppLocalizations.of(context)!.fileType, details['mimeType']?.toString() ?? ''),
                if (details['modified'] != null)
                  _DetailRow(
                    AppLocalizations.of(context)!.modified,
                    (details['modified'] as DateTime).toString().substring(0, 19),
                  ),
                if (details['fileCount'] != null)
                  _DetailRow(
                    AppLocalizations.of(context)!.files,
                    details['fileCount']?.toString() ?? '0',
                  ),
                if (details['directoryCount'] != null)
                  _DetailRow(
                    AppLocalizations.of(context)!.directories,
                    details['directoryCount']?.toString() ?? '0',
                  ),
                if (details['permissions'] != null)
                  _DetailRow(AppLocalizations.of(context)!.permissions, details['permissions']?.toString() ?? ''),
                if (details['owner'] != null)
                  _DetailRow(
                    AppLocalizations.of(context)!.owner,
                    '${details['owner']}${details['group'] != null ? ' (${details['group']})' : ''}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Column(
        children: [
          // Messaggio cache in corso
          if (_isGeneratingCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.diskCacheGenerating,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Selezione percorso base
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.selectBasePath,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                // Pulsanti Home e Dischi esterni
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    // Home
                    _PathButton(
                      icon: Icons.home,
                      label: AppLocalizations.of(context)!.home,
                      path: DiskAnalyzerService.getHomePath(),
                      isSelected: _selectedBasePath == DiskAnalyzerService.getHomePath(),
                      onTap: () => _selectBasePath(DiskAnalyzerService.getHomePath()),
                    ),
                    _PathButton(
                      icon: Icons.public,
                      label: AppLocalizations.of(context)!.filesystem,
                      path: '/',
                      isSelected: _selectedBasePath == '/',
                      onTap: () => _selectBasePath('/'),
                    ),
                    // Dischi esterni
                    ..._mountedDisks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final disk = entry.value;
                      final isExternal = disk['isExternal'] == 'true';
                      final mountPoint = disk['mountPoint']!;
                      final displayName = disk['label'] ?? _getDisplayName(mountPoint);
                      
                      return _PathButton(
                        icon: isExternal ? Icons.usb : Icons.storage,
                        label: displayName,
                        path: mountPoint,
                        isSelected: _selectedDiskIndex == index,
                        onTap: () => _selectExternalDisk(index),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          
          // Barra di navigazione
          if (_currentPath.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: _historyIndex > 0 ? _goBack : null,
                    tooltip: AppLocalizations.of(context)!.goBack,
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, size: 20),
                    onPressed: _historyIndex < _pathHistory.length - 1 ? _goForward : null,
                    tooltip: AppLocalizations.of(context)!.goForward,
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, size: 20),
                    onPressed: _selectedBasePath.isNotEmpty ? _goToRoot : null,
                    tooltip: AppLocalizations.of(context)!.goToRoot,
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _selectedDiskInfo != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${AppLocalizations.of(context)!.usedSpace}: ${_selectedDiskInfo!['used'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${AppLocalizations.of(context)!.freeSpace}: ${_selectedDiskInfo!['available'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.green.shade300
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _currentPath,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                  const SizedBox(width: 8),
                  // Pulsanti di ordinamento
                  IconButton(
                    icon: Icon(
                      _currentSort == SortType.sizeDescending 
                          ? Icons.arrow_downward 
                          : Icons.arrow_upward,
                      size: 20,
                    ),
                    onPressed: () {
                      _changeSortType(
                        _currentSort == SortType.sizeDescending
                            ? SortType.sizeAscending
                            : SortType.sizeDescending,
                      );
                    },
                    tooltip: _currentSort == SortType.sizeDescending
                        ? 'Ordina per dimensione crescente'
                        : 'Ordina per dimensione decrescente',
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort_by_alpha, size: 20),
                    onPressed: () {
                      _changeSortType(SortType.alphabetical);
                    },
                    tooltip: 'Ordina alfabeticamente (A-Z)',
                    style: IconButton.styleFrom(
                      foregroundColor: _currentSort == SortType.alphabetical
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    color: Theme.of(context).colorScheme.surface,
                    onSelected: (value) {
                      if (value == 'toggle_hidden') {
                        setState(() {
                          _showHiddenFiles = !_showHiddenFiles;
                        });
                        _loadDirectory(_currentPath, skipHistory: true);
                        // Aggiorna il grafico
                        _loadDirectorySizesAsync(_currentPath);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_hidden',
                        child: Row(
                          children: [
                            Icon(
                              _showHiddenFiles ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showHiddenFiles
                                  ? AppLocalizations.of(context)!.hideSystemFiles
                                  : AppLocalizations.of(context)!.showSystemFiles,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          
          // Contenuto principale: Grafico a sinistra e Cartelle a destra
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (_selectedBasePath.isNotEmpty)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grafico a sinistra
                  Flexible(
                    flex: 2,
                    child: Container(
                      margin: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0, right: 8.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                      child: _directorySizes.isEmpty
                          ? (_isChartLoading
                              ? const SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : SizedBox(
                                  height: 140,
                                  child: Center(
                                    child: Text(AppLocalizations.of(context)!.emptyDirectory),
                                  ),
                                ))
                          : _DiskPieChart(
                              directories: _directorySizes,
                            ),
                    ),
                  ),
                  // Cartelle a destra
                  Flexible(
                    flex: 3,
                    child: _currentItems.isNotEmpty
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _currentItems.length,
                            itemBuilder: (context, index) {
                              final item = _currentItems[index];
                              return _FileSystemItemListTile(
                                item: item,
                                onTap: () {
                                  if (item.isDirectory) {
                                    _navigateTo(item.path);
                                  } else {
                                    _showPreview(item);
                                  }
                                },
                                onMoveToTrash: () => _moveToTrash(item),
                                onRename: () => _showRenameDialog(item),
                                onShowDetails: () => _showDetailsDialog(item),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              _currentPath.isNotEmpty
                                  ? AppLocalizations.of(context)!.emptyDirectory
                                  : AppLocalizations.of(context)!.selectPathToAnalyze,
                            ),
                          ),
                  ),
                ],
              ),
            )
          else if (_currentPath.isNotEmpty)
            Expanded(
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.emptyDirectory,
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.selectPathToAnalyze,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _sortItems() {
    _currentItems.sort((a, b) {
      // Prima separa directory e file
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      
      // Poi ordina secondo il tipo selezionato
      switch (_currentSort) {
        case SortType.sizeAscending:
          return a.size.compareTo(b.size);
        case SortType.sizeDescending:
          return b.size.compareTo(a.size);
        case SortType.alphabetical:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
  }

  void _changeSortType(SortType sortType) {
    setState(() {
      _currentSort = sortType;
      _sortItems();
    });
  }

  String _getDisplayName(String path) {
    // Se il path è molto lungo, mostra solo l'ultima parte
    if (path.length > 30) {
      final parts = path.split('/');
      if (parts.length > 1) {
        return parts.last;
      }
    }
    return path;
  }

  Future<Map<String, String>?> _getDiskInfo(String path) async {
    try {
      final result = await Process.run('bash', ['-c', 'df -h "$path" 2>/dev/null | tail -1']);
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        final parts = output.split(RegExp(r'\s+'));
        if (parts.length >= 6) {
          return {
            'used': parts[2],
            'available': parts[3],
            'size': parts[1],
          };
        }
      }
    } catch (e) {
      // Ignora errori
    }
    return null;
  }

  /// Converte dimensioni disco da stringhe formattate (es. "50G", "100M") a bytes
  Future<Map<String, int>?> _getDiskBytes(String path) async {
    try {
      final result = await Process.run('bash', ['-c', 'df -B1 "$path" 2>/dev/null | tail -1']);
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        final parts = output.split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final totalBytes = int.tryParse(parts[1]) ?? 0;
          final usedBytes = int.tryParse(parts[2]) ?? 0;
          final availableBytes = int.tryParse(parts[3]) ?? 0;
          
          return {
            'total': totalBytes,
            'used': usedBytes,
            'available': availableBytes,
          };
        }
      }
    } catch (e) {
      // Ignora errori
    }
    return null;
  }

  /// Comando du senza `sort` nel pipe (così l'output arriva a chunk utilizzabili per il grafico).
  String _duStreamingInnerCommand(String normRoot) {
    if (normRoot == '/') {
      return 'du -h -d1 -x / '
          '--exclude=/proc '
          '--exclude=/sys '
          '--exclude=/dev '
          '--exclude=/run '
          '--exclude=/tmp '
          '--exclude=/snap '
          '--exclude=/boot '
          '--exclude=/boot/efi '
          '--exclude=/lost+found '
          '--exclude=/sysroot '
          '--exclude=/var/lib/docker '
          '--exclude=/var/lib/containers '
          '--exclude=/var/cache '
          '--exclude=/var/tmp '
          '2>/dev/null';
    }
    final escapedPath = normRoot.replaceAll("'", "'\\''");
    return "cd '$escapedPath' && for item in * .[!.]*; do [ -d \"\$item\" ] && du -sh \"\$item\" 2>/dev/null; done";
  }

  List<Map<String, dynamic>> _sortedDirectoryMapsFromAccum(
    Map<String, Map<String, dynamic>> byPath,
  ) {
    final list = byPath.values.toList();
    list.sort((a, b) => (b['size'] as int).compareTo(a['size'] as int));
    return list;
  }

  /// Avvia bash con inner; uso sudo solo se [useSudo] e password salvata.
  Future<Process?> _spawnDuShell({required bool useSudo, required String inner}) async {
    if (!useSudo) {
      return Process.start('bash', ['-c', inner], runInShell: true);
    }
    var password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      if (!mounted) return null;
      password = await _requestPasswordFromUser();
      if (password == null || password.isEmpty) return null;
      await PasswordStorage.savePassword(password);
    }
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    final escapedInner = inner.replaceAll("'", "'\\''");
    final cmd = 'printf "%s\\n" "$escapedPassword" | sudo -S bash -c \'$escapedInner\'';
    return Process.start('bash', ['-c', cmd], runInShell: true);
  }

  /// Legge stdout a chunk, emette risultati parziali (throttle), rispetta [maxDuration] poi termina il processo.
  Future<List<Map<String, dynamic>>> _drainDuStdoutToMaps(
    Process process,
    String normRoot, {
    required Map<String, Map<String, dynamic>> byPath,
    int? chartToken,
    void Function(List<Map<String, dynamic>> partial)? onPartial,
    required Duration maxDuration,
  }) async {
    Timer? throttle;
    var remainder = '';
    final sw = Stopwatch()..start();

    void schedulePartial() {
      if (onPartial == null) return;
      throttle?.cancel();
      throttle = Timer(const Duration(milliseconds: 400), () {
        throttle = null;
        if (chartToken == null || chartToken != _chartScanToken || !mounted) return;
        final sorted = _sortedDirectoryMapsFromAccum(byPath);
        if (sorted.isNotEmpty) onPartial(sorted);
      });
    }

    try {
      await for (final chunk in process.stdout.transform(utf8.decoder)) {
        if (sw.elapsed > maxDuration) {
          process.kill(ProcessSignal.sigterm);
          break;
        }
        remainder += chunk;
        final parts = remainder.split('\n');
        remainder = parts.isNotEmpty ? parts.removeLast() : '';
        for (final rawLine in parts) {
          final row = _tryParseDuLine(rawLine, normRoot);
          if (row != null) {
            byPath[row['path'] as String] = row;
            schedulePartial();
          }
        }
      }
      if (remainder.trim().isNotEmpty) {
        final row = _tryParseDuLine(remainder, normRoot);
        if (row != null) byPath[row['path'] as String] = row;
      }
    } finally {
      throttle?.cancel();
      try {
        await process.exitCode.timeout(const Duration(seconds: 2));
      } catch (_) {
        try {
          process.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
    }

    final finalList = _sortedDirectoryMapsFromAccum(byPath);
    if (onPartial != null && chartToken != null && chartToken == _chartScanToken && mounted && finalList.isNotEmpty) {
      onPartial(finalList);
    }
    return finalList;
  }

  /// Directory principali per il grafico: streaming + timeout progressivo (prima user, poi sudo) e aggiornamenti parziali.
  Future<List<Map<String, dynamic>>> _getTopDirectories(
    String path, {
    int? chartToken,
    void Function(List<Map<String, dynamic>> partial)? onPartial,
  }) async {
    try {
      final normalizedPath = path.startsWith('~')
          ? path.replaceFirst(
              '~',
              Platform.environment['HOME'] ??
                  '/home/${Platform.environment['USER'] ?? 'user'}',
            )
          : path;
      final normRoot = normalizedPath.endsWith('/') && normalizedPath.length > 1
          ? normalizedPath.substring(0, normalizedPath.length - 1)
          : normalizedPath;

      final inner = _duStreamingInnerCommand(normRoot);
      // Timeout progressivo: tentativi più brevi senza privilegi, più lunghi con sudo / root.
      final stages = normRoot == '/'
          ? const [
              (sudo: false, max: Duration(seconds: 25)),
              (sudo: true, max: Duration(seconds: 90)),
            ]
          : const [
              (sudo: false, max: Duration(seconds: 18)),
              (sudo: true, max: Duration(seconds: 40)),
            ];

      for (final stage in stages) {
        final proc = await _spawnDuShell(useSudo: stage.sudo, inner: inner);
        if (proc == null) continue;
        final byPath = <String, Map<String, dynamic>>{};
        final got = await _drainDuStdoutToMaps(
          proc,
          normRoot,
          byPath: byPath,
          chartToken: chartToken,
          onPartial: onPartial,
          maxDuration: stage.max,
        );
        if (got.isNotEmpty) return got;
      }

      final totalFilesSize = _currentItems
          .where((it) => !it.isDirectory)
          .fold<int>(0, (sum, it) => sum + it.size);
      if (totalFilesSize > 0) {
        return [
          {
            'name': 'Files',
            'path': normRoot,
            'size': totalFilesSize,
            'sizeFormatted': DiskAnalyzerService.formatSize(totalFilesSize),
          }
        ];
      }
    } catch (e) {
      // Ignora errori
    }
    return [];
  }

  /// Chiede la password all'utente tramite un dialog
  Future<String?> _requestPasswordFromUser() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.passwordRequired),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.passwordRequiredMessage),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.passwordLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                ),
                autofocus: true,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.pop(context, value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  Navigator.pop(context, passwordController.text);
                }
              },
              child: Text(AppLocalizations.of(context)!.confirm),
            ),
          ],
        ),
      ),
    );
    
    return result;
  }

  /// Una riga di output du (usata da streaming e batch).
  Map<String, dynamic>? _tryParseDuLine(String line, String basePath) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) return null;
    final sizeStr = parts[0];
    final dirPath = parts.sublist(1).join(' ').trim();
    if (dirPath.isEmpty) return null;

    final cleanPath = dirPath.endsWith('/') ? dirPath.substring(0, dirPath.length - 1) : dirPath;
    final fullPath = cleanPath.startsWith('/') ? cleanPath : '$basePath/$cleanPath';

    final pathParts = fullPath.split('/').where((p) => p.isNotEmpty).toList();
    final dirName = pathParts.isNotEmpty ? pathParts.last : cleanPath;

    final virtualDirs = ['proc', 'sys', 'dev', 'run', 'tmp', 'snap', 'lost+found', 'sysroot'];
    if (virtualDirs.contains(dirName.toLowerCase())) {
      return null;
    }

    if (fullPath == '/' ||
        fullPath == '/proc' || fullPath == '/sys' || fullPath == '/dev' ||
        fullPath == '/run' || fullPath == '/tmp' ||
        fullPath == '/snap' || fullPath == '/boot' || fullPath == '/boot/efi' ||
        fullPath == '/lost+found' || fullPath == '/sysroot' ||
        fullPath == '/var/lib/docker' || fullPath == '/var/lib/containers' ||
        fullPath == '/var/cache' || fullPath == '/var/tmp' ||
        fullPath.startsWith('/proc/') || fullPath.startsWith('/sys/') ||
        fullPath.startsWith('/dev/') || fullPath.startsWith('/run/') ||
        fullPath.startsWith('/tmp/') ||
        fullPath.startsWith('/snap/') || fullPath.startsWith('/boot/')) {
      return null;
    }

    final sizeBytes = _parseSizeToBytes(sizeStr);
    final maxSizeBytes = 100 * 1024 * 1024 * 1024 * 1024;
    if (sizeBytes <= 0 || sizeBytes > maxSizeBytes || dirName.isEmpty || dirName == '.' || dirName == '..') {
      return null;
    }
    return {
      'name': dirName,
      'path': fullPath,
      'size': sizeBytes,
      'sizeFormatted': sizeStr,
    };
  }

  /// Converte una stringa di dimensione (es. "1.5G", "500M", "2,0T") in bytes
  /// Supporta fino a 100TB
  int _parseSizeToBytes(String sizeStr) {
    // Sostituisci virgola con punto per supportare formati come "2,0T"
    final normalizedStr = sizeStr.replaceAll(',', '.');
    final regex = RegExp(r'^([\d.]+)([KMGT]?)$', caseSensitive: false);
    final match = regex.firstMatch(normalizedStr.toUpperCase());
    if (match != null) {
      final value = double.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = match.group(2) ?? '';
      
      // Limita a 100TB per evitare overflow
      final maxTB = 100.0;
      
      switch (unit) {
        case 'K':
          return (value * 1024).toInt();
        case 'M':
          return (value * 1024 * 1024).toInt();
        case 'G':
          return (value * 1024 * 1024 * 1024).toInt();
        case 'T':
          // Limita a 100TB
          final tbValue = value > maxTB ? maxTB : value;
          return (tbValue * 1024 * 1024 * 1024 * 1024).toInt();
        default:
          return value.toInt();
      }
    }
    return 0;
  }
}

class _PathButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;

  const _PathButton({
    required this.icon,
    required this.label,
    required this.path,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 220,
        ),
        child: SizedBox(
          height: 70,
          child: ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 24),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.95)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5);
                }
                if (isSelected) {
                  return Theme.of(context).colorScheme.primary;
                }
                if (states.contains(WidgetState.pressed)) {
                  return Theme.of(context).colorScheme.primaryContainer;
                }
                if (states.contains(WidgetState.hovered)) {
                  return Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8);
                }
                return Theme.of(context).colorScheme.surfaceContainerHighest;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.disabled)) {
                  return Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
                }
                if (isSelected) {
                  return Theme.of(context).colorScheme.onPrimary;
                }
                if (states.contains(WidgetState.pressed)) {
                  return Theme.of(context).colorScheme.onPrimaryContainer;
                }
                return Theme.of(context).colorScheme.onSurface;
              }),
              overlayColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (isSelected) {
                  return Theme.of(context).colorScheme.onPrimary.withOpacity(0.1);
                }
                return Theme.of(context).colorScheme.primary.withOpacity(0.1);
              }),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              minimumSize: WidgetStateProperty.all(const Size(220, 70)),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileSystemItemListTile extends StatelessWidget {
  final FileSystemItem item;
  final VoidCallback onTap;
  final VoidCallback onMoveToTrash;
  final VoidCallback onRename;
  final VoidCallback onShowDetails;

  const _FileSystemItemListTile({
    required this.item,
    required this.onTap,
    required this.onMoveToTrash,
    required this.onRename,
    required this.onShowDetails,
  });

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(AppLocalizations.of(context)!.moveToTrash),
              onTap: () {
                Navigator.pop(context);
                onMoveToTrash();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(AppLocalizations.of(context)!.rename),
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(AppLocalizations.of(context)!.details),
              onTap: () {
                Navigator.pop(context);
                onShowDetails();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Builder(
        builder: (context) => GestureDetector(
          onSecondaryTap: () {
            _showContextMenu(context);
          },
          onLongPress: () {
            _showContextMenu(context);
          },
          child: ListTile(
            leading: Icon(
              item.isDirectory ? Icons.folder : Icons.insert_drive_file,
              color: item.isDirectory 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
              size: 32,
            ),
            title: Text(
              item.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.isDirectory
                      ? AppLocalizations.of(context)!.directory
                      : AppLocalizations.of(context)!.file,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DiskAnalyzerService.formatSize(item.size),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert, size: 20),
              onPressed: () => _showContextMenu(context),
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilePreviewDialog extends StatelessWidget {
  final FileSystemItem item;

  const _FilePreviewDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return _FilePreviewDialogContent(item: item);
  }
}

class _FilePreviewDialogContent extends StatefulWidget {
  final FileSystemItem item;

  const _FilePreviewDialogContent({required this.item});

  @override
  State<_FilePreviewDialogContent> createState() => _FilePreviewDialogContentState();
}

class _FilePreviewDialogContentState extends State<_FilePreviewDialogContent> {
  Map<String, dynamic>? _metadata;
  bool _loadingMetadata = false;
  String? _thumbnailPath;
  bool _loadingThumbnail = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadThumbnail();
  }

  Future<void> _loadMetadata() async {
    setState(() {
      _loadingMetadata = true;
    });

    final metadata = await DiskAnalyzerService.getFileMetadata(
      widget.item.path,
      widget.item.mimeType,
    );

    if (mounted) {
      setState(() {
        _metadata = metadata;
        _loadingMetadata = false;
      });
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.item.isDirectory) return;
    
    final isPdf = widget.item.mimeType == 'application/pdf';
    final isOffice = widget.item.mimeType != null && (
      widget.item.mimeType!.contains('word') ||
      widget.item.mimeType!.contains('excel') ||
      widget.item.mimeType!.contains('powerpoint') ||
      widget.item.mimeType!.contains('spreadsheet') ||
      widget.item.mimeType!.contains('presentation') ||
      widget.item.mimeType!.contains('msword') ||
      widget.item.mimeType!.contains('vnd.ms-excel') ||
      widget.item.mimeType!.contains('vnd.ms-powerpoint')
    );
    
    if (isPdf || isOffice) {
      setState(() {
        _loadingThumbnail = true;
      });
      
      final thumbnail = await DiskAnalyzerService.generateThumbnail(
        widget.item.path,
        widget.item.mimeType,
      );
      
      if (mounted) {
        setState(() {
          _thumbnailPath = thumbnail;
          _loadingThumbnail = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.item.mimeType != null && widget.item.mimeType!.startsWith('image/');
    final isPdf = widget.item.mimeType == 'application/pdf';
    final isOffice = widget.item.mimeType != null && (
      widget.item.mimeType!.contains('word') ||
      widget.item.mimeType!.contains('excel') ||
      widget.item.mimeType!.contains('powerpoint') ||
      widget.item.mimeType!.contains('spreadsheet') ||
      widget.item.mimeType!.contains('presentation') ||
      widget.item.mimeType!.contains('msword') ||
      widget.item.mimeType!.contains('vnd.ms-excel') ||
      widget.item.mimeType!.contains('vnd.ms-powerpoint')
    );
    final isAudio = widget.item.mimeType != null && widget.item.mimeType!.startsWith('audio/');
    final isVideo = widget.item.mimeType != null && widget.item.mimeType!.startsWith('video/');

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: Center(
                child: _buildPreview(context, isImage, isPdf, isOffice, isAudio, isVideo),
              ),
            ),
            if (_metadata != null && !_loadingMetadata)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.details,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_metadata!['size'] != null)
                      _DetailRow(
                        AppLocalizations.of(context)!.size,
                        DiskAnalyzerService.formatSize(_metadata!['size'] as int),
                      ),
                    if (_metadata!['type'] != null)
                      _DetailRow(
                        AppLocalizations.of(context)!.type,
                        _metadata!['type'] as String,
                      ),
                    if (_metadata!['mimeType'] != null)
                      _DetailRow(
                        AppLocalizations.of(context)!.fileType,
                        _metadata!['mimeType'] as String,
                      ),
                    if (isPdf && _metadata!['pages'] != null)
                      _DetailRow(
                        AppLocalizations.of(context)!.pages,
                        _metadata!['pages'].toString(),
                      ),
                    if (isAudio || isVideo) ...[
                      if (_metadata!['duration'] != null)
                        _DetailRow(
                          AppLocalizations.of(context)!.duration,
                          _metadata!['duration'] as String,
                        ),
                      if (_metadata!['bitrate'] != null)
                        _DetailRow(
                          AppLocalizations.of(context)!.bitrate,
                          _metadata!['bitrate'] as String,
                        ),
                      if (isVideo && _metadata!['resolution'] != null)
                        _DetailRow(
                          AppLocalizations.of(context)!.resolution,
                          _metadata!['resolution'] as String,
                        ),
                      if (isVideo && _metadata!['codec'] != null)
                        _DetailRow(
                          AppLocalizations.of(context)!.codec,
                          _metadata!['codec'] as String,
                        ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, bool isImage, bool isPdf, bool isOffice, bool isAudio, bool isVideo) {
    if (isImage) {
      return Image.file(
        File(widget.item.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 64),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.cannotPreviewFile),
              ],
            ),
          );
        },
      );
    } else if (isPdf || isOffice) {
      if (_loadingThumbnail) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_thumbnailPath != null) {
        return Image.file(
          File(_thumbnailPath!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                isPdf ? Icons.picture_as_pdf : Icons.description,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        );
      }
      return Center(
        child: Icon(
          isPdf ? Icons.picture_as_pdf : Icons.description,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (isAudio || isVideo) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAudio ? Icons.audio_file : Icons.video_file,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            if (_loadingMetadata)
              const CircularProgressIndicator()
            else if (_metadata != null)
              ...(_metadata!.entries.map((e) => Text('${e.key}: ${e.value}'))),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.cannotPreviewFile),
          ],
        ),
      );
    }
  }
}

/// Widget per il grafico a barre orizzontali del disco (mostra tutte le directory)
class _DiskPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> directories;

  const _DiskPieChart({
    required this.directories,
  });

  @override
  State<_DiskPieChart> createState() => _DiskPieChartState();
}

class _DiskPieChartState extends State<_DiskPieChart> {
  // ScrollController separati per etichette e barre (sincronizzati)
  late final ScrollController _labelsScrollController;
  late final ScrollController _barsScrollController;
  bool _isSyncing = false; // Flag per evitare loop infiniti nella sincronizzazione

  // Formatta la dimensione in modo compatto (es. "38G" invece di "38.00 GB")
  String _formatCompactSize(String sizeStr) {
    // Rimuove gli zeri decimali e abbrevia le unità
    if (sizeStr.contains(' GB')) {
      final num = sizeStr.replaceAll(' GB', '');
      final value = double.tryParse(num) ?? 0.0;
      if (value == value.toInt()) {
        return '${value.toInt()}G';
      }
      return '${value.toStringAsFixed(1)}G';
    } else if (sizeStr.contains(' MB')) {
      final num = sizeStr.replaceAll(' MB', '');
      final value = double.tryParse(num) ?? 0.0;
      if (value == value.toInt()) {
        return '${value.toInt()}M';
      }
      return '${value.toStringAsFixed(1)}M';
    } else if (sizeStr.contains(' KB')) {
      final num = sizeStr.replaceAll(' KB', '');
      final value = double.tryParse(num) ?? 0.0;
      if (value == value.toInt()) {
        return '${value.toInt()}K';
      }
      return '${value.toStringAsFixed(1)}K';
    } else if (sizeStr.contains(' TB')) {
      final num = sizeStr.replaceAll(' TB', '');
      final value = double.tryParse(num) ?? 0.0;
      if (value == value.toInt()) {
        return '${value.toInt()}T';
      }
      return '${value.toStringAsFixed(1)}T';
    }
    return sizeStr;
  }

  // Colori predefiniti per le directory
  static final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _labelsScrollController = ScrollController();
    _barsScrollController = ScrollController();
    
    // Sincronizza lo scroll delle etichette con le barre
    _labelsScrollController.addListener(() {
      if (!_isSyncing && _labelsScrollController.hasClients && _barsScrollController.hasClients) {
        final diff = (_labelsScrollController.position.pixels - _barsScrollController.position.pixels).abs();
        if (diff > 1.0) {
          _isSyncing = true;
          _barsScrollController.jumpTo(_labelsScrollController.position.pixels);
          _isSyncing = false;
        }
      }
    });
    
    // Sincronizza lo scroll delle barre con le etichette
    _barsScrollController.addListener(() {
      if (!_isSyncing && _labelsScrollController.hasClients && _barsScrollController.hasClients) {
        final diff = (_barsScrollController.position.pixels - _labelsScrollController.position.pixels).abs();
        if (diff > 1.0) {
          _isSyncing = true;
          _labelsScrollController.jumpTo(_barsScrollController.position.pixels);
          _isSyncing = false;
        }
      }
    });
  }

  @override
  void dispose() {
    _labelsScrollController.dispose();
    _barsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.directories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calcola il massimo per la scala del grafico
    // Supporta fino a 100TB (100 * 1024^4 bytes)
    final maxSize = widget.directories.fold<int>(0, (max, dir) {
      final size = dir['size'] as int;
      // Limita il maxSize a 100TB per evitare overflow, ma mostra tutte le directory
      final maxAllowed = 100 * 1024 * 1024 * 1024 * 1024; // 100TB
      if (size > max && size <= maxAllowed) {
        return size;
      } else if (size > maxAllowed) {
        // Se una directory supera 100TB, usa 100TB come massimo
        return maxAllowed;
      }
      return max;
    });
    
    if (maxSize == 0) {
      return const SizedBox.shrink();
    }

    // Mostra tutte le directory (nessun limite)
    final allDirectories = widget.directories.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.diskAnalyzerMainDirectories,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        // Limita l'altezza del grafico per permettere lo scroll e lasciare spazio alla lista
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 500, // Altezza massima del grafico
            minHeight: 200, // Altezza minima
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etichette directory (asse Y)
              SizedBox(
                width: 150,
                child: Column(
                  children: [
                    // Spazio vuoto per allineare con l'header delle barre (20px + 4px spacing)
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _labelsScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: allDirectories.map((dir) {
                            final dirName = dir['name'] as String;
                            return SizedBox(
                              height: 28, // Altezza aumentata per le etichette (24px barra + 4px padding)
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    dirName.length > 18 ? '${dirName.substring(0, 18)}...' : dirName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Grafico a barre orizzontali
              Expanded(
                child: Column(
                  children: [
                    // Valori sull'asse X (in alto)
                    SizedBox(
                      height: 20,
                      child: Stack(
                        children: [
                          // Linee di griglia verticali
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(5, (i) {
                              return Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: i < 4
                                          ? BorderSide(
                                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                                              width: 1,
                                            )
                                          : BorderSide.none,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          // Etichette valori
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0),
                                child: Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ),
                              ...List.generate(4, (i) {
                                final value = (maxSize / 4 * (i + 1)).toInt();
                                return Text(
                                  _formatCompactSize(DiskAnalyzerService.formatSize(value)),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Barre
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _barsScrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: allDirectories.asMap().entries.map((entry) {
                            final index = entry.key;
                            final dir = entry.value;
                            final size = dir['size'] as int;
                            final percentage = maxSize > 0 ? (size / maxSize) : 0.0;
                            final color = _colors[index % _colors.length];
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1.5),
                              child: SizedBox(
                                height: 24,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          // Linee di griglia verticali
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: List.generate(5, (i) {
                                              return Expanded(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      right: i < 4
                                                          ? BorderSide(
                                                              color: Theme.of(context).dividerColor.withOpacity(0.2),
                                                              width: 1,
                                                            )
                                                          : BorderSide.none,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                          // Sfondo grigio
                                          Container(
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          // Barra colorata
                                          FractionallySizedBox(
                                            widthFactor: percentage,
                                            child: Container(
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              alignment: Alignment.centerRight,
                                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                              child: Text(
                                                _formatCompactSize(dir['sizeFormatted'] as String),
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget per gli elementi della legenda
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double percentage;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '$value (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
