import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singola voce della cronologia appunti.
class ClipboardEntry {
  final String text;
  final int timestampMs;

  const ClipboardEntry({required this.text, required this.timestampMs});

  Map<String, dynamic> toJson() => {'text': text, 'ts': timestampMs};

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) {
    return ClipboardEntry(
      text: (json['text'] ?? '').toString(),
      timestampMs: (json['ts'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Memorizza tutto ciò che passa per gli appunti di sistema.
///
/// Il monitoraggio avviene tramite polling di [Clipboard.getData] ogni 2
/// secondi: ogni nuovo testo viene salvato in [SharedPreferences] con il
/// timestamp di acquisizione. Le voci più vecchie della retention
/// configurata ([prefKeyRetentionHours], 1-8 ore) vengono eliminate
/// automaticamente a ogni avvio del monitoraggio e a ogni nuova acquisizione.
class ClipboardHistoryService {
  static const String prefKeyHistoryJson = 'clipboard_history_json';
  static const String prefKeyRetentionHours = 'clipboard_retention_hours';

  /// Ore di conservazione predefinite se l'utente non ha ancora scelto.
  static const int defaultRetentionHours = 4;

  /// Limite voci conservate (protezione memoria).
  static const int maxEntries = 500;

  static Timer? _pollTimer;
  static String? _lastSeenText;
  static bool _running = false;

  static bool get isRunning => _running;

  /// Ore di retention correnti (1-8), con fallback al default.
  static Future<int> getRetentionHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final h = prefs.getInt(prefKeyRetentionHours) ?? defaultRetentionHours;
      if (h < 1 || h > 8) return defaultRetentionHours;
      return h;
    } catch (_) {
      return defaultRetentionHours;
    }
  }

  static Future<void> setRetentionHours(int hours) async {
    final h = hours.clamp(1, 8);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefKeyRetentionHours, h);
    // Applica subito la nuova scadenza alle voci esistenti.
    await pruneExpired();
  }

  /// Avvia il monitoraggio periodico degli appunti. Idempotente.
  static void startMonitoring() {
    if (_running) return;
    _running = true;
    // Pulisci subito le voci scadute all'avvio.
    unawaited(pruneExpired());
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_pollOnce());
    });
    // Prima lettura immediata.
    unawaited(_pollOnce());
  }

  static void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _running = false;
  }

  static Future<void> _pollOnce() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) return;
      if (text == _lastSeenText) return;
      _lastSeenText = text;
      await recordText(text);
    } catch (_) {
      // Clipboard non disponibile (es. nessuna sessione grafica): ignora.
    }
  }

  /// Registra un testo evitando duplicati consecutivi.
  static Future<void> recordText(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final entries = await getEntries();
    if (entries.isNotEmpty && entries.first.text == t) return;
    entries.insert(
      0,
      ClipboardEntry(text: t, timestampMs: DateTime.now().millisecondsSinceEpoch),
    );
    final trimmed = entries.length > maxEntries ? entries.sublist(0, maxEntries) : entries;
    await _saveAll(trimmed);
    await pruneExpired();
  }

  /// Tutte le voci salvate, dalla più recente. Applica comunque la scadenza.
  static Future<List<ClipboardEntry>> getEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKeyHistoryJson);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = <ClipboardEntry>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final e = ClipboardEntry.fromJson(item);
          if (e.text.isNotEmpty) entries.add(e);
        }
      }
      entries.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
      final hours = prefs.getInt(prefKeyRetentionHours) ?? defaultRetentionHours;
      final cutoff = DateTime.now().millisecondsSinceEpoch - hours * 3600 * 1000;
      return entries.where((e) => e.timestampMs >= cutoff).toList();
    } catch (_) {
      return [];
    }
  }

  /// Elimina le voci oltre la retention. Ritorna quante ne sono rimaste.
  static Future<int> pruneExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKeyHistoryJson);
      if (raw == null || raw.isEmpty) return 0;
      final decoded = jsonDecode(raw) as List<dynamic>;
      final hours = prefs.getInt(prefKeyRetentionHours) ?? defaultRetentionHours;
      final cutoff = DateTime.now().millisecondsSinceEpoch - hours * 3600 * 1000;
      final kept = <ClipboardEntry>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final e = ClipboardEntry.fromJson(item);
          if (e.text.isNotEmpty && e.timestampMs >= cutoff) kept.add(e);
        }
      }
      kept.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
      final trimmed = kept.length > maxEntries ? kept.sublist(0, maxEntries) : kept;
      await prefs.setString(
        prefKeyHistoryJson,
        jsonEncode(trimmed.map((e) => e.toJson()).toList()),
      );
      return trimmed.length;
    } catch (_) {
      return 0;
    }
  }

  /// Aggiorna il testo di una voce identificata dal timestamp.
  static Future<void> updateEntry(int timestampMs, String newText) async {
    final t = newText.trim();
    if (t.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    final idx = entries.indexWhere((e) => e.timestampMs == timestampMs);
    if (idx < 0) return;
    entries[idx] = ClipboardEntry(text: t, timestampMs: entries[idx].timestampMs);
    await prefs.setString(
      prefKeyHistoryJson,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> deleteEntry(int timestampMs) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.removeWhere((e) => e.timestampMs == timestampMs);
    await prefs.setString(
      prefKeyHistoryJson,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefKeyHistoryJson);
    _lastSeenText = null;
  }

  static Future<void> _saveAll(List<ClipboardEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefKeyHistoryJson,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }
}
