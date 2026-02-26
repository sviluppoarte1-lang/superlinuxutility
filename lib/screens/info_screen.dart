import 'dart:async';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/config/app_build.dart';
import 'package:super_linux_utility/services/license_service.dart';
import 'license_activation_dialog.dart';

class InfoScreen extends StatefulWidget {
  final VoidCallback? onLicenseActivated;

  const InfoScreen({super.key, this.onLicenseActivated});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  String _appVersion = '1.8.6';
  String _appName = 'Super Linux Utility';
  bool _licenseActivated = false;
  bool _licenseCheckDone = false;

  @override
  void initState() {
    super.initState();
    _loadAppInfoAsync();
    if (isAdvancedBuild) _checkLicense();
  }

  Future<void> _checkLicense() async {
    final activated = await isActivated();
    if (mounted) setState(() { _licenseActivated = activated; _licenseCheckDone = true; });
  }

  Future<void> _openLicenseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => LicenseActivationDialog(
        onActivated: () {},
      ),
    );
    if (result == true && mounted) {
      await _checkLicense();
      widget.onLicenseActivated?.call();
    }
  }

  /// Carica PackageInfo in modo completamente asincrono senza bloccare l'UI
  void _loadAppInfoAsync() {
    // Usa un delay per assicurarsi che l'UI sia renderizzata prima
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadAppInfo();
      }
    });
  }

  Future<void> _loadAppInfo() async {
    if (!mounted) return;
    
    try {
      // Timeout ridotto a 1 secondo - se è lento, usa i valori di default
      final packageInfo = await PackageInfo.fromPlatform()
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              throw TimeoutException('Timeout PackageInfo');
            },
          );
      
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
          _appName = packageInfo.appName;
        });
      }
    } on TimeoutException {
      // Timeout - mantieni valori di default (già impostati)
      // Non loggare per non intasare la console
    } catch (e) {
      // Usa i valori di default se non riesce a caricare
      // Non loggare per non intasare la console
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      // Se le localizzazioni non sono disponibili, mostra un messaggio di errore
      return const Center(
        child: Text('Errore nel caricamento delle localizzazioni'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header con icona e nome app
          const Icon(
            Icons.settings_applications,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            _appName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${localizations.version} $_appVersion',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${localizations.creator}: ${localizations.creatorName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),

          // Descrizione
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appDescription.split('.').isNotEmpty 
                        ? localizations.appDescription.split('.')[0] + '.'
                        : localizations.appDescription,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.appDescription,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (isAdvancedBuild && _licenseCheckDone && !_licenseActivated) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_open, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          localizations.licenseActivateCardTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      localizations.licenseActivateCardDesc,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openLicenseDialog,
                      icon: const Icon(Icons.key),
                      label: Text(localizations.licenseActivateButton),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Caratteristiche principali
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoServices,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoServicesAnalysis,
                    localizations.infoServicesAnalysisDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoServicesManagement,
                    localizations.infoServicesManagementDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoServicesStatus,
                    localizations.infoServicesStatusDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.apps, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoStartupApps,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoStartupAppsManagement,
                    localizations.infoStartupAppsManagementDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoStartupAppsProtection,
                    localizations.infoStartupAppsProtectionDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoStartupAppsTermination,
                    localizations.infoStartupAppsTerminationDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cleaning_services, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoCleanup,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoCleanupTempFiles,
                    localizations.infoCleanupTempFilesDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoCleanupCache,
                    localizations.infoCleanupCacheDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoCleanupTrash,
                    localizations.infoCleanupTrashDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoInstalledApps,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoInstalledAppsManagement,
                    localizations.infoInstalledAppsManagementDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoInstalledAppsDependencies,
                    localizations.infoInstalledAppsDependenciesDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoInstalledAppsWarnings,
                    localizations.infoInstalledAppsWarningsDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monitor, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoMonitor,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoMonitorProcesses,
                    localizations.infoMonitorProcessesDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoMonitorSorting,
                    localizations.infoMonitorSortingDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoMonitorTermination,
                    localizations.infoMonitorTerminationDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoMonitorSystemInfo,
                    localizations.infoMonitorSystemInfoDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.palette, color: Colors.pink),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoAppearance,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoAppearanceFonts,
                    localizations.infoAppearanceFontsDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoAppearanceRendering,
                    localizations.infoAppearanceRenderingDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoAppearanceThemes,
                    localizations.infoAppearanceThemesDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoAppearanceWallpaper,
                    localizations.infoAppearanceWallpaperDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoAppearanceWindows,
                    localizations.infoAppearanceWindowsDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoGrub,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoGrubEditor,
                    localizations.infoGrubEditorDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoGrubBackup,
                    localizations.infoGrubBackupDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoGrubUpdate,
                    localizations.infoGrubUpdateDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoGrubRestore,
                    localizations.infoGrubRestoreDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.memory, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoKernel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoKernelList,
                    localizations.infoKernelListDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoKernelRemoval,
                    localizations.infoKernelRemovalDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoKernelDefault,
                    localizations.infoKernelDefaultDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoKernelCleanup,
                    localizations.infoKernelCleanupDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text(
                        localizations.infoSecurity,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    localizations.infoSecurityPassword,
                    localizations.infoSecurityPasswordDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoSecurityWarning,
                    localizations.infoSecurityWarningDesc,
                  ),
                  _buildFeatureItem(
                    localizations.infoSecurityMode,
                    localizations.infoSecurityModeDesc,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Footer
          Text(
            localizations.appTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '© 2024 ${localizations.creatorName}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.appExpertUsers,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

