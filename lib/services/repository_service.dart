import 'dart:io';
import 'password_storage.dart';

enum PkgManager { apt, dnf, pacman, unknown }

class SystemRepository {
  final String name;
  final String uri;
  final String suite;
  final String components;
  final String filePath;
  final int startLine;
  final bool enabled;
  final String rawContent;
  final String type;

  const SystemRepository({
    required this.name,
    required this.uri,
    required this.suite,
    required this.components,
    required this.filePath,
    required this.startLine,
    required this.enabled,
    required this.rawContent,
    this.type = 'deb',
  });

  SystemRepository copyWith({bool? enabled, String? rawContent}) {
    return SystemRepository(
      name: name,
      uri: uri,
      suite: suite,
      components: components,
      filePath: filePath,
      startLine: startLine,
      enabled: enabled ?? this.enabled,
      rawContent: rawContent ?? this.rawContent,
      type: type,
    );
  }
}

class RepositoryService {
  static Future<PkgManager> detectPkgManager() async {
    if (await _hasCommand('apt')) return PkgManager.apt;
    if (await _hasCommand('dnf')) return PkgManager.dnf;
    if (await _hasCommand('pacman')) return PkgManager.pacman;
    return PkgManager.unknown;
  }

  static Future<bool> _hasCommand(String cmd) async {
    try {
      final r = await Process.run('which', [cmd]);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<List<SystemRepository>> loadRepositories() async {
    final pm = await detectPkgManager();
    switch (pm) {
      case PkgManager.apt:
        return _loadAptRepos();
      case PkgManager.dnf:
        return _loadDnfRepos();
      case PkgManager.pacman:
        return _loadPacmanRepos();
      case PkgManager.unknown:
        return [];
    }
  }

  // ─── APT ───

  static Future<List<SystemRepository>> _loadAptRepos() async {
    final repos = <SystemRepository>[];
    await _parseAptFile(File('/etc/apt/sources.list'), repos);

    final dir = Directory('/etc/apt/sources.list.d');
    if (await dir.exists()) {
      await for (final f in dir.list()) {
        if (f is File) {
          final name = f.path;
          if (name.endsWith('.list')) {
            await _parseAptFile(f, repos);
          } else if (name.endsWith('.sources')) {
            await _parseDeb822File(f, repos);
          }
        }
      }
    }
    return repos;
  }

  static Future<void> _parseAptFile(File file, List<SystemRepository> repos) async {
    if (!await file.exists()) return;
    try {
      final lines = await file.readAsLines();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final isDisabled = line.startsWith('#');
        final cleanLine = isDisabled ? line.replaceFirst(RegExp(r'^#\s*'), '') : line;
        final parsed = _parseOneLineApt(cleanLine);
        if (parsed != null) {
          repos.add(SystemRepository(
            name: '${parsed['suite']} ${parsed['components']}',
            uri: parsed['uri']!,
            suite: parsed['suite']!,
            components: parsed['components']!,
            filePath: file.path,
            startLine: i,
            enabled: !isDisabled,
            rawContent: line,
            type: parsed['type']!,
          ));
        }
      }
    } catch (_) {}
  }

  static Map<String, String>? _parseOneLineApt(String line) {
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length < 4) return null;
    final type = parts[0];
    if (type != 'deb' && type != 'deb-src') return null;
    return {
      'type': type,
      'uri': parts[1],
      'suite': parts[2],
      'components': parts.sublist(3).join(' '),
    };
  }

  static Future<void> _parseDeb822File(File file, List<SystemRepository> repos) async {
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final blocks = content.split(RegExp(r'\n(?=\S)'));
      int lineOffset = 0;
      for (final block in blocks) {
        final blockLines = block.split('\n');
        String? types, uris, suites, components;
        bool enabled = true;
        for (final bl in blockLines) {
          final trimmed = bl.trim();
          if (trimmed.startsWith('#')) { enabled = false; continue; }
          if (trimmed.startsWith('Types:')) types = trimmed.substring(6).trim();
          if (trimmed.startsWith('URIs:')) uris = trimmed.substring(5).trim();
          if (trimmed.startsWith('Suites:')) suites = trimmed.substring(7).trim();
          if (trimmed.startsWith('Components:')) components = trimmed.substring(11).trim();
        }
        if (uris != null && suites != null) {
          repos.add(SystemRepository(
            name: '$suites ${components ?? ''}',
            uri: uris,
            suite: suites,
            components: components ?? '',
            filePath: file.path,
            startLine: lineOffset,
            enabled: enabled,
            rawContent: block.trim(),
            type: types ?? 'deb',
          ));
        }
        lineOffset += blockLines.length;
      }
    } catch (_) {}
  }

  // ─── DNF ───

  static Future<List<SystemRepository>> _loadDnfRepos() async {
    final repos = <SystemRepository>[];
    final dir = Directory('/etc/yum.repos.d');
    if (!await dir.exists()) return repos;

    await for (final f in dir.list()) {
      if (f is File && f.path.endsWith('.repo')) {
        await _parseDnfFile(f, repos);
      }
    }
    return repos;
  }

  static Future<void> _parseDnfFile(File file, List<SystemRepository> repos) async {
    if (!await file.exists()) return;
    try {
      final lines = await file.readAsLines();
      String? currentName;
      String? currentBaseurl;
      bool currentEnabled = true;
      int startLine = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('[') && line.endsWith(']')) {
          if (currentName != null) {
            repos.add(SystemRepository(
              name: currentName,
              uri: currentBaseurl ?? '',
              suite: '',
              components: '',
              filePath: file.path,
              startLine: startLine,
              enabled: currentEnabled,
              rawContent: currentName,
              type: 'repo',
            ));
          }
          currentName = line.substring(1, line.length - 1);
          currentBaseurl = null;
          currentEnabled = true;
          startLine = i;
        } else if (line.startsWith('baseurl=')) {
          currentBaseurl = line.substring(8).trim();
        } else if (line.startsWith('enabled=')) {
          currentEnabled = line.substring(8).trim() == '1';
        }
      }
      if (currentName != null) {
        repos.add(SystemRepository(
          name: currentName,
          uri: currentBaseurl ?? '',
          suite: '',
          components: '',
          filePath: file.path,
          startLine: startLine,
          enabled: currentEnabled,
          rawContent: currentName,
          type: 'repo',
        ));
      }
    } catch (_) {}
  }

  // ─── Pacman ───

  static Future<List<SystemRepository>> _loadPacmanRepos() async {
    final repos = <SystemRepository>[];
    final file = File('/etc/pacman.conf');
    if (!await file.exists()) return repos;
    try {
      final lines = await file.readAsLines();
      String? currentName;
      int startLine = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('[') && line.endsWith(']')) {
          currentName = line.substring(1, line.length - 1);
          startLine = i;
        } else if (line.startsWith('Server') && currentName != null) {
          final serverLine = line;
          final enabled = !line.startsWith('#');
          final uri = serverLine.replaceAll(RegExp(r'^#\s*'), '').replaceFirst('Server = ', '').replaceFirst('Server=', '');
          repos.add(SystemRepository(
            name: currentName,
            uri: uri.trim(),
            suite: '',
            components: '',
            filePath: '/etc/pacman.conf',
            startLine: startLine,
            enabled: enabled,
            rawContent: '$currentName: $serverLine',
            type: 'server',
          ));
          currentName = null;
        }
      }
    } catch (_) {}
    return repos;
  }

  // ─── Operations ───

  static Future<bool> editRepository(SystemRepository repo, String newContent) async {
    final pm = await detectPkgManager();
    switch (pm) {
      case PkgManager.apt:
        return _editAptRepo(repo, newContent);
      case PkgManager.dnf:
        return _editDnfRepo(repo, newContent);
      case PkgManager.pacman:
        return _editPacmanRepo(repo, newContent);
      case PkgManager.unknown:
        return false;
    }
  }

  static Future<bool> _editAptRepo(SystemRepository repo, String newContent) async {
    try {
      final content = await File(repo.filePath).readAsString();
      final lines = content.split('\n');
      if (repo.startLine >= lines.length) return false;
      lines[repo.startLine] = newContent;
      return _writeFileWithSudo(repo.filePath, lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _editDnfRepo(SystemRepository repo, String newContent) async {
    try {
      final content = await File(repo.filePath).readAsString();
      final lines = content.split('\n');
      if (repo.startLine >= lines.length) return false;
      bool inSection = false;
      int endLine = repo.startLine;
      for (int i = repo.startLine; i < lines.length; i++) {
        final line = lines[i].trim();
        if (i > repo.startLine && line.startsWith('[') && line.endsWith(']')) break;
        inSection = true;
        endLine = i;
      }
      if (!inSection) return false;
      final newLines = newContent.split('\n');
      lines.replaceRange(repo.startLine, endLine + 1, newLines);
      return _writeFileWithSudo(repo.filePath, lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _editPacmanRepo(SystemRepository repo, String newContent) async {
    try {
      final content = await File('/etc/pacman.conf').readAsString();
      final lines = content.split('\n');
      int endLine = repo.startLine;
      for (int i = repo.startLine + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('[') && line.endsWith(']')) break;
        endLine = i;
      }
      final newLines = newContent.split('\n');
      lines.replaceRange(repo.startLine, endLine + 1, newLines);
      return _writeFileWithSudo('/etc/pacman.conf', lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleRepository(SystemRepository repo, bool enable) async {
    final pm = await detectPkgManager();
    switch (pm) {
      case PkgManager.apt:
        return _toggleAptRepo(repo, enable);
      case PkgManager.dnf:
        return _toggleDnfRepo(repo, enable);
      case PkgManager.pacman:
        return _togglePacmanRepo(repo, enable);
      case PkgManager.unknown:
        return false;
    }
  }

  static Future<bool> _toggleAptRepo(SystemRepository repo, bool enable) async {
    try {
      final content = await File(repo.filePath).readAsString();
      final lines = content.split('\n');
      if (repo.startLine >= lines.length) return false;

      final line = lines[repo.startLine].trim();
      if (enable) {
        if (line.startsWith('#')) {
          lines[repo.startLine] = line.replaceFirst(RegExp(r'^#\s*'), '');
        }
      } else {
        if (!line.startsWith('#')) {
          lines[repo.startLine] = '#$line';
        }
      }
      return _writeFileWithSudo(repo.filePath, lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _toggleDnfRepo(SystemRepository repo, bool enable) async {
    try {
      final content = await File(repo.filePath).readAsString();
      final lines = content.split('\n');
      bool inSection = false;
      for (int i = repo.startLine; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('[') && line.endsWith(']')) {
          if (inSection) break;
          inSection = true;
          continue;
        }
        if (inSection && line.startsWith('enabled=')) {
          lines[i] = 'enabled=${enable ? '1' : '0'}';
          break;
        }
      }
      return _writeFileWithSudo(repo.filePath, lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _togglePacmanRepo(SystemRepository repo, bool enable) async {
    try {
      final content = await File('/etc/pacman.conf').readAsString();
      final lines = content.split('\n');
      bool inSection = false;
      for (int i = repo.startLine; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('[') && line.endsWith(']')) {
          if (inSection) break;
          inSection = true;
          continue;
        }
        if (inSection && (line.startsWith('Server') || line.startsWith('#Server'))) {
          if (enable) {
            lines[i] = line.replaceFirst(RegExp(r'^#\s*'), '');
          } else {
            if (!line.startsWith('#')) {
              lines[i] = '#$line';
            }
          }
          break;
        }
      }
      return _writeFileWithSudo('/etc/pacman.conf', lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeRepository(SystemRepository repo) async {
    final pm = await detectPkgManager();
    switch (pm) {
      case PkgManager.apt:
        return _removeAptRepo(repo);
      case PkgManager.dnf:
        return _removeDnfRepo(repo);
      case PkgManager.pacman:
        return _removePacmanRepo(repo);
      case PkgManager.unknown:
        return false;
    }
  }

  static Future<bool> _removeAptRepo(SystemRepository repo) async {
    try {
      if (repo.filePath == '/etc/apt/sources.list') {
        final content = await File(repo.filePath).readAsString();
        final lines = content.split('\n');
        if (repo.startLine < lines.length) {
          lines.removeAt(repo.startLine);
          return _writeFileWithSudo(repo.filePath, lines.join('\n'));
        }
        return false;
      }
      return await _runSudoCommand('rm -f ${_shellQuote(repo.filePath)}');
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _removeDnfRepo(SystemRepository repo) async {
    return _runSudoCommand('rm -f ${_shellQuote(repo.filePath)}');
  }

  static Future<bool> _removePacmanRepo(SystemRepository repo) async {
    try {
      final content = await File('/etc/pacman.conf').readAsString();
      final lines = content.split('\n');
      int endLine = repo.startLine;
      for (int i = repo.startLine + 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('[') && line.endsWith(']')) break;
        if (line.isEmpty && endLine == repo.startLine) {
          endLine = i;
          break;
        }
        endLine = i;
      }
      lines.removeRange(repo.startLine, endLine + 1);
      return _writeFileWithSudo('/etc/pacman.conf', lines.join('\n'));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> addRepository(String line) async {
    final pm = await detectPkgManager();
    switch (pm) {
      case PkgManager.apt:
        return _addAptRepo(line);
      case PkgManager.dnf:
        return _addDnfRepo(line);
      case PkgManager.pacman:
        return _addPacmanRepoFromLine(line);
      case PkgManager.unknown:
        return false;
    }
  }

  static Future<bool> _addAptRepo(String line) async {
    final file = '/etc/apt/sources.list.d/custom.list';
    final cmd = 'echo ${_shellQuote(line)} >> $file';
    return _runSudoCommand(cmd);
  }

  static Future<bool> _addDnfRepo(String line) async {
    final file = '/etc/yum.repos.d/custom.repo';
    final cmd = 'echo ${_shellQuote(line)} >> $file';
    return _runSudoCommand(cmd);
  }

  static Future<bool> _addPacmanRepoFromLine(String line) async {
    final cmd = 'echo ${_shellQuote(line)} >> /etc/pacman.conf';
    return _runSudoCommand(cmd);
  }

  // ─── Utility ───

  static Future<bool> _writeFileWithSudo(String path, String content) async {
    final tmpFile = '/tmp/_repo_tmp_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await File(tmpFile).writeAsString(content);
      final r = await _runSudoCommand('cp ${_shellQuote(tmpFile)} ${_shellQuote(path)}');
      await File(tmpFile).delete();
      return r;
    } catch (_) {
      try { await File(tmpFile).delete(); } catch (_) {}
      return false;
    }
  }

  static Future<bool> _runSudoCommand(String command) async {
    try {
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) return false;
      final escapedPassword = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');
      final fullCommand =
          'printf "%s\\n" "$escapedPassword" | sudo -p "" -S bash -c ${_shellQuote(command)} 2>&1';
      final result = await Process.run('bash', ['-c', fullCommand], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }
}
