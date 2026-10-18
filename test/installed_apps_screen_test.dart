import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/screens/installed_apps_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InstalledAppsScreen: carica gli elenchi e mostra la lista',
      (tester) async {
    // Viewport ampio: il font di test quadrato altrimenti fa traboccare
    // le righe (stesso pattern di changelog_test).
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // pumpWidget DEVE stare dentro runAsync: i subprocess di listing
    // vanno avviati e attesi nell'ambiente async reale, altrimenti le
    // Future registrate nella zona fake del test non si completano mai.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          home: const InstalledAppsScreen(),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 5));
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'il caricamento deve completarsi');
    // Elenco popolato: le righe delle app sono renderizzate.
    expect(find.byType(ListTile), findsWidgets);
    // Filtri per gestore: 7 chip (Tutti + i 6 gestori, incluse le nuove
    // voci Pacman e DNF).
    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(find.text('APT'), findsOneWidget);
    expect(find.text('Pacman'), findsOneWidget);
    expect(find.text('DNF'), findsOneWidget);
    expect(find.text('Flatpak'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
