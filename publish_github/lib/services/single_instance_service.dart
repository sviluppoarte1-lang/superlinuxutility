import 'dart:io';

/// Controlla se un'altra istanza dell'app è già in esecuzione (lock file con PID).
/// Restituisce true se questa è l'unica istanza (o il lock è obsoleto), false se un'altra istanza è attiva.
Future<bool> isSingleInstance() async {
  final cacheDir = Directory(
    Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME'] ?? '/tmp'}/.cache',
  );
  final appCacheDir = Directory('${cacheDir.path}/super-linux-utility');
  final lockFile = File('${appCacheDir.path}/app.lock');

  try {
    if (!await appCacheDir.exists()) {
      await appCacheDir.create(recursive: true);
    }
  } catch (_) {
    return true; // in caso di errore procedi comunque
  }

  final ourPid = pid;

  if (await lockFile.exists()) {
    try {
      final content = await lockFile.readAsString();
      final existingPid = int.tryParse(content.trim());
      if (existingPid != null && existingPid != ourPid) {
        // Verifica se il processo con existingPid è ancora in esecuzione
        final result = await Process.run('kill', ['-0', existingPid.toString()],
            runInShell: false);
        if (result.exitCode == 0) {
          return false; // altra istanza in esecuzione
        }
        // Lock obsoleto (processo non più attivo), rimuovilo e continua
      }
    } catch (_) {
      // Ignora errori di lettura
    }
  }

  try {
    await lockFile.writeAsString(ourPid.toString());
  } catch (_) {
    return true;
  }
  return true;
}

/// Rimuove il lock file (chiamare all'uscita dell'app).
Future<void> releaseSingleInstanceLock() async {
  final cacheDir = Directory(
    Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME'] ?? '/tmp'}/.cache',
  );
  final lockFile = File('${cacheDir.path}/super-linux-utility/app.lock');
  try {
    if (await lockFile.exists()) {
      await lockFile.delete();
    }
  } catch (_) {}
}
