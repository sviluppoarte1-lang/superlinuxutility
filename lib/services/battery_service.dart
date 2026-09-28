import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'password_storage.dart';

/// Istantanea salute batteria letta da /sys/class/power_supply/.
class BatteryHealth {
  final bool present;
  final String name;
  final int percent;
  final String status;
  final bool acOnline;
  final double? energyNowWh;
  final double? energyFullWh;
  final double? energyDesignWh;
  final double? healthPercent;
  final int? cycleCount;
  final double? voltageV;
  final double? powerW;
  final String? technology;
  final String? manufacturer;
  final String? model;
  final int? chargeEndThreshold;
  final int? chargeStartThreshold;
  final String? thresholdNode;

  const BatteryHealth({
    required this.present,
    this.name = '',
    this.percent = 0,
    this.status = 'Unknown',
    this.acOnline = false,
    this.energyNowWh,
    this.energyFullWh,
    this.energyDesignWh,
    this.healthPercent,
    this.cycleCount,
    this.voltageV,
    this.powerW,
    this.technology,
    this.manufacturer,
    this.model,
    this.chargeEndThreshold,
    this.chargeStartThreshold,
    this.thresholdNode,
  });

  static const absent = BatteryHealth(present: false);
}

/// Gestione alimentazione e batteria per notebook:
/// salute (cicli, Wh attuali/nominali, degrado), soglie di carica
/// (ASUS/ThinkPad/Lenovo/Dell via /sys/class/power_supply/) e
/// switch automatico del governor CPU in base all'alimentazione.
class BatteryService {
  static const String prefKeyGovernorAuto = 'battery_governor_auto';
  static const String prefKeyGovernorAc = 'battery_governor_ac';
  static const String prefKeyGovernorBattery = 'battery_governor_battery';

  static const String defaultAcGovernor = 'performance';
  static const String defaultBatteryGovernor = 'powersave';

  /// Soglie valide per il limite di carica (alcuni vendor accettano meno,
  /// 20-100 è sicuro ovunque).
  static const int minThreshold = 20;
  static const int maxThreshold = 100;

  static Timer? _acTimer;
  static bool? _lastAcOnline;
  static bool _monitorRunning = false;

  // ── Letture sysfs ──────────────────────────────────────────────

  static String _readFile(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return '';
      return f.readAsStringSync().trim();
    } catch (_) {
      return '';
    }
  }

  static int? parseSysInt(String raw) {
    final v = int.tryParse(raw.trim());
    return v;
  }

  /// Wh da valori sysfs in µWh.
  static double? uwhToWh(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null || v <= 0) return null;
    return v / 1000000.0;
  }

  /// Percentuale salute: energia piena / nominale di fabbrica.
  static double? computeHealthPercent(double? full, double? design) {
    if (full == null || design == null || design <= 0) return null;
    return (full / design * 100).clamp(0.0, 100.0);
  }

  static int clampThreshold(int v) => v.clamp(minThreshold, maxThreshold);

  static List<String> _batteryNames() {
    final names = <String>[];
    try {
      final dir = Directory('/sys/class/power_supply');
      if (!dir.existsSync()) return names;
      for (final e in dir.listSync()) {
        final name = e.path.split('/').last;
        if (!name.startsWith('BAT')) continue;
        if (_readFile('${e.path}/type') != 'Battery') continue;
        names.add(name);
      }
    } catch (_) {}
    names.sort();
    return names;
  }

  static bool _readAcOnline() {
    try {
      final dir = Directory('/sys/class/power_supply');
      if (!dir.existsSync()) return false;
      for (final e in dir.listSync()) {
        if (_readFile('${e.path}/type') != 'Mains') continue;
        if (_readFile('${e.path}/online') == '1') return true;
      }
    } catch (_) {}
    return false;
  }

  /// Salute batteria (prima BAT trovata). Ritorna [BatteryHealth.absent]
  /// sui desktop senza batteria.
  static Future<BatteryHealth> getBatteryHealth() async {
    final names = _batteryNames();
    if (names.isEmpty) return BatteryHealth.absent;
    final name = names.first;
    final base = '/sys/class/power_supply/$name';
    final status = _readFile('$base/status');
    final percent = parseSysInt(_readFile('$base/capacity')) ?? 0;
    var acOnline = _readAcOnline();
    // Deriva alimentazione dallo stato se non c'è il nodo Mains.
    if (!acOnline &&
        (status == 'Charging' || status == 'Full')) {
      acOnline = true;
    }
    final full = uwhToWh(_readFile('$base/energy_full'));
    final design = uwhToWh(_readFile('$base/energy_full_design'));
    final endNode = await findEndThresholdNode();
    return BatteryHealth(
      present: true,
      name: name,
      percent: percent.clamp(0, 100),
      status: status.isEmpty ? 'Unknown' : status,
      acOnline: acOnline,
      energyNowWh: uwhToWh(_readFile('$base/energy_now')),
      energyFullWh: full,
      energyDesignWh: design,
      healthPercent: computeHealthPercent(full, design),
      cycleCount: parseSysInt(_readFile('$base/cycle_count')),
      voltageV: _uvoltsToV(_readFile('$base/voltage_now')),
      powerW: uwhToWh(_readFile('$base/power_now')),
      technology: _nonEmpty(_readFile('$base/technology')),
      manufacturer: _nonEmpty(_readFile('$base/manufacturer')),
      model: _nonEmpty(_readFile('$base/model_name')),
      chargeEndThreshold:
          endNode == null ? null : parseSysInt(_readFile(endNode)),
      chargeStartThreshold: await _readStartThreshold(),
      thresholdNode: endNode,
    );
  }

  static double? _uvoltsToV(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null || v <= 0) return null;
    return v / 1000000.0;
  }

  static String? _nonEmpty(String s) => s.isEmpty ? null : s;

  // ── Soglie di carica ───────────────────────────────────────────

  static const _endCandidates = [
    'charge_control_end_threshold',
    'charge_stop_threshold',
  ];
  static const _startCandidates = [
    'charge_control_start_threshold',
    'charge_start_threshold',
  ];

  static Future<String?> _findNode(List<String> candidates) async {
    for (final bat in _batteryNames()) {
      for (final c in candidates) {
        final p = '/sys/class/power_supply/$bat/$c';
        try {
          if (File(p).existsSync()) return p;
        } catch (_) {}
      }
    }
    return null;
  }

  static Future<String?> findEndThresholdNode() =>
      _findNode(_endCandidates);

  static Future<int?> _readStartThreshold() async {
    final node = await _findNode(_startCandidates);
    if (node == null) return null;
    return parseSysInt(_readFile(node));
  }

  static Future<bool> get thresholdsSupported async =>
      await findEndThresholdNode() != null;

  static Future<ProcessResult> _runSudo(String command) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) {
      throw Exception(
          'Password non salvata. Salva la password nelle impostazioni.');
    }
    final escaped = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll("'", "\\'");
    final full =
        'printf "%s\\n" "$escaped" | sudo -S bash -c ${_shellQuote(command)} 2>&1';
    return Process.run('bash', ['-c', full], runInShell: true);
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }

  /// Imposta il limite massimo di carica (es. 80). Richiede sudo.
  static Future<void> setChargeEndThreshold(int percent) async {
    final node = await findEndThresholdNode();
    if (node == null) {
      throw Exception('Soglie di carica non supportate su questo hardware.');
    }
    final v = clampThreshold(percent);
    final r = await _runSudo('echo $v > $node');
    if (r.exitCode != 0) {
      throw Exception('Impostazione soglia fallita: ${(r.stdout ?? '').toString().trim()}');
    }
  }

  /// Imposta la soglia di inizio carica (solo ThinkPad e simili).
  static Future<void> setChargeStartThreshold(int percent) async {
    final node = await _findNode(_startCandidates);
    if (node == null) {
      throw Exception('Soglia di inizio non supportata su questo hardware.');
    }
    final v = clampThreshold(percent);
    final r = await _runSudo('echo $v > $node');
    if (r.exitCode != 0) {
      throw Exception('Impostazione soglia fallita: ${(r.stdout ?? '').toString().trim()}');
    }
  }

  // ── Governor ───────────────────────────────────────────────────

  static Future<List<String>> getAvailableGovernors() async {
    final raw = _readFile(
        '/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors');
    if (raw.isEmpty) return const ['performance', 'powersave'];
    return raw.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  static Future<String> getCurrentGovernor() async {
    final raw = _readFile(
        '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor');
    return raw.isEmpty ? 'unknown' : raw;
  }

  /// Imposta il governor su tutte le CPU (richiede sudo).
  static Future<void> setGovernorAll(String governor) async {
    final r = await _runSudo(
        'for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo $governor > \$f; done');
    if (r.exitCode != 0) {
      throw Exception('Cambio governor fallito.');
    }
  }

  /// Governor da applicare per lo stato di alimentazione dato.
  static String resolveTargetGovernor({
    required bool acOnline,
    required String acGovernor,
    required String batteryGovernor,
  }) =>
      acOnline ? acGovernor : batteryGovernor;

  static Future<bool> getGovernorAutoEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKeyGovernorAuto) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setGovernorAutoEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyGovernorAuto, v);
    if (v) {
      startAcMonitor();
      // Applica subito il profilo corretto.
      await applyGovernorForCurrentPower();
    } else {
      stopAcMonitor();
    }
  }

  static Future<String> _prefOr(
      String key, String fallback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static Future<String> getAcGovernor() =>
      _prefOr(prefKeyGovernorAc, defaultAcGovernor);
  static Future<String> getBatteryGovernor() =>
      _prefOr(prefKeyGovernorBattery, defaultBatteryGovernor);

  static Future<void> setAcGovernor(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyGovernorAc, v);
  }

  static Future<void> setBatteryGovernor(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyGovernorBattery, v);
  }

  /// Applica il governor corretto per l'alimentazione attuale.
  static Future<void> applyGovernorForCurrentPower() async {
    final h = await getBatteryHealth();
    // Sui desktop senza batteria non c'è nulla da commutare.
    if (!h.present) return;
    final target = resolveTargetGovernor(
      acOnline: h.acOnline,
      acGovernor: await getAcGovernor(),
      batteryGovernor: await getBatteryGovernor(),
    );
    final current = await getCurrentGovernor();
    if (current != target) {
      await setGovernorAll(target);
    }
  }

  /// Monitor alimentazione: ogni 5s controlla presa/batteria e commuta il
  /// governor al cambio di stato. Attivo finché l'app è in esecuzione (tray).
  static void startAcMonitor() {
    if (_monitorRunning) return;
    _monitorRunning = true;
    _lastAcOnline = null;
    _acTimer?.cancel();
    _acTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        if (!await getGovernorAutoEnabled()) return;
        final h = await getBatteryHealth();
        if (!h.present) return;
        if (_lastAcOnline == null) {
          _lastAcOnline = h.acOnline;
          return;
        }
        if (h.acOnline != _lastAcOnline) {
          _lastAcOnline = h.acOnline;
          await applyGovernorForCurrentPower();
        }
      } catch (_) {}
    });
  }

  static void stopAcMonitor() {
    _acTimer?.cancel();
    _acTimer = null;
    _monitorRunning = false;
    _lastAcOnline = null;
  }
}
