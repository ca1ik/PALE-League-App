import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';

class UltimateTeamProvider extends ChangeNotifier {
  List<Player> myClub = [];
  List<Player> startingXI = List.filled(
      7,
      Player(
          name: "BOŞ",
          rating: 0,
          position: "",
          playstyles: [])); // 7 Kişilik Kadro

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
    // Duplicate kontrolü yapılabilir, şimdilik direkt ekliyoruz
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
    return ChangeNotifierProvider(
      create: (_) => UltimateTeamProvider()..startTimer(),
      child: const _UltimateBody(),
    );
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
                  style: const TextStyle(color: Colors.white))),
        ],
      ),
      body: Row(
        children: [
          // SOL: KADRO (SAHA)
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/pitch_bg.png"),
                      fit: BoxFit.cover,
                      opacity: 0.3)),
              child: Stack(
                children: [
                  // 1-2-3-1 Formasyonu (7 Kişi)
                  _buildPosition(context, 0, "GK", 0.5, 0.9),
                  _buildPosition(context, 1, "DEF", 0.2, 0.7),
                  _buildPosition(context, 2, "DEF", 0.8, 0.7),
                  _buildPosition(context, 3, "MID", 0.5, 0.5),
                  _buildPosition(context, 4, "LW", 0.2, 0.3),
                  _buildPosition(context, 5, "RW", 0.8, 0.3),
                  _buildPosition(context, 6, "ST", 0.5, 0.15),
                ],
              ),
            ),
          ),

          // SAĞ: PAKEKLER VE DEPO
          Container(
            width: 350,
            color: const Color(0xFF15151E),
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildPackSection(provider),
                const Divider(color: Colors.white24),
                const Text("KULÜBÜM",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, childAspectRatio: 0.7),
                    itemCount: provider.myClub.length,
                    itemBuilder: (c, i) {
                      return Draggable<Player>(
                        data: provider.myClub[i],
                        feedback: SizedBox(
                            width: 80,
                            child: FCAnimatedCard(player: provider.myClub[i])),
                        child: GestureDetector(
                          onTap: () {/* Detay Göster */},
                          child: Transform.scale(
                              scale: 0.8,
                              child:
                                  FCAnimatedCard(player: provider.myClub[i])),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPosition(
      BuildContext context, int index, String label, double x, double y) {
    var provider = Provider.of<UltimateTeamProvider>(context);
    Player p = provider.startingXI[index];

    return Align(
      alignment: Alignment(x * 2 - 1, y * 2 - 1),
      child: DragTarget<Player>(
        onAccept: (data) => provider.setStarter(index, data),
        builder: (context, candidate, rejected) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              p.rating > 0
                  ? SizedBox(
                      width: 90, height: 120, child: FCAnimatedCard(player: p))
                  : Container(
                      width: 70,
                      height: 90,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black54,
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildPackSection(UltimateTeamProvider provider) {
    return Column(
      children: [
        if (!provider.claimedFirstPack)
          _packButton("BAŞLANGIÇ PAKETİ (5x +70)", Colors.purple,
              () => _openPack(provider, 5, 70, isStarter: true)),
        if (!provider.claimed15m && provider.secondsActive >= 900)
          _packButton("15 DK ÖDÜLÜ (+70)", Colors.green,
              () => _openPack(provider, 1, 70, rewardId: 1)),
        if (!provider.claimed30m && provider.secondsActive >= 1800)
          _packButton("30 DK ÖDÜLÜ (+75)", Colors.blue,
              () => _openPack(provider, 1, 75, rewardId: 2)),
        if (!provider.claimed1h && provider.secondsActive >= 3600)
          _packButton("1 SAAT ÖDÜLÜ (+80)", Colors.amber,
              () => _openPack(provider, 1, 80, rewardId: 3)),
        const SizedBox(height: 10),
        const Text("❓ Şans: 70-75 (%90) | 75-80 (%7) | 80-85 (%2) | 85+ (%1)",
            style: TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
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
                fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _openPack(UltimateTeamProvider provider, int count, int minRating,
      {bool isStarter = false, int? rewardId}) {
    List<Player> newCards = [];
    Random rnd = Random();

    // Basit bir mock oyuncu oluşturucu (Gerçekte veritabanından çekilmeli)
    // Burada algoritma simüle ediliyor
    for (int i = 0; i < count; i++) {
      int roll = rnd.nextInt(100);
      int baseR = minRating;
      if (roll < 90)
        baseR += rnd.nextInt(5); // %90
      else if (roll < 97)
        baseR = 75 + rnd.nextInt(5); // %7
      else if (roll < 99)
        baseR = 80 + rnd.nextInt(5); // %2
      else
        baseR = 85 + rnd.nextInt(14); // %1

      newCards.add(Player(
          name: "Oyuncu ${rnd.nextInt(1000)}",
          rating: baseR,
          position: "(9) ST",
          playstyles: [],
          cardType: "Temel",
          team: "Takımsız"));
    }

    // Provider'a ekle
    for (var p in newCards) {
      provider.addPlayerToClub(p);
    }

    // Durum güncelle
    if (isStarter) provider.claimedFirstPack = true;
    if (rewardId == 1) provider.claimed15m = true;
    if (rewardId == 2) provider.claimed30m = true;
    if (rewardId == 3) provider.claimed1h = true;

    // Animasyonlu Dialog Göster
    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          height: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber)),
          child: Column(children: [
            Text("PAKET AÇILDI!",
                style: GoogleFonts.russoOne(color: Colors.amber, fontSize: 30)),
            Expanded(
              child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: newCards
                      .map((p) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: FCAnimatedCard(player: p)))
                      .toList()),
            )
          ]),
        ),
      ),
    );
  }
}
