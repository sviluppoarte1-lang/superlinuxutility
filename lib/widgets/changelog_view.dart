import 'package:flutter/material.dart';

/// A single `## version` block parsed from CHANGELOG.md.
class ChangelogSection {
  final String title;
  final List<String> lines;

  const ChangelogSection(this.title, this.lines);
}

/// Splits raw changelog markdown into `## ` sections.
/// Text before the first `## ` (the document title) is skipped.
List<ChangelogSection> parseChangelog(String markdown) {
  final sections = <ChangelogSection>[];
  var title = '';
  var lines = <String>[];

  void flush() {
    if (title.isNotEmpty) sections.add(ChangelogSection(title, List.of(lines)));
  }

  for (final raw in markdown.split('\n')) {
    final line = raw.trimRight();
    if (line.startsWith('## ')) {
      flush();
      title = line.substring(3).trim();
      lines = <String>[];
    } else if (title.isNotEmpty) {
      final text = line.trim();
      if (text.isEmpty || text == '---') continue;
      lines.add(text);
    }
  }
  flush();
  return sections;
}

/// Renders parsed changelog markdown: `### ` subsections, bullets,
/// numbered items and `**bold**` inline text.
class ChangelogView extends StatelessWidget {
  final List<ChangelogSection> sections;
  final int? maxSections;

  const ChangelogView({super.key, required this.sections, this.maxSections});

  @override
  Widget build(BuildContext context) {
    final visible = maxSections == null
        ? sections
        : sections.take(maxSections!).toList();
    final base = const TextStyle(fontSize: 14, height: 1.45);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          ..._buildSection(context, visible[i], base),
        ],
      ],
    );
  }

  List<Widget> _buildSection(
    BuildContext context,
    ChangelogSection section,
    TextStyle base,
  ) {
    final widgets = <Widget>[
      Text(
        section.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    ];
    for (final line in section.lines) {
      if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.substring(4).trim(),
            style: base.copyWith(fontWeight: FontWeight.w700),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        widgets.add(_bullet(line.substring(2), base));
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final match = RegExp(r'^(\d+\.)\s+(.*)$').firstMatch(line)!;
        widgets.add(_bullet(match.group(2)!, base, marker: match.group(1)!));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text.rich(_inlineSpans(line, base), style: base),
        ));
      }
    }
    return widgets;
  }

  Widget _bullet(String text, TextStyle base, {String marker = '•'}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Text(marker, style: base.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text.rich(_inlineSpans(text, base), style: base)),
        ],
      ),
    );
  }
}

InlineSpan _inlineSpans(String text, TextStyle base) {
  final parts = text.split('**');
  final spans = <TextSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isEmpty) continue;
    spans.add(TextSpan(
      text: parts[i],
      style: i.isOdd ? base.copyWith(fontWeight: FontWeight.bold) : null,
    ));
  }
  if (spans.isEmpty) return TextSpan(text: text);
  return TextSpan(children: spans);
}
