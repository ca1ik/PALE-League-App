import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';

import '../data/player_data.dart';
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';
import '../modules/player_editor.dart';

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    // TAM EKRAN DÜZELTMESİ: Sınırlamalar kaldırıldı, direkt DefaultTabController dönüyor
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
                ]),
          ),
          body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SubTabPlayers(database: database),
                const SubTabPlayStyles(),
                const SubTabCardTypes(),
                const SubTabRoles()
              ]),
        ));
  }
}

class _SubTabPlayers extends StatefulWidget {
  final AppDatabase database;
  const _SubTabPlayers({required this.database});
  @override
  State<_SubTabPlayers> createState() => _SubTabPlayersState();
}

class _SubTabPlayersState extends State<_SubTabPlayers> {
  Player? selectedPlayer;
  int currentCardIndex = 0;
  Player _convert(PlayerTable t) {
    Map<String, int> st = {};
    List<PlayStyle> ps = [];
    try {
      st = Map<String, int>.from(jsonDecode(t.statsJson));
    } catch (_) {}
    try {
      var l = jsonDecode(t.playStylesJson) as List;
      ps = l.map((e) => PlayStyle(e.toString())).toList();
    } catch (_) {}
    return Player(
        name: t.name,
        rating: t.rating,
        position: t.position,
        playstyles: ps,
        cardType: t.cardType,
        team: t.team,
        marketValue: t.marketValue,
        stats: st,
        role: t.role,
        recLink: t.recLink ?? "",
        manualGoals: t.manualGoals,
        manualAssists: t.manualAssists,
        manualMatches: t.manualMatches);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PlayerTable>>(
        stream: widget.database.watchAllPlayers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          final all = snapshot.data!.map(_convert).toList();
          if (all.isEmpty)
            return Center(
                child: ElevatedButton(
                    onPressed: () =>
                        _showEditor(context, null, (p) => _save(p)),
                    child: const Text("İLK OYUNCUYU EKLE")));
          selectedPlayer ??= all.first;
          List<Player> versions =
              all.where((p) => p.name == selectedPlayer!.name).toList();
          if (currentCardIndex >= versions.length) currentCardIndex = 0;
          Player displayPlayer = versions[currentCardIndex];
          return Row(children: [
            Container(
                width: 260,
                decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white10))),
                child: Column(children: [
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
                              ]),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15)),
                              onPressed: () => _showGlobal(
                                  context,
                                  widget.database,
                                  (pT) => setState(() {
                                        selectedPlayer = _convert(pT);
                                        currentCardIndex = 0;
                                      })),
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
                  Expanded(
                      child: ListView.builder(
                          itemCount: all.length,
                          itemBuilder: (c, i) {
                            if (i > 0 && all[i - 1].name == all[i].name)
                              return const SizedBox.shrink();
                            final p = all[i];
                            return ListTile(
                                onTap: () => setState(() {
                                      selectedPlayer = p;
                                      currentCardIndex = 0;
                                    }),
                                selected: selectedPlayer?.name == p.name,
                                leading: Text("${p.rating}",
                                    style: GoogleFonts.russoOne(
                                        color: _getRatingColor(p.rating))),
                                title: Text(p.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)));
                          }))
                ])),
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
                          letterSpacing: 5,
                          fontWeight: FontWeight.bold))),
              const TabBar(
                  indicatorColor: Colors.cyanAccent,
                  labelColor: Colors.cyanAccent,
                  unselectedLabelColor: Colors.white54,
                  tabs: [Tab(text: "PROFİL"), Tab(text: "ULTIMATE ANALİZ")]),
              Expanded(
                  child: TabBarView(children: [
                _ViewProfile(
                    player: displayPlayer,
                    versions: versions,
                    onSelect: (p) =>
                        setState(() => currentCardIndex = versions.indexOf(p))),
                _ViewUltimate(
                    player: displayPlayer,
                    versions: versions,
                    index: currentCardIndex,
                    onIndex: (i) => setState(() => currentCardIndex = i),
                    context: context,
                    onSave: (p) => _save(p))
              ]))
            ]))
          ]);
        });
  }

  void _save(Player p) async {
    await widget.database.insertPlayer(PlayerTablesCompanion(
        name: drift.Value(p.name),
        rating: drift.Value(p.rating),
        position: drift.Value(p.position),
        team: drift.Value(p.team),
        cardType: drift.Value(p.cardType),
        role: drift.Value(p.role),
        marketValue: drift.Value(p.marketValue),
        statsJson: drift.Value(jsonEncode(p.stats)),
        playStylesJson:
            drift.Value(jsonEncode(p.playstyles.map((e) => e.name).toList())),
        recLink: drift.Value(p.recLink),
        manualGoals: drift.Value(p.manualGoals),
        manualAssists: drift.Value(p.manualAssists),
        manualMatches: drift.Value(p.manualMatches)));
  }
}

class SubTabPlayStyles extends StatelessWidget {
  const SubTabPlayStyles({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Center(
              child: Container(
            width: 800, // Ortalanmış genişlik
            margin: const EdgeInsets.only(bottom: 40),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF000000), Color(0xFF1A237E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2)
                ]),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text("V7 META ANALİZİ",
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          const Shadow(color: Colors.cyan, blurRadius: 15)
                        ])),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E24),
                              title: const Text("Bilgi",
                                  style: TextStyle(color: Colors.cyanAccent)),
                              content: const Text(
                                  "V7 modu için mevkilerine göre meta analizi önem sırasıyla verilmiştir.")));
                    },
                    icon: const Icon(Icons.info_outline,
                        color: Colors.cyanAccent))
              ]),
              const SizedBox(height: 25),
              ...metaPlaystyles.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 120,
                            child: Text(m['role'],
                                style: GoogleFonts.russoOne(
                                    color: Colors.cyanAccent, fontSize: 16))),
                        Expanded(
                            child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: _buildIcons(m['styles'])))
                      ])))
            ]),
          )),
          ...playStyleCategories.entries.map((entry) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                        child: Text(entry.key,
                            style: GoogleFonts.orbitron(
                                color: Colors.greenAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)))),
                Center(
                    child: Wrap(
                        spacing: 15,
                        runSpacing: 15,
                        alignment: WrapAlignment.center,
                        children: entry.value.map((ps) {
                          // Kutular küçültüldü (Width 320 -> 280), Açıklama fontu büyütüldü
                          return Container(
                              width: 280,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white12)),
                              child: Row(children: [
                                Image.asset(
                                    "assets/Playstyles/${ps['name']}.png",
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.help,
                                        color: Colors.white54)),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(ps['label']!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16)),
                                      Text(ps['desc']!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis)
                                    ]))
                              ]));
                        }).toList())),
                const SizedBox(height: 30)
              ]))
        ]));
  }

  List<Widget> _buildIcons(String s) {
    List<String> l = s.split(" - ");
    List<Widget> w = [];
    for (int i = 0; i < l.length; i++) {
      String n = l[i].trim();
      String fn = "";
      playStyleTranslationsReverse.forEach((k, v) {
        if (v == n) fn = k;
      });
      if (fn.isEmpty) fn = n.contains("Uzak") ? "FarReach" : n;
      w.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset("assets/Playstyles/$fn.png",
            width: 20,
            height: 20,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.circle, size: 10, color: Colors.amber)),
        const SizedBox(width: 5),
        Text(n, style: const TextStyle(color: Colors.white, fontSize: 13))
      ]));
      if (i < l.length - 1)
        w.add(const Icon(Icons.arrow_right_alt,
            color: Colors.purpleAccent, size: 16));
    }
    return w;
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
            childAspectRatio: 0.65,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30),
        itemCount: cardTypes.length,
        itemBuilder: (c, i) {
          String t = cardTypes[i];
          Color clr = _getCardTypeColor(t);
          return GestureDetector(
              onTap: () => _showCardDetail(
                  context,
                  t,
                  Player(
                      name: "ÖRNEK",
                      rating: 90,
                      position: "(9) ST",
                      playstyles: [],
                      cardType: t,
                      chemistryStyle: "Temel",
                      team: "PaleHax",
                      role: "Golcü")),
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(children: [
                    // Kart ismi kartın üzerinde (FCAnimatedCard içinde) olduğu için buradaki external ismi kaldırabilir veya çok yakınlaştırabiliriz.
                    // Kullanıcı "isimle kartvizit boşluk çok azalsın" dediği için burada sadece kartı gösteriyoruz, isim kartın içinde zaten var.
                    Expanded(
                        child: Transform.scale(
                            scale: 1.0,
                            child: FCAnimatedCard(
                                player: Player(
                                    name: "ÖRNEK",
                                    rating: 90,
                                    position: "(9) ST",
                                    playstyles: [],
                                    cardType: t,
                                    chemistryStyle: "Temel",
                                    team: "PaleHax",
                                    role: "Golcü"))))
                  ])));
        });
  }

  void _showCardDetail(BuildContext context, String t, Player p) {
    // Ballon d'Or açıklaması düzeltildi
    String desc = t == "BALLOND'OR"
        ? "Sezonun Oyuncusu"
        : (cardTypeDescriptions[t] ?? "");
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
                child: Container(
                    width: 400,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _getCardTypeColor(t), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: _getCardTypeColor(t).withOpacity(0.3),
                              blurRadius: 30)
                        ]),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(t,
                          style: GoogleFonts.orbitron(
                              color: _getCardTypeColor(t),
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    color: _getCardTypeColor(t), blurRadius: 20)
                              ])),
                      const SizedBox(height: 5),
                      SizedBox(
                          height: 480,
                          child: Transform.scale(
                              scale: 0.9, child: FCAnimatedCard(player: p))),
                      Text(desc,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("KAPAT"))
                    ])))));
  }
}

class SubTabRoles extends StatelessWidget {
  const SubTabRoles({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(30),
        children: roleCategories.entries.map((e) {
          IconData ic = (e.key.contains("GK"))
              ? Icons.sports_handball
              : (e.key.contains("CDM"))
                  ? Icons.shield
                  : (e.key.contains("CAM"))
                      ? Icons.auto_awesome
                      : (e.key.contains("RW"))
                          ? Icons.flash_on
                          : Icons.sports_soccer;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(ic, color: Colors.amber, size: 28),
                  const SizedBox(width: 10),
                  Text(e.key,
                      style: GoogleFonts.orbitron(
                          color: Colors.amber,
                          fontSize: 26,
                          fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 15),
                ...e.value.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0, left: 10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r,
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17)),
                          Text(roleDescriptions[r] ?? "Bilgi yok.",
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 14)),
                          const Divider(color: Colors.white10)
                        ]))),
                const SizedBox(height: 30)
              ]);
        }).toList());
  }
}

void _showGlobal(BuildContext c, AppDatabase db, Function(PlayerTable) onS) {
  String srt = "Reyting";
  String flt = "Tümü";
  String srch = "";
  showDialog(
      context: c,
      builder: (c) => StatefulBuilder(
          builder: (c, setS) => Dialog(
              backgroundColor: const Color(0xFF0D0D12),
              child: Container(
                  width: 1000,
                  height: 800,
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Row(children: [
                      SizedBox(
                          width: 200,
                          child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                  hintText: "Ara...",
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.cyanAccent),
                                  border: InputBorder.none),
                              onChanged: (v) => setS(() => srch = v))),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                          dropdownColor: Colors.grey[900],
                          value: flt,
                          items: ["Tümü", ...cardTypes]
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (v) => setS(() => flt = v!)),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                          dropdownColor: Colors.grey[900],
                          value: srt,
                          items: ["Reyting", "A-Z", "En Yeni"]
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e,
                                      style: const TextStyle(
                                          color: Colors.white))))
                              .toList(),
                          onChanged: (v) => setS(() => srt = v!)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(c))
                    ]),
                    const Divider(color: Colors.white24),
                    Expanded(
                        child: StreamBuilder<List<PlayerTable>>(
                            stream: db.watchFilteredPlayers(
                                searchQuery: srch,
                                cardTypeFilter: flt,
                                sortOption: srt),
                            builder: (c, sn) {
                              if (!sn.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());
                              return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          childAspectRatio: 0.65,
                                          crossAxisSpacing: 15,
                                          mainAxisSpacing: 15),
                                  itemCount: sn.data!.length,
                                  itemBuilder: (c, i) {
                                    final t = sn.data![i];
                                    Map<String, int> st = {};
                                    try {
                                      st = Map<String, int>.from(
                                          jsonDecode(t.statsJson));
                                    } catch (_) {}
                                    return GestureDetector(
                                        onTap: () {
                                          onS(t);
                                          Navigator.pop(c);
                                        },
                                        child: Transform.scale(
                                            scale: 0.9,
                                            child: FCAnimatedCard(
                                                player: Player(
                                                    name: t.name,
                                                    rating: t.rating,
                                                    position: t.position,
                                                    playstyles: [],
                                                    cardType: t.cardType,
                                                    team: t.team,
                                                    stats: st,
                                                    role: t.role))));
                                  });
                            }))
                  ])))));
}

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
          _buildMatch(player)
        ]));
  }

  Widget _buildMatch(Player p) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("SON MAÇLAR",
            style:
                GoogleFonts.orbitron(color: Colors.cyanAccent, fontSize: 16)),
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
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Text("${m.rating}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                ])))
            .toList()
      ]);
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
    var st = player.getSimulationStats();
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
                                child: Opacity(
                                    opacity: 0.8,
                                    child: Transform.scale(
                                        scale: 0.9,
                                        child: FCAnimatedCard(
                                            player: versions[(index + 1) %
                                                versions.length]))))),
                      FCAnimatedCard(player: player),
                      Positioned(
                          top: 0,
                          right: 0,
                          child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              onSelected: (v) {
                                if (v == 'edit')
                                  showDialog(
                                      context: context,
                                      builder: (c) => CreatePlayerDialog(
                                          playerToEdit: player,
                                          onSave: (p) => onSave(p)));
                              },
                              itemBuilder: (c) => [
                                    const PopupMenuItem(
                                        value: 'edit', child: Text("Düzenle"))
                                  ])),
                    ])),
                ElevatedButton(
                    onPressed: () => showDialog(
                        context: context,
                        builder: (c) => CreatePlayerDialog(
                            playerToEdit: player,
                            isNewVersion: true,
                            onSave: (p) => onSave(p))),
                    child: const Text("+ YENİ VERSİYON"))
              ]))),
      Expanded(
          flex: 5,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _stB("GOL", st['Gol']!, Colors.green),
                  _stB("ASİST", st['Asist']!, Colors.blue),
                  _stB("ŞUT", st['Şut']!, Colors.red)
                ]),
                const SizedBox(height: 20),
                CustomPaint(
                    size: const Size(160, 220),
                    painter: _PitP(player.getPitchPosition()))
              ])))
    ]);
  }

  Widget _stB(String l, String v, Color c) => Container(
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

class _PitP extends CustomPainter {
  final Offset p;
  _PitP(this.p);
  @override
  void paint(Canvas c, Size s) {
    Paint pt = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), pt);
    c.drawCircle(Offset(p.dx * s.width, p.dy * s.height), 6,
        Paint()..color = Colors.redAccent);
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

void _showEditor(BuildContext c, Player? p, Function(Player) onS) {
  showDialog(
      context: c,
      builder: (c) => CreatePlayerDialog(playerToEdit: p, onSave: onS));
}
