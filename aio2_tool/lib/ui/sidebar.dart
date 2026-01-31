import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/ui_provider.dart';
import 'secret_features.dart';

class CustomSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback onHaxBallClick;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.onHaxBallClick,
  });

  @override
  Widget build(BuildContext context) {
    final uiProv = Provider.of<UIProvider>(context);
    return uiProv.isModernSidebar
        ? _ModernSidebar(
            selectedIndex: selectedIndex,
            onIndexChanged: onIndexChanged,
            onHaxBallClick: onHaxBallClick)
        : _ClassicSidebar(
            selectedIndex: selectedIndex,
            onIndexChanged: onIndexChanged,
            onHaxBallClick: onHaxBallClick);
  }
}

class HaxBallProButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCompact;

  const HaxBallProButton(
      {super.key, required this.onTap, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: isCompact
          ? const EdgeInsets.symmetric(horizontal: 5, vertical: 10)
          : const EdgeInsets.fromLTRB(15, 20, 15, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            ),
            child: isCompact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.gamepad, color: Colors.white, size: 22),
                      const SizedBox(height: 4),
                      Text("HAXBALL",
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.gamepad, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text("HAXBALL",
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _ClassicSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback onHaxBallClick;
  const _ClassicSidebar(
      {required this.selectedIndex,
      required this.onIndexChanged,
      required this.onHaxBallClick});
  @override
  State<_ClassicSidebar> createState() => _ClassicSidebarState();
}

class _ClassicSidebarState extends State<_ClassicSidebar> {
  bool _isUpgradeExpanded = false;
  bool _isPaleHaxExpanded = true;

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
            right: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          HaxBallProButton(onTap: widget.onHaxBallClick, isCompact: true),
          const SizedBox(height: 5),
          const ProfileAvatar(),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(children: [
                  GestureDetector(
                      onTap: () => setState(
                          () => _isUpgradeExpanded = !_isUpgradeExpanded),
                      child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 5),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: _isUpgradeExpanded
                                  ? Colors.indigoAccent.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Icon(
                                _isUpgradeExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.grid_view_rounded,
                                color: isDark ? Colors.white : Colors.black,
                                size: 22),
                            const SizedBox(height: 2),
                            Text("Upgrade",
                                style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold))
                          ]))),
                  AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Column(children: [
                        _item(0, Icons.desktop_windows,
                            lang.translate('mod_res'), isDark),
                        _item(1, Icons.cleaning_services,
                            lang.translate('mod_clean'), isDark),
                        _item(2, Icons.dns, lang.translate('mod_dns'), isDark),
                        _item(
                            3, Icons.bolt, lang.translate('mod_power'), isDark),
                        _item(4, Icons.keyboard, lang.translate('mod_key'),
                            isDark),
                        _item(
                            5, Icons.wifi, lang.translate('mod_wifi'), isDark),
                        _item(6, Icons.security, lang.translate('mod_sec'),
                            isDark),
                        _item(
                            7, Icons.speed, lang.translate('mod_opt'), isDark),
                        _item(8, Icons.history, lang.translate('mod_hist'),
                            isDark),
                        _item(9, Icons.info_outline,
                            lang.translate('mod_about'), isDark),
                        _item(10, Icons.auto_awesome, lang.translate('mod_ai'),
                            isDark,
                            isRgb: true),
                        _item(11, Icons.currency_bitcoin,
                            lang.translate('mod_chart'), isDark,
                            isRgb: true),
                        _item(12, Icons.map_outlined,
                            lang.translate('weather_title'), isDark,
                            isRgb: true),
                        _item(13, Icons.settings, lang.translate('settings'),
                            isDark)
                      ]),
                      crossFadeState: _isUpgradeExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300)),
                  Divider(
                      color: isDark ? Colors.white24 : Colors.black12,
                      indent: 20,
                      endIndent: 20,
                      height: 20),
                  GestureDetector(
                      onTap: () => setState(
                          () => _isPaleHaxExpanded = !_isPaleHaxExpanded),
                      child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 5),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: _isPaleHaxExpanded
                                  ? Colors.cyan.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(children: [
                            Icon(
                                _isPaleHaxExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.sports_soccer,
                                color: isDark ? Colors.white : Colors.black,
                                size: 22),
                            const SizedBox(height: 2),
                            Text("PaleHax",
                                style: GoogleFonts.poppins(
                                    color: isDark ? Colors.white : Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold))
                          ]))),
                  AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Column(children: [
                        _item(14, Icons.home, "Anasayfa", isDark, isRgb: true),
                        _item(15, Icons.groups, "Oyuncular", isDark,
                            isRgb: true),
                        _item(16, Icons.table_chart_rounded, "Puan Durumu",
                            isDark,
                            isRgb: true),
                        _item(17, Icons.emoji_events, "Challenge", isDark,
                            isRgb: true),
                        _item(18, Icons.construction, "Kadro Kur", isDark,
                            isRgb: true),
                        // YENİ EKLENEN BUTONLAR
                        _item(19, Icons.list_alt, "Tier List", isDark,
                            isRgb: true),
                        _item(20, Icons.sports_soccer, "Ultimate", isDark,
                            isRgb: true),
                        _item(21, Icons.games, "Oyunlar", isDark, isRgb: true),
                      ]),
                      crossFadeState: _isPaleHaxExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300))
                ])),
          ),
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlowingKeyButton(
                  onTap: () => showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => const HackerLoginDialog()))),
          IconButton(
              onPressed: () => widget.onIndexChanged(13),
              icon: Icon(Icons.settings,
                  color: widget.selectedIndex == 13
                      ? const Color(0xFF6C63FF)
                      : Colors.grey),
              tooltip: lang.translate('settings')),
          Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: IconButton(
                  onPressed: () => themeProv.toggleTheme(),
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? Colors.yellow : Colors.indigo),
                  tooltip: "Temayı Değiştir")),
        ],
      ),
    );
  }

  Widget _item(int index, IconData icon, String label, bool isDark,
      {bool isRgb = false}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SidebarItem(
            icon: icon,
            label: label,
            isSelected: widget.selectedIndex == index,
            onTap: () => widget.onIndexChanged(index),
            isRgb: isRgb,
            isDark: isDark));
  }
}

class _ModernSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onIndexChanged;
  final VoidCallback onHaxBallClick;
  const _ModernSidebar(
      {required this.selectedIndex,
      required this.onIndexChanged,
      required this.onHaxBallClick});
  @override
  State<_ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<_ModernSidebar> {
  bool _isUpgradeExpanded = false;
  bool _isPaleHaxExpanded = true;
  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final isDark = themeProv.isDark;
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
                width: 240,
                margin:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05))),
                child: Column(children: [
                  const SizedBox(height: 30),
                  Icon(Icons.hub,
                      size: 40, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 10),
                  Text("NATROFF AIO",
                      style: GoogleFonts.orbitron(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold)),
                  HaxBallProButton(
                      onTap: widget.onHaxBallClick, isCompact: false),
                  const SizedBox(height: 10),
                  Expanded(
                      child: SingleChildScrollView(
                          child: Column(children: [
                    ListTile(
                        onTap: () => setState(
                            () => _isUpgradeExpanded = !_isUpgradeExpanded),
                        leading: Icon(Icons.grid_view_rounded,
                            color: isDark ? Colors.white70 : Colors.black54),
                        title: Text("Upgrade",
                            style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold)),
                        trailing: Icon(
                            _isUpgradeExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: isDark ? Colors.white54 : Colors.black45)),
                    AnimatedCrossFade(
                        firstChild: Container(),
                        secondChild: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(children: [
                              _modernItem(context, Icons.desktop_windows,
                                  lang.translate('mod_res'), 0, isDark),
                              _modernItem(context, Icons.cleaning_services,
                                  lang.translate('mod_clean'), 1, isDark),
                              _modernItem(context, Icons.dns,
                                  lang.translate('mod_dns'), 2, isDark),
                              _modernItem(context, Icons.bolt,
                                  lang.translate('mod_power'), 3, isDark),
                              _modernItem(context, Icons.keyboard,
                                  lang.translate('mod_key'), 4, isDark),
                              _modernItem(context, Icons.wifi,
                                  lang.translate('mod_wifi'), 5, isDark),
                              _modernItem(context, Icons.security,
                                  lang.translate('mod_sec'), 6, isDark),
                              _modernItem(context, Icons.speed,
                                  lang.translate('mod_opt'), 7, isDark),
                              _modernItem(context, Icons.history,
                                  lang.translate('mod_hist'), 8, isDark),
                              _modernItem(context, Icons.info_outline,
                                  lang.translate('mod_about'), 9, isDark),
                              _modernItem(context, Icons.auto_awesome,
                                  lang.translate('mod_ai'), 10, isDark),
                              _modernItem(context, Icons.currency_bitcoin,
                                  lang.translate('mod_chart'), 11, isDark),
                              _modernItem(context, Icons.map_outlined,
                                  lang.translate('weather_title'), 12, isDark),
                              _modernItem(context, Icons.settings,
                                  lang.translate('settings'), 13, isDark)
                            ])),
                        crossFadeState: _isUpgradeExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300)),
                    Divider(color: isDark ? Colors.white10 : Colors.black12),
                    ListTile(
                        onTap: () => setState(
                            () => _isPaleHaxExpanded = !_isPaleHaxExpanded),
                        leading:
                            Icon(Icons.sports_soccer, color: Colors.cyanAccent),
                        title: Text("PaleHax",
                            style: GoogleFonts.poppins(
                                color: isDark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold)),
                        trailing: Icon(
                            _isPaleHaxExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: isDark ? Colors.white54 : Colors.black45)),
                    AnimatedCrossFade(
                        firstChild: Container(),
                        secondChild: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Column(children: [
                              _modernItem(
                                  context, Icons.home, "Anasayfa", 14, isDark),
                              _modernItem(context, Icons.groups, "Oyuncular",
                                  15, isDark),
                              _modernItem(context, Icons.table_chart_rounded,
                                  "Puan Durumu", 16, isDark),
                              _modernItem(context, Icons.emoji_events,
                                  "Challenge", 17, isDark),
                              _modernItem(context, Icons.construction,
                                  "Kadro Kur", 18, isDark),
                              // YENİ BUTONLAR
                              _modernItem(context, Icons.list_alt, "Tier List",
                                  19, isDark),
                              _modernItem(context, Icons.sports_soccer,
                                  "Ultimate", 20, isDark),
                              _modernItem(
                                  context, Icons.games, "Oyunlar", 21, isDark),
                            ])),
                        crossFadeState: _isPaleHaxExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300)),
                  ]))),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: GlowingKeyButton(
                          onTap: () => showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) =>
                                  const HackerLoginDialog()))),
                ]))));
  }

  Widget _modernItem(BuildContext context, IconData icon, String label,
      int index, bool isDark) {
    bool isSelected = widget.selectedIndex == index;
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
                    left: BorderSide(
                        color: Theme.of(context).primaryColor, width: 3))
                : null),
        child: ListTile(
            onTap: () => widget.onIndexChanged(index),
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13)),
            hoverColor: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))));
  }
}

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
                          shaderCallback: (b) => const LinearGradient(colors: [
                                Colors.orange,
                                Colors.purple,
                                Colors.blue
                              ]).createShader(b),
                          child:
                              Icon(widget.icon, size: 30, color: Colors.white))
                      : Icon(widget.icon, size: 28, color: color),
                  const SizedBox(height: 5),
                  Text(widget.label,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (widget.isSelected || _hover)
                              ? (widget.isDark ? Colors.white : Colors.black)
                              : color),
                      textAlign: TextAlign.center)
                ]))));
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
