import 'package:flutter_test/flutter_test.dart';
import 'package:super_linux_utility/services/recovery_service.dart';
import 'package:super_linux_utility/services/driver_manager_service.dart';

void main() {
  group('RecoveryService.parseDnfUpdateLines (dnf4 + dnf5)', () {
    test('righe pacchetto dnf4 (name.arch version repo)', () {
      const out = '''
Last metadata expiration check: 0:00:02 ago on Fri 27 Oct 2026.
kernel-core.x86_64                        6.9.5-200.fc40               updates
python3-libdnf5.noarch                    5.1.5-1.fc40                 updates
Obsoleting Packages
firefox.x86_64                            132.0-2.fc40                 updates
''';
      final lines = RecoveryService.parseDnfUpdateLines(out);
      expect(lines.length, 3);
      expect(lines[0], contains('kernel-core.x86_64'));
      expect(lines[1], contains('python3-libdnf5.noarch'));
      expect(lines[2], contains('firefox.x86_64'));
    });

    test('rumore dnf5 scartato (Repository updates, transaction, ecc.)', () {
      const out = '''
Updating and loading repositories:
Repositories loaded.
kernel.x86_64         6.10.0-100.fc40     updates
Downloading Packages:
Running transaction
Transaction failed: Un/iso something
is this ok [y/N]:
''';
      final lines = RecoveryService.parseDnfUpdateLines(out);
      expect(lines.length, 1);
      expect(lines[0], startsWith('kernel.x86_64'));
    });

    test('update SOLO con arch e newline finale misto al marker RC', () {
      const out = '''
kernel-core.x86_64    6.9__DNF_RC__:100
''';
      final body = out
          .split('\n')
          .map((l) => l.replaceAll(RegExp(r'__DNF_RC__:\d+'), ''))
          .join('\n');
      final lines = RecoveryService.parseDnfUpdateLines(body);
      expect(lines.length, 1);
      expect(lines[0], startsWith('kernel-core.x86_64'));
    });

    test('output vuoto → 0 righe', () {
      expect(RecoveryService.parseDnfUpdateLines(''), isEmpty);
      expect(
          RecoveryService.parseDnfUpdateLines('Last metadata expiration ...'),
          isEmpty);
    });

    test('errori localizzati scartati', () {
      const out = '''
Errore: errore di une dipendenze
kernel.x86_64    1.0    updates
''';
      final lines = RecoveryService.parseDnfUpdateLines(out);
      expect(lines.length, 1);
    });
  });

  group('RecoveryService.dnfPackageNameFromLine', () {
    test('name.arch → name', () {
      expect(
          RecoveryService.dnfPackageNameFromLine(
              'kernel-core.x86_64    6.9.5-200.fc40    updates'),
          'kernel-core');
      expect(RecoveryService.dnfPackageNameFromLine('python3-libdnf5.noarch'),
          'python3-libdnf5');
    });
    test('nome senza arch resta invariato', () {
      expect(RecoveryService.dnfPackageNameFromLine('firefox'), 'firefox');
    });
    test('suffisso arch-ben formato rifiutato se non è un arch', () {
      // "1.0" dopo il punto non è un arch: non viene strip
      expect(
          RecoveryService.dnfPackageNameFromLine(
              'something.wrong   2:1.0-1'),
          'something.wrong');
    });
  });

  group('DriverManagerService.parseInstalledPackages', () {
    test('apt: dpkg-query con status', () {
      const out = '''
nvidia-driver-580\t580.95.05-0ubuntu1\tinstalled
some-old-pkg\t1.0\tconfig-files
cups\t2.4.2\tinstalled
''';
      final map = DriverManagerService.parseInstalledPackages(out, 'apt');
      expect(map['nvidia-driver-580'], '580.95.05-0ubuntu1');
      expect(map.containsKey('some-old-pkg'), isFalse,
          reason: 'il pacchetto rimosso (config-files) NON conta installato');
      expect(map['cups'], '2.4.2');
    });

    test('rpm -qa (dnf/zypper): name<TAB>version-release', () {
      const out = '''
xorg-x11-drv-nvidia\t580.105.08-2.fc41
kernel-core\t6.9.5-200.fc40
''';
      final map = DriverManagerService.parseInstalledPackages(out, 'dnf');
      expect(map['xorg-x11-drv-nvidia'], '580.105.08-2.fc41');
      expect(map['kernel-core'], '6.9.5-200.fc40');
    });

    test('pacman: name version', () {
      const out = '''
nvidia-dkms 575.57.08-1
mesa 1:25.0.5-1
''';
      final map = DriverManagerService.parseInstalledPackages(out, 'pacman');
      expect(map['nvidia-dkms'], '575.57.08-1');
      expect(map['mesa'], '1:25.0.5-1');
    });
  });

  group('DriverManagerService.matchInstalledPackages', () {
    const nvidiaPatterns = [
      r'^nvidia-driver-[0-9]+$',
      r'^libnvidia-',
      r'^xorg-x11-drv-nvidia($|-cuda)?$',
      r'^akmod-nvidia$',
      r'^nvidia-(dkms|open|utils)?$',
      r'^nvidia-glG06$',
    ];

    test('match pacchetto nvidia-driver-NNN su sistemi apt (versione reale)', () {
      final db = {
        'nvidia-driver-580': '580.95.05-0ubuntu1',
        'nvidia-driver-580-utils': '580.95.05-0ubuntu1',
        'kernel': '6.9.0',
      };
      final m = DriverManagerService.matchInstalledPackages(db, nvidiaPatterns);
      expect(m.map((e) => e.key), contains('nvidia-driver-580'));
      expect(
          m.firstWhere((e) => e.key == 'nvidia-driver-580').value,
          '580.95.05-0ubuntu1');
    });

    test('match xorg-x11-drv-nvidia su Fedora e nvidia-glG06 su openSUSE', () {
      final db = {
        'xorg-x11-drv-nvidia': '580.105.08-2.fc41',
        'akmod-nvidia': '3:580.105.08-1.fc41',
      };
      final m1 = DriverManagerService.matchInstalledPackages(db, nvidiaPatterns);
      expect(m1.map((e) => e.key),
          containsAll(['xorg-x11-drv-nvidia', 'akmod-nvidia']));
      final m2 = DriverManagerService.matchInstalledPackages(
          {'nvidia-glG06': 'G06-580'}, nvidiaPatterns);
      expect(m2.single.key, 'nvidia-glG06');
    });

    test('pattern invalido ignorato senza crash', () {
      final db = {'foo': '1.0'};
      final m = DriverManagerService.matchInstalledPackages(db, ['[']);
      expect(m, isEmpty);
    });

    test('nessun match → lista vuota (status resta available)', () {
      final db = {'mesa': '1.0'};
      final m = DriverManagerService.matchInstalledPackages(db, nvidiaPatterns);
      expect(m, isEmpty);
    });
  });
}
