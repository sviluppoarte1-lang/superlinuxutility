import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/operation_history_service.dart';

/// Banner "operazione annullabile": mostra uno SnackBar con il messaggio
/// del risultato e, se l'operazione registrata ha un undoCommand, un'azione
/// Undo che ri-esegue il comando di annullamento dalla cronologia.
///
/// Da chiamare subito dopo un'azione che ha registrato un'operazione con
/// undo (es. OperationHistoryService.logOperation(..., undoCommand: ...)).
Future<void> showOperationUndoSnackBar(
  BuildContext context,
  String message, {
  required bool ok,
  OperationRecord? record,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Catturato PRIMA dello show: nella chiusura della SnackBarAction il
  // context della snackbar originale può essere già deattivato.
  final messenger = ScaffoldMessenger.of(context);
  final canUndo = record != null &&
      record.undoCommand != null &&
      record.undoCommand!.isNotEmpty &&
      !record.restored;

  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            canUndo ? Icons.undo : (ok ? Icons.check_circle : Icons.error_outline),
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: ok ? Colors.green.shade700 : Colors.red.shade700,
      duration: Duration(seconds: canUndo ? 10 : 4),
      action: canUndo
          ? SnackBarAction(
              label: l10n.undo,
              textColor: Colors.white,
              onPressed: () async {
                final res = await OperationHistoryService.restoreOperation(record.id);
                final undone = res['success'] as bool? ?? false;
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          undone ? Icons.check_circle : Icons.error_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(undone ? l10n.undoDone : l10n.undoFailed),
                        ),
                      ],
                    ),
                    backgroundColor:
                        undone ? Colors.green.shade700 : Colors.red.shade700,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
            )
          : null,
    ),
  );
}

/// Cerca l'ultima operazione annullabile registrata per [category]/[action]
/// e mostra il banner con Undo. Comodo da chiamare dopo un'azione riuscita.
Future<void> showUndoSnackBarForLatest(
  BuildContext context,
  String message, {
  required bool ok,
  String? category,
  String? action,
}) async {
  if (!ok) {
    await showOperationUndoSnackBar(context, message, ok: false);
    return;
  }
  final record = await OperationHistoryService.latestRecord(
    category: category,
    action: action,
  );
  if (!context.mounted) return;
  await showOperationUndoSnackBar(context, message, ok: true, record: record);
}
