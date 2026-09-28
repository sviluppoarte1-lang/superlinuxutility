import 'dart:io';
import 'password_storage.dart';

/// Snapshot dei valori di RAM letti da /proc/meminfo.
class RamStats {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final int availableBytes;
  final int cachedBytes;
  final int swapTotalBytes;
  final int swapUsedBytes;

  const RamStats({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.availableBytes,
    required this.cachedBytes,
    required this.swapTotalBytes,
    required this.swapUsedBytes,
  });

  int get usedPercent =>
      totalBytes > 0 ? (usedBytes / totalBytes * 100).round() : 0;

  int get freedSwap => swapUsedBytes > 0 ? swapUsedBytes : 0;

  bool get hasSwap => swapTotalBytes > 0;
}

/// Esito della pulizia della RAM.
class RamCleanupResult {
  final bool success;
  final RamStats? before;
  final RamStats? after;
  final List<String> stepsDone;
  final List<String> stepsFailed;
  final String? error;

  const RamCleanupResult({
    required this.success,
    this.before,
    this.after,
    required this.stepsDone,
    required this.stepsFailed,
    this.error,
  });

  int? get freedBytes {
    if (before == null || after == null) return null;
    final beforeUsed = before!.usedBytes;
    final afterUsed = after!.usedBytes;
    final freed = beforeUsed - afterUsed;
    return freed > 0 ? freed : 0;
  }
}

/// Pulizia della RAM per tutte le distribuzioni Linux.
/// Solo operazioni non invasive: NON tocca servizi né file temporanei.
///  1. drop_caches (page cache, dentries, inodes) — richiede root
///  2. riciclo dello swap (swapoff + swapon) — richiede root
class RamCleanupService {
  static const String prefKeyIntervalMinutes = 'ram_cleanup_interval_minutes';
  static const String prefKeyLastRunTs = 'ram_cleanup_last_run_ts';

  static const int intervalDisabled = 0;

  /// Legge i valori della RAM da /proc/meminfo.
  static Future<RamStats> getRamStats() async {
    try {
      final content = await File('/proc/meminfo').readAsString();
      int total = 0, free = 0, available = 0, buffers = 0, cached = 0,
          sReclaimable = 0, shmem = 0, swapTotal = 0, swapFree = 0;
      for (final line in content.split('\n')) {
        if (!line.contains(':')) continue;
        final idx = line.indexOf(':');
        final key = line.substring(0, idx).trim();
        final valueKb =
            int.tryParse(line.substring(idx + 1).trim().split(RegExp(r'\s+')).first) ?? 0;
        switch (key) {
          case 'MemTotal': total = valueKb; break;
          case 'MemFree': free = valueKb; break;
          case 'MemAvailable': available = valueKb; break;
          case 'Buffers': buffers = valueKb; break;
          case 'Cached': cached = valueKb; break;
          case 'SReclaimable': sReclaimable = valueKb; break;
          case 'Shmem': shmem = valueKb; break;
          case 'SwapTotal': swapTotal = valueKb; break;
          case 'SwapFree': swapFree = valueKb; break;
        }
      }
      const kb = 1024;
      final cacheKb = cached + sReclaimable;
      final usedKb = (total - free - buffers - cacheKb - shmem).clamp(0, total);
      return RamStats(
        totalBytes: total * kb,
        usedBytes: usedKb * kb,
        freeBytes: free * kb,
        availableBytes: available * kb,
        cachedBytes: cacheKb * kb,
        swapTotalBytes: swapTotal * kb,
        swapUsedBytes: ((swapTotal - swapFree) * kb).clamp(0, 1 << 62),
      );
    } catch (_) {
      try {
        final result = await Process.run('bash', ['-c', 'LANG=C free -b']);
        final output = result.stdout.toString();
        int totalB = 0, usedB = 0, freeB = 0, availB = 0, cacheB = 0,
            swapTB = 0, swapUB = 0;
        for (final line in output.split('\n')) {
          final parts = line.split(RegExp(r'\s+'));
          if (line.startsWith('Mem:')) {
            if (parts.length >= 3) {
              totalB = int.tryParse(parts[1]) ?? 0;
              usedB = int.tryParse(parts[2]) ?? 0;
              freeB = int.tryParse(parts[3]) ?? 0;
            }
            if (parts.length >= 7) cacheB = int.tryParse(parts[6]) ?? 0;
          } else if (line.startsWith('Swap:')) {
            if (parts.length >= 3) {
              swapTB = int.tryParse(parts[1]) ?? 0;
              swapUB = int.tryParse(parts[2]) ?? 0;
            }
          }
        }
        availB = totalB - usedB;
        return RamStats(
          totalBytes: totalB,
          usedBytes: usedB,
          freeBytes: freeB,
          availableBytes: availB,
          cachedBytes: cacheB,
          swapTotalBytes: swapTB,
          swapUsedBytes: swapUB,
        );
      } catch (_) {
        return const RamStats(
          totalBytes: 0,
          usedBytes: 0,
          freeBytes: 0,
          availableBytes: 0,
          cachedBytes: 0,
          swapTotalBytes: 0,
          swapUsedBytes: 0,
        );
      }
    }
  }

  static Future<bool> _canUseSudo() async {
    try {
      final password = await PasswordStorage.getPassword();
      return password != null && password.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<ProcessResult> _runSudoCommand(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata.');
    }
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll("'", r"\'");
    final fullCommand =
        'printf "%s\\n" "$escapedPassword" | sudo -S bash -c ${shellQuote(command)} 2>&1';
    return Process.run('bash', ['-c', fullCommand], runInShell: true);
  }

  static String shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static Future<ProcessResult> _run(String command) =>
      Process.run('bash', ['-c', command], runInShell: false);

  /// Esegue la pulizia della RAM (solo drop_caches + riciclo swap).
  /// NON tocca servizi di sistema né file temporanei.
  /// Ritorna un [RamCleanupResult] con statistiche prima/dopo.
  static Future<RamCleanupResult> cleanupRam() async {
    final before = await getRamStats();
    final stepsDone = <String>[];
    final stepsFailed = <String>[];
    final hasSudo = await _canUseSudo();

    try {
      // 1) Sincronizza i file system prima di liberare le cache.
      await _run('sync 2>&1');
      stepsDone.add('sync');

      // 2) drop_caches (page cache + dentries + inodes).
      const dropCacheCmds = [
        'sync; echo 1 > /proc/sys/vm/drop_caches',
        'echo 2 > /proc/sys/vm/drop_caches',
        'echo 3 > /proc/sys/vm/drop_caches',
      ];
      var dropped = false;
      for (final cmd in dropCacheCmds) {
        try {
          final result =
              hasSudo ? await _runSudoCommand(cmd) : await _run(cmd);
          if (result.exitCode == 0) dropped = true;
        } catch (_) {}
      }
      if (dropped) {
        stepsDone.add('drop_caches');
      } else {
        stepsFailed.add('drop_caches (richiede password amministratore)');
      }

      // 3) Riciclo dello swap: libera la RAM usata da dati inattivi.
      //    Preserva zram: se attivo prima del cleanup, viene riattivato dopo.
      try {
        // Detect zram prima di swapoff
        bool zramWasActive = false;
        try {
          final zramCheck = await _run('swapon --show=NAME --noheadings 2>/dev/null');
          zramWasActive = (zramCheck.stdout as String).trim().contains('zram');
        } catch (_) {}

        final swapStats = await _run(r"free -b | awk '/Swap/ {print $2, $3}'");
        final swapParts = swapStats.stdout.toString().trim().split(RegExp(r'\s+'));
        final swapUsed = swapParts.length >= 2 ? int.tryParse(swapParts[1]) ?? 0 : 0;
        if (swapUsed > 0 || zramWasActive) {
          final result = hasSudo
              ? await _runSudoCommand('swapoff -a 2>&1 && swapon -a 2>&1')
              : await _run('swapoff -a 2>&1 && swapon -a 2>&1');
          if (result.exitCode == 0) {
            stepsDone.add('swap reclaim');
          } else {
            final result2 = hasSudo
                ? await _runSudoCommand('swapon -a 2>&1')
                : await _run('swapon -a 2>&1');
            if (result2.exitCode == 0) {
              stepsDone.add('swap reclaim (parziale)');
            } else {
              stepsFailed.add('swap reclaim');
            }
          }

          // Riattiva zram se era attivo prima del cleanup
          if (zramWasActive) {
            try {
              final zramNow = await _run('swapon --show=NAME --noheadings 2>/dev/null');
              final stillActive = (zramNow.stdout as String).trim().contains('zram');
              if (!stillActive) {
                if (hasSudo) {
                  await _runSudoCommand('systemctl start zramswap 2>/dev/null || true');
                } else {
                  await _run('systemctl start zramswap 2>/dev/null || true');
                }
                stepsDone.add('zram restored');
              }
            } catch (_) {}
          }
        } else {
          stepsDone.add('swap (nessuno swap in uso)');
        }
      } catch (_) {
        stepsFailed.add('swap reclaim');
      }

      // 4) Sincronizza di nuovo per consolidare.
      await _run('sync 2>&1');

      final after = await getRamStats();
      final success = true;
      return RamCleanupResult(
        success: success,
        before: before,
        after: after,
        stepsDone: stepsDone,
        stepsFailed: stepsFailed,
      );
    } catch (e) {
      return RamCleanupResult(
        success: false,
        before: before,
        after: await getRamStats(),
        stepsDone: stepsDone,
        stepsFailed: stepsFailed,
        error: e.toString(),
      );
    }
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
