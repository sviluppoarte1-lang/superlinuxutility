import 'dart:io';
import '../utils/process_utils.dart';
import 'password_storage.dart';
import 'repository_manager.dart';
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
  /// Verifica se le librerie per il system tray sono disponibili (Linux).
  ///
  /// Il plugin system_tray richiede `libayatana-appindicator3.so.1` (NEEDED a
  /// load time); a runtime fa inoltre `dlopen("libappindicator3.so.1")`, che su
  /// Debian/Ubuntu è un symlink verso ayatana (incluso nell'AppImage).
  ///
  /// * **AppImage**: le librerie sono bundled — si controlla l'AppDir (via
  ///   `APPDIR` o il percorso dell'eseguibile `/.mount_xxx/usr/bin/...`), non
  ///   il sistema host. Su Fedora i pacchetti appindicator non esistono nei
  ///   repo ufficiali, quindi il check host fallirebbe anche a tray funzionante.
  /// * **Sistema nativo**: `ldconfig` con percorsi assoluti (spesso non è in
  ///   PATH per le app GUI) + fallback `find` sui path multiarch.
  ///
  /// NOTA: il vecchio check leggeva `result.exitCode` di uno script che
  /// terminava con `echo $?` → exit code SEMPRE 0 → risultato "sempre true":
  /// le librerie mancanti (Fedora) venivano sempre date per presenti e il
  /// pulsante di installazione non compariva mai. Si legge ora l'output.
  static Future<bool> isSystemTraySupported() async {
    if (!Platform.isLinux) return false;
    try {
      // 1) AppImage: APPDIR è esportato dall'AppRun del bundle.
      final appDir = Platform.environment['APPDIR'];
      if (appDir != null && appDir.isNotEmpty) {
        if (await _dirHasAyatana('$appDir/usr/lib')) return true;
        return await _dirHasAyatana('$appDir/usr/bin/lib');
      }
      // 2) AppImage senza APPDIR: l'eseguibile risiede in /.mount_xxx/usr/bin
      //    → librerie in ../lib (usr/lib) rispetto alla binaria.
      final exe = Platform.resolvedExecutable;
      final exeDir = exe.substring(0, exe.lastIndexOf('/'));
      final usrDir = exeDir.contains('/')
          ? exeDir.substring(0, exeDir.lastIndexOf('/'))
          : '';
      if (usrDir.isNotEmpty && await _dirHasAyatana('$usrDir/lib')) return true;
      // 3) Sistema nativo.
      const script = r'''
found=1
for lc in ldconfig /sbin/ldconfig /usr/sbin/ldconfig /bin/ldconfig; do
  if [ -x "$lc" ] || command -v "$lc" >/dev/null 2>&1; then
    if "$lc" -p 2>/dev/null | grep -q 'libayatana-appindicator3\.so\.1'; then found=0; break; fi
  fi
done
if [ "$found" != 0 ]; then
  if find /usr/lib /usr/lib64 /lib /lib64 /usr/lib/x86_64-linux-gnu /lib/x86_64-linux-gnu -maxdepth 2 -name 'libayatana-appindicator3.so*' 2>/dev/null | grep -q .; then
    found=0
  fi
fi
echo "$found"
''';
      final result =
          await Process.run('bash', ['-c', script], runInShell: false);
      return result.stdout.toString().trim() == '0';
    } catch (_) {
      return false;
    }
  }

  /// True se [dir] contiene la libreria ayatana (file o symlink, non serve
  /// risolvere: basta il nome per indicare che il bundle/host la offre).
  static Future<bool> _dirHasAyatana(String dir) async {
    try {
      final d = Directory(dir);
      if (!await d.exists()) return false;
      await for (final e in d.list(followLinks: false)) {
        final name = e.path.split('/').last;
        if (name.startsWith('libayatana-appindicator3.so')) return true;
      }
    } catch (_) {}
    return false;
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
        // Fedora/RHEL NON pacchettabile libayatana-appindicator-gtk3 nei repo
        // ufficiali (solo la variante gtk2): il pacchetto "libappindicator-gtk3"
        // del vecchio comando NON esiste → dnf falliva sempre. Restituire null
        // fa mostrare il messaggio corretto: la tray su Fedora si usa con
        // l'AppImage (le librerie sono bundled).
        return null;
      }
      if (info.hasPacman || dist.contains('arch') || dist.contains('manjaro')) {
        return 'pacman -Sy --noconfirm libappindicator-gtk3';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Installa le dipendenze del system tray (richiede sudo).
  ///
  /// Ritorna sempre una mappa con `success` e un `code` macchina leggibile:
  /// `ok` | `unsupported` | `no-password` | `wrong-password` | `locked` | `error`
  /// (il `message` è solo un dettaglio tecnico: la UI lo traduce via `code`).
  static Future<Map<String, dynamic>> installSystemTrayDependencies() async {
    final cmd = await getSystemTrayInstallCommand();
    if (cmd == null) {
      return {'success': false, 'code': 'unsupported', 'message': 'Distribuzione non supportata per installazione automatica.'};
    }
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      return {'success': false, 'code': 'no-password', 'message': 'Salva la password nelle impostazioni per consentire l\'installazione.'};
    }
    final escaped = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll("'", "\\'");
    try {
      final result = await runProcess(
        'bash',
        ['-c', 'printf "%s\\n" "$escaped" | sudo -S bash -c "$cmd" 2>&1'],
        runInShell: true,
        timeout: const Duration(seconds: 300),
      );
      if (result.exitCode == 0) {
        return {'success': true, 'code': 'ok', 'message': 'Dipendenze installate.', 'output': result.stdout.toString()};
      }
      final err = (result.stderr?.toString() ?? '').trim();
      final out = (result.stdout?.toString() ?? '').trim();
      final blob = '$err\n$out';
      String code;
      if (blob.contains('incorrect password') || blob.contains('wrong password') || blob.contains('Sorry, try again')) {
        code = 'wrong-password';
      } else if (blob.contains('Could not lock') ||
          blob.contains('Unable to acquire') ||
          blob.contains('is another process') ||
          blob.contains('dpkg lock')) {
        code = 'locked';
      } else {
        code = 'error';
      }
      final detail = err.isNotEmpty ? err : (out.isNotEmpty ? out : 'Errore sconosciuto durante l\'installazione.');
      return {'success': false, 'code': code, 'message': detail};
    } catch (e) {
      return {'success': false, 'code': 'error', 'message': e.toString()};
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

  /// Assicura che i repository della distribuzione siano configurati.
  /// Utile prima di installare pacchetti su qualsiasi distribuzione.
  static Future<Map<String, dynamic>> ensureRepositories() async {
    try {
      final info = await SystemDetector.detectSystem();
      final updateCmd = RepositoryManager.getUpdateCacheCommand(info);
      // Verifica se i repository sono già sani prima di sovrascriverli
      final reposHealthy = await RepositoryManager.areRepositoriesHealthy();
      if (!reposHealthy) {
        final result = await RepositoryManager.restoreRepositories();
        if (result['success'] == true && updateCmd != null) {
          final password = await PasswordStorage.getPassword();
          if (password != null && password.isNotEmpty) {
            final escaped = password
                .replaceAll('\\', '\\\\')
                .replaceAll('"', '\\"')
                .replaceAll('\$', '\\\$')
                .replaceAll('`', '\\`');
            try {
              await runProcess(
                'bash',
                ['-c', 'printf "%s\\n" "$escaped" | sudo -S bash -c \'${updateCmd.replaceAll("'", "'\\''")}\''],
                runInShell: true,
                timeout: const Duration(seconds: 300),
              );
            } catch (_) {}
          }
        }
        return result;
      }
      // Repository già corretti, aggiorna solo la cache
      if (updateCmd != null) {
        final password = await PasswordStorage.getPassword();
        if (password != null && password.isNotEmpty) {
          final escaped = password
              .replaceAll('\\', '\\\\')
              .replaceAll('"', '\\"')
              .replaceAll('\$', '\\\$')
              .replaceAll('`', '\\`');
          try {
            await runProcess(
              'bash',
              ['-c', 'printf "%s\\n" "$escaped" | sudo -S bash -c \'${updateCmd.replaceAll("'", "'\\''")}\''],
              runInShell: true,
              timeout: const Duration(seconds: 300),
            );
          } catch (_) {}
        }
      }
      return {'success': true, 'message': 'Repository già configurati correttamente.', 'output': ''};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
