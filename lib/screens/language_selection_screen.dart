import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeModeChanged;
  final Function(Locale?)? onLocaleChanged;
  final VoidCallback? onComplete;
  
  const LanguageSelectionScreen({
    super.key, 
    this.onThemeModeChanged, 
    this.onLocaleChanged,
    this.onComplete,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Locale? _selectedLocale;
  final Map<String, Locale> _languages = {
    'it': const Locale('it'),
    'en': const Locale('en'),
    'fr': const Locale('fr'),
    'es': const Locale('es'),
    'de': const Locale('de'),
    'pt': const Locale('pt'),
  };

  String _getLanguageName(String code) {
    switch (code) {
      case 'it':
        return 'Italiano';
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'es':
        return 'Español';
      case 'de':
        return 'Deutsch';
      case 'pt':
        return 'Português';
      default:
        return code;
    }
  }

  Future<void> _saveLanguageSelection() async {
    if (_selectedLocale == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _selectedLocale!.languageCode);
    await prefs.setBool('language_selected', true);
    
    widget.onLocaleChanged?.call(_selectedLocale);
    
    // Attendi un momento per permettere alla localizzazione di aggiornarsi
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      // Naviga alla route principale per far ricontrollare i flag
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.language,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Language Selection',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select the language for the application',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Column(
                    children: _languages.entries.map((entry) {
                      final isSelected = _selectedLocale?.languageCode == entry.key;
                      return RadioListTile<Locale>(
                        title: Text(_getLanguageName(entry.key)),
                        value: entry.value,
                        groupValue: _selectedLocale,
                        onChanged: (Locale? value) {
                          setState(() {
                            _selectedLocale = value;
                          });
                        },
                        selected: isSelected,
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _selectedLocale == null ? null : _saveLanguageSelection,
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    minimumSize: const Size(200, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

