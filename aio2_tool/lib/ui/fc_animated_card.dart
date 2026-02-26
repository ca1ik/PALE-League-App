import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart'; // teamLogos, Player, PlayStyle buradan gelir

// Dosya isimleri eÅŸleÅŸtirme haritasÄ± (TÃ¼rkÃ§e karakter ve boÅŸluksuz)
final Map<String, String> playStyleFileMap = {
  "GameChanger": "OyunKurucu",
  "Acrobatic": "Akrobatik",
  "PowerShot": "SertSut",
  "FinesseShot": "Plase",
  "IncisivePass": "KeskinPas",
  "PingedPass": "AdreseTeslim",
  "LongBallPass": "UzunPas",
  "TikiTaka": "TikiTaka",
  "WhippedPass": "KesmePas",
  "Inventive": "Yaratici",
  "Jockey": "Bariyer",
  "Block": "Blok",
  "Intercept": "TopKesici",
  "Anticipate": "Sezgici",
  "Bruiser": "Kavgaci",
  "AerialFortress": "HavaHakimiyeti",
  "Technical": "Teknik",
  "Rapid": "Ani",
  "FirstTouch": "IlkDokunus",
  "Trickster": "Hilebaz",
  "PressProven": "BaskiyaDayanikli",
  "QuickStep": "CabukAdim",
  "FarReach": "UzakErisim",
  "Footwork": "AyakHareketleri",
  "CrossClaimer": "CaprazMuhafiz",
  "RushOut": "DisariyaTerk",
  "SlideTackle": "KayarakMudahale"
};

class FCAnimatedCard extends StatefulWidget {
  final Player player;
  final bool animateOnHover;
  const FCAnimatedCard(
      {super.key, required this.player, this.animateOnHover = false});
  @override
  State<FCAnimatedCard> createState() => _FCAnimatedCardState();
}

class _FCAnimatedCardState extends State<FCAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _loopController;
  late AnimationController _pulseController;
  final List<double> _randomX = List.generate(50, (i) => Random().nextDouble());
  final List<double> _randomSpeed =
      List.generate(50, (i) => 0.5 + Random().nextDouble() * 0.5);
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _loopController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    String type = normalizeCardType(widget.player.cardType);
    if (_hasGif(type)) {
      _loopController.repeat();
    } else if (!widget.animateOnHover && type != "TEMEL") {
      _loopController.repeat();
    }
    if (!widget.animateOnHover && type != "TEMEL") {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _loopController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleHover(bool hover) {
    if (!widget.animateOnHover || widget.player.cardType == "Temel") return;
    if (!mounted) return;
    setState(() => _isHovering = hover);
    if (hover) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Player p = widget.player;
    final String normalizedType = normalizeCardType(p.cardType);
    bool isBad = normalizedType == "BAD";
    bool isBasic = normalizedType == "TEMEL";
    final String cardBgAsset =
        cardTypeToAssetPath(normalizedType) ?? "assets/cards/s/Temel.png";
    Map<String, int> cs = p.getCardStats();

    // TÃœM GOLD PLAYSTYLE'LARI AL (Ä°stiflemek iÃ§in)
    List<PlayStyle> goldPsList = [];
    try {
      goldPsList = p.playstyles.where((ps) => ps.isGold).toList();
    } catch (e) {
      // Hata yok
    }

    String? teamLogo = teamLogos[p.team];

    // Koyu metin gereken kart tipleri
    final bool isDarkTextCard = [
      "TEMEL",
      "ICON",
      "FUTURE STARS",
      "MIDFIELDER",
      "ELO CHAMPION",
      "IQ",
      "KING",
      "TOTS ICON",
      "CLASSIC VII",
      "DREAMCHASERS",
      "BIRTHDAY",
      "AWARD WINNERS"
    ].contains(normalizedType);

    // Metin renkleri
    final Color mainTextColor =
        isDarkTextCard ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8);
    final Color subTextColor =
        isDarkTextCard ? const Color(0xFF333333) : const Color(0xFFCCCCCC);
    final Color statValueColor =
        isDarkTextCard ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8);
    final Color statLabelColor =
        isDarkTextCard ? const Color(0xFF444444) : const Color(0xFFBBBBBB);

    return FittedBox(
      fit: BoxFit.contain,
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: AnimatedBuilder(
            animation: Listenable.merge([_loopController, _pulseController]),
            builder: (context, child) {
              return AnimatedScale(
                scale: _isHovering ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: 340,
                  height: 500,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // --- ARKA PLAN ---
                      SizedBox(
                        width: 340,
                        height: 480,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                  child: Image.asset(cardBgAsset,
                                      fit: BoxFit.fill,
                                      errorBuilder: (c, e, s) =>
                                          const SizedBox.shrink())),
                              if (!isBasic) _buildCodeEffects(normalizedType),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 38.0, vertical: 18.0),
                                child: Stack(children: [
                                  // --- KART TÄ°PÄ° BAÅLIÄI ---
                                  Positioned(
                                      top: 4,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                          child: Text(
                                              isBasic
                                                  ? "TEMEL"
                                                  : (isBad
                                                      ? "BAD"
                                                      : _displayCardTitle(
                                                          normalizedType)),
                                              style: GoogleFonts.orbitron(
                                                  color: isBasic
                                                      ? const Color(0xFF444444)
                                                      : _getTitleColor(
                                                          normalizedType),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 12,
                                                  letterSpacing: 2.0,
                                                  shadows: isBasic
                                                      ? []
                                                      : [
                                                          Shadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.8),
                                                              blurRadius: 8)
                                                        ])))),
                                  // --- LOGOLAR (reytingin hemen üstünde) ---
                                  Positioned(
                                      top: 82,
                                      left: 10,
                                      child: (teamLogo != null &&
                                              teamLogo.isNotEmpty)
                                          ? Image.asset(teamLogo,
                                              width: 22,
                                              height: 22,
                                              errorBuilder: (c, e, s) => Icon(
                                                  Icons.sports_soccer,
                                                  color: subTextColor,
                                                  size: 18))
                                          : Icon(Icons.sports_soccer,
                                              color: subTextColor, size: 18)),
                                  Positioned(
                                      top: 82,
                                      right: 10,
                                      child: Image.asset(
                                          "assets/takimlar/palehax.png",
                                          width: 22,
                                          height: 22,
                                          errorBuilder: (c, e, s) => Icon(
                                              isBad
                                                  ? Icons.thumb_down
                                                  : Icons.shield,
                                              color: subTextColor,
                                              size: 18))),
                                  // --- KART TİPİ (logolar arası orta) ---
                                  Positioned(
                                      top: 82,
                                      left: 0,
                                      right: 0,
                                      height: 22,
                                      child: Center(
                                          child: Text(
                                              isBasic
                                                  ? "TEMEL"
                                                  : (isBad
                                                      ? "BAD"
                                                      : _displayCardTitle(
                                                          normalizedType)),
                                              style: GoogleFonts.orbitron(
                                                  color: isBasic
                                                      ? subTextColor
                                                      : _getTitleColor(
                                                          normalizedType),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 10,
                                                  letterSpacing: 1.8,
                                                  shadows: _buildTitleLedShadows(
                                                      _getTitleColor(
                                                          normalizedType)))))),
                                  // --- RATING & POZİSYON ---
                                  Positioned(
                                      top: 108,
                                      left: 14,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("${p.rating}",
                                                style: GoogleFonts.orbitron(
                                                    fontSize: 42,
                                                    fontWeight: FontWeight.w400,
                                                    color: mainTextColor,
                                                    height: 1,
                                                    letterSpacing: 2,
                                                    shadows: _ledShadows(
                                                        isDarkTextCard))),
                                            Text(
                                                p.position.replaceAll(
                                                    RegExp(r'[^A-Z]'), ''),
                                                style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    color: subTextColor,
                                                    letterSpacing: 1.5,
                                                    fontWeight:
                                                        FontWeight.w700))
                                          ])),
                                  // --- KIT NUMARASI ---
                                  Positioned(
                                      top: 108,
                                      right: 8,
                                      child: Text("${p.kitNumber}",
                                          style: GoogleFonts.outfit(
                                              fontSize: 40,
                                              fontWeight: FontWeight.w800,
                                              color: isDarkTextCard
                                                  ? Colors.black
                                                      .withOpacity(0.05)
                                                  : Colors.white
                                                      .withOpacity(0.05)))),
                                  // --- İSİM ---
                                  Positioned(
                                      top: 194,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                          child: Text(p.name.toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                  fontSize: 20,
                                                  color: isDarkTextCard
                                                      ? _getTitleColor(
                                                          normalizedType)
                                                      : mainTextColor,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 2.5,
                                                  shadows: _buildNameLedShadows(
                                                      _getTitleColor(
                                                          normalizedType),
                                                      isDarkTextCard)),
                                              overflow:
                                                  TextOverflow.ellipsis))),
                                  // --- STATLAR ---
                                  Positioned(
                                      top: 248,
                                      left: 6,
                                      right: 6,
                                      child: Column(children: [
                                        Divider(
                                            color: isDarkTextCard
                                                ? Colors.black.withOpacity(0.12)
                                                : Colors.white
                                                    .withOpacity(0.12),
                                            thickness: 0.5),
                                        const SizedBox(height: 3),
                                        if (p.position.contains("GK") ||
                                            cs.containsKey("REF"))
                                          Column(children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _cStat(
                                                      "REF",
                                                      cs["REF"] ??
                                                          cs["Refleks"] ??
                                                          50,
                                                      statValueColor,
                                                      statLabelColor),
                                                  _cStat(
                                                      "1v1",
                                                      cs["1v1"] ?? 50,
                                                      statValueColor,
                                                      statLabelColor)
                                                ]),
                                            const SizedBox(height: 5),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _cStat(
                                                      "Ã‡Ä°Z",
                                                      cs["Ã‡Ä°Z"] ?? 50,
                                                      statValueColor,
                                                      statLabelColor),
                                                  _cStat(
                                                      "POZ",
                                                      cs["POZ"] ?? 50,
                                                      statValueColor,
                                                      statLabelColor)
                                                ]),
                                            const SizedBox(height: 5),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _cStat(
                                                      "KAR",
                                                      cs["KAR"] ?? 50,
                                                      statValueColor,
                                                      statLabelColor),
                                                  _cStat(
                                                      "PAS",
                                                      cs["PAS"] ?? 50,
                                                      statValueColor,
                                                      statLabelColor)
                                                ])
                                          ])
                                        else
                                          Column(children: [
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _cStat(
                                                      "PAC",
                                                      cs["PAC"]!,
                                                      statValueColor,
                                                      statLabelColor),
                                                  _cStat(
                                                      "DRI",
                                                      cs["DRI"]!,
                                                      statValueColor,
                                                      statLabelColor)
                                                ]),
                                            const SizedBox(height: 5),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _cStat(
                                                      "SHO",
                                                      cs["SHO"]!,
                                                      statValueColor,
                                                      statLabelColor),
                                                  _cStat(
                                                      "DEF",
                                                      cs["DEF"]!,
                                                      statValueColor,
                                                      statLabelColor)
                                                ]),
                                            const SizedBox(height: 5),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  _cStat(
                                                      "PAS",
                                                      cs["PAS"]!,
                                                      statValueColor,
                                                      statLabelColor),
                                                  _cStat(
                                                      "PHY",
                                                      cs["PHY"]!,
                                                      statValueColor,
                                                      statLabelColor)
                                                ])
                                          ]),
                                        const SizedBox(height: 3),
                                        Divider(
                                            color: isDarkTextCard
                                                ? Colors.black.withOpacity(0.12)
                                                : Colors.white
                                                    .withOpacity(0.12),
                                            thickness: 0.5),
                                        // --- SKILL STARS & WEAK FOOT ---
                                        const SizedBox(height: 2),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text("${p.skillMoves}",
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isDarkTextCard
                                                          ? const Color(
                                                              0xFFB8860B)
                                                          : Colors.amber,
                                                      shadows: _ledShadows(
                                                          isDarkTextCard))),
                                              const SizedBox(width: 2),
                                              Icon(Icons.star_rounded,
                                                  color: isDarkTextCard
                                                      ? const Color(0xFFB8860B)
                                                      : Colors.amber,
                                                  size: 13),
                                              const SizedBox(width: 14),
                                              Text("${p.stats['WF'] ?? 3}",
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: statValueColor,
                                                      shadows: _ledShadows(
                                                          isDarkTextCard))),
                                              const SizedBox(width: 2),
                                              Icon(Icons.sports_soccer_outlined,
                                                  color: statValueColor
                                                      .withOpacity(0.75),
                                                  size: 12),
                                            ]),
                                        const SizedBox(height: 2),
                                      ])),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // --- INFO TEXT (kartÄ±n dÄ±ÅŸÄ±nda, altta) ---
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.science,
                                    color: const Color(0xFFAAAAAA), size: 12),
                                const SizedBox(width: 4),
                                Text(
                                    "${p.chemistryStyle} • ${p.role}"
                                        .toUpperCase(),
                                    style: GoogleFonts.outfit(
                                        color: const Color(0xFFAAAAAA),
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 8.5))
                              ])),
                      // --- PLAYSTYLE PLUS Ä°KONLARI (sol kenar ortasÄ±) ---
                      if (goldPsList.isNotEmpty && !isBad && !isBasic)
                        ...List.generate(goldPsList.length, (index) {
                          var ps = goldPsList[index];
                          double centerY = 240.0;
                          double totalH = goldPsList.length * 32.0;
                          double startY = centerY - totalH / 2;
                          return Positioned(
                              left: -10,
                              top: startY + (index * 32),
                              child: Image.asset(
                                  "assets/Playstyles/${playStyleFileMap[ps.name.trim()] ?? ps.name.trim()}Plus.png",
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 30)));
                        }),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _cStat(String l, int v, Color valueColor, Color labelColor) {
    final bool isDarkText = valueColor.computeLuminance() < 0.35;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text("$v",
          style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
              shadows: _ledShadowsStrong(isDarkText))),
      const SizedBox(width: 3),
      Text(l,
          style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: labelColor,
              letterSpacing: 0.6,
              shadows: _ledShadows(isDarkText)))
    ]);
  }

  // Subtle LED — rating, position, star/wf numbers, stat labels
  List<Shadow> _ledShadows(bool isDark) {
    if (isDark) {
      return [
        Shadow(color: Colors.white, blurRadius: 1),
        Shadow(color: Colors.white.withOpacity(0.95), blurRadius: 4),
        Shadow(color: Colors.white.withOpacity(0.75), blurRadius: 10),
        Shadow(color: Colors.white.withOpacity(0.45), blurRadius: 20),
        Shadow(color: Colors.white.withOpacity(0.2), blurRadius: 32),
      ];
    } else {
      return [
        Shadow(color: Colors.black, blurRadius: 1),
        Shadow(color: Colors.black.withOpacity(1.0), blurRadius: 4),
        Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 10),
        Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
        Shadow(color: Colors.black.withOpacity(0.25), blurRadius: 32),
      ];
    }
  }

  // Title LED — card type label glow (color-matched)
  List<Shadow> _buildTitleLedShadows(Color titleColor) {
    final Color glow = titleColor;
    final Color glowMid = titleColor.withOpacity(0.8);
    final Color glowSoft = titleColor.withOpacity(0.5);
    return [
      Shadow(color: Colors.black, blurRadius: 1),
      Shadow(color: glow, blurRadius: 3),
      Shadow(color: glow, blurRadius: 8),
      Shadow(color: glowMid, blurRadius: 16),
      Shadow(color: glowSoft, blurRadius: 28),
      Shadow(color: glowSoft, blurRadius: 40),
    ];
  }

  // Name LED — most intense; card-color tinted glow + contrast outline
  List<Shadow> _buildNameLedShadows(Color cardColor, bool isDark) {
    final Color glow = cardColor.withOpacity(1.0);
    final Color glowMid = cardColor.withOpacity(0.7);
    final Color glowSoft = cardColor.withOpacity(0.4);
    final Color outline =
        isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(1.0);
    return [
      Shadow(color: outline, blurRadius: 1),
      Shadow(color: glow, blurRadius: 4),
      Shadow(color: glow, blurRadius: 8),
      Shadow(color: glowMid, blurRadius: 16),
      Shadow(color: glowSoft, blurRadius: 28),
      Shadow(color: glowSoft, blurRadius: 40),
    ];
  }

  // Strong LED — for stat numbers
  List<Shadow> _ledShadowsStrong(bool isDark) {
    if (isDark) {
      return [
        Shadow(color: Colors.white, blurRadius: 1),
        Shadow(color: Colors.white, blurRadius: 3),
        Shadow(color: Colors.white.withOpacity(0.9), blurRadius: 8),
        Shadow(color: Colors.white.withOpacity(0.6), blurRadius: 16),
        Shadow(color: Colors.white.withOpacity(0.3), blurRadius: 28),
      ];
    } else {
      return [
        Shadow(color: Colors.black, blurRadius: 1),
        Shadow(color: Colors.black, blurRadius: 3),
        Shadow(color: Colors.black.withOpacity(0.95), blurRadius: 8),
        Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 16),
        Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 28),
      ];
    }
  }

  bool _hasGif(String t) => false; // GIF/Video efektler devre dÄ±ÅŸÄ±

  String _displayCardTitle(String t) {
    if (t == "BALLONDOR") return "BALLON D'OR";
    if (t == "ELO CHAMPION") return "ELO CHAMP";
    if (t == "FUNCUP CHAMPION") return "FUNCUP";
    if (t == "EVOLUTION PLUS") return "EVO+";
    return t;
  }

  Widget _buildCodeEffects(String type) {
    if (type == "BAD")
      return Stack(children: [
        Positioned(
            left: (_loopController.value * 400) - 50,
            top: 0,
            bottom: 0,
            child: Container(
                width: 30,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.red.withOpacity(0.3),
                  Colors.transparent
                ], begin: Alignment.centerLeft, end: Alignment.centerRight))))
      ]);
    else if (type == "TOTW")
      return Stack(
          children: List.generate(30, (i) {
        double progress = (_loopController.value * _randomSpeed[i]) % 1.0;
        return Positioned(
            top: progress * 480,
            left: _randomX[i] * 320,
            child: Container(
                width: 2,
                height: 2,
                decoration: const BoxDecoration(
                    color: Colors.amber, shape: BoxShape.circle)));
      }));
    return const SizedBox.shrink();
  }

  Color _getBorderColor(String t) {
    switch (t) {
      case "TOTW":
        return Colors.amber;
      case "TOTM":
        return const Color(0xFFE91E63);
      case "MVP":
        return Colors.redAccent;
      case "BALLONDOR":
        return Colors.amberAccent;
      case "BAD":
        return Colors.pinkAccent;
      case "TOTS":
        return Colors.cyanAccent;
      case "STAR":
        return Colors.cyan;
      case "ICON":
        return const Color(0xFFFFD700);
      case "RAMADAN":
        return const Color(0xFF8B00FF);
      case "FUTURE STARS":
        return const Color(0xFF00FFFF);
      case "FANTASY":
        return const Color(0xFFFF00FF);
      case "WINTER":
        return const Color(0xFF00FF7F);
      case "HEROES":
        return const Color(0xFFFF0000);
      case "THUNDERSTRUCK":
        return const Color(0xFFFFD700);
      case "PCL PRO":
        return const Color(0xFF1E3A8A);
      case "EVOLUTION":
        return const Color(0xFF10B981);
      case "TOTY":
        return const Color(0xFFFFD700);
      case "END OF AN ERA":
        return const Color(0xFF9CA3AF);
      case "STAFF":
        return const Color(0xFF1E40AF);
      case "PCL CHAMPION":
        return const Color(0xFFDC2626);
      case "PEL CHAMPION":
        return const Color(0xFF3B82F6);
      case "PECL CHAMPION":
        return const Color(0xFFF97316);
      case "FUNCUP CHAMPION":
        return const Color(0xFFEC4899);
      case "DRAFT CHAMPION":
        return const Color(0xFF059669);
      case "CLASSIC VII":
        return const Color(0xFF92400E);
      case "TRICKSTER":
        return const Color(0xFFD946EF);
      case "FM PRO":
        return const Color(0xFF047857);
      case "DREAMCHASERS":
        return const Color(0xFF6366F1);
      case "AWARD WINNERS":
        return const Color(0xFFFBBF24);
      case "TEAM TURKEY":
        return const Color(0xFFDC2626);
      case "BIRTHDAY":
        return const Color(0xFFFBBF24);
      case "EVOLUTION PLUS":
        return const Color(0xFF7C3AED);
      case "IQ":
        return const Color(0xFF06B6D4);
      case "KING":
        return const Color(0xFFFFD700);
      case "TOTS ICON":
        return const Color(0xFF38BDF8);
      case "TRAILBRAZERS":
        return const Color(0xFFF97316);
      case "ULTIMATE":
        return const Color(0xFFA78BFA);
      case "VS CHAMPION":
        return const Color(0xFF22C55E);
      default:
        return Colors.white24;
    }
  }

  Color _getTitleColor(String t) {
    switch (t) {
      case "TOTW":
        return Colors.amber;
      case "TOTM":
        return const Color(0xFFF48FB1);
      case "TOTS":
        return Colors.cyanAccent;
      case "BAD":
        return Colors.white;
      case "MVP":
        return Colors.redAccent;
      case "STAR":
        return Colors.cyan;
      case "BALLONDOR":
        return Colors.amber;
      case "ICON":
        return const Color(0xFFFFD700);
      case "RAMADAN":
        return const Color(0xFFFFD700);
      case "FUTURE STARS":
        return const Color(0xFF00FFFF);
      case "FANTASY":
        return const Color(0xFFFF69B4);
      case "WINTER":
        return const Color(0xFF00FF7F);
      case "HEROES":
        return const Color(0xFFFFD700);
      case "EVOLUTION PLUS":
        return const Color(0xFFA78BFA);
      case "IQ":
        return const Color(0xFF67E8F9);
      case "KING":
        return const Color(0xFFFFD700);
      case "TOTS ICON":
        return const Color(0xFF67E8F9);
      case "TRAILBRAZERS":
        return const Color(0xFFF97316);
      case "ULTIMATE":
        return const Color(0xFFC4B5FD);
      case "VS CHAMPION":
        return const Color(0xFF86EFAC);
      default:
        return Colors.white;
    }
  }
}
