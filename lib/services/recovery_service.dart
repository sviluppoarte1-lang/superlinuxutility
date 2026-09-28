import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'password_storage.dart';
import 'repository_manager.dart';
import 'system_detector.dart';

class RecoveryService {
  /// Esegue [command] interamente come root. Necessario per script con `&&` / `|`: senza
  /// `bash -c`, solo il primo comando dopo `printf … | sudo -S` è elevato (es. apt-get install senza sudo).
  static Future<ProcessResult> _runSudoCommand(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll("'", "\\'");    
    final fullCommand =
        'printf "%s\\n" "$escapedPassword" | sudo -S bash -c ${shellQuote(command)}';
    
    return await Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
  }

  static String shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static Future<Map<String, dynamic>> restartPipewire() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      
      if (!systemInfo.hasSystemd) {
        return {
          'success': false,
          'message': 'Systemd non disponibile su questo sistema',
        };
      }

      final command = 'systemctl --user restart pipewire pipewire-pulse wireplumber';
      
      String output = '';
      
      try {
        final result = await Process.run(
          'bash',
          ['-c', command],
          runInShell: true,
        );
        
        output = result.stdout.toString();
        if (result.exitCode != 0) {
          output += '\n${result.stderr}';
          return {
            'success': false,
            'message': 'Errore durante il riavvio di Pipewire',
            'output': output,
          };
        }
        
        return {
          'success': true,
          'message': 'Servizio Pipewire riavviato con successo',
          'output': output,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Errore durante il riavvio di Pipewire: $e',
          'output': output,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante il riavvio di Pipewire: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> restoreNetworkServices() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      
      if (!systemInfo.hasSystemd) {
        return {
          'success': false,
          'message': 'Systemd non disponibile su questo sistema',
        };
      }

      final distLower = systemInfo.distribution.toLowerCase();
      String output = '';
      
      final commonCommands = [
        'systemctl restart NetworkManager',
        'systemctl restart systemd-networkd',
        'systemctl restart systemd-resolved',
      ];

      for (final cmd in commonCommands) {
        try {
          final result = await _runSudoCommand(cmd);
          output += '${result.stdout}\n';
          if (result.exitCode != 0) {
            output += 'Warning: ${result.stderr}\n';
          }
        } catch (e) {}
      }

      if (distLower.contains('ubuntu') || distLower.contains('debian') || distLower.contains('mint')) {
        try {
          final result = await _runSudoCommand('systemctl restart networking');
          output += result.stdout.toString();
        } catch (e) {
          // Ignora se non disponibile
        }
      } else if (distLower.contains('fedora') || distLower.contains('rhel') || distLower.contains('centos')) {
        try {
          final result = await _runSudoCommand('systemctl restart network');
          output += result.stdout.toString();
        } catch (e) {
          // Ignora se non disponibile
        }
      }

      return {
        'success': true,
        'message': 'Servizi di rete ripristinati con successo',
        'output': output,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante il ripristino dei servizi di rete: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> rebuildGrub() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      
      if (!systemInfo.hasGrub) {
        return {
          'success': false,
          'message': 'GRUB non è installato su questo sistema',
        };
      }

      String output = '';
      final distLower = systemInfo.distribution.toLowerCase();
      
      // Backup del grub.cfg esistente (timestamp da Dart: con bash -c quotato, $(date) nella shell non verrebbe espanso)
      try {
        final stamp = _grubBackupTimestamp();
        if (distLower.contains('fedora') || distLower.contains('rhel') || distLower.contains('centos')) {
          await _runSudoCommand('cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.backup.$stamp');
        } else {
          await _runSudoCommand('cp /boot/grub/grub.cfg /boot/grub/grub.cfg.backup.$stamp');
        }
      } catch (e) {
        // Continua anche se il backup fallisce
      }

      // Esegui il comando GRUB appropriato
      final grubCommand = systemInfo.grubUpdateCommand;
      final result = await _runSudoCommand(grubCommand);
      
      output = result.stdout.toString();
      if (result.exitCode != 0) {
        output += '\n${result.stderr}';
        return {
          'success': false,
          'message': 'Errore durante la ricostruzione di GRUB',
          'output': output,
        };
      }

      return {
        'success': true,
        'message': 'GRUB ricostruito con successo',
        'output': output,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante la ricostruzione di GRUB: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> restoreFlathub() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      
      if (!systemInfo.hasFlatpak) {
        return {
          'success': false,
          'message': 'Flatpak non è installato su questo sistema',
        };
      }

      String output = '';
      
      // Rimuovi il repository Flathub se esiste già
      try {
        final removeResult = await Process.run(
          'flatpak',
          ['remote-delete', 'flathub'],
          runInShell: false,
        );
        // Ignora errori se il remote non esiste
      } catch (e) {
        // Continua
      }

      // Aggiungi il repository Flathub
      final addResult = await Process.run(
        'flatpak',
        ['remote-add', '--if-not-exists', 'flathub', 'https://flathub.org/repo/flathub.flatpakrepo'],
        runInShell: false,
      );

      output = addResult.stdout.toString();
      
      if (addResult.exitCode != 0) {
        output += '\n${addResult.stderr}';
        return {
          'success': false,
          'message': 'Errore durante il ripristino di Flathub',
          'output': output,
        };
      }

      // Aggiorna i repository
      final updateResult = await Process.run(
        'flatpak',
        ['update', '--appstream'],
        runInShell: false,
      );

      output += '\n${updateResult.stdout}';

      return {
        'success': true,
        'message': 'Flathub ripristinato con successo',
        'output': output,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante il ripristino di Flathub: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> restoreRepositories() async {
    return await RepositoryManager.restoreRepositories();
  }

  static Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      // Prima controlla se i repository sono sani; solo se necessario li ripristina.
      // Evita di sovrascrivere repository funzionanti ogni volta.
      try {
        final reposHealthy = await RepositoryManager.areRepositoriesHealthy();
        if (!reposHealthy) {
          await RepositoryManager.restoreRepositories();
        }
        final systemInfo = await SystemDetector.detectSystem();
        final updateCmd = RepositoryManager.getUpdateCacheCommand(systemInfo);
        if (updateCmd != null) {
          await _runSudoCommand(updateCmd);
        }
      } catch (_) {}
      // Poi procede con il check degli aggiornamenti
      final systemInfo = await SystemDetector.detectSystem();
      final updates = <String>[];
      final updateReport = <String, dynamic>{};

      if (systemInfo.hasApt) {
        updateReport['apt'] = await _checkAptUpdatesReport(updates);
      }
      if (systemInfo.hasDnf) {
        updateReport['dnf'] = await _checkDnfUpdatesReport(updates);
      }
      if (systemInfo.hasPacman) {
        updateReport['pacman'] = await _checkPacmanUpdatesReport(updates);
      }
      if (systemInfo.hasSnap) {
        updateReport['snap'] = await _checkSnapUpdatesReport(updates);
      }
      if (systemInfo.hasFlatpak) {
        updateReport['flatpak'] = await _checkFlatpakUpdatesReport(updates);
      }

      final aptPhased =
          (updateReport['apt'] as Map<String, dynamic>?)?['phasedCount'] as int? ?? 0;
      final summaryPackageCount = updates.length + aptPhased;

      // Estrai pacchetti kernel da APT e DNF
      final kernelPkgs = <String>{};
      final aptMap = updateReport['apt'] as Map<String, dynamic>?;
      if (aptMap != null) {
        final aptKernels = aptMap['kernelPackages'] as List? ?? [];
        kernelPkgs.addAll(aptKernels.map((e) => e.toString()));
      }
      // DNF ha packaging diverso — kernel* packages
      final dnfMap = updateReport['dnf'] as Map<String, dynamic>?;
      if (dnfMap != null) {
        final dnfKernels = (dnfMap['packages'] as List?)
                ?.where((e) => _isKernelPackage(e.toString().split(RegExp(r'\s+')).first))
                .map((e) => e.toString())
                .toList() ??
            <String>[];
        kernelPkgs.addAll(dnfKernels);
      }
      // Pacman (Arch/Manjaro/EndeavourOS): estrai kernel (liquorix, xanmod, cachyos, ecc.)
      final pacmanMap = updateReport['pacman'] as Map<String, dynamic>?;
      if (pacmanMap != null) {
        final pacmanKernels = pacmanMap['kernelPackages'] as List? ?? [];
        kernelPkgs.addAll(pacmanKernels.map((e) => e.toString()));
      }
      // Filtra kernel dalla lista updates per avere updateCount "senza kernel"
      final nonKernelUpdates = updates.where((u) {
        final rawName = u.toString().trim().split(RegExp(r'\s+')).first;
        return !_isKernelPackage(rawName);
      }).toList();
      final nonKernelLabels = nonKernelUpdates
          .map((u) => shortUpdateDisplayName(u.toString()))
          .toList();
      final kernelLabels = kernelPkgs
          .map((k) => shortUpdateDisplayName(k))
          .toList();

      final installableLabels =
          updates.map((u) => shortUpdateDisplayName(u.toString())).toList();
      List<String> phasedLabels = [];
      if (aptMap != null && aptMap['phasedPackages'] is List) {
        phasedLabels = (aptMap['phasedPackages'] as List)
            .map((e) => shortUpdateDisplayName(e.toString()))
            .toList();
      }

      return {
        'success': true,
        'message': 'recoveryCheckUpdatesComplete',
        'updateReport': updateReport,
        'updates': updates,
        'updateCount': updates.length,
        'summaryPackageCount': summaryPackageCount,
        'updateInstallableLabels': installableLabels,
        'updatePhasedLabels': phasedLabels,
        'kernelUpdates': kernelPkgs.toList(),
        'kernelUpdateCount': kernelPkgs.length,
        'kernelUpdateLabels': kernelLabels,
        'nonKernelUpdates': nonKernelUpdates,
        'nonKernelUpdateCount': nonKernelUpdates.length,
        'nonKernelUpdateLabels': nonKernelLabels,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'recoveryCheckUpdatesError',
        'error': e.toString(),
      };
    }
  }

  /// Restituisce true se [packageName] è un pacchetto del kernel Linux.
  ///
  /// Riconosce pacchetti Debian/Ubuntu (linux-image-*, linux-headers-*, …) e
  /// Fedora/RHEL (kernel-*, kernel-core, …).
  /// Detects kernel packages across ALL Linux distributions.
  ///
  /// Supported distros:
  /// - Debian/Ubuntu family (apt): linux-image, linux-headers, linux-modules, linux-tools, linux-libc-dev, linux-source, linux-signed, linux-base, linux-crashkernel
  /// - Fedora/RHEL/CentOS family (dnf/yum): kernel, kernel-core, kernel-modules, kernel-devel, kernel-headers, kernel-tools, kernel-debug, kernel-rt
  /// - Arch Linux family (pacman): linux, linux-lts, linux-zen, linux-hardened, linux-rt, linux-rt-lts, linux-cachyos, linux-bore, linux510/515/61/612 variants
  /// - openSUSE/SUSE (zypper): kernel-default, kernel-source, kernel-devel, kernel-rt
  /// - Gentoo (portage): sys-kernel/gentoo-kernel, sys-kernel/vanilla-kernel, sys-kernel/gentoo-sources, zen-sources, git-sources, etc.
  /// - Alpine (apk): linux-lts, linux-virt, linux-hardened, linux-rt
  /// - Void Linux (xbps-install): linux, linux-lts, linux-zen
  /// - Clear Linux: kernel-native, kernel-lts, kernel-devel
  /// - NixOS: linuxPackages.kernel, linuxPackages_latest.kernel, linuxPackages_hardened.kernel
  /// - Raspberry Pi OS: raspberrypi-kernel, raspberrypi-bootloader, raspberrypi-headers
  /// - Vendor kernels: xanmod, liquorix, cachyos, bore, surface, pf, ck, bmq, tkg, cjktty
  /// - Android: lineageos-kernel, com.android.kernel
  static bool _isKernelPackage(String name) {
    final t = name.trim();

    // ─── Exact match (no version suffix) ───
    if (t == 'linux') return true;
    if (t == 'kernel') return true;
    if (t == 'linux-libc-dev') return true;

    // ─── Debian/Ubuntu family (APT) ───
    if (t.startsWith('linux-image')) return true;
    if (t.startsWith('linux-headers')) return true;
    if (t.startsWith('linux-modules')) return true;
    if (t.startsWith('linux-modules-extra')) return true;
    if (t.startsWith('linux-tools')) return true;
    if (t.startsWith('linux-source')) return true;
    if (t.startsWith('linux-signed')) return true;
    if (t.startsWith('linux-base')) return true;
    if (t.startsWith('linux-crashkernel')) return true;
    if (t.startsWith('linux-performance-counters')) return true;
    if (t.startsWith('linux-doc')) return true;
    if (t.startsWith('linux-compiler-')) return true;
    if (t.startsWith('linux-buildinfo-')) return true;

    // ─── Fedora / RHEL / CentOS / Alma / Rocky (DNF/YUM) ───
    if (t == 'kernel-core') return true;
    if (t == 'kernel-modules') return true;
    if (t == 'kernel-modules-extra') return true;
    if (t == 'kernel-devel') return true;
    if (t == 'kernel-headers') return true;
    if (t == 'kernel-tools') return true;
    if (t == 'kernel-tools-libs') return true;
    if (t == 'kernel-tools-libs-devel') return true;
    if (t == 'kernel-doc') return true;
    if (t == 'kernel-abi-stablelists') return true;
    if (t == 'kernel-cross-headers') return true;
    if (t == 'kernel-debug') return true;
    if (t == 'kernel-debug-core') return true;
    if (t == 'kernel-debug-devel') return true;
    if (t == 'kernel-debug-modules') return true;
    if (t == 'kernel-debug-modules-extra') return true;
    if (t == 'kernel-rt') return true;
    if (t == 'kernel-rt-core') return true;
    if (t == 'kernel-rt-devel') return true;
    if (t == 'kernel-rt-modules') return true;
    if (t == 'kernel-rt-modules-extra') return true;
    if (t.startsWith('kernel-') && t.contains('.fc')) return true;  // Fedora versioned
    if (t.startsWith('kernel-') && t.contains('.el')) return true;  // RHEL versioned

    // ─── Arch Linux / Manjaro / EndeavourOS / Garuda (Pacman) ───
    if (t == 'linux-headers') return true;
    if (t == 'linux-lts') return true;
    if (t == 'linux-lts-headers') return true;
    if (t == 'linux-zen') return true;
    if (t == 'linux-zen-headers') return true;
    if (t == 'linux-hardened') return true;
    if (t == 'linux-hardened-headers') return true;
    if (t == 'linux-rt') return true;
    if (t == 'linux-rt-headers') return true;
    if (t == 'linux-rt-lts') return true;
    if (t == 'linux-rt-lts-headers') return true;
    if (t == 'linux-cachyos') return true;
    if (t == 'linux-cachyos-headers') return true;
    if (t == 'linux-cachyos-bore') return true;
    if (t == 'linux-cachyos-bore-headers') return true;
    if (t == 'linux-cachyos-hardened') return true;
    if (t == 'linux-cachyos-hardened-headers') return true;
    if (t == 'linux-cachyos-lts') return true;
    if (t == 'linux-cachyos-lts-headers') return true;
    if (t == 'linux-cachyos-rt-bore') return true;
    if (t == 'linux-cachyos-rt-bore-headers') return true;
    if (t == 'linux-cachyos-server') return true;
    if (t == 'linux-cachyos-server-headers') return true;
    if (t == 'linux-cachyos-deckify') return true;
    if (t == 'linux-cachyos-deckify-headers') return true;
    if (t == 'linux-bore') return true;
    if (t == 'linux-bore-headers') return true;
    if (t == 'linux-bore-eevdf') return true;
    if (t == 'linux-bore-eevdf-headers') return true;
    if (t == 'linux-bore-rt') return true;
    if (t == 'linux-bore-rt-headers') return true;
    if (t == 'linux-bore-cfs') return true;
    if (t == 'linux-bore-cfs-headers') return true;
    // Generic Arch patterns: linux-x.x.x.arch1-x, linux-lts-x.x.x-x, linux-zen-x.x.x-x
    if (RegExp(r'^linux(-lts|-zen|-hardened|-rt|-cachyos|-bore)?(-headers|-docs|-dbgsym)?$').hasMatch(t)) return true;

    // ─── openSUSE / SUSE (Zypper) ───
    if (t == 'kernel-default') return true;
    if (t == 'kernel-default-base') return true;
    if (t == 'kernel-default-devel') return true;
    if (t == 'kernel-default-extra') return true;
    if (t == 'kernel-default-optional') return true;
    if (t == 'kernel-source') return true;
    if (t == 'kernel-devel') return true;
    if (t == 'kernel-doc') return true;
    if (t == 'kernel-macros') return true;
    if (t == 'kernel-syms') return true;
    if (t == 'kernel-zfcpdump') return true;
    if (t == 'kernel-obs-build') return true;
    if (t == 'kernel-rt') return true;
    if (t == 'kernel-rt-devel') return true;
    if (t == 'kernel-rt-source-rt') return true;
    if (t == 'kernel-source-rt') return true;
    if (t == 'kernel-devel-rt') return true;

    // ─── Gentoo (Portage) ───
    if (t.startsWith('sys-kernel/gentoo-kernel')) return true;
    if (t.startsWith('sys-kernel/vanilla-kernel')) return true;
    if (t.startsWith('sys-kernel/gentoo-sources')) return true;
    if (t.startsWith('sys-kernel/vanilla-sources')) return true;
    if (t.startsWith('sys-kernel/linux-headers')) return true;
    if (t.startsWith('sys-kernel/debian-sources')) return true;
    if (t.startsWith('sys-kernel/zen-sources')) return true;
    if (t.startsWith('sys-kernel/git-sources')) return true;
    if (t.startsWith('sys-kernel/mptcp-sources')) return true;
    if (t.startsWith('sys-kernel/hardened-sources')) return true;
    if (t.startsWith('sys-kernel/ck-sources')) return true;
    if (t.startsWith('sys-kernel/bfq-sources')) return true;
    if (t.startsWith('sys-kernel/pf-sources')) return true;
    if (t.startsWith('sys-kernel/openrc-sources')) return true;

    // ─── Alpine Linux (APK) ───
    if (t == 'linux-lts') return true;
    if (t == 'linux-virt') return true;
    if (t == 'linux-hardened') return true;
    if (t == 'linux-rt') return true;
    if (t.startsWith('linux-lts-')) return true;
    if (t.startsWith('linux-virt-')) return true;
    if (t.startsWith('linux-hardened-')) return true;
    if (t.startsWith('linux-rt-')) return true;

    // ─── Void Linux (XBPS) ───
    if (t == 'linux') return true;
    if (t == 'linux-lts') return true;
    if (t == 'linux-zen') return true;
    if (t == 'linux-headers') return true;
    if (t == 'linux-lts-headers') return true;
    if (t == 'linux-zen-headers') return true;

    // ─── Clear Linux ───
    if (t == 'kernel-native') return true;
    if (t == 'kernel-lts') return true;
    if (t == 'kernel-devel') return true;
    if (t == 'kernel-headers') return true;
    if (t.startsWith('kernel-native-')) return true;
    if (t.startsWith('kernel-lts-')) return true;
    if (t.startsWith('kernel-devel-')) return true;

    // ─── NixOS ───
    if (t.startsWith('linuxPackages') && t.endsWith('.kernel')) return true;
    if (t.startsWith('linuxPackages') && t.contains('.linux-')) return true;
    if (t.startsWith('linux_')) return true;

    // ─── Raspberry Pi OS (apt) ───
    if (t.startsWith('raspberrypi-kernel')) return true;
    if (t.startsWith('raspberrypi-bootloader')) return true;
    if (t.startsWith('raspberrypi-headers')) return true;
    if (t.startsWith('raspberrypi-kernel-headers')) return true;

    // ─── Vendor/third-party kernels (universal) ───
    if (t.startsWith('linux-xanmod')) return true;
    if (t.startsWith('linux-liquorix')) return true;
    if (t.startsWith('linux-cachyos')) return true;
    if (t.startsWith('linux-bore')) return true;
    if (t.startsWith('linux-xanmod-edge')) return true;
    if (t.startsWith('linux-zen-git')) return true;
    if (t.startsWith('linux-hardened-git')) return true;
    if (t.startsWith('linux-pf')) return true;
    if (t.startsWith('linux-ck')) return true;
    if (t.startsWith('linux-pf-ck')) return true;
    if (t.startsWith('linux-bmq')) return true;
    if (t.startsWith('linux-tkg')) return true;
    if (t.startsWith('linux-cjktty')) return true;
    if (t.startsWith('linux-drm-tiled')) return true;
    if (t.startsWith('linux-surface')) return true;
    if (t.startsWith('linux-surface-headers')) return true;
    if (t.startsWith('linux-surface-lts')) return true;
    if (t.startsWith('linux-surface-lts-headers')) return true;

    // ─── Manjaro / Garuda / EndeavourOS specific (Pacman) ───
    if (t.startsWith('linux') && RegExp(r'^linux\d+$').hasMatch(t)) return true;  // linux510, linux515, linux61, linux612
    if (t.startsWith('linux') && RegExp(r'^linux\d+-headers$').hasMatch(t)) return true;

    // ─── NixOS (nix-env / nixos-rebuild) ───
    if (t.startsWith('linuxPackages_latest')) return true;
    if (t.startsWith('linuxPackages_testing')) return true;
    if (t.startsWith('linuxPackages_latest-zfs')) return true;

    // ─── Snap/Flatpak kernel-related ───
    if (t.contains('linux-kernel') || t.contains('kernel-update')) return true;

    // ─── Android kernel (Termux, LineageOS) ───
    if (t.startsWith('kernel-') && t.contains('android')) return true;
    if (t.startsWith('lineageos-kernel')) return true;
    if (t.startsWith('com.android.kernel')) return true;

    return false;
  }

  /// Human-readable short name for UI (APT/DNF/snap/Flatpak/pacman raw lines).
  static String shortUpdateDisplayName(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;

    // Flatpak ref: app/org.appname/x86_64/stable → "Org Appname"
    if (s.startsWith('app/') || s.startsWith('runtime/') || s.startsWith('system/')) {
      final segments = s.split('/');
      if (segments.length >= 2) {
        final appId = segments[1];
        final dotParts = appId.split('.');
        final name = dotParts.last;
        if (name.isNotEmpty) {
          return '${name[0].toUpperCase()}${name.substring(1)}';
        }
        return appId;
      }
    }

    final parts = s.split(RegExp(r'\s+'));
    final first = parts.first;
    // APT package pattern: firefox/focal-updates → firefox
    if (first.contains('/') && !first.startsWith('/')) {
      final idx = first.indexOf('/');
      if (idx > 0) {
        return first.substring(0, idx);
      }
    }
    if (first.contains('.') && first.contains('/')) {
      return first.split('/').first;
    }
    return first;
  }

  /// Estrae da una lista di pacchetti quelli del kernel.
  static List<String> _kernelPackagesFrom(List<String> pkgs) {
    return pkgs.where(_isKernelPackage).toList();
  }

  static Future<Map<String, dynamic>> _checkAptUpdatesReport(List<String> updatesOut) async {
    try {
      void addAptSimPackageLineTokens(String trimmed, Set<String> target) {
        final tokenRe =
            RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]*(?::[a-zA-Z0-9][a-zA-Z0-9+\-._]*)?$');
        for (final rawTok in trimmed.split(RegExp(r'\s+'))) {
          if (rawTok.isEmpty) continue;
          final tok = rawTok.trim();
          if (tok.length < 2) continue;
          if (!tokenRe.hasMatch(tok)) continue;
          target.add(tok);
        }
      }

      final simResult = await Process.run(
        'bash',
        ['-c', 'apt-get -s -y upgrade 2>&1'],
        runInShell: false,
      );
      final simOutput = '${simResult.stdout}\n${simResult.stderr}'.trim();
      if (simOutput.isEmpty) {
        updatesOut.clear();
        return {
          'mode': 'none',
          'installableCount': 0,
          'phasedCount': 0,
          'phasedPackages': <String>[],
        };
      }

      final instRegex = RegExp(r'^\s*Inst\s+([a-zA-Z0-9][a-zA-Z0-9+\-._]+)\b');
      final instPkgs = <String>{};
      for (final rawLine in simOutput.split('\n')) {
        final line = rawLine.trimRight();
        final match = instRegex.firstMatch(line);
        if (match != null) {
          instPkgs.add(match.group(1)!.trim());
        }
      }

      final deferredHeader = RegExp(
        r'(upgrades?\s+have\s+been\s+deferred|deferred.*phasing|postponed.*phasing|posticipat|scaglion|phasing:\s*$)',
        caseSensitive: false,
      );
      final deferredPkgs = <String>{};
      var inDeferredBlock = false;
      for (final rawLine in simOutput.split('\n')) {
        final line = rawLine.trim();
        if (deferredHeader.hasMatch(line)) {
          inDeferredBlock = true;
          continue;
        }
        if (inDeferredBlock) {
          if (line.isEmpty) {
            inDeferredBlock = false;
            continue;
          }
          final isIndented = rawLine.startsWith(' ') || rawLine.startsWith('\t');
          if (!isIndented) {
            inDeferredBlock = false;
            continue;
          }
          addAptSimPackageLineTokens(line, deferredPkgs);
        }
      }

      if (instPkgs.isNotEmpty) {
        final effectivePkgs = instPkgs.toList()..sort();
        final phasedList = deferredPkgs.toList()..sort();
        updatesOut
          ..clear()
          ..addAll(effectivePkgs);
        final kernelPkgs = _kernelPackagesFrom(effectivePkgs);
        return {
          'mode': 'installable',
          'installableCount': effectivePkgs.length,
          'phasedCount': deferredPkgs.length,
          'phasedPackages': phasedList,
          'kernelCount': kernelPkgs.length,
          'kernelPackages': kernelPkgs,
        };
      }

      final willUpgradeHeader = RegExp(
        r'(The following packages will be upgraded|following packages will be upgraded|pacchetti saranno aggiornati|Paquetes que serán actualizados|serán actualizados|seront mis à jour|werden aktualisiert|Pacotes a serem atualizados|saranno aggiornati)',
        caseSensitive: false,
      );
      var inWillUpgradeBlock = false;
      final willUpgradedPkgs = <String>{};
      for (final rawLine in simOutput.split('\n')) {
        final line = rawLine.trim();
        if (willUpgradeHeader.hasMatch(line)) {
          inWillUpgradeBlock = true;
          continue;
        }
        if (inWillUpgradeBlock) {
          if (line.isEmpty) {
            inWillUpgradeBlock = false;
            continue;
          }
          final isIndented = rawLine.startsWith(' ') || rawLine.startsWith('\t');
          if (!isIndented) {
            inWillUpgradeBlock = false;
            continue;
          }
          addAptSimPackageLineTokens(line, willUpgradedPkgs);
        }
      }

      if (willUpgradedPkgs.isNotEmpty) {
        final effectivePkgs = willUpgradedPkgs.toList()..sort();
        final phasedList = deferredPkgs.toList()..sort();
        updatesOut
          ..clear()
          ..addAll(effectivePkgs);
        final kernelPkgs = _kernelPackagesFrom(effectivePkgs);
        return {
          'mode': 'installable',
          'installableCount': effectivePkgs.length,
          'phasedCount': deferredPkgs.length,
          'phasedPackages': phasedList,
          'kernelCount': kernelPkgs.length,
          'kernelPackages': kernelPkgs,
        };
      }

      updatesOut.clear();
      final phasedList = deferredPkgs.toList()..sort();
      return {
        'mode': deferredPkgs.isNotEmpty ? 'phased_only' : 'none',
        'installableCount': 0,
        'phasedCount': deferredPkgs.length,
        'phasedPackages': phasedList,
        'kernelCount': 0,
        'kernelPackages': <String>[],
      };
    } catch (e) {
      try {
        final result = await Process.run(
          'apt',
          ['list', '--upgradable'],
          runInShell: false,
        );
        final aptOutput = result.stdout.toString();
        final packageRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+/[^\s,]+');
        final lines = aptOutput
            .split('\n')
            .where((line) {
              final trimmed = line.trim();
              return trimmed.isNotEmpty &&
                  !trimmed.contains('Listing...') &&
                  !trimmed.contains('WARNING:') &&
                  !trimmed.startsWith('WARNING:') &&
                  !trimmed.startsWith('...') &&
                  packageRegex.hasMatch(trimmed) &&
                  (trimmed.contains('upgradable') || trimmed.contains('/'));
            })
            .toList();
        updatesOut
          ..clear()
          ..addAll(lines);
        final kernelPkgs = _kernelPackagesFrom(lines);
        return {
          'mode': lines.isNotEmpty ? 'installable' : 'none',
          'installableCount': lines.length,
          'phasedCount': 0,
          'phasedPackages': <String>[],
          'kernelCount': kernelPkgs.length,
          'kernelPackages': kernelPkgs,
        };
      } catch (_) {
        updatesOut.clear();
        return {
          'mode': 'error',
          'installableCount': 0,
          'phasedCount': 0,
          'phasedPackages': <String>[],
          'errorMessage': '$e',
        };
      }
    }
  }

  static Future<Map<String, dynamic>> _checkDnfUpdatesReport(List<String> updatesOut) async {
    try {
      final result = await _runSudoCommand(r"dnf check-update --quiet 2>&1 | grep -v '^$' || true");
      final dnfOutput = result.stdout.toString();
      if (dnfOutput.isNotEmpty && !dnfOutput.contains('No updates')) {
        final packageRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+\.[a-zA-Z0-9]+\s+');
        final lines = dnfOutput
            .split('\n')
            .where((line) {
              final trimmed = line.trim();
              return trimmed.isNotEmpty &&
                  !trimmed.contains('Last metadata') &&
                  !trimmed.contains('Last metadata expiration') &&
                  !trimmed.contains('Error') &&
                  packageRegex.hasMatch(trimmed);
            })
            .toList();
        updatesOut.addAll(lines);
        return {'mode': 'installable', 'count': lines.length};
      }
      return {'mode': 'none', 'count': 0};
    } catch (e) {
      return {'mode': 'error', 'count': 0, 'errorMessage': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _checkPacmanUpdatesReport(List<String> updatesOut) async {
    try {
      final result = await _runSudoCommand('pacman -Qu 2>/dev/null || true');
      final pacmanOutput = result.stdout.toString();
      if (pacmanOutput.isNotEmpty) {
        final lines = pacmanOutput.split('\n').where((line) => line.trim().isNotEmpty).toList();
        updatesOut.addAll(lines);
        // Estrai pacchetti kernel (liquorix, xanmod, cachyos, ecc.)
        final kernelPkgs = _kernelPackagesFrom(lines.map((l) => l.trim().split(RegExp(r'\s+')).first).toList());
        return {
          'mode': 'installable',
          'count': lines.length,
          'kernelCount': kernelPkgs.length,
          'kernelPackages': kernelPkgs,
        };
      }
      return {'mode': 'none', 'count': 0};
    } catch (e) {
      return {'mode': 'error', 'count': 0, 'errorMessage': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _checkSnapUpdatesReport(List<String> updatesOut) async {
    try {
      final result = await _runSudoCommand('snap refresh --list 2>&1');
      final snapOutput = result.stdout.toString();
      if (snapOutput.isNotEmpty && !snapOutput.contains('All snaps up to date')) {
        final snapRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+\s+\d+\.\d+');
        final lines = snapOutput
            .split('\n')
            .where((line) {
              final trimmed = line.trim();
              return trimmed.isNotEmpty &&
                  !trimmed.contains('error') &&
                  !trimmed.contains('Error') &&
                  !trimmed.contains('Name') &&
                  !trimmed.startsWith('--') &&
                  snapRegex.hasMatch(trimmed);
            })
            .toList();
        updatesOut.addAll(lines);
        return {'mode': 'installable', 'count': lines.length};
      }
      return {'mode': 'none', 'count': 0};
    } catch (e) {
      return {'mode': 'error', 'count': 0, 'errorMessage': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> _checkFlatpakUpdatesReport(List<String> updatesOut) async {
    try {
      final found = <String>{};

      void parseOutput(String out) {
        final lines = out.split('\n');
        for (final rawLine in lines) {
          final trimmed = rawLine.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed.contains('Nothing to update')) continue;
          if (trimmed.startsWith('Looking for')) continue;
          if (trimmed.startsWith('Updating')) continue;
          if (trimmed.startsWith('Info:')) continue;
          if (trimmed.startsWith('Warning:')) continue;
          if (trimmed.startsWith('--')) continue;
          if (trimmed.startsWith('Error') || trimmed.contains('error')) continue;
          if (trimmed.startsWith('Ref ') || trimmed.startsWith('Name ')) continue;

          // Con `--columns=ref` ogni riga è già un ref. Se però arrivano warning/testo extra,
          // scartiamo tutto ciò che non assomiglia ad un ref Flatpak.
          if (!trimmed.contains('/')) continue;
          if (trimmed.contains(' ')) continue;
          found.add(trimmed);
        }
      }

      // Flatpak può avere installazioni "user" e "system": gli aggiornamenti tipo
      // Freedesktop Platform spesso sono a livello system, quindi controlliamo entrambi.
      try {
        final userRes = await Process.run(
          'bash',
          ['-c', 'flatpak --user remote-ls --updates --columns=ref 2>&1'],
          runInShell: false,
        );
        parseOutput('${userRes.stdout}\n${userRes.stderr}');
      } catch (_) {}

      try {
        final sysRes = await _runSudoCommand('flatpak --system remote-ls --updates --columns=ref 2>&1');
        parseOutput('${sysRes.stdout}\n${sysRes.stderr}');
      } catch (_) {}

      final count = found.length;
      if (count > 0) {
        updatesOut.addAll(found);
        return {'mode': 'installable', 'count': count};
      }

      return {'mode': 'none', 'count': 0};
    } catch (e) {
      return {'mode': 'error', 'count': 0, 'errorMessage': e.toString()};
    }
  }

  /// Da output apt/dpkg: nome pacchetto in corso (per UI).
  static String? _aptProgressPackageLine(String line) {
    final s = line.trimLeft();
    var m = RegExp(r'^Setting up\s+(\S+)').firstMatch(s);
    if (m != null) return m.group(1);
    m = RegExp(r'^Unpacking\s+(\S+)').firstMatch(s);
    if (m != null) return m.group(1);
    m = RegExp(r'^Preparing to unpack\s+\S+_(\S+?)_[\d.]+_').firstMatch(s);
    if (m != null) return m.group(1);
    return null;
  }

  /// Legge solo stdout (usa `2>&1` nel comando per unire gli stream).
  static Future<int> _pumpStdoutLines(
    Process process, {
    required void Function(String chunk) onChunk,
    void Function(String line)? onLine,
  }) async {
    final buf = StringBuffer();
    await for (final chunk in process.stdout.transform(utf8.decoder)) {
      onChunk(chunk);
      buf.write(chunk);
      var str = buf.toString();
      var nl = str.indexOf('\n');
      while (nl >= 0) {
        onLine?.call(str.substring(0, nl));
        str = str.substring(nl + 1);
        nl = str.indexOf('\n');
      }
      buf.clear();
      buf.write(str);
    }
    final tail = buf.toString();
    if (tail.isNotEmpty) onLine?.call(tail);
    await process.stderr.drain();
    return await process.exitCode;
  }

  static String _sudoBashCommand(String escapedPassword, String remoteCommand) {
    return 'printf "%s\\n" "$escapedPassword" | sudo -S bash -c ${shellQuote(remoteCommand)}';
  }

  static String _grubBackupTimestamp() {
    final n = DateTime.now();
    String p2(int x) => x.toString().padLeft(2, '0');
    return '${n.year}${p2(n.month)}${p2(n.day)}_${p2(n.hour)}${p2(n.minute)}${p2(n.second)}';
  }

  static Future<Map<String, dynamic>> performUpdates({
    Function(String)? onOutput,
    void Function(double progress, String? statusLabel)? onProgress,
    int expectedPackageCount = 0,
    List<String>? selectedUpdates,
  }) async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      var output = '';
      final updated = <String>[];

      var numManagers = 0;
      if (systemInfo.hasApt) numManagers++;
      if (systemInfo.hasDnf) numManagers++;
      if (systemInfo.hasPacman) numManagers++;
      if (systemInfo.hasSnap) numManagers++;
      if (systemInfo.hasFlatpak) numManagers++;

      if (numManagers == 0) {
        return {
          'success': false,
          'message': 'Nessun gestore pacchetti supportato (APT/DNF/Pacman/Snap/Flatpak)',
          'output': output,
        };
      }

      var managerIndex = 0;
      double segStart() => managerIndex / numManagers;
      double segEnd() => (managerIndex + 1) / numManagers;

      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        throw Exception('Password non salvata. Salva la password nelle impostazioni.');
      }
      final escapedPassword = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r')
          .replaceAll("'", "\\'");

      // APT (Ubuntu/Debian/Mint): apt update separato + upgrade con avanzamento
      if (systemInfo.hasApt) {
        final a = segStart();
        final b = segEnd();
        final span = b - a;
        try {
          onProgress?.call(a, 'APT: apt update');
          var cmd = _sudoBashCommand(escapedPassword, 'apt update 2>&1');
          var process = await Process.start('bash', ['-c', cmd], runInShell: true);
          var updateExit = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
          );

          if (updateExit != 0) {
            output += '\nAPT: apt update exit $updateExit\n';
          }

          onProgress?.call(a + span * 0.1, 'APT: apt upgrade');
          var aptSteps = 0;
          final denom = expectedPackageCount > 0 ? expectedPackageCount : 32;

          final isSelectiveApt = selectedUpdates != null && selectedUpdates.isNotEmpty;
          final aptPkgs = isSelectiveApt
              ? selectedUpdates.where((u) {
                  final s = u.trim();
                  return s.isNotEmpty &&
                      !s.contains('/') &&
                      !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]*\.[a-zA-Z]+\s+').hasMatch(s) &&
                      !s.contains(' ') &&
                      !s.startsWith('app/') &&
                      !s.startsWith('runtime/');
                }).map((u) => u.trim().split(RegExp(r'\s+')).first).join(' ')
              : '';
          final aptUpgradeCmd = isSelectiveApt && aptPkgs.isNotEmpty
              ? 'DEBIAN_FRONTEND=noninteractive apt install --only-upgrade -y $aptPkgs 2>&1'
              : 'DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1';
          cmd = _sudoBashCommand(escapedPassword, aptUpgradeCmd);
          process = await Process.start('bash', ['-c', cmd], runInShell: true);
          final aptExit = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
            onLine: (line) {
              final pkg = _aptProgressPackageLine(line);
              if (pkg != null) {
                aptSteps++;
                final localT = (aptSteps / denom).clamp(0.0, 1.0);
                final p = a + span * (0.1 + 0.88 * localT);
                onProgress?.call(p.clamp(0.0, 0.995), 'APT: $pkg');
              }
            },
          );

          if (aptExit == 0) {
            updated.add('APT');
          } else {
            output += '\nAPT: apt upgrade exit $aptExit\n';
          }
        } catch (e) {
          output += 'APT: Errore durante l\'aggiornamento: $e\n';
        }
        managerIndex++;
      }

      // DNF (Fedora/RHEL/CentOS)
      if (systemInfo.hasDnf) {
        final a = segStart();
        final b = segEnd();
        final span = b - a;
        try {
          onProgress?.call(a, 'DNF: update');
          var dnfLines = 0;
          final cmd = _sudoBashCommand(escapedPassword, 'dnf update -y 2>&1');
          final process = await Process.start('bash', ['-c', cmd], runInShell: true);
          final code = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
            onLine: (line) {
              final t = line.trim();
              if (t.isEmpty) return;
              if (t.startsWith('Last metadata') ||
                  t.startsWith('Dependencies resolved') ||
                  t.startsWith('Transaction Summary') ||
                  t.startsWith('Complete!')) {
                return;
              }
              dnfLines++;
              final localT = (dnfLines / 80.0).clamp(0.0, 1.0);
              onProgress?.call(
                (a + span * localT).clamp(0.0, 0.995),
                'DNF: $t',
              );
            },
          );
          if (code == 0) {
            updated.add('DNF');
          } else {
            output += 'DNF: exit $code\n';
          }
        } catch (e) {
          output += 'DNF: Errore durante l\'aggiornamento: $e\n';
        }
        managerIndex++;
      }

      // Pacman (Arch/Manjaro)
      if (systemInfo.hasPacman) {
        final a = segStart();
        final b = segEnd();
        final span = b - a;
        try {
          onProgress?.call(a, 'Pacman: -Syu');
          var n = 0;
          final cmd = _sudoBashCommand(escapedPassword, 'pacman -Syu --noconfirm 2>&1');
          final process = await Process.start('bash', ['-c', cmd], runInShell: true);
          final code = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
            onLine: (line) {
              final t = line.trim();
              if (t.isEmpty) return;
              n++;
              final localT = (n / 100.0).clamp(0.0, 1.0);
              onProgress?.call(
                (a + span * localT).clamp(0.0, 0.995),
                'Pacman: $t',
              );
            },
          );
          output += 'Pacman: exit $code\n';
          if (code == 0) {
            updated.add('Pacman');
          }
        } catch (e) {
          output += 'Pacman: Errore durante l\'aggiornamento: $e\n';
        }
        managerIndex++;
      }

      // Snap
      if (systemInfo.hasSnap) {
        final a = segStart();
        final b = segEnd();
        final span = b - a;
        try {
          onProgress?.call(a, 'Snap: refresh');
          var n = 0;
          final cmd = _sudoBashCommand(escapedPassword, 'snap refresh 2>&1');
          final process = await Process.start('bash', ['-c', cmd], runInShell: true);
          final code = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
            onLine: (line) {
              final t = line.trim();
              if (t.isEmpty) return;
              n++;
              final localT = (n / 40.0).clamp(0.0, 1.0);
              onProgress?.call(
                (a + span * localT).clamp(0.0, 0.995),
                'Snap: $t',
              );
            },
          );
          if (code == 0) {
            updated.add('Snap');
          } else {
            output += 'Snap: stderr/exit $code\n';
          }
        } catch (e) {
          output += 'Snap: Errore durante l\'aggiornamento: $e\n';
        }
        managerIndex++;
      }

      // Flatpak
      if (systemInfo.hasFlatpak) {
        final a = segStart();
        final b = segEnd();
        final span = b - a;
        final userSpan = span * 0.5;
        final sysSpan = span - userSpan;
        var ranAny = false;
        try {
          // Update "user" (non usa sudo, per non cambiare HOME).
          onProgress?.call(a, 'Flatpak: user update');
          var n = 0;
          final process = await Process.start(
            'bash',
            ['-c', 'flatpak --user update -y 2>&1'],
            runInShell: false,
          );
          final code = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
            onLine: (line) {
              final t = line.trim();
              if (t.isEmpty) return;
              n++;
              final localT = (n / 60.0).clamp(0.0, 1.0);
              onProgress?.call(
                (a + userSpan * localT).clamp(0.0, 0.995),
                'Flatpak: $t',
              );
            },
          );
          if (code == 0) ranAny = true;
          if (code != 0) output += 'Flatpak (user): exit $code\n';
        } catch (e) {
          output += 'Flatpak (user): Errore durante l\'aggiornamento: $e\n';
        }

        try {
          // Update "system" (Freedesktop Platform spesso è a livello system).
          onProgress?.call(a + userSpan * 0.98, 'Flatpak: system update');
          var n = 0;
          final cmd = _sudoBashCommand(
            escapedPassword,
            'flatpak --system update -y 2>&1',
          );
          final process = await Process.start('bash', ['-c', cmd], runInShell: true);
          final code = await _pumpStdoutLines(
            process,
            onChunk: (c) {
              output += c;
              onOutput?.call(c);
            },
            onLine: (line) {
              final t = line.trim();
              if (t.isEmpty) return;
              n++;
              final localT = (n / 60.0).clamp(0.0, 1.0);
              onProgress?.call(
                (a + userSpan + sysSpan * localT).clamp(0.0, 0.995),
                'Flatpak: $t',
              );
            },
          );
          if (code == 0) ranAny = true;
          if (code != 0) output += 'Flatpak (system): exit $code\n';
        } catch (e) {
          output += 'Flatpak (system): Errore durante l\'aggiornamento: $e\n';
        }

        if (ranAny) {
          updated.add('Flatpak');
        }
        managerIndex++;
      }

      onProgress?.call(1.0, null);

      if (updated.isEmpty) {
        return {
          'success': false,
          'message': 'Nessun aggiornamento eseguito',
          'output': output,
        };
      }

      return {
        'success': true,
        'message': 'Aggiornamenti completati per: ${updated.join(", ")}',
        'output': output,
        'updated': updated,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante l\'esecuzione degli aggiornamenti: $e',
      };
    }
  }

  /// Installs a list of packages using the system package manager. Returns { success, message, output }.
  static Future<Map<String, dynamic>> _installPackages(List<String> packages, String operationName) async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      // Assicura che i repository siano configurati per questa distro (solo se necessario)
      final reposHealthy = await RepositoryManager.areRepositoriesHealthy();
      if (!reposHealthy) {
        await RepositoryManager.restoreRepositories();
      }
      final updateCmd = RepositoryManager.getUpdateCacheCommand(systemInfo);
      if (updateCmd != null) {
        try { await _runSudoCommand(updateCmd); } catch (_) {}
      }
      String output = '';
      String command;

      if (systemInfo.hasApt) {
        command = 'apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y ${packages.join(" ")}';
      } else if (systemInfo.hasDnf) {
        command = 'dnf install -y ${packages.join(" ")}';
      } else if (systemInfo.hasPacman) {
        command = 'pacman -S --noconfirm ${packages.join(" ")}';
      } else {
        return {
          'success': false,
          'message': 'Nessun package manager supportato (APT/DNF/Pacman)',
        };
      }

      final result = await _runSudoCommand(command);
      output = result.stdout.toString();
      final err = result.stderr.toString();
      if (err.isNotEmpty) {
        if (output.isNotEmpty) output += '\n';
        output += err;
      }
      if (result.exitCode != 0) {
        return {
          'success': false,
          'message': 'Errore durante l\'installazione di $operationName',
          'output': output,
        };
      }
      return {
        'success': true,
        'message': '$operationName installato con successo',
        'output': output,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> installFfmpeg() async {
    return _installPackages(['ffmpeg'], 'FFmpeg');
  }

  static Future<Map<String, dynamic>> installYtDlp() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      if (systemInfo.hasApt) {
        return _installPackages(['yt-dlp'], 'yt-dlp');
      }
      if (systemInfo.hasDnf) {
        return _installPackages(['yt-dlp'], 'yt-dlp');
      }
      if (systemInfo.hasPacman) {
        return _installPackages(['yt-dlp'], 'yt-dlp');
      }
      return {'success': false, 'message': 'Package manager non supportato per yt-dlp'};
    } catch (e) {
      return {'success': false, 'message': 'Errore: $e'};
    }
  }

  static Future<Map<String, dynamic>> installSystemLibraries() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      List<String> packages;
      if (systemInfo.hasApt) {
        packages = ['build-essential', 'libc6-dev', 'pkg-config'];
      } else if (systemInfo.hasDnf) {
        packages = ['@development-tools', 'glibc-devel'];
      } else if (systemInfo.hasPacman) {
        packages = ['base-devel'];
      } else {
        return {'success': false, 'message': 'Package manager non supportato'};
      }
      return _installPackages(packages, 'Librerie di sistema');
    } catch (e) {
      return {'success': false, 'message': 'Errore: $e'};
    }
  }

  static Future<Map<String, dynamic>> installCodecs() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      List<String> packages;
      if (systemInfo.hasApt) {
        packages = [
          'gstreamer1.0-libav',
          'gstreamer1.0-plugins-bad',
          'gstreamer1.0-plugins-ugly',
        ];
      } else if (systemInfo.hasDnf) {
        packages = ['ffmpeg', 'gstreamer1-plugins-ugly', 'gstreamer1-plugins-bad-free'];
      } else if (systemInfo.hasPacman) {
        packages = ['gst-libav', 'gst-plugins-bad', 'gst-plugins-ugly'];
      } else {
        return {'success': false, 'message': 'Package manager non supportato'};
      }
      return _installPackages(packages, 'Codec video e audio');
    } catch (e) {
      return {'success': false, 'message': 'Errore: $e'};
    }
  }

  static Future<Map<String, dynamic>> installRsync() async {
    return _installPackages(['rsync'], 'rsync');
  }

  static Future<Map<String, dynamic>> fixWifiAutoSuspend() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      String output = '';

      // Step 1: udev rule — disable USB autosuspend globally (works on ALL distros)
      const udevRule =
          '# Disable USB autosuspend for WiFi adapters and all USB devices\n'
          'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"\n'
          'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend", ATTR{power/autosuspend}="0"\n'
          'ACTION=="add", SUBSYSTEM=="usb", TEST=="power/autosuspend_delay_ms", ATTR{power/autosuspend_delay_ms}="0"\n';

      const ruleFile = '/etc/udev/rules.d/99-wifi-disable-autosuspend.rules';

      // Write udev rule via sudo tee
      try {
        final result = await _runSudoCommand(
          'sh -c "cat > $ruleFile" << \'UDEV_EOF\'\n$udevRule\nUDEV_EOF',
        );
        output += 'udev rule: ${result.exitCode == 0 ? "written" : "error"}\n';
        if (result.exitCode != 0) {
          output += '${result.stderr}\n';
        }
      } catch (e) {
        output += 'udev rule write failed: $e\n';
      }

      // Reload udev rules
      try {
        final result = await _runSudoCommand('udevadm control --reload-rules && udevadm trigger');
        output += 'udev reload: ${result.exitCode == 0 ? "ok" : "error"}\n';
        if (result.exitCode != 0) {
          output += '${result.stderr}\n';
        }
      } catch (e) {
        output += 'udev reload failed: $e\n';
      }

      // Step 2: Disable WiFi power saving in NetworkManager (all distros)
      const nmConfigDir = '/etc/NetworkManager/conf.d';
      const nmConfigFile = '$nmConfigDir/99-wifi-powersave-off.conf';
      const nmContent = '[connection]\nwifi.powersave = 2\n';

      try {
        await _runSudoCommand('mkdir -p $nmConfigDir');
        final result = await _runSudoCommand(
          'sh -c "cat > $nmConfigFile" << \'NM_EOF\'\n$nmContent\nNM_EOF',
        );
        output += 'NM config: ${result.exitCode == 0 ? "written" : "error"}\n';
        if (result.exitCode != 0) {
          output += '${result.stderr}\n';
        }
      } catch (e) {
        output += 'NM config write failed: $e\n';
      }

      // Restart NetworkManager to apply
      try {
        final result = await _runSudoCommand('systemctl restart NetworkManager');
        output += 'NM restart: ${result.exitCode == 0 ? "ok" : "error"}\n';
        if (result.exitCode != 0) {
          output += '${result.stderr}\n';
        }
      } catch (e) {
        output += 'NM restart failed: $e\n';
      }

      // Step 3: Also apply immediately to currently connected USB WiFi devices
      try {
        final result = await Process.run(
          'bash',
          ['-c', 'for dev in /sys/bus/usb/devices/*/power/control; do '
              'if [ -f "\$dev" ]; then '
              'echo on > "\$dev" 2>/dev/null; '
              'fi; done; '
              'for dev in /sys/bus/usb/devices/*/power/autosuspend; do '
              'if [ -f "\$dev" ]; then '
              'echo 0 > "\$dev" 2>/dev/null; '
              'fi; done'],
          runInShell: true,
        );
        output += 'Runtime apply: ${result.exitCode == 0 ? "ok" : "partial"}\n';
      } catch (e) {
        output += 'Runtime apply skipped: $e\n';
      }

      final success = output.contains('written') || output.contains('ok');
      return {
        'success': success,
        'message': success
            ? 'WiFi auto-suspend disabilitato con successo. Riavvia per applicare completamente.'
            : 'Errore durante la disabilitazione del WiFi auto-suspend',
        'output': output,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante il fix WiFi auto-suspend: $e',
      };
    }
  }
}

