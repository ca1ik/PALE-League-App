import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../ui/glass_box.dart';
import '../ui/fc_animated_card.dart';
import 'player_editor.dart';
import '../providers/language_provider.dart';

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  Player? selectedPlayer;
  int currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    // V8 Kutusu Main'de açıldı, garanti olsun diye kontrol
    if (Hive.isBoxOpen('palehax_players_v8')) {
      var box = Hive.box<Player>('palehax_players_v8');
      if (box.isNotEmpty) selectedPlayer = box.getAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kutu açık değilse bekle (Hata önleyici)
    if (!Hive.isBoxOpen('palehax_players_v8'))
      return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
            context: context, builder: (context) => const CreatePlayerDialog()),
        label: const Text("YENİ OYUNCU",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
        backgroundColor: Colors.cyanAccent,
      ),
      body: Row(
        children: [
          // --- SOL: SABİT OYUNCU LİSTESİ ---
          Container(
            width: 280,
            decoration: const BoxDecoration(
                color: Color(0xFF0D0D12),
                border: Border(right: BorderSide(color: Colors.white10))),
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text("KADRO LİSTESİ",
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1))),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable:
                        Hive.box<Player>('palehax_players_v8').listenable(),
                    builder: (context, Box<Player> box, _) {
                      final allPlayers = box.values.toList();
                      if (allPlayers.isEmpty)
                        return const Center(
                            child: Text("Veri Yok",
                                style: TextStyle(color: Colors.white54)));

                      // Benzersiz İsim Listesi (Stacking için)
                      final uniqueNames =
                          allPlayers.map((e) => e.name).toSet().toList();

                      return ListView.builder(
                        itemCount: uniqueNames.length,
                        itemBuilder: (context, index) {
                          // O isme ait en güncel kartı (son eklenen) bul
                          final name = uniqueNames[index];
                          final p = allPlayers.lastWhere((e) => e.name == name);

                          bool isSel = selectedPlayer?.name == p.name;
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: isSel
                                    ? const Color(0xFF6C63FF).withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSel
                                    ? Border.all(color: const Color(0xFF6C63FF))
                                    : null),
                            child: ListTile(
                              onTap: () => setState(() {
                                selectedPlayer = p;
                                currentCardIndex = 0;
                              }),
                              leading: Text("${p.rating}",
                                  style: GoogleFonts.russoOne(
                                      fontSize: 20,
                                      color: _getRatingColor(p.rating))),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(p.position,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                              trailing: Icon(Icons.chevron_right,
                                  color: isSel ? Colors.white : Colors.white24),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- SAĞ: İÇERİK ALANI (3 SEKME) ---
          Expanded(
            child: selectedPlayer == null
                ? const Center(
                    child: Text("Listeden bir oyuncu seçin",
                        style: TextStyle(color: Colors.white54)))
                : DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        // TAB HEADER
                        Container(
                          color: const Color(0xFF0D0D12),
                          child: const TabBar(
                              indicatorColor: Color(0xFF6C63FF),
                              labelColor: Color(0xFF6C63FF),
                              unselectedLabelColor: Colors.white54,
                              tabs: [
                                Tab(text: "1. PROFİL"),
                                Tab(text: "2. KART YIĞINI"),
                                Tab(text: "3. ULTIMATE ANALİZ")
                              ]),
                        ),
                        // TAB CONTENT
                        Expanded(
                          child: ValueListenableBuilder(
                              valueListenable:
                                  Hive.box<Player>('palehax_players_v8')
                                      .listenable(),
                              builder: (context, Box<Player> box, _) {
                                final allPlayers = box.values.toList();
                                List<Player> versions = allPlayers
                                    .where(
                                        (p) => p.name == selectedPlayer!.name)
                                    .toList();
                                // Index taşma kontrolü
                                if (currentCardIndex >= versions.length)
                                  currentCardIndex = 0;
                                Player displayPlayer = versions.isNotEmpty
                                    ? versions[currentCardIndex]
                                    : selectedPlayer!;

                                return TabBarView(
                                  physics:
                                      const NeverScrollableScrollPhysics(), // Kaydırmayı kapat, sadece tıkla geç
                                  children: [
                                    _Tab1Profile(
                                        player: displayPlayer,
                                        context: context),
                                    _Tab2Stack(
                                        player: displayPlayer,
                                        versions: versions,
                                        index: currentCardIndex,
                                        onIndex: (i) => setState(
                                            () => currentCardIndex = i)),
                                    _Tab3Ultimate(player: displayPlayer),
                                  ],
                                );
                              }),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// --- SEKME 1: BASİT PROFİL ---
class _Tab1Profile extends StatelessWidget {
  final Player player;
  final BuildContext context;
  const _Tab1Profile({required this.player, required this.context});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FCAnimatedCard(player: player),
          const SizedBox(width: 50),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              Text("${player.position} | ${player.team}",
                  style: GoogleFonts.montserrat(
                      fontSize: 20, color: Colors.white70)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                  onPressed: () => _showDetailsDialog(context, player),
                  icon: const Icon(Icons.analytics, color: Colors.black),
                  label: const Text("DETAYLI ANALİZ RAPORU",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15)))
            ],
          )
        ],
      ),
    );
  }
}

// --- SEKME 2: KART YIĞINI ---
class _Tab2Stack extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  const _Tab2Stack(
      {required this.player,
      required this.versions,
      required this.index,
      required this.onIndex});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Gölge Kart (Önceki)
            if (versions.length > 1)
              Transform.translate(
                  offset: const Offset(30, 10),
                  child: Transform.scale(
                      scale: 0.9,
                      child: Opacity(
                          opacity: 0.5,
                          child: FCAnimatedCard(
                              player:
                                  versions[(index + 1) % versions.length])))),
            // Ana Kart
            FCAnimatedCard(player: player),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () =>
                    onIndex((index - 1 + versions.length) % versions.length)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                  "${index + 1} / ${versions.length} - ${player.cardType}",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            IconButton(
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onPressed: () => onIndex((index + 1) % versions.length)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => _createVersion(context, player),
                child: const Text("+ YENİ KART EKLE")),
            const SizedBox(width: 10),
            ElevatedButton(
                onPressed: () => _showDetailsDialog(context, player),
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text("ANALİZ",
                    style: TextStyle(color: Colors.white))),
          ],
        )
      ],
    );
  }
}

// --- SEKME 3: ULTIMATE DASHBOARD ---
class _Tab3Ultimate extends StatefulWidget {
  final Player player;
  const _Tab3Ultimate({required this.player});
  @override
  State<_Tab3Ultimate> createState() => _Tab3UltimateState();
}

class _Tab3UltimateState extends State<_Tab3Ultimate> {
  @override
  Widget build(BuildContext context) {
    Player p = widget.player;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SOL KOLON: ANALİZ
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFF15151A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
              child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("DETAYLI İSTATİSTİKLER",
                          style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.white12),
                      _buildStatColumn(p, false), // FC Modu
                    ]),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // ORTA KOLON: GRAFİKLER VE SEZON
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Üst İstatistik Kutuları
                  Row(
                    children: [
                      _statBox("GOLLER", "${_total(p, 'goals')}",
                          Colors.greenAccent),
                      const SizedBox(width: 10),
                      _statBox("ASİSTLER", "${_total(p, 'assists')}",
                          Colors.blueAccent),
                      const SizedBox(width: 10),
                      _statBox(
                          "MAÇLAR",
                          "${p.matches.length + p.seasons.length * 10}",
                          Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Sezon Tablosu
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: const Color(0xFF15151A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10)),
                    child: Column(
                      children: [
                        Text("KARİYER GEÇMİŞİ (S1-S5)",
                            style: GoogleFonts.orbitron(color: Colors.amber)),
                        const SizedBox(height: 10),
                        Table(
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(children: [
                              Text("SEZON",
                                  style: TextStyle(color: Colors.grey)),
                              Text("RTG", style: TextStyle(color: Colors.grey)),
                              Text("G/A", style: TextStyle(color: Colors.grey)),
                              Text("ÖDÜL", style: TextStyle(color: Colors.grey))
                            ]),
                            ...p.seasons.map((s) => TableRow(children: [
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Text(s.season,
                                          style: const TextStyle(
                                              color: Colors.white))),
                                  Text("${s.avgRating}",
                                      style: TextStyle(
                                          color: _getRatingColor(
                                              (s.avgRating * 10).toInt()),
                                          fontWeight: FontWeight.bold)),
                                  Text("${s.goals} / ${s.assists}",
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  s.isMVP
                                      ? const Icon(Icons.star,
                                          color: Colors.amber, size: 16)
                                      : const SizedBox()
                                ]))
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // KEY PASSES GRAFİĞİ (Mockup)
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: const Color(0xFF15151A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.3))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("ANAHTAR PASLAR (Son 5 Maç)",
                            style: TextStyle(
                                color: Colors.cyanAccent, fontSize: 12)),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: p.matches.map((m) {
                              double h = (m.rating / 10) * 80;
                              return Container(
                                  width: 20,
                                  height: h,
                                  decoration: BoxDecoration(
                                      color: Colors.cyanAccent.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(5)));
                            }).toList(),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          // SAĞ KOLON: KART
          Expanded(
            flex: 3,
            child: Column(
              children: [
                FCAnimatedCard(player: p),
                const SizedBox(height: 20),
                // Pas / Şut Yüzdeleri (Circular)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _circleIndicator("WIN RATE", 0.65, Colors.green),
                    _circleIndicator("PASS ACC", 0.88, Colors.blue),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  int _total(Player p, String key) {
    int t = 0;
    for (var s in p.seasons) {
      if (key == 'goals')
        t += s.goals;
      else
        t += s.assists;
    }
    for (var m in p.matches) {
      if (key == 'goals')
        t += m.goals;
      else
        t += m.assists;
    }
    return t;
  }

  Widget _statBox(String label, String val, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: c.withOpacity(0.3))),
        child: Column(children: [
          Text(val,
              style: TextStyle(
                  color: c, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: c.withOpacity(0.7), fontSize: 10))
        ]),
      ),
    );
  }

  Widget _circleIndicator(String label, double pct, Color c) {
    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
              value: pct,
              color: c,
              backgroundColor: Colors.white10,
              strokeWidth: 6),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10))
      ],
    );
  }
}

// --- YARDIMCI FONKSİYONLAR ---
void _createVersion(BuildContext context, Player p) {
  Player newVersion = Player(
      name: p.name,
      rating: p.rating,
      position: p.position,
      playstyles: List.from(p.playstyles),
      team: p.team,
      role: p.role,
      skillMoves: p.skillMoves,
      chemistryStyle: p.chemistryStyle,
      cardType: "TOTW",
      stats: Map.from(p.stats),
      seasons: p.seasons);
  showDialog(
      context: context,
      builder: (context) =>
          CreatePlayerDialog(playerToEdit: newVersion, isNewVersion: true));
}

void _showDetailsDialog(BuildContext context, Player p) {
  showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setSt) {
            bool isFM = false;
            return Dialog(
                backgroundColor: const Color(0xFF101014),
                child: Container(
                    width: 800,
                    height: 700,
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("DETAYLI ANALİZ",
                                style: GoogleFonts.orbitron(
                                    color: Colors.cyanAccent, fontSize: 24)),
                            Row(children: [
                              Text(isFM ? "FM" : "FC",
                                  style: const TextStyle(color: Colors.white)),
                              Switch(
                                  value: isFM,
                                  onChanged: (v) => setSt(() => isFM = v),
                                  activeColor: Colors.cyanAccent)
                            ])
                          ]),
                      const Divider(color: Colors.white24),
                      Expanded(
                          child: SingleChildScrollView(
                              child: _buildStatColumn(p, isFM))),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("KAPAT",
                              style: TextStyle(color: Colors.white)))
                    ])));
          }));
}

Widget _buildStatColumn(Player p, bool isFMView) {
  Map<String, int> bonuses = chemistryBonuses[p.chemistryStyle] ?? {};
  return Column(
      children: statSegments.entries.map((entry) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(entry.key,
              style: const TextStyle(
                  color: Colors.blueAccent, fontWeight: FontWeight.bold))),
      ...entry.value.map((statName) {
        int val = p.stats[statName] ?? 50;
        int displayVal = isFMView ? (val / 99 * 20).round().clamp(1, 20) : val;
        int bonus = bonuses[statName] ?? 0;
        return Row(children: [
          Expanded(
              child: Text(statName,
                  style: const TextStyle(color: Colors.white54, fontSize: 11))),
          if (!isFMView && bonus > 0) ...[
            Text("$displayVal",
                style: TextStyle(
                    color: _getRatingColor(val), fontWeight: FontWeight.bold)),
            Text(" +$bonus",
                style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 10))
          ] else
            Text("$displayVal",
                style: TextStyle(
                    color: _getRatingColor(val), fontWeight: FontWeight.bold)),
          const SizedBox(width: 5),
          SizedBox(
              width: 60,
              height: 4,
              child: LinearProgressIndicator(
                  value: (val + (isFMView ? 0 : bonus)) / 99,
                  color:
                      bonus > 0 ? Colors.lightBlueAccent : _getRatingColor(val),
                  backgroundColor: Colors.white10))
        ]);
      })
    ]);
  }).toList());
}

Color _getRatingColor(int r) {
  return r >= 90
      ? const Color(0xFF00FFC2)
      : (r >= 80 ? Colors.amber : Colors.white);
}

Color _getCardTypeColor(String t) {
  switch (t) {
    case "TOTY":
    case "STAR":
      return Colors.cyanAccent;
    case "MVP":
      return Colors.redAccent;
    case "BALLOND'OR":
      return Colors.amber;
    case "BAD":
      return Colors.pinkAccent;
    default:
      return Colors.white;
  }
}
