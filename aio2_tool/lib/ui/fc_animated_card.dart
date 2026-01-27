import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

class FCAnimatedCard extends StatefulWidget {
  final Player player;
  const FCAnimatedCard({super.key, required this.player});
  @override
  State<FCAnimatedCard> createState() => _FCAnimatedCardState();
}

class _FCAnimatedCardState extends State<FCAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _loopController; // Sonsuz döngü için (Partiküller)
  late AnimationController _pulseController; // Nefes alma efekti için (Glow)

  // Rastgelelik için sabit listeler (Performans için build dışında üretilir)
  final List<double> _randomX = List.generate(50, (i) => Random().nextDouble());
  final List<double> _randomY = List.generate(50, (i) => Random().nextDouble());
  final List<double> _randomSpeed =
      List.generate(50, (i) => 0.5 + Random().nextDouble() * 0.5);

  @override
  void initState() {
    super.initState();
    // Sonsuz lineer döngü (Takılmadan akması için)
    _loopController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    // Glow efekti için nefes alma
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loopController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Player p = widget.player;
    String type = p.cardType;
    bool isBad = type == "BAD";
    bool isBasic = type == "Temel";
    Map<String, int> cs = p.getCardStats();
    PlayStyle? goldPs = p.playstyles.isNotEmpty
        ? p.playstyles
            .firstWhere((ps) => ps.isGold, orElse: () => p.playstyles.first)
        : null;
    Color borderColor = _getBorderColor(type);

    return AnimatedBuilder(
        animation: Listenable.merge([_loopController, _pulseController]),
        builder: (context, child) {
          return SizedBox(
            width: 350,
            height: 480,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // --- KART GÖVDESİ ---
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
                                  blurRadius: isBad
                                      ? 5
                                      : 25, // BAD kartının glowu az olsun
                                  spreadRadius: isBad ? 0 : 3)
                            ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // --- ÖZEL EFEKTLER KATMANI ---
                        if (!isBasic) _buildSpecialEffects(type),

                        // --- SHADER (Sadece Parlak Kartlar) ---
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
                                                  pi), // Yavaşça dönsün
                                          colors: _getShaderColors(type))
                                      .createShader(bounds),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              width: 3,
                                              color: Colors.white
                                                  .withOpacity(0.15)))))),

                        // --- İÇERİK KATMANI ---
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Stack(
                            children: [
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
                                                : type
                                                    .toUpperCase(), // SAKAR yerine BAD
                                            style: isBad
                                                ? GoogleFonts.comicNeue(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)
                                                : GoogleFonts.orbitron(
                                                    color: _getTitleColor(
                                                        type), // İstenen özel renk
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    letterSpacing: 3,
                                                    shadows: [
                                                        Shadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.8),
                                                            blurRadius: 5)
                                                      ])))),

                              // Takım / Ülke Placeholder
                              Positioned(
                                  top: 40,
                                  left: 0,
                                  child: Icon(
                                      isBad
                                          ? Icons.broken_image
                                          : Icons.sports_soccer,
                                      color:
                                          _getTextColor(type).withOpacity(0.7),
                                      size: 30)),
                              Positioned(
                                  top: 40,
                                  right: 0,
                                  child: Icon(
                                      isBad ? Icons.thumb_down : Icons.shield,
                                      color:
                                          _getTextColor(type).withOpacity(0.7),
                                      size: 30)),

                              // Reyting & Pozisyon
                              Positioned(
                                  top: 80,
                                  left: 0,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text("${p.rating}",
                                            style: isBad
                                                ? GoogleFonts.comicNeue(
                                                    fontSize: 45,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)
                                                : GoogleFonts.orbitron(
                                                    fontSize: 45,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getTextColor(type),
                                                    height: 1)),
                                        Text(
                                            p.position.replaceAll(
                                                RegExp(r'[^A-Z]'), ''),
                                            style: isBad
                                                ? GoogleFonts.comicNeue(
                                                    fontSize: 20,
                                                    color: Colors.white70)
                                                : GoogleFonts.montserrat(
                                                    fontSize: 20,
                                                    color: _getTextColor(type)
                                                        .withOpacity(0.8),
                                                    fontWeight:
                                                        FontWeight.bold))
                                      ])),

                              // Forma No & Yıldızlar
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
                                                color: _getTextColor(type)
                                                    .withOpacity(0.15))),
                                        if (!isBad && !isBasic)
                                          Row(
                                              children: List.generate(
                                                  p.getCardTierStars(),
                                                  (i) => Icon(Icons.star,
                                                      color: borderColor,
                                                      size: 14)))
                                      ])),

                              // Oyuncu İsmi
                              Positioned(
                                  top: 190,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                      child: Text(p.name.toUpperCase(),
                                          style: isBad
                                              ? GoogleFonts.comicNeue(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)
                                              : GoogleFonts.orbitron(
                                                  fontSize: 26,
                                                  color: _getTextColor(type),
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2),
                                          overflow: TextOverflow.ellipsis))),

                              // Stats
                              Positioned(
                                  top: 250,
                                  left: 10,
                                  right: 10,
                                  child: Column(children: [
                                    Divider(
                                        color: isBad
                                            ? Colors.white30
                                            : Colors.white30),
                                    const SizedBox(height: 10),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _cStat(
                                              "PAC", cs["PAC"]!, type, isBad),
                                          _cStat("DRI", cs["DRI"]!, type, isBad)
                                        ]),
                                    const SizedBox(height: 5),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _cStat(
                                              "SHO", cs["SHO"]!, type, isBad),
                                          _cStat("DEF", cs["DEF"]!, type, isBad)
                                        ]),
                                    const SizedBox(height: 5),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _cStat(
                                              "PAS", cs["PAS"]!, type, isBad),
                                          _cStat("PHY", cs["PHY"]!, type, isBad)
                                        ]),
                                    const SizedBox(height: 15),
                                    Divider(
                                        color: isBad
                                            ? Colors.white30
                                            : Colors.white30)
                                  ])),

                              // Alt Bilgi
                              Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                            isBad
                                                ? Icons.mood_bad
                                                : Icons.science,
                                            color: _getTextColor(type)
                                                .withOpacity(0.6),
                                            size: 14),
                                        const SizedBox(width: 5),
                                        Text(
                                            "${p.chemistryStyle} • ${p.role}"
                                                .toUpperCase(),
                                            style: GoogleFonts.montserrat(
                                                color: _getTextColor(type)
                                                    .withOpacity(0.6),
                                                letterSpacing: 1,
                                                fontSize: 10))
                                      ]))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                // Playstyle İkonu
                if (goldPs != null && !isBad && !isBasic)
                  Positioned(
                      left: -5,
                      top: 220,
                      child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.amber, width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 15)
                              ]),
                          child: Image.asset(goldPs.assetPath,
                              width: 30,
                              height: 30,
                              errorBuilder: (c, e, s) => const Icon(Icons.star,
                                  color: Colors.amber, size: 30)))),
              ],
            ),
          );
        });
  }

  Widget _cStat(String l, int v, String t, bool bad) => Row(children: [
        Text("$v",
            style: bad
                ? GoogleFonts.comicNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)
                : GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _getTextColor(t))),
        const SizedBox(width: 5),
        Text(l,
            style: bad
                ? GoogleFonts.comicNeue(fontSize: 16, color: Colors.white70)
                : GoogleFonts.montserrat(
                    fontSize: 16, color: _getTextColor(t).withOpacity(0.7)))
      ]);

  // --- EFEKT YÖNETİCİSİ ---
  Widget _buildSpecialEffects(String type) {
    if (type == "BAD") {
      // BAD: Soldan sağa tarayan kırmızı çizgi (Block gibi)
      return Stack(
        children: [
          Positioned(
              // 320 genişlik, 2 saniyede bir tur. -50'den 350'ye
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
                ], begin: Alignment.centerLeft, end: Alignment.centerRight)),
              ))
        ],
      );
    } else if (type == "MVP") {
      // MVP: Çapraz düşen çizgiler (Yağmur gibi ama agresif)
      return Stack(
          children: List.generate(15, (i) {
        // Her çizgi farklı hızda ve konumda
        double startX = _randomX[i] * 320;
        double progress =
            (_loopController.value * (1.5 + _randomSpeed[i])) % 1.0;
        double top = progress * 550 - 50; // Yukarıdan aşağı
        double left =
            startX - (progress * 100); // Hafif sola kayarak düşüş (Çapraz)

        return Positioned(
          top: top,
          left: left,
          child: Transform.rotate(
            angle: 0.5, // Çapraz açı
            child: Container(
              width: 2, height: 40 + _randomY[i] * 40,
              color: Colors.redAccent
                  .withOpacity(0.4 * (1 - progress)), // Aşağı indikçe sön
            ),
          ),
        );
      }));
    } else if (type == "TOTM") {
      // TOTM: Rastgele beliren çizgiler (Glitch/Matrix vari ama pembe)
      return Stack(
          children: List.generate(20, (i) {
        // Opaklık zamanla değişsin (Yanıp sönme)
        double flicker = sin(
                (_loopController.value * 2 * pi * _randomSpeed[i]) +
                    _randomX[i] * 10)
            .abs();
        return Positioned(
            top: _randomY[i] * 480,
            left: _randomX[i] * 320,
            child: Opacity(
              opacity: flicker * 0.6,
              child: Container(
                width: 2,
                height: 20 + _randomSpeed[i] * 30,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.pinkAccent,
                  Colors.transparent
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              ),
            ));
      }));
    } else if (type == "TOTS") {
      // TOTS: Mavi Partiküller (Şimşek/Enerji)
      return Stack(
          children: List.generate(25, (i) {
        double progress = (_loopController.value * _randomSpeed[i]) % 1.0;
        return Positioned(
            top: (progress * 480), // Aşağı akış
            left: _randomX[i] * 320,
            child: Opacity(
                opacity: 1.0 - progress,
                child: const Icon(Icons.bolt,
                    color: Colors.cyanAccent, size: 14)));
      }));
    } else if (type == "BALLOND'OR") {
      // Ballon d'Or: Modern, aşağıdan yukarı süzülen altın ışıltılar
      return Stack(
          children: List.generate(20, (i) {
        double progress =
            (_loopController.value * 0.5 * _randomSpeed[i]) % 1.0; // Yavaş
        return Positioned(
            bottom: progress * 500, // Aşağıdan yukarı
            left: _randomX[i] * 320,
            child: Opacity(
                opacity: sin(
                    progress * pi), // Başta sönük, ortada parlak, sonda sönük
                child: Icon(Icons.auto_awesome,
                    color: Colors.amber, size: 10 + _randomY[i] * 15)));
      }));
    } else if (type == "TOTW") {
      // TOTW: Çok küçük toz zerresi efekti
      return Stack(
          children: List.generate(30, (i) {
        double progress = (_loopController.value * _randomSpeed[i]) % 1.0;
        return Positioned(
            top: progress * 480,
            left: _randomX[i] * 320,
            child: Container(
              width: 2, height: 2, // Çok küçük
              decoration: const BoxDecoration(
                  color: Colors.amber, shape: BoxShape.circle),
            ));
      }));
    }

    // Diğerleri (STAR vb.) için standart yıldız
    return Stack(
        children: List.generate(30, (i) {
      double progress = (_loopController.value * _randomSpeed[i]) % 1.0;
      return Positioned(
          top: progress * 480,
          left: _randomX[i] * 320,
          child: Opacity(
              opacity: 1 - progress,
              child: Icon(Icons.star, color: Colors.cyan, size: 8)));
    }));
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
        return Colors.pinkAccent; // Kırmızı/Pembe
      case "TOTS":
        return Colors.cyanAccent; // Mavi
      case "STAR":
        return Colors.cyan;
      default:
        return Colors.white;
    }
  }

  Color _getGlowColor(String t) {
    if (t == "BAD") return Colors.red;
    if (t == "MVP") return Colors.deepOrange;
    return _getBorderColor(t);
  }

  Color _getTitleColor(String t) {
    // KART İSMİNİN RENGİ (Karta uygun)
    switch (t) {
      case "TOTW":
        return Colors.amber;
      case "TOTM":
        return const Color(0xFFF48FB1); // Açık pembe
      case "TOTS":
        return Colors.cyanAccent; // Mavi
      case "BAD":
        return Colors.white; // BAD için beyaz istendi
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

  Color _getTextColor(String t) {
    // İçerik yazıları her zaman beyaz/açık olsun ki okunsun
    return Colors.white;
  }

  LinearGradient _getBgGradient(String t) {
    switch (t) {
      case "TOTW":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35)],
            begin: Alignment.topLeft);
      case "TOTM":
        return const LinearGradient(
            colors: [Color(0xFF2E001F), Color(0xFFC2185B)],
            begin: Alignment.topLeft); // Koyu Pembe
      case "MVP":
        return const LinearGradient(
            colors: [Colors.black, Color(0xFFB71C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case "BALLOND'OR":
        return const LinearGradient(
            colors: [Color(0xFF8E6E1D), Colors.black, Color(0xFFF8D568)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case "BAD":
        return const LinearGradient(
            colors: [Color(0xFFF48FB1), Color(0xFFB71C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter); // Pembe -> Kırmızı
      case "TOTS":
        return const LinearGradient(
            colors: [Colors.black, Color(0xFF1A237E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter); // Siyah -> Lacivert/Morumsu Mavi
      case "STAR":
        return const LinearGradient(
            colors: [Color(0xFF000046), Color(0xFF1CB5E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      default:
        return const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)],
            begin: Alignment.topLeft);
    }
  }

  List<Color> _getShaderColors(String t) {
    if (t == "BALLOND'OR") return [Colors.amber, Colors.white, Colors.amber];
    if (t == "TOTS") return [Colors.blue, Colors.cyanAccent, Colors.blue];
    if (t == "STAR") return [Colors.cyan, Colors.white, Colors.cyan];
    return [Colors.white, Colors.grey, Colors.white];
  }
}
