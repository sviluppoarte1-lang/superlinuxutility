import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/services/battery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('pure helpers', () {
    test('computeHealthPercent', () {
      expect(BatteryService.computeHealthPercent(40, 50), 80.0);
      expect(BatteryService.computeHealthPercent(null, 50), isNull);
      expect(BatteryService.computeHealthPercent(40, null), isNull);
      expect(BatteryService.computeHealthPercent(40, 0), isNull);
      expect(BatteryService.computeHealthPercent(60, 50), 100.0);
    });

    test('clampThreshold 20-100', () {
      expect(BatteryService.clampThreshold(80), 80);
      expect(BatteryService.clampThreshold(5), 20);
      expect(BatteryService.clampThreshold(150), 100);
    });

    test('parseSysInt / uwhToWh', () {
      expect(BatteryService.parseSysInt('  42\n'), 42);
      expect(BatteryService.parseSysInt(''), isNull);
      expect(BatteryService.parseSysInt('abc'), isNull);
      expect(BatteryService.uwhToWh('45000000'), 45.0);
      expect(BatteryService.uwhToWh('0'), isNull);
      expect(BatteryService.uwhToWh(''), isNull);
    });

    test('resolveTargetGovernor', () {
      expect(
          BatteryService.resolveTargetGovernor(
            acOnline: true,
            acGovernor: 'performance',
            batteryGovernor: 'powersave',
          ),
          'performance');
      expect(
          BatteryService.resolveTargetGovernor(
            acOnline: false,
            acGovernor: 'performance',
            batteryGovernor: 'powersave',
          ),
          'powersave');
    });
  });

  group('prefs governor', () {
    test('default spento + governor default', () async {
      expect(await BatteryService.getGovernorAutoEnabled(), isFalse);
      expect(await BatteryService.getAcGovernor(), 'performance');
      expect(await BatteryService.getBatteryGovernor(), 'powersave');
    });

    test('set/get governor personalizzati', () async {
      await BatteryService.setAcGovernor('ondemand');
      await BatteryService.setBatteryGovernor('schedutil');
      expect(await BatteryService.getAcGovernor(), 'ondemand');
      expect(await BatteryService.getBatteryGovernor(), 'schedutil');
    });
  });

  group('sysfs reale (questo container)', () {
    test('senza batteria -> absent', () async {
      final h = await BatteryService.getBatteryHealth();
      // Container senza /sys/class/power_supply/BAT*: deve tornare absent,
      // mai eccezione.
      expect(h.present, isFalse);
    });

    test('threshold non supportate qui -> eccezione leggibile', () async {
      final node = await BatteryService.findEndThresholdNode();
      if (node == null) {
        expect(
          () => BatteryService.setChargeEndThreshold(80),
          throwsA(isA<Exception>()),
        );
      }
    });

    test('governor corrente leggibile o unknown', () async {
      final g = await BatteryService.getCurrentGovernor();
      expect(g.isNotEmpty, isTrue);
      final avail = await BatteryService.getAvailableGovernors();
      expect(avail, isNotEmpty);
    });
  });
}
