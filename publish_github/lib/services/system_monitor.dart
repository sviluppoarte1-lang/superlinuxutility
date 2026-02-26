import 'dart:io';
import '../models/system_process.dart';
import '../models/system_info.dart';
import 'password_storage.dart';

class SystemMonitor {
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

  static Future<List<SystemProcess>> getProcesses() async {
    try {
      final result = await Process.run(
        'ps',
        ['aux'],
      );

      if (result.exitCode != 0) {
        return [];
      }

      return _parsePsOutput(result.stdout as String);
    } catch (e) {
      return [];
    }
  }

  static List<SystemProcess> _parsePsOutput(String output) {
    final processes = <SystemProcess>[];
    final lines = output.split('\n');

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 11) {
        try {
          final user = parts[0];
          final pid = int.parse(parts[1]);
          final cpuPercent = double.tryParse(parts[2]) ?? 0.0;
          final rss = int.tryParse(parts[5]) ?? 0;
          final stat = parts[7];
          
          final command = parts.sublist(10).join(' ');
          String name;
          if (command.startsWith('[') && command.endsWith(']')) {
            name = command.substring(1, command.length - 1);
            if (name.contains('/')) {
              name = name.split('/')[0];
            }
          } else {
            final firstPart = parts[10];
            if (firstPart.contains('/')) {
              name = firstPart.split('/').last;
            } else {
              name = firstPart;
            }
            name = name.split(' ')[0];
            name = name.split('\n')[0];
          }
          
          if (name.length <= 2 || RegExp(r'^\d+$').hasMatch(name)) {
            if (command.length > 30) {
              name = '${command.substring(0, 30)}...';
            } else {
              name = command;
            }
          }

          final memoryBytes = rss * 1024;

          processes.add(SystemProcess(
            pid: pid,
            name: name,
            user: user,
            cpuPercent: cpuPercent,
            memoryBytes: memoryBytes,
            command: command,
            state: stat,
          ));
        } catch (e) {
          continue;
        }
      }
    }

    processes.sort((a, b) => b.cpuPercent.compareTo(a.cpuPercent));

    return processes;
  }

  static Future<bool> killProcess(int pid, {bool force = false}) async {
    try {
      final signal = force ? '-9' : '-15';
      final result = await _runSudoCommand('kill $signal $pid');
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static Future<double?> getCpuTemperature() async {
    try {
      final zone = Directory('/sys/class/thermal');
      if (await zone.exists()) {
        double? pkgTemp;
        final zones = await zone.list().toList();
        for (final entity in zones) {
          if (entity is! Directory || !entity.path.contains('thermal_zone')) continue;
          try {
            final typeFile = File('${entity.path}/type');
            if (await typeFile.exists()) {
              final type = (await typeFile.readAsString()).trim();
              if (type == 'x86_pkg_temp') {
                final tempFile = File('${entity.path}/temp');
                if (await tempFile.exists()) {
                  final s = await tempFile.readAsString();
                  final millideg = int.tryParse(s.trim());
                  if (millideg != null) return millideg / 1000.0;
                }
              }
            }
          } catch (_) {}
        }
        for (final entity in zones) {
          if (entity is! Directory || !entity.path.contains('thermal_zone')) continue;
          try {
            final tempFile = File('${entity.path}/temp');
            if (await tempFile.exists()) {
              final s = await tempFile.readAsString();
              final millideg = int.tryParse(s.trim());
              if (millideg != null && millideg > 0 && millideg < 150000) {
                return millideg / 1000.0;
              }
            }
          } catch (_) {}
        }
      }
      final sensorsPatterns = [
        r"sensors 2>/dev/null | grep -iE 'Package id 0|Tctl|Tccd1|k10temp-pci' | head -3 | grep -oE '\+[0-9]+\.[0-9]+°C' | grep -oE '[0-9.]+' | head -1",
        r"sensors 2>/dev/null | grep -iE 'Core 0|CPU Temp|temp1:' | head -3 | grep -oE '\+[0-9]+\.[0-9]+°C' | grep -oE '[0-9.]+' | head -1",
        r"sensors 2>/dev/null | grep -oE '\+[0-9]+\.[0-9]+°C' | grep -oE '[0-9.]+' | head -1",
      ];
      for (final pattern in sensorsPatterns) {
        try {
          final result = await Process.run('bash', ['-c', pattern]);
          if (result.exitCode == 0) {
            final out = (result.stdout as String).trim();
            if (out.isNotEmpty) {
              final t = double.tryParse(out.split('\n').first);
              if (t != null && t > 0 && t < 150) return t;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  static Future<SystemInfo> getSystemInfo() async {
    final results = await Future.wait([
      _getCpuInfo(),
      _getMemoryInfo(),
      _getDiskInfo(),
      _getGpuInfo(),
    ]);
    return SystemInfo(
      cpu: results[0] as CpuInfo,
      memory: results[1] as MemoryInfo,
      disks: results[2] as List<DiskInfo>,
      gpu: results[3] as GpuInfo?,
    );
  }

  static Future<CpuInfo> _getCpuInfo() async {
    try {
      final modelResult = await Process.run('bash', ['-c', r'lscpu | grep "Model name" | cut -d: -f2 | xargs']);
      final modelOutput = (modelResult.stdout as String).trim();
      final model = modelOutput.isEmpty ? 'Unknown' : modelOutput;

      final coresResult = await Process.run('bash', ['-c', 'nproc']);
      final cores = int.tryParse((coresResult.stdout as String).trim()) ?? 1;

      final threadsResult = await Process.run('bash', ['-c', r'lscpu | grep "Thread(s) per core" | cut -d: -f2 | xargs']);
      final threadsPerCore = int.tryParse((threadsResult.stdout as String).trim()) ?? 1;
      final threads = cores * threadsPerCore;

      double cpuUsage = 0.0;
      try {
        final stat1 = await File('/proc/stat').readAsString();
        await Future.delayed(const Duration(milliseconds: 100));
        final stat2 = await File('/proc/stat').readAsString();
        
        final lines1 = stat1.split('\n');
        final lines2 = stat2.split('\n');
        
        if (lines1.isNotEmpty && lines2.isNotEmpty) {
          final cpu1 = lines1[0].split(RegExp(r'\s+'));
          final cpu2 = lines2[0].split(RegExp(r'\s+'));
          
          if (cpu1.length >= 8 && cpu2.length >= 8) {
            final idle1 = int.tryParse(cpu1[4]) ?? 0;
            final idle2 = int.tryParse(cpu2[4]) ?? 0;
            
            int total1 = 0;
            int total2 = 0;
            for (var i = 1; i < cpu1.length && i < 8; i++) {
              total1 += int.tryParse(cpu1[i]) ?? 0;
            }
            for (var i = 1; i < cpu2.length && i < 8; i++) {
              total2 += int.tryParse(cpu2[i]) ?? 0;
            }
            
            final totalDiff = total2 - total1;
            final idleDiff = idle2 - idle1;
            
            if (totalDiff > 0) {
              cpuUsage = ((totalDiff - idleDiff) / totalDiff) * 100;
            }
          }
        }
      } catch (e) {
        cpuUsage = 0.0;
      }
      final coreUsage = <double>[];
      try {
        final mpstatResult = await Process.run('bash', ['-c', r"mpstat -P ALL 1 1 2>/dev/null | tail -n +4 | awk '{print $3}'"]);
        if (mpstatResult.exitCode == 0) {
          final lines = (mpstatResult.stdout as String).split('\n');
          for (final line in lines) {
            final usage = double.tryParse(line.trim());
            if (usage != null) {
              coreUsage.add(100 - usage);
            }
          }
        }
      } catch (e) {}

      return CpuInfo(
        model: model,
        cores: cores,
        threads: threads,
        usagePercent: cpuUsage,
        coreUsage: coreUsage,
      );
    } catch (e) {
      return CpuInfo(
        model: 'Unknown',
        cores: 1,
        threads: 1,
        usagePercent: 0.0,
      );
    }
  }

  static Future<int?> _getInstalledRamBytesFromDmidecode() async {
    try {
      ProcessResult result = await Process.run(
        'bash',
        ['-c', 'dmidecode -t memory 2>/dev/null'],
        runInShell: true,
      ).timeout(const Duration(seconds: 2));
      if (result.exitCode != 0) {
        try {
          result = await _runSudoCommand('dmidecode -t memory 2>/dev/null');
        } catch (_) {
          return null;
        }
      }
      if (result.exitCode != 0) return null;
      final output = result.stdout as String;
      int sumMb = 0;
      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        final match = RegExp(r'Size:\s*(\d+)\s*MB').firstMatch(trimmed);
        if (match != null) {
          final mb = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (mb > 0) sumMb += mb;
        }
      }
      if (sumMb > 0) return sumMb * 1024 * 1024;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<MemoryInfo> _getMemoryInfo() async {
    try {
      final content = await File('/proc/meminfo').readAsString();
      final lines = content.split('\n');
      int memTotalKb = 0;
      int memFreeKb = 0;
      int buffersKb = 0;
      int cachedKb = 0;
      int swapTotalKb = 0;
      int swapFreeKb = 0;
      for (final line in lines) {
        if (!line.contains(':')) continue;
        final idx = line.indexOf(':');
        final key = line.substring(0, idx).trim();
        final valuePart = line.substring(idx + 1).trim().split(RegExp(r'\s+'));
        final valueKb = int.tryParse(valuePart.isNotEmpty ? valuePart[0] : '0') ?? 0;
        switch (key) {
          case 'MemTotal':
            memTotalKb = valueKb;
            break;
          case 'MemFree':
            memFreeKb = valueKb;
            break;
          case 'Buffers':
            buffersKb = valueKb;
            break;
          case 'Cached':
            cachedKb = valueKb;
            break;
          case 'SwapTotal':
            swapTotalKb = valueKb;
            break;
          case 'SwapFree':
            swapFreeKb = valueKb;
            break;
        }
      }
      const kb = 1024;
      int totalBytes = memTotalKb * kb;
      final kernelUsed = totalBytes - memFreeKb * kb - (buffersKb + cachedKb) * kb;
      final usedBytesClamped = kernelUsed > 0 ? kernelUsed : 0;
      final installedBytes = await _getInstalledRamBytesFromDmidecode();
      final useInstalledTotal = installedBytes != null && installedBytes > totalBytes;
      if (useInstalledTotal) totalBytes = installedBytes!;
      final freeBytesKernel = memFreeKb * kb;
      final freeBytes = useInstalledTotal
          ? (totalBytes - usedBytesClamped > 0 ? totalBytes - usedBytesClamped : 0)
          : freeBytesKernel;
      final cachedBytes = cachedKb * kb;
      final swapTotalBytes = swapTotalKb * kb;
      final swapUsedBytes = (swapTotalKb - swapFreeKb) * kb;
      return MemoryInfo(
        totalBytes: totalBytes,
        usedBytes: usedBytesClamped,
        freeBytes: freeBytes,
        cachedBytes: cachedBytes,
        swapTotalBytes: swapTotalBytes,
        swapUsedBytes: swapUsedBytes,
      );
    } catch (e) {
      try {
        final result = await Process.run('bash', ['-c', 'LANG=C free -b']);
        final output = result.stdout as String;
        final lines = output.split('\n');
        int totalBytes = 0;
        int usedBytes = 0;
        int freeBytes = 0;
        int cachedBytes = 0;
        int swapTotalBytes = 0;
        int swapUsedBytes = 0;
        for (final line in lines) {
          if (line.startsWith('Mem:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              totalBytes = int.tryParse(parts[1]) ?? 0;
              usedBytes = int.tryParse(parts[2]) ?? 0;
              freeBytes = int.tryParse(parts[3]) ?? 0;
              if (parts.length > 6) {
                cachedBytes = int.tryParse(parts[6]) ?? 0;
              }
            }
          } else if (line.startsWith('Swap:')) {
            final parts = line.split(RegExp(r'\s+'));
            if (parts.length >= 4) {
              swapTotalBytes = int.tryParse(parts[1]) ?? 0;
              swapUsedBytes = int.tryParse(parts[2]) ?? 0;
            }
          }
        }
        return MemoryInfo(
          totalBytes: totalBytes,
          usedBytes: usedBytes,
          freeBytes: freeBytes,
          cachedBytes: cachedBytes,
          swapTotalBytes: swapTotalBytes,
          swapUsedBytes: swapUsedBytes,
        );
      } catch (_) {
        return MemoryInfo(
          totalBytes: 0,
          usedBytes: 0,
          freeBytes: 0,
          cachedBytes: 0,
          swapTotalBytes: 0,
          swapUsedBytes: 0,
        );
      }
    }
  }

  static int _parseFreeHumanToBytes(String s) {
    final t = s.trim().toLowerCase();
    final match = RegExp(r'^(\d+(?:\.\d+)?)\s*([gmkb]i?)?$').firstMatch(t);
    if (match == null) return 0;
    final numPart = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2) ?? '';
    if (unit.startsWith('g')) return (numPart * 1024 * 1024 * 1024).round();
    if (unit.startsWith('m')) return (numPart * 1024 * 1024).round();
    if (unit.startsWith('k')) return (numPart * 1024).round();
    return numPart.round();
  }

  static String _formatBytesHuman(int bytes) {
    if (bytes < 0) return '0B';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}Ki';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}Mi';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}Gi';
  }

  static Future<int?> _getMemTotalKbFromMeminfo() async {
    try {
      final content = await File('/proc/meminfo').readAsString();
      for (final line in content.split('\n')) {
        if (line.startsWith('MemTotal:')) {
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length >= 2) return int.tryParse(parts[1]);
          break;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getMemoryFromFreeForTray() async {
    try {
      final totalKb = await _getMemTotalKbFromMeminfo();
      if (totalKb == null || totalKb <= 0) return null;
      final totalBytes = totalKb * 1024;
      final totalStr = _formatBytesHuman(totalBytes);

      final result = await Process.run('bash', ['-c', 'LANG=C free -h']);
      if (result.exitCode != 0) return null;
      final lines = (result.stdout as String).split('\n');
      String? usedStr;
      int usedBytes = 0;
      for (final line in lines) {
        if (!line.startsWith('Mem:')) continue;
        final parts = line.trim().split(RegExp(r'\s+'));
        if (parts.length < 3) return null;
        usedStr = parts[2];
        usedBytes = _parseFreeHumanToBytes(usedStr);
        break;
      }
      if (usedStr == null) return null;

      final usedPercent = totalBytes > 0 ? ((usedBytes / totalBytes) * 100) : 0.0;
      return {
        'totalStr': totalStr,
        'usedStr': _formatBytesHuman(usedBytes),
        'usedPercent': usedPercent,
      };
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getHomeDiskUsage() async {
    try {
      final result = await Process.run('bash', ['-c', 'df -B1 /home 2>/dev/null | tail -1']);
      if (result.exitCode != 0) return null;
      final line = (result.stdout as String).trim();
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 6) return null;
      final totalBytes = int.tryParse(parts[1]) ?? 0;
      final usedBytes = int.tryParse(parts[2]) ?? 0;
      if (totalBytes <= 0) return null;
      final usedPercent = (usedBytes / totalBytes) * 100;
      String formatB(int b) {
        if (b < 0) return '0';
        if (b < 1024) return '$b B';
        if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
        if (b < 1024 * 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
        return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
      }
      return {
        'usedPercent': usedPercent,
        'usedBytes': usedBytes,
        'totalBytes': totalBytes,
        'usedStr': formatB(usedBytes),
        'totalStr': formatB(totalBytes),
      };
    } catch (_) {
      return null;
    }
  }

  static Future<List<DiskInfo>> _getDiskInfo() async {
    try {
      final result = await Process.run('bash', ['-c', 'df -B1 -T']);
      final output = result.stdout as String;
      final lines = output.split('\n');

      final disks = <DiskInfo>[];

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 7) {
          final device = parts[0];
          final fileSystem = parts[1];
          final totalBytes = int.tryParse(parts[2]) ?? 0;
          final usedBytes = int.tryParse(parts[3]) ?? 0;
          final freeBytes = int.tryParse(parts[4]) ?? 0;
          final mountPoint = parts[6];
          final isExternal = device.startsWith('/dev/sd') && 
                            !device.contains('sda') && 
                            !mountPoint.startsWith('/boot') &&
                            !mountPoint.startsWith('/');

          disks.add(DiskInfo(
            device: device,
            mountPoint: mountPoint,
            fileSystem: fileSystem,
            totalBytes: totalBytes,
            usedBytes: usedBytes,
            freeBytes: freeBytes,
            isExternal: isExternal,
          ));
        }
      }

      return disks;
    } catch (e) {
      return [];
    }
  }

  static Future<GpuInfo?> _getGpuInfo() async {
    try {
      try {
        final nvidiaResult = await Process.run('bash', ['-c', 'nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used,utilization.gpu,temperature.gpu --format=csv,noheader,nounits']);
        if (nvidiaResult.exitCode == 0) {
          final output = (nvidiaResult.stdout as String).trim();
          final parts = output.split(', ');
          if (parts.length >= 6) {
            return GpuInfo(
              model: parts[0].trim(),
              driver: parts[1].trim(),
              memoryTotalBytes: int.tryParse(parts[2].trim()) != null 
                  ? int.parse(parts[2].trim()) * 1024 * 1024 
                  : null,
              memoryUsedBytes: int.tryParse(parts[3].trim()) != null 
                  ? int.parse(parts[3].trim()) * 1024 * 1024 
                  : null,
              usagePercent: double.tryParse(parts[4].trim()),
              temperature: double.tryParse(parts[5].trim()),
            );
          }
        }
      } catch (e) {}

      try {
        final amdResult = await Process.run('bash', ['-c', 'rocm-smi --showid --showproductname --showmeminfo vram --showtemp --showuse 2>/dev/null']);
        if (amdResult.exitCode == 0) {
          final output = (amdResult.stdout as String);
          String? model;
          double? usage;
          double? temp;
          
          for (final line in output.split('\n')) {
            if (line.contains('Card series:')) {
              model = line.split(':')[1].trim();
            } else if (line.contains('GPU use')) {
              final match = RegExp(r'(\d+\.?\d*)%').firstMatch(line);
              if (match != null && match.group(1) != null) {
                usage = double.tryParse(match.group(1)!);
              }
            } else if (line.contains('Temperature')) {
              final match = RegExp(r'(\d+\.?\d*)C').firstMatch(line);
              if (match != null && match.group(1) != null) {
                temp = double.tryParse(match.group(1)!);
              }
            }
          }
          
          if (model != null) {
            return GpuInfo(
              model: model,
              driver: 'AMD ROCm',
              usagePercent: usage,
              temperature: temp,
            );
          }
        }
      } catch (e) {}

      try {
        final intelResult = await Process.run('bash', ['-c', 'intel_gpu_top -l 1 2>/dev/null | head -5']);
        if (intelResult.exitCode == 0) {
          final output = (intelResult.stdout as String);
          if (output.isNotEmpty) {
            return GpuInfo(
              model: 'Intel Integrated Graphics',
              driver: 'Intel',
            );
          }
        }
      } catch (e) {}

      try {
        final lspciResult = await Process.run('bash', ['-c', 'lspci | grep -iE "(vga|3d|display)"']);
        if (lspciResult.exitCode == 0) {
          final output = (lspciResult.stdout as String).trim();
          if (output.isNotEmpty) {
            String model = output.split(':')[2].trim();
            if (model.toLowerCase().contains('nvidia')) {
              model = 'NVIDIA ${model.replaceAll(RegExp(r'.*nvidia\s*', caseSensitive: false), '')}';
            } else if (model.toLowerCase().contains('amd') || model.toLowerCase().contains('radeon') || model.toLowerCase().contains('ati')) {
              model = 'AMD ${model.replaceAll(RegExp(r'.*(amd|radeon|ati)\s*', caseSensitive: false), '')}';
            } else if (model.toLowerCase().contains('intel')) {
              model = 'Intel ${model.replaceAll(RegExp(r'.*intel\s*', caseSensitive: false), '')}';
            }
            
            return GpuInfo(
              model: model,
              driver: 'Unknown',
            );
          }
        }
      } catch (e) {}

      try {
        final glxResult = await Process.run('bash', ['-c', 'glxinfo | grep -i "OpenGL renderer"']);
        if (glxResult.exitCode == 0) {
          final output = (glxResult.stdout as String).trim();
          if (output.isNotEmpty) {
            final renderer = output.split(':')[1].trim();
            return GpuInfo(
              model: renderer,
              driver: 'OpenGL',
            );
          }
        }
      } catch (e) {}
      return null;
    } catch (e) {
      return null;
    }
  }
}

