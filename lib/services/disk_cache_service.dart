import 'dart:io';
import 'dart:convert';

/// Servizio per gestire la cache dei dati del disco
/// Ottimizza la lettura dei dati salvando le informazioni delle directory in cache
class DiskCacheService {
  static String? _cacheDir;
  
  /// Ottiene la directory della cache
  static Future<String> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    
    final homeDir = Platform.environment['HOME'] ?? '';
    _cacheDir = '$homeDir/.cache/super-linux-utility/disk-analyzer';
    
    // Crea la directory se non esiste
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
  
  /// Verifica se esiste una cache valida per un disco
  static Future<bool> hasCache(String diskPath) async {
    try {
      final path = _normalizeDiskPath(diskPath);
      final cacheFile = await _getCacheFile(path);
      final file = File(cacheFile);
      
      if (!await file.exists()) {
        return false;
      }
      
      // Verifica che il file non sia troppo vecchio (24 ore)
      final stat = await file.stat();
      final age = DateTime.now().difference(stat.modified);
      if (age.inHours > 24) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Carica i dati dalla cache
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
      
      // Verifica che la cache non sia troppo vecchia
      final cacheTime = DateTime.parse(data['timestamp'] as String);
      final age = DateTime.now().difference(cacheTime);
      if (age.inHours > 24) {
        return null;
      }
      
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
