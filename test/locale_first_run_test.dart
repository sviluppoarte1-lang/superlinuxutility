import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/main.dart';
import 'package:super_linux_utility/screens/settings_screen.dart';
import 'package:super_linux_utility/services/tray_service.dart';

/// Titolo della schermata di warning per ciascuna lingua (chiave warningTitle).
const Map<String, String> _warningTitleByLang = {
  'it': 'ATTENZIONE',
  'en': 'WARNING',
  'fr': 'ATTENTION',
  'es': 'ADVERTENCIA',
  'de': 'WARNUNG',
  'pt': 'AVISO',
};

/// Preferenze comuni che evitano subprocess/timer inattesi nei test.
Map<String, Object> _basePrefs({String? locale}) => <String, Object>{
      'theme_mode': 'light',
      if (locale != null) 'locale': locale,
    };

/// Interrompe i timer di MyApp e lascia avanzare i timer brevi residui.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tapSafe(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(finder);
}

/// Apre MyApp e attende la fine del caricamento iniziale.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

String _languageName(String code) {
  switch (code) {
    case 'it':
      return 'Italiano';
    case 'en':
      return 'English';
    case 'fr':
      return 'Français';
    case 'es':
      return 'Español';
    case 'de':
      return 'Deutsch';
    case 'pt':
      return 'Português';
  }
  return code;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('primo avvio: scegliere inglese applica la lingua',
      (tester) async {
    SharedPreferences.setMockInitialValues(_basePrefs());

    await _pumpApp(tester);

    expect(find.text('Language Selection'), findsOneWidget,
        reason: 'La schermata di scelta lingua deve comparire al primo avvio');

    await _tapSafe(tester, find.text('English'));
    await tester.pump(const Duration(milliseconds: 100));

    await _tapSafe(tester, find.text('Save'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'en',
        reason: 'La preferenza locale deve essere salvata come "en"');
    expect(prefs.getBool('language_selected'), isTrue);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale?.languageCode, 'en',
        reason: 'MaterialApp deve ricevere il locale "en"');

    expect(find.text('WARNING'), findsOneWidget,
        reason: 'Lo screen successivo deve mostrare il titolo in inglese');

    await _teardown(tester);
  });

  testWidgets('primo avvio: tutte e 6 le lingue vengono applicate',
      (tester) async {
    for (final entry in _warningTitleByLang.entries) {
      SharedPreferences.setMockInitialValues(_basePrefs());

      await _pumpApp(tester);
      expect(find.text('Language Selection'), findsOneWidget,
          reason: 'Primo avvio atteso per la lingua ${entry.key}');

      await _tapSafe(tester, find.text(_languageName(entry.key)));
      await tester.pump(const Duration(milliseconds: 100));
      await _tapSafe(tester, find.text('Save'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), entry.key);

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale?.languageCode, entry.key,
          reason: 'MaterialApp deve ricevere il locale "${entry.key}"');

      expect(find.text(entry.value), findsOneWidget,
          reason: 'Il titolo di warning deve essere in "${entry.key}"');

      await _teardown(tester);
    }
  });

  testWidgets('riavvio: la lingua salvata viene riapplicata', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ..._basePrefs(locale: 'de'),
      'language_selected': true,
      'warning_accepted': true,
      'password_configured': false,
    });

    await _pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale?.languageCode, 'de',
        reason: 'Al riavvio la lingua salvata deve essere applicata');
    expect(find.text('Passwort-Konfiguration'), findsOneWidget,
        reason: 'La schermata password deve essere in tedesco');

    await _teardown(tester);
  });

  testWidgets('sistema inglese, nessuna preferenza: interfaccia in inglese',
      (tester) async {
    tester.binding.platformDispatcher.localeTestValue =
        const Locale('en', 'US');
    addTearDown(
        () => tester.binding.platformDispatcher.clearLocaleTestValue());

    // Percorso upgrade: scelta lingua già fatta in passato ma preferenza
    // 'locale' mai salvata (o rimossa) → deve valere la lingua di sistema.
    SharedPreferences.setMockInitialValues(<String, Object>{
      ..._basePrefs(),
      'language_selected': true,
      'warning_accepted': true,
      'password_configured': false,
    });

    await _pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, isNull,
        reason: 'Senza preferenza si deve usare la lingua di sistema');

    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(ctx).languageCode, 'en',
        reason: 'La localizzazione risolta deve essere l\'inglese');
    expect(AppLocalizations.of(ctx)!.localeName, 'en');

    await _teardown(tester);
  });

  testWidgets('Settings: cambiare lingua applica subito la lingua',
      (tester) async {
    SharedPreferences.setMockInitialValues(_basePrefs());

    Locale? reported;
    Locale? hostLocale;
    late StateSetter hostSetState;

    await tester.pumpWidget(StatefulBuilder(
      builder: (context, setState) {
        hostSetState = setState;
        return MaterialApp(
          locale: hostLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it', ''),
            Locale('en', ''),
            Locale('fr', ''),
            Locale('es', ''),
            Locale('de', ''),
            Locale('pt', ''),
          ],
          home: Builder(
            builder: (context) => SettingsScreen(
              onThemeModeChanged: (_) {},
              onLocaleChanged: (locale) {
                reported = locale;
                hostLocale = locale;
                hostSetState(() {});
              },
            ),
          ),
        );
      },
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    final dropdown = find.byType(DropdownButtonFormField<Locale>);
    expect(dropdown, findsOneWidget);
    await _tapSafe(tester, dropdown);
    await tester.pump(const Duration(milliseconds: 300));

    await _tapSafe(tester, find.text('English').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(reported?.languageCode, 'en',
        reason: 'Settings deve notificare onLocaleChanged("en")');

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale?.languageCode, 'en',
        reason: 'Il cambio lingua deve applicarsi subito, senza riavvio');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('locale'), 'en',
        reason: 'La preferenza deve essere salvata');

    await _teardown(tester);
  });

  test('tray: etichette di default nella lingua salvata, non in italiano',
      () async {
    SharedPreferences.setMockInitialValues(_basePrefs(locale: 'en'));
    var labels = await TrayService.labelsForSavedLocale();
    expect(labels.exit, 'Exit');
    expect(labels.settings, 'Settings');
    expect(labels.showMainWindow, 'Show main window');

    SharedPreferences.setMockInitialValues(_basePrefs(locale: 'de'));
    labels = await TrayService.labelsForSavedLocale();
    expect(labels.exit, isNot('Esci'),
        reason: 'Con lingua tedesca il menu tray non deve restare italiano');
    expect(labels.exit, isNotEmpty);
  });
}
