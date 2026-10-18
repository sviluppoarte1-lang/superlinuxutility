import 'dart:io';
import '../utils/process_utils.dart';
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

/// Revisione snap non corrente (disabilitata dopo un aggiornamento).
class SnapOldRevision {
  final String name;
  final String rev;
  const SnapOldRevision({required this.name, required this.rev});
}

/// Runtime flatpak non usato (id + branch) estratto dal dry-run.
class FlatpakUnusedRef {
  final String name;
  final String branch;
  const FlatpakUnusedRef({required this.name, required this.branch});
}

/// Runtime flatpak non usati: conteggio + dimensione stimata.
class FlatpakUnusedInfo {
  final int refCount;
  final int sizeBytes;
  const FlatpakUnusedInfo({
    required this.refCount,
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
    return runProcess(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
      timeout: const Duration(seconds: 300),
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
      // du esce con codice 1 se una sottocartella non è leggibile (es.
      // /var/cache/apt/archives/partial in 700): il totale parziale viene
      // comunque stampato su stdout ed è valido per una stima.
      final out = r.stdout.toString().trim();
      if (out.isEmpty) return 0;
      final first = out.split(RegExp(r'\s+')).first;
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
    // Cache del package manager: .deb/.rpm/.pkg scaricati + indici binari.
    final pmSize = await getPackageManagerCacheBytes();
    if (pmSize > 0) {
      out.add(DevCacheInfo(
        id: 'pkg-cache',
        subtitle: await _pmCacheSubtitle(),
        sizeBytes: pmSize,
      ));
    }
    // Cache Electron/Chromium delle app desktop (Cache, GPUCache...).
    final electronDirs = await findElectronCacheDirs();
    if (electronDirs.isNotEmpty) {
      var total = 0;
      for (final p in electronDirs) {
        total += await _dirSize(p);
      }
      if (total > 0) {
        out.add(DevCacheInfo(
          id: 'electron-cache',
          subtitle: _shortPath(electronDirs.first) +
              (electronDirs.length > 1
                  ? ' (+${electronDirs.length - 1})'
                  : ''),
          sizeBytes: total,
        ));
      }
    }
    // OpenCode: log e snapshot (il database NO: è in uso continuo).
    final ocDirs = await findOpencodeDataDirs();
    if (ocDirs.isNotEmpty) {
      var total = 0;
      for (final p in ocDirs) {
        total += await _dirSize(p);
      }
      if (total > 0) {
        out.add(DevCacheInfo(
          id: 'opencode-data',
          subtitle: ocDirs.map(_shortPath).join(' + '),
          sizeBytes: total,
        ));
      }
    }
    // Repository installer CUDA locali (deb già scaricati).
    final cudaRepoDirs = await findCudaRepoDirs();
    if (cudaRepoDirs.isNotEmpty) {
      var total = 0;
      for (final p in cudaRepoDirs) {
        total += await _dirSize(p);
      }
      if (total > 0) {
        out.add(DevCacheInfo(
          id: 'cuda-repo',
          subtitle: cudaRepoDirs.map(_shortPath).join(' + '),
          sizeBytes: total,
        ));
      }
    }
    // Installazioni CUDA duplicate: si tiene solo quella attiva (nvcc).
    final cudaDups = await findDuplicateCudaDirs();
    if (cudaDups.isNotEmpty) {
      var total = 0;
      for (final p in cudaDups) {
        total += await _dirSize(p);
      }
      if (total > 0) {
        out.add(DevCacheInfo(
          id: 'cuda-dup',
          subtitle: cudaDups.map(_shortPath).join(' + '),
          sizeBytes: total,
        ));
      }
    }
    // Revisioni snap vecchie (disabilitate, con file .snap ancora presenti).
    final snapOld = await getOldSnapRevisions();
    if (snapOld.isNotEmpty) {
      final size = await getOldSnapRevisionsSize(snapOld);
      if (size > 0) {
        final shown =
            snapOld.take(3).map((e) => '${e.name} (${e.rev})').join(', ');
        final more = snapOld.length > 3 ? ' +${snapOld.length - 3}' : '';
        out.add(DevCacheInfo(
          id: 'snap-old',
          subtitle: '$shown$more',
          sizeBytes: size,
        ));
      }
    }
    // Flatpak: runtime non più usati (system + user), scoperti con dry-run.
    final fp = await getFlatpakUnused();
    if (fp != null && fp.refCount > 0 && fp.sizeBytes > 0) {
      out.add(DevCacheInfo(
        id: 'flatpak-unused',
        subtitle: 'flatpak uninstall --unused (${fp.refCount} runtimes)',
        sizeBytes: fp.sizeBytes,
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
        case 'pkg-cache':
          return await cleanPackageManagerCache();
        case 'electron-cache':
          return await _cleanDirs(await findElectronCacheDirs());
        case 'opencode-data':
          return await _cleanDirs(await findOpencodeDataDirs());
        case 'cuda-repo':
          return await _cleanDirs(await findCudaRepoDirs());
        case 'cuda-dup':
          return await removeDuplicateCudaInstalls();
        case 'snap-old':
          return await removeOldSnapRevisions(await getOldSnapRevisions());
        case 'flatpak-unused':
          return await cleanFlatpakUnused();
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

  /// Rimuove intere cartelle (non solo il contenuto): le app le
  /// ricreano al primo avvio. Percorsi assoluti obbligatori.
  static Future<bool> _cleanDirs(List<String> dirs) async {
    var ok = true;
    for (final p in dirs) {
      if (!p.startsWith('/') || p.length < 2) {
        ok = false;
        continue;
      }
      try {
        final r = await Process.run('bash', ['-c', 'rm -rf "$p" 2>&1'],
            runInShell: true);
        if (r.exitCode != 0) {
          try {
            final s = await _runSudo('rm -rf "$p"');
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

  // ── Cache del package manager ──────────────────────────────────

  /// .deb/.rpm/.pkg già scaricati + indici binari (apt: pkgcache.bin).
  static Future<int> getPackageManagerCacheBytes() async {
    var total = 0;
    if (await _hasApt()) total += await _dirSize('/var/cache/apt');
    if (await _commandExists('dnf')) total += await _dirSize('/var/cache/dnf');
    if (await _commandExists('pacman')) {
      total += await _dirSize('/var/cache/pacman/pkg');
    }
    return total;
  }

  static Future<String> _pmCacheSubtitle() async {
    final parts = <String>[];
    if (await _hasApt()) parts.add('apt-get clean');
    if (await _commandExists('dnf')) parts.add('dnf clean all');
    if (await _commandExists('pacman')) parts.add('pacman -Sc --noconfirm');
    return parts.isEmpty ? 'package cache' : parts.join(' / ');
  }

  static Future<bool> cleanPackageManagerCache() async {
    var tried = false;
    var ok = true;
    Future<void> run(String cmd) async {
      tried = true;
      try {
        final r = await _runSudo(cmd);
        if (r.exitCode != 0) ok = false;
      } catch (_) {
        ok = false;
      }
    }

    if (await _hasApt()) await run('apt-get clean');
    if (await _commandExists('dnf')) await run('dnf clean all');
    if (await _commandExists('pacman')) await run('pacman -Sc --noconfirm');
    return !tried || ok;
  }

  // ── Cache Electron/Chromium ────────────────────────────────────

  static const _electronCacheNames = [
    'Cache',
    'Code Cache',
    'GPUCache',
    'DawnGraphiteCache',
    'DawnWebGPUCache',
  ];

  /// Cartelle cache Electron/Chromium in ~/.config/{app}/ (rigenerabili:
  /// le app le ricreano al riavvio).
  static Future<List<String>> findElectronCacheDirs() async {
    final home = _home;
    final out = <String>[];
    if (home.isEmpty) return out;
    final config = Directory('$home/.config');
    try {
      if (!await config.exists()) return out;
      await for (final e in config.list(followLinks: false)) {
        if (e is! Directory) continue;
        for (final n in _electronCacheNames) {
          final d = Directory('${e.path}/$n');
          try {
            if (await d.exists()) out.add(d.path);
          } catch (_) {}
        }
      }
    } catch (_) {}
    return out;
  }

  // ── Dati OpenCode ──────────────────────────────────────────────

  /// Log e snapshot di OpenCode. Il database (opencode.db) NON viene
  /// mai toccato: è in uso continuo dall'app in esecuzione.
  static Future<List<String>> findOpencodeDataDirs() async {
    final home = _home;
    final out = <String>[];
    if (home.isEmpty) return out;
    final base = '$home/.local/share/opencode';
    for (final name in ['log', 'snapshot']) {
      final d = Directory('$base/$name');
      try {
        if (await d.exists()) out.add(d.path);
      } catch (_) {}
    }
    return out;
  }

  // ── CUDA: repository e installazioni duplicate ─────────────────

  static Future<List<String>> _globDirs(String parent, String prefix) async {
    final out = <String>[];
    try {
      final d = Directory(parent);
      if (!await d.exists()) return out;
      await for (final e in d.list(followLinks: false)) {
        if (e is! Directory) continue;
        if (e.path.split('/').last.startsWith(prefix)) out.add(e.path);
      }
    } catch (_) {}
    return out;
  }

  /// Repository installer CUDA locali (es. /var/cuda-repo-ubuntu2204-*):
  /// i .deb già scaricati, inutilizzati una volta installato il toolkit.
  static Future<List<String>> findCudaRepoDirs() async {
    final out = <String>[];
    out.addAll(await _globDirs('/var', 'cuda-repo'));
    out.addAll(await _globDirs('/var/lib', 'cuda-repo'));
    return out;
  }

  /// Radice CUDA attiva, in ordine: nvcc nel PATH → export hardcoded
  /// nelle shell rc (es. PATH=/usr/local/cuda-13.0/bin in .bashrc) →
  /// symlink /usr/local/cuda (alternatives). Vuoto se non determinabile.
  static Future<String> activeCudaRoot() async {
    try {
      final r = await Process.run('bash', [
        '-c',
        r'if command -v nvcc >/dev/null 2>&1; then '
        r'readlink -f "$(command -v nvcc)"; fi'
      ], runInShell: false);
      final p = _cudaRootFromNvcc(r.stdout.toString().trim());
      if (p.isNotEmpty) return p;
    } catch (_) {}
    // Ultimo file con un match vince: .bashrc per ultimo (shell interattiva).
    var fromRc = '';
    for (final f in [
      '.profile',
      '.bash_profile',
      '.zshrc',
      '.bash_login',
      '.bashrc',
    ]) {
      try {
        final file = File('$_home/$f');
        if (!await file.exists()) continue;
        final content = await file.readAsString();
        final matches =
            RegExp(r'/usr/local/cuda-\d+\.\d+').allMatches(content);
        if (matches.isNotEmpty) fromRc = matches.last.group(0)!;
      } catch (_) {}
    }
    if (fromRc.isNotEmpty &&
        await File('$fromRc/bin/nvcc').exists()) {
      return fromRc;
    }
    try {
      final r = await Process.run('bash', [
        '-c',
        'readlink -f /usr/local/cuda 2>/dev/null'
      ], runInShell: false);
      final p = _cudaRootFromNvcc(r.stdout.toString().trim());
      if (p.isNotEmpty) return p;
    } catch (_) {}
    return '';
  }

  static String _cudaRootFromNvcc(String path) {
    var p = path;
    if (p.endsWith('/bin/nvcc')) {
      p = p.substring(0, p.length - '/bin/nvcc'.length);
    }
    return p.startsWith('/usr/local/cuda-') ? p : '';
  }

  /// Installazioni CUDA duplicate in /usr/local (es. cuda-13.1 mentre
  /// la attiva è cuda-13.0): i symlink "cuda"/"cuda-13" non sono toccati.
  static Future<List<String>> findDuplicateCudaDirs() async {
    final active = await activeCudaRoot();
    if (active.isEmpty) return [];
    final out = <String>[];
    try {
      final local = Directory('/usr/local');
      if (!await local.exists()) return out;
      await for (final e in local.list(followLinks: false)) {
        if (e is! Directory) continue;
        final name = e.path.split('/').last;
        if (!RegExp(r'^cuda-\d+\.\d+$').hasMatch(name)) continue;
        if (e.path == active) continue;
        out.add(e.path);
      }
    } catch (_) {}
    return out;
  }

  /// Rimuove le directory CUDA duplicate e ricucisce il sistema attorno
  /// ad esse: alternatives ripuntate sulla radice attiva, file di
  /// ld.so.conf.d che le referenziavano eliminati, ldconfig eseguito.
  static Future<bool> removeDuplicateCudaInstalls() async {
    final active = await activeCudaRoot();
    if (active.isEmpty) return false;
    final dups = await findDuplicateCudaDirs();
    if (dups.isEmpty) return true;
    try {
      final r = await _runSudo(buildCudaCleanupCommand(active, dups));
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static String buildCudaCleanupCommand(String active, List<String> dups) {
    final b = StringBuffer('fail=0; ');
    for (final c in dups) {
      b.write('rm -rf "$c" || fail=1; ');
    }
    // ld.so.conf.d: elimina le entry che referenziavano le directory rimosse.
    b.write('for f in /etc/ld.so.conf.d/*.conf; do ');
    b.write('grep -q ');
    b.write(dups.map((c) => '-e "$c"').join(' '));
    b.write(r' "$f" 2>/dev/null && rm -f "$f"; done; ');
    // Alternatives: ripunta ogni gruppo che puntava nelle directory rimosse
    // sulla path corrispondente dentro la radice attiva, poi deregistra la
    // vecchia path. `--list` stampa solo path, niente etichette localizzate.
    // awk usa doppio apice con \$: il comando non contiene mai apici singoli
    // (devono passare intatti attraverso il quoting di _runSudo).
    b.write(
        r'for g in $(update-alternatives --get-selections 2>/dev/null | awk "{print \$1}"); do ');
    b.write(r'for v in $(update-alternatives --list "$g" 2>/dev/null); do ');
    b.write(r'case "$v" in ');
    for (final c in dups) {
      b.write('"$c"/*) ');
      b.write('nv="$active');
      b.write(r'${v#');
      b.write(c);
      b.write('}"; ');
      b.write(r'if [ -e "$nv" ]; then ');
      b.write(r'update-alternatives --set "$g" "$nv" >/dev/null 2>&1; ');
      b.write('fi; ');
      b.write(r'update-alternatives --remove "$g" "$v" >/dev/null 2>&1; ');
      b.write(';; ');
    }
    b.write('esac; done; done; ');
    b.write('ldconfig >/dev/null 2>&1 || true; ');
    b.write(r'[ "$fail" -eq 0 ]');
    return b.toString();
  }

  // ── Revisioni snap vecchie ─────────────────────────────────────

  static Future<String> _stdoutOf(String exe, List<String> args) async {
    try {
      final r = await Process.run(exe, args, runInShell: false);
      if (r.exitCode != 0) return '';
      return r.stdout.toString();
    } catch (_) {
      return '';
    }
  }

  /// Revisioni snap disabilitate dopo un aggiornamento, con file .snap
  /// ancora presenti su disco (spazio realmente recuperabile).
  static Future<List<SnapOldRevision>> getOldSnapRevisions() async {
    if (!await _commandExists('snap')) return [];
    final cur = await _stdoutOf('snap', ['list']);
    final all = await _stdoutOf('snap', ['list', '--all']);
    final old = filterOldSnapRevisions(cur, all);
    final out = <SnapOldRevision>[];
    for (final r in old) {
      final path = '/var/lib/snapd/snaps/${r.name}_${r.rev}.snap';
      if (await _fileSize(path) > 0) out.add(r);
    }
    return out;
  }

  /// Differenza `snap list --all` - `snap list` (intestazioni escluse:
  /// sono localizzate, quindi non vengono confrontate). Solo righe con
  /// nome snap e revisione validi, per sicurezza.
  static List<SnapOldRevision> filterOldSnapRevisions(
      String currentOutput, String allOutput) {
    if (currentOutput.trim().isEmpty || allOutput.trim().isEmpty) {
      return [];
    }
    final current = <String>{};
    var skipHeader = true;
    for (final line in currentOutput.split('\n')) {
      if (skipHeader) {
        skipHeader = false;
        continue;
      }
      final f = line.trim().split(RegExp(r'\s+'));
      if (f.length < 3) continue;
      current.add('${f[0]} ${f[2]}');
    }
    final out = <SnapOldRevision>[];
    final seen = <String>{};
    skipHeader = true;
    for (final line in allOutput.split('\n')) {
      if (skipHeader) {
        skipHeader = false;
        continue;
      }
      final f = line.trim().split(RegExp(r'\s+'));
      if (f.length < 3) continue;
      final name = f[0];
      final rev = f[2];
      if (!RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(name)) continue;
      if (!RegExp(r'^\d+$').hasMatch(rev)) continue;
      final key = '$name $rev';
      if (current.contains(key) || seen.contains(key)) continue;
      seen.add(key);
      out.add(SnapOldRevision(name: name, rev: rev));
    }
    return out;
  }

  static Future<int> getOldSnapRevisionsSize(
      List<SnapOldRevision> revs) async {
    var total = 0;
    for (final r in revs) {
      total +=
          await _fileSize('/var/lib/snapd/snaps/${r.name}_${r.rev}.snap');
    }
    return total;
  }

  static Future<bool> removeOldSnapRevisions(
      List<SnapOldRevision> revs) async {
    if (revs.isEmpty) return true;
    final parts = <String>[];
    for (final r in revs) {
      parts.add(
          'snap remove --revision=${r.rev} ${r.name} >/dev/null 2>&1 || fail=1');
    }
    final cmd =
        'fail=0; ${parts.join('; ')}; [ "\$fail" -eq 0 ]';
    try {
      final r = await _runSudo(cmd);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  // ── Flatpak: runtime non usati ─────────────────────────────────

  /// Scopre i runtime flatpak non usati con un dry-run di
  /// `flatpak uninstall --unused` per scope: la tabella operazioni viene
  /// stampata SOLO se ci sono ref inutilizzati e la risposta "n" annulla
  /// il tutto prima di rimuovere qualcosa. `LC_ALL=C` rende l'output
  /// indipendente dalla locale del sistema.
  static Future<FlatpakUnusedInfo?> getFlatpakUnused() async {
    if (!await _commandExists('flatpak')) return null;
    final wanted = <String>{}; // "id/branch/scope"
    var count = 0;
    for (final scope in ['user', 'system']) {
      try {
        final r = await Process.run('bash', [
          '-c',
          "printf 'n\\n' | LC_ALL=C flatpak uninstall --unused --$scope 2>&1"
        ], runInShell: false);
        final seen = <String>{};
        for (final row in parseFlatpakUnusedRows(r.stdout.toString())) {
          final key = '${row.name}/${row.branch}';
          if (!seen.add(key)) continue;
          count++;
          wanted.add('$key/$scope');
        }
      } catch (_) {}
    }
    if (count == 0) return null;
    final size = await _flatpakUnusedSize(wanted);
    if (size <= 0) return null;
    return FlatpakUnusedInfo(refCount: count, sizeBytes: size);
  }

  /// Righe della tabella operazioni del dry-run: campi separati da TAB
  /// con forma "N." / arch / id / branch / op ('r' = uninstall). Le
  /// righe della sezione "pinned" non hanno TAB e vengono ignorate.
  static List<FlatpakUnusedRef> parseFlatpakUnusedRows(String output) {
    final out = <FlatpakUnusedRef>[];
    for (final line in output.split('\n')) {
      final parts = line.split('\t');
      if (parts.length < 4) continue;
      if (parts.last.trim() != 'r') continue;
      final branch = parts[parts.length - 2].trim();
      final name = parts[parts.length - 3].trim();
      if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) continue;
      if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(branch)) continue;
      out.add(FlatpakUnusedRef(name: name, branch: branch));
    }
    return out;
  }

  static Future<int> _flatpakUnusedSize(Set<String> wanted) async {
    try {
      final r = await Process.run('bash', [
        '-c',
        'LC_ALL=C flatpak list --runtime '
        '--columns=ref,size,installation 2>&1'
      ], runInShell: false);
      if (r.exitCode != 0) return 0;
      var total = 0;
      for (final line in r.stdout.toString().split('\n')) {
        final f = line.split('\t');
        if (f.length < 3) continue;
        final seg = f[0].trim().split('/');
        if (seg.length < 3) continue;
        final key = '${seg.first}/${seg.last}/${f[2].trim()}';
        if (!wanted.contains(key)) continue;
        total += parseFlatpakSize(f[1]);
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Dimensione flatpak tollerante: "20.7 MB", "668.9\u00a0MB" (NBSP),
  /// separatore decimale virgola (locale italiana).
  static int parseFlatpakSize(String s) {
    final m = RegExp(r'(\d+(?:[.,]\d+)?)\s*[^\t\n]*?([KMGT]?B)',
            caseSensitive: false)
        .firstMatch(s);
    if (m == null) return 0;
    final v = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
    return _sizeToBytes(v, m.group(2)!.toUpperCase());
  }

  /// Rimuove i runtime flatpak inutilizzati in entrambi gli scope
  /// (system richiede sudo).
  static Future<bool> cleanFlatpakUnused() async {
    if (!await _commandExists('flatpak')) return false;
    var ok = true;
    try {
      final u = await Process.run(
          'flatpak', ['uninstall', '--unused', '--user', '-y'],
          runInShell: false);
      if (u.exitCode != 0) ok = false;
    } catch (_) {
      ok = false;
    }
    try {
      final s = await _runSudo('flatpak uninstall --unused --system -y');
      if (s.exitCode != 0) ok = false;
    } catch (_) {
      ok = false;
    }
    return ok;
  }

  static String _shortPath(String p) {
    final home = _home;
    if (home.isNotEmpty && p.startsWith('$home/')) {
      return '~${p.substring(home.length)}';
    }
    return p;
  }

  static Future<int> _fileSize(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) return await f.length();
    } catch (_) {}
    return 0;
  }
}
