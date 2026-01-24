import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/ui_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final uiProv = Provider.of<UIProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Koyu lacivert arka plan
      appBar: AppBar(
        title: Text(
          lang.translate('settings'),
          style:
              const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BÖLÜM 1: GÖRÜNÜM & STİL ---
            _sectionTitle(lang.currentLocale.languageCode == 'tr'
                ? "Görünüm & Stil"
                : "Appearance & Style"),
            const SizedBox(height: 10),

            // 1. Sidebar Stili Değiştirme (Modern vs Klasik)
            _buildSettingsCard(
              child: SwitchListTile(
                secondary: Icon(
                  uiProv.isModernSidebar
                      ? Icons.view_sidebar
                      : Icons.vertical_split,
                  color: Colors.pinkAccent,
                ),
                title: Text(
                  lang.translate('sidebar_style'), // LanguageProvider'dan gelir
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  uiProv.isModernSidebar
                      ? lang.translate('style_modern')
                      : lang.translate('style_classic'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: uiProv.isModernSidebar,
                activeColor: Colors.pinkAccent,
                onChanged: (val) {
                  uiProv.toggleSidebarStyle();
                },
              ),
            ),

            const SizedBox(height: 15),

            // 2. Spatial Mod (Vision Pro Tarzı) - YENİ EKLENDİ
            _buildSettingsCard(
              child: SwitchListTile(
                secondary: Icon(
                  uiProv.isSpatialMode ? Icons.view_in_ar : Icons.desktop_mac,
                  color: Colors.cyanAccent,
                ),
                title: Text(
                  lang.currentLocale.languageCode == 'tr'
                      ? "Spatial Mod (Vision UI)"
                      : "Spatial Mode",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lang.currentLocale.languageCode == 'tr'
                      ? "Uygulamayı parçalara ayır ve masanda yüzdür."
                      : "Detach modules and float them on your desktop.",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                value: uiProv.isSpatialMode,
                activeColor: Colors.cyanAccent,
                onChanged: (val) {
                  uiProv.toggleSpatialMode();
                },
              ),
            ),

            const SizedBox(height: 30),

            // --- BÖLÜM 2: GENEL AYARLAR ---
            _sectionTitle(lang.translate('app_title')),
            const SizedBox(height: 10),

            // 3. Dil Değiştirme
            _buildSettingsCard(
              child: ListTile(
                leading: const Icon(Icons.translate, color: Colors.blueAccent),
                title: Text(
                  lang.translate('lang_label'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.currentLocale.languageCode.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: lang.currentLocale.languageCode == 'en',
                      activeColor: Colors.blueAccent,
                      onChanged: (value) => lang.toggleLanguage(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bölüm Başlığı Widget'ı
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // Ayarlar Kartı Tasarımı
  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Kart rengi
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
