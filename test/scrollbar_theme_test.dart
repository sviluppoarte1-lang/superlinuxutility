import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/utils/scrollbar_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildAppScrollbarTheme', () {
    test('mantiene il pollice visibile e il trascinamento attivo', () {
      for (final Brightness brightness in Brightness.values) {
        final ScrollbarThemeData theme = buildAppScrollbarTheme(brightness);
        expect(
          theme.thumbVisibility!.resolve(<WidgetState>{}),
          isTrue,
          reason: 'thumbVisibility deve essere true per brightness=$brightness',
        );
        expect(theme.interactive, isTrue);
      }
    });

    test('colore del pollice visibile in ogni stato (riposo/hover/drag)', () {
      final ScrollbarThemeData light = buildAppScrollbarTheme(Brightness.light);
      final Color idle = light.thumbColor!.resolve(<WidgetState>{})!;
      final Color hover =
          light.thumbColor!.resolve(<WidgetState>{WidgetState.hovered})!;
      final Color drag =
          light.thumbColor!.resolve(<WidgetState>{WidgetState.dragged})!;

      // Riposo: 35% (il default Flutter è 10% → quasi invisibile su bianco).
      expect(idle.a, closeTo(0.35, 0.01));
      expect(hover.a, closeTo(0.55, 0.01));
      expect(drag.a, closeTo(0.75, 0.01));
      // Tema chiaro → pollice scuro (nero); tema scuro → pollice chiaro.
      expect(idle.r + idle.g + idle.b, lessThan(0.1));
      final Color darkIdle =
          buildAppScrollbarTheme(Brightness.dark).thumbColor!.resolve(<WidgetState>{})!;
      expect(darkIdle.r + darkIdle.g + darkIdle.b, greaterThan(2.9));
    });
  });

  group('Integrazione con MaterialApp (piattaforma Linux)', () {
    /// Pompola una pagina con molto contenuto (overflow garantito).
    Future<void> pumpPage(
      WidgetTester tester, {
      required bool withAppScrollbarTheme,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            platform: TargetPlatform.linux,
            scrollbarTheme:
                withAppScrollbarTheme ? buildAppScrollbarTheme(Brightness.light) : null,
          ),
          home: Scaffold(
            body: ListView.builder(
              itemCount: 60,
              itemBuilder: (context, index) => SizedBox(
                height: 40,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scrollbar), findsOneWidget);
    }

    testWidgets('senza il tema di default il pollice resta nascosto (bug Ubuntu)',
        (tester) async {
      await pumpPage(tester, withAppScrollbarTheme: false);
      // Comportamento Flutter di default su Linux: la scrollbar esiste ma il
      // pollice non viene dipinto finché non si scorre → su Ubuntu non si
      // vede alcuna barra di scorrimento.
      expect(find.byType(Scrollbar), isNot(paints..rect()));
    });

    testWidgets('con il tema applicato il pollice è visibile dal primo frame',
        (tester) async {
      await pumpPage(tester, withAppScrollbarTheme: true);
      // Il pollice viene effettivamente dipinto (overflow presente).
      expect(find.byType(Scrollbar), paints..rect());
    });
  });
}
