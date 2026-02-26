import 'package:shared_preferences/shared_preferences.dart';

class FontService {
  static const String _fontFamilyKey = 'font_family';
  static const String _fontSizeKey = 'font_size';
  
  // Font disponibili
  static const List<String> availableFonts = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Raleway',
    'Ubuntu',
    'Noto Sans',
    'Inter',
    'Poppins',
    'Source Sans Pro',
  ];
  
  // Dimensioni font disponibili (in sp)
  static const List<double> availableFontSizes = [
    10.0,
    11.0,
    12.0,
    13.0,
    14.0,
    15.0,
    16.0,
    17.0,
    18.0,
    20.0,
    22.0,
    24.0,
  ];
  
  /// Carica la famiglia del font salvata
  static Future<String?> getFontFamily() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontFamilyKey);
  }
  
  /// Salva la famiglia del font
  static Future<void> setFontFamily(String? fontFamily) async {
    final prefs = await SharedPreferences.getInstance();
    if (fontFamily != null && fontFamily.isNotEmpty) {
      await prefs.setString(_fontFamilyKey, fontFamily);
    } else {
      await prefs.remove(_fontFamilyKey);
    }
  }
  
  /// Carica la dimensione del font salvata
  static Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 14.0; // Default: 14sp
  }
  
  /// Salva la dimensione del font
  static Future<void> setFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }
  
  /// Ottiene il font family da usare (default se non impostato)
  static Future<String> getEffectiveFontFamily() async {
    final fontFamily = await getFontFamily();
    return fontFamily ?? 'Roboto'; // Default: Roboto (font standard di Flutter)
  }
  
  /// Ottiene la dimensione del font da usare
  static Future<double> getEffectiveFontSize() async {
    return await getFontSize();
  }
}
