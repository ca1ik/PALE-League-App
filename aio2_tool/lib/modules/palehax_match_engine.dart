import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// --- FİZİK VEKTÖRÜ ---
class Vector2 {
  double x, y;
  Vector2(this.x, this.y);
  void add(Vector2 v) {
    x += v.x;
    y += v.y;
  }

  void scale(double s) {
    x *= s;
    y *= s;
  }

  double dist(Vector2 v) => sqrt(pow(x - v.x, 2) + pow(y - v.y, 2));
}

// --- SİMÜLASYON OYUNCUSU ---
class SimPlayer {
  final Player data;
  Vector2 pos, vel, target;
  bool isHome;
  String role;
  SimPlayer? markTarget;
  Map<String, int> fm;
  int cooldown = 0;
  bool hasBall = false;

  SimPlayer(this.data, double x, double y, this.isHome, this.role)
      : pos = Vector2(x, y),
        vel = Vector2(0, 0),
        target = Vector2(x, y),
        fm = data.getFMStats();
}

class Ball {
  Vector2 pos, vel;
  SimPlayer? owner;
  Ball()
      : pos = Vector2(0.5, 0.5),
        vel = Vector2(0, 0);
}

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam, oppTeam;
  final Function(bool isWin) onMatchEnd;
  const MatchEngineView(
      {super.key,
      required this.myTeam,
      required this.oppTeam,
      required this.onMatchEnd});
  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView> {
  final int fps = 60;
  final int matchMinutes = 90;
  bool isStarted = false, isGoal = false;
  int homeScore = 0, awayScore = 0, tick = 0;
  List<SimPlayer> homeSquad = [], awaySquad = [];
  Ball ball = Ball();
  Timer? _timer;
  List<String> logs = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _init() {
    _create(widget.myTeam, homeSquad, true);
    _create(widget.oppTeam, awaySquad, false);
    _tactics();
    _resetPositions(true);
  }

  void _create(List<Player> src, List<SimPlayer> trg, bool home) {
    trg.clear();
    var sorted = List<Player>.from(src)
      ..sort((a, b) {
        int score(String p) => p.contains("GK")
            ? 0
            : p.contains("DEF")
                ? 1
                : p.contains("MID")
                    ? 2
                    : 3;
        return score(a.position).compareTo(score(b.position));
      });

    for (int i = 0; i < min(sorted.length, 7); i++) {
      String r = i == 0
          ? "GK"
          : i < 3
              ? "DEF"
              : i < 5
                  ? "MID"
                  : "FWD";
      double x = home ? 0.1 : 0.9, y = 0.5;
      if (r == "GK") {
        x = home ? 0.02 : 0.98;
      } else if (r == "DEF") {
        x = home ? 0.25 : 0.75;
        y = i % 2 == 0 ? 0.3 : 0.7;
      } else if (r == "MID") {
        x = home ? 0.5 : 0.5;
        y = i % 2 == 0 ? 0.4 : 0.6;
      } else {
        x = home ? 0.75 : 0.25;
        y = 0.5;
      }
      trg.add(SimPlayer(sorted[i], x, y, home, r));
    }
  }

  void _tactics() {
    var hDefs = homeSquad.where((p) => p.role == "DEF").toList();
    var aFwds = awaySquad.where((p) => p.role == "FWD").toList();
    for (int i = 0; i < min(hDefs.length, aFwds.length); i++)
      hDefs[i].markTarget = aFwds[i];
    var aDefs = awaySquad.where((p) => p.role == "DEF").toList();
    var hFwds = homeSquad.where((p) => p.role == "FWD").toList();
    for (int i = 0; i < min(aDefs.length, hFwds.length); i++)
      aDefs[i].markTarget = hFwds[i];
  }

  void _start() {
    if (isStarted) return;
    setState(() {
      isStarted = true;
      _addLog("MAÇ BAŞLADI!", Colors.white);
    });
    _timer = Timer.periodic(const Duration(milliseconds: 16), _loop);
  }

  void _loop(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    if (tick >= 60 * matchMinutes) {
      t.cancel();
      _finish();
      return;
    }
    if (!isGoal) {
      _physics();
      _ai();
      tick++;
    }
    if (tick % 2 == 0) setState(() {});
  }

  void _finish() {
    _timer?.cancel();
    _addLog("BİTTİ: $homeScore - $awayScore", Colors.amber);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onMatchEnd(homeScore > awayScore);
    });
  }

  void _physics() {
    if (ball.owner != null) {
      ball.pos.x = ball.owner!.pos.x + (ball.owner!.isHome ? 0.015 : -0.015);
      ball.pos.y = ball.owner!.pos.y;
      ball.vel.x = 0;
      ball.vel.y = 0;
    } else {
      ball.pos.add(ball.vel);
      ball.vel.scale(0.985);
      if (ball.pos.y <= 0.02 || ball.pos.y >= 0.98) ball.vel.y *= -0.9;
      bool gY = ball.pos.y > 0.36 && ball.pos.y < 0.64;
      if (!gY && (ball.pos.x <= 0.01 || ball.pos.x >= 0.99)) ball.vel.x *= -0.9;
      if (ball.pos.x < -0.05 && gY) _triggerGoal(false);
      if (ball.pos.x > 1.05 && gY) _triggerGoal(true);
    }
    for (var p in [...homeSquad, ...awaySquad]) {
      double dx = p.target.x - p.pos.x, dy = p.target.y - p.pos.y;
      double dist = sqrt(dx * dx + dy * dy);
      if (dist > 0.002) {
        double spd = 0.003 + ((p.fm['Hız'] ?? 10) * 0.00015);
        if (p == ball.owner) spd *= 0.85;
        p.pos.x += (dx / dist) * spd;
        p.pos.y += (dy / dist) * spd;
      }
      p.pos.x = p.pos.x.clamp(0.01, 0.99);
      p.pos.y = p.pos.y.clamp(0.01, 0.99);
    }
  }

  void _ai() {
    var all = [...homeSquad, ...awaySquad];
    if (ball.owner == null) {
      SimPlayer? near;
      double minDist = 100;
      for (var p in all) {
        double d = p.pos.dist(ball.pos);
        if (d < minDist) {
          minDist = d;
          near = p;
        }
      }
      if (near != null) {
        near.target.x = ball.pos.x;
        near.target.y = ball.pos.y;
        if (minDist < 0.025) ball.owner = near;
      }
    }
    for (var p in all) {
      if (p == ball.owner) {
        p.target.x = p.isHome ? 1.0 : 0.0;
        p.target.y = 0.5;
        int drib = p.fm['Dripling'] ?? 10;
        if (drib > 15 && (p.pos.y < 0.1 || p.pos.y > 0.9))
          p.target.y = p.pos.y < 0.5 ? 0.01 : 0.99;
        if (tick % 20 == 0) _decide(p);
      } else if (ball.owner != null && ball.owner!.isHome != p.isHome) {
        if (p.role == "GK") {
          p.target.x = p.isHome ? 0.02 : 0.98;
          p.target.y = ball.pos.y.clamp(0.4, 0.6);
        } else if (p.markTarget != null) {
          p.target.x = p.markTarget!.pos.x + (p.isHome ? -0.05 : 0.05);
          p.target.y = p.markTarget!.pos.y;
        } else {
          p.target.x = ball.pos.x + (p.isHome ? -0.2 : 0.2);
          p.target.y = ball.pos.y;
        }

        if (p.pos.dist(ball.pos) < 0.025) {
          int def = p.fm['Defans'] ?? 10;
          int dri = ball.owner!.fm['Dripling'] ?? 10;
          if ((def + _rng.nextInt(10)) > (dri + _rng.nextInt(5))) {
            ball.owner = p;
            _addLog("⚔️ ${p.data.name} topu kaptı!", Colors.orange);
          }
        }
      } else {
        int pos = p.fm['Pozisyon'] ?? 10;
        if (pos > 10) {
          p.target.x = p.isHome ? ball.pos.x + 0.15 : ball.pos.x - 0.15;
          if ((p.pos.y - ball.pos.y).abs() < 0.1)
            p.target.y = ball.pos.y + (ball.pos.y > 0.5 ? -0.2 : 0.2);
        }
      }
    }
  }

  void _decide(SimPlayer p) {
    bool range = p.isHome ? p.pos.x > 0.7 : p.pos.x < 0.3;
    int sho = p.fm['Şut'] ?? 10;
    if (range && _rng.nextInt(20) < sho)
      _shoot(p);
    else
      _pass(p);
  }

  void _pass(SimPlayer p) {
    var mates = p.isHome ? homeSquad : awaySquad;
    var opts = mates
        .where(
            (m) => m != p && (p.isHome ? m.pos.x > p.pos.x : m.pos.x < p.pos.x))
        .toList();
    if (opts.isEmpty) return;
    var t = opts[_rng.nextInt(opts.length)];
    double err = (20 - (p.fm['Pas'] ?? 10)) * 0.015;
    double angle = atan2(t.pos.y - p.pos.y, t.pos.x - p.pos.x) +
        (_rng.nextDouble() - 0.5) * err;
    double pwr = 0.035 + ((p.fm['Fizik'] ?? 10) * 0.0005);
    ball.owner = null;
    ball.vel.x = cos(angle) * pwr;
    ball.vel.y = sin(angle) * pwr;
  }

  void _shoot(SimPlayer p) {
    ball.owner = null;
    double gx = p.isHome ? 1.05 : -0.05, gy = 0.5;
    SimPlayer? gk = p.isHome
        ? (awaySquad.isNotEmpty ? awaySquad[0] : null)
        : (homeSquad.isNotEmpty ? homeSquad[0] : null);
    int ref = gk?.fm['Refleks'] ?? 10;
    if (_rng.nextInt(25) < ref && gk != null) {
      _addLog("🧤 ${gk.data.name} kurtardı!", Colors.cyanAccent);
      ball.vel.x = (p.isHome ? -1 : 1) * 0.02;
      ball.vel.y = (_rng.nextDouble() - 0.5) * 0.05;
    } else {
      _addLog("🚀 ${p.data.name} vurdu!", Colors.white);
      double angle = atan2(gy - p.pos.y, gx - p.pos.x);
      double pwr = 0.06;
      ball.vel.x = cos(angle) * pwr;
      ball.vel.y = sin(angle) * pwr;
    }
  }

  void _triggerGoal(bool home) {
    setState(() {
      isGoal = true;
      if (home) {
        homeScore++;
        _addLog("GOOOL! EV SAHİBİ!", Colors.green);
      } else {
        awayScore++;
        _addLog("GOOOL! DEPLASMAN!", Colors.redAccent);
      }
      ball.vel.x = 0;
      ball.vel.y = 0;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted)
        setState(() {
          isGoal = false;
          _resetPositions(!home);
        });
    });
  }

  void _resetPositions(bool homeStarts) {
    ball.pos = Vector2(0.5, 0.5);
    ball.vel = Vector2(0, 0);
    _create(widget.myTeam, homeSquad, true);
    _create(widget.oppTeam, awaySquad, false);
    _tactics();
    ball.owner = homeStarts
        ? (homeSquad.isNotEmpty ? homeSquad.last : null)
        : (awaySquad.isNotEmpty ? awaySquad.last : null);
  }

  void _addLog(String m, Color c) {
    logs.insert(0, "${(tick / 60).toInt()}' $m");
    if (logs.length > 20) logs.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        Container(
            height: 80,
            color: Colors.grey[900],
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("$homeScore",
                      style: GoogleFonts.russoOne(
                          fontSize: 50, color: Colors.cyan)),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${(tick / 60).toInt()}'",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24)),
                        if (!isStarted)
                          ElevatedButton(
                              onPressed: _start,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text("BAŞLAT")),
                      ]),
                  Text("$awayScore",
                      style: GoogleFonts.russoOne(
                          fontSize: 50, color: Colors.red)),
                ])),
        Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30, width: 4),
                  // ASSET HATA KORUMASI:
                  image: DecorationImage(
                      image: AssetImage("assets/pitch_bg.png"),
                      fit: BoxFit.cover,
                      onError: (e, s) {}),
                  color: Colors.green[900]),
              child: Stack(children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                        width: 30,
                        height: 160,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white12))),
                Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                        width: 30,
                        height: 160,
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            color: Colors.white12))),
                ...homeSquad.map((p) => _dot(p, Colors.cyan)),
                ...awaySquad.map((p) => _dot(p, Colors.red)),
                AnimatedAlign(
                    duration: const Duration(milliseconds: 16),
                    alignment:
                        Alignment(ball.pos.x * 2 - 1, ball.pos.y * 2 - 1),
                    child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black, blurRadius: 5)
                            ]))),
                if (isGoal)
                  Center(
                      child: Text("GOL!",
                          style: GoogleFonts.russoOne(
                              fontSize: 100,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                    blurRadius: 20, color: Colors.green)
                              ])))
              ]),
            )),
        Expanded(
            flex: 2,
            child: Container(
                color: Colors.black,
                child: ListView(
                    children: logs
                        .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            child: Text(e,
                                style: const TextStyle(
                                    color: Colors.greenAccent))))
                        .toList())))
      ]),
    );
  }

  Widget _dot(SimPlayer p, Color c) => AnimatedAlign(
      duration: const Duration(milliseconds: 16),
      alignment: Alignment(p.pos.x * 2 - 1, p.pos.y * 2 - 1),
      child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2)),
          child: Center(
              child: Text(p.role[0],
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold)))));
}
