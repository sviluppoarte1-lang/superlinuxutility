import 'package:flutter/material.dart';

/// Tema scrollbar per desktop Linux (Ubuntu e derivate).
///
/// Comportamento di default di Flutter su Linux:
/// - il pollice della scrollbar viene mostrato solo DURANTE lo scorrimento e
///   scompare dopo ~600ms;
/// - il colore di riposo è nero al 10% di opacità (tema chiaro), quindi
///   quasi invisibile sullo sfondo bianco.
/// Su pagine con molte funzioni l'utente non vede quindi alcuna barra di
/// scorrimento.
///
/// Questo tema rende il pollice:
/// - SEMPRE visibile quando la pagina è scorrevole (si nasconde da solo quando
///   non c'è overflow, grazie al controllo interno di `RawScrollbar`);
/// - ad alto contrasto in ogni stato (riposo, hover, trascinamento);
/// - trascinabile con il mouse (`interactive`).
ScrollbarThemeData buildAppScrollbarTheme(Brightness brightness) {
  final Color base = brightness == Brightness.dark ? Colors.white : Colors.black;
  return ScrollbarThemeData(
    // Pollice persistente: visibile finché la lista ha contenuto oltre la
    // fine della viewport. Quando non c'è overflow non viene disegnato.
    thumbVisibility: const WidgetStatePropertyAll<bool>(true),
    // Trascinamento del pollice col mouse (già di default su desktop, ma
    // esplicitato per rendere chiaro l'intento).
    interactive: true,
    thumbColor:
        WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
      if (states.contains(WidgetState.dragged)) {
        return base.withValues(alpha: 0.75);
      }
      if (states.contains(WidgetState.hovered)) {
        return base.withValues(alpha: 0.55);
      }
      // Riposo: 35% invece del 10% di default → visibile su bianco/nero.
      return base.withValues(alpha: 0.35);
    }),
  );
}
