import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/services/clipboard_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('retention default è 4 e clamp 1-8', () async {
    expect(await ClipboardHistoryService.getRetentionHours(), 4);
    await ClipboardHistoryService.setRetentionHours(99);
    expect(await ClipboardHistoryService.getRetentionHours(), 8);
    await ClipboardHistoryService.setRetentionHours(0);
    expect(await ClipboardHistoryService.getRetentionHours(), 1);
    await ClipboardHistoryService.setRetentionHours(8);
    expect(await ClipboardHistoryService.getRetentionHours(), 8);
  });

  test('record + get ordinati dal più recente', () async {
    await ClipboardHistoryService.recordText('primo');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await ClipboardHistoryService.recordText('secondo');
    final entries = await ClipboardHistoryService.getEntries();
    expect(entries.length, 2);
    expect(entries.first.text, 'secondo');
    expect(entries.last.text, 'primo');
  });

  test('duplicato consecutivo ignorato', () async {
    await ClipboardHistoryService.recordText('stesso');
    await ClipboardHistoryService.recordText('stesso');
    final entries = await ClipboardHistoryService.getEntries();
    expect(entries.length, 1);
  });

  test('testo vuoto ignorato', () async {
    await ClipboardHistoryService.recordText('   ');
    expect(await ClipboardHistoryService.getEntries(), isEmpty);
  });

  test('update + delete + clear', () async {
    await ClipboardHistoryService.recordText('originale');
    var entries = await ClipboardHistoryService.getEntries();
    final ts = entries.first.timestampMs;
    await ClipboardHistoryService.updateEntry(ts, 'modificato');
    entries = await ClipboardHistoryService.getEntries();
    expect(entries.first.text, 'modificato');
    await ClipboardHistoryService.deleteEntry(ts);
    expect(await ClipboardHistoryService.getEntries(), isEmpty);
    await ClipboardHistoryService.recordText('x');
    await ClipboardHistoryService.clearAll();
    expect(await ClipboardHistoryService.getEntries(), isEmpty);
  });

  test('prune elimina voci scadute', () async {
    await ClipboardHistoryService.setRetentionHours(1);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setString(
      ClipboardHistoryService.prefKeyHistoryJson,
      '[{"text":"vecchia","ts":${now - 2 * 3600 * 1000}},'
      '{"text":"recente","ts":$now}]',
    );
    final kept = await ClipboardHistoryService.pruneExpired();
    expect(kept, 1);
    final entries = await ClipboardHistoryService.getEntries();
    expect(entries.length, 1);
    expect(entries.first.text, 'recente');
  });
}
