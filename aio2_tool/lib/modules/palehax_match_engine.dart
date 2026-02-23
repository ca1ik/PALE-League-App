import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// --- LOKASYON ---
class Pos {
  double x, y;
  Pos(this.x, this.y);
  double dist(Pos p) => sqrt(pow(x - p.x, 2) + pow(y - p.y, 2));
  @override
  String toString() => "($x, $y)";
}

// --- OYUNCU SİMÜLASYONU ---
class SimPlayer {
  final Player data;
  Pos pos, moveTarget;
  bool isHome; // Ev sahibi = mavi, rakip = kırmızı
  String role; // GK, DEF, MID, FWD
  Map<String, int> stats;

  SimPlayer({
    required this.data,
    required this.pos,
    required this.isHome,
    required this.role,
  })  : moveTarget = Pos(pos.x, pos.y),
        stats = data.getFMStats();

  bool get hasSpace {
    // Açık alana konumlanmış mı?
    return (isHome && pos.x > 0.6) || (!isHome && pos.x < 0.4);
  }
}

// --- TOP ---
class Ball {
  Pos pos;
  SimPlayer? owner; // Topa kimin sahip olduğu
  int passTicksRemaining = 0; // Pas havada ise kaç tick daha

  Ball() : pos = Pos(0.5, 0.5);
}

// --- MAÇLAMA ENGINE'İ ---
class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam, oppTeam;
  final Function(bool isWin) onMatchEnd;
  final bool isPlayerTeamAway; // Oyuncu kırmızı takım mı?

  const MatchEngineView({
    super.key,
    required this.myTeam,
    required this.oppTeam,
    required this.onMatchEnd,
    this.isPlayerTeamAway = true,
  });

  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView> {
  late Ball ball;
  late List<SimPlayer> homeTeam, awayTeam;
  int homeScore = 0, awayScore = 0;
  int matchMinute = 0;
  int tick = 0; // 60 tick = 1 saniye
  bool isStarted = false;
  bool isGoal = false;
  Timer? gameTimer;
  List<String> logs = [];
  final Random rng = Random();

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    ball = Ball();

    // Takımları oluştur
    homeTeam = [];
    awayTeam = [];

    if (widget.isPlayerTeamAway) {
      _createTeam(widget.oppTeam, homeTeam, true);
      _createTeam(widget.myTeam, awayTeam, false);
    } else {
      _createTeam(widget.myTeam, homeTeam, true);
      _createTeam(widget.oppTeam, awayTeam, false);
    }

    // Başlangıç pozisyonları
    _resetPositions();
  }

  void _createTeam(List<Player> players, List<SimPlayer> target, bool isHome) {
    target.clear();

    var sorted = List<Player>.from(players)
      ..sort((a, b) {
        int scoreRole(String pos) {
          if (pos.contains("GK")) return 0;
          if (pos.contains("DEF")) return 1;
          if (pos.contains("MID")) return 2;
          return 3;
        }

        return scoreRole(a.position).compareTo(scoreRole(b.position));
      });

    for (int i = 0; i < min(sorted.length, 7); i++) {
      String role = i == 0
          ? "GK"
          : i < 3
              ? "DEF"
              : i < 5
                  ? "MID"
                  : "FWD";

      double x = isHome ? 0.15 : 0.85;
      double y = 0.5 + (i - 3) * 0.2;

      if (role == "GK") {
        x = isHome ? 0.02 : 0.98;
      } else if (role == "DEF") {
        x = isHome ? 0.25 : 0.75;
      } else if (role == "MID") {
        x = isHome ? 0.5 : 0.5;
      } else {
        x = isHome ? 0.75 : 0.25;
      }

      target.add(SimPlayer(
        data: sorted[i],
        pos: Pos(x, y.clamp(0.05, 0.95)),
        isHome: isHome,
        role: role,
      ));
    }
  }

  void _resetPositions() {
    if (widget.isPlayerTeamAway) {
      ball.owner = awayTeam.where((p) => p.role == "FWD").firstOrNull;
      if (ball.owner == null) ball.owner = awayTeam.last;
    } else {
      ball.owner = homeTeam.where((p) => p.role == "FWD").firstOrNull;
      if (ball.owner == null) ball.owner = homeTeam.last;
    }
    ball.pos = Pos(ball.owner!.pos.x, ball.owner!.pos.y);
    _addLog("🎾 ${ball.owner?.data.name} topla başladı", Colors.green);
  }

  void _startMatch() {
    if (isStarted) return;
    isStarted = true;
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _update();
    });
  }

  void _update() {
    if (!mounted || tick >= 90 * 60 * 60) {
      gameTimer?.cancel();
      _endMatch();
      return;
    }

    tick++;
    if (tick % 60 == 0) matchMinute = tick ~/ 60;

    if (!isGoal) {
      _updateLogic();
    }

    if (tick % 2 == 0) setState(() {});
  }

  void _updateLogic() {
    var allPlayers = [...homeTeam, ...awayTeam];

    // --- TOP SAHIP İSE ---
    if (ball.owner != null) {
      var owner = ball.owner!;
      var opponents = owner.isHome ? awayTeam : homeTeam;

      // Rakip alanına git
      owner.moveTarget.x = owner.isHome ? 0.95 : 0.05;
      owner.moveTarget.y = 0.5 + (rng.nextDouble() - 0.5) * 0.3;

      // Yakındaki rakipler?
      var closeOpponents =
          opponents.where((o) => o.pos.dist(owner.pos) < 0.15).toList();

      // Şut kararı
      if ((owner.isHome && owner.pos.x > 0.8) ||
          (!owner.isHome && owner.pos.x < 0.2)) {
        if (rng.nextInt(100) <
            30 + (owner.stats['Şut'] ?? 10) - (closeOpponents.length * 10)) {
          _shoot(owner);
          return;
        }
      }

      // Pas kararı
      if (closeOpponents.isNotEmpty || rng.nextInt(100) < 60) {
        _pass(owner);
      }
    }

    // --- TOP SAHİB DEĞİLSE ---
    else if (ball.passTicksRemaining > 0) {
      ball.passTicksRemaining--;

      // Pas biterse birini aç
      if (ball.passTicksRemaining <= 0) {
        SimPlayer? receiver = _findNearestPlayer(ball.pos);
        if (receiver != null) {
          ball.owner = receiver;
          _addLog(
            "⚽ ${receiver.data.name} topladı",
            receiver.isHome ? Colors.cyan : Colors.red,
          );
        }
      }
    }

    // --- OYUNCU HAREKETI ---
    for (var p in allPlayers) {
      if (p == ball.owner) continue; // Sahip harita çizer

      // Savunma pozisyonu
      if (p.role == "GK") {
        p.moveTarget.x = p.isHome ? 0.02 : 0.98;
        p.moveTarget.y = 0.5;
      } else if (ball.owner != null && ball.owner!.isHome != p.isHome) {
        // Rakip takım - savunma
        var ballOwner = ball.owner!;
        p.moveTarget.x = ballOwner.pos.x + (p.isHome ? -0.2 : 0.2);
        p.moveTarget.y = ballOwner.pos.y + (rng.nextDouble() - 0.5) * 0.2;

        // Top kaputma şansı
        if (p.pos.dist(ballOwner.pos) < 0.04) {
          int def = p.stats['Defans'] ?? 10;
          int dri = ballOwner.stats['Dripling'] ?? 10;
          if (rng.nextInt(100) < 40 + (def - dri)) {
            ball.owner = p;
            _addLog(
              "⚔️ ${p.data.name} topladı!",
              Colors.orange,
            );
            return;
          }
        }
      } else if (ball.owner != null && ball.owner!.isHome == p.isHome) {
        // Kendi takım - destek
        if (p.role == "FWD") {
          p.moveTarget.x = ball.owner!.pos.x + (p.isHome ? 0.2 : -0.2);
          p.moveTarget.y = ball.owner!.pos.y + (rng.nextDouble() - 0.5) * 0.3;
        } else {
          p.moveTarget.x = ball.owner!.pos.x + (p.isHome ? -0.15 : 0.15);
          p.moveTarget.y = ball.owner!.pos.y + (rng.nextDouble() - 0.5) * 0.15;
        }
      }

      // Hareketi uygula
      _movePlayer(p);
    }
  }

  void _pass(SimPlayer passer) {
    var teammates = passer.isHome ? homeTeam : awayTeam;
    var options = teammates
        .where((t) =>
            t != passer &&
            ((passer.isHome && t.pos.x > passer.pos.x) ||
                (!passer.isHome && t.pos.x < passer.pos.x)))
        .toList();

    if (options.isEmpty) return;

    // Best target seç
    SimPlayer bestTarget = options[0];
    double bestScore = -1000;

    for (var target in options) {
      double score = 100;

      // Açık alana konumlanmışsa bonus
      if (target.hasSpace) score += 50;

      // Forvetle bonus
      if (target.role == "FWD") score += 30;

      // Uzak paslar riskli
      double dist = passer.pos.dist(target.pos);
      if (dist > 0.6) score -= 50;

      if (score > bestScore) {
        bestScore = score;
        bestTarget = target;
      }
    }

    // Pas hatasını hesapla
    int passSkill = passer.stats['Pas'] ?? 10;
    int errorChance = max(5, 30 - passSkill);

    if (rng.nextInt(100) < errorChance) {
      // Pas hatası
      var opponents = passer.isHome ? awayTeam : homeTeam;
      var interceptor = opponents.fold<SimPlayer?>(null, (best, o) {
        if (best == null) return o;
        return o.pos.dist(passer.pos) < best.pos.dist(passer.pos) ? o : best;
      });

      if (interceptor != null && rng.nextInt(100) < 50) {
        ball.owner = interceptor;
        _addLog(
          "❌ Pas hatası! ${interceptor.data.name} kapladı",
          Colors.red,
        );
        return;
      }
    }

    // Pas başarılı
    ball.owner = null;
    ball.passTicksRemaining =
        10 + (bestTarget.pos.dist(passer.pos) * 50).toInt();
    ball.pos = Pos(bestTarget.pos.x, bestTarget.pos.y);

    _addLog(
      "✓ ${passer.data.name} → ${bestTarget.data.name}",
      Colors.blue,
    );
  }

  void _shoot(SimPlayer shooter) {
    int shootSkill = shooter.stats['Şut'] ?? 10;
    int accuracy = 40 + shootSkill;

    ball.owner = null;
    ball.passTicksRemaining = 0;

    var gk = shooter.isHome ? awayTeam[0] : homeTeam[0];
    int reflexes = gk.stats['Refleks'] ?? 10;

    bool isGoalShotted = rng.nextInt(100) < accuracy;
    bool gkSaved = false;

    if (isGoalShotted) {
      gkSaved = rng.nextInt(100) < (30 + reflexes);
    }

    if (!isGoalShotted || gkSaved) {
      // İskaya veya kurtarıldı
      _addLog(
        gkSaved
            ? "🧤 ${gk.data.name} kurtardı!"
            : "❌ ${shooter.data.name} ıskayı çekti!",
        gkSaved ? Colors.cyanAccent : Colors.redAccent,
      );
      ball.pos = Pos(shooter.isHome ? 0.95 : 0.05, 0.5);
    } else {
      // GOL!
      _triggerGoal(shooter.isHome);
    }
  }

  void _triggerGoal(bool homeTeamScored) {
    isGoal = true;
    setState(() {
      if (homeTeamScored) {
        homeScore++;
        _addLog("⚽🔥 GOOOL! EV SAHİBİ!", Colors.green);
      } else {
        awayScore++;
        _addLog("⚽🔥 GOOOL! DEPLASMAN!", Colors.amber);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isGoal = false;
          _resetPositions();
        });
      }
    });
  }

  SimPlayer? _findNearestPlayer(Pos toPos) {
    var allPlayers = [...homeTeam, ...awayTeam];
    SimPlayer? nearest;
    double minDist = 1000;

    for (var p in allPlayers) {
      double d = p.pos.dist(toPos);
      if (d < minDist) {
        minDist = d;
        nearest = p;
      }
    }

    return nearest;
  }

  void _movePlayer(SimPlayer player) {
    double dx = player.moveTarget.x - player.pos.x;
    double dy = player.moveTarget.y - player.pos.y;
    double dist = sqrt(dx * dx + dy * dy);

    if (dist > 0.003) {
      double speed = 0.004 + ((player.stats['Hız'] ?? 11) * 0.00012);
      player.pos.x += (dx / dist) * speed;
      player.pos.y += (dy / dist) * speed;
    }

    // Sınırlar
    player.pos.x = player.pos.x.clamp(0.01, 0.99);
    player.pos.y = player.pos.y.clamp(0.01, 0.99);
  }

  void _endMatch() {
    if (mounted) {
      gameTimer?.cancel();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          widget.onMatchEnd(homeScore > awayScore);
        }
      });
    }
  }

  void _addLog(String message, Color color) {
    logs.insert(0, "$matchMinute' $message");
    if (logs.length > 15) logs.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    var playerColor = widget.isPlayerTeamAway ? Colors.red : Colors.cyan;
    var playerScore = widget.isPlayerTeamAway ? awayScore : homeScore;
    var oppScore = widget.isPlayerTeamAway ? homeScore : awayScore;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Skor
          Container(
            height: 80,
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  playerScore.toString(),
                  style: GoogleFonts.russoOne(
                    fontSize: 60,
                    color: playerColor,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${matchMinute.toStringAsFixed(0)}'",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isStarted)
                      ElevatedButton(
                        onPressed: _startMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text("BAŞLAT"),
                      ),
                  ],
                ),
                Text(
                  oppScore.toString(),
                  style: GoogleFonts.russoOne(
                    fontSize: 60,
                    color: widget.isPlayerTeamAway ? Colors.cyan : Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Sahası
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white30, width: 4),
                color: Colors.green[900],
              ),
              child: Stack(
                children: [
                  // Goller
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 25,
                      height: 130,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white10,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 25,
                      height: 130,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        color: Colors.white10,
                      ),
                    ),
                  ),
                  // Oyuncular
                  ...homeTeam.map((p) => _playerWidget(p, Colors.cyan)),
                  ...awayTeam.map((p) => _playerWidget(p, Colors.red)),
                  // Top
                  if (ball.owner != null)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 16),
                      left: ball.owner!.pos.x *
                              (MediaQuery.of(context).size.width - 40) -
                          7,
                      top: ball.owner!.pos.y * 400 - 7,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 16),
                      left: ball.pos.x *
                              (MediaQuery.of(context).size.width - 40) -
                          7,
                      top: ball.pos.y * 400 - 7,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.yellowAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Gol animasyonu
                  if (isGoal)
                    Center(
                      child: Text(
                        "GOOOOOOOL!",
                        style: GoogleFonts.russoOne(
                          fontSize: 80,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Loglar
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: ListView(
                children: logs
                    .map(
                      (log) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        child: Text(
                          log,
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerWidget(SimPlayer player, Color color) {
    return Positioned(
      left: player.pos.x * (MediaQuery.of(context).size.width - 40) - 12,
      top: player.pos.y * 400 - 12,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Text(
            player.role[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
