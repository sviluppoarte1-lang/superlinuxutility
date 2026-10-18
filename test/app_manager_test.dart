import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_linux_utility/models/installed_app.dart';
import 'package:super_linux_utility/services/app_manager.dart';

void main() {
  // ==========================================================================
  // Parsing APT (dpkg-query tab, stato incluso)
  // ==========================================================================
  group('parseAptQueryOutput', () {
    test('la descrizione multilinea non crea app fantasma', () {
      const output = '7zip\t23.01\t1234\tinstalled\t'
          '7-Zip file archiver with a high compression ratio\n'
          '  continuation; with; semicolons; everywhere\n'
          '  more continuation foo; bar; baz\n'
          'foo\t1.0-1\t10\tinstalled\tshort desc\n';
      final apps = AppManager.parseAptQueryOutput(output);
      expect(apps.length, 2);
      expect(apps[0].name, '7zip');
      expect(apps[0].description, '7-Zip file archiver with a high compression ratio');
      expect(apps[1].name, 'foo');
      expect(apps[1].description, 'short desc');
    });

    test('esclude i pacchetti con residui di configurazione', () {
      const output = 'oldapp\t1.0\t5\tconfig-files\tOld removed app\n'
          'gone\t1.0\t5\tnot-installed\tGone\n'
          'kept\t1.0\t5\tinstalled\tKept\n'
          'pending\t1.0\t5\ttriggers-pending\tPending\n';
      final apps = AppManager.parseAptQueryOutput(output);
      expect(apps.map((a) => a.name), ['kept', 'pending']);
    });

    test('converte Installed-Size da KB a bytes', () {
      const output = 'pkg\t1.0\t512\tinstalled\tdesc\n';
      final apps = AppManager.parseAptQueryOutput(output);
      expect(apps.first.size, 512 * 1024);
    });

    test('dedup dei doppioni multiarch (stesso nome)', () {
      const output = 'libfoo\t1.0\t10\tinstalled\tdesc\n'
          'libfoo\t1.0\t10\tinstalled\tdesc due\n';
      final apps = AppManager.parseAptQueryOutput(output);
      expect(apps.length, 1);
    });

    test('; nella prima riga della descrizione non sposta i campi', () {
      const output = 'pkg\t1.0-2\t10\tinstalled\tfoo; bar; baz\n';
      final apps = AppManager.parseAptQueryOutput(output);
      expect(apps.single.name, 'pkg');
      expect(apps.single.version, '1.0-2');
      expect(apps.single.description, 'foo; bar; baz');
    });

    test('output vuoto → lista vuota', () {
      expect(AppManager.parseAptQueryOutput(''), isEmpty);
    });
  });

  // ==========================================================================
  // Parsing apt list (fallback)
  // ==========================================================================
  group('parseAptListOutput', () {
    test('estrae la versione corretta (non il codename)', () {
      const output = 'Listing...\n'
          '7zip/noble,now 23.01+dfsg-11 amd64 [installed,automatic]\n'
          'accounts-qml6-module-doc/noble,noble 0.7 all [installed]\n';
      final apps = AppManager.parseAptListOutput(output);
      expect(apps.length, 2);
      expect(apps[0].name, '7zip');
      expect(apps[0].version, '23.01+dfsg-11');
      expect(apps[1].name, 'accounts-qml6-module-doc');
      expect(apps[1].version, '0.7');
      expect(apps[0].description, isNull);
    });
  });

  // ==========================================================================
  // Parsing Snap
  // ==========================================================================
  group('parseSnapListOutput', () {
    const fixture = 'Nome               Versione          Rev    '
        'Tracciamento    Publisher     Note\n'
        'core22             20260101          1234   latest/stable  canonical**   base\n'
        'firefox            1.0               555    latest/stable  mozilla       -\n'
        'gnome-46-2404      46                0      latest/stable  canonical**   -\n'
        'android-studio     2026.1.4          242    latest/stable  snapcrafters* classic\n';

    test('header localizzato saltato, campi corretti, base marcate', () {
      final apps = AppManager.parseSnapListOutput(fixture);
      expect(apps.length, 4);
      expect(apps[0].name, 'core22');
      expect(apps[0].version, '20260101');
      expect(apps[1].name, 'firefox');
      expect(apps[1].description, isNull); // nessuna nota
      expect(apps[3].description, 'classic');
    });

    test('i base/runtime snap sono marcati di sistema', () {
      final apps = AppManager.parseSnapListOutput(fixture);
      final byName = {for (final a in apps) a.name: a};
      expect(byName['core22']!.isSystemPackage, isTrue);
      expect(byName['gnome-46-2404']!.isSystemPackage, isTrue);
      expect(byName['firefox']!.isSystemPackage, isFalse);
      expect(byName['android-studio']!.isSystemPackage, isFalse);
    });

    test('isSnapBase copre i runtime noti', () {
      for (final name in [
        'bare',
        'core18',
        'core24',
        'snapd',
        'gnome-42-2204',
        'gnome-42-2204-sdk',
        'gtk-common-themes',
        'kf6-core24',
        'mesa-2404',
      ]) {
        expect(AppManager.isSnapBase(name), isTrue, reason: name);
      }
      for (final name in ['firefox', 'code', 'lxd', 'ffmpeg']) {
        expect(AppManager.isSnapBase(name), isFalse, reason: name);
      }
    });
  });

  // ==========================================================================
  // Parsing Flatpak
  // ==========================================================================
  group('parseFlatpakListOutput', () {
    test('nomi display con spazi non rovinano l\'id', () {
      const output = 'Super Productivity\t'
          'com.super_productivity.SuperProductivity\t'
          'v19.1.0\tstable\tuser\n'
          'PDF Slicer\tcom.github.junrrein.PDFSlicer\t1.8.8\tstable\tuser\n';
      final apps = AppManager.parseFlatpakListOutput(output);
      expect(apps.length, 2);
      expect(apps[0].name, 'Super Productivity');
      expect(apps[0].description, 'com.super_productivity.SuperProductivity');
      expect(apps[0].installation, 'user');
      expect(apps[1].name, 'PDF Slicer');
      expect(apps[1].description, 'com.github.junrrein.PDFSlicer');
    });

    test('stessa app in user + system → installation both', () {
      const output = 'Foo\torg.foo.Bar\t1.0\tstable\tuser\n'
          'Foo\torg.foo.Bar\t1.0\tstable\tsystem\n';
      final apps = AppManager.parseFlatpakListOutput(output);
      expect(apps.length, 1);
      expect(apps.single.installation, 'both');
    });

    test('righe malformate e id invalidi ignorate', () {
      const output = 'riga senza tab\n'
          'Name\t\t1.0\tstable\tuser\n'
          'Valid\torg.valid.App\t1.0\tstable\tsystem\n';
      final apps = AppManager.parseFlatpakListOutput(output);
      expect(apps.length, 1);
      expect(apps.single.description, 'org.valid.App');
    });

    test('mergeFlatpakScope', () {
      expect(AppManager.mergeFlatpakScope(null, 'system'), 'system');
      expect(AppManager.mergeFlatpakScope('user', null), 'user');
      expect(AppManager.mergeFlatpakScope('user', 'system'), 'both');
      expect(AppManager.mergeFlatpakScope('user', 'user'), 'user');
      expect(AppManager.mergeFlatpakScope(null, null), isNull);
      expect(AppManager.mergeFlatpakScope('', 'user'), 'user');
    });
  });

  // ==========================================================================
  // File .desktop (app GNOME)
  // ==========================================================================
  group('parseDesktopEntry', () {
    test('estrae Name e Comment', () {
      const content = '[Desktop Entry]\n'
          'Type=Application\n'
          'Name=Mio Programma\n'
          'Comment=Un programmino\n'
          'Exec=mio-programma\n';
      final entry = AppManager.parseDesktopEntry(content);
      expect(entry, isNotNull);
      expect(entry!.name, 'Mio Programma');
      expect(entry.comment, 'Un programmino');
    });

    test('NoDisplay/Hidden/Type errato → null', () {
      expect(
          AppManager.parseDesktopEntry(
              '[Desktop Entry]\nName=X\nNoDisplay=true\n'),
          isNull);
      expect(
          AppManager.parseDesktopEntry('[Desktop Entry]\nName=X\nHidden=true\n'),
          isNull);
      expect(
          AppManager.parseDesktopEntry(
              '[Desktop Entry]\nName=X\nType=Directory\n'),
          isNull);
      expect(AppManager.parseDesktopEntry('[Desktop Entry]\nType=Application\n'),
          isNull);
    });

    test('solo Name localizzato senza Name= base → null', () {
      const content = '[Desktop Entry]\nType=Application\nName[it]=SoloIT\n';
      expect(AppManager.parseDesktopEntry(content), isNull);
    });
  });

  group('parseDpkgOwnedPaths', () {
    test('parsa pkg: /percorso e pkg:arch: /percorso, ignora il rumore', () {
      const output = 'firefox: /usr/share/applications/firefox.desktop\n'
          'libfoo:amd64: /usr/share/applications/foo.desktop\n'
          "dpkg-query: no path found matching pattern /nope.desktop\n";
      final owned = AppManager.parseDpkgOwnedPaths(output);
      expect(owned, contains('/usr/share/applications/firefox.desktop'));
      expect(owned, contains('/usr/share/applications/foo.desktop'));
      expect(owned.length, 2);
    });
  });

  // ==========================================================================
  // Pacman / DNF
  // ==========================================================================
  group('parsePacmanListOutput', () {
    test('blocchi pacman -Qi con campi inglesi (LC_ALL=C)', () {
      const output = 'Name           : firefox\n'
          'Version        : 132.0-1\n'
          'Description    : Fast Web Browser\n'
          'Architecture   : x86_64\n'
          '\n'
          'Name           : linux\n'
          'Version        : 6.11.5\n'
          'Description    : The Linux kernel and modules\n'
          'Architecture   : x86_64\n'
          '\n'
          'Name           : lastpkg\n'
          'Version        : 1.0\n'
          'Description    : Senza riga vuota finale\n';
      final apps = AppManager.parsePacmanListOutput(output);
      expect(apps.length, 3);
      expect(apps[0].name, 'firefox');
      expect(apps[0].version, '132.0-1');
      expect(apps[0].description, 'Fast Web Browser');
      // 'linux' è nel set esatto dei pacchetti di sistema
      final linux = apps.firstWhere((a) => a.name == 'linux');
      expect(linux.isSystemPackage, isTrue);
      // ultimo blocco senza riga vuota finale
      expect(apps.map((a) => a.name), contains('lastpkg'));
    });
  });

  group('parseDnfListOutput', () {
    test('rpm -qa qf TAB, ordinato e senza doppioni', () {
      const output = 'zsh\t5.9-9\tshell\n'
          'firefox\t132.0-1\tFast Web Browser\n'
          'firefox\t132.0-1\tFast Web Browser\n'
          'kernel\t6.8.0-1\tLinux kernel\n';
      final apps = AppManager.parseDnfListOutput(output);
      expect(apps.map((a) => a.name), ['firefox', 'kernel', 'zsh']);
      expect(apps.firstWhere((a) => a.name == 'kernel').isSystemPackage, isTrue);
      expect(apps.first.description, 'Fast Web Browser');
    });

    test('query di fallback senza summary (2 campi) → description null', () {
      const output = 'alpha\t1.0-1\nbeta\t2.0-1\n';
      final apps = AppManager.parseDnfListOutput(output);
      expect(apps, hasLength(2));
      expect(apps.map((a) => a.name), ['alpha', 'beta']);
      expect(apps.every((a) => a.description == null), isTrue);
      expect(apps.map((a) => a.version), ['1.0-1', '2.0-1']);
    });

    test('righe senza TAB/ruote saltate, summary con TAB extra troncato', () {
      const output = 'garbage-line-no-tabs\n'
          '\n'
          'weird\t1.0-1\tSummary con\tTab\tExtra\n';
      final apps = AppManager.parseDnfListOutput(output);
      expect(apps, hasLength(1));
      expect(apps.single.name, 'weird');
      expect(apps.single.version, '1.0-1');
      expect(apps.single.description, 'Summary con');
    });
  });

  group('getDnfApps (integrazione con rpm)', () {
    test('lista completa anche con summary non-UTF-8', () async {
      // Richiede il fake rpm in PATH (senza di esso il test è uno skip):
      //   PATH="$PWD/test/fixtures/fakebin:$PATH" flutter test test/app_manager_test.dart
      final marker = await Process.run('sh', [
        '-c',
        'command -v rpm >/dev/null 2>&1 && '
            'rpm --version 2>/dev/null | grep -q FAKE_RPM_FOR_TESTS'
      ]);
      if (marker.exitCode != 0) return; // fake non in PATH → skip

      final apps = await AppManager.getDnfApps();
      expect(apps.map((a) => a.name), containsAll(['alpha', 'beta', 'gamma']),
          reason: 'getDnfApps deve contare tutti i pacchetti dnf anche con '
              'byte non-UTF-8 nel summary: un solo byte invalido buttava via '
              "l'intera lista (decoder stretto) e Fedora risultava senza app.");
      final alpha = apps.firstWhere((a) => a.name == 'alpha');
      expect(alpha.version, '1.0-1');
      // Description presente → ha decodificato con allowMalformed (il fallback
      // senza %{SUMMARY} la lascerebbe null).
      expect(alpha.description, isNotNull);
      expect(alpha.packageManager, PackageManager.dnf);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });

  // ==========================================================================
  // Validazione nomi (anti-injection)
  // ==========================================================================
  group('validazione nomi', () {
    test('nomi apt validi', () {
      for (final name in ['7zip', 'libgtk-3-0', 'gcc-12', 'g++', 'a']) {
        expect(AppManager.isValidAptName(name), isTrue, reason: name);
      }
    });

    test('nomi apt invalidi (injection, spazi, trattini iniziali)', () {
      for (final name in [
        'foo bar',
        'foo;rm -rf /',
        '\$(rm -rf /)',
        '`id`',
        '-x',
        'foo:bar:baz',
        'FOO',
        '',
        'pkg:BAD',
      ]) {
        expect(AppManager.isValidAptName(name), isFalse, reason: name);
      }
    });

    test('nomi snap', () {
      expect(AppManager.isValidSnapName('firefox'), isTrue);
      expect(AppManager.isValidSnapName('gnome-46-2404'), isTrue);
      expect(AppManager.isValidSnapName('Foo'), isFalse);
      expect(AppManager.isValidSnapName('foo bar'), isFalse);
      expect(AppManager.isValidSnapName('x;id'), isFalse);
    });

    test('id flatpak', () {
      expect(AppManager.isValidFlatpakId('org.gnome.Calculator'), isTrue);
      expect(AppManager.isValidFlatpakId('app.zen_browser.zen'), isTrue);
      expect(AppManager.isValidFlatpakId('foo bar'), isFalse);
      expect(AppManager.isValidFlatpakId('\$(evil)'), isFalse);
      expect(AppManager.isValidFlatpakId('-bad.id'), isFalse);
    });

    test('nomi rpm/pacman', () {
      expect(AppManager.isValidRpmName('libstdc++'), isTrue);
      expect(AppManager.isValidRpmName('kernel-devel'), isTrue);
      expect(AppManager.isValidRpmName('python3-pip'), isTrue);
      expect(AppManager.isValidRpmName('foo bar'), isFalse);
      expect(AppManager.isValidRpmName('a;b'), isFalse);
    });
  });

  // ==========================================================================
  // Costruttori comandi
  // ==========================================================================
  group('costruttori comandi rimozione', () {
    test('apt: non-interactive, force-confold, -y, locale C', () {
      final cmd = AppManager.buildAptRemoveCommand('7zip');
      expect(cmd, contains('DEBIAN_FRONTEND=noninteractive'));
      expect(cmd, contains('Dpkg::Options::=--force-confold'));
      expect(cmd, contains('apt-get remove -y'));
      expect(cmd, contains('LC_ALL=C'));
      expect(cmd, contains(' 7zip'));
      expect(cmd, isNot(contains('--purge')));
    });

    test('apt status: formattazione dpkg literal', () {
      final cmd = AppManager.buildAptStatusCommand('7zip');
      expect(cmd, contains(r'${db:Status-Status}'));
      expect(cmd, contains("-- '7zip'"));
    });

    test('snap', () {
      final cmd = AppManager.buildSnapRemoveCommand('firefox');
      expect(cmd, contains('snap remove'));
      expect(cmd, contains("'firefox'"));
    });

    test('flatpak con scope', () {
      expect(AppManager.buildFlatpakUninstallCommand('org.foo.Bar'),
          contains('flatpak uninstall -y'));
      expect(
          AppManager.buildFlatpakUninstallCommand('org.foo.Bar',
              scope: 'user'),
          contains('--user'));
      expect(
          AppManager.buildFlatpakUninstallCommand('org.foo.Bar',
              scope: 'system'),
          contains('--system'));
      expect(
          AppManager.buildFlatpakUninstallCommand('org.foo.Bar',
              scope: 'user'),
          contains("'org.foo.Bar'"));
    });

    test('pacman: solo il pacchetto, senza autoremove aggressivo', () {
      final cmd = AppManager.buildPacmanRemoveCommand('firefox');
      expect(cmd, contains('pacman -R --noconfirm'));
      expect(cmd, isNot(contains('-Rns')));
    });

    test('dnf con fallback yum e 127 se assente', () {
      final cmd = AppManager.buildDnfRemoveCommand('firefox');
      expect(cmd, contains('dnf remove -y'));
      expect(cmd, contains('yum remove -y'));
      expect(cmd, contains('exit 127'));
      expect(cmd, contains("'firefox'"));
    });

    test('shq escape correttamente gli apici singoli', () {
      expect(AppManager.shq("it's"), r"'it'\''s'");
      expect(AppManager.shq('plain'), "'plain'");
    });

    test('tutti i costruttori sono bash validi (bash -n, senza eseguire)',
        () async {
      final commands = [
        AppManager.buildAptRemoveCommand('7zip'),
        AppManager.buildAptStatusCommand('7zip'),
        AppManager.buildSnapRemoveCommand('firefox'),
        AppManager.buildSnapListCommand('firefox'),
        AppManager.buildFlatpakUninstallCommand('org.foo.Bar'),
        AppManager.buildFlatpakUninstallCommand('org.foo.Bar',
            scope: 'user'),
        AppManager.buildFlatpakUninstallCommand('org.foo.Bar',
            scope: 'system'),
        AppManager.buildFlatpakInfoCommand('org.foo.Bar', scope: 'system'),
        AppManager.buildPacmanRemoveCommand('firefox'),
        AppManager.buildPacmanQueryCommand('firefox'),
        AppManager.buildDnfRemoveCommand('firefox'),
        AppManager.buildRpmQueryCommand('firefox'),
        // Variante con pipe sudo, come la genera _run().
        'printf "%s\\n" "pw" | sudo -S ${AppManager.buildAptRemoveCommand('7zip')}',
        // Formato rpm con TAB/newline reali dentro gli apici singoli.
        "rpm -qa --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{SUMMARY}\n'",
      ];
      for (final cmd in commands) {
        final r = await Process.run('bash', ['-n', '-c', cmd]);
        expect(r.exitCode, 0,
            reason: 'bash -n fallito per: $cmd\n${r.stderr}');
      }
    });
  });

  // ==========================================================================
  // errorTail e rdepends
  // ==========================================================================
  group('errorTail', () {
    test('ultime 4 righe joinate, prime scartate', () {
      final tail = AppManager.errorTail('l1\nl2\nl3\nl4\nl5\nl6');
      expect(tail, 'l3 — l4 — l5 — l6');
    });

    test('righe vuote e prompt password scartati', () {
      final tail = AppManager.errorTail('Password:\n\nsudo: sorry\n\n');
      expect(tail, 'sudo: sorry');
    });

    test('output vuoto → null', () {
      expect(AppManager.errorTail(''), isNull);
      expect(AppManager.errorTail('\n  \n'), isNull);
    });

    test('troncamento a 300 caratteri', () {
      final long = 'x' * 500;
      final tail = AppManager.errorTail(long)!;
      expect(tail.length, lessThanOrEqualTo(301)); // + ellisse iniziale
      expect(tail.startsWith('…'), isTrue);
    });
  });

  group('parseAptRdepends', () {
    test('dedup, stop a Reverse Provides, esclusione self', () {
      const output = 'ffmpeg\n'
          'Reverse Depends:\n'
          '  yt-dlp\n'
          '  yt-dlp\n'
          '  imagemagick-6.q16\n'
          'Reverse Provides:\n'
          '  some-provider\n';
      final deps = AppManager.parseAptRdepends(output, 'ffmpeg');
      expect(deps, ['yt-dlp', 'imagemagick-6.q16']);
    });

    test('senza sezione → vuoto', () {
      expect(AppManager.parseAptRdepends('qualcosaltro\n', 'ffmpeg'), isEmpty);
    });
  });

  group('isSystemPackage', () {
    test('match esatto o substring noti', () {
      expect(AppManager.isSystemPackage('linux'), isTrue);
      expect(AppManager.isSystemPackage('kernel'), isTrue);
      expect(AppManager.isSystemPackage('glibc'), isTrue);
      expect(AppManager.isSystemPackage('linux-firmware'), isTrue);
      expect(AppManager.isSystemPackage('systemd'), isTrue);
      expect(AppManager.isSystemPackage('vlc'), isFalse);
      expect(AppManager.isSystemPackage('firefox'), isFalse);
    });
  });

  // ==========================================================================
  // Flussi di rimozione senza effetti collaterali (nomi invalidi)
  // ==========================================================================
  group('removeApp: guardie di validazione', () {
    test('nome apt con injection viene rifiutato senza eseguire nulla',
        () async {
      final result = await AppManager.removeApp(InstalledApp(
        name: 'foo; rm -rf /',
        packageManager: PackageManager.apt,
      ));
      expect(result.success, isFalse);
      expect(result.code, 'invalid-name');
    });

    test('nome snap invalido rifiutato', () async {
      final result = await AppManager.removeApp(InstalledApp(
        name: 'Foo Bar',
        packageManager: PackageManager.snap,
      ));
      expect(result.success, isFalse);
      expect(result.code, 'invalid-name');
    });

    test('entry gnome senza percorso fallisce con codice dedicato', () async {
      final result = await AppManager.removeApp(InstalledApp(
        name: 'Qualsiasi',
        packageManager: PackageManager.gnome,
      ));
      expect(result.success, isFalse);
      expect(result.code, 'no-desktop-file');
    });
  });

  // ==========================================================================
  // Esecuzione reale su questa macchina (lettura + flusso sicuro)
  // ==========================================================================
  group('macchina reale: elenchi', () {
    test('getAptApps: non vuoto, niente fantasmi, niente doppioni', () async {
      final apps = await AppManager.getAptApps();
      expect(apps, isNotEmpty);
      final names = apps.map((a) => a.name).toList();
      expect(names.toSet().length, names.length, reason: 'nomi duplicati');
      for (final name in names) {
        expect(RegExp(r'^[a-z0-9][a-z0-9+.-]*$').hasMatch(name), isTrue,
            reason: 'nome fantasma o non valido: "$name"');
      }
      expect(apps.any((a) => a.version == null), isFalse,
          reason: 'ogni pacchetto dpkg ha una versione');
    });

    test('getGnomeApps: ogni entry ha un .desktop reale e univoco', () async {
      final apps = await AppManager.getGnomeApps();
      expect(apps, isNotEmpty);
      final paths = <String>{};
      for (final app in apps) {
        expect(app.desktopFile, isNotNull, reason: app.name);
        expect(await File(app.desktopFile!).exists(), isTrue,
            reason: app.desktopFile);
        expect(paths.add(app.desktopFile!), isTrue,
            reason: 'percorso duplicato: ${app.desktopFile}');
        expect(app.name, isNotEmpty);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('getPacmanApps/getDnfApps non esplodono (assenti qui → vuoti)',
        () async {
      final pacman = await AppManager.getPacmanApps();
      final dnf = await AppManager.getDnfApps();
      expect(pacman, isA<List<InstalledApp>>());
      expect(dnf, isA<List<InstalledApp>>());
    });
  });

  group('macchina reale: rimozione .desktop creata dal test', () {
    test('crea, trova e rimuove un .desktop di esempio', () async {
      final home = Platform.environment['HOME']!;
      final dir = Directory('$home/.local/share/applications');
      await dir.create(recursive: true);
      final file = File('${dir.path}/slu-test-uninstall.desktop');
      await file.writeAsString(
          '[Desktop Entry]\nType=Application\nName=SLU Test Uninstall\n'
          'Comment=Creato dal test\nExec=/bin/true\n');
      try {
        final apps = await AppManager.getGnomeApps();
        final match = apps.where(
            (a) => a.desktopFile == file.path && a.name == 'SLU Test Uninstall');
        expect(match, hasLength(1),
            reason: 'il .desktop creato deve comparire esattamente una volta');

        final result = await AppManager.removeApp(match.first);
        expect(result.success, isTrue,
            reason: 'rimozione dovrebbe riuscire: ${result.message}');
        expect(await file.exists(), isFalse);
      } finally {
        if (await file.exists()) await file.delete();
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('rimozione flatpak id inesistente è idempotente (success)',
        () async {
      // L'id non esiste: la verifica "è ancora installato?" risponde no →
      // la rimozione è considerata riuscita (l'obiettivo è raggiunto).
      final result = await AppManager.removeApp(InstalledApp(
        name: 'Test',
        description: 'org.slu.this.does.not.exist',
        packageManager: PackageManager.flatpak,
        installation: 'user',
      ));
      expect(result.success, isTrue, reason: result.message);
      expect(result.code, isNull);
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
