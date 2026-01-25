import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart'; // Eğer grafik paketi kurulu değilse bunu yorum satırı yapın
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../ui/glass_box.dart';
import '../providers/language_provider.dart';

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  Player? selectedPlayer;
  late Box<Player> playerBox;
  bool isFMView = false;

  // Çeviri haritasını buraya taşıdık (HATA ÇÖZÜMÜ)
  final Map<String, String> playStyleTranslations = {
    "Acrobatic": "Akrobatik",
    "AerialFortress": "Hava Hakimi",
    "Anticipate": "Sezgi",
    "Block": "Blok",
    "Bruiser": "Sert",
    "CrossClaimer": "Orta Kesici",
    "FarReach": "Uzak Erişim",
    "FinesseShot": "Plase",
    "FirstTouch": "İlk Dokunuş",
    "Footwork": "Ayak Oyunu",
    "GameChanger": "Oyun Kurucu",
    "IncisivePass": "Ara Pası",
    "Intercept": "Pas Arası",
    "Inventive": "Yaratıcı",
    "Jockey": "Markaj",
    "LongBallPass": "Uzun Top",
    "PingedPass": "Adrese Teslim",
    "PowerShot": "Sert Şut",
    "PressProven": "Baskı Yemez",
    "QuickStep": "Seri Adım",
    "Rapid": "Süratli",
    "RushOut": "Kalesini Terk",
    "SlideTackle": "Kayarak Müdahale",
    "Technical": "Teknik",
    "TikiTaka": "Tiki Taka",
    "Trickster": "Cambaz",
    "WhippedPass": "Kavisli Pas"
  };

  @override
  void initState() {
    super.initState();
    // V4 Kutusunu açıyoruz
    playerBox = Hive.box<Player>('palehax_players_v4');
    if (playerBox.isNotEmpty) selectedPlayer = playerBox.getAt(0);
  }

  @override
  Widget build(BuildContext context) {
    // Dil sağlayıcısı (kullanılmıyorsa kaldırılabilir ama yapıda vardı)
    // final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(null),
        label: const Text("OYUNCU OLUŞTUR",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: ValueListenableBuilder(
        valueListenable: playerBox.listenable(),
        builder: (context, Box<Player> box, _) {
          final players = box.values.toList();

          // Veritabanı boşsa uyarı göster
          if (players.isEmpty)
            return const Center(
                child: Text("Veritabanı boş. Yeni oyuncu oluşturun.",
                    style: TextStyle(color: Colors.white)));

          // Seçili oyuncu yoksa veya silindiyse ilkini seç
          if (selectedPlayer == null || !players.contains(selectedPlayer)) {
            if (players.isNotEmpty) selectedPlayer = players.first;
          }

          return Row(
            children: [
              // --- SOL LİSTE (OYUNCULAR) ---
              Container(
                width: 280,
                margin: const EdgeInsets.only(right: 20),
                decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white10))),
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    bool isSel = selectedPlayer == p;
                    return ListTile(
                      onTap: () => setState(() => selectedPlayer = p),
                      selected: isSel,
                      selectedTileColor:
                          Colors.deepPurpleAccent.withOpacity(0.2),
                      leading: Text("${p.rating}",
                          style: GoogleFonts.russoOne(
                              fontSize: 18, color: _getRatingColor(p.rating))),
                      title: Text(p.name,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text("${p.position} | ${p.team}",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10)),
                    );
                  },
                ),
              ),

              // --- SAĞ PROFİL (DETAYLAR) ---
              if (selectedPlayer != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // --- FC KARTI BÖLÜMÜ ---
                        Center(
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              _buildFCCard(selectedPlayer!),

                              // Düzenle / Sil Menüsü (Kartın sağ üstünde)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white),
                                  color: const Color(0xFF1E1E24),
                                  onSelected: (val) {
                                    if (val == 'edit')
                                      _showEditor(selectedPlayer);
                                    if (val == 'delete') {
                                      // Silme işlemi
                                      selectedPlayer!.delete();
                                      setState(() => selectedPlayer = null);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                        value: 'edit',
                                        child: Text("Düzenle",
                                            style: TextStyle(
                                                color: Colors.white))),
                                    const PopupMenuItem(
                                        value: 'delete',
                                        child: Text("Sil",
                                            style: TextStyle(
                                                color: Colors.redAccent))),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- DETAYLI ANALİZ BUTONU ---
                        ElevatedButton.icon(
                          onPressed: () => _showDetailsDialog(context),
                          icon: const Icon(Icons.analytics_outlined,
                              color: Colors.white),
                          label: const Text("DETAYLI RAPOR & STATLAR",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side:
                                      const BorderSide(color: Colors.white24))),
                        ),

                        const SizedBox(height: 30),

                        // --- MAÇ ANALİZİ (GRAFİKLER) ---
                        Text("SON 5 MAÇ PERFORMANSI",
                            style: GoogleFonts.orbitron(
                                color: Colors.cyanAccent, letterSpacing: 2)),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: 150,
                          child: Row(
                            children: selectedPlayer!.matches.map((m) {
                              return Expanded(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(m.opponent,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 10),
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 5),
                                      // Minik Rating Bar
                                      Container(
                                        height: 50,
                                        width: 10,
                                        decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                                BorderRadius.circular(5)),
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                            height: (m.rating / 10) * 50,
                                            width: 10,
                                            decoration: BoxDecoration(
                                                color: _getRatingColor(
                                                    (m.rating * 10).toInt()),
                                                borderRadius:
                                                    BorderRadius.circular(5))),
                                      ),
                                      const SizedBox(height: 5),
                                      Text("${m.rating}",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      Text("${m.goals}G ${m.assists}A",
                                          style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                )
            ],
          );
        },
      ),
    );
  }

  // --- FC 24 TARZI KART TASARIMI ---
  Widget _buildFCCard(Player p) {
    Map<String, int> cs = p.getCardStats();
    // Playstyle kontrolü (Varsa ilk gold, yoksa ilki, hiç yoksa boş)
    PlayStyle? goldPs;
    if (p.playstyles.isNotEmpty) {
      goldPs = p.playstyles
          .firstWhere((ps) => ps.isGold, orElse: () => p.playstyles.first);
    }

    return Container(
      width: 320, height: 480, // Kart Boyutu
      decoration: const BoxDecoration(
          // Arka plan gradient (Kart Resmi yoksa)
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF141E30), Color(0xFF243B55)]),
          boxShadow: [
            BoxShadow(color: Colors.black, blurRadius: 20, spreadRadius: 5)
          ],
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(30),
              bottomLeft: Radius.circular(30),
              topLeft: Radius.circular(5),
              bottomRight: Radius.circular(5)),
          border: Border.fromBorderSide(
              BorderSide(color: Color(0xFFD4AF37), width: 2)) // Altın çerçeve
          ),
      child: Stack(
        children: [
          // 1. SOL ÜST BİLGİLER
          Positioned(
            top: 40,
            left: 25,
            child: Column(
              children: [
                Text("${p.rating}",
                    style: GoogleFonts.oswald(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1)),
                Text(p.position,
                    style: GoogleFonts.oswald(
                        fontSize: 20, color: Colors.white70)),
                const SizedBox(height: 5),
                // Bayrak ve Takım (Statik ikonlar yerine dinamik yapılabilir)
                const Icon(Icons.flag, color: Colors.redAccent, size: 30),
                const SizedBox(height: 5),
                const Icon(Icons.shield, color: Colors.blueAccent, size: 30),
              ],
            ),
          ),

          // 2. OYUNCU RESMİ (Forma No)
          Positioned(
            top: 30,
            right: 20,
            child: Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              child: Text("${p.kitNumber}",
                  style: GoogleFonts.russoOne(
                      fontSize: 100, color: Colors.white.withOpacity(0.8))),
            ),
          ),

          // 3. İSİM
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            child: Center(
                child: Text(p.name.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                        fontSize: 32,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 2))),
          ),

          // 4. STATLAR VE ÇİZGİLER
          Positioned(
            top: 250,
            left: 30,
            right: 30,
            child: Column(
              children: [
                const Divider(color: Color(0xFFD4AF37), thickness: 1),
                const SizedBox(height: 10),
                // Stat Satırları
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _cardStat("PAC", cs["PAC"]!),
                      _cardStat("DRI", cs["DRI"]!)
                    ]),
                const SizedBox(height: 5),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _cardStat("SHO", cs["SHO"]!),
                      _cardStat("DEF", cs["DEF"]!)
                    ]),
                const SizedBox(height: 5),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _cardStat("PAS", cs["PAS"]!),
                      _cardStat("PHY", cs["PHY"]!)
                    ]),
                const SizedBox(height: 15),
                const Divider(color: Color(0xFFD4AF37), thickness: 1),
              ],
            ),
          ),

          // 5. ALT KISIM (PlayStyle+ ve Rol)
          Positioned(
            bottom: 20,
            left: 20,
            child: Row(
              children: [
                if (goldPs != null)
                  Image.asset(goldPs.assetPath,
                      width: 40,
                      height: 40,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.star, color: Colors.amber)),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skill Stars
                    Row(
                        children: List.generate(
                            5,
                            (i) => Icon(
                                i < p.skillMoves
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.white,
                                size: 14))),
                    Text(p.role,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _cardStat(String label, int val) {
    return SizedBox(
      width: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("$val",
              style: GoogleFonts.oswald(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.oswald(fontSize: 18, color: Colors.white70)),
        ],
      ),
    );
  }

  // --- DETAYLI ANALİZ PENCERESİ ---
  void _showDetailsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(builder: (context, setSt) {
              return Dialog(
                backgroundColor: const Color(0xFF101014),
                child: Container(
                  width: 800,
                  height: 700,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("DETAYLI ANALİZ",
                              style: GoogleFonts.orbitron(
                                  color: Colors.cyanAccent, fontSize: 24)),
                          // FM/FC Toggle
                          Row(
                            children: [
                              Text(
                                  isFMView
                                      ? "Mod: FM (1-20)"
                                      : "Mod: FC (1-99)",
                                  style: const TextStyle(color: Colors.white)),
                              Switch(
                                  value: isFMView,
                                  onChanged: (v) => setSt(() => isFMView = v),
                                  activeColor: Colors.cyanAccent),
                            ],
                          )
                        ],
                      ),
                      const Divider(color: Colors.white24),
                      Expanded(
                        child: Row(
                          children: [
                            // Sol: Statlar (Kategorik)
                            Expanded(
                              child: ListView(
                                children: statSegments.entries.map((entry) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(entry.key,
                                              style: const TextStyle(
                                                  color: Colors.blueAccent,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      ...entry.value.map((statName) {
                                        int val =
                                            selectedPlayer!.stats[statName] ??
                                                50;
                                        // FM Dönüşümü (99 üzerinden 20'ye)
                                        int displayVal = isFMView
                                            ? (val / 99 * 20)
                                                .round()
                                                .clamp(1, 20)
                                            : val;
                                        return Row(
                                          children: [
                                            Expanded(
                                                child: Text(statName,
                                                    style: const TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12))),
                                            Text("$displayVal",
                                                style: TextStyle(
                                                    color: _getRatingColor(val),
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(width: 10),
                                            SizedBox(
                                                width: 100,
                                                height: 5,
                                                child: LinearProgressIndicator(
                                                    value: val / 99,
                                                    color: _getRatingColor(val),
                                                    backgroundColor:
                                                        Colors.white10))
                                          ],
                                        );
                                      })
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            // Sağ: PlayStyles Listesi
                            Container(
                                width: 1,
                                color: Colors.white12,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("OYUN STİLLERİ",
                                      style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 15,
                                    runSpacing: 15,
                                    children:
                                        selectedPlayer!.playstyles.map((ps) {
                                      return Column(
                                        children: [
                                          Image.asset(ps.assetPath,
                                              width: 50,
                                              height: 50,
                                              errorBuilder: (c, e, s) =>
                                                  const Icon(Icons.star,
                                                      color: Colors.white)),
                                          Text(
                                              playStyleTranslations[ps.name] ??
                                                  ps.name,
                                              style: TextStyle(
                                                  color: ps.isGold
                                                      ? Colors.amber
                                                      : Colors.white,
                                                  fontSize: 10))
                                        ],
                                      );
                                    }).toList(),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("KAPAT"))
                    ],
                  ),
                ),
              );
            }));
  }

  void _showEditor(Player? p) {
    showDialog(
        context: context,
        builder: (context) => CreatePlayerDialog(playerToEdit: p));
  }

  Color _getRatingColor(int r) {
    return r >= 90
        ? const Color(0xFF00FFC2)
        : (r >= 80 ? Colors.amber : Colors.white);
  }
}

// --- OYUNCU OLUŞTURMA / DÜZENLEME FORMU ---
class CreatePlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  const CreatePlayerDialog({super.key, this.playerToEdit});
  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _pos = "ST";
  String _team = "Takımsız";
  String _role = "Seçiniz";
  int _skillMoves = 3;
  late TabController _tabController;
  final Map<String, int> _stats = {};
  final Map<String, bool> _ps = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.playerToEdit != null) {
      // Düzenleme: Verileri Çek
      var p = widget.playerToEdit!;
      _nameController.text = p.name;
      _valueController.text = p.marketValue;
      _pos = p.position;
      _team = p.team;
      _role = p.role;
      _skillMoves = p.skillMoves;
      _stats.addAll(p.stats);
      for (var style in p.playstyles) _ps[style.name] = style.isGold;
    } else {
      // Yeni: Varsayılan
      for (var list in statSegments.values) for (var s in list) _stats[s] = 50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101014),
      child: Container(
        width: 900,
        height: 800,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
                widget.playerToEdit == null
                    ? "YENİ TRANSFER"
                    : "PROFİLİ DÜZENLE",
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.cyanAccent,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: const [
                Tab(text: "KİMLİK"),
                Tab(text: "FİZİK & TOP"),
                Tab(text: "ŞUT"),
                Tab(text: "DEFANS"),
                Tab(text: "PAS")
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. KİMLİK TABI
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _field(_nameController, "Ad Soyad"),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _dropdown("Takım", availableTeams, _team,
                                  (v) => _team = v!)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _field(_valueController, "Piyasa Değeri"))
                        ]),
                        const SizedBox(height: 20),
                        Row(children: [
                          Expanded(
                              child: _dropdown(
                                  "Mevki",
                                  availablePositions,
                                  _pos,
                                  (v) => setState(() {
                                        _pos = v!;
                                        _role = roleCategories[_pos]?.first ??
                                            "Yok";
                                      }))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _dropdown(
                                  "Rol",
                                  roleCategories[_pos] ?? ["Yok"],
                                  _role,
                                  (v) => _role = v!))
                        ]),
                        const SizedBox(height: 20),
                        const Text("YETENEK YILDIZI",
                            style: TextStyle(color: Colors.amber)),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                5,
                                (i) => IconButton(
                                    icon: Icon(
                                        i < _skillMoves
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber),
                                    onPressed: () =>
                                        setState(() => _skillMoves = i + 1)))),
                        const Divider(color: Colors.white24),
                        const Text(
                            "OYUN STİLLERİ (Tıkla: Gümüş, Basılı Tut: Altın)",
                            style: TextStyle(color: Colors.white70)),
                        Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: availablePlayStyles
                                .map((ps) => _psChip(ps))
                                .toList())
                      ],
                    ),
                  ),
                  // 2-5 STAT TABLARI
                  _statPage("1. Top Sürme & Fizik"),
                  _statPage("2. Şut & Zihinsel"),
                  _statPage("3. Savunma & Güç"),
                  _statPage("4. Pas & Vizyon"),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
              child: const Text("KAYDET",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _statPage(String key) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        spacing: 30,
        runSpacing: 20,
        children: (statSegments[key] ?? []).map((s) {
          return SizedBox(
              width: 200,
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s, style: const TextStyle(color: Colors.white70)),
                      Text("${_stats[s]}",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold))
                    ]),
                Slider(
                    value: _stats[s]!.toDouble(),
                    min: 1,
                    max: 99,
                    activeColor: _getColor(_stats[s]!),
                    onChanged: (v) => setState(() => _stats[s] = v.toInt()))
              ]));
        }).toList(),
      ),
    );
  }

  Widget _field(TextEditingController c, String l) => TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: l, filled: true, fillColor: Colors.white10));
  Widget _dropdown(String l, List<String> i, String v, Function(String?) c) =>
      DropdownButtonFormField<String>(
          value: v,
          items:
              i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: c,
          dropdownColor: const Color(0xFF1E1E24),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              labelText: l, filled: true, fillColor: Colors.white10));

  Widget _psChip(String name) {
    bool isSel = _ps.containsKey(name);
    bool isGold = isSel && _ps[name]!;
    return GestureDetector(
      onTap: () => setState(() => isSel ? _ps.remove(name) : _ps[name] = false),
      onLongPress: () => setState(() => _ps[name] = true),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: isSel
                ? (isGold ? Colors.amber.withOpacity(0.2) : Colors.white24)
                : Colors.transparent,
            border: Border.all(
                color: isSel
                    ? (isGold ? Colors.amber : Colors.white)
                    : Colors.white12),
            borderRadius: BorderRadius.circular(5)),
        child: Image.asset(
            "assets/Playstyles/${isGold ? "${name}Plus" : name}.png",
            width: 30,
            height: 30,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.help, size: 30, color: Colors.white54)),
      ),
    );
  }

  Color _getColor(int v) {
    return v > 85
        ? Colors.greenAccent
        : (v > 70 ? Colors.lightGreen : Colors.orange);
  }

  void _save() {
    if (_nameController.text.isEmpty) return;

    // Playstyle Listesini Oluştur
    List<PlayStyle> psList =
        _ps.entries.map((e) => PlayStyle(e.key, isGold: e.value)).toList();

    // Düzenleme mi Yeni mi?
    Player p = widget.playerToEdit ??
        Player(name: "", rating: 0, position: "", playstyles: []);
    p.name = _nameController.text;
    p.marketValue = _valueController.text;
    p.position = _pos;
    p.team = _team;
    p.role = _role;
    p.skillMoves = _skillMoves;
    p.stats = Map.from(_stats);
    p.playstyles = psList;

    p.calculateRating();
    if (widget.playerToEdit == null)
      p.generateRandomMatches(); // Yeni ise maç geçmişi oluştur

    // Hive'a Kaydet
    var box = Hive.box<Player>('palehax_players_v4');
    if (widget.playerToEdit == null) {
      box.add(p);
    } else {
      p.save(); // Mevcut objeyi güncelle
    }

    Navigator.pop(context);
  }
}
