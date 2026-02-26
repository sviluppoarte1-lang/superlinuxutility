import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:path/path.dart' as path;
import 'password_storage.dart';

/// Servizio per gestire PLing-store e l'installazione di temi/icone da Pling.com/OpenDesktop.org
/// PLing-store è un'applicazione desktop dedicata per installare temi e icone
class PlingStoreService {
  /// Verifica se PLing-store è installato sul sistema
  static Future<bool> isPlingStoreInstalled() async {
    try {
      var shell = Shell();
      final results = await shell.run('which pling-store');
      final result = results.first;
      return result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Installa PLing-store (richiede sudo)
  static Future<bool> installPlingStore() async {
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
      
      var shell = Shell();
      
      // Prova prima con apt (Debian/Ubuntu)
      final aptCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S apt-get install -y pling-store';
      var results = await shell.run(aptCommand);
      var result = results.first;
      if (result.exitCode == 0) {
        return true;
      }
      
      // Prova con dnf (Fedora/RHEL)
      final dnfCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S dnf install -y pling-store';
      results = await shell.run(dnfCommand);
      result = results.first;
      if (result.exitCode == 0) {
        return true;
      }
      
      // Prova con pacman (Arch)
      final pacmanCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S pacman -S --noconfirm pling-store';
      results = await shell.run(pacmanCommand);
      result = results.first;
      if (result.exitCode == 0) {
        return true;
      }
      
      // Se nessun package manager ha funzionato, verifica se PLing-store è già installato
      if (await isPlingStoreInstalled()) {
        return true;
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica se un tema è stato installato tramite PLing-store
  /// Controlla se il tema ha metadati PLing o se è in una directory gestita da PLing-store
  static Future<bool> isThemeInstalledViaPlingStore(String themeName) async {
    try {
      final themePaths = [
        '/usr/share/themes/$themeName',
        '${Platform.environment['HOME']}/.themes/$themeName',
        '${Platform.environment['HOME']}/.local/share/themes/$themeName',
      ];
      
      for (final themePath in themePaths) {
        final dir = Directory(themePath);
        if (await dir.exists()) {
          // Controlla se ha un file .pling o metadati PLing
          final plingFile = File(path.join(themePath, '.pling'));
          final plingMetaFile = File(path.join(themePath, '.pling-meta'));
          final indexFile = File(path.join(themePath, 'index.theme'));
          
          if (await plingFile.exists() || await plingMetaFile.exists()) {
            return true;
          }
          
          // Controlla se index.theme contiene riferimenti a PLing
          if (await indexFile.exists()) {
            final content = await indexFile.readAsString();
            if (content.toLowerCase().contains('pling') || 
                content.toLowerCase().contains('opendesktop') ||
                content.toLowerCase().contains('plasma')) {
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Installa un tema tramite PLing-store usando l'URL o l'ID del tema
  static Future<bool> installThemeViaPlingStore(String themeUrlOrId) async {
    try {
      if (!await isPlingStoreInstalled()) {
        throw Exception('PLing-store non è installato');
      }
      
      var shell = Shell();
      
      // Prova ad aprire PLing-store con l'URL/ID del tema
      // PLing-store può essere aperto con un URL o ID come argomento
      var results = await shell.run('pling-store "$themeUrlOrId"');
      var result = results.first;
      
      // Se fallisce, prova con xdg-open
      if (result.exitCode != 0) {
        results = await shell.run('xdg-open "$themeUrlOrId"');
        result = results.first;
      }
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene informazioni su PLing-store (versione, stato)
  static Future<Map<String, String>> getPlingStoreInfo() async {
    final info = <String, String>{
      'installed': 'false',
      'version': 'unknown',
    };
    
    try {
      final installed = await isPlingStoreInstalled();
      info['installed'] = installed.toString();
      
      if (installed) {
        // Prova a ottenere la versione
        try {
          var shell = Shell();
          final results = await shell.run('pling-store --version');
          final result = results.first;
          if (result.exitCode == 0) {
            info['version'] = (result.stdout as String).trim();
          }
        } catch (e) {
          // Versione non disponibile
        }
      }
    } catch (e) {
      // Ignora errori
    }
    
    return info;
  }
}

