import 'dart:io';
import 'password_storage.dart';

/// Voce di cache rilevata: id stabile, sottotitolo tecnico, dimensione.
class DevCacheInfo {
  final String id;
  final String subtitle;
  final int sizeBytes;
  const DevCacheInfo({
    required this.id,
    required this.subtitle,
    required this.sizeBytes,
  });
}

/// Pulizia avanzata: cache di sviluppo/build, log journald e vecchi header
/// del kernel. Solo voci effettivamente presenti vengono proposte.
class AdvancedCleanupService {
  static Future<ProcessResult> _runSudo(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception(
          'Password non salvata. Salva la password nelle impostazioni.');
    }
    final escaped = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    // TUTTO il comando gira come root (bash -c quotato): con `sudo -S cmd`
    // semplice, solo la prima parola sarebbe elevata e tutto dopo `&&`
    // (scrittura /etc, systemctl...) fallirebbe senza permessi.
    final fullCommand =
        'printf "%s\\n" "$escaped" | sudo -S bash -c ${_shellQuote(command)} 2>&1';
    return Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static Future<int> _dirSize(String path) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) return 0;
      final r = await Process.run('du', ['-sb', path], runInShell: false);
      if (r.exitCode != 0) return 0;
      final first = r.stdout.toString().trim().split(RegExp(r'\s+')).first;
      return int.tryParse(first) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static String get _home => Platform.environment['HOME'] ?? '';

  static Future<bool> _commandExists(String cmd) async {
    try {
      final r = await Process.run('which', [cmd], runInShell: false);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ── Dev & build caches ─────────────────────────────────────────

  /// Rileva le cache di sviluppo presenti con la loro dimensione.
  static Future<List<DevCacheInfo>> getDevCaches() async {
    final out = <DevCacheInfo>[];
    final home = _home;

    Future<void> addDir(String id, String path) async {
      final size = await _dirSize(path);
      if (size > 0) {
        out.add(DevCacheInfo(id: id, subtitle: path, sizeBytes: size));
      }
    }

    // pip cache
    if (await _commandExists('pip3') || await _commandExists('pip')) {
      await addDir('pip', '$home/.cache/pip');
    }
    // cargo registry + git checkouts (rigenerabili)
    if (await _commandExists('cargo')) {
      var total = 0;
      for (final p in [
        '$home/.cargo/registry',
        '$home/.cargo/git',
      ]) {
        total += await _dirSize(p);
      }
      if (total > 0) {
        out.add(DevCacheInfo(
            id: 'cargo',
            subtitle: '$home/.cargo/registry + /git',
            sizeBytes: total));
      }
    }
    // npm / yarn / pnpm
    if (await _commandExists('npm')) {
      await addDir('npm', '$home/.npm');
    }
    // go build cache
    if (await _commandExists('go')) {
      var total = await _dirSize('$home/.cache/go-build');
      total += await _dirSize('$home/go/pkg/mod/cache/download');
      if (total > 0) {
        out.add(DevCacheInfo(
            id: 'go',
            subtitle: '$home/.cache/go-build + module cache',
            sizeBytes: total));
      }
    }
    // gradle
    if (await Directory('$home/.gradle').exists()) {
      await addDir('gradle', '$home/.gradle/caches');
    }
    // docker: immagini inutilizzate
    final dockerSize = await getDockerReclaimableBytes();
    if (dockerSize != null && dockerSize > 0) {
      out.add(DevCacheInfo(
        id: 'docker',
        subtitle: 'docker image prune -a (unused images)',
        sizeBytes: dockerSize,
      ));
    }
    // vecchi header/immagini kernel
    final oldKernels = await getOldKernelPackages();
    if (oldKernels.isNotEmpty) {
      final size = await getOldKernelPackagesSize(oldKernels);
      final shown = oldKernels.take(3).join(', ');
      final more =
          oldKernels.length > 3 ? ' +${oldKernels.length - 3}' : '';
      out.add(DevCacheInfo(
        id: 'kernel-headers',
        subtitle: '$shown$more',
        sizeBytes: size,
      ));
    }
    return out;
  }

  /// Pulisce una voce per id. Ritorna true se riuscita.
  static Future<bool> cleanDevCache(String id) async {
    try {
      final home = _home;
      switch (id) {
        case 'pip':
          return await _cleanPaths(['$home/.cache/pip']);
        case 'cargo':
          return await _cleanPaths(
              ['$home/.cargo/registry', '$home/.cargo/git']);
        case 'npm':
          if (await _commandExists('npm')) {
            final r = await Process.run(
                'npm', ['cache', 'clean', '--force'],
                runInShell: false);
            if (r.exitCode == 0) return true;
          }
          return await _cleanPaths(['$home/.npm']);
        case 'go':
          if (await _commandExists('go')) {
            final r = await Process.run('go', ['clean', '-cache'],
                runInShell: false);
            if (r.exitCode == 0) return true;
          }
          return await _cleanPaths(['$home/.cache/go-build']);
        case 'gradle':
          return await _cleanPaths(['$home/.gradle/caches']);
        case 'docker':
          return await _pruneDockerImages();
        case 'kernel-headers':
          return await removeOldKernelPackages();
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _cleanPaths(List<String> paths) async {
    var ok = true;
    for (final p in paths) {
      try {
        final dir = Directory(p);
        if (!await dir.exists()) continue;
        final r = await Process.run(
            'bash', ['-c', 'rm -rf "$p"/* 2>&1'],
            runInShell: true);
        if (r.exitCode != 0) {
          // Riprova con sudo (permessi root).
          try {
            final s = await _runSudo('rm -rf "$p"/*');
            if (s.exitCode != 0) ok = false;
          } catch (_) {
            ok = false;
          }
        }
      } catch (_) {
        ok = false;
      }
    }
    return ok;
  }

  // ── Docker ─────────────────────────────────────────────────────

  static Future<bool> _dockerUsable() async {
    if (!await _commandExists('docker')) return false;
    try {
      final r = await Process.run('docker', ['info'],
          runInShell: false);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Byte reclamabili dalle immagini inutilizzate (null se docker assente).
  static Future<int?> getDockerReclaimableBytes() async {
    if (!await _dockerUsable()) return null;
    try {
      final r = await Process.run(
          'docker', ['system', 'df'], runInShell: false);
      if (r.exitCode != 0) return null;
      return parseDockerReclaimable(r.stdout.toString());
    } catch (_) {
      return null;
    }
  }

  /// Estrae i byte "Reclaimable" dall'output di `docker system df`.
  static int parseDockerReclaimable(String output) {
    // Es. "Images    5    2    2.5GB    1.8GB (72%)"
    var total = 0;
    for (final line in output.split('\n')) {
      final m = RegExp(
              r'(\d+(?:\.\d+)?)\s*([KMGT]?B)\s*\(\d+%\s*\)',
              caseSensitive: false)
          .firstMatch(line);
      if (m != null) {
        total += _sizeToBytes(
            double.tryParse(m.group(1)!) ?? 0, m.group(2)!.toUpperCase());
      }
    }
    return total;
  }

  static int _sizeToBytes(double v, String unit) {
    switch (unit) {
      case 'KB':
      case 'K':
        return (v * 1024).round();
      case 'MB':
      case 'M':
        return (v * 1024 * 1024).round();
      case 'GB':
      case 'G':
        return (v * 1024 * 1024 * 1024).round();
      case 'TB':
      case 'T':
        return (v * 1024 * 1024 * 1024 * 1024).round();
      default:
        return v.round();
    }
  }

  static Future<bool> _pruneDockerImages() async {
    if (!await _commandExists('docker')) return false;
    try {
      var r = await Process.run(
          'docker', ['image', 'prune', '-a', '-f'],
          runInShell: false);
      if (r.exitCode == 0) return true;
      final s = await _runSudo('docker image prune -a -f');
      return s.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ── Vecchi kernel ──────────────────────────────────────────────

  static Future<String> _runningKernel() async {
    try {
      final r =
          await Process.run('uname', ['-r'], runInShell: false);
      if (r.exitCode == 0) return r.stdout.toString().trim();
    } catch (_) {}
    return '';
  }

  static Future<bool> _hasApt() async =>
      await _commandExists('apt-get') && await _commandExists('dpkg');
  static Future<bool> _hasDnf() async =>
      await _commandExists('dnf') && await _commandExists('rpm');

  /// Pacchetti kernel vecchi rimovibili (mai quello in uso).
  static Future<List<String>> getOldKernelPackages() async {
    try {
      if (await _hasApt()) return await _oldKernelsApt();
      if (await _hasDnf()) return await _oldKernelsDnf();
    } catch (_) {}
    return [];
  }

  static Future<List<String>> _oldKernelsApt() async {
    final r = await Process.run('bash', [
      '-c',
      "dpkg -l 'linux-image-*' 'linux-headers-*' 'linux-modules-*' 2>/dev/null | awk '/^ii/ {print \$2}'"
    ], runInShell: false);
    if (r.exitCode != 0) return [];
    final all = r.stdout
        .toString()
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return filterOldKernelPackagesApt(all, await _runningKernel());
  }

  /// Tiene kernel in uso + meta-pacchetti + ultima versione di scorta.
  static List<String> filterOldKernelPackagesApt(
      List<String> all, String running) {
    final runningNums = _versionNumbers(running);
    // Raggruppa per versione numerica (es. 6.8.0-60).
    final byVersion = <String, List<String>>{};
    for (final p in all) {
      if (!RegExp(r'\d').hasMatch(p)) continue; // meta-pacchetto: tienilo
      final v = _versionNumbers(p);
      if (v.isEmpty) continue;
      byVersion.putIfAbsent(v, () => []).add(p);
    }
    if (byVersion.isEmpty) return [];
    // Versioni ordinate, tieni l'ultima come scorta + quella in uso.
    final sorted = byVersion.keys.toList()..sort(_compareVersions);
    final keep = <String>{sorted.last};
    if (runningNums.isNotEmpty) keep.add(runningNums);
    final out = <String>[];
    for (final entry in byVersion.entries) {
      if (keep.contains(entry.key)) continue;
      // Mai toccare il kernel in uso (doppia protezione per nome).
      out.addAll(entry.value.where((p) =>
          running.isEmpty || !p.contains(_runningShort(running))));
    }
    // Non proporre nulla se resterebbe solo il kernel in uso: già coperto.
    return out;
  }

  static String _runningShort(String running) {
    // "6.8.0-60-generic" -> "6.8.0-60"
    final m =
        RegExp(r'(\d+\.\d+\.\d+-\d+)').firstMatch(running);
    return m?.group(1) ?? running;
  }

  static String _versionNumbers(String s) {
    final m =
        RegExp(r'(\d+\.\d+\.\d+-\d+)').firstMatch(s);
    return m?.group(1) ?? '';
  }

  static int _compareVersions(String a, String b) {
    List<int> parts(String v) => v
        .split(RegExp(r'[.\-]'))
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < pa.length && i < pb.length; i++) {
      if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
    }
    return pa.length.compareTo(pb.length);
  }

  static Future<List<String>> _oldKernelsDnf() async {
    final r = await Process.run('bash', [
      '-c',
      'rpm -q kernel kernel-core kernel-modules kernel-modules-core kernel-devel 2>/dev/null'
    ], runInShell: false);
    if (r.exitCode != 0) return [];
    final all = r.stdout
        .toString()
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !s.contains('not installed'))
        .toList();
    return filterOldKernelPackagesDnf(all, await _runningKernel());
  }

  /// Tiene kernel in uso + più recente per ogni nome pacchetto.
  static List<String> filterOldKernelPackagesDnf(
      List<String> all, String running) {
    final byName = <String, List<String>>{};
    for (final p in all) {
      // "kernel-core-6.5.6-200.fc38.x86_64" -> nome "kernel-core"
      final m = RegExp(r'^(.+)-(\d+\.\d+\.\d+[^ ]*)$').firstMatch(p);
      if (m == null) continue;
      byName.putIfAbsent(m.group(1)!, () => []).add(p);
    }
    final out = <String>[];
    for (final entry in byName.values) {
      if (entry.length <= 2) {
        // Tieni tutto se ce ne sono al massimo 2 (uso + scorta).
        // Rimuovi solo se nessuno è quello in uso? No: prudenza, tieni.
        continue;
      }
      final sorted = List<String>.from(entry)..sort();
      // Tieni gli ultimi 2 (uso presunto + scorta), mai quello in uso.
      final keep = sorted.skip(sorted.length - 2).toSet();
      for (final p in entry) {
        if (keep.contains(p)) continue;
        if (running.isNotEmpty && p.contains(running)) continue;
        out.add(p);
      }
    }
    return out;
  }

  static Future<int> getOldKernelPackagesSize(List<String> pkgs) async {
    if (pkgs.isEmpty) return 0;
    try {
      if (await _hasApt()) {
        final r = await Process.run('bash', [
          '-c',
          "dpkg-query -W -f='\${Installed-Size}\n' ${pkgs.join(' ')} 2>/dev/null"
        ], runInShell: false);
        if (r.exitCode == 0) {
          var kb = 0;
          for (final line in r.stdout.toString().split('\n')) {
            kb += int.tryParse(line.trim()) ?? 0;
          }
          return kb * 1024;
        }
      } else if (await _hasDnf()) {
        final r = await Process.run('bash', [
          '-c',
          "rpm -q --queryformat '%{SIZE}\n' ${pkgs.join(' ')} 2>/dev/null"
        ], runInShell: false);
        if (r.exitCode == 0) {
          var bytes = 0;
          for (final line in r.stdout.toString().split('\n')) {
            bytes += int.tryParse(line.trim()) ?? 0;
          }
          return bytes;
        }
      }
    } catch (_) {}
    return 0;
  }

  static Future<bool> removeOldKernelPackages() async {
    final pkgs = await getOldKernelPackages();
    if (pkgs.isEmpty) return true;
    try {
      if (await _hasApt()) {
        final r = await _runSudo(
            'apt-get purge -y ${pkgs.join(' ')} && apt-get autoremove -y');
        return r.exitCode == 0;
      } else if (await _hasDnf()) {
        final r =
            await _runSudo('dnf remove -y ${pkgs.join(' ')}');
        return r.exitCode == 0;
      }
    } catch (_) {}
    return false;
  }

  // ── Journald ───────────────────────────────────────────────────

  /// Spazio occupato dai journal (byte). null se journalctl assente.
  static Future<int?> getJournalBytes() async {
    if (!await _commandExists('journalctl')) return null;
    try {
      final r = await Process.run(
          'journalctl', ['--disk-usage'],
          runInShell: false);
      if (r.exitCode != 0) return null;
      return parseJournalDiskUsage(r.stdout.toString());
    } catch (_) {
      return null;
    }
  }

  /// Parsifica "Journals take up 1.2G" in byte (journalctl usa K/M/G/T
  /// senza la B finale).
  static int? parseJournalDiskUsage(String output) {
    final m = RegExp(
            r'take up\s+(\d+(?:\.\d+)?)\s*([KMGT]B?)',
            caseSensitive: false)
        .firstMatch(output);
    if (m == null) return null;
    return _sizeToBytes(
        double.tryParse(m.group(1)!) ?? 0, m.group(2)!.toUpperCase());
  }

  /// Compatta i journal alla dimensione data (es. "500M"). Richiede sudo.
  static Future<bool> vacuumJournal(String size) async {
    if (!RegExp(r'^\d+[MG]$').hasMatch(size)) return false;
    try {
      final r =
          await _runSudo('journalctl --vacuum-size=$size');
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Limite persistente attuale (SystemMaxUse) o null se non impostato.
  static Future<String?> getJournalSystemMaxUse() async {
    try {
      // Drop-in dedicati prima, poi journald.conf.
      final dir = Directory('/etc/systemd/journald.conf.d');
      if (await dir.exists()) {
        await for (final e in dir.list()) {
          if (e is File && e.path.endsWith('.conf')) {
            final v = _parseSystemMaxUse(await e.readAsString());
            if (v != null) return v;
          }
        }
      }
      final main = File('/etc/systemd/journald.conf');
      if (await main.exists()) {
        return _parseSystemMaxUse(await main.readAsString());
      }
    } catch (_) {}
    return null;
  }

  static String? _parseSystemMaxUse(String content) {
    for (final line in content.split('\n')) {
      final t = line.trim();
      if (t.startsWith('#') || t.isEmpty) continue;
      final m = RegExp(r'^SystemMaxUse\s*=\s*(\S+)').firstMatch(t);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// Comando che scrive il drop-in journald, riavvia il servizio e compatta.
  /// Usa doppi apici (niente apici singoli: viaggiano dentro un ulteriore
  /// quoting in _runSudo) e tollera il restart fallito (es. senza systemd).
  static String buildJournalLimitCommand(String size) {
    final conf = '[Journal]\nSystemMaxUse=$size\n';
    return 'mkdir -p /etc/systemd/journald.conf.d && printf "%s" "$conf" > '
        '/etc/systemd/journald.conf.d/99-slu-limit.conf && '
        '(systemctl restart systemd-journald || true) && '
        'journalctl --vacuum-size=$size';
  }

  /// Imposta il limite persistente + vacuum immediato + restart journald.
  /// Ritorna true solo se il limite risulta davvero applicato (riletto).
  static Future<bool> setJournalSystemMaxUse(String size) async {
    if (!RegExp(r'^\d+[MG]$').hasMatch(size)) return false;
    try {
      final r = await _runSudo(buildJournalLimitCommand(size));
      if (r.exitCode != 0) return false;
      return await getJournalSystemMaxUse() == size;
    } catch (_) {
      return false;
    }
  }
}
