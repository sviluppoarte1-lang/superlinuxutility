import 'dart:io';
import 'dart:async';
import 'password_storage.dart';

/// Modello per rappresentare un file o directory
class FileSystemItem {
  final String path;
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime? modified;
  final String? mimeType;

  FileSystemItem({
    required this.path,
    required this.name,
    required this.size,
    required this.isDirectory,
    this.modified,
    this.mimeType,
  });
}

/// Modello per rappresentare una directory con la sua dimensione
class DirectorySize {
  final String path;
  final int size;
  final int fileCount;
  final int directoryCount;
  final List<DirectorySize>? children;

  DirectorySize({
    required this.path,
    required this.size,
    required this.fileCount,
    required this.directoryCount,
    this.children,
  });

  String get name => path.split('/').last.isEmpty ? path : path.split('/').last;
}

class DiskAnalyzerService {
  static const List<String> _rootSkipPaths = [
    '/proc', '/sys', '/dev', '/run', '/snap', '/boot', '/boot/efi', '/lost+found', '/sysroot',
  ];

  static bool _shouldSkipForRoot(String path) {
    if (path == '/proc' || path == '/sys' || path == '/dev' || path == '/run') return true;
    if (path == '/snap' || path == '/boot' || path == '/boot/efi' || path == '/lost+found' || path == '/sysroot') return true;
    if (path.startsWith('/proc/') || path.startsWith('/sys/') || path.startsWith('/dev/') || path.startsWith('/run/')) return true;
    if (path.startsWith('/snap/') || path.startsWith('/boot/')) return true;
    return false;
  }

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

  /// Calcola la dimensione di una directory usando du (ottimizzato per velocità)
  /// Supporta anche cartelle molto grandi (oltre 1TB) con timeout più lunghi
  static Future<int> getDirectorySize(String path) async {
    try {
      // Prova prima con du -sb (preciso, ma può essere lento per cartelle molto grandi)
      // Usa un timeout più lungo (30 secondi) per cartelle di grandi dimensioni
      final result = await Process.run(
        'bash',
        ['-c', 'timeout 30 du -sb "$path" 2>/dev/null | tail -1 | cut -f1'],
      ).timeout(
        const Duration(seconds: 35),
      );
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        if (output.isNotEmpty) {
          final size = int.tryParse(output);
          if (size != null && size > 0) {
            return size;
          }
        }
      }
    } catch (e) {
      // Se timeout o errore, prova un metodo alternativo più veloce
      try {
        // Usa du -sh e converti (più veloce ma meno preciso)
        // Questo metodo è utile per cartelle molto grandi che richiederebbero troppo tempo
        final result = await Process.run(
          'bash',
          ['-c', 'timeout 15 du -sh "$path" 2>/dev/null | cut -f1'],
        ).timeout(
          const Duration(seconds: 20),
        );
        if (result.exitCode == 0) {
          final output = (result.stdout as String).trim();
          if (output.isNotEmpty) {
            // Converti da formato umano (es. "1.5G", "500T") a bytes
            return _parseHumanSize(output);
          }
        }
      } catch (e2) {
        // Se anche questo fallisce, prova un metodo ancora più veloce usando stat
        // Questo è utile per cartelle molto grandi su dischi esterni
        try {
          // Usa du con --apparent-size per velocità (non conta i link hard)
          final result = await Process.run(
            'bash',
            ['-c', 'timeout 20 du -sb --apparent-size "$path" 2>/dev/null | tail -1 | cut -f1'],
          ).timeout(
            const Duration(seconds: 25),
          );
          if (result.exitCode == 0) {
            final output = (result.stdout as String).trim();
            if (output.isNotEmpty) {
              return int.tryParse(output) ?? 0;
            }
          }
        } catch (e3) {
          // Ignora errori finali
        }
      }
    }
    return 0;
  }

  /// Converte una dimensione in formato umano (es. "1.5G", "500M", "2.5T") in bytes
  /// Supporta anche terabyte (T) per cartelle molto grandi
  static int _parseHumanSize(String sizeStr) {
    // Rimuovi spazi e converti in maiuscolo
    final cleanStr = sizeStr.trim().toUpperCase();
    
    // Pattern per riconoscere dimensioni come "1.5G", "500M", "2.5T", "1000K"
    // Supporta anche formati con spazi come "1.5 G" o "2.5 T"
    final regex = RegExp(r'^([\d.]+)\s*([KMGT]?)$', caseSensitive: false);
    final match = regex.firstMatch(cleanStr);
    if (match != null) {
      final value = double.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = (match.group(2) ?? '').toUpperCase();
      
      switch (unit) {
        case 'K':
          return (value * 1024).toInt();
        case 'M':
          return (value * 1024 * 1024).toInt();
        case 'G':
          return (value * 1024 * 1024 * 1024).toInt();
        case 'T':
          // Supporto per terabyte (importante per cartelle molto grandi)
          return (value * 1024 * 1024 * 1024 * 1024).toInt();
        default:
          // Se non c'è unità, assume bytes
          return value.toInt();
      }
    }
    return 0;
  }

  /// Lista i file e directory in un percorso (senza calcolare dimensioni per velocità)
  /// Per la root (/) usa prima ls con sudo per evitare blocchi di Directory.list()
  static Future<List<FileSystemItem>> listDirectory(String path, {bool calculateSizes = false}) async {
    final items = <FileSystemItem>[];

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return items;
      }

      bool listed = false;
      if (path == '/' || path.startsWith('/sys') || path.startsWith('/proc') || path.startsWith('/dev')) {
        try {
          final result = await _runSudoCommand('ls -la "$path" 2>/dev/null')
              .timeout(const Duration(seconds: 15), onTimeout: () => ProcessResult(1, -1, 'timeout', 'timeout'));
          if (result.exitCode == 0) {
            final output = result.stdout as String;
            final lines = output.split('\n').skip(1);
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 9) {
                final isDir = parts[0].startsWith('d');
                final name = parts.sublist(8).join(' ');
                if (name == '.' || name == '..') continue;
                final fullPath = path == '/' ? '/$name' : '$path/$name';
                if (path == '/' && _shouldSkipForRoot(fullPath)) continue;
                String? mimeType;
                if (!isDir) {
                  final ext = name.split('.').last.toLowerCase();
                  mimeType = _getMimeType(ext);
                }
                int size = 0;
                if (isDir && calculateSizes && !_shouldSkipForRoot(fullPath)) {
                  size = await getDirectorySize(fullPath).timeout(
                    const Duration(seconds: 5),
                    onTimeout: () => 0,
                  );
                }
                items.add(FileSystemItem(
                  path: fullPath,
                  name: name,
                  size: size,
                  isDirectory: isDir,
                  mimeType: mimeType,
                ));
              }
            }
            listed = true;
          }
        } catch (_) {}
      }

      if (!listed) {
        try {
          await for (final entity in dir.list(recursive: false).timeout(
                Duration(seconds: path == '/' ? 12 : 30),
                onTimeout: (sink) => sink.close(),
              )) {
            try {
              if (path == '/' && _rootSkipPaths.contains(entity.path)) continue;
              final stat = await entity.stat().timeout(
                const Duration(milliseconds: 500),
                onTimeout: () => throw TimeoutException('Stat timeout'),
              );
              final isDir = entity is Directory;
              final name = entity.path.split('/').last;
              String? mimeType;
              if (!isDir) {
                final extension = name.split('.').last.toLowerCase();
                mimeType = _getMimeType(extension);
              }
              int size = 0;
              if (!isDir) {
                size = stat.size;
              } else if (calculateSizes && !_shouldSkipForRoot(entity.path)) {
                size = await getDirectorySize(entity.path).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => 0,
                );
              }
              items.add(FileSystemItem(
                path: entity.path,
                name: name,
                size: size,
                isDirectory: isDir,
                modified: stat.modified,
                mimeType: mimeType,
              ));
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          // timeout o altro: restituisci comunque items (eventualmente vuoti)
        }
      }

      // Ordina: directory prima (per nome), poi file (per nome)
      // L'ordinamento per dimensione verrà fatto dopo che le dimensioni sono state calcolate
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        // Entrambi directory o entrambi file: ordina per nome (alfabetico)
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return items;
    } catch (e) {
      return items;
    }
  }

  /// Ottiene il tipo MIME basato sull'estensione
  static String? _getMimeType(String extension) {
    const mimeTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'html': 'text/html',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mp3': 'audio/mpeg',
      'zip': 'application/zip',
    };
    return mimeTypes[extension];
  }

  /// Analizza lo spazio occupato da una directory usando du per performance
  static Future<DirectorySize> analyzeDirectory(String path, {int maxDepth = 2}) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return DirectorySize(
          path: path,
          size: 0,
          fileCount: 0,
          directoryCount: 0,
        );
      }

      // Usa du per calcolare la dimensione totale (molto più veloce)
      // Supporta anche cartelle molto grandi (oltre 1TB) con timeout più lunghi
      int totalSize = 0;
      try {
        final duCmd = path == '/'
            ? 'timeout 30 du -sb / --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/run --exclude=/snap --exclude=/boot --exclude=/boot/efi --exclude=/lost+found 2>/dev/null | tail -1'
            : 'timeout 30 du -sb "$path" 2>/dev/null | tail -1';
        final result = await Process.run(
          'bash',
          ['-c', duCmd],
        ).timeout(
          const Duration(seconds: 35),
        );
        if (result.exitCode == 0) {
          final output = (result.stdout as String).trim();
          // Il formato di du -sb è: "dimensione\tpath"
          final parts = output.split(RegExp(r'\s+'));
          if (parts.isNotEmpty) {
            totalSize = int.tryParse(parts[0]) ?? 0;
          }
        }
      } catch (e) {
        // Se timeout, prova con formato umano (più veloce)
        try {
          final result = await Process.run(
            'bash', 
            ['-c', 'timeout 20 du -sh "$path" 2>/dev/null | cut -f1'],
          ).timeout(
            const Duration(seconds: 25),
          );
          if (result.exitCode == 0) {
            final output = (result.stdout as String).trim();
            if (output.isNotEmpty) {
              totalSize = _parseHumanSize(output);
            }
          }
        } catch (e2) {
          // Fallback se anche questo fallisce
          totalSize = 0;
        }
      }

      int fileCount = 0;
      int directoryCount = 0;
      List<DirectorySize>? children;

      if (maxDepth > 0) {
        children = [];
        try {
          int count = 0;
          const maxChildren = 50;
          await for (final entity in dir.list()) {
            if (count >= maxChildren) break;
            try {
              if (path == '/' && entity is Directory && _rootSkipPaths.contains(entity.path)) continue;
              if (entity is Directory) {
                directoryCount++;
                count++;
                int childSize = 0;
                try {
                  final isRootChild = path == '/';
                  final tSec = isRootChild ? 8 : 12;
                  final escPath = entity.path.replaceAll("'", "'\"'\"'");
                  final duResult = await Process.run(
                    'bash',
                    ['-c', 'timeout $tSec du -sb \'$escPath\' 2>/dev/null | tail -1'],
                  ).timeout(
                    Duration(seconds: isRootChild ? 10 : 15),
                  );
                  if (duResult.exitCode == 0) {
                    final output = (duResult.stdout as String).trim();
                    // Il formato di du -sb è: "dimensione\tpath"
                    final parts = output.split(RegExp(r'\s+'));
                    if (parts.isNotEmpty) {
                      childSize = int.tryParse(parts[0]) ?? 0;
                    }
                  }
                } catch (e) {
                  // Se du fallisce o timeout, salta questo directory
                  childSize = 0;
                }

                // Conta file e directory nel sottodirectory (limitato per performance)
                int childFileCount = 0;
                int childDirCount = 0;
                try {
                  int subCount = 0;
                  await for (final subEntity in Directory(entity.path).list(recursive: false)) {
                    if (subCount++ > 100) break; // Limita il conteggio per performance
                    if (subEntity is File) {
                      childFileCount++;
                    } else if (subEntity is Directory) {
                      childDirCount++;
                    }
                  }
                } catch (e) {
                  // Ignora errori
                }

                children.add(DirectorySize(
                  path: entity.path,
                  size: childSize,
                  fileCount: childFileCount,
                  directoryCount: childDirCount,
                  children: null, // Non analizzare ulteriormente per performance
                ));
              } else if (entity is File) {
                fileCount++;
              }
            } catch (e) {
              // Ignora errori di accesso
              continue;
            }
          }
        } catch (e) {
          // Ignora errori di accesso alla directory
        }

        // Ordina i figli per dimensione (dal più grande al più piccolo)
        children.sort((a, b) => b.size.compareTo(a.size));
      } else {
        // Se maxDepth è 0, conta solo file e directory
        try {
          await for (final entity in dir.list(recursive: true)) {
            try {
              if (entity is File) {
                fileCount++;
              } else if (entity is Directory) {
                directoryCount++;
              }
            } catch (e) {
              // Ignora errori di accesso
              continue;
            }
          }
        } catch (e) {
          // Ignora errori di accesso
        }
      }

      return DirectorySize(
        path: path,
        size: totalSize,
        fileCount: fileCount,
        directoryCount: directoryCount,
        children: children,
      );
    } catch (e) {
      return DirectorySize(
        path: path,
        size: 0,
        fileCount: 0,
        directoryCount: 0,
      );
    }
  }

  /// Rinomina un file o directory
  static Future<bool> renameItem(String oldPath, String newName) async {
    try {
      final dir = Directory(oldPath);
      final parent = dir.parent;
      final newPath = '${parent.path}/${newName}';
      
      if (await dir.exists()) {
        await dir.rename(newPath);
        return true;
      }
      
      final file = File(oldPath);
      if (await file.exists()) {
        await file.rename(newPath);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene informazioni dettagliate su un file o directory
  static Future<Map<String, dynamic>> getItemDetails(String path) async {
    final details = <String, dynamic>{};
    
    try {
      final entity = FileSystemEntity.typeSync(path);
      FileStat stat;
      if (entity == FileSystemEntityType.directory) {
        stat = await Directory(path).stat();
      } else if (entity == FileSystemEntityType.file) {
        stat = await File(path).stat();
      } else {
        return details;
      }
      
      details['path'] = path;
      details['name'] = path.split('/').last;
      details['size'] = stat.size;
      details['modified'] = stat.modified;
      details['accessed'] = stat.accessed;
      details['changed'] = stat.changed;
      details['type'] = entity == FileSystemEntityType.directory 
          ? 'directory' 
          : entity == FileSystemEntityType.file 
              ? 'file' 
              : 'unknown';
      
      if (entity == FileSystemEntityType.directory) {
        // Calcola dimensione totale della directory
        final size = await getDirectorySize(path);
        details['totalSize'] = size;
        
        // Conta file e directory
        int fileCount = 0;
        int dirCount = 0;
        try {
          await for (final item in Directory(path).list()) {
            if (item is File) {
              fileCount++;
            } else if (item is Directory) {
              dirCount++;
            }
          }
        } catch (e) {
          // Ignora errori
        }
        details['fileCount'] = fileCount;
        details['directoryCount'] = dirCount;
      } else if (entity == FileSystemEntityType.file) {
        // Determina tipo MIME
        final extension = path.split('.').last.toLowerCase();
        details['mimeType'] = _getMimeType(extension);
      }
      
      // Permessi
      try {
        final permissionsResult = await Process.run('bash', ['-c', 'stat -c "%a" "$path" 2>/dev/null']);
        if (permissionsResult.exitCode == 0) {
          details['permissions'] = (permissionsResult.stdout as String).trim();
        }
      } catch (e) {
        // Ignora errori
      }
      
      // Proprietario
      try {
        final ownerResult = await Process.run('bash', ['-c', 'stat -c "%U:%G" "$path" 2>/dev/null']);
        if (ownerResult.exitCode == 0) {
          final owner = (ownerResult.stdout as String).trim();
          final parts = owner.split(':');
          if (parts.length == 2) {
            details['owner'] = parts[0];
            details['group'] = parts[1];
          }
        }
      } catch (e) {
        // Ignora errori
      }
    } catch (e) {
      details['error'] = e.toString();
    }
    
    return details;
  }

  /// Sposta un file o directory nel cestino
  static Future<bool> moveToTrash(String path, {bool useSudo = false}) async {
    try {
      // Se richiesto sudo, elimina direttamente con rm -rf
      if (useSudo) {
        return await deleteWithSudo(path);
      }
      
      // Usa gio trash se disponibile (metodo preferito)
      final gioResult = await Process.run('which', ['gio']);
      if (gioResult.exitCode == 0) {
        final result = await Process.run('gio', ['trash', path]);
        return result.exitCode == 0;
      }
      
      // Fallback: sposta manualmente nel cestino
      final homeDir = Platform.environment['HOME'] ?? '';
      final trashDir = '$homeDir/.local/share/Trash';
      final filesDir = '$trashDir/files';
      final infoDir = '$trashDir/info';
      
      // Crea le directory se non esistono
      await Directory(filesDir).create(recursive: true);
      await Directory(infoDir).create(recursive: true);
      
      final fileName = path.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final trashPath = '$filesDir/${fileName}_$timestamp';
      
      // Sposta il file/directory
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.directory) {
        await Directory(path).rename(trashPath);
      } else {
        await File(path).rename(trashPath);
      }
      
      // Crea file info per il cestino
      final infoFile = File('$infoDir/${fileName}_$timestamp.trashinfo');
      await infoFile.writeAsString('''
[Trash Info]
Path=${Uri.encodeComponent(path)}
DeletionDate=${DateTime.now().toIso8601String()}
''');
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Elimina un file o directory con sudo usando rm -rf
  static Future<bool> deleteWithSudo(String path) async {
    try {
      // Verifica che il percorso esista
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.notFound) {
        return false;
      }
      
      // Usa sudo con rm -rf per eliminare definitivamente
      final escapedPath = path
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');
      
      final result = await _runSudoCommand('rm -rf "$escapedPath"');
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'etichetta di un disco montato
  static Future<String?> getDiskLabel(String mountPoint) async {
    try {
      // Prova con lsblk
      final lsblkResult = await Process.run(
        'bash',
        ['-c', 'lsblk -o LABEL,MOUNTPOINT -n | grep "$mountPoint\$" | head -1 | awk \'{print \\\$1}\''],
      );
      if (lsblkResult.exitCode == 0) {
        final label = (lsblkResult.stdout as String).trim();
        if (label.isNotEmpty && label != 'null') {
          return label;
        }
      }
      
      // Prova con findmnt
      final findmntResult = await Process.run(
        'bash',
        ['-c', 'findmnt -n -o LABEL "$mountPoint" 2>/dev/null'],
      );
      if (findmntResult.exitCode == 0) {
        final label = (findmntResult.stdout as String).trim();
        if (label.isNotEmpty && label != '-') {
          return label;
        }
      }
      
      // Prova con blkid
      try {
        final deviceResult = await Process.run(
          'bash',
          ['-c', 'findmnt -n -o SOURCE "$mountPoint" 2>/dev/null'],
        );
        if (deviceResult.exitCode == 0) {
          final device = (deviceResult.stdout as String).trim();
          if (device.isNotEmpty) {
            final blkidResult = await Process.run(
              'bash',
              ['-c', 'blkid -o value -s LABEL "$device" 2>/dev/null'],
            );
            if (blkidResult.exitCode == 0) {
              final label = (blkidResult.stdout as String).trim();
              if (label.isNotEmpty) {
                return label;
              }
            }
          }
        }
      } catch (e) {
        // Ignora errori
      }
    } catch (e) {
      // Ignora errori
    }
    return null;
  }

  /// Ottiene la lista dei dischi montati (inclusi esterni e USB)
  static Future<List<Map<String, String>>> getMountedDisks() async {
    try {
      final disks = <Map<String, String>>[];
      
      // Lista dei mount point di sistema da escludere
      final systemMountPoints = {
        '/',
        '/boot',
        '/boot/efi',
        '/sys',
        '/proc',
        '/dev',
        '/run',
        '/tmp',
        '/var',
        '/usr',
        '/opt',
        '/srv',
        '/home',
      };
      
      // Usa lsblk per identificare meglio i dispositivi USB
      try {
        final lsblkResult = await Process.run(
          'bash',
          ['-c', 'lsblk -o NAME,TYPE,MOUNTPOINT,SIZE,LABEL -n -b 2>/dev/null'],
        ).timeout(const Duration(seconds: 3), onTimeout: () => ProcessResult(1, -1, '', ''));
        
        if (lsblkResult.exitCode == 0) {
          final lsblkOutput = lsblkResult.stdout.toString();
          final lines = lsblkOutput.split('\n').where((line) => line.trim().isNotEmpty).toList();
          
          // Cerca dispositivi USB (hanno TYPE=disk o part e MOUNTPOINT)
          for (final line in lines) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              final deviceName = parts[0];
              final mountPoint = parts.length > 2 ? parts[2] : '';
              
              // Se ha un mount point e non è un dispositivo di sistema
              if (mountPoint.isNotEmpty && 
                  mountPoint != '-' && 
                  !systemMountPoints.contains(mountPoint) &&
                  !mountPoint.startsWith('/boot') &&
                  !mountPoint.startsWith('/sys') &&
                  !mountPoint.startsWith('/proc') &&
                  !mountPoint.startsWith('/dev') &&
                  !mountPoint.startsWith('/run/user')) {
                
                // Verifica se è USB usando udev o lsblk
                final isUsb = await _isUsbDevice('/dev/$deviceName');
                
                // Ottieni informazioni con df
                try {
                  final dfResult = await Process.run(
                    'bash',
                    ['-c', 'df -h "$mountPoint" 2>/dev/null | tail -1'],
                  ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
                  
                  if (dfResult.exitCode == 0) {
                    final dfOutput = dfResult.stdout.toString().trim();
                    final dfParts = dfOutput.split(RegExp(r'\s+'));
                    if (dfParts.length >= 6) {
                      final device = dfParts[0];
                      final size = dfParts[1];
                      final used = dfParts[2];
                      final available = dfParts[3];
                      
                      // Determina se è esterno/USB
                      final isExternal = isUsb || 
                                       mountPoint.startsWith('/media/') ||
                                       mountPoint.startsWith('/mnt/') ||
                                       mountPoint.startsWith('/run/media/');
                      
                      // Evita duplicati
                      final alreadyAdded = disks.any((d) => d['mountPoint'] == mountPoint);
                      if (!alreadyAdded) {
                        final label = parts.length > 4 && parts[4] != '-' 
                            ? parts[4] 
                            : await getDiskLabel(mountPoint);
                        final displayLabel = label ?? mountPoint.split('/').last;
                        
                        // Filtra dischi con label solo numeriche
                        final isNumericOnly = RegExp(r'^\d+$').hasMatch(displayLabel);
                        
                        // Mostra solo se è USB/esterno verificato o ha label significativa
                        if (isExternal && (isUsb || !isNumericOnly)) {
                          disks.add({
                            'device': device,
                            'mountPoint': mountPoint,
                            'size': size,
                            'used': used,
                            'available': available,
                            'isExternal': isExternal.toString(),
                            'label': displayLabel,
                          });
                        }
                      }
                    }
                  }
                } catch (e) {
                  // Ignora errori
                }
              }
            }
          }
        }
      } catch (e) {
        // Se lsblk fallisce, usa il metodo tradizionale
      }
      
      // Metodo tradizionale con df -h come fallback
      try {
        final result = await Process.run(
          'bash', 
          ['-c', "df -h | grep -E '^/dev/' | awk '{print \\\$1 \"|\" \\\$6 \"|\" \\\$2 \"|\" \\\$3 \"|\" \\\$4}'"],
        ).timeout(const Duration(seconds: 2), onTimeout: () => ProcessResult(1, -1, '', ''));
        
        final output = result.stdout.toString();
        final lines = output.split('\n').where((line) => line.isNotEmpty).toList();
        
        for (final line in lines) {
          final parts = line.split('|');
          if (parts.length >= 5) {
            final device = parts[0].trim();
            final mountPoint = parts[1].trim();
            final size = parts[2].trim();
            final used = parts[3].trim();
            final available = parts[4].trim();

            // Escludi dispositivi virtuali
            if (device.contains('tmpfs') || 
                device.contains('devtmpfs') ||
                device.contains('sysfs') ||
                device.contains('proc') ||
                device.contains('udev')) {
              continue;
            }

            // Determina se è un disco esterno/USB
            final isSystemMount = systemMountPoints.contains(mountPoint) ||
                                 mountPoint.startsWith('/boot') ||
                                 mountPoint.startsWith('/sys') ||
                                 mountPoint.startsWith('/proc') ||
                                 mountPoint.startsWith('/dev') ||
                                 (mountPoint.startsWith('/run') && !mountPoint.startsWith('/run/media'));

            // Verifica se è USB
            final isUsb = await _isUsbDevice(device);
            
            // Determina se è esterno/USB basandosi su:
            // 1. Mount point tipici per USB/esterni
            // 2. Verifica hardware USB
            // 3. Dispositivi non-sda (dischi aggiuntivi)
            final isExternal = !isSystemMount && (
              mountPoint.startsWith('/media/') ||
              mountPoint.startsWith('/mnt/') ||
              mountPoint.startsWith('/run/media/') ||
              isUsb ||
              // Dischi aggiuntivi (non il disco principale sda)
              (device.startsWith('/dev/sd') && 
               !device.startsWith('/dev/sda') && 
               !device.contains('sda') &&
               !mountPoint.startsWith('/')) ||
              // NVMe aggiuntivi (non montati su /)
              (device.startsWith('/dev/nvme') && 
               !mountPoint.startsWith('/') && 
               mountPoint != '/' &&
               !isSystemMount)
            );

            // Aggiungi solo se:
            // 1. È un disco USB/esterno (sempre mostrato)
            // 2. È un disco interno aggiuntivo montato manualmente (es. in /mnt)
            // NON aggiungere partizioni del disco principale montate in posizioni di sistema
            final shouldAdd = isExternal || 
                            (!isSystemMount && 
                             (mountPoint.startsWith('/mnt/') || 
                              mountPoint.startsWith('/media/') ||
                              mountPoint.startsWith('/run/media/')));
            
            if (shouldAdd) {
              // Evita duplicati
              final alreadyAdded = disks.any((d) => d['mountPoint'] == mountPoint);
              if (!alreadyAdded) {
                final label = await getDiskLabel(mountPoint);
                final displayLabel = label ?? mountPoint.split('/').last;
                
                // Filtra dischi con label solo numeriche o non significative
                // Escludi se la label è solo numeri (probabilmente una partizione non rilevante)
                final isNumericOnly = RegExp(r'^\d+$').hasMatch(displayLabel);
                
                // Mostra solo se:
                // 1. È USB/esterno verificato (sempre mostrato)
                // 2. Ha una label significativa (non solo numeri)
                // 3. È montato in una posizione specifica per dischi esterni
                if (isExternal && (isUsb || !isNumericOnly || 
                    mountPoint.startsWith('/media/') || 
                    mountPoint.startsWith('/mnt/') || 
                    mountPoint.startsWith('/run/media/'))) {
                  disks.add({
                    'device': device,
                    'mountPoint': mountPoint,
                    'size': size,
                    'used': used,
                    'available': available,
                    'isExternal': isExternal.toString(),
                    'label': displayLabel,
                  });
                } else if (!isExternal && !isNumericOnly) {
                  // Per dischi interni, mostra solo se hanno label significative
                  disks.add({
                    'device': device,
                    'mountPoint': mountPoint,
                    'size': size,
                    'used': used,
                    'available': available,
                    'isExternal': isExternal.toString(),
                    'label': displayLabel,
                  });
                }
              }
            }
          }
        }
      } catch (e) {
        // Ignora errori
      }
      
      // Aggiungi anche i dischi montati in /mnt e /run/media (USB)
      await _addDisksFromDirectory('/mnt', disks, systemMountPoints);
      await _addDisksFromDirectory('/run/media', disks, systemMountPoints);
      
      // Aggiungi dischi da /media (USB tradizionale)
      try {
        final mediaDir = Directory('/media');
        if (await mediaDir.exists()) {
          await for (final userDir in mediaDir.list()) {
            if (userDir is Directory) {
              await _addDisksFromDirectory(userDir.path, disks, systemMountPoints);
            }
          }
        }
      } catch (e) {
        // Ignora errori
      }

      return disks;
    } catch (e) {
      return [];
    }
  }

  /// Verifica se un dispositivo è USB
  static Future<bool> _isUsbDevice(String device) async {
    try {
      // Rimuovi partizioni (es. /dev/sdb1 -> /dev/sdb)
      String baseDevice = device;
      if (RegExp(r'[0-9]+$').hasMatch(device)) {
        baseDevice = device.replaceAll(RegExp(r'[0-9]+$'), '');
      }
      
      // Verifica con udevadm
      final udevResult = await Process.run(
        'bash',
        ['-c', 'udevadm info --query=property --name=$baseDevice 2>/dev/null | grep -i "ID_BUS=usb"'],
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      
      if (udevResult.exitCode == 0 && udevResult.stdout.toString().trim().isNotEmpty) {
        return true;
      }
      
      // Verifica con lsblk
      final lsblkResult = await Process.run(
        'bash',
        ['-c', 'lsblk -o NAME,TYPE,TRAN -n 2>/dev/null | grep "^${baseDevice.split("/").last}"'],
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      
      if (lsblkResult.exitCode == 0) {
        final output = lsblkResult.stdout.toString();
        if (output.contains('usb')) {
          return true;
        }
      }
    } catch (e) {
      // Ignora errori
    }
    return false;
  }

  /// Aggiunge dischi da una directory (es. /mnt, /run/media)
  static Future<void> _addDisksFromDirectory(
    String dirPath,
    List<Map<String, String>> disks,
    Set<String> systemMountPoints,
  ) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;
      
      await for (final entity in dir.list()) {
        if (entity is Directory) {
          final mountPoint = entity.path;
          
          // Salta se è un mount point di sistema
          if (systemMountPoints.contains(mountPoint)) continue;
          
          // Verifica se è un mount point usando findmnt
          try {
            final findmntResult = await Process.run(
              'bash',
              ['-c', 'findmnt -n -o SOURCE,TARGET,SIZE,USED,AVAIL "$mountPoint" 2>/dev/null'],
            ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
            
            if (findmntResult.exitCode == 0) {
              final findmntOutput = findmntResult.stdout.toString().trim();
              if (findmntOutput.isNotEmpty) {
                final parts = findmntOutput.split(RegExp(r'\s+'));
                if (parts.length >= 5) {
                  // Evita duplicati
                  final alreadyAdded = disks.any((d) => d['mountPoint'] == mountPoint);
                  if (!alreadyAdded) {
                    final device = parts[0];
                    final label = await getDiskLabel(mountPoint);
                    final displayLabel = label ?? mountPoint.split('/').last;
                    
                    // Filtra dischi con label solo numeriche
                    final isNumericOnly = RegExp(r'^\d+$').hasMatch(displayLabel);
                    
                    // Mostra solo se ha label significativa (non solo numeri)
                    if (!isNumericOnly) {
                      disks.add({
                        'device': device,
                        'mountPoint': mountPoint,
                        'size': parts[2],
                        'used': parts[3],
                        'available': parts[4],
                        'isExternal': 'true',
                        'label': displayLabel,
                      });
                    }
                  }
                }
              }
            }
          } catch (e) {
            // Se findmnt fallisce, prova con df
            try {
              final dfResult = await Process.run(
                'bash',
                ['-c', 'df -h "$mountPoint" 2>/dev/null | tail -1'],
              ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
              
              if (dfResult.exitCode == 0) {
                final dfOutput = dfResult.stdout.toString().trim();
                final dfParts = dfOutput.split(RegExp(r'\s+'));
                if (dfParts.length >= 6) {
                  // Evita duplicati
                  final alreadyAdded = disks.any((d) => d['mountPoint'] == mountPoint);
                  if (!alreadyAdded) {
                    final device = dfParts[0];
                    final label = await getDiskLabel(mountPoint);
                    final displayLabel = label ?? mountPoint.split('/').last;
                    
                    // Filtra dischi con label solo numeriche
                    final isNumericOnly = RegExp(r'^\d+$').hasMatch(displayLabel);
                    
                    // Mostra solo se ha label significativa (non solo numeri)
                    if (!isNumericOnly) {
                      disks.add({
                        'device': device,
                        'mountPoint': mountPoint,
                        'size': dfParts[1],
                        'used': dfParts[2],
                        'available': dfParts[3],
                        'isExternal': 'true',
                        'label': displayLabel,
                      });
                    }
                  }
                }
              }
            } catch (e) {
              // Ignora errori
            }
          }
        }
      }
    } catch (e) {
      // Ignora errori
    }
  }

  /// Ottiene metadati per file audio, video, PDF, Office
  static Future<Map<String, dynamic>> getFileMetadata(String path, String? mimeType) async {
    final metadata = <String, dynamic>{};
    
    if (mimeType == null) return metadata;

    try {
      if (mimeType.startsWith('audio/')) {
        // Prova con ffprobe per audio
        try {
          final result = await Process.run('bash', [
            '-c',
            'ffprobe -v quiet -print_format json -show_format -show_streams "$path" 2>/dev/null'
          ]).timeout(const Duration(seconds: 5));
          
          if (result.exitCode == 0) {
            final output = result.stdout as String;
            // Estrai informazioni base (semplificato, senza parsing JSON completo)
            if (output.contains('"duration"')) {
              final durationMatch = RegExp(r'"duration"\s*:\s*"([^"]+)"').firstMatch(output);
              if (durationMatch != null) {
                final duration = double.tryParse(durationMatch.group(1) ?? '0') ?? 0;
                metadata['duration'] = _formatDuration(duration);
              }
            }
            if (output.contains('"bit_rate"')) {
              final bitrateMatch = RegExp(r'"bit_rate"\s*:\s*"([^"]+)"').firstMatch(output);
              if (bitrateMatch != null) {
                final bitrate = int.tryParse(bitrateMatch.group(1) ?? '0') ?? 0;
                metadata['bitrate'] = '${(bitrate / 1000).toStringAsFixed(0)} kbps';
              }
            }
            if (output.contains('"TAG:title"')) {
              final titleMatch = RegExp(r'"TAG:title"\s*:\s*"([^"]+)"').firstMatch(output);
              if (titleMatch != null) {
                metadata['title'] = titleMatch.group(1);
              }
            }
            if (output.contains('"TAG:artist"')) {
              final artistMatch = RegExp(r'"TAG:artist"\s*:\s*"([^"]+)"').firstMatch(output);
              if (artistMatch != null) {
                metadata['artist'] = artistMatch.group(1);
              }
            }
          }
        } catch (e) {
          // Ignora errori
        }
      } else if (mimeType.startsWith('video/')) {
        // Prova con ffprobe per video
        try {
          final result = await Process.run('bash', [
            '-c',
            'ffprobe -v quiet -print_format json -show_format -show_streams "$path" 2>/dev/null'
          ]).timeout(const Duration(seconds: 5));
          
          if (result.exitCode == 0) {
            final output = result.stdout as String;
            if (output.contains('"duration"')) {
              final durationMatch = RegExp(r'"duration"\s*:\s*"([^"]+)"').firstMatch(output);
              if (durationMatch != null) {
                final duration = double.tryParse(durationMatch.group(1) ?? '0') ?? 0;
                metadata['duration'] = _formatDuration(duration);
              }
            }
            if (output.contains('"width"') && output.contains('"height"')) {
              final widthMatch = RegExp(r'"width"\s*:\s*(\d+)').firstMatch(output);
              final heightMatch = RegExp(r'"height"\s*:\s*(\d+)').firstMatch(output);
              if (widthMatch != null && heightMatch != null) {
                metadata['resolution'] = '${widthMatch.group(1)}x${heightMatch.group(1)}';
              }
            }
            if (output.contains('"codec_name"')) {
              final codecMatch = RegExp(r'"codec_name"\s*:\s*"([^"]+)"').firstMatch(output);
              if (codecMatch != null) {
                metadata['codec'] = codecMatch.group(1);
              }
            }
            if (output.contains('"bit_rate"')) {
              final bitrateMatch = RegExp(r'"bit_rate"\s*:\s*"([^"]+)"').firstMatch(output);
              if (bitrateMatch != null) {
                final bitrate = int.tryParse(bitrateMatch.group(1) ?? '0') ?? 0;
                metadata['bitrate'] = '${(bitrate / 1000).toStringAsFixed(0)} kbps';
              }
            }
          }
        } catch (e) {
          // Ignora errori
        }
      } else if (mimeType == 'application/pdf') {
        // Prova con pdfinfo per PDF
        try {
          final result = await Process.run('bash', [
            '-c',
            'pdfinfo "$path" 2>/dev/null | grep Pages'
          ]).timeout(const Duration(seconds: 3));
          
          if (result.exitCode == 0) {
            final output = result.stdout as String;
            final pagesMatch = RegExp(r'Pages:\s*(\d+)').firstMatch(output);
            if (pagesMatch != null) {
              metadata['pages'] = pagesMatch.group(1);
            }
          }
        } catch (e) {
          // Ignora errori
        }
      }
    } catch (e) {
      // Ignora errori
    }
    
    return metadata;
  }

  static String _formatDuration(double seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final secs = (seconds % 60).floor();
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  /// Genera un'anteprima per un file (PDF, Office, immagini)
  static Future<String?> generateThumbnail(String path, String? mimeType) async {
    try {
      final homeDir = Platform.environment['HOME'] ?? '';
      final thumbnailsDir = '$homeDir/.cache/thumbnails';
      final normalDir = '$thumbnailsDir/normal';
      final largeDir = '$thumbnailsDir/large';
      
      // Crea le directory se non esistono
      await Directory(normalDir).create(recursive: true);
      await Directory(largeDir).create(recursive: true);
      
      // Calcola hash del file per il nome thumbnail (stile GNOME)
      final hashResult = await Process.run('bash', [
        '-c',
        'echo -n "file://$path" | md5sum | cut -d" " -f1'
      ]);
      
      if (hashResult.exitCode != 0) return null;
      final hash = (hashResult.stdout as String).trim();
      final thumbnailPath = '$largeDir/${hash}.png';
      
      // Controlla se esiste già
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }
      
      // Genera thumbnail in base al tipo
      if (mimeType == 'application/pdf') {
        // Usa pdftoppm o convert per PDF
        try {
          // Prova con pdftoppm (poppler-utils)
          final result = await Process.run('bash', [
            '-c',
            'pdftoppm -png -f 1 -l 1 -scale-to 512 "$path" "$largeDir/${hash}" 2>/dev/null'
          ]).timeout(const Duration(seconds: 5));
          
          if (result.exitCode == 0) {
            final generatedFile = File('$largeDir/${hash}-1.png');
            if (await generatedFile.exists()) {
              await generatedFile.rename(thumbnailPath);
              return thumbnailPath;
            }
          }
        } catch (e) {
          // Prova con convert (ImageMagick)
          try {
            final result = await Process.run('bash', [
              '-c',
              'convert "$path[0]" -thumbnail 512x512 "$thumbnailPath" 2>/dev/null'
            ]).timeout(const Duration(seconds: 5));
            
            if (result.exitCode == 0 && await thumbnailFile.exists()) {
              return thumbnailPath;
            }
          } catch (e) {
            // Ignora errori
          }
        }
      } else if (mimeType != null && (
        mimeType.contains('word') ||
        mimeType.contains('excel') ||
        mimeType.contains('powerpoint') ||
        mimeType.contains('spreadsheet') ||
        mimeType.contains('presentation') ||
        mimeType.contains('msword') ||
        mimeType.contains('vnd.ms-excel') ||
        mimeType.contains('vnd.ms-powerpoint')
      )) {
        // Usa LibreOffice per convertire Office in PDF, poi in immagine
        try {
          final tempPdf = '$largeDir/${hash}_temp.pdf';
          final fileName = path.split('/').last;
          final baseName = fileName.contains('.') 
              ? fileName.substring(0, fileName.lastIndexOf('.'))
              : fileName;
          final expectedPdf = '$largeDir/$baseName.pdf';
          
          final result = await Process.run('bash', [
            '-c',
            'libreoffice --headless --convert-to pdf --outdir "$largeDir" "$path" 2>/dev/null'
          ]).timeout(const Duration(seconds: 10));
          
          if (result.exitCode == 0) {
            final expectedPdfFile = File(expectedPdf);
            if (await expectedPdfFile.exists()) {
              await expectedPdfFile.rename(tempPdf);
            }
          }
          
          if (result.exitCode == 0) {
            final tempPdfFile = File(tempPdf);
            if (await tempPdfFile.exists()) {
              // Converti PDF in immagine
              try {
                await Process.run('bash', [
                  '-c',
                  'pdftoppm -png -f 1 -l 1 -scale-to 512 "$tempPdf" "$largeDir/${hash}" 2>/dev/null || convert "$tempPdf[0]" -thumbnail 512x512 "$thumbnailPath" 2>/dev/null'
                ]).timeout(const Duration(seconds: 5));
                
                final generatedFile = File('$largeDir/${hash}-1.png');
                if (await generatedFile.exists()) {
                  await generatedFile.rename(thumbnailPath);
                } else if (await thumbnailFile.exists()) {
                  // Già creato da convert
                }
                
                // Rimuovi PDF temporaneo
                await tempPdfFile.delete();
                
                if (await thumbnailFile.exists()) {
                  return thumbnailPath;
                }
              } catch (e) {
                // Rimuovi PDF temporaneo anche in caso di errore
                try {
                  await File(tempPdf).delete();
                } catch (e) {
                  // Ignora
                }
              }
            }
          }
        } catch (e) {
          // Ignora errori
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Formatta la dimensione in formato leggibile
  /// Converte bytes in formato umano (supporta fino a 100TB)
  static String formatSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else {
      // Supporta fino a 100TB
      final tb = bytes / (1024 * 1024 * 1024 * 1024);
      if (tb >= 100) {
        return '${tb.toStringAsFixed(2)} TB';
      }
      return '${tb.toStringAsFixed(2)} TB';
    }
  }

  /// Ottiene il percorso home dell'utente
  static String getHomePath() {
    return Platform.environment['HOME'] ?? '/home/${Platform.environment['USER'] ?? 'user'}';
  }

  /// Ottiene il percorso root
  static String getRootPath() {
    return '/';
  }
}
