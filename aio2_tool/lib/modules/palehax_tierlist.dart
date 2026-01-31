import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import '../data/player_data.dart' as pd;
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';

class TierListView extends StatefulWidget {
  final AppDatabase database;
  const TierListView({super.key, required this.database});

  @override
  State<TierListView> createState() => _TierListViewState();
}

class _TierListViewState extends State<TierListView> {
  final ScreenshotController screenshotController = ScreenshotController();
  String searchQuery = "";

  Map<String, List<pd.Player>> tiers = {
    "S": [],
    "A": [],
    "B": [],
    "C": [],
    "D": []
  };

  final Map<String, Color> tierColors = {
    "S": const Color(0xFFFF7F7F),
    "A": const Color(0xFFFFBF7F),
    "B": const Color(0xFFFFDF7F),
    "C": const Color(0xFFFFFF7F),
    "D": const Color(0xFFBFFF7F)
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("TIER LIST MAKER",
            style: GoogleFonts.orbitron(
                color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.download, color: Colors.greenAccent),
              onPressed: _saveTierList,
              tooltip: "PNG Olarak İndir")
        ],
      ),
      body: Row(
        children: [
          // SOL TARAF: TIER LIST (DÜZELTİLDİ: Column + Expanded yapısı)
          Expanded(
            flex: 4,
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: const Color(0xFF15151E),
                padding: const EdgeInsets.all(10),
                child: SingleChildScrollView(
                  // Donmayı engellemek için
                  child: Column(
                    children:
                        tiers.keys.map((key) => _buildTierRow(key)).toList(),
                  ),
                ),
              ),
            ),
          ),
          // SAĞ TARAF: OYUNCU HAVUZU
          Container(
            width: 350,
            decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.white10)),
                color: Color(0xFF101014)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Oyuncu Ara...",
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.cyanAccent),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<dynamic>>(
                      stream: widget.database.watchAllPlayers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        // Filtreleme
                        var playerList = snapshot.data!
                            .map((t) => _convertToPlayer(t))
                            .toList();
                        var players = playerList
                            .where((p) =>
                                p.name
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()) &&
                                p.cardType == "Temel")
                            .toList();
                        players.sort((a, b) => b.rating.compareTo(a.rating));

                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio:
                                      0.72, // FCAnimatedCard AspectRatio ile uyumlu
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10),
                          itemCount: players.length,
                          itemBuilder: (c, i) {
                            pd.Player p = players[i];
                            // Draggable feedback'i sadeleştirerek MouseTracker hatasını önlüyoruz
                            return Draggable<pd.Player>(
                              data: p,
                              feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                      width: 120,
                                      child: FCAnimatedCard(
                                          player: p, animateOnHover: false))),
                              childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: FCAnimatedCard(
                                      player: p, animateOnHover: false)),
                              child: FCAnimatedCard(
                                  player: p, animateOnHover: true),
                            );
                          },
                        );
                      }),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTierRow(String tierKey) {
    return DragTarget<pd.Player>(
      onAccept: (player) {
        setState(() {
          tiers.forEach((k, v) => v.removeWhere((p) => p.name == player.name));
          tiers[tierKey]!.add(player);
        });
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 5),
          constraints: const BoxConstraints(minHeight: 130),
          decoration: BoxDecoration(
              border: isHovering
                  ? Border.all(color: Colors.cyanAccent, width: 2)
                  : Border.all(color: Colors.white10),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 10)
                    ]
                  : [],
              color: Colors.white.withOpacity(0.02)),
          child: IntrinsicHeight(
            // Row yüksekliğini eşitlemek için
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                      color: tierColors[tierKey],
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(5))),
                  child: Center(
                      child: Text(tierKey,
                          style: GoogleFonts.russoOne(
                              fontSize: 40, color: Colors.black))),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: tiers[tierKey]!
                          .map((p) => GestureDetector(
                                onTap: () =>
                                    setState(() => tiers[tierKey]!.remove(p)),
                                child: SizedBox(
                                    width: 90,
                                    child: FCAnimatedCard(
                                        player: p, animateOnHover: false)),
                              ))
                          .toList(),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  pd.Player _convertToPlayer(dynamic t) {
    // Veritabanı objesinden pd.Player modeline dönüşüm
    return pd.Player(
        name: t.name,
        rating: t.rating,
        position: t.position,
        playstyles: [],
        cardType: t.cardType,
        team: t.team,
        stats: {},
        role: t.role);
  }

  void _saveTierList() async {
    final image = await screenshotController.capture();
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Görüntü yakalandı!"), backgroundColor: Colors.green));
    }
  }
}
