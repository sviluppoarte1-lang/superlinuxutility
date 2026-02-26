import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secret used for HMAC (must match tools/license_key_generator.dart).
const String _kLicenseSecret = 'SLU-License-2025-Secret-Key-Change-In-Production';

const String _keyActivated = 'license_activated';
const String _keyLicensedTo = 'licensed_to';

String _normalize(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Generates the expected license code for the given user data.
/// Same algorithm as the key generator.
String generateCode(String nome, String cognome, String email) {
  final normalized = '${_normalize(nome)}|${_normalize(cognome)}|${_normalize(email)}';
  final key = utf8.encode(_kLicenseSecret);
  final bytes = utf8.encode(normalized);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(bytes);
  final hex = digest.toString();
  // Format as SLU-XXXXX-XXXXX-XXXXX-XXXXX (20 chars from hex)
  final part1 = hex.substring(0, 5).toUpperCase();
  final part2 = hex.substring(5, 10).toUpperCase();
  final part3 = hex.substring(10, 15).toUpperCase();
  final part4 = hex.substring(15, 20).toUpperCase();
  return 'SLU-$part1-$part2-$part3-$part4';
}

/// Verifies the user-entered code against nome, cognome, email.
bool verify(String nome, String cognome, String email, String code) {
  final expected = generateCode(nome, cognome, email);
  final entered = code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  final expectedNormalized = expected.replaceAll('-', '').replaceAll(' ', '');
  final enteredNormalized = entered.replaceAll('-', '').replaceAll(' ', '');
  return expectedNormalized == enteredNormalized;
}

/// Whether the advanced license is activated.
Future<bool> isActivated() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyActivated) ?? false;
}

/// Licensed-to string (e.g. "Nome Cognome <email>").
Future<String?> getLicensedTo() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_keyLicensedTo);
}

/// Save activation after successful verification.
Future<void> setActivated(String licensedTo) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyActivated, true);
  await prefs.setString(_keyLicensedTo, licensedTo);
}

/// Deactivate (e.g. for testing or logout).
Future<void> deactivate() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_keyActivated);
  await prefs.remove(_keyLicensedTo);
}
