import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/recovery_service.dart';
import '../utils/update_check_report_formatter.dart';
import '../widgets/updates_apply_progress_view.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  Map<String, bool> _operationStatus = {};
  Map<String, String> _operationOutput = {};
  Map<String, bool> _operationLoading = {};
  int _updateCount = 0;
  List<String> _pendingUpdates = [];

  @override
  void initState() {
    super.initState();
    _initializeOperationStates();
  }

  static const List<String> _recoveryOperations = [
    'pipewire', 'network', 'grub', 'flathub', 'repositories',
  ];
  static const List<String> _installerOperations = [
    'ffmpeg', 'ytdlp', 'systemlibs', 'codecs', 'rsync',
  ];

  void _initializeOperationStates() {
    for (final op in _recoveryOperations) {
      _operationStatus[op] = false;
      _operationOutput[op] = '';
      _operationLoading[op] = false;
    }
    _operationStatus['updates'] = false;
    _operationOutput['updates'] = '';
    _operationLoading['updates'] = false;
    for (final op in _installerOperations) {
      _operationStatus[op] = false;
      _operationOutput[op] = '';
      _operationLoading[op] = false;
    }
  }

  Future<void> _executeOperation(String operation) async {
    setState(() {
      _operationLoading[operation] = true;
      _operationStatus[operation] = false;
      _operationOutput[operation] = '';
    });

    try {
      Map<String, dynamic> result;
      
      switch (operation) {
        case 'pipewire':
          result = await RecoveryService.restartPipewire();
          break;
        case 'network':
          result = await RecoveryService.restoreNetworkServices();
          break;
        case 'grub':
          result = await RecoveryService.rebuildGrub();
          break;
        case 'flathub':
          result = await RecoveryService.restoreFlathub();
          break;
        case 'repositories':
          result = await RecoveryService.restoreRepositories();
          break;
        case 'updates':
          result = await RecoveryService.checkForUpdates();
          if (result['updateCount'] != null) {
            _updateCount = result['updateCount'] as int;
          }
          final upd = result['updates'];
          if (upd is List) {
            _pendingUpdates = upd.map((e) => e.toString()).toList();
          } else {
            _pendingUpdates = [];
          }
          break;
        case 'ffmpeg':
          result = await RecoveryService.installFfmpeg();
          break;
        case 'ytdlp':
          result = await RecoveryService.installYtDlp();
          break;
        case 'systemlibs':
          result = await RecoveryService.installSystemLibraries();
          break;
        case 'codecs':
          result = await RecoveryService.installCodecs();
          break;
        case 'rsync':
          result = await RecoveryService.installRsync();
          break;
        default:
          result = {'success': false, 'message': 'Operazione sconosciuta'};
      }

      final l10nForOutput = AppLocalizations.of(context)!;
      String outputText;
      if (operation == 'updates') {
        final formatted = UpdateCheckReportFormatter.format(
          l10nForOutput,
          result['updateReport'] as Map<String, dynamic>?,
        );
        outputText = formatted.isNotEmpty
            ? formatted
            : (result['output']?.toString() ?? result['message']?.toString() ?? '');
      } else {
        outputText = result['output']?.toString() ?? result['message']?.toString() ?? '';
      }
      setState(() {
        _operationLoading[operation] = false;
        _operationStatus[operation] = result['success'] as bool? ?? false;
        _operationOutput[operation] = outputText;
      });

      if (mounted) {
        final messageKey = result['message']?.toString() ?? '';
        final l10n = AppLocalizations.of(context)!;
        String message;
        
        // Traduci i messaggi se sono chiavi di traduzione
        if (messageKey == 'recoveryCheckUpdatesComplete') {
          message = l10n.recoveryCheckUpdatesComplete;
        } else if (messageKey == 'recoveryCheckUpdatesError') {
          final error = result['error']?.toString() ?? '';
          message = l10n.recoveryCheckUpdatesError(error);
        } else {
          message = messageKey;
        }
        
        final color = result['success'] as bool? ?? false ? Colors.green : Colors.red;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _operationLoading[operation] = false;
        _operationStatus[operation] = false;
        _operationOutput[operation] = 'Errore: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'esecuzione: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _performUpdates() async {
    final l10n = AppLocalizations.of(context)!;
    
    // Conferma prima di eseguire gli aggiornamenti
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recoveryPerformUpdates),
        content: Text(l10n.recoveryPerformUpdatesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _operationLoading['updates'] = true;
      _operationOutput['updates'] = ''; // Reset output
    });

    // Mostra dialog con output in tempo reale, avanzamento e elenco pacchetti
    final outputNotifier = ValueNotifier<String>('');
    final progressNotifier = ValueNotifier<double>(0);
    final statusNotifier = ValueNotifier<String?>(null);
    BuildContext? dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return AnimatedBuilder(
          animation: Listenable.merge([outputNotifier, progressNotifier, statusNotifier]),
          builder: (context, _) {
            final output = outputNotifier.value;
            return AlertDialog(
              title: Text(l10n.recoveryPerformUpdates),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UpdatesApplyProgressView(
                        progress: progressNotifier.value,
                        statusLabel: statusNotifier.value,
                        pendingPackages: _pendingUpdates,
                        logText: null,
                        maxPackagesHeight: 140,
                        maxLogHeight: 0,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.updatesCommandOutputTitle,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          reverse: true,
                          child: SelectableText(
                            output.isEmpty ? '…' : output,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (!_operationLoading['updates']!)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
              ],
            );
          },
        );
      },
    );

    final expectedCount = _updateCount > 0 ? _updateCount : _pendingUpdates.length;

    try {
      final result = await RecoveryService.performUpdates(
        expectedPackageCount: expectedCount,
        onOutput: (data) {
          outputNotifier.value += data;
          _operationOutput['updates'] = outputNotifier.value;
        },
        onProgress: (p, label) {
          progressNotifier.value = p;
          statusNotifier.value = label;
        },
      );

      setState(() {
        _operationLoading['updates'] = false;
        _operationStatus['updates'] = result['success'] as bool? ?? false;
        _operationOutput['updates'] = result['output']?.toString() ?? result['message']?.toString() ?? '';
        if (result['success'] == true) {
          _updateCount = 0; // Reset dopo aggiornamento
          _pendingUpdates = [];
        }
      });

      if (mounted && dialogContext != null) {
        Navigator.pop(dialogContext!);
      }

      if (mounted) {
        final messageKey = result['message']?.toString() ?? '';
        final l10nSnack = AppLocalizations.of(context)!;
        String message;

        if (messageKey == 'recoveryCheckUpdatesComplete') {
          message = l10nSnack.recoveryCheckUpdatesComplete;
        } else if (messageKey == 'recoveryCheckUpdatesError') {
          final error = result['error']?.toString() ?? '';
          message = l10nSnack.recoveryCheckUpdatesError(error);
        } else {
          message = messageKey;
        }

        final color = result['success'] as bool? ?? false ? Colors.green : Colors.red;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: color,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _operationLoading['updates'] = false;
        _operationStatus['updates'] = false;
        _operationOutput['updates'] = 'Errore: $e';
      });

      if (mounted && dialogContext != null) {
        Navigator.pop(dialogContext!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'esecuzione degli aggiornamenti: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        progressNotifier.dispose();
        statusNotifier.dispose();
        outputNotifier.dispose();
      });
    }
  }

  void _showOutputDialog(String operation, String title) {
    final output = _operationOutput[operation] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: SelectableText(
            output.isEmpty ? 'Nessun output disponibile' : output,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallerCard({
    required String operation,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isLoading = _operationLoading[operation] ?? false;
    final isSuccess = _operationStatus[operation] ?? false;
    final hasOutput = (_operationOutput[operation] ?? '').isNotEmpty;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isSuccess)
                  Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (_operationStatus[operation] == false && hasOutput)
                  Icon(Icons.error, color: Colors.red, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasOutput)
                  TextButton.icon(
                    onPressed: () => _showOutputDialog(operation, title),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(l10n.viewOutput),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : () => _executeOperation(operation),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(l10n.install),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryCard({
    required String operation,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isLoading = _operationLoading[operation] ?? false;
    final isSuccess = _operationStatus[operation] ?? false;
    final hasOutput = (_operationOutput[operation] ?? '').isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (isSuccess)
                  Icon(Icons.check_circle, color: Colors.green, size: 24)
                else if (_operationStatus[operation] == false)
                  Icon(Icons.error, color: Colors.red, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasOutput)
                  TextButton.icon(
                    onPressed: () => _showOutputDialog(operation, title),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: Text(AppLocalizations.of(context)!.viewOutput),
                  ),
                if (operation == 'updates' && _updateCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _performUpdates(),
                      icon: const Icon(Icons.system_update, size: 18),
                      label: Text(AppLocalizations.of(context)!.recoveryPerformUpdates),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : () => _executeOperation(operation),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text(AppLocalizations.of(context)!.execute),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: l10n.recoveryTabRecovery),
                Tab(text: l10n.recoveryTabCheckUpdates),
                Tab(text: l10n.recoveryTabSoftwareInstaller),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _initializeOperationStates();
                  });
                },
                child: TabBarView(
                  children: [
                    _buildRecoveryTab(l10n),
                    _buildCheckUpdatesTab(l10n),
                    _buildSoftwareInstallerTab(l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.recoveryDescription,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        _buildRecoveryCard(
          operation: 'pipewire',
          title: l10n.recoveryRestartPipewire,
          description: l10n.recoveryRestartPipewireDesc,
          icon: Icons.volume_up,
          color: Colors.blue,
        ),
        _buildRecoveryCard(
          operation: 'network',
          title: l10n.recoveryRestoreNetwork,
          description: l10n.recoveryRestoreNetworkDesc,
          icon: Icons.wifi,
          color: Colors.green,
        ),
        _buildRecoveryCard(
          operation: 'grub',
          title: l10n.recoveryRebuildGrub,
          description: l10n.recoveryRebuildGrubDesc,
          icon: Icons.settings_backup_restore,
          color: Colors.orange,
        ),
        _buildRecoveryCard(
          operation: 'flathub',
          title: l10n.recoveryRestoreFlathub,
          description: l10n.recoveryRestoreFlathubDesc,
          icon: Icons.apps,
          color: Colors.purple,
        ),
        _buildRecoveryCard(
          operation: 'repositories',
          title: l10n.recoveryRestoreRepos,
          description: l10n.recoveryRestoreReposDesc,
          icon: Icons.storage,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildCheckUpdatesTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.recoveryCheckUpdatesDesc,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        _buildRecoveryCard(
          operation: 'updates',
          title: l10n.recoveryCheckUpdates,
          description: l10n.recoveryCheckUpdatesDesc,
          icon: Icons.system_update,
          color: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildSoftwareInstallerTab(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.recoverySoftwareInstallerDesc,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ),
        _buildInstallerCard(
          operation: 'ffmpeg',
          title: l10n.recoveryInstallFfmpeg,
          description: l10n.recoveryInstallFfmpegDesc,
          icon: Icons.video_library,
          color: Colors.blue,
        ),
        _buildInstallerCard(
          operation: 'ytdlp',
          title: l10n.recoveryInstallYtDlp,
          description: l10n.recoveryInstallYtDlpDesc,
          icon: Icons.download,
          color: Colors.red,
        ),
        _buildInstallerCard(
          operation: 'systemlibs',
          title: l10n.recoveryInstallSystemLibs,
          description: l10n.recoveryInstallSystemLibsDesc,
          icon: Icons.build,
          color: Colors.orange,
        ),
        _buildInstallerCard(
          operation: 'codecs',
          title: l10n.recoveryInstallCodecs,
          description: l10n.recoveryInstallCodecsDesc,
          icon: Icons.music_video,
          color: Colors.purple,
        ),
        _buildInstallerCard(
          operation: 'rsync',
          title: l10n.recoveryInstallRsync,
          description: l10n.recoveryInstallRsyncDesc,
          icon: Icons.sync,
          color: Colors.teal,
        ),
      ],
    );
  }
}

