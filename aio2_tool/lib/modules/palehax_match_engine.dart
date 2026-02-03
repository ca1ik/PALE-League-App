import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart'; // Player modelini buradan alıyoruz

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam; // Senin Takımın
  final List<Player> oppTeam; // Rakip Takım

  const MatchEngineView(
      {super.key, required this.myTeam, required this.oppTeam});

  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView> {
  // Maç Durumu
  int homeScore = 0;
  int awayScore = 0;
  int time = 0;
  List<String> logs = [];
  bool isFinished = false;

  // Animasyon Pozisyonları (0.0 - 1.0 arası)
  double ballX = 0.5;
  double ballY = 0.5;
  bool isHomeAttack = true;

  @override
  void initState() {
    super.initState();
    _startMatch();
  }

  void _startMatch() async {
    // 10 Saniyelik Maç Döngüsü (Her saniye 9 dakika gibi işler)
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      setState(() {
        time = i * 9; // Dakika simülasyonu
        _calculateTurn();
      });
    }
    setState(() => isFinished = true);
  }

  // --- GELİŞMİŞ ALGORİTMA ---
  void _calculateTurn() {
    var rng = Random();

    // 1. Orta Saha Mücadelesi (Top Kimde?)
    // Rastgele bir orta saha oyuncusu seç
    Player myMid = _getRandomPlayer(widget.myTeam, "CDM") ??
        _getRandomPlayer(widget.myTeam, "CAM") ??
        widget.myTeam[0];
    Player oppMid = _getRandomPlayer(widget.oppTeam, "CDM") ??
        _getRandomPlayer(widget.oppTeam, "CAM") ??
        widget.oppTeam[0];

    // Stats: Pas + Dribbling vs Fizik + Defans
    int myPower =
        (myMid.getCardStats()['PAS']! + myMid.getCardStats()['DRI']!) ~/ 2;
    int oppPower =
        (oppMid.getCardStats()['PHY']! + oppMid.getCardStats()['DEF']!) ~/ 2;

    // Avantaj kimde?
    bool myTurn = (myPower + rng.nextInt(20)) > (oppPower + rng.nextInt(20));
    isHomeAttack = myTurn;

    // Saha Görselini Güncelle
    ballX = myTurn
        ? 0.7 + (rng.nextDouble() * 0.2)
        : 0.3 - (rng.nextDouble() * 0.2); // Rakip sahaya git
    ballY = 0.2 + (rng.nextDouble() * 0.6); // Rastgele kanat/merkez

    // 2. Gol Pozisyonu Hesaplama
    if (myTurn) {
      _attemptGoal(widget.myTeam, widget.oppTeam, true);
    } else {
      _attemptGoal(widget.oppTeam, widget.myTeam, false);
    }
  }

  void _attemptGoal(List<Player> attTeam, List<Player> defTeam, bool isMe) {
    var rng = Random();
    Player att = _getRandomPlayer(attTeam, "ST") ??
        _getRandomPlayer(attTeam, "RW") ??
        attTeam[0];
    Player def = _getRandomPlayer(defTeam, "CB") ??
        _getRandomPlayer(defTeam, "LB") ??
        defTeam[0];
    Player gk = _getRandomPlayer(defTeam, "GK") ?? defTeam[0];

    // İstatistik Çarpışması
    // Forvet: Şut + Dripling
    // Defans: Defans + Fizik
    int attScore =
        (att.getCardStats()['SHO']! * 0.6 + att.getCardStats()['DRI']! * 0.4)
            .toInt();
    int defScore = (def.getCardStats()['DEF']! * 0.5 +
            def.getCardStats()['PHY']! * 0.3 +
            gk.rating * 0.2)
        .toInt();

    // Gol İhtimali
    int chance = attScore - defScore + rng.nextInt(30); // Random faktör (Şans)

    if (chance > 20) {
      // GOL!
      if (isMe)
        homeScore++;
      else
        awayScore++;
      _addLog(
          "⚽ GOL! ${time}' - ${att.name} harika vurdu! (${gk.name} çaresiz)");
      // Topu filelere gönder
      ballX = isMe ? 0.95 : 0.05;
    } else if (chance > 5) {
      // KAÇTI
      _addLog("❌ ${time}' - ${att.name} şutunu çekti ama ${gk.name} kurtardı!");
      ballX = isMe ? 0.85 : 0.15; // Kaleci çizgisi
    } else {
      // TOP KAYBI
      _addLog(
          "🛡️ ${time}' - ${def.name}, ${att.name}'den topu tereyağından kıl çeker gibi aldı.");
    }
  }

  Player? _getRandomPlayer(List<Player> team, String posFilter) {
    var list = team.where((p) => p.position.contains(posFilter)).toList();
    if (list.isEmpty) return null;
    return list[Random().nextInt(list.length)];
  }

  void _addLog(String text) {
    // Listeyi kaydırmak için
    if (logs.length > 4) logs.removeAt(0);
    logs.add(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text("ULTIMATE VS SİMÜLASYONU",
            style: GoogleFonts.orbitron(color: Colors.amber, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // SKORBORD
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF1E1E24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _teamScore("BENİM TAKIM", homeScore, Colors.cyanAccent),
                Column(
                  children: [
                    Text("${time}'",
                        style: GoogleFonts.orbitron(
                            color: Colors.greenAccent, fontSize: 24)),
                    if (isFinished)
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text("ÇIKIŞ"))
                  ],
                ),
                _teamScore("RAKİP TAKIM", awayScore, Colors.redAccent),
              ],
            ),
          ),

          // FM TARZI SAHA GÖRÜNÜMÜ
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 5),
                  borderRadius: BorderRadius.circular(10),
                  image: const DecorationImage(
                      image: AssetImage("assets/pitch_bg.png"),
                      fit: BoxFit.cover)),
              child: Stack(
                children: [
                  // Saha Çizgileri (Opsiyonel, resim yoksa diye)
                  Center(
                      child: Container(
                          width: 2,
                          height: double.infinity,
                          color: Colors.white24)),
                  Center(
                      child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white24, width: 2)))),

                  // OYUNCU DOTLARI (Temsili)
                  ...List.generate(
                      5,
                      (i) => AnimatedPositioned(
                            duration: const Duration(seconds: 1),
                            left: (isHomeAttack ? 0.6 : 0.3) *
                                    MediaQuery.of(context).size.width *
                                    0.8 +
                                (Random().nextInt(50)),
                            top: 50.0 + (i * 40),
                            child: const Icon(Icons.circle,
                                size: 10, color: Colors.cyanAccent),
                          )),
                  ...List.generate(
                      5,
                      (i) => AnimatedPositioned(
                            duration: const Duration(seconds: 1),
                            left: (isHomeAttack ? 0.7 : 0.4) *
                                    MediaQuery.of(context).size.width *
                                    0.8 -
                                (Random().nextInt(50)),
                            top: 50.0 + (i * 40),
                            child: const Icon(Icons.circle,
                                size: 10, color: Colors.redAccent),
                          )),

                  // TOP (HAREKET EDEN)
                  AnimatedAlign(
                    duration: const Duration(seconds: 1),
                    alignment: Alignment(ballX * 2 - 1,
                        ballY * 2 - 1), // 0..1 aralığını -1..1'e çevir
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black),
                          boxShadow: [
                            const BoxShadow(
                                color: Colors.black54, blurRadius: 5)
                          ]),
                    ),
                  )
                ],
              ),
            ),
          ),

          // MAÇ LOGLARI (SPİKER)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MAÇ ANLATIMI",
                      style: GoogleFonts.orbitron(
                          color: Colors.grey, fontSize: 12)),
                  const Divider(color: Colors.white24),
                  ...logs
                      .map((log) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(log,
                                style: TextStyle(
                                    color: log.contains("GOL")
                                        ? Colors.greenAccent
                                        : (log.contains("kurtardı")
                                            ? Colors.orangeAccent
                                            : Colors.white),
                                    fontWeight: log.contains("GOL")
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                          ))
                      .toList()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _teamScore(String name, int score, Color color) {
    return Column(
      children: [
        Text(name, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        Text("$score",
            style: GoogleFonts.russoOne(color: Colors.white, fontSize: 40)),
      ],
    );
  }
}
