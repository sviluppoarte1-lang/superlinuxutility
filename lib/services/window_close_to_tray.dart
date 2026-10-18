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
      TrayService.hideWindow();
    }
  }

  @override
  void onWindowMinimize() async {
    final prefs = await SharedPreferences.getInstance();
    // Nasconde nel tray SOLO se l'utente lo ha chiesto esplicitamente
    // (Impostazioni → Riduci a icona nel tray). Default: comportamento
    // normale del minimize (resta nella barra delle applicazioni) —
    // un hide involontario al cambio focus/minimizzazione confonde
    // durante l'uso normale.
    final minimizeToTray = prefs.getBool(TrayService.prefKeyMinimizeToTray) ?? false;
    if (minimizeToTray && TrayService.isInitialized) {
      TrayService.hideWindow();
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
    // Primo avvio (lingua/avviso/password da completare): non nascondere mai,
    // le schermate di setup devono restare visibili.
    final languageSelected = prefs.getBool('language_selected') ?? false;
    final warningAccepted = prefs.getBool('warning_accepted') ?? false;
    final passwordConfigured = prefs.getBool('password_configured') ?? false;
    final firstRun =
        !languageSelected || !warningAccepted || !passwordConfigured;
    if (startMinimized && !firstRun && TrayService.isInitialized) {
      void doHide() {
        TrayService.hideWindow();
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
