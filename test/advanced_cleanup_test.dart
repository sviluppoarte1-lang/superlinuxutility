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
  });
}
