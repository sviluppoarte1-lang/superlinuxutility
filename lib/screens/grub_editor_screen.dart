import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/grub_service.dart';
import '../services/grub_suggestions_service.dart';

class GrubEditorScreen extends StatefulWidget {
  const GrubEditorScreen({super.key});

  @override
  State<GrubEditorScreen> createState() => _GrubEditorScreenState();
}

class _GrubEditorScreenState extends State<GrubEditorScreen> {
  final TextEditingController _editorController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _error;
  String? _originalContent;

  @override
  void initState() {
    super.initState();
    _loadGrubConfig();
    _editorController.addListener(() {
      if (_originalContent != null) {
        setState(() {
          _hasChanges = _editorController.text != _originalContent;
        });
      }
    });
  }

  @override
  void dispose() {
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _loadGrubConfig() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final content = await GrubService.readGrubConfig();
      setState(() {
        _originalContent = content;
        _editorController.text = content;
        _hasChanges = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveGrubConfig() async {
    final content = _editorController.text;

    // Valida il contenuto
    if (!GrubService.validateGrubConfig(content)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.grubInvalidContent),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.grubConfirmSave),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.grubSaveWarning,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.grubWillCreateBackup),
            Text(AppLocalizations.of(context)!.grubWillSave),
            Text(AppLocalizations.of(context)!.grubWillUpdate),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.grubWarning,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.saveAndUpdate,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final success = await GrubService.saveAndUpdateGrub(content);
      
      if (success) {
        setState(() {
          _originalContent = content;
          _hasChanges = false;
          _isSaving = false;
        });

        if (mounted) {
          // Mostra notifica di successo con avviso di riavvio
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.grubSavedSuccess),
                  const SizedBox(height: 4),
                  Text(
                    'Riavvia il sistema per applicare le modifiche.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.grubSaveError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showHardwareSuggestions() async {
    // Mostra un dialog di caricamento mentre generiamo i suggerimenti
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analisi hardware in corso...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final suggestions = await GrubSuggestionsService.generateSuggestions();
      
      if (!mounted) return;
      Navigator.pop(context); // Chiudi il dialog di caricamento

      if (suggestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nessun suggerimento disponibile per il tuo hardware.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      // Mostra il dialog con i suggerimenti
      await showDialog(
        context: context,
        builder: (context) => _HardwareSuggestionsDialog(
          suggestions: suggestions,
          onApply: (suggestion) async {
            try {
              final newConfig = await GrubSuggestionsService.applySuggestion(
                suggestion,
                _editorController.text,
              );
              setState(() {
                _editorController.text = newConfig;
                _hasChanges = true;
              });
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Suggerimento applicato: ${suggestion.parameter}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Errore nell\'applicazione del suggerimento: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Chiudi il dialog di caricamento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nella generazione dei suggerimenti: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.restoreBackup),
        content: Text(AppLocalizations.of(context)!.restoreBackupQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.restore,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await GrubService.restoreBackup();
      if (success) {
        await _loadGrubConfig();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backupRestoredSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.backupRestoreError),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading || _isSaving ? null : _loadGrubConfig,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context)!.reload),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _isSaving || !_hasChanges) ? null : _saveGrubConfig,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.saveAndUpdate),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading || _isSaving ? null : _showHardwareSuggestions,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Suggerimenti Hardware'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                const Spacer(),
                FutureBuilder<bool>(
                  future: GrubService.hasBackup(),
                  builder: (context, snapshot) {
                    if (snapshot.data == true) {
                      return TextButton.icon(
                        onPressed: _isLoading || _isSaving ? null : _restoreBackup,
                        icon: const Icon(Icons.restore),
                        label: Text(AppLocalizations.of(context)!.restoreBackup),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Avviso
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hai modifiche non salvate. Ricorda di salvare e aggiornare GRUB per applicare le modifiche.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Errore
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Editor
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _editorController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Contenuto del file GRUB...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Dialog per mostrare i suggerimenti hardware
class _HardwareSuggestionsDialog extends StatelessWidget {
  final List<GrubSuggestion> suggestions;
  final Function(GrubSuggestion) onApply;

  const _HardwareSuggestionsDialog({
    required this.suggestions,
    required this.onApply,
  });

  Color _getPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return Colors.red;
      case SuggestionPriority.medium:
        return Colors.orange;
      case SuggestionPriority.low:
        return Colors.blue;
    }
  }

  String _getPriorityText(SuggestionPriority priority, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (priority) {
      case SuggestionPriority.high:
        return l10n.hardwareSuggestionsPriorityHigh;
      case SuggestionPriority.medium:
        return l10n.hardwareSuggestionsPriorityMedium;
      case SuggestionPriority.low:
        return l10n.hardwareSuggestionsPriorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.hardwareSuggestionsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.hardwareSuggestionsDescription,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(suggestion.priority)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getPriorityText(suggestion.priority, context),
                                  style: TextStyle(
                                    color: _getPriorityColor(suggestion.priority),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (suggestion.isAlreadyPresent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Già presente',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suggestion.parameter,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (suggestion.currentValue != null) ...[
                            Text(
                              'Valore corrente: ${suggestion.currentValue}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            'Suggerito: ${suggestion.suggestedValue}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suggestion.reason,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (!suggestion.isAlreadyPresent) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => onApply(suggestion),
                                icon: const Icon(Icons.check),
                                label: Text(AppLocalizations.of(context)!.hardwareSuggestionsApply),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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

