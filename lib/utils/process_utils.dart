import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Process.run con kill su timeout.
///
/// `Process.run` di dart:io NON supporta un timeout: un comando fermo (es.
/// `sudo -S` in attesa di lock apt, o un prompt non risposto) bloccava l'app
/// per sempre. [runProcess] avvia il processo con [Process.start], raccoglie
/// stdout/stderr e se non termina entro [timeout] invia SIGKILL e restituisce
/// un [ProcessResult] con exitCode convenzionale **124** (timeout).
Future<ProcessResult> runProcess(
  String executable,
  List<String> arguments, {
  bool runInShell = false,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final Process process = await Process.start(
    executable,
    arguments,
    runInShell: runInShell,
  );
  bool killed = false;
  final killer = Timer(timeout, () {
    killed = true;
    process.kill(ProcessSignal.sigkill);
  });
  try {
    const dec = Utf8Decoder(allowMalformed: true);
    final out = await process.stdout.transform(dec).fold(
          StringBuffer(),
          (buf, chunk) => buf..write(chunk),
        );
    final err = await process.stderr.transform(dec).fold(
          StringBuffer(),
          (buf, chunk) => buf..write(chunk),
        );
    final code = await process.exitCode;
    return ProcessResult(
      process.pid,
      killed ? 124 : code,
      out.toString(),
      err.toString(),
    );
  } finally {
    killer.cancel();
  }
}
