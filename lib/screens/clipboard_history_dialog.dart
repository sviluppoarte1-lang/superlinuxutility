import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/services/clipboard_history_service.dart';

/// Cronologia appunti, accessibile SOLO dalla system tray.
///
/// Mostra tutti i testi passati per la clipboard con un editor di testo
/// integrato (tocca una voce per modificarla). Ogni voce può essere
/// ricopiata negli appunti, salvata in un file TXT o eliminata.
/// "Esporta tutto" salva l'intera cronologia in un unico TXT.
class ClipboardHistoryDialog extends StatefulWidget {
  const ClipboardHistoryDialog({super.key});

  @override
  State<ClipboardHistoryDialog> createState() => _ClipboardHistoryDialogState();
}

class _ClipboardHistoryDialogState extends State<ClipboardHistoryDialog> {
  List<ClipboardEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final entries = await ClipboardHistoryService.getEntries();
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  String _formatTs(BuildContext context, int ts) {
    try {
      final locale = Localizations.localeOf(context).toLanguageTag();
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      return DateFormat.yMd(locale).add_Hm().format(dt);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(ts).toString();
    }
  }

  Future<void> _copyBack(ClipboardEntry e) async {
    await Clipboard.setData(ClipboardData(text: e.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.clipboardCopiedBack)),
    );
  }

  Future<void> _editEntry(ClipboardEntry e) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: e.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clipboardEditTitle),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            maxLines: 8,
            minLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.clipboardCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clipboardSave),
          ),
        ],
      ),
    );
    final newText = controller.text;
    controller.dispose();
    if (saved == true && mounted) {
      await ClipboardHistoryService.updateEntry(e.timestampMs, newText);
      await _reload();
    }
  }

  Future<void> _deleteEntry(ClipboardEntry e) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clipboardDeleteTitle),
        content: Text(l10n.clipboardDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.clipboardCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clipboardDelete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ClipboardHistoryService.deleteEntry(e.timestampMs);
      await _reload();
    }
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clipboardClearAllTitle),
        content: Text(l10n.clipboardClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.clipboardCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clipboardClearAll),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ClipboardHistoryService.clearAll();
      await _reload();
    }
  }

  Future<void> _saveTextToFile(String text, String suggestedName) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final bytes = utf8.encode(text);
      final path = await FilePicker.platform.saveFile(
        dialogTitle: l10n.clipboardSaveEntryTxt,
        fileName: suggestedName,
        type: FileType.custom,
        allowedExtensions: ['txt'],
        bytes: bytes,
      );
      if (!mounted) return;
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clipboardSavedTo(path))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clipboardSaveFailed)),
      );
    }
  }

  Future<void> _exportAll() async {
    if (_entries.isEmpty) return;
    final buffer = StringBuffer();
    for (final e in _entries) {
      buffer.writeln('--- ${DateTime.fromMillisecondsSinceEpoch(e.timestampMs)} ---');
      buffer.writeln(e.text);
      buffer.writeln();
    }
    await _saveTextToFile(buffer.toString(), 'clipboard_history.txt');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.content_paste,
                      size: 28, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.clipboardTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.clipboardExportAll,
                    icon: const Icon(Icons.file_download,
                        color: Colors.blue),
                    onPressed: _entries.isEmpty ? null : _exportAll,
                  ),
                  IconButton(
                    tooltip: l10n.clipboardClearAll,
                    icon: const Icon(Icons.delete_sweep,
                        color: Colors.red),
                    onPressed: _entries.isEmpty ? null : _clearAll,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _entries.isEmpty
                        ? Center(
                            child: Text(
                              l10n.clipboardEmpty,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _entries.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final e = _entries[i];
                              final preview = e.text.length > 120
                                  ? '${e.text.substring(0, 120)}…'
                                  : e.text;
                              return ListTile(
                                title: Text(preview, maxLines: 3, overflow: TextOverflow.ellipsis),
                                subtitle: Text(_formatTs(context, e.timestampMs)),
                                onTap: () => _editEntry(e),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: l10n.clipboardCopiedBack,
                                      icon: const Icon(Icons.copy,
                                          size: 20, color: Colors.blue),
                                      onPressed: () => _copyBack(e),
                                    ),
                                    IconButton(
                                      tooltip: l10n.clipboardSaveEntryTxt,
                                      icon: const Icon(Icons.save_alt,
                                          size: 20, color: Colors.green),
                                      onPressed: () => _saveTextToFile(
                                        e.text,
                                        'clipboard_${e.timestampMs}.txt',
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: l10n.clipboardDelete,
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                          color: Colors.red),
                                      onPressed: () => _deleteEntry(e),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
