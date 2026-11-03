import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/startup_app.dart';
import '../services/system_optimizer_service.dart';

/// Wizard di ottimizzazione (advanced/personal): guida l'utente dalla
/// scansione di servizi e app in avvio fino all'applicazione con undo.
/// 0 intro → 1 scansione → 2 servizi → 3 app in avvio → 4 applica → 5 fine.
class OptimizerWizardScreen extends StatefulWidget {
  /// Azione della chiusura (fine wizard): il wizard è una TAB dentro la
  /// finestra principale, NON una route → senza questo callback l'unico
  /// modo per "chiudere" sarebbe `Navigator.pop()` sulla root route, che
  /// svuota lo stack e lascia una SCHERMATA BIANCA. La Home lo usa per
  /// tornare alla scheda principale.
  final VoidCallback? onClose;

  /// Solo per i test: sostituisce la scansione reale (niente comandi di
  /// sistema). Quando è null si usa `SystemOptimizerService.scan`.
  @visibleForTesting
  final Future<OptimizerScanResult> Function({void Function(String)? onPhase})?
      scanOverride;

  /// Solo per i test: sostituisce l'apply reale (niente systemctl/autostart
  /// veri). Quando è null si usa `SystemOptimizerService.apply`.
  @visibleForTesting
  final Future<OptimizerApplyResult> Function({
    required List<ServiceCandidate> services,
    required List<StartupApp> apps,
    void Function(String)? onProgress,
  })? applyOverride;

  const OptimizerWizardScreen({
    super.key,
    this.onClose,
    this.scanOverride,
    this.applyOverride,
  });

  @override
  State<OptimizerWizardScreen> createState() => _OptimizerWizardScreenState();
}

class _OptimizerWizardScreenState extends State<OptimizerWizardScreen> {
  int _step = 0;
  bool _applying = false;
  String _phase = '';
  String? _error;
  OptimizerScanResult? _result;
  OptimizerApplyResult? _applyResult;
  final Set<String> _selectedServices = {};
  final Set<String> _selectedApps = {};

  static const _totalSteps = 6;

  Future<void> _startScan() async {
    setState(() {
      _step = 1;
      _error = null;
      _phase = '';
    });
    try {
      final scan = widget.scanOverride ?? SystemOptimizerService.scan;
      final r = await scan(
        onPhase: (p) {
          if (mounted) setState(() => _phase = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _result = r;
        _step = 2;
        _selectedServices
          ..clear()
          ..addAll(r.services.where((s) => s.preselected).map((s) => s.unit));
        _selectedApps
          ..clear()
          ..addAll(r.startupApps
              .where((s) => s.preselected)
              .map((s) => s.app.desktopFile!));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _step = 0;
      });
    }
  }

  /// Chiude il wizard alla fine.
  ///
  /// 1. Se la Home ha passato `onClose` → si torna alla scheda principale
  ///    (nessuna route va toccata);
  /// 2. altrimenti si poppa SOLO se c'è davvero una route da poppare
  ///    (`canPop`): mai poppare la root di una finestra → schermata bianca;
  /// 3. infine si torna all'intro così il wizard è di nuovo riutilizzabile.
  void _closeWizard() {
    final onClose = widget.onClose;
    if (onClose != null) {
      onClose();
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else if (mounted) {
      setState(() => _step = 0);
    }
  }

  /// Conferma esplicita prima di applicare: un tap accidentale sul pulsante
  /// (la UI cambia passo sotto al puntatore) non deve mai disabilitare
  /// servizi/app senza un secondo gesto deliberato.
  Future<void> _confirmApply() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.optApplyTitle),
        content: Text(l10n.optApplyDesc(
            _selectedServices.length, _selectedApps.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.optApplyNow),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await _apply();
  }

  Future<void> _apply() async {
    final r = _result;
    if (r == null) return;
    final services =
        r.services.where((s) => _selectedServices.contains(s.unit)).toList();
    final apps = r.startupApps
        .where((a) => _selectedApps.contains(a.app.desktopFile))
        .map((a) => a.app)
        .toList();
    setState(() {
      _applying = true;
      _phase = '';
    });
    try {
      final doApply = widget.applyOverride ?? SystemOptimizerService.apply;
      final res = await doApply(
        services: services,
        apps: apps,
        onProgress: (p) {
          if (mounted) setState(() => _phase = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _applyResult = res;
        _applying = false;
        _step = 5;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = e.toString();
        _step = 4;
      });
    }
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step > 0 && _step != 1) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.optWizardTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: LinearProgressIndicator(
              value: (_step + 1) / _totalSteps,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(child: _buildStep(context, l10n)),
          if (_step >= 2 && _step <= 4) _buildNavBar(l10n),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, AppLocalizations l10n) {
    switch (_step) {
      case 0:
        return _buildIntro(l10n);
      case 1:
        return _buildScanning(l10n);
      case 2:
        return _buildServices(l10n);
      case 3:
        return _buildStartup(l10n);
      case 4:
        return _buildApply(l10n);
      default:
        return _buildDone(l10n);
    }
  }

  // ─── Step 0: intro ────────────────────────────────────────────────────

  Widget _buildIntro(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.auto_awesome, size: 56),
        const SizedBox(height: 16),
        Text(
          l10n.optIntroTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(l10n.optIntroDesc, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        _bullet(Icons.dns, l10n.optIntroBullet1),
        _bullet(Icons.rocket_launch, l10n.optIntroBullet2),
        _bullet(Icons.history, l10n.optIntroBullet3),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _startScan,
          icon: const Icon(Icons.search),
          label: Text(l10n.optStartScan),
        ),
      ],
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  // ─── Step 1: scansione ────────────────────────────────────────────────

  String _phaseText(AppLocalizations l10n) {
    switch (_phase) {
      case 'units':
        return l10n.optScanningUnits;
      case 'show':
        return l10n.optScanningShow;
      case 'blame':
        return l10n.optScanningBlame;
      case 'deps':
        return l10n.optScanningDeps;
      case 'startup':
        return l10n.optScanningStartup;
      default:
        return l10n.optScanningTitle;
    }
  }

  Widget _buildScanning(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(_phaseText(l10n), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.optScanningHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ─── Step 2: servizi ──────────────────────────────────────────────────

  Widget _buildServices(AppLocalizations l10n) {
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    if (!r.hasSystemd) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.info_outline,
              size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.optNoSystemd, textAlign: TextAlign.center),
        ],
      );
    }
    if (r.services.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.check_circle_outline, size: 48),
          const SizedBox(height: 16),
          Text(l10n.optServicesEmpty, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            l10n.optServicesUnknown(r.unknownEnabled),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.optServicesTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                l10n.optServicesSubtitle(r.servicesScanned, r.services.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (r.unknownEnabled > 0) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.optServicesUnknown(r.unknownEnabled),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedServices.length == r.services.length) {
                      _selectedServices.clear();
                    } else {
                      _selectedServices
                        ..clear()
                        ..addAll(r.services.map((s) => s.unit));
                    }
                  });
                },
                child: Text(l10n.selectAll),
              ),
              const Spacer(),
              Text(
                l10n.optSelectedCount(
                    _selectedServices.length, r.services.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              for (final s in r.services)
                _serviceTile(l10n, s, r.services.length),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _serviceTile(AppLocalizations l10n, ServiceCandidate s, int total) {
    final selected = _selectedServices.contains(s.unit);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) {
          setState(() {
            selected
                ? _selectedServices.remove(s.unit)
                : _selectedServices.add(s.unit);
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.unit,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            _riskBadge(l10n, s.risk),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_serviceDesc(l10n, s.descKey)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (final e in s.evidence) _evidenceChip(l10n, e)],
            ),
            if (s.description != null && s.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Step 3: app in avvio ─────────────────────────────────────────────

  Widget _buildStartup(AppLocalizations l10n) {
    final r = _result;
    if (r == null) return const SizedBox.shrink();
    if (r.startupApps.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.check_circle_outline, size: 48),
          const SizedBox(height: 16),
          Text(l10n.optStartupEmpty, textAlign: TextAlign.center),
          if (!r.usageAvailable) ...[
            const SizedBox(height: 12),
            Text(
              l10n.optNoUsageInfo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.optStartupTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                l10n.optStartupSubtitle(r.startupApps.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedApps.length == r.startupApps.length) {
                      _selectedApps.clear();
                    } else {
                      _selectedApps
                        ..clear()
                        ..addAll(r.startupApps.map((a) => a.app.desktopFile!));
                    }
                  });
                },
                child: Text(l10n.selectAll),
              ),
              const Spacer(),
              Text(
                l10n.optSelectedCount(
                    _selectedApps.length, r.startupApps.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              for (final a in r.startupApps) _startupTile(l10n, a),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _startupTile(AppLocalizations l10n, StartupCandidate a) {
    final file = a.app.desktopFile!;
    final selected = _selectedApps.contains(file);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) {
          setState(() {
            selected
                ? _selectedApps.remove(file)
                : _selectedApps.add(file);
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        title: Row(
          children: [
            Expanded(
              child: Text(a.app.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            _riskBadge(l10n, a.risk),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.app.command,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [for (final e in a.evidence) _evidenceChip(l10n, e)],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 4: applica ──────────────────────────────────────────────────

  Widget _buildApply(AppLocalizations l10n) {
    final svc = _selectedServices.length;
    final app = _selectedApps.length;
    if (_applying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(l10n.optApplying, style: Theme.of(context).textTheme.titleMedium),
            if (_phase.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_phase,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.tune, size: 56),
        const SizedBox(height: 16),
        Text(l10n.optApplyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(l10n.optApplyDesc(svc, app), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.undo),
            title: Text(l10n.optApplyUndoNote),
          ),
        ),
        if (svc == 0 && app == 0) ...[
          const SizedBox(height: 16),
          Text(l10n.optNothingSelected,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: (svc == 0 && app == 0) ? null : _confirmApply,
          icon: const Icon(Icons.check),
          label: Text(l10n.optApplyNow),
        ),
      ],
    );
  }

  // ─── Step 5: fine ─────────────────────────────────────────────────────

  Widget _buildDone(AppLocalizations l10n) =>
      OptimizerDoneView(result: _applyResult, onClose: _closeWizard);

  // ─── Navigazione ─────────────────────────────────────────────────────

  Widget _buildNavBar(AppLocalizations l10n) {
    final canBack = _step > 2;
    final canNext = _step < 4;
    // NB: "Avanti" è SEMPRE abilitato: bloccare il passo servizi quando
    // nessuno è selezionato impediva di raggiungere le app in avvio (chi
    // vuole ottimizzare solo quelle). Il passo applica gestisce da solo il
    // caso "nessuna selezione".
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (canBack)
              TextButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.goBack),
              ),
            const Spacer(),
            if (canNext)
              FilledButton.icon(
                onPressed: _next,
                icon: const Icon(Icons.arrow_forward),
                label: Text(l10n.onboardingContinue),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Widget di supporto ───────────────────────────────────────────────

  Widget _riskBadge(AppLocalizations l10n, OptimizerRisk risk) {
    final safe = risk == OptimizerRisk.safe;
    final color = safe ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        safe ? l10n.optRiskSafe : l10n.optRiskCaution,
        style: TextStyle(color: color, fontSize: 11),
      ),
    );
  }

  Widget _evidenceChip(AppLocalizations l10n, String code) {
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(_evidenceIcon(code), size: 14),
      label: Text(_evidenceText(l10n, code),
          style: const TextStyle(fontSize: 11)),
    );
  }

  IconData _evidenceIcon(String code) {
    switch (code) {
      case 'bootCost':
        return Icons.speed;
      case 'notRunning':
        return Icons.pause_circle_outline;
      case 'neverActive':
        return Icons.power_settings_new;
      case 'noBluetooth':
        return Icons.bluetooth_disabled;
      case 'noPrinters':
        return Icons.print_disabled;
      case 'noModems':
        return Icons.signal_cellular_off;
      case 'noSnaps':
        return Icons.inventory_2;
      case 'thirdParty':
        return Icons.extension_off;
      case 'unusedApp':
        return Icons.history;
      case 'missingBinary':
        return Icons.link_off;
      default:
        return Icons.info_outline;
    }
  }

  String _evidenceText(AppLocalizations l10n, String code) {
    switch (code) {
      case 'bootCost':
        return l10n.optEvBootCost;
      case 'notRunning':
        return l10n.optEvNotRunning;
      case 'neverActive':
        return l10n.optEvNeverActive;
      case 'lastActive':
        return l10n.optEvLastActive;
      case 'noBluetooth':
        return l10n.optEvNoBluetooth;
      case 'noPrinters':
        return l10n.optEvNoPrinters;
      case 'noModems':
        return l10n.optEvNoModems;
      case 'noSnaps':
        return l10n.optEvNoSnaps;
      case 'thirdParty':
        return l10n.optEvThirdParty;
      case 'unusedApp':
        return l10n.optEvUnusedApp;
      case 'missingBinary':
        return l10n.optEvMissingBinary;
      default:
        return code;
    }
  }

  String _serviceDesc(AppLocalizations l10n, String key) {
    switch (key) {
      case 'optSvcBluetooth':
        return l10n.optSvcBluetooth;
      case 'optSvcCups':
        return l10n.optSvcCups;
      case 'optSvcAvahi':
        return l10n.optSvcAvahi;
      case 'optSvcModemManager':
        return l10n.optSvcModemManager;
      case 'optSvcSnapd':
        return l10n.optSvcSnapd;
      case 'optSvcPackageKit':
        return l10n.optSvcPackageKit;
      case 'optSvcFwupd':
        return l10n.optSvcFwupd;
      case 'optSvcGeoclue':
        return l10n.optSvcGeoclue;
      case 'optSvcUpdateNotifier':
        return l10n.optSvcUpdateNotifier;
      case 'optSvcAnacron':
        return l10n.optSvcAnacron;
      case 'optSvcOpenVpn':
        return l10n.optSvcOpenVpn;
      case 'optSvcTeamViewer':
        return l10n.optSvcTeamViewer;
      case 'optSvcAnydesk':
        return l10n.optSvcAnydesk;
      case 'optSvcRustdesk':
        return l10n.optSvcRustdesk;
      case 'optSvcTailscale':
        return l10n.optSvcTailscale;
      case 'optSvcDocker':
        return l10n.optSvcDocker;
      case 'optSvcLibvirt':
        return l10n.optSvcLibvirt;
      case 'optSvcMysql':
        return l10n.optSvcMysql;
      case 'optSvcPostgres':
        return l10n.optSvcPostgres;
      default:
        return l10n.optSvcGeneric;
    }
  }
}

/// Schermata finale del wizard (estratta → testabile): esito dell'apply e
/// pulsante "Chiudi" che usa SOLO il callback `onClose` (mai
/// `Navigator.pop()`: il wizard è una tab, poppare la root route lascia una
/// schermata bianca).
class OptimizerDoneView extends StatelessWidget {
  final OptimizerApplyResult? result;

  /// Azione di chiusura richiesta al tap su "Chiudi".
  final VoidCallback onClose;

  const OptimizerDoneView({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final res = result;
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.check_circle, size: 56, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          l10n.optDoneTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.optDoneDesc(res?.servicesDisabled ?? 0, res?.appsDisabled ?? 0),
          textAlign: TextAlign.center,
        ),
        if (res != null && res.errors.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: colorScheme.error),
              title: Text(l10n.optDoneErrors(res.errors.length)),
              subtitle: Text(
                res.errors.take(6).join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.optDoneHistoryNote),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onClose,
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
