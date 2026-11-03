import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/screens/home_screen.dart';
import 'package:super_linux_utility/services/recovery_service.dart';

/// Risultato di controllo con 2 aggiornamenti APT finti.
Map<String, dynamic> fakeCheckResult({int count = 2}) {
  final names =
      List<String>.generate(count, (i) => 'pkg-${String.fromCharCode(97 + i)}');
  return <String, dynamic>{
    'success': true,
    'message': 'recoveryCheckUpdatesComplete',
    'updateReport': <String, dynamic>{
      'apt': <String, dynamic>{
        'mode': 'installable',
        'installableCount': count,
        'phasedCount': 0,
        'phasedPackages': <String>[],
        'kernelCount': 0,
        'kernelPackages': <String>[],
      },
    },
    'updates': names,
    'updateCount': count,
    'summaryPackageCount': count,
    'updateInstallableLabels': names,
    'updatePhasedLabels': <String>[],
    'kernelUpdates': <String>[],
    'kernelUpdateCount': 0,
    'kernelUpdateLabels': <String>[],
    'nonKernelUpdates': names,
    'nonKernelUpdateCount': count,
    'nonKernelUpdateLabels': names,
  };
}

/// Cerca [text] solo dentro lo SnackBar: lo stesso testo compare anche nella
/// riga di stato del dialogo, quindi finder globali troverebbero 2 widget.
Finder snackBarText(String text) => find.descendant(
      of: find.byType(SnackBar),
      matching: find.text(text),
    );

void main() {
  group('pendingManagersFromReport', () {
    test('mappa i report sui manager con conteggio > 0', () {
      final report = <String, dynamic>{
        'apt': <String, dynamic>{'mode': 'installable', 'installableCount': 2},
        'flatpak': <String, dynamic>{'mode': 'installable', 'count': 1},
        'dnf': <String, dynamic>{'mode': 'none', 'count': 0},
        'pacman': <String, dynamic>{'mode': 'installable', 'count': 0},
        'snap': <String, dynamic>{'mode': 'error', 'count': 0},
      };
      expect(
        RecoveryService.pendingManagersFromReport(report),
        {'APT', 'Flatpak'},
      );
    });

    test('report assente o vuoto → nessun manager atteso', () {
      expect(RecoveryService.pendingManagersFromReport(null), isEmpty);
      expect(RecoveryService.pendingManagersFromReport(<String, dynamic>{}),
          isEmpty);
    });
  });

  group('computeApplySuccess (nessun "falso successo")', () {
    test('un manager senza lavoro non copre il fallimento di chi aveva le update',
        () {
      // BUG REALE: `flatpak update -y` con "Nothing to do" esce 0 → prima
      // l'intero apply risultava OK anche se APT era fallito, e l'app
      // riproponeva gli stessi aggiornamenti al controllo successivo.
      expect(
        RecoveryService.computeApplySuccess(
          expectedManagers: {'APT'},
          managerResults: {'APT': false, 'Flatpak': true},
          updatedManagers: ['Flatpak'],
        ),
        isFalse,
      );
    });

    test('tutti gli attesi riusciti → successo', () {
      expect(
        RecoveryService.computeApplySuccess(
          expectedManagers: {'APT'},
          managerResults: {'APT': true, 'Flatpak': true},
          updatedManagers: ['APT', 'Flatpak'],
        ),
        isTrue,
      );
    });

    test('senza informazioni sui pendenti vale il criterio storico', () {
      expect(
        RecoveryService.computeApplySuccess(
          expectedManagers: null,
          managerResults: {'APT': false, 'Flatpak': true},
          updatedManagers: ['Flatpak'],
        ),
        isTrue,
      );
      expect(
        RecoveryService.computeApplySuccess(
          expectedManagers: const <String>{},
          managerResults: <String, bool>{},
          updatedManagers: <String>[],
        ),
        isFalse,
      );
    });

    test('manager atteso mai eseguito → fallito', () {
      expect(
        RecoveryService.computeApplySuccess(
          expectedManagers: {'APT'},
          managerResults: <String, bool>{},
          updatedManagers: <String>[],
        ),
        isFalse,
      );
    });
  });

  group('TrayCheckUpdatesDialog: stato dopo l\'apply', () {
    Future<TrayCheckUpdatesDialog> pumpDialog(
      WidgetTester tester, {
      required Future<Map<String, dynamic>> Function({
        Function(String)? onOutput,
        void Function(double progress, String? statusLabel)? onProgress,
        int expectedPackageCount,
        List<String>? selectedUpdates,
        Set<String>? expectedManagers,
      }) applyOverride,
      Future<Map<String, dynamic>> Function()? checkOverride,
    }) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final dialog = TrayCheckUpdatesDialog(
        initialResult: fakeCheckResult(),
        applyOverride: applyOverride,
        checkOverride: checkOverride,
      );
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: dialog),
      ));
      await tester.pump();
      return dialog;
    }

    Future<void> tapApplyAndSettle(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Perform Updates (2)'));
      // La catena apply → verifica finale è tutta asincrona (microtask).
      for (var i = 0; i < 8; i++) {
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets(
        'apply ok + verifica a 0 → lista vecchia azzerata (regressione)',
        (tester) async {
      Set<String>? seenExpected;
      var checkCalls = 0;

      await pumpDialog(
        tester,
        applyOverride: ({
          Function(String)? onOutput,
          void Function(double progress, String? statusLabel)? onProgress,
          int expectedPackageCount = 0,
          List<String>? selectedUpdates,
          Set<String>? expectedManagers,
        }) async {
          seenExpected = expectedManagers;
          return <String, dynamic>{'success': true, 'updated': ['APT']};
        },
        checkOverride: () async {
          checkCalls++;
          // Tutto installato: nessun aggiornamento residuo.
          return fakeCheckResult(count: 0);
        },
      );

      // Lista iniziale visibile.
      expect(find.text('pkg-a'), findsOneWidget);
      expect(find.text('pkg-b'), findsOneWidget);

      await tapApplyAndSettle(tester);

      expect(seenExpected, contains('APT'),
          reason: 'il dialogo deve dire al servizio quali manager erano attesi');
      expect(checkCalls, 1, reason: 'dopo l\'apply va rifatto il controllo');
      expect(find.text('pkg-a'), findsNothing,
          reason: 'la lista NON deve restare in piedi dopo l\'apply');
      expect(find.text('pkg-b'), findsNothing);
      expect(snackBarText('Update search completed'), findsOneWidget);
      expect(snackBarText('2 updates still pending'), findsNothing);
    });

    testWidgets('apply ok ma rimangono aggiornamenti → mostra quelli rimasti',
        (tester) async {
      await pumpDialog(
        tester,
        applyOverride: ({
          Function(String)? onOutput,
          void Function(double progress, String? statusLabel)? onProgress,
          int expectedPackageCount = 0,
          List<String>? selectedUpdates,
          Set<String>? expectedManagers,
        }) async {
          return <String, dynamic>{'success': true, 'updated': ['APT']};
        },
        // Stessi 2 pacchetti ancora pendenti: l'app non deve dichiarare 0.
        checkOverride: () async => fakeCheckResult(count: 2),
      );

      await tapApplyAndSettle(tester);

      expect(snackBarText('2 updates still pending'), findsOneWidget,
          reason: 'va detto che qualcosa è rimasto, non "completato"');
      expect(snackBarText('Update search completed'), findsNothing);
      expect(find.text('pkg-a'), findsOneWidget,
          reason: 'la lista rinnovata mostra i rimasti');
      expect(find.text('pkg-b'), findsOneWidget);
    });

    testWidgets('apply fallito → nessuna verifica e lista invariata',
        (tester) async {
      var checkCalls = 0;

      await pumpDialog(
        tester,
        applyOverride: ({
          Function(String)? onOutput,
          void Function(double progress, String? statusLabel)? onProgress,
          int expectedPackageCount = 0,
          List<String>? selectedUpdates,
          Set<String>? expectedManagers,
        }) async {
          return <String, dynamic>{
            'success': false,
            'message': 'Aggiornamenti non riusciti per: APT',
          };
        },
        checkOverride: () async {
          checkCalls++;
          return fakeCheckResult(count: 0);
        },
      );

      await tapApplyAndSettle(tester);

      expect(checkCalls, 0,
          reason: 'senza successo non ha senso ricontrollare');
      expect(
          snackBarText('Aggiornamenti non riusciti per: APT'), findsOneWidget);
      expect(find.text('pkg-a'), findsOneWidget,
          reason: 'in caso di errore la lista deve restare');
    });
  });
}
