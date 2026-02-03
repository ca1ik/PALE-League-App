import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// Simülasyon için Oyuncu Wrapper'ı (Konum ve Durum takibi)
class SimPlayer {
  final Player data;
  double x; // 0.0 - 1.0 (Saha yatay)
  double y; // 0.0 - 1.0 (Saha dikey)
  bool isHome;

  SimPlayer(this.data, this.x, this.y, this.isHome);
}

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam;
  final List<Player> oppTeam;

  const MatchEngineView(
      {super.key, required this.myTeam, required this.oppTeam});

  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView>
    with TickerProviderStateMixin {
  // Ayarlar
  int matchDuration = 30; // Varsayılan 30 saniye
  bool isMatchStarted = false;
  bool isFinished = false;

  // Skor ve Stats
  int homeScore = 0;
  int awayScore = 0;
  int homePasses = 0;
  int awayPasses = 0;
  int homeShots = 0;
  int awayShots = 0;

  // Saha Durumu
  List<SimPlayer> simHomeTeam = [];
  List<SimPlayer> simAwayTeam = [];
  SimPlayer? ballHolder; // Top kimde?

  // Top Konumu (Animasyon için)
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

  // Sahaya Dizilim (Formasyon Mantığı)
  void _setupPitch() {
    simHomeTeam.clear();
    simAwayTeam.clear();

    // EV SAHİBİ (Soldan Sağa: GK -> ST)
    _deployTeam(widget.myTeam, simHomeTeam, true);
    // DEPLASMAN (Sağdan Sola: GK -> ST)
    _deployTeam(widget.oppTeam, simAwayTeam, false);
  }

  void _deployTeam(List<Player> source, List<SimPlayer> target, bool isHome) {
    // Basit mantık: GK en geride, diğerleri sıralı
    // Kaynak listedeki oyuncuları pozisyona göre sıralayalım
    // GK, DEF, MID, FWD
    var sorted = List<Player>.from(source);
    sorted.sort(
        (a, b) => _getPosIndex(a.position).compareTo(_getPosIndex(b.position)));

    for (int i = 0; i < sorted.length; i++) {
      // X Konumu: Takıma göre saha yerleşimi
      // Ev Sahibi: 0.05 (Kale) -> 0.45 (Orta Saha)
      // Deplasman: 0.95 (Kale) -> 0.55 (Orta Saha)
      double baseX = isHome
          ? 0.1 + (i / sorted.length) * 0.4
          : 0.9 - (i / sorted.length) * 0.4;

      // Y Konumu: Sahaya yayılma (0.2 - 0.8 arası)
      double baseY = 0.2 + (i % 3) * 0.3;

      target.add(SimPlayer(sorted[i], baseX, baseY, isHome));
    }
  }

  int _getPosIndex(String pos) {
    if (pos.contains("GK")) return 0;
    if (pos.contains("DEF") || pos.contains("CB") || pos.contains("LB"))
      return 1;
    if (pos.contains("MID") || pos.contains("CDM") || pos.contains("CAM"))
      return 2;
    return 3; // FWD, ST, RW, LW
  }

  void _startMatch() {
    setState(() {
      isMatchStarted = true;
      isFinished = false;
      logs.clear();
      _addLog("📢 HAKEM DÜDÜĞÜ ÇALDI! MAÇ BAŞLADI!");

      // Başlangıç vuruşu (Ev sahibi orta saha)
      ballHolder = simHomeTeam.last;
      ballX = ballHolder!.x;
      ballY = ballHolder!.y;
    });

    // Oyun Döngüsü (Her 500ms bir karar verilir)
    // 30 saniye = 60 tur. 10 saniye = 20 tur.
    int totalTicks = matchDuration * 2;

    _gameLoop = Timer.periodic(const Duration(milliseconds: 500), (timer) {
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
      _addLog("🏁 MAÇ SONA ERDİ!");
      _addLog("📊 İSTATİSTİKLER:");
      _addLog("🏠 Ev: $homeScore Gol | $homeShots Şut | $homePasses Pas");
      _addLog("✈️ Dep: $awayScore Gol | $awayShots Şut | $awayPasses Pas");
    });
  }

  // --- YAPAY ZEKA VE FİZİK ---
  void _simulateStep() {
    setState(() {
      var rng = Random();

      // 1. OYUNCU HAREKETLERİ (Herkes biraz hareket eder)
      _movePlayersTowardsBall();

      // 2. TOP SAHİBİ KARARI
      if (ballHolder != null) {
        // Top ayakta, karar ver: Pas mı, Şut mu, Çalım mı?

        // Şut Mesafesi? (Ev sahibi sağa, Deplasman sola saldırır)
        bool canShoot =
            ballHolder!.isHome ? ballHolder!.x > 0.75 : ballHolder!.x < 0.25;

        if (canShoot) {
          _attemptShoot();
        } else {
          // Pas verecek uygun arkadaş bul
          _attemptPass();
        }
      } else {
        // Top boşta (Gol sonrası vs), santraya dön
        ballHolder = _findNearestPlayer(0.5, 0.5);
      }

      // Top konumunu güncelle (Sahibi varsa ayağında)
      if (ballHolder != null) {
        // Hafif dripling efekti
        ballX = ballHolder!.x + (rng.nextDouble() * 0.02 - 0.01);
        ballY = ballHolder!.y + (rng.nextDouble() * 0.02 - 0.01);
      }
    });
  }

  void _movePlayersTowardsBall() {
    // Basit mantık: Herkes topa biraz yaklaşır ama kendi bölgesinden çok kopmaz
    // Hücum eden takım ileri çıkar, savunan geri çekilir
    bool homeAttacking = ballHolder?.isHome ?? true;

    for (var p in [...simHomeTeam, ...simAwayTeam]) {
      // Eğer top bendeyse hareket etmem (karar aşaması)
      if (p == ballHolder) continue;

      double targetX = p.x;

      // Takımca hareket
      if (p.isHome) {
        // Ev sahibi: Hücumdaysa sağa (1.0), defanstaysa sola (0.0) kay
        targetX += homeAttacking ? 0.02 : -0.02;
      } else {
        targetX += homeAttacking ? -0.02 : 0.02; // Deplasman tersi
      }

      // Sınırları aşma
      p.x = targetX.clamp(0.05, 0.95);

      // Dikeyde topa yaklaş (Pres)
      if ((p.y - ballY).abs() < 0.2) {
        p.y += (ballY - p.y) * 0.1;
      }
    }
  }

  void _attemptPass() {
    // Takım arkadaşı bul (İlerideki)
    List<SimPlayer> teammates = ballHolder!.isHome ? simHomeTeam : simAwayTeam;
    // Kendisi hariç
    var options = teammates.where((p) => p != ballHolder).toList();

    if (options.isEmpty) return;

    // En mantıklı pas (İleriye doğru olan)
    // Ev sahibi için X'i büyük olan, Deplasman için X'i küçük olan
    options.sort((a, b) {
      if (ballHolder!.isHome) return b.x.compareTo(a.x); // En ileri
      return a.x.compareTo(b.x); // En geri (aslında onlar için ileri)
    });

    // En iyi 2 seçenekten birine at
    SimPlayer receiver = options[Random().nextInt(min(options.length, 2))];

    // İstatistik Güncelle
    if (ballHolder!.isHome)
      homePasses++;
    else
      awayPasses++;

    // Log
    if (Random().nextBool()) {
      // Her pası yazma spam olur
      // _addLog("Pass: ${ballHolder!.data.name} -> ${receiver.data.name}");
    }

    // Topu aktar
    ballHolder = receiver;
  }

  void _attemptShoot() {
    var rng = Random();
    Player shooter = ballHolder!.data;

    // Şut İstatistiği
    if (ballHolder!.isHome)
      homeShots++;
    else
      awayShots++;

    // Kaleci Kim?
    SimPlayer gk = ballHolder!.isHome
        ? simAwayTeam.first
        : simHomeTeam.first; // Basitçe listenin ilki GK varsaydık

    // Gol Hesaplama: (Şut + Rastgele) vs (Kaleci Rating)
    int attackPower = shooter.rating + rng.nextInt(30);
    int defensePower = gk.data.rating + rng.nextInt(20);

    if (attackPower > defensePower) {
      // GOL!
      if (ballHolder!.isHome)
        homeScore++;
      else
        awayScore++;

      _addLog("⚽ GOOOLL!! ${shooter.name} fileleri havalandırdı!");
      _addLog("⏱️ Dakika: ${(_tick * (90 / (matchDuration * 2))).toInt()}'");

      // Santra yap
      ballHolder = null;
      _resetPositions();
    } else {
      // KAÇTI
      _addLog("❌ ${shooter.name} vurdu, ${gk.data.name} kurtardı!");
      // Topu kaleciye ver
      ballHolder = gk;
    }
  }

  void _resetPositions() {
    // Gol sonrası herkes yerine döner
    _setupPitch();
    // Topu yiyen takım başlar
    if (ballHolder == null) {
      // Rastgele santra
      ballHolder = Random().nextBool() ? simHomeTeam.last : simAwayTeam.last;
    }
  }

  SimPlayer _findNearestPlayer(double x, double y) {
    var all = [...simHomeTeam, ...simAwayTeam];
    all.sort((a, b) {
      double distA = pow(a.x - x, 2) + pow(a.y - y, 2).toDouble();
      double distB = pow(b.x - x, 2) + pow(b.y - y, 2).toDouble();
      return distA.compareTo(distB);
    });
    return all.first;
  }

  void _addLog(String text) {
    logs.insert(0, text); // En yeni en üstte
    if (logs.length > 50) logs.removeLast();
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
      body: Column(
        children: [
          // 1. ÜST PANEL (Skor ve Süre Seçimi)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            color: const Color(0xFF1E1E24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _teamScore("EV SAHİBİ", homeScore, Colors.cyanAccent),

                // Orta Kontrol
                Column(
                  children: [
                    if (!isMatchStarted) ...[
                      const Text("SÜRE SEÇ",
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      Row(
                        children: [
                          _timeBtn(10),
                          const SizedBox(width: 5),
                          _timeBtn(30),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                          onPressed: _startMatch,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text("BAŞLAT"))
                    ] else ...[
                      Text(
                          isFinished
                              ? "MAÇ SONU"
                              : "${(_tick * (90 / (matchDuration * 2))).toInt()}'",
                          style: GoogleFonts.orbitron(
                              color: Colors.greenAccent, fontSize: 30)),
                      if (isFinished)
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("ÇIKIŞ",
                                style: TextStyle(color: Colors.red)))
                    ]
                  ],
                ),

                _teamScore("DEPLASMAN", awayScore, Colors.redAccent),
              ],
            ),
          ),

          // 2. SAHA SİMÜLASYONU (Görsel)
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 4),
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                      image: AssetImage("assets/pitch_bg.png"),
                      fit: BoxFit.cover)),
              child: Stack(
                children: [
                  // Saha çizgileri (Görsellik)
                  Center(
                      child: Container(
                          width: 2,
                          height: double.infinity,
                          color: Colors.white12)),
                  Center(
                      child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white12, width: 2)))),

                  // OYUNCULAR
                  ...simHomeTeam
                      .map((p) => _buildPlayerDot(p, Colors.cyanAccent)),
                  ...simAwayTeam
                      .map((p) => _buildPlayerDot(p, Colors.redAccent)),

                  // TOP
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 500),
                    alignment: Alignment(ballX * 2 - 1, ballY * 2 - 1),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            const BoxShadow(color: Colors.black, blurRadius: 5)
                          ],
                          border: Border.all(color: Colors.black)),
                    ),
                  )
                ],
              ),
            ),
          ),

          // 3. LOGLAR VE İSTATİSTİKLER
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF0D0D12),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📢 CANLI ANLATIM",
                      style: GoogleFonts.orbitron(
                          color: Colors.white54, fontSize: 12)),
                  const Divider(color: Colors.white12),
                  Expanded(
                    child: ListView.builder(
                      reverse: false, // Yeni en üstte
                      itemCount: logs.length,
                      itemBuilder: (c, i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                                logs[i].contains("GOL")
                                    ? Icons.sports_soccer
                                    : logs[i].contains("MAÇ")
                                        ? Icons.flag
                                        : Icons.article,
                                size: 14,
                                color: logs[i].contains("GOL")
                                    ? Colors.green
                                    : Colors.grey),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(logs[i],
                                  style: TextStyle(
                                      color: logs[i].contains("GOL")
                                          ? Colors.greenAccent
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
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlayerDot(SimPlayer p, Color color) {
    return AnimatedAlign(
      duration: const Duration(milliseconds: 500),
      alignment: Alignment(p.x * 2 - 1, p.y * 2 - 1),
      child: Tooltip(
        message: "${p.data.name} (${p.data.position})",
        child: Container(
          width: p == ballHolder ? 18 : 14, // Top bendeyse büyük
          height: p == ballHolder ? 18 : 14,
          decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white, width: p == ballHolder ? 2 : 1),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 5)
              ]),
          child: Center(
            child: Text(
                p.data.position
                    .replaceAll(RegExp(r'[0-9()]'), '')
                    .substring(0, 1),
                style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ),
        ),
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
            style: GoogleFonts.russoOne(color: Colors.white, fontSize: 35)),
      ],
    );
  }

  Widget _timeBtn(int seconds) {
    bool isSelected = matchDuration == seconds;
    return GestureDetector(
      onTap: () => setState(() => matchDuration = seconds),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: isSelected ? Colors.amber : Colors.white10,
            borderRadius: BorderRadius.circular(5)),
        child: Text("${seconds}sn",
            style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10)),
      ),
    );
  }
}
