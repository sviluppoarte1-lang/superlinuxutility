import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordStorage {
  static const String _passwordKey = 'admin_password';

  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = base64Encode(utf8.encode(password));
    await prefs.setString(_passwordKey, encoded);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_passwordKey);
    if (encoded != null) {
      try {
        return utf8.decode(base64Decode(encoded));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<bool> hasPassword() async {
    final password = await getPassword();
    return password != null && password.isNotEmpty;
  }

  static Future<void> deletePassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
  }
}
