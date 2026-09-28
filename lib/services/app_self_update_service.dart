import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_build.dart';
import 'password_storage.dart';

class AppSelfUpdateService {
  static const String _latestReleaseApi =
      'https://api.github.com/repos/sviluppoarte1-lang/superlinuxutility/releases/latest';

  /// Checks GitHub for a newer release without downloading.
  /// Returns `null` if no update or error; otherwise returns a map with
  /// `latestVersion`, `currentVersion`, `releaseUrl`, `assetName`, `downloadUrl`.
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    try {
      if (!Platform.isLinux) return null;
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final releaseResponse = await http.get(
        Uri.parse(_latestReleaseApi),
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (releaseResponse.statusCode != 200) return null;

      final payload = jsonDecode(releaseResponse.body) as Map<String, dynamic>;
      final latestTag = (payload['tag_name']?.toString() ?? '').trim();
      final latestVersion = _normalizeVersion(latestTag);
      final currentNormalized = _normalizeVersion(currentVersion);

      if (!_isVersionNewer(latestVersion, currentNormalized)) return null;

      final assets = (payload['assets'] as List<dynamic>? ?? const <dynamic>[]);
      final expectedPrefix = _expectedDebPrefixForBuild();
      final match = assets.cast<Map<String, dynamic>?>().firstWhere(
            (asset) {
              final name = asset?['name']?.toString().toLowerCase() ?? '';
              return name.startsWith(expectedPrefix) && name.endsWith('_amd64.deb');
            },
            orElse: () => null,
          );
      if (match == null) return null;

      final downloadUrl = match['browser_download_url']?.toString();
      final assetName = match['name']?.toString();
      if (downloadUrl == null || assetName == null) return null;

      return {
        'latestVersion': latestVersion,
        'currentVersion': currentVersion,
        'releaseUrl': payload['html_url']?.toString() ?? _latestReleaseApi,
        'assetName': assetName,
        'downloadUrl': downloadUrl,
        'tag_name': latestTag,
        'body': payload['body']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// Downloads a .deb from [downloadUrl] and installs via `sudo dpkg -i`.
  /// Returns a result map with `success`, `message`, optional `output`.
  static Future<Map<String, dynamic>> downloadAndInstall(String downloadUrl, String assetName) async {
    try {
      final debResponse = await http.get(Uri.parse(downloadUrl));
      if (debResponse.statusCode != 200) {
        return {'success': false, 'message': 'Download failed (${debResponse.statusCode}).'};
      }
      final tmpDir = await Directory.systemTemp.createTemp('slu_update_');
      final debPath = '${tmpDir.path}/$assetName';
      final debFile = File(debPath);
      await debFile.writeAsBytes(debResponse.bodyBytes, flush: true);

      final password = await PasswordStorage.getPassword();
      if (password == null || password.isEmpty) {
        return {'success': false, 'message': 'Admin password required to install updates.'};
      }

      final escapedPassword = password
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');
      final escapedDebPath = debPath.replaceAll('"', r'\"');

      final installCommand =
          'printf "%s\\n" "$escapedPassword" | sudo -S dpkg -i "$escapedDebPath" || '
          '(printf "%s\\n" "$escapedPassword" | sudo -S apt-get install -f -y && '
          'printf "%s\\n" "$escapedPassword" | sudo -S dpkg -i "$escapedDebPath")';

      final installResult = await Process.run('bash', ['-c', installCommand], runInShell: true);
      final output = '${installResult.stdout}\n${installResult.stderr}'.trim();
      if (installResult.exitCode != 0) {
        return {'success': false, 'message': 'Install failed.', 'output': output};
      }
      return {'success': true, 'message': 'Application updated successfully.', 'output': output};
    } catch (e) {
      return {'success': false, 'message': 'Download/install failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> checkAndAutoUpdateFromGithub() async {
    try {
      final update = await checkForUpdate();
      if (update == null) {
        final packageInfo = await PackageInfo.fromPlatform();
        return {
          'success': true,
          'updated': false,
          'message': 'App is already up to date.',
          'currentVersion': packageInfo.version,
          'latestVersion': packageInfo.version,
        };
      }
      final result = await downloadAndInstall(
        update['downloadUrl'] as String,
        update['assetName'] as String,
      );
      return {
        'success': result['success'],
        'updated': result['success'],
        'message': result['success']
            ? 'Application updated to ${update['latestVersion']}.'
            : result['message'],
        'output': result['output'],
        'latestVersion': update['latestVersion'],
      };
    } catch (e) {
      return {'success': false, 'updated': false, 'message': 'Auto update failed: $e'};
    }
  }

  static String _expectedDebPrefixForBuild() {
    if (isPersonalBuild) return 'super-linux-utility-personal_';
    if (isAdvancedBuild) return 'super-linux-utility-advanced_';
    return 'super-linux-utility_';
  }

  static String _normalizeVersion(String value) {
    var v = value.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    final plusIdx = v.indexOf('+');
    if (plusIdx >= 0) {
      v = v.substring(0, plusIdx);
    }
    return v;
  }

  static bool _isVersionNewer(String candidate, String current) {
    final a = candidate.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final b = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av > bv) return true;
      if (av < bv) return false;
    }
    return false;
  }
}
