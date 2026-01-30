import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/player_data.dart';
import '../ui/fc_animated_card.dart';

class SquadBuilderModule extends StatefulWidget {
  final bool isTOTWMode;
  const SquadBuilderModule(
      {super.key, this.isTOTWMode = true}); // Varsayılan True

  @override
  State<SquadBuilderModule> createState() => _SquadBuilderModuleState();
}

class _SquadBuilderModuleState extends State<SquadBuilderModule> {
  final Map<String, Offset> positions = {
    "GK": const Offset(0.5, 0.88),
    "LCB": const Offset(0.25, 0.70),
    "RCB": const Offset(0.75, 0.70),
    "CM": const Offset(0.5, 0.50),
    "LW": const Offset(0.15, 0.25),
    "RW": const Offset(0.85, 0.25),
    "ST": const Offset(0.5, 0.15),
  };

  final Map<String, Player?> squad = {
    "GK": null,
    "LCB": null,
    "RCB": null,
    "CM": null,
    "LW": null,
    "RW": null,
    "ST": null
  };
  Box<Player>? playerBox; // Nullable yapıldı
  bool _isInitialized = false;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    // Kutu ismini main.dart'takiyle eşledik
    if (!Hive.isBoxOpen('palehax_players_v9')) {
      playerBox = await Hive.openBox<Player>('palehax_players_v9');
    } else {
      playerBox = Hive.box<Player>('palehax_players_v9');
    }
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized)
      return const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent));

    double squadRating = _calculateRating();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(children: [
        Expanded(
            flex: 3,
            child: Column(children: [
              Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("HAFTANIN 7'LİSİ (TOTW)",
                                  style: GoogleFonts.orbitron(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              const Text("Haftanın en formda 7'lisi.",
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12))
                            ]),
                        Row(children: [
                          const Text("TAKIM REYTİNGİ: ",
                              style: TextStyle(color: Colors.white70)),
                          Text(squadRating.toStringAsFixed(0),
                              style: GoogleFonts.russoOne(
                                  fontSize: 24,
                                  color: _getRatingColor(squadRating.toInt())))
                        ]),
                      ])),
              Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 4)),
                      child: Stack(children: [
                        Positioned.fill(
                            child: CustomPaint(painter: PitchPainter())),
                        ...positions.entries
                            .map((e) => _buildPositionSlot(e.key, e.value))
                            .toList()
                      ]))),
            ])),
        const SizedBox(width: 20),
        Expanded(
            flex: 1,
            child: Container(
                decoration: BoxDecoration(
                    color: const Color(0xFF15151A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10)),
                child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: TextField(
                          style: const TextStyle(color: Colors.white),
                          onChanged: (v) =>
                              setState(() => searchQuery = v.toLowerCase()),
                          decoration: InputDecoration(
                              hintText: "Oyuncu Ara...",
                              prefixIcon: const Icon(Icons.search,
                                  color: Colors.cyanAccent),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none)))),
                  Expanded(
                      child: ValueListenableBuilder(
                          valueListenable: playerBox!.listenable(),
                          builder: (context, Box<Player> box, _) {
                            final players = box.values
                                .where((p) =>
                                    p.name.toLowerCase().contains(searchQuery))
                                .toList();
                            return ListView.builder(
                                itemCount: players.length,
                                itemBuilder: (c, i) {
                                  final p = players[i];
                                  return Draggable<Player>(
                                      data: p,
                                      feedback: Material(
                                          color: Colors.transparent,
                                          child: Transform.scale(
                                              scale: 0.3,
                                              child:
                                                  FCAnimatedCard(player: p))),
                                      child: _buildSidebarPlayerTile(p));
                                });
                          }))
                ])))
      ]),
    );
  }

  Widget _buildPositionSlot(String posName, Offset relativePos) {
    Player? p = squad[posName];
    return Align(
        alignment: Alignment(relativePos.dx * 2 - 1, relativePos.dy * 2 - 1),
        child: DragTarget<Player>(
            onAccept: (player) => setState(() => squad[posName] = player),
            builder: (c, cand, rej) {
              return Container(
                  width: 130,
                  height: 180,
                  decoration: p == null
                      ? BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: cand.isNotEmpty
                                  ? Colors.cyanAccent
                                  : Colors.white24))
                      : null,
                  child: p == null
                      ? Center(
                          child: Text(posName,
                              style: GoogleFonts.russoOne(
                                  color: Colors.white30, fontSize: 24)))
                      : GestureDetector(
                          onDoubleTap: () =>
                              setState(() => squad[posName] = null),
                          child: Transform.scale(
                              scale: 0.45, child: FCAnimatedCard(player: p))));
            }));
  }

  Widget _buildSidebarPlayerTile(Player p) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(5)),
            child: Text("${p.rating}",
                style: TextStyle(
                    color: _getRatingColor(p.rating),
                    fontWeight: FontWeight.bold))),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          Text("${p.position} | ${p.cardType}",
              style: const TextStyle(color: Colors.white54, fontSize: 10))
        ])),
        const Icon(Icons.drag_indicator, color: Colors.white24)
      ]));
  double _calculateRating() {
    int total = 0;
    int count = 0;
    squad.forEach((k, v) {
      if (v != null) {
        total += v.rating;
        count++;
      }
    });
    return count == 0 ? 0 : total / count;
  }

  Color _getRatingColor(int r) => r >= 90
      ? const Color(0xFF00FFC2)
      : (r >= 80 ? Colors.amber : Colors.white);
}

class PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint lp = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lp);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), lp);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.15, lp);
    double bw = size.width * 0.6;
    double bh = size.height * 0.15;
    canvas.drawRect(Rect.fromLTWH((size.width - bw) / 2, 0, bw, bh), lp);
    canvas.drawRect(
        Rect.fromLTWH((size.width - bw) / 2, size.height - bh, bw, bh), lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
