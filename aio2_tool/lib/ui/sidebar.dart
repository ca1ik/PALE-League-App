import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/ui_provider.dart';
import 'secret_features.dart'; // <--- YENİ DOSYAYI BURAYA EKLE

class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uiProv = Provider.of<UIProvider>(context);
    return uiProv.isModernSidebar
        ? _ModernSidebar(
            selectedIndex: selectedIndex, onIndexChanged: onIndexChanged)
        : _ClassicSidebar(
            selectedIndex: selectedIndex, onIndexChanged: onIndexChanged);
  }
}

// 1. TİP: KLASİK SIDEBAR
class _ClassicSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const _ClassicSidebar(
      {required this.selectedIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = themeProv.isDark;

    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101014).withOpacity(0.8) : Colors.white,
        border: Border(
            right: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const ProfileAvatar(),
          const SizedBox(height: 30),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _classicItem(0, Icons.desktop_windows,
                      lang.translate('mod_res'), isDark),
                  _classicItem(1, Icons.cleaning_services,
                      lang.translate('mod_clean'), isDark),
                  _classicItem(2, Icons.dns, lang.translate('mod_dns'), isDark),
                  _classicItem(
                      3, Icons.bolt, lang.translate('mod_power'), isDark),
                  _classicItem(
                      4, Icons.keyboard, lang.translate('mod_key'), isDark),
                  _classicItem(
                      5, Icons.wifi, lang.translate('mod_wifi'), isDark),
                  _classicItem(
                      6, Icons.security, lang.translate('mod_sec'), isDark),
                  _classicItem(
                      7, Icons.speed, lang.translate('mod_opt'), isDark),
                  _classicItem(
                      8, Icons.history, lang.translate('mod_hist'), isDark),
                  _classicItem(9, Icons.info_outline,
                      lang.translate('mod_about'), isDark),
                  Divider(
                      color: isDark ? Colors.white24 : Colors.black12,
                      indent: 20,
                      endIndent: 20),
                  _classicItem(
                      10, Icons.auto_awesome, lang.translate('mod_ai'), isDark,
                      isRgb: true),
                  _classicItem(11, Icons.currency_bitcoin,
                      lang.translate('mod_chart'), isDark,
                      isRgb: true),
                  _classicItem(12, Icons.map_outlined,
                      lang.translate('weather_title'), isDark,
                      isRgb: true),
                ],
              ),
            ),
          ),

          // --- GİZLİ ANAHTAR BUTONU (YENİ) ---
          Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: GlowingKeyButton(
              onTap: () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => const HackerLoginDialog(),
                );
              },
            ),
          ),

          // --- AYARLAR ---
          IconButton(
            onPressed: () => onIndexChanged(13),
            icon: Icon(Icons.settings,
                color: selectedIndex == 13
                    ? const Color(0xFF6C63FF)
                    : Colors.grey),
            tooltip: lang.translate('settings'),
          ),
          const SizedBox(height: 10),

          // --- TEMA ---
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: IconButton(
              onPressed: () => themeProv.toggleTheme(),
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                  color: isDark ? Colors.yellow : Colors.indigo),
              tooltip: "Temayı Değiştir",
            ),
          )
        ],
      ),
    );
  }

  Widget _classicItem(int index, IconData icon, String label, bool isDark,
      {bool isRgb = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SidebarItem(
        icon: icon,
        label: label,
        isSelected: selectedIndex == index,
        onTap: () => onIndexChanged(index),
        isRgb: isRgb,
        isDark: isDark,
      ),
    );
  }
}

// 2. TİP: MODERN SIDEBAR (Buna da ekleyelim)
class _ModernSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;

  const _ModernSidebar(
      {required this.selectedIndex, required this.onIndexChanged});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = themeProv.isDark;

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.desktop_windows, 'label': lang.translate('mod_res')},
      {'icon': Icons.cleaning_services, 'label': lang.translate('mod_clean')},
      {'icon': Icons.dns, 'label': lang.translate('mod_dns')},
      {'icon': Icons.power, 'label': lang.translate('mod_power')},
      {'icon': Icons.keyboard, 'label': lang.translate('mod_key')},
      {'icon': Icons.wifi, 'label': lang.translate('mod_wifi')},
      {'icon': Icons.security, 'label': lang.translate('mod_sec')},
      {'icon': Icons.speed, 'label': lang.translate('mod_opt')},
      {'icon': Icons.history, 'label': lang.translate('mod_hist')},
      {'icon': Icons.info_outline, 'label': lang.translate('mod_about')},
      {'icon': Icons.auto_awesome, 'label': lang.translate('mod_ai')},
      {'icon': Icons.currency_bitcoin, 'label': lang.translate('mod_chart')},
      {'icon': Icons.map_outlined, 'label': lang.translate('weather_title')},
      {'icon': Icons.settings, 'label': lang.translate('settings')},
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 240,
          margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Icon(Icons.hub, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text("NATROFF AIO",
                  style: GoogleFonts.orbitron(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    final isSelected = selectedIndex == index;
                    return _modernItem(context, item['icon'], item['label'],
                        isSelected, () => onIndexChanged(index), isDark);
                  },
                ),
              ),

              // --- MODERN TARAFDA DA GİZLİ BUTON ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: GlowingKeyButton(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => const HackerLoginDialog(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernItem(BuildContext context, IconData icon, String label,
      bool isSelected, VoidCallback onTap, bool isDark) {
    // ... Eski kodun aynısı ...
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border(
                left:
                    BorderSide(color: Theme.of(context).primaryColor, width: 3))
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon,
            color: isSelected
                ? Theme.of(context).primaryColor
                : (isDark ? Colors.white60 : Colors.black54),
            size: 20),
        title: Text(label,
            style: GoogleFonts.poppins(
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? Colors.white60 : Colors.black54),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
        hoverColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ... SidebarItem ve ProfileAvatar sınıfları aynı kalıyor ...
class SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isRgb;
  final bool isDark;
  final VoidCallback onTap;

  const SidebarItem(
      {super.key,
      required this.icon,
      required this.label,
      required this.isSelected,
      required this.onTap,
      required this.isRgb,
      required this.isDark});

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? const Color(0xFF6C63FF)
        : (widget.isDark ? Colors.grey : Colors.grey[600]);
    final scale = (_hover || widget.isSelected) ? 1.1 : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          child: Column(children: [
            widget.isRgb
                ? ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                            colors: [Colors.orange, Colors.purple, Colors.blue])
                        .createShader(b),
                    child: Icon(widget.icon, size: 30, color: Colors.white))
                : Icon(widget.icon, size: 28, color: color),
            const SizedBox(height: 5),
            Text(widget.label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight:
                        widget.isSelected ? FontWeight.bold : FontWeight.normal,
                    color: (widget.isSelected || _hover)
                        ? (widget.isDark ? Colors.white : Colors.black)
                        : color),
                textAlign: TextAlign.center)
          ]),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
        turns: _c,
        child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Colors.purple, Colors.cyan])),
            child: const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.white))));
  }
}
