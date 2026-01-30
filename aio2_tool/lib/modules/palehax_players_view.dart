import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';

import '../data/player_data.dart';
import '../services/database_service.dart';
import '../services/scraper_service.dart';
import '../ui/fc_animated_card.dart';
import '../modules/player_editor.dart';
import 'pale_webview.dart';

// --- MANUEL VERİ SETİ ---
final Map<String, String> teamMarketValues = {
  "Toulouse": "€96.86M",
  "Livorno": "€85.67M",
  "Werder Weremem": "€75.56M",
  "Maximilian": "€69.31M",
  "Invicta": "€63.89M",
  "Bursa Spor": "€61.82M",
  "Fenerbahçe": "€58.17M",
  "CA RIVER PLATE": "€55.70M",
  "Shamrock Rovers": "€46.48M",
  "Chelsea": "€30.81M",
  "It Spor": "€27.44M",
  "Tiyatro FC": "€24.59M",
  "Juventus": "€14.53M",
};

final Map<String, List<String>> manualTeamRosters = {
  "Bursa Spor": [
    "jesse00481⭐",
    "rodiiiwas⭐",
    "Syniox⭐",
    "xronle⭐",
    "butterfly.54",
    "dehsetzenc1",
    "efeesnmz",
    "ELSALVADOR97",
    "emirito34",
    "gok61",
    "MOVE",
    "Seishiro_Nagi",
    "symphnyn9p125dmnr",
    "Toeria",
    "wad",
    "zeeeyhyr_52"
  ],
  "CA RIVER PLATE": [
    "1wraithh⭐",
    "bigerdem⭐",
    "tykhe_theking⭐",
    ".1.ego",
    ".pulchra",
    "0ederson.",
    "ardaeryy",
    "eyvahnecdet",
    "fearless6514",
    "jaa_s",
    "jex.8",
    "Kangal",
    "lucibaba",
    "nes",
    "pies8",
    "sal.v1",
    "unfeat",
    "xclusive8888",
    "yuemt"
  ],
  "Chelsea": [
    "newstar.7kral⭐",
    "thetiran.⭐",
    "aide6589",
    "baropasha",
    "berkay.sr4",
    "brt_1",
    "eijist",
    "ekpe.udoh",
    "enessext",
    "lewissqw",
    "Marco",
    "pittson.",
    "sami00955",
    "shadeofsun",
    "shaps06",
    "shwmkr7"
  ],
  "Fenerbahçe": [
    "embiid21.⭐",
    "helauren⭐",
    "jaderduran99⭐",
    "kazein33⭐",
    "was2444⭐",
    "akamegakilll",
    "alprn41",
    "aurelioo7",
    "bachiralimye",
    "ennerxd_57557",
    "furkqn1",
    "krei10",
    "loves_gonna_get_you_kill",
    "rickyg7ornot",
    "vyxlora0x0",
    "wakamela",
    "ziya18"
  ],
  "Invicta": [
    "exploding_kittens⭐",
    "fluseps.⭐",
    "GABO⭐",
    "MAYMUN⭐",
    "8",
    "astorz.",
    "bombocan31",
    "boxlux_56235",
    "gusbecalm",
    "rivxs1ete",
    "secretexistence",
    "subasiccxdd",
    "vetzs",
    "w1rtzy"
  ],
  "It Spor": [
    "ANALHINOOOOOO⭐",
    "DELİ99⭐",
    "Josh⭐",
    "arap",
    "ardi0",
    "babayim0220",
    "Camikundaklayan31",
    "dorselitir",
    "elnenyy",
    "haciyatmaz936",
    "hizmetten",
    "hz._musa",
    "L_E_N_Q_U_E_V_O",
    "mambabaaaaaassssss",
    "mm_09.m",
    "muzteaq",
    "oburizmaspor",
    "scumbagdevourer",
    "waless42",
    "xelpahumut",
    "xxSamsunsporxx"
  ],
  "Juventus": [
    "canberkripsaw⭐",
    "noxel0⭐",
    "raulelchavo⭐",
    "boviix",
    "dall9",
    "erenka0920",
    "furkaniswood",
    "ghopzy",
    "gumerla",
    "lucisgod",
    "mertt1907",
    "obaloglu17",
    "poque2706",
    "sephomore",
    "topcu17",
    "villaea7",
    "wos_z"
  ],
  "Livorno": [
    "carpediem⭐",
    "flexible06⭐",
    "szcey⭐",
    "trexistroy⭐",
    ".anill10",
    "adilson28",
    "adolffare",
    "alp95",
    "barn_0",
    "beasy_1",
    "denkoko",
    "frkns61",
    "gracianas",
    "lui7638",
    "qweulas",
    "tokoz7",
    "vilhere",
    "vスペック"
  ],
  "Maximilian": [
    "5hinju⭐",
    "madrichaa⭐",
    "Ölümcül.⭐",
    "alanpasc",
    "arawnnn",
    "berkayy_9",
    "bouddas",
    "cevher7",
    "dogx",
    "dswrd1",
    "emman64_11558",
    "esved",
    "paidoss",
    "saikyoo_.",
    "st1wz",
    "Verone",
    "vmasterking"
  ],
  "Shamrock Rovers": [
    "Can_love_forgive_all?⭐",
    "croqs⭐",
    "Hakan_Ş.⭐",
    "glaby",
    "cubuk0",
    "devilq0u",
    "DREW_MCINTYRE",
    "duygusuz.",
    "exee.16",
    "gökhan_sazdağı",
    "leovaldez.",
    "misu123",
    "nicoloonfire",
    "nightmare5454",
    "Osmancan_Zurnacı",
    "rebic",
    "sacrios6",
    "saintmaxii",
    "signalv2",
    "sorloth33",
    "topcu24",
    "Zhou_Guanyu",
    "zlatk0vic"
  ],
  "Tiyatro FC": [
    "j4unty⭐",
    "messibaba1234⭐",
    "babaoglu_91217",
    "bossemenike",
    "izzet7979",
    "kreissa1",
    "Kylian_Mbappe",
    "lastarda97",
    "lee_07",
    "only.neco",
    "relax9782",
    "sealls.1",
    "secret7486",
    "troulax",
    "way.star",
    "westia",
    "wheloes",
    "xpyken000"
  ],
  "Toulouse": [
    "restes.1⭐",
    "scalettav.⭐",
    "gry2305",
    "juninho008",
    "klejka",
    "lanc10",
    "morutsanzei",
    "péno",
    "phyz3dd",
    "rafaeleao",
    "russellw.",
    "Saver",
    "solares9013CM",
    "soloxwa",
    "spiralstatic9582",
    "Sukemdiren",
    "sungto",
    "tzyx.",
    "vazopressin7DF",
    "Wings",
    "yldry9"
  ],
  "Werder Weremem": [
    "bnpear⭐",
    "mucolajj⭐",
    "orji⭐",
    "aguero.10",
    "ajorque",
    "au_rora7",
    "cacaa58",
    "dontdare.",
    "erling23",
    "ernlsv",
    "heathledgerz",
    "jexal",
    "klostrofobi",
    "mack",
    "mathildaxd",
    "meowmeran0",
    "monq",
    "neganhax",
    "Ronaldo_Иazário_de_Lima.",
    "schurzz8",
    "tsubasaozora_13",
    "xose_55"
  ],
};

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
                ]),
          ),
          body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SubTabPlayers(database: database),
                _SubTabTeams(database: database),
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
                        _showEditor(context, null, (p) => _save(p, true)),
                    child: const Text("İLK OYUNCUYU EKLE")));

          if (selectedPlayer == null ||
              !all.any((p) => p.name == selectedPlayer!.name)) {
            selectedPlayer = all.first;
          } else {
            selectedPlayer =
                all.firstWhere((p) => p.name == selectedPlayer!.name);
          }

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
                              onPressed: () =>
                                  _showGlobal(context, widget.database, (pT) {
                                    setState(() {
                                      selectedPlayer = _convert(pT);
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
                                  ])))),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                              onPressed: () => _showEditor(
                                  context, null, (p) => _save(p, true)),
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
                    onSave: (p) => _save(p, false),
                    onDelete: (p) => _delete(p))
              ]))
            ]))
          ]);
        });
  }

  void _save(Player p, bool isNew) async {
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

  void _delete(Player p) async {
    await widget.database.deletePlayerByNameAndType(p.name, p.cardType);
    setState(() {
      selectedPlayer = null;
    });
  }
}

class _SubTabTeams extends StatefulWidget {
  final AppDatabase database;
  const _SubTabTeams({required this.database});
  @override
  State<_SubTabTeams> createState() => _SubTabTeamsState();
}

class _SubTabTeamsState extends State<_SubTabTeams> {
  bool isWeb = false;
  Widget _btn(String t, bool a, VoidCallback o) => GestureDetector(
      onTap: o,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: BoxDecoration(
              color: a ? Colors.cyanAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  color: a ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold))));
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
                _btn("UYGULAMA", !isWeb, () => setState(() => isWeb = false)),
                _btn("WEB SİTESİ", isWeb, () => setState(() => isWeb = true))
              ]))),
      const SizedBox(height: 15),
      Expanded(
          child: isWeb
              ? const PaleWebView(url: "https://palehaxball.com/takimlar")
              : _buildTeamsBody())
    ]);
  }

  Widget _buildTeamsBody() {
    List<String> list = manualTeamRosters.keys.toList();
    return SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Center(
            child: Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: list.map((name) {
                  String? logo = teamLogos[name];
                  if (name == "CA RIVER PLATE") logo = "assets/logos/river.png";
                  if (name == "It Spor") logo = "assets/logos/itspor.png";
                  String marketValue = teamMarketValues[name] ?? "€0M";
                  return GestureDetector(
                      onTap: () =>
                          _showTeamDialog(context, name, logo, widget.database),
                      child: Container(
                          width: 200,
                          height: 210,
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                              border:
                                  Border.all(color: Colors.white12, width: 2)),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (logo != null && logo.isNotEmpty)
                                  Image.asset(logo,
                                      width: 80,
                                      height: 80,
                                      errorBuilder: (c, e, s) => const Icon(
                                          Icons.shield,
                                          color: Colors.white54,
                                          size: 60))
                                else
                                  const Icon(Icons.shield,
                                      color: Colors.white54, size: 60),
                                const SizedBox(height: 10),
                                Text(name,
                                    style: GoogleFonts.orbitron(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center),
                                Text(marketValue,
                                    style: const TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))
                              ])));
                }).toList())));
  }
}

// --- GLOBAL YARDIMCI METODLAR ---
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
                      Text("KADRO DEĞERİ: $marketValue",
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
                                                    const PopupMenuItem(
                                                        value: 'make_cap',
                                                        child:
                                                            Text("Kaptan Yap")),
                                                    const PopupMenuItem(
                                                        value: 'remove',
                                                        child: Text("Sil",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .redAccent)))
                                                  ])
                                        ]));
                              })),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("KAPAT"))
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
              title: Text("$teamName - Yeni Oyuncu"),
              content: TextField(
                  controller: ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: "Ad Soyad")),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty) {
                        onAdd(ctrl.text.replaceAll(" ", "_"));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Ekle"))
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
        role: match.role);
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              FCAnimatedCard(player: pObj, animateOnHover: true),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("KAPAT"))
            ])));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Bu oyuncunun kartı henüz oluşturulmamış."),
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
                Text("DETAYLI OYUNCU ANALİZİ",
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
                            children: statSegments.entries.map((entry) {
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
                                          int statValue =
                                              p.stats[statName] ?? 50;
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
                                                    Text("$statValue",
                                                        style: TextStyle(
                                                            color: statValue >=
                                                                    80
                                                                ? Colors
                                                                    .greenAccent
                                                                : (statValue >=
                                                                        60
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
                    child: const Text("KAPAT"))
              ]))));
}

// --- PROFILE WIDGETS ---
class _ViewProfile extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final Function(Player) onSelect;
  const _ViewProfile(
      {required this.player, required this.versions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    List<PlayStyle> sortedPs = List.from(player.playstyles)
      ..sort((a, b) => (b.isGold ? 1 : 0).compareTo(a.isGold ? 1 : 0));
    return ListView(padding: const EdgeInsets.all(35), children: [
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
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.name.toUpperCase(),
                                  style: GoogleFonts.orbitron(
                                      fontSize: 36,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              Text("${player.position} | ${player.team}",
                                  style: GoogleFonts.montserrat(
                                      fontSize: 20, color: Colors.white70))
                            ]),
                        Padding(
                            padding: const EdgeInsets.only(right: 120),
                            child: SizedBox(
                                width: 240,
                                height: 60,
                                child: ElevatedButton.icon(
                                    onPressed: () =>
                                        _showDetailedStats(context, player),
                                    icon: const Icon(Icons.analytics,
                                        color: Colors.black, size: 28),
                                    label: const Text("DETAYLI ANALİZ",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyanAccent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15))))))
                      ]),
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
                      children: sortedPs.map((ps) {
                        String translatedName =
                            playStyleTranslationsReverse[ps.name] ?? ps.name;
                        String displayName =
                            ps.isGold ? "$translatedName+" : translatedName;
                        String path = ps.isGold
                            ? "assets/Playstyles/plus/${ps.name}Plus.png"
                            : "assets/Playstyles/${ps.name}.png";
                        return SizedBox(
                            width: 110,
                            child: Column(children: [
                              Image.asset(path,
                                  width: 45,
                                  height: 45,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.help,
                                      color: Colors.white)),
                              const SizedBox(height: 8),
                              Text(displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: ps.isGold
                                          ? Colors.amber
                                          : Colors.white,
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
                        height: 160,
                        child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: versions.length,
                            itemBuilder: (c, i) {
                              if (versions[i] == player)
                                return const SizedBox.shrink();
                              return GestureDetector(
                                  onTap: () => onSelect(versions[i]),
                                  child: Container(
                                      margin: const EdgeInsets.only(right: 20),
                                      child: Column(children: [
                                        SizedBox(
                                            width: 100,
                                            height: 130,
                                            child: FittedBox(
                                                fit: BoxFit.contain,
                                                child: FCAnimatedCard(
                                                    player: versions[i],
                                                    animateOnHover: true))),
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
    ]);
  }
}

// --- WIKI TABS ---
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
                      colors: [Color(0xFF000000), Color(0xFF1A237E)]),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.cyanAccent.withOpacity(0.5))),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("V7 META ANALİZİ",
                          style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const Icon(Icons.info_outline, color: Colors.cyanAccent)
                    ]),
                const SizedBox(height: 25),
                ...metaPlaystyles.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(children: [
                      SizedBox(
                          width: 140,
                          child: Text(m['role'],
                              style: GoogleFonts.russoOne(
                                  color: Colors.cyanAccent, fontSize: 16))),
                      Expanded(
                          child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _buildIcons(m['styles'])))
                    ])))
              ])),
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
                                            MainAxisAlignment.start,
                                        children: [
                                      Text(ps['label']!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
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
    for (var n in l) {
      String fn = "";
      playStyleTranslationsReverse.forEach((k, v) {
        if (v == n.trim()) fn = k;
      });
      if (fn.isEmpty) fn = n.contains("Uzak") ? "FarReach" : n.trim();
      w.add(Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset("assets/Playstyles/$fn.png",
            width: 22,
            height: 22,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.circle, size: 10, color: Colors.amber)),
        const SizedBox(width: 5),
        Text(n.trim(),
            style: const TextStyle(color: Colors.white, fontSize: 14))
      ]));
      if (l.indexOf(n) < l.length - 1)
        w.add(const Icon(Icons.arrow_right_alt,
            color: Colors.purpleAccent, size: 18));
    }
    return w;
  }
}

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
                      team: "Takımsız"),
                  clr),
              child: Column(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: clr.withOpacity(0.8))),
                    child: Text(t,
                        style: GoogleFonts.orbitron(
                            color: clr,
                            fontSize: 13,
                            fontWeight: FontWeight.bold))),
                Expanded(
                    child: Transform.scale(
                        scale: 0.95,
                        child: FCAnimatedCard(
                            player: Player(
                                name: "ÖRNEK",
                                rating: 90,
                                position: "(9) ST",
                                playstyles: [],
                                cardType: t,
                                team: "Takımsız"),
                            animateOnHover: true)))
              ]));
        });
  }

  void _showCardDetail(BuildContext c, String t, Player p, Color clr) {
    showDialog(
        context: c,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
                child: Container(
                    width: 420,
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: clr, width: 2)),
                    child: Column(children: [
                      Text(t,
                          style:
                              GoogleFonts.orbitron(color: clr, fontSize: 32)),
                      const SizedBox(height: 10),
                      SizedBox(
                          height: 480,
                          child: Transform.scale(
                              scale: 0.95, child: FCAnimatedCard(player: p))),
                      const SizedBox(height: 15),
                      Text(cardTypeDescriptions[t] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 17)),
                      const SizedBox(height: 25),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text("KAPAT"))
                    ])))));
  }
}

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
                          color: Colors.amber, fontSize: 28))
                ]),
                const SizedBox(height: 20),
                ...e.value.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 15, left: 15),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r,
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(roleDescriptions[r] ?? "",
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 15)),
                          const Divider(color: Colors.white10)
                        ]))),
                const SizedBox(height: 40)
              ]);
        }).toList());
  }
}

// --- GLOBAL UTILS ---
class _ViewUltimate extends StatelessWidget {
  final Player player;
  final List<Player> versions;
  final int index;
  final Function(int) onIndex;
  final BuildContext context;
  final Function(Player) onSave;
  final Function(Player) onDelete;
  const _ViewUltimate(
      {required this.player,
      required this.versions,
      required this.index,
      required this.onIndex,
      required this.context,
      required this.onSave,
      required this.onDelete});
  @override
  Widget build(BuildContext context) {
    var st = player.getSimulationStats();
    List<Player> otherVersions = versions.where((v) => v != player).toList();
    return Row(children: [
      Expanded(
          flex: 4,
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                SizedBox(
                    height: 520,
                    width: 700,
                    child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          if (otherVersions.isNotEmpty)
                            ...otherVersions.asMap().entries.map((entry) {
                              int i = entry.key;
                              Player ver = entry.value;
                              return Positioned(
                                  left: 100.0 + (i * 95),
                                  top: 20.0 + (i * 15),
                                  child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        onIndex(versions.indexOf(ver));
                                      },
                                      child: Transform.scale(
                                          scale: 0.85 - (i * 0.05),
                                          child: Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                SizedBox(
                                                    width: 320,
                                                    height: 480,
                                                    child: AbsorbPointer(
                                                        child: FCAnimatedCard(
                                                            player: ver,
                                                            animateOnHover:
                                                                true))),
                                                Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                    margin: const EdgeInsets.all(
                                                        10),
                                                    decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.8),
                                                        border: Border.all(
                                                            color: Colors
                                                                .cyanAccent),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                5)),
                                                    child: Text(ver.cardType,
                                                        style: const TextStyle(
                                                            color: Colors
                                                                .cyanAccent,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12)))
                                              ]))));
                            }).toList(),
                          Positioned(
                              left: 0,
                              child: SizedBox(
                                  width: 350,
                                  height: 480,
                                  child: FCAnimatedCard(player: player))),
                          Positioned(
                              top: 0,
                              left: 300,
                              child: _buildCardMenu(
                                  context, player, onSave, onDelete))
                        ])),
                const SizedBox(height: 25),
                ElevatedButton(
                    onPressed: () => _createVersion(context, player, onSave),
                    child: const Text("+ YENİ KART VERSİYONU EKLE"))
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
                  Container(
                      padding: const EdgeInsets.all(12),
                      width: 250,
                      decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          border:
                              Border.all(color: Colors.purple.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(children: [
                        Text(st['Topla Oynama']!,
                            style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        const Text("TOPLA OYNAMA",
                            style:
                                TextStyle(color: Colors.purple, fontSize: 11))
                      ]))
                ]),
                const SizedBox(height: 30),
                if (player.recLink.isNotEmpty)
                  Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 25),
                      child: ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(player.recLink);
                            if (await canLaunchUrl(url)) launchUrl(url);
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
                Row(children: [
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
                        Table(children: [
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
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
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
                                        color: Colors.white70, fontSize: 13)),
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
}

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
          _showEditor(context, p, onSave);
        else if (val == 'delete') {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                    backgroundColor: const Color(0xFF1E1E24),
                    title: const Text("Kartı Sil"),
                    content: Text("${p.name} (${p.cardType}) silinsin mi?"),
                    actions: [
                      TextButton(
                          child: const Text("İptal"),
                          onPressed: () => Navigator.pop(context)),
                      TextButton(
                          child: const Text("Sil",
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
            const PopupMenuItem(value: 'edit', child: Text("Düzenle")),
            const PopupMenuItem(
                value: 'delete',
                child: Text("Sil", style: TextStyle(color: Colors.redAccent)))
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
      manualMatches: p.manualMatches);
  showDialog(
      context: context,
      builder: (c) => CreatePlayerDialog(
          playerToEdit: nV, isNewVersion: true, onSave: (p) => onSave(p)));
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

void _showGlobal(BuildContext c, AppDatabase db, Function(PlayerTable) onS) {
  String s = "Reyting", f = "Tümü", q = "";
  showDialog(
      context: c,
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
                              decoration: const InputDecoration(
                                  hintText: "Ara...",
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.cyanAccent)),
                              onChanged: (v) => setS(() => q = v))),
                      const SizedBox(width: 30),
                      DropdownButton<String>(
                          value: f,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: ["Tümü", ...cardTypes]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setS(() => f = v!)),
                      const SizedBox(width: 30),
                      DropdownButton<String>(
                          value: s,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: ["Reyting", "A-Z", "En Yeni"]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setS(() => s = v!)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(c))
                    ]),
                    const Divider(color: Colors.white10),
                    Expanded(
                        child: StreamBuilder<List<PlayerTable>>(
                            stream: db.watchFilteredPlayers(
                                searchQuery: q,
                                cardTypeFilter: f,
                                sortOption: s),
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
                                                    role: t.role),
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
