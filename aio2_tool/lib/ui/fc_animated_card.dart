import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart'; // teamLogos, Player, PlayStyle buradan gelir

// Dosya isimleri eşleştirme haritası (Türkçe karakter ve boşluksuz)
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

    // TÜM GOLD PLAYSTYLE'LARI AL (İstiflemek için)
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
      "TOTS ICON"
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
                              if (_hasGif(normalizedType))
                                Positioned(
                                    top: 12,
                                    left: 10,
                                    right: 10,
                                    bottom: 12,
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Opacity(
                                            opacity:
                                                normalizedType == "BALLONDOR"
                                                    ? 0.12
                                                    : 0.3,
                                            child: Image.asset(
                                                _getGif(normalizedType),
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) =>
                                                    Container())))),
                              if (!_hasGif(normalizedType) && !isBasic)
                                _buildCodeEffects(normalizedType),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40.0, vertical: 22.0),
                                child: Stack(children: [
                                  // --- KART TİPİ BAŞLIĞI ---
                                  if (!isBasic)
                                    Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                            child: Text(
                                                isBad
                                                    ? "BAD"
                                                    : _displayCardTitle(
                                                        normalizedType),
                                                style: GoogleFonts.orbitron(
                                                    color: _getTitleColor(
                                                        normalizedType),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 13,
                                                    letterSpacing: 2.5,
                                                    shadows: [
                                                      Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.7),
                                                          blurRadius: 6)
                                                    ]))))
                                  else
                                    Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                            child: Text("TEMEL",
                                                style: GoogleFonts.orbitron(
                                                    color:
                                                        const Color(0xFF444444),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 13,
                                                    letterSpacing: 2.5)))),
                                  // --- LOGOLAR ---
                                  Positioned(
                                      top: 32,
                                      left: 8,
                                      child: (teamLogo != null &&
                                              teamLogo.isNotEmpty)
                                          ? Image.asset(teamLogo,
                                              width: 26,
                                              height: 26,
                                              errorBuilder: (c, e, s) => Icon(
                                                  Icons.sports_soccer,
                                                  color: subTextColor,
                                                  size: 22))
                                          : Icon(Icons.sports_soccer,
                                              color: subTextColor, size: 22)),
                                  Positioned(
                                      top: 32,
                                      right: 8,
                                      child: Image.asset(
                                          "assets/takimlar/palehax.png",
                                          width: 26,
                                          height: 26,
                                          errorBuilder: (c, e, s) => Icon(
                                              isBad
                                                  ? Icons.thumb_down
                                                  : Icons.shield,
                                              color: subTextColor,
                                              size: 22))),
                                  // --- RATING & POZİSYON ---
                                  Positioned(
                                      top: 62,
                                      left: 12,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text("${p.rating}",
                                                style: GoogleFonts.oswald(
                                                    fontSize: 42,
                                                    fontWeight: FontWeight.w700,
                                                    color: mainTextColor,
                                                    height: 1)),
                                            Text(
                                                p.position.replaceAll(
                                                    RegExp(r'[^A-Z]'), ''),
                                                style: GoogleFonts.oswald(
                                                    fontSize: 17,
                                                    color: subTextColor,
                                                    fontWeight:
                                                        FontWeight.w500))
                                          ])),
                                  // --- KIT NUMARASI ---
                                  Positioned(
                                      top: 62,
                                      right: 8,
                                      child: Text("${p.kitNumber}",
                                          style: GoogleFonts.russoOne(
                                              fontSize: 46,
                                              color: isDarkTextCard
                                                  ? Colors.black
                                                      .withOpacity(0.06)
                                                  : Colors.white
                                                      .withOpacity(0.06)))),
                                  // --- İSİM ---
                                  Positioned(
                                      top: 170,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                          child: Text(p.name.toUpperCase(),
                                              style: GoogleFonts.oswald(
                                                  fontSize: 23,
                                                  color: mainTextColor,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.5),
                                              overflow:
                                                  TextOverflow.ellipsis))),
                                  // --- STATLAR ---
                                  Positioned(
                                      top: 220,
                                      left: 4,
                                      right: 4,
                                      child: Column(children: [
                                        Divider(
                                            color: isDarkTextCard
                                                ? Colors.black.withOpacity(0.15)
                                                : Colors.white
                                                    .withOpacity(0.15),
                                            thickness: 0.5),
                                        const SizedBox(height: 4),
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
                                                      "ÇİZ",
                                                      cs["ÇİZ"] ?? 50,
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
                                        const SizedBox(height: 6),
                                        Divider(
                                            color: isDarkTextCard
                                                ? Colors.black.withOpacity(0.15)
                                                : Colors.white
                                                    .withOpacity(0.15),
                                            thickness: 0.5)
                                      ])),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // --- INFO TEXT (kartın dışında, altta) ---
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
                                    style: GoogleFonts.montserrat(
                                        color: const Color(0xFFAAAAAA),
                                        letterSpacing: 1,
                                        fontSize: 9))
                              ])),
                      // --- PLAYSTYLE PLUS İKONLARI (İSTİFLENMİŞ) ---
                      if (goldPsList.isNotEmpty && !isBad && !isBasic)
                        ...List.generate(goldPsList.length, (index) {
                          var ps = goldPsList[index];
                          // Her birini biraz aşağı kaydırarak üst üste bindir
                          return Positioned(
                              left: -10,
                              top: 215.0 +
                                  (index * 35), // 35px aralıkla aşağı in
                              child: Image.asset(
                                  "assets/Playstyles/${playStyleFileMap[ps.name.trim()] ?? ps.name.trim()}Plus.png",
                                  width: 45,
                                  height: 45,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 35)));
                        }),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _cStat(String l, int v, Color valueColor, Color labelColor) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text("$v",
            style: GoogleFonts.oswald(
                fontSize: 19, fontWeight: FontWeight.w600, color: valueColor)),
        const SizedBox(width: 3),
        Text(l,
            style: GoogleFonts.montserrat(
                fontSize: 11, fontWeight: FontWeight.w600, color: labelColor))
      ]);

  bool _hasGif(String t) =>
      ["TOTS", "BALLONDOR", "MVP", "TOTM", "STAR"].contains(t);

  String _displayCardTitle(String t) {
    if (t == "BALLONDOR") return "BALLON D'OR";
    if (t == "ELO CHAMPION") return "ELO CHAMP";
    if (t == "FUNCUP CHAMPION") return "FUNCUP";
    if (t == "EVOLUTION PLUS") return "EVO+";
    return t;
  }

  String _getGif(String t) {
    switch (t) {
      case "TOTS":
        return "assets/gifs/tots_effect.gif";
      case "BALLONDOR":
        return "assets/gifs/ballondor_effect.gif";
      case "MVP":
        return "assets/gifs/mvp_effect.gif";
      case "STAR":
        return "assets/gifs/star_effect.gif";
      case "TOTM":
        return "assets/gifs/totm_effect.gif";
      default:
        return "";
    }
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

  Color _getGlowColor(String t) {
    if (t == "BAD") return Colors.red;
    if (t == "MVP") return Colors.deepOrange;
    if (t == "STAR") return Colors.cyan;
    return _getBorderColor(t);
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

  LinearGradient _getBgGradient(String t) {
    switch (t) {
      case "TOTW":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35)]);
      case "TOTM":
        return const LinearGradient(
            colors: [Color(0xFF2E001F), Color(0xFFC2185B)]);
      case "MVP":
        return const LinearGradient(colors: [Colors.black, Color(0xFFB71C1C)]);
      case "BALLONDOR":
        return const LinearGradient(
            colors: [Color(0xFF8E6E1D), Colors.black, Color(0xFFF8D568)]);
      case "BAD":
        return const LinearGradient(
            colors: [Color(0xFFF48FB1), Color(0xFFD32F2F)]);
      case "TOTS":
        return const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF311B92)]);
      case "STAR":
        return const LinearGradient(
            colors: [Color(0xFF000046), Color(0xFF1CB5E0)]);
      case "ICON":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35), Color(0xFFFFD700)]);
      case "RAMADAN":
        return const LinearGradient(
            colors: [Color(0xFF1A0033), Color(0xFF2E001F), Color(0xFF8B00FF)]);
      case "FUTURE STARS":
        return const LinearGradient(
            colors: [Color(0xFF001a33), Color(0xFF003366), Color(0xFF00FFFF)]);
      case "FANTASY":
        return const LinearGradient(
            colors: [Color(0xFF0D001A), Color(0xFF2D0A3D), Color(0xFFFF00FF)]);
      case "WINTER":
        return const LinearGradient(
            colors: [Color(0xFF001a1a), Color(0xFF003333), Color(0xFF00FF7F)]);
      case "HEROES":
        return const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF330000), Color(0xFFFF0000)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)]);
    }
  }

  List<Color> _getShaderColors(String t) {
    if (t == "BALLONDOR") return [Colors.amber, Colors.white, Colors.amber];
    if (t == "TOTS") return [Colors.blue, Colors.cyanAccent, Colors.blue];
    if (t == "STAR") return [Colors.cyan, Colors.white, Colors.cyan];
    if (t == "ICON") return [Colors.amber, Colors.white, Colors.amber];
    if (t == "RAMADAN")
      return [
        const Color(0xFF8B00FF),
        const Color(0xFFFFD700),
        const Color(0xFF8B00FF)
      ];
    if (t == "FUTURE STARS")
      return [const Color(0xFF00FFFF), Colors.white, const Color(0xFF00FFFF)];
    if (t == "FANTASY")
      return [
        const Color(0xFFFF00FF),
        const Color(0xFFFF69B4),
        const Color(0xFFFF00FF)
      ];
    if (t == "WINTER")
      return [const Color(0xFF00FF7F), Colors.white, const Color(0xFF00FF7F)];
    if (t == "HEROES")
      return [
        const Color(0xFFFF0000),
        const Color(0xFFFFD700),
        const Color(0xFFFF0000)
      ];
    return [Colors.white, Colors.grey, Colors.white];
  }
}
