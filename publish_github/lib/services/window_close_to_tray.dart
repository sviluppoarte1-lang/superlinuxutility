import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'tray_service.dart';

class _CloseToTrayListener extends WindowListener {
  @override
  void onWindowClose() async {
    final prefs = await SharedPreferences.getInstance();
    final closeToTray = prefs.getBool(TrayService.prefKeyCloseToTray) ?? true;
    if (closeToTray && TrayService.isInitialized) {
      await windowManager.hide();
    }
  }

  @override
  void onWindowMinimize() async {
    final prefs = await SharedPreferences.getInstance();
    final closeToTray = prefs.getBool(TrayService.prefKeyCloseToTray) ?? true;
    if (closeToTray && TrayService.isInitialized) {
      await windowManager.hide();
    }
  }
}

final _listener = _CloseToTrayListener();
bool _listenerAdded = false;

Future<void> initWindowCloseToTray() async {
  if (!Platform.isLinux) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final closeToTray = prefs.getBool(TrayService.prefKeyCloseToTray) ?? true;
    await windowManager.setPreventClose(closeToTray);
    if (!_listenerAdded) {
      windowManager.addListener(_listener);
      _listenerAdded = true;
    }
    final startMinimized = prefs.getBool(TrayService.prefKeyStartMinimized) ?? false;
    if (startMinimized && TrayService.isInitialized) {
      void doHide() {
        TrayService.hideWindow();
        windowManager.hide();
      }
      doHide();
      // Ripeti dopo un ritardo: la finestra su Linux può essere creata dopo il primo frame
      Future<void>.delayed(const Duration(milliseconds: 100), doHide);
      Future<void>.delayed(const Duration(milliseconds: 400), doHide);
      Future<void>.delayed(const Duration(milliseconds: 800), doHide);
    }
  } catch (_) {}
}

Future<void> setCloseToTray(bool value) async {
  if (!Platform.isLinux) return;
  try {
    await windowManager.setPreventClose(value);
  } catch (_) {}
}
