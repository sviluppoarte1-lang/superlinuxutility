import 'disk_cache_service.dart';

/// Motore interno che traccia lo stato di indicizzazione dei dischi
/// nell'Analizzatore Disco.
///
/// Un disco è considerato "indicizzato" quando è stata completata la prima
/// scansione completa (directory + dimensioni), i cui risultati sono salvati
/// nella cache persistente dell'analizzatore. Alla prima apertura l'app mostra
/// un piccolo avviso di indicizzazione finché la scansione non è terminata.
class DiskIndexingEngine {
  DiskIndexingEngine._();

  /// Chiave salvata nel JSON della cache quando la scansione completa è finita.
  static const String cacheFlag = 'fullyIndexed';

  /// Chiave SharedPreferences usata come segnale globale "indicizzato almeno una volta".
  static const String everIndexedPrefKey = 'disk_analyzer_ever_indexed';

  /// Dischi già marcati come indicizzati in questa sessione (evita riletture).
  static final Set<String> _indexedInSession = {};

  static String _normalizePath(String diskPath) {
    final t = diskPath.trim();
    if (t.isEmpty || t == '/') return '/';
    return t.endsWith('/') && t.length > 1 ? t.substring(0, t.length - 1) : t;
  }

  /// True se il disco ha già completato la prima indicizzazione.
  ///
  /// Controlla prima lo stato di sessione, poi la cache persistente.
  /// Una cache con `directorySizes` non vuoti (es. generata da versioni
  /// precedenti) è considerata già indicizzata.
  static Future<bool> isIndexed(String diskPath) async {
    final norm = _normalizePath(diskPath);
    if (_indexedInSession.contains(norm)) return true;
    try {
      final cache = await DiskCacheService.loadCache(norm);
      if (cache != null) {
        if (cache[cacheFlag] == true) {
          _indexedInSession.add(norm);
          return true;
        }
        final sizes = cache['directorySizes'];
        if (sizes is List && sizes.isNotEmpty) {
          _indexedInSession.add(norm);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Segna il disco come indicizzato (persistito nella cache del disco).
  static Future<void> markIndexed(String diskPath) async {
    final norm = _normalizePath(diskPath);
    _indexedInSession.add(norm);
    try {
      final cache = await DiskCacheService.loadCache(norm) ?? {};
      await DiskCacheService.saveCache(norm, {...cache, cacheFlag: true});
    } catch (_) {}
  }
}
