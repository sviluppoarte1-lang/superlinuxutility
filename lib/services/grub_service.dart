import 'dart:io';
import 'dart:convert';
import 'password_storage.dart';
import 'system_detector.dart';

class GrubService {
  static const String grubConfigPath = '/etc/default/grub';
  static const String grubBackupPath = '/etc/default/grub.backup';

  /// Esegue un comando con sudo usando la password salvata
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
        .replaceAll("'", "'\"'\"'");
    
    final fullCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S $command 2>&1';
    
    final result = await Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
    
    if (result.exitCode != 0) {
      final errorOutput = result.stderr.toString();
      if (errorOutput.contains('sudo:') && errorOutput.contains('password')) {
        throw Exception('Password errata o permessi insufficienti');
      }
    }
    
    return result;
  }

  /// Legge il contenuto del file GRUB
  static Future<String> readGrubConfig() async {
    try {
      // Prova prima senza sudo
      final file = File(grubConfigPath);
      if (await file.exists()) {
        try {
          return await file.readAsString();
        } catch (e) {
          // Se fallisce per permessi, usa sudo
          final result = await _runSudoCommand('cat $grubConfigPath');
          if (result.exitCode == 0) {
            return result.stdout.toString();
          }
          throw Exception('Impossibile leggere il file GRUB: ${result.stderr}');
        }
      } else {
        throw Exception('File GRUB non trovato: $grubConfigPath');
      }
    } catch (e) {
      throw Exception('Errore durante la lettura del file GRUB: $e');
    }
  }

  /// Crea un backup del file GRUB
  static Future<bool> createBackup() async {
    try {
      final result = await _runSudoCommand(
        'cp $grubConfigPath $grubBackupPath',
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Ripristina il backup del file GRUB
  static Future<bool> restoreBackup() async {
    try {
      final backupFile = File(grubBackupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup non trovato');
      }

      final result = await _runSudoCommand(
        'cp $grubBackupPath $grubConfigPath',
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se esiste un backup
  static Future<bool> hasBackup() async {
    final backupFile = File(grubBackupPath);
    return await backupFile.exists();
  }

  /// Salva il contenuto modificato nel file GRUB
  static Future<bool> saveGrubConfig(String content) async {
    try {
      await createBackup();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('/tmp/grub_config_$timestamp');
      await tempFile.writeAsString(content);

      var tempPath = tempFile.path.replaceAll("'", "'\"'\"'");
      var result = await _runSudoCommand(
        "cp '$tempPath' '$grubConfigPath' && chmod 644 '$grubConfigPath'",
      );

      if (result.exitCode != 0) {
        final tempPathEscaped = tempFile.path.replaceAll("'", "'\"'\"'");
        result = await _runSudoCommand(
          "cat '$tempPathEscaped' > '$grubConfigPath' && chmod 644 '$grubConfigPath'",
        );
      }
      
      if (result.exitCode != 0) {
        final contentBytes = await tempFile.readAsBytes();
        final contentBase64 = base64Encode(contentBytes);
        result = await _runSudoCommand(
          "echo '$contentBase64' | base64 -d | tee '$grubConfigPath' > /dev/null && chmod 644 '$grubConfigPath'",
        );
      }

      try {
        await tempFile.delete();
      } catch (e) {
        // Ignora errori nella rimozione del file temporaneo
      }

      if (result.exitCode != 0) {
        final errorOutput = result.stderr.toString().trim();
        final stdoutOutput = result.stdout.toString().trim();
        final combinedError = errorOutput.isNotEmpty ? errorOutput : stdoutOutput;
        
        try {
          final savedFile = File(grubConfigPath);
          if (await savedFile.exists()) {
            final savedContent = await savedFile.readAsString();
            if (savedContent == content) {
              return true;
            }
          }
        } catch (e) {
          // Ignora errori di verifica
        }
        
        throw Exception('Impossibile salvare il file GRUB. ${combinedError.isNotEmpty ? combinedError : "Errore sconosciuto (exit code: ${result.exitCode})"}');
      }
      
      try {
        final savedFile = File(grubConfigPath);
        if (await savedFile.exists()) {
          final savedContent = await savedFile.readAsString();
          if (savedContent != content) {
            throw Exception('Il file è stato scritto ma il contenuto non corrisponde. Potrebbe essere un problema di permessi.');
          }
        } else {
          throw Exception('Il file non è stato creato. Verifica i permessi.');
        }
      } catch (e) {
        if (e.toString().contains('Impossibile')) {
          rethrow;
        }
        throw Exception('Errore durante la verifica del file salvato: $e');
      }

      return true;
    } catch (e) {
      throw Exception('Errore durante il salvataggio: $e');
    }
  }

  /// Aggiorna GRUB dopo le modifiche (esegue sudo update-grub su Ubuntu/Debian)
  static Future<bool> updateGrub() async {
    try {
      final systemInfo = await SystemDetector.detectSystem();
      final distLower = systemInfo.distribution.toLowerCase();
      final command = systemInfo.grubUpdateCommand;

      ProcessResult result = await _runSudoCommand('$command 2>&1');

      if (result.exitCode != 0 && (distLower.contains('ubuntu') || distLower.contains('debian') || distLower.contains('mint'))) {
        result = await _runSudoCommand('update-grub 2>&1');
      }
      
      if (result.exitCode != 0) {
        // Prova grub-mkconfig (Arch/Manjaro)
        result = await _runSudoCommand(
          'grub-mkconfig -o /boot/grub/grub.cfg 2>&1',
        );
      }
      
      if (result.exitCode != 0) {
        // Prova grub2-mkconfig (Fedora/RHEL)
        result = await _runSudoCommand(
          'grub2-mkconfig -o /boot/grub2/grub.cfg 2>&1',
        );
      }
      
      if (result.exitCode != 0) {
        // Prova percorso EFI Fedora
        result = await _runSudoCommand(
          'grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg 2>&1',
        );
      }

      return result.exitCode == 0;
    } catch (e) {
      print('Errore nell\'aggiornamento GRUB: $e');
      return false;
    }
  }

  /// Salva e aggiorna GRUB in un'unica operazione
  static Future<bool> saveAndUpdateGrub(String content) async {
    try {
      final saved = await saveGrubConfig(content);
      if (!saved) {
        throw Exception('Impossibile salvare il file GRUB');
      }

      final updated = await updateGrub();
      if (!updated) {
        throw Exception('Impossibile aggiornare GRUB. Il file è stato salvato ma GRUB non è stato aggiornato.');
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Valida il contenuto del file GRUB
  static bool validateGrubConfig(String content) {
    // Verifica che il contenuto non sia vuoto
    if (content.trim().isEmpty) {
      return false;
    }

    // Verifica che contenga almeno una variabile GRUB (es. GRUB_DEFAULT, GRUB_TIMEOUT, ecc.)
    // I file GRUB contengono normalmente variabili che iniziano con GRUB_
    if (!content.contains(RegExp(r'GRUB_\w+'))) {
      // Se non contiene variabili GRUB, potrebbe essere un file vuoto o corrotto
      // Ma permettiamo comunque il salvataggio se non è completamente vuoto
      if (content.trim().isEmpty) {
        return false;
      }
    }

    // Non bloccare caratteri normali del file GRUB come $, `, ecc.
    // Questi sono validi in un file GRUB (es. GRUB_DISTRIBUTOR=`lsb_release -i -s`)
    // Rimuoviamo la validazione troppo restrittiva che bloccava caratteri legittimi
    
    return true;
  }
}

