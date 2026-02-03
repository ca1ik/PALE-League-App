import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';
import 'palehax_match_engine.dart';

// ... (UltimateTeamProvider aynı kalacak) ...
class UltimateTeamProvider extends ChangeNotifier {
  List<Player> myClub = [];
  List<Player> startingXI = List.filled(
      7, Player(name: "BOŞ", rating: 0, position: "", playstyles: []));
  int secondsActive = 0;
  Timer? _timer;
  bool claimedFirstPack = false;
  bool claimed15m = false;
  bool claimed30m = false;
  bool claimed1h = false;

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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
  Widget build(BuildContext context) => const _UltimateBody();
}

class _UltimateBody extends StatefulWidget {
  const _UltimateBody();
  @override
  State<_UltimateBody> createState() => _UltimateBodyState();
}

class _UltimateBodyState extends State<_UltimateBody> {
  TeamTactic selectedTactic = TeamTactic.balanced;

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<UltimateTeamProvider>(context);

    // BAŞLANGIÇ PAKETİ (12 Kart)
    if (provider.myClub.isEmpty && !provider.claimedFirstPack) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openStarterPack(context, provider));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
          title: const Text("ULTIMATE TEAM"),
          backgroundColor: Colors.transparent),
      body: Row(children: [
        // SAHA (Sol)
        Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage("assets/pitch_bg.png"),
                      fit: BoxFit.cover)),
              child: Stack(children: [
                _buildPos(context, 0, "GK", 0.5, 0.9),
                _buildPos(context, 1, "DEF", 0.25, 0.7),
                _buildPos(context, 2, "DEF", 0.75, 0.7),
                _buildPos(context, 3, "MID", 0.4, 0.5),
                _buildPos(context, 4, "MID", 0.6, 0.5),
                _buildPos(context, 5, "FWD", 0.3, 0.25),
                _buildPos(context, 6, "FWD", 0.7, 0.25),
              ]),
            )),
        // KULÜP (Sağ)
        Container(
            width: 400,
            color: const Color(0xFF15151E),
            child: Column(children: [
              ElevatedButton(
                  onPressed: () => _startMatch(context, provider),
                  child: const Text("VS AT")),
              Expanded(
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, childAspectRatio: 0.7),
                      itemCount: provider.myClub.length,
                      itemBuilder: (c, i) => InkWell(
                            onTap: () => _showFMProfile(
                                context, provider.myClub[i]), // FM PROFİLİ AÇ
                            child: Draggable<Player>(
                                data: provider.myClub[i],
                                feedback: SizedBox(
                                    width: 80,
                                    child: FCAnimatedCard(
                                        player: provider.myClub[i])),
                                child:
                                    FCAnimatedCard(player: provider.myClub[i])),
                          )))
            ]))
      ]),
    );
  }

  Widget _buildPos(
      BuildContext context, int index, String label, double rx, double ry) {
    var provider = Provider.of<UltimateTeamProvider>(context);
    Player p = provider.startingXI[index];
    return Align(
        alignment: Alignment(rx * 2 - 1, ry * 2 - 1),
        child: DragTarget<Player>(
            onAccept: (d) => provider.setStarter(index, d),
            builder: (c, cand, rej) => SizedBox(
                width: 90,
                height: 120,
                child: p.rating > 0
                    ? InkWell(
                        onTap: () => _showFMProfile(context, p),
                        child: FCAnimatedCard(player: p))
                    : Container(
                        color: Colors.white10,
                        child: Center(
                            child: Text(label,
                                style:
                                    const TextStyle(color: Colors.white)))))));
  }

  // --- FM TARZI PROFİL PENCERESİ ---
  void _showFMProfile(BuildContext context, Player p) {
    var stats = p.getFMStats();
    showDialog(
        context: context,
        builder: (c) => Dialog(
              backgroundColor: const Color(0xFF1E1E24),
              child: Container(
                width: 800,
                height: 600,
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  // Sol: Kart ve Bilgi
                  Column(children: [
                    SizedBox(width: 200, child: FCAnimatedCard(player: p)),
                    const SizedBox(height: 20),
                    Text(p.name,
                        style: GoogleFonts.orbitron(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    Text(p.team, style: const TextStyle(color: Colors.grey)),
                  ]),
                  const VerticalDivider(color: Colors.white24),
                  // Sağ: Detaylı FM Statları
                  Expanded(
                      child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    children: stats.entries
                        .map((e) => _buildStatBar(e.key, e.value))
                        .toList(),
                  ))
                ]),
              ),
            ));
  }

  Widget _buildStatBar(String label, int value) {
    Color color =
        value > 15 ? Colors.green : (value > 10 ? Colors.amber : Colors.red);
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Expanded(
              flex: 2,
              child:
                  Text(label, style: const TextStyle(color: Colors.white70))),
          Container(
              width: 30,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(5)),
              child: Text("$value",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(
              flex: 3,
              child: LinearProgressIndicator(
                  value: value / 20,
                  color: color,
                  backgroundColor: Colors.white10))
        ]));
  }

  // --- 12 KARTLIK BAŞLANGIÇ PAKETİ ---
  void _openStarterPack(
      BuildContext context, UltimateTeamProvider provider) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final rawList = await db.watchAllPlayers().first;
    List<Player> all = [];
    try {
      all = rawList
          .map((t) => Player(
              name: t.name,
              rating: t.rating,
              position: t.position,
              playstyles: [],
              cardType: t.cardType,
              team: t.team))
          .toList();
    } catch (e) {}

    List<Player> pack = [];
    var p70 = all.where((p) => p.rating >= 70 && p.rating < 75).toList();
    var p75 = all.where((p) => p.rating >= 75 && p.rating < 80).toList();
    var p80 = all.where((p) => p.rating >= 80).toList();

    Random r = Random();
    // 7 tane 70-75
    for (int i = 0; i < 7; i++)
      if (p70.isNotEmpty) pack.add(p70.removeAt(r.nextInt(p70.length)));
    // 3 tane 75-80
    for (int i = 0; i < 3; i++)
      if (p75.isNotEmpty) pack.add(p75.removeAt(r.nextInt(p75.length)));
    // 2 tane 80+
    for (int i = 0; i < 2; i++)
      if (p80.isNotEmpty) pack.add(p80.removeAt(r.nextInt(p80.length)));

    for (var p in pack) provider.addPlayerToClub(p);
    provider.claimedFirstPack = true;
    // Popup kodları burada (kısalttım)
  }

  // (Diğer yardımcı metodlar aynı kalacak: _startMatch, _buildPackSection)
  void _startMatch(BuildContext context, UltimateTeamProvider provider) {
    // (Önceki kodun aynısı)
    List<Player> myTeam =
        provider.startingXI.where((p) => p.rating > 0).toList();
    if (myTeam.length < 5) return;
    List<Player> oppTeam = List.generate(
        7,
        (i) => Player(
            name: "Rakip $i",
            rating: 80,
            position: "(9) ST",
            playstyles: [],
            cardType: "Temel"));
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => MatchEngineView(
                myTeam: myTeam,
                oppTeam: oppTeam,
                myTactic: selectedTactic,
                onMatchEnd: (w) {})));
  }

  Widget _buildPackSection(
          BuildContext context, UltimateTeamProvider provider) =>
      Container();
}
