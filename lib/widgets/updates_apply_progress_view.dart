import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';

/// Pannello condiviso: barra avanzamento, stato corrente, elenco pacchetti (ultimo check), log opzionale.
class UpdatesApplyProgressView extends StatelessWidget {
  final double progress;
  final String? statusLabel;
  final List<String> pendingPackages;
  final String? logText;
  final double maxPackagesHeight;
  final double maxLogHeight;

  const UpdatesApplyProgressView({
    super.key,
    required this.progress,
    this.statusLabel,
    this.pendingPackages = const [],
    this.logText,
    this.maxPackagesHeight = 140,
    this.maxLogHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        if (statusLabel != null && statusLabel!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.updatesProgressCurrent(statusLabel!),
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (pendingPackages.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.updatesPendingPackagesTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxPackagesHeight),
            child: Scrollbar(
              thumbVisibility: pendingPackages.length > 6,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: pendingPackages.length,
                itemBuilder: (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${pendingPackages[i]}',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.2),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (logText != null && logText!.isNotEmpty) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxLogHeight),
            child: SingleChildScrollView(
              reverse: true,
              child: SelectableText(
                logText!,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.25),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
