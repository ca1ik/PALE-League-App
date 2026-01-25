import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (Hive.isBoxOpen('palehax_players_v9')) {
      var box = Hive.box<Player>('palehax_players_v9');
      if (box.isNotEmpty) selectedPlayer = box.getAt(0);
    }
  }

  // Kart ekleme/güncelleme sonrası tetiklenecek
  void _onSaveCallback(Player newPlayer) {
    setState(() {
      selectedPlayer = newPlayer;
      var box = Hive.box<Player>('palehax_players_v9');
      List<Player> versions =
          box.values.where((p) => p.name == newPlayer.name).toList();
      currentCardIndex = versions.length - 1;
    });
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
                Tab(text: "3. OYUNCUNUN TÜM KARTLARI")
              ]),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: "global",
              onPressed: () => _showAllCardsGlobal(context),
              label: const Text("TÜM OYUNCU KARTLARI (GLOBAL)",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.apps, color: Colors.white),
              backgroundColor: Colors.purple,
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: "create",
              onPressed: () => _showEditor(context, null, _onSaveCallback),
              label: const Text("OYUNCU OLUŞTUR",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add, color: Colors.black),
              backgroundColor: Colors.cyanAccent,
            ),
          ],
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

            // Stacking Logic
            List<Player> playerVersions = allPlayers
                .where((p) => p.name == selectedPlayer!.name)
                .toList();
            if (currentCardIndex >= playerVersions.length) currentCardIndex = 0;
            Player displayPlayer = playerVersions.isNotEmpty
                ? playerVersions[currentCardIndex]
                : selectedPlayer!;

            return Row(
              children: [
                // SOL LİSTE (Sabit)
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10))),
                  child: Column(
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text("TÜM OYUNCU LİSTESİ",
                              style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                        child: ListView.builder(
                          itemCount: allPlayers.length,
                          itemBuilder: (context, index) {
                            final p = allPlayers[index];
                            if (index > 0 &&
                                allPlayers[index - 1].name == p.name)
                              return const SizedBox.shrink();
                            bool isSel = selectedPlayer!.name == p.name;
                            return ListTile(
                              onTap: () => setState(() {
                                selectedPlayer = p;
                                currentCardIndex = 0;
                              }),
                              selected: isSel,
                              selectedTileColor:
                                  Colors.cyanAccent.withOpacity(0.1),
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
                    ],
                  ),
                ),

                // SAĞ İÇERİK
                Expanded(
                  child: Column(
                    children: [
                      // TOP BAR (İSİM)
                      Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          width: double.infinity,
                          alignment: Alignment.center,
                          color: Colors.black12,
                          child: Text(selectedPlayer!.name.toUpperCase(),
                              style: GoogleFonts.orbitron(
                                  color: Colors.white,
                                  fontSize: 22,
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.bold))),
                      Expanded(
                        child: TabBarView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // 1. SEKME: PROFİL
                            _Tab1Profile(
                                player: displayPlayer,
                                versions: playerVersions,
                                context: context,
                                onSelectVersion: (p) {
                                  int idx = playerVersions.indexOf(p);
                                  if (idx != -1)
                                    setState(() => currentCardIndex = idx);
                                }),

                            // 2. SEKME: ULTIMATE ANALİZ
                            _Tab2Ultimate(
                                player: displayPlayer,
                                versions: playerVersions,
                                index: currentCardIndex,
                                onIndex: (i) =>
                                    setState(() => currentCardIndex = i),
                                context: context,
                                onSave: _onSaveCallback),

                            // 3. SEKME: OYUNCUNUN TÜM KARTLARI (HATA BURADAYDI, DÜZELTİLDİ)
                            _Tab3AllCards(
                                playerVersions:
                                    playerVersions, // Doğru parametre
                                onSelect: (p) {
                                  // Seçim fonksiyonu eklendi
                                  int idx = playerVersions.indexOf(p);
                                  if (idx != -1)
                                    setState(() => currentCardIndex = idx);
                                }),
                          ],
                        ),
                      ),
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

// --- SEKME 1: PROFİL ---
class _Tab1Profile extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final BuildContext context;
  final Function(Player) onSelectVersion;
  const _Tab1Profile(
      {required this.player,
      required this.versions,
      required this.context,
      required this.onSelectVersion});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FCAnimatedCard(player: player),
              const SizedBox(width: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.name.toUpperCase(),
                      style: GoogleFonts.orbitron(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text("${player.position} | ${player.team}",
                      style: GoogleFonts.montserrat(
                          fontSize: 18, color: Colors.white70)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      onPressed: () => _showDetailsDialog(context, player),
                      icon: const Icon(Icons.analytics, color: Colors.black),
                      label: const Text("DETAYLI ANALİZ",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15))),
                  const SizedBox(height: 20),
                  Text("OYUN STİLLERİ",
                      style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.orbitron().fontFamily)),
                  const SizedBox(height: 10),
                  Wrap(
                      spacing: 15,
                      runSpacing: 10,
                      children: player.playstyles
                          .map((ps) => Column(children: [
                                Image.asset(ps.assetPath,
                                    width: 40, height: 40),
                                Text(playStyleTranslations[ps.name] ?? ps.name,
                                    style: TextStyle(
                                        color: ps.isGold
                                            ? Colors.amber
                                            : Colors.white70,
                                        fontSize: 10))
                              ]))
                          .toList()),
                  const SizedBox(height: 30),
                  Text("DİĞER KARTLAR",
                      style: TextStyle(
                          color: Colors.purpleAccent,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                      height: 80,
                      width: 400,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: versions.length,
                          itemBuilder: (c, i) {
                            return GestureDetector(
                                onTap: () => onSelectVersion(versions[i]),
                                child: Container(
                                    margin: const EdgeInsets.only(right: 15),
                                    child: Transform.scale(
                                        scale: 0.2,
                                        child: FCAnimatedCard(
                                            player: versions[i]))));
                          }))
                ],
              )
            ],
          ),
          const SizedBox(height: 30),
          _buildMatchHistory(player, true),
        ],
      ),
    );
  }
}

// --- SEKME 2: ULTIMATE ANALİZ ---
class _Tab2Ultimate extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  final BuildContext context;
  final Function(Player) onSave;
  const _Tab2Ultimate(
      {required this.player,
      required this.versions,
      required this.index,
      required this.onIndex,
      required this.context,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    Map<String, String> simStats = player.getSimulationStats();

    return Row(
      children: [
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
                        right: -80,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => onIndex((index + 1) % versions.length),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Transform.scale(
                                  scale: 0.85,
                                  child: Opacity(
                                      opacity: 0.7,
                                      child: FCAnimatedCard(
                                          player: versions[
                                              (index + 1) % versions.length]))),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  margin:
                                      const EdgeInsets.only(top: 20, right: 20),
                                  decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(color: Colors.white)),
                                  child: Text(
                                      versions[(index + 1) % versions.length]
                                          .cardType,
                                      style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold)))
                            ],
                          ),
                        ),
                      ),
                    FCAnimatedCard(player: player),
                    Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCardMenu(context, player, onSave)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => _createVersion(context, player, onSave),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  child: const Text("+ YENİ KART VERSİYONU EKLE",
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        ),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statBox("GOL", simStats['Gol']!, Colors.greenAccent,
                        Icons.sports_soccer),
                    _statBox(
                        "ASİST",
                        "${player.matches.fold(0, (s, m) => s + m.assists)}",
                        Colors.blueAccent,
                        Icons.assist_walker),
                    _statBox(
                        "PAS", simStats['Pas']!, Colors.white, Icons.sports),
                    _statBox("İSABETLİ", simStats['İsabetli Pas']!,
                        Colors.white, Icons.check),
                    _statBox("KİLİT PAS", simStats['Kilit Pas']!,
                        Colors.amberAccent, Icons.vpn_key),
                    _statBox("ŞUT", simStats['Şut']!, Colors.redAccent,
                        Icons.track_changes),
                    _statBox("TOPLA OYNAMA", simStats['Topla Oynama']!,
                        Colors.purpleAccent, Icons.pie_chart),
                  ],
                ),
                const SizedBox(height: 20),
                if (player.recLink.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse(player.recLink);
                          if (!await launchUrl(url))
                            throw Exception('Link Hatası');
                        },
                        icon: const Icon(Icons.videocam, color: Colors.white),
                        label: const Text("MAÇ KAYDINI İZLE",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: const EdgeInsets.all(18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)))),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              2: FlexColumnWidth(1.2),
                              3: FixedColumnWidth(25)
                            },
                            children: [
                              const TableRow(children: [
                                Text("SEZON",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10)),
                                Text("RTG",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10)),
                                Text("G/A",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 10)),
                                SizedBox()
                              ]),
                              ...player.seasons.map((s) => TableRow(children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        child: Text(s.season,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12))),
                                    Text("${s.avgRating}",
                                        style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontWeight: FontWeight.bold)),
                                    Text("${s.goals} / ${s.assists}",
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    s.isMVP
                                        ? const Icon(Icons.star,
                                            color: Colors.amber, size: 16)
                                        : const SizedBox()
                                  ]))
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white10),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoBadge("SKILLS", "${player.skillMoves} ★",
                          color: Colors.amber),
                      _infoBadge(
                          "MAÇ REYTİNG",
                          "${player.matches.isNotEmpty ? player.matches.map((m) => m.rating).reduce((a, b) => a + b) / player.matches.length : 0.0}"
                              .substring(0, 3)),
                      _infoBadge("ROL", player.role),
                    ],
                  ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: c.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: c, size: 18),
        const SizedBox(height: 5),
        Text(value,
            style:
                TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(
                color: c.withOpacity(0.7),
                fontSize: 9,
                fontWeight: FontWeight.w600))
      ]),
    );
  }

  Widget _infoBadge(String label, String val, {Color color = Colors.white}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14))
      ]);
}

// --- SEKME 3: OYUNCUNUN TÜM KARTLARI (DÜZELTİLDİ) ---
class _Tab3AllCards extends StatelessWidget {
  final List<Player> playerVersions;
  final Function(Player) onSelect; // Seçim fonksiyonu eklendi

  const _Tab3AllCards({required this.playerVersions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 30,
          runSpacing: 30,
          children: playerVersions
              .map((p) => GestureDetector(
                    onTap: () => onSelect(p), // Tıklayınca seç
                    child: Column(children: [
                      Text(p.cardType,
                          style: GoogleFonts.orbitron(
                              color: _getCardTypeColor(p.cardType),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Transform.scale(
                          scale: 0.8, child: FCAnimatedCard(player: p))
                    ]),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// --- YARDIMCILAR ---
Widget _buildMatchHistory(Player p, bool showRec) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("SON 5 MAÇ PERFORMANSI",
        style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
    const SizedBox(height: 15),
    ...p.matches
        .map((m) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                      child: Text(m.opponent,
                          style: const TextStyle(color: Colors.white))),
                  Text("${m.score}",
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Container(
                      width: 40,
                      height: 6,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(3)),
                      child: FractionallySizedBox(
                          widthFactor: m.rating / 10,
                          child: Container(
                              color:
                                  _getRatingColor((m.rating * 10).toInt())))),
                  const SizedBox(width: 10),
                  Text("${m.rating}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  if (showRec && p.recLink.isNotEmpty) ...[
                    const SizedBox(width: 20),
                    ElevatedButton(
                        onPressed: () async {
                          final Uri url = Uri.parse(p.recLink);
                          if (!await launchUrl(url))
                            throw Exception('Link Hatası');
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5)),
                        child: const Text("REC",
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)))
                  ]
                ],
              ),
            ))
        .toList()
  ]);
}

Widget _buildCardMenu(BuildContext context, Player p, Function(Player) onSave) {
  return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF1E1E24),
      onSelected: (val) {
        if (val == 'edit') _showEditor(context, p, onSave);
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

void _createVersion(BuildContext context, Player p, Function(Player) onSave) {
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
      builder: (context) => CreatePlayerDialog(
          playerToEdit: newVersion,
          isNewVersion: true,
          onSave: () => onSave(newVersion)));
}

void _showEditor(BuildContext context, Player? p, Function(Player) onSave) {
  showDialog(
      context: context,
      builder: (context) => CreatePlayerDialog(
          playerToEdit: p,
          onSave: () {
            if (p != null) onSave(p);
          }));
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

void _showAllCardsGlobal(BuildContext context) {
  showDialog(
      context: context,
      builder: (_) => Dialog(
          backgroundColor: const Color(0xFF0D0D12),
          child: Container(
              width: 1000,
              height: 800,
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TÜM OYUNCU KARTLARI (GLOBAL)",
                          style: GoogleFonts.orbitron(
                              color: Colors.purpleAccent, fontSize: 24)),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context))
                    ]),
                const Divider(color: Colors.white24),
                Expanded(
                    child: ValueListenableBuilder(
                        valueListenable:
                            Hive.box<Player>('palehax_players_v9').listenable(),
                        builder: (context, Box<Player> box, _) {
                          Map<String, List<Player>> grouped = {};
                          for (var type in cardTypes) {
                            grouped[type] = box.values
                                .where((p) => p.cardType == type)
                                .toList();
                          }
                          return SingleChildScrollView(
                              child: Column(
                                  children: grouped.entries
                                      .where((e) => e.value.isNotEmpty)
                                      .map((entry) => Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20),
                                                    child: Text(entry.key,
                                                        style: GoogleFonts.orbitron(
                                                            color:
                                                                _getCardTypeColor(
                                                                    entry.key),
                                                            fontSize: 20))),
                                                Wrap(
                                                    spacing: 20,
                                                    runSpacing: 20,
                                                    children: entry.value
                                                        .map((p) =>
                                                            Transform.scale(
                                                                scale: 0.6,
                                                                child:
                                                                    FCAnimatedCard(
                                                                        player:
                                                                            p)))
                                                        .toList())
                                              ]))
                                      .toList()));
                        }))
              ]))));
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
