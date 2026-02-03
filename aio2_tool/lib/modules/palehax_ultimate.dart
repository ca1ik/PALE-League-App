import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';
import 'palehax_match_engine.dart'; // Maç motoru importu

class UltimateTeamProvider extends ChangeNotifier {
  List<Player> myClub = [];
  // 7 Kişilik Halı Saha Düzeni
  List<Player> startingXI = List.filled(
      7, Player(name: "BOŞ", rating: 0, position: "", playstyles: []));

  int secondsActive = 0;
  Timer? _timer;

  // Ödül Durumları
  bool claimedFirstPack = false;
  bool claimed15m = false;
  bool claimed30m = false;
  bool claimed1h = false;

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsActive++;
      notifyListeners();
    });
  }

  void stopTimer() => _timer?.cancel();

  void addPlayerToClub(Player p) {
    myClub.add(p);
    notifyListeners();
  }

  void setStarter(int index, Player p) {
    startingXI[index] = p;
    notifyListeners();
  }
}

class UltimateTeamView extends StatelessWidget {
  final AppDatabase database;
  const UltimateTeamView({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return const _UltimateBody();
  }
}

class _UltimateBody extends StatefulWidget {
  const _UltimateBody();
  @override
  State<_UltimateBody> createState() => _UltimateBodyState();
}

class _UltimateBodyState extends State<_UltimateBody> {
  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<UltimateTeamProvider>(context);

    // Otomatik Başlangıç Paketi (Eğer kulüp boşsa)
    if (provider.myClub.isEmpty && !provider.claimedFirstPack) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPack(context, provider, 7, 70, isStarter: true);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("MY ULTIMATE TEAM",
            style: GoogleFonts.orbitron(
                color: Colors.amber, fontWeight: FontWeight.bold)),
        actions: [
          Center(
              child: Text("Süre: ${provider.secondsActive ~/ 60} dk  ",
                  style: const TextStyle(color: Colors.white)))
        ],
      ),
      body: Row(children: [
        // --- 1. SOL TARAF: SAHA ---
        Expanded(
            flex: 4,
            child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                    image: const DecorationImage(
                        image: AssetImage("assets/pitch_bg.png"),
                        fit: BoxFit.cover,
                        opacity: 0.4)),
                child: LayoutBuilder(builder: (context, constraints) {
                  double w = constraints.maxWidth;
                  double h = constraints.maxHeight;
                  return Stack(children: [
                    _buildPos(context, 0, "GK", w * 0.5, h * 0.85),
                    _buildPos(context, 1, "DEF", w * 0.25, h * 0.65),
                    _buildPos(context, 2, "DEF", w * 0.75, h * 0.65),
                    _buildPos(context, 3, "MID", w * 0.4, h * 0.45),
                    _buildPos(context, 4, "MID", w * 0.6, h * 0.45),
                    _buildPos(context, 5, "FWD", w * 0.3, h * 0.2),
                    _buildPos(context, 6, "FWD", w * 0.7, h * 0.2),
                  ]);
                }))),

        // --- 2. SAĞ TARAF: KULÜP VE MENÜ ---
        Container(
            width: 400,
            color: const Color(0xFF15151E),
            padding: const EdgeInsets.all(15),
            child: Column(children: [
              // VS AT BUTONU
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 15),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 10),
                  icon: const Icon(Icons.sports_esports,
                      color: Colors.white, size: 28),
                  label: const Text("ONLİNE VS AT",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  onPressed: () => _startMatch(context, provider),
                ),
              ),

              _buildPackSection(context, provider),

              const Divider(color: Colors.white24, height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("KULÜBÜM",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text("${provider.myClub.length} Kart",
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),

              // KULÜP KARTLARI
              Expanded(
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10),
                      itemCount: provider.myClub.length,
                      itemBuilder: (c, i) {
                        return Draggable<Player>(
                            data: provider.myClub[i],
                            feedback: SizedBox(
                                width: 100,
                                child:
                                    FCAnimatedCard(player: provider.myClub[i])),
                            child: GestureDetector(
                                onTap: () {},
                                child: FCAnimatedCard(
                                    player: provider.myClub[i])));
                      }))
            ]))
      ]),
    );
  }

  Widget _buildPos(
      BuildContext context, int index, String label, double left, double top) {
    var provider = Provider.of<UltimateTeamProvider>(context);
    Player p = provider.startingXI[index];

    double cardW = 110;
    double cardH = 150;

    return Positioned(
      left: left - (cardW / 2),
      top: top - (cardH / 2),
      child: DragTarget<Player>(
        onAccept: (data) => provider.setStarter(index, data),
        builder: (context, candidate, rejected) {
          bool isHover = candidate.isNotEmpty;
          return Column(
            children: [
              Container(
                width: cardW,
                height: cardH,
                decoration: BoxDecoration(
                    color: isHover
                        ? Colors.green.withOpacity(0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10)),
                child: p.rating > 0
                    ? FCAnimatedCard(player: p)
                    : Container(
                        decoration: BoxDecoration(
                            color: Colors.black45,
                            border: Border.all(color: Colors.white24, width: 2),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add,
                                color: Colors.white54, size: 40),
                            Text(label,
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.bold))
                          ],
                        )),
              ),
              if (p.rating == 0)
                Container(
                  // DÜZELTİLEN KISIM BURASI:
                  margin: const EdgeInsets.only(
                      top: 5), // EdgeInsets.top() HATALIYDI
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(5)),
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
            ],
          );
        },
      ),
    );
  }

  void _startMatch(BuildContext context, UltimateTeamProvider provider) {
    List<Player> myTeam =
        provider.startingXI.where((p) => p.rating > 0).toList();
    if (myTeam.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Maça çıkmak için İLK 7'yi tamamlamalısın!"),
          backgroundColor: Colors.red));
      return;
    }

    double myAvg =
        myTeam.map((e) => e.rating).reduce((a, b) => a + b) / myTeam.length;
    Random r = Random();

    List<Player> oppTeam = List.generate(7, (i) {
      int rating = (myAvg + r.nextInt(10) - 5).toInt().clamp(60, 99);
      return Player(
          name: "Rakip $i",
          rating: rating,
          position: "GEN",
          playstyles: [],
          cardType: "Temel");
    });

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => MatchEngineView(
                myTeam: myTeam,
                oppTeam: oppTeam,
                onMatchEnd: (isWin) {
                  Navigator.pop(context);
                  if (isWin) {
                    _showMatchResult(context, "KAZANDIN!",
                        "+75 PAKET KAZANDIN!", Colors.green);
                    _openPack(context, provider, 1, 75);
                  } else {
                    _showMatchResult(context, "KAYBETTİN...",
                        "+70 TESELLİ PAKETİ", Colors.red);
                    _openPack(context, provider, 1, 70);
                  }
                })));
  }

  void _showMatchResult(
      BuildContext context, String title, String sub, Color color) {
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text(title,
                  style: GoogleFonts.russoOne(color: color, fontSize: 30)),
              content: Text(sub, style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text("TAMAM",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  Widget _buildPackSection(
      BuildContext context, UltimateTeamProvider provider) {
    return Column(children: [
      if (!provider.claimed15m && provider.secondsActive >= 900)
        _packButton("15 DK ÖDÜLÜ (+70)", Colors.green,
            () => _openPack(context, provider, 1, 70, rewardId: 1)),
      if (!provider.claimed30m && provider.secondsActive >= 1800)
        _packButton("30 DK ÖDÜLÜ (+75)", Colors.blue,
            () => _openPack(context, provider, 1, 75, rewardId: 2)),
      const SizedBox(height: 10),
      const Text("Maç yaparak daha iyi kartlar kazan!",
          style: TextStyle(color: Colors.grey, fontSize: 10))
    ]);
  }

  Widget _packButton(String text, Color color, VoidCallback onTap) {
    return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: onTap,
            child: Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white))));
  }

  void _openPack(BuildContext context, UltimateTeamProvider provider, int count,
      int minRating,
      {bool isStarter = false, int? rewardId}) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final rawList = await db.watchAllPlayers().first;

    List<Player> allPlayers = [];
    try {
      allPlayers = rawList
          .map((t) => Player(
              name: t.name,
              rating: t.rating,
              position: t.position,
              playstyles: [],
              cardType: t.cardType,
              team: t.team))
          .toList();
    } catch (e) {
      debugPrint("Hata: $e");
    }

    if (allPlayers.isEmpty) {
      allPlayers = [
        Player(
            name: "Yedek Oyuncu",
            rating: 75,
            position: "ST",
            playstyles: [],
            cardType: "Temel")
      ];
    }

    List<Player> newCards = [];
    Random rnd = Random();

    for (int i = 0; i < count; i++) {
      int roll = rnd.nextInt(100);
      int targetMin = minRating;
      int targetMax = minRating + 10;

      if (roll > 95) targetMin += 5;

      var candidates = allPlayers.where((p) => p.rating >= targetMin).toList();
      if (candidates.isEmpty) candidates = allPlayers;

      newCards.add(candidates[rnd.nextInt(candidates.length)]);
    }

    for (var p in newCards) provider.addPlayerToClub(p);

    if (isStarter) provider.claimedFirstPack = true;
    if (rewardId == 1) provider.claimed15m = true;
    if (rewardId == 2) provider.claimed30m = true;

    showDialog(
        context: context,
        builder: (c) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
                height: 450,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2),
                    boxShadow: [
                      const BoxShadow(color: Colors.amber, blurRadius: 20)
                    ]),
                child: Column(children: [
                  Text("PAKET AÇILDI!",
                      style: GoogleFonts.russoOne(
                          color: Colors.amber, fontSize: 30)),
                  const SizedBox(height: 20),
                  Expanded(
                      child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: newCards
                              .map((p) => Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: FCAnimatedCard(player: p)))
                              .toList()))
                ]))));
  }
}
