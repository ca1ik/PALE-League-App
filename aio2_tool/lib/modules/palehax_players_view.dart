import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../ui/glass_box.dart';
import '../providers/language_provider.dart';

// --- Çeviriler ---
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

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  Player? selectedPlayer;
  late Box<Player> playerBox;
  bool isFMView = false;

  @override
  void initState() {
    super.initState();
    playerBox = Hive.box<Player>('palehax_players_v7'); // V7 KUTUSU
    if (playerBox.isNotEmpty) selectedPlayer = playerBox.getAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            tabs: [Tab(text: "OYUNCU PROFİLLERİ"), Tab(text: "TÜM KARTLAR")],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showEditor(null),
          label: const Text("OYUNCU OLUŞTUR",
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: Colors.cyanAccent,
        ),
        body: ValueListenableBuilder(
          valueListenable: playerBox.listenable(),
          builder: (context, Box<Player> box, _) {
            final players = box.values.toList();
            if (players.isEmpty)
              return const Center(
                  child: Text("Veritabanı boş. Yeni oyuncu oluşturun.",
                      style: TextStyle(color: Colors.white)));

            return TabBarView(
              children: [
                // --- TAB 1: PROFİL GÖRÜNÜMÜ ---
                _buildProfileView(players),
                // --- TAB 2: TÜM KARTLAR (GRID) ---
                _buildAllCardsView(players),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- TAB 1 İÇERİĞİ ---
  Widget _buildProfileView(List<Player> players) {
    if (selectedPlayer == null || !players.contains(selectedPlayer)) {
      if (players.isNotEmpty) selectedPlayer = players.first;
    }
    return Row(
      children: [
        // Liste
        Container(
          width: 280,
          margin: const EdgeInsets.only(right: 20, top: 20),
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
                selectedTileColor: Colors.cyanAccent.withOpacity(0.1),
                leading: Text("${p.rating}",
                    style: GoogleFonts.russoOne(
                        fontSize: 18, color: _getRatingColor(p.rating))),
                title: Text(p.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                subtitle: Text("${p.position} | ${p.cardType}",
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 10)),
              );
            },
          ),
        ),
        // Profil Detayı
        if (selectedPlayer != null)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 30),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        FCAnimatedCard(
                            player: selectedPlayer!), // YENİ ANİMASYONLU KART
                        _buildCardMenu(selectedPlayer!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _showDetailsDialog(context),
                    icon: const Icon(Icons.analytics_outlined,
                        color: Colors.black),
                    label: const Text("DETAYLI RAPOR & STATLAR",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20)),
                  ),
                  const SizedBox(height: 30),
                  _buildMatchHistory(selectedPlayer!),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          )
      ],
    );
  }

  // --- TAB 2 İÇERİĞİ (TÜM KARTLAR - ORTALANMIŞ WRAP) ---
  Widget _buildAllCardsView(List<Player> players) {
    // Kart tipine göre grupla
    Map<String, List<Player>> grouped = {};
    for (var type in cardTypes) {
      grouped[type] = players.where((p) => p.cardType == type).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Column(
          children:
              grouped.entries.where((e) => e.value.isNotEmpty).map((entry) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text("${entry.key.toUpperCase()} KARTLARI",
                      style: GoogleFonts.orbitron(
                          color: _getCardTypeColor(entry.key),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ),
                Wrap(
                  spacing: 30,
                  runSpacing: 40,
                  alignment: WrapAlignment.center,
                  children: entry.value
                      .map((p) => Transform.scale(
                          scale: 0.8, child: FCAnimatedCard(player: p)))
                      .toList(),
                ),
                const SizedBox(height: 40),
                const Divider(color: Colors.white12),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- YARDIMCI WIDGETLAR ---
  Widget _buildCardMenu(Player p) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white),
        color: const Color(0xFF1E1E24),
        onSelected: (val) {
          if (val == 'edit') _showEditor(p);
          if (val == 'delete') {
            p.delete();
            setState(() => selectedPlayer = null);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
              value: 'edit',
              child: Text("Düzenle", style: TextStyle(color: Colors.white))),
          const PopupMenuItem(
              value: 'delete',
              child: Text("Sil", style: TextStyle(color: Colors.redAccent)))
        ],
      ),
    );
  }

  Widget _buildMatchHistory(Player p) {
    return Column(
      children: [
        Text("SON 5 MAÇ",
            style:
                GoogleFonts.orbitron(color: Colors.white54, letterSpacing: 2)),
        const SizedBox(height: 15),
        SizedBox(
          height: 150,
          child: Row(
            children: p.matches.map((m) {
              return Expanded(
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
                                    borderRadius: BorderRadius.circular(5)))),
                        Text("${m.rating}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text("${m.goals}G",
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 10)),
                      ]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => StatefulBuilder(builder: (context, setSt) {
              Map<String, int> bonuses =
                  chemistryBonuses[selectedPlayer!.chemistryStyle] ?? {};
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
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("DETAYLI ANALİZ",
                                    style: GoogleFonts.orbitron(
                                        color: Colors.cyanAccent,
                                        fontSize: 24)),
                                Text("Kimya: ${selectedPlayer!.chemistryStyle}",
                                    style: TextStyle(
                                        color: _getCardTypeColor(
                                            selectedPlayer!.cardType)))
                              ]),
                          Row(children: [
                            Text(isFMView ? "Mod: FM (1-20)" : "Mod: FC (1-99)",
                                style: const TextStyle(color: Colors.white)),
                            Switch(
                                value: isFMView,
                                onChanged: (v) => setSt(() => isFMView = v),
                                activeColor: Colors.cyanAccent)
                          ])
                        ]),
                    const Divider(color: Colors.white24),
                    Expanded(
                        child: Row(children: [
                      Expanded(
                          child: ListView(
                              children: statSegments.entries.map((entry) {
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(entry.key,
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold))),
                              ...entry.value.map((statName) {
                                int val = selectedPlayer!.stats[statName] ?? 50;
                                int displayVal = isFMView
                                    ? (val / 99 * 20).round().clamp(1, 20)
                                    : val;
                                int bonus = bonuses[statName] ?? 0;
                                return Row(children: [
                                  Expanded(
                                      child: Text(statName,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12))),
                                  if (!isFMView && bonus > 0) ...[
                                    Text("$displayVal",
                                        style: TextStyle(
                                            color: _getRatingColor(val),
                                            fontWeight: FontWeight.bold)),
                                    Text(" +$bonus",
                                        style: TextStyle(
                                            color: _getCardTypeColor(
                                                selectedPlayer!.cardType),
                                            fontWeight: FontWeight.bold))
                                  ] else
                                    Text("$displayVal",
                                        style: TextStyle(
                                            color: _getRatingColor(val),
                                            fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                      width: 100,
                                      height: 5,
                                      child: LinearProgressIndicator(
                                          value:
                                              (val + (isFMView ? 0 : bonus)) /
                                                  99,
                                          color: bonus > 0
                                              ? _getCardTypeColor(
                                                  selectedPlayer!.cardType)
                                              : _getRatingColor(val),
                                          backgroundColor: Colors.white10))
                                ]);
                              })
                            ]);
                      }).toList())),
                      Container(
                          width: 1,
                          color: Colors.white12,
                          margin: const EdgeInsets.symmetric(horizontal: 20)),
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
                                children: selectedPlayer!.playstyles.map((ps) {
                                  return Column(children: [
                                    Image.asset(ps.assetPath,
                                        width: 50,
                                        height: 50,
                                        errorBuilder: (c, e, s) => const Icon(
                                            Icons.star,
                                            color: Colors.white)),
                                    Text(
                                        playStyleTranslations[ps.name] ??
                                            ps.name,
                                        style: TextStyle(
                                            color: ps.isGold
                                                ? Colors.amber
                                                : Colors.white,
                                            fontSize: 10))
                                  ]);
                                }).toList())
                          ]))
                    ])),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("KAPAT",
                            style: TextStyle(color: Colors.white)))
                  ]),
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

  Color _getCardTypeColor(String type) {
    switch (type) {
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
}

// --- GELİŞMİŞ ANİMASYONLU KART WIDGET'I (V7) ---
class FCAnimatedCard extends StatefulWidget {
  final Player player;
  const FCAnimatedCard({super.key, required this.player});
  @override
  State<FCAnimatedCard> createState() => _FCAnimatedCardState();
}

class _FCAnimatedCardState extends State<FCAnimatedCard>
    with TickerProviderStateMixin {
  late AnimationController _rgbController;
  late AnimationController _pulseController;
  final List<Offset> _stars = List.generate(
      20,
      (i) => Offset(Random().nextDouble(),
          Random().nextDouble())); // Rastgele yıldız konumları

  @override
  void initState() {
    super.initState();
    _rgbController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rgbController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Player p = widget.player;
    Map<String, int> cs = p.getCardStats();
    PlayStyle? goldPs = p.playstyles.isNotEmpty
        ? p.playstyles
            .firstWhere((ps) => ps.isGold, orElse: () => p.playstyles.first)
        : null;
    String type = p.cardType;

    // Kart Stilleri
    BoxDecoration baseDecor = BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5)
        ],
        border: Border.all(width: 2, color: _getBorderColor(type)));
    LinearGradient bgGradient = _getBgGradient(type);

    return AnimatedBuilder(
        animation: Listenable.merge([_rgbController, _pulseController]),
        builder: (context, child) {
          return Container(
            width: 320,
            height: 480,
            decoration: baseDecor.copyWith(
                gradient: bgGradient,
                border: type == "TOTY" || type == "STAR" || type == "BALLOND'OR"
                    ? null
                    : baseDecor.border, // RGB ise border'ı shader yapacak
                boxShadow: [
                  BoxShadow(
                      color: _getGlowColor(type)
                          .withOpacity(_pulseController.value * 0.5 + 0.2),
                      blurRadius: 30,
                      spreadRadius: 5)
                ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // --- ARKA PLAN EFEKTLERİ ---
                  if (type == "TOTY" || type == "STAR" || type == "BALLOND'OR")
                    _buildParticles(type),

                  // --- RGB BORDER (ShaderMask) ---
                  if (type == "TOTY" || type == "STAR" || type == "BALLOND'OR")
                    Positioned.fill(
                        child: ShaderMask(
                            shaderCallback: (bounds) {
                              return SweepGradient(
                                      transform: GradientRotation(
                                          _rgbController.value * 2 * pi),
                                      colors: type == "BALLOND'OR"
                                          ? [
                                              Colors.amber,
                                              Colors.white,
                                              Colors.amber
                                            ]
                                          : [
                                              Colors.red,
                                              Colors.blue,
                                              Colors.green,
                                              Colors.red
                                            ])
                                  .createShader(bounds);
                            },
                            child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        width: 3, color: Colors.white))))),

                  // --- KART İÇERİĞİ ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      children: [
                        // Üst Kısım: Logolar ve Kimya
                        Positioned(
                            top: 0,
                            left: 0,
                            child: Icon(Icons.sports_soccer,
                                color: _getTextColor(type).withOpacity(0.7),
                                size: 30)), // Pale Logo Placeholder
                        Positioned(
                            top: 0,
                            right: 0,
                            child: Icon(Icons.shield,
                                color: _getTextColor(type).withOpacity(0.7),
                                size: 30)), // Takım Logo Placeholder
                        Positioned(
                            top: 5,
                            left: 0,
                            right: 0,
                            child: Center(
                                child: Text(p.chemistryStyle.toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                        color: _getBorderColor(type),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)))),

                        // Sol Üst Bilgiler
                        Positioned(
                            top: 50,
                            left: 0,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${p.rating}",
                                      style: GoogleFonts.orbitron(
                                          fontSize: 45,
                                          fontWeight: FontWeight.bold,
                                          color: _getTextColor(type),
                                          height: 1)),
                                  Text(p.position,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 20,
                                          color: _getTextColor(type)
                                              .withOpacity(0.8),
                                          fontWeight: FontWeight.bold)),
                                ])),

                        // Forma No ve Yıldızlar
                        Positioned(
                            top: 50,
                            right: 10,
                            child: Column(children: [
                              Text("${p.kitNumber}",
                                  style: GoogleFonts.russoOne(
                                      fontSize: 80,
                                      color: _getTextColor(type)
                                          .withOpacity(0.3))),
                              Row(
                                  children: List.generate(
                                      5,
                                      (i) => Icon(
                                          i < p.skillMoves
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: _getBorderColor(type),
                                          size: 16))),
                            ])),

                        // İsim
                        Positioned(
                            top: 180,
                            left: 0,
                            right: 0,
                            child: Center(
                                child: Text(p.name.toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                        fontSize: 28,
                                        color: _getTextColor(type),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5),
                                    overflow: TextOverflow.ellipsis))),

                        // Statlar
                        Positioned(
                            top: 240,
                            left: 20,
                            right: 20,
                            child: Column(children: [
                              const Divider(color: Colors.white30),
                              const SizedBox(height: 10),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _cStat("PAC", cs["PAC"]!, type),
                                    _cStat("DRI", cs["DRI"]!, type)
                                  ]),
                              const SizedBox(height: 5),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _cStat("SHO", cs["SHO"]!, type),
                                    _cStat("DEF", cs["DEF"]!, type)
                                  ]),
                              const SizedBox(height: 5),
                              Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _cStat("PAS", cs["PAS"]!, type),
                                    _cStat("PHY", cs["PHY"]!, type)
                                  ]),
                            ])),

                        // Sol Kenar Playstyle+
                        if (goldPs != null)
                          Positioned(
                              left: -10,
                              bottom: 80,
                              child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Row(children: [
                                    Text(
                                        playStyleTranslations[goldPs.name] ??
                                            goldPs.name,
                                        style: GoogleFonts.montserrat(
                                            color: _getBorderColor(type),
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 5),
                                    Image.asset(goldPs.assetPath,
                                        width: 25,
                                        height: 25,
                                        errorBuilder: (c, e, s) => Icon(
                                            Icons.star,
                                            color: _getBorderColor(type),
                                            size: 25))
                                  ]))),

                        // Alt Kısım Rol
                        Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                                child: Text(p.role.toUpperCase(),
                                    style: GoogleFonts.montserrat(
                                        color: _getTextColor(type)
                                            .withOpacity(0.6),
                                        letterSpacing: 2,
                                        fontSize: 12)))),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Widget _cStat(String l, int v, String t) => Row(children: [
        Text("$v",
            style: GoogleFonts.orbitron(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _getTextColor(t))),
        const SizedBox(width: 5),
        Text(l,
            style: GoogleFonts.montserrat(
                fontSize: 16, color: _getTextColor(t).withOpacity(0.7)))
      ]);

  Widget _buildParticles(String type) {
    Color pColor = type == "MVP"
        ? Colors.red
        : (type == "BALLOND'OR" ? Colors.amber : Colors.white);
    IconData pIcon = type == "MVP" ? Icons.circle : (Icons.star);
    return Stack(
        children: _stars
            .map((pos) => Positioned(
                left: pos.dx * 320,
                top: (pos.dy + _rgbController.value) % 1 * 480,
                child: Icon(pIcon,
                    color: pColor.withOpacity(0.3),
                    size: type == "MVP" ? 4 : 10)))
            .toList());
  }

  Color _getBorderColor(String t) {
    switch (t) {
      case "TOTW":
        return Colors.amber;
      case "TOTM":
        return Colors.purpleAccent;
      case "MVP":
        return Colors.redAccent;
      case "BALLOND'OR":
        return Colors.amberAccent;
      case "BAD":
        return Colors.pinkAccent;
      case "TOTY":
      case "STAR":
        return Colors.cyanAccent;
      default:
        return Colors.white;
    }
  }

  Color _getGlowColor(String t) {
    switch (t) {
      case "MVP":
        return Colors.red;
      case "BAD":
        return Colors.pink;
      case "BALLOND'OR":
        return Colors.amber[700]!;
      default:
        return _getBorderColor(t);
    }
  }

  Color _getTextColor(String t) {
    return t == "BALLOND'OR" ? Colors.amber[100]! : Colors.white;
  }

  LinearGradient _getBgGradient(String t) {
    switch (t) {
      case "TOTW":
        return const LinearGradient(
            colors: [Color(0xFF2C2C2C), Color(0xFFA47F35)],
            begin: Alignment.topLeft);
      case "TOTM":
        return const LinearGradient(
            colors: [Color(0xFF3E1E68), Color(0xFFC2185B)],
            begin: Alignment.topLeft);
      case "MVP":
        return const LinearGradient(
            colors: [Colors.black, Color(0xFF4A0000)],
            begin: Alignment.topCenter);
      case "BALLOND'OR":
        return const LinearGradient(
            colors: [Color(0xFF8E6E1D), Colors.black, Color(0xFFF8D568)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight);
      case "BAD":
        return const LinearGradient(
            colors: [Color(0xFF2C001E), Color(0xFF880E4F)],
            begin: Alignment.topLeft);
      case "TOTY":
      case "STAR":
        return const LinearGradient(
            colors: [Color(0xFF141E30), Color(0xFF243B55)],
            begin: Alignment.topLeft);
      default:
        return const LinearGradient(
            colors: [Color(0xFF232526), Color(0xFF414345)],
            begin: Alignment.topLeft);
    }
  }
}

// --- EDİTÖR FORMU (V7: Kart Tipi Eklendi) ---
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
  String _pos = "ST",
      _team = "Takımsız",
      _role = "Seçiniz",
      _chem = "Temel",
      _type = "Temel";
  int _skillMoves = 3;
  late TabController _tabController;
  final Map<String, int> _stats = {};
  final Map<String, bool> _ps = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    if (widget.playerToEdit != null) {
      var p = widget.playerToEdit!;
      _nameController.text = p.name;
      _valueController.text = p.marketValue;
      _pos = p.position;
      _team = p.team;
      _role = p.role;
      _skillMoves = p.skillMoves;
      _chem = p.chemistryStyle;
      _type = p.cardType;
      _stats.addAll(p.stats);
      for (var s in p.playstyles) _ps[s.name] = s.isGold;
    } else {
      for (var l in statSegments.values) for (var s in l) _stats[s] = 50;
      _role = roleCategories["ST"]!.first;
      _chem = chemistryBonuses.keys.first;
      _type = cardTypes.first;
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
            child: Column(children: [
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
                  ]),
              Expanded(
                  child: TabBarView(controller: _tabController, children: [
                SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
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
                                      _role =
                                          roleCategories[_pos]?.first ?? "Yok";
                                    }))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dropdown(
                                "Rol",
                                roleCategories[_pos] ?? ["Yok"],
                                _role,
                                (v) => _role = v!)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dropdown(
                                "Kimya",
                                chemistryBonuses.keys.toList(),
                                _chem,
                                (v) => _chem = v!)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dropdown("Kart Tipi", cardTypes, _type,
                                (v) => _type = v!))
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
                      const Text("OYUN STİLLERİ",
                          style: TextStyle(color: Colors.white70)),
                      Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: availablePlayStyles
                              .map((ps) => _psChip(ps))
                              .toList())
                    ])),
                _statPage("1. Top Sürme & Fizik"),
                _statPage("2. Şut & Zihinsel"),
                _statPage("3. Savunma & Güç"),
                _statPage("4. Pas & Vizyon")
              ])),
              ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15)),
                  child: const Text("KAYDET",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)))
            ])));
  }

  Widget _statPage(String k) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Wrap(
          spacing: 30,
          runSpacing: 20,
          children: (statSegments[k] ?? [])
              .map((s) => SizedBox(
                  width: 200,
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s,
                              style: const TextStyle(color: Colors.white70)),
                          Text("${_stats[s]}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))
                        ]),
                    Slider(
                        value: _stats[s]!.toDouble(),
                        min: 1,
                        max: 99,
                        activeColor: _getColor(_stats[s]!),
                        onChanged: (v) => setState(() => _stats[s] = v.toInt()))
                  ])))
              .toList()));
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
  Widget _psChip(String n) {
    bool s = _ps.containsKey(n);
    bool g = s && _ps[n]!;
    return GestureDetector(
        onTap: () => setState(() => s ? _ps.remove(n) : _ps[n] = false),
        onLongPress: () => setState(() => _ps[n] = true),
        child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: s
                    ? (g ? Colors.amber.withOpacity(0.2) : Colors.white24)
                    : Colors.transparent,
                border: Border.all(
                    color:
                        s ? (g ? Colors.amber : Colors.white) : Colors.white12),
                borderRadius: BorderRadius.circular(5)),
            child: Image.asset("assets/Playstyles/${g ? "${n}Plus" : n}.png",
                width: 30,
                height: 30,
                errorBuilder: (c, e, x) =>
                    const Icon(Icons.help, size: 30, color: Colors.white54))));
  }

  Color _getColor(int v) {
    return v > 85
        ? Colors.greenAccent
        : (v > 70 ? Colors.lightGreen : Colors.orange);
  }

  void _save() {
    if (_nameController.text.isEmpty) return;
    List<PlayStyle> ps =
        _ps.entries.map((e) => PlayStyle(e.key, isGold: e.value)).toList();
    Player p = widget.playerToEdit ??
        Player(name: "", rating: 0, position: "", playstyles: []);
    p.name = _nameController.text;
    p.marketValue = _valueController.text;
    p.position = _pos;
    p.team = _team;
    p.role = _role;
    p.skillMoves = _skillMoves;
    p.chemistryStyle = _chem;
    p.cardType = _type;
    p.stats = Map.from(_stats);
    p.playstyles = ps;
    p.calculateRating();
    if (widget.playerToEdit == null) p.generateRandomMatches();
    var box = Hive.box<Player>('palehax_players_v7');
    if (widget.playerToEdit == null)
      box.add(p);
    else
      p.save();
    Navigator.pop(context);
  }
}
