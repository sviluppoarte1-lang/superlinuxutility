import 'dart:io';
import 'package:path/path.dart' as path;

/// Gestisce l'avvio automatico dell'app al login (solo Linux).
/// Crea o rimuove un file .desktop in ~/.config/autostart/.
class AutostartService {
  static const String _desktopName = 'super-linux-utility.desktop';

  static Future<String> _getAutostartDir() async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    if (home.isEmpty) return '';
    return path.join(home, '.config', 'autostart');
  }

  static Future<String> _getDesktopPath() async {
    final dir = await _getAutostartDir();
    return dir.isEmpty ? '' : path.join(dir, _desktopName);
  }

  /// Verifica se l'avvio al login è abilitato (esiste il file .desktop in autostart).
  static Future<bool> isStartAtLoginEnabled() async {
    if (!Platform.isLinux) return false;
    final filePath = await _getDesktopPath();
    if (filePath.isEmpty) return false;
    return File(filePath).exists();
  }

  /// Abilita l'avvio al login: crea il file .desktop in ~/.config/autostart/.
  static Future<bool> setStartAtLogin(bool enable) async {
    if (!Platform.isLinux) return false;
    final filePath = await _getDesktopPath();
    if (filePath.isEmpty) return false;
    final file = File(filePath);
    if (enable) {
      try {
        final dir = Directory(path.dirname(filePath));
        if (!await dir.exists()) await dir.create(recursive: true);
        final executable = Platform.resolvedExecutable;
        final content = '''[Desktop Entry]
Type=Application
Name=Super Linux Utility
Comment=Super Linux Utility - System management
Exec=$executable
Terminal=false
X-GNOME-Autostart-enabled=true
''';
        await file.writeAsString(content);
        return true;
      } catch (_) {
        return false;
      }
    } else {
      try {
        if (await file.exists()) await file.delete();
        return true;
      } catch (_) {
        return false;
      }
    }
  }
}
