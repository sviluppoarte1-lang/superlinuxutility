import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/services/dependency_check_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isSystemTraySupported', () {
    test('rispecchia la realtà della macchina (indipendente dal servizio)',
        () async {
      // Verifica indipendente e volutamente diversa dall'implementazione:
      // presenza di libayatana-appindicator3 via ldconfig o find.
      final probe = await Process.run('bash', ['-c', r'''
if ldconfig -p 2>/dev/null | grep -q 'libayatana-appindicator3\.so\.1'; then
  echo yes
elif find /usr/lib /usr/lib64 /lib /lib64 /usr/lib/x86_64-linux-gnu \
    -maxdepth 2 -name 'libayatana-appindicator3.so*' 2>/dev/null | grep -q .; then
  echo yes
else
  echo no
fi
''']);
      final expected = probe.stdout.toString().trim() == 'yes';

      final supported =
          await DependencyCheckService.isSystemTraySupported();

      expect(supported, expected,
          reason: 'Il servizio deve tornare true SOLO se la libreria '
              'ayatana è realmente presente (in passato tornava SEMPRE true: '
              'il check leggeva l\'exit code di `echo \$?`, sempre 0, e su '
              'Fedora le librerie mancanti venivano date per presenti).');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('è un Future<bool> e non lancia eccezioni', () async {
      final result = DependencyCheckService.isSystemTraySupported();
      expect(result, isA<Future<bool>>());
      final value = await result;
      expect(value, isA<bool>());
    });
  });

  group('getSystemTrayInstallCommand', () {
    test('su questa macchina (APT) ritorna il comando apt o null senza crash',
        () async {
      final cmd =
          await DependencyCheckService.getSystemTrayInstallCommand();
      expect(cmd, anyOf(isNull, contains('apt-get'), contains('pacman')));
      if (cmd != null) {
        expect(cmd, contains('libayatana-appindicator3-1'),
            reason: 'Il pacchetto installato deve essere ayatana (legacy '
                'libappindicator-gtk3 non esiste più su Fedora e non serve '
                'oltre ad ayatana)');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
