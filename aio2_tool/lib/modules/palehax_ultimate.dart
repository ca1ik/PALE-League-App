import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';
import 'palehax_match_engine.dart';

class UltimateTeamProvider extends ChangeNotifier {
  List<Player> myClub = [];
  List<Player> startingXI = List.generate(
      7, (_) => Player(name: "BOŞ", rating: 0, position: "", playstyles: []));
  int secondsActive = 0;
  Timer? _timer;
  bool claimedFirstPack = false;
  bool claimed15m = false;
  bool claimed30m = false;

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsActive++;
      if (!claimed15m && secondsActive >= 900) notifyListeners();
      if (!claimed30m && secondsActive >= 1800) notifyListeners();
      notifyListeners();
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  void addPlayerToClub(Player p) {
    if (!myClub.any((e) => e.name == p.name && e.cardType == p.cardType)) {
      myClub.add(p);
      notifyListeners();
    }
  }

  void setStarter(int i, Player p) {
    startingXI[i] = p;
    notifyListeners();
  }

  void autoBuild() {
    startingXI = List.generate(
        7, (_) => Player(name: "BOŞ", rating: 0, position: "", playstyles: []));
    Set<String> used = {};
    var pool = List<Player>.from(myClub)
      ..sort((a, b) => b.rating.compareTo(a.rating));

    Player? find(List<String> pos, String stat) {
      Player? best;
      int m = -1;
      for (var p in pool) {
        if (used.contains(p.name)) continue;
        int statVal = (p.getFMStats()[stat] ?? 10);
        int posBonus = pos.any((x) => p.position.contains(x)) ? 50 : 0;
        int s = p.rating + statVal + posBonus;
        if (s > m) {
          m = s;
          best = p;
        }
      }
      if (best != null) used.add(best.name);
      return best;
    }

    startingXI[0] = find(["GK"], "Refleks") ?? startingXI[0];
    startingXI[1] = find(["DEF", "CB"], "Defans") ?? startingXI[1];
    startingXI[2] = find(["DEF", "LB", "RB"], "Defans") ?? startingXI[2];
    startingXI[3] = find(["MID", "CDM"], "Pas") ?? startingXI[3];
    startingXI[4] = find(["MID", "CAM"], "Vizyon") ?? startingXI[4];
    startingXI[5] = find(["ST", "FWD"], "Şut") ?? startingXI[5];
    startingXI[6] = find(["RW", "LW", "ST"], "Hız") ?? startingXI[6];
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UltimateTeamProvider>().startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    var prov = Provider.of<UltimateTeamProvider>(context);
    if (prov.myClub.isEmpty && !prov.claimedFirstPack) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _openStarter(context, prov));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
          title: Text("ULTIMATE TEAM",
              style: GoogleFonts.orbitron(color: Colors.amber)),
          actions: [
            ElevatedButton.icon(
                onPressed: () {
                  prov.autoBuild();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("En iyi kadro kuruldu!"),
                      backgroundColor: Colors.green));
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text("OTOMATİK DİZ"),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.indigo)),
            const SizedBox(width: 20)
          ]),
      body: Row(children: [
        Expanded(
            flex: 4,
            child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white12),
                    image: DecorationImage(
                        image: AssetImage("assets/pitch_bg.png"),
                        fit: BoxFit.cover,
                        opacity: 0.4,
                        onError: (e, s) {})),
                child: LayoutBuilder(builder: (c, cons) {
                  double w = cons.maxWidth, h = cons.maxHeight;
                  return Stack(children: [
                    _pos(context, 0, "GK", w * 0.5, h * 0.85),
                    _pos(context, 1, "DEF", w * 0.25, h * 0.65),
                    _pos(context, 2, "DEF", w * 0.75, h * 0.65),
                    _pos(context, 3, "MID", w * 0.4, h * 0.45),
                    _pos(context, 4, "MID", w * 0.6, h * 0.45),
                    _pos(context, 5, "FWD", w * 0.3, h * 0.25),
                    _pos(context, 6, "FWD", w * 0.7, h * 0.25),
                  ]);
                }))),
        Container(
            width: 380,
            color: const Color(0xFF15151E),
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              ElevatedButton(
                  onPressed: () => _vs(context, prov),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 60)),
                  child: const Text("ONLİNE VS AT",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold))),
              const Divider(color: Colors.white24, height: 30),
              _packs(context, prov),
              Expanded(
                  child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, childAspectRatio: 0.65),
                      itemCount: prov.myClub.length,
                      itemBuilder: (c, i) => Draggable<Player>(
                          data: prov.myClub[i],
                          feedback: SizedBox(
                              width: 80,
                              child: FCAnimatedCard(player: prov.myClub[i])),
                          child: InkWell(
                              onTap: () => _showFM(context, prov.myClub[i]),
                              child: FCAnimatedCard(player: prov.myClub[i])))))
            ]))
      ]),
    );
  }

  Widget _packs(BuildContext c, UltimateTeamProvider p) => Column(children: [
        if (!p.claimed15m && p.secondsActive >= 900)
          ElevatedButton(
              onPressed: () => _openPack(c, p, 1, 70, rid: 1),
              child: const Text("15DK ÖDÜLÜ (+70)")),
        if (!p.claimed30m && p.secondsActive >= 1800)
          ElevatedButton(
              onPressed: () => _openPack(c, p, 1, 75, rid: 2),
              child: const Text("30DK ÖDÜLÜ (+75)")),
      ]);

  Widget _pos(BuildContext context, int i, String l, double x, double y) {
    var p = context.watch<UltimateTeamProvider>().startingXI[i];
    return Positioned(
        left: x - 55,
        top: y - 75,
        child: DragTarget<Player>(
            onAccept: (d) =>
                context.read<UltimateTeamProvider>().setStarter(i, d),
            builder: (c, cand, rej) => SizedBox(
                width: 110,
                height: 150,
                child: p.rating > 0
                    ? InkWell(
                        onTap: () => _showFM(context, p),
                        child: FCAnimatedCard(player: p))
                    : Container(
                        color: Colors.black45,
                        child: Center(
                            child: Text(l,
                                style: const TextStyle(
                                    color: Colors.white38)))))));
  }

  void _vs(BuildContext context, UltimateTeamProvider prov) {
    var myTeam = prov.startingXI.where((p) => p.rating > 0).toList();
    if (myTeam.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lütfen 7 oyuncuyu da dizin!")));
      return;
    }
    double avg = myTeam.map((e) => e.rating).reduce((a, b) => a + b) / 7;
    var opp = List.generate(
        7,
        (i) => Player(
            name: "Rakip $i",
            rating: (avg + Random().nextInt(4) - 2).toInt(),
            position: i == 0 ? "GK" : "ST",
            playstyles: [],
            cardType: "Temel"));
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => MatchEngineView(
                myTeam: myTeam,
                oppTeam: opp,
                onMatchEnd: (w) {
                  Navigator.pop(context);
                  if (w)
                    _openPack(context, prov, 1, 75);
                  else
                    _openPack(context, prov, 1, 70);
                })));
  }

  void _showFM(BuildContext context, Player p) {
    var s = p.getFMStats();
    showDialog(
        context: context,
        builder: (c) => Dialog(
            backgroundColor: const Color(0xFF1E1E24),
            child: Container(
                width: 700,
                height: 500,
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  SizedBox(width: 200, child: FCAnimatedCard(player: p)),
                  const VerticalDivider(color: Colors.white12),
                  Expanded(
                      child: GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          children: s.entries
                              .map((e) => ListTile(
                                  title: Text(e.key,
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                  trailing: Text("${e.value}",
                                      style: TextStyle(
                                          color: e.value > 15
                                              ? Colors.green
                                              : Colors.amber,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold))))
                              .toList()))
                ]))));
  }

  Player _convert(dynamic row) {
    Map<String, int> st = {};
    List<PlayStyle> ps = [];
    try {
      if (row.statsJson != null)
        st = Map<String, int>.from(jsonDecode(row.statsJson));
    } catch (e) {}
    try {
      if (row.playStylesJson != null)
        ps = (jsonDecode(row.playStylesJson) as List)
            .map((e) => PlayStyle(e.toString()))
            .toList();
    } catch (e) {}
    return Player(
        name: row.name,
        rating: row.rating,
        position: row.position,
        playstyles: ps,
        cardType: row.cardType,
        team: row.team,
        stats: st,
        role: row.role ?? "Yok");
  }

  void _openStarter(BuildContext context, UltimateTeamProvider prov) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final raw = await db.watchAllPlayers().first;
    if (raw.isEmpty) return;

    var all = raw.map((r) => _convert(r)).toList();
    List<Player> pack = [];
    Random r = Random();
    void add(int n, int min, int max) {
      var sub = all.where((p) => p.rating >= min && p.rating < max).toList();
      for (int i = 0; i < n; i++)
        if (sub.isNotEmpty) pack.add(sub.removeAt(r.nextInt(sub.length)));
    }

    add(7, 70, 75);
    add(3, 75, 80);
    add(2, 80, 99);
    for (var p in pack) prov.addPlayerToClub(p);
    prov.claimedFirstPack = true;
    showDialog(
        context: context,
        builder: (c) => AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("HOŞ GELDİN! 12 KART KAZANDIN",
                style: TextStyle(color: Colors.amber)),
            content: SizedBox(
                width: 600,
                height: 200,
                child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: pack
                        .map((p) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: FCAnimatedCard(player: p)))
                        .toList()))));
  }

  void _openPack(
      BuildContext context, UltimateTeamProvider prov, int count, int min,
      {int? rid}) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final raw = await db.watchAllPlayers().first;
    var all = raw.map((r) => _convert(r)).toList();
    List<Player> pack = [];
    Random r = Random();
    for (int i = 0; i < count; i++) {
      var cand = all.where((p) => p.rating >= min).toList();
      if (cand.isEmpty) cand = all;
      pack.add(cand[r.nextInt(cand.length)]);
    }
    for (var p in pack) prov.addPlayerToClub(p);
    if (rid == 1) prov.claimed15m = true;
    if (rid == 2) prov.claimed30m = true;
    showDialog(
        context: context,
        builder: (c) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    border: Border.all(color: Colors.amber)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("PAKET AÇILDI!",
                      style: GoogleFonts.russoOne(
                          color: Colors.amber, fontSize: 30)),
                  SizedBox(
                      height: 250,
                      width: 400,
                      child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: pack
                              .map((p) => Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: FCAnimatedCard(player: p)))
                              .toList()))
                ]))));
  }
}
