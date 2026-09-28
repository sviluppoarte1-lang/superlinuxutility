import 'dart:io';
import 'password_storage.dart';

enum DriverStatus { installed, available, missing, firmwareUpdate, unknown }

class DriverInfo {
  final String deviceId;
  final String deviceName;
  final String category;
  final String? currentDriver;
  final List<String> candidatePackages;
  final String? recommendedDriver;
  final DriverStatus status;
  final String? version;
  final String? vendorId;
  final String? productId;
  final bool dkmsWarning;

  const DriverInfo({
    required this.deviceId,
    required this.deviceName,
    required this.category,
    this.currentDriver,
    this.candidatePackages = const [],
    this.recommendedDriver,
    this.status = DriverStatus.unknown,
    this.version,
    this.vendorId,
    this.productId,
    this.dkmsWarning = false,
  });

  DriverInfo copyWith({
    DriverStatus? status,
    String? version,
    bool? dkmsWarning,
    List<String>? candidatePackages,
  }) =>
      DriverInfo(
        deviceId: deviceId,
        deviceName: deviceName,
        category: category,
        currentDriver: currentDriver,
        candidatePackages: candidatePackages ?? this.candidatePackages,
        recommendedDriver: recommendedDriver,
        status: status ?? this.status,
        version: version ?? this.version,
        vendorId: vendorId,
        productId: productId,
        dkmsWarning: dkmsWarning ?? this.dkmsWarning,
      );
}

class FirmwareUpdate {
  final String deviceName;
  final String currentVersion;
  final String latestVersion;
  final String devicePath;
  final bool needsReboot;

  const FirmwareUpdate({
    required this.deviceName,
    required this.currentVersion,
    required this.latestVersion,
    required this.devicePath,
    this.needsReboot = false,
  });
}

class DriverScanResult {
  final List<DriverInfo> drivers;
  final List<FirmwareUpdate> firmwareUpdates;
  final String? error;
  final String kernelInfo;

  const DriverScanResult({
    required this.drivers,
    required this.firmwareUpdates,
    this.error,
    this.kernelInfo = '',
  });
}

class _ChipsetEntry {
  final Map<String, List<String>> packages;
  final String? driver;
  final String category;
  final String? name;

  const _ChipsetEntry({
    required this.packages,
    this.driver,
    required this.category,
    this.name,
  });
}

class DriverManagerService {
  static const _chipsetDb = <String, _ChipsetEntry>{
    '10de': _ChipsetEntry(
      packages: {
        'apt': ['nvidia-driver-535', 'nvidia-driver-530', 'nvidia-driver-525'],
        'dnf': ['xorg-x11-drv-nvidia-cuda', 'xorg-x11-drv-nvidia'],
        'pacman': ['nvidia-dkms', 'nvidia'],
        'zypper': ['nvidia-glG06'],
      },
      driver: 'nvidia',
      category: 'Graphics',
    ),
    '1002': _ChipsetEntry(
      packages: {
        'apt': ['firmware-amd-graphics', 'xserver-xorg-video-amdgpu'],
        'dnf': ['xorg-x11-drv-amdgpu', 'mesa-dri-drivers'],
        'pacman': ['xf86-video-amdgpu', 'mesa'],
        'zypper': ['xf86-video-amdgpu'],
      },
      driver: 'amdgpu',
      category: 'Graphics',
    ),
    '10ec:8812': _ChipsetEntry(
      packages: {
        'apt': ['rtl8812au-dkms'],
        'dnf': ['rtl8812au-dkms'],
        'pacman': ['rtl8812au-dkms-git', 'rtl8812au-dkms'],
        'zypper': ['rtl8812au-dkms'],
      },
      driver: '8812au',
      category: 'Network',
      name: 'Realtek RTL8812AU Wi-Fi',
    ),
    '10ec:8168': _ChipsetEntry(
      packages: {},
      driver: 'r8169',
      category: 'Network',
      name: 'Realtek RTL8168 Ethernet',
    ),
    '10ec:8821': _ChipsetEntry(
      packages: {
        'apt': ['rtl8821ce-dkms'],
        'dnf': ['rtl8821ce-dkms'],
        'pacman': ['rtl8821ce-dkms-git', 'rtl8821ce-dkms'],
        'zypper': ['rtl8821ce-dkms'],
      },
      driver: '8821ce',
      category: 'Network',
      name: 'Realtek RTL8821CE Wi-Fi',
    ),
    '10ec:b822': _ChipsetEntry(
      packages: {
        'apt': ['rtl8822be-dkms'],
        'dnf': ['rtl8822be-dkms'],
        'pacman': ['rtl8822be-dkms-git', 'rtl8822be-dkms'],
        'zypper': ['rtl8822be-dkms'],
      },
      driver: '8822be',
      category: 'Network',
      name: 'Realtek RTL8822BE Wi-Fi',
    ),
    '14e4:43a0': _ChipsetEntry(
      packages: {
        'apt': ['firmware-brcm80211', 'broadcom-sta-dkms'],
        'dnf': ['broadcom-wl'],
        'pacman': ['broadcom-wl-dkms', 'broadcom-wl'],
        'zypper': ['broadcom-wl'],
      },
      driver: 'wl',
      category: 'Network',
      name: 'Broadcom Wi-Fi',
    ),
    '14e4:4343': _ChipsetEntry(
      packages: {
        'apt': ['firmware-brcm80211', 'broadcom-sta-dkms'],
        'dnf': ['broadcom-wl'],
        'pacman': ['broadcom-wl-dkms', 'broadcom-wl'],
        'zypper': ['broadcom-wl'],
      },
      driver: 'wl',
      category: 'Network',
      name: 'Broadcom Wi-Fi',
    ),
    '8086:0a2e': _ChipsetEntry(
      packages: {
        'apt': ['firmware-iwlwifi'],
        'dnf': ['iwlwifi-firmware'],
        'pacman': ['linux-firmware'],
        'zypper': ['iwlwifi-firmware'],
      },
      driver: 'iwlwifi',
      category: 'Network',
      name: 'Intel Wi-Fi',
    ),
    '8086:2723': _ChipsetEntry(
      packages: {
        'apt': ['firmware-iwlwifi'],
        'dnf': ['iwlwifi-firmware'],
        'pacman': ['linux-firmware'],
        'zypper': ['iwlwifi-firmware'],
      },
      driver: 'iwlwifi',
      category: 'Network',
      name: 'Intel Wi-Fi 6 AX200',
    ),
    '8086:2725': _ChipsetEntry(
      packages: {
        'apt': ['firmware-iwlwifi'],
        'dnf': ['iwlwifi-firmware'],
        'pacman': ['linux-firmware'],
        'zypper': ['iwlwifi-firmware'],
      },
      driver: 'iwlwifi',
      category: 'Network',
      name: 'Intel Wi-Fi 6E AX211',
    ),
  };

  static String? _packageManager;
  static String? _runningKernel;
  static bool? _dkmsCapable;

  static Future<String> _detectPackageManager() async {
    if (_packageManager != null) return _packageManager!;
    for (final pm in ['apt', 'dnf', 'pacman', 'zypper']) {
      final r = await Process.run('which', [pm]);
      if (r.exitCode == 0) {
        _packageManager = pm;
        return pm;
      }
    }
    _packageManager = 'apt';
    return _packageManager!;
  }

  static Future<String> _detectRunningKernel() async {
    if (_runningKernel != null) return _runningKernel!;
    final r = await Process.run('uname', ['-r']);
    _runningKernel = (r.stdout as String? ?? '').trim();
    return _runningKernel!;
  }

  static Future<bool> _canBuildDkms() async {
    if (_dkmsCapable != null) return _dkmsCapable!;
    final pm = await _detectPackageManager();
    final kernel = await _detectRunningKernel();
    bool canBuild = false;

    switch (pm) {
      case 'apt':
        final r = await Process.run(
          'bash',
          ['-c', 'dpkg -l 2>/dev/null | grep linux-headers'],
        );
        if ((r.stdout as String? ?? '').contains('linux-headers')) {
          canBuild = true;
        } else {
          final f = File('/usr/src/linux-headers-$kernel/Makefile');
          canBuild = await f.exists();
        }
        break;
      case 'dnf':
        final r = await Process.run(
          'bash',
          ['-c', 'rpm -qa 2>/dev/null | grep kernel-headers'],
        );
        canBuild = (r.stdout as String? ?? '').isNotEmpty;
        break;
      case 'pacman':
        for (final hdrPkg in [
          'linux-headers',
          'linux-xanmod-headers',
          'linux-lts-headers',
        ]) {
          final r = await Process.run('pacman', ['-Q', hdrPkg]);
          if (r.exitCode == 0) {
            canBuild = true;
            break;
          }
        }
        break;
      case 'zypper':
        final r = await Process.run(
          'bash',
          ['-c', 'rpm -qa 2>/dev/null | grep kernel-default-devel'],
        );
        canBuild = (r.stdout as String? ?? '').isNotEmpty;
        break;
      default:
        canBuild = false;
    }

    _dkmsCapable = canBuild;
    return canBuild;
  }

  static bool _isDkmsPackage(String pkg) => pkg.contains('dkms');

  static Future<ProcessResult> _runSudo(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password not saved.');
    }
    final escaped = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('`', r'\`')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll("'", r"\'");
    final full =
        'printf "%s\\n" "$escaped" | sudo -S bash -c ${_shellQuote(command)} 2>&1';
    return Process.run('bash', ['-c', full], runInShell: true);
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static Future<String> _run(String cmd) async {
    try {
      final r = await Process.run('bash', ['-c', cmd], runInShell: true);
      return ((r.stdout as String?) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Detect all PCI/USB devices and check for known drivers.
  static Future<DriverScanResult> scanDrivers() async {
    try {
      final pm = await _detectPackageManager();
      final kernel = await _detectRunningKernel();
      final pciDevices = await _scanPciDevices();
      final usbDevices = await _scanUsbDevices();
      final allDevices = [...pciDevices, ...usbDevices];

      final drivers = <DriverInfo>[];
      for (final d in allDevices) {
        final entry = _lookupChipset(d);
        if (entry == null) continue;

        final candidates = entry.packages[pm] ?? [];
        final isLoaded = entry.driver != null
            ? await _isModuleLoaded(entry.driver!)
            : false;

        String? firstAvailable;
        bool firstIsInstalled = false;
        for (final c in candidates) {
          if (await _isPackageInstalled(c)) {
            firstAvailable = c;
            firstIsInstalled = true;
            break;
          }
        }
        firstAvailable ??= candidates.isNotEmpty ? candidates.first : null;

        bool dkmsWarn = false;
        if (firstAvailable != null &&
            _isDkmsPackage(firstAvailable) &&
            !(await _canBuildDkms())) {
          dkmsWarn = true;
        }

        DriverStatus status;
        if (isLoaded || firstIsInstalled) {
          status = DriverStatus.installed;
        } else if (firstAvailable != null && !dkmsWarn) {
          status = DriverStatus.available;
        } else if (firstAvailable != null && dkmsWarn) {
          status = DriverStatus.available;
        } else {
          status = DriverStatus.missing;
        }

        drivers.add(DriverInfo(
          deviceId: d['id'] ?? '',
          deviceName: entry.name ?? d['name'] ?? 'Unknown device',
          category: entry.category,
          currentDriver: await _getCurrentDriver(d['slot'] ?? ''),
          candidatePackages: candidates,
          recommendedDriver: entry.driver,
          status: status,
          vendorId: d['vendorId'],
          productId: d['productId'],
          dkmsWarning: dkmsWarn,
        ));
      }

      final firmwareUpdates = await _checkFirmwareUpdates();

      return DriverScanResult(
        drivers: drivers,
        firmwareUpdates: firmwareUpdates,
        kernelInfo: 'Running kernel: $kernel',
      );
    } catch (e) {
      return DriverScanResult(
        drivers: [],
        firmwareUpdates: [],
        error: e.toString(),
      );
    }
  }

  static _ChipsetEntry? _lookupChipset(Map<String, String> device) {
    final vid = device['vendorId'] ?? '';
    final pid = device['productId'] ?? '';
    final fullKey = '$vid:$pid';

    if (_chipsetDb.containsKey(fullKey)) return _chipsetDb[fullKey];
    if (_chipsetDb.containsKey(vid)) return _chipsetDb[vid];
    return null;
  }

  static Future<List<Map<String, String>>> _scanPciDevices() async {
    final output = await _run('lspci -nn 2>/dev/null');
    if (output.isEmpty) return [];
    final devices = <Map<String, String>>[];
    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      final idMatch =
          RegExp(r'^([0-9a-f]{2}:[0-9a-f]{2}\.[0-9])').firstMatch(line);
      if (idMatch == null) continue;
      final slot = idMatch.group(1)!;
      final nameMatch = RegExp(r':\s*(.+?)\s*\[').firstMatch(line);
      final name = nameMatch?.group(1)?.trim() ?? line;
      final vidPid =
          RegExp(r'\[([0-9a-f]{4}):([0-9a-f]{4})\]').firstMatch(line);
      devices.add({
        'id': slot,
        'slot': '0000:$slot',
        'name': name,
        'vendorId': vidPid?.group(1) ?? '',
        'productId': vidPid?.group(2) ?? '',
        'bus': 'pci',
      });
    }
    return devices;
  }

  static Future<List<Map<String, String>>> _scanUsbDevices() async {
    final output = await _run('lsusb 2>/dev/null');
    if (output.isEmpty) return [];
    final devices = <Map<String, String>>[];
    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      final idMatch =
          RegExp(r'ID\s+([0-9a-f]{4}):([0-9a-f]{4})').firstMatch(line);
      if (idMatch == null) continue;
      final nameMatch = RegExp(r'ID\s+[0-9a-f]{4}:[0-9a-f]{4}\s+(.*)$')
          .firstMatch(line);
      devices.add({
        'id': '${idMatch.group(1)}:${idMatch.group(2)}',
        'slot': '',
        'name': nameMatch?.group(1)?.trim() ?? 'USB Device',
        'vendorId': idMatch.group(1)!,
        'productId': idMatch.group(2)!,
        'bus': 'usb',
      });
    }
    return devices;
  }

  static Future<String?> _getCurrentDriver(String sysfsPath) async {
    if (sysfsPath.isEmpty) return null;
    try {
      final driverLink = '/sys/bus/pci/devices/$sysfsPath/driver';
      final target = await File(driverLink).resolveSymbolicLinks();
      return target.split('/').last;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _isPackageInstalled(String package) async {
    final pm = await _detectPackageManager();
    String cmd;
    switch (pm) {
      case 'apt':
        // Primary: dpkg -s (fast, exact)
        cmd =
            'dpkg -s $package 2>/dev/null | grep -q "^Status: install ok installed"';
        break;
      case 'dnf':
        cmd = 'rpm -q $package >/dev/null 2>&1';
        break;
      case 'pacman':
        cmd = 'pacman -Qi $package >/dev/null 2>&1';
        break;
      case 'zypper':
        cmd = 'rpm -q $package >/dev/null 2>&1';
        break;
      default:
        return false;
    }
    final r = await Process.run('bash', ['-c', cmd]);
    if (r.exitCode == 0) return true;

    // Fallback for apt: dpkg -l | grep (handles transitional/virtual packages)
    if (pm == 'apt') {
      final r2 = await Process.run(
          'bash', ['-c', 'dpkg -l 2>/dev/null | grep -qw $package']);
      if (r2.exitCode == 0) return true;
    }

    return false;
  }

  static Future<bool> _isModuleLoaded(String module) async {
    final r = await _run('lsmod 2>/dev/null | grep -w $module');
    return r.isNotEmpty;
  }

  /// Install the driver package for a given device, trying fallback candidates.
  static Future<String> installDriver(DriverInfo driver) async {
    if (driver.candidatePackages.isEmpty) {
      return 'No package available for this device.';
    }
    final pm = await _detectPackageManager();

    for (final pkg in driver.candidatePackages) {
      if (_isDkmsPackage(pkg) && !(await _canBuildDkms())) {
        final headerResult = await _installKernelHeaders();
        if (headerResult != 'ok') {
          continue;
        }
      }

      String cmd;
      switch (pm) {
        case 'apt':
          cmd =
              'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg';
          break;
        case 'dnf':
          cmd = 'dnf install -y $pkg';
          break;
        case 'pacman':
          cmd = 'pacman -Sy --noconfirm $pkg';
          break;
        case 'zypper':
          cmd = 'zypper --non-interactive install $pkg';
          break;
        default:
          return 'Unsupported package manager.';
      }
      final r = await _runSudo(cmd);
      if (r.exitCode == 0) {
        return 'ok';
      }
    }

    final r = await _runSudo(_buildInstallCmd(
      pm,
      driver.candidatePackages.last,
    ));
    return r.exitCode == 0 ? 'ok' : r.stdout.toString().trim();
  }

  static Future<String> _installKernelHeaders() async {
    final pm = await _detectPackageManager();
    String pkg;
    switch (pm) {
      case 'apt':
        final kernel = await _detectRunningKernel();
        pkg = 'linux-headers-$kernel';
        break;
      case 'dnf':
        pkg = 'kernel-headers';
        break;
      case 'pacman':
        pkg = 'linux-headers';
        break;
      case 'zypper':
        pkg = 'kernel-default-devel';
        break;
      default:
        return 'Unsupported package manager.';
    }
    final installed = await _isPackageInstalled(pkg);
    if (installed) return 'ok';
    final cmd = _buildInstallCmd(pm, pkg);
    final r = await _runSudo(cmd);
    return r.exitCode == 0 ? 'ok' : r.stdout.toString().trim();
  }

  static String _buildInstallCmd(String pm, String pkg) {
    switch (pm) {
      case 'apt':
        return 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg';
      case 'dnf':
        return 'dnf install -y $pkg';
      case 'pacman':
        return 'pacman -Sy --noconfirm $pkg';
      case 'zypper':
        return 'zypper --non-interactive install $pkg';
      default:
        return 'echo "Unsupported package manager"';
    }
  }

  /// Check for firmware updates via fwupdmgr or linux-firmware package.
  static Future<List<FirmwareUpdate>> _checkFirmwareUpdates() async {
    final updates = <FirmwareUpdate>[];
    final hasFwupd = await _run('which fwupdmgr');
    if (hasFwupd.isNotEmpty) {
      await _run('fwupdmgr refresh --force 2>/dev/null');
      final output = await _run('fwupdmgr get-updates 2>/dev/null');
      if (output.contains('No updates available')) return updates;
      final lines = output.split('\n');
      String? name, current, latest, path;
      for (final line in lines) {
        if (line.contains('│')) {
          final parts = line.split('│').map((s) => s.trim()).toList();
          if (parts.length >= 2) {
            final key = parts[0].toLowerCase();
            if (key.contains('device')) name = parts[1];
            if (key.contains('current')) current = parts[1];
            if (key.contains('available') || key.contains('new')) {
              latest = parts[1];
            }
            if (key.contains('id')) path = parts[1];
          }
        }
      }
      if (name != null && current != null && latest != null) {
        updates.add(FirmwareUpdate(
          deviceName: name,
          currentVersion: current,
          latestVersion: latest,
          devicePath: path ?? '',
          needsReboot: output.toLowerCase().contains('reboot'),
        ));
      }
    }
    return updates;
  }

  /// Apply a firmware update via fwupdmgr.
  static Future<String> applyFirmwareUpdate(FirmwareUpdate update) async {
    final hasFwupd = await _run('which fwupdmgr');
    if (hasFwupd.isEmpty) {
      return 'fwupdmgr not available.';
    }
    final r = await _runSudo('fwupdmgr update --no-reboot-check 2>&1');
    if (r.exitCode == 0) {
      return 'ok';
    }
    return r.stdout.toString().trim();
  }

  /// Install linux-firmware package (covers most firmware blobs).
  static Future<String> installLinuxFirmware() async {
    final pm = await _detectPackageManager();
    List<String> candidates;
    switch (pm) {
      case 'apt':
        candidates = ['linux-firmware', 'firmware-linux-free', 'firmware-misc-nonfree'];
        break;
      case 'dnf':
        candidates = ['linux-firmware'];
        break;
      case 'pacman':
        candidates = ['linux-firmware'];
        break;
      case 'zypper':
        candidates = ['linux-firmware'];
        break;
      default:
        return 'Unsupported package manager.';
    }

    for (final pkg in candidates) {
      final installed = await _isPackageInstalled(pkg);
      if (installed) return 'ok';

      final cmd = _buildInstallCmd(pm, pkg);
      final r = await _runSudo(cmd);
      if (r.exitCode == 0) return 'ok';
    }

    final cmd = _buildInstallCmd(pm, candidates.last);
    final r = await _runSudo(cmd);
    return r.exitCode == 0 ? 'ok' : r.stdout.toString().trim();
  }

  /// Reload a kernel module (requires root).
  static Future<String> reloadModule(String module) async {
    final r = await _runSudo('modprobe -r $module && modprobe $module');
    return r.exitCode == 0 ? 'ok' : r.stdout.toString().trim();
  }
}
