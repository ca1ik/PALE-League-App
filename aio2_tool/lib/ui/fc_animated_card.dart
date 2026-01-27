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
  late AnimationController _rgb, _pulse;
  final List<Offset> _stars = List.generate(
      45, (i) => Offset(Random().nextDouble(), Random().nextDouble()));

  @override
  void initState() {
    super.initState();
    int speed = (widget.player.cardType == "TOTS" ||
            widget.player.cardType == "BALLOND'OR")
        ? 3
        : 5;
    _rgb = AnimationController(vsync: this, duration: Duration(seconds: speed))
      ..repeat();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rgb.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Player p = widget.player;
    String type = p.cardType;
    bool isBad = type == "BAD";
    Map<String, int> cs = p.getCardStats();
    PlayStyle? goldPs = p.playstyles.isNotEmpty
        ? p.playstyles
            .firstWhere((ps) => ps.isGold, orElse: () => p.playstyles.first)
        : null;

    return AnimatedBuilder(
        animation: Listenable.merge([_rgb, _pulse]),
        builder: (context, child) {
          return SizedBox(
              width: 350,
              height: 480,
              child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 320,
                      height: 480,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              width: 2, color: _getBorderColor(type)),
                          gradient: _getBgGradient(type),
                          boxShadow: [
                            BoxShadow(
                                color: _getGlowColor(type)
                                    .withOpacity(_pulse.value * 0.4 + 0.1),
                                blurRadius: isBad ? 10 : 30,
                                spreadRadius: isBad ? 2 : 5)
                          ]),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(children: [
                            _buildParticles(type),
                            if (type == "TOTS" || type == "BALLOND'OR")
                              Positioned.fill(
                                  child: ShaderMask(
                                      shaderCallback: (bounds) => SweepGradient(
                                              transform: GradientRotation(
                                                  _rgb.value * 2 * pi),
                                              colors: type == "BALLOND'OR"
                                                  ? [
                                                      Colors.amber,
                                                      Colors.white,
                                                      Colors.amber
                                                    ]
                                                  : [
                                                      Colors.purpleAccent,
                                                      Colors.cyanAccent,
                                                      Colors.purpleAccent
                                                    ])
                                          .createShader(bounds),
                                      child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  width: 4,
                                                  color: Colors.white.withOpacity(0.3)))))),
                            Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Stack(children: [
                                  if (type != "Temel")
                                    Positioned(
                                        top: 0,
                                        left: 0,
                                        right: 0,
                                        child: Center(
                                            child: Text(
                                                isBad
                                                    ? "SAKAR"
                                                    : type.toUpperCase(),
                                                style: GoogleFonts.orbitron(
                                                    color: (isBad ||
                                                            type == "TOTS")
                                                        ? Colors.white
                                                        : _getBorderColor(type),
                                                    fontWeight: FontWeight.w900,
                                                    fontSize: 16,
                                                    letterSpacing: 3,
                                                    shadows: [
                                                      const Shadow(
                                                          color: Colors.black,
                                                          blurRadius: 10)
                                                    ])))),
                                  Positioned(
                                      top: 40,
                                      left: 0,
                                      child: Icon(
                                          isBad
                                              ? Icons.broken_image
                                              : Icons.sports_soccer,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 30)),
                                  Positioned(
                                      top: 40,
                                      right: 0,
                                      child: Icon(
                                          isBad
                                              ? Icons.thumb_down
                                              : Icons.shield,
                                          color: Colors.white.withOpacity(0.7),
                                          size: 30)),
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
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                    fontWeight:
                                                        FontWeight.bold))
                                          ])),
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
                                                    color: Colors.white
                                                        .withOpacity(0.15))),
                                            if (!isBad)
                                              Row(
                                                  children: List.generate(
                                                      p.getCardTierStars(),
                                                      (i) => const Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                          size: 14)))
                                          ])),
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
                                              overflow:
                                                  TextOverflow.ellipsis))),
                                  Positioned(
                                      top: 250,
                                      left: 10,
                                      right: 10,
                                      child: Column(children: [
                                        const Divider(color: Colors.white30),
                                        const SizedBox(height: 10),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _cStat("PAC", cs["PAC"]!),
                                              _cStat("DRI", cs["DRI"]!)
                                            ]),
                                        const SizedBox(height: 5),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _cStat("SHO", cs["SHO"]!),
                                              _cStat("DEF", cs["DEF"]!)
                                            ]),
                                        const SizedBox(height: 5),
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _cStat("PAS", cs["PAS"]!),
                                              _cStat("PHY", cs["PHY"]!)
                                            ]),
                                        const SizedBox(height: 15),
                                        const Divider(color: Colors.white30)
                                      ])),
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
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                size: 14),
                                            const SizedBox(width: 5),
                                            Text(
                                                "${p.chemistryStyle} • ${p.role}"
                                                    .toUpperCase(),
                                                style: GoogleFonts.montserrat(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    letterSpacing: 1,
                                                    fontSize: 10))
                                          ]))
                                ]))
                          ])),
                    ),
                    if (goldPs != null && !isBad)
                      Positioned(
                          left: -5,
                          top: 220,
                          child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.amber, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.amber.withOpacity(0.5),
                                        blurRadius: 15)
                                  ]),
                              child: Image.asset(goldPs.assetPath,
                                  width: 30,
                                  height: 30,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 30)))),
                  ]));
        });
  }

  Widget _cStat(String l, int v) => Row(children: [
        Text("$v",
            style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(width: 5),
        Text(l,
            style: GoogleFonts.montserrat(fontSize: 16, color: Colors.white70))
      ]);
  Widget _buildParticles(String type) {
    Color pColor = (type == "BALLOND'OR")
        ? Colors.amberAccent
        : (type == "TOTS"
            ? Colors.cyanAccent
            : (type == "MVP" ? Colors.red : Colors.white));
    IconData pIcon = (type == "BALLOND'OR")
        ? Icons.auto_awesome
        : (type == "TOTS" ? Icons.bolt : Icons.star);
    double speedMult = type == "TOTS" ? 0.3 : 1.0; // TOTS daha yavaş aksın
    return Stack(
        children: _stars
            .map((pos) => Positioned(
                left: pos.dx * 320,
                top: (pos.dy + _rgb.value * speedMult) % 1 * 480,
                child: Opacity(
                    opacity: 0.4,
                    child: Icon(pIcon,
                        color: pColor, size: type == "BALLOND'OR" ? 18 : 10))))
            .toList());
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
        return Colors.pinkAccent.withOpacity(0.6);
      case "TOTS":
        return Colors.purpleAccent;
      default:
        return Colors.white12;
    }
  }

  Color _getGlowColor(String t) {
    return (t == "BAD") ? Colors.pinkAccent : _getBorderColor(t);
  }

  LinearGradient _getBgGradient(String t) {
    switch (t) {
      case "TOTW":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35)],
            begin: Alignment.topLeft);
      case "TOTM":
        return const LinearGradient(
            colors: [Color(0xFF2E001F), Color(0xFFE91E63)],
            begin: Alignment.topLeft);
      case "BALLOND'OR":
        return const LinearGradient(
            colors: [Color(0xFF8E6E1D), Colors.black, Color(0xFFF8D568)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case "BAD":
        return const LinearGradient(
            colors: [Color(0xFFFFC1E3), Color(0xFFD81B60)],
            begin: Alignment.topLeft);
      case "TOTS":
        return const LinearGradient(
            colors: [Colors.black, Color(0xFF311B92)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      default:
        return const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)],
            begin: Alignment.topLeft);
    }
  }
}
