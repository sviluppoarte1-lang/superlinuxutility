import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../models/smart_info.dart';
import 'password_storage.dart';

/// Profilo comportamentale SMART specifico per ogni distribuzione Linux.
/// Ogni distro ha regole diverse per: rilevamento dischi, permessi, tipi device.
class SmartDistroProfile {
  /// ID della distribuzione rilevata
  final String id;

  /// Nome leggibile della famiglia
  final String familyName;

  // === DISCOVERY ===
  /// Usa lsblk come metodo primario di discovery (universale, non serve sudo)
  final bool lsblkPrimary;

  /// Usa smartctl --scan come metodo secondario (serve sudo, scopre NVMe/RAID)
  final bool smartctlScanSecondary;

  /// Prova smartctl --scan senza sudo durante discovery
  final bool trySmartctlScanNoSudo;

  // === READING (getSmartInfo) ===
  /// true = prova sudo prima, poi no-sudo; false = prova no-sudo prima, poi sudo
  final bool sudoFirstForReading;

  // === DEVICE TYPES ===
  /// Tipi device da provare per dischi SATA/SCSI
  final List<String?> satDeviceTypeVariants;

  /// Tipi device da provare per dischi NVMe
  final List<String?> nvmeDeviceTypeVariants;

  /// Timeout per smartctl (secondi)
  final int smartctlTimeoutSeconds;

  const SmartDistroProfile({
    required this.id,
    required this.familyName,
    this.lsblkPrimary = true,
    this.smartctlScanSecondary = true,
    this.trySmartctlScanNoSudo = false,
    this.sudoFirstForReading = false,
    this.satDeviceTypeVariants = const [null, 'sat', 'auto'],
    this.nvmeDeviceTypeVariants = const [null, 'nvme'],
    this.smartctlTimeoutSeconds = 10,
  });

  // === PROFILES PREDEFINITI PER FAMIGLIA ===

  /// Ubuntu/Zorin/Mint/Pop/elementary/KDE neon:
  /// - lsblk primario (non serve sudo per discovery)
  /// - smartctl --scan secondario (con sudo)
  /// - sudo prima per lettura (Ubuntu richiede root quasi sempre)
  static const ubuntuFamily = SmartDistroProfile(
    id: 'ubuntu',
    familyName: 'Ubuntu Family',
    lsblkPrimary: true,
    smartctlScanSecondary: true,
    trySmartctlScanNoSudo: true,
    sudoFirstForReading: true,
    satDeviceTypeVariants: [null, 'sat', 'auto'],
    smartctlTimeoutSeconds: 10,
  );

  /// Debian/Kali/MX/Deepin/Parrot/Devuan/antiX/Raspbian/Armbian:
  /// - lsblk primario (smartctl --scan rotto su Debian)
  /// - smartctl --scan secondario per NVMe/RAID
  /// - sudo prima per lettura
  static const debianFamily = SmartDistroProfile(
    id: 'debian',
    familyName: 'Debian Family',
    lsblkPrimary: true,
    smartctlScanSecondary: true,
    trySmartctlScanNoSudo: false,
    sudoFirstForReading: true,
    satDeviceTypeVariants: [null, 'sat', 'auto'],
    smartctlTimeoutSeconds: 10,
  );

  /// Fedora/RHEL/CentOS/Rocky/AlmaLinux:
  /// - lsblk primario
  /// - smartctl --scan spesso funziona senza sudo
  /// - no-sudo prima, poi sudo
  static const fedoraFamily = SmartDistroProfile(
    id: 'fedora',
    familyName: 'Fedora Family',
    lsblkPrimary: true,
    smartctlScanSecondary: true,
    trySmartctlScanNoSudo: true,
    sudoFirstForReading: false,
    satDeviceTypeVariants: [null, 'sat', 'auto'],
    smartctlTimeoutSeconds: 10,
  );

  /// Arch/Manjaro/CachyOS/EndeavourOS/Garuda:
  /// - lsblk primario
  /// - smartctl --scan spesso funziona senza sudo
  /// - no-sudo prima, poi sudo
  static const archFamily = SmartDistroProfile(
    id: 'arch',
    familyName: 'Arch Family',
    lsblkPrimary: true,
    smartctlScanSecondary: true,
    trySmartctlScanNoSudo: true,
    sudoFirstForReading: false,
    satDeviceTypeVariants: [null, 'sat', 'auto'],
    smartctlTimeoutSeconds: 10,
  );

  /// openSUSE:
  /// - lsblk primario
  /// - sudo prima (come Debian)
  static const opensuseFamily = SmartDistroProfile(
    id: 'opensuse',
    familyName: 'openSUSE Family',
    lsblkPrimary: true,
    smartctlScanSecondary: true,
    trySmartctlScanNoSudo: true,
    sudoFirstForReading: true,
    satDeviceTypeVariants: [null, 'sat', 'auto'],
    smartctlTimeoutSeconds: 10,
  );

  /// Sconosciuta: prova tutto, sudo prima (più sicuro)
  static const unknown = SmartDistroProfile(
    id: 'unknown',
    familyName: 'Unknown',
    lsblkPrimary: true,
    smartctlScanSecondary: true,
    trySmartctlScanNoSudo: true,
    sudoFirstForReading: true,
    satDeviceTypeVariants: [null, 'sat', 'auto'],
    smartctlTimeoutSeconds: 10,
  );
}

/// Codici errore localizzabili restituiti dai metodi di SmartService.
/// La UI traduce i codici tramite [SmartService.localizeError].
abstract final class SmartErrors {
  static const String noPassword = 'smartErrNoPassword';
  static const String wrongPassword = 'smartErrWrongPassword';
  static const String passwordRequired = 'smartErrPasswordRequired';
  static const String passwordTimeout = 'smartErrPasswordTimeout';
  static const String passwordGeneric = 'smartErrPasswordGeneric';
  static const String sudo = 'smartErrSudo';
  static const String unsupportedPm = 'smartErrUnsupportedPm';
  static const String unexpected = 'smartErrUnexpected';
  static const String aptLock = 'smartErrAptLock';
  static const String aptNoRepos = 'smartErrAptNoRepos';
  static const String aptUpdateFailed = 'smartErrAptUpdateFailed';
  static const String dpkgInterrupted = 'smartErrDpkgInterrupted';
  static const String gpgUnauthenticated = 'smartErrGpgUnauthenticated';
  static const String installFailed = 'smartErrInstallFailed';
  static const String notFoundAfterInstall = 'smartErrNotFoundAfterInstall';
}

class SmartService {
  static bool? _smartmontoolsInstalled;
  static DateTime? _smartmontoolsCheckedAt;
  static List<SmartDisk>? _disksCache;
  static DateTime? _disksCachedAt;
  static SmartDistroProfile? _cachedStrategy;

  /// Percorso assoluto di smartctl (risolto una volta, usato ovunque).
  /// Fondamentale quando l'app viene lanciata da .desktop con PATH ridotto.
  static String? _smartctlPath;

  /// Comando smartctl con percorso assoluto se disponibile.
  static String get _smartctlCmd => _smartctlPath ?? 'smartctl';

  /// Ambiente con PATH esteso per sopperire a lanci da .desktop (PATH=/usr/bin:/bin,
  /// senza /usr/sbin). Usato in tutti i Process.run per garantire che comandi come
  /// lsblk, smartctl, lspci, ecc. siano trovati indipendentemente dal contesto.
  static Map<String, String> _envWithPATH() {
    final env = Map<String, String>.from(Platform.environment);
    final existing = env['PATH'] ?? '';
    final extras = [
      '/usr/sbin',
      '/usr/local/sbin',
      '/usr/bin',
      '/usr/local/bin',
      '/bin',
      '/snap/bin',
    ];
    final parts = <String>[];
    for (final e in extras) {
      if (!existing.contains(e)) parts.add(e);
    }
    if (parts.isNotEmpty) {
      env['PATH'] = '$existing:${parts.join(':')}';
    }
    return env;
  }

  static void _log(String msg) {
    stderr.writeln('[SMART] $msg');
    try {
      File('/tmp/smart_debug.log').writeAsStringSync(
        '${DateTime.now().toIso8601String()} $msg\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  static Future<SmartDistroProfile> _detectStrategy() async {
    if (_cachedStrategy != null) return _cachedStrategy!;
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        String id = '';
        String idLike = '';
        String idVersionLike = '';
        for (final line in content.split('\n')) {
          if (line.startsWith('ID=')) {
            id = line.substring(3).replaceAll('"', '').trim().toLowerCase();
          }
          if (line.startsWith('ID_LIKE=')) {
            idLike = line.substring(8).replaceAll('"', '').trim().toLowerCase();
          }
          if (line.startsWith('VERSION_CODENAME=') || line.startsWith('UBUNTU_CODENAME=')) {
            final val = line.split('=').skip(1).join('=').replaceAll('"', '').trim().toLowerCase();
            if (val.isNotEmpty) idVersionLike = val;
          }
        }

        // === UBUNTU FAMILY ===
        // Ubuntu, Zorin, Linux Mint, Pop!_OS, elementary OS, KDE neon, Peppermint, LXLE, Netrunner
        if (id == 'ubuntu' || id == 'zorin' || id == 'linuxmint' ||
            id == 'pop' || id == 'elementary' || id == 'neon' ||
            id == 'peppermint' || id == 'lxle' || id == 'netrunner' ||
            id == 'kubuntu' || id == 'xubuntu' || id == 'lubuntu' ||
            id == 'edubuntu' || id == 'mythbuntu' || id == 'budgie' ||
            idLike.contains('ubuntu') || idVersionLike.contains('jammy') ||
            idVersionLike.contains('noble') || idVersionLike.contains('mantic') ||
            idVersionLike.contains('lunar') || idVersionLike.contains('kinetic')) {
          _cachedStrategy = SmartDistroProfile.ubuntuFamily;
          _log('_detectStrategy: Ubuntu family ($id)');
          return _cachedStrategy!;
        }

        // === DEBIAN FAMILY ===
        // Debian, Kali, Deepin, MX Linux, Parrot, Devuan, antiX, Raspbian, Armbian,
        // Sparky, Voyager, Q4OS, MakuluLinux, SpiralLinux, PeuxOS
        if (id == 'debian' || id == 'kali' || id == 'deepin' ||
            id == 'mx' || id == 'parrot' || id == 'devuan' ||
            id == 'antix' || id == 'raspbian' || id == 'armbian' ||
            id == 'sparky' || id == 'voyager' || id == 'q4os' ||
            id == 'makululinux' || id == 'spiralinux' || id == 'peuxos' ||
            id == 'puppy' || id == 'salix' || id == 'slackel' ||
            id == 'pisi' || id == 'kanotix' || id == 'damnsmall' ||
            idLike.contains('debian')) {
          _cachedStrategy = SmartDistroProfile.debianFamily;
          _log('_detectStrategy: Debian family ($id)');
          return _cachedStrategy!;
        }

        // === FEDORA FAMILY ===
        // Fedora, RHEL, CentOS, Rocky, AlmaLinux, Nobara, Ultramarine, Brownie
        if (id == 'fedora' || id == 'rhel' || id == 'centos' ||
            id == 'rocky' || id == 'almalinux' || id == 'nobara' ||
            id == 'ultramarine' || id == 'brownie' || id == 'roka' ||
            id == 'bazzite' || id == 'flagon' || id == 'vanilla' ||
            idLike.contains('rhel') || idLike.contains('fedora')) {
          _cachedStrategy = SmartDistroProfile.fedoraFamily;
          _log('_detectStrategy: Fedora family ($id)');
          return _cachedStrategy!;
        }

        // === ARCH FAMILY ===
        // Arch, Manjaro, CachyOS, EndeavourOS, Garuda, Artix, Parabola, KaOS
        if (id == 'arch' || id == 'archlinux' || id == 'manjaro' ||
            id == 'endeavouros' || id == 'garuda' || id == 'cachyos' ||
            id == 'artix' || id == 'parabola' || id == 'kaos' ||
            id == 'bluestar' || id == 'archcraft' || id == 'archbang' ||
            id == 'archyte' || id == 'rebirth' || id == 'instantos' ||
            idLike.contains('arch')) {
          _cachedStrategy = SmartDistroProfile.archFamily;
          _log('_detectStrategy: Arch family ($id)');
          return _cachedStrategy!;
        }

        // === OPENSUSE FAMILY ===
        if (id == 'opensuse-tumbleweed' || id == 'opensuse-leap' ||
            id == 'opensuse' || id == 'suse' || id == 'sles' ||
            idLike.contains('suse')) {
          _cachedStrategy = SmartDistroProfile.opensuseFamily;
          _log('_detectStrategy: openSUSE family ($id)');
          return _cachedStrategy!;
        }
      }
    } catch (e) {
      _log('_detectStrategy: error: $e');
    }
    _cachedStrategy = SmartDistroProfile.unknown;
    _log('_detectStrategy: unknown distro, using fallback');
    return _cachedStrategy!;
  }

  /// Normalizza percorsi NVMe: /dev/nvme0n1 → /dev/nvme0 (namespace → controller).
  /// Usato per deduplicare dispositivi NVMe rilevati da lsblk (namespace) e smartctl (controller).
  static String _normalizeNvmePath(String dev) {
    final m = RegExp(r'^(/dev/nvme\d+)n\d+$').firstMatch(dev);
    if (m != null) return m.group(1)!;
    return dev;
  }

  static Future<ProcessResult> _runSudoCommand(String command, {Duration timeout = const Duration(seconds: 10)}) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    final escapedPassword = _escapeForBashDoubleQuote(password);
    // Usa printf con singolo \n per gestire correttamente password con nuove linee
    // -p "" sopprime il prompt "[sudo] password per USER:" che corromperebbe stdout JSON
    final fullCommand = 'printf "%s\\n" "$escapedPassword" | sudo -p "" -S $command 2>&1';
    _log('_runSudoCommand: ${command.substring(0, command.length.clamp(0, 120))}');
    try {
      final result = await Process.run('bash', ['-c', fullCommand], runInShell: true, environment: _envWithPATH())
          .timeout(timeout);
      final out = (result.stdout as String?) ?? '';
      final err = (result.stderr as String?) ?? '';
      _log('_runSudoCommand: exit=${result.exitCode} out_len=${out.length} err_len=${err.length}');
      if (out.isNotEmpty) {
        _log('_runSudoCommand: out_preview=${out.substring(0, out.length.clamp(0, 300))}');
      }
      if (err.isNotEmpty) {
        _log('_runSudoCommand: err_preview=${err.substring(0, err.length.clamp(0, 200))}');
      }
      return result;
    } on TimeoutException {
      _log('_runSudoCommand: timed out after ${timeout.inSeconds}s');
      return ProcessResult(0, -1, '', 'Comando timeout dopo ${timeout.inSeconds}s');
    }
  }

  /// Valida la password sudo eseguendo `sudo -v`. Ritorna null se valida, altrimenti codice errore localizzabile.
  static Future<String?> validateSudoPassword() async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      return SmartErrors.noPassword;
    }
    final escapedPassword = _escapeForBashDoubleQuote(password);
    try {
      final r = await Process.run('bash', [
        '-c', 'printf "%s\\n" "$escapedPassword" | sudo -p "" -S -v 2>&1',
      ], environment: _envWithPATH()).timeout(const Duration(seconds: 5));
      if (r.exitCode == 0) return null;
      final stderr = (r.stderr as String).trim();
      final stdout = (r.stdout as String).trim();
      if (stderr.contains('incorrect password') || stderr.contains('wrong password') ||
          stdout.contains('incorrect password') || stdout.contains('wrong password')) {
        return SmartErrors.wrongPassword;
      }
      if (stderr.contains('a password is required') || stdout.contains('a password is required')) {
        return SmartErrors.passwordRequired;
      }
      return '${SmartErrors.sudo}:${stderr.isNotEmpty ? stderr : stdout}'.trim();
    } on TimeoutException {
      return SmartErrors.passwordTimeout;
    } catch (e) {
      return '${SmartErrors.passwordGeneric}:$e';
    }
  }

  /// Escape sicuro per uso dentro double-quote bash.
  /// Gestisce: backslash, doppio apice, dollaro, backtick, newlines, singolo apice.
  static String _escapeForBashDoubleQuote(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll("'", "\\'");
  }

  /// Result of ensureSmartctlAvailable with error details
  static Future<SmartctlInstallResult> ensureSmartctlAvailableDetailed() async {
    if (_smartmontoolsInstalled != null &&
        _smartmontoolsCheckedAt != null &&
        DateTime.now().difference(_smartmontoolsCheckedAt!) < const Duration(minutes: 5)) {
      return SmartctlInstallResult(success: _smartmontoolsInstalled!, error: null);
    }
    _smartmontoolsCheckedAt = DateTime.now();

    // 1. Se abbiamo già risolto il percorso, verifica che esista ancora
    if (_smartctlPath != null && await File(_smartctlPath!).exists()) {
      _smartmontoolsInstalled = true;
      return SmartctlInstallResult(success: true, error: null);
    }

    // 2. Cerca smartctl in PATH tramite which
    try {
      final env = _envWithPATH();
      final envPath = env['PATH'] ?? '(unset)';
      _log('ensureSmartctlAvailable: PATH=$envPath');
      final r = await Process.run('which', ['smartctl'], environment: env);
      _log('ensureSmartctlAvailable: which smartctl exit=${r.exitCode} out="${(r.stdout as String).trim()}"');
      if (r.exitCode == 0) {
        final path = (r.stdout as String).trim();
        if (path.isNotEmpty) {
          _smartctlPath = path;
          _smartmontoolsInstalled = true;
          return SmartctlInstallResult(success: true, error: null);
        }
      }
    } catch (e) {
      _log('ensureSmartctlAvailable: which smartctl exception: $e');
    }

    // 3. Cerca smartctl nei percorsi comuni (funziona anche da .desktop con PATH ridotto)
    const commonPaths = [
      '/usr/sbin/smartctl',
      '/usr/local/sbin/smartctl',
      '/usr/bin/smartctl',
      '/usr/local/bin/smartctl',
      '/snap/bin/smartctl',
    ];
    for (final p in commonPaths) {
      if (await File(p).exists()) {
        _smartctlPath = p;
        _smartmontoolsInstalled = true;
        _log('ensureSmartctlAvailable: found at $p (common path)');
        return SmartctlInstallResult(success: true, error: null);
      }
    }

    // 4. smartctl non trovato: prova a installare
    final pwdError = await validateSudoPassword();
    if (pwdError != null) {
      _smartmontoolsInstalled = false;
      _log('ensureSmartctlAvailable: password validation failed: $pwdError');
      return SmartctlInstallResult(success: false, error: pwdError);
    }
    try {
      final pm = await PackageManager.detect();
      _log('ensureSmartctlAvailable: detected package manager ${pm.name}');
      String? installError;
      if (pm == PackageManager.apt) {
        installError = await _installViaApt();
      } else if (pm == PackageManager.dnf) {
        installError = await _installViaDnf();
      } else if (pm == PackageManager.pacman) {
        installError = await _installViaPacman();
      } else {
        return SmartctlInstallResult(success: false, error: SmartErrors.unsupportedPm);
      }
      if (installError != null) {
        _smartmontoolsInstalled = false;
        _log('ensureSmartctlAvailable: install failed: $installError');
        return SmartctlInstallResult(success: false, error: installError);
      }
      // After install, check smartctl again (maybe in different PATH)
      final r2 = await Process.run('which', ['smartctl'], environment: _envWithPATH());
      _log('ensureSmartctlAvailable: post-install which smartctl exit=${r2.exitCode}');
      if (r2.exitCode != 0) {
        // Fallback 1: check common paths directly
        for (final p in ['/usr/sbin/smartctl', '/usr/bin/smartctl', '/usr/local/bin/smartctl', '/snap/bin/smartctl']) {
          if (await File(p).exists()) {
            _log('ensureSmartctlAvailable: found at $p, creating symlink');
            await _runSudoCommand('ln -sf "$p" /usr/local/bin/smartctl');
            _smartctlPath = p;
            _smartmontoolsInstalled = true;
            return SmartctlInstallResult(success: true, error: null);
          }
        }
        // Fallback 2: use dpkg -L to find actual installed path
        try {
          final dpkgR = await Process.run('bash', ['-c', 'dpkg -L smartmontools 2>/dev/null | grep smartctl'], environment: _envWithPATH());
          _log('ensureSmartctlAvailable: dpkg -L smartmontools: ${(dpkgR.stdout as String).trim()}');
          if (dpkgR.exitCode == 0) {
            final paths = (dpkgR.stdout as String).trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
            for (final p in paths) {
              if (await File(p).exists()) {
                _log('ensureSmartctlAvailable: dpkg found at $p');
                await _runSudoCommand('ln -sf "$p" /usr/local/bin/smartctl');
                _smartctlPath = p;
                _smartmontoolsInstalled = true;
                return SmartctlInstallResult(success: true, error: null);
              }
            }
          }
        } catch (_) {}
        _smartmontoolsInstalled = false;
        return SmartctlInstallResult(success: false, error: SmartErrors.notFoundAfterInstall);
      }
      _smartmontoolsInstalled = true;
      return SmartctlInstallResult(success: true, error: null);
    } catch (e) {
      _smartmontoolsInstalled = false;
      _log('ensureSmartctlAvailable: unexpected error: $e');
      return SmartctlInstallResult(success: false, error: '${SmartErrors.unexpected}:$e');
    }
  }

  /// Install smartmontools via apt, ritorna null se ok, altrimenti messaggio errore
  static Future<String?> _installViaApt() async {
    // Aggiorna cache prima di installare (Debian 13 potrebbe avere repo non aggiornati)
    _log('_installViaApt: running apt-get update...');
    final updateResult = await _runSudoCommand('apt-get update -qq', timeout: const Duration(seconds: 60));
    _log('_installViaApt: apt-get update exit=${updateResult.exitCode}');
    if (updateResult.exitCode != 0) {
      final err = (updateResult.stderr as String).trim();
      final out = (updateResult.stdout as String).trim();
      _log('_installViaApt: apt-get update failed (exit=${updateResult.exitCode}): $err $out');
      if (err.contains('Could not lock') || out.contains('Could not lock')) {
        return SmartErrors.aptLock;
      }
      if (err.contains('404') || err.contains('Unable to locate package') || out.contains('Unable to locate package')) {
        return SmartErrors.aptNoRepos;
      }
      return '${SmartErrors.aptUpdateFailed}:${err.isNotEmpty ? err : out}';
    }
    _log('_installViaApt: running apt-get install...');
    final r = await _runSudoCommand('apt-get install -y smartmontools', timeout: const Duration(seconds: 120));
    _log('_installViaApt: apt-get install exit=${r.exitCode}');
    if (r.exitCode != 0) {
      final err = (r.stderr as String).trim();
      final out = (r.stdout as String).trim();
      _log('_installViaApt: apt-get install failed (exit=${r.exitCode}): $err $out');
      if (err.contains('dpkg was interrupted') || out.contains('dpkg was interrupted')) {
        return SmartErrors.dpkgInterrupted;
      }
      if (err.contains('not authenticated') || out.contains('not authenticated')) {
        return SmartErrors.gpgUnauthenticated;
      }
      return '${SmartErrors.installFailed}:${err.isNotEmpty ? err : out}';
    }
    // Verifica che smartctl sia effettivamente installato
    final checkR = await Process.run('which', ['smartctl'], environment: _envWithPATH());
    _log('_installViaApt: which smartctl exit=${checkR.exitCode} out="${(checkR.stdout as String).trim()}" err="${(checkR.stderr as String).trim()}"');
    if (checkR.exitCode != 0) {
      // Prova anche con percorso assoluto
      final altCheck = await Process.run('bash', ['-c', 'ls -la /usr/sbin/smartctl /usr/bin/smartctl 2>&1'], environment: _envWithPATH());
      _log('_installViaApt: direct ls check: ${(altCheck.stdout as String).trim()}');
      // Prova a cercare ovunque
      final findR = await Process.run('bash', ['-c', 'find / -name smartctl -type f 2>/dev/null | head -5'], environment: _envWithPATH());
      _log('_installViaApt: find smartctl: ${(findR.stdout as String).trim()}');
      if (findR.exitCode == 0 && (findR.stdout as String).trim().isNotEmpty) {
        final foundPath = (findR.stdout as String).trim().split('\n').first;
        _log('_installViaApt: smartctl found at $foundPath but not in PATH');
        // Crea un symlink se trovato in percorso non standard
        final lnResult = await _runSudoCommand('ln -sf "$foundPath" /usr/local/bin/smartctl');
        _log('_installViaApt: symlink creation exit=${lnResult.exitCode}');
        if (lnResult.exitCode == 0) {
          return null; // symlink creato con successo
        }
      }
      return SmartErrors.notFoundAfterInstall;
    }
    return null;
  }

  /// Install smartmontools via dnf, ritorna null se ok, altrimenti codice errore localizzabile
  static Future<String?> _installViaDnf() async {
    final r = await _runSudoCommand('dnf install -y smartmontools', timeout: const Duration(seconds: 120));
    if (r.exitCode != 0) {
      final err = (r.stderr as String).trim();
      final out = (r.stdout as String).trim();
      return '${SmartErrors.installFailed}:${err.isNotEmpty ? err : out}';
    }
    return null;
  }

  /// Install smartmontools via pacman, ritorna null se ok, altrimenti codice errore localizzabile
  static Future<String?> _installViaPacman() async {
    final r = await _runSudoCommand('pacman -S --noconfirm smartmontools', timeout: const Duration(seconds: 120));
    if (r.exitCode != 0) {
      final err = (r.stderr as String).trim();
      final out = (r.stdout as String).trim();
      return '${SmartErrors.installFailed}:${err.isNotEmpty ? err : out}';
    }
    return null;
  }

  static Future<bool> ensureSmartctlAvailable() async {
    final result = await ensureSmartctlAvailableDetailed();
    return result.success;
  }

  /// Traduce un codice errore SMART nel messaggio localizzato.
  /// I codici possono includere dettaglio dinamico nel formato `codice:dettaglio`.
  static String localizeError(AppLocalizations l10n, String? code) {
    if (code == null || code.isEmpty) return l10n.smartInstallFailed;
    final sep = code.indexOf(':');
    final c = sep == -1 ? code : code.substring(0, sep);
    final detail = sep == -1 ? null : code.substring(sep + 1);
    switch (c) {
      case SmartErrors.noPassword:
        return l10n.smartErrNoPassword;
      case SmartErrors.wrongPassword:
        return l10n.smartErrWrongPassword;
      case SmartErrors.passwordRequired:
        return l10n.smartErrPasswordRequired;
      case SmartErrors.passwordTimeout:
        return l10n.smartErrPasswordTimeout;
      case SmartErrors.passwordGeneric:
        return l10n.smartErrPasswordGeneric(detail ?? '');
      case SmartErrors.sudo:
        return l10n.smartErrSudo(detail ?? '');
      case SmartErrors.unsupportedPm:
        return l10n.smartErrUnsupportedPm;
      case SmartErrors.unexpected:
        return l10n.smartErrUnexpected(detail ?? '');
      case SmartErrors.aptLock:
        return l10n.smartErrAptLock;
      case SmartErrors.aptNoRepos:
        return l10n.smartErrAptNoRepos;
      case SmartErrors.aptUpdateFailed:
        return l10n.smartErrAptUpdateFailed(detail ?? '');
      case SmartErrors.dpkgInterrupted:
        return l10n.smartErrDpkgInterrupted;
      case SmartErrors.gpgUnauthenticated:
        return l10n.smartErrGpgUnauthenticated;
      case SmartErrors.installFailed:
        return l10n.smartErrInstallFailed(detail ?? '');
      case SmartErrors.notFoundAfterInstall:
        return l10n.smartErrNotFoundAfterInstall;
      default:
        return code;
    }
  }

  /// Reset cache per permettere retry dopo fallimento
  static void resetSmartctlCache() {
    _smartmontoolsInstalled = null;
    _smartmontoolsCheckedAt = null;
    _smartctlPath = null;
  }

  static final Map<String, SmartInfo> _smartInfoCacheMap = {};
  static DateTime? _smartInfoCacheTimestamp;

  static const List<String> _usbVariants = [
    '',          // senza -d (auto-rilevamento)
    'sat',       // come rilevato da --scan
    'sat,16',
    'sat,12',
    'usbjmicron',
    'usbprolific',
    'usbcypress',
    'usbsunplus',
  ];
  static final Map<String, int> _usbNextVariant = {};
  static final Map<String, String?> _usbWorkingVariant = {};

  static const String _usbVariantPrefsKey = 'smart_usb_variants';

  static Future<void> _loadPersistedVariants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_usbVariantPrefsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in map.entries) {
          _usbWorkingVariant[entry.key] = entry.value as String?;
        }
        _log('_loadPersistedVariants: loaded ${map.length} variants');
      }
    } catch (_) {}
  }

  static Future<void> _savePersistedVariants() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, String>{};
      for (final entry in _usbWorkingVariant.entries) {
        if (entry.value != null) {
          map[entry.key] = entry.value!;
        }
      }
      await prefs.setString(_usbVariantPrefsKey, jsonEncode(map));
    } catch (_) {}
  }

  static void invalidateCache() {
    _disksCache = null;
    _disksCachedAt = null;
    _smartInfoCacheMap.clear();
    _smartInfoCacheTimestamp = null;
    _usbNextVariant.clear();
    _usbWorkingVariant.clear();
    _smartctlPath = null;
    _smartmontoolsInstalled = null;
    _smartmontoolsCheckedAt = null;
  }

  static Future<List<SmartDisk>> scanDisks() async {
    await _loadPersistedVariants();

    if (_disksCache != null && _disksCachedAt != null &&
        DateTime.now().difference(_disksCachedAt!) < const Duration(minutes: 2)) {
      _log('scanDisks: using cache (${_disksCache!.length} disks)');
      return _disksCache!;
    }
    final disks = <SmartDisk>[];
    final foundDevices = <String>{};

    try {
      if (!await ensureSmartctlAvailable()) {
        _log('scanDisks: smartctl not available');
        return disks;
      }

      final profile = await _detectStrategy();
      _log('scanDisks: profile=${profile.familyName} (${profile.id})');

      // === FASE 1: lsblk (universale, non serve sudo) ===
      // lsblk è il metodo più affidabile: funziona su TUTTE le distro
      // e non richiede permessi root
      if (profile.lsblkPrimary) {
        _log('scanDisks: phase 1 - lsblk discovery');
        await _discoverViaLsblk(disks, foundDevices);
        _log('scanDisks: after lsblk: ${disks.length} disks');
      }

      // === FASE 2: smartctl --scan (solo quando lsblk trova pochi dischi) ===
      // lsblk è universale: trova SATA, NVMe, USB su tutte le distro.
      // smartctl --scan serve per RAID/SCSI e dispositivi speciali.
      // Se lsblk ha trovato 2+ dischi, li abbiamo tutti — salta smartctl --scan.
      if (disks.isEmpty && profile.smartctlScanSecondary) {
        // Nessun disco da lsblk: prova smartctl --scan per trovare tutto
        if (profile.trySmartctlScanNoSudo) {
          _log('scanDisks: phase 2a - smartctl --scan (no sudo)');
          await _discoverViaSmartctlScanNoSudo(disks, foundDevices);
        }
        _log('scanDisks: phase 2b - smartctl --scan (sudo)');
        await _discoverViaSmartctlScan(disks, foundDevices);
      } else if (disks.isNotEmpty && disks.length <= 1 && profile.smartctlScanSecondary) {
        // Un solo disco: prova smartctl --scan solo con sudo per trovare RAID
        _log('scanDisks: phase 2 - smartctl --scan (sudo, 1 disk found)');
        await _discoverViaSmartctlScan(disks, foundDevices);
      }

      // === FASE 3: /sys/block fallback ===
      if (disks.isEmpty) {
        _log('scanDisks: no disks found, trying /sys/block fallback');
        await _discoverViaSysBlock(disks, foundDevices);
      }
    } catch (e) {
      _log('scanDisks: top-level error: $e');
    }
    _disksCache = disks;
    _disksCachedAt = DateTime.now();
    _log('scanDisks: returning ${disks.length} disks');
    return disks;
  }

  // ============================================================
  // Discovery: smartctl --scan
  // ============================================================

  /// Scopre dischi via smartctl --scan con sudo
  static Future<void> _discoverViaSmartctlScan(List<SmartDisk> disks, Set<String> foundDevices) async {
    try {
      final r = await _runSudoCommand('$_smartctlCmd --scan 2>/dev/null', timeout: const Duration(seconds: 15));
      final lines = (r.stdout as String).split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _log('_discoverViaSmartctlScan (sudo): found ${lines.length} devices');
      for (final line in lines) {
        try {
          final devMatch = RegExp(r'^(/dev/[^\s]+)').firstMatch(line);
          if (devMatch == null) continue;
          final dev = devMatch.group(1)!;
          final normalized = _normalizeNvmePath(dev);
          if (foundDevices.any((d) => _normalizeNvmePath(d) == normalized)) continue;
          if (foundDevices.contains(dev)) continue;
          final typeMatch = RegExp(r'-d\s+(\S+)').firstMatch(line);
          final deviceType = typeMatch?.group(1);
          foundDevices.add(dev);

          String iface = 'Unknown';
          if (deviceType == 'nvme' || dev.contains('nvme')) { iface = 'NVMe'; }
          else if (deviceType == 'sat' || deviceType == 'auto') { iface = 'SATA'; }
          disks.add(SmartDisk(device: dev, model: dev, interface: iface, deviceType: deviceType));
          _log('_discoverViaSmartctlScan (sudo): $dev (type=$deviceType)');
        } catch (e) {
          _log('_discoverViaSmartctlScan (sudo): error parsing line: $e');
        }
      }
    } catch (e) {
      _log('_discoverViaSmartctlScan (sudo): error: $e');
    }
  }

  /// Scopre dischi via smartctl --scan SENZA sudo (funziona su Fedora/Arch/openSUSE)
  static Future<void> _discoverViaSmartctlScanNoSudo(List<SmartDisk> disks, Set<String> foundDevices) async {
    try {
      final r = await Process.run('bash', [
        '-c', '$_smartctlCmd --scan 2>/dev/null',
      ], environment: _envWithPATH())
          .timeout(const Duration(seconds: 15)).catchError((e) => ProcessResult(0, -1, '', 'timeout'));
      if (r.exitCode != 0) return;
      final lines = (r.stdout as String).split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _log('_discoverViaSmartctlScanNoSudo: found ${lines.length} devices');
      for (final line in lines) {
        try {
          final devMatch = RegExp(r'^(/dev/[^\s]+)').firstMatch(line);
          if (devMatch == null) continue;
          final dev = devMatch.group(1)!;
          final normalized = _normalizeNvmePath(dev);
          if (foundDevices.any((d) => _normalizeNvmePath(d) == normalized)) continue;
          if (foundDevices.contains(dev)) continue;
          final typeMatch = RegExp(r'-d\s+(\S+)').firstMatch(line);
          final deviceType = typeMatch?.group(1);
          foundDevices.add(dev);

          String iface = 'Unknown';
          if (deviceType == 'nvme' || dev.contains('nvme')) { iface = 'NVMe'; }
          else if (deviceType == 'sat' || deviceType == 'auto') { iface = 'SATA'; }
          disks.add(SmartDisk(device: dev, model: dev, interface: iface, deviceType: deviceType));
          _log('_discoverViaSmartctlScanNoSudo: $dev (type=$deviceType)');
        } catch (e) {
          _log('_discoverViaSmartctlScanNoSudo: error parsing line: $e');
        }
      }
    } catch (e) {
      _log('_discoverViaSmartctlScanNoSudo: error: $e');
    }
  }

  // ============================================================
  // Discovery: lsblk (universale, non serve sudo)
  // ============================================================

  /// Scopre dischi via lsblk (metodo primario, funziona su tutte le distro)
  static Future<void> _discoverViaLsblk(List<SmartDisk> disks, Set<String> foundDevices) async {
    try {
      // Prova JSON prima (più affidabile)
      final env = _envWithPATH();
      final r = await Process.run('bash', [
        '-c', 'lsblk -dJno NAME,SIZE,MODEL,SERIAL,TRAN,ROTA,TYPE 2>/dev/null',
      ], environment: env);
      _log('_discoverViaLsblk: JSON exit=${r.exitCode} stdout_len=${(r.stdout as String).length}');
      if (r.exitCode == 0) {
        final out = r.stdout as String;
        if (out.trim().isEmpty) {
          _log('_discoverViaLsblk: JSON output empty');
        } else {
          _log('_discoverViaLsblk: JSON output=${out.trim().substring(0, (out.trim().length).clamp(0, 500))}');
        }
        await _parseLsblkJson(r.stdout as String, disks, foundDevices);
        return;
      }
      // Fallback: testo semplice
      final r2 = await Process.run('bash', [
        '-c', 'lsblk -dno NAME,SIZE,MODEL,SERIAL,TRAN,ROTA,TYPE 2>/dev/null',
      ], environment: env);
      _log('_discoverViaLsblk: TEXT fallback exit=${r2.exitCode} stdout_len=${(r2.stdout as String).length}');
      if (r2.exitCode == 0) {
        _parseLsblkTextOutput(r2.stdout as String, disks, foundDevices);
      }
    } catch (e) {
      _log('_discoverViaLsblk: error: $e');
    }
  }

  /// Parse lsblk JSON output
  static Future<void> _parseLsblkJson(String jsonStr, List<SmartDisk> disks, Set<String> foundDevices) async {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final blockdevices = json['blockdevices'] as List<dynamic>? ?? [];
      _log('_parseLsblkJson: ${blockdevices.length} blockdevices found');
      for (final dev in blockdevices) {
        final name = dev['name'] as String? ?? '';
        final type = dev['type'] as String? ?? '';
        if (type != 'disk') {
          _log('_parseLsblkJson: skipping $name (type=$type)');
          continue;
        }
        final devPath = '/dev/$name';
        if (foundDevices.contains(devPath)) continue;
        final model = (dev['model'] as String?)?.trim() ?? devPath;
        final serial = (dev['serial'] as String?)?.trim();
        final tran = (dev['tran'] as String?)?.trim() ?? '';
        final rota = dev['rota'] as bool? ?? true;

        String? deviceType;
        String iface = 'Unknown';
        if (tran == 'usb') {
          deviceType = 'sat';
          iface = 'USB';
        } else if (tran == 'nvme' || name.startsWith('nvme')) {
          deviceType = 'nvme';
          iface = 'NVMe';
        } else if (tran == 'sata' || tran == 'sas') {
          iface = tran.toUpperCase();
        } else if (!rota) {
          iface = 'SSD';
        }

        _log('_parseLsblkJson: found $devPath model="$model" tran=$tran');
        foundDevices.add(devPath);
        // Non chiamare _trySmartctlInfo con sudo qui — rallenta la scansione.
        // Usa solo le info da lsblk. I dettagli SMART verranno letti in getSmartInfo.
        disks.add(SmartDisk(device: devPath, model: model, serial: serial, interface: iface, deviceType: deviceType));
      }
    } catch (e) {
      _log('_parseLsblkJson: error: $e');
    }
  }

  /// Parse lsblk text output (fallback)
  static void _parseLsblkTextOutput(String output, List<SmartDisk> disks, Set<String> foundDevices) {
    final lines = output.split('\n').where((l) => l.trim().isNotEmpty).toList();
    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final name = parts[0];
      final devPath = name.startsWith('/dev/') ? name : '/dev/$name';
      if (foundDevices.contains(devPath)) continue;
      final model = parts.length >= 3 ? parts[2] : devPath;
      final serial = parts.length >= 4 ? parts[3] : null;
      final tran = parts.length >= 5 ? parts[4] : '';
      final type = parts.length >= 7 ? parts[6] : '';
      if (type.isNotEmpty && type != 'disk') continue;

      String? deviceType;
      String iface = 'Unknown';
      if (tran == 'usb') { deviceType = 'sat'; iface = 'USB'; }
      else if (tran == 'nvme' || name.startsWith('nvme')) { deviceType = 'nvme'; iface = 'NVMe'; }
      else if (tran == 'sata' || tran == 'sas') { iface = tran.toUpperCase(); }

      _log('_parseLsblkText: found $devPath model="$model"');
      foundDevices.add(devPath);
      disks.add(SmartDisk(device: devPath, model: model, serial: serial, interface: iface, deviceType: deviceType));
    }
  }

  // ============================================================
  // Fallback: /sys/block
  // ============================================================

  static Future<void> _discoverViaSysBlock(List<SmartDisk> disks, Set<String> foundDevices) async {
    try {
      final env = _envWithPATH();
      final r = await Process.run('bash', [
        '-c', 'ls /sys/block/ 2>/dev/null | grep -E "^(sd|nvme|hd|vd|xvd|mmcblk)"',
      ], environment: env);
      _log('_discoverViaSysBlock: ls /sys/block exit=${r.exitCode}');
      if (r.exitCode != 0) return;
      final devices = (r.stdout as String).split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _log('_discoverViaSysBlock: found ${devices.length} devices: ${devices.join(", ")}');
      for (final devName in devices) {
        final devPath = '/dev/$devName';
        if (foundDevices.contains(devPath)) continue;
        if (!await File(devPath).exists()) continue;
        foundDevices.add(devPath);
        String model = devPath;
        try {
          final modelR = await Process.run('cat', ['/sys/block/$devName/device/model']);
          if (modelR.exitCode == 0) model = (modelR.stdout as String).trim();
        } catch (_) {}
        String? deviceType;
        String iface = 'Unknown';
        if (devName.startsWith('nvme')) { deviceType = 'nvme'; iface = 'NVMe'; }
        else if (devName.startsWith('sd')) { iface = 'SATA'; }
        _log('_discoverViaSysBlock: found $devPath');
        disks.add(SmartDisk(device: devPath, model: model, interface: iface, deviceType: deviceType));
      }
    } catch (e) {
      _log('_discoverViaSysBlock: error: $e');
    }
  }

  // ============================================================
  // Reading: getSmartInfo
  // ============================================================

  static Future<SmartInfo?> getSmartInfo(SmartDisk disk, {bool immediate = false}) async {
    final device = disk.device;
    try {
      if (!await ensureSmartctlAvailable()) {
        _log('getSmartInfo($device): smartctl not available');
        return null;
      }
      // Usa interface (non deviceType) per distinguere USB da SATA locale
      // deviceType='sat' viene usato sia per USB-SATA bridge che per SATA locale
      final isRealUsb = disk.interface == 'USB' || disk.interface == 'usb';
      final isNvmeDevice = disk.deviceType == 'nvme' ||
          disk.deviceType == 'sntasmedia' ||
          disk.deviceType == 'sntjmicron' ||
          disk.deviceType == 'sntrealtek';
      final isUsb = isRealUsb; // solo USB reali, non SATA locali

      // Cache hit (per-device Map)
      if (_smartInfoCacheTimestamp != null &&
          DateTime.now().difference(_smartInfoCacheTimestamp!) < const Duration(minutes: 2)) {
        final cached = _smartInfoCacheMap[device];
        if (cached != null) {
          if (!isUsb || _usbWorkingVariant[device] != null) {
            _log('getSmartInfo($device): using cache');
            return cached;
          }
        }
      }

      bool hasUsableOutput(String o) {
        if (o.isEmpty) return false;
        try {
          final j = jsonDecode(o) as Map<String, dynamic>;
          // Verifica che ci siano dati SMART effettivi.
          // NOTA: j.containsKey('smartctl') NON è sufficiente: smartctl restituisce
          // JSON con exit_status >= 2 quando fallisce (es. permission denied) ma con
          // la chiave 'smartctl' presente. Questo causava che le risposte di errore
          // fossero considerate "usabili", impedendo il fallback a sudo.
          if (j.containsKey('smart_status')) return true;
          if (j['temperature'] != null) return true;
          if (j['ata_smart_attributes'] != null) return true;
          if (j['nvme_smart_health_information_log'] != null) return true;
          if (j['scsi_smart_log'] != null) return true;
          if (j['model_family'] != null || j['model_name'] != null) return true;
          if (j['serial_number'] != null) return true;
          // smartctl con exit_status 0 o 1 ha dati utili anche senza le chiavi sopra
          if (j.containsKey('smartctl')) {
            final exitStatus = j['smartctl']?['exit_status'] as int? ?? -1;
            if (exitStatus <= 1) return true;
          }
          return false;
        } catch (_) {
          return false;
        }
      }

      // Costruisce lista comandi basata sul profilo distro
      final cmdVariants = <String>[];
      final sudoCmdVariants = <String>[];
      final profile = await _detectStrategy();

      if (isUsb) {
        // USB: usa progressive probe
        final working = _usbWorkingVariant[device];
        if (working != null) {
          final cmd = working.isEmpty
              ? '$_smartctlCmd -j -a "$device"'
              : '$_smartctlCmd -j -a -d $working "$device"';
          cmdVariants.add(cmd);
          sudoCmdVariants.add(cmd);
        } else if (immediate) {
          for (final dt in _usbVariants) {
            final cmd = dt.isEmpty
                ? '$_smartctlCmd -j -a "$device"'
                : '$_smartctlCmd -j -a -d $dt "$device"';
            cmdVariants.add(cmd);
          }
          sudoCmdVariants.addAll(List.from(cmdVariants));
        } else {
          int idx = _usbNextVariant[device] ?? 0;
          if (idx >= _usbVariants.length) {
            _log('getSmartInfo($device): USB probe exhausted');
            _usbNextVariant.remove(device);
            return null;
          }
          _usbNextVariant[device] = idx + 1;
          final dt = _usbVariants[idx];
          final cmd = dt.isEmpty
              ? '$_smartctlCmd -j -a "$device"'
              : '$_smartctlCmd -j -a -d $dt "$device"';
          cmdVariants.add(cmd);
          sudoCmdVariants.add(cmd);
        }
      } else if (isNvmeDevice) {
        // NVMe: usa le varianti del profilo
        for (final dt in profile.nvmeDeviceTypeVariants) {
          final cmd = dt != null ? '$_smartctlCmd -j -a -d $dt "$device"' : '$_smartctlCmd -j -a "$device"';
          cmdVariants.add(cmd);
          sudoCmdVariants.add(cmd);
        }
      } else {
        // SATA/SCSI: usa le varianti del profilo
        for (final dt in profile.satDeviceTypeVariants) {
          final cmd = dt != null ? '$_smartctlCmd -j -a -d $dt "$device"' : '$_smartctlCmd -j -a "$device"';
          cmdVariants.add(cmd);
          sudoCmdVariants.add(cmd);
        }
      }

      String? out;
      int exitCode = -1;
      String? usbProbeVariant;

      // Per TUTTE le distro: prova prima senza sudo (più veloce, non richiede password).
      // smartctl -j -a su /dev/sdX funziona senza sudo sulla maggior parte dei sistemi
      // perché udev concede accesso in lettura al gruppo disk.
      // Solo se fallisce si ricade su sudo.
      // USB richiede sudo quasi sempre, quindi per USB invertiamo l'ordine.
      _log('getSmartInfo($device): profile=${profile.familyName} isUsb=$isUsb');

      if (isUsb) {
        // USB: prova sudo prima (quasi sempre necessario)
        for (int i = 0; i < sudoCmdVariants.length; i++) {
          final cmd = sudoCmdVariants[i];
          _log('getSmartInfo($device): [sudo] attempt ${i+1}/${sudoCmdVariants.length}: ${cmd.substring(0, cmd.length.clamp(0, 120))}');
          final r = await _runSudoCommand('$cmd 2>/dev/null', timeout: const Duration(seconds: 3));
          out = (r.stdout as String?) ?? '';
          exitCode = r.exitCode;
          _log('getSmartInfo($device): [sudo] exit=$exitCode stdout_len=${out.length}');
          if (out.isNotEmpty && hasUsableOutput(out)) {
            final m = RegExp(r'-d\s+(\S+)').firstMatch(cmd); usbProbeVariant = m?.group(1) ?? '';
            break;
          }
          out = '';
        }
        if (out == null || out.isEmpty || !hasUsableOutput(out)) {
          for (int i = 0; i < cmdVariants.length; i++) {
            final cmd = cmdVariants[i];
            _log('getSmartInfo($device): [no-sudo] attempt ${i+1}/${cmdVariants.length}');
            final r = await Process.run('bash', ['-c', '$cmd 2>/dev/null'], runInShell: true, environment: _envWithPATH())
                .timeout(const Duration(seconds: 3))
                .catchError((e) => ProcessResult(0, -1, '', 'timeout'));
            out = (r.stdout as String?) ?? '';
            exitCode = r.exitCode;
            if (out.isNotEmpty && hasUsableOutput(out)) {
              final m = RegExp(r'-d\s+(\S+)').firstMatch(cmd); usbProbeVariant = m?.group(1) ?? '';
              break;
            }
            out = '';
          }
        }
      } else {
        // SATA/NVMe: prova prima senza sudo (più veloce, non serve password)
        for (int i = 0; i < cmdVariants.length; i++) {
          final cmd = cmdVariants[i];
          _log('getSmartInfo($device): [no-sudo] attempt ${i+1}/${cmdVariants.length}: $cmd');
          final r = await Process.run('bash', ['-c', '$cmd 2>/dev/null'], runInShell: true, environment: _envWithPATH())
              .timeout(const Duration(seconds: 8))
              .catchError((e) => ProcessResult(0, -1, '', 'timeout'));
          out = (r.stdout as String?) ?? '';
          exitCode = r.exitCode;
          final err = (r.stderr as String?) ?? '';
          _log('getSmartInfo($device): [no-sudo] exit=$exitCode out_len=${out.length} err_len=${err.length}');
          if (out.isNotEmpty) {
            _log('getSmartInfo($device): [no-sudo] out_preview=${out.substring(0, out.length.clamp(0, 300))}');
            if (hasUsableOutput(out)) {
              break;
            }
          }
          if (err.isNotEmpty) {
            _log('getSmartInfo($device): [no-sudo] err_preview=${err.substring(0, err.length.clamp(0, 200))}');
          }
          out = '';
        }
        if (out == null || out.isEmpty || !hasUsableOutput(out)) {
          for (int i = 0; i < sudoCmdVariants.length; i++) {
            final cmd = sudoCmdVariants[i];
            _log('getSmartInfo($device): [sudo] attempt ${i+1}/${sudoCmdVariants.length}: $cmd');
            final r = await _runSudoCommand('$cmd', timeout: const Duration(seconds: 8));
            out = (r.stdout as String?) ?? '';
            exitCode = r.exitCode;
            final err = (r.stderr as String?) ?? '';
            _log('getSmartInfo($device): [sudo] exit=$exitCode out_len=${out.length} err_len=${err.length}');
            if (out.isNotEmpty) {
              _log('getSmartInfo($device): [sudo] out_preview=${out.substring(0, out.length.clamp(0, 300))}');
              if (hasUsableOutput(out)) {
                break;
              }
            }
            if (err.isNotEmpty) {
              _log('getSmartInfo($device): [sudo] err_preview=${err.substring(0, err.length.clamp(0, 200))}');
            }
            out = '';
          }
        }
      }

      _log('getSmartInfo($device): final attempt exit=$exitCode, stdout len=${out?.length ?? 0}');

      // Se non ha trovato dati, log il contenuto per debug
      if (out != null && out.isNotEmpty && !hasUsableOutput(out)) {
        _log('getSmartInfo($device): has usable output: false, first 300 chars: ${out.substring(0, out.length.clamp(0, 300))}');
      }

      // Se USB progressive e non ha trovato dati: non cache, ritorna null
      if (isUsb && !immediate && _usbWorkingVariant[device] == null) {
        if (out == null || out.isEmpty || !hasUsableOutput(out)) {
          _log('getSmartInfo($device): USB probe not yet successful');
          return null;
        }
      }

      if (out == null || out.isEmpty) {
        _log('getSmartInfo($device): empty output after all attempts');
        return null;
      }

      Map<String, dynamic> json;
      try {
        json = jsonDecode(out) as Map<String, dynamic>;
      } catch (e) {
        _log('getSmartInfo($device): JSON parse error: $e');
        _log('getSmartInfo($device): first 500 chars: ${out.substring(0, out.length.clamp(0, 500))}');
        return null;
      }

      // Log dei messaggi di errore smartctl per debugging
      final msgs = json['smartctl']?['messages'] as List<dynamic>?;
      if (msgs != null && msgs.isNotEmpty) {
        for (final m in msgs) {
          _log('getSmartInfo($device): smartctl msg: ${m['string']} (${m['kind']})');
        }
      }

      final exitStatus = json['smartctl']?['exit_status'] as int? ?? 0;
      _log('getSmartInfo($device): smartctl exit_status=$exitStatus');

      if (exitStatus >= 2) {
        final hasUsable = json['smart_status'] is Map ||
            json['temperature'] != null ||
            json['ata_smart_attributes']?['table'] != null ||
            json['nvme_smart_health_information_log'] != null ||
            json['scsi_smart_log'] != null ||
            json['smart_support']?['available'] == true;
        if (!hasUsable) {
          _log('getSmartInfo($device): exitStatus=$exitStatus, json keys: ${json.keys.take(30).join(', ')}');
          _log('getSmartInfo($device): no usable data, aborting');
          // Mostra almeno il JSON raw se abbiamo device info
          if (json['device'] is Map) {
            _log('getSmartInfo($device): returning partial info (device only)');
          } else {
            return null;
          }
        }
        _log('getSmartInfo($device): exitStatus=$exitStatus but has usable data, continuing');
      }

      final model = json['model_name'] as String? ??
          json['device']?['model'] as String? ?? disk.model;
      final updatedDisk = SmartDisk(
        device: disk.device,
        model: model,
        serial: json['serial_number'] as String? ?? disk.serial,
        firmware: json['firmware_version'] as String? ?? disk.firmware,
        interface: json['device']?['type'] as String? ?? disk.interface,
        deviceType: disk.deviceType,
      );
      final smartAvailable = json['smart_support']?['available'] as bool? ?? false;
      final smartEnabled = json['smart_support']?['enabled'] as bool? ?? false;

      bool passed;
      final sp = json['smart_status'];
      if (sp is Map) {
        passed = (sp['passed'] as bool?) ?? true;
        _log('getSmartInfo($device): smart_status.passed=$passed');
      } else {
        _log('getSmartInfo($device): smart_status absent or not a map, default true');
        passed = true;
      }

      if (json['ata_smart_attributes']?['table'] != null) {
        _log('getSmartInfo($device): has ATA attribute table');
      }
      _log('getSmartInfo($device): json keys: ${json.keys.take(30).join(', ')}');
      // Check NVMe fields
      for (final k in ['temperature', 'percentage_used', 'media_errors', 'power_on_hours', 'power_cycles']) {
        if (json[k] != null) {
          _log('getSmartInfo($device): NVMe field "$k" = ${json[k]}');
        }
      }

      int? temperature;
      int? powerOnHours;
      int? powerCycleCount;
      final attributes = <SmartAttribute>[];

      final table = json['ata_smart_attributes']?['table'] as List<dynamic>?;
      if (table != null) {
        _log('getSmartInfo($device): parsing ${table.length} ATA attributes');
        for (final entry in table) {
          final entryMap = entry as Map<String, dynamic>;
          final id = entryMap['id'] as int? ?? 0;
          final name = entryMap['name'] as String? ?? 'Unknown';
          final value = entryMap['value'] as int? ?? 0;
          final worst = entryMap['worst'] as int? ?? 0;
          final thresh = entryMap['thresh'] as int? ?? 0;
          final raw = entryMap['raw']?['string'] as String? ?? '';
          final wf = entryMap['when_failed'];
          final failed = wf is String && wf.trim().isNotEmpty;
          _log('getSmartInfo($device): ATA attr id=$id name=$name value=$value worst=$worst thresh=$thresh raw=$raw when_failed=$wf failed=$failed');

          if (name == 'Temperature_Celsius') {
            temperature = int.tryParse(raw);
          } else if (name == 'Power_On_Hours') {
            powerOnHours = int.tryParse(raw);
          } else if (name == 'Power_Cycle_Count') {
            powerCycleCount = int.tryParse(raw);
          }

          attributes.add(SmartAttribute(
            id: id,
            name: name,
            value: value,
            worst: worst,
            threshold: thresh,
            rawValue: raw,
            failed: failed,
            isCritical: _isCriticalAttribute(id),
          ));
        }
        attributes.sort((a, b) {
          if (a.failed != b.failed) return a.failed ? -1 : 1;
          if (a.isCritical != b.isCritical) return a.isCritical ? -1 : 1;
          return a.id.compareTo(b.id);
        });
      }

      final nvmeFields = <String, String>{
        'temperature': 'Temperature',
        'percentage_used': 'Percentage_Used',
        'available_spare': 'Available_Spare',
        'critical_warning': 'Critical_Warning',
        'media_errors': 'Media_Errors',
        'data_units_read': 'Data_Units_Read',
        'data_units_written': 'Data_Units_Written',
        'power_on_hours': 'Power_On_Hours',
        'power_cycles': 'Power_Cycles',
      };
      final isNvme = table == null && disk.deviceType == 'nvme';
      final nvmeLog = json['nvme_smart_health_information_log'] as Map<String, dynamic>?;
      for (final entry in nvmeFields.entries) {
        dynamic val = json[entry.key];
        if (val == null && nvmeLog != null) {
          val = nvmeLog[entry.key];
          _log('getSmartInfo($device): NVMe field "${entry.key}" fallback from nvme_log = $val');
        } else if (val != null) {
          _log('getSmartInfo($device): NVMe field "${entry.key}" top-level = $val');
        }
        if (val == null) continue;

        // smartctl spesso restituisce la temperatura come {"current": 44, ...}
        Object resolved = val;
        if (entry.key == 'temperature' && val is Map) {
          final curr = val['current'];
          if (curr != null) resolved = curr;
        }

        if (entry.key == 'temperature') {
          temperature ??= (resolved as num?)?.toInt();
        } else if (entry.key == 'power_on_hours') {
          powerOnHours ??= (resolved as num?)?.toInt();
        } else if (entry.key == 'power_cycles') {
          powerCycleCount ??= (resolved as num?)?.toInt();
        }

        // Aggiungi pseudo-attributi solo per dischi NVMe (senza tabella ATA)
        if (isNvme) {
          final raw = resolved.toString();
          final int norm;
          if (entry.key == 'percentage_used') {
            norm = 100 - ((resolved as num?)?.toInt() ?? 0).clamp(0, 100);
          } else {
            norm = 100;
          }
          attributes.add(SmartAttribute(
            id: 0,
            name: entry.value,
            value: norm,
            worst: norm,
            threshold: 0,
            rawValue: raw,
            isCritical: entry.key == 'critical_warning' ||
                        entry.key == 'media_errors' ||
                        entry.key == 'available_spare',
          ));
        }
      }

      final sensors = json['temperature_sensors'] as List<dynamic>?;
      if (sensors != null && sensors.isNotEmpty) {
        final first = sensors.first;
        temperature ??= (first is Map ? (first['current'] as num?)?.toInt() : (first as num?)?.toInt());
      }

      final info = SmartInfo(
        disk: updatedDisk,
        smartAvailable: smartAvailable,
        smartEnabled: smartEnabled,
        overallHealthPassed: passed,
        temperature: temperature,
        powerOnHours: powerOnHours,
        powerCycleCount: powerCycleCount,
        attributes: attributes,
        rawJson: out,
      );
      // Ricorda la variante USB che ha funzionato (per skip futuro e persistenza)
      if (isUsb && usbProbeVariant != null) {
        _usbWorkingVariant[device] = usbProbeVariant;
        _savePersistedVariants();
        _log('getSmartInfo($device): USB variant found and persisted: "$usbProbeVariant"');
      }
      _smartInfoCacheMap[device] = info;
      _smartInfoCacheTimestamp = DateTime.now();
      _log('getSmartInfo($device): returning SmartInfo (temp=$temperature, poh=$powerOnHours, attrs=${attributes.length}, passed=$passed)');
      return info;
    } catch (e) {
      _log('getSmartInfo($device): UNCAUGHT ERROR: $e');
      return null;
    }
  }

  static bool _isCriticalAttribute(int id) {
    return [
      1, 5, 10, 184, 187, 188, 196, 197, 198, 201,
    ].contains(id);
  }
}

class PackageManager {
  static Future<PackageManager> detect() async {
    if (await _has('apt')) return PackageManager.apt;
    if (await _has('dnf')) return PackageManager.dnf;
    if (await _has('pacman')) return PackageManager.pacman;
    return PackageManager.unknown;
  }

  static Future<bool> _has(String cmd) async {
    try {
      final r = await Process.run('which', [cmd]);
      return r.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static const PackageManager apt = PackageManager._('apt');
  static const PackageManager dnf = PackageManager._('dnf');
  static const PackageManager pacman = PackageManager._('pacman');
  static const PackageManager unknown = PackageManager._('unknown');

  final String name;
  const PackageManager._(this.name);
}

/// Result of ensureSmartctlAvailable with error details
class SmartctlInstallResult {
  final bool success;
  final String? error;
  const SmartctlInstallResult({required this.success, this.error});
}
