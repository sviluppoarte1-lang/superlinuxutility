import 'dart:io';
import '../models/installed_app.dart';
import 'password_storage.dart';

class AppManager {
  /// Esegue un comando con sudo usando la password salvata
  static Future<ProcessResult> _runSudoCommand(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    
    final fullCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S $command';
    
    return await Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
  }

  /// Ottiene tutte le app installate da tutti i package manager
  /// Il controllo delle dipendenze viene fatto solo quando necessario (lazy loading)
  static Future<List<InstalledApp>> getAllInstalledApps() async {
    final apps = <InstalledApp>[];
    
    // Ottieni app da tutti i package manager in parallelo
    final results = await Future.wait([
      getAptApps(),
      getSnapApps(),
      getFlatpakApps(),
      getGnomeApps(),
    ]);
    
    for (final appList in results) {
      apps.addAll(appList);
    }
    
    // NON controlliamo le dipendenze qui - troppo lento!
    // Le dipendenze verranno controllate solo quando necessario (prima della rimozione)
    
    return apps;
  }
  
  /// Controlla le dipendenze per un'app specifica (chiamato solo quando necessario)
  static Future<InstalledApp> checkAppDependencies(InstalledApp app) async {
    if (app.packageManager == PackageManager.apt) {
      await _checkAptDependencies(app);
    }
    return app;
  }

  /// Ottiene le app installate via APT
  static Future<List<InstalledApp>> getAptApps() async {
    try {
      final result = await Process.run(
        'dpkg-query',
        ['-W', '-f=\${Package};\${Version};\${Description};\${Installed-Size}\\n'],
      );

      if (result.exitCode != 0) {
        // Prova con apt list
        final aptResult = await Process.run(
          'apt',
          ['list', '--installed', '2>/dev/null'],
        );
        return _parseAptList(aptResult.stdout as String);
      }

      return _parseDpkgQuery(result.stdout as String);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di dpkg-query
  static List<InstalledApp> _parseDpkgQuery(String output) {
    final apps = <InstalledApp>[];
    final lines = output.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final parts = line.split(';');
      if (parts.length >= 3) {
        final name = parts[0].trim();
        final version = parts[1].trim();
        final description = parts.length > 2 ? parts[2].trim() : '';
        final size = parts.length > 3 ? int.tryParse(parts[3].trim()) : null;
        
        // Determina se è un pacchetto di sistema
        final isSystem = _isSystemPackage(name);
        
        apps.add(InstalledApp(
          name: name,
          version: version,
          description: description,
          packageManager: PackageManager.apt,
          size: size != null ? size * 1024 : null, // Converti KB in bytes
          isSystemPackage: isSystem,
        ));
      }
    }
    
    return apps;
  }

  /// Parsing dell'output di apt list
  static List<InstalledApp> _parseAptList(String output) {
    final apps = <InstalledApp>[];
    final lines = output.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty || line.startsWith('Listing...')) continue;
      
      // Formato: nome/versione,architettura descrizione
      final match = RegExp(r'^([^/]+)/([^\s]+)\s+(.+)$').firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final version = match.group(2)!.split(',')[0].trim();
        final description = match.group(3)?.trim() ?? '';
        
        apps.add(InstalledApp(
          name: name,
          version: version,
          description: description,
          packageManager: PackageManager.apt,
          isSystemPackage: _isSystemPackage(name),
        ));
      }
    }
    
    return apps;
  }

  /// Ottiene le app installate via Snap
  static Future<List<InstalledApp>> getSnapApps() async {
    try {
      final result = await Process.run(
        'snap',
        ['list'],
      );

      if (result.exitCode != 0) {
        return [];
      }

      return _parseSnapList(result.stdout as String);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di snap list
  static List<InstalledApp> _parseSnapList(String output) {
    final apps = <InstalledApp>[];
    final lines = output.split('\n');
    
    // Salta la prima riga (header)
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final name = parts[0];
        final version = parts[1];
        final notes = parts.length > 2 ? parts.sublist(2).join(' ') : '';
        
        apps.add(InstalledApp(
          name: name,
          version: version,
          description: notes,
          packageManager: PackageManager.snap,
          isSystemPackage: name == 'core' || name == 'snapd',
        ));
      }
    }
    
    return apps;
  }

  /// Ottiene le app installate via Flatpak
  static Future<List<InstalledApp>> getFlatpakApps() async {
    try {
      final result = await Process.run(
        'flatpak',
        ['list', '--app'],
      );

      if (result.exitCode != 0) {
        return [];
      }

      return _parseFlatpakList(result.stdout as String);
    } catch (e) {
      return [];
    }
  }

  /// Parsing dell'output di flatpak list
  static List<InstalledApp> _parseFlatpakList(String output) {
    final apps = <InstalledApp>[];
    final lines = output.split('\n');
    
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Formato: Nome    Applicazione ID    Versione    Branch
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final name = parts[0];
        final appId = parts[1];
        final version = parts.length > 2 ? parts[2] : '';
        
        apps.add(InstalledApp(
          name: name,
          version: version,
          description: appId,
          packageManager: PackageManager.flatpak,
          isSystemPackage: false,
        ));
      }
    }
    
    return apps;
  }

  /// Ottiene le app GNOME (desktop applications)
  static Future<List<InstalledApp>> getGnomeApps() async {
    try {
      final apps = <InstalledApp>[];
      final homeDir = Platform.environment['HOME'] ?? '';
      
      // Cerca in /usr/share/applications e ~/.local/share/applications
      final paths = [
        '/usr/share/applications',
        '$homeDir/.local/share/applications',
      ];
      
      for (final path in paths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          await for (final entity in dir.list()) {
            if (entity is File && entity.path.endsWith('.desktop')) {
              try {
                final content = await entity.readAsString();
                String? name;
                String? comment;
                
                for (final line in content.split('\n')) {
                  if (line.startsWith('Name=')) {
                    name = line.substring(5).trim();
                  } else if (line.startsWith('Comment=')) {
                    comment = line.substring(8).trim();
                  }
                }
                
                if (name != null) {
                  apps.add(InstalledApp(
                    name: name,
                    description: comment,
                    packageManager: PackageManager.gnome,
                    isSystemPackage: path.startsWith('/usr'),
                  ));
                }
              } catch (e) {
                // Ignora errori
              }
            }
          }
        }
      }
      
      return apps;
    } catch (e) {
      return [];
    }
  }

  /// Verifica se un pacchetto è di sistema
  static bool _isSystemPackage(String name) {
    final systemPackages = [
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
    
    final lowerName = name.toLowerCase();
    return systemPackages.any((pkg) => lowerName.contains(pkg));
  }

  /// Controlla le dipendenze per un pacchetto APT
  static Future<void> _checkAptDependencies(InstalledApp app) async {
    try {
      // Ottieni le dipendenze
      final depsResult = await Process.run(
        'apt-cache',
        ['depends', app.name],
      );
      
      if (depsResult.exitCode == 0) {
        final deps = <String>[];
        for (final line in (depsResult.stdout as String).split('\n')) {
          if (line.trim().startsWith('Depends:')) {
            final dep = line.replaceFirst('Depends:', '').trim();
            deps.add(dep.split(' ')[0]); // Prendi solo il nome, ignora versione
          }
        }
        app.dependencies.addAll(deps);
      }
      
      // Ottieni le dipendenze inverse (chi dipende da questo pacchetto)
      final revDepsResult = await Process.run(
        'apt-cache',
        ['rdepends', '--installed', app.name],
      );
      
      if (revDepsResult.exitCode == 0) {
        final revDeps = <String>[];
        final lines = (revDepsResult.stdout as String).split('\n');
        bool inReverseDepends = false;
        
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed == 'Reverse Depends:' || trimmed == 'Reverse Depends') {
            inReverseDepends = true;
            continue;
          }
          if (inReverseDepends && trimmed.isNotEmpty && !trimmed.startsWith(app.name)) {
            // Prendi solo il nome del pacchetto, ignora versione e architettura
            final pkgName = trimmed.split(' ')[0].split('(')[0].trim();
            if (pkgName.isNotEmpty && pkgName != app.name) {
              revDeps.add(pkgName);
            }
          }
        }
        app.reverseDependencies.addAll(revDeps);
      }
    } catch (e) {
      // Ignora errori
    }
  }

  /// Rimuove un'app installata
  static Future<bool> removeApp(InstalledApp app) async {
    try {
      ProcessResult result;
      
      switch (app.packageManager) {
        case PackageManager.apt:
          result = await _runSudoCommand('apt-get remove -y ${app.name}');
          break;
        case PackageManager.snap:
          result = await Process.run('snap', ['remove', app.name]);
          break;
        case PackageManager.flatpak:
          result = await Process.run('flatpak', ['uninstall', '-y', app.description ?? app.name]);
          break;
        case PackageManager.gnome:
          // Per le app GNOME, rimuovi il file .desktop
          final homeDir = Platform.environment['HOME'] ?? '';
          final desktopFile = File('$homeDir/.local/share/applications/${app.name}.desktop');
          if (await desktopFile.exists()) {
            await desktopFile.delete();
            return true;
          }
          return false;
      }
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Rimuove un'app con tutte le sue dipendenze non utilizzate
  static Future<bool> removeAppWithDependencies(InstalledApp app) async {
    try {
      if (app.packageManager == PackageManager.apt) {
        final result = await _runSudoCommand('apt-get autoremove -y ${app.name}');
        return result.exitCode == 0;
      }
      return await removeApp(app);
    } catch (e) {
      return false;
    }
  }
}

