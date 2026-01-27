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
import 'pale_webview.dart';

// ==============================================================================
// ANA GÖRÜNÜM (5 TABLI YAPI)
// ==============================================================================
class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    return DefaultTabController(
      length: 5,
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
              Tab(text: "TAKIMLAR"),
              Tab(text: "OYUN STİLLERİ (WIKI)"),
              Tab(text: "KART TİPLERİ"),
              Tab(text: "ROLLER")
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _SubTabPlayers(database: database),
            const SubTabTeams(),
            const SubTabPlayStyles(),
            const SubTabCardTypes(),
            const SubTabRoles()
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// 1. SEKME: OYUNCU YÖNETİMİ
// ==============================================================================
class _SubTabPlayers extends StatefulWidget {
  final AppDatabase database;
  const _SubTabPlayers({required this.database});
  @override
  State<_SubTabPlayers> createState() => _SubTabPlayersState();
}

class _SubTabPlayersState extends State<_SubTabPlayers>
    with SingleTickerProviderStateMixin {
  Player? selectedPlayer;
  int currentCardIndex = 0;
  late TabController _innerTabController;
  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

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
          if (selectedPlayer == null ||
              !all.any((p) => p.name == selectedPlayer!.name))
            selectedPlayer = all.first;
          else
            selectedPlayer =
                all.firstWhere((p) => p.name == selectedPlayer!.name);
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
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showEditor(context, null, (p) => _save(p)),
                              icon: const Icon(Icons.person_add,
                                  color: Colors.black, size: 20),
                              label: const Text("YENİ OYUNCU",
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent)))),
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
                                    overflow: TextOverflow.ellipsis));
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
              Container(
                  color: Colors.black26,
                  child: TabBar(
                      controller: _innerTabController,
                      indicatorColor: Colors.cyanAccent,
                      labelColor: Colors.cyanAccent,
                      unselectedLabelColor: Colors.white54,
                      tabs: const [
                        Tab(text: "PROFİL"),
                        Tab(text: "ULTIMATE ANALİZ")
                      ])),
              Expanded(
                  child: TabBarView(controller: _innerTabController, children: [
                _ViewProfile(
                    player: displayPlayer,
                    versions: versions,
                    onSelect: (p) => setState(() {
                          selectedPlayer = p;
                          currentCardIndex = versions.indexOf(p);
                        })),
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
    setState(() {});
  }
}

// ==============================================================================
// 2. SEKME: TAKIMLAR (APP / WEB TOGGLE) - DÜZELTİLDİ
// ==============================================================================
class SubTabTeams extends StatefulWidget {
  const SubTabTeams({super.key});
  @override
  State<SubTabTeams> createState() => _SubTabTeamsState();
}

class _SubTabTeamsState extends State<SubTabTeams> {
  bool isWebMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 15),
      Center(
          child: Container(
              decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _toggleBtn("UYGULAMA", !isWebMode,
                    () => setState(() => isWebMode = false)),
                _toggleBtn("WEB SİTESİ", isWebMode,
                    () => setState(() => isWebMode = true)),
              ]))),
      const SizedBox(height: 15),
      Expanded(
          child: isWebMode
              ? const PaleWebView(url: "https://palehaxball.com/takimlar")
              : _buildTeamGrid())
    ]);
  }

  Widget _toggleBtn(String txt, bool active, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            decoration: BoxDecoration(
                color: active ? Colors.cyanAccent : Colors.transparent,
                borderRadius: BorderRadius.circular(20)),
            child: Text(txt,
                style: TextStyle(
                    color: active ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold))));
  }

  Widget _buildTeamGrid() {
    List<String> teamsToShow =
        availableTeams.where((t) => t != "Takımsız").toList();
    return Center(
      child: GridView.builder(
          padding: const EdgeInsets.all(40),
          // KUTUCUKLARI KÜÇÜLTMEK İÇİN crossAxisCount ARTTIRILDI (5)
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.1,
              crossAxisSpacing: 30,
              mainAxisSpacing: 30),
          shrinkWrap: true, // Merkeze toplamak için
          itemCount: teamsToShow.length,
          itemBuilder: (c, i) {
            String tName = teamsToShow[i];
            String? logo = teamLogos[tName];
            return GestureDetector(
              onTap: () => _showTeamRoster(tName, logo),
              child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 2)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (logo != null && logo.isNotEmpty)
                          Image.asset(logo,
                              width: 60,
                              height: 60,
                              errorBuilder: (c, e, s) => const Icon(
                                  Icons.shield,
                                  color: Colors.white54,
                                  size: 50))
                        else
                          const Icon(Icons.shield,
                              color: Colors.white54, size: 50),
                        const SizedBox(height: 10),
                        Text(tName,
                            style: GoogleFonts.orbitron(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)
                      ])),
            );
          }),
    );
  }

  void _showTeamRoster(String team, String? logo) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: const Color(0xFF0D0D12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Container(
                width: 500,
                height: 750,
                padding: const EdgeInsets.all(30),
                child: Column(children: [
                  if (logo != null && logo.isNotEmpty)
                    Image.asset(logo, width: 90, height: 90),
                  const SizedBox(height: 15),
                  Text(team,
                      style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const Divider(
                      color: Colors.white10, height: 40, thickness: 2),
                  Expanded(
                      child: ListView.builder(
                          itemCount: 20,
                          itemBuilder: (c, i) {
                            bool isCaptain = i == 0;
                            return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                    color: isCaptain
                                        ? Colors.amber.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(12),
                                    border: isCaptain
                                        ? Border.all(
                                            color:
                                                Colors.amber.withOpacity(0.3))
                                        : null),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // HATA DÜZELTME: Text width kaldırıldı, SizedBox eklendi
                                      SizedBox(
                                          width: 30,
                                          child: Text("${i + 1}.",
                                              style: TextStyle(
                                                  color: isCaptain
                                                      ? Colors.amber
                                                      : Colors.white54,
                                                  fontWeight:
                                                      FontWeight.bold))),
                                      Icon(Icons.person,
                                          color: isCaptain
                                              ? Colors.amber
                                              : Colors.white70,
                                          size: 22),
                                      const SizedBox(width: 15),
                                      Text("Oyuncu ${i + 1}",
                                          style: TextStyle(
                                              color: isCaptain
                                                  ? Colors.amber
                                                  : Colors.white,
                                              fontSize: 17,
                                              fontWeight: isCaptain
                                                  ? FontWeight.bold
                                                  : FontWeight.normal)),
                                      if (isCaptain) ...[
                                        const SizedBox(width: 10),
                                        const Text("(Captain)",
                                            style: TextStyle(
                                                color: Colors.amber,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic))
                                      ]
                                    ]));
                          })),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            padding: const EdgeInsets.all(15)),
                        child: const Text("KAPAT",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  )
                ]))));
  }
}

// ==============================================================================
// 3. SEKME: OYUN STİLLERİ (WIKI)
// ==============================================================================
class SubTabPlayStyles extends StatelessWidget {
  const SubTabPlayStyles({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            width: double.infinity,
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
                    onPressed: () {},
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
                            width: 140,
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
          ),
          ...playStyleCategories.entries.map((entry) => Column(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                        child: Text(entry.key,
                            style: GoogleFonts.orbitron(
                                color: Colors.greenAccent,
                                fontSize: 26,
                                fontWeight: FontWeight.bold)))),
                Center(
                    child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: entry.value.map((ps) {
                          return Container(
                              width: 300,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white12)),
                              child: Row(children: [
                                Image.asset(
                                    "assets/Playstyles/${ps['name']}.png",
                                    width: 45,
                                    height: 45,
                                    errorBuilder: (c, e, s) => const Icon(
                                        Icons.help,
                                        color: Colors.white54)),
                                const SizedBox(width: 15),
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
                                              fontSize: 17)),
                                      Text(ps['desc']!,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis)
                                    ]))
                              ]));
                        }).toList())),
                const SizedBox(height: 40)
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
            width: 22,
            height: 22,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.circle, size: 10, color: Colors.amber)),
        const SizedBox(width: 5),
        Text(n, style: const TextStyle(color: Colors.white, fontSize: 14))
      ]));
      if (i < l.length - 1)
        w.add(const Icon(Icons.arrow_right_alt,
            color: Colors.purpleAccent, size: 18));
    }
    return w;
  }
}

// ==============================================================================
// 4. SEKME: KART TİPLERİ
// ==============================================================================
class SubTabCardTypes extends StatelessWidget {
  const SubTabCardTypes({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: const EdgeInsets.all(40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.65,
            crossAxisSpacing: 35,
            mainAxisSpacing: 35),
        itemCount: cardTypes.length,
        itemBuilder: (c, i) {
          String t = cardTypes[i];
          Color clr = _getCardTypeColor(t);
          if (t == "TOTW") clr = Colors.amber;
          if (t == "TOTM") clr = const Color(0xFFE91E63);
          if (t == "TOTS") clr = Colors.cyanAccent;
          if (t == "BAD") clr = Colors.pinkAccent;
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
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(15),
                                border:
                                    Border.all(color: clr.withOpacity(0.8))),
                            child: Text(t,
                                style: GoogleFonts.orbitron(
                                    color: clr,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold))),
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
                                        role: "Golcü"),
                                    animateOnHover: true)))
                      ])));
        });
  }

  void _showCardDetail(BuildContext context, String t, Player p) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
                child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
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
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                    color: _getCardTypeColor(t), blurRadius: 20)
                              ])),
                      const SizedBox(height: 10),
                      SizedBox(
                          height: 480,
                          child: Transform.scale(
                              scale: 0.95, child: FCAnimatedCard(player: p))),
                      const SizedBox(height: 15),
                      Text(
                          t == "BALLOND'OR"
                              ? "Sezonun Oyuncusu"
                              : (cardTypeDescriptions[t] ?? ""),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17)),
                      const SizedBox(height: 25),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  padding: const EdgeInsets.all(15)),
                              child: const Text("KAPAT",
                                  style: TextStyle(color: Colors.white))))
                    ])))));
  }
}

// ==============================================================================
// 5. SEKME: ROLLER
// ==============================================================================
class SubTabRoles extends StatelessWidget {
  const SubTabRoles({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(40),
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
                  Icon(ic, color: Colors.amber, size: 32),
                  const SizedBox(width: 15),
                  Text(e.key,
                      style: GoogleFonts.orbitron(
                          color: Colors.amber,
                          fontSize: 28,
                          fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 20),
                ...e.value.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 15.0, left: 15),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r,
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          const SizedBox(height: 5),
                          Text(roleDescriptions[r] ?? "Bilgi yok.",
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 15,
                                  height: 1.4)),
                          const SizedBox(height: 10),
                          const Divider(color: Colors.white10)
                        ]))),
                const SizedBox(height: 40)
              ]);
        }).toList());
  }
}

// ==============================================================================
// YARDIMCILAR (PROFİL / ULTIMATE / GLOBAL)
// ==============================================================================
void _showGlobal(BuildContext c, AppDatabase db, Function(PlayerTable) onS) {
  String srt = "Reyting";
  String flt = "Tümü";
  String srch = "";
  showDialog(
      context: c,
      builder: (c) => StatefulBuilder(
          builder: (c, setS) => Dialog(
              backgroundColor: const Color(0xFF0D0D12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
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
                              decoration: const InputDecoration(
                                  hintText: "Oyuncu ara...",
                                  hintStyle: TextStyle(color: Colors.white30),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.cyanAccent),
                                  border: InputBorder.none),
                              onChanged: (v) => setS(() => srch = v))),
                      const SizedBox(width: 30),
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
                      const SizedBox(width: 30),
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
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(c))
                    ]),
                    const Divider(
                        color: Colors.white10, height: 40, thickness: 2),
                    Expanded(
                        child: StreamBuilder<List<PlayerTable>>(
                            stream: db.watchFilteredPlayers(
                                searchQuery: srch,
                                cardTypeFilter: flt,
                                sortOption: srt),
                            builder: (c, sn) {
                              if (!sn.hasData)
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.cyanAccent));
                              final data = sn.data!;
                              if (data.isEmpty)
                                return const Center(
                                    child: Text("Sonuç bulunamadı.",
                                        style:
                                            TextStyle(color: Colors.white38)));
                              return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                          childAspectRatio: 0.65,
                                          crossAxisSpacing: 20,
                                          mainAxisSpacing: 20),
                                  itemCount: data.length,
                                  itemBuilder: (c, i) {
                                    final t = data[i];
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
                                                    role: t.role),
                                                animateOnHover: true)));
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
    List<PlayStyle> sortedStyles = List.from(player.playstyles);
    sortedStyles.sort((a, b) => (b.isGold ? 1 : 0).compareTo(a.isGold ? 1 : 0));
    return SingleChildScrollView(
        padding: const EdgeInsets.all(35),
        child: Column(children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FCAnimatedCard(player: player, animateOnHover: true),
                const SizedBox(width: 50),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(player.name.toUpperCase(),
                          style: GoogleFonts.orbitron(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("${player.position} | ${player.team}",
                          style: GoogleFonts.montserrat(
                              fontSize: 20, color: Colors.white70)),
                      const SizedBox(height: 35),
                      Text("OYUN STİLLERİ",
                          style: GoogleFonts.orbitron(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const SizedBox(height: 15),
                      Wrap(
                          spacing: 20,
                          runSpacing: 15,
                          children: sortedStyles.map((ps) {
                            Color clr = ps.isGold ? Colors.amber : Colors.white;
                            String path =
                                ps.isGold ? "${ps.name}Plus" : ps.name;
                            return SizedBox(
                                width: 95,
                                child: Column(children: [
                                  Image.asset("assets/Playstyles/$path.png",
                                      width: 45,
                                      height: 45,
                                      errorBuilder: (c, e, s) =>
                                          Icon(Icons.help, color: clr)),
                                  const SizedBox(height: 8),
                                  Text(
                                      playStyleTranslationsReverse[ps.name] ??
                                          ps.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: clr,
                                          fontSize: 12,
                                          fontWeight: ps.isGold
                                              ? FontWeight.bold
                                              : FontWeight.normal))
                                ]));
                          }).toList()),
                      const SizedBox(height: 40),
                      if (versions.length > 1) ...[
                        Text("OYUNCUNUN DİĞER KARTLARI",
                            style: GoogleFonts.orbitron(
                                color: Colors.purpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                        const SizedBox(height: 15),
                        SizedBox(
                            height: 150,
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
                                              const EdgeInsets.only(right: 20),
                                          child: Column(children: [
                                            Transform.scale(
                                                scale: 0.28,
                                                child: FCAnimatedCard(
                                                    player: versions[i],
                                                    animateOnHover: true)),
                                            Text(versions[i].cardType,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11))
                                          ])));
                                }))
                      ]
                    ]))
              ]),
          const SizedBox(height: 40),
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
    var st = player.getSimulationStats();
    return Row(children: [
      Expanded(
          flex: 4,
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                SizedBox(
                    height: 520,
                    child: Stack(alignment: Alignment.center, children: [
                      if (versions.length > 1)
                        AnimatedPositioned(
                            duration: const Duration(milliseconds: 500),
                            right: -140,
                            top: 0,
                            child: GestureDetector(
                                onTap: () =>
                                    onIndex((index + 1) % versions.length),
                                child: Opacity(
                                    opacity: 0.7,
                                    child: Transform.scale(
                                        scale: 0.85,
                                        child: FCAnimatedCard(
                                            player: versions[
                                                (index + 1) % versions.length],
                                            animateOnHover: true))))),
                      FCAnimatedCard(player: player),
                      Positioned(
                          top: 0,
                          right: 0,
                          child: _buildCardMenu(context, player, onSave)),
                    ])),
                const SizedBox(height: 25),
                ElevatedButton(
                    onPressed: () => _createVersion(context, player, onSave),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15)),
                    child: const Text("+ YENİ KART VERSİYONU EKLE",
                        style: TextStyle(color: Colors.white)))
              ]))),
      Expanded(
          flex: 5,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(children: [
                Wrap(spacing: 15, runSpacing: 15, children: [
                  _statBox("GOL", st['Gol']!, Colors.green),
                  _statBox("ASİST", st['Asist']!, Colors.blue),
                  _statBox("PAS", st['Pas']!, Colors.white),
                  _statBox("İSABET", st['İsabetli Pas']!, Colors.cyan),
                  _statBox("KİLİT", st['Kilit Pas']!, Colors.amber),
                  _statBox("ŞUT", st['Şut']!, Colors.red),
                  _statBox("TOPLA OYNAMA", st['Topla Oynama']!, Colors.purple)
                ]),
                const SizedBox(height: 30),
                if (player.recLink.isNotEmpty)
                  Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 25),
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15))))),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      width: 180,
                      height: 250,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24, width: 2),
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withOpacity(0.03)),
                      child: CustomPaint(
                          painter: _MiniPitchPainter(
                              playerPos: player.getPitchPosition()),
                          child: Stack(children: [
                            Positioned(
                                left: player.getPitchPosition().dx * 180 - 10,
                                top: player.getPitchPosition().dy * 250 - 10,
                                child: Column(children: [
                                  const Icon(Icons.circle,
                                      color: Colors.redAccent, size: 16),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Text(
                                          player.position.replaceAll(
                                              RegExp(r'[^A-Z]'), ''),
                                          style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)))
                                ]))
                          ]))),
                  const SizedBox(width: 30),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text("SEZON GEÇMİŞİ",
                            style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Table(
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            children: [
                              const TableRow(children: [
                                Text("SEZON",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                                Text("RTG",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                                Text("G/A",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 11)),
                                SizedBox()
                              ]),
                              ...player.seasons.map((s) => TableRow(children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(s.season,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13))),
                                    Text("${s.avgRating}",
                                        style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                    Text("${s.goals} / ${s.assists}",
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13)),
                                    s.isMVP
                                        ? const Icon(Icons.star,
                                            color: Colors.amber, size: 16)
                                        : const SizedBox()
                                  ]))
                            ])
                      ]))
                ]),
                const SizedBox(height: 30),
                Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.white10),
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.02)),
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
  Widget _infoBadge(String label, String val, {Color color = Colors.white}) =>
      Column(children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(val,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16))
      ]);
}

void _showGlobalCards(
    BuildContext context, AppDatabase db, Function(PlayerTable) onSelect) {
  _showGlobal(context, db, onSelect);
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
          onSave: (player) {
            if (player != null) onSave(player);
          }));
}

class _MiniPitchPainter extends CustomPainter {
  final Offset playerPos;
  _MiniPitchPainter({required this.playerPos});
  @override
  void paint(Canvas c, Size s) {
    Paint linePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), linePaint);
    c.drawLine(
        Offset(0, s.height / 2), Offset(s.width, s.height / 2), linePaint);
    c.drawCircle(Offset(s.width / 2, s.height / 2), 15, linePaint);
    c.drawRect(Rect.fromLTWH(s.width * 0.25, 0, s.width * 0.5, s.height * 0.15),
        linePaint);
    c.drawRect(
        Rect.fromLTWH(
            s.width * 0.25, s.height * 0.85, s.width * 0.5, s.height * 0.15),
        linePaint);
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
