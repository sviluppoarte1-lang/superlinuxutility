import 'package:flutter/material.dart';

/// Disattiva il keep-alive predefinito del [TabBarView] (PageView) per questa pagina.
///
/// Senza questo wrapper, Flutter mantiene in memoria tutte le tab già visitate, con
/// molte schermate pesanti (monitor, app installate, analisi disco, …) la RSS sale
/// da ~200MB a centinaia di MB anche con l’app in background.
class TabPageNoKeepAlive extends StatefulWidget {
  const TabPageNoKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<TabPageNoKeepAlive> createState() => _TabPageNoKeepAliveState();
}

class _TabPageNoKeepAliveState extends State<TabPageNoKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
