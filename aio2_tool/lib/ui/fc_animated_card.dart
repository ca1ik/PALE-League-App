import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../data/player_data.dart';

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

  @override
  void initState() {
    super.initState();
    _loopController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    if (!widget.animateOnHover && widget.player.cardType != "Temel") {
      _loopController.repeat();
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
    if (hover) {
      _loopController.repeat();
      _pulseController.repeat(reverse: true);
    } else {
      _loopController.stop();
      _pulseController.stop();
    }
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
    String? logo = teamLogos[p.team];

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
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
                                    blurRadius: isBad ? 5 : 25,
                                    spreadRadius: isBad ? 0 : 3)
                              ]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          if (_hasVideoEffect(type))
                            Positioned.fill(
                                child: _CardVideoLayer(
                                    cardType: type,
                                    isHovered: widget.animateOnHover
                                        ? (_loopController.isAnimating)
                                        : true)),
                          if (!_hasVideoEffect(type) && !isBasic)
                            _buildCodeEffects(type),
                          if (!isBasic &&
                              !isBad &&
                              (type == "TOTS" ||
                                  type == "BALLOND'OR" ||
                                  type == "STAR"))
                            Positioned.fill(
                                child: ShaderMask(
                                    shaderCallback: (bounds) => SweepGradient(
                                            transform: GradientRotation(
                                                _loopController.value * 4 * pi),
                                            colors: _getShaderColors(type))
                                        .createShader(bounds),
                                    child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                width: 3,
                                                color: Colors.white.withOpacity(0.15)))))),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Stack(
                              children: [
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
                                              style: isBad
                                                  ? GoogleFonts.comicNeue(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white)
                                                  : GoogleFonts.orbitron(
                                                      color:
                                                          _getTitleColor(type),
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 16,
                                                      letterSpacing: 3,
                                                      shadows: [
                                                          Shadow(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.8),
                                                              blurRadius: 5)
                                                        ])))),
                                Positioned(
                                    top: 40,
                                    left: 0,
                                    child: (logo != null && logo.isNotEmpty)
                                        ? Image.asset(logo,
                                            width: 35,
                                            height: 35,
                                            errorBuilder: (c, e, s) => Icon(
                                                Icons.sports_soccer,
                                                color: Colors.white70,
                                                size: 30))
                                        : Icon(Icons.sports_soccer,
                                            color: Colors.white70, size: 30)),
                                Positioned(
                                    top: 40,
                                    right: 0,
                                    child: Icon(
                                        isBad ? Icons.thumb_down : Icons.shield,
                                        color: Colors.white70,
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
                                                  color: Colors.white70,
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
                                                  color: Colors.white12)),
                                          if (!isBad && !isBasic)
                                            Row(
                                                children: List.generate(
                                                    p.getCardTierStars(),
                                                    (i) => Icon(Icons.star,
                                                        color: borderColor,
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
                                            overflow: TextOverflow.ellipsis))),
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
                                            _cStat(
                                                "PAC", cs["PAC"]!, type, isBad),
                                            _cStat(
                                                "DRI", cs["DRI"]!, type, isBad)
                                          ]),
                                      const SizedBox(height: 5),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _cStat(
                                                "SHO", cs["SHO"]!, type, isBad),
                                            _cStat(
                                                "DEF", cs["DEF"]!, type, isBad)
                                          ]),
                                      const SizedBox(height: 5),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            _cStat(
                                                "PAS", cs["PAS"]!, type, isBad),
                                            _cStat(
                                                "PHY", cs["PHY"]!, type, isBad)
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
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  if (goldPs != null && !isBad && !isBasic)
                    Positioned(
                        left: -5,
                        top: 220,
                        child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.amber.withOpacity(0.6),
                                      blurRadius: 15)
                                ]),
                            child: Image.asset(goldPs.assetPath,
                                width: 30,
                                height: 30,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.star,
                                    color: Colors.white,
                                    size: 30)))),
                ],
              ),
            );
          }),
    );
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

  bool _hasVideoEffect(String type) =>
      ["TOTS", "BALLOND'OR", "MVP", "TOTM", "STAR"].contains(type);

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
        return Colors.white;
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

  Color _getTextColor(String t) => Colors.white;
  LinearGradient _getBgGradient(String t) {
    switch (t) {
      case "TOTW":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35)],
            begin: Alignment.topLeft);
      case "TOTM":
        return const LinearGradient(
            colors: [Color(0xFF2E001F), Color(0xFFC2185B)],
            begin: Alignment.topLeft);
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
            colors: [Color(0xFFF48FB1), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case "TOTS":
        return const LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF311B92)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
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

class _CardVideoLayer extends StatefulWidget {
  final String cardType;
  final bool isHovered;
  const _CardVideoLayer({required this.cardType, required this.isHovered});
  @override
  State<_CardVideoLayer> createState() => _CardVideoLayerState();
}

class _CardVideoLayerState extends State<_CardVideoLayer> {
  VideoPlayerController? _controller;
  bool _isInit = false;
  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    String path = _getPath(widget.cardType);
    if (path.isEmpty) return;
    _controller = VideoPlayerController.asset(path)
      ..initialize().then((_) {
        _controller!.setLooping(true);
        _controller!.setVolume(0);
        if (widget.isHovered) _controller!.play();
        if (mounted) setState(() => _isInit = true);
      }).catchError((e) {
        debugPrint("Video hata: $e");
      });
  }

  @override
  void didUpdateWidget(covariant _CardVideoLayer old) {
    super.didUpdateWidget(old);
    if (widget.isHovered)
      _controller?.play();
    else
      _controller?.pause();
  }

  String _getPath(String t) {
    switch (t) {
      case "TOTS":
        return "assets/videos/tots_effect.mp4";
      case "BALLOND'OR":
        return "assets/videos/ballondor_effect.mp4";
      case "MVP":
        return "assets/videos/mvp_effect.mp4";
      case "STAR":
        return "assets/videos/star_effect.mp4";
      case "TOTM":
        return "assets/videos/totm_effect.mp4";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) return const SizedBox.shrink();
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ShaderMask(
            shaderCallback: (r) =>
                const LinearGradient(colors: [Colors.white, Colors.white])
                    .createShader(r),
            blendMode: BlendMode.screen,
            child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!)))));
  }
}
