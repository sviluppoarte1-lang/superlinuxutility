import 'dart:io';
import 'password_storage.dart';
import '../models/device_info.dart';

/// Servizio di gestione periferiche (stile Windows XP Device Manager).
/// Legge dispositivi da lspci, lsusb, /sys/block, /sys/class/net.
/// Disabilitazione/abilitazione persistente tramite systemd service che al
/// boot esegue `echo 0 > .../enable` (PCI), `echo 0 > .../authorized` (USB),
/// `ip link set X down` (rete).
class DeviceManagerService {
  static const _confFile = '/etc/slu_disabled_devices.conf';
  static const _serviceFile = '/etc/systemd/system/slu-device-disable.service';
  static const _scriptFile = '/usr/local/bin/slu-disable-devices.sh';

  static Future<ProcessResult> _runSudo(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password not saved. Save it in Settings.');
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

  // ─── PERSISTENCE: CONFIG FILE + SYSTEMD SERVICE ───

  /// Formato file /etc/slu_disabled_devices.conf:
  /// ```
  /// # Super Linux Utility - disabled devices
  /// pci 0000:01:00.0
  /// usb 3-2
  /// net enp2s0
  /// ```

  static Future<Set<String>> _readDisabledDevices() async {
    try {
      final content = await File(_confFile).readAsString();
      return content
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty && !l.startsWith('#'))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> _writeDisabledDevices(Set<String> entries) async {
    final lines = <String>['# Super Linux Utility - disabled devices'];
    lines.addAll(entries);
    final content = '${lines.join('\n')}\n';
    await _runSudo('printf "%s" ${_shellQuote(content)} > $_confFile');
  }

  /// Crea/aggiorna il servizio systemd + script che al boot disabilita i
  /// dispositivi elencati nella config.
  static Future<void> _ensureSystemdService() async {
    // Verifica se lo script esiste già
    final exists = await _run('test -f $_scriptFile && echo yes || echo no');
    if (exists == 'yes') return;

    // Script di disabilitazione (usa /usr/bin/env bash per portabilità)
    final script = '''#!/usr/bin/env bash
# Super Linux Utility - boot-time device disable
# Eseguito come root dal servizio systemd slu-device-disable.service
CONF="$_confFile"
[ -f "\$CONF" ] || exit 0

# Attendi che i device siano pronti
sleep 2

while IFS= read -r line; do
  # Salta commenti e righe vuote
  [[ "\$line" =~ ^#\$ || -z "\$line" ]] && continue
  bus=\$(echo "\$line" | awk '{print \$1}')
  id=\$(echo "\$line" | awk '{print \$2}')
  case "\$bus" in
    pci)
      EN="/sys/bus/pci/devices/0000:\$id/enable"
      if [ -f "\$EN" ]; then
        echo 0 > "\$EN" 2>/dev/null || true
      fi
      ;;
    usb)
      AU="/sys/bus/usb/devices/\$id/authorized"
      if [ -f "\$AU" ]; then
        echo 0 > "\$AU" 2>/dev/null || true
      fi
      ;;
    net)
      ip link set "\$id" down 2>/dev/null || true
      ;;
  esac
done < "\$CONF"
''';

    // Scrivi script
    await _runSudo('printf "%s" ${_shellQuote(script)} > $_scriptFile');
    await _runSudo('chmod 755 $_scriptFile');

    // Servizio systemd — esegue come root, dopo udev
    final service = '''[Unit]
Description=Super Linux Utility - Disable Devices
After=local-fs.target systemd-udev-settle.service
Before=network-pre.target

[Service]
Type=oneshot
ExecStart=$_scriptFile
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
''';

    await _runSudo('printf "%s" ${_shellQuote(service)} > $_serviceFile');
    await _runSudo('chmod 644 $_serviceFile');
    await _runSudo('systemctl daemon-reload');
    await _runSudo('systemctl enable slu-device-disable.service 2>/dev/null || true');
  }

  /// Aggiunge o rimuove un dispositivo dalla config e rigenera lo script.
  static Future<void> _updatePersistence(
      String bus, String id, bool disable) async {
    final entry = '$bus $id';
    final disabled = await _readDisabledDevices();
    if (disable) {
      disabled.add(entry);
    } else {
      disabled.remove(entry);
    }
    await _writeDisabledDevices(disabled);
    // Rigenera lo script e il servizio (potrebbe non esistere ancora)
    await _runSudo('rm -f $_scriptFile'); // Forza rigenerazione
    await _ensureSystemdService();
  }

  // ─── RILEVAMENTO PERIFERICHE ───

  static Future<List<DeviceCategory>> getAllDevices() async {
    final devices = <DeviceInfo>[];
    devices.addAll(await _getPciDevices());
    devices.addAll(await _getUsbDevices());
    devices.addAll(await _getBlockDevices());
    devices.addAll(await _getNetDevices());

    final map = <String, List<DeviceInfo>>{};
    for (final d in devices) {
      map.putIfAbsent(d.category, () => []).add(d);
    }

    const order = [
      'Display adapters',
      'Network adapters',
      'Sound, video and game controllers',
      'USB controllers',
      'Storage controllers',
      'Disk drives',
      'IDE ATA/ATAPI controllers',
      'Processor',
      'System devices',
      'Input devices',
      'Multimedia devices',
      'Other devices',
    ];

    final result = <DeviceCategory>[];
    for (final cat in order) {
      if (map.containsKey(cat)) {
        result.add(DeviceCategory(
            name: cat, icon: _catIcon(cat), devices: map[cat]!));
      }
    }
    for (final entry in map.entries) {
      if (!order.contains(entry.key)) {
        result.add(DeviceCategory(
            name: entry.key, icon: '🔧', devices: entry.value));
      }
    }
    return result;
  }

  static String _catIcon(String cat) {
    switch (cat) {
      case 'Display adapters':
        return '🖥️';
      case 'Network adapters':
        return '🌐';
      case 'Sound, video and game controllers':
        return '🔊';
      case 'USB controllers':
        return '🔌';
      case 'Storage controllers':
        return '💾';
      case 'Disk drives':
        return '💿';
      case 'IDE ATA/ATAPI controllers':
        return '🔌';
      case 'Processor':
        return '⚡';
      case 'System devices':
        return '⚙️';
      case 'Input devices':
        return '⌨️';
      case 'Multimedia devices':
        return '📷';
      default:
        return '🔧';
    }
  }

  // ─── PCI DEVICES ───

  static Future<List<DeviceInfo>> _getPciDevices() async {
    final result = <DeviceInfo>[];
    try {
      final output = await _run('lspci -nn -k 2>/dev/null');
      if (output.isEmpty) return result;

      final lines = output.split('\n');
      String? currentSlot;
      String? currentClass;
      String? currentVendor;
      String? currentDeviceId;
      String? currentDriver;

      void flush() {
        if (currentSlot != null && currentClass != null) {
          final cat = _pciClassToCategory(currentClass!);
          final enablePath =
              '/sys/bus/pci/devices/0000:$currentSlot/enable';
          bool enabled = true;
          bool canDisable = true;
          try {
            final en = File(enablePath).readAsStringSync().trim();
            enabled = en == '1';
          } catch (_) {}
          if (currentClass!.contains('Host bridge') ||
              currentClass!.contains('PCI bridge') ||
              currentClass!.contains('ISA bridge') ||
              currentClass!.contains('IOMMU') ||
              currentClass!.contains('SMBus') ||
              currentClass!.contains('Process')) {
            canDisable = false;
          }

          result.add(DeviceInfo(
            id: 'pci:0000:$currentSlot',
            name: currentClass!,
            category: cat,
            vendor: currentVendor,
            vendorId: null,
            deviceId: currentDeviceId,
            driver: currentDriver,
            enabled: enabled,
            canDisable: canDisable,
            bus: 'pci',
          ));
        }
        currentSlot = null;
        currentClass = null;
        currentVendor = null;
        currentDeviceId = null;
        currentDriver = null;
      }

      for (final line in lines) {
        if (line.isEmpty) continue;
        if (RegExp(r'^[0-9a-f]{2}:[0-9a-f]{2}\.\d').hasMatch(line)) {
          flush();
          final slotMatch =
              RegExp(r'^([0-9a-f]{2}:[0-9a-f]{2}\.\d)').firstMatch(line);
          currentSlot = slotMatch?.group(1);
          final classMatch = RegExp(r'\[([0-9a-f]{4})\]').firstMatch(line);
          final classCode = classMatch?.group(1) ?? '';
          currentClass = _pciClassName(line, classCode);
          final idMatch =
              RegExp(r'\[([0-9a-f]{4}):([0-9a-f]{4})\]').firstMatch(line);
          currentVendor = idMatch?.group(1);
          currentDeviceId = idMatch?.group(2);
          final nameMatch = RegExp(r'\]:\s*(.+)').firstMatch(line);
          if (nameMatch != null) {
            currentClass = '$currentClass — ${nameMatch.group(1)!.trim()}';
          }
        } else if (line.startsWith('        ')) {
          if (line.contains('Kernel driver in use:')) {
            final driverMatch =
                RegExp(r'Kernel driver in use:\s*(\S+)').firstMatch(line);
            currentDriver = driverMatch?.group(1);
          }
        }
      }
      flush();
    } catch (_) {}
    return result;
  }

  static String _pciClassName(String line, String classCode) {
    final classMatch = RegExp(r':\s*(.+?)(?:\s*\[|$)').firstMatch(line);
    final rawClass = classMatch?.group(1)?.trim() ?? 'Unknown device';
    final colonIdx = rawClass.indexOf(':');
    return colonIdx > 0 ? rawClass.substring(0, colonIdx).trim() : rawClass;
  }

  static String _pciClassToCategory(String className) {
    final lower = className.toLowerCase();
    if (lower.contains('vga') ||
        lower.contains('display') ||
        lower.contains('3d') ||
        lower.contains('graphics')) {
      return 'Display adapters';
    }
    if (lower.contains('ethernet') ||
        lower.contains('network') ||
        lower.contains('wireless') ||
        lower.contains('wifi') ||
        lower.contains('bluetooth')) {
      return 'Network adapters';
    }
    if (lower.contains('audio') ||
        lower.contains('sound') ||
        lower.contains('multimedia') ||
        lower.contains('hd audio')) {
      return 'Sound, video and game controllers';
    }
    if (lower.contains('usb')) {
      return 'USB controllers';
    }
    if (lower.contains('sata') ||
        lower.contains('raid') ||
        lower.contains('nvme') ||
        lower.contains('scsi')) {
      return 'Storage controllers';
    }
    if (lower.contains('ide') || lower.contains('ata')) {
      return 'IDE ATA/ATAPI controllers';
    }
    if (lower.contains('process') || lower.contains('cpu')) {
      return 'Processor';
    }
    if (lower.contains('host bridge') ||
        lower.contains('pci bridge') ||
        lower.contains('isa bridge') ||
        lower.contains('iommu') ||
        lower.contains('smbus') ||
        lower.contains('isa') ||
        lower.contains('encryption') ||
        lower.contains('signal') ||
        lower.contains('data fabric')) {
      return 'System devices';
    }
    if (lower.contains('input') ||
        lower.contains('keyboard') ||
        lower.contains('mouse')) {
      return 'Input devices';
    }
    if (lower.contains('camera') ||
        lower.contains('video') ||
        lower.contains('capture')) {
      return 'Multimedia devices';
    }
    return 'Other devices';
  }

  // ─── USB DEVICES ───

  static Future<List<DeviceInfo>> _getUsbDevices() async {
    final result = <DeviceInfo>[];
    try {
      final dirs =
          await _run('ls -d /sys/bus/usb/devices/[0-9]* 2>/dev/null');
      if (dirs.isEmpty) return result;

      for (final dir in dirs.split('\n')) {
        if (dir.isEmpty) continue;
        final d = dir.trim();
        try {
          final devClass = await File('$d/bDeviceClass')
              .readAsString()
              .catchError((_) => Future.value(''));
          if (devClass.trim() == '09') continue;

          final product = await File('$d/product')
              .readAsString()
              .catchError((_) => Future.value(''));
          final mfg = await File('$d/manufacturer')
              .readAsString()
              .catchError((_) => Future.value(''));
          final vid = await File('$d/idVendor')
              .readAsString()
              .catchError((_) => Future.value(''));
          final pid = await File('$d/idProduct')
              .readAsString()
              .catchError((_) => Future.value(''));
          final authorized = await File('$d/authorized')
              .readAsString()
              .catchError((_) => Future.value('1'));
          final driver = await File('$d/driver')
              .readAsString()
              .catchError((_) => Future.value(''));

          final name = product.trim().isNotEmpty
              ? product.trim()
              : (mfg.trim().isNotEmpty
                  ? '${mfg.trim()} Device'
                  : 'USB Device ${vid.trim()}:${pid.trim()}');

          final pathParts = d.split('/');
          final usbId = pathParts.last;

          result.add(DeviceInfo(
            id: 'usb:$usbId',
            name: name,
            category: _usbDeviceCategory(devClass.trim()),
            vendor: mfg.trim().isNotEmpty ? mfg.trim() : null,
            vendorId: vid.trim(),
            deviceId: pid.trim(),
            driver: driver.trim().isNotEmpty ? driver.trim() : null,
            enabled: authorized.trim() == '1',
            canDisable: true,
            bus: 'usb',
          ));
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  static String _usbDeviceCategory(String devClass) {
    switch (devClass) {
      case '02':
        return 'Network adapters';
      case '0e':
        return 'Multimedia devices';
      case '03':
        return 'Input devices';
      case '07':
        return 'Printer';
      case '08':
        return 'Multimedia devices';
      case 'e0':
        return 'Wireless controllers';
      default:
        return 'Other devices';
    }
  }

  // ─── BLOCK DEVICES ───

  static Future<List<DeviceInfo>> _getBlockDevices() async {
    final result = <DeviceInfo>[];
    try {
      final output = await _run(
          'lsblk -dno NAME,TYPE,SIZE,MODEL,SERIAL,TRAN 2>/dev/null');
      if (output.isEmpty) return result;

      for (final line in output.split('\n')) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(RegExp(r'\s{2,}'));
        if (parts.length < 2) continue;
        final name = parts[0].trim();
        final type = parts.length > 1 ? parts[1].trim() : '';
        final size = parts.length > 2 ? parts[2].trim() : '';
        final model = parts.length > 3 ? parts[3].trim() : '';
        final serial = parts.length > 4 ? parts[4].trim() : '';
        final tran = parts.length > 5 ? parts[5].trim() : '';

        if (type != 'disk' && type != 'part') continue;

        final displayName = model.isNotEmpty
            ? '$name — $model'
            : (tran.isNotEmpty ? '$name — $tran' : name);

        final details = <String>[];
        if (size.isNotEmpty) details.add('Size: $size');
        if (model.isNotEmpty) details.add('Model: $model');
        if (serial.isNotEmpty) details.add('S/N: $serial');
        if (tran.isNotEmpty) details.add('Bus: $tran');

        result.add(DeviceInfo(
          id: 'block:$name',
          name: displayName,
          category: 'Disk drives',
          enabled: true,
          canDisable: false,
          bus: tran.isNotEmpty ? tran : 'sata',
          details: details.join(' | '),
        ));
      }
    } catch (_) {}
    return result;
  }

  // ─── NETWORK DEVICES ───

  static Future<List<DeviceInfo>> _getNetDevices() async {
    final result = <DeviceInfo>[];
    try {
      final disabledEntries = await _readDisabledDevices();
      final disabledIfaces = disabledEntries
          .where((e) => e.startsWith('net '))
          .map((e) => e.replaceFirst('net ', ''))
          .toSet();

      final output = await _run('ls -1 /sys/class/net/ 2>/dev/null');
      if (output.isEmpty) return result;

      for (final iface in output.split('\n')) {
        if (iface.trim().isEmpty || iface.trim() == 'lo') continue;
        final name = iface.trim();
        final path = '/sys/class/net/$name';

        String mac = '';
        String state = '';
        String driver = '';
        String type = '';
        try {
          mac = await File('$path/address')
              .readAsString()
              .catchError((_) => Future.value(''));
          state = await File('$path/operstate')
              .readAsString()
              .catchError((_) => Future.value(''));
        } catch (_) {}

        try {
          final deviceLink = await File('$path/device')
              .resolveSymbolicLinks()
              .catchError((_) => Future.value(''));
          if (deviceLink.isNotEmpty) {
            final driverPath = '$deviceLink/driver';
            try {
              final driverLink = await File(driverPath)
                  .resolveSymbolicLinks()
                  .catchError((_) => Future.value(''));
              driver = driverLink.split('/').last;
            } catch (_) {}
          }
        } catch (_) {}

        final wirelessPath = '$path/wireless';
        try {
          if (await Directory(wirelessPath).exists()) type = 'WiFi';
        } catch (_) {}
        if (type.isEmpty) {
          final typeOutput = await _run("cat $path/type 2>/dev/null");
          type = typeOutput == '1' ? 'Ethernet' : 'Network';
        }

        final isPersistentlyDisabled = disabledIfaces.contains(name);
        final isEnabled = state.trim() == 'up' && !isPersistentlyDisabled;

        result.add(DeviceInfo(
          id: 'net:$name',
          name: '$name — $type',
          category: 'Network adapters',
          driver: driver.isNotEmpty ? driver : null,
          enabled: isEnabled,
          canDisable: true,
          bus: 'net',
          details: [
            if (mac.trim().isNotEmpty) 'MAC: ${mac.trim()}',
            'State: ${state.trim().isNotEmpty ? state.trim() : 'unknown'}',
            if (driver.isNotEmpty) 'Driver: $driver',
            if (isPersistentlyDisabled) 'Persistent: disabled at boot',
          ].join(' | '),
        ));
      }
    } catch (_) {}
    return result;
  }

  // ─── ENABLE / DISABLE ───

  static Future<Map<String, dynamic>> toggleDevice(
      DeviceInfo device, bool enable) async {
    try {
      switch (device.bus) {
        case 'pci':
          return await _togglePci(device, enable);
        case 'usb':
          return await _toggleUsb(device, enable);
        case 'net':
          return await _toggleNet(device, enable);
        default:
          return {
            'success': false,
            'message': 'Toggle not supported for this device type'
          };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _togglePci(
      DeviceInfo device, bool enable) async {
    final slot = device.id.replaceFirst('pci:', '');
    // "pci:0000:03:00.0" → "03:00.0" (senza il prefisso bus)
    final sysfsId = slot.replaceFirst(RegExp(r'^0000:'), '');
    final path = '/sys/bus/pci/devices/0000:$sysfsId/enable';
    final value = enable ? '1' : '0';

    // 1) Toggle immediato via sysfs
    final cmd = 'echo $value > $path';
    bool immediateOk = false;
    try {
      final r = await Process.run('bash', ['-c', cmd], runInShell: true);
      immediateOk = r.exitCode == 0;
    } catch (_) {}
    if (!immediateOk) {
      try {
        final r = await _runSudo(cmd);
        immediateOk = r.exitCode == 0;
      } catch (_) {}
    }

    // 2) Salva nel file di persistenza e rigenera servizio systemd
    try {
      await _updatePersistence('pci', sysfsId, !enable);
    } catch (_) {}

    return {
      'success': immediateOk,
      'message': immediateOk
          ? (enable ? 'Device enabled' : 'Device disabled (persists on reboot)')
          : 'Failed to toggle device',
    };
  }

  static Future<Map<String, dynamic>> _toggleUsb(
      DeviceInfo device, bool enable) async {
    final usbId = device.id.replaceFirst('usb:', '');
    final path = '/sys/bus/usb/devices/$usbId/authorized';
    final value = enable ? '1' : '0';

    // 1) Toggle immediato
    final cmd = 'echo $value > $path';
    bool immediateOk = false;
    try {
      final r = await Process.run('bash', ['-c', cmd], runInShell: true);
      immediateOk = r.exitCode == 0;
    } catch (_) {}
    if (!immediateOk) {
      try {
        final r = await _runSudo(cmd);
        immediateOk = r.exitCode == 0;
      } catch (_) {}
    }

    // 2) Persistenza
    try {
      await _updatePersistence('usb', usbId, !enable);
    } catch (_) {}

    return {
      'success': immediateOk,
      'message': immediateOk
          ? (enable ? 'Device enabled' : 'Device disabled (persists on reboot)')
          : 'Failed to toggle device',
    };
  }

  static Future<Map<String, dynamic>> _toggleNet(
      DeviceInfo device, bool enable) async {
    final iface = device.id.replaceFirst('net:', '');

    // 1) Toggle immediato
    final cmd = enable ? 'ip link set $iface up' : 'ip link set $iface down';
    bool immediateOk = false;
    try {
      final r = await Process.run('bash', ['-c', cmd], runInShell: true);
      immediateOk = r.exitCode == 0;
    } catch (_) {}
    if (!immediateOk) {
      try {
        final r = await _runSudo(cmd);
        immediateOk = r.exitCode == 0;
      } catch (_) {}
    }

    // 2) Persistenza
    try {
      await _updatePersistence('net', iface, !enable);
    } catch (_) {}

    return {
      'success': immediateOk,
      'message': immediateOk
          ? (enable
              ? 'Interface up'
              : 'Interface down (persists on reboot)')
          : 'Failed to toggle interface',
    };
  }
}
