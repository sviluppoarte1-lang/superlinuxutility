import 'dart:io';
import '../models/system_process.dart';
import '../models/system_info.dart';
import 'password_storage.dart';

class _CpuCorePrev {
  final int total;
  final int idle; // idle + iowait (corretto)
  _CpuCorePrev(this.total, this.idle);
}

class SystemMonitor {
  static int? _dmidecodeInstalledRamBytesCache;
  static DateTime? _dmidecodeInstalledRamBytesCacheAt;

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
      // Usa formato esplicito per evitare problemi di parsing con ps aux
      // Formato: pid, comm (nome eseguibile), %cpu, rss (resident set in KB), user, stat, args
      final result = await Process.run(
        'ps',
        ['-e', '-o', 'pid,comm,%cpu,rss,user,stat,args', '--sort=-%cpu'],
      );

      if (result.exitCode != 0) {
        return [];
      }

      final selfPid = pid; // PID del processo corrente (dart:io)
      final allProcesses = _parsePsOutput(result.stdout as String);
      // Filtra processi di sistema transienti e il processo corrente
      return allProcesses.where((p) => p.pid != selfPid && !_isTransientProcess(p)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Processi transienti di sistema da filtrare dalla lista processi
  static final _transientNames = {
    'ps', 'bash', 'sh', 'zsh', 'dash', 'fish',
    'sudo', 'su', 'pkexec',
    'systemd', 'systemd-',
    'kthreadd', 'ksoftirqd', 'kworker', 'migration', 'rcu_', 'watchdog',
    'dbus-daemon', 'dbus-broker',
    'agetty', 'login', 'cron', 'atd',
  };

  static bool _isTransientProcess(SystemProcess p) {
    final name = p.name.toLowerCase();
    final cmd = (p.command ?? '').toLowerCase();

    // Filtra per nome esatto
    if (_transientNames.contains(name)) return true;

    // Filtra processi kernel (pid < 100 e user root)
    if (p.pid < 100 && p.user == 'root') return true;

    // Filtra comandi che iniziano con ps/e/o (il nostro comando ps stesso)
    if (cmd.startsWith('ps ') || cmd == 'ps') return true;

    // Filtra processi con nome che inizia con "kworker", "ksoftirqd", ecc.
    if (name.startsWith('kworker') || name.startsWith('ksoftirqd') ||
        name.startsWith('rcu') || name.startsWith('migration')) return true;

    return false;
  }

  static List<SystemProcess> _parsePsOutput(String output) {
    final processes = <SystemProcess>[];
    final lines = output.split('\n');

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 6) continue;

      try {
        final pid = int.parse(parts[0]);
        final name = parts[1];
        final cpuPercent = double.tryParse(parts[2]) ?? 0.0;
        final rss = int.tryParse(parts[3]) ?? 0;
        final user = parts[4];
        final stat = parts[5];
        final command = parts.length > 6
            ? parts.sublist(6).join(' ')
            : name;

        // Salta processi kernel (pid < 2) opzionale
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

    return processes;
  }

  static Future<bool> killProcess(int pid, {bool force = false}) async {
    try {
      final signal = force ? '-9' : '-15';
      // Prova prima senza sudo (per processi dell'utente)
      final directResult = await Process.run('kill', [signal, '$pid']);
      if (directResult.exitCode == 0) return true;
      // Fallback con sudo (per processi di sistema/root)
      final result = await _runSudoCommand('kill $signal $pid');
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  static String? _cachedThermalZonePath;
  static DateTime? _thermalZoneCachedAt;

  static Future<String?> _findThermalZonePath() async {
    final now = DateTime.now();
    if (_cachedThermalZonePath != null &&
        _thermalZoneCachedAt != null &&
        now.difference(_thermalZoneCachedAt!) < const Duration(hours: 1)) {
      return _cachedThermalZonePath;
    }
    try {
      final zone = Directory('/sys/class/thermal');
      if (!await zone.exists()) return null;
      final zones = await zone.list().toList();
      for (final entity in zones) {
        if (entity is! Directory || !entity.path.contains('thermal_zone')) continue;
        try {
          final typeFile = File('${entity.path}/type');
          if (await typeFile.exists()) {
            final type = (await typeFile.readAsString()).trim();
            if (type == 'x86_pkg_temp') {
              _cachedThermalZonePath = entity.path;
              _thermalZoneCachedAt = now;
              return entity.path;
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
              _cachedThermalZonePath = entity.path;
              _thermalZoneCachedAt = now;
              return entity.path;
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  static double? _cpuTempCache;
  static DateTime? _cpuTempCachedAt;
  static CpuInfo? _cpuInfoCache;
  static DateTime? _cpuInfoCachedAt;
  static const Duration _cpuInfoCacheDuration = Duration(minutes: 5);
  static List<DiskInfo>? _diskInfoCache;
  static DateTime? _diskInfoCachedAt;
  static const Duration _diskInfoCacheDuration = Duration(minutes: 3);

  static Future<double?> getCpuTemperature() async {
    try {
      if (_cpuTempCache != null && _cpuTempCachedAt != null &&
          DateTime.now().difference(_cpuTempCachedAt!) < const Duration(seconds: 5)) {
        return _cpuTempCache;
      }

      final zonePath = await _findThermalZonePath();
      if (zonePath != null) {
        final tempFile = File('$zonePath/temp');
        if (await tempFile.exists()) {
          final s = await tempFile.readAsString();
          final millideg = int.tryParse(s.trim());
          if (millideg != null && millideg > 0 && millideg < 150000) {
            _cpuTempCache = millideg / 1000.0;
            _cpuTempCachedAt = DateTime.now();
            return _cpuTempCache;
          }
        }
      }
      final result = await Process.run('bash', [
        '-c',
        r"sensors -u 2>/dev/null | grep -m1 '  temp1_input:' | awk '{print $2}'",
      ]);
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim();
        if (out.isNotEmpty) {
          final t = double.tryParse(out.split('\n').first);
          if (t != null && t > 0 && t < 150) {
            _cpuTempCache = t;
            _cpuTempCachedAt = DateTime.now();
            return t;
          }
        }
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
    // Return cached CPU info (model, cores, threads) if available
    if (_cpuInfoCache != null && _cpuInfoCachedAt != null &&
        DateTime.now().difference(_cpuInfoCachedAt!) < _cpuInfoCacheDuration) {
      // Update only the dynamic usage values
      final cached = _cpuInfoCache!;
      try {
        final cpuUsage = await _cpuUsagePercentFromProcStat();
        final coreUsage = <double>[];
        try {
          final mpstatResult = await Process.run('bash', ['-c', r"mpstat -P ALL 1 1 2>/dev/null | tail -n +4 | awk '{print $3}'"]);
          if (mpstatResult.exitCode == 0) {
            final lines = (mpstatResult.stdout as String).split('\n');
            for (final line in lines) {
              final usage = double.tryParse(line.trim());
              if (usage != null) coreUsage.add(100 - usage);
            }
          }
        } catch (e) {}
        if (coreUsage.isEmpty) {
          try {
            coreUsage.addAll(await _coreUsageFromProcStat());
          } catch (e) {}
        }
        double? currentSpeedMhz;
        try {
          final freqResult = await Process.run('bash', ['-c', 'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | head -1']);
          if (freqResult.exitCode == 0) {
            final freqKHz = int.tryParse((freqResult.stdout as String).trim());
            if (freqKHz != null) currentSpeedMhz = freqKHz / 1000.0;
          }
          if (currentSpeedMhz == null) {
            final cpuinfoResult = await Process.run('bash', ['-c', r"grep '^cpu MHz' /proc/cpuinfo | head -1 | awk '{print $4}'"]);
            if (cpuinfoResult.exitCode == 0) {
              currentSpeedMhz = double.tryParse((cpuinfoResult.stdout as String).trim());
            }
          }
        } catch (e) {}
        return CpuInfo(
          model: cached.model,
          cores: cached.cores,
          threads: cached.threads,
          usagePercent: cpuUsage,
          coreUsage: coreUsage,
          currentSpeedMhz: currentSpeedMhz,
        );
      } catch (e) {
        return cached;
      }
    }

    try {
      final modelResult = await Process.run('bash', ['-c', r'lscpu | grep "Model name" | cut -d: -f2 | xargs']);
      final modelOutput = (modelResult.stdout as String).trim();
      final model = modelOutput.isEmpty ? 'Unknown' : modelOutput;

      final threadsResult = await Process.run('bash', ['-c', 'nproc']);
      final threads = int.tryParse((threadsResult.stdout as String).trim()) ?? 1;

      final coresResult = await Process.run('bash', ['-c', r'lscpu | grep "Core(s) per socket" | cut -d: -f2 | xargs']);
      final coresPerSocket = int.tryParse((coresResult.stdout as String).trim()) ?? 0;

      final socketsResult = await Process.run('bash', ['-c', r'lscpu | grep "Socket(s)" | cut -d: -f2 | xargs']);
      final sockets = int.tryParse((socketsResult.stdout as String).trim()) ?? 1;

      final cores = coresPerSocket > 0 ? coresPerSocket * sockets : threads;

      final cpuUsage = await _cpuUsagePercentFromProcStat();
      final coreUsage = <double>[];
      // Prova mpstat (parte di sysstat); se assente, fallback /proc/stat
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
      if (coreUsage.isEmpty) {
        // Fallback: /proc/stat per-core
        try {
          coreUsage.addAll(await _coreUsageFromProcStat());
        } catch (e) {}
      }

      // Velocità CPU attuale dal primo core (sysfs cpufreq)
      double? currentSpeedMhz;
      try {
        final freqResult = await Process.run('bash', ['-c', 'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null | head -1']);
        if (freqResult.exitCode == 0) {
          final freqKHz = int.tryParse((freqResult.stdout as String).trim());
          if (freqKHz != null) currentSpeedMhz = freqKHz / 1000.0;
        }
        if (currentSpeedMhz == null) {
          // Fallback: /proc/cpuinfo
          final cpuinfoResult = await Process.run('bash', ['-c', r"grep '^cpu MHz' /proc/cpuinfo | head -1 | awk '{print $4}'"]);
          if (cpuinfoResult.exitCode == 0) {
            currentSpeedMhz = double.tryParse((cpuinfoResult.stdout as String).trim());
          }
        }
      } catch (e) {}

      final cpuInfo = CpuInfo(
        model: model,
        cores: cores,
        threads: threads,
        usagePercent: cpuUsage,
        coreUsage: coreUsage,
        currentSpeedMhz: currentSpeedMhz,
      );
      _cpuInfoCache = cpuInfo;
      _cpuInfoCachedAt = DateTime.now();
      return cpuInfo;
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
    final now = DateTime.now();
    if (_dmidecodeInstalledRamBytesCache != null &&
        _dmidecodeInstalledRamBytesCacheAt != null &&
        now.difference(_dmidecodeInstalledRamBytesCacheAt!) < const Duration(hours: 24)) {
      return _dmidecodeInstalledRamBytesCache;
    }
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
      if (sumMb > 0) {
        final bytes = sumMb * 1024 * 1024;
        _dmidecodeInstalledRamBytesCache = bytes;
        _dmidecodeInstalledRamBytesCacheAt = now;
        return bytes;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Solo `/proc/stat`: usa cache dei valori precedenti per evitare delay di 100ms.
  /// Formula corretta: idle = cpu[4] + cpu[5] (idle + iowait),
  /// active = user + nice + system + irq + softirq + steal.
  /// guest/guest_nice sono già inclusi in user/nice → esclusi.
  static int? _prevCpuTotal;
  static int? _prevCpuIdle;

  static Future<double> _cpuUsagePercentFromProcStat() async {
    try {
      final stat = await File('/proc/stat').readAsString();
      final lines = stat.split('\n');
      if (lines.isEmpty) return 0;
      final cpu = lines[0].split(RegExp(r'\s+'));
      if (cpu.length < 8) return 0;

      // /proc/stat: cpu user nice system idle iowait irq softirq steal [guest guest_nice]
      // guest/guest_nice già inclusi in user/nice → non sommare (ultime 2 colonne)
      final fields = cpu.length > 10 ? cpu.length - 2 : cpu.length;
      final idle = int.tryParse(cpu[4]) ?? 0;
      final iowait = int.tryParse(cpu[5]) ?? 0;
      var total = 0;
      for (var i = 1; i < fields; i++) {
        total += int.tryParse(cpu[i]) ?? 0;
      }

      if (_prevCpuTotal == null || _prevCpuIdle == null) {
        _prevCpuTotal = total;
        _prevCpuIdle = idle + iowait;
        return 0;
      }

      final totalDiff = total - _prevCpuTotal!;
      final idleDiff = (idle + iowait) - _prevCpuIdle!;
      _prevCpuTotal = total;
      _prevCpuIdle = idle + iowait;
      if (totalDiff <= 0) return 0;
      return ((totalDiff - idleDiff) / totalDiff) * 100;
    } catch (_) {
      return 0;
    }
  }

  // Per-core prev values cache per /proc/stat fallback
  // idle campo = idle + iowait (corretto)
  static final Map<String, _CpuCorePrev> _corePrev = {};

  static Future<List<double>> _coreUsageFromProcStat() async {
    final stat = await File('/proc/stat').readAsString();
    final lines = stat.split('\n');
    final result = <double>[];
    for (final line in lines) {
      if (!line.startsWith('cpu')) continue;
      if (!RegExp(r'^cpu\d+').hasMatch(line)) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 8) continue;

      // guest/guest_nice già inclusi in user/nice → escludi
      final fields = parts.length > 10 ? parts.length - 2 : parts.length;
      final idle = int.tryParse(parts[4]) ?? 0;
      final iowait = int.tryParse(parts[5]) ?? 0;
      var total = 0;
      for (var i = 1; i < fields; i++) {
        total += int.tryParse(parts[i]) ?? 0;
      }

      final key = parts[0];
      final prev = _corePrev[key];
      if (prev == null) {
        _corePrev[key] = _CpuCorePrev(total, idle + iowait);
        result.add(0);
        continue;
      }
      final totalDiff = total - prev.total;
      final idleDiff = (idle + iowait) - prev.idle;
      _corePrev[key] = _CpuCorePrev(total, idle + iowait);
      if (totalDiff <= 0) {
        result.add(0);
      } else {
        result.add(((totalDiff - idleDiff) / totalDiff) * 100);
      }
    }
    return result;
  }

  static GpuInfo? _quickNvidiaCache;
  static DateTime? _quickNvidiaCachedAt;

  /// Solo `nvidia-smi` rapido se disponibile (niente lspci/rocm/glxinfo).
  static Future<GpuInfo?> _tryQuickNvidiaGpuForTray() async {
    if (_quickNvidiaCache != null && _quickNvidiaCachedAt != null &&
        DateTime.now().difference(_quickNvidiaCachedAt!) < const Duration(seconds: 5)) {
      return _quickNvidiaCache;
    }
    try {
      final r = await Process.run('bash', [
        '-c',
        'command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1',
      ]);
      if (r.exitCode != 0) return null;
      final line = (r.stdout as String).trim();
      if (line.isEmpty) return null;
      final parts = line.split(', ');
      if (parts.length < 2) return null;
      final u = double.tryParse(parts[0].trim());
      final t = double.tryParse(parts[1].trim());
      if (u == null && t == null) return null;
      _quickNvidiaCache = GpuInfo(
        model: 'NVIDIA',
        driver: 'nvidia-smi',
        usagePercent: u,
        temperature: t,
      );
      _quickNvidiaCachedAt = DateTime.now();
      return _quickNvidiaCache;
    } catch (_) {
      return null;
    }
  }

  /// Per il system tray: niente mpstat, df globale, dmidecode né scansione GPU completa.
  static Future<TrayCpuGpuStats> getTrayLightweightStats() async {
    final cpuUsage = await _cpuUsagePercentFromProcStat();
    final gpu = await _tryQuickNvidiaGpuForTray();
    return TrayCpuGpuStats(
      cpuUsagePercent: cpuUsage,
      gpuUsagePercent: gpu?.usagePercent,
      gpuTemp: gpu?.temperature,
    );
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

  static String _formatBytesHuman(int bytes) {
    if (bytes < 0) return '0B';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}Ki';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}Mi';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}Gi';
  }

  static Future<Map<String, dynamic>?> getMemoryFromFreeForTray() async {
    try {
      final content = await File('/proc/meminfo').readAsString();
      int memTotalKb = 0, memFreeKb = 0, buffersKb = 0, cachedKb = 0;
      for (final line in content.split('\n')) {
        if (!line.contains(':')) continue;
        final idx = line.indexOf(':');
        final key = line.substring(0, idx).trim();
        final valueKb = int.tryParse(line.substring(idx + 1).trim().split(RegExp(r'\s+')).first) ?? 0;
        if (key == 'MemTotal') memTotalKb = valueKb;
        else if (key == 'MemFree') memFreeKb = valueKb;
        else if (key == 'Buffers') buffersKb = valueKb;
        else if (key == 'Cached') cachedKb = valueKb;
      }
      if (memTotalKb <= 0) return null;
      final totalBytes = memTotalKb * 1024;
      final usedBytes = (memTotalKb - memFreeKb - buffersKb - cachedKb) * 1024;
      if (usedBytes < 0) return null;
      final usedPercent = totalBytes > 0 ? ((usedBytes / totalBytes) * 100) : 0.0;
      return {
        'totalStr': _formatBytesHuman(totalBytes),
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
    if (_diskInfoCache != null && _diskInfoCachedAt != null &&
        DateTime.now().difference(_diskInfoCachedAt!) < _diskInfoCacheDuration) {
      return _diskInfoCache!;
    }
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

      _diskInfoCache = disks;
      _diskInfoCachedAt = DateTime.now();
      return disks;
    } catch (e) {
      return [];
    }
  }

  static GpuInfo? _gpuInfoCache;
  static DateTime? _gpuInfoCachedAt;

  /// Cerca GPU tramite /sys/class/drm/ (funziona su Wayland e X11).
  static Future<GpuInfo?> _getGpuInfoFromSysDrm() async {
    try {
      final drmDir = Directory('/sys/class/drm');
      if (!await drmDir.exists()) return null;
      final cards = await drmDir.list().where((e) =>
        e is Directory && e.path.contains('card') && !e.path.contains('-')).toList();
      if (cards.isEmpty) return null;
      final cardDir = cards.first.path;
      final deviceDir = Directory('$cardDir/device');
      if (!await deviceDir.exists()) return null;
      final entries = await deviceDir.list().toList();
      String? vendor;
      String? model;
      for (final e in entries) {
        final name = e.path.split('/').last;
        if (name == 'vendor') {
          vendor = (await File(e.path).readAsString()).trim();
          final vendors = {'0x10de': 'NVIDIA', '0x1002': 'AMD', '0x8086': 'Intel'};
          vendor = vendors[vendor] ?? vendor;
        } else if (name == 'device') {
          model = (await File(e.path).readAsString()).trim();
        }
      }
      if (vendor != null) {
        return GpuInfo(model: model != null ? '$vendor (${model.substring(0, 8)}...)' : vendor, driver: 'DRM');
      }
    } catch (_) {}
    return null;
  }

  static Future<GpuInfo?> _getGpuInfo() async {
    try {
      if (_gpuInfoCache != null && _gpuInfoCachedAt != null &&
          DateTime.now().difference(_gpuInfoCachedAt!) < const Duration(seconds: 30)) {
        return _gpuInfoCache;
      }

      final isWayland = Platform.environment['XDG_SESSION_TYPE']?.toLowerCase() == 'wayland' ||
          (Platform.environment['WAYLAND_DISPLAY'] ?? '').isNotEmpty;

      GpuInfo? result;

      try {
        final nvidiaResult = await Process.run('bash', ['-c', 'nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used,utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null']);
        if (nvidiaResult.exitCode == 0) {
          final output = (nvidiaResult.stdout as String).trim();
          final parts = output.split(', ');
          if (parts.length >= 2) {
            result = GpuInfo(
              model: parts[0].trim(),
              driver: parts.length >= 2 ? parts[1].trim() : 'nvidia',
              memoryTotalBytes: parts.length >= 3 && int.tryParse(parts[2].trim()) != null 
                  ? int.parse(parts[2].trim()) * 1024 * 1024 
                  : null,
              memoryUsedBytes: parts.length >= 4 && int.tryParse(parts[3].trim()) != null 
                  ? int.parse(parts[3].trim()) * 1024 * 1024 
                  : null,
              usagePercent: parts.length >= 5 ? double.tryParse(parts[4].trim()) : null,
              temperature: parts.length >= 6 ? double.tryParse(parts[5].trim()) : null,
            );
          }
        }
      } catch (_) {}

      if (result == null) {
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
                if (match != null) usage = double.tryParse(match.group(1)!);
              } else if (line.contains('Temperature')) {
                final match = RegExp(r'(\d+\.?\d*)C').firstMatch(line);
                if (match != null) temp = double.tryParse(match.group(1)!);
              }
            }
            if (model != null) {
              result = GpuInfo(model: model, driver: 'AMD ROCm', usagePercent: usage, temperature: temp);
            }
          }
        } catch (_) {}
      }

      if (result == null) {
        try {
          final intelResult = await Process.run('bash', ['-c', 'intel_gpu_top -l 1 2>/dev/null | head -5']);
          if (intelResult.exitCode == 0 && (intelResult.stdout as String).trim().isNotEmpty) {
            result = GpuInfo(model: 'Intel Integrated Graphics', driver: 'Intel');
          }
        } catch (_) {}
      }

      if (result == null) {
        try {
          final lspciResult = await Process.run('bash', ['-c', 'lspci -d ::0300 -nn 2>/dev/null; lspci -d ::0302 -nn 2>/dev/null']);
          if (lspciResult.exitCode == 0) {
            final output = (lspciResult.stdout as String).trim();
            if (output.isNotEmpty) {
              final match = RegExp(r'\[(10de|1002|8086):[0-9a-fA-F]+\]').firstMatch(output);
              final nameMatch = RegExp(r':\s*(.+?)\s*\[').firstMatch(output);
              final vendors = {'10de': 'NVIDIA', '1002': 'AMD', '8086': 'Intel'};
              final vendorCode = match?.group(1);
              final vendor = vendorCode != null ? vendors[vendorCode] ?? 'Unknown' : 'Unknown';
              final name = nameMatch?.group(1)?.trim() ?? 'Unknown GPU';
              result = GpuInfo(model: '$vendor $name', driver: 'Unknown');
            }
          }
        } catch (_) {}
      }

      if (result == null && isWayland) {
        result = await _getGpuInfoFromSysDrm();
      }

      if (result == null && !isWayland) {
        try {
          final glxResult = await Process.run('bash', ['-c', 'glxinfo 2>/dev/null | grep -i "OpenGL renderer"']);
          if (glxResult.exitCode == 0) {
            final output = (glxResult.stdout as String).trim();
            if (output.isNotEmpty) {
              final renderer = output.split(':')[1].trim();
              result = GpuInfo(model: renderer, driver: 'OpenGL');
            }
          }
        } catch (_) {}
      }

      if (result != null) {
        _gpuInfoCache = result;
        _gpuInfoCachedAt = DateTime.now();
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}

