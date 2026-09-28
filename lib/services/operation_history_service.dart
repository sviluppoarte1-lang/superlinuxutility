import 'dart:convert';
import 'dart:io';
import 'password_storage.dart';

class OperationRecord {
  final String id;
  final String category;
  final String action;
  final String? param;
  final String appliedCommand;
  final String? undoCommand;
  final DateTime timestamp;
  final bool success;
  final bool restored;

  const OperationRecord({
    required this.id,
    required this.category,
    required this.action,
    this.param,
    required this.appliedCommand,
    this.undoCommand,
    required this.timestamp,
    required this.success,
    this.restored = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'action': action,
        'param': param,
        'appliedCommand': appliedCommand,
        'undoCommand': undoCommand,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'success': success,
        'restored': restored,
      };

  factory OperationRecord.fromJson(Map<String, dynamic> json) => OperationRecord(
        id: json['id'] as String? ?? '',
        category: json['category'] as String? ?? '',
        action: json['action'] as String? ?? '',
        param: json['param'] as String?,
        appliedCommand: json['appliedCommand'] as String? ?? '',
        undoCommand: json['undoCommand'] as String?,
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            (json['timestamp'] as num?)?.toInt() ?? 0),
        success: json['success'] as bool? ?? false,
        restored: json['restored'] as bool? ?? false,
      );

  OperationRecord copyWith({bool? restored}) => OperationRecord(
        id: id,
        category: category,
        action: action,
        param: param,
        appliedCommand: appliedCommand,
        undoCommand: undoCommand,
        timestamp: timestamp,
        success: success,
        restored: restored ?? this.restored,
      );
}

class OperationHistoryService {
  static const String categorySecurity = 'security';
  static const String categoryKernel = 'kernel';

  static Future<String> _historyDir() async {
    final home = Platform.environment['HOME'] ?? '/root';
    final dir = Directory('$home/.local/share/super-linux-utility');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<File> _historyFile() async {
    final dir = await _historyDir();
    return File('$dir/operations.json');
  }

  static Future<void> logOperation({
    required String category,
    required String action,
    String? param,
    required String appliedCommand,
    String? undoCommand,
    required bool success,
  }) async {
    try {
      final file = await _historyFile();
      final records = await _readRecords(file);
      records.insert(
        0,
        OperationRecord(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          category: category,
          action: action,
          param: param,
          appliedCommand: appliedCommand,
          undoCommand: undoCommand,
          timestamp: DateTime.now(),
          success: success,
        ),
      );
      // Limita la cronologia ai 200 eventi più recenti.
      if (records.length > 200) {
        records.removeRange(200, records.length);
      }
      await file.writeAsString(jsonEncode(records.map((r) => r.toJson()).toList()));
    } catch (_) {
      // Il log non deve mai bloccare l'operazione principale.
    }
  }

  static Future<List<OperationRecord>> _readRecords(File file) async {
    try {
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(OperationRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<OperationRecord>> getOperations() async {
    final file = await _historyFile();
    return _readRecords(file);
  }

  /// Ripristina l'operazione ri-eseguendo il comando di undo. Ritorna l'esito.
  static Future<Map<String, dynamic>> restoreOperation(String id) async {
    final file = await _historyFile();
    final records = await _readRecords(file);
    final index = records.indexWhere((r) => r.id == id);
    if (index < 0) {
      return {'success': false, 'message': 'Operation not found'};
    }
    final record = records[index];
    final undo = record.undoCommand;
    if (undo == null || undo.isEmpty) {
      return {'success': false, 'message': 'This operation cannot be restored'};
    }
    final result = await _runSudoCommand(undo);
    final ok = result.exitCode == 0;
    records[index] = record.copyWith(restored: ok);
    await file.writeAsString(jsonEncode(records.map((r) => r.toJson()).toList()));
    return {
      'success': ok,
      'message': ok ? 'Operation restored successfully' : 'Restore failed',
      'output': (result.stdout as String).trim(),
    };
  }

  static Future<void> markRestored(String id) async {
    final file = await _historyFile();
    final records = await _readRecords(file);
    final index = records.indexWhere((r) => r.id == id);
    if (index < 0) return;
    records[index] = records[index].copyWith(restored: true);
    await file.writeAsString(jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  static Future<void> clearHistory() async {
    final file = await _historyFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Esegue [command] interamente come root (necessario per `&&` / `|`).
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
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll("'", "\\'");
    final fullCommand =
        'printf "%s\\n" "$escapedPassword" | sudo -S bash -c ${shellQuote(command)}';
    return Process.run('bash', ['-c', fullCommand], runInShell: true);
  }

  static String shellQuote(String s) {
    if (s.isEmpty) return "''";
    return "'${s.replaceAll("'", "'\\''")}'";
  }
}
