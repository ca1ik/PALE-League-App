import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // Eğer link açmak istersen
import '../data/player_data.dart';
import '../ui/glass_box.dart';
import '../ui/fc_animated_card.dart';
import 'player_editor.dart';

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
    _initHive();
  }

  Future<void> _initHive() async {
    // V8 -> V9 Migration (Rec Link için)
    var v8Box = await Hive.openBox<Player>('palehax_players_v8');
    var v9Box = await Hive.openBox<Player>('palehax_players_v9');
    if (v9Box.isEmpty && v8Box.isNotEmpty) {
      v9Box.addAll(v8Box.values);
    }
    if (v9Box.isNotEmpty) selectedPlayer = v9Box.getAt(0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('palehax_players_v9'))
      return const Center(child: CircularProgressIndicator());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0,
          bottom: const TabBar(
              indicatorColor: Colors.cyanAccent,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: "1. PROFİL"),
                Tab(text: "2. ULTIMATE ANALİZ"),
                Tab(text: "3. TÜM KARTLAR")
              ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEditor(context, null),
          label: const Text("OYUNCU OLUŞTUR",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: Colors.cyanAccent,
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box<Player>('palehax_players_v9').listenable(),
          builder: (context, Box<Player> box, _) {
            final allPlayers = box.values.toList();
            if (allPlayers.isEmpty)
              return const Center(
                  child: Text("Veritabanı boş.",
                      style: TextStyle(color: Colors.white)));
            if (selectedPlayer == null ||
                !allPlayers.contains(selectedPlayer)) {
              if (allPlayers.isNotEmpty) selectedPlayer = allPlayers.first;
            }

            List<Player> playerVersions = allPlayers
                .where((p) => p.name == selectedPlayer!.name)
                .toList();
            if (currentCardIndex >= playerVersions.length) currentCardIndex = 0;
            Player displayPlayer = playerVersions.isNotEmpty
                ? playerVersions[currentCardIndex]
                : selectedPlayer!;

            return Row(
              children: [
                // SOL LİSTE
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10))),
                  child: ListView.builder(
                    itemCount: allPlayers.length,
                    itemBuilder: (context, index) {
                      final p = allPlayers[index];
                      if (index > 0 && allPlayers[index - 1].name == p.name)
                        return const SizedBox.shrink();
                      bool isSel = selectedPlayer!.name == p.name;
                      return ListTile(
                        onTap: () => setState(() {
                          selectedPlayer = p;
                          currentCardIndex = 0;
                        }),
                        selected: isSel,
                        selectedTileColor: Colors.cyanAccent.withOpacity(0.1),
                        leading: Text("${p.rating}",
                            style: GoogleFonts.russoOne(
                                fontSize: 18,
                                color: _getRatingColor(p.rating))),
                        title: Text(p.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(p.position,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 10)),
                      );
                    },
                  ),
                ),

                // TAB İÇERİKLERİ
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _Tab1Profile(player: displayPlayer, context: context),
                      _Tab2Ultimate(
                          player: displayPlayer,
                          versions: playerVersions,
                          index: currentCardIndex,
                          onIndex: (i) => setState(() => currentCardIndex = i),
                          context: context),
                      _Tab3AllCards(allPlayers: allPlayers),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- SEKME 1: PROFİL (Klasik) ---
class _Tab1Profile extends StatelessWidget {
  final Player player;
  final BuildContext context;
  const _Tab1Profile({required this.player, required this.context});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          FCAnimatedCard(player: player), // KART ORTADA
          const SizedBox(height: 30),
          ElevatedButton.icon(
              onPressed: () => _showDetailsDialog(context, player),
              icon: const Icon(Icons.analytics, color: Colors.black),
              label: const Text("DETAYLI ANALİZ RAPORU",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent)),
          const SizedBox(height: 30),
          const Text("OYUN STİLLERİ",
              style:
                  TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
              spacing: 10,
              children: player.playstyles
                  .map((ps) => Tooltip(
                      message: ps.name,
                      child: Image.asset(ps.assetPath, width: 40, height: 40)))
                  .toList()),
          const SizedBox(height: 30),
          _buildMatchHistory(player),
        ],
      ),
    );
  }
}

// --- SEKME 2: ULTIMATE ANALİZ (YENİLENMİŞ) ---
class _Tab2Ultimate extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  final BuildContext context;
  const _Tab2Ultimate(
      {required this.player,
      required this.versions,
      required this.index,
      required this.onIndex,
      required this.context});

  @override
  Widget build(BuildContext context) {
    Map<String, String> simStats = player.getSimulationStats();

    return Row(
      children: [
        // ORTA: KART STACK (Daha görünür animasyon)
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 500,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    if (versions.length > 1)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        right: -60, top: 20, // Daha dışarıda
                        child: GestureDetector(
                          onTap: () => onIndex((index + 1) % versions.length),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Transform.scale(
                                    scale: 0.9,
                                    child: Opacity(
                                        opacity: 0.8,
                                        child: FCAnimatedCard(
                                            player: versions[(index + 1) %
                                                versions.length]))),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    margin: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(5),
                                        border:
                                            Border.all(color: Colors.white54)),
                                    child: Text(
                                        versions[(index + 1) % versions.length]
                                            .cardType,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    FCAnimatedCard(player: player),
                    Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCardMenu(context, player)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => _createVersion(context, player),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: const Text("+ YENİ KART VERSİYONU EKLE",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ),

        // SAĞ: DETAYLAR (ŞEFFAF VE DOLU)
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // İSTATİSTİK KUTULARI (Daha şık)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _statBox("GOALS", simStats['Goals']!, Colors.greenAccent,
                        Icons.sports_soccer),
                    _statBox(
                        "ASSISTS",
                        "${player.matches.fold(0, (s, m) => s + m.assists)}",
                        Colors.blueAccent,
                        Icons.assist_walker),
                    _statBox("PASSES", simStats['Passes']!, Colors.white,
                        Icons.compare_arrows),
                    _statBox("KEY PASS", simStats['Key Pass']!,
                        Colors.amberAccent, Icons.vpn_key),
                    _statBox("SHOTS", simStats['Shots']!, Colors.redAccent,
                        Icons.track_changes),
                    _statBox("POSS%", simStats['Possession']!,
                        Colors.purpleAccent, Icons.pie_chart),
                  ],
                ),
                const SizedBox(height: 20),
                // REC BUTONU
                if (player.recLink.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.videocam),
                        label: const Text("MAÇ KAYDINI İZLE"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.all(15))),
                  ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MİNİ SAHA
                    Container(
                      width: 160,
                      height: 220,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.02)),
                      child: CustomPaint(
                        painter: _MiniPitchPainter(
                            playerPos: player.getPitchPosition()),
                        child: Stack(
                          children: [
                            Positioned(
                              left: player.getPitchPosition().dx * 160 - 10,
                              top: player.getPitchPosition().dy * 220 - 10,
                              child: Column(children: [
                                const Icon(Icons.circle,
                                    color: Colors.redAccent, size: 14),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    color: Colors.black54,
                                    child: Text(player.position,
                                        style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)))
                              ]),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // SEZON TABLOSU (Daha Kompakt)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("SEZON GEÇMİŞİ",
                              style: GoogleFonts.orbitron(
                                  color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 5),
                          Table(
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1),
                              3: FixedColumnWidth(20)
                            },
                            children: player.seasons
                                .map((s) => TableRow(children: [
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4),
                                          child: Text(s.season,
                                              style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 11))),
                                      Text("${s.avgRating}",
                                          style: const TextStyle(
                                              color: Colors.cyanAccent,
                                              fontWeight: FontWeight.bold)),
                                      Text("${s.goals}G ${s.assists}A",
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11)),
                                      s.isMVP
                                          ? const Icon(Icons.star,
                                              color: Colors.amber, size: 14)
                                          : const SizedBox()
                                    ]))
                                .toList(),
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                // Vücut ve Form
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBadge("BOY/KİLO",
                        "185cm / 78kg"), // Mock data (veri modeline eklenebilir)
                    _infoBadge("AYAK", "Sağ"),
                    _infoBadge("FORM", "Mükemmel", color: Colors.green),
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _statBox(String label, String value, Color c, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 16),
        const SizedBox(height: 5),
        Text(value,
            style:
                TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: c.withOpacity(0.7), fontSize: 8))
      ]),
    );
  }

  Widget _infoBadge(String label, String val, {Color color = Colors.white}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      Text(val, style: TextStyle(color: color, fontWeight: FontWeight.bold))
    ]);
  }
}

// --- SEKME 3: TÜM KARTLAR GALERİSİ ---
class _Tab3AllCards extends StatelessWidget {
  final List<Player> allPlayers;
  const _Tab3AllCards({required this.allPlayers});
  @override
  Widget build(BuildContext context) {
    Map<String, List<Player>> grouped = {};
    for (var type in cardTypes) {
      grouped[type] = allPlayers.where((p) => p.cardType == type).toList();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: grouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text("${entry.key} KOLEKSİYONU",
                      style: GoogleFonts.orbitron(
                          color: _getCardTypeColor(entry.key),
                          fontSize: 20,
                          letterSpacing: 2))),
              Wrap(
                spacing: 30,
                runSpacing: 30,
                children: entry.value
                    .map((p) => Transform.scale(
                        scale: 0.7, child: FCAnimatedCard(player: p)))
                    .toList(),
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white12),
              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// --- YARDIMCILAR ---
Widget _buildMatchHistory(Player p) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("SON 5 MAÇ PERFORMANSI",
        style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
    const SizedBox(height: 15),
    SizedBox(
        height: 150,
        child: Row(
            children: p.matches
                .map((m) => Expanded(
                    child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(m.opponent,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 5),
                              Container(
                                  height: 50,
                                  width: 10,
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(5)),
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                      height: (m.rating / 10) * 50,
                                      width: 10,
                                      decoration: BoxDecoration(
                                          color: _getRatingColor(
                                              (m.rating * 10).toInt()),
                                          borderRadius:
                                              BorderRadius.circular(5)))),
                              Text("${m.rating}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text("${m.goals}G",
                                  style: const TextStyle(
                                      color: Colors.greenAccent, fontSize: 10))
                            ]))))
                .toList()))
  ]);
}

Widget _buildCardMenu(BuildContext context, Player p) {
  return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF1E1E24),
      onSelected: (val) {
        if (val == 'edit') _showEditor(context, p);
        if (val == 'delete') {
          p.delete();
        }
      },
      itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'edit',
                child: Text("Düzenle", style: TextStyle(color: Colors.white))),
            const PopupMenuItem(
                value: 'delete',
                child: Text("Sil", style: TextStyle(color: Colors.redAccent)))
          ]);
}

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
      seasons: p.seasons,
      recLink: p.recLink);
  showDialog(
      context: context,
      builder: (context) =>
          CreatePlayerDialog(playerToEdit: newVersion, isNewVersion: true));
}

void _showEditor(BuildContext context, Player? p) {
  showDialog(
      context: context,
      builder: (context) => CreatePlayerDialog(playerToEdit: p));
}

void _showDetailsDialog(BuildContext context, Player p) {
  showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setSt) {
            bool isFM = false;
            Map<String, int> bonuses = chemistryBonuses[p.chemistryStyle] ?? {};
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
                              child: Column(
                                  children: statSegments.entries
                                      .map((entry) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 8),
                                                    child: Text(entry.key,
                                                        style: const TextStyle(
                                                            color: Colors
                                                                .blueAccent,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                ...entry.value.map((statName) {
                                                  int val =
                                                      p.stats[statName] ?? 50;
                                                  int dVal = isFM
                                                      ? (val / 99 * 20).round()
                                                      : val;
                                                  int b =
                                                      bonuses[statName] ?? 0;
                                                  return Row(children: [
                                                    Expanded(
                                                        child: Text(statName,
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .white54))),
                                                    Text("$dVal",
                                                        style: TextStyle(
                                                            color:
                                                                _getRatingColor(
                                                                    val),
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                                    if (!isFM && b > 0)
                                                      Text(" +$b",
                                                          style: const TextStyle(
                                                              color: Colors
                                                                  .lightBlueAccent,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    const SizedBox(width: 10),
                                                    SizedBox(
                                                        width: 100,
                                                        height: 5,
                                                        child: LinearProgressIndicator(
                                                            value: val / 99,
                                                            color:
                                                                _getRatingColor(
                                                                    val),
                                                            backgroundColor:
                                                                Colors.white10))
                                                  ]);
                                                })
                                              ]))
                                      .toList()))),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("KAPAT",
                              style: TextStyle(color: Colors.white)))
                    ])));
          }));
}

class _MiniPitchPainter extends CustomPainter {
  final Offset playerPos;
  _MiniPitchPainter({required this.playerPos});
  @override
  void paint(Canvas c, Size s) {
    Paint p = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), p);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), p);
    c.drawCircle(Offset(s.width / 2, s.height / 2), 15, p);
    c.drawRect(
        Rect.fromLTWH(s.width * 0.25, 0, s.width * 0.5, s.height * 0.15), p);
    c.drawRect(
        Rect.fromLTWH(
            s.width * 0.25, s.height * 0.85, s.width * 0.5, s.height * 0.15),
        p);
    c.drawCircle(
        Offset(playerPos.dx * s.width, playerPos.dy * s.height),
        6,
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

Color _getRatingColor(int r) {
  return r >= 90
      ? const Color(0xFF00FFC2)
      : (r >= 80 ? Colors.amber : Colors.white);
}

Color _getCardTypeColor(String t) {
  switch (t) {
    case "TOTS":
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
