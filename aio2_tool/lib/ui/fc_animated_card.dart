import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart'; // teamLogos, Player, PlayStyle buradan gelir

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

    String type = widget.player.cardType;
    if (_hasGif(type)) {
      _loopController.repeat();
    } else if (!widget.animateOnHover && type != "Temel") {
      _loopController.repeat();
    }
    if (!widget.animateOnHover && type != "Temel") {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _isHovering = hover);
      if (hover) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Player p = widget.player;
    String type = p.cardType;
    bool isBad = type == "BAD";
    bool isBasic = type == "Temel";
    Map<String, int> cs = p.getCardStats();

    PlayStyle? goldPs;
    if (p.playstyles.isNotEmpty) {
      goldPs = p.playstyles
          .firstWhere((ps) => ps.isGold, orElse: () => p.playstyles.first);
    }

    Color borderColor = _getBorderColor(type);
    String? teamLogo = teamLogos[p.team];

    // --- BURASI KRİTİK DEĞİŞİKLİK ---
    // FittedBox sayesinde kartı 350x480 olarak tasarlıyoruz ama her yere sığıyor.
    return FittedBox(
      fit: BoxFit.contain, // Ebeveynin boyutuna orantılı sığdır
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
                  width: 350, // ESKİ SABİT GENİŞLİK
                  height: 480, // ESKİ SABİT YÜKSEKLİK
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 320,
                        height: 480,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(width: 2, color: borderColor),
                            gradient: _getBgGradient(type),
                            boxShadow: isBasic
                                ? []
                                : [
                                    BoxShadow(
                                        color: _getGlowColor(type).withOpacity(
                                            _pulseController.value * 0.3 + 0.1),
                                        blurRadius: isBad ? 5 : 25,
                                        spreadRadius: isBad ? 0 : 3)
                                  ]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(children: [
                            if (_hasGif(type))
                              Positioned.fill(
                                  child: Opacity(
                                      opacity:
                                          type == "BALLOND'OR" ? 0.15 : 0.5,
                                      child: Image.asset(_getGif(type),
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              Container()))),
                            if (!_hasGif(type) && !isBasic)
                              _buildCodeEffects(type),

                            // Parlama Efekti
                            if (!isBasic &&
                                !isBad &&
                                (type == "TOTS" ||
                                    type == "BALLOND'OR" ||
                                    type == "STAR"))
                              Positioned.fill(
                                  child: ShaderMask(
                                      shaderCallback: (bounds) => SweepGradient(
                                              transform: GradientRotation(
                                                  _loopController.value *
                                                      4 *
                                                      pi),
                                              colors: _getShaderColors(type))
                                          .createShader(bounds),
                                      child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(width: 3, color: Colors.white.withOpacity(0.15)))))),

                            // İçerik
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Stack(children: [
                                // Kart Tipi Başlığı
                                if (!isBasic)
                                  Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: Center(
                                          child: Text(
                                              isBad
                                                  ? "BAD"
                                                  : type.toUpperCase(),
                                              style: GoogleFonts.orbitron(
                                                  color: _getTitleColor(type),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                  letterSpacing: 3,
                                                  shadows: [
                                                    const Shadow(
                                                        color: Colors.black,
                                                        blurRadius: 5)
                                                  ])))),

                                // Takım Logosu
                                Positioned(
                                    top: 40,
                                    left: 0,
                                    child: (teamLogo != null &&
                                            teamLogo.isNotEmpty)
                                        ? Image.asset(teamLogo,
                                            width: 35,
                                            height: 35,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.sports_soccer,
                                                    color: Colors.white70))
                                        : const Icon(Icons.sports_soccer,
                                            color: Colors.white70, size: 30)),

                                // Palehax Logo
                                Positioned(
                                    top: 40,
                                    right: 0,
                                    child: Image.asset(
                                        "assets/takimlar/palehax.png",
                                        width: 35,
                                        height: 35,
                                        errorBuilder: (c, e, s) => Icon(
                                            isBad
                                                ? Icons.thumb_down
                                                : Icons.shield,
                                            color: Colors.white70,
                                            size: 30))),

                                // Reyting ve Pozisyon
                                Positioned(
                                    top: 80,
                                    left: 0,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text("${p.rating}",
                                              style: GoogleFonts.orbitron(
                                                  fontSize: 45,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  height: 1)),
                                          Text(
                                              p.position.replaceAll(
                                                  RegExp(r'[^A-Z]'), ''),
                                              style: GoogleFonts.montserrat(
                                                  fontSize: 20,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.bold))
                                        ])),

                                // Forma No ve Yıldızlar
                                Positioned(
                                    top: 80,
                                    right: 5,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text("${p.kitNumber}",
                                              style: GoogleFonts.russoOne(
                                                  fontSize: 60,
                                                  color: Colors.white12)),
                                          if (!isBad && !isBasic)
                                            Row(
                                                children: List.generate(
                                                    p.getCardTierStars(),
                                                    (i) => Icon(Icons.star,
                                                        color: borderColor,
                                                        size: 14)))
                                        ])),

                                // İsim
                                Positioned(
                                    top: 190,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                        child: Text(p.name.toUpperCase(),
                                            style: GoogleFonts.orbitron(
                                                fontSize: 26,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2),
                                            overflow: TextOverflow.ellipsis))),

                                // İstatistikler (kaleci farklı gösterim)
                                Positioned(
                                    top: 250,
                                    left: 10,
                                    right: 10,
                                    child: Column(children: [
                                      const Divider(color: Colors.white30),
                                      const SizedBox(height: 10),
                                      if (p.position.contains("GK") ||
                                          cs.containsKey("REF"))
                                        // GK layout
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
                                                    type,
                                                    isBad),
                                                _cStat("1v1", cs["1v1"] ?? 50,
                                                    type, isBad)
                                              ]),
                                          const SizedBox(height: 5),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _cStat("DIV", cs["DIV"] ?? 50,
                                                    type, isBad),
                                                _cStat("HAN", cs["HAN"] ?? 50,
                                                    type, isBad)
                                              ]),
                                          const SizedBox(height: 5),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _cStat(
                                                    "KIC",
                                                    cs["KIC"] ??
                                                        cs["Güç"] ??
                                                        50,
                                                    type,
                                                    isBad),
                                                _cStat(
                                                    "POS",
                                                    cs["POS"] ??
                                                        cs["Pozisyon Alma"] ??
                                                        50,
                                                    type,
                                                    isBad)
                                              ])
                                        ])
                                      else
                                        // Field player layout
                                        Column(children: [
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _cStat("PAC", cs["PAC"]!, type,
                                                    isBad),
                                                _cStat("DRI", cs["DRI"]!, type,
                                                    isBad)
                                              ]),
                                          const SizedBox(height: 5),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _cStat("SHO", cs["SHO"]!, type,
                                                    isBad),
                                                _cStat("DEF", cs["DEF"]!, type,
                                                    isBad)
                                              ]),
                                          const SizedBox(height: 5),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                _cStat("PAS", cs["PAS"]!, type,
                                                    isBad),
                                                _cStat("PHY", cs["PHY"]!, type,
                                                    isBad)
                                              ])
                                        ]),
                                      const SizedBox(height: 15),
                                      const Divider(color: Colors.white30)
                                    ])),

                                // Kimya ve Rol
                                Positioned(
                                    bottom: 10,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.science,
                                              color: Colors.white60, size: 14),
                                          const SizedBox(width: 5),
                                          Text(
                                              "${p.chemistryStyle} • ${p.role}"
                                                  .toUpperCase(),
                                              style: GoogleFonts.montserrat(
                                                  color: Colors.white60,
                                                  letterSpacing: 1,
                                                  fontSize: 10))
                                        ]))
                              ]),
                            ),

                            // PlayStyle Plus İkonu
                            if (goldPs != null && !isBad && !isBasic)
                              Positioned(
                                  left: -5,
                                  top: 220,
                                  child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.amber, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.amber
                                                    .withOpacity(0.5),
                                                blurRadius: 10)
                                          ]),
                                      child: Image.asset(
                                          goldPs.isGold
                                              ? "assets/Playstyles/plus/${goldPs.name}Plus.png"
                                              : goldPs.assetPath,
                                          width: 30,
                                          height: 30,
                                          errorBuilder: (c, e, s) => const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 20)))),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      ),
    );
  }

  Widget _cStat(String l, int v, String t, bool bad) => Row(children: [
        Text("$v",
            style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(width: 5),
        Text(l,
            style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white70))
      ]);

  bool _hasGif(String t) =>
      ["TOTS", "BALLOND'OR", "MVP", "TOTM", "STAR"].contains(t);

  String _getGif(String t) {
    switch (t) {
      case "TOTS":
        return "assets/gifs/tots_effect.gif";
      case "BALLOND'OR":
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
      case "BALLOND'OR":
        return Colors.amberAccent;
      case "BAD":
        return Colors.pinkAccent;
      case "TOTS":
        return Colors.cyanAccent;
      case "STAR":
        return Colors.cyan;
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
      case "BALLOND'OR":
        return Colors.amber;
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
      case "BALLOND'OR":
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
      default:
        return const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)]);
    }
  }

  List<Color> _getShaderColors(String t) {
    if (t == "BALLOND'OR") return [Colors.amber, Colors.white, Colors.amber];
    if (t == "TOTS") return [Colors.blue, Colors.cyanAccent, Colors.blue];
    if (t == "STAR") return [Colors.cyan, Colors.white, Colors.cyan];
    return [Colors.white, Colors.grey, Colors.white];
  }
}
