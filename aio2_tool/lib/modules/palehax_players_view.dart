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
    // Veritabanı bağlantısı
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
            _SubTabPlayers(), // 1. Oyuncu Yönetimi
            _SubTabPlayStyles(), // 2. Wiki & Meta
            _SubTabCardTypes(), // 3. Kart Açıklamaları
            _SubTabRoles(), // 4. Rol Açıklamaları
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 1. ANA SEKME: OYUNCU YÖNETİMİ (PROFİL & ANALİZ)
// ==============================================================================
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

  // Editörden dönen callback
  void _onSave(Player p) {
    setState(() {
      selectedPlayer = p;
      var box = Hive.box<Player>('palehax_manager_db');
      List<Player> versions =
          box.values.where((v) => v.name == p.name).toList();
      int idx = versions.indexOf(p);
      currentCardIndex = idx != -1 ? idx : 0;
    });
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
              return const Center(
                  child:
                      Text("Veri Yok", style: TextStyle(color: Colors.white)));

            // Seçili oyuncu kontrolü
            if (selectedPlayer == null ||
                !allPlayers.contains(selectedPlayer)) {
              if (allPlayers.isNotEmpty) selectedPlayer = allPlayers.first;
            }

            // Versiyonları bul
            List<Player> versions = allPlayers
                .where((p) => p.name == selectedPlayer!.name)
                .toList();
            if (currentCardIndex >= versions.length) currentCardIndex = 0;
            Player displayPlayer = versions.isNotEmpty
                ? versions[currentCardIndex]
                : selectedPlayer!;

            return Row(
              children: [
                // --- SOL SIDEBAR (LİSTE & GLOBAL BUTON) ---
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.white10))),
                  child: Column(children: [
                    // RGB GLOBAL BUTON
                    Padding(
                        padding: const EdgeInsets.all(15),
                        child: Container(
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Colors.purpleAccent,
                                  Colors.blueAccent
                                ]),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.purple.withOpacity(0.5),
                                      blurRadius: 10)
                                ]),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15)),
                                onPressed: () =>
                                    _showGlobalCards(context, box, (p) {
                                      setState(() {
                                        selectedPlayer = p;
                                        currentCardIndex = 0;
                                      }); // Globalden seçince
                                    }),
                                child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.public, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text("GLOBAL KARTLAR",
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))
                                    ])))),
                    const Divider(color: Colors.white10),
                    // OYUNCU LİSTESİ
                    Expanded(
                        child: ListView.builder(
                            itemCount: allPlayers.length,
                            itemBuilder: (c, i) {
                              final p = allPlayers[i];
                              // Listede sadece benzersiz isimleri göster
                              if (i > 0 && allPlayers[i - 1].name == p.name)
                                return const SizedBox.shrink();

                              bool isSel = selectedPlayer?.name == p.name;
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
                                          color: _getRatingColor(p.rating),
                                          fontSize: 18)),
                                  title: Text(p.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(p.position,
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10)));
                            }))
                  ]),
                ),

                // --- SAĞ İÇERİK ---
                Expanded(
                    child: Column(children: [
                  // İsim Barı
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
                  // Tab Bar
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
                  // Tab İçeriği
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
                        onIndex: (i) => setState(() => currentCardIndex = i),
                        context: context,
                        onSave: _onSave)
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
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FCAnimatedCard(player: player),
                const SizedBox(width: 40),
                Expanded(
                    child: Column(
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
                      const SizedBox(height: 30),
                      Text("OYUN STİLLERİ",
                          style: GoogleFonts.orbitron(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                          spacing: 15,
                          runSpacing: 10,
                          children: player.playstyles
                              .map((ps) => Column(children: [
                                    Image.asset(ps.assetPath,
                                        width: 40,
                                        height: 40,
                                        errorBuilder: (c, e, s) => const Icon(
                                            Icons.help,
                                            color: Colors.white)),
                                    Text(
                                        playStyleTranslations[ps.name] ??
                                            ps.name,
                                        style: TextStyle(
                                            color: ps.isGold
                                                ? Colors.amber
                                                : Colors.white70,
                                            fontSize: 10))
                                  ]))
                              .toList()),
                      const SizedBox(height: 30),
                      // DİĞER KARTLAR (YATAY LİSTE)
                      if (versions.length > 1) ...[
                        Text("OYUNCUNUN DİĞER KARTLARI",
                            style: GoogleFonts.orbitron(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                            height: 140,
                            child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: versions.length,
                                itemBuilder: (c, i) {
                                  if (versions[i] == player)
                                    return const SizedBox.shrink();
                                  return GestureDetector(
                                      onTap: () => onSelect(versions[i]),
                                      child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 15),
                                          child: Column(children: [
                                            Transform.scale(
                                                scale: 0.25,
                                                child: FCAnimatedCard(
                                                    player: versions[i])),
                                            Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                    color: Colors.black,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            3)),
                                                child: Text(
                                                    versions[i].cardType,
                                                    style: const TextStyle(
                                                        color:
                                                            Colors.cyanAccent,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold)))
                                          ])));
                                }))
                      ]
                    ]))
              ]),
          const SizedBox(height: 30),
          _buildMatchHistory(player, true)
        ]));
  }
}

// --- GÖRÜNÜM 2: ULTIMATE ANALİZ ---
class _ViewUltimate extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  final BuildContext context;
  final Function(Player) onSave;
  const _ViewUltimate(
      {required this.player,
      required this.versions,
      required this.index,
      required this.onIndex,
      required this.context,
      required this.onSave});

  @override
  Widget build(BuildContext context) {
    var stats = player.getSimulationStats();
    return Row(children: [
      Expanded(
          flex: 4,
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                SizedBox(
                    height: 500,
                    child: Stack(alignment: Alignment.center, children: [
                      // ARKA KART (Geçiş için tıklanabilir)
                      if (versions.length > 1)
                        AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            right: -130,
                            top: 0,
                            child: GestureDetector(
                                onTap: () =>
                                    onIndex((index + 1) % versions.length),
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
                                                      player: versions[(index +
                                                              1) %
                                                          versions.length]))),
                                          Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              margin: const EdgeInsets.only(
                                                  top: 20, right: 20),
                                              decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  border: Border.all(
                                                      color: Colors.cyanAccent),
                                                  borderRadius:
                                                      BorderRadius.circular(5)),
                                              child: Text(
                                                  versions[(index + 1) %
                                                          versions.length]
                                                      .cardType,
                                                  style: const TextStyle(
                                                      color: Colors.cyanAccent,
                                                      fontWeight:
                                                          FontWeight.bold)))
                                        ])))),
                      // ÖN KART
                      FCAnimatedCard(player: player),
                      Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCardMenu(context, player, onSave)),
                    ])),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () => _createVersion(context, player, onSave),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10),
                    child: const Text("+ YENİ KART VERSİYONU EKLE",
                        style: TextStyle(color: Colors.white)))
              ]))),
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
                  _statBox("ŞUT", stats['Şut']!, Colors.red),
                  _statBox(
                      "TOPLA OYNAMA", stats['Topla Oynama']!, Colors.purple)
                ]),
                const SizedBox(height: 20),
                // REC BUTONU
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
                                  borderRadius: BorderRadius.circular(10))))),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      width: 160,
                      height: 220,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.02)),
                      child: CustomPaint(
                          painter: _MiniPitchPainter(
                              playerPos: player.getPitchPosition()),
                          child: Stack(children: [
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
                                ]))
                          ]))),
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
                                            color: Colors.amber, size: 14)
                                        : const SizedBox()
                                  ]))
                            ])
                      ]))
                ]),
                const SizedBox(height: 20),
                Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoBadge("YETENEK", "${player.skillMoves} ★",
                              color: Colors.amber),
                          _infoBadge("MAÇ REYTİNG",
                              "${player.matches.isNotEmpty ? (player.matches.fold(0.0, (sum, m) => sum + m.rating) / player.matches.length).toStringAsFixed(1) : '-'}",
                              color: Colors.greenAccent),
                          _infoBadge("ROL", player.role)
                        ]))
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
  Widget _infoBadge(String label, String val, {Color color = Colors.white}) =>
      Column(children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 2),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14))
      ]);
}

// ==============================================================================
// 2. ANA SEKME: OYUN STİLLERİ (WIKI & META)
// ==============================================================================
class _SubTabPlayStyles extends StatelessWidget {
  const _SubTabPlayStyles();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // META LED GRAFİK
          Container(
            margin: const EdgeInsets.only(bottom: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.blue.shade900, Colors.purple.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2)
                ],
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.5))),
            child: Column(children: [
              Text("V7 META ANALİZİ",
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        const Shadow(color: Colors.cyan, blurRadius: 10)
                      ])),
              const SizedBox(height: 20),
              ...metaPlaystyles.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 160,
                            child: Text(m['role'],
                                style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16))),
                        Expanded(
                            child: Text(m['styles'],
                                style: const TextStyle(
                                    color: Colors.white70, height: 1.5)))
                      ])))
            ]),
          ),
          // KATEGORİLER
          ...playStyleCategories.entries.map((entry) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(entry.key,
                        style: GoogleFonts.orbitron(
                            color: Colors.greenAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold))),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    itemCount: entry.value.length,
                    itemBuilder: (c, i) {
                      var ps = entry.value[i];
                      return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10)),
                          child: Row(children: [
                            Image.asset("assets/Playstyles/${ps['name']}.png",
                                width: 50,
                                height: 50,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.help,
                                    color: Colors.white,
                                    size: 40)),
                            const SizedBox(width: 15),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  Text(ps['label']!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(ps['desc']!,
                                      style: const TextStyle(
                                          color: Colors.white54, fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)
                                ]))
                          ]));
                    }),
                const SizedBox(height: 30)
              ]))
        ]));
  }
}

// ==============================================================================
// 3. ANA SEKME: KART TİPLERİ
// ==============================================================================
class _SubTabCardTypes extends StatelessWidget {
  const _SubTabCardTypes();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(30),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20),
      itemCount: cardTypes.length,
      itemBuilder: (c, i) {
        String type = cardTypes[i];
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getCardTypeColor(type), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: _getCardTypeColor(type).withOpacity(0.2),
                      blurRadius: 10)
                ]),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(type,
                  style: GoogleFonts.orbitron(
                      color: _getCardTypeColor(type),
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(cardTypeDescriptions[type] ?? "",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5)))
            ]),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// 4. ANA SEKME: ROLLER
// ==============================================================================
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
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...e.value.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                          leading: Icon(Icons.sports_soccer,
                              color: Colors.white.withOpacity(0.5)),
                          title: Text(r,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              roleDescriptions[r] ??
                                  "Bu rol hakkında detaylı bilgi...",
                              style: const TextStyle(color: Colors.white54))))),
                  const Divider(color: Colors.white24, height: 40)
                ]))
            .toList());
  }
}

// ==============================================================================
// YARDIMCI FONKSİYONLAR
// ==============================================================================

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
          if (sort == "Z-A") list.sort((a, b) => b.name.compareTo(a.name));
          if (sort == "Reyting")
            list.sort((a, b) => b.rating.compareTo(a.rating));
          if (sort == "En Yeni") list = list.reversed.toList();

          return Dialog(
              backgroundColor: const Color(0xFF0D0D12),
              child: Container(
                  width: 1000,
                  height: 800,
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
                      const SizedBox(width: 30),
                      const Text("SIRALA:",
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                          dropdownColor: Colors.grey[900],
                          value: sort,
                          items: ["A-Z", "Z-A", "Reyting", "En Yeni"]
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
            child: Row(children: [
              Expanded(
                  child: Text(m.opponent,
                      style: const TextStyle(color: Colors.white))),
              Text("${m.score}",
                  style: const TextStyle(
                      color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
                          color: _getRatingColor((m.rating * 10).toInt())))),
              const SizedBox(width: 10),
              Text("${m.rating}",
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              if (showRec && p.recLink.isNotEmpty) ...[
                const SizedBox(width: 20),
                ElevatedButton(
                    onPressed: () async {
                      final Uri url = Uri.parse(p.recLink);
                      if (!await launchUrl(url)) throw Exception('Link Hatası');
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5)),
                    child: const Text("KAYDI İZLE",
                        style: TextStyle(color: Colors.white, fontSize: 10)))
              ]
            ])))
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
      recLink: p.recLink,
      manualGoals: p.manualGoals,
      manualAssists: p.manualAssists,
      manualMatches: p.manualMatches,
      manualPasses: p.manualPasses,
      manualKeyPasses: p.manualKeyPasses,
      manualShots: p.manualShots,
      manualPossession: p.manualPossession);
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
