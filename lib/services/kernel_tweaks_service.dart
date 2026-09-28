import 'dart:io';
import 'operation_history_service.dart';
import 'password_storage.dart';

class KernelTweakOption {
  final String id;
  final String value;
  const KernelTweakOption({required this.id, required this.value});
}

class KernelTweak {
  final String id;
  final String current;
  final String? persistent;
  final bool available;
  final List<KernelTweakOption> options;
  const KernelTweak({
    required this.id,
    required this.current,
    this.persistent,
    required this.available,
    required this.options,
  });
}

/// Tweaks del kernel applicati in modo permanente (versione ADVANCED).
/// Le impostazioni vengono applicate subito e riapplicate a ogni avvio tramite
/// un servizio systemd dedicato; l'azione resta registrata nella cronologia
/// operazioni per poter essere annullata.
class KernelTweaksService {
  static const String _serviceName = 'slu-kernel-tweaks.service';
  static const String _scriptPath = '/etc/slu-kernel-tweaks.sh';

  static Future<String> _runBash(String command) async {
    try {
      final result = await Process.run('bash', ['-c', command], runInShell: true);
      return ((result.stdout as String?) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static Future<ProcessResult> _runSudo(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception('Password non salvata. Salva la password nelle impostazioni.');
    }
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll("'", "\\'");
    final fullCommand =
        'printf "%s\\n" "$escapedPassword" | sudo -S bash -c ${shellQuote(command)} 2>&1';
    return Process.run('bash', ['-c', fullCommand], runInShell: true);
  }

  static String shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  static String _readSysfs(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return '';
      return f.readAsStringSync().trim();
    } catch (_) {
      return '';
    }
  }

  /// Stato attuale dei tweak disponibili.
  static Future<List<KernelTweak>> getKernelTweaks() async {
    final persistent = await _readPersistentValues();

    // THP
    String thpCurrent = 'madvise';
    final thpRaw = _readSysfs('/sys/kernel/mm/transparent_hugepage/enabled');
    if (thpRaw.isNotEmpty) {
      final m = RegExp(r'\[([^\]]+)\]').firstMatch(thpRaw);
      if (m != null) thpCurrent = m.group(1)!;
    }

    // Governor
    final govRaw = _readSysfs('/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor');
    final governorAvailable = govRaw.isNotEmpty;

    // Scheduler
    final schedRaw = await _runBash('cat /proc/sys/kernel/sched_child_runs_first 2>/dev/null');
    final schedCurrent = schedRaw.trim() == '1' ? '1' : '0';

    return [
      KernelTweak(
        id: 'thp',
        current: thpCurrent,
        persistent: persistent['thp'],
        available: thpRaw.isNotEmpty,
        options: const [
          KernelTweakOption(id: 'always', value: 'always'),
          KernelTweakOption(id: 'madvise', value: 'madvise'),
          KernelTweakOption(id: 'never', value: 'never'),
        ],
      ),
      KernelTweak(
        id: 'governor',
        current: governorAvailable ? govRaw : '',
        persistent: persistent['governor'],
        available: governorAvailable,
        options: const [
          KernelTweakOption(id: 'performance', value: 'performance'),
          KernelTweakOption(id: 'ondemand', value: 'ondemand'),
          KernelTweakOption(id: 'schedutil', value: 'schedutil'),
          KernelTweakOption(id: 'powersave', value: 'powersave'),
        ],
      ),
      KernelTweak(
        id: 'scheduler',
        current: schedCurrent,
        persistent: persistent['scheduler'],
        available: true,
        options: const [
          KernelTweakOption(id: 'child_runs_first_1', value: '1'),
          KernelTweakOption(id: 'child_runs_first_0', value: '0'),
        ],
      ),
    ];
  }

  /// Legge i valori già salvati nel servizio di persistenza, così da poter
  /// verificare quali parametri sono già configurati per il prossimo avvio.
  static Future<Map<String, String>> _readPersistentValues() async {
    final values = <String, String>{};
    try {
      final r = await _runSudo('cat $_scriptPath 2>/dev/null || true');
      final content = (r.stdout as String);
      for (final line in content.split('\n')) {
        final t = line.trim();
        final thpM = RegExp(
                r'echo\s+([a-z]+)\s+>\s+/sys/kernel/mm/transparent_hugepage/enabled')
            .firstMatch(t);
        if (thpM != null) {
          values['thp'] = thpM.group(1)!;
          continue;
        }
        final govM = RegExp(r'echo\s+([a-z]+)\s+>\s+"\$g"').firstMatch(t);
        if (govM != null) {
          values['governor'] = govM.group(1)!;
          continue;
        }
        final schedM = RegExp(r'sched_child_runs_first=(\d+)').firstMatch(t);
        if (schedM != null) {
          values['scheduler'] = schedM.group(1)!;
        }
      }
    } catch (_) {
      // Nessun servizio configurato → mappa vuota.
    }
    return values;
  }

  /// Verifica se il servizio di persistenza è già attivo.
  static Future<bool> isPersistentServiceActive() async {
    final r = await _runSudo('systemctl is-enabled $_serviceName 2>/dev/null || true');
    return (r.stdout as String).trim() == 'enabled';
  }

  /// Applica il tweak selezionato. [selectedValues] è una mappa tweakId → valore.
  static Future<Map<String, dynamic>> applyKernelTweaks(
      Map<String, String> selectedValues) async {
    if (selectedValues.isEmpty) {
      return {'success': false, 'message': 'No tweak selected'};
    }
    try {
      final thp = selectedValues['thp'];
      final governor = selectedValues['governor'];
      final sched = selectedValues['scheduler'];

      final script = StringBuffer('#!/bin/bash\n');
      script.writeln('# Super Linux Utility - persistent kernel tweaks');
      if (thp != null) {
        script.writeln('if [ -w /sys/kernel/mm/transparent_hugepage/enabled ]; then');
        script.writeln('  echo $thp > /sys/kernel/mm/transparent_hugepage/enabled');
        script.writeln('fi');
      }
      if (governor != null) {
        script.writeln('for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do');
        script.writeln('  [ -w "\$g" ] && echo $governor > "\$g";');
        script.writeln('done');
      }
      if (sched != null) {
        script.writeln('sysctl -w kernel.sched_child_runs_first=$sched >/dev/null 2>&1 || true');
      }

      final serviceFile = '''
[Unit]
Description=Super Linux Utility kernel tweaks
After=sysinit.target
[Service]
Type=oneshot
ExecStart=$_scriptPath
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
''';

      final applyCommand =
          'cat > $_scriptPath <<\'EOF\'\n$script\nEOF\n'
          'chmod 755 $_scriptPath\n'
          'cat > /etc/systemd/system/$_serviceName <<\'EOF\'\n$serviceFile\nEOF\n'
          'systemctl daemon-reload && systemctl enable --now $_serviceName && bash $_scriptPath';

      final undoCommand =
          'systemctl disable --now $_serviceName 2>/dev/null || true; '
          'rm -f /etc/systemd/system/$_serviceName /etc/init.d/$_serviceName; '
          'rm -f $_scriptPath; systemctl daemon-reload; '
          'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null; '
          'sysctl -w kernel.sched_child_runs_first=0 >/dev/null 2>&1; true';

      final result = await _runSudo(applyCommand);
      final ok = result.exitCode == 0;
      final output = (result.stdout as String).trim();

      await OperationHistoryService.logOperation(
        category: OperationHistoryService.categoryKernel,
        action: 'kernel_tweaks_apply',
        param: selectedValues.toString(),
        appliedCommand: applyCommand,
        undoCommand: undoCommand,
        success: ok,
      );

      return {
        'success': ok,
        'message': ok ? 'Kernel tweaks applied and saved for boot' : (output.isNotEmpty ? output : 'Operation failed'),
        'output': output,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Rimuove il servizio di persistenza e ripristina i valori predefiniti.
  static Future<Map<String, dynamic>> resetKernelTweaks() async {
    try {
      final undoCommand =
          'systemctl disable --now $_serviceName 2>/dev/null || true; '
          'rm -f /etc/systemd/system/$_serviceName; '
          'rm -f $_scriptPath; systemctl daemon-reload; '
          'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null; '
          'sysctl -w kernel.sched_child_runs_first=0 >/dev/null 2>&1; true';

      final result = await _runSudo(undoCommand);
      final ok = result.exitCode == 0;

      await OperationHistoryService.logOperation(
        category: OperationHistoryService.categoryKernel,
        action: 'kernel_tweaks_reset',
        appliedCommand: undoCommand,
        undoCommand: null,
        success: ok,
      );

      return {
        'success': ok,
        'message': ok ? 'Kernel tweaks reset to defaults' : 'Reset failed',
        'output': (result.stdout as String).trim(),
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
