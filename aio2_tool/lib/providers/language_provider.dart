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
      // Modüller
      'mod_res': 'Ekran', 'mod_clean': 'Temizlik', 'mod_dns': 'DNS',
      'mod_power': 'Güç',
      'mod_key': 'Klavye', 'mod_wifi': 'Ağ', 'mod_sec': 'Güvenlik',
      'mod_opt': 'Optimize',
      'mod_hist': 'Geçmiş', 'mod_web': 'Web', 'mod_about': 'Hakkında',
      'mod_ai': 'AI Foto',
      'mod_chart': 'Borsa',
      // Settings
      'sidebar_style': 'Sidebar Stili', 'style_modern': 'Modern (Cam & Geniş)',
      'style_classic': 'Klasik (İnce)',

      // PlayStyles (TÜRKÇE)
      'ps_Technical': 'Teknik', 'ps_Rapid': 'Süratli',
      'ps_QuickStep': 'Seri Adım',
      'ps_FirstTouch': 'İlk Dokunuş', 'ps_Trickster': 'Cambaz',
      'ps_FinesseShot': 'Plase',
      'ps_PowerShot': 'Sert Şut', 'ps_Acrobatic': 'Akrobatik',
      'ps_GameChanger': 'Oyun Kurucu',
      'ps_PingedPass': 'Adrese Teslim', 'ps_FarReach': 'Uzak Erişim',
      'ps_RushOut': 'Kalesini Terk',
      'ps_Jockey': 'Yakın Markaj', 'ps_LongBallPass': 'Uzun Top',
      'ps_TikiTaka': 'Tiki Taka',
      'ps_IncisivePass': 'Ara Pası', 'ps_PressProven': 'Baskıya Direnç',
      'ps_AerialFortress': 'Hava Hakimiyeti',
      'ps_Intercept': 'Pas Arası', 'ps_Anticipate': 'Sezgi',
      'ps_Bruiser': 'Sert Müdahale',
      // UI
      'ui_squad_list': 'TAKIM LİSTESİ', 'ui_playstyles': 'OYUN STİLLERİ',
      'ui_match_analysis': 'MAÇ ANALİZİ',
      'ui_market_val': 'Piyasa Değeri', 'ui_create_player': 'Oyuncu Oluştur',
    },
    'en': {
      'app_title': 'Natroff AIO Ultimate',
      'settings': 'Settings', 'lang_label': 'Language (Dil)',
      'weather_title': 'Weather Forecast',
      'select_city': 'Click a city for details',
      'today': 'Today', 'tomorrow': 'Tomorrow', 'weekly': 'Weekly',
      // Modules
      'mod_res': 'Display', 'mod_clean': 'Cleaner', 'mod_dns': 'DNS',
      'mod_power': 'Power',
      'mod_key': 'Keyboard', 'mod_wifi': 'Network', 'mod_sec': 'Security',
      'mod_opt': 'Boost',
      'mod_hist': 'History', 'mod_web': 'Web', 'mod_about': 'About',
      'mod_ai': 'AI Photo', 'mod_chart': 'Market',
      // Settings
      'sidebar_style': 'Sidebar Style', 'style_modern': 'Modern (Glass & Wide)',
      'style_classic': 'Classic (Thin)',
      // PlayStyles (ENGLISH - Default names)
      'ps_Technical': 'Technical', 'ps_Rapid': 'Rapid',
      'ps_QuickStep': 'Quick Step',
      'ps_FirstTouch': 'First Touch', 'ps_Trickster': 'Trickster',
      'ps_FinesseShot': 'Finesse Shot',
      'ps_PowerShot': 'Power Shot', 'ps_Acrobatic': 'Acrobatic',
      'ps_GameChanger': 'Game Changer',
      'ps_PingedPass': 'Pinged Pass', 'ps_FarReach': 'Far Reach',
      'ps_RushOut': 'Rush Out',
      'ps_Jockey': 'Jockey', 'ps_LongBallPass': 'Long Ball Pass',
      'ps_TikiTaka': 'Tiki Taka',
      'ps_IncisivePass': 'Incisive Pass', 'ps_PressProven': 'Press Proven',
      'ps_AerialFortress': 'Aerial Fortress',
      'ps_Intercept': 'Intercept', 'ps_Anticipate': 'Anticipate',
      'ps_Bruiser': 'Bruiser',
      // UI
      'ui_squad_list': 'SQUAD LIST', 'ui_playstyles': 'PLAYSTYLES',
      'ui_match_analysis': 'MATCH ANALYSIS',
      'ui_market_val': 'Market Value', 'ui_create_player': 'Create Player',
    },
  };

  String translate(String key) {
    // Playstyle için özel kontrol
    if (key.startsWith('ps_')) {
      return _localizedValues[_currentLocale.languageCode]?[key] ??
          key.replaceAll('ps_', '');
    }
    return _localizedValues[_currentLocale.languageCode]?[key] ?? key;
  }
}
