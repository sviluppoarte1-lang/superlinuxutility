import 'dart:io';
import 'password_storage.dart';
import 'system_detector.dart';

/// Risultato del check di una dipendenza
class DependencyStatus {
  final String id;
  final String name;
  final bool installed;
  final String? installCommand;
  final String? description;

  const DependencyStatus({
    required this.id,
    required this.name,
    this.installed = false,
    this.installCommand,
    this.description,
  });
}

/// Servizio per verificare e installare le dipendenze necessarie (es. system tray)
class DependencyCheckService {
  /// Verifica se le librerie per il system tray sono disponibili (Linux)
  static Future<bool> isSystemTraySupported() async {
    if (!Platform.isLinux) return false;
    try {
      // Controlla presenza libreria appindicator (necessaria per system_tray su Linux)
      const script = r'ldconfig -p 2>/dev/null | grep -q libappindicator3 || ldconfig -p 2>/dev/null | grep -q libayatana_appindicator3 || pkg-config --exists appindicator3-0.1 2>/dev/null || pkg-config --exists ayatana-appindicator3-0.1 2>/dev/null; echo $?';
      final result = await Process.run('bash', ['-c', script], runInShell: false);
      if (result.exitCode == 0) return true;
      final out = result.stdout.toString().trim();
      if (out == '0') return true;
      // Alternativa: verifica file .so
      const findScript = r'find /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu -name "*appindicator*" 2>/dev/null | head -1';
      final soCheck = await Process.run('bash', ['-c', findScript], runInShell: false);
      return (soCheck.stdout as String).trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Restituisce il comando per installare le dipendenze del system tray in base alla distribuzione
  static Future<String?> getSystemTrayInstallCommand() async {
    if (!Platform.isLinux) return null;
    try {
      final info = await SystemDetector.detectSystem();
      final dist = info.distribution.toLowerCase();
      if (info.hasApt || dist.contains('ubuntu') || dist.contains('debian') || dist.contains('mint') || dist.contains('pop')) {
        // Ubuntu 22.04+ usa libayatana-appindicator3
        return 'apt-get update && apt-get install -y libayatana-appindicator3-1 libgtk-3-0';
      }
      if (info.hasDnf || dist.contains('fedora') || dist.contains('rhel') || dist.contains('centos')) {
        return 'dnf install -y libappindicator-gtk3';
      }
      if (info.hasPacman || dist.contains('arch') || dist.contains('manjaro')) {
        return 'pacman -Sy --noconfirm libappindicator-gtk3';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Installa le dipendenze del system tray (richiede sudo)
  static Future<Map<String, dynamic>> installSystemTrayDependencies() async {
    final cmd = await getSystemTrayInstallCommand();
    if (cmd == null) {
      return {'success': false, 'message': 'Distribuzione non supportata per installazione automatica.'};
    }
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      return {'success': false, 'message': 'Salva la password nelle impostazioni per consentire l\'installazione.'};
    }
    final escaped = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    try {
      final result = await Process.run(
        'bash',
        ['-c', 'printf "%s\\n" "$escaped" | sudo -S bash -c "$cmd"'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        return {'success': true, 'message': 'Dipendenze installate.', 'output': result.stdout.toString()};
      }
      return {
        'success': false,
        'message': result.stderr?.toString() ?? result.stdout?.toString() ?? 'Errore installazione',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Esegue il check completo delle dipendenze necessarie all'avvio
  static Future<Map<String, DependencyStatus>> checkAllDependencies() async {
    final results = <String, DependencyStatus>{};
    if (Platform.isLinux) {
      final trayOk = await isSystemTraySupported();
      final installCmd = await getSystemTrayInstallCommand();
      results['system_tray'] = DependencyStatus(
        id: 'system_tray',
        name: 'System Tray (libappindicator)',
        installed: trayOk,
        installCommand: installCmd,
        description: 'Necessario per l\'icona nella system tray.',
      );
    }
    return results;
  }
}
