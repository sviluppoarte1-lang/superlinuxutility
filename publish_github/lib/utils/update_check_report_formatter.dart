import 'package:super_linux_utility/l10n/app_localizations.dart';

/// Builds localized multiline text for [RecoveryService.checkForUpdates] report.
class UpdateCheckReportFormatter {
  static String format(AppLocalizations l10n, Map<String, dynamic>? rawReport) {
    if (rawReport == null || rawReport.isEmpty) {
      return '';
    }
    final buf = StringBuffer();

    void appendApt(Map<String, dynamic> apt) {
      final mode = apt['mode'] as String? ?? 'none';
      final installable = apt['installableCount'] as int? ?? 0;
      final phased = apt['phasedCount'] as int? ?? 0;
      final err = apt['errorMessage'] as String?;

      if (mode == 'error') {
        buf.writeln(l10n.updateCheckAptError(err ?? ''));
      } else if (mode == 'installable') {
        buf.writeln(l10n.updateCheckAptHasUpdates(installable));
        if (phased > 0) {
          buf.writeln(l10n.updateCheckAptPhasedExtra(phased));
        }
      } else if (mode == 'phased_only') {
        buf.writeln(l10n.updateCheckAptPhasedOnly);
        if (phased > 0) {
          buf.writeln(l10n.updateCheckAptPhasedExtra(phased));
        }
      } else {
        buf.writeln(l10n.updateCheckAptNone);
      }
    }

    void appendSimple(
      Map<String, dynamic>? block,
      String noneLabel,
      String Function(int count) has,
      String Function(String error) err,
    ) {
      if (block == null) return;
      final mode = block['mode'] as String? ?? 'none';
      final count = block['count'] as int? ?? 0;
      final e = block['errorMessage'] as String? ?? '';
      if (mode == 'error') {
        buf.writeln(err(e));
      } else if (mode == 'installable') {
        buf.writeln(has(count));
      } else {
        buf.writeln(noneLabel);
      }
    }

    final apt = rawReport['apt'] as Map<String, dynamic>?;
    if (apt != null) {
      appendApt(apt);
    }

    appendSimple(
      rawReport['dnf'] as Map<String, dynamic>?,
      l10n.updateCheckDnfNone,
      l10n.updateCheckDnfHasUpdates,
      l10n.updateCheckDnfError,
    );
    appendSimple(
      rawReport['pacman'] as Map<String, dynamic>?,
      l10n.updateCheckPacmanNone,
      l10n.updateCheckPacmanHasUpdates,
      l10n.updateCheckPacmanError,
    );
    appendSimple(
      rawReport['snap'] as Map<String, dynamic>?,
      l10n.updateCheckSnapNone,
      l10n.updateCheckSnapHasUpdates,
      l10n.updateCheckSnapError,
    );
    appendSimple(
      rawReport['flatpak'] as Map<String, dynamic>?,
      l10n.updateCheckFlatpakNone,
      l10n.updateCheckFlatpakHasUpdates,
      l10n.updateCheckFlatpakError,
    );

    return buf.toString().trim();
  }
}
