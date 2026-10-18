// ignore_for_file: avoid_print
/// Generates a license code for the Advanced version.
/// Usage: dart run tools/license_key_generator.dart <nome> <cognome> <email>
/// Example: dart run tools/license_key_generator.dart "Mario" "Rossi" "mario@example.com"
///
/// Il secret NON è più nel repo: viene letto dal file git-ignored
/// `$HOME/.config/slu/license_secret` (stessa sorgente degli script di build)
/// oppure dalla env `SLU_LICENSE_SECRET` (ha la precedenza).
/// Se il file non esiste, crealo UNA volta (gira con openssl):
///   mkdir -p ~/.config/slu && echo -n "$(openssl rand -hex 32)" > ~/.config/slu/license_secret
/// ATTENZIONE: il valore nel file DEVE essere lo stesso usato per i build —
/// se cambi il file, le licenze già vendute smettono di funzionare.

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';

String _licenseSecret() {
  final env = Platform.environment['SLU_LICENSE_SECRET'];
  if (env != null && env.isNotEmpty) return env;
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return '';
  final f = File('$home/.config/slu/license_secret');
  if (!f.existsSync()) return '';
  final s = f.readAsStringSync().trim();
  return s;
}

String _normalize(String s) =>
    s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String generateCode(String nome, String cognome, String email) {
  final normalized = '${_normalize(nome)}|${_normalize(cognome)}|${_normalize(email)}';
  final secret = _licenseSecret();
  if (secret.isEmpty) {
    print('ERROR: secret non trovato.');
    print("Crea il file: mkdir -p ~/.config/slu && echo -n '\$(openssl rand -hex 32)' > ~/.config/slu/license_secret");
    print('Oppure: export SLU_LICENSE_SECRET=<valore>');
    exit(2);
  }
  final key = utf8.encode(secret);
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
