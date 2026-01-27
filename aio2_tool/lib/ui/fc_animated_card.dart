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
      30, (i) => Offset(Random().nextDouble(), Random().nextDouble()));

  @override
  void initState() {
    super.initState();
    int speed = widget.player.cardType == "TOTS" ||
            widget.player.cardType == "BALLOND'OR"
        ? 2
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
    Map<String, int> cs = p.getCardStats();
    PlayStyle? goldPs = p.playstyles.isNotEmpty
        ? p.playstyles
            .firstWhere((ps) => ps.isGold, orElse: () => p.playstyles.first)
        : null;
    String type = p.cardType;
    int tierStars = p.getCardTierStars();

    BoxDecoration baseDecor = BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5)
        ],
        border: Border.all(width: 2, color: _getBorderColor(type)));

    return AnimatedBuilder(
        animation: Listenable.merge([_rgb, _pulse]),
        builder: (context, child) {
          return SizedBox(
            width: 350, // Genişletildi
            height: 480,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 320,
                  height: 480,
                  decoration: baseDecor.copyWith(
                      gradient: _getBgGradient(type),
                      border: (type == "TOTS" || type == "BALLOND'OR")
                          ? null
                          : baseDecor.border,
                      boxShadow: [
                        BoxShadow(
                            color: _getGlowColor(type)
                                .withOpacity(_pulse.value * 0.4 + 0.1),
                            blurRadius: 30,
                            spreadRadius: 5)
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        if (tierStars >= 3) _buildParticles(type),
                        if (type == "TOTS" || type == "BALLOND'OR" || type == "STAR")
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
                                                  Colors.cyan,
                                                  Colors.purple,
                                                  Colors.blue,
                                                  Colors.cyan
                                                ])
                                      .createShader(bounds),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              width: 4,
                                              color: Colors.white))))),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Stack(
                            children: [
                              if (type != "Temel")
                                Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                        child: Text(type.toUpperCase(),
                                            style: GoogleFonts.orbitron(
                                                color: _getBorderColor(type),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                letterSpacing: 3,
                                                shadows: [
                                                  Shadow(
                                                      color: Colors.black,
                                                      blurRadius: 10)
                                                ])))),
                              Positioned(
                                  top: 40,
                                  left: 0,
                                  child: Icon(Icons.sports_soccer,
                                      color:
                                          _getTextColor(type).withOpacity(0.7),
                                      size: 30)),
                              Positioned(
                                  top: 40,
                                  right: 0,
                                  child: Icon(Icons.shield,
                                      color:
                                          _getTextColor(type).withOpacity(0.7),
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
                                                color: _getTextColor(type),
                                                height: 1)),
                                        Text(p.position,
                                            style: GoogleFonts.montserrat(
                                                fontSize: 20,
                                                color: _getTextColor(type)
                                                    .withOpacity(0.8),
                                                fontWeight: FontWeight.bold))
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
                                                color: _getTextColor(type)
                                                    .withOpacity(0.15))),
                                        if (tierStars > 0)
                                          Row(
                                              children: List.generate(
                                                  tierStars,
                                                  (i) => Icon(Icons.star,
                                                      color:
                                                          _getBorderColor(type),
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
                                              color: _getTextColor(type),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2),
                                          overflow: TextOverflow.ellipsis))),
                              Positioned(
                                  top: 250,
                                  left: 20,
                                  right: 20,
                                  child: Column(children: [
                                    const Divider(color: Colors.white30),
                                    const SizedBox(height: 10),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _cStat("PAC", cs["PAC"]!, type),
                                          _cStat("DRI", cs["DRI"]!, type)
                                        ]),
                                    const SizedBox(height: 5),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _cStat("SHO", cs["SHO"]!, type),
                                          _cStat("DEF", cs["DEF"]!, type)
                                        ]),
                                    const SizedBox(height: 5),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _cStat("PAS", cs["PAS"]!, type),
                                          _cStat("PHY", cs["PHY"]!, type)
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
                                        Icon(Icons.science,
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
                                      ])),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                // PLAYSTYLE+ (YARISI DIŞARIDA)
                if (goldPs != null)
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

  Widget _cStat(String l, int v, String t) => Row(children: [
        Text("$v",
            style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getTextColor(t))),
        const SizedBox(width: 5),
        Text(l,
            style: GoogleFonts.montserrat(
                fontSize: 16, color: _getTextColor(t).withOpacity(0.7)))
      ]);
  Widget _buildParticles(String type) {
    Color pColor = type == "MVP"
        ? Colors.red
        : (type == "BALLOND'OR" ? Colors.amber : Colors.cyanAccent);
    IconData pIcon = type == "MVP" ? Icons.circle : (Icons.star);
    return Stack(
        children: _stars
            .map((pos) => Positioned(
                left: pos.dx * 320,
                top: (pos.dy + _rgb.value) % 1 * 480,
                child: Icon(pIcon,
                    color:
                        pColor.withOpacity(0.3 + (Random().nextDouble() * 0.3)),
                    size: type == "MVP" ? 4 : 10)))
            .toList());
  }

  Color _getBorderColor(String t) {
    switch (t) {
      case "TOTW":
        return Colors.amber;
      case "TOTM":
        return Colors.purpleAccent;
      case "MVP":
        return Colors.redAccent;
      case "BALLOND'OR":
        return Colors.amberAccent;
      case "BAD":
        return Colors.pinkAccent;
      case "TOTS":
      case "STAR":
        return Colors.cyanAccent;
      default:
        return Colors.white;
    }
  }

  Color _getGlowColor(String t) {
    switch (t) {
      case "MVP":
        return Colors.red;
      case "BAD":
        return Colors.pink;
      case "BALLOND'OR":
        return Colors.amber[700]!;
      default:
        return _getBorderColor(t);
    }
  }

  Color _getTextColor(String t) {
    return t == "BALLOND'OR" ? Colors.amber[100]! : Colors.white;
  }

  LinearGradient _getBgGradient(String t) {
    switch (t) {
      case "TOTW":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35)],
            begin: Alignment.topLeft);
      case "TOTM":
        return const LinearGradient(
            colors: [Color(0xFF3E1E68), Color(0xFFC2185B)],
            begin: Alignment.topLeft);
      case "MVP":
        return const LinearGradient(
            colors: [Colors.black, Color(0xFF4A0000)],
            begin: Alignment.topCenter);
      case "BALLOND'OR":
        return const LinearGradient(
            colors: [Color(0xFF8E6E1D), Colors.black, Color(0xFFF8D568)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case "BAD":
        return const LinearGradient(
            colors: [Color(0xFF2C001E), Color(0xFF880E4F)],
            begin: Alignment.topLeft);
      case "TOTS":
      case "STAR":
        return const LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft);
      default:
        return const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)],
            begin: Alignment.topLeft);
    }
  }
}
