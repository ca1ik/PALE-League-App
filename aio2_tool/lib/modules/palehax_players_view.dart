import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift; // Drift çakışmasını önlemek için
import 'package:url_launcher/url_launcher.dart';

// Kendi dosya yollarını kontrol et
import '../data/player_data.dart';
import '../services/database_service.dart'; // Yeni oluşturduğumuz DB servisi
import '../ui/fc_animated_card.dart';
import 'player_editor.dart';

// ==============================================================================
// ANA GÖRÜNÜM (TAB YAPISI)
// ==============================================================================
class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  @override
  Widget build(BuildContext context) {
    // Veritabanını Provider üzerinden alıyoruz
    final database = Provider.of<AppDatabase>(context);

    return DefaultTabController(
      length: 4,
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
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _SubTabPlayers(database: database), // 1. Oyuncular (DB Entegre)
            const SubTabPlayStyles(), // 2. Wiki
            const SubTabCardTypes(), // 3. Kartlar
            const SubTabRoles(), // 4. Roller
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 1. SEKME: OYUNCU YÖNETİMİ (SQL STREAM YAPISI)
// ==============================================================================
class _SubTabPlayers extends StatefulWidget {
  final AppDatabase database;
  const _SubTabPlayers({required this.database});

  @override
  State<_SubTabPlayers> createState() => _SubTabPlayersState();
}

class _SubTabPlayersState extends State<_SubTabPlayers> {
  Player? selectedPlayer;
  int currentCardIndex = 0;

  // Veritabanı tablosunu UI Modelimize (Player) çeviren yardımcı
  Player _convertTableToPlayer(PlayerTable t) {
    Map<String, int> stats = {};
    try {
      stats = Map<String, int>.from(jsonDecode(t.statsJson));
    } catch (e) {
      debugPrint("Stats parse hatası: $e");
    }

    // Playstyle'lar JSON'dan çekilebilir, şimdilik UI hatası vermesin diye boş veya basit geçiyoruz
    // İlerde: jsonDecode(t.playStylesJson).map(...) yapılabilir.

    return Player(
      name: t.name,
      rating: t.rating,
      position: t.position,
      playstyles: [], // Playstyle'ları veritabanından çekmek için burayı güncelleyebilirsin
      cardType: t.cardType,
      team: t.team,
      marketValue: t.marketValue,
      stats: stats,
      role: t.role,
      recLink: t.recLink ?? "",
      manualGoals: t.manualGoals,
      manualAssists: t.manualAssists,
      manualMatches: t.manualMatches,
      // Diğer manuel istatistikler eklenebilir...
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: StreamBuilder<List<PlayerTable>>(
        stream: widget.database.watchAllPlayers(), // SQL CANLI TAKİP
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Hata: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          }

          final allPlayerTables = snapshot.data ?? [];
          // Tablodan Modele Çevir
          final allPlayers =
              allPlayerTables.map(_convertTableToPlayer).toList();

          if (allPlayers.isEmpty) {
            return Center(
              child: ElevatedButton(
                onPressed: () =>
                    _showEditor(context, null, (p) => _savePlayerToDb(p)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent),
                child: const Text("İLK OYUNCUYU EKLE",
                    style: TextStyle(color: Colors.black)),
              ),
            );
          }

          // Seçili oyuncu kontrolü
          if (selectedPlayer == null) {
            selectedPlayer = allPlayers.first;
          } else {
            // Veri güncellendiyse seçili olanı listeden tekrar bul
            try {
              selectedPlayer =
                  allPlayers.firstWhere((p) => p.name == selectedPlayer!.name);
            } catch (_) {
              selectedPlayer = allPlayers.first;
            }
          }

          // Versiyonlama Mantığı (Aynı isimli oyuncular)
          List<Player> versions =
              allPlayers.where((p) => p.name == selectedPlayer!.name).toList();
          if (currentCardIndex >= versions.length) currentCardIndex = 0;
          Player displayPlayer = versions.isNotEmpty
              ? versions[currentCardIndex]
              : selectedPlayer!;

          return Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showEditor(context, null, (p) {
                _savePlayerToDb(p);
                setState(() {
                  selectedPlayer = p;
                  currentCardIndex = 0;
                });
              }),
              backgroundColor: Colors.cyanAccent,
              child: const Icon(Icons.add, color: Colors.black),
            ),
            body: Row(
              children: [
                // --- SOL LİSTE ---
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white10)),
                  ),
                  child: Column(
                    children: [
                      // GLOBAL KARTLAR BUTONU
                      Padding(
                        padding: const EdgeInsets.all(10),
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
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15)),
                            onPressed: () => _showGlobalCards(
                                context, widget.database, (pTable) {
                              setState(() {
                                // Seçilen oyuncuyu bul ve göster
                                selectedPlayer = _convertTableToPlayer(pTable);
                                currentCardIndex = 0;
                              });
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      // LİSTE ELEMANLARI
                      Expanded(
                        child: ListView.builder(
                          itemCount: allPlayers.length,
                          itemBuilder: (c, i) {
                            final p = allPlayers[i];
                            // Aynı isimdeki versiyonları listede tekrar gösterme (Gruplama)
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
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // --- SAĞ İÇERİK (PROFİL & ANALİZ) ---
                Expanded(
                  child: Column(
                    children: [
                      // Başlık
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
                                fontWeight: FontWeight.bold)),
                      ),
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
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _ViewProfile(
                              player: displayPlayer,
                              versions: versions,
                              onSelect: (p) => setState(
                                  () => currentCardIndex = versions.indexOf(p)),
                            ),
                            _ViewUltimate(
                              player: displayPlayer,
                              versions: versions,
                              index: currentCardIndex,
                              onIndex: (i) =>
                                  setState(() => currentCardIndex = i),
                              context: context,
                              onSave: (p) =>
                                  _savePlayerToDb(p), // Kayıt fonksiyonu
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- SQL KAYIT İŞLEMİ ---
  void _savePlayerToDb(Player p) async {
    final companion = PlayerTablesCompanion(
      name: drift.Value(p.name),
      rating: drift.Value(p.rating),
      position: drift.Value(p.position),
      team: drift.Value(p.team),
      cardType: drift.Value(p.cardType),
      role: drift.Value(p.role),
      marketValue: drift.Value(p.marketValue),
      statsJson:
          drift.Value(jsonEncode(p.stats)), // İstatistikleri JSON yapıp sakla
      playStylesJson: drift.Value("[]"), // Şimdilik boş
      recLink: drift.Value(p.recLink),
      manualGoals: drift.Value(p.manualGoals),
      manualAssists: drift.Value(p.manualAssists),
      manualMatches: drift.Value(p.manualMatches),
    );

    // Eğer ID varsa güncelle, yoksa ekle (Mantık gereği burada basit insert/update ayrımı yapıyoruz)
    // Bu örnekte her zaman yeni ekler veya var olanı üzerine yazar.
    // Gelişmiş senaryoda ID kontrolü gerekir.
    await widget.database.insertPlayer(companion);
    setState(() {}); // UI Tetikle
  }
}

// ==============================================================================
// GLOBAL KARTLAR (SQL FİLTRELEME İLE)
// ==============================================================================
void _showGlobalCards(
    BuildContext context, AppDatabase db, Function(PlayerTable) onSelect) {
  String sort = "Reyting";
  String filter = "Tümü";
  String search = "";

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Dialog(
          backgroundColor: const Color(0xFF0D0D12),
          child: Container(
            width: 1000,
            height: 800,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- ÜST BAR (FİLTRELER) ---
                Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            hintText: "Oyuncu Ara...",
                            hintStyle: TextStyle(color: Colors.white54),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.cyanAccent),
                            border: InputBorder.none),
                        onChanged: (v) => setState(() => search = v),
                      ),
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                      dropdownColor: Colors.grey[900],
                      value: filter,
                      items: ["Tümü", ...cardTypes]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => filter = v!),
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                      dropdownColor: Colors.grey[900],
                      value: sort,
                      items: ["Reyting", "A-Z", "Z-A", "En Yeni"]
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setState(() => sort = v!),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(color: Colors.white24),

                // --- KART LİSTESİ (STREAM BUILDER) ---
                Expanded(
                  child: StreamBuilder<List<PlayerTable>>(
                    // Drift'in gücü: Sorguyu anlık dinliyoruz
                    stream: db.watchFilteredPlayers(
                        searchQuery: search,
                        cardTypeFilter: filter,
                        sortOption: sort),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      final players = snapshot.data!;

                      if (players.isEmpty) {
                        return const Center(
                            child: Text("Oyuncu bulunamadı.",
                                style: TextStyle(color: Colors.white54)));
                      }

                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final pTable = players[index];

                          // Drift tablosunu eski Player modeline çeviriyoruz (Görsel İçin)
                          // Bu yardımcı fonksiyonu burada da kullanabilmek için yukarıdan kopyaladık veya statik yapabiliriz.
                          // Hızlı çözüm için yerel çevirici:
                          Map<String, int> stats = Map<String, int>.from(
                              jsonDecode(pTable.statsJson));
                          final pModel = Player(
                              name: pTable.name,
                              rating: pTable.rating,
                              position: pTable.position,
                              playstyles: [],
                              cardType: pTable.cardType,
                              team: pTable.team,
                              stats: stats,
                              role: pTable.role);

                          return GestureDetector(
                            onTap: () {
                              onSelect(pTable); // Seçimi geri döndür
                              Navigator.pop(context);
                            },
                            child: Transform.scale(
                              scale: 0.9,
                              child: FCAnimatedCard(player: pModel),
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
        );
      });
    },
  );
}

// ==============================================================================
// DİĞER MODÜLLER VE YARDIMCILAR (ORİJİNAL KODDAN KORUNDU)
// ==============================================================================

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
                                        playStyleTranslationsReverse[ps.name] ??
                                            ps.name,
                                        style: TextStyle(
                                            color: ps.isGold
                                                ? Colors.amber
                                                : Colors.white70,
                                            fontSize: 10))
                                  ]))
                              .toList()),
                      const SizedBox(height: 30),
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
                                            Text(versions[i].cardType,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10))
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

class SubTabPlayStyles extends StatefulWidget {
  const SubTabPlayStyles({super.key});
  @override
  State<SubTabPlayStyles> createState() => _SubTabPlayStylesState();
}

class _SubTabPlayStylesState extends State<SubTabPlayStyles>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(
                                0.5 + (_pulseController.value * 0.5)),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.cyanAccent.withOpacity(
                                  0.2 + (_pulseController.value * 0.3)),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ]),
                    child: Column(children: [
                      Text("V7 META ANALİZİ",
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              shadows: [
                                const Shadow(color: Colors.cyan, blurRadius: 15)
                              ])),
                      const SizedBox(height: 25),
                      ...metaPlaystyles.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 180,
                                    child: Text(m['role'],
                                        style: GoogleFonts.russoOne(
                                            color: Colors.cyanAccent,
                                            fontSize: 18))),
                                Expanded(
                                    child: Text(m['styles'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            height: 1.4)))
                              ])))
                    ]));
              }),
          ...playStyleCategories.entries.map((entry) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(entry.key,
                        style: GoogleFonts.orbitron(
                            color: Colors.greenAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold))),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    itemCount: entry.value.length,
                    itemBuilder: (c, i) {
                      var ps = entry.value[i];
                      return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24)),
                          child: Row(children: [
                            Image.asset("assets/Playstyles/${ps['name']}.png",
                                width: 45,
                                height: 45,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.help,
                                    color: Colors.white,
                                    size: 30)),
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
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16)),
                                  Text(ps['desc']!,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
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

class SubTabCardTypes extends StatelessWidget {
  const SubTabCardTypes({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: const EdgeInsets.all(30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.7,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30),
        itemCount: cardTypes.length,
        itemBuilder: (c, i) {
          String type = cardTypes[i];
          Player dummyP = Player(
              name: "ÖRNEK",
              rating: 90,
              position: "ST",
              playstyles: [],
              cardType: type,
              chemistryStyle: "Temel",
              team: "PaleHax",
              role: "Golcü",
              matches: [],
              seasons: []);
          return GestureDetector(
              onTap: () => _showCardDetail(context, type, dummyP),
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(children: [
                    Expanded(
                        child: Transform.scale(
                            scale: 0.9, child: FCAnimatedCard(player: dummyP))),
                    const SizedBox(height: 10),
                    Text(type,
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  ])));
        });
  }

  void _showCardDetail(BuildContext context, String type, Player p) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
                width: 400,
                height: 600,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type,
                          style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Transform.scale(
                          scale: 1.1, child: FCAnimatedCard(player: p)),
                      const SizedBox(height: 40),
                      Text(cardTypeDescriptions[type] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10),
                          child: const Text("KAPAT",
                              style: TextStyle(color: Colors.white)))
                    ]))));
  }
}

class SubTabRoles extends StatelessWidget {
  const SubTabRoles({super.key});
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
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...e.value.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r,
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 5),
                            Text(
                                roleDescriptions[r] ??
                                    "Bu rol hakkında detaylı bilgi wiki sayfasında.",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14))
                          ]))),
                  const Divider(color: Colors.white24, height: 50)
                ]))
            .toList());
  }
}

// ==============================================================================
// YARDIMCI FONKSİYONLAR
// ==============================================================================

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
          // SQL Delete
          // Not: Bunu çağıran yerde DB erişimi olduğu için onSave veya benzeri bir callback ile handle edilmeli
          // Şimdilik sadece modelden siliniyor gibi görünecek, DB entegrasyonu _SubTabPlayers içinde.
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
