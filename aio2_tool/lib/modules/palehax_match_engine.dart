import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// --- GELİŞMİŞ SİMÜLASYON MODELLERİ ---
class SimPlayer {
  final Player data;
  double x; // 0.0 (Sol Kale) - 1.0 (Sağ Kale)
  double y; // 0.0 (Üst) - 1.0 (Alt)
  bool isHome;
  String role; // GK, DEF, MID, FWD
  double stamina; // Yorulma etkisi (İleride kullanılabilir)

  SimPlayer(this.data, this.x, this.y, this.isHome, this.role)
      : stamina = 100.0;
}

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam;
  final List<Player> oppTeam;
  final Function(bool isWin) onMatchEnd; // Maç sonu ödül için callback

  const MatchEngineView(
      {super.key,
      required this.myTeam,
      required this.oppTeam,
      required this.onMatchEnd});

  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView>
    with TickerProviderStateMixin {
  // Ayarlar
  int matchDuration = 30; // Saniye cinsinden
  bool isMatchStarted = false;
  bool isFinished = false;
  bool showGoalAnim = false; // Gol animasyonu tetikleyicisi
  String goalScorerName = "";

  // Skor
  int homeScore = 0;
  int awayScore = 0;

  // Saha Durumu
  List<SimPlayer> simHomeTeam = []; // 7 Kişi
  List<SimPlayer> simAwayTeam = []; // 7 Kişi
  SimPlayer? ballHolder; // Top kimde? (Null ise top boşta)

  // Top Konumu (Animasyonlu)
  double ballX = 0.5;
  double ballY = 0.5;

  List<String> logs = [];
  Timer? _gameLoop;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _setupPitch();
  }

  // --- 1. SAHA VE TAKIM KURULUMU (7vs7) ---
  void _setupPitch() {
    simHomeTeam.clear();
    simAwayTeam.clear();

    // Diziliş: 1 GK, 2 DEF, 2 MID, 2 FWD (Toplam 7)
    // Eğer gelen liste boyutları farklıysa da algoritma rol atar.
    _deployTeam(widget.myTeam, simHomeTeam, true);
    _deployTeam(widget.oppTeam, simAwayTeam, false);
  }

  void _deployTeam(List<Player> source, List<SimPlayer> target, bool isHome) {
    // Pozisyona göre sırala: GK -> DEF -> MID -> FWD
    var sorted = List<Player>.from(source);
    sorted.sort((a, b) =>
        _getPosWeight(a.position).compareTo(_getPosWeight(b.position)));

    // İlk 7 oyuncuyu al (Yedekler varsa kes)
    int count = min(sorted.length, 7);

    for (int i = 0; i < count; i++) {
      Player p = sorted[i];
      String role = _determineRole(p.position, i, count);

      // Başlangıç Koordinatları
      double startX = isHome ? 0.1 : 0.9; // GK Konumu
      double startY = 0.5;

      if (role == "GK") {
        startX = isHome ? 0.05 : 0.95;
        startY = 0.5;
      } else if (role == "DEF") {
        startX = isHome ? 0.25 : 0.75;
        startY = (i % 2 == 0) ? 0.3 : 0.7; // Biri yukarı biri aşağı
      } else if (role == "MID") {
        startX = isHome ? 0.5 : 0.5; // Santra çizgisi
        startY = (i % 2 == 0) ? 0.4 : 0.6;
      } else {
        // FWD
        startX = isHome ? 0.7 : 0.3;
        startY = (i % 2 == 0) ? 0.2 : 0.8; // Kanatlara açıl
      }

      target.add(SimPlayer(p, startX, startY, isHome, role));
    }
  }

  int _getPosWeight(String pos) {
    if (pos.contains("GK")) return 0;
    if (pos.contains("DEF") || pos.contains("CB") || pos.contains("LB"))
      return 1;
    if (pos.contains("CDM") || pos.contains("MID")) return 2;
    return 3;
  }

  String _determineRole(String pos, int index, int total) {
    if (index == 0) return "GK"; // İlk oyuncu hep kaleci
    if (index < 3) return "DEF"; // Sonraki 2
    if (index < 5) return "MID"; // Sonraki 2
    return "FWD"; // Kalanlar Forvet
  }

  // --- 2. OYUN DÖNGÜSÜ ---
  void _startMatch() {
    setState(() {
      isMatchStarted = true;
      isFinished = false;
      logs.clear();
      _addLog("🔊 HAKEM DÜDÜĞÜ ÇALDI! MAÇ BAŞLADI!");
      // Santra
      ballHolder = simHomeTeam.last; // Forvet başlar
      ballX = ballHolder!.x;
      ballY = ballHolder!.y;
    });

    // Her 250ms'de bir oyun mantığı çalışır (4 FPS Logic Update)
    // 30 sn maç = 120 döngü.
    int totalTicks = matchDuration * 4;

    _gameLoop = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_tick >= totalTicks) {
        _endMatch();
        timer.cancel();
      } else {
        _simulateStep();
        _tick++;
      }
    });
  }

  void _endMatch() {
    setState(() {
      isFinished = true;
      _addLog("🏁 MAÇ BİTTİ!");
      if (homeScore > awayScore) {
        _addLog("🏆 KAZANAN: EV SAHİBİ!");
      } else if (awayScore > homeScore) {
        _addLog("🏆 KAZANAN: DEPLASMAN!");
      } else {
        _addLog("🤝 BERABERE!");
      }
    });
    // Ödül Callback'i
    widget.onMatchEnd(homeScore > awayScore);
  }

  // --- 3. YAPAY ZEKA VE FİZİK MOTORU ---
  void _simulateStep() {
    if (showGoalAnim) return; // Gol sevinci varsa oyun dursun

    setState(() {
      Random rng = Random();

      // A) OYUNCU HAREKETLERİ (AI)
      _moveAllPlayers();

      // B) TOP SAHİBİ AKSİYONLARI
      if (ballHolder != null) {
        // Top ayakta: Sür, Pas Ver veya Şut Çek
        _handleBallHolderDecision(rng);
      } else {
        // Top boşta: En yakın oyuncu kapsın
        _handleLooseBall();
      }
    });
  }

  void _moveAllPlayers() {
    // Tüm oyuncular topa veya taktiksel konuma göre hareket eder
    for (var p in [...simHomeTeam, ...simAwayTeam]) {
      if (p == ballHolder)
        continue; // Top sahibi karar mekanizmasıyla hareket eder

      double targetX = p.x;
      double targetY = p.y;
      double speed = 0.03; // Temel hız

      // 1. Topa olan mesafe
      double distToBall = sqrt(pow(p.x - ballX, 2) + pow(p.y - ballY, 2));

      if (p.role == "GK") {
        // KALECİ MANTIĞI: Kalede kal, topa göre açı al
        double goalLine = p.isHome ? 0.02 : 0.98;
        targetX = goalLine;
        // Topun Y eksenini takip et ama kaleden çok uzaklaşma
        targetY = ballY.clamp(0.4, 0.6);
      } else {
        // SAHA OYUNCUSU MANTIĞI

        // a) Top Rakipteyse -> PRES YAP
        bool opponentHasBall =
            (ballHolder != null && ballHolder!.isHome != p.isHome);

        if (opponentHasBall) {
          if (distToBall < 0.3) {
            // Yakınsa topa koş (Pres)
            targetX = ballX;
            targetY = ballY;
            speed = 0.04; // Depar
          } else {
            // Uzaksa defans hattına çekil
            targetX = p.isHome ? ballX - 0.2 : ballX + 0.2;
            targetY = ballY; // Rakibi karşıla
          }
        }
        // b) Top Bizimkideyse -> BOŞA KAÇ / DESTEK OL
        else {
          // Hücum yönüne koş
          double attackDir = p.isHome ? 1.0 : -1.0;
          targetX = p.x + (attackDir * 0.05);

          // KÖŞE MANTIĞI: Eğer top köşedeyse (Korner bayrağına yakın)
          bool ballInCorner =
              (ballY < 0.15 || ballY > 0.85) && (ballX < 0.1 || ballX > 0.9);
          if (ballInCorner) {
            if (p.role == "FWD" || p.role == "MID") {
              // Ceza sahasına gir (Kafa topu için)
              targetX = p.isHome ? 0.85 : 0.15;
              targetY = 0.5 + (Random().nextDouble() * 0.2 - 0.1);
            } else {
              // Defanslar geride kalsın
              targetX = p.isHome ? 0.4 : 0.6;
            }
          }
        }
      }

      // Hareketi Uygula (Yumuşak Geçiş)
      double dx = targetX - p.x;
      double dy = targetY - p.y;
      // Normalize et ve hızla çarp
      double dist = sqrt(dx * dx + dy * dy);
      if (dist > 0) {
        p.x += (dx / dist) * speed;
        p.y += (dy / dist) * speed;
      }

      // Sınırları aşma
      p.x = p.x.clamp(0.01, 0.99);
      p.y = p.y.clamp(0.01, 0.99);
    }
  }

  void _handleBallHolderDecision(Random rng) {
    SimPlayer p = ballHolder!;

    // Topu sür (Hafif hareket)
    double attackDir = p.isHome ? 1.0 : -1.0;
    p.x += attackDir * 0.02; // Kaleye sür
    ballX = p.x;
    ballY = p.y;

    // RAKİP MÜDAHALESİ (TACKLE) KONTROLÜ
    SimPlayer? nearestOpponent;
    double minOppDist = 100.0;
    List<SimPlayer> opponents = p.isHome ? simAwayTeam : simHomeTeam;

    for (var opp in opponents) {
      double d = sqrt(pow(p.x - opp.x, 2) + pow(p.y - opp.y, 2));
      if (d < minOppDist) {
        minOppDist = d;
        nearestOpponent = opp;
      }
    }

    // Eğer rakip çok yakınsa (0.03 birim) -> TOP ÇALMA DENEMESİ
    if (minOppDist < 0.03 && nearestOpponent != null) {
      int defStat = 70; // Varsayılan
      int driStat = 80;
      // Şans faktörü: Defans + Random > Dripling
      if ((defStat + rng.nextInt(40)) > (driStat + rng.nextInt(20))) {
        // BAŞARILI MÜDAHALE
        _addLog(
            "⚔️ ${nearestOpponent.data.name}, ${p.data.name}'den topu söktü aldı!");
        ballHolder = nearestOpponent; // Top el değiştirdi
        return; // Tur bitti
      } else {
        // ÇALIM
        _addLog("🔥 ${p.data.name} rakibini çalımladı ve devam ediyor!");
      }
    }

    // ŞUT ÇEKME KARARI
    // Mesafe uygun mu? Ev sahibi > 0.75, Deplasman < 0.25
    bool inShootingRange = p.isHome ? p.x > 0.75 : p.x < 0.25;

    if (inShootingRange) {
      if (rng.nextInt(100) < 40) {
        // %40 Şut çekme ihtimali (Pas vermezse)
        _shoot(p, rng);
        return;
      }
    }

    // PAS VERME KARARI (Şut çekmediyse)
    if (rng.nextInt(100) < 30) {
      // %30 Pas ihtimali
      _pass(p);
    }
  }

  void _handleLooseBall() {
    // Top sahipsizse en yakın oyuncu kim?
    SimPlayer? nearest;
    double minDist = 100.0;

    for (var p in [...simHomeTeam, ...simAwayTeam]) {
      double d = sqrt(pow(p.x - ballX, 2) + pow(p.y - ballY, 2));
      if (d < minDist) {
        minDist = d;
        nearest = p;
      }
    }

    if (minDist < 0.05 && nearest != null) {
      ballHolder = nearest;
      _addLog("⚽ ${nearest.data.name} topu kontrolüne aldı.");
    }
  }

  void _pass(SimPlayer sender) {
    // Takım arkadaşı bul (İleride olan)
    List<SimPlayer> team = sender.isHome ? simHomeTeam : simAwayTeam;
    var candidates = team.where((t) => t != sender).toList();

    if (candidates.isEmpty) return;

    // En uygun aday (X olarak en ilerideki)
    candidates.sort((a, b) {
      if (sender.isHome) return b.x.compareTo(a.x);
      return a.x.compareTo(b.x);
    });

    // En iyi 2 adaydan birine at
    SimPlayer receiver =
        candidates[Random().nextInt(min(candidates.length, 2))];

    ballHolder = receiver;
    ballX = receiver.x;
    ballY = receiver.y;

    if (sender.isHome) homeScore; // Dummy logic to use var
    // _addLog("👟 Pas: ${sender.data.name} -> ${receiver.data.name}");
  }

  void _shoot(SimPlayer shooter, Random rng) {
    _addLog("🚀 ${shooter.data.name} kaleyi denedi...");
    ballHolder = null; // Top ayaktan çıktı

    // Kaleci Kurtarış Denemesi
    SimPlayer gk = shooter.isHome ? simAwayTeam.first : simHomeTeam.first;
    int shotPower = shooter.data.rating + rng.nextInt(30); // 75 + 15 = 90
    int savePower = gk.data.rating + rng.nextInt(30); // 80 + 10 = 90

    bool isGoal = shotPower > savePower;

    // Topu kaleye gönder (Görsel)
    double goalX = shooter.isHome ? 1.05 : -0.05; // Filelerin içi
    double goalY = 0.5; // Tam 90'a

    // Animasyonla top oraya gitsin (Basitçe teleport değil, bir sonraki frame'de orada olsun)
    ballX = goalX;
    ballY = goalY;

    if (isGoal) {
      _triggerGoal(shooter, shooter.isHome);
    } else {
      _addLog("🧤 ${gk.data.name} inanılmaz bir kurtarış yaptı!");
      // Top kalecide kalsın
      ballHolder = gk;
      ballX = gk.x;
      ballY = gk.y;
    }
  }

  void _triggerGoal(SimPlayer scorer, bool isHomeGoal) {
    setState(() {
      showGoalAnim = true;
      goalScorerName = scorer.data.name;
      if (isHomeGoal)
        homeScore++;
      else
        awayScore++;

      _addLog("⚽ GOOOOOOLLLL!!! ${scorer.data.name} attı!");
      if (_getLastPasser() != null) {
        _addLog("🅰️ Asist: ${_getLastPasser()}");
      }
    });

    // 2 Saniye Gol Sevinci, Sonra Santra
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showGoalAnim = false;
          _resetPitchAfterGoal();
        });
      }
    });
  }

  String? _getLastPasser() {
    // Basitlik adına null dönüyoruz, istenirse log geçmişinden son pası atan bulunabilir
    return null;
  }

  void _resetPitchAfterGoal() {
    // Herkesi kendi sahasına çek
    _setupPitch();
    // Topu yiyen takım başlar
    ballHolder = Random().nextBool() ? simHomeTeam.last : simAwayTeam.last;
    ballX = ballHolder!.x;
    ballY = ballHolder!.y;
    _addLog("📢 Santra yapılıyor...");
  }

  void _addLog(String text) {
    String timeStr = "${(_tick * (90 / (matchDuration * 4))).toInt()}'";
    logs.insert(0, "$timeStr $text");
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
        title: Text("ULTIMATE MATCH ENGINE",
            style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 16)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. SKORBORD
              _buildScoreBoard(),

              // 2. SAHA (Expanded ile yer kaplasın)
              Expanded(
                flex: 4,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 4),
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                          image: AssetImage("assets/pitch_bg.png"),
                          fit: BoxFit.cover)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // KALE DİREKLERİ (Görsel)
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: _GoalPost(isLeft: true)),
                        const Align(
                            alignment: Alignment.centerRight,
                            child: _GoalPost(isLeft: false)),

                        // OYUNCULAR
                        ...simHomeTeam
                            .map((p) => _buildPlayerDot(p, Colors.cyanAccent)),
                        ...simAwayTeam
                            .map((p) => _buildPlayerDot(p, Colors.redAccent)),

                        // TOP
                        AnimatedAlign(
                          duration: const Duration(
                              milliseconds: 250), // Logic hızıyla aynı
                          alignment: Alignment(ballX * 2 - 1, ballY * 2 - 1),
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.black, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black54, blurRadius: 5)
                                ]),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // 3. LOGLAR
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF0D0D12),
                  padding: const EdgeInsets.all(10),
                  child: ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (c, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                              logs[i].contains("GOL")
                                  ? Icons.sports_soccer
                                  : logs[i].contains("kurtardı")
                                      ? Icons.back_hand
                                      : Icons.circle,
                              size: 12,
                              color: logs[i].contains("GOL")
                                  ? Colors.greenAccent
                                  : Colors.white30),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(logs[i],
                                style: TextStyle(
                                    color: logs[i].contains("GOL")
                                        ? Colors.green
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: logs[i].contains("GOL")
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),

          // GOL ANİMASYONU (OVERLAY)
          if (showGoalAnim)
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 80, color: Colors.amber),
                    Text("GOOOOL!",
                        style: GoogleFonts.russoOne(
                            fontSize: 60, color: Colors.white)),
                    Text(goalScorerName,
                        style: GoogleFonts.orbitron(
                            fontSize: 30, color: Colors.cyanAccent)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: const Color(0xFF1E1E24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _teamScore("EV SAHİBİ", homeScore, Colors.cyanAccent),
          Column(
            children: [
              if (!isMatchStarted)
                ElevatedButton(
                    onPressed: _startMatch,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("BAŞLAT"))
              else
                Text(
                    isFinished
                        ? "MAÇ SONU"
                        : "${(_tick * (90 / (matchDuration * 4))).toInt()}'",
                    style: GoogleFonts.orbitron(
                        color: Colors.greenAccent, fontSize: 30)),
              if (isFinished)
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("ÇIKIŞ"))
            ],
          ),
          _teamScore("DEPLASMAN", awayScore, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _teamScore(String name, int score, Color color) {
    return Column(
      children: [
        Text(name,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        Text("$score",
            style: GoogleFonts.russoOne(color: Colors.white, fontSize: 40)),
      ],
    );
  }

  Widget _buildPlayerDot(SimPlayer p, Color color) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment(p.x * 2 - 1, p.y * 2 - 1),
      child: Container(
        width: 24, // Kartları biraz büyüttük
        height: 24,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white,
                width: p == ballHolder ? 3 : 1), // Top bendeyse kalın kenar
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)
            ]),
        child: Center(
          child: Text(p.role.substring(0, 1), // G, D, M, F
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ),
    );
  }
}

// Görsel Kale Direği
class _GoalPost extends StatelessWidget {
  final bool isLeft;
  const _GoalPost({required this.isLeft});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 80,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          color: Colors.white24,
          borderRadius: BorderRadius.horizontal(
              left: isLeft ? Radius.zero : const Radius.circular(10),
              right: isLeft ? const Radius.circular(10) : Radius.zero)),
    );
  }
}
