import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import '../services/system_detector.dart';

class WarningScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;
  final Function(Locale?)? onLocaleChanged;
  final SystemDetectionInfo? systemInfo;
  final VoidCallback? onComplete;
  
  const WarningScreen({
    super.key, 
    this.onThemeModeChanged, 
    this.onLocaleChanged,
    this.systemInfo,
    this.onComplete,
  });

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  bool _dontShowAgain = false;

  Future<void> _acceptAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    // Salva sempre il flag che i warning sono stati accettati
    await prefs.setBool('warning_accepted', true);
    
    // Attendi un momento per assicurarsi che il flag sia salvato
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (mounted) {
      // Naviga alla route principale per far ricontrollare i flag
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icona di avviso
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 80,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Titolo
                  Text(
                    AppLocalizations.of(context)!.warningTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sottotitolo
                  Text(
                    AppLocalizations.of(context)!.warningSubtitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Messaggio principale
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.warningMessage,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildWarningItem(
                          Icons.error_outline,
                          AppLocalizations.of(context)!.warningGrub,
                          AppLocalizations.of(context)!.warningGrubDesc,
                        ),
                        const SizedBox(height: 12),
                        _buildWarningItem(
                          Icons.delete_outline,
                          AppLocalizations.of(context)!.warningKernel,
                          AppLocalizations.of(context)!.warningKernelDesc,
                        ),
                        const SizedBox(height: 12),
                        _buildWarningItem(
                          Icons.settings_power,
                          AppLocalizations.of(context)!.warningServices,
                          AppLocalizations.of(context)!.warningServicesDesc,
                        ),
                        const SizedBox(height: 12),
                        _buildWarningItem(
                          Icons.delete_forever,
                          AppLocalizations.of(context)!.warningCleanup,
                          AppLocalizations.of(context)!.warningCleanupDesc,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                                  AppLocalizations.of(context)!.warningBackup,
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
                  const SizedBox(height: 32),
                  
                  // Informazioni sistema rilevato
                  if (widget.systemInfo != null) ...[
                    _buildSystemInfoCard(widget.systemInfo!),
                    const SizedBox(height: 24),
                  ],
                  
                  // Checkbox "Non mostrare più"
                  CheckboxListTile(
                    value: _dontShowAgain,
                    onChanged: (value) {
                      setState(() {
                        _dontShowAgain = value ?? false;
                      });
                    },
                    title: Text(
                      AppLocalizations.of(context)!.warningDontShow,
                      style: const TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  
                  // Pulsante di accettazione
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _acceptAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.warningAccept,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.tertiary,
          size: 24,
        ),
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
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemInfoCard(SystemDetectionInfo systemInfo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.computer,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Text(
                'Sistema Rilevato',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Distribuzione', '${systemInfo.distribution} ${systemInfo.distributionVersion}'),
          _buildInfoRow('Desktop Environment', systemInfo.desktopEnvironment),
          if (systemInfo.hasGrub) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Comando GRUB', systemInfo.grubUpdateCommand),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (systemInfo.hasSystemd)
                _buildFeatureChip('Systemd', Icons.settings),
              if (systemInfo.hasGsettings)
                _buildFeatureChip('Gsettings', Icons.tune),
              if (systemInfo.hasGnome)
                _buildFeatureChip('GNOME', Icons.desktop_windows),
              if (systemInfo.hasKde)
                _buildFeatureChip('KDE', Icons.desktop_mac),
              if (systemInfo.hasXfce)
                _buildFeatureChip('XFCE', Icons.desktop_windows),
              if (systemInfo.hasApt)
                _buildFeatureChip('APT', Icons.inventory),
              if (systemInfo.hasDnf)
                _buildFeatureChip('DNF', Icons.inventory),
              if (systemInfo.hasPacman)
                _buildFeatureChip('Pacman', Icons.inventory),
              if (systemInfo.hasSnap)
                _buildFeatureChip('Snap', Icons.apps),
              if (systemInfo.hasFlatpak)
                _buildFeatureChip('Flatpak', Icons.apps),
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

