import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/player_data.dart';
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';
import 'palehax_match_engine.dart';

// =============================================================================
// MODELS
// =============================================================================

class MarketListing {
  final String id;
  final Player player;
  final int price;
  final String sellerName;
  final DateTime listedAt;
  MarketListing({
    required this.id,
    required this.player,
    required this.price,
    required this.sellerName,
    required this.listedAt,
  });
}

class HistoryEntry {
  final String type; // 'match' | 'sold' | 'bought'
  final String description;
  final int tokenChange;
  final DateTime date;
  HistoryEntry({
    required this.type,
    required this.description,
    required this.tokenChange,
    required this.date,
  });
}

class RankEntry {
  final String playerName;
  final int wins;
  final int losses;
  final int draws;
  final int tokens;
  final int rank;
  RankEntry({
    required this.playerName,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.tokens,
    required this.rank,
  });
  int get points => wins * 3 + draws;
}

// =============================================================================
// ULTIMATE TEAM PROVIDER
// =============================================================================

class UltimateTeamProvider extends ChangeNotifier {
  // Club & formation
  List<Player> myClub = [];
  List<Player> startingXI = List.generate(
      7, (_) => Player(name: 'BOŞ', rating: 0, position: '', playstyles: []));

  // Tactics
  TacticStyle tacticStyle = TacticStyle.tikiTaka;
  Map<int, PlayerInstruction> playerInstructions = {};

  // Economy
  int tokens = 100;
  bool isRanked = false;

  // Market
  List<MarketListing> transferMarket = [];
  List<MarketListing> myListings = [];

  // History
  List<HistoryEntry> history = [];

  // Stats for ranked
  int wins = 0, losses = 0, draws = 0;
  String playerName = 'Oyuncu 1';

  // Session
  int secondsActive = 0;
  bool claimedFirstPack = false;
  bool claimed15m = false;
  bool claimed30m = false;
  Timer? _timer;

  // Simulated leaderboard
  List<RankEntry> leaderboard = [];

  UltimateTeamProvider() {
    _loadPrefs();
    _generateMarket();
    _generateLeaderboard();
  }

  // ─── PERSISTENCE ───────────────────────────────────────────────────────────

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    tokens = sp.getInt('ut_tokens') ?? 100;
    wins = sp.getInt('ut_wins') ?? 0;
    losses = sp.getInt('ut_losses') ?? 0;
    draws = sp.getInt('ut_draws') ?? 0;
    playerName = sp.getString('ut_player') ?? 'Oyuncu 1';
    claimed15m = sp.getBool('ut_15m') ?? false;
    claimed30m = sp.getBool('ut_30m') ?? false;
    claimedFirstPack = sp.getBool('ut_first') ?? false;
    notifyListeners();
  }

  Future<void> _savePrefs() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('ut_tokens', tokens);
    await sp.setInt('ut_wins', wins);
    await sp.setInt('ut_losses', losses);
    await sp.setInt('ut_draws', draws);
    await sp.setString('ut_player', playerName);
    await sp.setBool('ut_15m', claimed15m);
    await sp.setBool('ut_30m', claimed30m);
    await sp.setBool('ut_first', claimedFirstPack);
  }

  // ─── ECONOMY ───────────────────────────────────────────────────────────────

  void addTokens(int amount) {
    tokens += amount;
    _savePrefs();
    notifyListeners();
  }

  void spendTokens(int amount) {
    tokens = max(0, tokens - amount);
    _savePrefs();
    notifyListeners();
  }

  void recordMatchResult(bool win, bool draw) {
    if (win)
      wins++;
    else if (draw)
      draws++;
    else
      losses++;
    int reward = _matchReward(win, draw);
    addTokens(reward);
    history.insert(
        0,
        HistoryEntry(
          type: 'match',
          description: win
              ? '🏆 Galibiyet'
              : draw
                  ? '🤝 Beraberlik'
                  : '💔 Mağlubiyet',
          tokenChange: reward,
          date: DateTime.now(),
        ));
    _savePrefs();
    _generateLeaderboard();
    notifyListeners();
  }

  int _matchReward(bool win, bool draw) {
    int base = win
        ? 20
        : draw
            ? 10
            : 5;
    return isRanked ? base * 2 : base;
  }

  // ─── CLUB MANAGEMENT ───────────────────────────────────────────────────────

  void addPlayerToClub(Player p) {
    bool dup = myClub.any((e) => e.name == p.name && e.cardType == p.cardType);
    if (!dup) {
      myClub.add(p);
      notifyListeners();
    }
  }

  void setStarter(int slot, Player p) {
    startingXI[slot] = p;
    notifyListeners();
  }

  void setTactic(TacticStyle t) {
    tacticStyle = t;
    notifyListeners();
  }

  void setInstruction(int slot, PlayerInstruction instr) {
    playerInstructions[slot] = instr;
    notifyListeners();
  }

  void setRanked(bool v) {
    isRanked = v;
    notifyListeners();
  }

  void autoBuild() {
    startingXI = List.generate(
        7, (_) => Player(name: 'BOŞ', rating: 0, position: '', playstyles: []));
    Set<String> used = {};

    Player? find(List<String> posHints, String statKey) {
      Player? best;
      int top = -1;
      for (var p in myClub) {
        if (used.contains(p.name)) continue;
        int sv = p.getFMStats()[statKey] ?? 10;
        int pb = posHints.any((x) => p.position.contains(x)) ? 50 : 0;
        int sc = p.rating + sv + pb;
        if (sc > top) {
          top = sc;
          best = p;
        }
      }
      if (best != null) used.add(best.name);
      return best;
    }

    startingXI[0] = find(['GK'], 'Refleks') ?? startingXI[0];
    startingXI[1] = find(['DEF', 'CB'], 'Defans') ?? startingXI[1];
    startingXI[2] = find(['DEF', 'LB', 'RB'], 'Defans') ?? startingXI[2];
    startingXI[3] = find(['MID', 'CDM'], 'Pas') ?? startingXI[3];
    startingXI[4] = find(['MID', 'CAM'], 'Vizyon') ?? startingXI[4];
    startingXI[5] = find(['ST', 'FWD'], 'Şut') ?? startingXI[5];
    startingXI[6] = find(['RW', 'LW', 'ST'], 'Hız') ?? startingXI[6];
    notifyListeners();
  }

  // ─── MARKET ────────────────────────────────────────────────────────────────

  void _generateMarket() {
    final rng = Random();
    final fakeNames = [
      'Kowalski A.',
      'DiMaggio F.',
      'Chen J.',
      'Markov P.',
      'Okonkwo E.',
      'Ferreira L.',
      'Müller K.',
      'Hassan A.',
      'Park S.',
      'Barbosa M.',
      'Lefebvre T.',
      'Ivanov N.',
      'Popescu C.',
      'Nakamura H.',
    ];
    final cardTypes = [
      'Temel',
      'STAR',
      'TOTW',
      'TOTS',
      'MVP',
      'BALLONDOR',
      'FUTURE STARS'
    ];
    final positions = [
      'GK',
      'CB',
      'LB',
      'RB',
      'CDM',
      'CM',
      'CAM',
      'LW',
      'RW',
      'ST'
    ];
    final sellers = [
      'AlphaFC',
      'NeonClub',
      'PaleHax',
      'ShadowTeam',
      'EliteFC',
      'GoldenBoot',
      'UltraClub',
      'DarkStar'
    ];

    for (int i = 0; i < 18; i++) {
      String pos = positions[rng.nextInt(positions.length)];
      String ct = cardTypes[rng.nextInt(cardTypes.length)];
      int rat = 72 + rng.nextInt(28);
      int price = 20 + rng.nextInt(200);
      String name = fakeNames[rng.nextInt(fakeNames.length)];

      // Avoid repeated names
      int suffix = i;
      String finalName =
          '$name${suffix > 0 ? " ${String.fromCharCode(65 + suffix % 26)}" : ""}';

      var fakeStats = <String, int>{
        'Hız': 8 + rng.nextInt(12),
        'Şut': 8 + rng.nextInt(12),
        'Pas': 8 + rng.nextInt(12),
        'Dripling': 8 + rng.nextInt(12),
        'Defans': 8 + rng.nextInt(12),
        'Refleks': 8 + rng.nextInt(12),
      };

      transferMarket.add(MarketListing(
        id: 'mkt_$i',
        player: Player(
          name: finalName,
          rating: rat,
          position: pos,
          playstyles: [],
          cardType: ct,
          stats: fakeStats,
        ),
        price: price,
        sellerName: sellers[rng.nextInt(sellers.length)],
        listedAt: DateTime.now().subtract(Duration(hours: rng.nextInt(48))),
      ));
    }
  }

  bool buyFromMarket(MarketListing listing) {
    if (tokens < listing.price) return false;
    spendTokens(listing.price);
    addPlayerToClub(listing.player);
    transferMarket.removeWhere((l) => l.id == listing.id);
    history.insert(
        0,
        HistoryEntry(
          type: 'bought',
          description:
              '🛒 Satın alındı: ${listing.player.name} (${listing.price} 🪙)',
          tokenChange: -listing.price,
          date: DateTime.now(),
        ));
    notifyListeners();
    return true;
  }

  void listForSale(Player player, int price) {
    var listing = MarketListing(
      id: 'own_${DateTime.now().millisecondsSinceEpoch}',
      player: player,
      price: price,
      sellerName: playerName,
      listedAt: DateTime.now(),
    );
    myListings.add(listing);
    transferMarket.add(listing);
    notifyListeners();
  }

  void removeOwnListing(String id) {
    myListings.removeWhere((l) => l.id == id);
    transferMarket.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  void simulateSale() {
    // Occasionally simulate that someone bought our listing
    if (myListings.isEmpty) return;
    final rng = Random();
    if (rng.nextInt(100) < 15) {
      var listing = myListings[rng.nextInt(myListings.length)];
      addTokens(listing.price);
      history.insert(
          0,
          HistoryEntry(
            type: 'sold',
            description:
                '✅ Satıldı: ${listing.player.name} (${listing.price} 🪙)',
            tokenChange: listing.price,
            date: DateTime.now(),
          ));
      myListings.removeWhere((l) => l.id == listing.id);
      transferMarket.removeWhere((l) => l.id == listing.id);
      notifyListeners();
    }
  }

  // ─── LEADERBOARD ───────────────────────────────────────────────────────────

  void _generateLeaderboard() {
    final rng = Random();
    final names = [
      'FC Phantom',
      'RedBlaze',
      'AlphaKing',
      'CyberFC',
      'NeonWolves',
      'GoldStar',
      'SilverPeak',
      playerName
    ];

    leaderboard = List.generate(8, (i) {
      int w = (i == 7) ? wins : rng.nextInt(20);
      int l = (i == 7) ? losses : rng.nextInt(15);
      int d = (i == 7) ? draws : rng.nextInt(8);
      int t = (i == 7) ? tokens : 100 + rng.nextInt(400);
      return RankEntry(
          playerName: names[i],
          wins: w,
          losses: l,
          draws: d,
          tokens: t,
          rank: 0);
    });

    leaderboard.sort((a, b) => b.points.compareTo(a.points));
    for (int i = 0; i < leaderboard.length; i++) {
      leaderboard[i] = RankEntry(
        playerName: leaderboard[i].playerName,
        wins: leaderboard[i].wins,
        losses: leaderboard[i].losses,
        draws: leaderboard[i].draws,
        tokens: leaderboard[i].tokens,
        rank: i + 1,
      );
    }
    notifyListeners();
  }

  // ─── TIMER ─────────────────────────────────────────────────────────────────

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsActive++;
      if (secondsActive % 30 == 0) simulateSale();
      notifyListeners();
    });
  }

  void stopTimer() => _timer?.cancel();

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  List<Player> get starters => startingXI.where((p) => p.rating > 0).toList();

  bool get canStartMatch => starters.length == 7;

  Player _convertRow(dynamic row) {
    Map<String, int> st = {};
    List<PlayStyle> ps = [];
    try {
      if (row.statsJson != null)
        st = Map<String, int>.from(jsonDecode(row.statsJson));
    } catch (_) {}
    try {
      if (row.playStylesJson != null) {
        ps = (jsonDecode(row.playStylesJson) as List)
            .map((e) => PlayStyle(e.toString()))
            .toList();
      }
    } catch (_) {}
    return Player(
      name: row.name,
      rating: row.rating,
      position: row.position,
      playstyles: ps,
      cardType: row.cardType,
      team: row.team,
      stats: st,
      role: row.role ?? 'Yok',
    );
  }

  Future<void> openStarterPack(BuildContext context) async {
    if (claimedFirstPack) return;
    final db = Provider.of<AppDatabase>(context, listen: false);
    final raw = await db.watchAllPlayers().first;
    if (raw.isEmpty) return;

    final all = raw.map((r) => _convertRow(r)).toList();
    final rng = Random();
    final List<Player> pack = [];
    final Set<String> usedKeys = {};

    void tryAdd(Player p) {
      String k = '${p.name}_${p.cardType}';
      if (!usedKeys.contains(k)) {
        pack.add(p);
        usedKeys.add(k);
      }
    }

    // 3 special cards
    final specials = all
        .where((p) => [
              'TOTS',
              'BALLONDOR',
              'MVP',
              'TOTM',
              'STAR',
              'ICON',
              'KING'
            ].contains(p.cardType.toUpperCase()))
        .toList();
    specials.shuffle(rng);
    for (int i = 0; i < min(3, specials.length); i++) tryAdd(specials[i]);

    // 7 basic/normal cards (rating 70-99)
    final normals = all
        .where((p) =>
            p.rating >= 70 && !usedKeys.contains('${p.name}_${p.cardType}'))
        .toList();
    normals.shuffle(rng);
    int needed = 10 - pack.length;
    for (int i = 0; i < min(needed, normals.length); i++) tryAdd(normals[i]);

    // Fallback if not enough normals
    if (pack.length < 10) {
      final leftover = all
          .where((p) => !usedKeys.contains('${p.name}_${p.cardType}'))
          .toList();
      leftover.shuffle(rng);
      for (var p in leftover) {
        if (pack.length >= 10) break;
        tryAdd(p);
      }
    }

    for (var p in pack) addPlayerToClub(p);
    claimedFirstPack = true;
    _savePrefs();
    notifyListeners();
  }

  List<Player> generateOpponent() {
    final rng = Random();
    double avg = starters.isNotEmpty
        ? starters.map((p) => p.rating.toDouble()).reduce((a, b) => a + b) /
            starters.length
        : 80.0;

    final positions = ['GK', 'CB', 'CB', 'CM', 'CM', 'ST', 'LW'];
    final fakeNames = [
      'A. Turner',
      'B. Kovac',
      'C. Silva',
      'D. Muller',
      'E. Tanaka',
      'F. Obi',
      'G. Perez'
    ];
    final cardTypes = ['Temel', 'TOTW', 'STAR', 'MVP', 'TOTS'];

    return List.generate(7, (i) {
      int rat = (avg + rng.nextInt(8) - 4).clamp(60, 99).toInt();
      var fakeStats = <String, int>{
        'Hız': 8 + rng.nextInt(10),
        'Şut': 8 + rng.nextInt(10),
        'Pas': 8 + rng.nextInt(10),
        'Dripling': 8 + rng.nextInt(10),
        'Defans': 8 + rng.nextInt(10),
        'Refleks': 8 + rng.nextInt(10),
      };
      return Player(
        name: fakeNames[i],
        rating: rat,
        position: positions[i],
        playstyles: [],
        cardType: cardTypes[rng.nextInt(cardTypes.length)],
        stats: fakeStats,
      );
    });
  }
}

// =============================================================================
// MAIN VIEW ENTRY
// =============================================================================

class UltimateTeamView extends StatelessWidget {
  final AppDatabase database;
  const UltimateTeamView({super.key, required this.database});

  @override
  Widget build(BuildContext context) => const _UltimateRoot();
}

// =============================================================================
// ROOT STATE (handles tab + starter pack prompt)
// =============================================================================

class _UltimateRoot extends StatefulWidget {
  const _UltimateRoot();
  @override
  State<_UltimateRoot> createState() => _UltimateRootState();
}

class _UltimateRootState extends State<_UltimateRoot> {
  int _tabIndex = 0;
  bool _starterShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UltimateTeamProvider>().startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UltimateTeamProvider>();

    // Show starter pack dialog once
    if (!_starterShown && !prov.claimedFirstPack && prov.myClub.isEmpty) {
      _starterShown = true;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showStarterDialog(context, prov));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Stack(children: [
        Column(children: [
          _buildTopBar(context, prov),
          _buildTabs(),
          Expanded(child: _buildBody(context, prov)),
        ]),
        // Floating AI button
        Positioned(
          bottom: 24,
          right: 24,
          child: _AIChatButton(prov: prov),
        ),
      ]),
    );
  }

  Widget _buildTopBar(BuildContext context, UltimateTeamProvider prov) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C1020), Color(0xFF1C2540)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF2A3A60))),
      ),
      child: Row(children: [
        const SizedBox(width: 16),
        Text('ULTIMATE TEAM',
            style: GoogleFonts.orbitron(
                color: Colors.amber,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        const Spacer(),
        // Token LED display
        _TokenLED(tokens: prov.tokens),
        const SizedBox(width: 16),
        // Normal / Ranked toggle
        _ModeToggle(
          isRanked: prov.isRanked,
          onToggle: (v) => prov.setRanked(v),
        ),
        const SizedBox(width: 16),
      ]),
    );
  }

  Widget _buildTabs() {
    const tabs = ['MY TEAM', 'TACTICS', 'TRANSFERS', 'SELL', 'HISTORY'];
    return Container(
      height: 44,
      color: const Color(0xFF0E0E1C),
      child: Row(
          children: List.generate(tabs.length, (i) {
        bool sel = _tabIndex == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tabIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF1A2A50) : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                      color: sel ? Colors.amber : Colors.transparent, width: 2),
                ),
              ),
              child: Center(
                child: Text(tabs[i],
                    style: TextStyle(
                        color: sel ? Colors.amber : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1)),
              ),
            ),
          ),
        );
      })),
    );
  }

  Widget _buildBody(BuildContext ctx, UltimateTeamProvider prov) {
    switch (_tabIndex) {
      case 0:
        return _MyTeamTab(prov: prov, onVs: () => _startVs(ctx, prov));
      case 1:
        return _TacticsTab(prov: prov);
      case 2:
        return _TransfersTab(prov: prov);
      case 3:
        return _SellTab(prov: prov);
      case 4:
        return _HistoryTab(prov: prov);
      default:
        return const SizedBox.shrink();
    }
  }

  void _startVs(BuildContext context, UltimateTeamProvider prov) {
    if (!prov.canStartMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen 7 oyuncuyu sahaya dizin!')));
      return;
    }
    var opp = prov.generateOpponent();
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => MatchEngineView(
                myTeam: prov.starters,
                oppTeam: opp,
                myTactic: prov.tacticStyle,
                oppTactic: TacticStyle
                    .values[Random().nextInt(TacticStyle.values.length)],
                playerInstructions: prov.playerInstructions,
                isPlayerTeamAway: true,
                onMatchEnd: (result) {
                  Navigator.pop(context);
                  prov.recordMatchResult(result.isWin, result.isDraw);
                  _showMatchResult(context, result, prov);
                },
              )),
    );
  }

  void _showMatchResult(
      BuildContext context, MatchResult result, UltimateTeamProvider prov) {
    int reward = prov.history.isNotEmpty ? prov.history.first.tokenChange : 0;
    String title = result.isWin
        ? '🏆 GALİBİYET!'
        : result.isDraw
            ? '🤝 BERABERLİK'
            : '💔 MAĞLUBİYET';
    Color tc = result.isWin
        ? Colors.greenAccent
        : result.isDraw
            ? Colors.amber
            : Colors.redAccent;

    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: const Color(0xFF0E1020),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: tc, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                style: GoogleFonts.russoOne(
                    fontSize: 28,
                    color: tc,
                    shadows: [Shadow(color: tc, blurRadius: 14)])),
            const SizedBox(height: 12),
            Text('${result.myGoals} : ${result.oppGoals}',
                style: GoogleFonts.orbitron(
                    fontSize: 42,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.4))),
              child: Text('+$reward 🪙 TOKEN',
                  style: GoogleFonts.orbitron(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(c),
              style: ElevatedButton.styleFrom(
                  backgroundColor: tc.withOpacity(0.2),
                  side: BorderSide(color: tc),
                  minimumSize: const Size(160, 44)),
              child: Text('TAMAM',
                  style: TextStyle(color: tc, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }

  void _showStarterDialog(
      BuildContext context, UltimateTeamProvider prov) async {
    await prov.openStarterPack(context);
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => Dialog(
        backgroundColor: const Color(0xFF0A0A16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.amber, width: 2)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('HOŞGELDIN!',
                style: GoogleFonts.russoOne(
                    color: Colors.amber,
                    fontSize: 30,
                    shadows: [
                      const Shadow(color: Colors.amber, blurRadius: 16)
                    ])),
            const SizedBox(height: 6),
            Text('10 Başlangıç Kartı Hediye!',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text('(7 Normal + 3 Özel)',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: prov.myClub
                    .map((p) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: SizedBox(
                            width: 115, child: FCAnimatedCard(player: p))))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(c),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(180, 46)),
              child: Text('HADI BAŞLAYALIM!',
                  style: GoogleFonts.orbitron(fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}

// =============================================================================
// TOKEN LED WIDGET
// =============================================================================

class _TokenLED extends StatelessWidget {
  final int tokens;
  const _TokenLED({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: Colors.amber.withOpacity(0.25), blurRadius: 10)
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('🪙', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          '$tokens',
          style: GoogleFonts.orbitron(
            color: Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [const Shadow(color: Colors.amber, blurRadius: 8)],
          ),
        ),
      ]),
    );
  }
}

// =============================================================================
// MODE TOGGLE (Normal / Ranked)
// =============================================================================

class _ModeToggle extends StatelessWidget {
  final bool isRanked;
  final ValueChanged<bool> onToggle;
  const _ModeToggle({required this.isRanked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _btn('NORMAL', !isRanked, Colors.cyanAccent, () => onToggle(false)),
      const SizedBox(width: 4),
      _btn('RANKED', isRanked, Colors.redAccent, () => onToggle(true)),
    ]);
  }

  Widget _btn(String label, bool active, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: active ? c : Colors.white24, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? c : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// =============================================================================
// TAB 0: MY TEAM
// =============================================================================

class _MyTeamTab extends StatefulWidget {
  final UltimateTeamProvider prov;
  final VoidCallback onVs;
  const _MyTeamTab({required this.prov, required this.onVs});
  @override
  State<_MyTeamTab> createState() => _MyTeamTabState();
}

class _MyTeamTabState extends State<_MyTeamTab> {
  @override
  Widget build(BuildContext context) {
    final prov = widget.prov;
    bool isMobile = MediaQuery.of(context).size.width < 850;

    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      children: [
        // PITCH
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A5E1A),
                  Color(0xFF226622),
                  Color(0xFF1A5E1A)
                ],
              ),
            ),
            child: LayoutBuilder(builder: (ctx, cons) {
              double w = cons.maxWidth, h = cons.maxHeight;
              return Stack(children: [
                CustomPaint(size: Size(w, h), painter: _PitchMarkingsPainter()),
                _pitchSlot(ctx, prov, 0, 'GK', w * 0.50, h * 0.87),
                _pitchSlot(ctx, prov, 1, 'DEF', w * 0.25, h * 0.68),
                _pitchSlot(ctx, prov, 2, 'DEF', w * 0.75, h * 0.68),
                _pitchSlot(ctx, prov, 3, 'MID', w * 0.28, h * 0.46),
                _pitchSlot(ctx, prov, 4, 'MID', w * 0.72, h * 0.46),
                _pitchSlot(ctx, prov, 5, 'FWD', w * 0.35, h * 0.22),
                _pitchSlot(ctx, prov, 6, 'FWD', w * 0.65, h * 0.22),
              ]);
            }),
          ),
        ),
        // SIDE PANEL
        Container(
          width: isMobile ? double.infinity : 340,
          height: isMobile ? 260 : double.infinity,
          color: const Color(0xFF10101C),
          child: Column(children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onVs,
                    icon: const Text('⚽', style: TextStyle(fontSize: 18)),
                    label: Text('MAÇ BAŞLAT',
                        style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      shadowColor: Colors.red.withOpacity(0.4),
                      elevation: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => prov.autoBuild(),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Icon(Icons.auto_fix_high, color: Colors.white),
                ),
              ]),
            ),
            const Divider(color: Colors.white10, height: 12),
            // Club cards
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.66,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4),
                itemCount: prov.myClub.length,
                itemBuilder: (ctx, i) {
                  final p = prov.myClub[i];
                  return Draggable<Player>(
                    data: p,
                    feedback:
                        SizedBox(width: 80, child: FCAnimatedCard(player: p)),
                    childWhenDragging: Opacity(
                        opacity: 0.35, child: FCAnimatedCard(player: p)),
                    child: GestureDetector(
                      onTap: () => _showPlayerStats(context, p),
                      child: FCAnimatedCard(player: p),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _pitchSlot(BuildContext ctx, UltimateTeamProvider prov, int i,
      String label, double cx, double cy) {
    var p = prov.startingXI[i];
    return Positioned(
      left: cx - 48,
      top: cy - 62,
      child: DragTarget<Player>(
        onAcceptWithDetails: (details) => prov.setStarter(i, details.data),
        builder: (c, cand, _) => SizedBox(
          width: 96,
          height: 124,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: cand.isNotEmpty ? Colors.amber : Colors.transparent,
                  width: 2),
            ),
            child: p.rating > 0
                ? GestureDetector(
                    onTap: () => _showPlayerStats(ctx, p),
                    child: FCAnimatedCard(player: p))
                : Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.black38,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add,
                              color: Colors.white30, size: 20),
                          Text(label,
                              style: const TextStyle(
                                  color: Colors.white30, fontSize: 11)),
                        ]),
                  ),
          ),
        ),
      ),
    );
  }

  void _showPlayerStats(BuildContext ctx, Player p) {
    var s = p.getFMStats();
    showDialog(
      context: ctx,
      builder: (c) => Dialog(
        backgroundColor: const Color(0xFF0E0E1C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A3A60))),
        child: SizedBox(
          width: 680,
          height: 460,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              SizedBox(width: 180, child: FCAnimatedCard(player: p)),
              const SizedBox(width: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 4.2,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 8,
                  children: s.entries.map((e) {
                    Color vc = e.value >= 16
                        ? Colors.greenAccent
                        : e.value >= 12
                            ? Colors.amber
                            : Colors.redAccent;
                    return Container(
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(children: [
                        Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12))),
                        Text('${e.value}',
                            style: TextStyle(
                                color: vc,
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: TACTICS
// =============================================================================

class _TacticsTab extends StatefulWidget {
  final UltimateTeamProvider prov;
  const _TacticsTab({required this.prov});
  @override
  State<_TacticsTab> createState() => _TacticsTabState();
}

class _TacticsTabState extends State<_TacticsTab> {
  int? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    final prov = widget.prov;
    final slots = ['GK', 'DEF', 'DEF', 'MID', 'MID', 'FWD', 'FWD'];

    return Row(children: [
      // Tactic board + player slots
      Expanded(
        flex: 5,
        child: Column(children: [
          // Tactic style selector
          Container(
            color: const Color(0xFF0C0C18),
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: TacticStyle.values.map((t) {
                bool sel = prov.tacticStyle == t;
                return GestureDetector(
                  onTap: () => prov.setTactic(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel
                          ? t.color.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      border: Border.all(
                          color: sel ? t.color : Colors.white.withOpacity(0.20),
                          width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(t.label,
                        style: TextStyle(
                            color: sel ? t.color : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          // Pitch with clickable players
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1A5E1A),
                    Color(0xFF226622),
                    Color(0xFF1A5E1A)
                  ],
                ),
                border: Border.all(color: Colors.white12),
              ),
              child: LayoutBuilder(builder: (_, cons) {
                double w = cons.maxWidth, h = cons.maxHeight;
                final positions = [
                  Offset(w * 0.50, h * 0.87),
                  Offset(w * 0.25, h * 0.68),
                  Offset(w * 0.75, h * 0.68),
                  Offset(w * 0.28, h * 0.46),
                  Offset(w * 0.72, h * 0.46),
                  Offset(w * 0.35, h * 0.22),
                  Offset(w * 0.65, h * 0.22),
                ];
                return Stack(children: [
                  CustomPaint(
                      size: Size(w, h), painter: _PitchMarkingsPainter()),
                  ...List.generate(7, (i) {
                    var p = prov.startingXI[i];
                    bool sel = _selectedSlot == i;
                    PlayerInstruction instr =
                        prov.playerInstructions[i] ?? PlayerInstruction();
                    return Positioned(
                      left: positions[i].dx - 40,
                      top: positions[i].dy - 38,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedSlot = sel ? null : i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 80,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: sel
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                                color: sel
                                    ? Colors.amber
                                    : instr.isBalanced
                                        ? Colors.transparent
                                        : instr.color,
                                width: sel ? 2 : 1.5),
                          ),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(p.rating > 0 ? p.name : slots[i],
                                style: TextStyle(
                                    color: sel ? Colors.amber : Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(instr.label,
                                style:
                                    TextStyle(color: instr.color, fontSize: 8),
                                textAlign: TextAlign.center),
                            // Arrow indicator for runs
                            if (instr.constantRuns)
                              const Icon(Icons.arrow_upward,
                                  color: Colors.orangeAccent, size: 12),
                            if (instr.stayWide)
                              const Icon(Icons.swap_horiz,
                                  color: Colors.greenAccent, size: 12),
                          ]),
                        ),
                      ),
                    );
                  }),
                ]);
              }),
            ),
          ),
        ]),
      ),
      // Right panel: instruction editor
      Container(
        width: 240,
        color: const Color(0xFF0A0A14),
        padding: const EdgeInsets.all(14),
        child: _selectedSlot == null
            ? Center(
                child: Text(
                    'Oyuncu Seçin\n(Taktik sahada\nbir oyuncuya tıklayın)',
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white30, fontSize: 12)),
              )
            : _instructionPanel(prov, _selectedSlot!),
      ),
    ]);
  }

  Widget _instructionPanel(UltimateTeamProvider prov, int slot) {
    var p = prov.startingXI[slot];
    PlayerInstruction cur =
        (prov.playerInstructions[slot] ?? PlayerInstruction()).copy();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(p.rating > 0 ? p.name : 'Boş Slot',
          style: GoogleFonts.orbitron(
              color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
      if (p.rating > 0)
        Text('${p.position} • ${p.rating}',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 14),
      const Text('TALİMAT SEÇ',
          style:
              TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
      const SizedBox(height: 8),
      ..._instrOptions(cur, slot, prov),
      const SizedBox(height: 16),
      const Divider(color: Colors.white10),
      const SizedBox(height: 8),
      // Tactic description
      Text(_tacticDescription(prov.tacticStyle),
          style: const TextStyle(
              color: Colors.white38, fontSize: 10, height: 1.5)),
    ]);
  }

  List<Widget> _instrOptions(
      PlayerInstruction cur, int slot, UltimateTeamProvider prov) {
    final options = [
      ('⚖ Dengeli', 'balanced'),
      ('📨 Pas Odaklı', 'passOnly'),
      ('↔ Geniş Dur', 'stayWide'),
      ('🔒 Markaj', 'marking'),
      ('🏃 Sürekli Koşu', 'constantRuns'),
    ];
    return options.map((opt) {
      bool active = _isActive(cur, opt.$2);
      return GestureDetector(
        onTap: () {
          var n = PlayerInstruction();
          if (opt.$2 != 'balanced') {
            switch (opt.$2) {
              case 'passOnly':
                n = PlayerInstruction(passOnly: true);
                break;
              case 'stayWide':
                n = PlayerInstruction(stayWide: true);
                break;
              case 'marking':
                n = PlayerInstruction(marking: true);
                break;
              case 'constantRuns':
                n = PlayerInstruction(constantRuns: true);
                break;
            }
          }
          prov.setInstruction(slot, n);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? Colors.amber.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? Colors.amber : Colors.white12, width: 1.2),
          ),
          child: Text(opt.$1,
              style: TextStyle(
                  color: active ? Colors.amber : Colors.white54,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }).toList();
  }

  bool _isActive(PlayerInstruction i, String key) {
    if (key == 'balanced') return i.isBalanced;
    if (key == 'passOnly') return i.passOnly;
    if (key == 'stayWide') return i.stayWide;
    if (key == 'marking') return i.marking;
    if (key == 'constantRuns') return i.constantRuns;
    return false;
  }

  String _tacticDescription(TacticStyle t) {
    switch (t) {
      case TacticStyle.attack:
        return 'Hücum: Oyuncular yukarı itilir. Defans riski artar. Çok şut, yüksek baskı hücumda.';
      case TacticStyle.gegen:
        return 'Gegenpres: Top kaybedilince 3-6 oyuncu anında baskı yapar. Yüksek yoğunluk.';
      case TacticStyle.defensive:
        return 'Savunmacı: Defans derinden oynar. Kontra ataklar için bekler. Güvenli blok.';
      case TacticStyle.counter:
        return 'Kontra Atak: Derine çekilir, top kazanılınca hızlı dikey pas ile forvetlere çabuk ulaşır.';
      case TacticStyle.tikiTaka:
        return 'Tiki-Taka: Kısa paslarla top dolaşımı. Yavaş yapılanma ama yüksek kontrolü sağlar.';
      case TacticStyle.highPress:
        return 'Yüksek Baskı: Rakibin kalesine yakın presler. Top erken kazanılırsa tehlikeli.';
    }
  }
}

// =============================================================================
// TAB 2: TRANSFERS
// =============================================================================

class _TransfersTab extends StatefulWidget {
  final UltimateTeamProvider prov;
  const _TransfersTab({required this.prov});
  @override
  State<_TransfersTab> createState() => _TransfersTabState();
}

class _TransfersTabState extends State<_TransfersTab> {
  String _filter = '';
  String _sortBy = 'Fiyat';

  @override
  Widget build(BuildContext context) {
    final prov = widget.prov;
    var listings = List<MarketListing>.from(prov.transferMarket)
      ..removeWhere(
          (l) => prov.myListings.any((m) => m.id == l.id)); // don't show own

    if (_filter.isNotEmpty) {
      listings.retainWhere((l) =>
          l.player.name.toLowerCase().contains(_filter.toLowerCase()) ||
          l.player.position.toLowerCase().contains(_filter.toLowerCase()) ||
          l.player.cardType.toLowerCase().contains(_filter.toLowerCase()));
    }
    if (_sortBy == 'Fiyat') {
      listings.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Rating') {
      listings.sort((a, b) => b.player.rating.compareTo(a.player.rating));
    }

    return Column(children: [
      // Search + sort bar
      Container(
        color: const Color(0xFF0A0A14),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Oyuncu / Pozisyon / Kart ara…',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white30, size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: _sortBy,
            dropdownColor: const Color(0xFF0E0E1C),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            underline: const SizedBox.shrink(),
            items: ['Fiyat', 'Rating']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _sortBy = v!),
          ),
        ]),
      ),
      // Grid
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisExtent: 320,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: listings.length,
          itemBuilder: (ctx, i) => _listingCard(ctx, prov, listings[i]),
        ),
      ),
    ]);
  }

  Widget _listingCard(
      BuildContext ctx, UltimateTeamProvider prov, MarketListing l) {
    bool canBuy = prov.tokens >= l.price;
    return GestureDetector(
      onTap: () => _showListingDetail(ctx, prov, l),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0C0C18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(children: [
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FCAnimatedCard(player: l.player))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A14),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(l.sellerName,
                    style: const TextStyle(color: Colors.white38, fontSize: 9)),
                Row(children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text('${l.price}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ]),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 32,
                child: ElevatedButton(
                  onPressed: canBuy
                      ? () {
                          if (prov.buyFromMarket(l)) {
                            setState(() {});
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text('${l.player.name} satın alındı!'),
                                backgroundColor: Colors.green));
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canBuy
                        ? Colors.amber.withOpacity(0.8)
                        : Colors.grey.withOpacity(0.2),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(canBuy ? 'SATIN AL' : 'TOKEN YETMEDİ',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showListingDetail(
      BuildContext ctx, UltimateTeamProvider prov, MarketListing l) {
    var stats = l.player.getFMStats();
    showDialog(
      context: ctx,
      builder: (c) => Dialog(
        backgroundColor: const Color(0xFF0E0E1C),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.amber, width: 1)),
        child: SizedBox(
          width: 580,
          height: 440,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              SizedBox(width: 170, child: FCAnimatedCard(player: l.player)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.player.name,
                          style: GoogleFonts.orbitron(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text(
                          '${l.player.position} • ${l.player.rating} • ${l.player.cardType}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('Satıcı: ${l.sellerName}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      const Divider(color: Colors.white12, height: 16),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 8,
                          children: stats.entries.map((e) {
                            Color vc = e.value >= 16
                                ? Colors.greenAccent
                                : e.value >= 12
                                    ? Colors.amber
                                    : Colors.redAccent;
                            return Row(children: [
                              Expanded(
                                  child: Text(e.key,
                                      style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11))),
                              Text('${e.value}',
                                  style: TextStyle(
                                      color: vc,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ]);
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text('${l.price}',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: prov.tokens >= l.price
                              ? () {
                                  prov.buyFromMarket(l);
                                  Navigator.pop(c);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black),
                          child: const Text('SATIN AL',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 3: SELL
// =============================================================================

class _SellTab extends StatefulWidget {
  final UltimateTeamProvider prov;
  const _SellTab({required this.prov});
  @override
  State<_SellTab> createState() => _SellTabState();
}

class _SellTabState extends State<_SellTab> {
  Player? _selectedPlayer;
  final _priceCtrl = TextEditingController(text: '50');

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = widget.prov;
    return Row(children: [
      // My club
      Expanded(
        flex: 3,
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('SATMAK İSTEDİĞİN KARTLARI SEÇ',
                style: TextStyle(
                    color: Colors.white54, fontSize: 11, letterSpacing: 1)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.68,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4),
              itemCount: prov.myClub.length,
              itemBuilder: (ctx, i) {
                var p = prov.myClub[i];
                bool already = prov.myListings.any((l) =>
                    l.player.name == p.name && l.player.cardType == p.cardType);
                bool sel = _selectedPlayer?.name == p.name &&
                    _selectedPlayer?.cardType == p.cardType;
                return GestureDetector(
                  onTap: already
                      ? null
                      : () => setState(() => _selectedPlayer = p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: sel
                              ? Colors.amber
                              : already
                                  ? Colors.green
                                  : Colors.transparent,
                          width: sel || already ? 2 : 0),
                    ),
                    child: Stack(children: [
                      Opacity(
                          opacity: already ? 0.4 : 1.0,
                          child: FCAnimatedCard(player: p)),
                      if (already)
                        const Positioned.fill(
                            child: Center(
                                child: Text('LİSTEDE',
                                    style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)))),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      // Sell panel
      Container(
        width: 260,
        color: const Color(0xFF0A0A14),
        padding: const EdgeInsets.all(16),
        child: _selectedPlayer == null
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.sell_outlined,
                    color: Colors.white.withOpacity(0.20), size: 48),
                SizedBox(height: 10),
                Text('Bir kart seçin',
                    style: TextStyle(color: Colors.white30, fontSize: 13)),
              ]))
            : _sellPanel(prov),
      ),
      // Active listings
      Container(
        width: 220,
        color: const Color(0xFF070710),
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Text('AKTİF İLANLARIM',
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1)),
          ),
          Expanded(
            child: prov.myListings.isEmpty
                ? Center(
                    child: Text('Henüz ilan yok',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.20),
                            fontSize: 12)))
                : ListView.builder(
                    itemCount: prov.myListings.length,
                    itemBuilder: (ctx, i) {
                      var l = prov.myListings[i];
                      return ListTile(
                        dense: true,
                        title: Text(l.player.name,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        subtitle: Text('🪙 ${l.price}',
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.redAccent, size: 18),
                          onPressed: () {
                            prov.removeOwnListing(l.id);
                            setState(() {});
                          },
                        ),
                      );
                    }),
          ),
        ]),
      ),
    ]);
  }

  Widget _sellPanel(UltimateTeamProvider prov) {
    var p = _selectedPlayer!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 160, child: FCAnimatedCard(player: p)),
      const SizedBox(height: 12),
      Text(p.name,
          style: GoogleFonts.orbitron(
              color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
      Text('${p.position} • ${p.rating}',
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
      const SizedBox(height: 16),
      const Text('FİYAT (🪙 Token)',
          style: TextStyle(color: Colors.white54, fontSize: 11)),
      const SizedBox(height: 6),
      TextField(
        controller: _priceCtrl,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
          prefixText: '🪙 ',
          prefixStyle: const TextStyle(color: Colors.amber),
        ),
      ),
      const SizedBox(height: 14),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            int price = int.tryParse(_priceCtrl.text) ?? 50;
            price = price.clamp(1, 9999);
            prov.listForSale(p, price);
            setState(() => _selectedPlayer = null);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${p.name} transfer pazarına listelendi!'),
                backgroundColor: Colors.green));
          },
          icon: const Icon(Icons.sell, size: 16),
          label: const Text('SATIŞ İLANI VER',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(0, 44)),
        ),
      ),
    ]);
  }
}

// =============================================================================
// TAB 4: HISTORY
// =============================================================================

class _HistoryTab extends StatelessWidget {
  final UltimateTeamProvider prov;
  const _HistoryTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Match/market history
      Expanded(
        flex: 3,
        child: Column(children: [
          _header('GEÇMİŞ'),
          Expanded(
            child: prov.history.isEmpty
                ? const Center(
                    child: Text('Henüz kayıt yok',
                        style: TextStyle(color: Colors.white30)))
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: prov.history.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (_, i) {
                      var h = prov.history[i];
                      bool pos = h.tokenChange >= 0;
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pos
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                          ),
                          child: Center(
                              child: Text(
                                  h.type == 'match'
                                      ? '⚽'
                                      : h.type == 'sold'
                                          ? '💰'
                                          : '🛒',
                                  style: const TextStyle(fontSize: 16))),
                        ),
                        title: Text(h.description,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        subtitle: Text(
                          '${h.date.day}/${h.date.month} ${h.date.hour}:${h.date.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 10),
                        ),
                        trailing: Text(
                          '${pos ? '+' : ''}${h.tokenChange} 🪙',
                          style: TextStyle(
                              color:
                                  pos ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
          ),
        ]),
      ),
      // Leaderboard
      Container(
        width: 320,
        color: const Color(0xFF08081480),
        child: Column(children: [
          _header('RANKED LIDER TABLOSU'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(children: [
              // Win / Loss / Draw summary
              _statChip('Galibiyet', '${prov.wins}', Colors.greenAccent),
              const SizedBox(width: 6),
              _statChip('Beraberlik', '${prov.draws}', Colors.amber),
              const SizedBox(width: 6),
              _statChip('Mağlubiyet', '${prov.losses}', Colors.redAccent),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: prov.leaderboard.length,
              itemBuilder: (_, i) {
                var e = prov.leaderboard[i];
                bool isMe = e.playerName == prov.playerName;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isMe
                        ? Colors.amber.withOpacity(0.12)
                        : const Color(0xFF0C0C18),
                    border: Border.all(
                        color: isMe
                            ? Colors.amber.withOpacity(0.5)
                            : Colors.white12,
                        width: isMe ? 1.5 : 1),
                  ),
                  child: Row(children: [
                    SizedBox(
                      width: 28,
                      child: Text('#${e.rank}',
                          style: TextStyle(
                              color:
                                  e.rank <= 3 ? Colors.amber : Colors.white54,
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                        child: Text(e.playerName,
                            style: TextStyle(
                                color: isMe ? Colors.amber : Colors.white70,
                                fontSize: 12,
                                fontWeight: isMe
                                    ? FontWeight.bold
                                    : FontWeight.normal))),
                    Text('${e.points}p',
                        style: const TextStyle(
                            color: Colors.cyanAccent, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('🪙 ${e.tokens}',
                        style:
                            const TextStyle(color: Colors.amber, fontSize: 11)),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _header(String title) => Container(
        color: const Color(0xFF080810),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
        ),
      );

  Widget _statChip(String label, String value, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: c.withOpacity(0.10),
            border: Border.all(color: c.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: c, fontSize: 16, fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ]),
        ),
      );
}

// =============================================================================
// AI CHAT BUTTON & OVERLAY
// =============================================================================

class _AIChatButton extends StatefulWidget {
  final UltimateTeamProvider prov;
  const _AIChatButton({required this.prov});
  @override
  State<_AIChatButton> createState() => _AIChatButtonState();
}

class _AIChatButtonState extends State<_AIChatButton>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _anim;
  late Animation<double> _scale;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Simple rule-based AI memory
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    // Greeting
    _messages.add({
      'role': 'ai',
      'text':
          '👋 Merhaba! Ben Ultimate Team Danışmanınım. Takımın hakkında sorular sor, taktik önerileri alabilirsin!'
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          ScaleTransition(
            scale: _scale,
            alignment: Alignment.bottomRight,
            child: _chatPanel(),
          ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            setState(() => _open = !_open);
            if (_open)
              _anim.forward();
            else
              _anim.reverse();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _open
                    ? [Colors.red, Colors.redAccent]
                    : [const Color(0xFF3D5AFE), const Color(0xFF00E5FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_open ? Colors.red : const Color(0xFF3D5AFE))
                      .withOpacity(0.5),
                  blurRadius: 14,
                )
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _open
                    ? const Icon(Icons.close,
                        color: Colors.white, key: ValueKey('close'))
                    : const Text('🤖',
                        style: TextStyle(fontSize: 24), key: ValueKey('ai')),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chatPanel() {
    return Container(
      width: 320,
      height: 440,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0C0C1C),
        border: Border.all(color: const Color(0xFF2A3A80), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF3D5AFE).withOpacity(0.3), blurRadius: 20)
        ],
      ),
      child: Column(children: [
        // Header
        Container(
          height: 46,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            gradient:
                LinearGradient(colors: [Color(0xFF1A2060), Color(0xFF0e1840)]),
          ),
          child: Row(children: [
            const SizedBox(width: 12),
            const Text('🤖', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('AI Danışman',
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _messages.add({'role': 'ai', 'text': '✨ Sohbet sıfırlandı!'});
                });
              },
              child: const Text('Temizle',
                  style: TextStyle(color: Colors.white38, fontSize: 10)),
            ),
          ]),
        ),
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              var m = _messages[i];
              bool isAI = m['role'] == 'ai';
              return Align(
                alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 260),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isAI
                        ? const Color(0xFF152040)
                        : const Color(0xFF1E1040),
                    border: Border.all(
                        color: isAI
                            ? const Color(0xFF2A4080).withOpacity(0.6)
                            : Colors.purpleAccent.withOpacity(0.3)),
                  ),
                  child: Text(m['text']!,
                      style: TextStyle(
                          color: isAI ? Colors.lightBlueAccent : Colors.white,
                          fontSize: 11,
                          height: 1.5)),
                ),
              );
            },
          ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Soru sor…',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3D5AFE), Color(0xFF00B0FF)]),
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 16),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _send() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _ctrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': q});
    });

    // Generate AI response
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      String reply = _generateReply(q.toLowerCase(), widget.prov);
      setState(() {
        _messages.add({'role': 'ai', 'text': reply});
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
        }
      });
    });
  }

  String _generateReply(String q, UltimateTeamProvider prov) {
    final club = prov.myClub;
    final xi = prov.starters;
    final tac = prov.tacticStyle;
    final rng = Random();

    // --- Greeting ---
    if (q.contains('merhaba') || q.contains('selam') || q.contains('naber')) {
      return '👋 Merhaba! Takımın hakkında yardımcı olabilirim. Kadro analizi, taktik önerisi veya oyuncu karşılaştırması için sorabilirsin!';
    }

    // --- Best formation ---
    if (q.contains('kadro') ||
        q.contains('dizilim') ||
        q.contains('xi') ||
        q.contains('11')) {
      if (xi.isEmpty)
        return '⚠️ Henüz sahaya oyuncu dizilmemiş. My Team sekmesinden oyuncuları yerleştir.';
      var analysis = xi.map((p) {
        var s = p.getFMStats();
        int best = s.values.reduce(max);
        String bestKey = s.entries.firstWhere((e) => e.value == best).key;
        return '• ${p.name} (${p.position}) – En iyi: $bestKey=$best';
      }).join('\n');
      return '📊 Mevcut Kadro Analizi:\n$analysis';
    }

    // --- Weak foot / left-right advice ---
    if (q.contains('zayıf ayak') ||
        q.contains('weakfoot') ||
        q.contains('sağ') && q.contains('sol')) {
      if (xi.isEmpty)
        return 'Sahaya oyuncu dizilmemişken zayıf ayak analizi yapamam.';
      String advice = '';
      for (var p in xi) {
        int sf = p.skillMoves;
        if (sf <= 2 &&
            (p.position.contains('RW') || p.position.contains('RM'))) {
          advice +=
              '• ${p.name}: Zayıf ayakla oynuyor (${sf}★). Sola alınması önerilebilir.\n';
        }
        if (sf <= 2 &&
            (p.position.contains('LW') || p.position.contains('LM'))) {
          advice +=
              '• ${p.name}: Zayıf ayakla oynuyor (${sf}★). Sağa alınması önerilebilir.\n';
        }
      }
      return advice.isEmpty
          ? '✅ Zayıf ayak sorunu tespit edilmedi. Oyuncular uygun konumlarda görünüyor.'
          : '⚠️ Zayıf Ayak Tavsiyeleri:\n$advice';
    }

    // --- Tactic recommendation ---
    if (q.contains('taktik') || q.contains('tactic') || q.contains('sistem')) {
      if (xi.isEmpty) return 'Önce sahaya oyuncu dizilmeli.';
      double avgDef = xi
              .map((p) => p.getFMStats()['Defans'] ?? 10)
              .reduce((a, b) => a + b) /
          xi.length;
      double avgShot =
          xi.map((p) => p.getFMStats()['Şut'] ?? 10).reduce((a, b) => a + b) /
              xi.length;
      double avgPas =
          xi.map((p) => p.getFMStats()['Pas'] ?? 10).reduce((a, b) => a + b) /
              xi.length;
      double avgSpd =
          xi.map((p) => p.getFMStats()['Hız'] ?? 10).reduce((a, b) => a + b) /
              xi.length;

      String rec;
      if (avgPas > 14 && avgSpd > 13) {
        rec =
            '🌀 TİKİ-TAKA: Yüksek pas kalitesi (${avgPas.toStringAsFixed(1)}) var. Kısa pas döngüsü çok etkili olur.';
      } else if (avgSpd > 15) {
        rec =
            '⚡ KONTRA ATAK: Takımın hızı (${avgSpd.toStringAsFixed(1)}) çok iyi. Derin savunma + hızlı kontra harika.';
      } else if (avgDef > 14) {
        rec =
            '🛡 SAVUNMACI: Defans kalitesi yüksek (${avgDef.toStringAsFixed(1)}). Bloklama ve bekletme taktiği ideal.';
      } else if (avgShot > 14) {
        rec =
            '🔥 HÜCUM: Forvetlerin şut gücü (${avgShot.toStringAsFixed(1)}) yüksek. Agresif hücum oyna.';
      } else {
        rec = '⚖ DENGELİ: Takımın dengeli. Tiki-taka veya Gegenpres dene.';
      }
      return '🎯 Taktik Önerisi:\n$rec';
    }

    // --- Gegenpres / pressing ---
    if (q.contains('gegen') || q.contains('pres') || q.contains('baskı')) {
      if (xi.isEmpty) return 'Sahaya oyuncu dizin.';
      double avgPhys =
          xi.map((p) => p.getFMStats()['Fizik'] ?? 10).reduce((a, b) => a + b) /
              xi.length;
      if (avgPhys < 12) {
        return '⚠️ Gegenpres için fiziksel güç önemli. Takımın fizik ortalaması düşük (${avgPhys.toStringAsFixed(1)}). Daha güçlü kartlar öneririm.';
      }
      return '💪 Gegenpres: Fizik ortalamanız (${avgPhys.toStringAsFixed(1)}) yeterli. Gegenpres seçtiğinde top kaybedilince 3-6 oyuncu anında baskıya geçer!';
    }

    // --- Best striker ---
    if (q.contains('forvet') || q.contains('striker') || q.contains('st')) {
      if (club.isEmpty) return 'Kulübünde henüz oyuncu yok.';
      var fwds = club
          .where((p) =>
              p.position.contains('ST') ||
              p.position.contains('FWD') ||
              p.position.contains('LW') ||
              p.position.contains('RW'))
          .toList();
      if (fwds.isEmpty) fwds = club;
      fwds.sort((a, b) =>
          (b.getFMStats()['Şut'] ?? 0).compareTo(a.getFMStats()['Şut'] ?? 0));
      var top = fwds.take(3).toList();
      String res = top
          .map((p) =>
              '⚽ ${p.name} (${p.position}) – Şut: ${p.getFMStats()['Şut']}')
          .join('\n');
      return '🏆 En İyi Forvet Adayları:\n$res';
    }

    // --- GK recommendation ---
    if (q.contains('kaleci') || q.contains('gk') || q.contains('goalkeeper')) {
      if (club.isEmpty) return 'Kulübünde henüz oyuncu yok.';
      var gks = club.where((p) => p.position.contains('GK')).toList();
      if (gks.isEmpty)
        return '⚠️ Kulübünde GK pozisyonunda oyuncu yok! Transfers sekmesinden bir kaleci al.';
      gks.sort((a, b) => (b.getFMStats()['Refleks'] ?? 0)
          .compareTo(a.getFMStats()['Refleks'] ?? 0));
      var best = gks.first;
      return '🧤 Önerilen Kaleci: ${best.name} – Refleks: ${best.getFMStats()['Refleks']}';
    }

    // --- Token tips ---
    if (q.contains('token') || q.contains('para') || q.contains('kazan')) {
      int multi = prov.isRanked ? 2 : 1;
      return '💰 Token Kazanma:\n'
          '• Galibiyet: ${20 * multi} 🪙\n'
          '• Beraberlik: ${10 * multi} 🪙\n'
          '• Mağlubiyet: ${5 * multi} 🪙\n'
          '${prov.isRanked ? "✅ Ranked Mod aktif (2x çarpan)!" : "💡 Ranked moda geç → 2x daha fazla token!"}\n'
          'Ayrıca kartlarını Sell sekmesinden satabilirsin.';
    }

    // --- Ranked vs Normal ---
    if (q.contains('ranked') || q.contains('normal mod')) {
      return '🏆 Ranked Mod: Token ödülü 2kat, sıralamanın görünür.\n'
          '⚽ Normal Mod: Sıralama etkisi yok, rahat oyun.\n'
          'Şu an: ${prov.isRanked ? "RANKED ✅" : "NORMAL"}';
    }

    // --- Speed ---
    if (q.contains('hız') || q.contains('süre') || q.contains('zaman')) {
      return '⏱ Maç Süresi:\n'
          '• HIZLI: 15 saniye\n'
          '• ORTA: 40 saniye\n'
          '• YAVAŞ: 90 saniye\n'
          'Maç ekranında hız değiştirme butonları bulunuyor.';
    }

    // --- Sell advice ---
    if (q.contains('sat') || q.contains('sell')) {
      if (club.length <= 7)
        return '⚠️ Kulübünde çok az oyuncu var. Satmak yerine Transfers\'ten yeni oyuncu al!';
      var low = club.where((p) => p.rating < 75).toList();
      if (low.isEmpty)
        return '💚 Tüm oyuncuların kaliteli görünüyor. Satmana gerek yok.';
      var worst = low.reduce((a, b) => a.rating < b.rating ? a : b);
      return '📤 Satılabilecek Düşük Kaliteli Oyuncu:\n• ${worst.name} (${worst.position}) – Rating: ${worst.rating}\n\nSell sekmesinden liste çıkarabilirsin.';
    }

    // --- General team summary ---
    if (q.contains('analiz') || q.contains('durum') || q.contains('nasıl')) {
      int total = club.length;
      int started = xi.length;
      double avgRat = xi.isNotEmpty
          ? xi.map((p) => p.rating.toDouble()).reduce((a, b) => a + b) /
              xi.length
          : 0;
      return '📊 Takım Durumu:\n'
          '• Kulüp: $total oyuncu\n'
          '• Sahada: $started / 7\n'
          '• Ortalama Rating: ${avgRat.toStringAsFixed(1)}\n'
          '• Taktik: ${tac.label}\n'
          '• Token: ${prov.tokens} 🪙\n'
          '• Ranked Stats: ${prov.wins}G ${prov.draws}B ${prov.losses}M';
    }

    // --- Default ---
    final defaults = [
      '🤔 Bunu anlayamadım. Şunları sorabilirsin:\n• "Kadro analizi"\n• "Hangi taktik önerirsin?"\n• "En iyi forvet kim?"\n• "Token nasıl kazanırım?"',
      '💡 İpucu: Taktik sekmesinden her oyuncuya farklı talimat verebilirsin (Pas Odaklı, Geniş Dur, Markaj, Koşu)',
      '🎯 Hatırlatma: Ranked mod seçersen token ödülleri 2 kat artıyor!',
    ];
    return defaults[rng.nextInt(defaults.length)];
  }
}

// =============================================================================
// PITCH MARKINGS PAINTER (shared)
// =============================================================================

class _PitchMarkingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.13)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double w = size.width, h = size.height;
    // Center line (horizontal — portrait pitch)
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), p);
    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), min(w, h) * 0.14, p);
    // Center dot
    p.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), 4, p);
    p.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(_) => false;
}
