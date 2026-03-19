import 'dart:io';
import 'dart:convert';

/// Servizio per gestire la cache dei dati del disco
/// Ottimizza la lettura dei dati salvando le informazioni delle directory in cache
class DiskCacheService {
  static String? _cacheDir;
  
  /// Ottiene la directory della cache (in .local/share dell'app, non in .cache, per non essere cancellata dalla pulizia file temporanei)
  static Future<String> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;

    final homeDir = Platform.environment['HOME'] ?? '';
    _cacheDir = '$homeDir/.local/share/super-linux-utility/disk-analyzer';

    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return _cacheDir!;
  }
  
  /// Normalizza il percorso disco per cache (root è sempre "/")
  static String _normalizeDiskPath(String diskPath) {
    final t = diskPath.trim();
    if (t.isEmpty || t == '/') return '/';
    return t.endsWith('/') && t.length > 1 ? t.substring(0, t.length - 1) : t;
  }

  /// Genera una chiave di cache basata sul percorso del disco
  static String _getCacheKey(String diskPath) {
    final normalizedPath = _normalizeDiskPath(diskPath);
    if (normalizedPath == '/') return 'root';
    final safeKey = normalizedPath
        .replaceAll('/', '_')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
    return safeKey.isEmpty ? 'root' : safeKey;
  }
  
  /// Ottiene il percorso del file di cache per un disco
  static Future<String> _getCacheFile(String diskPath) async {
    final cacheDir = await _getCacheDir();
    final key = _getCacheKey(_normalizeDiskPath(diskPath));
    return '$cacheDir/$key.json';
  }
  
  /// Verifica se esiste una cache per un disco (il file viene creato una sola volta, poi solo aggiornato)
  static Future<bool> hasCache(String diskPath) async {
    try {
      final path = _normalizeDiskPath(diskPath);
      final cacheFile = await _getCacheFile(path);
      final file = File(cacheFile);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Carica i dati dalla cache (nessuna scadenza: la cache si aggiorna solo incrementalmente)
  static Future<Map<String, dynamic>?> loadCache(String diskPath) async {
    try {
      final path = _normalizeDiskPath(diskPath);
      final cacheFile = await _getCacheFile(path);
      final file = File(cacheFile);

      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return null;
    }
  }
  
  /// Salva i dati nella cache
  static Future<void> saveCache(
    String diskPath,
    Map<String, dynamic> data,
  ) async {
    try {
      final cacheFile = await _getCacheFile(diskPath);
      final file = File(cacheFile);
      
      // Aggiungi timestamp
      final cacheData = {
        ...data,
        'timestamp': DateTime.now().toIso8601String(),
        'diskPath': diskPath,
      };
      
      await file.writeAsString(
        jsonEncode(cacheData),
        mode: FileMode.write,
      );
    } catch (e) {
      // Ignora errori di scrittura cache
    }
  }
  
  /// Salva le dimensioni delle directory nella cache
  static Future<void> saveDirectorySizes(
    String diskPath,
    List<Map<String, dynamic>> directorySizes,
  ) async {
    final path = _normalizeDiskPath(diskPath);
    await saveCache(path, {
      'directorySizes': directorySizes,
    });
  }
  
  /// Carica le dimensioni delle directory dalla cache
  static Future<List<Map<String, dynamic>>?> loadDirectorySizes(String diskPath) async {
    final path = _normalizeDiskPath(diskPath);
    final cache = await loadCache(path);
    if (cache == null) return null;
    
    final sizes = cache['directorySizes'];
    if (sizes is List) {
      return sizes.cast<Map<String, dynamic>>();
    }
    
    return null;
  }
  
  /// Salva la lista dei file/directory nella cache
  static Future<void> saveDirectoryList(
    String diskPath,
    String directoryPath,
    List<Map<String, dynamic>> items,
  ) async {
    final cache = await loadCache(diskPath) ?? {};
    final directoryLists = (cache['directoryLists'] as Map<String, dynamic>?) ?? {};
    
    directoryLists[directoryPath] = items;
    
    await saveCache(diskPath, {
      ...cache,
      'directoryLists': directoryLists,
    });
  }
  
  /// Carica la lista dei file/directory dalla cache
  static Future<List<Map<String, dynamic>>?> loadDirectoryList(
    String diskPath,
    String directoryPath,
  ) async {
    final cache = await loadCache(diskPath);
    if (cache == null) return null;

    final directoryLists = cache['directoryLists'] as Map<String, dynamic>?;
    if (directoryLists == null) return null;

    final items = directoryLists[directoryPath];
    if (items is List) {
      return items.cast<Map<String, dynamic>>();
    }

    return null;
  }

  /// Aggiorna la cache in modo incrementale: mantiene voci esistenti invariate,
  /// rimuove quelle cancellate, aggiunge le nuove, aggiorna sul momento solo ciò che è modificato su disco (modified/size).
  static Future<void> updateDirectoryListIncremental(
    String diskPath,
    String directoryPath,
    List<Map<String, dynamic>> currentFromFs,
  ) async {
    final cache = await loadCache(diskPath);
    if (cache == null) return;

    final directoryLists = Map<String, dynamic>.from(cache['directoryLists'] as Map<String, dynamic>? ?? {});
    final cachedList = (directoryLists[directoryPath] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final fsByPath = {for (final e in currentFromFs) e['path'] as String: e};
    final cachedPaths = cachedList.map((e) => e['path'] as String).toSet();

    final merged = <Map<String, dynamic>>[];
    for (final c in cachedList) {
      final path = c['path'] as String?;
      if (path == null) continue;
      if (!fsByPath.containsKey(path)) continue; // rimosso su disco
      final fromFs = fsByPath[path]!;
      final cachedMod = c['modified'] as String?;
      final fsMod = fromFs['modified'] as String?;
      final cachedSize = c['size'] as int? ?? 0;
      final fsSize = fromFs['size'] as int? ?? 0;
      final isDir = c['isDirectory'] as bool? ?? false;
      if (cachedMod != fsMod || (!isDir && cachedSize != fsSize)) {
        merged.add(Map<String, dynamic>.from(fromFs));
      } else {
        merged.add(Map<String, dynamic>.from(c));
      }
    }
    for (final f in currentFromFs) {
      final path = f['path'] as String?;
      if (path != null && !cachedPaths.contains(path)) {
        merged.add(Map<String, dynamic>.from(f));
      }
    }
    directoryLists[directoryPath] = merged;
    await saveCache(diskPath, { ...cache, 'directoryLists': directoryLists });
  }

  /// Aggiorna solo le dimensioni (e modified) degli elementi in una lista già in cache.
  /// Usato dopo il calcolo in background: la lista in cache resta completa, si aggiornano solo size/modified per path corrispondenti.
  static Future<void> updateDirectoryListSizes(
    String diskPath,
    String directoryPath,
    List<Map<String, dynamic>> itemsWithSizes,
  ) async {
    final cache = await loadCache(diskPath);
    if (cache == null) return;

    final directoryLists = Map<String, dynamic>.from(cache['directoryLists'] as Map<String, dynamic>? ?? {});
    final cachedList = (directoryLists[directoryPath] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (cachedList.isEmpty) return;

    final sizeByPath = {for (final e in itemsWithSizes) e['path'] as String: e};

    for (int i = 0; i < cachedList.length; i++) {
      final path = cachedList[i]['path'] as String?;
      if (path == null) continue;
      final updated = sizeByPath[path];
      if (updated != null) {
        cachedList[i] = {
          ...cachedList[i],
          'size': updated['size'] ?? cachedList[i]['size'],
          if (updated['modified'] != null) 'modified': updated['modified'],
        };
      }
    }

    directoryLists[directoryPath] = cachedList;
    await saveCache(diskPath, { ...cache, 'directoryLists': directoryLists });
  }

  /// Aggiorna le dimensioni directory in modo incrementale: mantiene quelle ancora esistenti,
  /// rimuove cartelle cancellate, aggiunge nuove con size 0.
  static Future<void> updateDirectorySizesIncremental(
    String diskPath,
    List<Map<String, dynamic>> currentDirsFromFs,
    List<Map<String, dynamic>> cachedSizes,
  ) async {
    final currentPaths = currentDirsFromFs.map((e) => e['path'] as String).toSet();
    final cachedPaths = cachedSizes.map((e) => e['path'] as String).toSet();

    final merged = <Map<String, dynamic>>[
      ...cachedSizes.where((c) => currentPaths.contains(c['path'])),
      ...currentDirsFromFs.where((f) => !cachedPaths.contains(f['path'])).map((f) => {
        'name': f['name'],
        'path': f['path'],
        'size': 0,
        'sizeFormatted': '0 B',
      }),
    ];
    final path = _normalizeDiskPath(diskPath);
    final cache = await loadCache(path);
    if (cache != null) {
      await saveCache(path, { ...cache, 'directorySizes': merged });
    } else {
      await saveDirectorySizes(diskPath, merged);
    }
  }

  /// Invalida la cache per un disco specifico
  static Future<void> invalidateCache(String diskPath) async {
    try {
      final cacheFile = await _getCacheFile(diskPath);
      final file = File(cacheFile);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignora errori
    }
  }
  
  /// Pulisce tutta la cache
  static Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDir();
      final dir = Directory(cacheDir);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e) {
      // Ignora errori
    }
  }
  
  /// Ottiene la dimensione totale della cache
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDir();
      final dir = Directory(cacheDir);
      if (!await dir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in dir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}
