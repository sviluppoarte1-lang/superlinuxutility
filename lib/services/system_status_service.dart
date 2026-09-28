import 'dart:io';
import 'password_storage.dart';

class KernelStatus {
  final String version;
  final String buildInfo;
  final String thpMode;
  final String zswapStatus;
  final String governor;
  final String ioScheduler;
  final int cpuCount;

  const KernelStatus({
    required this.version,
    required this.buildInfo,
    required this.thpMode,
    required this.zswapStatus,
    required this.governor,
    required this.ioScheduler,
    required this.cpuCount,
  });
}

class SecurityStatus {
  final String appArmor;
  final String selinux;
  final String secureBoot;
  final String firewallBackend;
  final bool firewallActive;
  final bool sshActive;
  final bool rootSshAllowed;
  final bool autoUpdatesEnabled;
  final bool sudoAvailable;

  const SecurityStatus({
    required this.appArmor,
    required this.selinux,
    required this.secureBoot,
    required this.firewallBackend,
    required this.firewallActive,
    required this.sshActive,
    required this.rootSshAllowed,
    required this.autoUpdatesEnabled,
    this.sudoAvailable = true,
  });
}

class VirtualizationStatus {
  final bool cpuVirtSupported;
  final String kvmModule;
  final bool iommuEnabled;
  final bool vfioLoaded;
  final bool ksmRunning;
  final bool dockerInstalled;
  final bool libvirtInstalled;

  const VirtualizationStatus({
    required this.cpuVirtSupported,
    required this.kvmModule,
    required this.iommuEnabled,
    required this.vfioLoaded,
    required this.ksmRunning,
    required this.dockerInstalled,
    required this.libvirtInstalled,
  });
}

class PrintersStatus {
  final bool cupsActive;
  final List<String> printers;
  final List<String> drivers;

  const PrintersStatus({
    required this.cupsActive,
    required this.printers,
    required this.drivers,
  });
}

/// Stato di sola lettura di sistema (kernel, sicurezza, virtualizzazione, stampanti).
/// Nessuna di queste operazioni modifica il sistema.
class SystemStatusService {
  static Future<String> _runBash(String command) async {
    try {
      final result = await Process.run('bash', ['-c', command], runInShell: true);
      return ((result.stdout as String?) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static Future<String> _runSudoOutput(String command) async {
    try {
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) return '';
      final escapedPassword = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll("'", "\\'");
      final fullCommand =
          'printf "%s\\n" "$escapedPassword" | sudo -S bash -c ${shellQuote(command)} 2>/dev/null';
      final result = await Process.run('bash', ['-c', fullCommand], runInShell: true);
      return ((result.stdout as String?) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static String shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static bool _containsSubstring(String haystack, String needle) =>
      haystack.toLowerCase().contains(needle.toLowerCase());

  // ─── KERNEL ───

  static Future<KernelStatus> getKernelStatus() async {
    final version = await _runBash('uname -r');
    final buildInfo = await _runBash('uname -v');
    final thpRaw = await _runBash('cat /sys/kernel/mm/transparent_hugepage/enabled');
    final zswapRaw = await _runBash('cat /sys/module/zswap/parameters/enabled');
    final governor = await _runBash(
        'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo ""');
    final ioRaw = await _runBash(
        'for s in /sys/block/*/queue/scheduler; do cat "\$s" 2>/dev/null | head -1; break; done');
    final cpuCountRaw = await _runBash('nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo');

    String thpMode = 'not available';
    final bracketMatch = RegExp(r'\[([^\]]+)\]').firstMatch(thpRaw);
    if (bracketMatch != null) thpMode = bracketMatch.group(1)!;
    if (thpRaw.isEmpty) thpMode = 'not available';

    String zswapStatus = 'not available';
    if (zswapRaw.isNotEmpty) {
      final v = zswapRaw.toLowerCase();
      zswapStatus = (v == 'y' || v == '1') ? 'enabled' : 'disabled';
    }

    String io = 'not available';
    if (ioRaw.isNotEmpty) {
      final m = RegExp(r'\[([^\]]+)\]').firstMatch(ioRaw);
      io = m?.group(1) ?? ioRaw.split(' ').first;
    }

    return KernelStatus(
      version: version.isNotEmpty ? version : 'unknown',
      buildInfo: buildInfo.isNotEmpty ? buildInfo : 'unknown',
      thpMode: thpMode,
      zswapStatus: zswapStatus,
      governor: governor.isNotEmpty ? governor : 'not available',
      ioScheduler: io,
      cpuCount: int.tryParse(cpuCountRaw) ?? 0,
    );
  }

  // ─── SECURITY ───

  static Future<SecurityStatus> getSecurityStatus() async {
    // AppArmor: modulo caricato?
    final aaRaw = await _runBash('cat /sys/module/apparmor/parameters/enabled 2>/dev/null');
    final aaBin = await _runBash('aa-enabled 2>/dev/null && echo enabled || echo -');
    String appArmor = 'not installed';
    if (aaRaw.toLowerCase() == 'y' || aaBin.contains('enabled')) {
      appArmor = 'enabled';
    } else if (aaRaw.isNotEmpty) {
      appArmor = 'disabled';
    } else if (aaBin.isNotEmpty && aaBin != '-') {
      appArmor = 'enabled';
    }

    // SELinux
    String selinux = 'not installed';
    final seRaw = await _runBash('getenforce 2>/dev/null');
    if (seRaw.isNotEmpty && seRaw.toLowerCase() != 'disabled') {
      selinux = seRaw.toLowerCase();
    } else if (seRaw.toLowerCase() == 'disabled') {
      selinux = 'disabled';
    }

    // Secure Boot
    String secureBoot = 'unknown';
    final sbRaw = await _runBash(
        'mokutil --sb-state 2>/dev/null | grep -o "SecureBoot [a-z]*"; '
        'ls /sys/firmware/efi/efivars/ 2>/dev/null | grep -qi SecureBoot- && echo "efi-secureboot-present"; '
        'echo done');
    if (sbRaw.contains('SecureBoot enabled')) {
      secureBoot = 'enabled';
    } else if (sbRaw.contains('SecureBoot disabled')) {
      secureBoot = 'disabled';
    }

    // Firewall: ufw / firewalld / nftables - first active wins
    final ufwRaw = await _runBash('ufw status 2>/dev/null');
    final fwRaw = await _runBash('systemctl is-active firewalld 2>/dev/null');
    final nftRaw = await _runBash('systemctl is-active nftables 2>/dev/null');
    String backend = 'none';
    bool firewallActive = false;

    if (_containsSubstring(ufwRaw, 'status: active')) {
      backend = 'ufw';
      firewallActive = true;
    } else if (fwRaw == 'active') {
      backend = 'firewalld';
      firewallActive = true;
    } else if (nftRaw == 'active') {
      backend = 'nftables';
      firewallActive = true;
    } else if (_containsSubstring(ufwRaw, 'ufw')) {
      backend = 'ufw'; // ufw installed but inactive
    }

    // SSH
    final sshActive = await _runBash(
            'systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null') ==
        'active';

    // Root SSH login: leggi sshd_config (richiede sudo per i permessi)
    final password = await PasswordStorage.getPassword();
    final sudoAvailable = password != null && password.isNotEmpty;
    bool rootSsh = false;
    if (sudoAvailable) {
      final sshCfg = await _runSudoOutput(
          'cat /etc/ssh/sshd_config 2>/dev/null; echo "---D---"; '
          'cat /etc/ssh/sshd_config.d/*.conf 2>/dev/null');
      final lines = sshCfg.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.isEmpty || parts[0] != 'PermitRootLogin') continue;
        final value = parts.length > 1 ? parts[1].toLowerCase() : 'no';
        // L'ultima direttiva valida vince.
        rootSsh = value == 'yes' || value == 'prohibit-password' || value == 'without-password';
      }
    }

    // Auto-updates: APT (unattended-upgrades) + DNF (dnf-automatic)
    final autoRaw = await _runBash(
        'grep -r "Unattended-Upgrade" /etc/apt/apt.conf.d/ 2>/dev/null | grep -v "^#" | head -1');
    final autoService = await _runBash(
        'systemctl is-active unattended-upgrades 2>/dev/null');
    final autoDnf = await _runBash(
        'systemctl is-active dnf-automatic-install.timer 2>/dev/null');
    final autoUpdates =
        autoRaw.isNotEmpty || autoService == 'active' || autoDnf == 'active';

    return SecurityStatus(
      appArmor: appArmor,
      selinux: selinux,
      secureBoot: secureBoot,
      firewallBackend: backend,
      firewallActive: firewallActive,
      sshActive: sshActive,
      rootSshAllowed: rootSsh,
      autoUpdatesEnabled: autoUpdates,
      sudoAvailable: sudoAvailable,
    );
  }

  // ─── VIRTUALIZATION ───

  static Future<VirtualizationStatus> getVirtualizationStatus() async {
    final lscpuRaw = await _runBash('lscpu 2>/dev/null');
    final virtSupported = _containsSubstring(lscpuRaw, 'virtualization');

    final lsmodRaw = await _runBash('lsmod 2>/dev/null');
    String kvmModule = 'none';
    if (lsmodRaw.contains('kvm_amd')) {
      kvmModule = 'kvm_amd';
    } else if (lsmodRaw.contains('kvm_intel')) {
      kvmModule = 'kvm_intel';
    } else if (lsmodRaw.contains(' kvm ')) {
      kvmModule = 'kvm';
    }

    final cmdline = await _runBash('cat /proc/cmdline');
    final hasDmar = await _runBash('ls /sys/class/iommu/ 2>/dev/null | head -1');
    final iommuEnabled = _containsSubstring(cmdline, 'iommu=on') ||
        _containsSubstring(cmdline, 'intel_iommu=on') ||
        _containsSubstring(cmdline, 'amd_iommu=on') ||
        hasDmar.isNotEmpty;

    final vfioLoaded = lsmodRaw.contains('vfio');
    final ksmRaw = await _runBash('cat /sys/kernel/mm/ksm/run 2>/dev/null');
    final ksmRunning = ksmRaw.trim() == '1';

    final dockerRaw = await _runBash(
        'systemctl is-active docker 2>/dev/null || systemctl is-active containerd 2>/dev/null');
    final dockerInstalled = dockerRaw == 'active' ||
        (await _runBash('command -v docker 2>/dev/null')).isNotEmpty;

    final libvirtRaw =
        await _runBash('systemctl is-active libvirtd 2>/dev/null || command -v virsh 2>/dev/null');
    final libvirtInstalled = libvirtRaw == 'active' || libvirtRaw.contains('virsh');

    return VirtualizationStatus(
      cpuVirtSupported: virtSupported,
      kvmModule: kvmModule,
      iommuEnabled: iommuEnabled,
      vfioLoaded: vfioLoaded,
      ksmRunning: ksmRunning,
      dockerInstalled: dockerInstalled,
      libvirtInstalled: libvirtInstalled,
    );
  }

  // ─── PRINTERS ───

  static Future<PrintersStatus> getPrintersStatus() async {
    final cupsRaw = await _runBash(
        'systemctl is-active cups 2>/dev/null || systemctl is-active org.cups.cupsd 2>/dev/null');
    final cupsActive = cupsRaw == 'active';

    final lpRaw = await _runBash('lpstat -p 2>/dev/null');
    final printers = lpRaw
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .map((l) => l.trim().replaceAll(RegExp(r'\s+'), ' '))
        .toList();

    final drvRaw = await _runBash(
        'dpkg -l cups-filters hplip printer-driver-gutenprint foomatic-db printer-driver-cups-pdf 2>/dev/null '
        '| grep ^ii | awk \'{print \$2}\'');
    final drivers = drvRaw.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return PrintersStatus(
      cupsActive: cupsActive,
      printers: printers,
      drivers: drivers,
    );
  }
}
