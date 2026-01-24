import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'glass_box.dart';

class SpatialSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const SpatialSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    // İkon Listesi
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.desktop_windows, 'label': lang.translate('mod_res')},
      {'icon': Icons.cleaning_services, 'label': lang.translate('mod_clean')},
      {'icon': Icons.dns, 'label': lang.translate('mod_dns')},
      {'icon': Icons.power, 'label': lang.translate('mod_power')},
      {'icon': Icons.keyboard, 'label': lang.translate('mod_key')},
      {'icon': Icons.wifi, 'label': lang.translate('mod_wifi')},
      {'icon': Icons.security, 'label': lang.translate('mod_sec')},
      {'icon': Icons.speed, 'label': lang.translate('mod_opt')},
      {'icon': Icons.map_outlined, 'label': lang.translate('weather_title')},
      {'icon': Icons.settings, 'label': lang.translate('settings')},
    ];

    return GlassBox(
      width: 80, // İnce uzun hap şeklinde
      height: 600,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Icon(Icons.hub, color: Colors.white, size: 30),
          ),
          ...List.generate(menuItems.length, (index) {
            final item = menuItems[index];
            final isSelected = selectedIndex == index;

            return Tooltip(
              message: item['label'], // Üzerine gelince yazar
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: () => onIndexChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white : Colors.transparent,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                  child: Icon(
                    item['icon'],
                    color: isSelected ? Colors.black : Colors.white70,
                    size: 24,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
