import 'dart:io';
import 'package:path/path.dart' as path;
import 'ocs_url_service.dart';
import 'pling_store_service.dart';
import 'ocs_theme_installer.dart';

/// Servizio per gestire le impostazioni di aspetto del sistema Linux
/// Utilizza gsettings per modificare font, temi, sfondo e comportamento finestre
class AppearanceService {
  /// Esegue un comando gsettings con timeout per evitare blocchi
  static Future<ProcessResult> _runGsettings(String schema, String key, String value) async {
    try {
      // Verifica D-Bus prima di procedere (su Zorin OS 18 può essere lento)
      final dbusAvailable = await _isDbusAvailable();
      if (!dbusAvailable) {
        throw Exception('D-Bus non disponibile');
      }

      // Usa Process.run invece di Shell per evitare blocchi su Ubuntu 24/Zorin OS 18
      final result = await Process.run(
        'gsettings',
        ['set', schema, key, value],
        runInShell: false,
      ).timeout(
        const Duration(seconds: 2), // Ridotto a 2 secondi
        onTimeout: () {
          print('Timeout gsettings set $schema $key');
          return ProcessResult(1, -1, '', 'Timeout');
        },
      );
      
      // Verifica errori
      if (result.exitCode != 0) {
        throw Exception('gsettings failed: ${result.stderr}');
      }
      
      return result;
    } catch (e) {
      print('Errore in _runGsettings: $e');
      rethrow;
    }
  }

  /// Verifica se D-Bus è disponibile (per evitare blocchi su Zorin OS 18)
  static Future<bool> _isDbusAvailable() async {
    try {
      final result = await Process.run(
        'dbus-send',
        ['--print-reply', '--dest=org.freedesktop.DBus', '/org/freedesktop/DBus', 'org.freedesktop.DBus.GetId'],
        runInShell: false,
      ).timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Legge un valore da gsettings con timeout per evitare blocchi
  static Future<String> _getGsettings(String schema, String key) async {
    try {
      // Verifica D-Bus prima di procedere (su Zorin OS 18 può essere lento)
      final dbusAvailable = await _isDbusAvailable();
      if (!dbusAvailable) {
        print('D-Bus non disponibile, ritorno valore vuoto');
        return '';
      }

      // Usa Process.run invece di Shell per evitare blocchi su Ubuntu 24/Zorin OS 18
      final result = await Process.run(
        'gsettings',
        ['get', schema, key],
        runInShell: false,
      ).timeout(
        const Duration(seconds: 2), // Ridotto a 2 secondi
        onTimeout: () {
          print('Timeout gsettings get $schema $key');
          return ProcessResult(1, -1, '', 'Timeout');
        },
      );
      
      if (result.exitCode == 0) {
        var value = (result.stdout as String).trim();
        // Rimuove le virgolette singole all'inizio e alla fine
        if (value.startsWith("'") && value.endsWith("'")) {
          value = value.substring(1, value.length - 1);
        }
        return value;
      }
      return '';
    } catch (e) {
      print('Errore in _getGsettings: $e');
      return '';
    }
  }

  static List<String>? _cachedFonts;
  static DateTime? _fontsCacheTime;
  
  /// Ottiene la lista dei font disponibili (con cache)
  static Future<List<String>> getAvailableFonts() async {
    try {
      // Usa cache se disponibile e non troppo vecchia (30 minuti per performance)
      if (_cachedFonts != null && _fontsCacheTime != null) {
        final cacheAge = DateTime.now().difference(_fontsCacheTime!);
        if (cacheAge.inMinutes < 30) {
          return _cachedFonts!;
        }
      }
      
      // Usa Process.run invece di Shell per avere più controllo
      final result = await Process.run(
        'fc-list',
        [':', 'family'],
        runInShell: false,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          print('Timeout nel comando fc-list');
          return ProcessResult(1, -1, '', 'Timeout');
        },
      );
      
      if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
        final fonts = (result.stdout as String)
            .split('\n')
            .map((f) => f.trim())
            .where((f) => f.isNotEmpty)
            .toSet()
            .toList();
        fonts.sort();
        
        // Aggiorna cache solo se abbiamo ottenuto risultati validi
        if (fonts.isNotEmpty) {
        _cachedFonts = fonts;
        _fontsCacheTime = DateTime.now();
        return fonts;
        }
      }
    } catch (e) {
      print('Errore nel recupero font: $e');
      // Ignora errori e ritorna cache o default
    }
    return _cachedFonts ?? ['Ubuntu', 'Ubuntu Sans', 'Sans', 'Serif', 'Monospace'];
  }

  // ========== FONT PREFERENCES ==========

  /// Estrae il nome del font da una stringa che può contenere anche la dimensione
  /// Esempio: "DejaVu Sans Ultra-Light 10" -> "DejaVu Sans Ultra-Light"
  static String _extractFontName(String fontString) {
    if (fontString.isEmpty) return '';
    // Rimuove l'ultimo numero (dimensione) se presente
    final parts = fontString.trim().split(' ');
    if (parts.length > 1) {
      final lastPart = parts.last;
      // Se l'ultima parte è un numero, rimuovila
      if (RegExp(r'^\d+$').hasMatch(lastPart)) {
        return parts.sublist(0, parts.length - 1).join(' ');
      }
    }
    return fontString;
  }

  /// Estrae la dimensione del font da una stringa
  /// Esempio: "DejaVu Sans Ultra-Light 10" -> 10.0
  static double _extractFontSize(String fontString) {
    if (fontString.isEmpty) return 10.0;
    final parts = fontString.trim().split(' ');
    if (parts.length > 1) {
      final lastPart = parts.last;
      if (RegExp(r'^\d+$').hasMatch(lastPart)) {
        return double.tryParse(lastPart) ?? 10.0;
      }
    }
    return 10.0;
  }

  /// Ottiene la dimensione del font dell'interfaccia
  static Future<double> getInterfaceFontSize() async {
    final fullFont = await _getGsettings('org.gnome.desktop.interface', 'font-name');
    return _extractFontSize(fullFont);
  }

  /// Ottiene la dimensione del font del documento
  static Future<double> getDocumentFontSize() async {
    final fullFont = await _getGsettings('org.gnome.desktop.interface', 'document-font-name');
    return _extractFontSize(fullFont);
  }

  /// Ottiene la dimensione del font a spaziatura fissa
  static Future<double> getMonospaceFontSize() async {
    final fullFont = await _getGsettings('org.gnome.desktop.interface', 'monospace-font-name');
    return _extractFontSize(fullFont);
  }

  /// Ottiene il font dell'interfaccia (solo nome, senza dimensione)
  static Future<String> getInterfaceFont() async {
    final fullFont = await _getGsettings('org.gnome.desktop.interface', 'font-name');
    return _extractFontName(fullFont);
  }

  /// Imposta il font dell'interfaccia
  static Future<bool> setInterfaceFont(String fontName, {double? fontSize}) async {
    try {
      String fontToSet;
      if (fontSize != null) {
        fontToSet = '$fontName ${fontSize.toInt()}';
      } else if (!RegExp(r'\s\d+$').hasMatch(fontName)) {
        final currentFull = await _getGsettings('org.gnome.desktop.interface', 'font-name');
        if (currentFull.isNotEmpty) {
          final parts = currentFull.split(' ');
          if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
            fontToSet = '$fontName ${parts.last}';
          } else {
            fontToSet = '$fontName 10';
          }
        } else {
          fontToSet = '$fontName 10';
        }
      } else {
        fontToSet = fontName;
      }
      await _runGsettings('org.gnome.desktop.interface', 'font-name', fontToSet);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il font del documento (solo nome, senza dimensione)
  static Future<String> getDocumentFont() async {
    final fullFont = await _getGsettings('org.gnome.desktop.interface', 'document-font-name');
    return _extractFontName(fullFont);
  }

  /// Imposta il font del documento
  static Future<bool> setDocumentFont(String fontName, {double? fontSize}) async {
    try {
      String fontToSet;
      if (fontSize != null) {
        fontToSet = '$fontName ${fontSize.toInt()}';
      } else if (!RegExp(r'\s\d+$').hasMatch(fontName)) {
        final currentFull = await _getGsettings('org.gnome.desktop.interface', 'document-font-name');
        if (currentFull.isNotEmpty) {
          final parts = currentFull.split(' ');
          if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
            fontToSet = '$fontName ${parts.last}';
          } else {
            fontToSet = '$fontName 10';
          }
        } else {
          fontToSet = '$fontName 10';
        }
      } else {
        fontToSet = fontName;
      }
      await _runGsettings('org.gnome.desktop.interface', 'document-font-name', fontToSet);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il font a spaziatura fissa (solo nome, senza dimensione)
  static Future<String> getMonospaceFont() async {
    final fullFont = await _getGsettings('org.gnome.desktop.interface', 'monospace-font-name');
    return _extractFontName(fullFont);
  }

  /// Verifica se un font è monospace
  static Future<bool> _isMonospaceFont(String fontName) async {
    try {
      final result = await Process.run(
        'bash',
        ['-c', 'fc-list :spacing=mono family | grep -i "^$fontName" || fc-list :spacing=mono family | grep -i "$fontName"'],
        runInShell: false,
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
      );
      return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Imposta il font a spaziatura fissa
  /// Verifica che il font sia effettivamente monospace per evitare problemi nel terminale
  static Future<bool> setMonospaceFont(String fontName, {double? fontSize}) async {
    try {
      // Verifica che il font sia monospace
      final isMonospace = await _isMonospaceFont(fontName);
      if (!isMonospace) {
        // Se non è monospace, prova a trovare una variante monospace
        final variants = ['Mono', 'Monospace', 'Courier', 'Fixed'];
        String? monospaceVariant;
        for (final variant in variants) {
          final testName = '$fontName $variant';
          if (await _isMonospaceFont(testName)) {
            monospaceVariant = testName;
            break;
          }
        }
        if (monospaceVariant == null) {
          // Se non trova una variante, usa un font monospace di default
          monospaceVariant = 'Ubuntu Mono';
        }
        fontName = monospaceVariant;
      }
      
      String fontToSet;
      if (fontSize != null) {
        fontToSet = '$fontName ${fontSize.toInt()}';
      } else if (!RegExp(r'\s\d+$').hasMatch(fontName)) {
        final currentFull = await _getGsettings('org.gnome.desktop.interface', 'monospace-font-name');
        if (currentFull.isNotEmpty) {
          final parts = currentFull.split(' ');
          if (parts.length > 1 && RegExp(r'^\d+$').hasMatch(parts.last)) {
            fontToSet = '$fontName ${parts.last}';
          } else {
            fontToSet = '$fontName 10';
          }
        } else {
          fontToSet = '$fontName 10';
        }
      } else {
        fontToSet = fontName;
      }
      
      // Imposta il font monospace globale (solo per l'interfaccia, non per il terminale)
      await _runGsettings('org.gnome.desktop.interface', 'monospace-font-name', fontToSet);
      
      // NOTA: Il terminale mantiene le sue impostazioni classiche e non viene modificato
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========== RENDERING ==========

  /// Ottiene il hinting (Pieno, Medio, Leggero, Nessuno)
  static Future<String> getHinting() async {
    return await _getGsettings('org.gnome.desktop.interface', 'font-hinting');
  }

  /// Imposta il hinting
  static Future<bool> setHinting(String hinting) async {
    // Valori: 'none', 'slight', 'medium', 'full'
    try {
      await _runGsettings('org.gnome.desktop.interface', 'font-hinting', hinting);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'antialiasing
  static Future<String> getAntialiasing() async {
    return await _getGsettings('org.gnome.desktop.interface', 'font-antialiasing');
  }

  /// Imposta l'antialiasing
  static Future<bool> setAntialiasing(String antialiasing) async {
    // Valori: 'none', 'grayscale', 'rgba'
    try {
      await _runGsettings('org.gnome.desktop.interface', 'font-antialiasing', antialiasing);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il fattore di scala
  static Future<double> getScaleFactor() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.interface', 'text-scaling-factor');
      return double.tryParse(result) ?? 1.0;
    } catch (e) {
      return 1.0;
    }
  }

  /// Imposta il fattore di scala
  static Future<bool> setScaleFactor(double factor) async {
    try {
      await _runGsettings('org.gnome.desktop.interface', 'text-scaling-factor', factor.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========== STILI E TEMI ==========

  /// Ottiene il cursore (tema)
  static Future<String> getCursorTheme() async {
    return await _getGsettings('org.gnome.desktop.interface', 'cursor-theme');
  }

  /// Imposta il cursore (tema)
  static Future<bool> setCursorTheme(String theme) async {
    try {
      await _runGsettings('org.gnome.desktop.interface', 'cursor-theme', theme);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il tema delle icone
  static Future<String> getIconTheme() async {
    return await _getGsettings('org.gnome.desktop.interface', 'icon-theme');
  }

  /// Imposta il tema delle icone
  static Future<bool> setIconTheme(String theme) async {
    try {
      final themeName = theme.replaceAll("'", "").trim();
      await _runGsettings('org.gnome.desktop.interface', 'icon-theme', themeName);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il tema delle applicazioni legacy
  static Future<String> getLegacyTheme() async {
    return await _getGsettings('org.gnome.desktop.interface', 'gtk-theme');
  }

  /// Legge il nome del tema dall'index.theme
  /// Cerca prima GtkTheme=, poi Name= come fallback
  static Future<String> _getThemeNameFromIndex(String themePath) async {
    try {
      final indexFile = File('$themePath/index.theme');
      if (await indexFile.exists()) {
        final content = await indexFile.readAsString();
        final lines = content.split('\n');
        
        // Prima cerca GtkTheme= (nome del tema GTK)
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('GtkTheme=')) {
            final themeName = trimmedLine.substring('GtkTheme='.length).trim();
            if (themeName.isNotEmpty) {
              return themeName;
            }
          }
        }
        
        // Se non trovato, cerca Name= nella sezione [Desktop Entry]
        bool inDesktopEntry = false;
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine == '[Desktop Entry]') {
            inDesktopEntry = true;
            continue;
          }
          if (trimmedLine.startsWith('[') && trimmedLine.endsWith(']')) {
            inDesktopEntry = false;
            continue;
          }
          if (inDesktopEntry && trimmedLine.startsWith('Name=')) {
            final themeName = trimmedLine.substring('Name='.length).trim();
            if (themeName.isNotEmpty) {
              return themeName;
            }
          }
        }
      }
    } catch (e) {
      // Ignora errori
    }
    return '';
  }

  /// Applica il tema GNOME completo
  static Future<void> applyGnomeTheme(String themeName) async {
    try {
      final actualThemeName = themeName.replaceAll("'", "").trim();
      
      // Verifica che il tema esista usando il nome della directory
      final themePaths = [
        '/usr/share/themes/$actualThemeName',
        '${Platform.environment['HOME']}/.themes/$actualThemeName',
      ];
      
      bool themeExists = false;
      String themePath = '';
      String finalThemeName = actualThemeName;
      String gtkThemeName = actualThemeName; // Nome per GTK theme
      String wmThemeName = actualThemeName; // Nome per WM theme
      
      for (final path in themePaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          themeExists = true;
          themePath = path;
          // Leggi il nome corretto dall'index.theme se disponibile
          final nameFromIndex = await _getThemeNameFromIndex(path);
          if (nameFromIndex.isNotEmpty) {
            // Usa il nome da index.theme per GTK theme
            gtkThemeName = nameFromIndex;
            // Per WM theme, prova prima il nome da index.theme, poi il nome della directory
            // Alcuni temi hanno nomi diversi per GTK e WM
            wmThemeName = nameFromIndex;
          } else {
            // Se non c'è index.theme, usa il nome della directory per entrambi
            gtkThemeName = actualThemeName;
            wmThemeName = actualThemeName;
          }
          finalThemeName = gtkThemeName;
          break;
        }
      }
      
      // Se il tema non esiste, verifica se richiede ocs-url o PLing-store
      if (!themeExists) {
        final requiresOcs = await OcsUrlService.themeRequiresOcsUrl(actualThemeName);
        final isPlingTheme = await PlingStoreService.isThemeInstalledViaPlingStore(actualThemeName);
        
        if (requiresOcs || isPlingTheme) {
          // Prova a installare il tema direttamente senza ocs-url
          try {
            final installedThemeName = await OcsThemeInstaller.installThemeRequiringOcs(actualThemeName);
            if (installedThemeName != null) {
              // Ricarica il tema appena installato
              themeExists = true;
              themePath = '${Platform.environment['HOME']}/.themes/$installedThemeName';
              final nameFromIndex = await _getThemeNameFromIndex(themePath);
              if (nameFromIndex.isNotEmpty) {
                gtkThemeName = nameFromIndex;
                wmThemeName = nameFromIndex;
              } else {
                gtkThemeName = installedThemeName;
                wmThemeName = installedThemeName;
              }
              finalThemeName = gtkThemeName;
            } else {
              throw Exception('Impossibile installare il tema "$actualThemeName"');
            }
          } catch (e) {
            // Se l'installazione diretta fallisce, lancia l'eccezione
            throw Exception('Tema "$actualThemeName" non trovato e impossibile installarlo automaticamente: $e');
          }
        } else {
          throw Exception('Tema "$actualThemeName" non trovato');
        }
      }
      
      // Verifica se il tema è installato correttamente
      final isInstalledCorrectly = await OcsUrlService.isThemeInstalledCorrectly(actualThemeName);
      final isPlingTheme = await PlingStoreService.isThemeInstalledViaPlingStore(actualThemeName);
      
      if (!isInstalledCorrectly && !isPlingTheme) {
        final requiresOcs = await OcsUrlService.themeRequiresOcsUrl(actualThemeName);
        if (requiresOcs) {
          // Prova a installare/riparare il tema direttamente
          try {
            final installedThemeName = await OcsThemeInstaller.installThemeRequiringOcs(actualThemeName);
            if (installedThemeName == null) {
              throw Exception('Impossibile installare/riparare il tema "$actualThemeName"');
            }
            // Verifica nuovamente dopo l'installazione
            final isNowInstalled = await OcsUrlService.isThemeInstalledCorrectly(installedThemeName);
            if (!isNowInstalled) {
              throw Exception('Tema "$actualThemeName" installato ma non valido');
            }
          } catch (e) {
            throw Exception('Tema "$actualThemeName" non è installato correttamente: $e');
          }
        }
      }
      
      // 1. Applica il tema GTK3 (principale) - usa il nome da index.theme o directory
      await _runGsettings('org.gnome.desktop.interface', 'gtk-theme', gtkThemeName);
      
      // 2. Applica il tema per le decorazioni delle finestre (WM) - usa il nome della directory
      // Il WM theme spesso richiede il nome esatto della directory, non quello da index.theme
      await _runGsettings('org.gnome.desktop.wm.preferences', 'theme', actualThemeName);
      
      // 3. Applica il tema GTK2 (per applicazioni legacy)
      try {
        final homeDir = Platform.environment['HOME'] ?? '';
        final gtk2RcContent = '''
# GTK2 Theme Configuration
include "/usr/share/themes/$gtkThemeName/gtk-2.0/gtkrc"
include "$homeDir/.themes/$gtkThemeName/gtk-2.0/gtkrc"
gtk-theme-name="$gtkThemeName"
''';
        final gtk2RcFile = File('$homeDir/.gtkrc-2.0');
        await gtk2RcFile.writeAsString(gtk2RcContent);
      } catch (e) {
        // Ignora errori GTK2
      }
      
      // 4. Applica il tema GTK4 tramite variabile d'ambiente
      // Nota: export in un processo separato non ha effetto, quindi saltiamo questo
      // Il tema GTK4 viene applicato tramite gsettings
      try {
        // Non serve fare export in un processo separato
      } catch (e) {
        // Ignora errori
      }
      
      // 5. Applica il tema icone (se il tema include icone)
      try {
        final iconPaths = [
          '/usr/share/icons/$gtkThemeName',
          '${Platform.environment['HOME']}/.icons/$gtkThemeName',
          '/usr/share/icons/${gtkThemeName}-icons',
          '${Platform.environment['HOME']}/.icons/${gtkThemeName}-icons',
        ];
        
        // Se il tema ha un GtkTheme diverso dal nome directory, prova anche quello
        if (gtkThemeName != actualThemeName) {
          iconPaths.addAll([
            '/usr/share/icons/$actualThemeName',
            '${Platform.environment['HOME']}/.icons/$actualThemeName',
          ]);
        }
        
        for (final iconPath in iconPaths) {
          final iconDir = Directory(iconPath);
          if (await iconDir.exists()) {
            final iconThemeName = iconPath.split('/').last;
            await _runGsettings('org.gnome.desktop.interface', 'icon-theme', iconThemeName);
            break;
          }
        }
      } catch (e) {
        // Ignora errori se il tema non include icone
      }
      
      // 6. Applica il tema GNOME Shell (se estensione User Themes è attiva)
      try {
        final result = await Process.run(
          'bash',
          ['-c', 'gnome-extensions list --enabled | grep -q user-theme && echo "enabled" || echo "disabled"'],
          runInShell: false,
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
        );
        
        if (result.exitCode == 0 && result.stdout.toString().trim().contains('enabled')) {
          // Per GNOME Shell, usa il nome della directory (come per WM)
          await _runGsettings('org.gnome.shell.extensions.user-theme', 'name', actualThemeName);
          
          // Riavvia GNOME Shell per applicare immediatamente (con timeout)
          try {
            await Process.run(
              'busctl',
              ['--user', 'call', 'org.gnome.Shell', '/org/gnome/Shell', 'org.gnome.Shell', 'Eval', 's', 'Meta.restart(\'Restarting…\')'],
              runInShell: false,
            ).timeout(
              const Duration(seconds: 2),
              onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
            );
          } catch (e) {
            // Ignora errori nel riavvio GNOME Shell
          }
        }
      } catch (e) {
        // Estensione non disponibile o non installata
      }
      
      // 7. Aggiorna la cache delle icone
      try {
        final iconPaths = [
          '/usr/share/icons/$gtkThemeName',
          '${Platform.environment['HOME']}/.icons/$gtkThemeName',
        ];
        
        for (final iconPath in iconPaths) {
          try {
            final dir = Directory(iconPath);
            if (await dir.exists()) {
              await Process.run(
                'gtk-update-icon-cache',
                ['-f', '-t', iconPath],
                runInShell: false,
              ).timeout(
                const Duration(seconds: 2),
                onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
              );
            }
          } catch (e) {
            // Ignora errori
          }
        }
      } catch (e) {
        // Ignora errori
      }
      
      // 8. Applica il tema anche per le applicazioni Flatpak (se disponibile)
      try {
        final homeDir = Platform.environment['HOME'] ?? '';
        await Process.run(
          'flatpak',
          ['--user', 'override', '--env=GTK_THEME=$gtkThemeName', '--env=GTK2_RC_FILES=$homeDir/.gtkrc-2.0'],
          runInShell: false,
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
        );
      } catch (e) {
        // Flatpak non disponibile o non installato
      }
      
      // 9. Aggiorna le variabili d'ambiente globali per GTK2 e GTK4
      try {
        final homeDir = Platform.environment['HOME'] ?? '';
        final profileContent = '''
# GTK Theme Configuration
export GTK_THEME="$gtkThemeName"
export GTK2_RC_FILES="$homeDir/.gtkrc-2.0"
''';
        
        // Aggiungi al .profile se non esiste già
        final profileFile = File('$homeDir/.profile');
        String existingContent = '';
        if (await profileFile.exists()) {
          existingContent = await profileFile.readAsString();
        }
        
        if (!existingContent.contains('GTK_THEME=')) {
          await profileFile.writeAsString('$existingContent\n$profileContent', mode: FileMode.append);
        }
      } catch (e) {
        // Ignora errori
      }
      
      // 10. Forza il refresh del tema GTK3
      try {
        // Prima imposta a vuoto, poi al tema finale
        await _runGsettings('org.gnome.desktop.interface', 'gtk-theme', '');
        await Future.delayed(const Duration(milliseconds: 200));
        await _runGsettings('org.gnome.desktop.interface', 'gtk-theme', finalThemeName);
      } catch (e) {
        // Se fallisce, riprova con il metodo normale
        try {
        await _runGsettings('org.gnome.desktop.interface', 'gtk-theme', finalThemeName);
        } catch (e2) {
          // Ignora errori
        }
      }
      
      // 11. Notifica alle applicazioni GTK di ricaricare il tema
      try {
        await Process.run(
          'killall',
          ['-HUP', 'gtk-launch'],
          runInShell: false,
        ).timeout(
          const Duration(seconds: 1),
          onTimeout: () => ProcessResult(1, -1, '', 'Timeout'),
        );
      } catch (e) {
        // Ignora errori (gtk-launch potrebbe non essere in esecuzione)
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Imposta il tema delle applicazioni GTK
  static Future<bool> setLegacyTheme(String theme) async {
    try {
      await applyGnomeTheme(theme);
      return true;
    } catch (e) {
      return false;
    }
  }

  static List<String>? _cachedThemes;
  static DateTime? _themesCacheTime;
  
  /// Ottiene la lista dei temi disponibili (con cache)
  static Future<List<String>> getAvailableThemes({bool forceRefresh = false}) async {
    try {
      // Se forceRefresh è true, invalida la cache
      if (forceRefresh) {
        invalidateThemesCache();
      }
      
      // Usa cache se disponibile e non troppo vecchia (30 minuti per performance)
      if (_cachedThemes != null && _themesCacheTime != null && !forceRefresh) {
        final cacheAge = DateTime.now().difference(_themesCacheTime!);
        if (cacheAge.inMinutes < 30) {
          return _cachedThemes!;
        }
      }
      
      List<String> themes = [];

      // Directory possibili
      List<String> themeDirs = [
        path.join(Platform.environment['HOME'] ?? '', '.themes'),
        '/usr/share/themes',
      ];

      for (var dirPath in themeDirs) {
        try {
          var dir = Directory(dirPath);
          if (await dir.exists()) {
            await for (var entity in dir.list()) {
              try {
                if (entity is Directory) {
                  String themeName = path.basename(entity.path);
                  
                  // Verifica che sia un tema valido (ha almeno gtk-3.0, gtk-4.0, gnome-shell o index.theme)
                  var gtk3 = Directory(path.join(entity.path, 'gtk-3.0'));
                  var gtk4 = Directory(path.join(entity.path, 'gtk-4.0'));
                  var shellDir = Directory(path.join(entity.path, 'gnome-shell'));
                  var indexFile = File(path.join(entity.path, 'index.theme'));
                  
                  // Aggiungi se ha almeno una di queste strutture (verifica rapida senza controlli ocs)
                  // I controlli ocs sono costosi, li facciamo solo quando necessario (durante l'applicazione)
                  if (await gtk3.exists() || 
                      await gtk4.exists() || 
                      await shellDir.exists() || 
                      await indexFile.exists()) {
                    themes.add(themeName);
                  }
                }
              } catch (e) {
                // Ignora errori su singole entità
                continue;
              }
            }
          }
        } catch (e) {
          // Ignora errori su singole directory
          continue;
        }
      }

      // Rimuovi duplicati e ordina
      final uniqueThemes = themes.toSet().toList()..sort();
      
      // Aggiorna cache solo se abbiamo trovato almeno un tema
      if (uniqueThemes.isNotEmpty) {
        _cachedThemes = uniqueThemes;
        _themesCacheTime = DateTime.now();
      } else {
        // Se non troviamo temi, prova valori di default
        return ['Yaru', 'Yaru-dark', 'Adwaita', 'Adwaita-dark'];
      }
      
      return uniqueThemes;
    } catch (e) {
      // Se c'è un errore, prova a invalidare la cache e ritorna valori di default
      invalidateThemesCache();
      return _cachedThemes ?? ['Yaru', 'Yaru-dark', 'Adwaita', 'Adwaita-dark'];
    }
  }
  
  /// Invalida la cache dei temi
  static void invalidateThemesCache() {
    _cachedThemes = null;
    _themesCacheTime = null;
  }

  /// Invalida la cache dei font
  static void invalidateFontsCache() {
    _cachedFonts = null;
    _fontsCacheTime = null;
  }

  // ========== SFONDO ==========

  /// Ottiene l'immagine di sfondo predefinita
  static Future<String> getBackgroundImage() async {
    return await _getGsettings('org.gnome.desktop.background', 'picture-uri');
  }

  /// Imposta l'immagine di sfondo predefinita
  static Future<bool> setBackgroundImage(String imagePath) async {
    try {
      // gsettings richiede un URI file://
      final uri = imagePath.startsWith('file://') ? imagePath : 'file://$imagePath';
      await _runGsettings('org.gnome.desktop.background', 'picture-uri', uri);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'immagine di sfondo per lo stile scuro
  static Future<String> getDarkBackgroundImage() async {
    return await _getGsettings('org.gnome.desktop.background', 'picture-uri-dark');
  }

  /// Imposta l'immagine di sfondo per lo stile scuro
  static Future<bool> setDarkBackgroundImage(String imagePath) async {
    try {
      final uri = imagePath.startsWith('file://') ? imagePath : 'file://$imagePath';
      await _runGsettings('org.gnome.desktop.background', 'picture-uri-dark', uri);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene la regolazione dello sfondo
  static Future<String> getBackgroundAdjustment() async {
    return await _getGsettings('org.gnome.desktop.background', 'picture-options');
  }

  /// Imposta la regolazione dello sfondo
  static Future<bool> setBackgroundAdjustment(String adjustment) async {
    // Valori: 'none', 'wallpaper', 'centered', 'scaled', 'stretched', 'zoom', 'spanned'
    try {
      await _runGsettings('org.gnome.desktop.background', 'picture-options', adjustment);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ========== COMPORTAMENTO FINESTRE ==========

  /// Ottiene l'azione del doppio clic sulla barra del titolo
  static Future<String> getDoubleClickAction() async {
    return await _getGsettings('org.gnome.desktop.wm.preferences', 'action-double-click-titlebar');
  }

  /// Imposta l'azione del doppio clic sulla barra del titolo
  static Future<bool> setDoubleClickAction(String action) async {
    // Valori: 'toggle-maximize', 'toggle-maximize-horizontally', 'toggle-maximize-vertically', 'toggle-shade', 'toggle-menu', 'minimize', 'none', 'lower'
    try {
      await _runGsettings('org.gnome.desktop.wm.preferences', 'action-double-click-titlebar', action);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'azione del clic centrale sulla barra del titolo
  static Future<String> getMiddleClickAction() async {
    return await _getGsettings('org.gnome.desktop.wm.preferences', 'action-middle-click-titlebar');
  }

  /// Imposta l'azione del clic centrale sulla barra del titolo
  static Future<bool> setMiddleClickAction(String action) async {
    try {
      await _runGsettings('org.gnome.desktop.wm.preferences', 'action-middle-click-titlebar', action);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'azione del clic secondario sulla barra del titolo
  static Future<String> getRightClickAction() async {
    return await _getGsettings('org.gnome.desktop.wm.preferences', 'action-right-click-titlebar');
  }

  /// Imposta l'azione del clic secondario sulla barra del titolo
  static Future<bool> setRightClickAction(String action) async {
    try {
      await _runGsettings('org.gnome.desktop.wm.preferences', 'action-right-click-titlebar', action);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene se il pulsante massimizza è visibile
  static Future<bool> getMaximizeButtonVisible() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.wm.preferences', 'button-layout');
      return result.contains(':maximize') || result.contains('maximize:');
    } catch (e) {
      return true;
    }
  }

  /// Imposta la visibilità del pulsante massimizza
  static Future<bool> setMaximizeButtonVisible(bool visible) async {
    try {
      final current = await _getGsettings('org.gnome.desktop.wm.preferences', 'button-layout');
      // Formato: 'close,minimize,maximize:' o ':minimize,maximize,close'
      
      // Determina se i pulsanti sono a sinistra (inizia con ':') o a destra
      final isLeft = current.startsWith(':');
      
      // Estrai i pulsanti attuali (rimuovi i ':')
      final buttons = current.replaceAll(':', '').split(',').where((b) => b.isNotEmpty && b != 'maximize').toList();
      
      String newLayout;
      if (visible) {
        // Aggiungi 'maximize' se non è già presente
        if (!buttons.contains('maximize')) {
          // Aggiungi 'maximize' dopo 'minimize' se esiste, altrimenti alla fine
          final minimizeIndex = buttons.indexOf('minimize');
          if (minimizeIndex >= 0) {
            buttons.insert(minimizeIndex + 1, 'maximize');
          } else {
            buttons.add('maximize');
          }
        }
      }
      // Se visible = false, 'maximize' è già stato rimosso dalla lista sopra
      
      // Ricostruisci il layout preservando la posizione (sinistra/destra)
      final buttonsString = buttons.join(',');
      newLayout = isLeft ? ':$buttonsString' : '$buttonsString:';
      
      await _runGsettings('org.gnome.desktop.wm.preferences', 'button-layout', newLayout);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene se il pulsante minimizza è visibile
  static Future<bool> getMinimizeButtonVisible() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.wm.preferences', 'button-layout');
      return result.contains(':minimize') || result.contains('minimize:');
    } catch (e) {
      return true;
    }
  }

  /// Imposta la visibilità del pulsante minimizza
  static Future<bool> setMinimizeButtonVisible(bool visible) async {
    try {
      final current = await _getGsettings('org.gnome.desktop.wm.preferences', 'button-layout');
      // Formato: 'close,minimize,maximize:' o ':minimize,maximize,close'
      
      // Determina se i pulsanti sono a sinistra (inizia con ':') o a destra
      final isLeft = current.startsWith(':');
      
      // Estrai i pulsanti attuali (rimuovi i ':')
      final buttons = current.replaceAll(':', '').split(',').where((b) => b.isNotEmpty && b != 'minimize').toList();
      
      String newLayout;
      if (visible) {
        // Aggiungi 'minimize' se non è già presente
        if (!buttons.contains('minimize')) {
          // Aggiungi 'minimize' dopo 'close' se esiste, altrimenti all'inizio
          final closeIndex = buttons.indexOf('close');
          if (closeIndex >= 0) {
            buttons.insert(closeIndex + 1, 'minimize');
          } else {
            buttons.insert(0, 'minimize');
          }
        }
      }
      // Se visible = false, 'minimize' è già stato rimosso dalla lista sopra
      
      // Ricostruisci il layout preservando la posizione (sinistra/destra)
      final buttonsString = buttons.join(',');
      newLayout = isLeft ? ':$buttonsString' : '$buttonsString:';
      
      await _runGsettings('org.gnome.desktop.wm.preferences', 'button-layout', newLayout);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'ordine corrente dei pulsanti
  /// Ritorna una lista con l'ordine: ['close', 'minimize', 'maximize'] o simile
  static Future<List<String>> getButtonOrder() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.wm.preferences', 'button-layout');
      // Rimuove i ':' e ottiene solo i pulsanti
      final buttons = result.replaceAll(':', '').split(',').where((b) => b.isNotEmpty).toList();
      return buttons;
    } catch (e) {
      return ['close', 'minimize', 'maximize'];
    }
  }

  /// Ottiene il posizionamento dei pulsanti (Sinistra/Destra)
  static Future<String> getButtonPosition() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.wm.preferences', 'button-layout');
      // Se inizia con ':', i pulsanti sono a sinistra, altrimenti a destra
      // INVERTITO: quando il sistema ha ':' (sinistra), mostriamo 'right' nell'UI
      return result.startsWith(':') ? 'right' : 'left';
    } catch (e) {
      return 'left';
    }
  }

  /// Imposta l'ordine dei pulsanti
  /// buttons: lista con l'ordine desiderato, es. ['close', 'minimize', 'maximize']
  /// position: 'left' o 'right' (INVERTITO: 'left' nell'UI = destra nel sistema, 'right' nell'UI = sinistra nel sistema)
  static Future<bool> setButtonLayout({required List<String> buttons, required String position}) async {
    try {
      String newLayout;
      final buttonsString = buttons.join(',');
      
      // INVERTITO: quando l'utente seleziona 'left' nell'UI, i pulsanti vanno a destra nel sistema
      if (position == 'left') {
        // Pulsanti a destra nel sistema: 'close,minimize,maximize:'
        newLayout = '$buttonsString:';
      } else {
        // Pulsanti a sinistra nel sistema: ':close,minimize,maximize'
        newLayout = ':$buttonsString';
      }
      
      await _runGsettings('org.gnome.desktop.wm.preferences', 'button-layout', newLayout);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Imposta il posizionamento dei pulsanti (mantenendo l'ordine corrente)
  static Future<bool> setButtonPosition(String position) async {
    try {
      final currentButtons = await getButtonOrder();
      return await setButtonLayout(buttons: currentButtons, position: position);
    } catch (e) {
      return false;
    }
  }

  /// Ottiene se le finestre di dialogo allegate sono attaccate
  static Future<bool> getAttachedDialogs() async {
    try {
      final result = await _getGsettings('org.gnome.mutter', 'attach-modal-dialogs');
      return result.toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Imposta se le finestre di dialogo allegate sono attaccate
  static Future<bool> setAttachedDialogs(bool attached) async {
    try {
      await _runGsettings('org.gnome.mutter', 'attach-modal-dialogs', attached.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene se le nuove finestre sono centrate
  static Future<bool> getCenterNewWindows() async {
    try {
      final result = await _getGsettings('org.gnome.mutter', 'center-new-windows');
      return result.toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Imposta se le nuove finestre sono centrate
  static Future<bool> setCenterNewWindows(bool center) async {
    try {
      await _runGsettings('org.gnome.mutter', 'center-new-windows', center.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il tasto azioni della finestra
  static Future<String> getWindowActionKey() async {
    return await _getGsettings('org.gnome.desktop.wm.keybindings', 'switch-windows');
  }

  /// Ottiene se il ridimensionamento con clic secondario è abilitato
  static Future<bool> getResizeWithSecondaryClick() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.wm.preferences', 'resize-with-right-button');
      return result.toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Imposta se il ridimensionamento con clic secondario è abilitato
  static Future<bool> setResizeWithSecondaryClick(bool enabled) async {
    try {
      await _runGsettings('org.gnome.desktop.wm.preferences', 'resize-with-right-button', enabled.toString());
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene il focus della finestra
  static Future<String> getWindowFocus() async {
    return await _getGsettings('org.gnome.desktop.wm.preferences', 'focus-mode');
  }

  /// Imposta il focus della finestra
  static Future<bool> setWindowFocus(String focusMode) async {
    // Valori: 'click', 'sloppy', 'mouse'
    try {
      await _runGsettings('org.gnome.desktop.wm.preferences', 'focus-mode', focusMode);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene se le finestre vengono sollevate quando hanno il focus
  static Future<bool> getRaiseOnFocus() async {
    try {
      final result = await _getGsettings('org.gnome.desktop.wm.preferences', 'raise-on-click');
      return result.toLowerCase() == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Imposta se le finestre vengono sollevate quando hanno il focus
  static Future<bool> setRaiseOnFocus(bool raise) async {
    try {
      await _runGsettings('org.gnome.desktop.wm.preferences', 'raise-on-click', raise.toString());
      return true;
    } catch (e) {
      return false;
    }
  }
}



