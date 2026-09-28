import 'dart:io';
import 'password_storage.dart';

class SwapInfo {
  final int totalKb;
  final int usedKb;
  final int freeKb;
  final int swapinness;
  final int persistedSwappiness; // Value written to sysctl.conf/sysctl.d (for "is applied" check)
  final String? swapDevice;
  final int ramTotalKb;
  final bool zswapEnabled;
  final String zswapStatus; // 'enabled', 'disabled', 'not available'

  const SwapInfo({
    required this.totalKb,
    required this.usedKb,
    required this.freeKb,
    required this.swapinness,
    this.persistedSwappiness = 0,
    this.swapDevice,
    required this.ramTotalKb,
    this.zswapEnabled = false,
    this.zswapStatus = 'not available',
  });

  double get totalGb => totalKb / 1024 / 1024;
  double get usedGb => usedKb / 1024 / 1024;
  double get ramGb => ramTotalKb / 1024 / 1024;
  bool get hasSwap => totalKb > 0;
}

class SwapRecommendation {
  final String title;
  final String description;
  final String command;
  final bool isCurrentlyApplied;

  const SwapRecommendation({
    required this.title,
    required this.description,
    required this.command,
    required this.isCurrentlyApplied,
  });
}

class DavinciFix {
  final String id;
  final String title;
  final String description;
  final String command;
  final bool requiresRestart;
  final bool isCurrentlyApplied;

  const DavinciFix({
    required this.id,
    required this.title,
    required this.description,
    required this.command,
    this.requiresRestart = false,
    this.isCurrentlyApplied = false,
  });
}

class TweaksService {
  static Future<String> _runSudoCommandOutput(String command) async {
    try {
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) return 'No password saved';
      final escapedPassword = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');
      final fullCommand =
          'printf "%s\\n" "$escapedPassword" | sudo -p "" -S bash -c ${_shellQuote(command)} 2>&1';
      final result = await Process.run('bash', ['-c', fullCommand], runInShell: true);
      final output = (result.stdout as String).trim();
      final err = (result.stderr as String).trim();
      return err.isNotEmpty ? err : (output.isNotEmpty ? output : (result.exitCode == 0 ? 'OK' : 'Failed'));
    } catch (e) {
      return e.toString();
    }
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  // ─── SWAP ───

  static Future<SwapInfo> getSwapInfo() async {
    int totalKb = 0, usedKb = 0, freeKb = 0, swapiness = 60, ramTotalKb = 0;
    String? swapDevice;

    try {
      final meminfo = await File('/proc/meminfo').readAsLines();
      for (final line in meminfo) {
        if (line.startsWith('SwapTotal:')) {
          totalKb = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0;
        } else if (line.startsWith('SwapFree:')) {
          freeKb = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0;
        } else if (line.startsWith('MemTotal:')) {
          ramTotalKb = int.tryParse(line.split(RegExp(r'\s+'))[1]) ?? 0;
        }
      }
      usedKb = totalKb - freeKb;
    } catch (_) {}

    // Read effective swappiness from sysctl (runtime value)
    try {
      final result = await Process.run('sysctl', ['-n', 'vm.swappiness']);
      if (result.exitCode == 0) {
        swapiness = int.tryParse((result.stdout as String).trim()) ?? 60;
      }
    } catch (_) {
      try {
        final swappiness = await File('/proc/sys/vm/swappiness').readAsString();
        swapiness = int.tryParse(swappiness.trim()) ?? 60;
      } catch (_) {}
    }

    // Read the persisted (configured) value from sysctl.d / sysctl.conf
    // This is the value that WILL be applied at boot.
    // We use this for the "is currently applied" check, not the runtime value
    // which can be overridden by kernel defaults or other services at boot.
    int persistedSwappiness = swapiness;
    try {
      final sysctlD = await File('/etc/sysctl.d/99-slu-swappiness.conf').readAsString();
      for (final line in sysctlD.split('\n')) {
        if (line.startsWith('vm.swappiness=')) {
          persistedSwappiness = int.tryParse(line.split('=')[1].trim()) ?? swapiness;
        }
      }
    } catch (_) {}
    try {
      final sysctlConf = await File('/etc/sysctl.conf').readAsString();
      for (final line in sysctlConf.split('\n')) {
        if (line.startsWith('vm.swappiness=')) {
          persistedSwappiness = int.tryParse(line.split('=')[1].trim()) ?? persistedSwappiness;
        }
      }
    } catch (_) {}
    // swapiness keeps the runtime value for display.
    // persistedSwappiness is used in getSwapRecommendations for the "is applied" check.

    // Check if ZRAM is active
    try {
      final result = await Process.run('swapon', ['--show=NAME', '--noheadings']);
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        if (output.isNotEmpty) swapDevice = output.split('\n').first.trim();
      }
    } catch (_) {}

    // Detect zswap status
    bool zswapEnabled = false;
    String zswapStatus = 'not available';
    try {
      final zswapRaw = await Process.run(
          'bash', ['-c', 'cat /sys/module/zswap/parameters/enabled 2>/dev/null'],
          runInShell: true);
      final zswapVal = (zswapRaw.stdout as String).trim().toLowerCase();
      if (zswapVal == 'y' || zswapVal == '1') {
        zswapEnabled = true;
        zswapStatus = 'enabled';
      } else if (zswapVal.isNotEmpty) {
        zswapEnabled = false;
        zswapStatus = 'disabled';
      }
    } catch (_) {}

    return SwapInfo(
      totalKb: totalKb,
      usedKb: usedKb,
      freeKb: freeKb,
      swapinness: swapiness,
      persistedSwappiness: persistedSwappiness,
      swapDevice: swapDevice,
      ramTotalKb: ramTotalKb,
      zswapEnabled: zswapEnabled,
      zswapStatus: zswapStatus,
    );
  }

  static Future<bool> isZramActive() async {
    try {
      final result = await Process.run('swapon', ['--show=NAME', '--noheadings']);
      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        if (output.contains('zram')) return true;
      }
    } catch (_) {}
    // Fallback: check /proc/swaps directly
    try {
      final swaps = await File('/proc/swaps').readAsString();
      if (swaps.contains('zram')) return true;
    } catch (_) {}
    // Fallback: check /sys/block/zram0
    try {
      final disksize = await File('/sys/block/zram0/disksize').readAsString();
      if ((int.tryParse(disksize.trim()) ?? 0) > 0) {
        // zram device exists with size > 0, check if it's in use as swap
        final swaps = await File('/proc/swaps').readAsString();
        if (swaps.contains('zram')) return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<bool> isZramInstalled() async {
    try {
      final result = await Process.run('dpkg', ['-s', 'zram-tools']);
      if (result.exitCode == 0) return true;
    } catch (_) {}
    try {
      final result = await Process.run('rpm', ['-q', 'zram-tools']);
      if (result.exitCode == 0) return true;
    } catch (_) {}
    try {
      final result = await Process.run('pacman', ['-Qi', 'zram-tools']);
      if (result.exitCode == 0) return true;
    } catch (_) {}
    return false;
  }

  static List<SwapRecommendation> getSwapRecommendations(SwapInfo info, {bool zramActive = false, bool zramInstalled = false}) {
    final recs = <SwapRecommendation>[];

    // Recommendation 1: Swappiness
    final idealSwappiness = info.ramGb <= 4 ? 60 : (info.ramGb <= 8 ? 40 : 20);
    // Use persisted value for comparison (not runtime which can be overridden at boot)
    final effectiveSwappiness = info.persistedSwappiness > 0 ? info.persistedSwappiness : info.swapinness;
    if (effectiveSwappiness != idealSwappiness) {
      recs.add(SwapRecommendation(
        title: 'Adjust swappiness (${info.swapinness} → $idealSwappiness)',
        description: info.ramGb <= 4
            ? 'With ${info.ramGb.toStringAsFixed(1)} GB RAM, swappiness of 60 ensures enough swap for stability.'
            : info.ramGb <= 8
                ? 'With ${info.ramGb.toStringAsFixed(1)} GB RAM, swappiness of 40 balances RAM usage and swap.'
                : 'With ${info.ramGb.toStringAsFixed(1)} GB RAM, swappiness of 20 minimizes unnecessary swap usage.',
        command: 'sysctl -w vm.swappiness=$idealSwappiness && '
            '(grep -q "^vm.swappiness" /etc/sysctl.conf 2>/dev/null && '
            'sed -i "s/^vm.swappiness.*/vm.swappiness=$idealSwappiness/" /etc/sysctl.conf || '
            'echo "vm.swappiness=$idealSwappiness" >> /etc/sysctl.conf) && '
            'mkdir -p /etc/sysctl.d && '
            'echo "vm.swappiness=$idealSwappiness" > /etc/sysctl.d/99-slu-swappiness.conf && '
            'sysctl --system 2>/dev/null',
        isCurrentlyApplied: false,
      ));
    } else {
      recs.add(SwapRecommendation(
        title: 'Swappiness is optimal ($effectiveSwappiness)',
        description: 'Current swappiness matches the recommended value for your ${info.ramGb.toStringAsFixed(1)} GB RAM.',
        command: '',
        isCurrentlyApplied: true,
      ));
    }

    // Recommendation 2: Swap file size
    if (!info.hasSwap) {
      final swapSize = info.ramGb <= 8 ? 4 : 8;
      final createCmd = 'fallocate -l ${swapSize}G /swapfile && '
          'chmod 600 /swapfile && '
          'mkswap /swapfile && '
          'swapon /swapfile && '
          '(grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" | tee -a /etc/fstab > /dev/null)';
      recs.add(SwapRecommendation(
        title: 'Create swap file ($swapSize GB)',
        description: 'No swap detected. Creating a swap file improves stability under memory pressure.',
        command: createCmd,
        isCurrentlyApplied: false,
      ));
    }

    // Recommendation 3: ZRAM
    if (zramActive) {
      recs.add(SwapRecommendation(
        title: 'ZRAM is active',
        description: 'Compressed swap in RAM is running. This provides faster swap and reduces disk I/O.',
        command: '',
        isCurrentlyApplied: true,
      ));
    } else if (zramInstalled) {
      recs.add(SwapRecommendation(
        title: 'Start ZRAM service',
        description: 'ZRAM tools are installed but the service is not running.',
        command: 'systemctl enable zramswap 2>/dev/null; '
            'systemctl restart zramswap 2>/dev/null; '
            'sleep 2; '
            'if ! swapon --show=NAME --noheadings 2>/dev/null | grep -q zram; then '
            '  for z in /dev/zram*; do [ -b "\$z" ] && mkswap "\$z" 2>/dev/null && swapon -p 100 "\$z" 2>/dev/null; done; '
            'fi',
        isCurrentlyApplied: false,
      ));
    } else {
      recs.add(SwapRecommendation(
        title: 'Enable ZRAM (compressed swap in RAM)',
        description: 'ZRAM compresses swap data in RAM, providing faster swap and reducing disk I/O.',
        command: '(dpkg -l zram-tools 2>/dev/null | grep -q "^ii" || '
            'rpm -q zram-tools 2>/dev/null | grep -q "zram-tools" || '
            'pacman -Qi zram-tools 2>/dev/null | grep -q "zram-tools" || '
            '(apt-get update -qq && apt-get install -y zram-tools 2>/dev/null) || '
            '(dnf install -y zram-tools 2>/dev/null) || '
            '(pacman -S --noconfirm zram-tools 2>/dev/null)) && '
            'systemctl enable zramswap 2>/dev/null; '
            'systemctl restart zramswap 2>/dev/null; '
            'sleep 2; '
            'for z in /dev/zram*; do [ -b "\$z" ] && mkswap "\$z" 2>/dev/null && swapon -p 100 "\$z" 2>/dev/null; done',
        isCurrentlyApplied: false,
      ));
    }

    return recs;
  }

  // ─── SWAP APPLY ───

  static Future<String> applySwappiness(int value) async {
    return _runSudoCommandOutput(
      // 1) Apply immediately
      'sysctl -w vm.swappiness=$value && '
      // 2) Write to /etc/sysctl.conf (legacy, for tools that still read it)
      '(grep -q "^vm.swappiness" /etc/sysctl.conf 2>/dev/null && '
      'sed -i "s/^vm.swappiness.*/vm.swappiness=$value/" /etc/sysctl.conf || '
      'echo "vm.swappiness=$value" >> /etc/sysctl.conf) && '
      // 3) Write to /etc/sysctl.d/ (systemd-sysctl reads this LAST = highest priority)
      'mkdir -p /etc/sysctl.d && '
      'echo "vm.swappiness=$value" > /etc/sysctl.d/99-slu-swappiness.conf && '
      // 4) Reload sysctl to ensure persistence
      'sysctl --system 2>/dev/null | grep -q swappiness && echo "OK" || echo "Written to config"',
    );
  }

  static Future<String> createSwapFile(int sizeGb) async {
    return _runSudoCommandOutput(
      'fallocate -l ${sizeGb}G /swapfile && '
      'chmod 600 /swapfile && '
      'mkswap /swapfile && '
      'swapon /swapfile && '
      'grep -q "/swapfile" /etc/fstab || echo "/swapfile none swap sw 0 0" >> /etc/fstab',
    );
  }

  static Future<String> enableZram() async {
    return _runSudoCommandOutput(
      // 1) Install zram-tools if not present
      '(dpkg -l zram-tools 2>/dev/null | grep -q "^ii" || '
      'rpm -q zram-tools 2>/dev/null | grep -q "zram-tools" || '
      'pacman -Qi zram-tools 2>/dev/null | grep -q "zram-tools" || '
      '(apt-get update -qq && apt-get install -y zram-tools 2>/dev/null) || '
      '(dnf install -y zram-tools 2>/dev/null) || '
      '(pacman -S --noconfirm zram-tools 2>/dev/null)) && '
      // 2) Enable and start zramswap service
      'systemctl enable zramswap 2>/dev/null; '
      'systemctl restart zramswap 2>/dev/null; '
      // 3) Wait for device to appear
      'sleep 2; '
      // 4) Force-activate zram if service didn't do it
      'if ! swapon --show=NAME --noheadings 2>/dev/null | grep -q zram; then '
      '  for z in /dev/zram*; do '
      '    [ -b "\$z" ] && mkswap "\$z" 2>/dev/null && swapon -p 100 "\$z" 2>/dev/null; '
      '  done; '
      'fi; '
      // 5) Verify
      'if swapon --show=NAME --noheadings 2>/dev/null | grep -q zram; then '
      '  echo "ZRAM active"; '
      'else '
      '  echo "ZRAM service started (activation may need reboot)"; '
      'fi',
    );
  }

  // ─── DAVINCI RESOLVE ───

  static bool _isLibMoved(String libName) {
    final disabledDir = Directory('/opt/resolve/libs/disabled_libs');
    if (!disabledDir.existsSync()) return false;
    return disabledDir.listSync().any((f) => f.path.contains(libName));
  }

  static bool _isUnneededDir() {
    final unneededDir = Directory('/opt/resolve/libs/unneeded');
    if (!unneededDir.existsSync()) return false;
    return unneededDir.listSync().any((f) => f.path.contains('libglib'));
  }

  static bool _hasDisabledLibs() {
    return _isLibMoved('libglib') || _isUnneededDir();
  }

  static Future<List<DavinciFix>> getDavinciFixes() async {
    final fixes = <DavinciFix>[];

    final libsFixed = _hasDisabledLibs();

    // Fix 1: Conflicting GLib libraries
    fixes.add(DavinciFix(
      id: 'glib_conflict',
      title: 'Fix GLib library conflict (g_once_init_leave_pointer)',
      description: 'DaVinci Resolve bundles older GLib that conflicts with the system version. '
          'This causes "symbol lookup error: g_once_init_leave_pointer" on launch. '
          'Moving bundled libraries forces Resolve to use the system version.',
      command: 'mkdir -p /opt/resolve/libs/disabled_libs && '
          'mv /opt/resolve/libs/libglib-2.0.so* /opt/resolve/libs/disabled_libs/ 2>/dev/null; '
          'mv /opt/resolve/libs/libgio-2.0.so* /opt/resolve/libs/disabled_libs/ 2>/dev/null; '
          'mv /opt/resolve/libs/libgmodule-2.0.so* /opt/resolve/libs/disabled_libs/ 2>/dev/null; '
          'mv /opt/resolve/libs/libgobject-2.0.so* /opt/resolve/libs/disabled_libs/ 2>/dev/null; '
          'echo "GLib libraries moved"',
      requiresRestart: true,
      isCurrentlyApplied: libsFixed,
    ));

    // Fix 2: Missing system dependencies (APT)
    fixes.add(DavinciFix(
      id: 'missing_deps_apt',
      title: 'Install missing dependencies (Ubuntu/Debian)',
      description: 'Installs all required libraries for Ubuntu/Debian: libapr1, libaprutil1, '
          'libasound2t64, libglib2.0-0t64, libxcb-composite0, libxcb-cursor0, libfuse2, '
          'libqt5x11extras5, libglu1-mesa.',
      command: 'apt-get update -qq && apt-get install -y libapr1 libaprutil1 libasound2t64 '
          'libglib2.0-0t64 libglib2.0-bin libxcb-composite0 libxcb-cursor0 libfuse2 '
          'libqt5x11extras5 libglu1-mesa',
    ));

    // Fix 3: Missing system dependencies (DNF)
    fixes.add(DavinciFix(
      id: 'missing_deps_dnf',
      title: 'Install missing dependencies (Fedora/RHEL)',
      description: 'Installs required libraries for Fedora/RHEL systems.',
      command: 'dnf install -y apr apr-util alsa-lib glib2 libxcb libxkbcommon fuse2 '
          'mesa-libGLU libXcursor',
    ));

    // Fix 4: Missing system dependencies (Pacman)
    fixes.add(DavinciFix(
      id: 'missing_deps_pacman',
      title: 'Install missing dependencies (Arch/Manjaro)',
      description: 'Installs required libraries for Arch Linux and derivatives.',
      command: 'pacman -S --needed --noconfirm base-devel libxcrypt-compat glu apr-util '
          'libxcb libxkbcommon fuse2',
    ));

    // Fix 5: SKIP_PACKAGE_CHECK
    fixes.add(const DavinciFix(
      id: 'skip_pkg_check',
      title: 'Run installer with SKIP_PACKAGE_CHECK=1',
      description: 'The installer checks for legacy package names that no longer exist on '
          'Ubuntu 24.04+. This flag bypasses the outdated check.',
      command: 'SKIP_PACKAGE_CHECK=1 ./DaVinci_Resolve_*_Linux.run -i',
    ));

    // Fix 6: Wayland incompatibility
    String sessionType = 'unknown';
    try {
      sessionType = Platform.environment['XDG_SESSION_TYPE'] ?? 'unknown';
    } catch (_) {}
    final isWayland = sessionType == 'wayland';

    fixes.add(DavinciFix(
      id: 'wayland',
      title: isWayland ? 'Wayland session detected — switch to X11' : 'Display server: X11 (OK)',
      description: isWayland
          ? 'DaVinci Resolve does not support Wayland natively. '
              'Log out and select "Ubuntu on Xorg" or equivalent at the login screen.'
          : 'Your session is using X11, which is compatible with DaVinci Resolve.',
      command: '',
      isCurrentlyApplied: !isWayland,
    ));

    // Fix 7: NVIDIA driver
    String nvidiaVersion = '';
    try {
      final result = await Process.run('nvidia-smi', ['--query-gpu=driver_version', '--format=csv,noheader']);
      if (result.exitCode == 0) {
        nvidiaVersion = (result.stdout as String).trim().split('\n').first;
      }
    } catch (_) {}

    final hasNvidia = nvidiaVersion.isNotEmpty;
    final nvidiaOk = hasNvidia && _compareVersions(nvidiaVersion, '525.0');

    fixes.add(DavinciFix(
      id: 'nvidia_driver',
      title: hasNvidia
          ? (nvidiaOk ? 'NVIDIA driver $nvidiaVersion (compatible)' : 'NVIDIA driver $nvidiaVersion (too old, need ≥525)')
          : 'Install NVIDIA driver (525+)',
      description: hasNvidia
          ? (nvidiaOk
              ? 'Your NVIDIA driver version is compatible with DaVinci Resolve.'
              : 'DaVinci Resolve requires NVIDIA driver 525 or newer for CUDA support.')
          : 'If you have an NVIDIA GPU, install the proprietary driver for CUDA support.',
      command: hasNvidia ? '' : 'apt-get install -y nvidia-driver-535 2>/dev/null || '
          'dnf install -y nvidia-driver 2>/dev/null || '
          'pacman -S --noconfirm nvidia nvidia-utils 2>/dev/null; '
          'echo "Driver installed — reboot required"',
      isCurrentlyApplied: nvidiaOk,
      requiresRestart: hasNvidia && !nvidiaOk,
    ));

    // Fix 8: AMD ROCm OpenCL
    fixes.add(const DavinciFix(
      id: 'amdgpu_opencl',
      title: 'Install AMD ROCm OpenCL (AMD GPUs)',
      description: 'For AMD GPUs: install ROCm OpenCL runtime for DaVinci Resolve GPU acceleration. '
          'Requires Vega 10 or newer GPU.',
      command: 'apt-get install -y rocm-opencl-runtime 2>/dev/null || '
          'dnf install -y rocm-opencl-runtime 2>/dev/null || '
          'pacman -S --noconfirm rocm-opencl-runtime 2>/dev/null; '
          'usermod -aG render,video \$(whoami); '
          'echo "ROCm OpenCL installed — logout/login required"',
    ));

    // Fix 9: Intel OpenCL
    fixes.add(const DavinciFix(
      id: 'intel_opencl',
      title: 'Install Intel OpenCL runtime (Intel GPUs)',
      description: 'For Intel GPUs: install the Intel compute runtime for OpenCL support.',
      command: 'apt-get install -y intel-opencl-icd 2>/dev/null || '
          'dnf install -y intel-opencl-icd 2>/dev/null || '
          'pacman -S --noconfirm intel-compute-runtime 2>/dev/null; '
          'echo "Intel OpenCL installed"',
    ));

    // Fix 10: H.264/H.265 codec workaround
    fixes.add(const DavinciFix(
      id: 'codec_fix',
      title: 'Transcode H.264/H.265 to DNxHR (free edition)',
      description: 'The free edition of DaVinci Resolve cannot decode H.264/H.265 on Linux. '
          'Transcode your footage to DNxHR using FFmpeg before importing.',
      command: 'ffmpeg -i input.mp4 -c:v dnxhd -profile:v dnxhr_hq -c:a pcm_s16le output.mov',
    ));

    // Fix 11: Audio configuration
    fixes.add(const DavinciFix(
      id: 'audio_fix',
      title: 'Fix audio (ALSA/PipeWire compatibility)',
      description: 'If Resolve has no audio output, install the ALSA plugin for your audio server '
          'and set the audio output in Fairlight > Audio I/O.',
      command: 'apt-get install -y libasound2-plugins pulseaudio-utils 2>/dev/null || '
          'dnf install -y alsa-plugins-pulseaudio 2>/dev/null || '
          'pacman -S --noconfirm libpulse 2>/dev/null; '
          'echo "Audio plugins installed"',
    ));

    // Fix 12: Desktop launcher refresh
    fixes.add(const DavinciFix(
      id: 'desktop_refresh',
      title: 'Refresh desktop launcher database',
      description: 'If DaVinci Resolve does not appear in the application menu after installation.',
      command: 'update-desktop-database /usr/share/applications/ 2>/dev/null; echo "Desktop database refreshed"',
    ));

    // Fix 13: Library path fix (ldconfig)
    fixes.add(const DavinciFix(
      id: 'ldconfig',
      title: 'Run ldconfig (fix "Could not load libcuda.so")',
      description: 'If Resolve reports missing libcuda.so, update the linker cache after driver installation.',
      command: 'ldconfig; echo "ldconfig completed"',
    ));

    // Fix 14: GPU memory limit (info only)
    fixes.add(const DavinciFix(
      id: 'gpu_memory',
      title: 'GPU memory full — set manual VRAM limit',
      description: 'If Resolve shows "GPU memory full" on launch, manually set the GPU memory limit '
          'to 10-15% below your actual VRAM capacity in Preferences > System > Memory and GPU.',
      command: '',
    ));

    return fixes;
  }

  static bool _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).whereType<int>().toList();
    final parts2 = v2.split('.').map(int.tryParse).whereType<int>().toList();
    for (int i = 0; i < _max(parts1.length, parts2.length); i++) {
      final a = i < parts1.length ? parts1[i] : 0;
      final b = i < parts2.length ? parts2[i] : 0;
      if (a != b) return a > b;
    }
    return true;
  }

  static int _max(int a, int b) => a > b ? a : b;
}
