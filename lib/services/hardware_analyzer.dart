import 'dart:io';

/// Servizio per analizzare la configurazione hardware del sistema
/// Utilizzato per generare suggerimenti GRUB ottimizzati
class HardwareAnalyzer {
  /// Informazioni sull'hardware raccolte
  static Map<String, dynamic>? _cachedHardwareInfo;
  static DateTime? _cacheTime;

  /// Analizza l'hardware del sistema
  static Future<Map<String, dynamic>> analyzeHardware({bool forceRefresh = false}) async {
    // Usa cache se disponibile e non troppo vecchia (5 minuti)
    if (!forceRefresh && _cachedHardwareInfo != null && _cacheTime != null) {
      final cacheAge = DateTime.now().difference(_cacheTime!);
      if (cacheAge.inMinutes < 5) {
        return _cachedHardwareInfo!;
      }
    }

    final hardwareInfo = <String, dynamic>{};

    try {
      // CPU Info
      final cpuInfo = await _getCpuInfo();
      hardwareInfo['cpu'] = cpuInfo;

      // RAM Info
      final ramInfo = await _getRamInfo();
      hardwareInfo['ram'] = ramInfo;

      // GPU Info
      final gpuInfo = await _getGpuInfo();
      hardwareInfo['gpu'] = gpuInfo;

      // Disco Info
      final diskInfo = await _getDiskInfo();
      hardwareInfo['disk'] = diskInfo;

      // UEFI/BIOS Info
      final firmwareInfo = await _getFirmwareInfo();
      hardwareInfo['firmware'] = firmwareInfo;

      // Aggiorna cache
      _cachedHardwareInfo = hardwareInfo;
      _cacheTime = DateTime.now();

      return hardwareInfo;
    } catch (e) {
      print('Errore durante l\'analisi hardware: $e');
      return hardwareInfo;
    }
  }

  /// Ottiene informazioni sulla CPU
  static Future<Map<String, dynamic>> _getCpuInfo() async {
    final info = <String, dynamic>{};

    try {
      // Modello CPU
      final cpuModelResult = await Process.run('lscpu', []);
      if (cpuModelResult.exitCode == 0) {
        final output = cpuModelResult.stdout.toString();
        final lines = output.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('Model name:')) {
            info['model'] = line.substring('Model name:'.length).trim();
          } else if (line.startsWith('CPU(s):')) {
            final cores = int.tryParse(line.substring('CPU(s):'.length).trim());
            if (cores != null) info['cores'] = cores;
          } else if (line.startsWith('Thread(s) per core:')) {
            final threads = int.tryParse(line.substring('Thread(s) per core:'.length).trim());
            if (threads != null) info['threads_per_core'] = threads;
          } else if (line.startsWith('Architecture:')) {
            info['arch'] = line.substring('Architecture:'.length).trim();
          } else if (line.startsWith('Flags:')) {
            info['flags'] = line.substring('Flags:'.length).trim();
          }
        }
      }

      // Fallback: /proc/cpuinfo
      if (info['model'] == null) {
        final cpuinfoFile = File('/proc/cpuinfo');
        if (await cpuinfoFile.exists()) {
          final content = await cpuinfoFile.readAsString();
          final lines = content.split('\n');
          for (final line in lines) {
            if (line.startsWith('model name')) {
              info['model'] = line.split(':').length > 1 
                  ? line.split(':')[1].trim() 
                  : null;
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Errore nel recupero info CPU: $e');
    }

    return info;
  }

  /// Ottiene informazioni sulla RAM
  static Future<Map<String, dynamic>> _getRamInfo() async {
    final info = <String, dynamic>{};

    try {
      final meminfoFile = File('/proc/meminfo');
      if (await meminfoFile.exists()) {
        final content = await meminfoFile.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('MemTotal:')) {
            final kb = int.tryParse(line.split(RegExp(r'\s+'))[1]);
            if (kb != null) info['total_kb'] = kb;
          } else if (line.startsWith('MemAvailable:')) {
            final kb = int.tryParse(line.split(RegExp(r'\s+'))[1]);
            if (kb != null) info['available_kb'] = kb;
          }
        }
      }
    } catch (e) {
      print('Errore nel recupero info RAM: $e');
    }

    return info;
  }

  /// Ottiene informazioni sulla GPU
  static Future<Map<String, dynamic>> _getGpuInfo() async {
    final info = <String, dynamic>{};

    try {
      // Prova lspci per GPU
      final lspciResult = await Process.run('lspci', ['-nn']);
      if (lspciResult.exitCode == 0) {
        final output = lspciResult.stdout.toString();
        final lines = output.split('\n');
        
        for (final line in lines) {
          if (line.contains('VGA') || line.contains('3D') || line.contains('Display')) {
            info['model'] = line;
            // Estrai il vendor
            if (line.contains('NVIDIA')) {
              info['vendor'] = 'nvidia';
            } else if (line.contains('AMD') || line.contains('ATI')) {
              info['vendor'] = 'amd';
            } else if (line.contains('Intel')) {
              info['vendor'] = 'intel';
            }
            break;
          }
        }
      }

      // Verifica se NVIDIA è presente
      final nvidiaResult = await Process.run('nvidia-smi', ['--query-gpu=name', '--format=csv,noheader']);
      if (nvidiaResult.exitCode == 0) {
        info['model'] = nvidiaResult.stdout.toString().trim();
        info['vendor'] = 'nvidia';
        info['has_nvidia'] = true;
      }
    } catch (e) {
      // Ignora errori
    }

    return info;
  }

  /// Ottiene informazioni sul disco
  static Future<Map<String, dynamic>> _getDiskInfo() async {
    final info = <String, dynamic>{};

    try {
      final lsblkResult = await Process.run('lsblk', ['-d', '-o', 'NAME,SIZE,TYPE']);
      if (lsblkResult.exitCode == 0) {
        final output = lsblkResult.stdout.toString();
        final lines = output.split('\n');
        
        final disks = <String>[];
        for (final line in lines.skip(1)) {
          if (line.trim().isNotEmpty) {
            final parts = line.trim().split(RegExp(r'\s+'));
            if (parts.length >= 2 && parts[1] == 'disk') {
              disks.add(parts[0]);
            }
          }
        }
        info['disks'] = disks;
        info['disk_count'] = disks.length;
      }
    } catch (e) {
      print('Errore nel recupero info disco: $e');
    }

    return info;
  }

  /// Ottiene informazioni sul firmware (UEFI/BIOS)
  static Future<Map<String, dynamic>> _getFirmwareInfo() async {
    final info = <String, dynamic>{};

    try {
      // Verifica se è UEFI
      final efiDir = Directory('/sys/firmware/efi');
      if (await efiDir.exists()) {
        info['is_uefi'] = true;
        info['firmware_type'] = 'UEFI';
      } else {
        info['is_uefi'] = false;
        info['firmware_type'] = 'BIOS';
      }

      // Verifica Secure Boot
      if (info['is_uefi'] == true) {
        try {
          final mokutilResult = await Process.run('mokutil', ['--sb-state']);
          if (mokutilResult.exitCode == 0) {
            final output = mokutilResult.stdout.toString();
            info['secure_boot'] = output.contains('enabled');
          }
        } catch (e) {
          // mokutil non disponibile, prova a verificare direttamente
          try {
            final efiVarsDir = Directory('/sys/firmware/efi/efivars');
            if (await efiVarsDir.exists()) {
              // Cerca file SecureBoot
              await for (final entity in efiVarsDir.list()) {
                if (entity.path.contains('SecureBoot')) {
                  info['secure_boot'] = true;
                  break;
                }
              }
            }
          } catch (e2) {
            // Ignora errori
          }
        }
      }
    } catch (e) {
      // Ignora errori
    }

    return info;
  }

  /// Invalida la cache
  static void invalidateCache() {
    _cachedHardwareInfo = null;
    _cacheTime = null;
  }
}

