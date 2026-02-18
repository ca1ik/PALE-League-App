import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/player_data.dart';
import '../ui/fc_animated_card.dart';
import '../ui/player_editor.dart';
import 'special_teams_builder.dart'; // YENİ MODÜLÜ İMPORT ET

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});

  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();
    // 3 Sekme: Tüm Oyuncular, Özel Kartlar, Özel Takımlar
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _deletePlayer(Player player) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        title: Text("Oyuncuyu Sil",
            style: GoogleFonts.orbitron(color: Colors.red)),
        content: Text("${player.name} silinsin mi? Bu işlem geri alınamaz.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              final box = Hive.box<Player>('palehax_players_v9');
              final keyToDelete =
                  box.keys.firstWhere((k) => box.get(k)?.id == player.id);
              box.delete(keyToDelete);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${player.name} silindi.")));
            },
            child: const Text("SİL", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "TÜM OYUNCULAR"),
            Tab(text: "ÖZEL KARTLAR"),
            Tab(text: "ÖZEL TAKIMLAR"), // YENİ SEKME
          ],
        ),
        actions: [
          // İŞLEM BUTONLARI (Sağ Üst)
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Row(
              children: [
                _buildActionButton(Icons.add, "Oluştur", Colors.green, () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PlayerEditor()));
                }),
                const SizedBox(width: 10),
                _buildActionButton(Icons.edit, "Düzenle", Colors.orange, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Düzenlemek için bir karta tıkla.")));
                }),
                const SizedBox(width: 10),
                _buildActionButton(_isDeleteMode ? Icons.close : Icons.delete,
                    _isDeleteMode ? "İptal" : "Sil", Colors.red, () {
                  setState(() => _isDeleteMode = !_isDeleteMode);
                }),
              ],
            ),
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Player>('palehax_players_v9').listenable(),
        builder: (context, Box<Player> box, _) {
          List<Player> allPlayers = box.values.toList();

          // Özel Kartlar için filtreleme ve gruplama
          List<Player> specialPlayers =
              allPlayers.where((p) => p.cardType != 'Temel').toList();
          Map<String, List<Player>> groupedSpecials = {};
          for (var p in specialPlayers) {
            if (!groupedSpecials.containsKey(p.cardType)) {
              groupedSpecials[p.cardType] = [];
            }
            groupedSpecials[p.cardType]!.add(p);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // SEKME 1: TÜM OYUNCULAR (Mevcut Grid Görünümü)
              _buildPlayerGrid(allPlayers),

              // SEKME 2: ÖZEL KARTLAR (Yeni Gruplanmış Görünüm)
              _buildSpecialCardsView(groupedSpecials),

              // SEKME 3: ÖZEL TAKIMLAR (Yeni Modül)
              const SpecialTeamsBuilder(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.orbitron(fontSize: 12)),
    );
  }

  // Grid Görünümü (Tüm Oyuncular için)
  Widget _buildPlayerGrid(List<Player> players) {
    if (players.isEmpty) {
      return Center(
          child: Text("Henüz oyuncu yok.",
              style: GoogleFonts.orbitron(color: Colors.white54)));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6, // Geniş ekranda 6 kart yan yana
        childAspectRatio: 0.7,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return _buildClickableCard(player);
      },
    );
  }

  // Tıklanabilir Kart (Düzenleme/Silme için)
  Widget _buildClickableCard(Player player) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (_isDeleteMode) {
              _deletePlayer(player);
            } else {
              // Düzenleme Moduna Git
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          PlayerEditor(playerToEdit: player)));
            }
          },
          child: FCAnimatedCard(player: player),
        ),
        if (_isDeleteMode)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
      ],
    );
  }

  // YENİ: Özel Kartlar Görünümü (Gruplanmış ve Ortalı)
  Widget _buildSpecialCardsView(Map<String, List<Player>> groupedPlayers) {
    if (groupedPlayers.isEmpty) {
      return Center(
          child: Text("Henüz özel kart yok.",
              style: GoogleFonts.orbitron(color: Colors.white54)));
    }
    return ListView(
      padding: const EdgeInsets.all(30),
      children: groupedPlayers.entries.map((entry) {
        String cardType = entry.key;
        List<Player> players = entry.value;

        // Başlık Rengi (FCAnimatedCard'daki mantığa benzer)
        Color headerColor = Colors.white;
        if (cardType == 'TOTW' || cardType == "BALLOND'OR")
          headerColor = Colors.amber;
        else if (cardType == 'TOTS' || cardType == 'STAR')
          headerColor = Colors.cyanAccent;
        else if (cardType == 'MVP')
          headerColor = Colors.redAccent;
        else if (cardType == 'TOTM') headerColor = Colors.pinkAccent;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Başlığı ortala
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "$cardType KARTLARI",
                style: GoogleFonts.orbitron(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: headerColor,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                          color: headerColor.withOpacity(0.5), blurRadius: 15)
                    ]),
              ),
            ),
            Wrap(
              spacing: 25,
              runSpacing: 25,
              alignment: WrapAlignment.center, // Kartları ortala
              children: players
                  .map((player) => SizedBox(
                      width:
                          220, // Kart boyutunu biraz küçülttük ki wrap içinde sığsınlar
                      height: 300,
                      child: _buildClickableCard(player)))
                  .toList(),
            ),
            const SizedBox(height: 40),
            Divider(color: Colors.white.withOpacity(0.1)),
          ],
        );
      }).toList(),
    );
  }
}
