import 'dart:io';

import '../models/startup_app.dart';
import '../utils/process_utils.dart';
import 'operation_history_service.dart';
import 'password_storage.dart';
import 'startup_apps_analyzer.dart';

/// Wizard di ottimizzazione: analizza i servizi di sistema (systemd) e le
/// app in avvio, usando scansioni BULK (pochi subprocess per tutto il
/// sistema, non uno per servizio) + un database curato di servizi opzionali
/// con probe specifici (bluetoothctl, lpstat, mmcli, snap list) + le
/// abitudini dell'utente lette da `~/.local/share/recently-used.xbel`.
///
/// I servizi "inamovibili" (systemd-*, dbus, polkit, display manager, ...)
/// vengono filtrati DOPO la scansione e NON compaiono mai nel risultato.
enum OptimizerRisk { safe, caution }

/// Evidenza come CODICE: l'UI la traduce con l10n (`optEv<Code>`).
/// Codici: bootCost, notRunning, neverActive, lastActive, noBluetooth,
/// noPrinters, noModems, noSnaps, thirdParty, unusedApp, missingBinary.
typedef OptEvidence = String;

class ServiceCandidate {
  final String unit;
  final String? description;
  final String enabledState;
  final String activeState;
  final Duration? inactiveSince; // da quando non è più attivo (null = mai attivo)
  final int restarts;
  final String? slowBoot;
  final String descKey;
  final OptimizerRisk risk;
  final List<OptEvidence> evidence;
  final bool preselected;

  const ServiceCandidate({
    required this.unit,
    this.description,
    required this.enabledState,
    required this.activeState,
    this.inactiveSince,
    this.restarts = 0,
    this.slowBoot,
    required this.descKey,
    required this.risk,
    required this.evidence,
    this.preselected = false,
  });

  ServiceCandidate copyWith({List<OptEvidence>? evidence}) => ServiceCandidate(
        unit: unit,
        description: description,
        enabledState: enabledState,
        activeState: activeState,
        inactiveSince: inactiveSince,
        restarts: restarts,
        slowBoot: slowBoot,
        descKey: descKey,
        risk: risk,
        evidence: evidence ?? this.evidence,
        preselected: preselected,
      );
}

class StartupCandidate {
  final StartupApp app;
  final List<OptEvidence> evidence;
  final OptimizerRisk risk;
  final bool preselected;
  final int uses30d;
  final DateTime? lastUsed;

  const StartupCandidate({
    required this.app,
    required this.evidence,
    required this.risk,
    this.preselected = false,
    this.uses30d = 0,
    this.lastUsed,
  });
}

class OptimizerScanResult {
  final bool hasSystemd;
  final List<ServiceCandidate> services;
  final List<StartupCandidate> startupApps;
  final int servicesScanned;
  final int unknownEnabled; // unit enabled non proposte (non riconosciute/protette)
  final bool usageAvailable; // recently-used.xbel leggibile

  const OptimizerScanResult({
    required this.hasSystemd,
    required this.services,
    required this.startupApps,
    required this.servicesScanned,
    this.unknownEnabled = 0,
    this.usageAvailable = false,
  });
}

class OptimizerApplyResult {
  final int servicesDisabled;
  final int appsDisabled;
  final List<String> errors;
  const OptimizerApplyResult({
    required this.servicesDisabled,
    required this.appsDisabled,
    required this.errors,
  });
}

/// Conteggi di utilizzo per chiave (nome app / basename exe).
class OptimizerUsage {
  final Map<String, int> count30d;
  final Map<String, DateTime?> lastUsed;
  const OptimizerUsage({
    required this.count30d,
    required this.lastUsed,
  });
}

class SystemOptimizerService {
  SystemOptimizerService._();

  static const Duration _cmdTimeout = Duration(seconds: 45);

  // ─── DB: servizi opzionali noti ───────────────────────────────────────

  static final List<(RegExp, String, OptimizerRisk, String?)> _optionalDb = [
    (RegExp(r'^bluetooth\.service$', caseSensitive: false), 'optSvcBluetooth',
        OptimizerRisk.safe, 'bluetooth'),
    (RegExp(r'^cups\.service$', caseSensitive: false), 'optSvcCups',
        OptimizerRisk.safe, 'cups'),
    (RegExp(r'^avahi(-daemon)?\.service$', caseSensitive: false), 'optSvcAvahi',
        OptimizerRisk.caution, null),
    (RegExp(r'^ModemManager\.service$', caseSensitive: false),
        'optSvcModemManager', OptimizerRisk.safe, 'modem'),
    (RegExp(r'^snapd(\.service|\.apparmor\.service)$', caseSensitive: false),
        'optSvcSnapd', OptimizerRisk.safe, 'snap'),
    (RegExp(r'^packagekit(\.service|d\.service)$', caseSensitive: false),
        'optSvcPackageKit', OptimizerRisk.caution, null),
    (RegExp(r'^(fwupd|fwupd-refresh)\.service$', caseSensitive: false),
        'optSvcFwupd', OptimizerRisk.caution, null),
    (RegExp(r'^(geoclue|geoclue-.*|geoclue-demo-agent)\.service$',
        caseSensitive: false),
        'optSvcGeoclue', OptimizerRisk.caution, null),
    (RegExp(r'^(update-notifier|update-notifier-download|ubuntu-advantage)\.service$',
        caseSensitive: false),
        'optSvcUpdateNotifier', OptimizerRisk.caution, null),
    (RegExp(r'^anacron\.service$', caseSensitive: false), 'optSvcAnacron',
        OptimizerRisk.caution, null),
    (RegExp(r'^(openvpn|openvpn-.*|vpn-\w+)\.service$', caseSensitive: false),
        'optSvcOpenVpn', OptimizerRisk.caution, null),
    (RegExp(r'^teamviewer(\.service)?$', caseSensitive: false),
        'optSvcTeamViewer', OptimizerRisk.caution, null),
    (RegExp(r'^anydesk(\.service)?$', caseSensitive: false), 'optSvcAnydesk',
        OptimizerRisk.caution, null),
    (RegExp(r'^rustdesk(\.service)?$', caseSensitive: false), 'optSvcRustdesk',
        OptimizerRisk.caution, null),
    (RegExp(r'^(tailscaled|tailscale)\.service$', caseSensitive: false),
        'optSvcTailscale', OptimizerRisk.caution, null),
    (RegExp(r'^(docker|docker\.socket|containerd)\.service$', caseSensitive: false),
        'optSvcDocker', OptimizerRisk.caution, null),
    (RegExp(r'^(libvirtd|libvirt.*|virtqemud|virtnetworkd)\.service$',
        caseSensitive: false),
        'optSvcLibvirt', OptimizerRisk.caution, null),
    (RegExp(r'^(mysql|mariadb|mysqld)\.service$', caseSensitive: false),
        'optSvcMysql', OptimizerRisk.caution, null),
    (RegExp(r'^(postgres|postgresql)\.service$', caseSensitive: false),
        'optSvcPostgres', OptimizerRisk.caution, null),
  ];

  /// Pattern delle unit "terze parti": proposte anche quando attive.
  static final RegExp _thirdPartyPattern = RegExp(
      r'teamviewer|anydesk|rustdesk|tailscale|docker|containerd|libvirt|mysql|mariadb|postgres|openvpn|zerotier',
      caseSensitive: false);

  /// Le unit con queste sottostringhe NON vengono mai proposte (ramo
  /// "sconosciute"): sicurezza, sessioni, cron, hardware critico.
  static final List<String> _neverPropose = [
    'ssh', 'sshd', 'cron', 'atd', 'irqbalance', 'thermald', 'acpid',
    'apparmor', 'selinux', 'firewalld', 'ufw', 'auditd', 'nftables',
    'speech', 'colord', 'modem', 'ofono', 'netfilter', 'iptables',
    'lvm', 'mdmonitor', 'smartd', 'fstrim', 'logrotate', 'logwatch',
    'man-db', 'dpkg', 'apt', 'dnf', 'packagekit-offline', 'motd',
    'kerneloops', 'apport', 'whoopsie', 'snapd-',
  ];

  // ─── Denylist dura: servizi inamovibili (mai proposti) ────────────────

  static const List<String> _protectedPrefixes = [
    'systemd', 'dbus', 'polkit', 'udisks', 'upower', 'accounts', 'rtkit',
    'gvfs', 'networkmanager', 'wpa_supplicant', 'iwd', 'gdm', 'sddm',
    'lightdm', 'greetd', 'lydm', 'lxdm', 'slim', 'nodm', 'pipewire',
    'wireplumber', 'pulseaudio', 'alsa', 'getty', 'user@', 'init',
    'finalrd', 'umount', 'swap', 'cryptsetup', 'fsck', 'verity',
    'integrity', 'firewalld', 'apparmor', 'selinux', 'auditd', 'ufw',
    'cron', 'atd', 'irqbalance', 'thermald', 'acpid', 'kmod', 'random',
    'oomd', 'hostnamed', 'timedated', 'locale', 'machined', 'resolved',
    'logind', 'journald', 'udevd', 'networkd', 'timesyncd', 'console',
    'getty', 'rescue', 'emergency', 'user-runtime', 'session-c',
    'ModemManager', 'bluetooth', 'cups', 'avahi', 'snapd', 'packagekit',
    'fwupd', 'geoclue', 'update-notifier', 'anacron',
  ];

  /// Le ultime voci sono servizi GESTITI dal DB opzionale: vengono
  /// escluse dalla denylist perché devono poter essere proposti.
  static final Set<String> _dbManaged = {
    'bluetooth', 'cups', 'avahi', 'modemmanager', 'snapd', 'packagekit',
    'fwupd', 'geoclue', 'update-notifier', 'anacron', 'openvpn',
    'teamviewer', 'anydesk', 'rustdesk', 'tailscale', 'docker', 'libvirt',
    'mysql', 'mariadb', 'postgres',
  };

  /// Filtro UNICO dei servizi inamovibili. Le unit gestite dal DB
  /// opzionale escono dalla denylist e vengono valutate normalmente.
  static bool isProtectedUnit(String unit) {
    final n = unit.toLowerCase();
    // Le unit gestite dal DB opzionale non sono "inamovibili".
    for (final m in _dbManaged) {
      if (n.startsWith(m) || n.contains('.$m')) return false;
    }
    for (final p in _protectedPrefixes) {
      if (n.startsWith(p.toLowerCase())) return true;
    }
    // Template e istanze speciali mai toccate.
    if (unit.contains('@')) return true;
    return false;
  }

  // ─── Parser pubblici (testabili) ──────────────────────────────────────

  /// `systemctl list-unit-files --type=service --no-legend`:
  /// "cups.service                    enabled" / "bluetooth.service   disabled"
  static Map<String, String> parseUnitFiles(String output) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      final m = RegExp(r'^(\S+\.service)\s+(\S+)').firstMatch(line.trim());
      if (m != null) map[m.group(1)!] = m.group(2)!;
    }
    return map;
  }

  /// `systemctl list-units --type=service --all --no-legend`:
  /// "  cups.service    loaded active   running  CUPS Scheduler"
  /// Il marker ● (unit failed) è tollerato.
  static Map<String, String> parseListUnits(String output) {
    final map = <String, String>{};
    for (final line in output.split('\n')) {
      final m = RegExp(r'^\s*●?\s*(\S+\.service)\s+(\S+)\s+(\S+)')
          .firstMatch(line);
      if (m != null) map[m.group(1)!] = m.group(3)!; // ActiveState
    }
    return map;
  }

  /// `systemd-analyze blame --no-pager` → unit → "12.5s".
  /// Il formato reale ha anche segmenti multipli: "15min 23.914s unit".
  static Map<String, String> parseBlame(String output) {
    final map = <String, String>{};
    final lineRe =
        RegExp(r'^\s*((?:[\d.]+(?:ms|s|min|h)\s+)+)(\S+\.service)\s*$');
    final timeTok = RegExp(r'([\d.]+)(ms|s|min|h)');
    for (final line in output.split('\n')) {
      final m = lineRe.firstMatch(line);
      if (m == null) continue;
      var secs = 0.0;
      for (final t in timeTok.allMatches(m.group(1)!)) {
        final v = double.tryParse(t.group(1)!) ?? 0;
        secs += switch (t.group(2)!) {
          'ms' => v / 1000,
          'min' => v * 60,
          'h' => v * 3600,
          _ => v,
        };
      }
      if (secs >= 2) map[m.group(2)!] = _fmtDur(secs);
    }
    return map;
  }

  static String _fmtDur(double secs) => secs >= 60
      ? '${(secs / 60).toStringAsFixed(1)}m'
      : '${secs.toStringAsFixed(1)}s';

  /// `systemctl show` su unit multiple con -p Id, Description, ActiveState,
  /// ActiveEnterTimestamp, InactiveExitTimestamp, NRestarts →
  /// unit → {prop: value}.
  static Map<String, Map<String, String>> parseShow(String output) {
    final map = <String, Map<String, String>>{};
    Map<String, String>? current;
    for (final line in output.split('\n')) {
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final key = line.substring(0, eq);
      final value = line.substring(eq + 1);
      if (key == 'Id') {
        current = map.putIfAbsent(value, () => {});
      } else {
        current ??= <String, String>{};
        current[key] = value;
      }
    }
    return map;
  }

  static final RegExp _tsRe =
      RegExp(r'(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})');

  static DateTime? parseTimestamp(String raw) {
    if (raw.trim().isEmpty) return null;
    final m = _tsRe.firstMatch(raw);
    if (m == null) return null;
    return DateTime(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
  }

  /// `~/.local/share/recently-used.xbel` → usage per nome app/basename.
  static OptimizerUsage parseXbel(String xml, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final cutoff = ref.subtract(const Duration(days: 30));
    final counts = <String, int>{};
    final last = <String, DateTime?>{};

    final bookmarkRe = RegExp(
        r'<bookmark\s[^>]*href="([^"]*)"[^>]*>([\s\S]*?)</bookmark>');
    for (final bm in bookmarkRe.allMatches(xml)) {
      final href = bm.group(1) ?? '';
      final body = bm.group(2) ?? '';
      final hrefKey = _basename(href).toLowerCase();

      DateTime? bmDate;
      final modInTag = RegExp(r'modified="([^"]*)"')
          .firstMatch(bm.group(0) ?? '');
      if (modInTag != null) bmDate = DateTime.tryParse(modInTag.group(1)!);

      final appRe = RegExp(r'<bookmark:application\b([^>]*)/?>');
      var hasApp = false;
      for (final app in appRe.allMatches(body)) {
        hasApp = true;
        final attrs = app.group(1) ?? '';
        final name = RegExp(r'\bname="([^"]*)"').firstMatch(attrs);
        final exec = RegExp(r'\bexec="([^"]*)"').firstMatch(attrs);
        final mod = RegExp(r'\bmodified="([^"]*)"').firstMatch(attrs);
        final date = mod != null
            ? DateTime.tryParse(mod.group(1)!)
            : bmDate;
        final keys = <String>{};
        if (name != null) keys.add(name.group(1)!.toLowerCase());
        if (exec != null) keys.add(_basename(exec.group(1)!).toLowerCase());
        if (hrefKey.isNotEmpty) keys.add(hrefKey);
        for (final k in keys) {
          if (k.isEmpty) continue;
          if (date != null) {
            last[k] = (last[k] == null || date.isAfter(last[k]!))
                ? date
                : last[k];
            if (!date.isBefore(cutoff)) {
              counts[k] = (counts[k] ?? 0) + 1;
            }
          }
        }
      }
      if (!hasApp && hrefKey.isNotEmpty && bmDate != null) {
        last[hrefKey] =
            (last[hrefKey] == null || bmDate.isAfter(last[hrefKey]!))
                ? bmDate
                : last[hrefKey];
        if (!bmDate.isBefore(cutoff)) {
          counts[hrefKey] = (counts[hrefKey] ?? 0) + 1;
        }
      }
    }
    return OptimizerUsage(count30d: counts, lastUsed: last);
  }

  static String _basename(String p) {
    var s = p.trim().replaceAll('"', '');
    // Primo token del comando (per gli exec con argomenti).
    final sp = s.indexOf(' ');
    if (sp > 0) s = s.substring(0, sp);
    final i = s.lastIndexOf('/');
    return i >= 0 ? s.substring(i + 1) : s;
  }

  /// Usage aggregato per un'app: somma i conteggi di tutte le chiavi
  /// correlate (nome display, basename comando) e prende l'ultimo uso.
  static (int, DateTime?) usageFor(
      OptimizerUsage u, String name, String command) {
    final keys = <String>{
      name.toLowerCase(),
      _basename(command).toLowerCase(),
    };
    var count = 0;
    DateTime? last;
    for (final k in keys) {
      if (k.isEmpty) continue;
      count += u.count30d[k] ?? 0;
      final d = u.lastUsed[k];
      if (d != null && (last == null || d.isAfter(last))) last = d;
    }
    return (count, last);
  }

  // ─── Scansione ────────────────────────────────────────────────────────

  static Future<OptimizerScanResult> scan(
      {void Function(String phase)? onPhase}) async {
    void phase(String p) => onPhase?.call(p);

    final hasSystemd = Directory('/run/systemd/system').existsSync();
    if (!hasSystemd) {
      return const OptimizerScanResult(
        hasSystemd: false,
        services: [],
        startupApps: [],
        servicesScanned: 0,
      );
    }

    phase('units');
    final unitFiles = parseUnitFiles(await _out(
        'systemctl',
        ['list-unit-files', '--type=service', '--no-legend', '--no-pager']));
    final liveStates = parseListUnits(await _out(
        'systemctl',
        ['list-units', '--type=service', '--all', '--no-legend', '--no-pager']));

    // Preliminari: unit enabled, non protette, non template.
    final prelim = <String, String>{}; // unit → stato enable
    for (final e in unitFiles.entries) {
      final unit = e.key;
      final st = e.value;
      if (!st.startsWith('enabled')) continue;
      if (isProtectedUnit(unit)) continue;
      prelim[unit] = st;
    }

    phase('show');
    final showUnits = prelim.keys.toList();
    final props = <String, Map<String, String>>{};
    for (var i = 0; i < showUnits.length; i += 40) {
      final chunk = showUnits.sublist(
          i, i + 40 > showUnits.length ? showUnits.length : i + 40);
      final out = await _out('systemctl', [
        'show',
        ...chunk,
        '-p', 'Id', '-p', 'Description', '-p', 'ActiveState',
        '-p', 'ActiveEnterTimestamp', '-p', 'InactiveExitTimestamp',
        '-p', 'NRestarts',
      ]);
      props.addAll(parseShow(out));
    }

    phase('blame');
    final blame = parseBlame(await _out('systemd-analyze', ['blame', '--no-pager']));

    final now = DateTime.now();
    final candidates = <ServiceCandidate>[];
    var unknownEnabled = 0;

    for (final unit in prelim.keys) {
      final p = props[unit] ?? {};
      final active = p['ActiveState'] ?? liveStates[unit] ?? 'unknown';
      final activeTs = parseTimestamp(p['ActiveEnterTimestamp'] ?? '');
      final inactiveTs = parseTimestamp(p['InactiveExitTimestamp'] ?? '');
      final restarts = int.tryParse(p['NRestarts'] ?? '') ?? 0;
      final desc = (p['Description'] ?? '').trim();
      final sinceInactive = inactiveTs != null ? now.difference(inactiveTs) : null;
      final wasNeverActive = activeTs == null && active != 'active';

      // Trova spec DB.
      (String, OptimizerRisk, String?)? spec;
      for (final s in _optionalDb) {
        if (s.$1.hasMatch(unit)) {
          spec = (s.$2, s.$3, s.$4);
          break;
        }
      }

      final isThird = _thirdPartyPattern.hasMatch(unit);

      if (spec != null) {
        // Unit noto: proposto se inattivo e non più in uso, o terza parte.
        final inactiveEnough = active != 'active' &&
            (wasNeverActive ||
                (sinceInactive != null &&
                    sinceInactive.inDays >= 7));
        if (!inactiveEnough && !isThird) continue;

        var risk = spec.$2;
        var evidence = <OptEvidence>[];
        var preselect = false;

        final probe = spec.$3;
        if (probe != null) {
          final pr = await _probe(probe);
          if (pr == true) continue; // utile: non proposto
          if (pr == false) {
            evidence.add(switch (probe) {
              'bluetooth' => 'noBluetooth',
              'cups' => 'noPrinters',
              'modem' => 'noModems',
              _ => 'noSnaps',
            });
            risk = OptimizerRisk.safe;
            preselect = true;
          } else {
            evidence.add('notRunning');
            risk = OptimizerRisk.caution;
          }
        } else {
          evidence.add(wasNeverActive ? 'neverActive' : 'notRunning');
          if (isThird) evidence.add('thirdParty');
          if (isThird && risk == OptimizerRisk.safe) {
            risk = OptimizerRisk.caution;
          }
          preselect = risk == OptimizerRisk.safe && wasNeverActive;
        }
        if (isThird && !evidence.contains('thirdParty')) {
          evidence.add('thirdParty');
        }
        if (blame.containsKey(unit)) evidence.add('bootCost');

        candidates.add(ServiceCandidate(
          unit: unit,
          description: desc.isEmpty ? null : desc,
          enabledState: prelim[unit]!,
          activeState: active,
          inactiveSince: sinceInactive,
          restarts: restarts,
          slowBoot: blame[unit],
          descKey: spec.$1,
          risk: risk,
          evidence: evidence,
          preselected: preselect,
        ));
        continue;
      }

      // Sconosciuto: proposto SOLO con evidenza forte (mai attivo da boot).
      unknownEnabled++;
      if (isThird) {
        candidates.add(ServiceCandidate(
          unit: unit,
          description: desc.isEmpty ? null : desc,
          enabledState: prelim[unit]!,
          activeState: active,
          inactiveSince: sinceInactive,
          restarts: restarts,
          slowBoot: blame[unit],
          descKey: 'optSvcGeneric',
          risk: OptimizerRisk.caution,
          evidence: const ['thirdParty', 'neverActive'],
          preselected: false,
        ));
        continue;
      }
      if (!wasNeverActive || active == 'active') continue;
      if (_neverPropose.any((k) => unit.toLowerCase().contains(k))) continue;
      candidates.add(ServiceCandidate(
        unit: unit,
        description: desc.isEmpty ? null : desc,
        enabledState: prelim[unit]!,
        activeState: active,
        inactiveSince: null,
        restarts: restarts,
        slowBoot: blame[unit],
        descKey: 'optSvcGeneric',
        risk: OptimizerRisk.caution,
        evidence: const ['neverActive'],
        preselected: false,
      ));
    }

    phase('deps');
    final withDeps = <ServiceCandidate>[];
    for (final c in candidates) {
      final dependents = await _reverseDependents(c.unit);
      final blockers = dependents
          .where((d) => !candidates.any((x) => x.unit == d))
          .toList();
      if (blockers.isEmpty) {
        withDeps.add(c);
      }
      // Altrimenti: protetto da dipendenze → non proposto.
    }

    phase('startup');
    final startup = await _scanStartupApps();

    return OptimizerScanResult(
      hasSystemd: true,
      services: withDeps,
      startupApps: startup.candidates,
      servicesScanned: unitFiles.length,
      unknownEnabled: unknownEnabled,
      usageAvailable: startup.usageAvailable,
    );
  }

  // ─── Probe (positivo = servizio utile, non proposto) ──────────────────

  /// Ritorna true (utile), false (non utilizzato) o null (sconosciuto).
  static Future<bool?> _probe(String kind) async {
    switch (kind) {
      case 'bluetooth':
        final r = await _outResult(
            'bluetoothctl', ['devices', 'Paired'],
            timeout: const Duration(seconds: 8));
        if (r == null || r.exitCode == 124) return null;
        final out = r.stdout.trim();
        if (out.isEmpty || out.contains('No default controller') ||
            out.contains('No default controller available')) {
          return false;
        }
        return true;
      case 'cups':
        final r = await _outResult('lpstat', ['-p'],
            timeout: const Duration(seconds: 6));
        if (r == null || r.exitCode == 124) return null;
        final out = (r.stdout as String).trim();
        final err = (r.stderr as String).trim();
        if (r.exitCode == 127 || err.contains('not found')) return false;
        if (out.isEmpty ||
            out.contains('no destinations') ||
            out.contains('no default destination')) {
          return false;
        }
        return true;
      case 'modem':
        final r = await _outResult('mmcli', ['-L'],
            timeout: const Duration(seconds: 8));
        if (r == null || r.exitCode == 124) return null;
        final out = r.stdout.trim();
        if (r.exitCode == 127 || out.contains('command not found')) {
          return false;
        }
        if (out.isEmpty || out.contains('No modems were found')) return false;
        return true;
      case 'snap':
        final r = await _outResult('snap', ['list'],
            timeout: const Duration(seconds: 12));
        if (r == null || r.exitCode == 124) return null;
        if (r.exitCode != 0) return false;
        final lines = (r.stdout as String)
            .split('\n')
            .where((l) => l.trim().isNotEmpty)
            .toList();
        // Header + eventuali runtime base (core/snapd/base): nessuna app.
        final apps = lines.skip(1).where((l) {
          final name = l.split(RegExp(r'\s+')).first.toLowerCase();
          return !name.startsWith('core') &&
              name != 'snapd' &&
              !name.startsWith('base') &&
              name != 'gtk-common-themes' &&
              !RegExp(r'^\d').hasMatch(name);
        });
        return apps.isNotEmpty;
      default:
        return null;
    }
  }

  // ─── Dipendenze reverse ───────────────────────────────────────────────

  static Future<List<String>> _reverseDependents(String unit) async {
    final out = await _out('systemctl', [
      'list-dependencies',
      '--reverse',
      unit,
      '--no-pager',
      '--no-legend',
    ], allowFailure: true);
    final list = <String>[];
    for (final line in out.split('\n')) {
      final t = line.trim().replaceAll('●', '').trim();
      if (t.isEmpty) continue;
      final name = t.split(RegExp(r'\s+')).first;
      if (name == unit || name.endsWith('.target')) continue;
      if (name.endsWith('.service') || name.contains('@')) list.add(name);
    }
    return list;
  }

  // ─── App in avvio ─────────────────────────────────────────────────────

  static Future<({List<StartupCandidate> candidates, bool usageAvailable})>
      _scanStartupApps() async {
    final apps = await StartupAppsAnalyzer.analyzeStartupApps();
    OptimizerUsage usage = const OptimizerUsage(count30d: {}, lastUsed: {});
    var usageAvailable = false;
    try {
      final f = File(
          '${Platform.environment['HOME'] ?? ''}/.local/share/recently-used.xbel');
      if (await f.exists()) {
        usage = parseXbel(await f.readAsString());
        usageAvailable = true;
      }
    } catch (_) {
      usageAvailable = false;
    }

    final out = <StartupCandidate>[];
    final now = DateTime.now();
    final cutoff7 = now.subtract(const Duration(days: 7));
    final cutoff30 = now.subtract(const Duration(days: 30));

    for (final app in apps) {
      if (!app.isEnabled) continue;
      if (app.isProtected) continue;
      if (app.desktopFile == null || app.desktopFile!.isEmpty) continue;

      final (uses, lastUsed) = usageAvailable
          ? usageFor(usage, app.name, app.command)
          : (0, null);

      final evidence = <OptEvidence>[];
      var risk = OptimizerRisk.safe;
      var preselect = false;

      // Evidenza forte: il binario non esiste più.
      final exe = extractExecutable(app.command);
      final missing =
          exe != null && exe.isNotEmpty && !File(exe).existsSync();
      if (missing) {
        evidence.add('missingBinary');
        preselect = true;
      } else if (usageAvailable) {
        if (uses == 0 &&
            (lastUsed == null || lastUsed.isBefore(cutoff30))) {
          evidence.add('unusedApp');
          risk = OptimizerRisk.safe;
          preselect = true;
        } else if (uses == 0 ||
            (lastUsed != null && lastUsed.isBefore(cutoff7))) {
          evidence.add('unusedApp');
          risk = OptimizerRisk.caution;
          preselect = false;
        } else {
          continue; // usata di recente: non toccare
        }
      } else {
        continue; // niente info abitudini: non proponiamo app normali
      }

      out.add(StartupCandidate(
        app: app,
        evidence: evidence,
        risk: risk,
        preselected: preselect,
        uses30d: uses,
        lastUsed: lastUsed,
      ));
    }
    return (candidates: out, usageAvailable: usageAvailable);
  }

  /// Primo token del comando → percorso dell'eseguibile (con ~ espanso).
  /// Estrae l'eseguibile dal comando di una app di avvio (con espanso di ~,
  /// senza prefissi env): utile per verificare se il binario esiste ancora.
  static String? extractExecutable(String command) {
    var s = command.trim();
    if (s.isEmpty) return null;
    // Rimuovi env prefix tipo "env VAR=x cmd".
    while (s.startsWith('env ') || RegExp(r'^\w+=').hasMatch(s)) {
      final sp = s.indexOf(' ');
      if (sp < 0) return null;
      s = s.substring(sp + 1).trim();
    }
    if (s.startsWith('"') || s.startsWith("'")) {
      final q = s[0];
      final end = s.indexOf(q, 1);
      if (end > 0) return s.substring(1, end);
    }
    final sp = s.indexOf(' ');
    final exe = sp > 0 ? s.substring(0, sp) : s;
    if (exe.startsWith('~')) {
      return '${Platform.environment['HOME'] ?? ''}${exe.substring(1)}';
    }
    return exe;
  }

  // ─── Apply ────────────────────────────────────────────────────────────

  static Future<OptimizerApplyResult> apply({
    required List<ServiceCandidate> services,
    required List<StartupApp> apps,
    void Function(String done)? onProgress,
  }) async {
    var svcDone = 0;
    var appDone = 0;
    final errors = <String>[];

    for (final s in services) {
      if (!RegExp(r'^[A-Za-z0-9@_.\-\\]+$').hasMatch(s.unit)) {
        errors.add('invalid: ${s.unit}');
        continue;
      }
      try {
        final wasActive = s.activeState == 'active';
        final res = await _runSudo('systemctl disable --now ${s.unit}',
            timeout: const Duration(seconds: 60));
        if (res != 0) {
          errors.add('${s.unit}: rc=$res');
          continue;
        }
        // Verifica: lo stato deve essere davvero cambiato.
        final enabledNow =
            (await _out('systemctl', ['is-enabled', s.unit])).trim();
        if (enabledNow == 'enabled' || enabledNow == 'enabled-runtime') {
          errors.add('${s.unit}: still $enabledNow');
          continue;
        }
        await OperationHistoryService.logOperation(
          category: 'optimizer',
          action: 'disableService',
          param: s.unit,
          appliedCommand: 'systemctl disable --now ${s.unit}',
          undoCommand: wasActive
              ? 'systemctl enable --now ${s.unit}'
              : 'systemctl enable ${s.unit}',
          success: true,
        );
        svcDone++;
        onProgress?.call(s.unit);
      } catch (e) {
        errors.add('${s.unit}: $e');
      }
    }

    for (final a in apps) {
      final path = a.desktopFile;
      if (path == null || path.isEmpty) continue;
      try {
        final ok = await StartupAppsAnalyzer.disableStartupApp(path,
            appName: a.name, command: a.command);
        if (ok) {
          await OperationHistoryService.logOperation(
            category: 'optimizer',
            action: 'disableStartupApp',
            param: a.name,
            appliedCommand: path,
            undoCommand: _startupUndoCommand(path),
            success: true,
          );
          appDone++;
          onProgress?.call(a.name);
        } else {
          errors.add(a.name);
        }
      } catch (e) {
        errors.add('${a.name}: $e');
      }
    }

    return OptimizerApplyResult(
      servicesDisabled: svcDone,
      appsDisabled: appDone,
      errors: errors,
    );
  }

  /// Undo corretto per `StartupAppsAnalyzer.disableStartupApp`:
  /// - file di sistema (`/etc/xdg/autostart`): viene creato un override
  ///   utente con `Hidden=true` → l'undo rimuove l'override;
  /// - file utente: `Hidden=true` viene scritto nel file → l'undo rimette
  ///   `Hidden=false` (funzionalmente equivalente all'originale).
  static String _startupUndoCommand(String path) {
    if (path.startsWith('/etc/xdg/autostart/')) {
      final name = path.split('/').last;
      return 'rm -f "\$HOME/.config/autostart/$name"';
    }
    return "sed -i 's/^Hidden=.*/Hidden=false/' \"$path\"";
  }

  // ─── Helpers di esecuzione ────────────────────────────────────────────

  static Future<String> _out(String exec, List<String> args,
      {Duration timeout = _cmdTimeout, bool allowFailure = false}) async {
    final r = await _outResult(exec, args, timeout: timeout);
    if (r == null) return '';
    if (!allowFailure && r.exitCode != 0 && r.exitCode != 1) return '';
    return r.stdout as String;
  }

  static Future<ProcessResult?> _outResult(String exec, List<String> args,
      {Duration timeout = _cmdTimeout}) async {
    try {
      return await runProcess(exec, args, timeout: timeout);
    } catch (_) {
      return null;
    }
  }

  static Future<int> _runSudo(String command,
      {Duration timeout = const Duration(seconds: 60)}) async {
    final password = await PasswordStorage.getPassword();
    if (password == null || password.isEmpty) return -2;
    final escapedPassword = password
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\$', '\\\$')
        .replaceAll('`', '\\`');
    final fullCommand =
        'printf "%s\\n" "$escapedPassword" | sudo -p "" -S bash -c ${_shellQuote(command)} 2>&1';
    try {
      final result = await runProcess('bash', ['-c', fullCommand],
          runInShell: true, timeout: timeout);
      return result.exitCode;
    } catch (_) {
      return -1;
    }
  }

  static String _shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }
}
