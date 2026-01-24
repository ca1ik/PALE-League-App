import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('tr');
  Locale get currentLocale => _currentLocale;

  void toggleLanguage() {
    _currentLocale = _currentLocale.languageCode == 'tr'
        ? const Locale('en')
        : const Locale('tr');
    notifyListeners();
  }

  // Çeviri Sözlüğü - TÜM KELİMELER EKLENDİ
  static final Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      'app_title': 'Natroff AIO Ultimate',
      'settings': 'Ayarlar',
      'lang_label': 'Dil (Language)',
      'weather_title': 'Hava Durumu',
      'select_city': 'Detaylar için bir ile tıklayın',
      'today': 'Bugün',
      'tomorrow': 'Yarın',
      'weekly': 'Haftalık',
      // Modül İsimleri (TR)
      'mod_res': 'Ekran',
      'mod_clean': 'Temizlik',
      'mod_dns': 'DNS',
      'mod_power': 'Güç',
      'mod_key': 'Klavye',
      'mod_wifi': 'Ağ',
      'mod_sec': 'Güvenlik',
      'mod_opt': 'Optimize',
      'mod_hist': 'Geçmiş',
      'mod_web': 'Web',
      'mod_about': 'Hakkında',
      'mod_ai': 'AI Foto',
      'mod_chart': 'Borsa',
      // Ayarlar
      'sidebar_style': 'Sidebar Stili',
      'style_modern': 'Modern (Cam & Geniş)',
      'style_classic': 'Klasik (İnce)',
    },
    'en': {
      'app_title': 'Natroff AIO Ultimate',
      'settings': 'Settings',
      'lang_label': 'Language (Dil)',
      'weather_title': 'Weather Forecast',
      'select_city': 'Click a city for details',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'weekly': 'Weekly',
      // Modül İsimleri (EN)
      'mod_res': 'Display',
      'mod_clean': 'Cleaner',
      'mod_dns': 'DNS',
      'mod_power': 'Power',
      'mod_key': 'Keyboard',
      'mod_wifi': 'Network',
      'mod_sec': 'Security',
      'mod_opt': 'Boost',
      'mod_hist': 'History',
      'mod_web': 'Web',
      'mod_about': 'About',
      'mod_ai': 'AI Photo',
      'mod_chart': 'Market',
      // Settings
      'sidebar_style': 'Sidebar Style',
      'style_modern': 'Modern (Glass & Wide)',
      'style_classic': 'Classic (Thin)',
    },
  };

  String translate(String key) {
    return _localizedValues[_currentLocale.languageCode]?[key] ?? key;
  }
}
