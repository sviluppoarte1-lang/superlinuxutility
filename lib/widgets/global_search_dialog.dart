import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

/// Voce dell'indice di ricerca globale: un tab raggiungibile con la sua
/// etichetta localizzata, icona e parole chiave (degli alias EN inclusi).
class TabSearchEntry {
  final String key;
  final String label;
  final IconData icon;
  final Color? color;
  final List<String> keywords;

  const TabSearchEntry(
      this.key, this.label, this.icon, this.color, this.keywords);
}

/// Ricerca globale (Ctrl+K) tra i tab dell'app: filtra le voci fornite dal
/// chiamante e ritorna la chiave del tab selezionato (Navigator.pop).
class GlobalSearchDialog extends StatefulWidget {
  final List<TabSearchEntry> entries;

  const GlobalSearchDialog({super.key, required this.entries});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  String _query = '';

  int _matchScore(TabSearchEntry e, List<String> tokens) {
    if (tokens.isEmpty) return 1;
    final label = e.label.toLowerCase();
    final keywords = e.keywords.join(' ').toLowerCase();
    int score = 0;
    for (final t in tokens) {
      int tokenScore = 0;
      if (label.startsWith(t)) {
        tokenScore = 4;
      } else if (label.contains(t)) {
        tokenScore = 3;
      } else if (keywords.contains(t)) {
        tokenScore = 1;
      }
      // Tutti i token devono corrispondere (AND).
      if (tokenScore == 0) return 0;
      score += tokenScore;
    }
    return score;
  }

  List<TabSearchEntry> get _results {
    final tokens =
        _query.toLowerCase().trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    final scored = <MapEntry<TabSearchEntry, int>>[];
    for (final e in widget.entries) {
      final s = _matchScore(e, tokens);
      if (s > 0) scored.add(MapEntry(e, s));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  void _select(TabSearchEntry e) => Navigator.of(context).pop(e.key);

  void _selectFirst() {
    final r = _results;
    if (r.isNotEmpty) _select(r.first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = _results;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.search,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(LogicalKeyboardKey.enter): _selectFirst,
                      },
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 40,
                              color:
                                  Theme.of(context).colorScheme.outline),
                          const SizedBox(height: 12),
                          Text(l10n.searchNoResults,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final e = results[index];
                        return ListTile(
                          leading: Icon(e.icon, color: e.color),
                          title: Text(e.label),
                          onTap: () => _select(e),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
