import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';

class ServicesGuideDialog extends StatefulWidget {
  const ServicesGuideDialog({super.key});

  @override
  State<ServicesGuideDialog> createState() => _ServicesGuideDialogState();
}

class _ServicesGuideDialogState extends State<ServicesGuideDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.servicesGuideTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _sectionTitle(theme, l10n.servicesGuideWhatAre),
              _paragraph(l10n.servicesGuideWhatAreBody),
              const SizedBox(height: 16),
              _sectionTitle(theme, l10n.servicesGuideHowToManage),
              _paragraph(l10n.servicesGuideHowToManageBody),
              const SizedBox(height: 16),
              _sectionTitle(theme, l10n.servicesGuidePrecautions),
              _paragraph(l10n.servicesGuidePrecautionsBody),
              const SizedBox(height: 16),
              _sectionTitle(theme, l10n.servicesGuideHowToDisable),
              _paragraph(l10n.servicesGuideHowToDisableBody),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _dontShowAgain,
                      onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _dontShowAgain = !_dontShowAgain),
                      child: Text(l10n.servicesGuideDontShowAgain, style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_dontShowAgain);
          },
          child: Text(l10n.servicesGuideGotIt),
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _paragraph(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, height: 1.4));
  }
}

Future<void> showServicesGuideIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final alreadyShown = prefs.getBool('services_guide_shown') ?? false;
  if (alreadyShown) return;

  final dontShowAgain = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const ServicesGuideDialog(),
  );

  await prefs.setBool('services_guide_shown', true);
}
