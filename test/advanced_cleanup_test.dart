import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:super_linux_utility/services/advanced_cleanup_service.dart';

void main() {
  group('parseJournalDiskUsage', () {
    test('GB con decimali', () {
      expect(
          AdvancedCleanupService.parseJournalDiskUsage(
              'Journals take up 1.2G on disk.'),
          1288490189);
    });
    test('MB interi', () {
      expect(
          AdvancedCleanupService.parseJournalDiskUsage(
              'Archived and active journals take up 850M in the file system.'),
          850 * 1024 * 1024);
    });
    test('KB', () {
      expect(
          AdvancedCleanupService.parseJournalDiskUsage(
              'Journals take up 96K.'),
          96 * 1024);
    });
    test('output non valido -> null', () {
      expect(AdvancedCleanupService.parseJournalDiskUsage('niente log'), isNull);
      expect(AdvancedCleanupService.parseJournalDiskUsage(''), isNull);
    });
  });

  group('parseDockerReclaimable', () {
    test('somma percentuali reclamabili', () {
      const out = 'TYPE  TOTAL  ACTIVE  SIZE  RECLAIMABLE\n'
          'Images  5  2  2.5GB  1.8GB (72%)\n'
          'Containers  3  0  120MB  120MB (100%)\n'
          'Local Volumes  1  0  50MB  50MB (100%)\n';
      final bytes = AdvancedCleanupService.parseDockerReclaimable(out);
      expect(bytes,
          (1.8 * 1024 * 1024 * 1024 + 170 * 1024 * 1024).round());
    });
    test('output vuoto -> 0', () {
      expect(AdvancedCleanupService.parseDockerReclaimable(''), 0);
    });
  });

  group('filterOldKernelPackagesApt', () {
    const all = [
      'linux-image-6.8.0-52-generic',
      'linux-headers-6.8.0-52-generic',
      'linux-image-6.8.0-60-generic',
      'linux-headers-6.8.0-60-generic',
      'linux-modules-6.8.0-60-generic',
      'linux-image-generic',
      'linux-headers-generic',
    ];

    test('tiene in uso + ultimo, rimuove il resto', () {
      final old = AdvancedCleanupService.filterOldKernelPackagesApt(
          all, '6.8.0-60-generic');
      expect(old, containsAll([
        'linux-image-6.8.0-52-generic',
        'linux-headers-6.8.0-52-generic',
      ]));
      expect(old, isNot(contains('linux-image-6.8.0-60-generic')));
      expect(old, isNot(contains('linux-image-generic')));
      expect(old, isNot(contains('linux-headers-generic')));
    });

    test('con kernel vecchio avviato tiene anche quello', () {
      final old = AdvancedCleanupService.filterOldKernelPackagesApt(
          all, '6.8.0-52-generic');
      expect(old, isNot(contains('linux-image-6.8.0-52-generic')));
      // Rimuove solo 6.8.0-60? No: 60 è l'ultimo (scorta) -> resta.
      expect(old, isEmpty);
    });

    test('lista vuota -> vuota', () {
      expect(AdvancedCleanupService.filterOldKernelPackagesApt(
          [], '6.8.0-60-generic'), isEmpty);
    });
  });

  group('filterOldKernelPackagesDnf', () {
    test('tiene 2 per nome, rimuove i più vecchi (mai in uso)', () {
      const all = [
        'kernel-core-6.5.6-200.fc38.x86_64',
        'kernel-core-6.6.9-200.fc39.x86_64',
        'kernel-core-6.7.4-200.fc39.x86_64',
      ];
      final old = AdvancedCleanupService.filterOldKernelPackagesDnf(
          all, '6.7.4-200.fc39.x86_64');
      expect(old, ['kernel-core-6.5.6-200.fc38.x86_64']);
    });

    test('con 2 soli kernel non tocca nulla', () {
      const all = [
        'kernel-core-6.6.9-200.fc39.x86_64',
        'kernel-core-6.7.4-200.fc39.x86_64',
      ];
      final old = AdvancedCleanupService.filterOldKernelPackagesDnf(
          all, '6.7.4-200.fc39.x86_64');
      expect(old, isEmpty);
    });
  });

  group('buildJournalLimitCommand', () {
    test('contiene size, drop-in e vacuum', () {
      final cmd = AdvancedCleanupService.buildJournalLimitCommand('500M');
      expect(cmd, contains('SystemMaxUse=500M'));
      expect(cmd, contains('99-slu-limit.conf'));
      expect(cmd, contains('journalctl --vacuum-size=500M'));
      expect(cmd, contains('systemctl restart systemd-journald'));
    });

    test('niente apici singoli (romperebbero il quoting sudo)', () {
      for (final s in ['100M', '500M', '1G', '2G']) {
        expect(AdvancedCleanupService.buildJournalLimitCommand(s),
            isNot(contains("'")));
      }
    });

    test('tutto gira sotto un unico bash elevato', () {
      final cmd = AdvancedCleanupService.buildJournalLimitCommand('1G');
      // Un solo flusso && : mkdir, scrittura, restart e vacuum insieme.
      expect('&&'.allMatches(cmd).length, greaterThanOrEqualTo(3));
    });
  });

  group('sysfs reale (questo container)', () {
    test('getDevCaches non lancia mai', () async {
      final list = await AdvancedCleanupService.getDevCaches();
      expect(list, isA<List>());
    });

    test('getJournalBytes: numero o null, mai eccezione', () async {
      final v = await AdvancedCleanupService.getJournalBytes();
      expect(v == null || v >= 0, isTrue);
    });

    test('vacuum con formato errato rifiutato senza sudo', () async {
      expect(await AdvancedCleanupService.vacuumJournal('abc'), isFalse);
      expect(await AdvancedCleanupService.setJournalSystemMaxUse('10X'),
          isFalse);
    });

    test('cleanDevCache con id sconosciuto -> false', () async {
      expect(await AdvancedCleanupService.cleanDevCache('no-such-id'),
          isFalse);
    });
  });

  group('filterOldSnapRevisions', () {
    const current = 'Nome Versione Rev Tracciamento Publisher Note\n'
        'core24 1.0 2124 latest/stable canonical** -\n'
        'cups 2.4 1238 latest/stable openprinting -\n';
    const all = 'Nome Versione Rev Tracciamento Publisher Note\n'
        'core24 1.0 2124 latest/stable canonical** -\n'
        'core24 1.0 1643 latest/stable canonical** disabilitato\n'
        'cups 2.4 1238 latest/stable openprinting -\n'
        'cups 2.4 1229 latest/stable openprinting '
        'disabilitato,malfunzionante\n'
        'android-studio 2026.1 241 latest/stable snapcrafters* '
        'disabilitato\n';

    test('isola le revisioni non correnti', () {
      final old =
          AdvancedCleanupService.filterOldSnapRevisions(current, all);
      expect(old.map((e) => '${e.name} ${e.rev}').toSet(), {
        'core24 1643',
        'cups 1229',
        'android-studio 241',
      });
    });

    test('intestazione localizzata saltata (inglese o italiano)', () {
      final old = AdvancedCleanupService.filterOldSnapRevisions(
        'Name Version Rev Tracking Publisher Notes\n'
        'core24 1.0 2124 latest/stable canonical** -\n',
        'Name Version Rev Tracking Publisher Notes\n'
        'core24 1.0 2124 latest/stable canonical** -\n'
        'core24 1.0 1643 latest/stable canonical** disabled\n',
      );
      expect(old.single.name, 'core24');
      expect(old.single.rev, '1643');
    });

    test('output vuoto o snap list fallito -> lista vuota', () {
      expect(
          AdvancedCleanupService.filterOldSnapRevisions('', ''), isEmpty);
      // `snap list` fallito ma `--all` ok: non proporre nulla.
      expect(
          AdvancedCleanupService.filterOldSnapRevisions(
              '', 'Nome Version Rev\nfoo 1 2\n'),
          isEmpty);
      expect(
          AdvancedCleanupService.filterOldSnapRevisions(
              'Nome Version Rev\nfoo 1 2\n', ''),
          isEmpty);
    });

    test('righe con rev non numerica o nome non valido saltate', () {
      final old = AdvancedCleanupService.filterOldSnapRevisions(
        'Nome Version Rev\nfoo 1 2\n',
        'Nome Version Rev\n'
        'foo 1 2\n'
        'foo 1 xyz\n'
        'Foo 1 3\n'
        'bar 1 4\n',
      );
      expect(old.map((e) => e.name).toList(), ['bar']);
    });
  });

  group('parseFlatpakUnusedRows', () {
    test('riga tab-separated della tabella operazioni (con arch)', () {
      const out = '\n'
          '\n'
          ' 1.\t   \torg.freedesktop.Platform.VAAPI.nvidia\t25.08\tr\n'
          '\n'
          'Proceed with these changes to the system installation? '
          '[Y/n]: \n';
      final rows = AdvancedCleanupService.parseFlatpakUnusedRows(out);
      expect(rows, hasLength(1));
      expect(rows.single.name, 'org.freedesktop.Platform.VAAPI.nvidia');
      expect(rows.single.branch, '25.08');
    });

    test('riga senza colonna arch (4 campi)', () {
      const out = ' 2.\torg.example.App\t1.0\tr\n';
      final rows = AdvancedCleanupService.parseFlatpakUnusedRows(out);
      expect(rows.single.name, 'org.example.App');
      expect(rows.single.branch, '1.0');
    });

    test('sezione pinned e "Nothing unused" ignorate', () {
      const out = "These runtimes in installation 'user' are pinned and "
          "won't be removed; see flatpak-pin(1):\n"
          '  runtime/org.freedesktop.Platform.GL.nvidia/x86_64/1.4\n'
          'Nothing unused to uninstall\n';
      expect(AdvancedCleanupService.parseFlatpakUnusedRows(out), isEmpty);
    });

    test('output vuoto -> vuoto', () {
      expect(AdvancedCleanupService.parseFlatpakUnusedRows(''), isEmpty);
    });
  });

  group('parseFlatpakSize', () {
    test('punto decimale (LC_ALL=C)', () {
      expect(AdvancedCleanupService.parseFlatpakSize('668.9 MB'),
          (668.9 * 1024 * 1024).round());
    });

    test('virgola decimale + NBSP (locale italiana)', () {
      expect(AdvancedCleanupService.parseFlatpakSize('20,7\u00a0MB'),
          (20.7 * 1024 * 1024).round());
    });

    test('carattere sporco tra numero e unità', () {
      expect(AdvancedCleanupService.parseFlatpakSize('668.9?MB'),
          (668.9 * 1024 * 1024).round());
    });

    test('gigabyte', () {
      expect(AdvancedCleanupService.parseFlatpakSize('1.5 GB'),
          (1.5 * 1024 * 1024 * 1024).round());
    });

    test('testo non valido -> 0', () {
      expect(AdvancedCleanupService.parseFlatpakSize(''), 0);
      expect(AdvancedCleanupService.parseFlatpakSize('n/a'), 0);
    });
  });

  group('buildCudaCleanupCommand', () {
    test('contiene rm, ld.so, alternatives, ldconfig', () {
      final cmd = AdvancedCleanupService.buildCudaCleanupCommand(
          '/usr/local/cuda-13.0', ['/usr/local/cuda-13.1']);
      expect(cmd, contains('rm -rf "/usr/local/cuda-13.1"'));
      expect(cmd, contains('/etc/ld.so.conf.d/*.conf'));
      expect(cmd, contains('update-alternatives --list'));
      expect(cmd, contains('update-alternatives --set'));
      expect(cmd, contains('ldconfig'));
      expect(cmd, contains(r'${v#/usr/local/cuda-13.1}'));
      expect(cmd, contains('nv="/usr/local/cuda-13.0'));
      expect(cmd.trimRight(), endsWith(r'[ "$fail" -eq 0 ]'));
    });

    test('più duplicati -> più rm e più rami case', () {
      final cmd = AdvancedCleanupService.buildCudaCleanupCommand(
          '/usr/local/cuda-13.0',
          ['/usr/local/cuda-12.4', '/usr/local/cuda-13.1']);
      expect('rm -rf'.allMatches(cmd).length, 2);
      expect(cmd, contains('/usr/local/cuda-12.4'));
      expect(cmd, contains('/usr/local/cuda-13.1'));
    });

    test('nessun apice singolo (romperebbe il quoting sudo)', () {
      final cmd = AdvancedCleanupService.buildCudaCleanupCommand(
          '/usr/local/cuda-13.0', ['/usr/local/cuda-13.1']);
      expect(cmd, isNot(contains("'")));
    });

    test('sintassi bash valida (bash -n, senza eseguire)', () async {
      final cmd = AdvancedCleanupService.buildCudaCleanupCommand(
          '/usr/local/cuda-13.0',
          ['/usr/local/cuda-12.4', '/usr/local/cuda-13.1']);
      final r = await Process.run('bash', ['-n', '-c', cmd]);
      expect(r.exitCode, 0, reason: r.stderr.toString());
    });
  });
}
