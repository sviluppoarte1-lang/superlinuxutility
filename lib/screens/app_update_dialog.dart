import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/services/app_self_update_service.dart';

/// Dialog shown when a new app version is available on GitHub.
/// Lets the user choose to download & install, skip, or view the release page.
class AppUpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  bool _installing = false;
  String? _progressMessage;
  bool? _success;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = widget.updateInfo;
    final latest = info['latestVersion'] ?? '?';
    final current = info['currentVersion'] ?? '?';
    final releaseNotes = (info['body'] as String?)?.trim() ?? '';

    if (_success == true) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text('${l10n.app} ${l10n.version} $latest')),
          ],
        ),
        content: Text('$latest ${l10n.version} installed successfully.'),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    }

    if (_success == false) {
      return AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.error)),
          ],
        ),
        content: Text(_progressMessage ?? l10n.error),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text('${l10n.version} $latest')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.version} $current → $latest',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (releaseNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Release notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  releaseNotes,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
            if (_installing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              if (_progressMessage != null) ...[
                const SizedBox(height: 8),
                Text(_progressMessage!, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ],
        ),
      ),
      actions: _installing
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton.icon(
                onPressed: _install,
                icon: const Icon(Icons.download),
                label: const Text('Download & Install'),
              ),
            ],
    );
  }

  Future<void> _install() async {
    setState(() {
      _installing = true;
      _progressMessage = 'Downloading...';
    });
    final result = await AppSelfUpdateService.downloadAndInstall(
      widget.updateInfo['downloadUrl'] as String,
      widget.updateInfo['assetName'] as String,
    );
    if (!mounted) return;
    setState(() {
      _installing = false;
      _success = result['success'] == true;
      _progressMessage = result['message'] as String?;
    });
  }
}
