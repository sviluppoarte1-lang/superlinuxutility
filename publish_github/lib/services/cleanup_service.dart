import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'password_storage.dart';

class CleanupService {
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
  
  static Future<bool> testSudo() async {
    try {
      final result = await _runSudoCommand('true');
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> dropLinuxCache() async {
    try {
      const cmd = "bash -c 'sync && echo 1 | tee /proc/sys/vm/drop_caches > /dev/null'";
      final result = await _runSudoCommand(cmd);
      if (result.exitCode == 0) {
        return {'success': true, 'message': 'OK'};
      }
      final err = result.stderr?.toString() ?? result.stdout?.toString() ?? 'Errore';
      return {'success': false, 'message': err};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, int>> findAppTempFiles() async {
    final sizes = <String, int>{};
    final homeDir = Platform.environment['HOME'] ?? '';
    
    final appPaths = <String>[
      '$homeDir/.cache/google-chrome',
      '$homeDir/.cache/chromium',
      '$homeDir/.cache/mozilla/firefox',
      '$homeDir/.cache/microsoft-edge',
      '$homeDir/.cache/opera',
      '$homeDir/.cache/brave',
      '$homeDir/.mozilla/firefox/*/cache2',
      '$homeDir/.mozilla/firefox/*/OfflineCache',
      '$homeDir/.config/google-chrome/Default/Cache',
      '$homeDir/.config/chromium/Default/Cache',
      
      '$homeDir/.cache/atom',
      '$homeDir/.cache/sublime-text-3',
      '$homeDir/.cache/gedit',
      '$homeDir/.cache/kate',
      '$homeDir/.npm',
      '$homeDir/.cache/npm',
      '$homeDir/.yarn/cache',
      '$homeDir/.yarn/unplugged',
      '$homeDir/.pnpm-store',
      '$homeDir/.node-gyp',
      '$homeDir/.cache/pip',
      '$homeDir/.cache/pypoetry',
      '$homeDir/.local/share/pip',
      '$homeDir/.cargo/registry/cache',
      '$homeDir/.cargo/git',
      '$homeDir/.gradle/caches',
      '$homeDir/.gradle/daemon',
      '$homeDir/.m2/repository',
      '$homeDir/.cache/go-build',
      '$homeDir/go/pkg/mod/cache',
      '$homeDir/.cache/apt',
      '/var/cache/apt/archives',
      '/var/cache/apt/pkgcache.bin',
      '/var/cache/apt/srcpkgcache.bin',
      '$homeDir/.cache/snapd',
      '$homeDir/.cache/flatpak',
      '$homeDir/.var/app/*/cache',
      '$homeDir/.cache/vlc',
      '$homeDir/.cache/spotify',
      '$homeDir/.cache/audacious',
      '$homeDir/.cache/rhythmbox',
      '$homeDir/.cache/clementine',
      '$homeDir/.docker',
      '$homeDir/.cache/docker',
      '$homeDir/.cache/thumbnails',
      '$homeDir/.cache/fontconfig',
      '$homeDir/.cache/gstreamer-1.0',
      '$homeDir/.cache/evolution',
      '$homeDir/.cache/gnome-software',
      '$homeDir/.cache/gnome-shell',
      '$homeDir/.cache/compiz',
      '$homeDir/.cache/compizconfig-1',
      '$homeDir/.cache/zeitgeist',
      '$homeDir/.cache/tracker3',
      '$homeDir/.local/share/recently-used.xbel',
      '$homeDir/.local/share/Trash',
      '$homeDir/.cache/thumbnails',
    ];

    for (final pathPattern in appPaths) {
      try {
        if (pathPattern.contains('*')) {
          final basePath = pathPattern.substring(0, pathPattern.indexOf('*'));
          final dir = Directory(basePath);
          if (await dir.exists()) {
            await for (final entity in dir.list()) {
              if (entity is Directory) {
                final fullPath = entity.path + pathPattern.substring(pathPattern.indexOf('*') + 1);
                final targetDir = Directory(fullPath);
                if (await targetDir.exists()) {
                  final size = await _calculateDirSize(targetDir);
                  if (size > 0) {
                    sizes[fullPath] = size;
                  }
                }
              }
            }
          }
        } else {
          final dir = Directory(pathPattern);
          if (await dir.exists()) {
            final size = await _calculateDirSize(dir);
            if (size > 0) {
              sizes[pathPattern] = size;
            }
          }
        }
      } catch (e) {
        continue;
      }
    }

    return sizes;
  }

  static Future<int> _calculateDirSize(Directory dir) async {
    try {
      int size = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            size += await entity.length();
          } catch (e) {}
        }
      }
      return size;
    } catch (e) {
      return 0;
    }
  }

  static Future<Set<String>> getExcludedPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final excludedJson = prefs.getString('cleanup_excluded_paths');
      if (excludedJson != null) {
        final List<dynamic> excludedList = jsonDecode(excludedJson);
        return excludedList.map((e) => e.toString()).toSet();
      }
    } catch (e) {}
    return <String>{};
  }

  static Future<void> setExcludedPaths(Set<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cleanup_excluded_paths', jsonEncode(paths.toList()));
  }

  static Set<String> _getCriticalPaths(String homeDir) {
    return <String>{
      '$homeDir/.cache/ibus',
      '$homeDir/.cache/ibus-table',
      '$homeDir/.cache/fcitx',
      '$homeDir/.cache/fcitx5',
      '$homeDir/.config/ibus',
      '$homeDir/.config/fcitx',
      '$homeDir/.config/fcitx5',
      '$homeDir/.cache/Cursor',
      '$homeDir/.cache/cursor',
      '$homeDir/.config/Cursor',
      '$homeDir/.config/cursor',
      '$homeDir/.config/Cursor/User/workspaceStorage',
      '$homeDir/.config/Cursor/User/globalStorage',
      '$homeDir/.config/Cursor/CachedData',
      '$homeDir/.config/Cursor/Cache',
      '$homeDir/.config/Cursor/logs',
      '$homeDir/.config/Cursor/User/History',
      '$homeDir/.cache/Code',
      '$homeDir/.config/Code/User/workspaceStorage',
      '$homeDir/.config/Code/User/globalStorage',
      '$homeDir/.config/Code/CachedData',
      '$homeDir/.config/Code/Cache',
      '$homeDir/.config/Code/logs',
      '$homeDir/.config/Code/User/History',
      '$homeDir/.cache/session',
      '$homeDir/.cache/.lock',
      '$homeDir/.local/share/applications',
      '$homeDir/.cache/fontconfig',
      '$homeDir/.cache/gtk-3.0',
      '$homeDir/.cache/gtk-4.0',
      '$homeDir/.cache/gvfs',
      '$homeDir/.cache/dconf',
      '$homeDir/.cache/keyring',
      '$homeDir/.cache/gnome-keyring',
      '$homeDir/.cache/pkcs11',
      '$homeDir/.config/autostart',
      '$homeDir/.config/environment.d',
    };
  }

  static Future<Map<String, bool>> cleanupTempFiles() async {
    final results = <String, bool>{};
    final homeDir = Platform.environment['HOME'] ?? '';
    
    final basePaths = <String>{
      '$homeDir/.cache',
      '$homeDir/.local/share/Trash',
      '$homeDir/.tmp',
      '$homeDir/.thumbnails',
    };

    final appTempFiles = await findAppTempFiles();
    
    var allPaths = <String>{...basePaths, ...appTempFiles.keys};
    
    final excludedPaths = await getExcludedPaths();
    
    final criticalPaths = _getCriticalPaths(homeDir);
    
    allPaths = allPaths.where((path) {
      for (final critical in criticalPaths) {
        if (path == critical || path.startsWith('$critical/')) {
          return false;
        }
      }
      for (final excluded in excludedPaths) {
        if (path == excluded || path.startsWith('$excluded/')) {
          return false;
        }
      }
      return true;
    }).toSet();

    for (final path in allPaths) {
      
      try {
        final dir = Directory(path);
        
        if (!await dir.exists()) {
          results[path] = true;
          continue;
        }

        ProcessResult result;
        
        bool isCritical = false;
        for (final critical in criticalPaths) {
          if (path == critical || path.startsWith('$critical/')) {
            isCritical = true;
            break;
          }
        }
        if (isCritical) {
          results[path] = true;
          continue;
        }
        
        final criticalSubdirs = <String>[];
        for (final critical in criticalPaths) {
          if (critical.startsWith('$path/')) {
            final subdir = critical.substring(path.length + 1).split('/').first;
            if (subdir.isNotEmpty && !criticalSubdirs.contains(subdir)) {
              criticalSubdirs.add(subdir);
            }
          }
        }
        
        String cleanupCommand;
        if (criticalSubdirs.isEmpty) {
          cleanupCommand = 'rm -rf "$path"/* 2>&1';
        } else {
          final excludeNames = criticalSubdirs.map((dir) => '-name "$dir"').join(' -o ');
          cleanupCommand = 'find "$path" -mindepth 1 -maxdepth 1 \\( $excludeNames \\) -prune -o -print0 | xargs -0 rm -rf 2>&1 || true';
        }
        
        result = await Process.run(
          'bash',
          ['-c', cleanupCommand],
          runInShell: true,
        );
        
        if (result.exitCode != 0 && 
            (result.stderr as String).toLowerCase().contains('permission denied')) {
          try {
            result = await _runSudoCommand(cleanupCommand);
          } catch (e) {
            results[path] = false;
            continue;
          }
        }
        
        results[path] = result.exitCode == 0;
        
        if (!results[path]!) {
          try {
            await for (final entity in dir.list()) {
              try {
                bool isCriticalEntity = false;
                final entityPath = entity.path;
                for (final critical in criticalPaths) {
                  if (entityPath == critical || entityPath.startsWith('$critical/')) {
                    isCriticalEntity = true;
                    break;
                  }
                }
                
                if (isCriticalEntity) {
                  continue;
                }
                
                if (entity is File) {
                  await entity.delete();
                } else if (entity is Directory) {
                  await entity.delete(recursive: true);
                }
              } catch (e) {}
            }
            results[path] = true;
          } catch (e) {
            results[path] = false;
          }
        }
      } catch (e) {
        results[path] = false;
      }
    }

    return results;
  }

  static Future<Map<String, int>> getTempFilesSize() async {
    final sizes = <String, int>{};
    final homeDir = Platform.environment['HOME'] ?? '';
    
    final basePaths = [
      '$homeDir/.cache',
      '$homeDir/.local/share/Trash',
      '$homeDir/.tmp',
      '$homeDir/.thumbnails',
    ];

    final excludedPaths = await getExcludedPaths();
    final criticalPaths = _getCriticalPaths(homeDir);
    for (final path in basePaths) {
      bool isCritical = false;
      for (final critical in criticalPaths) {
        if (path == critical || path.startsWith('$critical/')) {
          isCritical = true;
          break;
        }
      }
      if (isCritical || excludedPaths.contains(path)) {
        sizes[path] = 0;
        continue;
      }
      
      try {
        final dir = Directory(path);
        if (await dir.exists()) {
          final size = await _calculateDirSize(dir);
          sizes[path] = size;
        } else {
          sizes[path] = 0;
        }
      } catch (e) {
        sizes[path] = 0;
      }
    }

    final appTempFiles = await findAppTempFiles();
    for (final entry in appTempFiles.entries) {
      bool isCritical = false;
      for (final critical in criticalPaths) {
        if (entry.key == critical || entry.key.startsWith('$critical/')) {
          isCritical = true;
          break;
        }
      }
      if (isCritical) {
        continue;
      }
      bool isExcluded = false;
      for (final excluded in excludedPaths) {
        if (entry.key == excluded || entry.key.startsWith('$excluded/')) {
          isExcluded = true;
          break;
        }
      }
      if (!isExcluded) {
        sizes[entry.key] = entry.value;
      }
    }

    return sizes;
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
