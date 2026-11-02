import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/screens/optimizer_wizard_screen.dart';
import 'package:super_linux_utility/services/system_optimizer_service.dart';

void main() {
  group('parseUnitFiles', () {
    test('stati e spazi multipli', () {
      const out = '''
bluetooth.service                   enabled
cups.service                        disabled
avahi-daemon.service                enabled
ssh.service                         static
''';
      final m = SystemOptimizerService.parseUnitFiles(out);
      expect(m['bluetooth.service'], 'enabled');
      expect(m['cups.service'], 'disabled');
      expect(m['avahi-daemon.service'], 'enabled');
      expect(m['ssh.service'], 'static');
      expect(m, hasLength(4));
    });

    test('righe non-unit ignorate', () {
      const out = 'UNIT FILE    STATE\ncups.service   enabled\n';
      final m = SystemOptimizerService.parseUnitFiles(out);
      expect(m.keys, ['cups.service']);
    });
  });

  group('parseListUnits', () {
    test('colonna ActiveState con marker ●', () {
      const out = '''
  cups.service    loaded active   running   CUPS Scheduler
●  failed.service  loaded failed  failed    Broken
  avahi.service   loaded inactive  dead      Avahi
''';
      final m = SystemOptimizerService.parseListUnits(out);
      expect(m['cups.service'], 'active');
      expect(m['failed.service'], 'failed');
      expect(m['avahi.service'], 'inactive');
    });
  });

  group('parseBlame', () {
    test('solo unit >= 2s, con conversione ms/min', () {
      const out = '''
12.5s   cups.service
950ms   quick.service
1.5s    tiny.service
3min    slow.service
15min 23.914s fstrim.service
12.5s   not-a-service.target
''';
      final m = SystemOptimizerService.parseBlame(out);
      expect(m['cups.service'], '12.5s');
      expect(m.containsKey('quick.service'), isFalse);
      expect(m.containsKey('tiny.service'), isFalse);
      expect(m['slow.service'], '3.0m');
      expect(m['fstrim.service'], '15.4m');
      expect(m.containsKey('not-a-service.target'), isFalse);
    });
  });

  group('parseShow', () {
    test('raggruppamento per Id', () {
      const out = '''
Id=cups.service
Description=CUPS Scheduler
ActiveState=inactive
NRestarts=3
Id=avahi.service
Description=Avahi mDNS
ActiveState=active
''';
      final m = SystemOptimizerService.parseShow(out);
      expect(m, hasLength(2));
      expect(m['cups.service']!['Description'], 'CUPS Scheduler');
      expect(m['cups.service']!['NRestarts'], '3');
      expect(m['avahi.service']!['ActiveState'], 'active');
    });

    test('valori con uguali e campi vuoti', () {
      const out = '''
Id=x.service
Description=a=b
ActiveEnterTimestamp=
''';
      final m = SystemOptimizerService.parseShow(out);
      expect(m['x.service']!['Description'], 'a=b');
      expect(m['x.service']!['ActiveEnterTimestamp'], '');
    });
  });

  group('parseTimestamp', () {
    test('data locale systemd', () {
      final d = SystemOptimizerService
          .parseTimestamp('Mon 2026-10-27 10:00:00 CEST');
      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 10);
      expect(d.day, 27);
      expect(d.hour, 10);
    });

    test('stringa vuota o invalida → null', () {
      expect(SystemOptimizerService.parseTimestamp(''), isNull);
      expect(SystemOptimizerService.parseTimestamp('n/a'), isNull);
    });
  });

  group('parseXbel + usageFor', () {
    const xbel = '''<?xml version="1.0" encoding="UTF-8"?>
<xbel version="1.0">
  <bookmark href="file:///usr/bin/firefox"
      modified="2026-10-28T10:00:00.000000Z">
    <info><metadata owner="http://freedesktop.org">
      <bookmark:applications>
        <bookmark:application name="firefox" exec="firefox %u"
            modified="2026-10-28T10:00:00.000000Z" count="5"/>
      </bookmark:applications>
    </metadata></info>
  </bookmark>
  <bookmark href="file:///opt/Old/app.AppImage"
      modified="2026-08-01T09:00:00.000000Z">
    <info><metadata owner="http://freedesktop.org">
      <bookmark:applications>
        <bookmark:application name="OldApp" exec="/opt/Old/app.AppImage %U"
            modified="2026-08-01T09:00:00.000000Z"/>
      </bookmark:applications>
    </metadata></info>
  </bookmark>
</xbel>''';

    test('conteggi ultimi 30 giorni e ultimo uso', () {
      final now = DateTime(2026, 11, 2);
      final u = SystemOptimizerService.parseXbel(xbel, now: now);
      expect(u.count30d['firefox'], 1);
      expect(u.count30d.containsKey('oldapp'), isFalse);
      expect(u.lastUsed['firefox']!.year, 2026);
      expect(u.lastUsed['oldapp']!.month, 8);
      // Anche il basename dell'exec e dell'href sono chiavi.
      expect(u.lastUsed.containsKey('app.appimage'), isTrue);
    });

    test('usageFor somma nome e basename comando', () {
      final now = DateTime(2026, 11, 2);
      final u = SystemOptimizerService.parseXbel(xbel, now: now);
      final (count, last) =
          SystemOptimizerService.usageFor(u, 'Firefox', 'firefox %u');
      expect(count, 1);
      expect(last, isNotNull);
      final (c2, _) = SystemOptimizerService
          .usageFor(u, 'Missing', '/nonexistent/tool');
      expect(c2, 0);
    });

    test('xbel vuoto → nessun uso', () {
      final u = SystemOptimizerService.parseXbel('');
      expect(u.count30d, isEmpty);
      expect(u.lastUsed, isEmpty);
    });
  });

  group('isProtectedUnit (servizi inamovibili)', () {
    const protected = [
      'systemd-journald.service',
      'systemd-logind.service',
      'dbus.service',
      'dbus-broker.service',
      'polkit.service',
      'NetworkManager.service',
      'wpa_supplicant.service',
      'gdm.service',
      'sddm.service',
      'lightdm.service',
      'pipewire.service',
      'wireplumber.service',
      'pulseaudio.service',
      'accounts-daemon.service',
      'upower.service',
      'udisks2.service',
      'gvfs-daemon.service',
      'rtkit-daemon.service',
      'getty@tty1.service',
      'user@1000.service',
      'cron.service',
      'ufw.service',
      'apparmor.service',
    ];
    test('tutti protetti', () {
      for (final u in protected) {
        expect(SystemOptimizerService.isProtectedUnit(u), isTrue,
            reason: '$u deve essere protetto');
      }
    });

    const proposable = [
      'bluetooth.service',
      'cups.service',
      'avahi-daemon.service',
      'ModemManager.service',
      'snapd.service',
      'docker.service',
      'teamviewer.service',
      'anydesk.service',
      'tailscaled.service',
      'libvirtd.service',
      'mysql.service',
      'some-third-party.service',
    ];
    test('unit del DB opzionale mai bloccate dalla denylist', () {
      for (final u in proposable) {
        expect(SystemOptimizerService.isProtectedUnit(u), isFalse,
            reason: '$u deve essere valutabile');
      }
    });
  });

  group('extractExecutable', () {
    test('comando semplice con argomenti', () {
      expect(SystemOptimizerService.extractExecutable('firefox %u'),
          'firefox');
    });

    test('percorso tra virgolette', () {
      expect(
          SystemOptimizerService.extractExecutable('"/opt/My App/run" --flag'),
          '/opt/My App/run');
    });

    test('prefissi env rimossi', () {
      expect(
          SystemOptimizerService.extractExecutable('env GDK_BACKEND=x11 foo'),
          'foo');
      expect(SystemOptimizerService.extractExecutable('LANG=it foo'), 'foo');
    });

    test('tilde espansa con HOME', () {
      final exe = SystemOptimizerService.extractExecutable('~/bin/tool');
      expect(exe, startsWith('/'));
      expect(exe, endsWith('/bin/tool'));
    });

    test('comando vuoto → null', () {
      expect(SystemOptimizerService.extractExecutable('  '), isNull);
    });
  });

  test('scan reale: struttura coerente (systemd di questa macchina)',
      () async {
    final r = await SystemOptimizerService.scan()
        .timeout(const Duration(minutes: 2));
    if (!r.hasSystemd) return; // macchina senza systemd: niente da verificare
    expect(r.servicesScanned, greaterThan(0));
    expect(r.services, isA<List<ServiceCandidate>>());
    // Nessun servizio inamovibile può mai comparire nei candidati.
    for (final c in r.services) {
      expect(SystemOptimizerService.isProtectedUnit(c.unit), isFalse,
          reason: '${c.unit} è inamovibile e non deve essere proposto');
      expect(c.descKey, startsWith('optSvc'));
      expect(c.evidence, isNotEmpty);
    }
    expect(r.startupApps, isA<List<StartupCandidate>>());
    for (final a in r.startupApps) {
      expect(a.app.desktopFile, isNotNull);
      expect(a.evidence, isNotEmpty);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('wizard mostra intro con titolo e pulsante scansione',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const OptimizerWizardScreen(),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Optimization wizard'), findsOneWidget);
    expect(find.text('Start scan'), findsOneWidget);
    // Le evidenze del DB servizi esistono in l10n (chiavi tradotte).
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
