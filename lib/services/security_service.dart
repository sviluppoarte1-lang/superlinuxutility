import 'dart:io';
import 'operation_history_service.dart';
import 'password_storage.dart';

/// Sicurezza attiva (versione ADVANCED): firewall, servizio SSH, login root
/// via SSH e aggiornamenti automatici. Ogni azione viene registrata nella
/// cronologia operazioni così da poter essere annullata in un secondo momento.
class SecurityService {
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

  static Future<bool> _commandExists(String cmd) async {
    final r = await Process.run('bash', ['-c', 'command -v $cmd 2>/dev/null'], runInShell: true);
    return r.exitCode == 0;
  }

  static Future<String> _sshService() async {
    final r = await Process.run(
        'bash',
        ['-c', 'systemctl list-unit-files 2>/dev/null | grep -q "^ssh.service" && echo ssh || (systemctl list-unit-files 2>/dev/null | grep -q "^sshd.service" && echo sshd || echo ssh)'],
        runInShell: true);
    final output = ((r.stdout as String?) ?? '').trim();
    return output == 'sshd' ? 'sshd' : 'ssh';
  }

  // ─── FIREWALL ───

  /// Abilita il firewall disponibile (ufw → firewalld → nftables). Ritorna l'esito.
  static Future<Map<String, dynamic>> enableFirewall() async {
    final hasUfw = await _commandExists('ufw');
    final hasFirewalld = await _commandExists('firewall-cmd');
    final hasNftables = await _commandExists('nft');
    String backend;
    String apply;
    String undo;
    if (hasUfw) {
      backend = 'ufw';
      apply = 'ufw --force enable';
      undo = 'ufw disable';
    } else if (hasFirewalld) {
      backend = 'firewalld';
      apply = 'systemctl enable --now firewalld 2>&1';
      undo = 'systemctl disable --now firewalld 2>&1';
    } else if (hasNftables) {
      backend = 'nftables';
      apply = 'systemctl enable --now nftables 2>&1';
      undo = 'systemctl disable --now nftables 2>&1';
    } else {
      return {'success': false, 'message': 'No supported firewall found'};
    }
    return _runAndLog(
      category: OperationHistoryService.categorySecurity,
      action: 'firewall_enable',
      param: backend,
      applyCommand: apply,
      undoCommand: undo,
      successMessage: 'Firewall enabled ($backend)',
    );
  }

  static Future<Map<String, dynamic>> disableFirewall() async {
    final hasUfw = await _commandExists('ufw');
    final hasFirewalld = await _commandExists('firewall-cmd');
    final hasNftables = await _commandExists('nft');
    String backend;
    String apply;
    String undo;
    if (hasUfw) {
      backend = 'ufw';
      apply = 'echo y | ufw disable';
      undo = 'ufw --force enable';
    } else if (hasFirewalld) {
      backend = 'firewalld';
      apply = 'systemctl disable --now firewalld 2>&1';
      undo = 'systemctl enable --now firewalld 2>&1';
    } else if (hasNftables) {
      backend = 'nftables';
      apply = 'systemctl disable --now nftables 2>&1';
      undo = 'systemctl enable --now nftables 2>&1';
    } else {
      return {'success': false, 'message': 'No supported firewall found'};
    }
    return _runAndLog(
      category: OperationHistoryService.categorySecurity,
      action: 'firewall_disable',
      param: backend,
      applyCommand: apply,
      undoCommand: undo,
      successMessage: 'Firewall disabled ($backend)',
    );
  }

  // ─── SSH ───

  static Future<Map<String, dynamic>> enableSsh() async {
    final svc = await _sshService();
    return _runAndLog(
      category: OperationHistoryService.categorySecurity,
      action: 'ssh_enable',
      param: svc,
      applyCommand: 'systemctl enable --now $svc 2>&1',
      undoCommand: 'systemctl disable --now $svc 2>&1',
      successMessage: 'SSH service enabled',
    );
  }

  static Future<Map<String, dynamic>> disableSsh() async {
    final svc = await _sshService();
    return _runAndLog(
      category: OperationHistoryService.categorySecurity,
      action: 'ssh_disable',
      param: svc,
      applyCommand: 'systemctl disable --now $svc 2>&1',
      undoCommand: 'systemctl enable --now $svc 2>&1',
      successMessage: 'SSH service disabled',
    );
  }

  // ─── ROOT SSH LOGIN ───

  static Future<Map<String, dynamic>> allowRootSsh() =>
      _setRootSsh(true);

  static Future<Map<String, dynamic>> denyRootSsh() =>
      _setRootSsh(false);

  static Future<Map<String, dynamic>> _setRootSsh(bool allow) async {
    final value = allow ? 'yes' : 'no';
    final svc = await _sshService();
    // Preferisci un file drop-in in /etc/ssh/sshd_config.d/ (più sicuro),
    // altrimenti fai un backup e modifica /etc/ssh/sshd_config.
    final dropInCommand =
        'mkdir -p /etc/ssh/sshd_config.d && '
        'printf "PermitRootLogin $value\\n" > /etc/ssh/sshd_config.d/90-slu-root.conf && '
        'systemctl reload $svc 2>&1';
    final dropInUndo =
        'rm -f /etc/ssh/sshd_config.d/90-slu-root.conf && systemctl reload $svc 2>&1';
    final mainConfigCommand =
        'cp /etc/ssh/sshd_config /etc/ssh/sshd_config.slu.bak && '
        'if grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then '
        'sed -i "s/^#*PermitRootLogin.*/PermitRootLogin $value/" /etc/ssh/sshd_config; '
        'else printf "\\nPermitRootLogin $value\\n" >> /etc/ssh/sshd_config; fi && '
        'systemctl reload $svc 2>&1';
    final mainConfigUndo =
        'if [ -f /etc/ssh/sshd_config.slu.bak ]; then '
        'mv -f /etc/ssh/sshd_config.slu.bak /etc/ssh/sshd_config; fi && '
        'systemctl reload $svc 2>&1';

    // Verifica se sshd_config include la directory drop-in.
    final includesDir = await _runSudo(
        'grep -q "sshd_config.d" /etc/ssh/sshd_config 2>/dev/null && echo yes');
    final useDropIn = (includesDir.stdout as String).trim() == 'yes';
    final apply = useDropIn ? dropInCommand : mainConfigCommand;
    final undo = useDropIn ? dropInUndo : mainConfigUndo;

    return _runAndLog(
      category: OperationHistoryService.categorySecurity,
      action: allow ? 'ssh_root_allow' : 'ssh_root_deny',
      param: value,
      applyCommand: apply,
      undoCommand: undo,
      successMessage: allow ? 'Root SSH login allowed' : 'Root SSH login denied',
    );
  }

  // ─── AUTO-UPDATES ───

  static Future<Map<String, dynamic>> enableAutoUpdates() async {
    return _setAutoUpdates(true);
  }

  static Future<Map<String, dynamic>> disableAutoUpdates() async {
    return _setAutoUpdates(false);
  }

  static Future<Map<String, dynamic>> _setAutoUpdates(bool enable) async {
    // APT (Ubuntu, Debian, Mint, Fedora...)
    final hasApt = await _commandExists('apt-get');
    final hasDnf = await _commandExists('dnf');
    final hasPacman = await _commandExists('pacman');

    String apply;
    String undo;
    if (hasApt) {
      if (enable) {
        apply = 'printf "APT::Periodic::Update-Package-Lists \\"1\\";\\n'
            'APT::Periodic::Unattended-Upgrade \\"1\\";\\n" > /etc/apt/apt.conf.d/20auto-upgrades && '
            '(systemctl enable --now unattended-upgrades 2>&1 || true)';
        undo = 'rm -f /etc/apt/apt.conf.d/20auto-upgrades && '
            '(systemctl disable --now unattended-upgrades 2>&1 || true)';
      } else {
        apply = 'rm -f /etc/apt/apt.conf.d/20auto-upgrades && '
            '(systemctl disable --now unattended-upgrades 2>&1 || true)';
        undo = 'printf "APT::Periodic::Update-Package-Lists \\"1\\";\\n'
            'APT::Periodic::Unattended-Upgrade \\"1\\";\\n" > /etc/apt/apt.conf.d/20auto-upgrades && '
            '(systemctl enable --now unattended-upgrades 2>&1 || true)';
      }
    } else if (hasDnf) {
      if (enable) {
        apply = 'systemctl enable --now dnf-automatic-install.timer 2>&1';
        undo = 'systemctl disable --now dnf-automatic-install.timer 2>&1';
      } else {
        apply = 'systemctl disable --now dnf-automatic-install.timer 2>&1';
        undo = 'systemctl enable --now dnf-automatic-install.timer 2>&1';
      }
    } else if (hasPacman) {
      return {'success': false, 'message': 'Auto-updates not supported on this distribution'};
    } else {
      return {'success': false, 'message': 'Auto-updates not supported on this distribution'};
    }

    return _runAndLog(
      category: OperationHistoryService.categorySecurity,
      action: enable ? 'autoupdate_enable' : 'autoupdate_disable',
      applyCommand: apply,
      undoCommand: undo,
      successMessage: enable ? 'Automatic updates enabled' : 'Automatic updates disabled',
    );
  }

  // ─── HELPER ───

  static Future<Map<String, dynamic>> _runAndLog({
    required String category,
    required String action,
    String? param,
    required String applyCommand,
    required String undoCommand,
    required String successMessage,
  }) async {
    try {
      final result = await _runSudo(applyCommand);
      final ok = result.exitCode == 0;
      final output = (result.stdout as String).trim();
      await OperationHistoryService.logOperation(
        category: category,
        action: action,
        param: param,
        appliedCommand: applyCommand,
        undoCommand: undoCommand,
        success: ok,
      );
      return {
        'success': ok,
        'message': ok ? successMessage : (output.isNotEmpty ? output : 'Operation failed'),
        'output': output,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
