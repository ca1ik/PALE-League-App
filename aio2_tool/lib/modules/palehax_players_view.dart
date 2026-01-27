import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
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
    if (Hive.isBoxOpen('palehax_manager_db')) {
      var box = Hive.box<Player>('palehax_manager_db');
      if (box.isNotEmpty) selectedPlayer = box.getAt(0);
    }
  }

  void _onSaveCallback(Player newPlayer) {
    setState(() {
      selectedPlayer = newPlayer;
      currentCardIndex = 0; // Yeni oyuncuda her zaman en başa dön
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('palehax_manager_db'))
      return const Center(child: CircularProgressIndicator());

    return DefaultTabController(
      length: 4, // 4 ANA SEKME
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
                Tab(text: "OYUNCULAR"),
                Tab(text: "OYUN STİLLERİ (WIKI)"),
                Tab(text: "KART TİPLERİ"),
                Tab(text: "ROLLER")
              ]),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _SubTabPlayers(), // Mevcut Oyuncu Ekranı (Sidebar + Profil/Analiz)
            _SubTabPlayStyles(), // YENİ: Wiki
            _SubTabCardTypes(), // YENİ: Kartlar
            _SubTabRoles(), // YENİ: Roller
          ],
        ),
      ),
    );
  }
}

// --- ANA SEKME 1: OYUNCULAR (ESKİ YAPININ İYİLEŞTİRİLMİŞ HALİ) ---
class _SubTabPlayers extends StatefulWidget {
  const _SubTabPlayers();
  @override
  State<_SubTabPlayers> createState() => _SubTabPlayersState();
}

class _SubTabPlayersState extends State<_SubTabPlayers> {
  Player? selectedPlayer;
  int currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    var box = Hive.box<Player>('palehax_manager_db');
    if (box.isNotEmpty) selectedPlayer = box.getAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Profil ve Ultimate Analiz
      child: ValueListenableBuilder(
          valueListenable: Hive.box<Player>('palehax_manager_db').listenable(),
          builder: (context, Box<Player> box, _) {
            final allPlayers = box.values.toList();
            if (allPlayers.isEmpty)
              return const Center(child: Text("Veri Yok"));
            if (selectedPlayer == null ||
                !allPlayers.contains(selectedPlayer)) if (allPlayers.isNotEmpty)
              selectedPlayer = allPlayers.first;

            List<Player> versions = allPlayers
                .where((p) => p.name == selectedPlayer!.name)
                .toList();
            if (currentCardIndex >= versions.length) currentCardIndex = 0;
            Player displayPlayer = versions[currentCardIndex];

            return Row(
              children: [
                // SIDEBAR
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10))),
                  child: Column(children: [
                    // GLOBAL RGB BUTON
                    Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Colors.purple, Colors.blue]),
                                borderRadius: BorderRadius.circular(10)),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent),
                                onPressed: () =>
                                    _showGlobalCards(context, box, (p) {
                                      setState(() {
                                        selectedPlayer = p;
                                        currentCardIndex = 0;
                                      });
                                    }),
                                child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.public, color: Colors.white),
                                      SizedBox(width: 5),
                                      Text("GLOBAL KARTLAR",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))
                                    ])))),
                    Expanded(
                        child: ListView.builder(
                            itemCount: allPlayers.length,
                            itemBuilder: (c, i) {
                              final p = allPlayers[i];
                              if (i > 0 && allPlayers[i - 1].name == p.name)
                                return const SizedBox.shrink();
                              return ListTile(
                                  onTap: () => setState(() {
                                        selectedPlayer = p;
                                        currentCardIndex = 0;
                                      }),
                                  selected: selectedPlayer?.name == p.name,
                                  selectedTileColor:
                                      Colors.cyanAccent.withOpacity(0.1),
                                  leading: Text("${p.rating}",
                                      style: GoogleFonts.russoOne(
                                          color: _getRatingColor(p.rating),
                                          fontSize: 18)),
                                  title: Text(p.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)));
                            }))
                  ]),
                ),
                // CONTENT
                Expanded(
                    child: Column(children: [
                  Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: Text(selectedPlayer!.name.toUpperCase(),
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 5))),
                  Container(
                      color: Colors.black26,
                      child: const TabBar(
                          indicatorColor: Colors.cyanAccent,
                          labelColor: Colors.cyanAccent,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            Tab(text: "PROFİL"),
                            Tab(text: "ULTIMATE ANALİZ")
                          ])),
                  Expanded(
                      child: TabBarView(children: [
                    _ViewProfile(
                        player: displayPlayer,
                        versions: versions,
                        onSelect: (p) => setState(
                            () => currentCardIndex = versions.indexOf(p))),
                    _ViewUltimate(
                        player: displayPlayer,
                        versions: versions,
                        index: currentCardIndex,
                        onIndex: (i) => setState(() => currentCardIndex = i))
                  ]))
                ]))
              ],
            );
          }),
    );
  }
}

// --- GÖRÜNÜM 1: PROFİL ---
class _ViewProfile extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final Function(Player) onSelect;
  const _ViewProfile(
      {required this.player, required this.versions, required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            FCAnimatedCard(player: player),
            const SizedBox(width: 40),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(player.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              Text("${player.position} | ${player.team}",
                  style: GoogleFonts.montserrat(
                      fontSize: 18, color: Colors.white70)),
              const SizedBox(height: 30),
              const Text("OYUN STİLLERİ",
                  style: TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                  spacing: 15,
                  children: player.playstyles
                      .map((ps) => Tooltip(
                          message:
                              playStyleTranslationsReverse[ps.name] ?? ps.name,
                          child:
                              Image.asset(ps.assetPath, width: 40, height: 40)))
                      .toList()),
              const SizedBox(height: 30),
              if (versions.length > 1) ...[
                Text("OYUNCUNUN DİĞER KARTLARI",
                    style: GoogleFonts.orbitron(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                    height: 120,
                    width: 400,
                    child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: versions.length,
                        itemBuilder: (c, i) {
                          if (versions[i] == player)
                            return const SizedBox.shrink();
                          return GestureDetector(
                              onTap: () => onSelect(versions[i]),
                              child: Container(
                                  margin: const EdgeInsets.only(right: 15),
                                  child: Column(children: [
                                    Transform.scale(
                                        scale: 0.25,
                                        child: FCAnimatedCard(
                                            player: versions[i])),
                                    Text(versions[i].cardType,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 10))
                                  ])));
                        }))
              ]
            ])
          ]),
          const SizedBox(height: 30),
          _buildMatchHistory(player)
        ]));
  }
}

// --- GÖRÜNÜM 2: ULTIMATE ANALİZ ---
class _ViewUltimate extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  const _ViewUltimate(
      {required this.player,
      required this.versions,
      required this.index,
      required this.onIndex});
  @override
  Widget build(BuildContext context) {
    var stats = player.getSimulationStats();
    return Row(children: [
      Expanded(
          flex: 4,
          child: Center(
              child: SizedBox(
                  height: 500,
                  child: Stack(alignment: Alignment.center, children: [
                    if (versions.length > 1)
                      AnimatedPositioned(
                          duration: const Duration(milliseconds: 500),
                          right: -120,
                          top: 0,
                          child: GestureDetector(
                              onTap: () =>
                                  onIndex((index + 1) % versions.length),
                              child: Opacity(
                                  opacity: 0.7,
                                  child: Transform.scale(
                                      scale: 0.9,
                                      child: FCAnimatedCard(
                                          player: versions[(index + 1) %
                                              versions.length]))))),
                    FCAnimatedCard(player: player)
                  ])))),
      Expanded(
          flex: 5,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _statBox("GOL", stats['Gol']!, Colors.green),
                  _statBox("ASİST", stats['Asist']!, Colors.blue),
                  _statBox("PAS", stats['Pas']!, Colors.white),
                  _statBox("İSABET", stats['İsabetli Pas']!, Colors.cyan),
                  _statBox("KİLİT", stats['Kilit Pas']!, Colors.amber),
                  _statBox(
                      "TOPLA OYNAMA", stats['Topla Oynama']!, Colors.purple)
                ]),
                const SizedBox(height: 20),
                Container(
                    width: 160,
                    height: 220,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(10)),
                    child: CustomPaint(
                        painter: _MiniPitchPainter(
                            playerPos: player.getPitchPosition()),
                        child: Center(
                            child: Icon(Icons.circle,
                                color: Colors.red, size: 10))))
              ])))
    ]);
  }

  Widget _statBox(String l, String v, Color c) => Container(
      padding: const EdgeInsets.all(10),
      width: 100,
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          border: Border.all(color: c.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(v,
            style:
                TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(l, style: TextStyle(color: c.withOpacity(0.7), fontSize: 10))
      ]));
}

// --- ANA SEKME 2: OYUN STİLLERİ (WIKI & META) ---
class _SubTabPlayStyles extends StatelessWidget {
  const _SubTabPlayStyles();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // META GRAFİK ALANI
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.purple.shade900]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)
                ]),
            child: Column(children: [
              Text("V7 META ANALİZİ",
                  style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...metaPlaystyles.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    SizedBox(
                        width: 150,
                        child: Text(m['role'],
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text(m['styles'],
                            style: const TextStyle(color: Colors.white70)))
                  ])))
            ]),
          ),
          // KATEGORİK LİSTE
          ...playStyleCategories.entries.map((entry) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.key,
                    style: GoogleFonts.orbitron(
                        color: Colors.greenAccent, fontSize: 20)),
                const Divider(color: Colors.white24),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    itemCount: entry.value.length,
                    itemBuilder: (c, i) {
                      var ps = entry.value[i];
                      return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            Image.asset("assets/Playstyles/${ps['name']}.png",
                                width: 40,
                                height: 40,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.help,
                                    color: Colors.white)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  Text(ps['label']!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text(ps['desc']!,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 10),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis)
                                ]))
                          ]));
                    }),
                const SizedBox(height: 30)
              ]))
        ]));
  }
}

// --- ANA SEKME 3: KART TİPLERİ ---
class _SubTabCardTypes extends StatelessWidget {
  const _SubTabCardTypes();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(30),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.6,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20),
      itemCount: cardTypes.length,
      itemBuilder: (c, i) {
        String type = cardTypes[i];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: cardTypeDescriptions[type] ?? "",
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _getCardTypeColor(type))),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(type,
                        style: GoogleFonts.orbitron(
                            color: _getCardTypeColor(type),
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(cardTypeDescriptions[type] ?? "",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70)))
                  ]),
            ),
          ),
        );
      },
    );
  }
}

// --- ANA SEKME 4: ROLLER ---
class _SubTabRoles extends StatelessWidget {
  const _SubTabRoles();
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(30),
        children: roleCategories.entries
            .map((e) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.key,
                      style: GoogleFonts.orbitron(
                          color: Colors.amber, fontSize: 20)),
                  ...e.value.map((r) => ListTile(
                      title:
                          Text(r, style: const TextStyle(color: Colors.white)),
                      subtitle: Text("Bu rol hakkında detaylı bilgi...",
                          style: const TextStyle(color: Colors.white54)))),
                  const Divider(color: Colors.white24)
                ]))
            .toList());
  }
}

// --- YARDIMCILAR ---
void _showGlobalCards(
    BuildContext context, Box<Player> box, Function(Player) onSelect) {
  List<Player> all = box.values.toList();
  String sort = "A-Z";
  String filter = "Tümü";
  showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          // Filtreleme
          var list = all
              .where((p) => filter == "Tümü" || p.cardType == filter)
              .toList();
          // Sıralama
          if (sort == "A-Z") list.sort((a, b) => a.name.compareTo(b.name));
          if (sort == "Reyting")
            list.sort((a, b) => b.rating.compareTo(a.rating));
          if (sort == "En Yeni") list = list.reversed.toList();

          return Dialog(
              backgroundColor: const Color(0xFF0D0D12),
              child: Container(
                  width: 900,
                  height: 700,
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Row(children: [
                      const Text("FİLTRE:",
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                          dropdownColor: Colors.grey[900],
                          value: filter,
                          items: ["Tümü", ...cardTypes]
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (v) => setState(() => filter = v!)),
                      const SizedBox(width: 20),
                      const Text("SIRALA:",
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                          dropdownColor: Colors.grey[900],
                          value: sort,
                          items: ["A-Z", "Reyting", "En Yeni"]
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (v) => setState(() => sort = v!)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context))
                    ]),
                    const Divider(color: Colors.white24),
                    Expanded(
                        child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    childAspectRatio: 0.65,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15),
                            itemCount: list.length,
                            itemBuilder: (c, i) {
                              return GestureDetector(
                                  onTap: () {
                                    onSelect(list[i]);
                                    Navigator.pop(context);
                                  },
                                  child: Transform.scale(
                                      scale: 0.9,
                                      child: FCAnimatedCard(player: list[i])));
                            }))
                  ])));
        });
      });
}

Widget _buildMatchHistory(Player p) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text("SON 5 MAÇ",
        style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
    const SizedBox(height: 10),
    ...p.matches
        .map((m) => Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(5)),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.opponent, style: const TextStyle(color: Colors.white)),
                  Text(m.score,
                      style: const TextStyle(color: Colors.cyanAccent)),
                  Text("${m.rating}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                ])))
        .toList()
  ]);
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
