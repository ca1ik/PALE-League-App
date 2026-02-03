import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// --- GELİŞMİŞ FİZİK MODELLERİ ---

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

  double distanceTo(Vector2 v) => sqrt(pow(x - v.x, 2) + pow(y - v.y, 2));

  // Vektör normalizasyonu (Yön bulma)
  Vector2 normalized() {
    double len = sqrt(x * x + y * y);
    if (len == 0) return Vector2(0, 0);
    return Vector2(x / len, y / len);
  }
}

class SimPlayer {
  final Player data;
  Vector2 pos; // Anlık Konum
  Vector2 velocity; // Hız Vektörü
  Vector2 target; // Gitmek istediği yer

  bool isHome;
  String role; // GK, DEF, MID, FWD

  // FM Statları (1-20)
  late int pac, sho, pas, dri, def, phy;

  // Anlık Durum
  double stamina = 100.0;
  int actionCooldown = 0; // Yapay zeka düşünme süresi

  SimPlayer(this.data, double x, double y, this.isHome, this.role)
      : pos = Vector2(x, y),
        velocity = Vector2(0, 0),
        target = Vector2(x, y) {
    var stats = data.getFMStats();
    pac = stats['Hız']!;
    sho = stats['Şut']!;
    pas = stats['Pas']!;
    dri = stats['Dripling']!;
    def = stats['Defans']!;
    phy = stats['Fizik']!;
  }
}

class Ball {
  Vector2 pos;
  Vector2 velocity;
  SimPlayer? owner; // Top kimde? (Null ise serbest)

  Ball()
      : pos = Vector2(0.5, 0.5),
        velocity = Vector2(0, 0);
}

// --- ANA WIDGET ---

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam;
  final List<Player> oppTeam;
  final Function(bool isWin) onMatchEnd;

  const MatchEngineView({
    super.key,
    required this.myTeam,
    required this.oppTeam,
    required this.onMatchEnd,
  });

  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView>
    with SingleTickerProviderStateMixin {
  // Ayarlar
  final int fps = 60; // Saniyedeki kare sayısı
  final double friction = 0.96; // Zemin sürtünmesi (Top yavaşlar)
  final double playerSpeedBase = 0.002; // Oyuncu temel hızı

  late Timer _gameTimer;
  int _ticks = 0;
  int matchDurationSeconds = 45; // Maç süresi

  // Oyun Nesneleri
  List<SimPlayer> homeTeam = [];
  List<SimPlayer> awayTeam = [];
  Ball ball = Ball();

  // Skor ve Durum
  int homeScore = 0;
  int awayScore = 0;
  bool isGoalAnim = false;
  String goalText = "";
  List<String> logs = [];

  @override
  void initState() {
    super.initState();
    _initMatch();
  }

  void _initMatch() {
    // Takımları Sahaya Diz
    _deploySquad(widget.myTeam, homeTeam, true);
    _deploySquad(widget.oppTeam, awayTeam, false);

    // Topu Santraya Koy
    _resetKickOff(true);

    // Oyun Döngüsünü Başlat
    _gameTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (timer) {
      if (!mounted) return;
      if (_ticks >= matchDurationSeconds * fps) {
        _finishMatch();
      } else {
        _updatePhysics();
        _updateAI();
        setState(() {
          _ticks++;
        });
      }
    });

    _addLog("MAÇ BAŞLADI! Başarılar...");
  }

  void _deploySquad(List<Player> source, List<SimPlayer> target, bool isHome) {
    target.clear();
    // Sıralama: GK -> DEF -> MID -> FWD
    var sorted = List<Player>.from(source);
    // Basit bir sıralama mantığı
    sorted.sort((a, b) {
      int scoreA = a.position.contains("GK")
          ? 0
          : a.position.contains("DEF")
              ? 1
              : a.position.contains("MID")
                  ? 2
                  : 3;
      int scoreB = b.position.contains("GK")
          ? 0
          : b.position.contains("DEF")
              ? 1
              : b.position.contains("MID")
                  ? 2
                  : 3;
      return scoreA.compareTo(scoreB);
    });

    for (int i = 0; i < min(sorted.length, 7); i++) {
      Player p = sorted[i];
      String role = i == 0
          ? "GK"
          : i < 3
              ? "DEF"
              : i < 5
                  ? "MID"
                  : "FWD";

      // Başlangıç Koordinatları
      double x = isHome ? 0.1 : 0.9;
      double y = 0.5;

      if (role == "GK") {
        x = isHome ? 0.05 : 0.95;
        y = 0.5;
      } else if (role == "DEF") {
        x = isHome ? 0.25 : 0.75;
        y = (i % 2 == 0) ? 0.3 : 0.7;
      } else if (role == "MID") {
        x = isHome ? 0.5 : 0.5;
        y = (i % 2 == 0) ? 0.4 : 0.6;
      } // Santra
      else {
        x = isHome ? 0.75 : 0.25;
        y = 0.5;
      } // FWD

      target.add(SimPlayer(p, x, y, isHome, role));
    }
  }

  void _finishMatch() {
    _gameTimer.cancel();
    widget.onMatchEnd(homeScore > awayScore);
  }

  // --- FİZİK MOTORU ---
  void _updatePhysics() {
    if (isGoalAnim) return;

    // 1. Top Hareketi
    if (ball.owner == null) {
      // Top serbest, fizik kurallarına uy
      ball.pos.add(ball.velocity);
      ball.velocity.scale(friction); // Sürtünme

      // Duvarlardan Sekme (Wall Bounce)
      if (ball.pos.y <= 0.02 || ball.pos.y >= 0.98) {
        ball.velocity.y *= -0.8; // Esneklik kaybı ile sekme
        ball.pos.y = ball.pos.y.clamp(0.02, 0.98);
      }

      // Kale Arkası (Korner yok, duvar var)
      if ((ball.pos.x < 0.0 && (ball.pos.y < 0.35 || ball.pos.y > 0.65)) ||
          (ball.pos.x > 1.0 && (ball.pos.y < 0.35 || ball.pos.y > 0.65))) {
        ball.velocity.x *= -0.8;
        ball.pos.x = ball.pos.x.clamp(0.0, 1.0);
      }

      // GOL KONTROLÜ
      if (ball.pos.x < -0.05 && ball.pos.y > 0.35 && ball.pos.y < 0.65) {
        _goalScored(false); // Deplasman attı
      } else if (ball.pos.x > 1.05 && ball.pos.y > 0.35 && ball.pos.y < 0.65) {
        _goalScored(true); // Ev sahibi attı
      }
    } else {
      // Top oyuncuda, oyuncuyla beraber hareket et
      // Oyuncu dribbling yaparken topu biraz önünde tutar
      double offsetX = ball.owner!.isHome ? 0.015 : -0.015;
      ball.pos.x = ball.owner!.pos.x + offsetX;
      ball.pos.y = ball.owner!.pos.y;
      ball.velocity.x = 0;
      ball.velocity.y = 0;
    }

    // 2. Oyuncu Hareketi (İvmelenme mantığı)
    for (var p in [...homeTeam, ...awayTeam]) {
      // Hedefe doğru vektör
      double dx = p.target.x - p.pos.x;
      double dy = p.target.y - p.pos.y;
      double dist = sqrt(dx * dx + dy * dy);

      if (dist > 0.005) {
        // Hız Statına Göre Hareket
        // Hız 1 ise -> 0.002, Hız 20 ise -> 0.005
        double speed = playerSpeedBase + (p.pac * 0.00015);
        if (p == ball.owner) speed *= 0.85; // Topla koşan yavaşlar

        p.pos.x += (dx / dist) * speed;
        p.pos.y += (dy / dist) * speed;
      }

      // Saha Sınırları
      p.pos.x = p.pos.x.clamp(0.01, 0.99);
      p.pos.y = p.pos.y.clamp(0.01, 0.99);
    }
  }

  // --- YAPAY ZEKA (AI) ---
  void _updateAI() {
    if (isGoalAnim) return;
    Random rng = Random();
    List<SimPlayer> allPlayers = [...homeTeam, ...awayTeam];

    // 1. TOP KAPMA VE SAHİPLENME
    if (ball.owner == null) {
      // Topa en yakın oyuncuyu bul
      SimPlayer? nearest;
      double minDist = 100.0;
      for (var p in allPlayers) {
        double d = p.pos.distanceTo(ball.pos);
        if (d < minDist) {
          minDist = d;
          nearest = p;
        }
      }

      // Topa koş
      if (nearest != null) {
        nearest.target = Vector2(ball.pos.x, ball.pos.y);

        // Topu alma mesafesi
        if (minDist < 0.02) {
          ball.owner = nearest;
          // _addLog("${nearest.data.name} topu kontrol etti.");
        }
      }
    }

    // 2. TOP SAHİBİ KARARLARI
    if (ball.owner != null) {
      SimPlayer p = ball.owner!;
      p.actionCooldown++;

      // Rakip oyuncu yakınlığı (Pres)
      SimPlayer? nearestOpponent;
      double oppDist = 100.0;
      for (var opp in allPlayers) {
        if (opp.isHome != p.isHome) {
          double d = p.pos.distanceTo(opp.pos);
          if (d < oppDist) {
            oppDist = d;
            nearestOpponent = opp;
          }
        }
      }

      // TACKLE (Top Çalma)
      if (oppDist < 0.02 && nearestOpponent != null) {
        // Defans vs Dripling
        int rollDef = nearestOpponent.def + rng.nextInt(10);
        int rollDri = p.dri + rng.nextInt(10);

        if (rollDef > rollDri) {
          _addLog("⚔️ ${nearestOpponent.data.name} topu kazandı!");
          ball.owner = nearestOpponent;
          p.actionCooldown = -20; // Kaybeden afallar
          return;
        }
      }

      // Karar Verme (Her 10 frame'de bir veya baskı altındaysa)
      if (p.actionCooldown > 20 || (oppDist < 0.1 && p.actionCooldown > 5)) {
        p.actionCooldown = 0;

        // Şut Mesafesi?
        bool canShoot = p.isHome ? p.pos.x > 0.75 : p.pos.x < 0.25;

        if (canShoot) {
          // Şut Çek (%30 + Şut Statı)
          if (rng.nextInt(40) < p.sho) {
            _actionShoot(p);
            return;
          }
        }

        // Pas Ver (%50 + Vizyon)
        if (rng.nextInt(30) < p.pas) {
          _actionPass(p);
          return;
        }

        // Dripling Yap (Hedef kale)
        p.target.x = p.isHome ? 1.0 : 0.0;
        p.target.y = 0.5;

        // Önünde adam varsa kenara kay (Wall Dribble)
        if (oppDist < 0.15 && nearestOpponent != null) {
          if (p.pos.y > nearestOpponent.pos.y)
            p.target.y = 0.9;
          else
            p.target.y = 0.1;
        }
      }
    }

    // 3. TOP SUZ OYUNCULARIN HAREKETİ
    for (var p in allPlayers) {
      if (p == ball.owner) continue;

      // Varsayılan Formasyon Konumu (BaseX, BaseY)
      // Bunu SimPlayer içinde tutmadık, burada dinamik hesaplayalım
      double formX = 0.5, formY = 0.5;

      // Basit rol konumu (setup kısmındaki gibi)
      if (p.role == "GK") {
        formX = p.isHome ? 0.05 : 0.95;
      } else if (p.role == "DEF") {
        formX = p.isHome ? 0.25 : 0.75;
      } else if (p.role == "MID") {
        formX = 0.5;
      } else {
        formX = p.isHome ? 0.75 : 0.25;
      } // FWD

      // Topun konumuna göre kayma (Shift)
      double shiftX = (ball.pos.x - 0.5) * 0.5;

      // Hücumdaysak ileri çık, defanstaysak geri gel
      bool attacking = (ball.owner != null && ball.owner!.isHome == p.isHome);

      if (p.role != "GK") {
        if (attacking) {
          // Boşa kaç
          p.target.x = formX + shiftX + (p.isHome ? 0.1 : -0.1);
          p.target.y =
              ball.pos.y + (p.pos.y > 0.5 ? 0.2 : -0.2); // Pas kanalı aç
        } else {
          // Markaj / Kademe
          p.target.x = formX + shiftX;
          // Top ile kale arasına gir
          p.target.y = ball.pos.y * 0.5 + 0.25;
        }
      } else {
        // Kaleci topu takip eder
        p.target.y = ball.pos.y.clamp(0.4, 0.6);
      }
    }
  }

  // --- AKSİYONLAR ---

  void _actionPass(SimPlayer p) {
    Random rng = Random();
    List<SimPlayer> mates = p.isHome ? homeTeam : awayTeam;
    // İlerideki boş arkadaşı bul
    var candidates = mates
        .where(
            (m) => m != p && (p.isHome ? m.pos.x > p.pos.x : m.pos.x < p.pos.x))
        .toList();

    if (candidates.isNotEmpty) {
      SimPlayer target = candidates[rng.nextInt(candidates.length)];

      // Pas Hatası Hesabı (20 üzerinden stat)
      // Pas=20 -> Hata 0.0, Pas=1 -> Hata 0.4 radyan
      double error = (20 - p.pas) * 0.02;
      double angle = atan2(target.pos.y - p.pos.y, target.pos.x - p.pos.x);
      angle += (rng.nextDouble() - 0.5) * error;

      double power = 0.025 + (p.phy * 0.0005); // Sert pas

      ball.owner = null;
      ball.velocity.x = cos(angle) * power;
      ball.velocity.y = sin(angle) * power;

      // _addLog("👟 ${p.data.name} pas verdi.");
    }
  }

  void _actionShoot(SimPlayer p) {
    Random rng = Random();

    // Hedef Kale
    double tx = p.isHome ? 1.0 : 0.0;
    double ty = 0.5; // 90'a asmak ister

    // Şut Hatası
    double error = (20 - p.sho) * 0.015;
    double angle = atan2(ty - p.pos.y, tx - p.pos.x);
    angle += (rng.nextDouble() - 0.5) * error;

    double power = 0.045 + (p.phy * 0.001); // Roket şut

    ball.owner = null;
    ball.velocity.x = cos(angle) * power;
    ball.velocity.y = sin(angle) * power;

    _addLog("🚀 ${p.data.name} kaleyi yokladı!");
  }

  void _goalScored(bool home) {
    setState(() {
      isGoalAnim = true;
      if (home) {
        homeScore++;
        goalText = "GOOOL! EV SAHİBİ!";
      } else {
        awayScore++;
        goalText = "GOOOL! DEPLASMAN!";
      }
      _addLog(goalText);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isGoalAnim = false;
          _resetKickOff(!home);
        });
      }
    });
  }

  void _resetKickOff(bool homeStarts) {
    ball.pos = Vector2(0.5, 0.5);
    ball.velocity = Vector2(0, 0);
    // Santra yapan takımın forvetine ver
    ball.owner = homeStarts ? homeTeam.last : awayTeam.last;

    // Herkesi resetle
    for (var p in [...homeTeam, ...awayTeam]) {
      // Setup'taki mantıkla yaklaşık yerlerine ışınla (Basitlik için)
      // Gerçekçilik için koşarak dönmeleri lazım ama süre kısıtlı
      if (p.role == "GK")
        p.pos.x = p.isHome ? 0.05 : 0.95;
      else if (p.role == "FWD")
        p.pos.x = p.isHome ? 0.55 : 0.45; // Santra
      else
        p.pos.x = p.isHome ? 0.25 : 0.75;
    }
  }

  void _addLog(String t) {
    int min = (_ticks / fps / 60 * 90).toInt(); // Dakika hesabı
    logs.insert(0, "$min' $t");
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      appBar: AppBar(
          title: const Text("PRO SİMÜLASYON"),
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false),
      body: Column(
        children: [
          // SKORBORD
          Container(
            height: 80,
            color: const Color(0xFF202020),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("$homeScore",
                      style: GoogleFonts.russoOne(
                          fontSize: 50, color: Colors.cyan)),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("${(_ticks / fps / 60 * 90).toInt()}'",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20)),
                        const Text("CANLI",
                            style: TextStyle(color: Colors.green, fontSize: 10))
                      ]),
                  Text("$awayScore",
                      style: GoogleFonts.russoOne(
                          fontSize: 50, color: Colors.red)),
                ]),
          ),

          // SAHA
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 4),
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                      image: AssetImage("assets/pitch_bg.png"),
                      fit: BoxFit.cover)),
              child: ClipRect(
                child: Stack(
                  children: [
                    // OYUNCULAR
                    ...homeTeam.map((p) => _buildPlayer(p, Colors.cyan)),
                    ...awayTeam.map((p) => _buildPlayer(p, Colors.red)),

                    // TOP
                    AnimatedAlign(
                      duration:
                          const Duration(milliseconds: 16), // 60 FPS akıcılık
                      alignment:
                          Alignment(ball.pos.x * 2 - 1, ball.pos.y * 2 - 1),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 4)
                            ]),
                      ),
                    ),

                    // GOL OVERLAY
                    if (isGoalAnim)
                      Center(
                          child: Text("GOL!",
                              style: GoogleFonts.russoOne(
                                  fontSize: 100, color: Colors.white)))
                  ],
                ),
              ),
            ),
          ),

          // LOGLAR
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (c, i) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Text(logs[i],
                      style: TextStyle(
                          color: logs[i].contains("GOL")
                              ? Colors.greenAccent
                              : Colors.white70,
                          fontSize: 12)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlayer(SimPlayer p, Color c) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 100), // Hareket yumuşatma
      alignment: Alignment(p.pos.x * 2 - 1, p.pos.y * 2 - 1),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white),
            boxShadow: [BoxShadow(color: c.withOpacity(0.5), blurRadius: 5)]),
        child: Center(
            child: Text(p.role[0],
                style:
                    const TextStyle(fontSize: 8, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
