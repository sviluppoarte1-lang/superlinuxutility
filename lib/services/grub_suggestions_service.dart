import 'dart:io';
import 'hardware_analyzer.dart';
import 'grub_service.dart';

/// Rappresenta un suggerimento GRUB
class GrubSuggestion {
  final String parameter;
  final String? currentValue;
  final String suggestedValue;
  final String reason;
  final SuggestionPriority priority;
  final bool isAlreadyPresent;

  GrubSuggestion({
    required this.parameter,
    this.currentValue,
    required this.suggestedValue,
    required this.reason,
    this.priority = SuggestionPriority.medium,
    this.isAlreadyPresent = false,
  });
}

enum SuggestionPriority {
  low,
  medium,
  high,
}

/// Servizio per generare suggerimenti GRUB basati sull'hardware
class GrubSuggestionsService {
  /// Genera suggerimenti GRUB basati sull'hardware
  static Future<List<GrubSuggestion>> generateSuggestions() async {
    final suggestions = <GrubSuggestion>[];

    try {
      // Analizza l'hardware
      final hardwareInfo = await HardwareAnalyzer.analyzeHardware();

      // Leggi la configurazione GRUB corrente
      final grubConfig = await GrubService.readGrubConfig();
      final currentParams = _parseGrubConfig(grubConfig);

      // Genera suggerimenti basati su CPU
      final cpuInfo = hardwareInfo['cpu'] as Map<String, dynamic>?;
      if (cpuInfo != null) {
        suggestions.addAll(_suggestCpuParams(cpuInfo, currentParams));
      }

      // Genera suggerimenti basati su RAM
      final ramInfo = hardwareInfo['ram'] as Map<String, dynamic>?;
      if (ramInfo != null) {
        suggestions.addAll(_suggestRamParams(ramInfo, currentParams));
      }

      // Genera suggerimenti basati su GPU
      final gpuInfo = hardwareInfo['gpu'] as Map<String, dynamic>?;
      if (gpuInfo != null) {
        suggestions.addAll(_suggestGpuParams(gpuInfo, currentParams));
      }

      // Genera suggerimenti basati su firmware
      final firmwareInfo = hardwareInfo['firmware'] as Map<String, dynamic>?;
      if (firmwareInfo != null) {
        suggestions.addAll(_suggestFirmwareParams(firmwareInfo, currentParams));
      }

      // Genera suggerimenti generici di performance
      suggestions.addAll(_suggestPerformanceParams(currentParams));

      // Ordina per priorità
      suggestions.sort((a, b) {
        final priorityOrder = {
          SuggestionPriority.high: 0,
          SuggestionPriority.medium: 1,
          SuggestionPriority.low: 2,
        };
        return priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
      });

      return suggestions;
    } catch (e) {
      print('Errore nella generazione suggerimenti: $e');
      return suggestions;
    }
  }

  /// Analizza la configurazione GRUB e estrae i parametri
  static Map<String, String> _parseGrubConfig(String config) {
    final params = <String, String>{};
    
    final lines = config.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('GRUB_') && trimmed.contains('=')) {
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          // Rimuovi le virgolette se presenti
          String cleanValue = value;
          if (cleanValue.startsWith('"') || cleanValue.startsWith("'")) {
            cleanValue = cleanValue.substring(1);
          }
          if (cleanValue.endsWith('"') || cleanValue.endsWith("'")) {
            cleanValue = cleanValue.substring(0, cleanValue.length - 1);
          }
          params[key] = cleanValue;
        }
      }
    }

    return params;
  }

  /// Genera suggerimenti basati sulla CPU
  static List<GrubSuggestion> _suggestCpuParams(
    Map<String, dynamic> cpuInfo,
    Map<String, String> currentParams,
  ) {
    final suggestions = <GrubSuggestion>[];

    final cores = cpuInfo['cores'] as int?;
    final threadsPerCore = cpuInfo['threads_per_core'] as int?;
    final flags = cpuInfo['flags'] as String? ?? '';
    final arch = cpuInfo['arch'] as String? ?? '';

    // Suggerimento per CPU con molti core
    if (cores != null && cores >= 8) {
      final currentValue = currentParams['GRUB_CMDLINE_LINUX_DEFAULT'] ?? '';
      if (!currentParams.containsKey('GRUB_CMDLINE_LINUX_DEFAULT') ||
          !currentValue.contains('threadirqs')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentValue.isEmpty ? null : currentValue,
          suggestedValue: _addToCmdline(currentValue, 'threadirqs'),
          reason: 'CPU con $cores core: threadirqs migliora le prestazioni multi-core',
          priority: SuggestionPriority.medium,
          isAlreadyPresent: currentValue.contains('threadirqs'),
        ));
      }
    }

    // Suggerimento per mitigazioni CPU (se non già presenti)
    final currentCmdline = currentParams['GRUB_CMDLINE_LINUX_DEFAULT'] ?? '';
    if (cores != null && cores >= 4) {
      // Per CPU moderne, alcune mitigazioni possono essere disabilitate per performance
      if (!currentCmdline.contains('mitigations=')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'mitigations=off'),
          reason: 'CPU moderna: disabilitare mitigazioni può migliorare le prestazioni (solo se sicurezza non critica)',
          priority: SuggestionPriority.low,
          isAlreadyPresent: false,
        ));
      }
    }

    // Suggerimento per CPU Intel/AMD specifici
    final model = (cpuInfo['model'] as String? ?? '').toLowerCase();
    if (model.contains('intel')) {
      if (!currentCmdline.contains('intel_iommu=')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'intel_iommu=on'),
          reason: 'CPU Intel: abilitare IOMMU per virtualizzazione e sicurezza',
          priority: SuggestionPriority.low,
          isAlreadyPresent: false,
        ));
      }
    } else if (model.contains('amd')) {
      if (!currentCmdline.contains('amd_iommu=')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'amd_iommu=on'),
          reason: 'CPU AMD: abilitare IOMMU per virtualizzazione e sicurezza',
          priority: SuggestionPriority.low,
          isAlreadyPresent: false,
        ));
      }
    }

    return suggestions;
  }

  /// Genera suggerimenti basati sulla RAM
  static List<GrubSuggestion> _suggestRamParams(
    Map<String, dynamic> ramInfo,
    Map<String, String> currentParams,
  ) {
    final suggestions = <GrubSuggestion>[];

    final totalKb = ramInfo['total_kb'] as int?;
    if (totalKb == null) return suggestions;

    final totalGb = totalKb / (1024 * 1024);
    final currentCmdline = currentParams['GRUB_CMDLINE_LINUX_DEFAULT'] ?? '';

    // Per sistemi con molta RAM, suggerisci di disabilitare zswap
    if (totalGb >= 16 && !currentCmdline.contains('zswap.enabled=')) {
      suggestions.add(GrubSuggestion(
        parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
        currentValue: currentCmdline.isEmpty ? null : currentCmdline,
        suggestedValue: _addToCmdline(currentCmdline, 'zswap.enabled=0'),
        reason: 'Sistema con ${totalGb.toStringAsFixed(1)} GB RAM: zswap non necessario',
        priority: SuggestionPriority.low,
        isAlreadyPresent: false,
      ));
    }

    // Per sistemi con poca RAM, suggerisci zswap
    if (totalGb < 8 && !currentCmdline.contains('zswap.enabled=')) {
      suggestions.add(GrubSuggestion(
        parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
        currentValue: currentCmdline.isEmpty ? null : currentCmdline,
        suggestedValue: _addToCmdline(currentCmdline, 'zswap.enabled=1'),
        reason: 'Sistema con ${totalGb.toStringAsFixed(1)} GB RAM: zswap può migliorare le prestazioni',
        priority: SuggestionPriority.medium,
        isAlreadyPresent: false,
      ));
    }

    return suggestions;
  }

  /// Genera suggerimenti basati sulla GPU
  static List<GrubSuggestion> _suggestGpuParams(
    Map<String, dynamic> gpuInfo,
    Map<String, String> currentParams,
  ) {
    final suggestions = <GrubSuggestion>[];

    final vendor = gpuInfo['vendor'] as String?;
    final hasNvidia = gpuInfo['has_nvidia'] as bool? ?? false;
    final currentCmdline = currentParams['GRUB_CMDLINE_LINUX_DEFAULT'] ?? '';

    // Suggerimenti per NVIDIA
    if (hasNvidia || vendor == 'nvidia') {
      if (!currentCmdline.contains('nvidia-drm.modeset=')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'nvidia-drm.modeset=1'),
          reason: 'GPU NVIDIA rilevata: abilitare modeset per migliori prestazioni',
          priority: SuggestionPriority.high,
          isAlreadyPresent: false,
        ));
      }

      if (!currentCmdline.contains('nvidia.NVreg_PreserveVideoMemoryAllocations=')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'nvidia.NVreg_PreserveVideoMemoryAllocations=1'),
          reason: 'GPU NVIDIA: preservare allocazioni memoria video',
          priority: SuggestionPriority.medium,
          isAlreadyPresent: false,
        ));
      }
    }

    // Suggerimenti per AMD
    if (vendor == 'amd') {
      if (!currentCmdline.contains('amdgpu.ppfeaturemask=')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'amdgpu.ppfeaturemask=0xffffffff'),
          reason: 'GPU AMD: abilitare tutte le funzionalità di power management',
          priority: SuggestionPriority.medium,
          isAlreadyPresent: false,
        ));
      }
    }

    // Suggerimento generico per GPU
    if (!currentCmdline.contains('video=') && vendor != null) {
      suggestions.add(GrubSuggestion(
        parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
        currentValue: currentCmdline.isEmpty ? null : currentCmdline,
        suggestedValue: _addToCmdline(currentCmdline, 'video=1920x1080'),
        reason: 'Impostare risoluzione video per evitare problemi al boot',
        priority: SuggestionPriority.low,
        isAlreadyPresent: false,
      ));
    }

    return suggestions;
  }

  /// Genera suggerimenti basati sul firmware
  static List<GrubSuggestion> _suggestFirmwareParams(
    Map<String, dynamic> firmwareInfo,
    Map<String, String> currentParams,
  ) {
    final suggestions = <GrubSuggestion>[];

    final isUefi = firmwareInfo['is_uefi'] as bool? ?? false;
    final secureBoot = firmwareInfo['secure_boot'] as bool?;

    // Per UEFI, verifica che GRUB_CMDLINE_LINUX_DEFAULT contenga i parametri corretti
    if (isUefi) {
      final currentCmdline = currentParams['GRUB_CMDLINE_LINUX_DEFAULT'] ?? '';
      
      if (!currentCmdline.contains('quiet') && !currentCmdline.contains('splash')) {
        suggestions.add(GrubSuggestion(
          parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
          currentValue: currentCmdline.isEmpty ? null : currentCmdline,
          suggestedValue: _addToCmdline(currentCmdline, 'quiet splash'),
          reason: 'UEFI: quiet splash migliora l\'esperienza di boot',
          priority: SuggestionPriority.low,
          isAlreadyPresent: false,
        ));
      }
    }

    return suggestions;
  }

  /// Genera suggerimenti generici di performance
  static List<GrubSuggestion> _suggestPerformanceParams(Map<String, String> currentParams) {
    final suggestions = <GrubSuggestion>[];

    final currentCmdline = currentParams['GRUB_CMDLINE_LINUX_DEFAULT'] ?? '';

    // Suggerimento per I/O scheduler
    if (!currentCmdline.contains('elevator=')) {
      // Per SSD moderni, suggerisci none o mq-deadline
      try {
        final lsblkResult = Process.runSync('lsblk', ['-d', '-o', 'ROTA']);
        if (lsblkResult.exitCode == 0) {
          final output = lsblkResult.stdout.toString();
          if (!output.contains('1')) {
            // Nessun disco rotativo, probabilmente solo SSD
            suggestions.add(GrubSuggestion(
              parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
              currentValue: currentCmdline.isEmpty ? null : currentCmdline,
              suggestedValue: _addToCmdline(currentCmdline, 'elevator=none'),
              reason: 'Sistema con SSD: elevator=none per migliori prestazioni I/O',
              priority: SuggestionPriority.medium,
              isAlreadyPresent: false,
            ));
          }
        }
      } catch (e) {
        // Ignora errori
      }
    }

    // Suggerimento per swappiness (se non già presente)
    if (!currentCmdline.contains('swappiness=')) {
      suggestions.add(GrubSuggestion(
        parameter: 'GRUB_CMDLINE_LINUX_DEFAULT',
        currentValue: currentCmdline.isEmpty ? null : currentCmdline,
        suggestedValue: _addToCmdline(currentCmdline, 'vm.swappiness=10'),
        reason: 'Ridurre swappiness per sistemi con RAM sufficiente',
        priority: SuggestionPriority.low,
        isAlreadyPresent: false,
      ));
    }

    return suggestions;
  }

  /// Aggiunge un parametro a GRUB_CMDLINE_LINUX_DEFAULT
  static String _addToCmdline(String current, String param) {
    if (current.isEmpty) {
      return param;
    }
    // Verifica se il parametro è già presente
    final paramName = param.split('=')[0];
    if (current.contains(paramName)) {
      return current; // Già presente
    }
    return '$current $param';
  }

  /// Applica un suggerimento alla configurazione GRUB
  static Future<String> applySuggestion(GrubSuggestion suggestion, String currentConfig) async {
    final lines = currentConfig.split('\n');
    final newLines = <String>[];

    bool found = false;
    for (final line in lines) {
      if (line.trim().startsWith(suggestion.parameter) && line.contains('=')) {
        // Sostituisci la linea esistente
        if (suggestion.parameter == 'GRUB_CMDLINE_LINUX_DEFAULT') {
          final currentValue = _extractCurrentValue(line);
          final newValue = suggestion.suggestedValue;
          newLines.add('${suggestion.parameter}="$newValue"');
        } else {
          newLines.add('${suggestion.parameter}="${suggestion.suggestedValue}"');
        }
        found = true;
      } else {
        newLines.add(line);
      }
    }

    // Se non trovato, aggiungi alla fine
    if (!found) {
      newLines.add('${suggestion.parameter}="${suggestion.suggestedValue}"');
    }

    return newLines.join('\n');
  }

  /// Estrae il valore corrente da una linea GRUB
  static String _extractCurrentValue(String line) {
    if (!line.contains('=')) return '';
    final parts = line.split('=');
    if (parts.length < 2) return '';
    final value = parts.sublist(1).join('=').trim();
    String cleanValue = value;
    if (cleanValue.startsWith('"') || cleanValue.startsWith("'")) {
      cleanValue = cleanValue.substring(1);
    }
    if (cleanValue.endsWith('"') || cleanValue.endsWith("'")) {
      cleanValue = cleanValue.substring(0, cleanValue.length - 1);
    }
    return cleanValue;
  }
}

