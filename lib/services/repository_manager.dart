import 'dart:io';
import 'password_storage.dart';
import 'system_detector.dart';

class RepositoryManager {
  static Future<List<String>> getRestoreCommands(SystemDetectionInfo info) async {
    final dist = info.distribution.toLowerCase();
    final cmds = <String>[];

    if (info.hasApt) {
      cmds.addAll(await _getAptRestoreCommands(dist, info));
    }
    if (info.hasDnf) {
      cmds.addAll(_getDnfRestoreCommands(dist, info.distributionVersion));
    }
    if (info.hasPacman) {
      cmds.addAll(await _getPacmanRestoreCommands(dist));
    }

    return cmds;
  }

  static Future<Map<String, dynamic>> restoreRepositories() async {
    try {
      final info = await SystemDetector.detectSystem();
      final cmds = await getRestoreCommands(info);

      if (cmds.isEmpty) {
        final updateCmd = getUpdateCacheCommand(info);
        if (updateCmd != null) {
          try {
            await _runSudoCommand(updateCmd);
          } catch (_) {}
        }
        return {'success': true, 'message': 'Nessun repository specifico da ripristinare, cache aggiornata.', 'output': ''};
      }

      final outputs = <String>[];
      for (final cmd in cmds) {
        try {
          final result = await _runSudoCommand(cmd);
          final out = result.stdout.toString().trim();
          final err = result.stderr.toString().trim();
          if (out.isNotEmpty) outputs.add(out);
          if (err.isNotEmpty) outputs.add(err);
        } catch (e) {
          outputs.add('Error: $e');
        }
      }

      final updateCmd = getUpdateCacheCommand(info);
      if (updateCmd != null) {
        try {
          final result = await _runSudoCommand(updateCmd);
          final out = result.stdout.toString().trim();
          if (out.isNotEmpty) outputs.add(out);
        } catch (_) {}
      }

      return {'success': true, 'message': 'Repository ripristinati con successo.', 'output': outputs.join('\n')};
    } catch (e) {
      return {'success': false, 'message': 'Errore durante il ripristino dei repository: $e', 'output': ''};
    }
  }

  static String? getUpdateCacheCommand(SystemDetectionInfo info) {
    if (info.hasApt) return 'apt update 2>/dev/null || true';
    if (info.hasDnf) return 'dnf clean all 2>/dev/null; dnf makecache 2>/dev/null || true';
    if (info.hasPacman) return 'pacman -Sy 2>/dev/null || true';
    return null;
  }

  /// Verifica se i repository APT attuali sono sani per la distribuzione rilevata.
  /// Controlla che non ci siano repository Ubuntu su sistemi LMDE, o repository
  /// Debian su sistemi Mint standard, ecc.
  /// Restituisce true se i repository sono OK o se non è possibile verificarli.
  static Future<bool> areRepositoriesHealthy() async {
    try {
      final id = await _osReleaseField('ID');
      final isMint = id == 'linuxmint';
      final isLmde = isMint ? await _isLmde() : false;

      if (!isMint) return true;

      // Controlla /etc/apt/sources.list: su Mint non dovrebbe avere repo
      // (le repo vanno in official-package-repositories.list)
      final sourcesList = File('/etc/apt/sources.list');
      if (await sourcesList.exists()) {
        final content = await sourcesList.readAsString();
        final hasDebLines = content.split('\n').any((l) => l.trimLeft().startsWith('deb '));
        if (hasDebLines) return false; // sources.list ha righe deb → errato per Mint
      }

      // Controlla official-package-repositories.list
      final officialList = File('/etc/apt/sources.list.d/official-package-repositories.list');
      if (await officialList.exists()) {
        final content = await officialList.readAsString();
        if (isLmde && content.contains('archive.ubuntu.com')) {
          return false; // LMDE con repo Ubuntu → rotto
        }
        // Controlla che ci sia almeno una riga Mint
        if (!content.contains('packages.linuxmint.com')) {
          return false; // File senza repo Mint
        }
      } else if (!await sourcesList.exists()) {
        // Nessuno dei due file esiste → probabilmente rotto
        return false;
      }

      // Controlla file extra in sources.list.d/ con repo sbagliate
      final sourcesDir = Directory('/etc/apt/sources.list.d');
      if (await sourcesDir.exists()) {
        await for (final entity in sourcesDir.list()) {
          if (entity is File) {
            final name = entity.path.split('/').last;
            if (name == 'official-package-repositories.list') continue;
            if (!name.endsWith('.list') && !name.endsWith('.sources')) continue;
            final content = await entity.readAsString();
            final hasDebLines = content.split('\n').any((l) => l.trimLeft().startsWith('deb '));
            if (hasDebLines) {
              // File extra con repo → potenzialmente errato per Mint
              if (isLmde && content.contains('archive.ubuntu.com')) return false;
              if (!isLmde && content.contains('deb.debian.org')) return false;
            }
          }
        }
      }

      return true;
    } catch (_) {
      // In caso di errore nella lettura, lascia passare
      return true;
    }
  }

  // ─── /etc/os-release helpers ───

  static Future<String> _osReleaseField(String field) async {
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        for (final line in content.split('\n')) {
          if (line.startsWith('$field=')) {
            return line.substring(field.length + 1).replaceAll('"', '').trim().toLowerCase();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// Detecta LMDE (Linux Mint Debian Edition).
  /// Usa multipli segnali per massima robustezza:
  /// 1. ID=linuxmint + ID_LIKE contiene 'debian'
  /// 2. PRETTY_NAME contiene 'LMDE'
  /// 3. DEBIAN_CODENAME è presente (specifico di LMDE)
  static Future<bool> _isLmde() async {
    final id = await _osReleaseField('ID');
    if (id != 'linuxmint') return false;

    final idLike = await _osReleaseField('ID_LIKE');

    // Se ID_LIKE contiene 'ubuntu', è Mint standard (non LMDE).
    // Questo previene falsi positivi su sistemi Mint standard che
    // potrebbero avere DEBIAN_CODENAME nel loro os-release.
    if (idLike.contains('ubuntu')) return false;

    // Check 1: ID_LIKE contiene 'debian'
    if (idLike.contains('debian')) return true;

    // Check 2: PRETTY_NAME contiene 'LMDE'
    final prettyName = await _osReleaseField('PRETTY_NAME');
    if (prettyName.contains('lmde')) return true;

    // Check 3: DEBIAN_CODENAME è presente (solo LMDE lo ha)
    final dc = await _osReleaseField('DEBIAN_CODENAME');
    if (dc.isNotEmpty) return true;

    return false;
  }

  static Future<String> _detectCodename() async {
    final vc = await _osReleaseField('VERSION_CODENAME');
    if (vc.isNotEmpty) return vc;
    final uc = await _osReleaseField('UBUNTU_CODENAME');
    if (uc.isNotEmpty) return uc;
    try {
      final lsbRelease = File('/etc/lsb-release');
      if (await lsbRelease.exists()) {
        final content = await lsbRelease.readAsString();
        for (final line in content.split('\n')) {
          if (line.startsWith('DISTRIB_CODENAME=')) {
            return line.substring(17).replaceAll('"', '').trim().toLowerCase();
          }
        }
      }
    } catch (_) {}
    return '';
  }

  /// Per Ubuntu-based Mint: UBUNTU_CODENAME. Per LMDE: DEBIAN_CODENAME o versione.
  /// Per tutte le altre: VERSION_CODENAME.
  static Future<String> _getBaseCodename() async {
    final id = await _osReleaseField('ID');
    if (id == 'linuxmint') {
      final isLmde = await _isLmde();
      if (isLmde) {
        final dc = await _osReleaseField('DEBIAN_CODENAME');
        if (dc.isNotEmpty) return dc;
        // Usa match ESATTO su VERSION_ID (non startsWith!)
        // VERSION_ID LMDE: 2,3,4,5,6,7 — VERSION_ID Mint standard: 21,22,22.1
        // startsWith('2') su VERSION_ID='22' matcherebbe → jessie (SBAGLIATO!)
        final ver = await _osReleaseField('VERSION_ID');
        if (ver == '8') return 'forky';
        if (ver == '7') return 'trixie';
        if (ver == '6') return 'bookworm';
        if (ver == '5') return 'bullseye';
        if (ver == '4') return 'buster';
        if (ver == '3') return 'stretch';
        if (ver == '2') return 'jessie';
        return 'trixie';
      }
      final uc = await _osReleaseField('UBUNTU_CODENAME');
      if (uc.isNotEmpty) return uc;
    }
    return _detectCodename();
  }

  static Future<String> _getMintCodename() async {
    final mc = await _osReleaseField('VERSION_CODENAME');
    return mc.isNotEmpty ? mc : 'faye';
  }

  // ─── APT based ───

  static Future<List<String>> _getAptRestoreCommands(String dist, SystemDetectionInfo info) async {
    final codename = await _getBaseCodename();
    final cmds = <String>[];

    if (codename.isEmpty) {
      cmds.add('apt update 2>/dev/null || true');
      return cmds;
    }

    final id = await _osReleaseField('ID');
    final isLmde = await _isLmde();

    // ─── Linux Mint (tutte le varianti) ───
    // PROTETTO: Linux Mint (Cinnamon, XFCE, MATE, KDE, LMDE) usa SEMPRE
    // repository proprie. NON generare MAI repository Ubuntu per Mint.
    if (id == 'linuxmint') {
      cmds.addAll(await _mintRepos(codename, isLmde));
    } else if (dist.contains('ubuntu') || dist.contains('pop') ||
               dist.contains('zorin') || dist.contains('elementary') ||
               dist.contains('neon') || dist.contains('kde neon')) {
      cmds.addAll(_ubuntuRepos(codename));
    } else if (dist.contains('debian') || dist.contains('mx') ||
               dist.contains('kali') || dist.contains('raspbian') ||
               dist.contains('deepin') || dist.contains('parrot') ||
               dist.contains('devuan') || dist.contains('antix') ||
               dist.contains('sparky') || dist.contains('voyager') ||
               dist.contains('q4os') || dist.contains('puppy') ||
               dist.contains('salix') || dist.contains('slackel')) {
      cmds.addAll(_debianRepos(codename));
    }

    return cmds;
  }

  static Future<List<String>> _mintRepos(String baseCodename, bool isLmde) async {
    final cmds = <String>[];
    final mintCodename = await _getMintCodename();

    // ─── SAFETY: per LMDE, il codename DEVE essere un codename Debian ───
    // Se baseCodename sembra essere un codename Mint/Ubuntu (non Debian),
    // usa 'stable' come fallback sicuro per non rompere il sistema.
    final safeCodename = isLmde ? _sanitizeLmdeCodename(baseCodename) : baseCodename;

    cmds.add('mkdir -p /etc/apt/sources.list.d');
    cmds.add("cp -f /etc/apt/sources.list.d/official-package-repositories.list "
             "/etc/apt/sources.list.d/official-package-repositories.list.bak 2>/dev/null || true");
    cmds.add('rm -f /etc/apt/sources.list');

    // Rimuovi file extra in sources.list.d/ con repo sbagliate
    // (residui di versioni precedenti dell'app o configurazioni errate)
    if (isLmde) {
      // Su LMDE: rimuovi file con repo Ubuntu (deb.debian.org è corretto)
      cmds.add('find /etc/apt/sources.list.d -maxdepth 1 \\( -name "*.list" -o -name "*.sources" \\) '
               '-exec grep -l "archive.ubuntu.com" {} \\; -exec rm -f {} \\; 2>/dev/null || true');
    } else {
      // Su Mint standard: rimuovi file con repo Debian (archive.ubuntu.com è corretto)
      cmds.add('find /etc/apt/sources.list.d -maxdepth 1 \\( -name "*.list" -o -name "*.sources" \\) '
               '-exec grep -l "deb.debian.org" {} \\; -exec rm -f {} \\; 2>/dev/null || true');
    }

    if (isLmde) {
      final mirror = 'http://deb.debian.org/debian';
      final security = 'http://deb.debian.org/debian-security';
      cmds.add("""cat > /etc/apt/sources.list.d/official-package-repositories.list << 'MINTEOF'
deb http://packages.linuxmint.com $mintCodename main upstream import backport

deb $mirror $safeCodename main contrib non-free non-free-firmware
deb $mirror $safeCodename-updates main contrib non-free non-free-firmware
deb $mirror $safeCodename-backports main contrib non-free non-free-firmware
deb $security ${safeCodename}-security main contrib non-free non-free-firmware
MINTEOF""");
    } else {
      final mirror = 'http://archive.ubuntu.com/ubuntu';
      final security = 'http://security.ubuntu.com/ubuntu';
      cmds.add("""cat > /etc/apt/sources.list.d/official-package-repositories.list << 'MINTEOF'
deb http://packages.linuxmint.com $mintCodename main upstream import backport

deb $mirror $baseCodename main restricted universe multiverse
deb $mirror $baseCodename-updates main restricted universe multiverse
deb $mirror $baseCodename-backports main restricted universe multiverse
deb $security ${baseCodename}-security main restricted universe multiverse
MINTEOF""");
    }
    return cmds;
  }

  /// Converte un codename potenzialmente errato in un codename Debian valido.
  /// Previene che codename Mint (gigi, faye, ecc.) vengano usati come
  /// codename Debian nelle repository.
  static String _sanitizeLmdeCodename(String codename) {
    // Codename Debian validi
    const validDebianCodenames = {
      'trixie', 'bookworm', 'bullseye', 'buster',
      'stretch', 'jessie', 'wheezy', 'squeeze',
      'stable', 'testing', 'unstable', 'sid',
      'forky', // Debian 14
    };
    if (validDebianCodenames.contains(codename)) return codename;
    // Codename non riconosciuto come Debian → usa 'stable' come fallback sicuro
    return 'stable';
  }

  static List<String> _ubuntuRepos(String codename) {
    final mirror = 'http://archive.ubuntu.com/ubuntu';
    final security = 'http://security.ubuntu.com/ubuntu';
    final cmds = <String>[];
    cmds.add('mkdir -p /etc/apt/sources.list.d');
    cmds.add('rm -f /etc/apt/sources.list.d/official-package-repositories.list');

    // Ubuntu 24.04+ usa formato DEB822 in ubuntu.sources.
    // Se il file esiste, lo riscriviamo in formato DEB822. Altrimenti sources.list.
    cmds.add("""if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
  cp -f /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.bak 2>/dev/null || true
  cat > /etc/apt/sources.list.d/ubuntu.sources << 'DEB822'
Types: deb
URIs: $mirror
Suites: $codename $codename-updates $codename-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: $security
Suites: ${codename}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
DEB822
  rm -f /etc/apt/sources.list
else
  cp -f /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
  cat > /etc/apt/sources.list << 'EOF'
deb $mirror $codename main restricted universe multiverse
deb $mirror $codename-updates main restricted universe multiverse
deb $mirror $codename-backports main restricted universe multiverse
deb $security ${codename}-security main restricted universe multiverse
EOF
fi""");
    return cmds;
  }

  static List<String> _debianRepos(String codename) {
    final mirror = 'http://deb.debian.org/debian';
    final security = 'http://deb.debian.org/debian-security';
    final cmds = <String>[];
    cmds.add('mkdir -p /etc/apt/sources.list.d');
    cmds.add("cp -f /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true");
    cmds.add("cp -f /etc/apt/sources.list.d/debian.sources /etc/apt/sources.list.d/debian.sources.bak 2>/dev/null || true");

    cmds.add("""DEBIAN_VERSION=\$(bash -c 'source /etc/os-release 2>/dev/null; echo "\${VERSION_ID}"')
if dpkg --compare-versions "\$DEBIAN_VERSION" ge 12 2>/dev/null || [ -f /etc/apt/sources.list.d/debian.sources ]; then
  rm -f /etc/apt/sources.list
  cat > /etc/apt/sources.list.d/debian.sources << 'DEBSRC'
Types: deb
URIs: $mirror
Suites: $codename ${codename}-updates ${codename}-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: $security
Suites: ${codename}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
DEBSRC
else
  rm -f /etc/apt/sources.list.d/debian.sources
  cat > /etc/apt/sources.list << 'DEBLIST'
deb $mirror $codename main contrib non-free non-free-firmware
deb $mirror $codename-updates main contrib non-free non-free-firmware
deb $mirror $codename-backports main contrib non-free non-free-firmware
deb $security ${codename}-security main contrib non-free non-free-firmware
DEBLIST
fi""");
    return cmds;
  }

  // ─── DNF based ───

  static List<String> _getDnfRestoreCommands(String dist, String version) {
    final cmds = <String>[];
    cmds.add('mkdir -p /etc/yum.repos.d');

    if (dist.contains('fedora')) {
      cmds.addAll(_fedoraRepos(version));
    } else if (dist.contains('rhel')) {
      cmds.addAll(_rhelRepos());
    } else if (dist.contains('centos')) {
      cmds.addAll(_centosRepos());
    }

    return cmds;
  }

  static List<String> _fedoraRepos(String version) {
    return [
      'cat > /etc/yum.repos.d/fedora.repo << \'EOF\'\n'
      '[fedora]\n'
      'name=Fedora \$releasever - \$basearch\n'
      'metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-\$releasever&arch=\$basearch\n'
      'enabled=1\ngpgcheck=1\n'
      'gpgkey=https://getfedora.org/static/fedora.gpg\n'
      '\n'
      '[updates]\n'
      'name=Fedora \$releasever - \$basearch - Updates\n'
      'metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f\$releasever&arch=\$basearch\n'
      'enabled=1\ngpgcheck=1\n'
      'gpgkey=https://getfedora.org/static/fedora.gpg\n'
      '\n'
      '[updates-testing]\n'
      'name=Fedora \$releasever - \$basearch - Test Updates\n'
      'metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f\$releasever&arch=\$basearch\n'
      'enabled=0\ngpgcheck=1\n'
      'gpgkey=https://getfedora.org/static/fedora.gpg\n'
      'EOF',
    ];
  }

  static List<String> _rhelRepos() {
    return [
      'cat > /etc/yum.repos.d/rhel.repo << \'EOF\'\n'
      '[rhel-baseos]\n'
      'name=Red Hat Enterprise Linux \$releasever - BaseOS\n'
      'baseurl=https://cdn.redhat.com/content/dist/rhel\$releasever/\$releasever/baseos/os/\n'
      'enabled=1\ngpgcheck=1\n'
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release\n'
      '\n'
      '[rhel-appstream]\n'
      'name=Red Hat Enterprise Linux \$releasever - AppStream\n'
      'baseurl=https://cdn.redhat.com/content/dist/rhel\$releasever/\$releasever/appstream/os/\n'
      'enabled=1\ngpgcheck=1\n'
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release\n'
      'EOF',
    ];
  }

  static List<String> _centosRepos() {
    return [
      'cat > /etc/yum.repos.d/centos.repo << \'EOF\'\n'
      '[baseos]\n'
      'name=CentOS \$releasever - BaseOS\n'
      'baseurl=http://mirror.centos.org/centos/\$releasever/BaseOS/\$basearch/os/\n'
      'gpgcheck=1\nenabled=1\n'
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial\n'
      '\n'
      '[appstream]\n'
      'name=CentOS \$releasever - Appstream\n'
      'baseurl=http://mirror.centos.org/centos/\$releasever/AppStream/\$basearch/os/\n'
      'gpgcheck=1\nenabled=1\n'
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial\n'
      '\n'
      '[epel]\n'
      'name=Extra Packages for Enterprise Linux \$releasever - \$basearch\n'
      'metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-\$releasever&arch=\$basearch\n'
      'enabled=1\ngpgcheck=1\n'
      'gpgkey=https://getfedora.org/static/epel.gpg\n'
      '\n'
      '[powertools]\n'
      'name=CentOS \$releasever - PowerTools\n'
      'baseurl=http://mirror.centos.org/centos/\$releasever/PowerTools/\$basearch/os/\n'
      'enabled=1\ngpgcheck=1\n'
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial\n'
      'EOF',
    ];
  }

  // ─── Pacman based ───

  static Future<List<String>> _getPacmanRestoreCommands(String dist) async {
    if (dist.contains('manjaro')) {
      return _manjaroRepos();
    }
    return _archRepos();
  }

  static List<String> _archRepos() {
    return [
      'cat > /etc/pacman.conf << \'EOF\'\n'
      '[options]\n'
      'HoldPkg     = pacman glibc\n'
      'Architecture = auto\n'
      'SigLevel    = Required DatabaseOptional\n'
      'LocalFileSigLevel = Optional\n'
      'RemoteFileSigLevel = Optional\n'
      '\n'
      '[core]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      '\n'
      '[extra]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      '\n'
      '[community]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      '\n'
      '[multilib]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      'EOF',
      'pacman-key --init 2>/dev/null; pacman-key --populate archlinux 2>/dev/null || true',
    ];
  }

  static List<String> _manjaroRepos() {
    return [
      'cat > /etc/pacman.conf << \'EOF\'\n'
      '[options]\n'
      'HoldPkg     = pacman glibc\n'
      'Architecture = auto\n'
      'SigLevel    = Required DatabaseOptional\n'
      'LocalFileSigLevel = Optional\n'
      'RemoteFileSigLevel = Optional\n'
      '\n'
      '[core]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      '\n'
      '[extra]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      '\n'
      '[community]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      '\n'
      '[multilib]\n'
      'Include = /etc/pacman.d/mirrorlist\n'
      'EOF',
      'pacman-key --init 2>/dev/null; pacman-key --populate archlinux manjaro 2>/dev/null || true',
    ];
  }

  // ─── Utility ───

  static Future<ProcessResult> _runSudoCommand(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    final fullCommand =
        'printf "%s\\n" "$escapedPassword" | sudo -p "" -S bash -c ${_shellQuote(command)}';
    return await Process.run('bash', ['-c', fullCommand], runInShell: true);
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }
}
