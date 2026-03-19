import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:super_linux_utility/l10n/app_localizations.dart';
import 'package:super_linux_utility/config/app_build.dart';
import '../services/license_service.dart';

/// Dialog to activate the Advanced version with nome, cognome, email and license code.
class LicenseActivationDialog extends StatefulWidget {
  final VoidCallback? onActivated;

  const LicenseActivationDialog({super.key, this.onActivated});

  @override
  State<LicenseActivationDialog> createState() => _LicenseActivationDialogState();
}

class _LicenseActivationDialogState extends State<LicenseActivationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final nome = _nomeController.text;
    final cognome = _cognomeController.text;
    final email = _emailController.text;
    final code = _codeController.text;

    final ok = verify(nome, cognome, email, code);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      await setActivated('$nome $cognome <$email>');
      widget.onActivated?.call();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = AppLocalizations.of(context)!.licenseActivateError;
      });
    }
  }

  /// Link PayPal.me con importo preimpostato 19,99 € (formato: paypal.me/username/amount)
  static const String _paypalUrl = 'https://paypal.me/fearescape/19.99';

  Future<void> _launchPayPal() async {
    final uri = Uri.parse(_paypalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.licenseActivate),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdvancedBuild) ...[
                Text(
                  l10n.purchaseLicenseViaPaypal,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _launchPayPal,
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text(l10n.payWithPaypal),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: l10n.licenseName,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.licenseRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cognomeController,
                decoration: InputDecoration(
                  labelText: l10n.licenseSurname,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.licenseRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.licenseEmail,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.licenseRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: l10n.licenseCode,
                  hintText: 'SLU-XXXXX-XXXXX-XXXXX-XXXXX',
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => (v == null || v.trim().isEmpty) ? l10n.licenseRequired : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loading
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) _activate();
                },
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.licenseActivateButton),
        ),
      ],
    );
  }
}
