import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Archiviazione sicura della password sudo.
///
/// - **Preferita**: keyring desktop (Secret Service / libsecret, KDE Wallet
///   compatibile) via `flutter_secure_storage` — la password non sta più in
///   base64 in `shared_preferences.json` leggibile da qualsiasi processo.
/// - **Fallback**: SharedPreferences base64 (comportamento legacy), usato solo
///   se il keyring non è disponibile o fallisce (sistemi minimali/senza gnome-
///   keyring), così l'app continua a funzionare.
/// - **Migrazione**: alla prima lettura/salvataggio la vecchia copia legacy
///   viene spostata nel keyring e RIMOSSA dalle prefs.
class PasswordStorage {
  /// Chiave legacy (base64 in SharedPreferences).
  static const String _legacyKey = 'admin_password';

  /// Chiave nel keyring.
  static const String _secureKey = 'sudo_admin_password';

  static FlutterSecureStorage? _storage;
  static bool? _secureAvailable;

  static FlutterSecureStorage get _secure =>
      _storage ??= const FlutterSecureStorage();

  /// true se il keyring è utilizzabile su questo sistema.
  static Future<bool> keyringAvailable() async {
    if (_secureAvailable != null) return _secureAvailable!;
    try {
      // operazione leggera e senza side-effect per verificare che il backend
      // Secret Service risponda.
      await _secure.containsKey(key: _secureKey);
      _secureAvailable = true;
    } catch (_) {
      _secureAvailable = false;
    }
    return _secureAvailable!;
  }

  /// Sposta la password legacy (base64 in prefs) nel keyring e rimuove la
  /// copia dalle prefs. Best-effort, silenzioso.
  static Future<void> _migrateLegacyToKeyring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = prefs.getString(_legacyKey);
      if (encoded == null) return;
      final pw = utf8.decode(base64Decode(encoded));
      await prefs.remove(_legacyKey);
      if (pw.isNotEmpty) {
        await _secure.write(key: _secureKey, value: pw);
      }
    } catch (_) {
      // se la migrazione fallisce resta comunque la copia legacy leggibile.
    }
  }

  /// Salva la password: preferisce il keyring; in fallback usa base64 legacy.
  static Future<void> savePassword(String password) async {
    if (await keyringAvailable()) {
      try {
        await _secure.write(key: _secureKey, value: password);
        // pulizia eventuale copia legacy precedente
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_legacyKey);
        return;
      } catch (_) {
        _secureAvailable = false; // backend caduto: passa al fallback
      }
    }
    // Fallback legacy.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_legacyKey, base64Encode(utf8.encode(password)));
  }

  /// Legge la password (keyring → fallback legacy con migrazione opportunistica).
  static Future<String?> getPassword() async {
    if (await keyringAvailable()) {
      try {
        final v = await _secure.read(key: _secureKey);
        if (v != null && v.isNotEmpty) {
          // se esiste ancora una copia legacy, è meglio eliminarla.
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_legacyKey);
          } catch (_) {}
          return v;
        }
        // keyring sano ma vuoto: migrazione opportunistica dal legacy.
        await _migrateLegacyToKeyring();
        final migrated = await _secure.read(key: _secureKey);
        if (migrated != null && migrated.isNotEmpty) return migrated;
      } catch (_) {
        _secureAvailable = false;
      }
    }
    // FALLBACK legacy: letta e ritornata TAL QUALE (non svuotata, per non
    // perdere la password su sistemi senza keyring che l'utente ricrea).
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_legacyKey);
    if (encoded == null) return null;
    try {
      return utf8.decode(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasPassword() async {
    final password = await getPassword();
    return password != null && password.isNotEmpty;
  }

  /// Rimuove la password da TUTTI i backend (keyring + legacy).
  static Future<void> deletePassword() async {
    try {
      await _secure.delete(key: _secureKey);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyKey);
  }
}
