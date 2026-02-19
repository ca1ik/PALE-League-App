import '../modules/palehax_players_view.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:screenshot/screenshot.dart'; // EKLENDİ: Ekran görüntüsü için

// Kendi proje yapına göre bu importların doğruluğundan emin ol
import '../data/player_data.dart' as pd;
import '../data/player_data.dart' show Player, PlayStyle;
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart'; // Kart tasarımı dosyan
// import '../modules/player_editor.dart'; // BUNU KAPATTIM, AŞAĞIYA EKLEDİM
import 'pale_webview.dart';

void _showTeamDialog(
    BuildContext context, String teamName, String? logo, AppDatabase db) {
  List<String> roster = List.from(manualTeamRosters[teamName] ?? []);
  String marketValue = teamMarketValues[teamName] ?? "€0M";
  showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
            List<String> captains =
                roster.where((n) => n.contains("⭐")).toList();
            List<String> others = roster.where((n) => !n.contains("⭐")).toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            List<String> sorted = [...captains, ...others];
            return Dialog(
                backgroundColor: const Color(0xFF0D0D12),
                child: Container(
                    width: 600,
                    height: 750,
                    padding: const EdgeInsets.all(30),
                    child: Column(children: [
                      if (logo != null)
                        Image.asset(logo,
                            width: 80,
                            height: 80,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.shield, color: Colors.white)),
                      const SizedBox(height: 15),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(teamName,
                                style: GoogleFonts.orbitron(
                                    color: Colors.cyanAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                                icon: const Icon(Icons.person_add_alt_1,
                                    color: Colors.greenAccent),
                                onPressed: () => _addNewPlayerToRoster(
                                    context,
                                    teamName,
                                    (newName) => setModalState(
                                        () => roster.add(newName))))
                          ]),
                      Text("${pd.PaleHaxLoc.txt("KADRO DEĞERİ")}: $marketValue",
                          style: GoogleFonts.russoOne(
                              color: Colors.greenAccent, fontSize: 18)),
                      const Divider(color: Colors.white24),
                      Expanded(
                          child: ListView.builder(
                              itemCount: sorted.length,
                              itemBuilder: (c, i) {
                                String raw = sorted[i];
                                bool isCap = raw.contains("⭐");
                                String clean = raw.replaceAll("⭐", "").trim();
                                return ListTile(
                                    onTap: () =>
                                        _tryOpenCard(context, db, clean),
                                    leading: Text("${i + 1}.",
                                        style: TextStyle(
                                            color: isCap
                                                ? Colors.amber
                                                : Colors.white54)),
                                    title: Text(clean,
                                        style: TextStyle(
                                            color: isCap
                                                ? Colors.amber
                                                : Colors.white,
                                            fontWeight: isCap
                                                ? FontWeight.bold
                                                : FontWeight.normal)),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isCap)
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 18),
                                          PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert,
                                                  color: Colors.white38),
                                              onSelected: (val) {
                                                if (val == 'remove')
                                                  setModalState(
                                                      () => roster.remove(raw));
                                                if (val == 'make_cap')
                                                  setModalState(() {
                                                    int idx =
                                                        roster.indexOf(raw);
                                                    roster[idx] = "$raw⭐";
                                                  });
                                              },
                                              itemBuilder: (c) => [
                                                    PopupMenuItem(
                                                        value: 'make_cap',
                                                        child: Text(
                                                            pd.PaleHaxLoc.txt(
                                                                "Kaptan Yap"))),
                                                    PopupMenuItem(
                                                        value: 'remove',
                                                        child: Text(
                                                            pd.PaleHaxLoc.txt(
                                                                "Sil"),
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .redAccent)))
                                                  ])
                                        ]));
                              })),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(pd.PaleHaxLoc.txt("KAPAT")))
                    ])));
          }));
}

void _addNewPlayerToRoster(
    BuildContext context, String teamName, Function(String) onAdd) {
  TextEditingController ctrl = TextEditingController();
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              title: Text("$teamName - ${pd.PaleHaxLoc.txt("Yeni Oyuncu")}"),
              content: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      InputDecoration(hintText: pd.PaleHaxLoc.txt("Ad Soyad"))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(pd.PaleHaxLoc.txt("İptal"))),
                ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        onAdd(ctrl.text.replaceAll(" ", "_"));
                        Navigator.pop(context);
                      }
                    },
                    child: Text(pd.PaleHaxLoc.txt("Ekle")))
              ]));
}

void _tryOpenCard(
    BuildContext context, AppDatabase db, String playerName) async {
  final allPlayers = await db.select(db.playerTables).get();
  try {
    final match = allPlayers.firstWhere(
        (p) => p.name.toLowerCase().trim() == playerName.toLowerCase().trim());
    Map<String, int> st = Map<String, int>.from(jsonDecode(match.statsJson));
    List<PlayStyle> ps = (jsonDecode(match.playStylesJson) as List)
        .map((e) => PlayStyle(e.toString()))
        .toList();
    Player pObj = Player(
        name: match.name,
        rating: match.rating,
        position: match.position,
        playstyles: ps,
        cardType: match.cardType,
        team: match.team,
        stats: st,
        role: match.role,
        style: "Temel",
        styleTier: 0);
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FCAnimatedCard(player: pObj, animateOnHover: true),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(pd.PaleHaxLoc.txt("KAPAT")))
            ])));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(pd.PaleHaxLoc.txt("Bu oyuncunun kartı henüz oluşturulmamış.")),
        backgroundColor: Colors.redAccent));
  }
}

void _showDetailedStats(BuildContext context, Player p) {
  showDialog(
      context: context,
      builder: (_) => Dialog(
          backgroundColor: const Color(0xFF101014),
          child: Container(
              width: 1200,
              height: 700,
              padding: const EdgeInsets.all(30),
              child: Column(children: [
                Text(pd.PaleHaxLoc.txt("DETAYLI OYUNCU ANALİZİ"),
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24, height: 30),
                Expanded(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: pd.statSegments.entries.map((entry) {
                              return Container(
                                  width: 250,
                                  margin: const EdgeInsets.only(right: 30),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.key,
                                            style: GoogleFonts.orbitron(
                                                color: Colors.amber,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        const Divider(color: Colors.white24),
                                        const SizedBox(height: 10),
                                        ...entry.value.map((statName) {
                                          int val = p.stats[statName] ?? 50;
                                          return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(statName,
                                                        style: const TextStyle(
                                                            color:
                                                                Colors.white70,
                                                            fontSize: 15)),
                                                    Text("$val",
                                                        style: TextStyle(
                                                            color: val >= 80
                                                                ? Colors
                                                                    .greenAccent
                                                                : (val >= 60
                                                                    ? Colors
                                                                        .amber
                                                                    : Colors
                                                                        .redAccent),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20))
                                                  ]));
                                        })
                                      ]));
                            }).toList()))),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10),
                    child: Text(pd.PaleHaxLoc.txt("KAPAT")))
              ]))));
}

void _showGlobal(
    BuildContext context, AppDatabase db, Function(dynamic) onSelect) {
  String sort = pd.PaleHaxLoc.txt("Reyting"),
      filter = pd.PaleHaxLoc.txt("Tümü"),
      query = "";
  showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
          builder: (c, setS) => Dialog(
              backgroundColor: const Color(0xFF0D0D12),
              child: Container(
                  width: 1100,
                  height: 850,
                  padding: const EdgeInsets.all(25),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(
                          width: 250,
                          child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                  hintText: pd.PaleHaxLoc.txt("Ara..."),
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.cyanAccent)),
                              onChanged: (v) => setS(() => query = v))),
                      const SizedBox(width: 30),
                      DropdownButton<String>(
                          value: filter,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            pd.PaleHaxLoc.txt("Tümü"),
                            ...pd.globalCardTypes
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setS(() => filter = v!)),
                      const SizedBox(width: 30),
                      DropdownButton<String>(
                          value: sort,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            pd.PaleHaxLoc.txt("Reyting"),
                            pd.PaleHaxLoc.txt("A-Z"),
                            pd.PaleHaxLoc.txt("En Yeni")
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setS(() => sort = v!)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(c))
                    ]),
                    const Divider(color: Colors.white10),
                    Expanded(
                        child: StreamBuilder<List<dynamic>>(
                            stream: db.watchFilteredPlayers(
                                searchQuery: query,
                                cardTypeFilter: filter,
                                sortOption: sort),
                            builder: (c, sn) {
                              if (!sn.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());
                              return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          childAspectRatio: 0.65),
                                  itemCount: sn.data!.length,
                                  itemBuilder: (c, i) {
                                    final t = sn.data![i];
                                    List<PlayStyle> ps = [];
                                    try {
                                      var l =
                                          jsonDecode(t.playStylesJson) as List;
                                      ps = l
                                          .map((e) => PlayStyle(e.toString()))
                                          .toList();
                                    } catch (_) {}
                                    Player p = Player(
                                        name: t.name,
                                        rating: t.rating,
                                        position: t.position,
                                        playstyles: ps,
                                        cardType: t.cardType,
                                        team: t.team,
                                        role: t.role,
                                        style: "Temel",
                                        styleTier: 0);
                                    return GestureDetector(
                                        onTap: () {
                                          onSelect(t);
                                          Navigator.pop(c);
                                        },
                                        child: Transform.scale(
                                            scale: 0.9,
                                            child: FCAnimatedCard(
                                                player: p,
                                                animateOnHover: true)));
                                  });
                            }))
                  ])))));
}

Widget _infoBadge(String label, String val, {Color color = Colors.white}) =>
    Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 4),
      Text(val,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16))
    ]);
Widget _statBox(String l, String v, Color c) => Container(
    padding: const EdgeInsets.all(12),
    width: 110,
    decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        border: Border.all(color: c.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(v,
          style:
              TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(l, style: TextStyle(color: c.withOpacity(0.7), fontSize: 11))
    ]));

class _MiniPitchPainter extends CustomPainter {
  final Offset playerPos;
  _MiniPitchPainter({required this.playerPos});
  @override
  void paint(Canvas c, Size s) {
    Paint lp = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), lp);
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), lp);
    c.drawCircle(Offset(s.width / 2, s.height / 2), 15, lp);
    c.drawRect(
        Rect.fromLTWH(s.width * 0.25, 0, s.width * 0.5, s.height * 0.15), lp);
    c.drawRect(
        Rect.fromLTWH(
            s.width * 0.25, s.height * 0.85, s.width * 0.5, s.height * 0.15),
        lp);
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

Color _getRatingColor(int r) =>
    r >= 90 ? const Color(0xFF00FFC2) : (r >= 80 ? Colors.amber : Colors.white);
Color _getCardTypeColor(String t) {
  switch (t) {
    case "TOTS":
      return Colors.cyanAccent;
    case "BALLOND'OR":
      return Colors.amber;
    case "MVP":
      return Colors.redAccent;
    case "BAD":
      return Colors.pinkAccent;
    case "TOTW":
      return Colors.amber;
    case "TOTM":
      return const Color(0xFFE91E63);
    case "STAR":
      return Colors.cyan;
    default:
      return Colors.white;
  }
}

Widget _buildMatchHistory(Player p, bool showRec) {
  return Column(
      children: p.matches
          .map((m) =>
              Text(m.opponent, style: const TextStyle(color: Colors.white)))
          .toList());
}

Widget _buildCardMenu(BuildContext context, Player p, Function(Player) onSave,
    Function(Player) onDelete) {
  return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF1E1E24),
      onSelected: (val) {
        if (val == 'edit')
          _showEditor(
              context,
              p,
              (newP, oldP) => onSave(
                  newP)); // onSave burada sadece yeni player alıyor, wrapper gerekebilir ama _ViewProfile içinde onSave zaten tek parametreli tanımlanmış, bu yüzden _ViewProfile'ı güncellememiz gerekebilir veya _showEditor'ı uyarlamalıyız.
        // DÜZELTME: _ViewProfile içindeki onSave tek parametreli (Player). Ancak _showEditor artık (Player, Player?) istiyor.
        // Bu yüzden _ViewProfile'ı güncellemek yerine _showEditor çağrısını düzeltelim.
        _showEditor(context, p, (newP, oldP) => onSave(newP));
        if (val == 'delete') {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    backgroundColor: const Color(0xFF1E1E24),
                    title: Text(pd.PaleHaxLoc.txt("Kartı Sil")),
                    content: Text("${p.name} (${p.cardType}) silinsin mi?"),
                    actions: [
                      TextButton(
                          child: Text(pd.PaleHaxLoc.txt("İptal")),
                          onPressed: () => Navigator.pop(context)),
                      TextButton(
                          child: Text(pd.PaleHaxLoc.txt("Sil"),
                              style: TextStyle(color: Colors.redAccent)),
                          onPressed: () {
                            onDelete(p);
                            Navigator.pop(context);
                          })
                    ]);
              });
        }
      },
      itemBuilder: (c) => [
            PopupMenuItem(
                value: 'edit', child: Text(pd.PaleHaxLoc.txt("DÜZENLE"))),
            PopupMenuItem(
                value: 'delete',
                child: Text(pd.PaleHaxLoc.txt("SİL"),
                    style: const TextStyle(color: Colors.redAccent)))
          ]);
}

void _createVersion(BuildContext context, Player p, Function(Player) onSave) {
  Player nV = Player(
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
      style: p.style,
      styleTier: p.styleTier);
  showDialog(
      context: context,
      builder: (c) => CreatePlayerDialog(
          playerToEdit: nV,
          isNewVersion: true,
          onSave: (p) {
            if (p != null) onSave(p);
          }));
}

// ============================================================================
// BÖLÜM 6: VİTRİN VE SQUAD BUILDER FONKSİYONLARI
// ============================================================================

void _showGlobalShowcase(BuildContext context, AppDatabase db) async {
  // Verileri çek
  final allRows = await db.select(db.playerTables).get();

  // Kart Tipine Göre Gruplama
  Map<String, List<Player>> groupedPlayers = {};

  // Dönüştür ve Filtrele
  for (var row in allRows) {
    // Temel kartları atla
    if (row.cardType != "Temel") {
      // Basit convert işlemi
      List<PlayStyle> ps = [];
      try {
        var l = jsonDecode(row.playStylesJson) as List;
        ps = l.map((e) {
          String s = e.toString();
          return s.endsWith("+")
              ? PlayStyle(s.substring(0, s.length - 1), isGold: true)
              : PlayStyle(s, isGold: false);
        }).toList();
      } catch (_) {}

      Player p = Player(
          name: row.name,
          rating: row.rating,
          position: row.position,
          playstyles: ps,
          cardType: row.cardType,
          team: row.team,
          stats: {},
          role: row.role ?? "Yok",
          style: "Temel",
          styleTier: 0);

      if (!groupedPlayers.containsKey(row.cardType)) {
        groupedPlayers[row.cardType] = [];
      }
      groupedPlayers[row.cardType]!.add(p);
    }
  }

  // Her grubu kendi içinde reytinge göre sırala
  groupedPlayers.forEach((key, list) {
    list.sort((a, b) => b.rating.compareTo(a.rating));
  });

  showDialog(
      context: context,
      builder: (c) => _ShowcaseDialog(groupedPlayers: groupedPlayers));
}

// Animasyonlu Arka Plan İçin Widget
class _ShowcaseDialog extends StatefulWidget {
  final Map<String, List<Player>> groupedPlayers;
  const _ShowcaseDialog({required this.groupedPlayers});

  @override
  State<_ShowcaseDialog> createState() => _ShowcaseDialogState();
}

class _ShowcaseDialogState extends State<_ShowcaseDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF0D0D12), const Color(0xFF1A237E),
                      _controller.value)!,
                  Color.lerp(const Color(0xFF000000), const Color(0xFF311B92),
                      _controller.value)!,
                  Color.lerp(const Color(0xFF1A237E), const Color(0xFF4A148C),
                      _controller.value)!,
                ],
              ),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: Column(
              children: [
                // RGB / Gradient Yazı Efekti
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Colors.cyanAccent,
                      Colors.purpleAccent,
                      Colors.amber
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(pd.PaleHaxLoc.txt("VİTRİN"),
                      style: GoogleFonts.russoOne(
                          color: Colors.white, // ShaderMask bunu ezecek
                          fontSize: 50,
                          letterSpacing: 10)),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.groupedPlayers.entries.map((entry) {
                        Color typeColor = _getCardTypeColor(entry.key);
                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // ORTALA
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center, // ORTALA
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) => LinearGradient(
                                      colors: [typeColor, Colors.white],
                                    ).createShader(bounds),
                                    child: Text(entry.key,
                                        style: GoogleFonts.orbitron(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 30,
                              runSpacing: 30,
                              alignment:
                                  WrapAlignment.center, // KARTLARI ORTALA
                              children: entry.value
                                  .map((p) => Transform.scale(
                                      scale: 1.1,
                                      child: FCAnimatedCard(
                                          player: p, animateOnHover: true)))
                                  .toList(),
                            ),
                            const SizedBox(height: 60), // BOŞLUK ARTTIRILDI
                            Divider(color: Colors.white.withOpacity(0.1)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 20)),
                    onPressed: () => Navigator.pop(context),
                    child: Text(pd.PaleHaxLoc.txt("KAPAT"),
                        style: TextStyle(color: Colors.white)))
              ],
            ),
          ),
        );
      },
    );
  }
}

void _showSquadBuilder(BuildContext context, AppDatabase db) {
  showDialog(
    context: context,
    builder: (c) => _SquadBuilderDialog(database: db),
  );
}

class _SquadBuilderDialog extends StatefulWidget {
  final AppDatabase database;
  const _SquadBuilderDialog({required this.database});

  @override
  State<_SquadBuilderDialog> createState() => _SquadBuilderDialogState();
}

class _SquadBuilderDialogState extends State<_SquadBuilderDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  TextEditingController _teamNameController =
      TextEditingController(text: "TEAM OF THE SEASON");
  bool isVertical = true;
  String searchQuery = "";

  // 7 Pozisyon: 0:GK, 1:LCB, 2:RCB, 3:CAM, 4:LW, 5:RW, 6:ST
  List<Player?> squad = List.filled(7, null);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D0D12),
      insetPadding: EdgeInsets.zero, // Full screen hissiyatı
      child: SizedBox(
        width: MediaQuery.of(context).size.width, // TAM EKRAN
        height: MediaQuery.of(context).size.height, // TAM EKRAN
        child: Row(
          children: [
            // --- SOL: SAHA VE KADRO ---
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Üst Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    color: Colors.black26,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 400,
                          child: TextField(
                            controller: _teamNameController,
                            style: GoogleFonts.russoOne(
                                color: Colors.white, fontSize: 24),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: pd.PaleHaxLoc.txt("TAKIM İSMİ"),
                                hintStyle:
                                    const TextStyle(color: Colors.white24)),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                  isVertical
                                      ? Icons.stay_current_portrait
                                      : Icons.stay_current_landscape,
                                  color: Colors.white),
                              tooltip: "Yönü Değiştir",
                              onPressed: () =>
                                  setState(() => isVertical = !isVertical),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _capture,
                              icon: const Icon(Icons.download,
                                  color: Colors.black),
                              label: Text(pd.PaleHaxLoc.txt("İNDİR (PNG)"),
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context))
                          ],
                        )
                      ],
                    ),
                  ),
                  // Saha Alanı
                  Expanded(
                    child: Screenshot(
                      controller: _screenshotController,
                      child: Container(
                        // DÜZELTME: Sabit boyut yerine sonsuz boyut ile alanı dolduruyoruz
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF050505),
                                  Color(0xFF101025),
                                  Color(0xFF050505)
                                ]),
                            // Kenarlık inceltildi, radius kaldırıldı (Tam otursun diye)
                            border:
                                Border.all(color: Colors.white12, width: 2)),
                        child: Stack(
                          children: [
                            // Saha Çizgileri
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _PitchLinesPainter(
                                        isVertical: isVertical))),

                            // Takım İsmi
                            Positioned(
                                top: 20,
                                left: 0,
                                right: 0,
                                child: Center(
                                    child: ValueListenableBuilder<
                                            TextEditingValue>(
                                        valueListenable: _teamNameController,
                                        builder: (context, value, child) {
                                          return Text(value.text.toUpperCase(),
                                              style: GoogleFonts.russoOne(
                                                  color: Colors.white10,
                                                  fontSize: 80));
                                        }))),

                            // OYUNCU SLOTLARI VE NUMARALAR
                            // Kaleci (1)
                            _buildSlot(0, "GK", isVertical ? 0.5 : 0.1,
                                isVertical ? 0.88 : 0.5, 1),
                            // İlk Defans (3)
                            _buildSlot(1, "DEF", isVertical ? 0.3 : 0.25,
                                isVertical ? 0.72 : 0.3, 3),
                            // Yanındaki Defans (6)
                            _buildSlot(2, "DEF", isVertical ? 0.7 : 0.25,
                                isVertical ? 0.72 : 0.7, 6),
                            // Orta Saha (10)
                            _buildSlot(3, "CAM", isVertical ? 0.5 : 0.45,
                                isVertical ? 0.52 : 0.5, 10),
                            // Sol Kanat (7)
                            _buildSlot(4, "LW", isVertical ? 0.15 : 0.7,
                                isVertical ? 0.35 : 0.2, 7),
                            // Sağ Kanat (11)
                            _buildSlot(5, "RW", isVertical ? 0.85 : 0.7,
                                isVertical ? 0.35 : 0.8, 11),
                            // Forvet (9)
                            _buildSlot(6, "ST", isVertical ? 0.5 : 0.85,
                                isVertical ? 0.15 : 0.5, 9),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            // --- SAĞ: OYUNCU HAVUZU ---
            Container(
              width: 350,
              color: const Color(0xFF101014),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: pd.PaleHaxLoc.txt("Oyuncu Ara..."),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.cyanAccent),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                    onChanged: (v) => setState(() => searchQuery = v),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<List<dynamic>>(
                        stream: widget.database.watchAllPlayers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return const Center(
                                child: CircularProgressIndicator());
                          // Basit convert
                          var list = snapshot.data!
                              .map((row) {
                                List<PlayStyle> ps = [];
                                try {
                                  var l =
                                      jsonDecode(row.playStylesJson) as List;
                                  ps = l.map((e) {
                                    String s = e.toString();
                                    return s.endsWith("+")
                                        ? PlayStyle(
                                            s.substring(0, s.length - 1),
                                            isGold: true)
                                        : PlayStyle(s, isGold: false);
                                  }).toList();
                                } catch (_) {}
                                return Player(
                                    name: row.name,
                                    rating: row.rating,
                                    position: row.position,
                                    playstyles: ps,
                                    cardType: row.cardType,
                                    team: row.team,
                                    stats: {},
                                    role: row.role ?? "Yok",
                                    style: "Temel",
                                    styleTier: 0);
                              })
                              .where((p) => p.name
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()))
                              .toList();

                          return GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.7,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10),
                            itemCount: list.length,
                            itemBuilder: (c, i) {
                              return Draggable<Player>(
                                data: list[i],
                                feedback: Material(
                                    color: Colors.transparent,
                                    child: SizedBox(
                                        width: 120,
                                        child:
                                            FCAnimatedCard(player: list[i]))),
                                child: FCAnimatedCard(
                                    player: list[i], animateOnHover: false),
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
      ),
    );
  }

  Widget _buildSlot(
      int index, String label, double xAlign, double yAlign, int kitNumber) {
    // Align: 0.0 -> 1.0 arası. Stack içinde Positioned kullanacağız ama Alignment daha kolay.
    // Container boyutları (Saha): W:600/900, H:800/600
    // Kart Boyutu: W:130, H:180 (Büyük istendi)

    return Align(
      alignment: Alignment((xAlign * 2) - 1, (yAlign * 2) - 1),
      child: DragTarget<Player>(
        onAccept: (p) => setState(() => squad[index] = p),
        builder: (c, cand, rej) {
          Player? p = squad[index];
          return Container(
            width: 230, // KART ALANI DAHA DA BÜYÜTÜLDÜ
            height: 320, // NUMARA İÇİN YER AÇILDI
            decoration: BoxDecoration(
                // DÜZELTME: Kartlar daha belirgin olsun diye arka plan ve gölge
                color: p == null
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                boxShadow: p != null
                    ? [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ]
                    : [],
                border: p == null
                    ? Border.all(color: Colors.white12, width: 2)
                    : Border.all(color: Colors.white24, width: 1)),
            child: p != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // FORMA NUMARASI
                      Text("$kitNumber",
                          style: GoogleFonts.russoOne(
                              fontSize: 32,
                              color: Colors.white,
                              shadows: [
                                const Shadow(
                                    color: Colors.black, blurRadius: 10)
                              ])),
                      const SizedBox(height: 5),
                      // KART
                      Expanded(
                        child: GestureDetector(
                            onTap: () => setState(
                                () => squad[index] = null), // Tıklayınca sil
                            child: FCAnimatedCard(
                                player: p, animateOnHover: true)),
                      ),
                    ],
                  )
                : Center(
                    child: Text(label,
                        style: GoogleFonts.russoOne(
                            color: Colors.white24, fontSize: 20))),
          );
        },
      ),
    );
  }

  void _capture() async {
    final image =
        await _screenshotController.capture(pixelRatio: 3.0); // Yüksek Kalite
    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(pd.PaleHaxLoc.txt("Görüntü kaydedildi!")),
          backgroundColor: Colors.green));
      // Burada dosya kaydetme işlemi yapılabilir (path_provider ile)
    }
  }
}

class _PitchLinesPainter extends CustomPainter {
  final bool isVertical;
  _PitchLinesPainter({required this.isVertical});
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    // Orta Çizgi
    if (isVertical)
      canvas.drawLine(
          Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
    else
      canvas.drawLine(
          Offset(size.width / 2, 0), Offset(size.width / 2, size.height), p);
    // Orta Yuvarlak
    double radius = size.shortestSide * 0.15; // Dinamik yarıçap
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), radius, p);
    // Ceza Sahaları (Basit)
    if (isVertical) {
      canvas.drawRect(
          Rect.fromLTWH(
              size.width * 0.2, 0, size.width * 0.6, size.height * 0.15),
          p);
      canvas.drawRect(
          Rect.fromLTWH(size.width * 0.2, size.height * 0.85, size.width * 0.6,
              size.height * 0.15),
          p);
    } else {
      canvas.drawRect(
          Rect.fromLTWH(
              0, size.height * 0.2, size.width * 0.15, size.height * 0.6),
          p);
      canvas.drawRect(
          Rect.fromLTWH(size.width * 0.85, size.height * 0.2, size.width * 0.15,
              size.height * 0.6),
          p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

void _showEditor(
    BuildContext context, Player? p, Function(Player, Player?) onSave) {
  showDialog(
      context: context,
      builder: (context) => CreatePlayerDialog(
          playerToEdit: p,
          onSave: (player) {
            if (player != null) onSave(player, p);
          }));
}

// ============================================================================
// BÖLÜM 5: CREATE PLAYER DIALOG (EKSİK OLAN PARÇA BURAYA EKLENDİ)
// ============================================================================

class CreatePlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  final Function(Player?) onSave;
  final bool isNewVersion;

  const CreatePlayerDialog(
      {super.key,
      this.playerToEdit,
      required this.onSave,
      this.isNewVersion = false});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _teamController;
  late TextEditingController _ratingController;
  late TextEditingController _marketValueController;

  String selectedPosition = "(9) ST";
  String selectedCardType = "Temel";
  String selectedRole = "Avcı Forvet";
  int selectedSkillMoves = 3;
  int selectedWeakFoot = 3;
  String selectedChemistryStyle = "Basic";
  String selectedStyle = "Temel";
  int selectedStyleTier = 0; // 0, 1, 2
  List<PlayStyle> selectedPlayStyles = [];
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    Player p = widget.playerToEdit ??
        Player(
            name: "",
            rating: 75,
            position: "(9) ST",
            playstyles: [],
            cardType: "Temel",
            team: "Takımsız",
            style: "Temel",
            styleTier: 0);
    _nameController = TextEditingController(text: p.name);
    _teamController = TextEditingController(text: p.team);
    _ratingController = TextEditingController(text: p.rating.toString());
    // Market Value sadece sayı kısmını al
    String mvRaw = p.marketValue.replaceAll("€", "").replaceAll("M", "");
    _marketValueController = TextEditingController(text: mvRaw);

    selectedPosition = p.position;
    selectedCardType = p.cardType;
    selectedRole = p.role;
    selectedSkillMoves = p.skillMoves;
    selectedWeakFoot = p.stats['WF'] ?? 3;
    selectedChemistryStyle = p.chemistryStyle;
    selectedPlayStyles = List.from(p.playstyles);
    stats = Map<String, int>.from(p.stats);
    if (stats.isEmpty) {
      pd.statSegments.values.expand((e) => e).forEach((s) => stats[s] = 50);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teamController.dispose();
    _ratingController.dispose();
    _marketValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E24),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        // DÜZELTME: Sabit boyut yerine ekran oranlı boyut (Pixel hatasını önler)
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Text(
                widget.playerToEdit == null
                    ? pd.PaleHaxLoc.txt("YENİ OYUNCU OLUŞTUR")
                    : pd.PaleHaxLoc.txt("OYUNCUYU DÜZENLE"),
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24, height: 30),
            Expanded(
              child: Row(
                children: [
                  // SOL TARA - Temel Bilgiler
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _input(
                              pd.PaleHaxLoc.txt("Ad Soyad"), _nameController),
                          // TAKIM SEÇİMİ (DROPDOWN)
                          _dropdown(
                              pd.PaleHaxLoc.txt("Takım"),
                              pd.teamLogos.keys.toList(),
                              _teamController.text, (v) {
                            setState(() => _teamController.text = v!);
                          }),

                          _input(
                              pd.PaleHaxLoc.txt("Reyting"), _ratingController,
                              isNum: true),
                          _dropdown(pd.PaleHaxLoc.txt("Pozisyon"), pd.positions,
                              selectedPosition, (v) {
                            setState(() => selectedPosition = v!);
                            _checkGKStats(); // Pozisyon değişince statları güncelle
                            selectedStyle = "Temel"; // Stili sıfırla
                            // Pozisyona göre varsayılan rolü seç
                            // Burada basit bir mantık kurabilirsin
                          }),
                          _dropdown(pd.PaleHaxLoc.txt("Kart Tipi"),
                              pd.globalCardTypes, selectedCardType, (v) {
                            setState(() => selectedCardType = v!);
                          }),
                          _dropdown(
                              pd.PaleHaxLoc.txt("Rol"),
                              roleDescriptions.keys.toList(),
                              selectedRole, (v) {
                            setState(() => selectedRole = v!);
                          }),
                          _dropdown(pd.PaleHaxLoc.txt("Kimya Stili"),
                              chemistryStylesList, selectedChemistryStyle, (v) {
                            setState(() => selectedChemistryStyle = v!);
                          }),
                          _input(pd.PaleHaxLoc.txt("Piyasa Değeri (M€)"),
                              _marketValueController,
                              isNum: true),

                          // YENİ: STİL SEÇİMİ
                          const SizedBox(height: 10),
                          Text(pd.PaleHaxLoc.txt("Oyun Stili"),
                              style: TextStyle(color: Colors.cyanAccent)),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _getAvailableStyles()
                                          .contains(selectedStyle)
                                      ? selectedStyle
                                      : _getAvailableStyles().first,
                                  items: _getAvailableStyles()
                                      .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e,
                                              style: const TextStyle(
                                                  color: Colors.white))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => selectedStyle = v!),
                                  dropdownColor: const Color(0xFF2C2C35),
                                  decoration: InputDecoration(
                                      filled: true, fillColor: Colors.black26),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // TIER SEÇİMİ (+ / ++)
                              ToggleButtons(
                                isSelected: [
                                  selectedStyleTier == 0,
                                  selectedStyleTier == 1,
                                  selectedStyleTier == 2
                                ],
                                onPressed: (idx) =>
                                    setState(() => selectedStyleTier = idx),
                                color: Colors.white54,
                                selectedColor: Colors.cyanAccent,
                                fillColor: Colors.cyanAccent.withOpacity(0.2),
                                children: const [
                                  Text("-"),
                                  Text("+"),
                                  Text("++")
                                ],
                              )
                            ],
                          ),

                          // YETENEK VE ZAYIF AYAK
                          const SizedBox(height: 10),
                          Text(pd.PaleHaxLoc.txt("Yetenek & Zayıf Ayak"),
                              style: TextStyle(color: Colors.amber)),
                          Row(
                            children: [
                              Expanded(
                                  child: Column(
                                children: [
                                  Text("SM: $selectedSkillMoves ⭐",
                                      style: TextStyle(color: Colors.white)),
                                  Slider(
                                      value: selectedSkillMoves.toDouble(),
                                      min: 1,
                                      max: 5,
                                      divisions: 4,
                                      activeColor: Colors.yellow,
                                      onChanged: (v) => setState(
                                          () => selectedSkillMoves = v.toInt()))
                                ],
                              )),
                              Expanded(
                                  child: Column(
                                children: [
                                  Text("WF: $selectedWeakFoot ⭐",
                                      style: TextStyle(color: Colors.white)),
                                  Slider(
                                      value: selectedWeakFoot.toDouble(),
                                      min: 1,
                                      max: 5,
                                      divisions: 4,
                                      activeColor: Colors.redAccent,
                                      onChanged: (v) => setState(
                                          () => selectedWeakFoot = v.toInt()))
                                ],
                              ))
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 40, color: Colors.white10),
                  // SAĞ TARAF - İstatistikler ve PlayStyle
                  Expanded(
                    flex: 2,
                    child: DefaultTabController(
                      length: 3, // Sekme sayısı 3 oldu
                      child: Column(
                        children: [
                          TabBar(
                            indicatorColor: Colors.cyanAccent,
                            tabs: [
                              Tab(text: pd.PaleHaxLoc.txt("İSTATİSTİKLER")),
                              Tab(text: pd.PaleHaxLoc.txt("NORMAL PS")),
                              Tab(text: pd.PaleHaxLoc.txt("PLUS PS")),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // TAB 1: İSTATİSTİKLER
                                SingleChildScrollView(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: _getStatList().map((entry) {
                                      return Container(
                                        width: 250,
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(entry.key,
                                                style: const TextStyle(
                                                    color: Colors.amber,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 10),
                                            ...entry.value.map((s) => Row(
                                                  children: [
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text(s,
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        12))),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Slider(
                                                        value: (stats[s] ?? 50)
                                                            .toDouble(),
                                                        min: 0,
                                                        max: 99,
                                                        activeColor:
                                                            Colors.cyanAccent,
                                                        inactiveColor:
                                                            Colors.white10,
                                                        onChanged: (v) =>
                                                            setState(() =>
                                                                stats[s] =
                                                                    v.toInt()),
                                                      ),
                                                    ),
                                                    Text("${stats[s] ?? 50}",
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))
                                                  ],
                                                ))
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                // TAB 2: NORMAL PLAYSTYLES
                                _buildPlayStyleSelector(isPlusMode: false),

                                // TAB 3: PLUS PLAYSTYLES
                                _buildPlayStyleSelector(isPlusMode: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(pd.PaleHaxLoc.txt("İPTAL"),
                        style: TextStyle(color: Colors.white54))),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save, color: Colors.black),
                    label: Text(pd.PaleHaxLoc.txt("KAYDET"),
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
      ),
    );
  }

  // Pozisyona göre stil listesi
  List<String> _getAvailableStyles() {
    if (selectedPosition.contains("GK"))
      return ["Temel Kaleci", ...pd.styleOptions["GK"]!];
    if (selectedPosition.contains("CB"))
      return ["Temel Defans", ...pd.styleOptions["DEF"]!];
    if (selectedPosition.contains("CDM"))
      return ["Temel Defans", ...pd.styleOptions["DEF"]!]; // CDM de defansif
    if (selectedPosition.contains("CAM"))
      return ["Temel Orta Saha", ...pd.styleOptions["MID"]!];
    if (selectedPosition.contains("RW") || selectedPosition.contains("LW"))
      return ["Temel Kanat", ...pd.styleOptions["WING"]!];
    if (selectedPosition.contains("ST"))
      return ["Temel Forvet", ...pd.styleOptions["FWD"]!];
    return ["Temel"];
  }

  // GK ise statları değiştir
  void _checkGKStats() {
    if (selectedPosition.contains("GK")) {
      // GK Statlarını ekle
      for (var s in pd.gkStatsList) {
        if (!stats.containsKey(s)) stats[s] = 50;
      }
    }
  }

  // Gösterilecek stat listesi
  List<MapEntry<String, List<String>>> _getStatList() {
    if (selectedPosition.contains("GK")) {
      return [
        MapEntry("KALECİLİK", pd.gkStatsList),
      ];
    }
    return pd.statSegments.entries.toList();
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;

    // Zayıf ayağı stats içine gömüyoruz
    stats['WF'] = selectedWeakFoot;

    Player newP = Player(
        name: _nameController.text,
        rating: int.tryParse(_ratingController.text) ?? 75,
        position: selectedPosition,
        team: _teamController.text,
        cardType: selectedCardType,
        skillMoves: selectedSkillMoves,
        chemistryStyle: selectedChemistryStyle,
        marketValue: "€${_marketValueController.text}M", // Otomatik format
        playstyles: selectedPlayStyles,
        style: selectedStyle,
        styleTier: selectedStyleTier,
        stats: stats,
        role: selectedRole,
        recLink: widget.playerToEdit?.recLink ??
            "", // Eski veriyi koru (Maç geçmişi burada)
        manualGoals: widget.playerToEdit?.manualGoals ?? 0,
        manualAssists: widget.playerToEdit?.manualAssists ?? 0);

    widget.onSave(newP);
    Navigator.pop(context);
  }

  Widget _buildPlayStyleSelector({required bool isPlusMode}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: playStyleCategories.values.expand((e) => e).map((psData) {
          // Bu stil seçili mi?
          bool isSelected =
              selectedPlayStyles.any((p) => p.name == psData['name']);
          bool isGold = false;

          if (isSelected) {
            isGold = selectedPlayStyles
                .firstWhere((p) => p.name == psData['name'])
                .isGold;
          }

          // Eğer bu sekme Plus moduysa ve seçili olan Gold ise -> Aktif
          // Eğer bu sekme Normal modsa ve seçili olan Gold değilse -> Aktif
          bool isActiveInThisTab = isSelected && (isPlusMode == isGold);

          return GestureDetector(
            onTap: () {
              setState(() {
                // Önce var olanı kaldır (Toggle veya Değişim için)
                selectedPlayStyles.removeWhere((p) => p.name == psData['name']);

                // Eğer zaten bu modda seçiliyse kaldırdık, işlem bitti (Toggle Off)
                if (isActiveInThisTab) {
                  return;
                }

                // Değilse yeni halini ekle
                selectedPlayStyles
                    .add(PlayStyle(psData['name']!, isGold: isPlusMode));
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActiveInThisTab
                    ? (isPlusMode
                        ? Colors.amber.withOpacity(0.2)
                        : Colors.cyanAccent.withOpacity(0.2))
                    : Colors.white10,
                border: Border.all(
                    color: isActiveInThisTab
                        ? (isPlusMode ? Colors.amber : Colors.cyanAccent)
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActiveInThisTab)
                    Icon(isPlusMode ? Icons.star : Icons.check,
                        size: 14,
                        color: isPlusMode ? Colors.amber : Colors.cyanAccent),
                  const SizedBox(width: 5),
                  Text(psData['label']!,
                      style: TextStyle(
                          color:
                              isActiveInThisTab ? Colors.white : Colors.white54,
                          fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _input(String label, TextEditingController c, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String val,
      Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: items.contains(val) ? val : items.first,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white))))
            .toList(),
        onChanged: onChange,
        dropdownColor: const Color(0xFF2C2C35),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
