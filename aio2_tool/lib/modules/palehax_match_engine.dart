import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

enum TeamTactic { balanced, attacking, defensive, counterAttack }

class SimPlayer {
  final Player data;
  double x, y;
  bool isHome;
  String role;
  double baseX, baseY;
  Map<String, int> fmStats; // 1-20 arası statlar

  SimPlayer(this.data, this.x, this.y, this.isHome, this.role)
      : baseX = x,
        baseY = y,
        fmStats = data.getFMStats();
}

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam, oppTeam;
  final TeamTactic myTactic;
  final Function(bool isWin) onMatchEnd;

  const MatchEngineView(
      {super.key,
      required this.myTeam,
      required this.oppTeam,
      required this.myTactic,
      required this.onMatchEnd});
  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView>
    with TickerProviderStateMixin {
  int matchDuration = 30;
  bool isMatchStarted = false, isFinished = false, showGoalAnim = false;
  String goalScorerName = "";
  int homeScore = 0, awayScore = 0;

  List<SimPlayer> simHomeTeam = [], simAwayTeam = [];
  SimPlayer? ballHolder;

  double ballX = 0.5, ballY = 0.5;
  double ballVelX = 0.0, ballVelY = 0.0; // Top hızı vektörü

  List<String> logs = [];
  Timer? _gameLoop;
  int _tick = 0;

  TeamTactic oppTactic = TeamTactic.balanced;

  @override
  void initState() {
    super.initState();
    oppTactic = TeamTactic.values[Random().nextInt(TeamTactic.values.length)];
    _setupPitch();
  }

  void _setupPitch() {
    simHomeTeam.clear();
    simAwayTeam.clear();
    _deployTeam(widget.myTeam, simHomeTeam, true, widget.myTactic);
    _deployTeam(widget.oppTeam, simAwayTeam, false, oppTactic);
  }

  void _deployTeam(List<Player> source, List<SimPlayer> target, bool isHome,
      TeamTactic tactic) {
    // Diziliş mantığı (Önceki kodun aynısı ama konumlar daha geniş)
    for (int i = 0; i < source.length; i++) {
      String role = i == 0 ? "GK" : (i < 3 ? "DEF" : (i < 5 ? "MID" : "FWD"));
      double sx = isHome ? 0.1 : 0.9, sy = 0.5;

      if (role == "GK") {
        sx = isHome ? 0.02 : 0.98;
      } else if (role == "DEF") {
        sx = isHome ? 0.25 : 0.75;
        sy = (i % 2 == 0) ? 0.3 : 0.7;
      } else if (role == "MID") {
        sx = isHome ? 0.5 : 0.5;
        sy = (i % 2 == 0) ? 0.4 : 0.6;
      } else {
        sx = isHome ? 0.75 : 0.25;
        sy = (i % 2 == 0) ? 0.2 : 0.8;
      }

      target.add(SimPlayer(source[i], sx, sy, isHome, role));
    }
  }

  void _startMatch() {
    setState(() {
      isMatchStarted = true;
      isFinished = false;
      logs.clear();
      ballHolder = simHomeTeam.last;
      ballX = ballHolder!.x;
      ballY = ballHolder!.y;
    });

    // 60 FPS (16ms) Simülasyon
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_tick >= matchDuration * 60) {
        _endMatch();
        timer.cancel();
      } else {
        _updatePhysics();
        _updateAI();
        _tick++;
      }
    });
  }

  void _endMatch() {
    setState(() => isFinished = true);
    widget.onMatchEnd(homeScore > awayScore);
  }

  // --- FİZİK MOTORU (PRO HAXBALL) ---
  void _updatePhysics() {
    if (showGoalAnim) return;

    setState(() {
      if (ballHolder != null) {
        ballX = ballHolder!.x;
        ballY = ballHolder!.y;
        ballVelX = 0;
        ballVelY = 0;
      } else {
        // Top serbest hareket
        ballX += ballVelX;
        ballY += ballVelY;

        // Sürtünme (Çim saha)
        ballVelX *= 0.985;
        ballVelY *= 0.985;

        // DUVAR SEKMESİ (Wall Bounce)
        if (ballY <= 0.02 || ballY >= 0.98) {
          ballVelY = -ballVelY * 0.9; // Enerji kaybı
        }

        // Kale Arkası Duvarı (Korner yok)
        if ((ballX < 0.0 && (ballY < 0.36 || ballY > 0.64)) ||
            (ballX > 1.0 && (ballY < 0.36 || ballY > 0.64))) {
          ballVelX = -ballVelX * 0.9;
        }

        // GOL KONTROLÜ
        if (ballX < -0.05 && ballY > 0.36 && ballY < 0.64) _triggerGoal(false);
        if (ballX > 1.05 && ballY > 0.36 && ballY < 0.64) _triggerGoal(true);
      }
    });
  }

  // --- GELİŞMİŞ YAPAY ZEKA ---
  void _updateAI() {
    if (showGoalAnim) return;
    var rng = Random();

    // 1. OYUNCU HAREKETLERİ
    List<SimPlayer> allPlayers = [...simHomeTeam, ...simAwayTeam];

    // Top kime yakın?
    SimPlayer? nearestToBall;
    double minDist = 100.0;

    for (var p in allPlayers) {
      double d = sqrt(pow(p.x - ballX, 2) + pow(p.y - ballY, 2));
      if (d < minDist) {
        minDist = d;
        nearestToBall = p;
      }

      double targetX = p.baseX;
      double targetY = p.baseY;
      double speed = 0.002 + (p.fmStats['Hız']! * 0.0001); // FM Stat etkisi

      if (p == ballHolder) {
        // Dripling Yap
        double goalDir = p.isHome ? 1.0 : -1.0;
        targetX = p.x + (goalDir * 0.05);

        // Köşede sıkışırsa duvara yaklaş (Wall Dribble)
        if (p.fmStats['Dripling']! > 15 && (p.y < 0.1 || p.y > 0.9)) {
          targetY = p.y < 0.1 ? 0.01 : 0.99; // Duvara yapış
        } else {
          targetY = 0.5; // Merkeze in
        }
      } else if (ballHolder != null && ballHolder!.isHome != p.isHome) {
        // SAVUNMA: MARKAJ SİSTEMİ
        if (p.role == "DEF" || p.role == "MID") {
          // En yakın rakibi bul ve yapış
          SimPlayer? markTarget;
          double markDist = 100.0;
          List<SimPlayer> opponents = p.isHome ? simAwayTeam : simHomeTeam;
          for (var opp in opponents) {
            double dist = sqrt(pow(p.x - opp.x, 2) + pow(p.y - opp.y, 2));
            if (dist < markDist && opp.x > (p.isHome ? 0.5 : 0.0)) {
              // Sadece tehlikeli bölgedekiler
              markDist = dist;
              markTarget = opp;
            }
          }

          if (markTarget != null) {
            // Adam adama (Rakiple kale arasında dur)
            targetX = markTarget.x + (p.isHome ? -0.05 : 0.05);
            targetY = markTarget.y;
          } else {
            // Alan savunması (Topa göre kay)
            targetX = ballX + (p.isHome ? -0.2 : 0.2);
            targetY = ballY;
          }
        }
      } else if (ballHolder == null) {
        // Top boşta: Sadece en yakın koşsun, diğerleri pozisyon alsın
        if (d < 0.2 && p == nearestToBall) {
          targetX = ballX;
          targetY = ballY;
          speed *= 1.5; // Depar
        } else {
          // Pozisyon alma statına göre doğru yerde dur
          double iqOffset = (20 - p.fmStats['Pozisyon']!) * 0.01;
          targetX += (rng.nextDouble() - 0.5) * iqOffset;
        }
      }

      // Hareketi Uygula
      p.x += (targetX - p.x) * speed;
      p.y += (targetY - p.y) * speed;
      p.x = p.x.clamp(0.01, 0.99);
      p.y = p.y.clamp(0.01, 0.99);
    }

    // 2. TOP KAPMA VE KARAR
    if (ballHolder == null && nearestToBall != null && minDist < 0.02) {
      ballHolder = nearestToBall; // Topu kaptı
    } else if (ballHolder != null) {
      // Pas/Şut Kararı (Her 30 tickte bir - 0.5sn)
      if (_tick % 30 == 0) _makeDecision(ballHolder!, rng);
    }
  }

  void _makeDecision(SimPlayer p, Random rng) {
    bool inRange = p.isHome ? p.x > 0.7 : p.x < 0.3;

    // Şut mu Pas mı?
    if (inRange && rng.nextInt(20) < p.fmStats['Şut']!) {
      _shoot(p, rng);
    } else {
      _pass(p, rng);
    }
  }

  void _pass(SimPlayer p, Random rng) {
    List<SimPlayer> mates = p.isHome ? simHomeTeam : simAwayTeam;
    // En uygun arkadaşı bul (Vizyon statına göre)
    var options = mates
        .where((m) => m != p && (p.isHome ? m.x > p.x : m.x < p.x))
        .toList();
    if (options.isEmpty) return;

    SimPlayer target = options[rng.nextInt(options.length)];

    // Hata Payı (Pas statı düşükse sapar)
    double errorMargin = (20 - p.fmStats['Pas']!) * 0.02;
    double angle = atan2(target.y - p.y, target.x - p.x);
    angle += (rng.nextDouble() - 0.5) * errorMargin;

    // Pas Hızı (Videodaki gibi sert)
    double power = 0.015 + (p.fmStats['Fizik']! * 0.0005);

    ballHolder = null;
    ballVelX = cos(angle) * power;
    ballVelY = sin(angle) * power;
  }

  void _shoot(SimPlayer p, Random rng) {
    ballHolder = null;
    double goalX = p.isHome ? 1.0 : 0.0;
    double goalY = 0.5;

    // Şut isabeti (Şut statı)
    double error = (20 - p.fmStats['Şut']!) * 0.015;
    double angle = atan2(goalY - p.y, goalX - p.x);
    angle += (rng.nextDouble() - 0.5) * error;

    double power = 0.025; // Çok hızlı
    ballVelX = cos(angle) * power;
    ballVelY = sin(angle) * power;

    _addLog("🚀 ${p.data.name} vurdu!");
  }

  void _triggerGoal(bool isHomeGoal) {
    setState(() {
      showGoalAnim = true;
      if (isHomeGoal)
        homeScore++;
      else
        awayScore++;
      ballVelX = 0;
      ballVelY = 0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showGoalAnim = false;
          _setupPitch();
          ballHolder = isHomeGoal ? simAwayTeam.last : simHomeTeam.last;
        });
      }
    });
  }

  void _addLog(String t) {
    if (logs.length > 5) logs.removeLast();
    logs.insert(0, "${(_tick / 60).toInt()}' $t");
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
          title: Text("PRO HAXBALL ENGINE",
              style: GoogleFonts.orbitron(color: Colors.amber)),
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false),
      body: Stack(children: [
        // Saha ve Oyuncular
        Column(children: [
          _buildScoreBoard(),
          Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24, width: 2),
                    image: const DecorationImage(
                        image: AssetImage("assets/pitch_bg.png"),
                        fit: BoxFit.cover)),
                child: Stack(children: [
                  ...simHomeTeam
                      .map((p) => _PlayerDot(p: p, color: Colors.cyanAccent)),
                  ...simAwayTeam
                      .map((p) => _PlayerDot(p: p, color: Colors.redAccent)),
                  AnimatedAlign(
                      duration: const Duration(milliseconds: 16),
                      alignment: Alignment(ballX * 2 - 1, ballY * 2 - 1),
                      child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)))
                ]),
              )),
          Expanded(
              flex: 2,
              child: Container(
                  color: Colors.black,
                  child: ListView(
                      children: logs
                          .map((e) => Text(e,
                              style:
                                  const TextStyle(color: Colors.greenAccent)))
                          .toList())))
        ]),
        if (showGoalAnim)
          Center(
              child: Text("GOOOL!",
                  style:
                      GoogleFonts.russoOne(fontSize: 80, color: Colors.white)))
      ]),
    );
  }

  Widget _buildScoreBoard() => Container(
      height: 60,
      color: Colors.black87,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Text("$homeScore",
            style: const TextStyle(fontSize: 30, color: Colors.white)),
        Text("$awayScore",
            style: const TextStyle(fontSize: 30, color: Colors.white))
      ]));
}

class _PlayerDot extends StatelessWidget {
  final SimPlayer p;
  final Color color;
  const _PlayerDot({required this.p, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 100), // Hareket yumuşatma
      alignment: Alignment(p.x * 2 - 1, p.y * 2 - 1),
      child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white))),
    );
  }
}
