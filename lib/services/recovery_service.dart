import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'password_storage.dart';
import 'system_detector.dart';

class RecoveryService {
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
      
      // Backup del grub.cfg esistente
      try {
        if (distLower.contains('fedora') || distLower.contains('rhel') || distLower.contains('centos')) {
          await _runSudoCommand(r'cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.backup.$(date +%Y%m%d_%H%M%S)');
        } else {
          await _runSudoCommand(r'cp /boot/grub/grub.cfg /boot/grub/grub.cfg.backup.$(date +%Y%m%d_%H%M%S)');
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
    try {
      final systemInfo = await SystemDetector.detectSystem();
      String output = '';
      final distLower = systemInfo.distribution.toLowerCase();

      if (systemInfo.hasApt) {
        // Ubuntu/Debian/Mint
        try {
          // Aggiorna le liste dei pacchetti
          final result = await _runSudoCommand('apt update');
          output = result.stdout.toString();
          if (result.exitCode != 0) {
            output += '\n${result.stderr}';
            return {
              'success': false,
              'message': 'Errore durante l\'aggiornamento dei repository APT',
              'output': output,
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Errore durante il ripristino dei repository: $e',
          };
        }
      } else if (systemInfo.hasDnf) {
        // Fedora/RHEL/CentOS
        try {
          // Ricostruisce la cache DNF
          final result = await _runSudoCommand('dnf clean all && dnf makecache');
          output = result.stdout.toString();
          if (result.exitCode != 0) {
            output += '\n${result.stderr}';
            return {
              'success': false,
              'message': 'Errore durante il ripristino dei repository DNF',
              'output': output,
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Errore durante il ripristino dei repository: $e',
          };
        }
      } else if (systemInfo.hasPacman) {
        // Arch/Manjaro
        try {
          // Aggiorna il database dei pacchetti
          final result = await _runSudoCommand('pacman -Sy');
          output = result.stdout.toString();
          if (result.exitCode != 0) {
            output += '\n${result.stderr}';
            return {
              'success': false,
              'message': 'Errore durante l\'aggiornamento del database Pacman',
              'output': output,
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Errore durante il ripristino dei repository: $e',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Nessun package manager supportato rilevato',
        };
      }

      return {
        'success': true,
        'message': 'Repository ripristinati con successo',
        'output': output,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore durante il ripristino dei repository: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> checkForUpdates() async {
    try {
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

      return {
        'success': true,
        'message': 'recoveryCheckUpdatesComplete',
        'updateReport': updateReport,
        'updates': updates,
        'updateCount': updates.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'recoveryCheckUpdatesError',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _checkAptUpdatesReport(List<String> updatesOut) async {
    try {
      final simResult = await Process.run(
        'bash',
        ['-c', 'apt-get -s -y upgrade 2>&1'],
        runInShell: false,
      );
      final simOutput = '${simResult.stdout}\n${simResult.stderr}'.trim();
      if (simOutput.isEmpty) {
        updatesOut.clear();
        return {'mode': 'none', 'installableCount': 0, 'phasedCount': 0};
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
        r'(upgrades?\s+have\s+been\s+deferred.*phasing|deferred.*phasing|postponed.*phasing|scaglion)',
        caseSensitive: false,
      );
      final pkgPrefixRegex = RegExp(r'^([a-zA-Z0-9][a-zA-Z0-9+\-._]+)');
      final deferredPkgs = <String>{};
      var inDeferredBlock = false;
      for (final rawLine in simOutput.split('\n')) {
        final trimmed = rawLine.trim();
        if (deferredHeader.hasMatch(trimmed)) {
          inDeferredBlock = true;
          continue;
        }
        if (inDeferredBlock) {
          if (trimmed.isEmpty) {
            inDeferredBlock = false;
            continue;
          }
          final match = pkgPrefixRegex.firstMatch(trimmed);
          if (match != null) {
            deferredPkgs.add(match.group(1)!.trim());
          }
        }
      }

      if (instPkgs.isNotEmpty) {
        final effectivePkgs = instPkgs.toList()..sort();
        updatesOut
          ..clear()
          ..addAll(effectivePkgs);
        return {
          'mode': 'installable',
          'installableCount': effectivePkgs.length,
          'phasedCount': deferredPkgs.length,
        };
      }

      final willUpgradeHeader = RegExp(r'^The following packages will be upgraded:\s*$');
      var inWillUpgradeBlock = false;
      final willUpgradedPkgs = <String>{};
      for (final rawLine in simOutput.split('\n')) {
        final trimmed = rawLine.trim();
        if (willUpgradeHeader.hasMatch(trimmed)) {
          inWillUpgradeBlock = true;
          continue;
        }
        if (inWillUpgradeBlock) {
          if (trimmed.isEmpty) {
            inWillUpgradeBlock = false;
            continue;
          }
          final match = pkgPrefixRegex.firstMatch(trimmed);
          if (match != null) {
            willUpgradedPkgs.add(match.group(1)!.trim());
          }
        }
      }

      if (willUpgradedPkgs.isNotEmpty) {
        final effectivePkgs = willUpgradedPkgs.toList()..sort();
        updatesOut
          ..clear()
          ..addAll(effectivePkgs);
        return {
          'mode': 'installable',
          'installableCount': effectivePkgs.length,
          'phasedCount': deferredPkgs.length,
        };
      }

      updatesOut.clear();
      return {
        'mode': deferredPkgs.isNotEmpty ? 'phased_only' : 'none',
        'installableCount': 0,
        'phasedCount': deferredPkgs.length,
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
        return {
          'mode': lines.isNotEmpty ? 'installable' : 'none',
          'installableCount': lines.length,
          'phasedCount': 0,
        };
      } catch (_) {
        updatesOut.clear();
        return {
          'mode': 'error',
          'installableCount': 0,
          'phasedCount': 0,
          'errorMessage': '$e',
        };
      }
    }
  }

  static Future<Map<String, dynamic>> _checkDnfUpdatesReport(List<String> updatesOut) async {
    try {
      final result = await _runSudoCommand(r'dnf check-update --quiet 2>&1 | grep -v "^$" || true');
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
        return {'mode': 'installable', 'count': lines.length};
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
      final result = await _runSudoCommand('flatpak remote-ls --updates 2>&1');
      final flatpakOutput = result.stdout.toString();
      if (flatpakOutput.isNotEmpty && !flatpakOutput.contains('Nothing to update')) {
        final flatpakRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+\s+');
        final lines = flatpakOutput
            .split('\n')
            .where((line) {
              final trimmed = line.trim();
              return trimmed.isNotEmpty &&
                  !trimmed.contains('Looking for') &&
                  !trimmed.contains('Error') &&
                  !trimmed.contains('error') &&
                  flatpakRegex.hasMatch(trimmed);
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

  static String shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static Future<Map<String, dynamic>> performUpdates({
    Function(String)? onOutput,
    void Function(double progress, String? statusLabel)? onProgress,
    int expectedPackageCount = 0,
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
          .replaceAll('`', '\\`');

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

          cmd = _sudoBashCommand(escapedPassword, 'DEBIAN_FRONTEND=noninteractive apt upgrade -y 2>&1');
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
        try {
          onProgress?.call(a, 'Flatpak: update');
          var n = 0;
          final cmd = _sudoBashCommand(escapedPassword, 'flatpak update -y 2>&1');
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
                (a + span * localT).clamp(0.0, 0.995),
                'Flatpak: $t',
              );
            },
          );
          if (code == 0) {
            updated.add('Flatpak');
          } else {
            output += 'Flatpak: exit $code\n';
          }
        } catch (e) {
          output += 'Flatpak: Errore durante l\'aggiornamento: $e\n';
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
      if (result.exitCode != 0) {
        output += '\n${result.stderr}';
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
}

