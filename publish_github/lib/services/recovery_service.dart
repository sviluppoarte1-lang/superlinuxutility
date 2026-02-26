import 'dart:io';
import 'dart:convert';
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
      String output = '';
      List<String> updates = [];

      // APT (Ubuntu/Debian/Mint)
      if (systemInfo.hasApt) {
        try {
          // apt list --upgradable non richiede sudo
          final result = await Process.run(
            'apt',
            ['list', '--upgradable'],
            runInShell: false,
          );
          final aptOutput = result.stdout.toString();
          if (aptOutput.isNotEmpty) {
            // Filtra solo le righe che sono pacchetti validi (formato: nome/versione)
            // Escludi header, messaggi di warning, e righe vuote
            // Il formato tipico è: nome/versione,versione2,versione3 arch [upgradable from: versione]
            final packageRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+/[^\s,]+');
            final lines = aptOutput.split('\n')
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
            updates.addAll(lines);
            output += 'APT: ${lines.length} aggiornamenti disponibili\n';
          } else {
            output += 'APT: Nessun aggiornamento disponibile\n';
          }
        } catch (e) {
          output += 'APT: Errore durante la verifica: $e\n';
        }
      }

      // DNF (Fedora/RHEL/CentOS)
      if (systemInfo.hasDnf) {
        try {
          final result = await _runSudoCommand(r'dnf check-update --quiet 2>&1 | grep -v "^$" || true');
          final dnfOutput = result.stdout.toString();
          if (dnfOutput.isNotEmpty && !dnfOutput.contains('No updates')) {
            // Filtra solo le righe che sono pacchetti (escludi header, metadata, messaggi)
            // I pacchetti DNF hanno formato: nome.arch versione repository
            final packageRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+\.[a-zA-Z0-9]+\s+');
            final lines = dnfOutput.split('\n')
                .where((line) {
                  final trimmed = line.trim();
                  return trimmed.isNotEmpty && 
                      !trimmed.contains('Last metadata') &&
                      !trimmed.contains('Last metadata expiration') &&
                      !trimmed.contains('Error') &&
                      packageRegex.hasMatch(trimmed);
                })
                .toList();
            updates.addAll(lines);
            output += 'DNF: ${lines.length} aggiornamenti disponibili\n';
          } else {
            output += 'DNF: Nessun aggiornamento disponibile\n';
          }
        } catch (e) {
          output += 'DNF: Errore durante la verifica\n';
        }
      }

      // Pacman (Arch/Manjaro)
      if (systemInfo.hasPacman) {
        try {
          final result = await _runSudoCommand('pacman -Qu 2>/dev/null || true');
          final pacmanOutput = result.stdout.toString();
          if (pacmanOutput.isNotEmpty) {
            final lines = pacmanOutput.split('\n').where((line) => line.trim().isNotEmpty).toList();
            updates.addAll(lines);
            output += 'Pacman: ${lines.length} aggiornamenti disponibili\n';
          } else {
            output += 'Pacman: Nessun aggiornamento disponibile\n';
          }
        } catch (e) {
          output += 'Pacman: Errore durante la verifica\n';
        }
      }

      // Snap
      if (systemInfo.hasSnap) {
        try {
          final result = await _runSudoCommand('snap refresh --list 2>&1');
          final snapOutput = result.stdout.toString();
          if (snapOutput.isNotEmpty && !snapOutput.contains('All snaps up to date')) {
            // Filtra solo le righe che sono snap packages validi
            // Il formato è: nome versione da versione
            final snapRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+\s+\d+\.\d+');
            final lines = snapOutput.split('\n')
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
            updates.addAll(lines);
            output += 'Snap: ${lines.length} aggiornamenti disponibili\n';
          } else {
            output += 'Snap: Nessun aggiornamento disponibile\n';
          }
        } catch (e) {
          output += 'Snap: Errore durante la verifica\n';
        }
      }

      // Flatpak
      if (systemInfo.hasFlatpak) {
        try {
          final result = await _runSudoCommand('flatpak remote-ls --updates 2>&1');
          final flatpakOutput = result.stdout.toString();
          if (flatpakOutput.isNotEmpty && !flatpakOutput.contains('Nothing to update')) {
            // Filtra solo le righe che sono applicazioni flatpak valide
            // Il formato è: nome versione branch
            final flatpakRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9+\-._]+\s+');
            final lines = flatpakOutput.split('\n')
                .where((line) {
                  final trimmed = line.trim();
                  return trimmed.isNotEmpty && 
                      !trimmed.contains('Looking for') &&
                      !trimmed.contains('Error') &&
                      !trimmed.contains('error') &&
                      flatpakRegex.hasMatch(trimmed);
                })
                .toList();
            updates.addAll(lines);
            output += 'Flatpak: ${lines.length} aggiornamenti disponibili\n';
          } else {
            output += 'Flatpak: Nessun aggiornamento disponibile\n';
          }
        } catch (e) {
          output += 'Flatpak: Errore durante la verifica\n';
        }
      }

      return {
        'success': true,
        'message': 'recoveryCheckUpdatesComplete', // Chiave di traduzione
        'output': output,
        'updates': updates,
        'updateCount': updates.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'recoveryCheckUpdatesError', // Chiave di traduzione
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> performUpdates({
    Function(String)? onOutput,
  }) async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      String output = '';
      List<String> updated = [];

      // APT (Ubuntu/Debian/Mint)
      if (systemInfo.hasApt) {
        try {
          final password = await PasswordStorage.getPassword();
          if (password == null || password.isEmpty) {
            throw Exception('Password non salvata. Salva la password nelle impostazioni.');
          }
          
          final escapedPassword = password
              .replaceAll('\\', '\\\\')
              .replaceAll('"', '\\"')
              .replaceAll('\$', '\\\$')
              .replaceAll('`', '\\`');
          
          // Usa Process.start per avere output in tempo reale
          final process = await Process.start(
            'bash',
            ['-c', 'printf "%s\\n" "$escapedPassword" | sudo -S bash -c "apt update && apt upgrade -y"'],
            runInShell: true,
          );
          
          // Leggi l'output in tempo reale
          process.stdout.transform(const SystemEncoding().decoder).listen((data) {
            output += data;
            onOutput?.call(data);
          });
          
          process.stderr.transform(const SystemEncoding().decoder).listen((data) {
            output += data;
            onOutput?.call(data);
          });
          
          final exitCode = await process.exitCode;
          if (exitCode == 0) {
            updated.add('APT');
          } else {
            output += '\nAPT: Comando terminato con codice $exitCode\n';
          }
        } catch (e) {
          output += 'APT: Errore durante l\'aggiornamento: $e\n';
        }
      }

      // DNF (Fedora/RHEL/CentOS)
      if (systemInfo.hasDnf) {
        try {
          final result = await _runSudoCommand('dnf update -y');
          output += 'DNF: ${result.stdout}\n';
          if (result.exitCode == 0) {
            updated.add('DNF');
          } else {
            output += 'DNF: ${result.stderr}\n';
          }
        } catch (e) {
          output += 'DNF: Errore durante l\'aggiornamento: $e\n';
        }
      }

      // Pacman (Arch/Manjaro)
      if (systemInfo.hasPacman) {
        try {
          final result = await _runSudoCommand('pacman -Syu --noconfirm');
          output += 'Pacman: ${result.stdout}\n';
          if (result.exitCode == 0) {
            updated.add('Pacman');
          } else {
            output += 'Pacman: ${result.stderr}\n';
          }
        } catch (e) {
          output += 'Pacman: Errore durante l\'aggiornamento: $e\n';
        }
      }

      // Snap
      if (systemInfo.hasSnap) {
        try {
          final result = await _runSudoCommand('snap refresh 2>&1');
          output += 'Snap: ${result.stdout}\n';
          if (result.exitCode == 0) {
            updated.add('Snap');
          } else {
            output += 'Snap: ${result.stderr}\n';
          }
        } catch (e) {
          output += 'Snap: Errore durante l\'aggiornamento: $e\n';
        }
      }

      // Flatpak
      if (systemInfo.hasFlatpak) {
        try {
          final result = await _runSudoCommand('flatpak update -y 2>&1');
          output += 'Flatpak: ${result.stdout}\n';
          if (result.exitCode == 0) {
            updated.add('Flatpak');
          } else {
            output += 'Flatpak: ${result.stderr}\n';
          }
        } catch (e) {
          output += 'Flatpak: Errore durante l\'aggiornamento: $e\n';
        }
      }

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
}

