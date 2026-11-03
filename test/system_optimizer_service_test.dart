import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/models/startup_app.dart';
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

  group('executableExists (regressione comandi in PATH)', () {
    test('percorso assoluto: controllo diretto', () {
      expect(SystemOptimizerService.executableExists('/bin/sh'), isTrue);
      expect(SystemOptimizerService.executableExists('/nonexistent/slu-nope-xyz'),
          isFalse);
    });

    test('nome in PATH non è "mancante" (caso xdg-* / flatpak / orca)', () {
      // I .desktop usano spesso il NOME in PATH: il vecchio check
      // `File(exe).existsSync()` risolveva un nome relativo contro la cwd →
      // SEMPRE false → app preselezionate a torto con "eseguibile mancante".
      expect(SystemOptimizerService.executableExists('sh'), isTrue);
      expect(
          SystemOptimizerService.executableExists('slu-no-such-binary-xyz'),
          isFalse);
      // xdg-user-dirs-update è il caso reale segnalato; assert solo se
      // installato (il test deve restare verde anche senza xdg-user-dirs).
      if (File('/usr/bin/xdg-user-dirs-update').existsSync()) {
        expect(
            SystemOptimizerService.executableExists('xdg-user-dirs-update'),
            isTrue);
      }
      if (File('/usr/bin/xdg-user-dirs-gtk-update').existsSync()) {
        expect(
            SystemOptimizerService.executableExists('xdg-user-dirs-gtk-update'),
            isTrue);
      }
    });

    test('stringa vuota → false', () {
      expect(SystemOptimizerService.executableExists(''), isFalse);
    });
  });

  group('evaluateStartupApp (voci NoDisplay / abitudini)', () {
    final now = DateTime(2026, 11, 2);
    final empty = OptimizerUsage(count30d: const {}, lastUsed: const {});

    StartupApp app({
      required String command,
      bool enabled = true,
      bool protected = false,
      bool noDisplay = false,
      String? file = '/etc/xdg/autostart/demo.desktop',
      String name = 'Demo App',
    }) =>
        StartupApp(
          name: name,
          command: command,
          isEnabled: enabled,
          desktopFile: file,
          isProtected: protected,
          noDisplay: noDisplay,
        );

    test('voce NoDisplay non è MAI proposta sull\'uso (xdg, nm-applet)',
        () {
      // Lo storico recently-used.xbel registra i file aperti: un semaforo
      // di sistema non apre file → zero record SEMPRE → veniva preselezionato
      // a torto come "non utilizzata".
      final c = SystemOptimizerService.evaluateStartupApp(
        app(command: r"/bin/sh -c 'nm-applet'", noDisplay: true,
            name: 'NetworkManager Applet',
            file: '/etc/xdg/autostart/nm-applet.desktop'),
        empty,
        usageAvailable: true,
        now: now,
      );
      expect(c, isNull,
          reason: 'NoDisplay=true: nessun record di uso non prova nulla');
    });

    test('voce NoDisplay con binario MANCANTE resta proponibile', () {
      final c = SystemOptimizerService.evaluateStartupApp(
        app(command: '/nonexistent/slu-notifier', noDisplay: true),
        empty,
        usageAvailable: true,
        now: now,
      );
      expect(c, isNotNull);
      expect(c!.evidence, ['missingBinary']);
      expect(c.preselected, isTrue);
    });

    test('exe sotto /usr/lib (componente di sistema) → non proposta', () {
      // Caso reale: xapp-sn-watcher (watcher della tray) non dichiara
      // NoDisplay ma è un agente di background in /usr/lib.
      final c = SystemOptimizerService.evaluateStartupApp(
        app(
            command:
                '/usr/lib/x86_64-linux-gnu/xapps/xapp-sn-watcher --foo',
            name: 'xapp-sn-watcher',
            file: '/etc/xdg/autostart/xapp-sn-watcher.desktop'),
        empty,
        usageAvailable: true,
        now: now,
      );
      expect(c, isNull,
          reason: 'un eseguibile in /usr/lib è un componente di sistema');
    });

    test('componente di sistema con binario mancante → comunque proposto', () {
      final c = SystemOptimizerService.evaluateStartupApp(
        app(command: '/usr/lib/x86_64-linux-gnu/libexec/slu-notifier',
            noDisplay: true),
        empty,
        usageAvailable: true,
        now: now,
      );
      expect(c, isNotNull);
      expect(c!.evidence, ['missingBinary']);
      expect(c.preselected, isTrue);
    });

    test('app visibile mai vista nello storico → preselezionata', () {
      final c = SystemOptimizerService.evaluateStartupApp(
        app(command: r"/bin/sh -c 'mychat'"),
        empty,
        usageAvailable: true,
        now: now,
      );
      expect(c, isNotNull);
      expect(c!.evidence, ['unusedApp']);
      expect(c.preselected, isTrue);
      expect(c.risk, OptimizerRisk.safe);
    });

    test('app visibile usata ieri → non toccata', () {
      // usageFor cerca per nome app (minuscolo) e basename comando: qui la
      // chiave è il nome display ("Demo App" → "demo app").
      final usage = OptimizerUsage(
        count30d: const {'demo app': 4},
        lastUsed: {'demo app': now.subtract(const Duration(days: 1))},
      );
      expect(
        SystemOptimizerService.evaluateStartupApp(
            app(command: r"/bin/sh -c 'mychat'"), usage,
            usageAvailable: true, now: now),
        isNull,
      );
    });

    test('app visibile usata 40gg fa → preselezionata come inutilizzata', () {
      final usage = OptimizerUsage(
        count30d: const {},
        lastUsed: {'demo app': now.subtract(const Duration(days: 40))},
      );
      final c = SystemOptimizerService.evaluateStartupApp(
          app(command: r"/bin/sh -c 'mychat'"), usage,
          usageAvailable: true, now: now);
      expect(c, isNotNull);
      expect(c!.preselected, isTrue);
      expect(c.uses30d, 0);
    });

    test('senza storico abitudini → nessuna proposta per app normali', () {
      expect(
        SystemOptimizerService.evaluateStartupApp(
            app(command: r"/bin/sh -c 'mychat'"), empty,
            usageAvailable: false, now: now),
        isNull,
      );
    });

    test('disabilitata / protetta / senza .desktop → sempre null', () {
      final base = OptimizerUsage(count30d: const {}, lastUsed: const {});
      expect(
          SystemOptimizerService.evaluateStartupApp(
              app(command: 'sh', enabled: false), base,
              usageAvailable: true, now: now),
          isNull);
      expect(
          SystemOptimizerService.evaluateStartupApp(
              app(command: 'sh', protected: true), base,
              usageAvailable: true, now: now),
          isNull);
      expect(
          SystemOptimizerService.evaluateStartupApp(
              app(command: 'sh', file: null), base,
              usageAvailable: true, now: now),
          isNull);
    });
  });

  testWidgets('OptimizerDoneView: Chiudi usa il callback, senza poppare',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: OptimizerDoneView(
            result: const OptimizerApplyResult(
              servicesDisabled: 3,
              appsDisabled: 4,
              errors: ['x.service'],
            ),
            onClose: () => closed++,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Optimization complete'), findsOneWidget);
    expect(find.textContaining('Disabled 3 system services and 4 startup apps'),
        findsOneWidget);
    expect(find.text('x.service'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pump();

    expect(closed, 1, reason: 'Chiudi deve usare il callback onClose');
    // La route è ancora lì: niente Navigator.pop() (farebbe schermata bianca).
    expect(find.byType(OptimizerDoneView), findsOneWidget);
  });

  testWidgets('OptimizerDoneView con result nullo non va in crash',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: OptimizerDoneView(result: null, onClose: () {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Optimization complete'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  // Flusso completo del wizard con scansione/apply finti: verifica i passi,
  // il pulsante "Avanti" libero a zero selezione, il dialogo di conferma
  // dell'apply e la chiusura SENZA poppare (regressione schermata bianca).
  testWidgets('wizard: flusso completo intro → fine → onClose, no pop',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    OptimizerScanResult fakeScanResult() => OptimizerScanResult(
          hasSystemd: true,
          services: const [
            ServiceCandidate(
              unit: 'demo.service',
              descKey: 'optSvcGeneric',
              risk: OptimizerRisk.caution,
              evidence: ['neverActive'],
              enabledState: 'enabled',
              activeState: 'inactive',
            ),
          ],
          startupApps: [
            StartupCandidate(
              app: StartupApp(
                name: 'Demo App',
                command: '/bin/sh -c true',
                isEnabled: true,
                desktopFile: '/tmp/demo.desktop',
              ),
              evidence: const ['unusedApp'],
              risk: OptimizerRisk.safe,
              preselected: true,
            ),
          ],
          servicesScanned: 10,
        );

    Future<OptimizerScanResult> fakeScan({void Function(String)? onPhase}) async {
      onPhase?.call('units');
      return fakeScanResult();
    }

    List<ServiceCandidate>? appliedServices;
    List<StartupApp>? appliedApps;
    Future<OptimizerApplyResult> fakeApply({
      required List<ServiceCandidate> services,
      required List<StartupApp> apps,
      void Function(String)? onProgress,
    }) async {
      appliedServices = services;
      appliedApps = apps;
      onProgress?.call('demo.service');
      return const OptimizerApplyResult(
          servicesDisabled: 0, appsDisabled: 1, errors: []);
    }

    var closed = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: OptimizerWizardScreen(
          onClose: () => closed++,
          scanOverride: fakeScan,
          applyOverride: fakeApply,
        ),
      ),
    );
    await tester.pump();

    // Step 0: intro.
    expect(find.text('Optimization wizard'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Start scan'));
    await tester.pump();
    await tester.pump();

    // Step 2: servizi — e "Avanti" DEVE essere attivo anche con zero
    // selezioni (prima era bloccato: impossibile raggiungere le app).
    expect(find.text('System services'), findsOneWidget);
    final nextBtn = find.widgetWithText(FilledButton, 'Next');
    expect(tester.widget<FilledButton>(nextBtn).onPressed, isNotNull,
        reason: 'Avanti non deve dipendere dalla selezione dei servizi');
    await tester.tap(nextBtn);
    await tester.pump();

    // Step 3: app in avvio (l'app finta è preselezionata).
    expect(find.text('Startup apps'), findsOneWidget);
    expect(find.text('Demo App'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pump();

    // Step 4: riepilogo → serve il DIALOGO di conferma.
    expect(find.text('Ready to optimize'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Apply now'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget,
        reason: "l'apply richiede sempre una conferma");
    // Annulla → nessuna applicazione.
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(appliedApps, isNull);

    // Conferma → apply finto → step finale.
    await tester.tap(find.widgetWithText(FilledButton, 'Apply now'));
    await tester.pump();
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Apply now'),
    );
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump();

    expect(find.text('Optimization complete'), findsOneWidget);
    expect(appliedServices, isEmpty,
        reason: 'nessun servizio selezionato: non devono essere toccati');
    expect(appliedApps, hasLength(1));

    // "Chiudi": chiama onClose e NON poppa la route (schermata bianca).
    await tester.tap(find.text('Close'));
    await tester.pump();
    expect(closed, 1);
    expect(find.byType(OptimizerWizardScreen), findsOneWidget,
        reason: 'la route deve restare: niente Navigator.pop() sulla root');
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
