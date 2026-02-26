import 'dart:io';
import 'package:process_run/shell.dart';
import 'package:path/path.dart' as path;
import 'password_storage.dart';

/// Servizio per gestire ocs-url e l'installazione di temi/icone da OpenDesktop.org
/// ocs-url è un'applicazione che gestisce l'installazione di temi e icone tramite URL ocs://
class OcsUrlService {
  /// Verifica se ocs-url è installato sul sistema
  static Future<bool> isOcsUrlInstalled() async {
    try {
      var shell = Shell();
      final results = await shell.run('which ocs-url');
      final result = results.first;
      return result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se ocs-url è configurato come handler per il protocollo ocs://
  static Future<bool> isOcsUrlHandlerConfigured() async {
    try {
      var shell = Shell();
      final results = await shell.run('xdg-mime query default x-scheme-handler/ocs');
      final result = results.first;
      if (result.exitCode == 0) {
        final handler = (result.stdout as String).trim();
        return handler.isNotEmpty && handler.toLowerCase().contains('ocs');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Installa ocs-url (richiede sudo)
  static Future<bool> installOcsUrl() async {
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
      final aptCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S apt-get install -y ocs-url';
      var results = await shell.run(aptCommand);
      var result = results.first;
      if (result.exitCode == 0) {
        // Configura anche l'handler dopo l'installazione
        await configureOcsUrlHandler();
        return true;
      }
      
      // Prova con dnf (Fedora/RHEL)
      final dnfCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S dnf install -y ocs-url';
      results = await shell.run(dnfCommand);
      result = results.first;
      if (result.exitCode == 0) {
        await configureOcsUrlHandler();
        return true;
      }
      
      // Prova con pacman (Arch)
      final pacmanCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S pacman -S --noconfirm ocs-url';
      results = await shell.run(pacmanCommand);
      result = results.first;
      if (result.exitCode == 0) {
        await configureOcsUrlHandler();
        return true;
      }
      
      // Se nessun package manager ha funzionato, verifica se ocs-url è già installato
      if (await isOcsUrlInstalled()) {
        await configureOcsUrlHandler();
        return true;
      }
      
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Configura ocs-url come handler per il protocollo ocs://
  static Future<bool> configureOcsUrlHandler() async {
    try {
      var shell = Shell();
      
      // Trova il file desktop di ocs-url
      final desktopFiles = [
        '/usr/share/applications/ocs-url.desktop',
        '/usr/local/share/applications/ocs-url.desktop',
        '${Platform.environment['HOME']}/.local/share/applications/ocs-url.desktop',
      ];
      
      String? desktopFile;
      for (final file in desktopFiles) {
        final f = File(file);
        if (await f.exists()) {
          desktopFile = file;
          break;
        }
      }
      
      if (desktopFile == null) {
        return false;
      }
      
      // Configura il handler
      final results = await shell.run('xdg-mime default ocs-url.desktop x-scheme-handler/ocs');
      final result = results.first;
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se un tema richiede ocs-url per essere installato correttamente
  /// Controlla se il tema ha file di configurazione ocs o se mancano dipendenze
  static Future<bool> themeRequiresOcsUrl(String themeName) async {
    try {
      final themePaths = [
        '/usr/share/themes/$themeName',
        '${Platform.environment['HOME']}/.themes/$themeName',
      ];
      
      for (final themePath in themePaths) {
        final dir = Directory(themePath);
        if (await dir.exists()) {
          // Controlla se ha un file .ocs o riferimenti a ocs
          final ocsFile = File(path.join(themePath, '.ocs'));
          final indexFile = File(path.join(themePath, 'index.theme'));
          
          if (await ocsFile.exists()) {
            return true;
          }
          
          // Controlla se index.theme contiene riferimenti a ocs
          if (await indexFile.exists()) {
            final content = await indexFile.readAsString();
            if (content.toLowerCase().contains('ocs') || 
                content.toLowerCase().contains('opendesktop')) {
              return true;
            }
          }
          
          // Controlla se mancano file essenziali (potrebbe richiedere installazione via ocs)
          final gtk3Dir = Directory(path.join(themePath, 'gtk-3.0'));
          final gtk4Dir = Directory(path.join(themePath, 'gtk-4.0'));
          final shellDir = Directory(path.join(themePath, 'gnome-shell'));
          
          // Se il tema esiste ma non ha nessuna struttura GTK, potrebbe richiedere ocs
          if (!await gtk3Dir.exists() && 
              !await gtk4Dir.exists() && 
              !await shellDir.exists() && 
              await indexFile.exists()) {
            // Leggi index.theme per vedere se ha riferimenti a download o installazione
            final content = await indexFile.readAsString();
            if (content.toLowerCase().contains('download') || 
                content.toLowerCase().contains('install')) {
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

  /// Installa un tema tramite ocs-url usando l'URL ocs://
  static Future<bool> installThemeViaOcsUrl(String ocsUrl) async {
    try {
      if (!await isOcsUrlInstalled()) {
        throw Exception('ocs-url non è installato');
      }
      
      // Assicurati che ocs-url sia configurato come handler
      if (!await isOcsUrlHandlerConfigured()) {
        await configureOcsUrlHandler();
      }
      
      // Apri l'URL ocs:// usando xdg-open o direttamente ocs-url
      var shell = Shell();
      
      // Prova prima con xdg-open
      var results = await shell.run('xdg-open "$ocsUrl"');
      var result = results.first;
      if (result.exitCode == 0) {
        return true;
      }
      
      // Prova direttamente con ocs-url
      results = await shell.run('ocs-url "$ocsUrl"');
      result = results.first;
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Verifica se un tema è installato correttamente
  /// Controlla se tutti i file necessari sono presenti
  static Future<bool> isThemeInstalledCorrectly(String themeName) async {
    try {
      final themePaths = [
        '/usr/share/themes/$themeName',
        '${Platform.environment['HOME']}/.themes/$themeName',
      ];
      
      for (final themePath in themePaths) {
        final dir = Directory(themePath);
        if (await dir.exists()) {
          // Verifica che abbia almeno una struttura GTK valida
          final gtk3Dir = Directory(path.join(themePath, 'gtk-3.0'));
          final gtk4Dir = Directory(path.join(themePath, 'gtk-4.0'));
          final shellDir = Directory(path.join(themePath, 'gnome-shell'));
          final indexFile = File(path.join(themePath, 'index.theme'));
          
          // Deve avere almeno index.theme e una struttura GTK
          if (await indexFile.exists() && 
              (await gtk3Dir.exists() || 
               await gtk4Dir.exists() || 
               await shellDir.exists())) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene informazioni su ocs-url (versione, stato)
  static Future<Map<String, String>> getOcsUrlInfo() async {
    final info = <String, String>{
      'installed': 'false',
      'handler_configured': 'false',
      'version': 'unknown',
    };
    
    try {
      final installed = await isOcsUrlInstalled();
      info['installed'] = installed.toString();
      
      if (installed) {
        final handlerConfigured = await isOcsUrlHandlerConfigured();
        info['handler_configured'] = handlerConfigured.toString();
        
        // Prova a ottenere la versione
        try {
          var shell = Shell();
          final results = await shell.run('ocs-url --version');
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

