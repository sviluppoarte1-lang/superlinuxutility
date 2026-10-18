import 'dart:convert';
import 'dart:io';

import '../models/installed_app.dart';
import 'password_storage.dart';

/// Esito di una operazione di rimozione di un'app.
class RemovalResult {
  /// true se l'app è stata effettivamente rimossa (verificato).
  final bool success;

  /// Dettaglio dell'errore (coda di stderr, in inglese tecnico).
  final String? message;

  /// Codice di errore strutturato: 'no-password' | 'timeout' |
  /// 'invalid-name' | 'no-desktop-file' | null.
  final String? code;

  const RemovalResult._(this.success, this.message, this.code);

  const RemovalResult.ok() : this._(true, null, null);

  const RemovalResult.fail({String? message, String? code})
      : this._(false, message, code);
}

/// Entrata .desktop parsata (per le app "GNOME").
class DesktopEntry {
  final String name;
  final String? comment;

  const DesktopEntry({required this.name, this.comment});
}

/// Risultato grezzo di un processo bash.
class _Cmd {
  final int exitCode;
  final String out;
  final String err;
  final bool timedOut;

  const _Cmd(this.exitCode, this.out, this.err, this.timedOut);
}

class AppManager {
  // ===========================================================================
  // Utility
  // ===========================================================================

  static const Duration _removeTimeout = Duration(seconds: 180);
  static const Duration _verifyTimeout = Duration(seconds: 20);

  /// Wrapping di una stringa in una shell (apici singoli escape-ati).
  static String shq(String value) => "'${value.replaceAll("'", r"'\''")}'";

  static String _escapePassword(String password) => password
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\$', '\\\$')
      .replaceAll('`', '\\`');

  /// Esegue un comando via bash. Con [sudo] antepone pipe della password
  /// salvata + `sudo -S` (come in altri service dell'app).
  static Future<_Cmd> _run(
    String command, {
    bool sudo = false,
    Duration timeout = _removeTimeout,
  }) async {
    var full = command;
    if (sudo) {
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        return const _Cmd(-2, '', 'NO_PASSWORD', false);
      }
      full =
          'printf "%s\\n" "${_escapePassword(password)}" | sudo -S $command';
    }
    try {
      final proc = await Process.start('bash', ['-c', full]);
      proc.stdin.close();
      // allowMalformed: UN solo byte non-UTF-8 nell'output (es. %{SUMMARY} di
      // un singolo pacchetto rpm) faceva fallire l'intero decoder → catch →
      // exit -1 → l'intera lista dnf veniva buttata ("app dnf non calcolate").
      const tolerant = Utf8Decoder(allowMalformed: true);
      final outFuture = proc.stdout.transform(tolerant).join();
      final errFuture = proc.stderr.transform(tolerant).join();
      var timedOut = false;
      final exitCode = await proc.exitCode.timeout(timeout, onTimeout: () {
        timedOut = true;
        proc.kill(ProcessSignal.sigkill);
        return -9;
      });
      final out = await outFuture.timeout(const Duration(seconds: 5),
          onTimeout: () => '');
      final err = await errFuture.timeout(const Duration(seconds: 5),
          onTimeout: () => '');
      return _Cmd(exitCode, out, err, timedOut);
    } catch (e) {
      return _Cmd(-1, '', e.toString(), false);
    }
  }

  /// Ultime righe utili di un output di errore (per la SnackBar).
  static String? errorTail(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l != 'Password:')
        .toList();
    if (lines.isEmpty) return null;
    final tail = lines.length > 4 ? lines.sublist(lines.length - 4) : lines;
    var joined = tail.join(' — ');
    if (joined.length > 300) {
      joined = '…${joined.substring(joined.length - 300)}';
    }
    return joined;
  }

  static RemovalResult _failureFrom(_Cmd cmd, {Duration? timeout}) {
    if (cmd.err.trim() == 'NO_PASSWORD') {
      return const RemovalResult.fail(code: 'no-password');
    }
    if (cmd.timedOut) {
      final secs = timeout?.inSeconds;
      return RemovalResult.fail(
        message: secs != null ? 'timeout after ${secs}s' : 'timeout',
        code: 'timeout',
      );
    }
    final tail = errorTail(cmd.err.isNotEmpty ? cmd.err : cmd.out);
    return RemovalResult.fail(message: tail ?? 'exit code ${cmd.exitCode}');
  }

  /// Pattern unico per tutti i package manager: esegue la rimozione, poi
  /// VERIFICA che il bersaglio sia davvero sparito (success guidato dalla
  /// verifica, non dal solo exit code).
  static Future<RemovalResult> _execRemoval(
    String command, {
    required bool sudo,
    required Future<bool> Function() stillPresent,
    required String stillPresentMessage,
    Duration timeout = _removeTimeout,
  }) async {
    final cmd = await _run(command, sudo: sudo, timeout: timeout);
    if (cmd.err.trim() == 'NO_PASSWORD') {
      return const RemovalResult.fail(code: 'no-password');
    }
    if (cmd.timedOut || cmd.exitCode == -1 || cmd.exitCode == 127) {
      return _failureFrom(cmd, timeout: timeout);
    }
    if (!await stillPresent()) return const RemovalResult.ok();
    if (cmd.exitCode != 0) return _failureFrom(cmd, timeout: timeout);
    return RemovalResult.fail(message: stillPresentMessage);
  }

  static bool _isLockError(String err) =>
      err.contains('lock') || err.contains('Locking process');

  // ===========================================================================
  // Validazione nomi (anti-injection: i nomi arrivano da output di sistema
  // ma non vanno mai inseriti grezzi in una shell senza verifica)
  // ===========================================================================

  static final RegExp _aptNameRe = RegExp(r'^[a-z0-9][a-z0-9+.:-]*$');
  static final RegExp _aptArchRe = RegExp(r'^[a-z0-9]+$');
  static final RegExp _snapNameRe = RegExp(r'^[a-z0-9][a-z0-9-]*$');
  static final RegExp _flatpakIdRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
  static final RegExp _rpmNameRe = RegExp(r'^[A-Za-z0-9][A-Za-z0-9+._@-]*$');

  static bool isValidAptName(String name) {
    if (!_aptNameRe.hasMatch(name)) return false;
    final parts = name.split(':');
    if (parts.length > 2) return false;
    if (parts.length == 2 && !_aptArchRe.hasMatch(parts[1])) return false;
    return true;
  }

  static bool isValidSnapName(String name) => _snapNameRe.hasMatch(name);

  static bool isValidFlatpakId(String id) => _flatpakIdRe.hasMatch(id);

  static bool isValidRpmName(String name) => _rpmNameRe.hasMatch(name);

  // ===========================================================================
  // Costruttori di comandi (publici: testabili)
  // ===========================================================================

  /// apt-get remove non-interactive: niente prompt dpkg su confile modificate
  /// (EOF su stdin => fallimento silenzioso), niente debconf/needrestart.
  static String buildAptRemoveCommand(String package) =>
      'env LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get remove -y '
      '-o Dpkg::Options::=--force-confold $package';

  static String buildAptStatusCommand(String package) =>
      r"dpkg-query -W -f '${db:Status-Status}' -- " + shq(package);

  static String buildSnapRemoveCommand(String snap) =>
      'env LC_ALL=C snap remove ${shq(snap)}';

  static String buildSnapListCommand(String snap) =>
      'env LC_ALL=C snap list ${shq(snap)}';

  static String buildFlatpakUninstallCommand(String id, {String? scope}) {
    final flag = switch (scope) {
      'user' => ' --user',
      'system' => ' --system',
      _ => '',
    };
    return 'env LC_ALL=C flatpak uninstall -y$flag ${shq(id)}';
  }

  static String buildFlatpakInfoCommand(String id, {String? scope}) {
    final flag = switch (scope) {
      'user' => '--user ',
      'system' => '--system ',
      _ => '',
    };
    return 'flatpak info $flag${shq(id)}';
  }

  static String buildPacmanRemoveCommand(String package) =>
      'env LC_ALL=C pacman -R --noconfirm ${shq(package)}';

  static String buildPacmanQueryCommand(String package) =>
      'pacman -Q ${shq(package)}';

  /// Nessun autoremove: come apt-get remove, rimuove SOLO il pacchetto.
  static String buildDnfRemoveCommand(String package) =>
      'export LC_ALL=C; '
      'if command -v dnf >/dev/null 2>&1; then dnf remove -y ${shq(package)}; '
      'elif command -v yum >/dev/null 2>&1; then yum remove -y ${shq(package)}; '
      'else echo "dnf/yum not found" >&2; exit 127; fi';

  static String buildRpmQueryCommand(String package) =>
      'rpm -q ${shq(package)}';

  // ===========================================================================
  // Verifiche "è ancora installato?"
  // ===========================================================================

  /// dpkg: dopo una remove senza purge lo stato diventa 'config-files'
  /// (solo residui di configurazione) => l'app è rimossa.
  static Future<bool> _aptStillInstalled(String package) async {
    final cmd = await _run(buildAptStatusCommand(package),
        timeout: _verifyTimeout);
    if (cmd.exitCode != 0) return false; // dpkg non lo conosce più
    final status = cmd.out.trim();
    return status.isNotEmpty &&
        status != 'config-files' &&
        status != 'not-installed';
  }

  static Future<bool> _snapStillInstalled(String snap) async {
    final cmd =
        await _run(buildSnapListCommand(snap), timeout: _verifyTimeout);
    return cmd.exitCode == 0;
  }

  static Future<bool> _flatpakStillInstalled(String id, {String? scope}) async {
    final cmd = await _run(buildFlatpakInfoCommand(id, scope: scope),
        timeout: _verifyTimeout, sudo: scope == 'system');
    if (cmd.err.trim() == 'NO_PASSWORD') return true; // non verificabile
    return cmd.exitCode == 0;
  }

  static Future<bool> _pacmanStillInstalled(String package) async {
    final cmd =
        await _run(buildPacmanQueryCommand(package), timeout: _verifyTimeout);
    return cmd.exitCode == 0;
  }

  static Future<bool> _rpmStillInstalled(String package) async {
    final cmd =
        await _run(buildRpmQueryCommand(package), timeout: _verifyTimeout);
    return cmd.exitCode == 0;
  }

  // ===========================================================================
  // Elenco app installate
  // ===========================================================================

  /// Ottiene le app installate via APT.
  /// Formato: Package \t Version \t Installed-Size \t Status \t Description
  /// (la Description di dpkg è lunga e multilinea: le righe di continuazione
  /// iniziano con spazio e vengono scartate nel parsing).
  static Future<List<InstalledApp>> getAptApps() async {
    try {
      final result = await Process.run('dpkg-query', [
        '-W',
        '-f=\${Package}\\t\${Version}\\t\${Installed-Size}\\t'
            '\${db:Status-Status}\\t\${Description}\\n',
      ]).timeout(const Duration(seconds: 30));

      if (result.exitCode != 0) {
        // Fallback: apt list --installed (attenzione: il redirect 2>/dev/null
        // come ARGOMENTO non funziona con Process.run, serve il solo stdout).
        final aptResult = await Process.run('apt', ['list', '--installed'])
            .timeout(const Duration(seconds: 30));
        if (aptResult.exitCode != 0) return [];
        return parseAptListOutput(aptResult.stdout as String);
      }

      return parseAptQueryOutput(result.stdout as String);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di dpkg-query (formato tab, stato incluso).
  static List<InstalledApp> parseAptQueryOutput(String output) {
    final apps = <InstalledApp>[];
    final seen = <String>{};

    for (final rawLine in output.split('\n')) {
      // Le descrizioni lunghe continuano su righe che iniziano con spazio:
      // scartate, così una riga "foo;bar;baz" dentro una descrizione non
      // genera un'app fantasma che apt non saprebbe mai rimuovere.
      if (rawLine.isEmpty || rawLine.startsWith(' ')) continue;

      final parts = rawLine.split('\t');
      if (parts.length < 4) continue;

      final name = parts[0].trim();
      final version = parts[1].trim();
      final sizeKb = int.tryParse(parts[2].trim());
      final status = parts[3].trim();
      final description = parts.length > 4 ? parts[4].trim() : '';

      if (name.isEmpty || version.isEmpty) continue;
      // Pacchetti già rimossi con residui di configurazione: non mostrarli
      // (rimuoverli di nuovo è un no-op che l'utente scambierebbe per errore).
      if (status == 'config-files' || status == 'not-installed') continue;
      // Dedup multiarch (stesso nome per architetture diverse).
      if (!seen.add(name)) continue;

      apps.add(InstalledApp(
        name: name,
        version: version,
        description: description.isEmpty ? null : description,
        packageManager: PackageManager.apt,
        size: sizeKb != null ? sizeKb * 1024 : null,
        isSystemPackage: isSystemPackage(name),
      ));
    }

    return apps;
  }

  /// Parsing dell'output di `apt list --installed` (fallback).
  /// Formato: 7zip/noble,now 23.01+dfsg-11 amd64 [installed,automatic]
  static List<InstalledApp> parseAptListOutput(String output) {
    final apps = <InstalledApp>[];
    final seen = <String>{};

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('Listing')) continue;

      final match =
          RegExp(r'^([^/]+)/\S+\s+(\S+)\s+\S+\s+\[').firstMatch(trimmed);
      if (match == null) continue;

      final name = match.group(1)!;
      final version = match.group(2)!;
      if (!seen.add(name)) continue;

      apps.add(InstalledApp(
        name: name,
        version: version,
        packageManager: PackageManager.apt,
        isSystemPackage: isSystemPackage(name),
      ));
    }

    return apps;
  }

  /// Ottiene le app installate via Snap.
  static Future<List<InstalledApp>> getSnapApps() async {
    try {
      final r = await _run('env LC_ALL=C snap list',
          timeout: const Duration(seconds: 30));
      if (r.exitCode != 0) return [];
      return parseSnapListOutput(r.out);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di snap list.
  /// Colonne: Name Version Rev Tracking Publisher Notes.
  /// La prima riga è l'header, ma il suo testo è localizzato anche con
  /// LC_ALL=C: viene saltata ciecamente.
  static List<InstalledApp> parseSnapListOutput(String output) {
    final apps = <InstalledApp>[];
    final lines = output.split('\n');

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 2) continue;

      final name = parts[0];
      final version = parts[1];
      final notes =
          parts.length > 5 ? parts.sublist(5).join(' ').trim() : '';

      apps.add(InstalledApp(
        name: name,
        version: version,
        description: (notes.isEmpty || notes == '-') ? null : notes,
        packageManager: PackageManager.snap,
        isSystemPackage: isSnapBase(name),
      ));
    }

    return apps;
  }

  /// Ottiene le app installate via Flatpak.
  /// Colonne esplicita + separatore TAB: il nome display può contenere spazi
  /// ("Super Productivity") e con lo split su whitespace l'id veniva rovinato.
  static Future<List<InstalledApp>> getFlatpakApps() async {
    try {
      final r = await _run(
        'env LC_ALL=C flatpak list --app '
        '--columns=name,application,version,branch,installation',
        timeout: const Duration(seconds: 30),
      );
      if (r.exitCode != 0) return [];
      return parseFlatpakListOutput(r.out);
    } catch (e) {
      return [];
    }
  }

  /// Unisce le portate di installazione flatpak ('user'/'system') di una
  /// stessa app: se presenti in entrambe → 'both'.
  static String? mergeFlatpakScope(String? a, String? b) {
    if (a == null || a.isEmpty) return (b == null || b.isEmpty) ? null : b;
    if (b == null || b.isEmpty) return a;
    return a == b ? a : 'both';
  }

  /// Parsing dell'output di flatpak list (TAB-separated).
  static List<InstalledApp> parseFlatpakListOutput(String output) {
    final apps = <InstalledApp>[];
    final indexById = <String, int>{};

    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;

      final parts = line.split('\t');
      if (parts.length < 2) continue;

      final name = parts[0].trim();
      final id = parts[1].trim();
      if (!isValidFlatpakId(id)) continue;

      final version = parts.length > 2 ? parts[2].trim() : '';
      final installation = parts.length > 4 ? parts[4].trim() : '';

      final existingIndex = indexById[id];
      if (existingIndex != null) {
        // Stessa app in due installazioni → merged 'both'.
        final prev = apps[existingIndex];
        apps[existingIndex] = InstalledApp(
          name: prev.name,
          version: prev.version,
          description: prev.description,
          packageManager: PackageManager.flatpak,
          size: prev.size,
          isSystemPackage: false,
          desktopFile: prev.desktopFile,
          installation: mergeFlatpakScope(prev.installation, installation),
        );
        continue;
      }

      indexById[id] = apps.length;
      apps.add(InstalledApp(
        name: name.isEmpty ? id : name,
        version: version.isEmpty ? null : version,
        description: id,
        packageManager: PackageManager.flatpak,
        installation: installation.isEmpty ? null : installation,
      ));
    }

    return apps;
  }

  /// App "GNOME": file .desktop in /usr/share/applications,
  /// /usr/local/share/applications e ~/.local/share/applications.
  /// Quelli posseduti da un pacchetto dpkg vengono saltati: sono già
  /// nell'elenco APT (prima venivano mostrati due volte e la rimozione
  /// falliva perché il percorso .desktop veniva indovinato dal display name).
  static Future<List<InstalledApp>> getGnomeApps() async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final paths = <String>[
        '/usr/share/applications',
        '/usr/local/share/applications',
        if (homeDir.isNotEmpty) '$homeDir/.local/share/applications',
      ];

      // Raccolta file esistenti (una sola passata di listing).
      final filesByDir = <String, List<String>>{};
      final allFiles = <String>[];
      for (final path in paths) {
        final dir = Directory(path);
        if (!await dir.exists()) continue;
        final files = <String>[];
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File && entity.path.endsWith('.desktop')) {
            files.add(entity.path);
            allFiles.add(entity.path);
          }
        }
        filesByDir[path] = files;
      }
      if (allFiles.isEmpty) return [];

      final owned = await _packageOwnedDesktopFiles(allFiles);

      // Basename → app: se lo stesso .desktop esiste in più cartelle vince
      // l'override utente (~/.local/share/application).
      final candidates = <String, InstalledApp>{};
      for (final path in paths) {
        for (final filePath in filesByDir[path] ?? const <String>[]) {
          if (owned.contains(filePath)) continue;
          try {
            final entry = parseDesktopEntry(await File(filePath).readAsString());
            final basename = filePath.split('/').last;
            if (entry == null) {
              // Entry nascosta (Hidden/NoDisplay): un override utente
              // nasconde anche la voce di sistema corrispondente.
              candidates.remove(basename);
              continue;
            }
            candidates[basename] = InstalledApp(
              name: entry.name,
              description: entry.comment,
              packageManager: PackageManager.gnome,
              isSystemPackage: path.startsWith('/usr'),
              desktopFile: filePath,
            );
          } catch (e) {
            // File non leggibile: ignorato.
          }
        }
      }

      final apps = candidates.values.toList()
        ..sort((a, b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return apps;
    } catch (e) {
      return [];
    }
  }

  /// Interroga dpkg sui percorsi .desktop (a blocchi per non superare
  /// l'arg max). Se dpkg non esiste (Fedora/Arch) → nessun filtro.
  static Future<Set<String>> _packageOwnedDesktopFiles(
      List<String> filePaths) async {
    final owned = <String>{};
    // 1) Debian/Ubuntu: dpkg -S in batch (mapping path→pacchetto diretto).
    try {
      for (var i = 0; i < filePaths.length; i += 400) {
        final chunk = filePaths.skip(i).take(400);
        final r = await Process.run('dpkg', ['-S', ...chunk])
            .timeout(const Duration(seconds: 15));
        owned.addAll(parseDpkgOwnedPaths(r.stdout as String));
      }
      return owned;
    } catch (e) {
      // dpkg assente (Fedora/RHEL/Arch): passa a rpm/pacman sotto.
    }

    // 2) rpm (Fedora/RHEL) o pacman (Arch): una query per file con concorrenza
    //    limitata — su più file l'output non garantisce il mapping
    //    path→pacchetto. Solo i file sotto /usr/share/applications: quelli in
    //    /usr/local e ~/.local non sono mai posseduti da un pacchetto.
    //    Senza questo filtro su Fedora TUTTI i .desktop finivano sotto
    //    "GNOME", in duplicati con l'elenco dnf/pacman.
    late final String tool;
    late final List<String> toolArgs;
    if (await _hasCommand('rpm')) {
      tool = 'rpm';
      toolArgs = ['-qf'];
    } else if (await _hasCommand('pacman')) {
      tool = 'pacman';
      toolArgs = ['-Qqo'];
    } else {
      return owned;
    }

    final systemFiles = filePaths
        .where((p) => p.startsWith('/usr/share/applications'))
        .toList();
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= systemFiles.length) return;
        try {
          final r = await Process.run(tool, [...toolArgs, systemFiles[i]])
              .timeout(const Duration(seconds: 5));
          final out = (r.stdout as String).trim();
          if (r.exitCode == 0 && out.isNotEmpty && !out.contains('not owned')) {
            owned.add(systemFiles[i]);
          }
        } catch (e) {
          // Query fallita: il file resta nel listato gnome (come in passato).
        }
      }
    }

    await Future.wait([for (var i = 0; i < 8; i++) worker()]);
    return owned;
  }

  /// True se il comando esiste nel PATH (`command -v`).
  static Future<bool> _hasCommand(String cmd) async {
    try {
      final r = await Process.run('sh', ['-c', 'command -v "$cmd"']);
      return r.exitCode == 0 && (r.stdout as String).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Parsing di `dpkg -S`: "pkg: /percorso" (con varianti pkg:arch).
  static Set<String> parseDpkgOwnedPaths(String output) {
    final owned = <String>{};
    for (final line in output.split('\n')) {
      final idx = line.indexOf(': ');
      if (idx <= 0) continue;
      final path = line.substring(idx + 2).trim();
      if (path.startsWith('/')) owned.add(path);
    }
    return owned;
  }

  /// Parsing di un file .desktop. Ritorna null se l'entry è nascosta
  /// (NoDisplay/Hidden), non è un'applicazione o non ha Name.
  static DesktopEntry? parseDesktopEntry(String content) {
    String? name;
    String? comment;
    var hidden = false;
    var typeOk = true;

    for (final line in content.split('\n')) {
      if (line.startsWith('Name=')) {
        name ??= line.substring(5).trim();
      } else if (line.startsWith('Comment=')) {
        comment ??= line.substring(8).trim();
      } else if (line.startsWith('NoDisplay=true') ||
          line.startsWith('Hidden=true')) {
        hidden = true;
      } else if (line.startsWith('Type=')) {
        typeOk = line.substring(5).trim() == 'Application';
      }
    }

    if (hidden || !typeOk || name == null || name.isEmpty) return null;
    return DesktopEntry(name: name, comment: comment);
  }

  /// Ottiene i pacchetti installati via DNF/YUM (rpm).
  static Future<List<InstalledApp>> getDnfApps() async {
    try {
      // LC_ALL=C per output stabile. TAB/newline sono letterali nel formato.
      var r = await _run(
        "env LC_ALL=C rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'",
        timeout: const Duration(seconds: 60),
      );
      if (r.exitCode == 0) {
        final apps = parseDnfListOutput(r.out);
        if (apps.isNotEmpty) return apps;
      }
      // Fallback senza %{SUMMARY} (campo testuale: può contenere byte non
      // UTF-8 o caratteri anomali): nome+versione bastano per contare e
      // mostrare i pacchetti installati con dnf.
      r = await _run(
        "env LC_ALL=C rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\n'",
        timeout: const Duration(seconds: 60),
      );
      if (r.exitCode != 0) return [];
      return parseDnfListOutput(r.out);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di `rpm -qa --qf` (TAB-separated, non ordinato).
  static List<InstalledApp> parseDnfListOutput(String output) {
    final apps = <InstalledApp>[];
    final seen = <String>{};

    for (final line in output.split('\n')) {
      final parts = line.split('\t');
      if (parts.length < 2) continue;

      final name = parts[0].trim();
      final version = parts[1].trim();
      if (name.isEmpty || !seen.add(name)) continue;

      final summary = parts.length > 2 ? parts[2].trim() : '';
      apps.add(InstalledApp(
        name: name,
        version: version.isEmpty ? null : version,
        description: summary.isEmpty ? null : summary,
        packageManager: PackageManager.dnf,
        isSystemPackage: isSystemPackage(name),
      ));
    }

    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  /// Ottiene i pacchetti installati via Pacman (Arch).
  static Future<List<InstalledApp>> getPacmanApps() async {
    try {
      final r = await _run('env LC_ALL=C pacman -Qi',
          timeout: const Duration(seconds: 60));
      if (r.exitCode != 0) return [];
      return parsePacmanListOutput(r.out);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di `pacman -Qi` (blocchi separati da riga vuota,
  /// campi "Etichetta   : valore"; con LC_ALL=C le etichette sono inglesi).
  static List<InstalledApp> parsePacmanListOutput(String output) {
    final apps = <InstalledApp>[];
    final seen = <String>{};
    String? name;
    String? version;
    String? description;

    void flush() {
      if (name != null && name!.isNotEmpty && seen.add(name!)) {
        apps.add(InstalledApp(
          name: name!,
          version: version,
          description: description,
          packageManager: PackageManager.pacman,
          isSystemPackage: isSystemPackage(name!),
        ));
      }
      name = null;
      version = null;
      description = null;
    }

    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) {
        flush();
        continue;
      }
      final idx = line.indexOf(':');
      if (idx <= 0) continue;
      final key = line.substring(0, idx).trim();
      final value = line.substring(idx + 1).trim();
      switch (key) {
        case 'Name':
          name = value;
          break;
        case 'Version':
          version = value;
          break;
        case 'Description':
          description = value.isEmpty ? null : value;
          break;
      }
    }
    flush();

    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  // ===========================================================================
  // Classifiche
  // ===========================================================================

  static const List<String> _systemSubstrings = [
    'linux-',
    'libc',
    'libstdc',
    'libgcc',
    'systemd',
    'dbus',
    'udev',
    'core',
    'snapd',
    'ubuntu-',
    'gnome-',
    'gdm',
    'network-manager',
    'networkd',
    'pulseaudio',
    'alsa',
    'xorg',
    'mesa',
    'nvidia',
    'firmware',
  ];

  static const Set<String> _systemExact = {
    'linux',
    'kernel',
    'kernel-core',
    'glibc',
    'gcc-libs',
    'bash',
    'coreutils',
    'filesystem',
  };

  /// Verifica se un pacchetto è di sistema (solo avviso, non blocca).
  static bool isSystemPackage(String name) {
    final lower = name.toLowerCase();
    if (_systemExact.contains(lower)) return true;
    return _systemSubstrings.any(lower.contains);
  }

  /// Base/runtime snap (core22, bare, gnome-46-2404, ...): non app avviabili.
  static final RegExp _snapBaseRe = RegExp(
      r'^(bare(-runtime)?|core\d*|snapd|gnome-\d[\d.]*(-[\w-]+)?|'
      r'gtk-common-themes|kf\d-core\d+|mesa-[\d-]+|nvidia-\d+.*|cuda-[\d.].*)$');

  static bool isSnapBase(String name) => _snapBaseRe.hasMatch(name);

  // ===========================================================================
  // Dipendenze (APT)
  // ===========================================================================

  /// Controlla le dipendenze per un pacchetto APT (chiamato solo quando
  /// necessario, prima della rimozione).
  static Future<void> _checkAptDependencies(InstalledApp app) async {
    try {
      // LC_ALL=C: apt-cache localizza "Reverse Depends:"/"Depends:".
      final depsResult = await _run(
          'env LC_ALL=C apt-cache depends ${shq(app.name)}',
          timeout: _verifyTimeout);
      if (depsResult.exitCode == 0) {
        final deps = <String>{};
        for (final line in depsResult.out.split('\n')) {
          final trimmed = line.trim();
          if (trimmed.startsWith('Depends:')) {
            var dep = trimmed.replaceFirst('Depends:', '').trim();
            dep = dep.split(' ').first.replaceAll('<', '').replaceAll('>', '');
            if (dep.isNotEmpty) deps.add(dep);
          }
        }
        app.dependencies.addAll(deps);
      }

      final revDepsResult = await _run(
          'env LC_ALL=C apt-cache rdepends --installed ${shq(app.name)}',
          timeout: _verifyTimeout);
      if (revDepsResult.exitCode == 0) {
        app.reverseDependencies.addAll(
            parseAptRdepends(revDepsResult.out, app.name));
      }
    } catch (e) {
      // Ignora errori
    }
  }

  /// Parsing di `apt-cache rdepends --installed` (con LC_ALL=C):
  /// ritorna i dipendenti deduplicati, fermandosi prima della sezione
  /// "Reverse Provides:" (che non contiene dipendenti reali).
  static List<String> parseAptRdepends(String output, String selfName) {
    final revDeps = <String>{};
    var inReverseDepends = false;

    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed == 'Reverse Depends:' || trimmed == 'Reverse Depends') {
        inReverseDepends = true;
        continue;
      }
      if (trimmed == 'Reverse Provides:' || trimmed == 'Reverse Provides') {
        break;
      }
      if (!inReverseDepends || trimmed.isEmpty) continue;
      final pkg = trimmed.split(' ').first.split('(').first.trim();
      if (pkg.isNotEmpty && pkg != selfName) revDeps.add(pkg);
    }

    return revDeps.toList();
  }

  /// Controlla le dipendenze per un'app specifica (chiamato solo quando necessario).
  static Future<InstalledApp> checkAppDependencies(InstalledApp app) async {
    if (app.packageManager == PackageManager.apt) {
      await _checkAptDependencies(app);
    }
    return app;
  }

  // ===========================================================================
  // Rimozione
  // ===========================================================================

  /// Rimuove un'app installata. Il successo è verificato ri-interrogando il
  /// package manager (alcuni comandi escono con rc=0 anche a fronte di errori).
  static Future<RemovalResult> removeApp(InstalledApp app) async {
    try {
      switch (app.packageManager) {
        case PackageManager.apt:
          return await _removeApt(app.name);
        case PackageManager.snap:
          return await _removeSnap(app.name);
        case PackageManager.flatpak:
          return await _removeFlatpak(app);
        case PackageManager.gnome:
          return await _removeDesktopFile(app);
        case PackageManager.pacman:
          return await _removePacman(app.name);
        case PackageManager.dnf:
          return await _removeDnf(app.name);
      }
    } catch (e) {
      return RemovalResult.fail(message: e.toString());
    }
  }

  static Future<RemovalResult> _removeApt(String package) async {
    if (!isValidAptName(package)) {
      return RemovalResult.fail(
          message: 'invalid package name: $package', code: 'invalid-name');
    }

    final command = buildAptRemoveCommand(package);
    var cmd = await _run(command, sudo: true, timeout: _removeTimeout);
    // In caso di lock dpkg (unattended-upgrades, Update Manager...) riprova.
    var lockAttempts = 0;
    while (cmd.exitCode != 0 &&
        lockAttempts < 3 &&
        _isLockError(cmd.err)) {
      lockAttempts++;
      await Future.delayed(const Duration(milliseconds: 2500));
      cmd = await _run(command, sudo: true, timeout: _removeTimeout);
    }

    if (cmd.err.trim() == 'NO_PASSWORD') {
      return const RemovalResult.fail(code: 'no-password');
    }
    if (cmd.timedOut || cmd.exitCode == -1 || cmd.exitCode == 127) {
      return _failureFrom(cmd, timeout: _removeTimeout);
    }
    if (!await _aptStillInstalled(package)) return const RemovalResult.ok();
    if (cmd.exitCode != 0) return _failureFrom(cmd, timeout: _removeTimeout);
    return const RemovalResult.fail(
        message: 'package still installed after removal');
  }

  static Future<RemovalResult> _removeSnap(String snap) async {
    if (!isValidSnapName(snap)) {
      return RemovalResult.fail(
          message: 'invalid snap name: $snap', code: 'invalid-name');
    }
    return _execRemoval(
      buildSnapRemoveCommand(snap),
      sudo: true,
      stillPresent: () => _snapStillInstalled(snap),
      stillPresentMessage: 'snap still installed after removal',
    );
  }

  static Future<RemovalResult> _removeFlatpak(InstalledApp app) async {
    final id = (app.description?.isNotEmpty ?? false)
        ? app.description!
        : app.name;
    if (!isValidFlatpakId(id)) {
      return RemovalResult.fail(
          message: 'invalid flatpak id: $id', code: 'invalid-name');
    }
    final scope = app.installation;

    if (scope == 'both') {
      // Servono entrambe le portate: la parte system richiede sudo, quindi
      // la password va verificata PRIMA di rimuovere la parte user.
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        return const RemovalResult.fail(code: 'no-password');
      }

      final userCmd = await _run(buildFlatpakUninstallCommand(id, scope: 'user'),
          timeout: _removeTimeout);
      if (await _flatpakStillInstalled(id, scope: 'user')) {
        final tail = errorTail(userCmd.err);
        return RemovalResult.fail(
            message: tail ?? 'user installation still present');
      }

      final sysCmd = await _run(
          buildFlatpakUninstallCommand(id, scope: 'system'),
          sudo: true,
          timeout: _removeTimeout);
      if (await _flatpakStillInstalled(id, scope: 'system')) {
        if (sysCmd.err.trim() == 'NO_PASSWORD') {
          return const RemovalResult.fail(code: 'no-password');
        }
        if (sysCmd.exitCode != 0) return _failureFrom(sysCmd);
        return const RemovalResult.fail(
            message: 'system installation still present');
      }
      return const RemovalResult.ok();
    }

    return _execRemoval(
      buildFlatpakUninstallCommand(id, scope: scope),
      sudo: scope == 'system',
      stillPresent: () => _flatpakStillInstalled(id, scope: scope),
      stillPresentMessage: 'flatpak still installed after removal',
    );
  }

  static Future<RemovalResult> _removeDesktopFile(InstalledApp app) async {
    final path = app.desktopFile;
    if (path == null || path.isEmpty) {
      return const RemovalResult.fail(
          message: 'desktop file path not available', code: 'no-desktop-file');
    }

    final file = File(path);
    if (await file.exists()) {
      if (path.startsWith('/usr')) {
        final cmd = await _run('rm -f -- ${shq(path)}',
            sudo: true, timeout: const Duration(seconds: 30));
        if (cmd.err.trim() == 'NO_PASSWORD') {
          return const RemovalResult.fail(code: 'no-password');
        }
        if (cmd.exitCode != 0 && await file.exists()) {
          return _failureFrom(cmd);
        }
      } else {
        try {
          await file.delete();
        } catch (e) {
          return RemovalResult.fail(message: e.toString());
        }
      }
    }

    if (await file.exists()) {
      return const RemovalResult.fail(
          message: 'file still present after removal');
    }
    return const RemovalResult.ok();
  }

  static Future<RemovalResult> _removePacman(String package) async {
    if (!isValidRpmName(package)) {
      return RemovalResult.fail(
          message: 'invalid package name: $package', code: 'invalid-name');
    }
    return _execRemoval(
      buildPacmanRemoveCommand(package),
      sudo: true,
      stillPresent: () => _pacmanStillInstalled(package),
      stillPresentMessage: 'package still installed after removal',
    );
  }

  static Future<RemovalResult> _removeDnf(String package) async {
    if (!isValidRpmName(package)) {
      return RemovalResult.fail(
          message: 'invalid package name: $package', code: 'invalid-name');
    }
    return _execRemoval(
      buildDnfRemoveCommand(package),
      sudo: true,
      stillPresent: () => _rpmStillInstalled(package),
      stillPresentMessage: 'package still installed after removal',
    );
  }
}
