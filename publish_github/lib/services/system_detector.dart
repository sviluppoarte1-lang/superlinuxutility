import 'dart:io';

class SystemDetectionInfo {
  final String distribution;
  final String distributionVersion;
  final String desktopEnvironment;
  final bool hasGrub;
  final bool hasSystemd;
  final bool hasGsettings;
  final bool hasGnome;
  final bool hasKde;
  final bool hasXfce;
  final bool hasSnap;
  final bool hasFlatpak;
  final bool hasApt;
  final bool hasDnf;
  final bool hasPacman;
  final String grubUpdateCommand;
  final String grubConfigPath;

  SystemDetectionInfo({
    required this.distribution,
    required this.distributionVersion,
    required this.desktopEnvironment,
    required this.hasGrub,
    required this.hasSystemd,
    required this.hasGsettings,
    required this.hasGnome,
    required this.hasKde,
    required this.hasXfce,
    required this.hasSnap,
    required this.hasFlatpak,
    required this.hasApt,
    required this.hasDnf,
    required this.hasPacman,
    required this.grubUpdateCommand,
    required this.grubConfigPath,
  });
}

class SystemDetector {
  static SystemDetectionInfo? _cachedSystemInfo;

  static Future<SystemDetectionInfo> detectSystem({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedSystemInfo != null) {
      return _cachedSystemInfo!;
    }

    final distribution = await _detectDistribution();
    final distributionVersion = await _detectDistributionVersion(distribution);
    final desktopEnvironment = await _detectDesktopEnvironment();
    final hasGrub = await _hasGrub();
    final hasSystemd = await _hasSystemd();
    final hasGsettings = await _hasGsettings();
    final hasGnome = desktopEnvironment.toLowerCase().contains('gnome');
    final hasKde = desktopEnvironment.toLowerCase().contains('kde');
    final hasXfce = desktopEnvironment.toLowerCase().contains('xfce');
    final hasSnap = await _hasCommand('snap');
    final hasFlatpak = await _hasCommand('flatpak');
    final hasApt = await _hasCommand('apt');
    final hasDnf = await _hasCommand('dnf');
    final hasPacman = await _hasCommand('pacman');
    
    final grubUpdateCommand = _getGrubUpdateCommand(distribution);
    final grubConfigPath = _getGrubConfigPath(distribution);

    final systemInfo = SystemDetectionInfo(
      distribution: distribution,
      distributionVersion: distributionVersion,
      desktopEnvironment: desktopEnvironment,
      hasGrub: hasGrub,
      hasSystemd: hasSystemd,
      hasGsettings: hasGsettings,
      hasGnome: hasGnome,
      hasKde: hasKde,
      hasXfce: hasXfce,
      hasSnap: hasSnap,
      hasFlatpak: hasFlatpak,
      hasApt: hasApt,
      hasDnf: hasDnf,
      hasPacman: hasPacman,
      grubUpdateCommand: grubUpdateCommand,
      grubConfigPath: grubConfigPath,
    );

    _cachedSystemInfo = systemInfo;
    return systemInfo;
  }

  static Future<String> _detectDistribution() async {
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('ID=')) {
            final id = line.substring(3).replaceAll('"', '').trim().toLowerCase();
            switch (id) {
              case 'ubuntu':
                return 'Ubuntu';
              case 'debian':
                return 'Debian';
              case 'fedora':
                return 'Fedora';
              case 'arch':
              case 'archlinux':
                return 'Arch Linux';
              case 'manjaro':
                return 'Manjaro';
              case 'opensuse-tumbleweed':
              case 'opensuse-leap':
                return 'openSUSE';
              case 'zorin':
                return 'Zorin OS';
              case 'linuxmint':
                return 'Linux Mint';
              case 'elementary':
                return 'elementary OS';
              case 'pop':
                return 'Pop!_OS';
              default:
                return id.split('_')[0].split('-')[0];
            }
          }
        }
        
        for (final line in lines) {
          if (line.startsWith('NAME=')) {
            final name = line.substring(5).replaceAll('"', '').trim();
            return name.split(' ')[0];
          }
        }
      }

      final lsbRelease = File('/etc/lsb-release');
      if (await lsbRelease.exists()) {
        final content = await lsbRelease.readAsString();
        final match = RegExp(r'DISTRIB_ID=(.+)').firstMatch(content);
        if (match != null) {
          return match.group(1)!.replaceAll('"', '').trim();
        }
      }
    } catch (e) {
      print('Errore nel rilevamento distribuzione: $e');
    }

    return 'Linux';
  }

  /// Rileva la versione della distribuzione
  static Future<String> _detectDistributionVersion(String distribution) async {
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          if (line.startsWith('VERSION_ID=')) {
            return line.substring(11).replaceAll('"', '').trim();
          }
        }
      }
    } catch (e) {
      // Ignora errori
    }
    return 'Unknown';
  }

  /// Rileva il desktop environment
  static Future<String> _detectDesktopEnvironment() async {
    try {
      final xdgDesktop = Platform.environment['XDG_CURRENT_DESKTOP'];
      if (xdgDesktop != null && xdgDesktop.isNotEmpty) {
        return xdgDesktop.split(':').first; // Prendi il primo se ci sono multipli
      }

      final desktop = Platform.environment['DESKTOP_SESSION'];
      if (desktop != null && desktop.isNotEmpty) {
        return desktop;
      }

      final session = Platform.environment['SESSION'];
      if (session != null && session.isNotEmpty) {
        return session;
      }

      // Prova a verificare se GNOME è in esecuzione
      final gnomeResult = await Process.run(
        'pgrep',
        ['-u', Platform.environment['USER'] ?? '', 'gnome-session'],
        runInShell: false,
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      
      if (gnomeResult.exitCode == 0) {
        return 'GNOME';
      }

      // Prova KDE
      final kdeResult = await Process.run(
        'pgrep',
        ['-u', Platform.environment['USER'] ?? '', 'startkde'],
        runInShell: false,
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      
      if (kdeResult.exitCode == 0) {
        return 'KDE';
      }
    } catch (e) {
      // Ignora errori
    }

    return 'Unknown';
  }

  /// Verifica se GRUB è installato
  static Future<bool> _hasGrub() async {
    try {
      // Verifica se esiste il file di configurazione GRUB
      final grubPaths = [
        '/etc/default/grub',
        '/boot/grub/grub.cfg',
        '/boot/grub2/grub.cfg',
        '/boot/efi/EFI/fedora/grub.cfg',
      ];
      
      for (final path in grubPaths) {
        final file = File(path);
        if (await file.exists()) {
          return true;
        }
      }

      // Verifica se il comando grub è disponibile
      final result = await Process.run(
        'which',
        ['grub-mkconfig', 'grub2-mkconfig', 'update-grub'],
        runInShell: false,
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se systemd è disponibile
  static Future<bool> _hasSystemd() async {
    try {
      final result = await Process.run(
        'systemctl',
        ['--version'],
        runInShell: false,
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se gsettings è disponibile
  static Future<bool> _hasGsettings() async {
    try {
      final result = await Process.run(
        'which',
        ['gsettings'],
        runInShell: false,
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se un comando è disponibile
  static Future<bool> _hasCommand(String command) async {
    try {
      final result = await Process.run(
        'which',
        [command],
        runInShell: false,
      ).timeout(const Duration(seconds: 1), onTimeout: () => ProcessResult(1, -1, '', ''));
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Determina il comando GRUB corretto in base alla distribuzione
  static String _getGrubUpdateCommand(String distribution) {
    final distLower = distribution.toLowerCase();
    
    if (distLower.contains('ubuntu') || 
        distLower.contains('debian') || 
        distLower.contains('mint') ||
        distLower.contains('zorin') ||
        distLower.contains('elementary') ||
        distLower.contains('pop')) {
      return 'update-grub';
    } else if (distLower.contains('fedora') || 
               distLower.contains('rhel') ||
               distLower.contains('centos')) {
      return 'grub2-mkconfig -o /boot/grub2/grub.cfg';
    } else if (distLower.contains('arch') || 
               distLower.contains('manjaro')) {
      return 'grub-mkconfig -o /boot/grub/grub.cfg';
    } else if (distLower.contains('opensuse') || 
               distLower.contains('suse')) {
      return 'grub2-mkconfig -o /boot/grub2/grub.cfg';
    } else {
      // Default: prova update-grub, poi grub-mkconfig
      return 'update-grub';
    }
  }

  /// Determina il percorso del file di configurazione GRUB
  static String _getGrubConfigPath(String distribution) {
    final distLower = distribution.toLowerCase();
    
    if (distLower.contains('fedora')) {
      return '/boot/grub2/grub.cfg';
    } else {
      return '/boot/grub/grub.cfg';
    }
  }

  /// Invalida la cache
  static void invalidateCache() {
    _cachedSystemInfo = null;
  }
}

