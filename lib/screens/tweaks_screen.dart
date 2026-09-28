import 'dart:io';
import 'package:flutter/material.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/tweaks_service.dart';
import '../services/password_storage.dart';
import '../services/kernel_tweaks_service.dart';

class TweaksScreen extends StatefulWidget {
  final bool isAdvanced;
  const TweaksScreen({super.key, this.isAdvanced = false});

  @override
  State<TweaksScreen> createState() => _TweaksScreenState();
}

class _TweaksScreenState extends State<TweaksScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  SwapInfo? _swapInfo;
  List<SwapRecommendation> _swapRecs = [];
  List<DavinciFix> _davinciFixes = [];
  bool _loadingSwap = true;
  bool _loadingDavinci = true;
  final Set<String> _runningCommands = {};
  final Set<String> _completedCommands = {};

  List<KernelTweak> _kernelTweaks = [];
  bool _loadingKernel = true;
  bool _kernelRunning = false;
  Map<String, String> _kernelSelected = {};
  bool _kernelPersistentActive = false;

  int get _tabLength => widget.isAdvanced ? 3 : 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLength, vsync: this);
    _loadSwapInfo();
    _loadDavinciFixes();
    if (widget.isAdvanced) _loadKernelTweaks();
  }

  @override
  void didUpdateWidget(TweaksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAdvanced != widget.isAdvanced) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
        length: _tabLength,
        vsync: this,
        initialIndex: oldIndex < _tabLength ? oldIndex : 0,
      );
      if (widget.isAdvanced) _loadKernelTweaks();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadSwapInfo() async {
    setState(() { _loadingSwap = true; });
    try {
      final info = await TweaksService.getSwapInfo();
      final zramActive = await TweaksService.isZramActive();
      final zramInstalled = await TweaksService.isZramInstalled();
      final recs = TweaksService.getSwapRecommendations(info, zramActive: zramActive, zramInstalled: zramInstalled);
      if (mounted) {
        setState(() {
          _swapInfo = info;
          _swapRecs = recs;
          _loadingSwap = false;
          _completedCommands.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loadingSwap = false; });
    }
  }

  Future<void> _loadDavinciFixes() async {
    setState(() { _loadingDavinci = true; });
    try {
      final fixes = await TweaksService.getDavinciFixes();
      if (mounted) setState(() { _davinciFixes = fixes; _loadingDavinci = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingDavinci = false; });
    }
  }

  // ─── KERNEL TWEAKS ───

  Future<void> _loadKernelTweaks() async {
    setState(() { _loadingKernel = true; });
    try {
      final results = await Future.wait([
        KernelTweaksService.getKernelTweaks(),
        KernelTweaksService.isPersistentServiceActive(),
      ]);
      if (!mounted) return;
      setState(() {
        _kernelTweaks = results[0] as List<KernelTweak>;
        _kernelPersistentActive = results[1] as bool;
        _kernelSelected = {};
        for (final t in _kernelTweaks) {
          if (t.available) {
            // Preseleziona il valore persistente se esiste, altrimenti quello attuale.
            _kernelSelected[t.id] = t.persistent ?? t.current;
          }
        }
        _loadingKernel = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loadingKernel = false; });
    }
  }

  Future<void> _applyKernelTweaks() async {
    setState(() { _kernelRunning = true; });
    try {
      final result = await KernelTweaksService.applyKernelTweaks(_kernelSelected);
      if (!mounted) return;
      final ok = result['success'] as bool? ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? (ok ? 'OK' : 'Failed')),
          backgroundColor: ok ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      await _loadKernelTweaks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _kernelRunning = false; });
    }
  }

  Future<void> _resetKernelTweaks() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.kernelTweaksResetTitle),
        content: Text(l10n.kernelTweaksResetConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.postpone)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.kernelTweaksReset)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _kernelRunning = true; });
    try {
      final result = await KernelTweaksService.resetKernelTweaks();
      if (!mounted) return;
      final ok = result['success'] as bool? ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Failed'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
      await _loadKernelTweaks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _kernelRunning = false; });
    }
  }

  Widget _buildKernelTab(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_loadingKernel) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKernelPersistenceBanner(l10n, colorScheme),
        const SizedBox(height: 16),
        for (final t in _kernelTweaks) ...[
          _buildKernelTweakCard(l10n, colorScheme, t),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _kernelRunning ? null : _applyKernelTweaks,
                icon: _kernelRunning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(l10n.kernelTweaksApply),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _kernelRunning ? null : _resetKernelTweaks,
              icon: const Icon(Icons.restart_alt, size: 18),
              label: Text(l10n.kernelTweaksReset),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKernelPersistenceBanner(AppLocalizations l10n, ColorScheme colorScheme) {
    final active = _kernelPersistentActive;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (active ? Colors.green : colorScheme.surfaceContainerHighest)
            .withValues(alpha: active ? 0.15 : 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? Colors.green.withValues(alpha: 0.4)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.info_outline,
            color: active ? Colors.green : colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              active ? l10n.kernelTweaksPersistActive : l10n.kernelTweaksPersistNote,
              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKernelTweakCard(
      AppLocalizations l10n, ColorScheme colorScheme, KernelTweak tweak) {
    final selected = _kernelSelected[tweak.id] ?? '';
    String title;
    switch (tweak.id) {
      case 'thp':
        title = l10n.kernelTweaksThp;
        break;
      case 'governor':
        title = l10n.kernelTweaksGovernor;
        break;
      case 'scheduler':
        title = l10n.kernelTweaksScheduler;
        break;
      default:
        title = tweak.id;
    }
    String description;
    switch (tweak.id) {
      case 'thp':
        description = l10n.kernelTweaksThpDesc;
        break;
      case 'governor':
        description = l10n.kernelTweaksGovernorDesc;
        break;
      case 'scheduler':
        description = l10n.kernelTweaksSchedulerDesc;
        break;
      default:
        description = '';
    }

    if (!tweak.available) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty, size: 20, color: Colors.grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title — ${l10n.statusNotAvailable}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, size: 20, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${l10n.kernelTweaksCurrent}: ${_kernelOptionLabel(l10n, tweak.id, tweak.current)}',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tweak.options.map((opt) {
                final label = _kernelOptionLabel(l10n, tweak.id, opt.id);
                final isSelected = selected == opt.id;
                final isPersisted = opt.id == tweak.persistent;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      if (isPersisted) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.lock_outline, size: 12, color: Colors.green),
                      ],
                    ],
                  ),
                  tooltip: isPersisted ? l10n.kernelTweaksSavedForBoot : null,
                  selected: isSelected,
                  onSelected: _kernelRunning
                      ? null
                      : (_) => setState(() => _kernelSelected[tweak.id] = opt.id),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _kernelOptionLabel(AppLocalizations l10n, String tweakId, String optionId) {
    switch (optionId) {
      case 'performance':
        return l10n.kernelTweaksPerf;
      case 'ondemand':
        return l10n.kernelTweaksOndemand;
      case 'schedutil':
        return l10n.kernelTweaksSchedutil;
      case 'powersave':
        return l10n.kernelTweaksPowersave;
      case 'always':
        return l10n.kernelTweaksAlways;
      case 'madvise':
        return l10n.kernelTweaksMadvise;
      case 'never':
        return l10n.kernelTweaksNever;
      case 'child_runs_first_1':
        return l10n.kernelTweaksSchedOn;
      case 'child_runs_first_0':
        return l10n.kernelTweaksSchedOff;
      default:
        return optionId;
    }
  }

  Future<void> _executeCommand(String key, String command) async {
    setState(() { _runningCommands.add(key); });
    try {
      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        if (!mounted) return;
        setState(() { _runningCommands.remove(key); });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sudo password saved. Please save your password in Settings first.'), backgroundColor: Colors.orange),
        );
        return;
      }

      final escapedPassword = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');
      final fullCommand =
          'printf "%s\\n" "$escapedPassword" | sudo -p "" -S bash -c ${_shellQuote(command)} 2>&1';
      final result = await Process.run('bash', ['-c', fullCommand], runInShell: true);

      if (!mounted) return;
      setState(() { _runningCommands.remove(key); });

      if (result.exitCode == 0) {
        setState(() { _completedCommands.add(key); });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Command executed successfully'), backgroundColor: Colors.green),
        );
        // Refresh swap info after any swap command
        _loadSwapInfo();
      } else {
        final output = (result.stdout as String).trim();
        final errOutput = (result.stderr as String).trim();
        final msg = errOutput.isNotEmpty ? errOutput : (output.isNotEmpty ? output : 'Command failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _runningCommands.remove(key); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.tune, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.tabTweaks,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.swap_horiz, size: 20), text: l10n.tweaksSwap),
            Tab(icon: const Icon(Icons.movie_creation_outlined, size: 20), text: 'DaVinci Resolve'),
            if (widget.isAdvanced)
              Tab(icon: const Icon(Icons.memory, size: 20), text: l10n.tabKernel),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSwapTab(l10n, colorScheme),
              _buildDavinciTab(l10n, colorScheme),
              if (widget.isAdvanced) _buildKernelTab(l10n, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SWAP TAB ───

  Widget _buildSwapTab(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_loadingSwap) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_swapInfo != null) ...[
          _buildSwapInfoCard(_swapInfo!, colorScheme),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.tweaksSwapRecommendations,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._swapRecs.map((rec) => _buildSwapRecCard(rec, colorScheme)),
      ],
    );
  }

  Widget _buildSwapInfoCard(SwapInfo info, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'System Memory',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('RAM', '${info.ramGb.toStringAsFixed(1)} GB', colorScheme),
            _buildInfoRow('Swap Total', info.hasSwap ? '${info.totalGb.toStringAsFixed(1)} GB' : 'None', colorScheme),
            if (info.hasSwap) ...[
              _buildInfoRow('Swap Used', '${info.usedGb.toStringAsFixed(1)} GB', colorScheme),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: info.totalKb > 0 ? info.usedKb / info.totalKb : 0,
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            const SizedBox(height: 8),
            _buildInfoRow('Swappiness', '${info.swapinness}', colorScheme),
            if (info.swapDevice != null)
              _buildInfoRow('Swap Device', info.swapDevice!, colorScheme),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Zswap',
              info.zswapStatus == 'enabled'
                  ? 'Attivo'
                  : info.zswapStatus == 'disabled'
                      ? 'Disattivo'
                      : 'Non disponibile',
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSwapRecCard(SwapRecommendation rec, ColorScheme colorScheme) {
    final cmdKey = rec.command;
    final isRunning = _runningCommands.contains(cmdKey);
    final isCompleted = _completedCommands.contains(cmdKey);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: rec.isCurrentlyApplied
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  rec.isCurrentlyApplied ? Icons.check_circle : Icons.lightbulb_outline,
                  color: rec.isCurrentlyApplied ? Colors.green : Colors.amber,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: rec.isCurrentlyApplied ? Colors.green : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rec.description,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            if (rec.command.isNotEmpty && !rec.isCurrentlyApplied) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.command,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: isCompleted
                    ? const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text('Applied', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: isRunning ? null : () => _executeCommand(cmdKey, rec.command),
                        icon: isRunning
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.play_arrow, size: 18),
                        label: Text(isRunning ? 'Running...' : 'Execute'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── DAVINCI TAB ───

  Widget _buildDavinciTab(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_loadingDavinci) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Linux Fixes & Workarounds',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'All known fixes for running DaVinci Resolve on Linux.',
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ..._davinciFixes.map((fix) => _buildDavinciFixCard(fix, colorScheme)),
      ],
    );
  }

  Widget _buildDavinciFixCard(DavinciFix fix, ColorScheme colorScheme) {
    final isApplied = fix.isCurrentlyApplied;
    final cmdKey = 'davinci_${fix.id}';
    final isRunning = _runningCommands.contains(cmdKey);
    final isCompleted = _completedCommands.contains(cmdKey);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isApplied
              ? Colors.green.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isApplied ? Icons.check_circle : Icons.build_circle_outlined,
                  color: isApplied ? Colors.green : colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fix.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isApplied ? Colors.green : null,
                    ),
                  ),
                ),
                if (fix.requiresRestart)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Restart required', style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fix.description,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            if (fix.command.isNotEmpty && !isApplied) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SelectableText(
                  fix.command,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: isCompleted
                    ? const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text('Applied', style: TextStyle(color: Colors.green, fontSize: 12)),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: isRunning ? null : () => _executeCommand(cmdKey, fix.command),
                        icon: isRunning
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.play_arrow, size: 18),
                        label: Text(isRunning ? 'Running...' : 'Execute'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer,
                          foregroundColor: colorScheme.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
