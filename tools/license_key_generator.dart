// ignore_for_file: avoid_print
/// Generates a license code for the Advanced version.
/// Usage: dart run tools/license_key_generator.dart <nome> <cognome> <email>
/// Example: dart run tools/license_key_generator.dart "Mario" "Rossi" "mario@example.com"

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

const String _kLicenseSecret = 'SLU-License-2025-Secret-Key-Change-In-Production';

String _normalize(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String generateCode(String nome, String cognome, String email) {
  final normalized = '${_normalize(nome)}|${_normalize(cognome)}|${_normalize(email)}';
  final key = utf8.encode(_kLicenseSecret);
  final bytes = utf8.encode(normalized);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(bytes);
  final hex = digest.toString();
  final part1 = hex.substring(0, 5).toUpperCase();
  final part2 = hex.substring(5, 10).toUpperCase();
  final part3 = hex.substring(10, 15).toUpperCase();
  final part4 = hex.substring(15, 20).toUpperCase();
  return 'SLU-$part1-$part2-$part3-$part4';
}

void main(List<String> args) {
  if (args.length < 3) {
    print('Usage: dart run tools/license_key_generator.dart <nome> <cognome> <email>');
    print('Example: dart run tools/license_key_generator.dart "Mario" "Rossi" "mario@example.com"');
    exit(1);
  }
  final nome = args[0];
  final cognome = args[1];
  final email = args[2];
  final code = generateCode(nome, cognome, email);
  print('License code for $nome $cognome <$email>:');
  print(code);
}
