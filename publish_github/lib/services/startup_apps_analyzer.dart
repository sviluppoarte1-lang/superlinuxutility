import 'dart:io';
import '../models/startup_app.dart';
import 'protected_apps.dart';
import 'system_monitor.dart';

class StartupAppsAnalyzer {
  /// Analizza le applicazioni all'avvio
  static Future<List<StartupApp>> analyzeStartupApps() async {
    try {
      final apps = <StartupApp>[];
      final userAppNames = <String>{}; // Traccia le app utente per evitare duplicati

      // PRIMA cerca in ~/.config/autostart (override utente)
      final autostartDir = Directory('${Platform.environment['HOME']}/.config/autostart');
      if (await autostartDir.exists()) {
        await for (final entity in autostartDir.list()) {
          if (entity is File && entity.path.endsWith('.desktop')) {
            final app = await _parseDesktopFile(entity);
            if (app != null) {
              apps.add(app);
              // Traccia il nome del file per evitare duplicati da /etc/xdg/autostart
              final fileName = entity.path.split('/').last;
              userAppNames.add(fileName);
            }
          }
        }
      }

      // POI cerca in /etc/xdg/autostart (solo se non c'è già un override utente)
      try {
        final result = await Process.run(
          'bash',
          ['-c', 'ls /etc/xdg/autostart/*.desktop 2>/dev/null || true'],
        );
        
        if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
          final lines = (result.stdout as String).split('\n');
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            final file = File(line.trim());
            if (await file.exists()) {
              final fileName = file.path.split('/').last;
              // Aggiungi solo se non c'è già un override utente
              if (!userAppNames.contains(fileName)) {
                final app = await _parseDesktopFile(file);
                if (app != null) {
                  apps.add(app);
                }
              }
            }
          }
        }
      } catch (e) {
        // Ignora errori per /etc/xdg/autostart
      }

      return apps;
    } catch (e) {
      throw Exception('Errore durante l\'analisi delle app all\'avvio: $e');
    }
  }

  /// Analizza un file .desktop
  static Future<StartupApp?> _parseDesktopFile(File file) async {
    try {
      final content = await file.readAsString();
      String? name;
      String? command;
      String? comment;
      bool hidden = false;
      bool xgnomeEnabled = true;

      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('Name=')) {
          name = trimmed.substring(5).trim();
        } else if (trimmed.startsWith('Exec=')) {
          command = trimmed.substring(5).trim();
        } else if (trimmed.startsWith('Comment=')) {
          comment = trimmed.substring(8).trim();
        } else if (trimmed.startsWith('Hidden=')) {
          hidden = trimmed.substring(7).trim().toLowerCase() == 'true';
        } else if (trimmed.startsWith('X-GNOME-Autostart-enabled=')) {
          xgnomeEnabled = trimmed.substring(28).trim().toLowerCase() == 'true';
        }
      }

      // Se manca name o command, non è un file valido
      if (name == null || command == null) {
        return null;
      }

      // L'app è abilitata se NON è hidden E (X-GNOME-Autostart-enabled è true o non presente)
      // Se Hidden=true, l'app è disabilitata indipendentemente da X-GNOME-Autostart-enabled
      final isEnabled = !hidden && xgnomeEnabled;

      // Verifica se l'app è protetta
      final isProtected = ProtectedApps.isProtected(
        name: name,
        command: command,
        desktopFile: file.path,
      );

      return StartupApp(
        name: name,
        command: command,
        comment: comment,
        isEnabled: isEnabled,
        desktopFile: file.path,
        isProtected: isProtected,
      );
    } catch (e) {
      // Ignora file non validi
    }
    return null;
  }

  /// Disabilita un'applicazione all'avvio
  static Future<bool> disableStartupApp(String desktopFilePath, {String? appName, String? command}) async {
    try {
      final file = File(desktopFilePath);
      if (!await file.exists()) {
        throw Exception('File non trovato: $desktopFilePath');
      }

      // Verifica se l'app è protetta
      if (appName != null && command != null) {
        if (ProtectedApps.isProtected(
          name: appName,
          command: command,
          desktopFile: desktopFilePath,
        )) {
          throw Exception('APP_PROTECTED');
        }
      }

      // Leggi il contenuto
      var content = await file.readAsString();
      
      // Aggiungi o modifica Hidden=true
      if (content.contains('Hidden=')) {
        content = content.replaceAll(
          RegExp(r'Hidden=.*'),
          'Hidden=true',
        );
      } else {
        // Aggiungi Hidden=true nella sezione [Desktop Entry]
        if (content.contains('[Desktop Entry]')) {
          content = content.replaceFirst(
            '[Desktop Entry]',
            '[Desktop Entry]\nHidden=true',
          );
        }
      }

      // Se è in /etc/xdg/autostart, crea un override in ~/.config/autostart
      if (desktopFilePath.startsWith('/etc/xdg/autostart')) {
        final fileName = file.path.split('/').last;
        final userAutostart = File(
          '${Platform.environment['HOME']}/.config/autostart/$fileName',
        );
        
        // Crea la directory se non esiste
        await userAutostart.parent.create(recursive: true);
        
        // Leggi il file originale per copiare tutto il contenuto
        final originalContent = await file.readAsString();
        var newContent = originalContent;
        
        // Aggiungi o modifica Hidden=true
        if (newContent.contains('Hidden=')) {
          newContent = newContent.replaceAll(
            RegExp(r'Hidden=.*'),
            'Hidden=true',
          );
        } else {
          // Aggiungi Hidden=true nella sezione [Desktop Entry]
          if (newContent.contains('[Desktop Entry]')) {
            newContent = newContent.replaceFirst(
              '[Desktop Entry]',
              '[Desktop Entry]\nHidden=true',
            );
          }
        }
        
        // Rimuovi anche X-GNOME-Autostart-enabled se presente (per coerenza)
        if (newContent.contains('X-GNOME-Autostart-enabled=')) {
          newContent = newContent.replaceAll(
            RegExp(r'X-GNOME-Autostart-enabled=.*\n?'),
            '',
          );
        }
        
        // Scrivi il file override
        await userAutostart.writeAsString(newContent);
        return true;
      } else {
        // Modifica direttamente il file utente
        await file.writeAsString(content);
        return true;
      }
    } catch (e) {
      throw Exception('Errore durante la disabilitazione dell\'app: $e');
    }
  }

  /// Abilita un'applicazione all'avvio
  static Future<bool> enableStartupApp(String desktopFilePath) async {
    try {
      final file = File(desktopFilePath);
      
      // Se è in /etc/xdg/autostart, rimuovi l'override utente se esiste
      if (desktopFilePath.startsWith('/etc/xdg/autostart')) {
        final fileName = file.path.split('/').last;
        final userAutostart = File(
          '${Platform.environment['HOME']}/.config/autostart/$fileName',
        );
        
        // Se esiste un override utente, rimuovilo per riabilitare l'app di sistema
        if (await userAutostart.exists()) {
          await userAutostart.delete();
        }
        return true;
      } else {
        // Modifica direttamente il file utente
        if (!await file.exists()) {
          throw Exception('File non trovato: $desktopFilePath');
        }

        var content = await file.readAsString();
        
        // Rimuovi Hidden=true o imposta Hidden=false
        if (content.contains('Hidden=')) {
          content = content.replaceAll(
            RegExp(r'Hidden=.*'),
            'Hidden=false',
          );
        } else {
          // Se non c'è Hidden, aggiungilo come false
          if (content.contains('[Desktop Entry]')) {
            content = content.replaceFirst(
              '[Desktop Entry]',
              '[Desktop Entry]\nHidden=false',
            );
          }
        }

        await file.writeAsString(content);
        return true;
      }
    } catch (e) {
      throw Exception('Errore durante l\'abilitazione dell\'app: $e');
    }
  }

  /// Trova i processi in esecuzione per un'app basandosi sul comando
  static Future<List<int>> findRunningProcesses(String command) async {
    try {
      // Estrai il nome base del comando (prima parte prima di spazi o parametri)
      String baseCommand = command.split(' ')[0].split('/').last;
      
      // Rimuovi eventuali estensioni
      if (baseCommand.contains('.')) {
        baseCommand = baseCommand.split('.')[0];
      }
      
      // Ottieni tutti i processi
      final processes = await SystemMonitor.getProcesses();
      
      // Filtra i processi che corrispondono al comando
      final matchingPids = <int>[];
      for (final process in processes) {
        // Controlla se il comando o il nome del processo corrisponde
        final commandLower = process.command?.toLowerCase() ?? '';
        final nameLower = process.name.toLowerCase();
        final baseCommandLower = baseCommand.toLowerCase();
        
        if (commandLower.contains(baseCommandLower) ||
            nameLower.contains(baseCommandLower)) {
          matchingPids.add(process.pid);
        }
      }
      
      return matchingPids;
    } catch (e) {
      return [];
    }
  }

  /// Termina tutti i processi di un'app
  static Future<bool> killAppProcesses(String command, {bool force = false}) async {
    try {
      final pids = await findRunningProcesses(command);
      if (pids.isEmpty) {
        return false; // Nessun processo trovato
      }
      
      bool allKilled = true;
      for (final pid in pids) {
        final success = await SystemMonitor.killProcess(pid, force: force);
        if (!success) {
          allKilled = false;
        }
      }
      
      return allKilled;
    } catch (e) {
      return false;
    }
  }

  /// Elimina un'applicazione all'avvio
  static Future<bool> removeStartupApp(String desktopFilePath) async {
    try {
      final file = File(desktopFilePath);
      
      // Se è in /etc/xdg/autostart, crea un override in ~/.config/autostart
      if (desktopFilePath.startsWith('/etc/xdg/autostart')) {
        final fileName = file.path.split('/').last;
        final userAutostart = File(
          '${Platform.environment['HOME']}/.config/autostart/$fileName',
        );
        
        await userAutostart.parent.create(recursive: true);
        
        // Crea un file con Hidden=true
        final content = await file.readAsString();
        var modifiedContent = content;
        if (modifiedContent.contains('Hidden=')) {
          modifiedContent = modifiedContent.replaceAll(
            RegExp(r'Hidden=.*'),
            'Hidden=true',
          );
        } else {
          if (modifiedContent.contains('[Desktop Entry]')) {
            modifiedContent = modifiedContent.replaceFirst(
              '[Desktop Entry]',
              '[Desktop Entry]\nHidden=true',
            );
          }
        }
        
        await userAutostart.writeAsString(modifiedContent);
        return true;
      } else {
        // Elimina direttamente
        await file.delete();
        return true;
      }
    } catch (e) {
      throw Exception('Errore durante la rimozione dell\'app: $e');
    }
  }
}


