import 'package:flutter_test/flutter_test.dart';

import 'package:super_linux_utility/services/system_monitor.dart';

void main() {
  group('SystemMonitor.processCpuPercent (formula gnome-system-monitor)', () {
    test('delta rtime / delta jiffies totali, normalizzato su 100', () {
      // 1713 jiffies di CPU su 4800 jiffies totali (24 core x 2s x 100 Hz)
      expect(SystemMonitor.processCpuPercent(2480119, 2478406, 4800),
          closeTo(35.69, 0.01));
    });

    test('primo campione (nessun prev) -> 0%', () {
      expect(SystemMonitor.processCpuPercent(1000, null, 4800), 0.0);
    });

    test('nessun avanzamento jiffies di sistema -> 0%', () {
      expect(SystemMonitor.processCpuPercent(1000, 500, 0), 0.0);
      expect(SystemMonitor.processCpuPercent(1000, 500, -5), 0.0);
    });

    test('processo appena terminato (rtime regresso) -> 0%', () {
      expect(SystemMonitor.processCpuPercent(100, 500, 4800), 0.0);
    });

    test('clamp a 100 (capacita macchina, solaris-mode)', () {
      // Piu jiffies del totale di sistema: rumore di campionamento
      expect(SystemMonitor.processCpuPercent(100000, 0, 4800), 100.0);
    });

    test('100% = tutti i core occupati', () {
      // Un processo che usa tutti i 24 core per 2s: 4800 jiffies su 4800
      expect(SystemMonitor.processCpuPercent(9600, 4800, 4800), 100.0);
    });
  });

  group('SystemMonitor.parsePsIdentityLines', () {
    test('parsa pid, user e command (con spazi)', () {
      final out = SystemMonitor.parsePsIdentityLines(
          '  1 root /sbin/init\n'
          '241498 workstation llama-server --model x.bin -c 8192\n'
          '  3 user \n');
      expect(out.length, 3);
      expect(out[1]!.user, 'root');
      expect(out[1]!.command, '/sbin/init');
      expect(out[241498]!.user, 'workstation');
      expect(out[241498]!.command, 'llama-server --model x.bin -c 8192');
      // args vuoto (es. zombie): command stringa vuota
      expect(out[3]!.user, 'user');
      expect(out[3]!.command, '');
    });

    test('righe non numeriche o vuote saltate', () {
      final out = SystemMonitor.parsePsIdentityLines(
          '\n'
          'PID USER COMMAND\n'
          'abc root /sbin/init\n'
          '  7 root\n');
      expect(out.length, 1);
      expect(out[7]!.user, 'root');
      expect(out[7]!.command, '');
    });
  });
}
