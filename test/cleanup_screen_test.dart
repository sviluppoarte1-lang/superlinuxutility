import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/screens/cleanup_screen.dart';
import 'package:super_linux_utility/utils/scrollbar_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'CleanupScreen: pagina interamente scorrevole con scrollbar fino in fondo',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Finestra realistica (schermata Ubuntu reale, circa 1024×674).
    tester.view.physicalSize = const Size(1024, 674);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var titleTappable = false;
    var tileExpanded = false;

    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('it'),
          theme: ThemeData(
            platform: TargetPlatform.linux,
            scrollbarTheme: buildAppScrollbarTheme(Brightness.dark),
          ),
          home: const CleanupScreen(),
        ),
      );

      // Aspetta che la card RAM entri nella ListView PRIMA del tap:
      // inserirla dopo sposta gli indici dei figli e l'elemento del tile
      // verrebbe ricreato perdendo lo stato di espansione.
      var ramCardVisible = false;
      for (var i = 0; i < 40 && !ramCardVisible; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await tester.pump();
        ramCardVisible = find.byIcon(Icons.speed).evaluate().isNotEmpty;
      }

      // Espande "Pulizia avanzata" (il caso che con la vecchia Column fissa
      // faceva traboccare il layout ritagliando lista e pulsanti).
      final title = find.text('Pulizia avanzata (log e cache sviluppo)');
      titleTappable = title.evaluate().length == 1 &&
          tester.getCenter(title).dy < 674;
      if (titleTappable) {
        await tester.tap(title);
      }

      // Polling finché il contenuto del tile non è caricato: le scansioni
      // (du/journalctl) girano nella zona async reale, qui.
      for (var i = 0; i < 48 && !tileExpanded; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await tester.pump();
        tileExpanded =
            find.byType(CheckboxListTile).evaluate().isNotEmpty ||
                find
                    .text('Nessuna cache di sviluppo rilevata.')
                    .evaluate()
                    .isNotEmpty;
      }
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 1) Niente overflow di layout (prima: RenderFlex overflowed con il tile
    //    aperto, lista file e pulsanti sotto erano irraggiungibili).
    expect(titleTappable, isTrue, reason: 'titolo del tile visibile e cliccabile');
    expect(tileExpanded, isTrue, reason: 'tile espanso e contenuto caricato');
    expect(tester.takeException(), isNull,
        reason: 'la pagina non deve traboccare con il tile aperto');

    // 2) Struttura: UNA sola ListView e il tile "Pulizia avanzata" vive
    //    DENTRO di essa (prima era una sorella non scorrevole).
    expect(find.byType(ListView), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(ExpansionTile),
        matching: find.byType(ListView),
      ),
      findsOneWidget,
      reason: 'la pulizia avanzata deve stare dentro la ListView scorrevole',
    );

    // 3) Scorrimento fino in fondo: l'utente raggiunge pulsanti e lista file.
    final ScrollableState scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    expect(scrollable.position.maxScrollExtent, greaterThan(0),
        reason: 'la pagina deve essere scorrevole');

    // Un drag reale (mouse) deve far scorrere la pagina.
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(scrollable.position.pixels, greaterThan(0),
        reason: 'il drag dello scorrimento deve muovere la pagina');

    // maxScrollExtent è una stima finché i figli fuori viewport non vengono
    // costruiti: si porta lo scroll sul massimo e si ripete finché il valore
    // non si stabilizza (jumpTo è deterministico e ferma ogni ballistic).
    for (var i = 0; i < 6; i++) {
      final position = scrollable.position;
      if ((position.pixels - position.maxScrollExtent).abs() <= 1.0) break;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(scrollable.position.pixels,
        closeTo(scrollable.position.maxScrollExtent, 1.0),
        reason: 'lo scorrimento deve raggiungere il fondo della pagina');
    expect(tester.takeException(), isNull);

    // 4) Scrollbar presente con pollice dipinto (tema: thumbVisibility).
    expect(find.byType(Scrollbar), findsOneWidget);
    expect(find.byType(Scrollbar), paints..rect());
  }, timeout: const Timeout(Duration(minutes: 2)));
}
