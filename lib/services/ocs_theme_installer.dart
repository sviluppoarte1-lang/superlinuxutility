import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';
import 'password_storage.dart';

/// Servizio per installare temi direttamente da OpenDesktop.org/Pling.com
/// senza richiedere ocs-url installato
class OcsThemeInstaller {
  /// Estrae l'URL di download da un URL ocs://
  static String? extractDownloadUrl(String ocsUrl) {
    try {
      // Formato: ocs://install?url=https://www.pling.com/p/1234567/
      if (ocsUrl.startsWith('ocs://')) {
        final uri = Uri.parse(ocsUrl);
        return uri.queryParameters['url'];
      }
      // Se è già un URL diretto
      if (ocsUrl.startsWith('http://') || ocsUrl.startsWith('https://')) {
        return ocsUrl;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Ottiene l'URL di download diretto da un URL Pling.com
  static Future<String?> getPlingDownloadUrl(String plingUrl) async {
    try {
      // Se l'URL contiene già un link diretto al file, usalo
      if (plingUrl.contains('.tar.gz') || plingUrl.contains('.zip')) {
        return plingUrl;
      }

      // Fai una richiesta HTTP per ottenere la pagina
      final response = await http.get(Uri.parse(plingUrl));
      if (response.statusCode != 200) {
        return null;
      }

      final html = response.body;
      
      // Cerca il link di download nella pagina HTML
      // I link di download su Pling.com sono tipicamente in un elemento con classe "download-button" o simile
      // Pattern comune: href="https://www.pling.com/p/1234567/files/download/file_id=1234567"
      final downloadPattern = RegExp(
        r'(?i)href="(https?://[^"]*pling\.com[^"]*download[^"]*)"'
      );
      
      final match = downloadPattern.firstMatch(html);
      if (match != null) {
        return match.group(1);
      }

      // Prova anche con virgolette singole
      final downloadPattern2 = RegExp(
        r"(?i)href='(https?://[^']*pling\.com[^']*download[^']*)'"
      );
      
      final match2 = downloadPattern2.firstMatch(html);
      if (match2 != null) {
        return match2.group(1);
      }

      // Prova a cercare link diretti a file .tar.gz o .zip
      final filePattern = RegExp(
        r'(?i)href="(https?://[^"]*\.(tar\.gz|zip))"'
      );
      
      final fileMatch = filePattern.firstMatch(html);
      if (fileMatch != null) {
        return fileMatch.group(1);
      }

      // Prova anche con virgolette singole per i file
      final filePattern2 = RegExp(
        r"(?i)href='(https?://[^']*\.(tar\.gz|zip))'"
      );
      
      final fileMatch2 = filePattern2.firstMatch(html);
      if (fileMatch2 != null) {
        return fileMatch2.group(1);
      }

      // Se non troviamo un link diretto, prova a costruire l'URL di download
      // Pling.com usa spesso questo formato: https://www.pling.com/p/{id}/files/download/file_id={file_id}
      final idMatch = RegExp(r'/p/(\d+)').firstMatch(plingUrl);
      if (idMatch != null) {
        final itemId = idMatch.group(1);
        // Prova a ottenere l'API JSON per ottenere i file disponibili
        try {
          final apiUrl = 'https://www.pling.com/api/projects/$itemId';
          final apiResponse = await http.get(Uri.parse(apiUrl));
          if (apiResponse.statusCode == 200) {
            final json = jsonDecode(apiResponse.body);
            // Cerca il primo file disponibile
            if (json is Map && json.containsKey('files')) {
              final files = json['files'];
              if (files is List && files.isNotEmpty) {
                final firstFile = files[0];
                if (firstFile is Map && firstFile.containsKey('download_url')) {
                  return firstFile['download_url'] as String?;
                }
              }
            }
          }
        } catch (e) {
          // Ignora errori API
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Scarica e installa un tema da un URL ocs:// o Pling.com
  static Future<String?> downloadAndInstallTheme(String ocsUrlOrPlingUrl) async {
    try {
      // Estrai l'URL di download
      String? downloadUrl = extractDownloadUrl(ocsUrlOrPlingUrl);
      if (downloadUrl == null) {
        downloadUrl = ocsUrlOrPlingUrl;
      }

      // Se è un URL Pling.com, ottieni l'URL di download diretto
      if (downloadUrl.contains('pling.com') || downloadUrl.contains('opendesktop.org')) {
        downloadUrl = await getPlingDownloadUrl(downloadUrl);
        if (downloadUrl == null) {
          throw Exception('Impossibile trovare l\'URL di download per questo tema');
        }
      }

      // Scarica il file
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Errore durante il download: ${response.statusCode}');
      }

      // Determina il tipo di file e estrai
      final homeDir = Platform.environment['HOME'] ?? '';
      final themesDir = Directory(path.join(homeDir, '.themes'));
      if (!await themesDir.exists()) {
        await themesDir.create(recursive: true);
      }

      Archive? archive;
      if (downloadUrl.endsWith('.zip') || response.headers['content-type']?.contains('zip') == true) {
        archive = ZipDecoder().decodeBytes(response.bodyBytes);
      } else if (downloadUrl.endsWith('.tar.gz') || downloadUrl.endsWith('.tgz') || 
                 response.headers['content-type']?.contains('gzip') == true) {
        archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(response.bodyBytes));
      } else {
        throw Exception('Formato file non supportato. Supportati: .zip, .tar.gz');
      }

      // Estrai l'archivio
      String? themeName;
      for (final file in archive.files) {
        if (file.isFile) {
          final filename = file.name;
          // Trova la directory principale del tema (di solito la prima directory)
          final parts = filename.split('/');
          if (parts.length > 1) {
            final potentialThemeName = parts[0];
            if (themeName == null || potentialThemeName.length < themeName.length) {
              themeName = potentialThemeName;
            }
          }
        }
      }

      if (themeName == null || themeName.isEmpty) {
        throw Exception('Impossibile determinare il nome del tema dall\'archivio');
      }

      final themeDir = Directory(path.join(themesDir.path, themeName));
      if (await themeDir.exists()) {
        // Rimuovi il tema esistente
        await themeDir.delete(recursive: true);
      }
      await themeDir.create(recursive: true);

      // Estrai i file
      for (final file in archive.files) {
        if (file.isFile) {
          final filename = file.name;
          // Rimuovi il prefisso della directory principale
          final relativePath = filename.replaceFirst('$themeName/', '');
          if (relativePath == filename) {
            // Se non c'è il prefisso, prova a rimuovere solo la prima parte
            final parts = filename.split('/');
            if (parts.length > 1) {
              final newParts = parts.sublist(1);
              final newPath = newParts.join('/');
              final targetFile = File(path.join(themeDir.path, newPath));
              await targetFile.parent.create(recursive: true);
              await targetFile.writeAsBytes(file.content as List<int>);
            }
          } else {
            final targetFile = File(path.join(themeDir.path, relativePath));
            await targetFile.parent.create(recursive: true);
            await targetFile.writeAsBytes(file.content as List<int>);
          }
        }
      }

      // Aggiorna la cache delle icone GTK
      try {
        var shell = Shell();
        await shell.run('gtk-update-icon-cache -f -t ${themeDir.path} 2>/dev/null || true');
      } catch (e) {
        // Ignora errori di cache
      }

      return themeName;
    } catch (e) {
      rethrow;
    }
  }

  /// Cerca un URL ocs:// o Pling.com in un tema esistente
  static Future<String?> findOcsUrlInTheme(String themeName) async {
    try {
      final themePaths = [
        '/usr/share/themes/$themeName',
        '${Platform.environment['HOME']}/.themes/$themeName',
      ];

      for (final themePath in themePaths) {
        final dir = Directory(themePath);
        if (await dir.exists()) {
          // Cerca file .ocs
          final ocsFile = File(path.join(themePath, '.ocs'));
          if (await ocsFile.exists()) {
            final content = await ocsFile.readAsString();
            final urlMatch = RegExp(r'(?i)(ocs://[^\s]+|https?://[^\s]*pling\.com[^\s]+)').firstMatch(content);
            if (urlMatch != null) {
              return urlMatch.group(1);
            }
          }

          // Cerca in index.theme
          final indexFile = File(path.join(themePath, 'index.theme'));
          if (await indexFile.exists()) {
            final content = await indexFile.readAsString();
            final urlMatch = RegExp(r'(?i)(ocs://[^\s]+|https?://[^\s]*pling\.com[^\s]+)').firstMatch(content);
            if (urlMatch != null) {
              return urlMatch.group(1);
            }
          }

          // Cerca in tutti i file di testo
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              try {
                final content = await entity.readAsString();
                final urlMatch = RegExp(r'(?i)(ocs://[^\s]+|https?://[^\s]*pling\.com[^\s]+)').firstMatch(content);
                if (urlMatch != null) {
                  return urlMatch.group(1);
                }
              } catch (e) {
                // Ignora file binari
              }
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Installa un tema che richiede ocs-url, scaricandolo direttamente
  static Future<String?> installThemeRequiringOcs(String themeName) async {
    try {
      // Cerca l'URL ocs:// nel tema
      final ocsUrl = await findOcsUrlInTheme(themeName);
      if (ocsUrl == null) {
        throw Exception('Impossibile trovare l\'URL ocs:// per il tema "$themeName"');
      }

      // Scarica e installa il tema
      return await downloadAndInstallTheme(ocsUrl);
    } catch (e) {
      rethrow;
    }
  }
}

