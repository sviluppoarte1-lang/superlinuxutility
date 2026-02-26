import 'dart:io';
import '../models/systemd_service.dart';
import 'password_storage.dart';

class SystemAnalyzer {
  static Future<String?> _getPassword() async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    return password;
  }

  /// Esegue un comando con sudo usando la password salvata
  static Future<ProcessResult> _runSudoCommand(
    String command, {
    String? password,
  }) async {
    final pwd = password ?? await _getPassword();
    final fullCommand = 'echo "$pwd" | sudo -S $command';
    
    return await Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
  }

  /// Analizza tutti i servizi systemd (versione semplificata e veloce)
  static Future<List<SystemdService>> analyzeSystemdServices() async {
    try {
      // Ottieni la lista dei servizi con informazioni complete
      final result = await Process.run(
        'systemctl',
        ['list-units', '--type=service', '--all', '--no-pager', '--full'],
      );

      if (result.exitCode != 0) {
        throw Exception('Errore nel recupero dei servizi: ${result.stderr}');
      }

      final lines = (result.stdout as String).split('\n');
      final services = <SystemdService>[];

      // Salta le prime due righe (header)
      for (var i = 2; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          // Parsing migliorato della linea systemctl
          // Formato: UNIT LOAD ACTIVE SUB DESCRIPTION
          // Esempio: "acpid.service loaded active running ACPI Daemon"
          final parts = line.split(RegExp(r'\s+'));
          if (parts.length < 3) continue;

          final name = parts[0];
          if (!name.endsWith('.service')) continue;
          
          final active = parts[2];
          
          // Verifica se è abilitato (in modo asincrono ma senza bloccare)
          bool isEnabled = false;
          try {
            final enabledResult = await Process.run(
              'systemctl',
              ['is-enabled', name, '--no-pager'],
            );
            isEnabled = (enabledResult.stdout as String).trim() == 'enabled';
          } catch (e) {
            // Se fallisce, assume che non sia abilitato
            isEnabled = false;
          }
          
          // Ottieni la descrizione (opzionale, non blocca se fallisce)
          String? description;
          try {
            final showResult = await Process.run(
              'systemctl',
              ['show', name, '--property=Description', '--no-pager'],
            );
            
            if (showResult.exitCode == 0) {
              final descLine = (showResult.stdout as String).trim();
              if (descLine.startsWith('Description=')) {
                description = descLine.substring('Description='.length).trim();
                if (description.isEmpty) description = null;
              }
            }
          } catch (e) {
            // Ignora errori nella descrizione
          }

          final service = SystemdService(
            name: name,
            status: active,
            isEnabled: isEnabled,
            isActive: active == 'active',
            description: description,
            isSlow: false,
          );
          
          services.add(service);
        } catch (e) {
          // Ignora servizi con formato non valido
          continue;
        }
      }

      return services;
    } catch (e) {
      throw Exception('Errore durante l\'analisi dei servizi: $e');
    }
  }

  /// Ottiene i servizi più lenti all'avvio
  static Future<List<SystemdService>> getSlowServices() async {
    try {
      final result = await Process.run(
        'systemd-analyze',
        ['blame', '--no-pager'],
      );

      if (result.exitCode != 0) {
        throw Exception('Errore: ${result.stderr}');
      }

      final lines = (result.stdout as String).split('\n');
      final slowServices = <SystemdService>[];

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Formato: "3.234s service-name.service"
        final match = RegExp(r'(\d+\.?\d*)\s*(ms|s|m)\s+(.+)').firstMatch(line);
        if (match != null) {
          final value = double.parse(match.group(1)!);
          final unit = match.group(2)!;
          final serviceName = match.group(3)!.trim();
          
          Duration duration;
          switch (unit) {
            case 'ms':
              duration = Duration(milliseconds: value.toInt());
              break;
            case 's':
              duration = Duration(seconds: value.toInt());
              break;
            case 'm':
              duration = Duration(minutes: value.toInt());
              break;
            default:
              continue;
          }

          // Considera lento un servizio che impiega più di 2 secondi
          if (duration.inSeconds >= 2) {
            final serviceInfo = await _getServiceInfo(serviceName);
            slowServices.add(SystemdService(
              name: serviceName,
              status: serviceInfo['status'] ?? 'unknown',
              bootTime: duration,
              isEnabled: serviceInfo['enabled'] ?? false,
              isActive: serviceInfo['active'] ?? false,
              description: serviceInfo['description'],
              isSlow: true,
            ));
          }
        }
      }

      return slowServices;
    } catch (e) {
      throw Exception('Errore durante l\'analisi dei servizi lenti: $e');
    }
  }

  /// Ottiene informazioni dettagliate su un servizio
  static Future<Map<String, dynamic>> _getServiceInfo(String serviceName) async {
    try {
      final statusResult = await Process.run(
        'systemctl',
        ['is-active', serviceName],
      );
      
      final enabledResult = await Process.run(
        'systemctl',
        ['is-enabled', serviceName],
      );

      final showResult = await Process.run(
        'systemctl',
        ['show', serviceName, '--property=Description'],
      );

      String? description;
      if (showResult.exitCode == 0) {
        final descLine = (showResult.stdout as String).split('=');
        if (descLine.length > 1) {
          description = descLine[1].trim();
        }
      }

      return {
        'status': (statusResult.stdout as String).trim(),
        'active': (statusResult.stdout as String).trim() == 'active',
        'enabled': (enabledResult.stdout as String).trim() == 'enabled',
        'description': description,
      };
    } catch (e) {
      return {
        'status': 'unknown',
        'active': false,
        'enabled': false,
        'description': null,
      };
    }
  }

  /// Disabilita un servizio all'avvio
  static Future<bool> disableService(String serviceName) async {
    try {
      final result = await _runSudoCommand('systemctl disable $serviceName');
      return result.exitCode == 0;
    } catch (e) {
      throw Exception('Errore durante la disabilitazione del servizio: $e');
    }
  }

  /// Ferma un servizio
  static Future<bool> stopService(String serviceName) async {
    try {
      final result = await _runSudoCommand('systemctl stop $serviceName');
      return result.exitCode == 0;
    } catch (e) {
      throw Exception('Errore durante l\'arresto del servizio: $e');
    }
  }

  /// Abilita un servizio all'avvio
  static Future<bool> enableService(String serviceName) async {
    try {
      final result = await _runSudoCommand('systemctl enable $serviceName');
      return result.exitCode == 0;
    } catch (e) {
      throw Exception('Errore durante l\'abilitazione del servizio: $e');
    }
  }

  /// Ottiene tutti i servizi disabilitati
  static Future<List<SystemdService>> getDisabledServices() async {
    try {
      final result = await Process.run(
        'systemctl',
        ['list-unit-files', '--type=service', '--state=disabled', '--no-pager'],
      );

      if (result.exitCode != 0) {
        throw Exception('Errore nel recupero dei servizi disabilitati: ${result.stderr}');
      }

      final lines = (result.stdout as String).split('\n');
      final services = <SystemdService>[];

      // Salta la prima riga (header)
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Formato: "service-name.service disabled"
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final serviceName = parts[0];
          final state = parts[1];

          if (state == 'disabled') {
            final serviceInfo = await _getServiceInfo(serviceName);
            services.add(SystemdService(
              name: serviceName,
              status: serviceInfo['status'] ?? 'inactive',
              isEnabled: false,
              isActive: serviceInfo['active'] ?? false,
              description: serviceInfo['description'],
              isSlow: false,
            ));
          }
        }
      }

      return services;
    } catch (e) {
      throw Exception('Errore durante il recupero dei servizi disabilitati: $e');
    }
  }
}

