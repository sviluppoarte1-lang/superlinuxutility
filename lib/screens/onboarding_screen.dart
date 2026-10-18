import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/system_detector.dart';

/// Onboarding in un unico stepper:
///  1. Selezione lingua (la lingua si applica subito al tap);
///  2. Avviso rischi con card sistema rilevato (distro rilevata da
///     SystemDetector / SystemDetectionInfo).
///
/// Sostituisce le due schermate separate (lingua hardcoded EN + warning).
class OnboardingScreen extends StatefulWidget {
  final Function(Locale?)? onLocaleChanged;
  final SystemDetectionInfo? systemInfo;

  /// 0 = passo lingua, 1 = passo avviso. Se la lingua è già stata scelta
  /// (flag salvato) l'onboarding riparte direttamente dall'avviso.
  final int initialStep;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    this.onLocaleChanged,
    this.systemInfo,
    this.initialStep = 0,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late int _step = widget.initialStep.clamp(0, 1);
  Locale? _selectedLocale;
  bool _completing = false;

  static const Map<String, Locale> _languages = {
    'it': Locale('it'),
    'en': Locale('en'),
    'fr': Locale('fr'),
    'es': Locale('es'),
    'de': Locale('de'),
    'pt': Locale('pt'),
  };

  static String _languageName(String code) {
    switch (code) {
      case 'it':
        return 'Italiano';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      default:
        return code;
    }
  }

  /// Applica la lingua IMMEDIATAMENTE (feedback) e la persiste: se l'utente
  /// chiude l'app prima del passo 2, al prossimo avvio riparte dall'avviso
  /// già localizzato (flag language_selected salvato).
  Future<void> _applyLanguage(Locale locale) async {
    if (_selectedLocale == locale) return;
    setState(() => _selectedLocale = locale);
    widget.onLocaleChanged?.call(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    await prefs.setBool('language_selected', true);
  }

  Future<void> _nextStep() async {
    if (_selectedLocale == null) return;
    setState(() => _step = 1);
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('warning_accepted', true);
    await Future.delayed(const Duration(milliseconds: 100));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
              Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _step == 0
                    ? _buildLanguageStep(l10n)
                    : _buildWarningStep(l10n),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------- Passo 1: lingua -------------------------

  Widget _buildLanguageStep(AppLocalizations? l10n) {
    // Prima del primo avvio non è garantito un l10n: usa i fallback inglesi
    // (pari ai testi originali del flusso di selezione lingua).
    final title = l10n?.languageSelectionTitle ?? 'Language Selection';
    final desc =
        l10n?.languageSelectionDesc ?? 'Select the language for the application';
    final next = l10n?.onboardingContinue ?? 'Next';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.language,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Text(
          desc,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Card(
          child: RadioGroup<Locale>(
            groupValue: _selectedLocale,
            onChanged: (Locale? value) {
              if (value != null) _applyLanguage(value);
            },
            child: Column(
              children: _languages.entries.map((entry) {
                return RadioListTile<Locale>(
                  title: Text(_languageName(entry.key)),
                  value: entry.value,
                  selected: _selectedLocale?.languageCode == entry.key,
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedLocale == null ? null : _nextStep,
            icon: const Icon(Icons.arrow_forward),
            label: Text(next),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size(200, 48),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------ Passo 2: avvio rischi ------------------------

  Widget _buildWarningStep(AppLocalizations? l10n) {
    final a = l10n ?? _englishFallback();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          a.warningTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          a.warningSubtitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.warningMessage,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              _buildWarningItem(Icons.error_outline, a.warningGrub,
                  a.warningGrubDesc),
              const SizedBox(height: 12),
              _buildWarningItem(Icons.delete_outline, a.warningKernel,
                  a.warningKernelDesc),
              const SizedBox(height: 12),
              _buildWarningItem(Icons.settings_power, a.warningServices,
                  a.warningServicesDesc),
              const SizedBox(height: 12),
              _buildWarningItem(Icons.delete_forever, a.warningCleanup,
                  a.warningCleanupDesc),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        a.warningBackup,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (widget.systemInfo != null) ...[
          _buildSystemInfoCard(widget.systemInfo!, a),
          const SizedBox(height: 24),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _complete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              a.warningAccept,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  /// Fallback EN assoluti (usati solo se l10n non risolvibile, cosa che
  /// non succede: il passo avviso è raggiungibile solo dopo la scelta
  /// della lingua).
  static AppLocalizations _englishFallback() {
    return lookupAppLocalizations(const Locale('en'));
  }

  Widget _buildWarningItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.tertiary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfoCard(SystemDetectionInfo info, AppLocalizations a) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.computer,
                  color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Text(
                a.warningSystemCard,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              a.warningOsLabel,
              '${info.distribution} ${info.distributionVersion}'),
          _buildInfoRow(a.warningDesktopLabel, info.desktopEnvironment),
          if (info.hasGrub) ...[
            const SizedBox(height: 8),
            _buildInfoRow(a.warningGrubCommand, info.grubUpdateCommand),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (info.hasSystemd) _buildFeatureChip('Systemd', Icons.settings),
              if (info.hasGsettings)
                _buildFeatureChip('Gsettings', Icons.tune),
              if (info.hasGnome)
                _buildFeatureChip('GNOME', Icons.desktop_windows),
              if (info.hasKde) _buildFeatureChip('KDE', Icons.desktop_mac),
              if (info.hasXfce)
                _buildFeatureChip('XFCE', Icons.desktop_windows),
              if (info.hasApt) _buildFeatureChip('APT', Icons.inventory),
              if (info.hasDnf) _buildFeatureChip('DNF', Icons.inventory),
              if (info.hasPacman) _buildFeatureChip('Pacman', Icons.inventory),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
