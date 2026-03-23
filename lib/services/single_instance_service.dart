import 'dart:convert';
import 'dart:io';

import 'package:super_linux_utility/config/application_constants.dart';

File _lockFile() {
  final cacheDir = Directory(
    Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME'] ?? '/tmp'}/.cache',
  );
  final appCacheDir = Directory('${cacheDir.path}/super-linux-utility');
  return File('${appCacheDir.path}/app.lock');
}

Directory _appCacheDir() {
  final cacheDir = Directory(
    Platform.environment['XDG_CACHE_HOME'] ??
        '${Platform.environment['HOME'] ?? '/tmp'}/.cache',
  );
  return Directory('${cacheDir.path}/super-linux-utility');
}

/// True se [pid] è molto probabilmente il processo principale di questa app (non un PID riusato).
///
/// `kill -0` da solo non basta: dopo crash/riavvio il PID nel lock può essere assegnato a un altro programma.
Future<bool> _processIsOurSuperLinuxUtility(int pid) async {
  if (pid <= 0) return false;

  if (!Platform.isLinux) {
    final result = await Process.run('kill', ['-0', '$pid'], runInShell: false);
    return result.exitCode == 0;
  }

  final marker = ApplicationConstants.linuxExecutableName;
  try {
    final cmdlineFile = File('/proc/$pid/cmdline');
    if (await cmdlineFile.exists()) {
      final bytes = await cmdlineFile.readAsBytes();
      final decoded = utf8.decode(bytes, allowMalformed: true)
          .replaceAll('\x00', ' ')
          .trim();
      if (decoded.contains(marker)) {
        return true;
      }
    }

    final exeLink = Link('/proc/$pid/exe');
    if (await exeLink.exists()) {
      final target = await exeLink.resolveSymbolicLinks();
      if (target.contains(marker)) {
        return true;
      }
    }
  } catch (_) {}

  return false;
}

/// Controlla se un'altra istanza dell'app è già in esecuzione (lock file con PID).
/// Restituisce true se questa è l'unica istanza (o il lock è obsoleto), false se un'altra istanza è attiva.
Future<bool> isSingleInstance() async {
  final appCacheDir = _appCacheDir();
  final lockFile = _lockFile();

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
        final alive = await Process.run(
          'kill',
          ['-0', existingPid.toString()],
          runInShell: false,
        );
        if (alive.exitCode == 0) {
          if (await _processIsOurSuperLinuxUtility(existingPid)) {
            return false; // altra istanza reale dell'app
          }
          // PID ancora "vivo" ma non è Super Linux Utility → lock obsoleto (riuso PID)
        }
        try {
          await lockFile.delete();
        } catch (_) {}
      }
    } catch (_) {
      try {
        await lockFile.delete();
      } catch (_) {}
    }
  }

  try {
    await lockFile.writeAsString(ourPid.toString());
  } catch (_) {
    return true;
  }
  return true;
}

/// Rimuove il lock file solo se contiene ancora il PID di questo processo (chiamare all'uscita).
Future<void> releaseSingleInstanceLock() async {
  final lockFile = _lockFile();
  try {
    if (!await lockFile.exists()) return;
    final content = await lockFile.readAsString();
    final lockPid = int.tryParse(content.trim());
    if (lockPid == pid) {
      await lockFile.delete();
    }
  } catch (_) {}
}
