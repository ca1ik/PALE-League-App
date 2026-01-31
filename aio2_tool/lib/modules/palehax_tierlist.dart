import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart'; // Dosya kaydı için gerekli
import '../data/player_data.dart';
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
  Map<String, List<Player>> tiers = {
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
            tooltip: "PNG Olarak İndir",
          )
        ],
      ),
      body: Row(
        children: [
          // SOL TARAF: TIER LIST ALANI
          Expanded(
            flex: 3,
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: const Color(0xFF15151E),
                padding: const EdgeInsets.all(10),
                child: ListView(
                  children:
                      tiers.keys.map((key) => _buildTierRow(key)).toList(),
                ),
              ),
            ),
          ),
          // SAĞ TARAF: OYUNCU HAVUZU
          Container(
            width: 300,
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
                        // Sadece temel kartları ve yüksek reytinglileri al, isme göre filtrele
                        var players = snapshot.data!
                            .where((p) =>
                                p.name
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase()) &&
                                p.cardType == "Temel")
                            .toList();
                        // Reytinge göre sırala
                        players.sort((a, b) => b.rating.compareTo(a.rating));

                        return GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10),
                          itemCount: players.length,
                          itemBuilder: (c, i) {
                            Player p = _convertToPlayer(players[i]);
                            return Draggable<Player>(
                              data: p,
                              feedback: SizedBox(
                                  width: 100,
                                  height: 140,
                                  child: FCAnimatedCard(player: p)),
                              childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: FCAnimatedCard(player: p)),
                              child: FCAnimatedCard(player: p),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      constraints: const BoxConstraints(minHeight: 120),
      child: Row(
        children: [
          // Tier Başlığı (S, A, B...)
          Container(
            width: 80,
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
                color: tierColors[tierKey],
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(5))),
            child: Center(
                child: Text(tierKey,
                    style: GoogleFonts.russoOne(
                        fontSize: 40, color: Colors.black))),
          ),
          // Tier İçeriği (Drop Zone)
          Expanded(
            child: DragTarget<Player>(
              onAccept: (player) {
                setState(() {
                  // Başka tierlardan sil
                  tiers.forEach(
                      (k, v) => v.removeWhere((p) => p.name == player.name));
                  tiers[tierKey]!.add(player);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Wrap(
                    children: tiers[tierKey]!
                        .map((p) => GestureDetector(
                              onTap: () {
                                // Tıklayınca tierdan kaldır
                                setState(() => tiers[tierKey]!.remove(p));
                              },
                              child: Container(
                                  width: 80,
                                  height: 110,
                                  margin: const EdgeInsets.all(5),
                                  child: FCAnimatedCard(player: p)),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Player _convertToPlayer(dynamic t) {
    // Veritabanı tablosundan Player modeline çevirici (Basitleştirilmiş)
    // Gerçek projede jsonDecode işlemleri burada olmalı.
    return Player(
        name: t.name,
        rating: t.rating,
        position: t.position,
        playstyles: [],
        cardType: t.cardType,
        team: t.team);
  }

  void _saveTierList() async {
    // Web veya Desktop için dosya kaydetme mantığı
    final image = await screenshotController.capture();
    if (image != null) {
      // Burada dosya kaydetme dialogu açılabilir. Şimdilik sadece uyarı veriyoruz.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              "Tier List Görüntüsü Hazırlandı (Kaydetme mantığı eklenecek)"),
          backgroundColor: Colors.green));
    }
  }
}
