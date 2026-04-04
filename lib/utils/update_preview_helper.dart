import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';

/// Shared “names of updates” preview for tray dialogs, home, and recovery tab.
class UpdatePreviewHelper {
  UpdatePreviewHelper._();

  static const int maxPreviewItems = 28;

  static List<String> mergedLines(AppLocalizations l10n, Map<String, dynamic>? result) {
    if (result == null) return const [];
    final inst = (result['updateInstallableLabels'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];
    final phased = (result['updatePhasedLabels'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];
    return [...inst, ...phased.map((n) => l10n.updateLabelPhased(n))];
  }

  /// Plain text for recovery output / logs (heading + comma list + optional footer).
  static String plainText(
    AppLocalizations l10n,
    Map<String, dynamic>? result, {
    required String heading,
    int maxItems = maxPreviewItems,
  }) {
    final all = mergedLines(l10n, result);
    if (all.isEmpty) return '';
    final truncated = all.length > maxItems;
    final shown = truncated ? all.sublist(0, maxItems) : all;
    final buf = StringBuffer()
      ..writeln(heading)
      ..write(shown.join(', '));
    if (truncated) {
      buf
        ..writeln()
        ..write(l10n.updatesPreviewTruncated(all.length - maxItems));
    }
    final phased = (result?['updatePhasedLabels'] as List?) ?? const [];
    if (phased.isNotEmpty) {
      buf
        ..writeln()
        ..writeln()
        ..write(l10n.updatesAvailablePhasedFooter);
    }
    return buf.toString();
  }

  static Widget previewBlock(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic>? result, {
    required String heading,
  }) {
    final all = mergedLines(l10n, result);
    if (all.isEmpty) return const SizedBox.shrink();
    final truncated = all.length > maxPreviewItems;
    final shown = truncated ? all.sublist(0, maxPreviewItems) : all;
    final body = shown.join(', ');
    final phased = (result?['updatePhasedLabels'] as List?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SelectableText(
          truncated
              ? '$body\n${l10n.updatesPreviewTruncated(all.length - maxPreviewItems)}'
              : body,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
        ),
        if (phased.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.updatesAvailablePhasedFooter,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
