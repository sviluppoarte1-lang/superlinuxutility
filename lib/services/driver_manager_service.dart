import 'dart:io';
import 'password_storage.dart';
import '../utils/process_utils.dart';

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
  final String? installedPackageName;
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
    this.installedPackageName,
    this.vendorId,
    this.productId,
    this.dkmsWarning = false,
  });

  DriverInfo copyWith({
    DriverStatus? status,
    String? version,
    String? installedPackageName,
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
        installedPackageName: installedPackageName ?? this.installedPackageName,
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

/// Stato del pacchetto firmware linux (linux-firmware e varianti):
/// non installato / installato ma con aggiornamento / installato e aggiornato.
class LinuxFirmwareStatus {
  final bool installed;
  final bool updateAvailable;
  final List<String> installedPackages;
  final List<String> updatablePackages;

  const LinuxFirmwareStatus({
    required this.installed,
    required this.updateAvailable,
    this.installedPackages = const [],
    this.updatablePackages = const [],
  });
}

class _ChipsetEntry {
  final Map<String, List<String>> packages;
  final String? driver;
  final String category;
  final String? name;
  /// Pattern (regex, case-insensitive) dei nomi di pacchetto che implementano
  /// questo chipset su QUALSIASI PM. Serve per leggere la VERSIONE realmente
  /// installata dal database pacchetti (dpkg/rpm/pacman), indipendente dai
  /// candidati suggeriti (che possono essere datati).
  final List<String> installedPatterns;

  const _ChipsetEntry({
    required this.packages,
    this.driver,
    required this.category,
    this.name,
    this.installedPatterns = const [],
  });
}

class DriverManagerService {
  static const _chipsetDb = <String, _ChipsetEntry>{
    '10de': _ChipsetEntry(
      installedPatterns: [
        r'^nvidia-driver-[0-9]+$', r'^libnvidia-',
        r'^xorg-x11-drv-nvidia($|-cuda)?$', r'^akmod-nvidia$', r'^nvidia-(dkms|open|utils)?$', r'^nvidia-glG06$',
      ],
      packages: {
        // Fallback statico SOLO se l'interrogazione dinamica di apt-cache
        // fallisce; preferiti nvidia-driver-580+ in modo che l'elenco non
        // appaia "fermo a 535" su sistemi con driver più nuovi.
        'apt': [
          'nvidia-driver-580',
          'nvidia-driver-575',
          'nvidia-driver-570',
          'nvidia-driver-560',
          'nvidia-driver-550',
          'nvidia-driver-535',
        ],
        'dnf': ['xorg-x11-drv-nvidia-cuda', 'xorg-x11-drv-nvidia'],
        'pacman': ['nvidia-dkms', 'nvidia'],
        'zypper': ['nvidia-glG06'],
      },
      driver: 'nvidia',
      category: 'Graphics',
    ),
    '1002': _ChipsetEntry(
      installedPatterns: [
        r'^xserver-xorg-video-amdgpu$', r'^firmware-amd-graphics$',
        r'^xorg-x11-drv-amdgpu$', r'^mesa-dri-drivers$', r'^xf86-video-amdgpu$', r'^mesa$',
      ],
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
      installedPatterns: [r'^rtl8812au'],
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
      installedPatterns: [r'^r8169$'],
      packages: {},
      driver: 'r8169',
      category: 'Network',
      name: 'Realtek RTL8168 Ethernet',
    ),
    '10ec:8821': _ChipsetEntry(
      installedPatterns: [r'^rtl8821ce'],
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
      installedPatterns: [r'^rtl8822be'],
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
      installedPatterns: [r'^broadcom-sta', r'^broadcom-wl', r'^wl-kmod$', r'^firmware-brcm80211$'],
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
      installedPatterns: [r'^broadcom-sta', r'^broadcom-wl', r'^wl-kmod$', r'^firmware-brcm80211$'],
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
      installedPatterns: [r'^firmware-iwlwifi$', r'^iwlwifi-firmware$', r'^linux-firmware$'],
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
      installedPatterns: [r'^firmware-iwlwifi$', r'^iwlwifi-firmware$', r'^linux-firmware$'],
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
      installedPatterns: [r'^firmware-iwlwifi$', r'^iwlwifi-firmware$', r'^linux-firmware$'],
      packages: {
        'apt': ['firmware-iwlwifi'],
        'dnf': ['iwlwifi-firmware'],
        'pacman': ['linux-firmware'],
        'zypper': ['iwlwifi-firmware'],
      },
      driver: 'iwlwifi',
      category: 'Network',
      // NOTA: PCI 8086:2725 = AX210 (Typhoon Peak). L'AX211 esiste ma è solo
      // CNVio2 (non PCIe) e ha ID diversi — non usare AX211 qui per coerenza
      // con device_manager_service.
      name: 'Intel Wi-Fi 6E AX210',
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
    return runProcess('bash', ['-c', full], runInShell: true, timeout: const Duration(seconds: 180));
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static Future<String> _run(String cmd) async {
    try {
      final r = await runProcess('bash', ['-c', cmd], runInShell: true, timeout: const Duration(seconds: 20));
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
      final installedDb = await _installedPackages();
      final dynamicAptNvidia = pm == 'apt'
          ? await _queryAptNvidiaDrivers()
          : null;
      for (final d in allDevices) {
        final entry = _lookupChipset(d);
        if (entry == null) continue;

        var candidates = entry.packages[pm] ?? [];
        if (d['vendorId'] == '10de' && pm == 'apt' && dynamicAptNvidia != null) {
          candidates = dynamicAptNvidia;
        }
        final isLoaded = entry.driver != null
            ? await _isModuleLoaded(entry.driver!)
            : false;

        // Versioni reali dal database pacchetti: match con i pattern della
        // famiglia chipset + per-occupazione dei candidati.
        String? firstAvailable;
        final matchedInstalled =
            matchInstalledPackages(installedDb, entry.installedPatterns);
        final matchedByName = {
          for (final m in matchedInstalled) m.key: m.value,
        };
        final candidateInstalled =
            candidates.any((c) => installedDb.containsKey(c));
        final hasInstalled = matchedInstalled.isNotEmpty || candidateInstalled;

        String? installedName;
        String? installedVer;
        if (matchedByName.isNotEmpty) {
          installedName = candidates.firstWhere(
            (c) => matchedByName.containsKey(c),
            orElse: () => matchedInstalled.first.key,
          );
          installedVer = matchedByName[installedName];
        }

        // GPU NVIDIA: la versione driver ESATTA viene da nvidia-smi
        // (indipendente dal packaging della distro).
        if (entry.category == 'Graphics' && d['vendorId'] == '10de') {
          final smi = await _queryNvidiaSmiDriverVersion();
          if (smi != null) installedVer = smi;
        }

        firstAvailable ??= candidates.isNotEmpty ? candidates.first : null;

        bool dkmsWarn = false;
        if (firstAvailable != null &&
            _isDkmsPackage(firstAvailable) &&
            !(await _canBuildDkms())) {
          dkmsWarn = true;
        }

        DriverStatus status;
        if (isLoaded || hasInstalled) {
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
          version: installedVer,
          installedPackageName: hasInstalled ? installedName : null,
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
    if (_chipsetDb.containsKey(vid)) {
      final base = _chipsetDb[vid]!;
      // FALLBACK VENDOR-LEVEL (es. '10de'): matcha anche la funzione HDMI audio
      // della GPU (es. "00.1 Audio device" [10de:228e]) → ricategorizzala,
      // altrimenti la schermata Driver la raggruppa sotto "Graphics".
      final lowerName = (device['name'] ?? '').toLowerCase();
      if (base.category == 'Graphics' && lowerName.contains('audio')) {
        return _ChipsetEntry(
          packages: base.packages,
          driver: base.driver,
          category: 'Audio (GPU HDMI)',
          name: base.name,
        );
      }
      return base;
    }
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

  // ─── Versioni realmente installate (tutte le PM) ───────────────────────────
  static Map<String, String>? _installedPkgCache;
  static DateTime? _installedPkgCacheTs;

  /// Database "pacchetto → versione" installato. Un solo comando per scan,
  /// cache statica (TTL 2 min).
  static Future<Map<String, String>> _installedPackages() async {
    if (_installedPkgCache != null &&
        _installedPkgCacheTs != null &&
        DateTime.now().difference(_installedPkgCacheTs!) <
            const Duration(minutes: 2)) {
      return _installedPkgCache!;
    }
    final pm = await _detectPackageManager();
    String cmd;
    switch (pm) {
      case 'apt':
        cmd = r"LC_ALL=C dpkg-query -W -f='${Package}\t${Version}\t${db:Status-Status}\n' 2>/dev/null";
        break;
      case 'dnf':
      case 'zypper':
        cmd = r"LC_ALL=C rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\n'";
        break;
      case 'pacman':
        cmd = 'LC_ALL=C pacman -Q';
        break;
      default:
        return const {};
    }
    final out = await _run(cmd);
    final parsed = parseInstalledPackages(out, pm);
    _installedPkgCache = parsed;
    _installedPkgCacheTs = DateTime.now();
    return parsed;
  }

  /// Parser puro dell'output del database pacchetti per PM:
  /// - apt:  `name<TAB>version<TAB>status`
  /// - dnf/zypper: `name<TAB>version-release` (rpm -qa --qf)
  /// - pacman: `name version`
  /// Testato in driver_manager_test.
  static Map<String, String> parseInstalledPackages(String output, String pm) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      if (line.trim().isEmpty) continue;
      final cols = line.split('\t');
      switch (pm) {
        case 'apt':
          if (cols.length >= 2 && cols[0].trim().isNotEmpty) {
            final status = cols.length >= 3 ? cols[2].trim() : 'installed';
            if (status == 'installed' || status == 'half-installed') {
              map[cols[0].trim()] = cols[1].trim();
            }
          }
          break;
        case 'dnf':
        case 'zypper':
          if (cols.length >= 2 && cols[0].trim().isNotEmpty) {
            map[cols[0].trim()] = cols[1].trim();
          }
          break;
        case 'pacman':
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) map[parts[0]] = parts[1];
          break;
      }
    }
    return map;
  }

  /// Pacchetti installati che matchano i pattern della famiglia chipset.
  /// Puro e testato; pattern regex case-insensitive, pattern invalidi ignorati.
  static List<MapEntry<String, String>> matchInstalledPackages(
      Map<String, String> db, List<String> patterns) {
    final out = <MapEntry<String, String>>[];
    for (final e in db.entries) {
      for (final p in patterns) {
        RegExp? re;
        try {
          re = RegExp(p, caseSensitive: false);
        } catch (_) {
          re = null;
        }
        if (re != null && re.hasMatch(e.key)) {
          out.add(MapEntry(e.key, e.value));
          break;
        }
      }
    }
    return out;
  }

  /// Versione driver NVIDIA dall'hardware (nvidia-smi), es. "580.105.08":
  /// valida su QUALSIASI distro indipendentemente dal packaging.
  static String? _nvidiaDriverVersionCache;
  static DateTime? _nvidiaDriverVersionTs;

  static Future<String?> _queryNvidiaSmiDriverVersion() async {
    if (_nvidiaDriverVersionCache != null &&
        _nvidiaDriverVersionTs != null &&
        DateTime.now().difference(_nvidiaDriverVersionTs!) <
            const Duration(minutes: 5)) {
      return _nvidiaDriverVersionCache;
    }
    String? ver;
    try {
      final r = await runProcess('nvidia-smi',
          ['--query-gpu=driver_version', '--format=csv,noheader'],
          timeout: const Duration(seconds: 8));
      final out = ((r.stdout as String?) ?? '').trim();
      if (RegExp(r'^\d{3,4}\.\d+(\.\d+)?$').hasMatch(out.split('\n').first)) {
        ver = out.split('\n').first.trim();
      }
    } catch (_) {
      ver = null;
    }
    if (ver != null) {
      _nvidiaDriverVersionCache = ver;
      _nvidiaDriverVersionTs = DateTime.now();
    }
    return ver;
  }

  /// Versioni dei driver NVIDIA di Ubuntu/Debian disponibili nei repository
  /// (`apt-cache search --names-only '^nvidia-driver-[0-9]+$'`), ordinate
  /// dalla più recente. Fallback: lista statica nel DB. Cache statica 10 min.
  static List<String>? _aptNvidiaCache;
  static DateTime? _aptNvidiaTs;

  static Future<List<String>?> _queryAptNvidiaDrivers() async {
    if (_aptNvidiaCache != null &&
        _aptNvidiaTs != null &&
        DateTime.now().difference(_aptNvidiaTs!) < const Duration(minutes: 10)) {
      return _aptNvidiaCache;
    }
    List<String>? result;
    try {
      final out = await _run(
          r"LC_ALL=C apt-cache search --names-only '^nvidia-driver-[0-9]+$' 2>/dev/null");
      final versions = <int>[];
      for (final line in out.split('\n')) {
        final m = RegExp(r'^nvidia-driver-(\d+)\b').firstMatch(line.trim());
        if (m != null && !versions.contains(int.parse(m.group(1)!))) {
          versions.add(int.parse(m.group(1)!));
        }
      }
      versions.sort((a, b) => b - a);
      if (versions.isNotEmpty) {
        result = versions.take(3).map((v) => 'nvidia-driver-$v').toList();
      }
    } catch (_) {
      result = null;
    }
    if (result != null) {
      _aptNvidiaCache = result;
      _aptNvidiaTs = DateTime.now();
    }
    return result;
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

  /// Pacchetti firmware candidati per il package manager corrente.
  static List<String> _firmwareCandidates(String pm) {
    switch (pm) {
      case 'apt':
        // Ubuntu/Zorin/Mint: linux-firmware; Debian: firmware-linux-*.
        return [
          'linux-firmware',
          'firmware-linux-nonfree',
          'firmware-linux-free',
          'firmware-misc-nonfree',
        ];
      case 'dnf':
      case 'pacman':
      case 'zypper':
        return ['linux-firmware'];
      default:
        return ['linux-firmware'];
    }
  }

  /// Stato attuale del pacchetto firmware: installato? aggiornamento pronto?
  static Future<LinuxFirmwareStatus> getLinuxFirmwareStatus() async {
    final pm = await _detectPackageManager();
    final candidates = _firmwareCandidates(pm);
    final installed = <String>[];
    for (final pkg in candidates) {
      if (await _isPackageInstalled(pkg)) installed.add(pkg);
    }
    if (installed.isEmpty) {
      return const LinuxFirmwareStatus(
          installed: false, updateAvailable: false);
    }

    final updatable = <String>[];
    switch (pm) {
      case 'apt':
        final r = await Process.run(
          'bash',
          [
            '-c',
            'LC_ALL=C apt-cache policy ${installed.join(' ')} 2>/dev/null'
          ],
          runInShell: false,
        );
        if (r.exitCode == 0) {
          updatable
              .addAll(parseAptPolicyUpdatable(r.stdout.toString(), installed));
        }
        break;
      case 'dnf':
        // exit 100 = aggiornamenti disponibili (dnf check-update convention).
        final r = await Process.run(
          'bash',
          [
            '-c',
            'LC_ALL=C dnf check-update -q ${installed.join(' ')} 2>/dev/null'
          ],
          runInShell: false,
        );
        if (r.exitCode == 100) updatable.addAll(installed);
        break;
      case 'pacman':
        final r = await Process.run(
          'bash',
          [
            '-c',
            'LC_ALL=C pacman -Qu ${installed.join(' ')} 2>/dev/null'
          ],
          runInShell: false,
        );
        final out = r.stdout.toString();
        for (final pkg in installed) {
          if (out.contains(pkg)) updatable.add(pkg);
        }
        break;
      case 'zypper':
        final r = await Process.run(
          'bash',
          [
            '-c',
            'LC_ALL=C zypper --non-interactive list-updates 2>/dev/null '
                '| grep -E "linux-firmware|firmware-linux"'
          ],
          runInShell: false,
        );
        if (r.stdout.toString().trim().isNotEmpty) updatable.addAll(installed);
        break;
    }
    return LinuxFirmwareStatus(
      installed: true,
      updateAvailable: updatable.isNotEmpty,
      installedPackages: installed,
      updatablePackages: updatable,
    );
  }

  /// Parsifica l'output di `apt-cache policy` e ritorna i pacchetti per cui
  /// Candidate differisce da Installed (aggiornamento disponibile).
  static List<String> parseAptPolicyUpdatable(
      String output, List<String> packages) {
    final updatable = <String>[];
    String? current;
    String? installed;
    String? candidate;

    void flush() {
      if (current != null &&
          installed != null &&
          candidate != null &&
          installed != '(none)' &&
          candidate != '(none)' &&
          candidate != installed) {
        updatable.add(current!);
      }
      current = null;
      installed = null;
      candidate = null;
    }

    for (final line in output.split('\n')) {
      if (line.isEmpty) continue;
      // Intestazione del pacchetto: "linux-firmware:" (colonna 0).
      if (!line.startsWith(' ') && line.trimRight().endsWith(':')) {
        flush();
        current = line.trimRight();
        current = current!.substring(0, current!.length - 1);
        continue;
      }
      final i = RegExp(r'^\s+Installed:\s*(.+)$').firstMatch(line);
      if (i != null) {
        installed = i.group(1)!.trim();
        continue;
      }
      final c = RegExp(r'^\s+Candidate:\s*(.+)$').firstMatch(line);
      if (c != null) {
        candidate = c.group(1)!.trim();
        continue;
      }
    }
    flush();
    // Mantiene solo i pacchetti richiesti (l'output può contenere altri).
    return updatable.where((p) => packages.contains(p)).toList();
  }

  /// Installa da zero oppure aggiorna, a seconda dello stato rilevato.
  static Future<String> installOrUpdateLinuxFirmware(
      LinuxFirmwareStatus status) async {
    if (!status.installed) return installLinuxFirmware();
    if (!status.updateAvailable) return 'ok';
    return updateLinuxFirmware(status);
  }

  /// Aggiorna i pacchetti firmware già installati alla versione disponibile.
  static Future<String> updateLinuxFirmware(LinuxFirmwareStatus status) async {
    final pm = await _detectPackageManager();
    final pkgs = status.updatablePackages.isNotEmpty
        ? status.updatablePackages
        : status.installedPackages;
    if (pkgs.isEmpty) return 'ok';
    final names = pkgs.join(' ');
    String cmd;
    switch (pm) {
      case 'apt':
        cmd = 'apt-get update -qq && '
            'DEBIAN_FRONTEND=noninteractive '
            'apt-get install -y --only-upgrade $names';
        break;
      case 'dnf':
        cmd = 'dnf upgrade -y $names';
        break;
      case 'pacman':
        // Su Arch un upgrade parziale non è supportato: -Syu è il modo corretto.
        cmd = 'pacman -Syu --noconfirm $names';
        break;
      case 'zypper':
        cmd = 'zypper --non-interactive update $names';
        break;
      default:
        return 'Unsupported package manager.';
    }
    try {
      final r = await _runSudo(cmd);
      if (r.exitCode == 0) return 'ok';
      final out = r.stdout.toString().trim();
      return out.isNotEmpty ? out : 'firmware update failed';
    } catch (e) {
      return e.toString();
    }
  }

  /// Install linux-firmware package (covers most firmware blobs).
  static Future<String> installLinuxFirmware() async {
    final pm = await _detectPackageManager();
    final candidates = _firmwareCandidates(pm);
    if (candidates.isEmpty) return 'Unsupported package manager.';

    for (final pkg in candidates) {
      final installed = await _isPackageInstalled(pkg);
      if (installed) return 'ok';

      final cmd = _buildInstallCmd(pm, pkg);
      final r = await _runSudo(cmd);
      if (r.exitCode == 0) return 'ok';
    }

    final cmd = _buildInstallCmd(pm, candidates.last);
    final r = await _runSudo(cmd);
    if (r.exitCode == 0) return 'ok';
    final out = r.stdout.toString().trim();
    return out.isNotEmpty ? out : 'firmware install failed';
  }

  /// Reload a kernel module (requires root).
  static Future<String> reloadModule(String module) async {
    final r = await _runSudo('modprobe -r $module && modprobe $module');
    return r.exitCode == 0 ? 'ok' : r.stdout.toString().trim();
  }
}
