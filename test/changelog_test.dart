import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/screens/info_screen.dart';
import 'package:super_linux_utility/widgets/changelog_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parseChangelog splits sections and skips text before the first header',
      () {
    final sections = parseChangelog(
      '# Changelog\n\nintro text\n\n'
      '## 1.0 — 2026-01-01\n\n### Fixes\n\n- fixed a bug\n',
    );

    expect(sections, hasLength(1));
    expect(sections.single.title, '1.0 — 2026-01-01');
    expect(sections.single.lines, ['### Fixes', '- fixed a bug']);
  });

  // L'asset va caricato qui dentro: rootBundle in un test() separato fa
  // bloccare il pump del testWidgets successivo.
  testWidgets('Info shows the latest release and opens the full changelog',
      (tester) async {
    // Viewport più ampio: il font di test quadrato altrimenti fa
    // traboccare le righe dei titoli nelle card.
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final markdown = await rootBundle.loadString('CHANGELOG.md');
    final sections = parseChangelog(markdown);
    expect(sections, isNotEmpty);
    expect(sections.first.title, startsWith('2.1.0'));
    expect(sections.last.title, startsWith('1.8.6'));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const InfoScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Changelog'), findsOneWidget);
    expect(
      find.textContaining('Driver & Firmware Manager', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('View full changelog'), findsOneWidget);

    final showAll = find.text('View full changelog');
    await tester.ensureVisible(showAll);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    expect(find.text('1.8.6 — 2026-02-26'), findsOneWidget);
    expect(
      find.textContaining('First public release', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('1.8.6 — 2026-02-26'), findsNothing);

    // Fa scadere il timeout di 1s di PackageInfo prima di smontare l'albero.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
