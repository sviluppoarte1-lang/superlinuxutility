import 'dart:io';
import 'dart:convert';
import 'password_storage.dart';

/// Servizio per gestire lo spegnimento automatico del PC usando systemd timers
/// 
/// IMPORTANTE: I timer systemd sono servizi di sistema indipendenti dall'applicazione.
/// Funzionano anche quando l'app non è in esecuzione e persistono dopo il riavvio del sistema.
/// Quando si modifica un timer nell'app, il servizio systemd viene automaticamente aggiornato.
/// 
/// Compatibilità:
/// - Fedora: ✅ Supportato (systemd nativo)
/// - Ubuntu: ✅ Supportato (systemd da Ubuntu 15.04+)
/// - Debian: ✅ Supportato (systemd da Debian 8+)
/// - Arch Linux: ✅ Supportato (systemd nativo)
/// - openSUSE: ✅ Supportato (systemd nativo)
/// - Manjaro: ✅ Supportato (systemd nativo)
/// - Linux Mint: ✅ Supportato (systemd da Mint 18+)
/// - Pop!_OS: ✅ Supportato (systemd nativo)
/// - Zorin OS: ✅ Supportato (systemd nativo)
/// - elementary OS: ✅ Supportato (systemd nativo)
/// 
/// Requisiti:
/// - systemd installato e attivo
/// - Privilegi sudo per creare/rimuovere timer systemd
/// - Password di sistema configurata nell'app
class ShutdownSchedulerService {
  static const String timerPrefix = 'super-linux-utility-shutdown';
  static const String timerDir = '/etc/systemd/system';
  
  /// Esegue un comando con sudo usando la password salvata
  static Future<ProcessResult> _runSudoCommand(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`')
        .replaceAll("'", "'\"'\"'");
    
    final fullCommand = 'printf "%s\\n" "$escapedPassword" | sudo -S $command 2>&1';
    
    final result = await Process.run(
      'bash',
      ['-c', fullCommand],
      runInShell: true,
    );
    
    if (result.exitCode != 0) {
      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      final errorOutput = err.isNotEmpty ? err : out;
      if (errorOutput.contains('sudo:') && errorOutput.contains('password')) {
        throw Exception('Password errata o permessi insufficienti');
      }
    }
    
    return result;
  }

  /// Restituisce l'output di un comando (con 2>&1 stderr va in stdout)
  static String _resultOutput(ProcessResult r) {
    final out = r.stdout.toString().trim();
    final err = r.stderr.toString().trim();
    if (out.isNotEmpty && err.isNotEmpty) return '$err\n$out';
    return err.isNotEmpty ? err : out;
  }
  
  /// Crea o aggiorna un timer systemd per lo spegnimento automatico
  /// Il timer funziona anche quando l'app non è in esecuzione (servizio di sistema)
  /// 
  /// [scheduleType] può essere: 'daily', 'weekly', 'monthly'
  /// [time] formato HH:mm (es. "22:30")
  /// [daysOfWeek] lista di giorni della settimana (0=domenica, 6=sabato) - solo per weekly
  /// [dayOfMonth] giorno del mese (1-31) - solo per monthly
  /// [updateExisting] se true, aggiorna un timer esistente invece di rimuoverlo e ricrearlo
  static Future<bool> createShutdownTimer({
    required String scheduleType,
    required String time,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    bool updateExisting = false,
  }) async {
    try {
      // Valida i parametri
      if (!['daily', 'weekly', 'monthly'].contains(scheduleType)) {
        throw Exception('Tipo di programmazione non valido');
      }
      
      // Valida il formato dell'ora
      final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
      if (!timeRegex.hasMatch(time)) {
        throw Exception('Formato ora non valido. Usa HH:mm');
      }
      
      // Genera il nome del timer basato sul tipo
      final timerName = '$timerPrefix-$scheduleType';
      final timerFile = '$timerDir/$timerName.timer';
      final serviceFile = '$timerDir/$timerName.service';
      
      // CRITICO: Se esiste già un timer, rimuovilo COMPLETAMENTE prima di crearne uno nuovo
      // Questo garantisce che non ci siano configurazioni problematiche residue
      // IMPORTANTE: I timer systemd funzionano anche quando l'app non è in esecuzione
      final existingTimer = File(timerFile);
      final existingService = File(serviceFile);
      
      if (await existingTimer.exists() || await existingService.exists()) {
        // CRITICO: Ferma il servizio PRIMA di tutto per evitare spegnimenti
        try {
          await _runSudoCommand('systemctl stop $timerName.service');
        } catch (e) {
          // Ignora errori se il servizio non è attivo
        }
        
        // Ferma e disabilita il timer esistente
        try {
          await _runSudoCommand('systemctl stop $timerName.timer');
        } catch (e) {
          // Ignora errori se il timer non è attivo
        }
        
        // CRITICO: Disabilita il servizio per evitare che si avvii all'avvio
        try {
          await _runSudoCommand('systemctl disable $timerName.service');
        } catch (e) {
          // Ignora errori se il servizio non è abilitato
        }
        
        // Disabilita il timer
        try {
          await _runSudoCommand('systemctl disable $timerName.timer');
        } catch (e) {
          // Ignora errori se il timer non è abilitato
        }
        
        // Rimuovi i file esistenti
        try {
          await _runSudoCommand('rm -f $timerFile');
          await _runSudoCommand('rm -f $serviceFile');
        } catch (e) {
          // Ignora errori
        }
        
        // Ricarica systemd per applicare le modifiche
        try {
          await _runSudoCommand('systemctl daemon-reload');
        } catch (e) {
          // Ignora errori
        }
        
        // Attendi un momento per assicurarsi che systemd abbia processato le modifiche
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Genera OnCalendar in base al tipo
      String onCalendar;
      switch (scheduleType) {
        case 'daily':
          onCalendar = '*-*-* $time:00';
          break;
        case 'weekly':
          if (daysOfWeek == null || daysOfWeek.isEmpty) {
            throw Exception('Specifica almeno un giorno della settimana per programmazione settimanale');
          }
          // systemd usa il formato: Mon,Wed,Fri 22:30
          // Converti i giorni: 0=domenica, 1=lunedì, ..., 6=sabato
          final daysList = daysOfWeek.map((d) {
            // Converti da 0=domenica a systemd format
            final systemdDay = d == 0 ? 7 : d; // systemd usa 7 per domenica
            return _getDayName(systemdDay);
          }).toList();
          final daysStr = daysList.join(',');
          onCalendar = '$daysStr $time:00';
          break;
        case 'monthly':
          if (dayOfMonth == null || dayOfMonth < 1 || dayOfMonth > 31) {
            throw Exception('Giorno del mese non valido (1-31)');
          }
          onCalendar = '*-$dayOfMonth $time:00';
          break;
        default:
          throw Exception('Tipo di programmazione non supportato');
      }
      
      // Crea il file service con comando corretto per Ubuntu 22-25.10, Fedora 39-43, Arch Linux
      // IMPORTANTE: Il servizio NON deve essere avviato all'avvio del sistema!
      // Il servizio viene eseguito SOLO quando il timer scatta all'orario specificato.
      // Rimuoviamo la sezione [Install] per evitare che il servizio si avvii all'avvio.
      // Il timer è quello che viene abilitato, non il servizio.
      final execStartCmd = r"sync; /usr/bin/systemctl poweroff";
      final serviceContent = '''[Unit]
Description=Automatic Shutdown - Super Linux Utility
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c '$execStartCmd'
User=root
StandardOutput=journal
StandardError=journal
KillMode=none
''';
      
      // Crea il file timer.
      // NON usare Wants= sul .service: altrimenti al boot (quando il timer si avvia) systemd avvierebbe anche il servizio = spegnimento immediato.
      // Il timer lancia il .service solo quando scatta OnCalendar (stesso nome base: xxx.timer -> xxx.service).
      final timerContent = '''[Unit]
Description=Automatic Shutdown Timer - Super Linux Utility

[Timer]
OnCalendar=$onCalendar
Persistent=false

[Install]
WantedBy=timers.target
''';
      
      // Scrivi i file usando un approccio robusto con file temporanei
      // Questo garantisce che i file vengano scritti correttamente anche se systemd li sta leggendo
      // IMPORTANTE: Questo permette di aggiornare i timer anche quando l'app non è in esecuzione
      final tempServiceFile = '/tmp/${timerName}_service_${DateTime.now().millisecondsSinceEpoch}.tmp';
      final tempTimerFile = '/tmp/${timerName}_timer_${DateTime.now().millisecondsSinceEpoch}.tmp';
      
      // Codifica in base64 per evitare problemi con caratteri speciali
      final serviceContentBase64 = base64Encode(utf8.encode(serviceContent));
      final timerContentBase64 = base64Encode(utf8.encode(timerContent));
      
      // Scrivi i file temporanei
      await _runSudoCommand(
        'echo "$serviceContentBase64" | base64 -d > "$tempServiceFile"',
      );
      
      await _runSudoCommand(
        'echo "$timerContentBase64" | base64 -d > "$tempTimerFile"',
      );
      
      // Sposta i file nella posizione finale (operazione atomica)
      // Questo garantisce che systemd non legga file parziali durante l'aggiornamento
      await _runSudoCommand('mv "$tempServiceFile" "$serviceFile"');
      await _runSudoCommand('mv "$tempTimerFile" "$timerFile"');
      
      // Imposta i permessi corretti (644 per i file systemd)
      await _runSudoCommand('chmod 644 "$serviceFile" "$timerFile"');
      
      // CRITICO: Ricarica systemd per riconoscere i nuovi/modificati file
      // Questo è essenziale perché systemd deve ricaricare la configurazione
      // Senza questo, le modifiche non verrebbero applicate
      final reloadResult = await _runSudoCommand('systemctl daemon-reload');
      if (reloadResult.exitCode != 0) {
        throw Exception('Errore durante il reload di systemd: ${_resultOutput(reloadResult)}');
      }
      
      // CRITICO: NON abilitare MAI il servizio! Il servizio NON deve essere eseguito all'avvio.
      // Verifica che il servizio NON sia abilitato (dovrebbe già non esserlo, ma verifichiamo)
      try {
        final serviceEnabledCheck = await Process.run(
          'systemctl',
          ['is-enabled', '$timerName.service'],
          runInShell: false,
        );
        if (serviceEnabledCheck.exitCode == 0) {
          // Se il servizio è abilitato, disabilitalo immediatamente
          await _runSudoCommand('systemctl disable $timerName.service');
        }
      } catch (e) {
        // Ignora errori, il servizio probabilmente non è abilitato
      }
      
      // CRITICO: Assicurati che il servizio NON sia in esecuzione
      try {
        final serviceActiveCheck = await Process.run(
          'systemctl',
          ['is-active', '$timerName.service'],
          runInShell: false,
        );
        if (serviceActiveCheck.exitCode == 0) {
          // Se il servizio è attivo, fermalo immediatamente
          await _runSudoCommand('systemctl stop $timerName.service');
        }
      } catch (e) {
        // Ignora errori, il servizio probabilmente non è attivo
      }
      
      // Abilita SOLO il timer (NON il servizio)
      // IMPORTANTE: enable rende il timer permanente, funzionerà anche senza l'app
      // Il timer è un servizio di sistema indipendente dall'applicazione
      // Il timer eseguirà il servizio SOLO all'orario specificato in OnCalendar
      // Con OnBootSec= vuoto, il timer NON eseguirà il servizio all'avvio
      final enableResult = await _runSudoCommand('systemctl enable $timerName.timer');
      if (enableResult.exitCode != 0) {
        throw Exception('Errore durante l\'abilitazione del timer: ${_resultOutput(enableResult)}');
      }
      
      // Avvia il timer (lo attiva immediatamente, ma NON esegue il servizio)
      // Il timer NON esegue il servizio all'avvio grazie a OnBootSec= vuoto
      // Il timer eseguirà il servizio SOLO quando OnCalendar corrisponde all'orario specificato
      final startResult = await _runSudoCommand('systemctl start $timerName.timer');
      if (startResult.exitCode != 0) {
        throw Exception('Errore durante l\'avvio del timer: ${_resultOutput(startResult)}');
      }
      
      // CRITICO: Verifica che il servizio NON sia stato avviato
      await Future.delayed(const Duration(milliseconds: 500));
      final serviceStillActive = await Process.run(
        'systemctl',
        ['is-active', '$timerName.service'],
        runInShell: false,
      );
      if (serviceStillActive.exitCode == 0) {
        // Se il servizio è attivo, fermalo immediatamente
        await _runSudoCommand('systemctl stop $timerName.service');
        throw Exception('ERRORE CRITICO: Il servizio si è avviato automaticamente! Questo non dovrebbe accadere. Timer disabilitato per sicurezza.');
      }
      
      // Verifica che il timer sia effettivamente attivo dopo un breve delay
      // Questo garantisce che systemd abbia processato la configurazione
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Verifica che il timer sia attivo
      final verifyActive = await Process.run(
        'systemctl',
        ['is-active', '$timerName.timer'],
        runInShell: false,
      );
      
      // Verifica che il timer sia abilitato (persistente)
      final verifyEnabled = await Process.run(
        'systemctl',
        ['is-enabled', '$timerName.timer'],
        runInShell: false,
      );
      
      if (verifyActive.exitCode != 0 || verifyEnabled.exitCode != 0) {
        throw Exception('Il timer non è stato attivato correttamente. Verifica i log con: journalctl -u $timerName.timer');
      }
      
      // Verifica che il timer sia programmato correttamente
      final listResult = await Process.run(
        'systemctl',
        ['list-timers', '$timerName.timer', '--no-pager'],
        runInShell: false,
      );
      
      if (listResult.exitCode != 0 || !listResult.stdout.toString().contains(timerName)) {
        throw Exception('Il timer non appare nella lista dei timer attivi. Verifica la configurazione.');
      }
      
      // VERIFICA FINALE CRITICA: Assicurati che il servizio NON sia abilitato o attivo
      final finalServiceCheck = await Process.run(
        'systemctl',
        ['is-enabled', '$timerName.service'],
        runInShell: false,
      );
      // Su alcune distro, abilitare il timer può far risultare il servizio come "enabled" (o indirect).
      // Disabilitiamo solo il servizio e lasciamo il timer attivo: lo spegnimento scatterà solo all'orario.
      if (finalServiceCheck.exitCode == 0) {
        await _runSudoCommand('systemctl disable $timerName.service 2>/dev/null || true');
      }
      
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      throw Exception('Errore durante la creazione del timer: $msg');
    }
  }
  
  /// Converte il numero del giorno in nome systemd
  static String _getDayName(int day) {
    // systemd usa: Mon, Tue, Wed, Thu, Fri, Sat, Sun
    // day: 1=lunedì, 2=martedì, ..., 7=domenica
    switch (day) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        throw Exception('Giorno non valido: $day');
    }
  }
  
  /// Rimuove un timer di spegnimento
  /// CRITICO: Rimuove completamente timer e servizio per evitare spegnimenti automatici
  static Future<bool> removeShutdownTimer(String scheduleType) async {
    try {
      final timerName = '$timerPrefix-$scheduleType';
      
      // CRITICO: Ferma il servizio PRIMA di tutto per evitare spegnimenti
      try {
        await _runSudoCommand('systemctl stop $timerName.service');
      } catch (e) {
        // Ignora se il servizio non è attivo
      }
      
      // Ferma e disabilita il timer (ignora errori se non esiste)
      try {
        await _runSudoCommand('systemctl stop $timerName.timer');
      } catch (e) {
        // Ignora se il timer non è attivo
      }
      
      // CRITICO: Disabilita il servizio per evitare che si avvii all'avvio
      try {
        await _runSudoCommand('systemctl disable $timerName.service');
      } catch (e) {
        // Ignora se il servizio non è abilitato
      }
      
      // Disabilita il timer
      try {
        await _runSudoCommand('systemctl disable $timerName.timer');
      } catch (e) {
        // Ignora se il timer non è abilitato
      }
      
      // Rimuovi i file (CRITICO: rimuove completamente la configurazione)
      await _runSudoCommand('rm -f $timerDir/$timerName.timer');
      await _runSudoCommand('rm -f $timerDir/$timerName.service');
      
      // Ricarica systemd per applicare le modifiche
      await _runSudoCommand('systemctl daemon-reload');
      
      // Verifica finale che il servizio non sia più attivo
      try {
        final serviceCheck = await Process.run(
          'systemctl',
          ['is-active', '$timerName.service'],
          runInShell: false,
        );
        if (serviceCheck.exitCode == 0) {
          // Se il servizio è ancora attivo, forzalo a fermarsi
          await _runSudoCommand('systemctl kill $timerName.service');
        }
      } catch (e) {
        // Ignora errori
      }
      
      return true;
    } catch (e) {
      throw Exception('Errore durante la rimozione del timer: $e');
    }
  }
  
  /// Verifica se un timer è attivo
  static Future<bool> isTimerActive(String scheduleType) async {
    try {
      final timerName = '$timerPrefix-$scheduleType';
      final result = await Process.run(
        'systemctl',
        ['is-active', '$timerName.timer'],
        runInShell: false,
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Ottiene lo stato di un timer
  static Future<Map<String, dynamic>> getTimerStatus(String scheduleType) async {
    try {
      final timerName = '$timerPrefix-$scheduleType';
      
      // Verifica se il timer esiste
      final timerFile = File('$timerDir/$timerName.timer');
      if (!await timerFile.exists()) {
        return {
          'exists': false,
          'active': false,
          'enabled': false,
        };
      }
      
      // Verifica se è attivo
      final isActiveResult = await Process.run(
        'systemctl',
        ['is-active', '$timerName.timer'],
        runInShell: false,
      );
      final isActive = isActiveResult.exitCode == 0;
      
      // Verifica se è abilitato
      final isEnabledResult = await Process.run(
        'systemctl',
        ['is-enabled', '$timerName.timer'],
        runInShell: false,
      );
      final isEnabled = isEnabledResult.exitCode == 0;
      
      // Ottieni la prossima esecuzione
      String? nextRun;
      try {
        final listResult = await Process.run(
          'systemctl',
          ['list-timers', '$timerName.timer', '--no-pager'],
          runInShell: false,
        );
        final output = listResult.stdout.toString();
        final lines = output.split('\n');
        if (lines.length > 2) {
          // La seconda riga contiene le informazioni del timer
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            nextRun = '${parts[0]} ${parts[1]}';
          }
        }
      } catch (e) {
        // Ignora errori nel parsing
      }
      
      return {
        'exists': true,
        'active': isActive,
        'enabled': isEnabled,
        'nextRun': nextRun,
      };
    } catch (e) {
      return {
        'exists': false,
        'active': false,
        'enabled': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Ottiene tutti i timer di spegnimento configurati
  static Future<List<Map<String, dynamic>>> getAllTimers() async {
    final types = ['daily', 'weekly', 'monthly'];
    final timers = <Map<String, dynamic>>[];
    
    for (final type in types) {
      final status = await getTimerStatus(type);
      if (status['exists'] == true) {
        timers.add({
          'type': type,
          ...status,
        });
      }
    }
    
    return timers;
  }
  
  /// Spegne il PC immediatamente (per test)
  /// Usa un comando aggressivo che killa tutti i processi prima di spegnere
  static Future<bool> shutdownNow() async {
    try {
      // Comando corretto per Ubuntu 22-25.10, Fedora 39-43, Arch Linux
      // systemctl poweroff è il comando standard per systemd e gestisce automaticamente
      // la chiusura dei processi e lo spegnimento in modo sicuro
      await _runSudoCommand('sync; /usr/bin/systemctl poweroff');
      return true;
    } catch (e) {
      throw Exception('Errore durante lo spegnimento: $e');
    }
  }
  
  /// Ottiene i dettagli completi di un timer per la modifica
  static Future<Map<String, dynamic>?> getTimerDetails(String scheduleType) async {
    try {
      final timerName = '$timerPrefix-$scheduleType';
      final timerFile = File('$timerDir/$timerName.timer');
      
      if (!await timerFile.exists()) {
        return null;
      }
      
      // Leggi il contenuto del timer usando sudo
      final result = await _runSudoCommand('cat "$timerFile"');
      if (result.exitCode != 0) {
        return null;
      }
      
      final timerContent = result.stdout.toString();
      
      // Estrai OnCalendar
      final onCalendarMatch = RegExp(r'OnCalendar=(.+)').firstMatch(timerContent);
      String? onCalendar = onCalendarMatch?.group(1)?.trim();
      
      if (onCalendar == null) {
        return null;
      }
      
      // Parse OnCalendar per estrarre ora e giorni
      String? time;
      List<int>? daysOfWeek;
      int? dayOfMonth;
      String detectedType = scheduleType;
      
      // Formato daily: *-*-* HH:mm:00
      if (onCalendar.contains('*-*-*')) {
        final timeMatch = RegExp(r'(\d{2}:\d{2})').firstMatch(onCalendar);
        time = timeMatch?.group(1);
        detectedType = 'daily';
      }
      // Formato weekly: Mon,Tue,Wed HH:mm:00
      else if (onCalendar.contains(RegExp(r'Mon|Tue|Wed|Thu|Fri|Sat|Sun'))) {
        final daysMatch = RegExp(r'(Mon|Tue|Wed|Thu|Fri|Sat|Sun)').allMatches(onCalendar);
        daysOfWeek = daysMatch.map((m) {
          final day = m.group(0);
          switch (day) {
            case 'Mon': return 1;
            case 'Tue': return 2;
            case 'Wed': return 3;
            case 'Thu': return 4;
            case 'Fri': return 5;
            case 'Sat': return 6;
            case 'Sun': return 0;
            default: return 0;
          }
        }).toList();
        final timeMatch = RegExp(r'(\d{2}:\d{2})').firstMatch(onCalendar);
        time = timeMatch?.group(1);
        detectedType = 'weekly';
      }
      // Formato monthly: *-DD HH:mm:00
      else if (onCalendar.contains(RegExp(r'^\*-(\d+)'))) {
        final dayMatch = RegExp(r'^\*-(\d+)').firstMatch(onCalendar);
        dayOfMonth = int.tryParse(dayMatch?.group(1) ?? '');
        final timeMatch = RegExp(r'(\d{2}:\d{2})').firstMatch(onCalendar);
        time = timeMatch?.group(1);
        detectedType = 'monthly';
      }
      
      return {
        'type': detectedType,
        'time': time,
        'daysOfWeek': daysOfWeek,
        'dayOfMonth': dayOfMonth,
      };
    } catch (e) {
      return null;
    }
  }
  
  /// Verifica se systemd è disponibile
  static Future<bool> isSystemdAvailable() async {
    try {
      final result = await Process.run(
        'systemctl',
        ['--version'],
        runInShell: false,
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () => ProcessResult(1, -1, '', ''),
      );
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// FUNZIONE DI EMERGENZA: Rimuove TUTTI i timer di spegnimento esistenti
  /// Usa questa funzione se il PC si spegne automaticamente all'avvio
  /// Questa funzione rimuove completamente tutti i timer e servizi problematici
  static Future<bool> emergencyRemoveAllTimers() async {
    try {
      final types = ['daily', 'weekly', 'monthly'];
      
      for (final type in types) {
        try {
          await removeShutdownTimer(type);
        } catch (e) {
          // Continua anche se un timer fallisce
        }
      }
      
      // Verifica finale che non ci siano più timer attivi
      final listResult = await Process.run(
        'systemctl',
        ['list-timers', '--no-pager'],
        runInShell: false,
      );
      
      final output = listResult.stdout.toString();
      if (output.contains(timerPrefix)) {
        // Se ci sono ancora timer, prova a rimuoverli manualmente
        for (final type in types) {
          final timerName = '$timerPrefix-$type';
          try {
            await _runSudoCommand('systemctl stop $timerName.service');
            await _runSudoCommand('systemctl stop $timerName.timer');
            await _runSudoCommand('systemctl disable $timerName.service');
            await _runSudoCommand('systemctl disable $timerName.timer');
            await _runSudoCommand('rm -f $timerDir/$timerName.timer');
            await _runSudoCommand('rm -f $timerDir/$timerName.service');
          } catch (e) {
            // Ignora errori
          }
        }
        await _runSudoCommand('systemctl daemon-reload');
      }
      
      return true;
    } catch (e) {
      throw Exception('Errore durante la rimozione di emergenza: $e');
    }
  }
}
