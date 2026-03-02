import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// =============================================================================
// ENUMS & EXTENSIONS
// =============================================================================

enum MatchSpeed { fast, medium, slow }

extension MatchSpeedExt on MatchSpeed {
  int get durationSeconds => this == MatchSpeed.fast
      ? 10
      : this == MatchSpeed.medium
          ? 50
          : 120;
  int get totalTicks => durationSeconds * 60;
  String get label => this == MatchSpeed.fast
      ? 'HIZLI'
      : this == MatchSpeed.medium
          ? 'ORTA'
          : 'YAVAŞ';
  Color get color => this == MatchSpeed.fast
      ? Colors.redAccent
      : this == MatchSpeed.medium
          ? Colors.amber
          : Colors.greenAccent;
}

enum TacticStyle { attack, gegen, defensive, counter, tikiTaka, highPress }

extension TacticStyleExt on TacticStyle {
  String get label {
    switch (this) {
      case TacticStyle.attack:
        return 'HÜCUM';
      case TacticStyle.gegen:
        return 'GEGENPRES';
      case TacticStyle.defensive:
        return 'SAVUNMACI';
      case TacticStyle.counter:
        return 'KONTRA';
      case TacticStyle.tikiTaka:
        return 'TİKİ-TAKA';
      case TacticStyle.highPress:
        return 'YÜKSEK BASK';
    }
  }

  Color get color {
    switch (this) {
      case TacticStyle.attack:
        return Colors.redAccent;
      case TacticStyle.gegen:
        return Colors.orangeAccent;
      case TacticStyle.defensive:
        return Colors.blueAccent;
      case TacticStyle.counter:
        return Colors.purpleAccent;
      case TacticStyle.tikiTaka:
        return Colors.cyanAccent;
      case TacticStyle.highPress:
        return Colors.yellowAccent;
    }
  }
}

// =============================================================================
// PLAYER INSTRUCTION
// =============================================================================

class PlayerInstruction {
  bool passOnly;
  bool stayWide;
  bool marking;
  bool constantRuns;

  PlayerInstruction({
    this.passOnly = false,
    this.stayWide = false,
    this.marking = false,
    this.constantRuns = false,
  });

  bool get isBalanced => !passOnly && !stayWide && !marking && !constantRuns;

  String get label {
    if (passOnly) return '📨 Pas Odaklı';
    if (stayWide) return '↔ Geniş Dur';
    if (marking) return '🔒 Markaj';
    if (constantRuns) return '🏃 Koşu';
    return '⚖ Dengeli';
  }

  Color get color {
    if (passOnly) return Colors.cyanAccent;
    if (stayWide) return Colors.greenAccent;
    if (marking) return Colors.redAccent;
    if (constantRuns) return Colors.orangeAccent;
    return Colors.white70;
  }

  PlayerInstruction copy() => PlayerInstruction(
        passOnly: passOnly,
        stayWide: stayWide,
        marking: marking,
        constantRuns: constantRuns,
      );
}

// =============================================================================
// POSITION
// =============================================================================

class Pos {
  double x, y;
  Pos(this.x, this.y);

  double dist(Pos p) => sqrt(pow(x - p.x, 2) + pow(y - p.y, 2));
  Pos lerp(Pos to, double t) => Pos(x + (to.x - x) * t, y + (to.y - y) * t);
  Pos copy() => Pos(x, y);
  void set(Pos other) {
    x = other.x;
    y = other.y;
  }
}

// =============================================================================
// SIM PLAYER
// =============================================================================

class SimPlayer {
  final Player data;
  Pos pos;
  Pos moveTarget;
  Pos homeBase;
  bool isHome;
  String role;
  Map<String, int> stats;
  PlayerInstruction instruction;

  bool isPressing = false;
  int pressTimer = 0;
  bool isCornering = false;

  // Visual & marking state
  bool isPassShoot = false;
  int passShootTimer = 0;
  int playerIndex = 0; // 0=GK,1-2=DEF,3-4=MID,5-6=FWD
  SimPlayer? markTarget; // assigned man-marking target

  // Dribbling state
  bool isDribbling = false;
  int dribbleTimer = 0;

  // Corner trick support: when true, player shoots immediately on ball receipt
  bool shootOnReceive = false;

  // FM26-style smooth movement
  double vx = 0, vy = 0;
  // Stamina: 1.0 = fresh → 0.72 = tired late game
  double stamina = 1.0;

  SimPlayer({
    required this.data,
    required Pos startPos,
    required this.isHome,
    required this.role,
    PlayerInstruction? instruction,
  })  : pos = startPos.copy(),
        moveTarget = startPos.copy(),
        homeBase = startPos.copy(),
        stats = data.getFMStats(),
        instruction = instruction ?? PlayerInstruction();

  // Engine-scale stats (raw FM stats * 5 → 0-100 ballpark)
  int get shootStat => (stats['Şut'] ?? 10) * 5;
  int get passStat => (stats['Pas'] ?? 10) * 5;
  int get speedStat => (stats['Hız'] ?? 10) * 5;
  int get defStat => (stats['Defans'] ?? 10) * 5;
  int get dribbleStat => (stats['Dripling'] ?? 10) * 5;
  int get reflexStat => (stats['Refleks'] ?? 10) * 5;
}

// =============================================================================
// PLAYER MATCH INSIGHT
// =============================================================================

class _PlayerInsight {
  int passes = 0;
  int shots = 0;
  int shotsOnTarget = 0;
  int tackles = 0;
  int keyPasses = 0;
  int goals = 0;
  double rating = 6.5;

  void update({
    bool pass = false,
    bool shotOT = false,
    bool tackle = false,
    bool keyPass = false,
    bool goal = false,
    bool miss = false,
    bool badPass = false,
  }) {
    if (pass) {
      passes++;
      rating = (rating + 0.05).clamp(4.0, 10.0);
    }
    if (shotOT) {
      shots++;
      shotsOnTarget++;
      rating = (rating + 0.35).clamp(4.0, 10.0);
    }
    if (tackle) {
      tackles++;
      rating = (rating + 0.18).clamp(4.0, 10.0);
    }
    if (keyPass) {
      keyPasses++;
      rating = (rating + 0.28).clamp(4.0, 10.0);
    }
    if (goal) {
      goals++;
      rating = (rating + 1.2).clamp(4.0, 10.0);
    }
    if (miss) rating = (rating - 0.1).clamp(4.0, 10.0);
    if (badPass) rating = (rating - 0.15).clamp(4.0, 10.0);
  }

  String get ratingStr => rating.toStringAsFixed(1);

  Color get ratingColor {
    if (rating >= 9.0) return const Color(0xFF00E676);
    if (rating >= 8.0) return const Color(0xFF76FF03);
    if (rating >= 7.0) return const Color(0xFFFFD600);
    if (rating >= 6.0) return Colors.orange;
    if (rating >= 5.0) return Colors.deepOrange;
    return Colors.redAccent;
  }
}

// =============================================================================
// BALL
// =============================================================================

enum BallPhase { owned, passFlight, cornerDelay, free, shotFlight }

class Ball {
  Pos pos = Pos(0.5, 0.5);
  SimPlayer? owner;

  // Pass state
  SimPlayer? passTarget;
  Pos passFrom = Pos(0.5, 0.5);
  Pos passTo = Pos(0.5, 0.5);
  int passTicksTotal = 1;
  int passTicksRemaining = 0;

  BallPhase phase = BallPhase.owned;

  // Shot-flight velocity – enables realistic wall-bounce physics
  double vBallX = 0, vBallY = 0;
  bool shotBounced = false; // for log dedup
  bool isRocketShot = false; // wall-run diagonal rocket

  // Wall-run state
  bool isWallRunActive = false;
  SimPlayer? wallRunner;
  Pos wallRunTarget = Pos(0.5, 0.5);
  int wallRunCountdown = 0;
  int wallRunBlinkTimer = 0;

  // Wall-pull state (kanat duvara çekerek topu kendine alır)
  bool isWallPull = false;
  SimPlayer? wallPullRunner;
  int wallPullBouncesLeft = 0; // kalan sekme sayısı (1 veya 2)

  // Corner Wall Trick state – haxball köşe duvar triki
  bool isCornerTrick = false;
  SimPlayer? cornerTrickRunner;
  int cornerTrickPhase = 0; // 1=top duvara uçuş, 2=oyuncuya geri dönüş
  int cornerTrickDirection = 0; // -1=üst köşe (y→0), +1=alt köşe (y→1)

  // Shot-flight state
  bool shotWillGoal = false;
  bool shotOnTarget = false;
  SimPlayer? shotGk;
  String shotShooterName = '';
  bool shotIsHome = false;

  // Corner state
  bool cornerForHome = false;
  int cornerCountdown = 0;

  // Visual-only ball display offset (ball orbits just outside player)
  double ballDispDx = 0.0;
  double ballDispDy = 0.0;
}

// =============================================================================
// LOG
// =============================================================================

class LogEntry {
  final String msg;
  final Color color;
  final int minute;
  LogEntry(this.msg, this.color, this.minute);
}

// =============================================================================
// MATCH RESULT
// =============================================================================

class MatchResult {
  final int myGoals, oppGoals;
  final bool isWin, isDraw;
  final List<LogEntry> highlights;
  const MatchResult({
    required this.myGoals,
    required this.oppGoals,
    required this.isWin,
    required this.isDraw,
    required this.highlights,
  });
}

// =============================================================================
// MATCH ENGINE VIEW
// =============================================================================

class MatchEngineView extends StatefulWidget {
  final List<Player> myTeam;
  final List<Player> oppTeam;
  final TacticStyle myTactic;
  final TacticStyle oppTactic;
  final Map<int, PlayerInstruction> playerInstructions;
  final bool isPlayerTeamAway;
  final void Function(MatchResult) onMatchEnd;

  const MatchEngineView({
    super.key,
    required this.myTeam,
    required this.oppTeam,
    required this.onMatchEnd,
    this.myTactic = TacticStyle.tikiTaka,
    this.oppTactic = TacticStyle.tikiTaka,
    this.playerInstructions = const {},
    this.isPlayerTeamAway = true,
  });

  @override
  State<MatchEngineView> createState() => _MatchEngineViewState();
}

class _MatchEngineViewState extends State<MatchEngineView>
    with TickerProviderStateMixin {
  final _rng = Random();

  late Ball ball;
  late List<SimPlayer> homeTeam, awayTeam;

  int homeScore = 0, awayScore = 0;
  double matchMinute = 0;
  int tick = 0;
  bool isStarted = false;
  bool isGoal = false;
  bool isMatchOver = false;
  String goalCelebText = '';

  MatchSpeed speed = MatchSpeed.medium;
  Ticker? _ticker;
  Duration _lastFrameTime = Duration.zero;
  double _simAccumulator = 0.0;
  static const double _simTickInterval = 1.0 / 60.0; // 60 sim ticks/sec
  late AnimationController _goalAnim;
  List<LogEntry> logs = [];
  int _shotSlowMoTicks = 0;
  int _rocketFreezeTicks = 0;
  List<Pos> _ballTrail = [];

  // Foul / free-kick state
  bool _isFreeKick = false;
  bool _freeKickForHome = false;
  Pos _freeKickPos = Pos(0.5, 0.5);

  // Lane tracking – 0=top(y<0.35), 1=mid, 2=bottom(y>0.65)
  int _homeLane = 1;
  int _awayLane = 1;
  int _homeConsecLane = 0;
  int _awayConsecLane = 0;

  // Köşe duvar triki planlama (her maç en az 1, bazen 2-3)
  int _homeCornerTricksDone = 0, _awayCornerTricksDone = 0;
  int _homeCornerTricksMax = 1, _awayCornerTricksMax = 1;

  // Cached team power (0-100): recalculated at init
  double _homePower = 50;
  double _awayPower = 50;

  // ── LIVE MATCH STATS ──────────────────────────────────────────────────────
  int _homePossessionTicks = 0, _awayPossessionTicks = 0;
  int _homeShots = 0, _awayShots = 0;
  int _homeShotsOnTarget = 0, _awayShotsOnTarget = 0;
  int _homePassesAtt = 0, _awayPassesAtt = 0;
  int _homePassesCmpl = 0, _awayPassesCmpl = 0;
  int _homeCorners = 0, _awayCorners = 0;
  int _homeFouls = 0, _awayFouls = 0;
  int _homeYellows = 0, _awayYellows = 0;
  int _homeTackles = 0, _awayTackles = 0;

  // ── PER-PLAYER CARD TRACKING ──────────────────────────────────────────────
  final Map<String, int> _playerYellowCount = {};
  final Set<String> _redCardedPlayers = {};
  int _homeReds = 0, _awayReds = 0;

  // ── SCORE-REACTIVE AI: last tick a goal was scored by each side ──────────
  int _homeLastGoalTick = -1, _awayLastGoalTick = -1;

  // ── BALL STUCK DETECTION ─────────────────────────────────────────────────
  int _ballStuckTicks = 0;
  Pos _lastBallPos = Pos(0.5, 0.5);

  // ── GK SAVE ANIMATION ─────────────────────────────────────────────────────
  bool _gkSaveActive = false;
  SimPlayer? _gkSavingPlayer;
  int _gkSaveTimer = 0;

  // ── SHOT EFFECT ───────────────────────────────────────────────────────────
  bool _shootEffectActive = false;
  SimPlayer? _shootEffectPlayer;
  int _shootEffectTimer = 0;

  // ── SHOT PARTICLES ────────────────────────────────────────────────────────
  final List<_ShotParticle> _shotParticles = [];

  // ── MANAGER PANEL ─────────────────────────────────────────────────────────
  bool _panelOpen = false;
  int _panelTab = 0; // 0=stats 1=tactics 2=squad 3=analysis
  late AnimationController _panelAnim;

  // ── MID-MATCH ADJUSTMENTS ─────────────────────────────────────────────────
  TacticStyle? _liveHomeTactic, _liveAwayTactic;
  double _defLineVal = 0.5; // 0.0=deep block … 1.0=high line
  double _pressLineVal = 0.5; // 0.0=sit off   … 1.0=max press
  double _widthVal = 0.5; // 0.0=narrow    … 1.0=wide
  double _tempoVal = 0.5; // 0.0=slow      … 1.0=direct

  // ── SUBSTITUTIONS ─────────────────────────────────────────────────────────
  int _subsUsed = 0;
  final int _maxSubs = 5;
  SimPlayer? _subCandidate;
  final List<SimPlayer> _subbedPlayers = [];

  // ── PLAYER MATCH INSIGHTS ─────────────────────────────────────────────────
  final Map<String, _PlayerInsight> _insights = {};

  void _ensureInsight(SimPlayer p) =>
      _insights.putIfAbsent(p.data.name, () => _PlayerInsight());

  _PlayerInsight _insight(SimPlayer p) {
    _ensureInsight(p);
    return _insights[p.data.name]!;
  }

  @override
  void initState() {
    super.initState();
    _goalAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _panelAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _initGame();
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _goalAnim.dispose();
    _panelAnim.dispose();
    super.dispose();
  }

  // ─── INIT ───────────────────────────────────────────────────────────────────

  void _initGame() {
    ball = Ball();
    _lastBallPos = Pos(0.5, 0.5);
    _ballStuckTicks = 0;
    homeTeam = [];
    awayTeam = [];

    if (widget.isPlayerTeamAway) {
      _buildTeam(widget.oppTeam, homeTeam, true, widget.oppTactic, {});
      _buildTeam(widget.myTeam, awayTeam, false, widget.myTactic,
          widget.playerInstructions);
    } else {
      _buildTeam(widget.myTeam, homeTeam, true, widget.myTactic,
          widget.playerInstructions);
      _buildTeam(widget.oppTeam, awayTeam, false, widget.oppTactic, {});
    }

    _kickoff(homeTeam);
    _homePower = _calcTeamPower(homeTeam, _myTactic(true));
    _awayPower = _calcTeamPower(awayTeam, _myTactic(false));

    // Init live tactics and insights
    _liveHomeTactic =
        widget.isPlayerTeamAway ? widget.oppTactic : widget.myTactic;
    _liveAwayTactic =
        widget.isPlayerTeamAway ? widget.myTactic : widget.oppTactic;
    _insights.clear();
    _subbedPlayers.clear();
    _subsUsed = 0;
    _subCandidate = null;
    _homePossessionTicks = 0;
    _awayPossessionTicks = 0;
    _homeShots = 0;
    _awayShots = 0;
    _homeShotsOnTarget = 0;
    _awayShotsOnTarget = 0;
    _homePassesAtt = 0;
    _awayPassesAtt = 0;
    _homePassesCmpl = 0;
    _awayPassesCmpl = 0;
    _homeCorners = 0;
    _awayCorners = 0;
    _homeFouls = 0;
    _awayFouls = 0;
    _homeYellows = 0;
    _awayYellows = 0;
    _homeTackles = 0;
    _awayTackles = 0;
    _playerYellowCount.clear();
    _redCardedPlayers.clear();
    _homeReds = 0;
    _awayReds = 0;
    _homeLastGoalTick = -1;
    _awayLastGoalTick = -1;
    _homeCornerTricksDone = 0;
    _awayCornerTricksDone = 0;
    _homeCornerTricksMax = 1 + _rng.nextInt(2); // her maç 1 veya 2 tane
    _awayCornerTricksMax = 1 + _rng.nextInt(2);
    for (var p in [...homeTeam, ...awayTeam]) _ensureInsight(p);
  }

  double _calcTeamPower(List<SimPlayer> team, TacticStyle tac) {
    if (team.isEmpty) return 50;
    double avg = team.map((p) {
          var s = p.stats;
          return ((s['Şut'] ?? 10) +
                  (s['Pas'] ?? 10) +
                  (s['Hız'] ?? 10) +
                  (s['Defans'] ?? 10) +
                  (s['Dripling'] ?? 10) +
                  (s['Refleks'] ?? 10))
              .toDouble();
        }).reduce((a, b) => a + b) /
        team.length /
        6;
    // avg is on 1-20 scale → multiply to 0-100
    double power = avg * 5.0;
    // Tactic synergy bonus
    if (tac == TacticStyle.tikiTaka) power += 3;
    if (tac == TacticStyle.highPress) power += 2;
    if (tac == TacticStyle.gegen) power += 2;
    if (tac == TacticStyle.attack) power += 4;
    return power.clamp(20, 100);
  }

  void _buildTeam(
    List<Player> players,
    List<SimPlayer> target,
    bool isHome,
    TacticStyle tactic,
    Map<int, PlayerInstruction> instructions,
  ) {
    target.clear();

    // ── Formation 1-2-1-2-1 ─────────────────────────────────────────────────
    // Slots: GK(0)  DEF-L(1)  DEF-R(2)  CAM(3)  WING-L(4)  WING-R(5)  ST(6)
    // Sort: GK first → DEF → MID/CAM → FWD/WING/ST
    var sorted = List<Player>.from(players)
      ..sort((a, b) => _posScore(a.position).compareTo(_posScore(b.position)));

    // Base positions for home (attacking rightward → x toward 1.0)
    final baseX = [0.06, 0.21, 0.21, 0.50, 0.62, 0.62, 0.80];
    final baseY = [0.50, 0.24, 0.76, 0.50, 0.08, 0.92, 0.50];

    // Tactic depth adjustments
    double xBias = 0;
    if (tactic == TacticStyle.attack) xBias = 0.08;
    if (tactic == TacticStyle.defensive) xBias = -0.09;
    if (tactic == TacticStyle.counter) xBias = -0.06;
    if (tactic == TacticStyle.highPress) xBias = 0.11;
    if (tactic == TacticStyle.gegen) xBias = 0.04;

    for (int i = 0; i < min(sorted.length, 7); i++) {
      double bx = (isHome ? baseX[i] : 1.0 - baseX[i]);
      double by = baseY[i];

      if (i > 0) bx = (bx + (isHome ? xBias : -xBias)).clamp(0.05, 0.95);

      PlayerInstruction instr = (instructions[i] ?? PlayerInstruction()).copy();
      // stayWide on wingers pins them to the extreme touchline
      if (instr.stayWide && (i == 4 || i == 5)) {
        by = i == 4 ? 0.04 : 0.96;
      }

      // Role assignment: no central midfielders
      String role;
      if (i == 0) {
        role = 'GK';
      } else if (i < 3) {
        role = 'DEF';
      } else if (i == 3) {
        role = 'CAM'; // Ofansif orta saha
      } else if (i < 6) {
        role = 'WING'; // Left & right wingers – run all over
      } else {
        role = 'ST'; // Centre forward
      }

      target.add(SimPlayer(
        data: sorted[i],
        startPos: Pos(bx, by),
        isHome: isHome,
        role: role,
        instruction: instr,
      ));
      target.last.playerIndex = i;
    }
  }

  int _posScore(String pos) {
    if (pos.contains('GK')) return 0;
    if (pos.contains('DEF') ||
        pos.contains('CB') ||
        pos.contains('LB') ||
        pos.contains('RB')) return 1;
    if (pos.contains('MID') ||
        pos.contains('CDM') ||
        pos.contains('CAM') ||
        pos.contains('CM')) return 2;
    return 3;
  }

  void _kickoff(List<SimPlayer> byTeam) {
    // Tüm oyuncuları KENDI yarı sahalarına sıfırla (gerçek futbol santralı gibi)
    // Home (kırmızı) → x < 0.5 (sol yarı), Away (mavi) → x > 0.5 (sağ yarı)
    for (var p in [...homeTeam, ...awayTeam]) {
      double kx = p.isHome
          ? p.homeBase.x.clamp(0.04, 0.49) // home: kendi yarısında kal
          : p.homeBase.x.clamp(0.51, 0.96); // away: kendi yarısında kal
      p.pos = Pos(kx, p.homeBase.y);
      p.moveTarget = Pos(kx, p.homeBase.y);
      p.vx = 0;
      p.vy = 0;
      p.isPressing = false;
      p.pressTimer = 0;
      p.isCornering = false;
      p.isPassShoot = false;
      p.passShootTimer = 0;
      p.markTarget = null;
      p.isDribbling = false;
      p.dribbleTimer = 0;
      p.shootOnReceive = false;
    }

    // Reset ball to center
    ball.phase = BallPhase.owned;
    ball.passTarget = null;
    ball.pos = Pos(0.5, 0.5);
    ball.shotWillGoal = false;
    ball.shotOnTarget = false;
    ball.shotGk = null;
    ball.shotShooterName = '';
    ball.shotIsHome = false;
    ball.isRocketShot = false;
    ball.isWallRunActive = false;
    ball.wallRunner = null;
    ball.wallRunCountdown = 0;
    ball.wallRunBlinkTimer = 0;
    ball.isWallPull = false;
    ball.wallPullRunner = null;
    ball.wallPullBouncesLeft = 0;
    ball.isCornerTrick = false;
    ball.cornerTrickRunner = null;
    ball.cornerTrickPhase = 0;
    ball.cornerTrickDirection = 0;
    _shotSlowMoTicks = 0;
    _rocketFreezeTicks = 0;
    _shotParticles.clear();

    SimPlayer kicker = byTeam.firstWhere(
      (p) => p.role == 'ST' || p.role == 'WING' || p.role == 'FWD',
      orElse: () => byTeam.last,
    );
    kicker.pos.set(Pos(0.5, 0.5));
    // Give kicker an immediate forward target so it doesn't freeze at centre
    bool goRightKick = byTeam.first.isHome;
    kicker.moveTarget.set(Pos(
      (0.5 + (goRightKick ? 0.09 : -0.09)).clamp(0.10, 0.90),
      0.38 + _rng.nextDouble() * 0.24,
    ));
    ball.owner = kicker;

    // Gerçek futbol santralı: kanatlar ve forvet hemen ileri koşu başlatır,
    // rakip defans da bu koşucuları takip etmek üzere hazır pozisyon alır.
    bool goRight = byTeam.first.isHome;
    for (var p in byTeam) {
      if (p == kicker) continue;
      if (p.role == 'WING') {
        bool isLeftWing = p.playerIndex == 4;
        double runX = (goRight
                ? 0.60 + _rng.nextDouble() * 0.22
                : 0.18 + _rng.nextDouble() * 0.22)
            .clamp(0.05, 0.95);
        double runY = isLeftWing
            ? 0.05 + _rng.nextDouble() * 0.10
            : 0.85 + _rng.nextDouble() * 0.10;
        p.moveTarget = Pos(runX, runY);
      } else if (p.role == 'ST' || p.role == 'FWD') {
        double runX = (goRight
                ? 0.65 + _rng.nextDouble() * 0.18
                : 0.17 + _rng.nextDouble() * 0.18)
            .clamp(0.05, 0.95);
        p.moveTarget = Pos(runX, 0.38 + _rng.nextDouble() * 0.24);
      }
    }

    // Rakip defans, ileri kaçan oyuncuları tutmak için öne pozisyon alır
    var oppTeamList = goRight ? awayTeam : homeTeam;
    for (var p in oppTeamList) {
      if (p.role == 'DEF') {
        // Defansçılar kendi yarısında rakip forvetlere karşı barikat kurar
        double guardX = goRight
            ? (0.60 + _rng.nextDouble() * 0.12).clamp(0.51, 0.80)
            : (0.28 + _rng.nextDouble() * 0.12).clamp(0.20, 0.49);
        p.moveTarget = Pos(
            guardX,
            p.playerIndex == 1
                ? 0.28 + _rng.nextDouble() * 0.10
                : 0.62 + _rng.nextDouble() * 0.10);
      }
    }

    _log('🎾 Santral: ${kicker.data.name}', Colors.greenAccent);
  }

  // ─── GAME LOOP ──────────────────────────────────────────────────────────────

  void _startMatch() {
    if (isStarted) return;
    isStarted = true;
    _lastFrameTime = Duration.zero;
    _simAccumulator = 0.0;
    _ticker = createTicker(_onFrame);
    _ticker!.start();
  }

  /// Called every vsync frame – runs simulation at fixed 60 Hz,
  /// renders at the display's native refresh rate (uncapped).
  void _onFrame(Duration elapsed) {
    if (!mounted || isMatchOver) return;

    // Delta time in seconds; skip the very first frame to avoid spike
    double dt = (_lastFrameTime == Duration.zero)
        ? 0.0
        : (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = elapsed;

    // During goal celebration: keep rendering for animation but don't run sim
    if (isGoal) {
      _simAccumulator = 0.0; // drain so there's no burst after celebration ends
      setState(() {}); // keep goal overlay & animation alive
      return;
    }

    // Rocket freeze: pause simulation for dramatic freeze-frame effect
    if (_rocketFreezeTicks > 0) {
      _rocketFreezeTicks--;
      setState(() {}); // keep rendering, no sim step
      return;
    }

    // Clamp dt to avoid spiral-of-death if window is hidden/unfocused
    _simAccumulator += dt.clamp(0.0, 0.05);

    bool simRan = false;
    while (_simAccumulator >= _simTickInterval) {
      _simAccumulator -= _simTickInterval;
      _onTick();
      simRan = true;
      if (isMatchOver || isGoal) break;
    }

    // Render every frame regardless of whether simulation stepped
    if (simRan) setState(() {});
  }

  void _onTick() {
    tick++;
    matchMinute = (tick / speed.totalTicks * 90.0).clamp(0, 90);

    // ─ Update shot particles ─
    _shotParticles.removeWhere((sp) => sp.life <= 0);
    for (var sp in _shotParticles) {
      sp.x += sp.vx;
      sp.y += sp.vy;
      sp.vy += 0.00018; // micro gravity
      sp.life -= 0.040;
    }

    // ─ GK save animation countdown ─
    if (_gkSaveTimer > 0) {
      _gkSaveTimer--;
      if (_gkSaveTimer == 0) {
        _gkSaveActive = false;
        _gkSavingPlayer = null;
      }
    }

    if (_shootEffectTimer > 0) {
      _shootEffectTimer--;
      if (_shootEffectTimer == 0) {
        _shootEffectActive = false;
        _shootEffectPlayer = null;
      }
    }

    if (!isGoal) _simulate();

    // Ball-stuck detection: if ball barely moves for >1.5 real-seconds → force handover
    // Skip during pass / shot flights – ball IS moving along its trajectory
    if (!isGoal &&
        ball.phase != BallPhase.cornerDelay &&
        ball.phase != BallPhase.shotFlight &&
        ball.phase != BallPhase.passFlight) {
      if (ball.pos.dist(_lastBallPos) < 0.003) {
        _ballStuckTicks++;
        // ~90 ticks = 1.5 s at 60 Hz sim rate; tightened for fast mode, relaxed for slow
        int stuckLimit = speed == MatchSpeed.slow
            ? 72
            : speed == MatchSpeed.fast
                ? 108
                : 90;
        if (_ballStuckTicks > stuckLimit) {
          _forcePassToBall();
          _ballStuckTicks = 0;
        }
      } else {
        _ballStuckTicks = 0;
      }
      _lastBallPos = ball.pos.copy();
    }

    // Possession tracking
    if (ball.owner != null && !isGoal) {
      if (ball.owner!.isHome)
        _homePossessionTicks++;
      else
        _awayPossessionTicks++;
    }

    // Ball trail – always track for smooth FM26 motion blur
    if (!isGoal && ball.phase != BallPhase.cornerDelay) {
      // Use visual display offset during owned phase so trail follows orbiting ball
      Pos trailPos = (ball.owner != null && ball.phase == BallPhase.owned)
          ? Pos(
              (ball.pos.x + ball.ballDispDx).clamp(0.01, 0.99),
              (ball.pos.y + ball.ballDispDy).clamp(0.02, 0.98),
            )
          : ball.pos.copy();
      _ballTrail.add(trailPos);
      if (_ballTrail.length > 16) _ballTrail.removeAt(0);
    } else if (isGoal) {
      _ballTrail.clear();
    }

    if (tick >= speed.totalTicks && !isMatchOver) {
      _ticker?.stop();
      _endMatch();
    }
  }

  // ─── SIMULATION ─────────────────────────────────────────────────────────────

  void _simulate() {
    // ── Pre-sync: keep ball.pos glued to owner BEFORE any phase logic runs ──
    // This guarantees every part of _simulate() reads the correct ball position.
    if (ball.owner != null && ball.phase == BallPhase.owned) {
      ball.pos.set(ball.owner!.pos);
    }

    switch (ball.phase) {
      case BallPhase.owned:
        _ownedPhase();
        break;
      case BallPhase.passFlight:
        _passFlightPhase();
        break;
      case BallPhase.cornerDelay:
        _cornerDelayPhase();
        break;
      case BallPhase.free:
        _freeBallPhase();
        break;
      case BallPhase.shotFlight:
        _shotFlightPhase();
        break;
    }

    // Move all non-owner players; tick visual timers
    for (var p in [...homeTeam, ...awayTeam]) {
      if (p.passShootTimer > 0) {
        p.passShootTimer--;
        if (p.passShootTimer == 0) p.isPassShoot = false;
      }
      if (p != ball.owner) {
        _updateMovementTarget(p);
        _moveToward(p);
      }
    }

    // Stamina drain: each player tires across the match
    if (tick % 90 == 0) {
      for (var p in [...homeTeam, ...awayTeam]) {
        double phy = (p.stats['Fizik'] ?? 10).toDouble();
        double drainRate = 0.0012 * (1.2 - phy * 0.007).clamp(0.3, 1.2);
        p.stamina = max(0.72, p.stamina - drainRate);
      }
    }

    // Owner moves toward their current target; ball stays glued to owner.
    // We re-sync here so the renderer always reads the freshest pos.
    if (ball.owner != null && ball.phase == BallPhase.owned) {
      _moveToward(ball.owner!);
      ball.pos.set(ball.owner!.pos);
      // ── Visual orbit offset: ball position relative to player ──
      var ow = ball.owner!;
      double velLen = sqrt(ow.vx * ow.vx + ow.vy * ow.vy);
      double orbitAngle;
      double orbitR;
      if (ow.isDribbling) {
        // Sürüş: hız vektörü beklenmeden doğrudan hareket yönüne bak — vx/vy
        // her zaman güncelleniyor bu admda (moveToward önce çalıştı)
        double dvx = ow.vx;
        double dvy = ow.vy;
        double dvLen = sqrt(dvx * dvx + dvy * dvy);
        if (dvLen > 0.00008) {
          orbitAngle = atan2(dvy, dvx);
        } else {
          // Oyuncu henuz kalkmadı: hedef yönünden tahmin et
          double tdx = ow.moveTarget.x - ow.pos.x;
          double tdy = ow.moveTarget.y - ow.pos.y;
          orbitAngle = atan2(tdy, tdx);
        }
        orbitR = 0.048;
      } else if (velLen > 0.00025) {
        // Moving normally: slight forward offset with minimal sway
        orbitAngle = atan2(ow.vy, ow.vx) + sin(tick * 0.18) * 0.18;
        orbitR = 0.024;
      } else {
        // Standing still: slow idle orbit
        orbitAngle = tick * 0.07 + ow.playerIndex * 1.31;
        orbitR = 0.018;
      }
      ball.ballDispDx = cos(orbitAngle) * orbitR;
      ball.ballDispDy = sin(orbitAngle) * orbitR;
    } else {
      ball.ballDispDx = 0.0;
      ball.ballDispDy = 0.0;
    }
  }

  // ─── OWNED PHASE ────────────────────────────────────────────────────────────

  void _ownedPhase() {
    // ─ Wall-run active: route to dedicated handler ─
    if (ball.isWallRunActive) {
      _wallRunPhase();
      return;
    }
    var owner = ball.owner;
    if (owner == null) {
      ball.phase = BallPhase.free;
      return;
    }

    // ── İÇ PAS ALINDI: kutudaysa anında şut, değilse içeri sprint ──────────
    if (owner.shootOnReceive) {
      owner.shootOnReceive = false;
      var _oppForShoot = owner.isHome ? awayTeam : homeTeam;
      var _gkForShoot = _oppForShoot.firstWhereOrNull((pl) => pl.role == 'GK');
      if (_gkForShoot != null) {
        bool _nowInBox = owner.isHome ? owner.pos.x > 0.73 : owner.pos.x < 0.27;
        bool _goodAngle = owner.pos.y > 0.23 && owner.pos.y < 0.77;
        if (_nowInBox && _goodAngle) {
          _log(
              '💥 ${owner.data.name} gelişine VURDU!', const Color(0xFFFFD600));
          _shoot(owner, _gkForShoot);
        } else {
          // Kutu dışında – önce kaleye sprint at, sonra inBox logic devreye girer
          bool _gr = owner.isHome;
          owner.moveTarget = Pos(
            (_gr
                    ? 0.80 + _rng.nextDouble() * 0.10
                    : 0.10 + _rng.nextDouble() * 0.10)
                .clamp(0.05, 0.95),
            (owner.pos.y * 0.55 + 0.50 * 0.45).clamp(0.10, 0.90),
          );
          owner.isDribbling = true;
          owner.dribbleTimer = 14 + _rng.nextInt(10);
          _log('🏃 ${owner.data.name} kutuya koşuyor!', Colors.orangeAccent);
        }
        return;
      }
    }

    bool goRight = owner.isHome;
    double goalX = goRight ? 0.97 : 0.03;
    var opp = owner.isHome ? awayTeam : homeTeam;
    var team = owner.isHome ? homeTeam : awayTeam;
    var gk = opp.firstWhere((p) => p.role == 'GK', orElse: () => opp.first);

    // ─── SKOR-REAKTİF AI: geriden gelen takım daha agresif oynar ─────────────
    {
      int myScore = owner.isHome ? homeScore : awayScore;
      int oppScore = owner.isHome ? awayScore : homeScore;
      int diff = myScore - oppScore; // >0 önde, <0 geride
      bool ownerGoRight = owner.isHome;

      if (diff < 0 && owner.role != 'GK' && owner.role != 'DEF') {
        // Gerideyken FWD/WING/CAM daha ileri konumlanır
        double pushFwd = (-diff * 0.04).clamp(0.0, 0.10);
        bool inOwnSide = ownerGoRight ? owner.pos.x < 0.52 : owner.pos.x > 0.48;
        if (inOwnSide && _rng.nextInt(100) < 50) {
          owner.moveTarget = Pos(
            (owner.pos.x + (ownerGoRight ? 0.10 + pushFwd : -0.10 - pushFwd))
                .clamp(0.04, 0.96),
            (owner.pos.y * 0.65 + 0.5 * 0.35).clamp(0.05, 0.95),
          );
        }
      }
      // 2+ fark gerideyken 75.+ dakikada çaresiz hücum
      if (diff <= -2 &&
          matchMinute > 75 &&
          owner.role != 'GK' &&
          _rng.nextInt(100) < 40) {
        _log('🔴 Son dakika baskısı! ${owner.data.name} ileri!',
            Colors.redAccent);
        owner.moveTarget = Pos(
          (ownerGoRight
                  ? 0.68 + _rng.nextDouble() * 0.24
                  : 0.08 + _rng.nextDouble() * 0.24)
              .clamp(0.04, 0.96),
          0.18 + _rng.nextDouble() * 0.64,
        );
      }
      // 2+ fark önde iken savunma bloğu: DEF daha geri çekilir
      if (diff >= 2 && owner.role == 'DEF' && _rng.nextInt(100) < 35) {
        double retreatX = ownerGoRight
            ? (owner.homeBase.x - 0.05).clamp(0.04, 0.50)
            : (owner.homeBase.x + 0.05).clamp(0.50, 0.96);
        owner.moveTarget = Pos(retreatX, owner.homeBase.y);
      }
    }

    // ── Lane tracking: update which vertical zone owner is in ──
    int curLane = owner.pos.y < 0.35
        ? 0
        : owner.pos.y > 0.65
            ? 2
            : 1;
    if (owner.isHome) {
      if (curLane == _homeLane)
        _homeConsecLane++;
      else {
        _homeLane = curLane;
        _homeConsecLane = 0;
      }
    } else {
      if (curLane == _awayLane)
        _awayConsecLane++;
      else {
        _awayLane = curLane;
        _awayConsecLane = 0;
      }
    }

    // ── OWNER MOVEMENT: FM26-style – reads the field ──
    double lookX = (owner.pos.x + (goRight ? 0.14 : -0.14)).clamp(0.04, 0.96);
    var blocking = opp
        .where((o) =>
            (o.pos.x - lookX).abs() < 0.12 &&
            (o.pos.y - owner.pos.y).abs() < 0.14)
        .toList();

    if (blocking.isEmpty && owner.role != 'GK') {
      bool _isAtk =
          owner.role == 'ST' || owner.role == 'FWD' || owner.role == 'WING';
      bool _isMid = owner.role == 'CAM' || owner.role == 'MID';
      // Increased fwdStep so ball carrier drives forward more aggressively
      double fwdStep = owner.role == 'DEF'
          ? 0.014
          : _isAtk
              ? 0.028
              : _isMid
                  ? 0.023
                  : 0.018;
      double sway = sin(tick * 0.12 + owner.playerIndex * 1.3) * 0.022;
      // Pull attackers toward penalty area centre when not yet in the box
      bool _inBoxNow = goRight ? owner.pos.x > 0.76 : owner.pos.x < 0.24;
      double targetY = owner.pos.y + sway;
      if (_isAtk && !_inBoxNow) {
        if (owner.role == 'WING') {
          // Kanatlar kenarda kalmalı – kendi çizgisine çekim (bencil taşıma)
          targetY = targetY * 0.72 + owner.homeBase.y * 0.28;
        } else {
          // ST/FWD/CAM: ceza alanı ortasına doğru çekim
          targetY = targetY * 0.65 + 0.50 * 0.35;
        }
      }
      owner.moveTarget = Pos(
        (owner.pos.x + (goRight ? fwdStep : -fwdStep)).clamp(0.01, 0.99),
        targetY.clamp(0.04, 0.96),
      );
    } else {
      // Engel var – her 16 tickte bir taraf seçer ve o yönden yavaşça geçer.
      // Periyodik taraf seçimi: ani sağ-sol salmalar tamamen ortadan kalkar.
      int _eSide = ((tick ~/ 16) + owner.playerIndex) % 2;
      double _avY = _eSide == 0
          ? (owner.pos.y - 0.055).clamp(0.04, 0.96)
          : (owner.pos.y + 0.055).clamp(0.04, 0.96);
      owner.moveTarget = Pos(
        (owner.pos.x + (goRight ? 0.005 : -0.005)).clamp(0.04, 0.96),
        (owner.moveTarget.y * 0.68 + _avY * 0.32).clamp(0.04, 0.96),
      );
    }

    // Yakın baskı yapanlar
    var pressers = opp.where((o) => o.pos.dist(owner.pos) < 0.12).toList();

    // ── GK DAĞITIMI – büyük çoğunlukla uzun top ──
    if (owner.role == 'GK') {
      owner.moveTarget.set(owner.homeBase);
      int gkPassFreq = _scaledPassEvery(8);
      // Baskı varsa beklemeden anında dağıt
      if (tick % gkPassFreq == 0 || pressers.isNotEmpty) {
        // 75% uzun top: ST veya WING'e doğrudan servis
        if (_rng.nextInt(100) < 75) {
          var fwds = team
              .where(
                  (p) => p.role == 'ST' || p.role == 'WING' || p.role == 'FWD')
              .toList();
          if (fwds.isNotEmpty) {
            // En açık ve en ileride olanı seç
            fwds.sort((a, b) =>
                (owner.isHome ? b.pos.x - a.pos.x : a.pos.x - b.pos.x)
                    .toDouble()
                    .compareTo(0));
            var fwdTarget = fwds.first;
            _log('🦵 ${owner.data.name} uzun top! → ${fwdTarget.data.name}',
                Colors.greenAccent);
            _execPass(owner, fwdTarget);
            return;
          }
        }
        // 25%: kısa ama mutlaka ileriye oyna
        _tryPass(owner, team, preferFwd: true);
      }
      return;
    }

    TacticStyle myTac = _myTactic(owner.isHome);

    // ── 1v1 KALECİ: defans aşıldıysa şut (derin rakip sahasında) ──
    if (!owner.instruction.passOnly && owner.role != 'GK') {
      bool inDeepAtt = goRight ? owner.pos.x > 0.62 : owner.pos.x < 0.38;
      // Kanattan köşeye gidiyorsa bu erken şutu atla
      bool _wingHeadingCorner =
          owner.role == 'WING' && (owner.pos.y < 0.22 || owner.pos.y > 0.78);
      if (inDeepAtt && !_wingHeadingCorner) {
        // Kendi ile kale arasında rakip DEF var mı?
        bool noDefBetween = opp
            .where((o) =>
                o.role == 'DEF' &&
                (goRight
                    ? o.pos.x > owner.pos.x - 0.04
                    : o.pos.x < owner.pos.x + 0.04) &&
                o.pos.dist(owner.pos) < 0.32)
            .isEmpty;
        if (noDefBetween) {
          _shoot(owner, gk);
          return;
        }
      }
    }

    // ── KENDİ YARISINDA HIZLI ÇIKIŞ: kısa pas döngüsünü önle ──
    bool inOwnHalf = goRight ? owner.pos.x < 0.50 : owner.pos.x > 0.50;
    if (inOwnHalf && owner.role != 'GK') {
      // Baskı varsa → derhal uzun top veya ileri pas
      if (pressers.isNotEmpty) {
        var fwds = team
            .where((t) =>
                (t.role == 'ST' || t.role == 'WING' || t.role == 'FWD') &&
                (goRight ? t.pos.x > 0.45 : t.pos.x < 0.55))
            .toList();
        if (fwds.isNotEmpty) {
          fwds.sort((a, b) => (goRight ? b.pos.x - a.pos.x : a.pos.x - b.pos.x)
              .toDouble()
              .compareTo(0));
          _log('⚡ ${owner.data.name} tahliye!', Colors.orangeAccent);
          _execPass(owner, fwds.first);
          return;
        }
        _tryPass(owner, team, preferFwd: true);
        return;
      }
      // Baskı yoksa kendi sahasında topu sürerek ilerliyorsun: nadiren pas
      if (tick % _scaledPassEvery(12) == 0) {
        if (_tryThroughPass(owner, team)) return;
        _tryPass(owner, team, preferFwd: true);
        return;
      }
    }

    // ── WING KÖŞE YAKLAŞIMI: touchline’da rakip sahasındayken köşeye zorla dribble ──
    if (owner.role == 'WING' && !owner.instruction.passOnly) {
      bool _wingInAttHalf = goRight ? owner.pos.x > 0.50 : owner.pos.x < 0.50;
      bool _wingOnLine = owner.pos.y < 0.22 || owner.pos.y > 0.78;
      bool _wingAtCorner = goRight ? owner.pos.x > 0.76 : owner.pos.x < 0.24;
      if (_wingInAttHalf &&
          _wingOnLine &&
          !_wingAtCorner &&
          pressers.length < 2) {
        double _cx = (owner.pos.x + (goRight ? 0.09 : -0.09)).clamp(0.04, 0.96);
        double _cy = owner.pos.y < 0.5
            ? owner.pos.y.clamp(0.04, 0.18)
            : owner.pos.y.clamp(0.82, 0.96);
        owner.moveTarget = Pos(_cx, _cy);
        if (!owner.isDribbling) {
          owner.isDribbling = true;
          owner.dribbleTimer = 30 + _rng.nextInt(20);
          _log(
              '🏃 ${owner.data.name} köşeye sürüyor!', const Color(0xFF00BCD4));
        }
        return;
      }
    }

    // ── DUVAR PAS: sadece RAKIP sahasında, kenar çizgisine yakınken içe pas ──
    bool nearSideWall = owner.pos.y < 0.08 || owner.pos.y > 0.92;
    bool notInBox = goRight ? owner.pos.x < 0.78 : owner.pos.x > 0.22;
    bool inOwnHalfForWall = goRight ? owner.pos.x < 0.50 : owner.pos.x > 0.50;
    if (nearSideWall &&
        notInBox &&
        !inOwnHalfForWall && // kendi sahasında duvar pas yok
        owner.role != 'WING' && // kanat bu blokla köşe gidişini kaybetmez
        pressers.isEmpty &&
        _rng.nextInt(100) < 35) {
      var closeMates = team
          .where((t) =>
              t != owner && t.role != 'GK' && t.pos.dist(owner.pos) < 0.30)
          .toList();
      if (closeMates.isNotEmpty) {
        closeMates.sort(
            (a, b) => a.pos.dist(owner.pos).compareTo(b.pos.dist(owner.pos)));
        _log('🧱 ${owner.data.name} duvara oynadı!', Colors.tealAccent);
        _execPass(owner, closeMates.first);
        return;
      }
    }

    // ── CAM KOMBINASYON: rakip yarısında ise WING veya ST'ye ara pas ──
    if (owner.role == 'CAM') {
      bool inOppHalf = goRight ? owner.pos.x > 0.50 : owner.pos.x < 0.50;
      if (inOppHalf && !owner.instruction.passOnly && _rng.nextInt(100) < 50) {
        if (_tryThroughPass(owner, team)) return;
        // Prefer WING or ST in advanced positions
        var atk = team
            .where((t) =>
                (t.role == 'WING' || t.role == 'ST' || t.role == 'FWD') &&
                (goRight ? t.pos.x > owner.pos.x : t.pos.x < owner.pos.x))
            .toList();
        if (atk.isNotEmpty) {
          atk.sort((a, b) =>
              (goRight ? b.pos.x - a.pos.x : a.pos.x - b.pos.x).toInt());
          _execPass(owner, atk.first);
          return;
        }
      }
    }

    // ── KÖŞE SERVİSİ: topu rakip köşedeki kanada ilet (trick planlandıysa) ──
    if (owner.role != 'GK' && !owner.instruction.passOnly) {
      int _tricksLeft = owner.isHome
          ? (_homeCornerTricksMax - _homeCornerTricksDone)
          : (_awayCornerTricksMax - _awayCornerTricksDone);
      bool _inOffHalf = goRight ? owner.pos.x > 0.46 : owner.pos.x < 0.54;
      if (_tricksLeft > 0 && _inOffHalf && !ball.isCornerTrick) {
        // Köşe koridorunda (touchline boyunca) bekleyen/ilerleyen WING var mı?
        var _cornerWing = team.firstWhereOrNull((t) =>
            t != owner &&
            t.role == 'WING' &&
            (goRight ? t.pos.x > 0.60 : t.pos.x < 0.40) &&
            (t.pos.y < 0.22 || t.pos.y > 0.78) &&
            opp.every((o) => o.pos.dist(t.pos) > 0.12));
        if (_cornerWing != null && _rng.nextInt(100) < 68) {
          _log(
              '📢 ${owner.data.name} → kanat koridoru! (${_cornerWing.data.name})',
              const Color(0xFF40C4FF));
          _execPass(owner, _cornerWing);
          return;
        }
        // Kanat henüz koridorda değil ama yolda → öne pas at, koştur
        var _approachWing = team.firstWhereOrNull((t) =>
            t != owner &&
            t.role == 'WING' &&
            (goRight ? t.pos.x > 0.50 : t.pos.x < 0.50) &&
            (t.pos.y < 0.28 || t.pos.y > 0.72) &&
            opp.every((o) => o.pos.dist(t.pos) > 0.16));
        if (_approachWing != null && _rng.nextInt(100) < 42) {
          _log(
              '📡 ${owner.data.name} → kanada yönlendirme! (${_approachWing.data.name})',
              const Color(0xFF0091EA));
          _execPass(owner, _approachWing);
          return;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ── KANAT KARAR AĞACI (HaxBall gerçekçi kanat oyunu) ──────────────────
    // Öncelik sırası:
    //  1) Byline cut-back → ST/CAM anında şut (shootOnReceive)
    //  2) Çok derin + touchline → iç pas (%74) > kutu pas (%52) > köşe triki (%18)
    //  3) Final third touchline → erkenden iç pas (%48) veya içe kesme (%28)
    //  4) Duvar çekme mid-range (nadir %18)
    //  5) Duvar roketi: önce iç pas (%60), sonra rocket (%55)
    //  6) Köşe sürüş yaklaşımı → %36 içe kes / %64 touchline devam
    //  7) Çapraz içe kesilme (mid-wide, pressers.isEmpty)
    // ─────────────────────────────────────────────────────────────────────────
    if (owner.role == 'WING') {
      bool _onLine = owner.pos.y < 0.22 || owner.pos.y > 0.78;
      bool _huggingLine = owner.pos.y < 0.20 || owner.pos.y > 0.80;
      bool _veryDeep = goRight ? owner.pos.x > 0.76 : owner.pos.x < 0.24;
      bool _finalThird = goRight ? owner.pos.x > 0.68 : owner.pos.x < 0.32;
      bool _midApproach = goRight
          ? (owner.pos.x > 0.58 && owner.pos.x < 0.76)
          : (owner.pos.x < 0.42 && owner.pos.x > 0.24);

      // ── 1. BYLINE CUT-BACK ────────────────────────────────────────────────
      bool nearByline = goRight ? owner.pos.x > 0.82 : owner.pos.x < 0.18;
      if (nearByline && !owner.instruction.passOnly) {
        var cbTargets = team
            .where((t) =>
                (t.role == 'ST' || t.role == 'CAM' || t.role == 'FWD') &&
                (goRight ? t.pos.x > 0.66 : t.pos.x < 0.34) &&
                t.pos.y > 0.22 &&
                t.pos.y < 0.78)
            .toList();
        if (cbTargets.isNotEmpty && _rng.nextInt(100) < 82) {
          cbTargets.sort(
              (a, b) => a.pos.dist(owner.pos).compareTo(b.pos.dist(owner.pos)));
          var _cb = cbTargets.first;
          _cb.shootOnReceive = true;
          _log('🔄 ${owner.data.name} byline geri pas! → ${_cb.data.name}',
              Colors.cyanAccent);
          _execPass(owner, _cb);
          return;
        }
      }

      // ── 2. ÇOK DERİN + TOUCHLINE: iç pas > kutu pas > köşe triki ─────────
      if (_veryDeep &&
          _onLine &&
          pressers.isEmpty &&
          !owner.instruction.passOnly) {
        // Ön.1 – açık iç oyuncuya direkt iç pas (%74)
        var _innerCut = team.firstWhereOrNull((t) =>
            t != owner &&
            (t.role == 'CAM' || t.role == 'ST' || t.role == 'FWD') &&
            (goRight ? t.pos.x > 0.60 : t.pos.x < 0.40) &&
            t.pos.y > 0.24 &&
            t.pos.y < 0.76 &&
            opp.every((o) => o.pos.dist(t.pos) > 0.12));
        if (_innerCut != null && _rng.nextInt(100) < 74) {
          _innerCut.shootOnReceive = true;
          _log(
              '⚡ ${owner.data.name} → ${_innerCut.data.name} iç pas, gelişine vur!',
              const Color(0xFFFFD600));
          _execPass(owner, _innerCut);
          return;
        }
        // Ön.2 – kutu içinde herhangi açık oyuncu (%52)
        var _boxMate = team.firstWhereOrNull((t) =>
            t != owner &&
            t.role != 'GK' &&
            (goRight ? t.pos.x > 0.68 : t.pos.x < 0.32) &&
            t.pos.y > 0.22 &&
            t.pos.y < 0.78 &&
            opp.every((o) => o.pos.dist(t.pos) > 0.11));
        if (_boxMate != null && _rng.nextInt(100) < 52) {
          _boxMate.shootOnReceive = (_boxMate.role == 'ST' ||
              _boxMate.role == 'CAM' ||
              _boxMate.role == 'FWD');
          _log('📩 ${owner.data.name} → ${_boxMate.data.name} kutu içi pas!',
              Colors.orangeAccent);
          _execPass(owner, _boxMate);
          return;
        }
        // Ön.3 – köşe triki son çare (%18)
        int _tLeft = owner.isHome
            ? (_homeCornerTricksMax - _homeCornerTricksDone)
            : (_awayCornerTricksMax - _awayCornerTricksDone);
        if (_tLeft > 0 &&
            !ball.isCornerTrick &&
            !ball.isWallRunActive &&
            !ball.isWallPull &&
            _rng.nextInt(100) < 18) {
          _startCornerTrick(owner);
          return;
        }
        // Ön.4 – pas seçeneği yoksa geri dön
        if (_tryPass(owner, team, preferFwd: false)) return;
      }

      // ── 3. FINAL THIRD TOUCHLINE: erkenden iç pas veya içe kesme ──────────
      if (_finalThird &&
          _onLine &&
          !_veryDeep &&
          pressers.isEmpty &&
          !owner.instruction.passOnly) {
        var _earlyInner = team.firstWhereOrNull((t) =>
            t != owner &&
            (t.role == 'CAM' || t.role == 'ST' || t.role == 'FWD') &&
            (goRight ? t.pos.x > 0.60 : t.pos.x < 0.40) &&
            t.pos.y > 0.27 &&
            t.pos.y < 0.73 &&
            opp.every((o) => o.pos.dist(t.pos) > 0.14));
        if (_earlyInner != null && _rng.nextInt(100) < 48) {
          _earlyInner.shootOnReceive = true;
          _log(
              '↪ ${owner.data.name} → ${_earlyInner.data.name} final third iç pas!',
              const Color(0xFFFFD600));
          _execPass(owner, _earlyInner);
          return;
        }
        // %28: içe keserek ceza alanı girişine hücum
        if (_rng.nextInt(100) < 28 && !owner.isDribbling) {
          owner.isDribbling = true;
          owner.dribbleTimer = 16 + _rng.nextInt(12);
          owner.moveTarget = Pos(
            (goRight
                    ? 0.78 + _rng.nextDouble() * 0.09
                    : 0.13 + _rng.nextDouble() * 0.09)
                .clamp(0.04, 0.96),
            owner.pos.y < 0.5
                ? 0.28 + _rng.nextDouble() * 0.20
                : 0.52 + _rng.nextDouble() * 0.20,
          );
          _log('↙ ${owner.data.name} içe kesiyor!', Colors.cyanAccent);
          return;
        }
      }

      // ── 4. DUVAR ÇEKMESİ: mid-range duvara yakın (nadir) ─────────────────
      bool wingNearSide = owner.pos.y < 0.17 || owner.pos.y > 0.83;
      bool wingNotTooDeep = goRight ? owner.pos.x < 0.70 : owner.pos.x > 0.30;
      if (wingNearSide &&
          wingNotTooDeep &&
          pressers.isEmpty &&
          !ball.isWallRunActive &&
          !ball.isWallPull &&
          !owner.instruction.passOnly &&
          _rng.nextInt(100) < 18) {
        _startWallPull(owner);
        return;
      }

      // ── 5. DUVAR ROKETİ: derin + duvarda – önce iç pas, sonra rocket ──────
      bool wingDeepOpp = goRight ? owner.pos.x > 0.64 : owner.pos.x < 0.36;
      bool wingOnWall = owner.pos.y < 0.08 || owner.pos.y > 0.92;
      if (wingDeepOpp &&
          wingOnWall &&
          pressers.isEmpty &&
          !ball.isWallRunActive &&
          !owner.instruction.passOnly) {
        var _rocketInner = team.firstWhereOrNull((t) =>
            t != owner &&
            (t.role == 'CAM' || t.role == 'ST' || t.role == 'FWD') &&
            (goRight ? t.pos.x > 0.60 : t.pos.x < 0.40) &&
            t.pos.y > 0.26 &&
            t.pos.y < 0.74 &&
            opp.every((o) => o.pos.dist(t.pos) > 0.13));
        if (_rocketInner != null && _rng.nextInt(100) < 60) {
          _rocketInner.shootOnReceive = true;
          _log(
              '⚡ ${owner.data.name} → ${_rocketInner.data.name} (rocket yerine iç pas)!',
              const Color(0xFFFFD600));
          _execPass(owner, _rocketInner);
          return;
        }
        if (_rng.nextInt(100) < 55) {
          _startWallRun(owner);
          return;
        }
      }

      // ── 6. KÖŞE YAKLAŞIM: mid-approach + touchline → %36 içe / %64 sür ──
      if (_midApproach &&
          _huggingLine &&
          pressers.isEmpty &&
          !owner.isDribbling &&
          !owner.instruction.passOnly &&
          _rng.nextInt(100) < 68) {
        if (_rng.nextInt(100) < 36) {
          // İçe keserek ceza alanı girişine git
          owner.isDribbling = true;
          owner.dribbleTimer = 18 + _rng.nextInt(12);
          owner.moveTarget = Pos(
            (goRight
                    ? 0.76 + _rng.nextDouble() * 0.10
                    : 0.14 + _rng.nextDouble() * 0.10)
                .clamp(0.04, 0.96),
            owner.pos.y < 0.5
                ? 0.28 + _rng.nextDouble() * 0.20
                : 0.52 + _rng.nextDouble() * 0.20,
          );
          _log('↙ ${owner.data.name} içe kesiyor...', Colors.cyanAccent);
        } else {
          // Touchline boyunca köşeye sür
          owner.isDribbling = true;
          owner.dribbleTimer = 24 + _rng.nextInt(14);
          double _dribX =
              (owner.pos.x + (goRight ? 0.10 : -0.10)).clamp(0.04, 0.96);
          double _dribY = owner.pos.y < 0.5
              ? (owner.pos.y - 0.015).clamp(0.04, 0.20)
              : (owner.pos.y + 0.015).clamp(0.80, 0.96);
          owner.moveTarget = Pos(_dribX, _dribY);
          _log('🎭 ${owner.data.name} köşeye sürüyor...',
              const Color(0xFF00BCD4));
        }
        return;
      }

      // ── 7. ÇAPRAZ İÇE KESİLME: geniş ama touchline'a tam yaslanmamış ──────
      bool midWide = owner.pos.y < 0.24 || owner.pos.y > 0.76;
      if (midWide &&
          !_huggingLine &&
          !owner.instruction.stayWide &&
          pressers.isEmpty &&
          _rng.nextInt(100) < 40) {
        owner.moveTarget = Pos(
          (owner.pos.x + (goRight ? 0.07 : -0.07)).clamp(0.05, 0.95),
          0.30 + _rng.nextDouble() * 0.40,
        );
      }
    }

    // ── TALİMAT ──
    if (owner.instruction.stayWide) {
      owner.moveTarget = Pos(goalX, owner.pos.y);
      bool nearLine = goRight ? owner.pos.x > 0.80 : owner.pos.x < 0.20;
      if (nearLine) {
        _cross(owner, team);
        return;
      }
    }

    if (owner.instruction.passOnly) {
      if (tick % 10 == 0 || pressers.isNotEmpty) {
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    if (owner.instruction.constantRuns) {
      owner.moveTarget = Pos(goalX, 0.35 + _rng.nextDouble() * 0.30);
    }

    // ── ŞUT: ceza alanı içi ──
    bool inBox = goRight ? owner.pos.x > 0.76 : owner.pos.x < 0.24;
    // Kanat touchline'da köşeye ilerliyor – ceza alanında bile şut atma, trick’e bırak
    bool _wingCornerRunning =
        owner.role == 'WING' && (owner.pos.y < 0.22 || owner.pos.y > 0.78);
    if (inBox && !owner.instruction.passOnly && !_wingCornerRunning) {
      // One-two / low cross combination: topa açık arkadaş varsa önce gönder
      bool hasOpenBoxMate = team.any((t) =>
          t != owner &&
          t.role != 'GK' &&
          t.pos.dist(owner.pos) < 0.22 &&
          opp.every((o) => o.pos.dist(t.pos) > 0.10));
      // Tiki-taka/highPress: daha çok çeviriyor
      int boxPassChance = myTac == TacticStyle.tikiTaka
          ? 35
          : myTac == TacticStyle.highPress
              ? 28
              : 22;
      if (hasOpenBoxMate && _rng.nextInt(100) < boxPassChance) {
        if (_tryPass(owner, team, preferFwd: false, boxPass: true)) return;
      }

      // Merkeze çekilip şut: 1v1 durumunda yüksek şans
      bool is1v1 = opp
          .where((o) => o.pos.dist(owner.pos) < 0.18 && o.role == 'DEF')
          .isEmpty;
      double pAdv = (owner.isHome ? _homePower : _awayPower) -
          (owner.isHome ? _awayPower : _homePower);
      int shootChance = _calcShootChance(myTac, owner.role, pressers.length,
          teamPowerAdv: pAdv, is1v1: is1v1);
      // Tempo yüksekse daha direkt şut
      double tempoBoost = _tempoVal * 12;
      int finalShootChance = min(97, shootChance + 15 + tempoBoost.round());
      if (_rng.nextInt(100) < finalShootChance) {
        _shoot(owner, gk);
        return;
      }
    }

    // ── NEAR-BOX KOMBINASYON: ceza alanı girişinde bölge oyunu ──
    bool nearBox = goRight
        ? (owner.pos.x > 0.62 && owner.pos.x <= 0.76)
        : (owner.pos.x < 0.38 && owner.pos.x >= 0.24);
    if (nearBox && owner.role != 'DEF' && pressers.isEmpty) {
      // Açı varsa direkt şut: merkezi konum + yolda defans yok
      bool _nearBoxAngle = owner.pos.y > 0.26 && owner.pos.y < 0.74;
      bool _nearBoxClear = opp
          .where((o) =>
              o.role != 'GK' &&
              (goRight ? o.pos.x > owner.pos.x : o.pos.x < owner.pos.x) &&
              o.pos.dist(owner.pos) < 0.26 &&
              (o.pos.y - owner.pos.y).abs() < 0.12)
          .isEmpty;
      if (_nearBoxAngle &&
          _nearBoxClear &&
          !owner.instruction.passOnly &&
          _rng.nextInt(100) < 55) {
        _log('🎯 ${owner.data.name} açıdan şut!', Colors.greenAccent);
        _shoot(owner, gk);
        return;
      }
      // Ceza alanı girişinde ortak arama – üçüncü adam koşusu
      bool mate = team.any((t) =>
          t != owner &&
          (t.role == 'FWD' || t.role == 'ST' || t.role == 'WING') &&
          (goRight ? t.pos.x > 0.70 : t.pos.x < 0.30));
      if (mate && _rng.nextInt(100) < 40) {
        if (_tryThroughPass(owner, team)) return;
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    // ── DEVAM EDEN SÜRÜŞ: her tick topu düz önde tut ──
    if (owner.isDribbling && owner.dribbleTimer > 0) {
      bool spaceStillAhead = pressers.isEmpty &&
          opp.every((o) => !((goRight
                  ? o.pos.x > owner.pos.x - 0.04
                  : o.pos.x < owner.pos.x + 0.04) &&
              o.pos.dist(owner.pos) < 0.16));
      if (spaceStillAhead) {
        owner.dribbleTimer--;
        // Her tick hedefi mevcut konumdan sabit bir adım önde tut
        // → takılma yok, sürekli akış
        double stepX =
            (owner.pos.x + (goRight ? 0.055 : -0.055)).clamp(0.04, 0.96);
        double stepY = owner.role == 'WING'
            ? (owner.pos.y * 0.80 + owner.homeBase.y * 0.20).clamp(0.04, 0.96)
            : owner.pos.y; // düz ileri
        owner.moveTarget = Pos(stepX, stepY);
        if (owner.dribbleTimer == 0) owner.isDribbling = false;
        return;
      } else {
        owner.isDribbling = false;
        owner.dribbleTimer = 0;
      }
    }

    // ── SÜRÜŞE BAŞLA: önde açık alan varsa ──
    bool canDribble = owner.role != 'GK' && !owner.instruction.passOnly;
    bool inCarryZone = goRight ? owner.pos.x > 0.22 : owner.pos.x < 0.78;
    if (pressers.isEmpty && canDribble && inCarryZone) {
      bool spaceAhead = opp.every((o) => !((goRight
              ? o.pos.x > owner.pos.x - 0.04
              : o.pos.x < owner.pos.x + 0.04) &&
          o.pos.dist(owner.pos) < 0.17));
      // DEF carries less eagerly; wingers most eager to drive forward
      int carryChance = owner.role == 'DEF'
          ? 38
          : owner.role == 'WING'
              ? 88
              : owner.role == 'MID'
                  ? 55
                  : 65;
      if (spaceAhead && _rng.nextInt(100) < carryChance) {
        owner.isDribbling = true;
        owner.dribbleTimer = 36 + _rng.nextInt(20);
        double dribX =
            (owner.pos.x + (goRight ? 0.065 : -0.065)).clamp(0.04, 0.96);
        double dribY = owner.role == 'WING'
            ? (owner.pos.y * 0.80 + owner.homeBase.y * 0.20).clamp(0.04, 0.96)
            : owner.pos.y;
        owner.moveTarget = Pos(dribX, dribY);
        _log('\u26bd ${owner.data.name} sürdü!', Colors.orangeAccent);
        return;
      }
    }

    // ── MÜDAHALE RİSKİ ──
    if (pressers.isNotEmpty) {
      var tackler = pressers.first;
      int defSk = tackler.defStat;
      int driSk = owner.dribbleStat;
      // Power imbalance: stronger team tackles easier
      double pwr = owner.isHome ? _homePower : _awayPower;
      double oppPwr = owner.isHome ? _awayPower : _homePower;
      int tackleMod = ((oppPwr - pwr) * 0.30)
          .round(); // stronger power difference = much harder tackles
      if (_rng.nextInt(100) < max(6, defSk - driSk + 28 + tackleMod)) {
        _beenTackled(owner, tackler);
        return;
      }
      // Under pressure → pass or shoot
      if (_rng.nextInt(100) < 70) {
        if (inBox) {
          _shoot(owner, gk);
          return;
        }
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    // ── DÜZENLİ PAS (hız moduna göre ölçeklendirilmiş) ──
    // Uzun süredir aynı kanatta → daha sık pas zorla
    int consecBonus =
        owner.isHome ? (_homeConsecLane ~/ 30) : (_awayConsecLane ~/ 30);
    // Tempo yükseldikçe daha az bekle (daha direkt play)
    int tempoBonus = (_tempoVal * 3).round();
    // Larger base = players carry the ball longer before deciding to pass
    int basePassEvery = myTac == TacticStyle.tikiTaka
        ? 10
        : myTac == TacticStyle.gegen
            ? 14
            : myTac == TacticStyle.highPress
                ? 12
                : 16;
    int passEvery =
        _scaledPassEvery(max(3, basePassEvery - consecBonus - tempoBonus));
    if (tick % passEvery == 0) {
      // Kanat oyuncusu: son üçte bire gelene kadar topu sürerek ileri taşır
      bool wingInFinalThird = goRight ? owner.pos.x > 0.68 : owner.pos.x < 0.32;
      if (owner.role == 'WING' && pressers.isEmpty) {
        bool _wOnLine = owner.pos.y < 0.22 || owner.pos.y > 0.78;
        if (wingInFinalThird && _wOnLine) {
          // Final third + touchline: iç pas fırsatı önce dene (%44)
          var _ftInner = team.firstWhereOrNull((t) =>
              t != owner &&
              (t.role == 'CAM' || t.role == 'ST' || t.role == 'FWD') &&
              (goRight ? t.pos.x > 0.58 : t.pos.x < 0.42) &&
              t.pos.y > 0.26 &&
              t.pos.y < 0.74 &&
              opp.every((o) => o.pos.dist(t.pos) > 0.13));
          if (_ftInner != null && _rng.nextInt(100) < 44) {
            _ftInner.shootOnReceive = true;
            _log(
                '📮 ${owner.data.name} → ${_ftInner.data.name} final third iç pas!',
                const Color(0xFFFFD600));
            _execPass(owner, _ftInner);
            return;
          }
          // İç pas yok → köşeye doğru devam et
          double fwdX =
              (owner.pos.x + (goRight ? 0.07 : -0.07)).clamp(0.05, 0.95);
          owner.moveTarget = Pos(fwdX, owner.pos.y.clamp(0.04, 0.96));
        } else if (!wingInFinalThird) {
          // Üçte birden önce: ilerleyip pozisyon al, pas atma
          double fwdX =
              (owner.pos.x + (goRight ? 0.09 : -0.09)).clamp(0.05, 0.95);
          owner.moveTarget = Pos(
            fwdX,
            (owner.pos.y * 0.70 + owner.homeBase.y * 0.30).clamp(0.04, 0.96),
          );
        }
      } else {
        int throughChance = 20 + (_tempoVal * 20).round();
        if (_rng.nextInt(100) < throughChance) {
          if (_tryThroughPass(owner, team)) return;
        }
        _tryPass(owner, team, preferFwd: true);
      }
    }

    // ── UZAKTAN ŞUT: sadece ceza alanı girişi ve iç saha (kanatlar orta sahadan şut atmaz) ──
    // Kanatlar: duvara drive ederek pozisyon kurar, orta sahadan şut atmamalı.
    bool inLongRange = goRight
        ? (owner.pos.x > 0.56 && owner.pos.x < 0.76)
        : (owner.pos.x > 0.24 && owner.pos.x < 0.44);
    if (inLongRange &&
        owner.role != 'DEF' &&
        owner.role != 'WING' &&
        !owner.instruction.passOnly) {
      int lsc = owner.role == 'ST'
          ? 28
          : owner.role == 'CAM'
              ? 30
              : owner.role == 'FWD'
                  ? 32
                  : owner.role == 'MID'
                      ? 18
                      : 8;
      if (pressers.length >= 2) lsc += 22;
      bool _goodAngle = owner.pos.y > 0.28 && owner.pos.y < 0.72;
      bool _defInPath = opp.any((o) =>
          o.role != 'GK' &&
          (goRight ? o.pos.x > owner.pos.x : o.pos.x < owner.pos.x) &&
          o.pos.dist(owner.pos) < 0.26 &&
          (o.pos.y - owner.pos.y).abs() < 0.12);
      if (_goodAngle && !_defInPath) lsc += 22;
      if (_rng.nextInt(100) < lsc) {
        _log('💥 ${owner.data.name} uzaktan şut!', Colors.orange);
        _shoot(owner, gk);
        return;
      }
    }

    // ── GENİŞ KANAT DEĞİŞİMİ: sık ──
    if (tick % 22 == 0) {
      var winers =
          team.where((t) => t.instruction.stayWide && t != owner).toList();
      if (winers.isNotEmpty) {
        _execPass(owner, winers[_rng.nextInt(winers.length)]);
        return;
      }
      // Force field-switch if stuck in same lane too long
      if ((owner.isHome ? _homeConsecLane : _awayConsecLane) > 60) {
        if (_tryPass(owner, team, preferFwd: false, forceLaneSwitch: true))
          return;
      }
    }
  }

  int _calcShootChance(TacticStyle tac, String role, int pressers,
      {double teamPowerAdv = 0, bool is1v1 = false}) {
    int base = role == 'ST'
        ? 90
        : role == 'WING'
            ? 78 // wingers love the diagonal cut-and-shoot
            : role == 'CAM'
                ? 64
                : role == 'FWD' // legacy
                    ? 88
                    : role == 'MID' // legacy
                        ? 68
                        : 24;
    if (tac == TacticStyle.attack) base += 28;
    if (tac == TacticStyle.defensive) base -= 8;
    if (tac == TacticStyle.tikiTaka) base -= 2;
    if (tac == TacticStyle.counter) base += 18;
    if (tac == TacticStyle.highPress) base += 8;
    if (pressers > 1) base += 22;
    if (is1v1) base += 18; // 1v1 with GK → strong shot urge
    base += (teamPowerAdv * 0.20).round().clamp(-8, 16);
    return base.clamp(18, 96);
  }

  TacticStyle _myTactic(bool isHome) {
    if (isHome) {
      return _liveHomeTactic ??
          (widget.isPlayerTeamAway ? widget.oppTactic : widget.myTactic);
    }
    return _liveAwayTactic ??
        (widget.isPlayerTeamAway ? widget.myTactic : widget.oppTactic);
  }

  // ─── PASS ───────────────────────────────────────────────────────────────────

  bool _tryPass(SimPlayer passer, List<SimPlayer> team,
      {bool preferFwd = false,
      bool boxPass = false,
      bool forceLaneSwitch = false}) {
    var opts = team.where((t) => t != passer && t.role != 'GK').toList();
    if (opts.isEmpty) return false;

    bool goRight = passer.isHome;
    var oppTeam = passer.isHome ? awayTeam : homeTeam;

    // Determine current lane of the passer
    int passerLane = passer.pos.y < 0.35
        ? 0
        : passer.pos.y > 0.65
            ? 2
            : 1;
    int consecLane = passer.isHome ? _homeConsecLane : _awayConsecLane;
    // If stuck in same lane >= 2 passes, heavily prefer a different lane
    bool forceNewLane = forceLaneSwitch || consecLane >= 55;

    SimPlayer? best;
    double bestS = -9999;

    // Pasörün kendi sahasında olup olmadığı
    bool passerInOwnHalf = goRight ? passer.pos.x < 0.50 : passer.pos.x > 0.50;

    for (var t in opts) {
      double s = 0;

      // İleriye pas tercihi – daha güçlü ileri yönelim
      if (preferFwd) {
        double fwdDist =
            goRight ? t.pos.x - passer.pos.x : passer.pos.x - t.pos.x;
        s += fwdDist * 95;
      }

      // Kendi sahasında: derinlere/arkaya pas ağır ceza, ileriye büyük bonus
      if (passerInOwnHalf) {
        double fwdDist =
            goRight ? t.pos.x - passer.pos.x : passer.pos.x - t.pos.x;
        if (fwdDist < -0.05) s -= 140; // geri veya yanlara pas yasak
        if (fwdDist > 0.10) s += 80; // ileriye pas büyük ödül
        // DEF veya GK'ya pas vermeyi tamamen engelle
        if (t.role == 'DEF' || t.role == 'GK') s -= 200;
        // Kanat/forvet en öncelikli
        if (t.role == 'ST' ||
            t.role == 'WING' ||
            t.role == 'FWD' ||
            t.role == 'CAM') s += 90;
      }

      // Rakip sahasındayken geri pas cezası – topu öne taşı
      bool passerInOppHalf =
          goRight ? passer.pos.x > 0.50 : passer.pos.x < 0.50;
      if (passerInOppHalf) {
        double fwd2 = goRight ? t.pos.x - passer.pos.x : passer.pos.x - t.pos.x;
        if (fwd2 < -0.18) s -= 80; // derin geri pas büyük ceza
        if (fwd2 > 0.05) s += 35; // ileri pas bonusu
      }

      // Ceza alanı içi pas: yakın ve açık oyuncuyu tercih et
      if (boxPass) {
        double d2 = passer.pos.dist(t.pos);
        if (d2 < 0.22) s += 80;
      }

      // Açık oyuncu: yakınında rakip yok
      bool open = oppTeam.every((o) => o.pos.dist(t.pos) > 0.12);
      if (open) s += 70;

      // Farklı Y bölgesinde (yayılma): yoğunlaşmayı önle
      double yDiff = (t.pos.y - passer.pos.y).abs();
      if (yDiff > 0.18) s += 30;
      if (yDiff > 0.32) s += 50; // Kanat değiştirme: saha genişliği ödülü
      // Kanat oyuncusuna pas: saha genişliği zorla
      if (t.role == 'WING' && yDiff > 0.20) s += 40;

      // ── LANE ROTATION: penalize same-lane targets when stuck ──
      int targetLane = t.pos.y < 0.35
          ? 0
          : t.pos.y > 0.65
              ? 2
              : 1;
      if (forceNewLane && targetLane == passerLane) {
        s -= 80; // strongly avoid same lane
      } else if (forceNewLane && targetLane != passerLane) {
        s += 60; // strongly prefer different lane
      }

      if (t.role == 'FWD' || t.role == 'ST' || t.role == 'WING') s += 35;
      if (t.instruction.stayWide) s += 25;

      // Optimal pas mesafesi: 0.10-0.50 arası
      double d = passer.pos.dist(t.pos);
      if (d < 0.07) s -= 35;
      if (d > 0.52) s -= 60;
      if (d >= 0.10 && d <= 0.40) s += 20;

      if (s > bestS) {
        bestS = s;
        best = t;
      }
    }

    if (best == null) return false;
    _execPass(passer, best);
    return true;
  }

  // ─── THROUGH BALL (ARA PAS) ────────────────────────────────────────────────────

  bool _tryThroughPass(SimPlayer passer, List<SimPlayer> team) {
    bool goRight = passer.isHome;
    var opp = passer.isHome ? awayTeam : homeTeam;

    for (var candidate in team) {
      if (candidate == passer || candidate.role == 'GK') continue;
      double fwdDist = goRight
          ? candidate.pos.x - passer.pos.x
          : passer.pos.x - candidate.pos.x;
      if (fwdDist < 0.12) continue; // Must be significantly ahead

      // ─── OFSAYT KONTROLÜ: alıcı son savunmacının gerisindeyse hakem durdurur ───
      final _ofsDefs = opp.where((o) => o.role != 'GK').toList();
      if (_ofsDefs.isNotEmpty) {
        double _lastDefX = goRight
            ? _ofsDefs.map((d) => d.pos.x).reduce((a, b) => a < b ? a : b)
            : _ofsDefs.map((d) => d.pos.x).reduce((a, b) => a > b ? a : b);
        bool _isOffside = goRight
            ? (candidate.pos.x > _lastDefX + 0.05 && passer.pos.x < _lastDefX)
            : (candidate.pos.x < _lastDefX - 0.05 && passer.pos.x > _lastDefX);
        // Hakem %68 oranında offsaydı görür (gerçekçilik için bazen kaçırıyor)
        if (_isOffside && _rng.nextInt(100) < 68) {
          _triggerOffside(passer);
          return true;
        }
      }

      // Project where they’ll sprint to
      double projX =
          (candidate.pos.x + (goRight ? 0.15 : -0.15)).clamp(0.05, 0.95);
      double projY = candidate.pos.y + (_rng.nextDouble() - 0.5) * 0.06;

      // Projection must be open
      bool open = opp.every((o) => o.pos.dist(Pos(projX, projY)) > 0.09);
      if (!open) continue;

      // Sprint runner toward the through-ball destination
      candidate.moveTarget = Pos(projX, projY.clamp(0.05, 0.95));

      ball.owner = null;
      ball.phase = BallPhase.passFlight;
      ball.passFrom.set(passer.pos);
      ball.passTo = Pos(projX, projY.clamp(0.04, 0.96));
      ball.passTarget = candidate;
      ball.passTicksTotal = max(16,
          (passer.pos.dist(Pos(projX, projY)) * 92 * _passTicksMult()).round());
      ball.passTicksRemaining = ball.passTicksTotal;
      ball.pos.set(passer.pos);

      // Passer also makes a run
      passer.moveTarget = Pos(
        (passer.pos.x + (goRight ? 0.15 : -0.15)).clamp(0.05, 0.95),
        (passer.pos.y + (_rng.nextDouble() - 0.5) * 0.18).clamp(0.05, 0.95),
      );

      _log('⚡ ${passer.data.name} ara pas! → ${candidate.data.name}',
          Colors.yellowAccent);
      return true;
    }
    return false;
  }

  void _startWallPull(SimPlayer runner) {
    bool goRight = runner.isHome;
    if (goRight && runner.pos.x > 0.82) return;
    if (!goRight && runner.pos.x < 0.18) return;
    // 1 veya 2 kez duvara çek
    int bounces = _rng.nextBool() ? 1 : 2;
    double wallY = runner.pos.y < 0.5 ? 0.012 : 0.988;
    // DÜMDÜZ duvara: aynı X, sadece Y değişir
    Pos wallTarget = Pos(runner.pos.x, wallY);
    ball.isWallPull = true;
    ball.wallPullBouncesLeft = bounces;
    ball.wallPullRunner = runner;
    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(runner.pos);
    ball.passTo.set(wallTarget);
    ball.passTarget = null;
    ball.passTicksTotal =
        max(6, (runner.pos.dist(wallTarget) * 68 * _passTicksMult()).round());
    ball.passTicksRemaining = ball.passTicksTotal;
    ball.pos.set(runner.pos);
    // Kanat DÜMDÜZ ileri sprint başlatır (Y sabit)
    double sprintX =
        (runner.pos.x + (goRight ? 0.11 : -0.11)).clamp(0.04, 0.96);
    runner.moveTarget = Pos(sprintX, runner.pos.y);
    _log('🏃 ${runner.data.name} duvara çekti! ($bounces sek)',
        Colors.lightGreenAccent);
  }

  void _startWallRun(SimPlayer runner) {
    bool goRight = runner.isHome;
    double wallY = runner.pos.y < 0.5 ? 0.02 : 0.98;
    ball.isWallRunActive = true;
    ball.wallRunner = runner;
    ball.wallRunTarget = Pos(
      (runner.pos.x + (goRight ? 0.06 : -0.06)).clamp(0.04, 0.96),
      wallY,
    );
    ball.wallRunCountdown = 50;
    ball.wallRunBlinkTimer = 0;
    _log('💨 ${runner.data.name} duvara koşuyor!', Colors.yellowAccent);
  }

  // ─── HaxBall KÖŞE DUVAR TRİKİ ──────────────────────────────────────────────
  // Kanat rakip köşesine ulaştığında:
  //   Faz 1 → topu köşeye (x+y duvarına) vurur
  //   Faz 2 → top çapraz geri sekip oyuncuya gelir
  //   Karar → %75 iç pas (CAM/ST), %25 şut
  void _startCornerTrick(SimPlayer runner) {
    bool goRight = runner.isHome;
    // Hangi köşe? Oyuncunun Y'sine göre belirle
    bool isTopCorner = runner.pos.y < 0.5;
    int direction = isTopCorner ? -1 : 1; // -1=üst köşe, +1=alt köşe

    // Köşe noktası: hem x hem y duvarına yakın
    double cornerX = goRight ? 0.975 : 0.025;
    double cornerY = isTopCorner ? 0.018 : 0.982;

    ball.isCornerTrick = true;
    ball.cornerTrickRunner = runner;
    ball.cornerTrickPhase = 1;
    ball.cornerTrickDirection = direction;

    // Topu köşeye gönder (passFlight, passTarget=null → duvara çarpacak)
    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(runner.pos);
    ball.passTo = Pos(cornerX, cornerY);
    ball.passTarget = null; // köşe duvarı
    ball.passTicksTotal = max(
        8,
        (runner.pos.dist(Pos(cornerX, cornerY)) * 52 * _passTicksMult())
            .round());
    ball.passTicksRemaining = ball.passTicksTotal;
    ball.pos.set(runner.pos);

    // Oyuncu köşeye birlikte sprint atar
    runner.moveTarget = Pos(
      (goRight ? 0.88 : 0.12),
      isTopCorner ? 0.06 : 0.94,
    );

    if (runner.isHome)
      _homeCornerTricksDone++;
    else
      _awayCornerTricksDone++;

    _log('🔵 ${runner.data.name} HaxBall köşe duvar triki!',
        const Color(0xFF40C4FF));
  }

  void _execPass(SimPlayer passer, SimPlayer target) {
    // Guard: cannot pass to yourself
    if (passer == target) return;
    int psk = passer.passStat;
    // Error chance scales with pass stat: low stat → higher error
    // passStat 75 → ~10%, 50 → ~21%, 25 → ~32%
    int errChance = max(3, ((100 - psk) * 0.42).round());

    if (_rng.nextInt(100) < errChance) {
      var opp = passer.isHome ? awayTeam : homeTeam;
      // Check if opponent can intercept (close to target)
      SimPlayer? intr =
          opp.firstWhereOrNull((o) => o.pos.dist(target.pos) < 0.16);
      if (intr != null && _rng.nextInt(100) < 30) {
        ball.owner = intr;
        ball.phase = BallPhase.owned;
        ball.pos.set(intr.pos);
        _log('❌ Pas kesildi! ${intr.data.name} kaptı', Colors.redAccent);
        _maybeTriggerGegen(passer.isHome);
        return;
      }
      // Errant pass – ball goes to wrong position (loose ball)
      double errScale = 0.12 + (1.0 - psk / 100.0) * 0.22;
      double errX = (target.pos.x + (_rng.nextDouble() - 0.5) * errScale * 2.2)
          .clamp(0.03, 0.97);
      double errY = (target.pos.y + (_rng.nextDouble() - 0.5) * errScale * 2.2)
          .clamp(0.03, 0.97);
      ball.owner = null;
      ball.phase = BallPhase.passFlight;
      ball.passFrom.set(passer.pos);
      ball.passTo = Pos(errX, errY);
      ball.passTarget = null; // Loose ball – no guaranteed receiver
      ball.passTicksTotal = max(18,
          (passer.pos.dist(Pos(errX, errY)) * 95 * _passTicksMult()).round());
      ball.passTicksRemaining = ball.passTicksTotal;
      ball.pos.set(passer.pos);
      // Stats – failed pass
      if (passer.isHome)
        _homePassesAtt++;
      else
        _awayPassesAtt++;
      _insight(passer).update(badPass: true);
      _log('⚠️ ${passer.data.name} hatalı pas!', Colors.orange);
      passer.moveTarget = Pos(
        (passer.pos.x + (passer.isHome ? 0.10 : -0.10)).clamp(0.05, 0.95),
        passer.pos.y,
      );
      return;
    }

    // ── PASSER YARATICI KOŞU: pas attıktan sonra boşluğa koştur ──
    bool goRight = passer.isHome;
    bool nearBox = goRight ? passer.pos.x > 0.50 : passer.pos.x < 0.50;
    double runX, runY;
    if (nearBox && _rng.nextInt(100) < 86) {
      // Pas sonrası ileri taşı – daha fazla şut imkânı yarat
      runX = (goRight
              ? 0.72 + _rng.nextDouble() * 0.18
              : 0.10 + _rng.nextDouble() * 0.18)
          .clamp(0.05, 0.95);
      runY = 0.20 + _rng.nextDouble() * 0.60;
    } else if (_rng.nextInt(100) < 60) {
      // Genel yaratıcı koşu – ileri ve yana
      runX = (passer.pos.x +
              (goRight ? 0.14 : -0.14) +
              (_rng.nextDouble() - 0.5) * 0.10)
          .clamp(0.05, 0.95);
      runY =
          (passer.pos.y + (_rng.nextDouble() - 0.5) * 0.32).clamp(0.05, 0.95);
    } else {
      // Çapraz koşu – yeni açı yarat
      double diagY = (passer.homeBase.y > 0.5 ? 1 : -1) * 0.22;
      runX = (passer.pos.x + (goRight ? 0.12 : -0.12)).clamp(0.05, 0.95);
      runY = (passer.pos.y + diagY).clamp(0.05, 0.95);
    }
    passer.moveTarget = Pos(runX, runY);

    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(passer.pos);
    ball.passTo.set(target.pos); // locked destination
    ball.passTarget = target;
    // Receiver MUST run to exact arrival point – prevents "floating" ball
    target.moveTarget.set(ball.passTo);
    ball.passTicksTotal =
        max(16, (passer.pos.dist(target.pos) * 95 * _passTicksMult()).round());
    ball.passTicksRemaining = ball.passTicksTotal;
    ball.pos.set(passer.pos);

    // Stats – successful pass
    if (passer.isHome) {
      _homePassesAtt++;
      _homePassesCmpl++;
    } else {
      _awayPassesAtt++;
      _awayPassesCmpl++;
    }
    bool isIntoBox = passer.isHome ? target.pos.x > 0.76 : target.pos.x < 0.24;
    _insight(passer).update(pass: true, keyPass: isIntoBox);
    _log('✓ ${passer.data.name} → ${target.data.name}', Colors.lightBlueAccent);
  }

  // ─── PASS FLIGHT ────────────────────────────────────────────────────────────

  void _passFlightPhase() {
    ball.passTicksRemaining--;
    double t = 1.0 - (ball.passTicksRemaining / ball.passTicksTotal);
    ball.pos.set(ball.passFrom.lerp(ball.passTo, t));

    if (ball.passTicksRemaining > 0) return;

    // ── DUVAR SEKME: top duvara ulaştı (passTarget==null) veya oyuncuya döndü ──
    if (ball.isWallPull) {
      var runner = ball.wallPullRunner;
      if (runner == null) {
        ball.isWallPull = false;
        ball.wallPullBouncesLeft = 0;
        ball.phase = BallPhase.free;
        return;
      }
      bool goRight = runner.isHome;

      if (ball.passTarget == null) {
        // ── FAZ A: Top duvara çarptı → DÜMDÜZ ileri oyuncuya geri gönder ──
        // Oyuncu sprintle ilerledi; top onun ilerisine döner
        double returnX =
            (runner.pos.x + (goRight ? 0.07 : -0.07)).clamp(0.04, 0.96);
        double returnY = runner.pos.y; // dümdüz geri, Y sabit
        Pos returnTarget = Pos(returnX, returnY);
        ball.passFrom.set(ball.pos);
        ball.passTo.set(returnTarget);
        ball.passTarget = runner;
        ball.passTicksTotal = max(
            6, (ball.pos.dist(returnTarget) * 68 * _passTicksMult()).round());
        ball.passTicksRemaining = ball.passTicksTotal;
        runner.moveTarget.set(returnTarget);
        _log(
            '💥 Duvardan döndü → ${runner.data.name}', Colors.lightGreenAccent);
      } else {
        // ── FAZ B: Top oyuncuya ulaştı ──
        ball.wallPullBouncesLeft--;
        if (ball.wallPullBouncesLeft > 0) {
          // Daha sekme var → tekrar duvara dümdüz çek
          double wallY = runner.pos.y < 0.5 ? 0.012 : 0.988;
          Pos wallTarget = Pos(runner.pos.x, wallY);
          ball.passFrom.set(runner.pos);
          ball.passTo.set(wallTarget);
          ball.passTarget = null;
          ball.passTicksTotal = max(
              6, (runner.pos.dist(wallTarget) * 68 * _passTicksMult()).round());
          ball.passTicksRemaining = ball.passTicksTotal;
          ball.pos.set(runner.pos);
          // Sprint devam – dümdüz ileri
          double sprintX =
              (runner.pos.x + (goRight ? 0.11 : -0.11)).clamp(0.04, 0.96);
          runner.moveTarget = Pos(sprintX, runner.pos.y);
          _log(
              '🏃 ${runner.data.name} tekrar duvara!', Colors.lightGreenAccent);
        } else {
          // Son sekme: topu al ve dripling başlat
          ball.isWallPull = false;
          ball.wallPullRunner = null;
          ball.wallPullBouncesLeft = 0;
          ball.owner = runner;
          ball.phase = BallPhase.owned;
          ball.pos.set(runner.pos);
          runner.isDribbling = true;
          runner.dribbleTimer = 44 + _rng.nextInt(20);
          double dribX =
              (runner.pos.x + (goRight ? 0.055 : -0.055)).clamp(0.04, 0.96);
          runner.moveTarget = Pos(dribX, runner.pos.y);
          _log('⚡ ${runner.data.name} topu aldı, ileri!', Colors.greenAccent);
        }
      }
      return;
    }

    // ── KÖŞE DUVAR TRİKİ: iki fazlı (duvara uçuş + oyuncuya geri) ──
    if (ball.isCornerTrick) {
      var _tr = ball.cornerTrickRunner;
      if (_tr == null) {
        ball.isCornerTrick = false;
        ball.cornerTrickPhase = 0;
        ball.phase = BallPhase.free;
        return;
      }
      bool _goRight = _tr.isHome;

      if (ball.cornerTrickPhase == 1) {
        // FAZ 1 tamamlandı: top köşeye çarptı → oyuncuya geri sek
        ball.cornerTrickPhase = 2;
        // Geri sekme: köşeden çapraz olarak oyuncunun önüne
        double _retX =
            (_tr.pos.x + (_goRight ? -0.08 : 0.08)).clamp(0.08, 0.92);
        double _retY = (ball.cornerTrickDirection < 0)
            ? (_tr.pos.y + 0.13).clamp(0.04, 0.50)
            : (_tr.pos.y - 0.13).clamp(0.50, 0.96);
        Pos _retPos = Pos(_retX, _retY);
        ball.passFrom.set(ball.pos);
        ball.passTo.set(_retPos);
        ball.passTarget = _tr;
        ball.passTicksTotal =
            max(7, (ball.pos.dist(_retPos) * 60 * _passTicksMult()).round());
        ball.passTicksRemaining = ball.passTicksTotal;
        _tr.moveTarget.set(_retPos);
        _log('💫 Köşeden geri döndü → ${_tr.data.name}',
            const Color(0xFF40C4FF));
        return;
      }

      if (ball.cornerTrickPhase == 2) {
        // FAZ 2 tamamlandı: oyuncu topu aldı → içe dön + karar ver
        ball.isCornerTrick = false;
        ball.cornerTrickRunner = null;
        ball.cornerTrickPhase = 0;
        ball.cornerTrickDirection = 0;
        ball.owner = _tr;
        ball.phase = BallPhase.owned;
        ball.passTarget = null;
        ball.pos.set(_tr.pos);
        _log('↩ ${_tr.data.name} içe döndü!', const Color(0xFF40C4FF));

        var _tTeam = _tr.isHome ? homeTeam : awayTeam;
        var _tOpp = _tr.isHome ? awayTeam : homeTeam;
        var _tGk = _tOpp.firstWhereOrNull((pl) => pl.role == 'GK');

        // 40% şut, 60% içeri pas – içe dönerek karar ver
        // Önce GK'ya açık bakış var mı kontrol et
        bool _hasLane = _tOpp
            .where((o) =>
                o.role != 'GK' &&
                (_goRight ? o.pos.x > _tr.pos.x : o.pos.x < _tr.pos.x) &&
                o.pos.dist(_tr.pos) < 0.28 &&
                (o.pos.y - _tr.pos.y).abs() < 0.14)
            .isEmpty;
        // Köşe triki sonrası: büyük çoğunlukla iç pas – kanat şutu son çare.
        if (_tGk != null && (_rng.nextInt(100) < (_hasLane ? 12 : 6))) {
          _log('🎯 ${_tr.data.name} köşeden şut!', const Color(0xFFFF5722));
          _shoot(_tr, _tGk);
        } else {
          // İç pas: CAM / ST / FWD – merkez bölgesindeki oyuncuya
          var _inner = _tTeam
              .where((t) =>
                  t != _tr &&
                  t.role != 'GK' &&
                  (t.role == 'CAM' || t.role == 'ST' || t.role == 'FWD') &&
                  (_goRight ? t.pos.x > 0.52 : t.pos.x < 0.48) &&
                  t.pos.y > 0.24 &&
                  t.pos.y < 0.76)
              .toList();
          if (_inner.isNotEmpty) {
            _inner.sort((a, b) =>
                (_goRight ? b.pos.x - a.pos.x : a.pos.x - b.pos.x).toInt());
            _log('📩 ${_tr.data.name} → ${_inner.first.data.name} (iç pas!)',
                const Color(0xFF40C4FF));
            _inner.first.shootOnReceive = true; // gelince vursun!
            _execPass(_tr, _inner.first);
          } else if (_tGk != null) {
            _log('🎯 ${_tr.data.name} zoraki şut!', const Color(0xFFFF5722));
            _shoot(_tr, _tGk);
          } else {
            _tryPass(_tr, _tTeam, preferFwd: true);
          }
        }
        return;
      }
      // Beklenmedik faz → serbest bırak
      ball.isCornerTrick = false;
      ball.phase = BallPhase.free;
      return;
    }

    SimPlayer? recv = ball.passTarget;
    if (recv == null) {
      // Errant pass – loose ball at landing spot
      ball.phase = BallPhase.free;
      return;
    }

    // Can an opponent intercept at arrival?
    var opp = recv.isHome ? awayTeam : homeTeam;
    // Only attempt interception if rival is physically close (< 0.15) AND
    // closer to the ball than the receiver – prevents far-away snap ownership.
    SimPlayer? rival = opp.firstWhereOrNull((o) =>
        o.pos.dist(ball.pos) < 0.15 &&
        o.pos.dist(ball.pos) < recv.pos.dist(ball.pos) - 0.03);
    if (rival != null) {
      // Power-weighted interception: stronger team intercepts more reliably
      double recvPwr = recv.isHome ? _homePower : _awayPower;
      double rivPwr = recv.isHome ? _awayPower : _homePower;
      double powerAdv = ((rivPwr - recvPwr) / 100.0).clamp(-0.6, 0.6);
      int interceptChance = (20 + (powerAdv * 38)).round().clamp(3, 72);
      if (_rng.nextInt(100) < interceptChance) {
        ball.owner = rival;
        ball.phase = BallPhase.owned;
        ball.pos.set(rival.pos);
        _log('\u2694\ufe0f ${rival.data.name} aras\u0131na girdi!',
            Colors.orangeAccent);
        _maybeTriggerGegen(recv.isHome);
        return;
      }
    }

    // Ball arrives – snap ball to where the receiver CURRENTLY is.
    // Do NOT teleport the receiver; they keep moving naturally.
    // (Receiver was running toward passTo the whole flight – they are close.)
    ball.pos.set(recv.pos);
    ball.owner = recv;
    ball.phase = BallPhase.owned;
    ball.passTarget = null; // clear target immediately to prevent re-use
    // Ceza alanında pas alındıysa anında şut imkânı değerlendir
    var recvOpp = recv.isHome ? awayTeam : homeTeam;
    var recvGk = recvOpp.firstWhereOrNull((pl) => pl.role == 'GK');
    bool inAttBox = recv.isHome ? recv.pos.x > 0.76 : recv.pos.x < 0.24;
    bool isAttacker = recv.role == 'ST' ||
        recv.role == 'WING' ||
        recv.role == 'CAM' ||
        recv.role == 'FWD';
    if (inAttBox && recvGk != null && isAttacker && _rng.nextInt(100) < 52) {
      _shoot(recv, recvGk);
      return;
    }
  }

  // ─── WALL RUN ────────────────────────────────────────────────────────────────

  void _wallRunPhase() {
    var runner = ball.wallRunner;
    if (runner == null) {
      ball.isWallRunActive = false;
      return;
    }
    // Point the runner toward the wall – _simulate() handles actual movement
    runner.moveTarget.set(ball.wallRunTarget);
    ball.wallRunCountdown--;

    double distToWall = runner.pos.dist(ball.wallRunTarget);
    bool reachedWall = distToWall < 0.07 || ball.wallRunCountdown <= 0;
    if (!reachedWall) return;

    // ── BLINK PHASE: oyuncu 2 kez yanıp söner ──
    ball.wallRunBlinkTimer++;
    // blink effect exposed via isPassShoot toggle (~14 tick per blink)
    runner.isPassShoot = (ball.wallRunBlinkTimer % 14) < 7;

    if (ball.wallRunBlinkTimer < 30) return; // ~0.5s blink phase

    // Done blinking → fire diagonal rocket shot
    runner.isPassShoot = false;
    ball.isWallRunActive = false;
    ball.wallRunner = null;

    var opp = runner.isHome ? awayTeam : homeTeam;
    var gk = opp.firstWhereOrNull((p) => p.role == 'GK');
    if (gk != null) _rocketShoot(runner, gk);
  }

  // ─── ROCKET SHOOT (diagonal wall shot) ──────────────────────────────────────

  void _rocketShoot(SimPlayer shooter, SimPlayer gk) {
    bool goRight = shooter.isHome;
    double goalX = goRight ? 0.985 : 0.015;
    // Shoot diagonally to opposite post from shooter's Y
    double goalY = shooter.pos.y < 0.5 ? 0.62 : 0.38;

    int shotSk = shooter.shootStat;
    // Rocket is highly precise – almost always on target
    bool onTarget = _rng.nextInt(100) >= max(1, 96 - shotSk);
    // GK has much less time to react – save probability halved
    int saveChance = max(1, (gk.reflexStat * 0.11).round());
    bool gkSaves = onTarget && _rng.nextInt(100) < saveChance;

    ball.shotWillGoal = onTarget && !gkSaves;
    ball.shotOnTarget = onTarget;
    ball.shotGk = gk;
    ball.shotShooterName = shooter.data.name;
    ball.shotIsHome = shooter.isHome;
    ball.isRocketShot = true;

    const int flightTicks = 20;
    double dxShot = goalX - shooter.pos.x;
    double dyShot = goalY - shooter.pos.y;
    ball.vBallX = dxShot / flightTicks;
    ball.vBallY = dyShot / flightTicks;
    ball.shotBounced = false;

    ball.owner = null;
    ball.phase = BallPhase.shotFlight;
    ball.passFrom.set(shooter.pos);
    ball.passTo = Pos(goalX, goalY);
    ball.passTicksTotal = flightTicks;
    ball.passTicksRemaining = flightTicks;
    ball.pos.set(shooter.pos);
    _rocketFreezeTicks = 18; // brief freeze-frame before flight

    if (shooter.isHome) {
      _homeShots++;
      if (onTarget) _homeShotsOnTarget++;
    } else {
      _awayShots++;
      if (onTarget) _awayShotsOnTarget++;
    }
    _insight(shooter).update(shotOT: onTarget, miss: !onTarget);

    // Spawn red rocket particles
    for (int i = 0; i < 28; i++) {
      double angle = _rng.nextDouble() * 2 * pi;
      double spd = 0.005 + _rng.nextDouble() * 0.010;
      _shotParticles.add(_ShotParticle(
        shooter.pos.x,
        shooter.pos.y,
        cos(angle) * spd,
        sin(angle) * spd,
        1.0,
        Color.lerp(Colors.redAccent, Colors.orangeAccent, _rng.nextDouble())!,
      ));
    }

    _log('🚀 ${shooter.data.name} DUVAR ROKET ŞUT!', Colors.redAccent);
  }

  // ─── CROSS ──────────────────────────────────────────────────────────────────

  void _cross(SimPlayer crosser, List<SimPlayer> team) {
    bool goRight = crosser.isHome;
    var targets = team
        .where((t) =>
            t != crosser &&
            (t.role == 'FWD' ||
                t.role == 'MID' ||
                t.role == 'ST' ||
                t.role == 'WING' ||
                t.role == 'CAM'))
        .toList();
    if (targets.isEmpty) return;

    // Priority: ST > WING > CAM > MID/FWD
    SimPlayer tgt = targets.firstWhere(
      (t) => t.role == 'ST',
      orElse: () => targets.firstWhere(
        (t) => t.role == 'WING',
        orElse: () => targets.first,
      ),
    );

    tgt.moveTarget = Pos(
      goRight
          ? 0.80 + _rng.nextDouble() * 0.12
          : 0.08 + _rng.nextDouble() * 0.12,
      0.28 + _rng.nextDouble() * 0.44,
    );

    _log('⤴ ${crosser.data.name} ortaya gönderdi!', Colors.greenAccent);

    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(crosser.pos);
    ball.passTo.set(tgt.moveTarget);
    ball.passTarget = tgt;
    ball.passTicksTotal = max(20, (45 * _passTicksMult()).round());
    ball.passTicksRemaining = ball.passTicksTotal;
  }

  // ─── SHOOT ──────────────────────────────────────────────────────────────────

  void _shoot(SimPlayer shooter, SimPlayer gk) {
    ball.isRocketShot = false; // regular shot – clear any previous rocket flag
    bool isVolley =
        (ball.phase == BallPhase.passFlight || ball.passTicksRemaining > 0);
    int shotSk = shooter.shootStat;

    // Error formulas per spec:
    //  Normal: errorChance = 100 - shootStat   (90→10% error)
    //  Volley: max(10, 100 - shootStat*0.89)   (90→~20% error)
    int errorChance = isVolley
        ? max(10, (100 - shotSk * 0.89).round())
        : max(5, 100 - shotSk);

    bool onTarget = _rng.nextInt(100) >= errorChance;

    _log('🎯 ${shooter.data.name}${isVolley ? ' (gelişine)' : ''} şut!',
        Colors.amber);

    // Stats tracking
    if (shooter.isHome) {
      _homeShots++;
      if (onTarget) _homeShotsOnTarget++;
    } else {
      _awayShots++;
      if (onTarget) _awayShotsOnTarget++;
    }
    _insight(shooter).update(shotOT: onTarget, miss: !onTarget);

    // LED ring şut efekti
    shooter.isPassShoot = true;
    shooter.passShootTimer = 45;

    // ŞUUUT! screen overlay
    _shootEffectActive = true;
    _shootEffectPlayer = shooter;
    _shootEffectTimer = 60;

    // Spawn orange shot particles
    for (int i = 0; i < 18; i++) {
      double angle = _rng.nextDouble() * 2 * pi;
      double spd = 0.003 + _rng.nextDouble() * 0.007;
      _shotParticles.add(_ShotParticle(
        shooter.pos.x,
        shooter.pos.y,
        cos(angle) * spd,
        sin(angle) * spd,
        1.0,
        Color.lerp(const Color(0xFFFF6D00), Colors.yellow, _rng.nextDouble())!,
      ));
    }

    bool goRight = shooter.isHome;

    // Dar açı tespiti: yan çizgiye yakın ve ceza alanı köşesindeyse
    bool isNarrowAngle = (shooter.pos.y < 0.26 || shooter.pos.y > 0.74) &&
        (goRight ? shooter.pos.x > 0.70 : shooter.pos.x < 0.30);

    // Determine GK save outcome upfront
    int reflex = gk.reflexStat;
    bool is1v1 = (shooter.isHome ? homeTeam : awayTeam)
        .where((p) => p.role == 'DEF' && p.pos.dist(shooter.pos) < 0.18)
        .isEmpty;
    int saveChance = max(6, (reflex * 0.38).round() + (is1v1 ? 0 : 14));
    bool gkSaves = onTarget && _rng.nextInt(100) < saveChance;

    // Store verdict in ball for flight resolution
    ball.shotWillGoal = onTarget && !gkSaves;
    ball.shotOnTarget = onTarget;
    ball.shotGk = gk;
    ball.shotShooterName = shooter.data.name;
    ball.shotIsHome = shooter.isHome;

    // Build shot target position: aim toward goal with slight randomness
    double goalX = goRight ? 0.985 : 0.015;
    double goalY;
    if (!onTarget) {
      // Off-target: aim wide or over (misses the goal box)
      double baseY = 0.5 + (_rng.nextDouble() - 0.5) * 0.7;
      goalY = baseY.clamp(0.02, 0.98);
    } else {
      // Finishing stat drives corner placement:
      // shootStat 40 → center only; 100 → 72% chance at corner
      double cornerProb = ((shooter.shootStat - 40) / 60.0).clamp(0.0, 1.0);
      if (isNarrowAngle) {
        // Dar açıdan yakın direğe hassas şut
        bool nearSide = shooter.pos.y < 0.5;
        goalY = nearSide
            ? 0.355 + _rng.nextDouble() * 0.045 // yakın direk (üst)
            : 0.600 + _rng.nextDouble() * 0.045; // yakın direk (alt)
      } else if (_rng.nextDouble() < cornerProb * 0.72) {
        // Corner of the goal
        goalY = _rng.nextBool()
            ? 0.37 + _rng.nextDouble() * 0.03 // near post
            : 0.60 + _rng.nextDouble() * 0.03; // far post
      } else {
        // Aim at center-ish area (easier for GK but still on target)
        goalY = 0.43 + _rng.nextDouble() * 0.14;
      }
    }

    // Launch ball as shot flight with velocity-based wall-bounce physics
    double dxShot = goalX - shooter.pos.x;
    double dyShot = goalY - shooter.pos.y;
    const int flightTicks = 30;
    ball.vBallX = dxShot / flightTicks;
    ball.vBallY = dyShot / flightTicks;
    ball.shotBounced = false;

    ball.owner = null;
    ball.phase = BallPhase.shotFlight;
    ball.passFrom.set(shooter.pos);
    ball.passTo = Pos(goalX, goalY);
    ball.passTicksTotal = flightTicks;
    ball.passTicksRemaining = flightTicks;
    ball.pos.set(shooter.pos);
  }

  // ─── SHOT FLIGHT ────────────────────────────────────────────────────────────

  void _shotFlightPhase() {
    // Advance ball position by velocity
    ball.pos.x += ball.vBallX;
    ball.pos.y += ball.vBallY;

    // ── ROLLING FRICTION: HaxBall-style deceleration each tick ───────────────
    // Rocket shots are faster, retain less friction (power shot feel)
    if (ball.isRocketShot) {
      ball.vBallX *= 0.9985;
      ball.vBallY *= 0.9985;
    } else {
      ball.vBallX *= 0.9954;
      ball.vBallY *= 0.9954;
    }

    // ── INELASTIC WALL BOUNCE: lose energy on impact (like a real football) ──
    // Üst/alt çizgi (y < 0.02 veya y > 0.98)
    if (ball.pos.y < 0.02) {
      ball.pos.y = 0.02 + (0.02 - ball.pos.y); // yansıt
      ball.vBallY = -(ball.vBallY * 0.62); // enerji kaybı: %38 absorpsiyon
      ball.vBallX *= 0.88; // yönsel sürtünme
      if (!ball.shotBounced) {
        _logVariant([
          '🏀 Top duvara çarptı!',
          '🪃 Kenar çizgisinden sektı!',
          '💥 Duvar! Top döndü!',
        ], Colors.white54);
        ball.shotBounced = true;
      }
    } else if (ball.pos.y > 0.98) {
      ball.pos.y = 0.98 - (ball.pos.y - 0.98);
      ball.vBallY = -(ball.vBallY * 0.62);
      ball.vBallX *= 0.88;
      if (!ball.shotBounced) {
        _logVariant([
          '🏀 Top duvara çarptı!',
          '🪃 Kenar çizgisinden sektı!',
          '💥 Duvar! Top döndü!',
        ], Colors.white54);
        ball.shotBounced = true;
      }
    }

    ball.passTicksRemaining--;
    if (ball.passTicksRemaining > 0) return;

    // Shot arrived – resolve
    if (ball.shotWillGoal) {
      _goal(ball.shotIsHome, ball.shotShooterName);
    } else {
      SimPlayer? gk = ball.shotGk;
      bool goRight = ball.shotIsHome;

      if (!ball.shotOnTarget) {
        _log('❌ İskalık! ${ball.shotShooterName}', Colors.grey);
        bool nearBase =
            goRight ? ball.passFrom.x > 0.72 : ball.passFrom.x < 0.28;
        if (nearBase && _rng.nextBool()) {
          _triggerCorner(!ball.shotIsHome, ball.passTo.y);
        } else {
          // Off target → defending GK gets the ball immediately
          var defTeam = ball.shotIsHome ? awayTeam : homeTeam;
          var defGK = defTeam.firstWhere((p) => p.role == 'GK',
              orElse: () => defTeam.first);
          ball.owner = defGK;
          ball.phase = BallPhase.owned;
          ball.pos.set(defGK.pos);
          _log('🧤 ${defGK.data.name} topu aldı (isabetsiz şut)',
              Colors.cyanAccent);
        }
      } else {
        // On target but GK saves
        _gkSave(gk);
      }
    }
  }

  void _gkSave(SimPlayer? gk) {
    if (gk == null) {
      ball.phase = BallPhase.free;
      return;
    }

    String saveMsg =
        (_saveComments[_rng.nextInt(_saveComments.length)]) + gk.data.name;
    _log(saveMsg, Colors.cyanAccent);
    ball.pos.set(gk.pos);

    // Kurtarış animasyonu tetikle
    _gkSaveActive = true;
    _gkSavingPlayer = gk;
    _gkSaveTimer = 72;
    _insight(gk).update(tackle: true);
    _insight(gk).rating = (_insight(gk).rating + 0.55).clamp(4.0, 10.0);

    int outcome = _rng.nextInt(100);

    if (outcome < 20) {
      // ── RICOCHET: ball bounces to a MID zone (NOT near goal mouth) ──
      // Send it toward the center/middle of the field
      bool saveAtRightGoal = ball.shotIsHome;
      double rebX = saveAtRightGoal
          ? 0.40 + _rng.nextDouble() * 0.25 // bounces well away from goal
          : 0.35 + _rng.nextDouble() * 0.25;
      double rebY = 0.20 + _rng.nextDouble() * 0.60;
      ball.owner = null;
      ball.phase = BallPhase.free;
      ball.pos = Pos(rebX, rebY);
      _log('💥 Top sekti! Orta saha!', Colors.orangeAccent);
    } else if (outcome < 65) {
      // ── DISTRIBUTION: GK throws DEEP to a DEF or MID (build from back) ──
      var ownTeam = gk.isHome ? homeTeam : awayTeam;
      // Prefer DEF/MID first, and pick the FURTHEST (most open) one
      // Dağıtımda önce MID veya FWD tercih et – topu öne taşı
      var defMid = ownTeam
          .where((p) =>
              p != gk &&
              (p.role == 'MID' ||
                  p.role == 'CAM' ||
                  p.role == 'FWD' ||
                  p.role == 'WING' ||
                  p.role == 'ST' ||
                  p.role == 'DEF'))
          .toList();
      var targets = defMid.isNotEmpty
          ? defMid
          : ownTeam.where((p) => p != gk && p.role != 'GK').toList();
      if (targets.isNotEmpty) {
        // Pick the furthest open teammate to build from back
        targets
            .sort((a, b) => b.pos.dist(gk.pos).compareTo(a.pos.dist(gk.pos)));
        SimPlayer recv = targets.first;
        _log('🧤➡ ${gk.data.name} geriden ${recv.data.name}\'e dağıttı',
            Colors.lightBlueAccent);
        ball.owner = null;
        ball.phase = BallPhase.passFlight;
        ball.passFrom.set(gk.pos);
        ball.passTo.set(recv.pos);
        ball.passTarget = recv;
        ball.passTicksTotal =
            max(20, (gk.pos.dist(recv.pos) * 70 * _passTicksMult()).round());
        ball.passTicksRemaining = ball.passTicksTotal;
      } else {
        ball.owner = gk;
        ball.phase = BallPhase.owned;
      }
    } else {
      // ── HOLD: GK catches cleanly ──
      ball.owner = gk;
      ball.phase = BallPhase.owned;
      _log('${gk.data.name} kucakladı', Colors.white54);
    }
  }

  // ─── GOAL ───────────────────────────────────────────────────────────────────

  void _goal(bool homeScored, String scorer) {
    isGoal = true;
    if (homeScored) {
      homeScore++;
      _homeLastGoalTick = tick;
    } else {
      awayScore++;
      _awayLastGoalTick = tick;
    }
    // ── Hızlı gol tespiti: rakip golünden kısa süre sonra gol geldi mi? ──────
    int oppLastGoalTick = homeScored ? _awayLastGoalTick : _homeLastGoalTick;
    bool isQuickReply = oppLastGoalTick > 0 && (tick - oppLastGoalTick) < 180;

    String celebPrefix = isQuickReply
        ? '⚡ HIZLI CEVAP! '
        : _goalComments[_rng.nextInt(_goalComments.length)];
    goalCelebText = '⚽ GOOOL!\n$scorer\n${homeScore} - ${awayScore}';
    _log('${celebPrefix}$scorer  $homeScore-$awayScore', Colors.yellowAccent);

    // Scorer insight
    var scorerPlayer = [...homeTeam, ...awayTeam]
        .firstWhereOrNull((p) => p.data.name == scorer);
    if (scorerPlayer != null) _insight(scorerPlayer).update(goal: true);

    // Topu kaleye gönder (fiziksel)
    double goalX = homeScored ? 0.985 : 0.015;
    ball.pos = Pos(goalX, 0.5);
    ball.owner = null;
    ball.phase = BallPhase.free;

    _goalAnim.forward(from: 0);

    setState(() {});

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        isGoal = false;
        _kickoff(homeScored ? awayTeam : homeTeam);
      });
    });
  }

  // ─── CORNER ─────────────────────────────────────────────────────────────────

  void _triggerCorner(bool forHome, double lastY) {
    ball.phase = BallPhase.cornerDelay;
    ball.cornerForHome = forHome;
    ball.cornerCountdown = 90; // ~1.5s

    bool goRight = forHome;
    double cx = goRight ? 0.99 : 0.01;
    double cy = lastY < 0.5 ? 0.02 : 0.98;
    ball.pos = Pos(cx, cy);

    var takingTeam = forHome ? homeTeam : awayTeam;
    SimPlayer taker = takingTeam.fold(
        takingTeam.first, (b, p) => p.passStat > b.passStat ? p : b);

    taker.pos.set(Pos(cx, cy));
    taker.moveTarget.set(Pos(cx, cy));
    taker.isCornering = true;
    ball.owner = taker;

    double penX = goRight ? 0.82 : 0.18;
    for (var p in takingTeam) {
      if (p != taker && p.role != 'GK') {
        p.moveTarget = Pos(penX, 0.22 + _rng.nextDouble() * 0.56);
      }
    }

    _log('🚩 Korner! ${taker.data.name} kullanacak…', Colors.purpleAccent);
    // Corner stats
    if (forHome)
      _homeCorners++;
    else
      _awayCorners++;
  }

  void _cornerDelayPhase() {
    ball.cornerCountdown--;
    if (ball.cornerCountdown > 0) return;

    var taking = ball.cornerForHome ? homeTeam : awayTeam;
    var defending = ball.cornerForHome ? awayTeam : homeTeam;
    var recv = taking.where((p) => p != ball.owner && p.role != 'GK').toList();
    if (recv.isEmpty) {
      ball.phase = BallPhase.free;
      return;
    }

    if (ball.owner != null) ball.owner!.isCornering = false;

    // ─── KAFA DÜELLOSU: en iyi başlık yapan atakçı vs defansçı ──────────────
    SimPlayer atkHeader = recv.reduce((a, b) {
      int aS = (a.stats['Fizik'] ?? 10) * 3 + (a.stats['Hız'] ?? 10);
      int bS = (b.stats['Fizik'] ?? 10) * 3 + (b.stats['Hız'] ?? 10);
      return bS > aS ? b : a;
    });

    var defHeaders = defending.where((p) => p.role == 'DEF').toList();
    SimPlayer? defChallenger = defHeaders.isNotEmpty
        ? defHeaders.reduce((a, b) {
            int aS = (a.stats['Fizik'] ?? 10) * 3 + (a.stats['Defans'] ?? 10);
            int bS = (b.stats['Fizik'] ?? 10) * 3 + (b.stats['Defans'] ?? 10);
            return bS > aS ? b : a;
          })
        : null;

    int atkScore = (atkHeader.stats['Fizik'] ?? 10) * 4 +
        (atkHeader.stats['Şut'] ?? 10) * 2 +
        _rng.nextInt(40);
    int defScore = defChallenger != null
        ? (defChallenger.stats['Fizik'] ?? 10) * 4 +
            (defChallenger.stats['Defans'] ?? 10) * 2 +
            _rng.nextInt(40)
        : 0;

    SimPlayer target;
    bool atkWon = atkScore > defScore;
    if (atkWon) {
      target = atkHeader;
      _log('🤜 ${atkHeader.data.name} kafa düellosunu KAZANDI!',
          Colors.orangeAccent);
      target.shootOnReceive = true; // Doğrudan şut atar
    } else if (defChallenger != null) {
      target = defChallenger;
      _log('🤛 ${defChallenger.data.name} kafayı uzaklaştırdı!',
          Colors.lightBlueAccent);
    } else {
      target = recv.reduce(
          (a, b) => a.pos.dist(ball.pos) < b.pos.dist(ball.pos) ? a : b);
    }

    _log('⤴ Korner ${atkWon ? "hücum" : "savunma"} başlığına!',
        Colors.purpleAccent);

    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(ball.pos);
    ball.passTo.set(target.moveTarget);
    ball.passTarget = target;
    ball.passTicksTotal = max(22, (52 * _passTicksMult()).round());
    ball.passTicksRemaining = ball.passTicksTotal;
  }

  // ─── FREE BALL ──────────────────────────────────────────────────────────────

  void _freeBallPhase() {
    var all = [...homeTeam, ...awayTeam];
    bool ballInHomeHalf = ball.pos.x < 0.5;

    SimPlayer? nearest;
    double minD = 999;
    for (var p in all) {
      double d = p.pos.dist(ball.pos);
      // Only nearby players sprint to ball; distant players hold tactical shape
      if (d < 0.55) p.moveTarget.set(ball.pos);

      bool isDefending =
          (p.isHome && !ballInHomeHalf) || (!p.isHome && ballInHomeHalf);
      double teamPwr = p.isHome ? _homePower : _awayPower;
      double oppPwr = p.isHome ? _awayPower : _homePower;
      double powerBonus = ((teamPwr - oppPwr) * 0.0012).clamp(-0.04, 0.06);
      double effectiveD = isDefending
          ? max(0.0, d - 0.065 - powerBonus)
          : max(0.0, d - powerBonus);

      if (effectiveD < minD) {
        minD = effectiveD;
        nearest = p;
      }
    }
    // Actual physical pickup range still uses real distance
    double realD = nearest != null ? nearest.pos.dist(ball.pos) : 999;
    if (nearest != null && realD < 0.065) {
      ball.owner = nearest;
      ball.phase = BallPhase.owned;
      ball.pos.set(nearest.pos); // sync ball to owner immediately on pickup
      _log('⚽ ${nearest.data.name} topu aldı',
          nearest.isHome ? Colors.lightBlue : Colors.redAccent);
      _triggerCounterRun(nearest);
    }
  }

  // ─── FORCE BALL HANDOVER ────────────────────────────────────────────────────

  /// Called when ball is static >1.5 s.
  /// Releases ball as free at its current position – NO instant ownership snap.
  /// _freeBallPhase naturally awards it to the nearest player who reaches it.
  void _forcePassToBall() {
    ball.owner = null;
    ball.passTarget = null;
    ball.phase = BallPhase.free;
    // ball.pos stays where it is; _freeBallPhase handles pickup
  }

  // ─── TACKLE ─────────────────────────────────────────────────────────────────

  void _beenTackled(SimPlayer owner, SimPlayer tackler) {
    if (_rng.nextInt(100) < max(15, tackler.defStat - owner.dribbleStat + 38)) {
      // Foul chance: sert müdahale veya düşük defans statı
      int foulChance = max(5, 30 - tackler.defStat ~/ 5);
      if (!_isFreeKick && _rng.nextInt(100) < foulChance) {
        _triggerFoul(owner, tackler);
        return;
      }
      ball.owner = tackler;
      ball.phase = BallPhase.owned;
      ball.pos.set(tackler.pos);
      // Tackle stats
      if (tackler.isHome)
        _homeTackles++;
      else
        _awayTackles++;
      _insight(tackler).update(tackle: true);
      _log('⚔️ ${tackler.data.name} topladı!', Colors.orangeAccent);
      _maybeTriggerGegen(owner.isHome);
      _triggerCounterRun(tackler);
    }
  }

  void _triggerFoul(SimPlayer fouled, SimPlayer tackler) {
    // ── CEZA SAHASI KONTROLÜ: penalti mi, serbest vuruş mu? ─────────────────
    bool inPenArea = fouled.isHome
        ? (fouled.pos.x > 0.83 && fouled.pos.y > 0.22 && fouled.pos.y < 0.78)
        : (fouled.pos.x < 0.17 && fouled.pos.y > 0.22 && fouled.pos.y < 0.78);
    if (inPenArea && tackler.isHome != fouled.isHome) {
      if (tackler.isHome)
        _homeFouls++;
      else
        _awayFouls++;
      _log(
          '🟥 PENALTİ! ${tackler.data.name} → ${fouled.data.name} (Ceza sahası!)',
          Colors.redAccent);
      _triggerPenalty(fouled.isHome);
      return;
    }

    _isFreeKick = true;
    _freeKickForHome = fouled.isHome;
    _freeKickPos = fouled.pos.copy();
    ball.owner = null;
    ball.phase = BallPhase.free;
    ball.pos.set(_freeKickPos);

    // ── KART SİSTEMİ: 2. sarı = kırmızı, oyuncu sahadan atılır ─────────────
    bool yellowCard = _rng.nextInt(100) < 22;
    bool directRed = _rng.nextInt(100) < 5; // Ağır faul direkt kırmızı
    String card = '';

    if (directRed && !_redCardedPlayers.contains(tackler.data.name)) {
      _redCardedPlayers.add(tackler.data.name);
      if (tackler.isHome) {
        _homeYellows++;
        _homeReds++;
      } else {
        _awayYellows++;
        _awayReds++;
      }
      card = ' 🟥 KIRMIZI KART!';
      tackler.pos = Pos(-5.0, -5.0);
      tackler.moveTarget = Pos(-5.0, -5.0);
      _log('🟥 KIRMIZI KART! ${tackler.data.name} SAHADAN ATILDI!',
          Colors.redAccent);
    } else if (yellowCard) {
      int prevY = _playerYellowCount[tackler.data.name] ?? 0;
      _playerYellowCount[tackler.data.name] = prevY + 1;
      if (prevY >= 1 && !_redCardedPlayers.contains(tackler.data.name)) {
        _redCardedPlayers.add(tackler.data.name);
        if (tackler.isHome)
          _homeReds++;
        else
          _awayReds++;
        card = ' 🟨🟥 2. SARI = KIRMIZI!';
        tackler.pos = Pos(-5.0, -5.0);
        tackler.moveTarget = Pos(-5.0, -5.0);
        _log(
            '🟨→🟥 ${tackler.data.name} 2. Sarı ile ATILDI!', Colors.redAccent);
      } else {
        card = ' 🟨 Sarı Kart!';
      }
      if (tackler.isHome)
        _homeYellows++;
      else
        _awayYellows++;
    }

    // Foul stats
    if (tackler.isHome)
      _homeFouls++;
    else
      _awayFouls++;

    _logVariant([
      '🚨 Faul! ${tackler.data.name} → ${fouled.data.name}$card',
      '⚠️ Sert giriş! ${tackler.data.name}$card',
      '🦵 ${tackler.data.name} durdurdu$card',
    ], Colors.redAccent);

    // Foul bekleme süresi (ms)
    int waitMs = speed == MatchSpeed.slow
        ? 2600
        : speed == MatchSpeed.medium
            ? 1200
            : 600;
    var team = _freeKickForHome ? homeTeam : awayTeam;
    SimPlayer taker =
        team.fold(team.first, (b, p) => p.passStat > b.passStat ? p : b);

    Future.delayed(Duration(milliseconds: waitMs), () {
      if (!mounted || isMatchOver || isGoal) return;
      _isFreeKick = false;
      taker.pos.set(_freeKickPos);
      taker.vx = 0;
      taker.vy = 0;
      ball.owner = taker;
      ball.pos.set(_freeKickPos);
      ball.phase = BallPhase.owned;
      _log('⚡ ${taker.data.name} serbest vuruş kullandı',
          Colors.lightBlueAccent);
    });
  }

  // ─── OFSİDE (OFFSIDE) ────────────────────────────────────────────────────────

  void _triggerOffside(SimPlayer passer) {
    _isFreeKick = true;
    _freeKickForHome = !passer.isHome; // savunan takım serbest vuruş alır
    _freeKickPos = ball.pos.copy();
    ball.owner = null;
    ball.phase = BallPhase.free;
    ball.pos.set(_freeKickPos);

    if (passer.isHome)
      _homeFouls++;
    else
      _awayFouls++;

    _logVariant([
      '🚩 OFSAYT! ${passer.data.name} – Serbest vuruş',
      '🚩 Ofsayt bayrağı! Pozisyon iptal',
      '🚩 Çok ilerde! Ofsayt – ${passer.data.name}',
    ], Colors.yellowAccent);

    int waitMs = speed == MatchSpeed.slow
        ? 2200
        : speed == MatchSpeed.medium
            ? 950
            : 480;
    var team = _freeKickForHome ? homeTeam : awayTeam;
    SimPlayer taker =
        team.fold(team.first, (b, p) => p.passStat > b.passStat ? p : b);

    Future.delayed(Duration(milliseconds: waitMs), () {
      if (!mounted || isMatchOver || isGoal) return;
      setState(() {
        _isFreeKick = false;
        taker.pos.set(_freeKickPos);
        taker.vx = 0;
        taker.vy = 0;
        ball.owner = taker;
        ball.pos.set(_freeKickPos);
        ball.phase = BallPhase.owned;
      });
      _log(
          '⚡ ${taker.data.name} ofsayt serbest vuruşu', Colors.lightBlueAccent);
    });
  }

  // ─── PENALTİ ATIŞI ───────────────────────────────────────────────────────────

  /// Ceza sahası içindeki faulde penalti atışı verilir.
  void _triggerPenalty(bool forHome) {
    _isFreeKick = false;
    ball.owner = null;
    ball.phase = BallPhase.free;

    var attackTeam = forHome ? homeTeam : awayTeam;
    var defendTeam = forHome ? awayTeam : homeTeam;

    SimPlayer taker = attackTeam.fold(
        attackTeam.first, (b, p) => p.shootStat > b.shootStat ? p : b);
    SimPlayer gk = defendTeam.firstWhere((p) => p.role == 'GK',
        orElse: () => defendTeam.first);

    // Penalti başlangıç pozisyonu: ceza noktası
    double penX = forHome ? 0.12 : 0.88;
    taker.pos.set(Pos(penX, 0.5));
    taker.vx = 0;
    taker.vy = 0;
    ball.pos.set(Pos(penX, 0.5));
    ball.owner = taker;
    ball.phase = BallPhase.owned;

    // Başarı oranı: %72-90 arası (shoot stat'a göre)
    double successRate = 0.72 + (taker.shootStat / 100.0) * 0.18;
    bool scores = _rng.nextDouble() < successRate;

    _log('🟥 PENALTİ! ${taker.data.name} vuracak...', Colors.redAccent);

    int waitMs = speed == MatchSpeed.slow
        ? 2500
        : speed == MatchSpeed.medium
            ? 1200
            : 600;
    Future.delayed(Duration(milliseconds: waitMs), () {
      if (!mounted || isMatchOver) return;
      if (scores) {
        _logVariant([
          '⚽ PENALTİ GOL! ${taker.data.name}!!',
          '💥 PENALTI GOLÜ! ${taker.data.name} atmadı mı?',
          '🎯 SOĞUKKANLILIĞA BAKTI! ${taker.data.name}',
        ], Colors.yellowAccent);
        _goal(forHome, taker.data.name);
      } else {
        _logVariant([
          '🧤 PENALTİYİ KURTARDI! ${gk.data.name}!',
          '🧤 ${gk.data.name} penaltıyı önledi! EFSANE!',
          '🧤 Direğin dibi – ${gk.data.name} atladı!',
        ], Colors.cyanAccent);
        ball.owner = gk;
        ball.phase = BallPhase.owned;
        ball.pos.set(gk.pos);
      }
      setState(() {});
    });
  }

  // ─── COUNTER ATTACK SPRINT ──────────────────────────────────────────────────

  /// Kontra Atak taktiğindeyken top kazanıldığı anda FWD ve bazı MID'ler
  /// anında hücum bölgesine sprint yapar.
  void _triggerCounterRun(SimPlayer newOwner) {
    TacticStyle tac = _myTactic(newOwner.isHome);
    if (tac != TacticStyle.counter) return;
    bool goRight = newOwner.isHome;
    bool inOwnHalf = goRight ? newOwner.pos.x < 0.52 : newOwner.pos.x > 0.48;
    if (!inOwnHalf) return;
    var myTeam = newOwner.isHome ? homeTeam : awayTeam;
    for (var p in myTeam) {
      if (p == newOwner || p.role == 'GK') continue;
      if (p.role == 'FWD' || p.role == 'ST' || p.role == 'WING') {
        double tx = (goRight
                ? 0.76 + _rng.nextDouble() * 0.14
                : 0.10 + _rng.nextDouble() * 0.14)
            .clamp(0.05, 0.95);
        p.moveTarget = Pos(tx, 0.18 + _rng.nextDouble() * 0.64);
      } else if ((p.role == 'MID' || p.role == 'CAM') && _rng.nextBool()) {
        double tx = (goRight
                ? 0.55 + _rng.nextDouble() * 0.22
                : 0.23 + _rng.nextDouble() * 0.22)
            .clamp(0.05, 0.95);
        p.moveTarget = Pos(tx, 0.20 + _rng.nextDouble() * 0.60);
      }
    }
    _log('⚡ Kontra! ${newOwner.data.name} öne çıkıyor', Colors.yellowAccent);
  }

  void _maybeTriggerGegen(bool losingIsHome) {
    TacticStyle tac = _myTactic(losingIsHome);
    if (tac != TacticStyle.gegen && tac != TacticStyle.highPress) return;

    var losingTeam = losingIsHome ? homeTeam : awayTeam;
    var sorted = List<SimPlayer>.from(losingTeam)
      ..sort((a, b) => a.pos.dist(ball.pos).compareTo(b.pos.dist(ball.pos)));

    int n = (3 + _rng.nextInt(4)).clamp(3, min(6, sorted.length));
    for (int i = 0; i < n; i++) {
      sorted[i].isPressing = true;
      sorted[i].pressTimer = 180;
    }
    _log('💢 Gegenpres! $n oyuncu baskı yapıyor',
        Colors.orange.withOpacity(0.85));
  }

  // ─── PLAYER MOVEMENT (non-owner) ────────────────────────────────────────────

  /// Rol bazlı markaj hedefini döndürür. null = markaj yok
  SimPlayer? _resolveMarkTarget(SimPlayer p) {
    var opp = p.isHome ? awayTeam : homeTeam;
    if (opp.isEmpty) return null;

    // GK: kendi takımı topdayken rakibin FWD'sini (idx 5) markaj yapabilir
    if (p.role == 'GK') {
      bool ownHasBall = ball.owner != null && ball.owner!.isHome == p.isHome;
      if (!ownHasBall) return null;
      var targets = opp.where((o) => o.role == 'FWD').toList();
      if (targets.isEmpty) return null;
      // En yakın FWD'yi seç ama kaleye çok yakın olmasın
      targets.sort((a, b) => a.pos.dist(p.pos).compareTo(b.pos.dist(p.pos)));
      return targets.first;
    }

    // DEF: marks opponent attackers (ST, WING, FWD)
    if (p.role == 'DEF') {
      var oppAtk = opp
          .where((o) => o.role == 'ST' || o.role == 'WING' || o.role == 'FWD')
          .toList();
      if (oppAtk.isEmpty) return null;
      oppAtk.sort((a, b) => a.playerIndex.compareTo(b.playerIndex));
      int pick = (p.playerIndex == 1) ? 0 : (oppAtk.length > 1 ? 1 : 0);
      return oppAtk[pick.clamp(0, oppAtk.length - 1)];
    }

    // CAM: marks opponent's CAM or MID
    if (p.role == 'CAM') {
      var oppMid =
          opp.where((o) => o.role == 'CAM' || o.role == 'MID').toList();
      if (oppMid.isNotEmpty) {
        oppMid.sort((a, b) => a.pos.dist(p.pos).compareTo(b.pos.dist(p.pos)));
        return oppMid.first;
      }
      return null;
    }

    // WING: marks opponent WING on same side (direct duel)
    if (p.role == 'WING') {
      var oppWings =
          opp.where((o) => o.role == 'WING' || o.role == 'FWD').toList();
      if (oppWings.isEmpty) return null;
      bool defending = ball.owner != null && ball.owner!.isHome != p.isHome;
      if (!defending) return null;
      oppWings.sort((a, b) => a.pos.dist(p.pos).compareTo(b.pos.dist(p.pos)));
      return oppWings.first;
    }

    // ST: marks opponent DEF when defending
    if (p.role == 'ST' || p.role == 'FWD') {
      bool defending = ball.owner != null && ball.owner!.isHome != p.isHome;
      if (!defending) return null;
      var oppDefs = opp.where((o) => o.role == 'DEF').toList();
      if (oppDefs.isEmpty) return null;
      oppDefs.sort((a, b) => a.playerIndex.compareTo(b.playerIndex));
      return oppDefs.first;
    }

    return null;
  }

  // Takım toplu olduğunda yayılma pozisyonunu hesapla
  Pos _spreadPosition(SimPlayer p, Pos ballPos) {
    bool goRight = p.isHome;
    // Y channels per slot – new 1-2-1-2-1 formation spread
    const spreadY = [0.50, 0.22, 0.78, 0.50, 0.08, 0.92, 0.50];
    double ty = spreadY[p.playerIndex.clamp(0, 6)];

    double tx;
    switch (p.role) {
      case 'GK':
        return p.homeBase.copy();
      case 'DEF':
        tx = goRight
            ? (ballPos.x - 0.22).clamp(0.08, 0.40)
            : (ballPos.x + 0.22).clamp(0.60, 0.92);
        break;
      case 'CAM':
        tx = goRight
            ? (ballPos.x + 0.04).clamp(0.36, 0.75)
            : (ballPos.x - 0.04).clamp(0.25, 0.64);
        break;
      case 'WING':
        bool isLeft = p.playerIndex == 4;
        tx = goRight
            ? (ballPos.x + 0.14).clamp(0.48, 0.92)
            : (ballPos.x - 0.14).clamp(0.08, 0.52);
        ty = isLeft ? 0.08 : 0.92;
        break;
      case 'ST':
        tx = goRight
            ? (ballPos.x + 0.18).clamp(0.58, 0.94)
            : (ballPos.x - 0.18).clamp(0.06, 0.42);
        break;
      case 'FWD': // legacy
        tx = goRight
            ? (ballPos.x + 0.16).clamp(0.52, 0.92)
            : (ballPos.x - 0.16).clamp(0.08, 0.48);
        break;
      case 'MID': // legacy
        tx = goRight
            ? (ballPos.x - 0.06).clamp(0.30, 0.72)
            : (ballPos.x + 0.06).clamp(0.28, 0.70);
        break;
      default:
        tx = p.homeBase.x;
    }
    return Pos(tx, ty);
  }

  void _updateMovementTarget(SimPlayer p) {
    // ─── PASS RECEIVER: always run to locked arrival point ──────────────────
    if (ball.phase == BallPhase.passFlight && ball.passTarget == p) {
      p.moveTarget.set(ball.passTo); // keep running to where ball will arrive
      return;
    }

    // ─── GK: açı daraltma + live Y takibi ────────────────────────────────────
    if (p.role == 'GK') {
      bool ownHasBall = ball.owner != null && ball.owner!.isHome == p.isHome;
      double ballRefY = ball.pos.y;
      bool goRight = p.isHome;

      if (ownHasBall) {
        // Takım topla: direk yakınında dur, biraz Y'ye eğil
        double gy = (ballRefY * 0.20 + p.homeBase.y * 0.80).clamp(0.28, 0.72);
        p.moveTarget = Pos(p.homeBase.x, gy);
      } else {
        // ─── AÇI DARALTMA: GK atıcı – kale merkezi hattında ileri çıkar ─────
        bool oppInFinalThird = goRight ? ball.pos.x > 0.60 : ball.pos.x < 0.40;
        double idealY = ballRefY.clamp(0.24, 0.76);

        if (oppInFinalThird) {
          // Kalecinin kale hattından ne kadar ileri çıkacağı (t=0 kale, t=1 atıcı)
          const double t2 = 0.26;
          double narrowX = p.homeBase.x + (ball.pos.x - p.homeBase.x) * t2;
          double maxStep = 0.09;
          double clampedX = goRight
              ? narrowX.clamp(p.homeBase.x, p.homeBase.x + maxStep)
              : narrowX.clamp(p.homeBase.x - maxStep, p.homeBase.x);
          double narrowY = ball.pos.y * 0.55 + 0.5 * 0.45;
          p.moveTarget = Pos(clampedX, narrowY.clamp(0.24, 0.76));
        } else {
          // Uzak durumdayken normal kale hattında
          p.moveTarget = Pos(p.homeBase.x, idealY);
        }
      }
      return;
    }

    // During shot flight: players anticipate rebound
    if (ball.phase == BallPhase.shotFlight) {
      bool goRight = p.isHome;
      bool attacking = p.role == 'FWD' || p.role == 'MID';
      if (attacking) {
        // Rush toward rebound zone
        double rebX = goRight
            ? 0.78 + _rng.nextDouble() * 0.12
            : 0.10 + _rng.nextDouble() * 0.12;
        p.moveTarget = Pos(rebX, 0.28 + _rng.nextDouble() * 0.44);
      } else if (tick % 7 == p.playerIndex % 7) {
        p.moveTarget.x = (p.moveTarget.x + (_rng.nextDouble() - 0.5) * 0.04)
            .clamp(0.04, 0.96);
        p.moveTarget.y = (p.moveTarget.y + (_rng.nextDouble() - 0.5) * 0.035)
            .clamp(0.04, 0.96);
      }
      return;
    }

    // Gegenpres overrides everything
    if (p.isPressing) {
      p.pressTimer--;
      if (p.pressTimer <= 0) {
        p.isPressing = false;
        p.moveTarget.set(p.homeBase);
      } else {
        p.moveTarget.set(ball.pos);
      }
      return;
    }

    // Wide talimatı
    if (p.instruction.stayWide) {
      bool isLeft = p.homeBase.y < 0.5;
      p.moveTarget.y = isLeft ? 0.07 : 0.93;
      if (ball.owner != null) {
        p.moveTarget.x =
            (ball.owner!.pos.x + (p.isHome ? 0.10 : -0.10)).clamp(0.08, 0.92);
      }
      return;
    }

    // Manuel markaj talimatı
    if (p.instruction.marking) {
      var opp = p.isHome ? awayTeam : homeTeam;
      if (opp.isNotEmpty) {
        var mark =
            opp.reduce((a, b) => a.pos.dist(p.pos) < b.pos.dist(p.pos) ? a : b);
        p.markTarget = mark;
        p.moveTarget = Pos(mark.pos.x + (p.isHome ? -0.04 : 0.04), mark.pos.y);
      }
      return;
    }

    // Sürekli koşu talimatı
    if (p.instruction.constantRuns &&
        ball.owner != null &&
        ball.owner!.isHome == p.isHome) {
      bool goRight = p.isHome;
      p.moveTarget = Pos(
        goRight
            ? 0.74 + _rng.nextDouble() * 0.16
            : 0.10 + _rng.nextDouble() * 0.16,
        0.24 + _rng.nextDouble() * 0.52,
      );
      return;
    }

    // Use ball.pos as reference during flights too
    Pos ballRef = ball.pos;
    bool ownTeamHasBall =
        (ball.owner != null && (ball.owner!.isHome == p.isHome)) ||
            (ball.isCornerTrick &&
                ball.cornerTrickRunner != null &&
                ball.cornerTrickRunner!.isHome == p.isHome);
    SimPlayer? bo = ball.owner;

    // ── YÜKLEME BASKISI: rakip kendi sahasında topla – hücum oyuncuları presler ──
    if (!ownTeamHasBall && bo != null && p.role != 'GK') {
      bool oppDeepInDef = p.isHome
          ? ballRef.x < 0.38 // rakip (away) kendi ceza sahası önünde
          : ballRef.x > 0.62; // rakip (home) kendi ceza sahası önünde
      bool isAttacker = p.role == 'ST' ||
          p.role == 'WING' ||
          p.role == 'CAM' ||
          p.role == 'FWD';
      if (oppDeepInDef && isAttacker) {
        // Topa doğru agresif pres
        double pressX =
            (ballRef.x + (p.isHome ? 0.06 : -0.06)).clamp(0.05, 0.92);
        double pressY =
            (ballRef.y * 0.55 + p.homeBase.y * 0.45).clamp(0.05, 0.95);
        p.moveTarget = Pos(pressX, pressY);
        // Yakınsa müdahale
        if (p.pos.dist(bo.pos) < 0.11) {
          if (_rng.nextInt(100) < max(8, p.defStat - bo.dribbleStat + 26)) {
            _beenTackled(bo, p);
          }
        }
        _constrainByTactic(p);
        _applySeparation(p);
        return;
      }
    }

    // ── OTOMATİK MAN-MARKING sistemi ──
    // Markaj hedefini güncelle (sadece savunma pozisyonundayken)
    SimPlayer? autoMark = _resolveMarkTarget(p);
    p.markTarget = autoMark;

    if (!ownTeamHasBall && autoMark != null && p.role != 'GK') {
      // ── DEF: savunma hattı + kaçan forvetleri aktif takip ──
      if (p.role == 'DEF') {
        bool goRight = p.isHome;
        // Our penalty box edge – last line of defence
        double boxEdge = goRight ? 0.83 : 0.17;
        // Chase the marked runner: blend between box-edge and attacker's actual X
        // If attacker has already entered box zone, push tight against them
        double attackerX = autoMark.pos.x;
        bool attackerInBox = goRight ? attackerX > 0.74 : attackerX < 0.26;
        double chaseBlend = attackerInBox ? 0.85 : 0.55; // tighter when in box
        double baseWallX = goRight
            ? min(boxEdge, ballRef.x - 0.06).clamp(0.06, boxEdge)
            : max(boxEdge, ballRef.x + 0.06).clamp(boxEdge, 0.94);
        double chaseX = goRight
            ? min(boxEdge, attackerX - 0.05).clamp(0.06, boxEdge)
            : max(boxEdge, attackerX + 0.05).clamp(boxEdge, 0.94);
        double wallX = baseWallX * (1 - chaseBlend) + chaseX * chaseBlend;
        // Y: each DEF covers a channel; blend tightly toward attacker's Y
        const defChannelY = [0.32, 0.68];
        double channelY = defChannelY[(p.playerIndex == 1) ? 0 : 1];
        // Tight man-marking: 80% attacker Y, wider channel only as fallback
        double targetY = autoMark.pos.y * 0.80 + channelY * 0.20;
        p.moveTarget = Pos(wallX, targetY.clamp(0.05, 0.95));
        // Tackle if attacker walks into defender
        if (p.pos.dist(autoMark.pos) < 0.055 && bo != null) {
          if (_rng.nextInt(100) < max(10, p.defStat - bo.dribbleStat + 32)) {
            _beenTackled(bo, p);
          }
        }
        _constrainByTactic(p);
        _applySeparation(p);
        return;
      }
      // Rakibi gölgele - biraz önünde dur
      double shadowX = autoMark.pos.x + (p.isHome ? -0.04 : 0.04);
      double shadowY = autoMark.pos.y;
      p.moveTarget = Pos(
        shadowX.clamp(0.04, 0.96),
        shadowY.clamp(0.04, 0.96),
      );
      // Yakın geçişte müdahale
      if (p.pos.dist(autoMark.pos) < 0.052 && bo != null) {
        if (_rng.nextInt(100) < max(8, p.defStat - bo.dribbleStat + 30)) {
          _beenTackled(bo, p);
        }
      }
      _constrainByTactic(p);
      _applySeparation(p);
      return;
    }

    if (ownTeamHasBall) {
      // ── TAKIM TOPLU: FM26-style şekil ──
      bool goRight = p.isHome;
      // Recompute target every 4 ticks per player – stable yet responsive
      bool shouldUpdate = (tick % 4 == p.playerIndex % 4);

      // ── KÖŞE DESTEK: takımın WING'i touchline’da köşeye koşuyor veya
      //    cornerTrick aktifte – ST/CAM/FWD/diğer WING kutuya girerek pas bekle ──
      SimPlayer? _activeBo =
          bo ?? (ball.isCornerTrick ? ball.cornerTrickRunner : null);
      bool _friendlyWingOnCornerRun = _activeBo != null &&
          _activeBo.isHome == p.isHome &&
          _activeBo.role == 'WING' &&
          (_activeBo.pos.y < 0.22 || _activeBo.pos.y > 0.78) &&
          (goRight ? _activeBo.pos.x > 0.52 : _activeBo.pos.x < 0.48);
      bool _cornerSupportNeeded =
          _friendlyWingOnCornerRun || ball.isCornerTrick;
      bool _isSupportRole = p.role == 'ST' ||
          p.role == 'CAM' ||
          p.role == 'FWD' ||
          (p.role == 'WING' && (bo == null || bo != p));
      if (_cornerSupportNeeded &&
          _isSupportRole &&
          p.role != 'GK' &&
          (tick % 3 == p.playerIndex % 3)) {
        // Her destek oyuncusu kutunun FARKLI çeyreğine koşsun
        // – sıkışmadan paş alabilsin
        double _supX, _supY;
        // Aktif WING hangi kenarda?
        SimPlayer? _activeWing = _activeBo != null &&
                _activeBo.isHome == p.isHome &&
                _activeBo.role == 'WING'
            ? _activeBo
            : ball.cornerTrickRunner;
        bool _wingTop = _activeWing != null ? _activeWing.pos.y < 0.5 : true;
        switch (p.playerIndex % 4) {
          case 0: // Kutu merkezi – direkt şut pozisyonu
            _supX = (goRight
                    ? 0.72 + _rng.nextDouble() * 0.14
                    : 0.14 + _rng.nextDouble() * 0.14)
                .clamp(0.06, 0.94);
            _supY = 0.38 + _rng.nextDouble() * 0.24;
            break;
          case 1: // Yakın direk
            _supX = (goRight
                    ? 0.78 + _rng.nextDouble() * 0.10
                    : 0.12 + _rng.nextDouble() * 0.10)
                .clamp(0.06, 0.94);
            _supY = _wingTop
                ? 0.54 + _rng.nextDouble() * 0.18
                : 0.28 + _rng.nextDouble() * 0.18;
            break;
          case 2: // Ceza alanı başı
            _supX = (goRight
                    ? 0.64 + _rng.nextDouble() * 0.10
                    : 0.26 + _rng.nextDouble() * 0.10)
                .clamp(0.06, 0.94);
            _supY = 0.32 + _rng.nextDouble() * 0.36;
            break;
          default: // Uzak direk
            _supX = (goRight
                    ? 0.76 + _rng.nextDouble() * 0.12
                    : 0.12 + _rng.nextDouble() * 0.12)
                .clamp(0.06, 0.94);
            _supY = _wingTop
                ? 0.60 + _rng.nextDouble() * 0.20
                : 0.20 + _rng.nextDouble() * 0.20;
        }
        p.moveTarget = Pos(_supX, _supY);
        _applySeparation(p);
        return;
      }

      // ── WING: kendi yolunda ilerle – köşe triki planlandıysa köşeye yönel ──
      if (p.role == 'WING' && (tick % 4 == p.playerIndex % 4)) {
        bool isLeftWing = p.playerIndex == 4;
        double homeY = isLeftWing ? 0.06 : 0.94;

        // Maçta hâlâ köşe triki planı varsa kanat o köşeye yönelsin
        int _wTricksLeft = p.isHome
            ? (_homeCornerTricksMax - _homeCornerTricksDone)
            : (_awayCornerTricksMax - _awayCornerTricksDone);
        // Rakip yarısına girer girmez touchline'a yaslan ve köşeye sprint at
        bool _wDeepEnough = goRight ? p.pos.x > 0.46 : p.pos.x < 0.54;
        if (_wDeepEnough && !ball.isCornerTrick) {
          // Kademeli yaklaşım: önce touchline'a çek, sonra köşeye sprint
          bool _alreadyOnLine = (homeY < 0.5) ? p.pos.y < 0.22 : p.pos.y > 0.78;
          double _cornerRunX;
          double _cornerRunY;
          if (!_alreadyOnLine) {
            // Adım 1: Y'yi touchline'a yaklaştır
            _cornerRunX =
                (p.pos.x + (goRight ? 0.06 : -0.06)).clamp(0.04, 0.96);
            _cornerRunY = homeY;
          } else {
            // Adım 2: X'i köşeye sprint at
            _cornerRunX = (goRight
                    ? 0.80 + _rng.nextDouble() * 0.12
                    : 0.08 + _rng.nextDouble() * 0.12)
                .clamp(0.04, 0.96);
            _cornerRunY = homeY;
          }
          p.moveTarget = Pos(_cornerRunX, _cornerRunY);
          _applySeparation(p);
          return;
        }

        // 3-fazlı çevrim: 0=kanat koşusu  1=içe çekilme  2=ay çizgisi sprint
        int phaseCycle = ((tick ~/ 22) + p.playerIndex * 7) % 3;
        switch (phaseCycle) {
          case 0:
            // Kanattan ilerle – defansı geniş tut (homeY'den ayrılma)
            double wx = (goRight
                    ? 0.70 + sin(tick * 0.08 + p.playerIndex) * 0.16
                    : 0.30 - sin(tick * 0.08 + p.playerIndex) * 0.16)
                .clamp(0.06, 0.94);
            p.moveTarget = Pos(wx, homeY);
            break;
          case 1:
            // Kanattan ileri sprint – homeY'ye sıkı kal
            double inX = (goRight
                    ? 0.72 + _rng.nextDouble() * 0.14
                    : 0.14 + _rng.nextDouble() * 0.14)
                .clamp(0.06, 0.94);
            p.moveTarget = Pos(
                inX, (homeY + (isLeftWing ? 0.06 : -0.06)).clamp(0.04, 0.96));
            break;
          default:
            // Ay çizgisi sprint – geri pas için homeY pozisyon
            double ovX = (goRight
                    ? 0.84 + _rng.nextDouble() * 0.08
                    : 0.08 + _rng.nextDouble() * 0.08)
                .clamp(0.04, 0.96);
            p.moveTarget = Pos(ovX, homeY);
            break;
        }
        _applySeparation(p);
        return;
      }

      // ── ST: kutuda sürekli hareketli – her 20 tickte pozisyon değiştir ───────
      if ((p.role == 'ST' || p.role == 'FWD') &&
          (tick % 4 == p.playerIndex % 4)) {
        // 3 tip koşu sürekli dönüşümlü
        int runType = ((tick ~/ 28) + p.playerIndex * 9) % 3;
        double tx, ty;
        switch (runType) {
          case 0: // Defansçıları ayır – merkezi koşu
            tx = (goRight
                    ? 0.76 + sin(tick * 0.06) * 0.12
                    : 0.24 - sin(tick * 0.06) * 0.12)
                .clamp(0.52, 0.96);
            ty = 0.36 + _rng.nextDouble() * 0.28;
            break;
          case 1: // Yakın direk koşusu
            tx = (goRight
                    ? 0.83 + _rng.nextDouble() * 0.10
                    : 0.07 + _rng.nextDouble() * 0.10)
                .clamp(0.52, 0.96);
            ty = 0.30 + _rng.nextDouble() * 0.14;
            break;
          default: // Uzak direk koşusu
            tx = (goRight
                    ? 0.81 + _rng.nextDouble() * 0.10
                    : 0.09 + _rng.nextDouble() * 0.10)
                .clamp(0.52, 0.96);
            ty = 0.56 + _rng.nextDouble() * 0.14;
            break;
        }
        p.moveTarget = Pos(tx, ty);
        _applySeparation(p);
        return;
      }

      // ── CAM: fluid support – distributor & second forward ───────────────────
      if (p.role == 'CAM' && shouldUpdate && bo != null) {
        bool goRight = p.isHome;
        // Faster cycle (every 22 ticks) so CAM stays very dynamic
        int camCycle = ((tick ~/ 22) + p.playerIndex * 5) % 4;
        switch (camCycle) {
          case 0: // Between midfield & attack – classic #10 position
            double camX = (goRight
                    ? 0.52 + _rng.nextDouble() * 0.22
                    : 0.26 + _rng.nextDouble() * 0.22)
                .clamp(0.10, 0.90);
            // Lean toward ball Y
            double cy0 =
                (0.34 + _rng.nextDouble() * 0.32) * 0.6 + ball.pos.y * 0.4;
            p.moveTarget = Pos(camX, cy0.clamp(0.08, 0.92));
            break;
          case 1: // Penetrating run into box – second striker
            double atkX = (goRight
                    ? 0.70 + _rng.nextDouble() * 0.16
                    : 0.14 + _rng.nextDouble() * 0.16)
                .clamp(0.10, 0.90);
            p.moveTarget = Pos(atkX, 0.30 + _rng.nextDouble() * 0.40);
            break;
          case 2: // Drop deep to receive & distribute
            double linkX = (goRight
                    ? 0.38 + _rng.nextDouble() * 0.18
                    : 0.44 + _rng.nextDouble() * 0.18)
                .clamp(0.10, 0.90);
            p.moveTarget = Pos(
                linkX,
                (ball.pos.y * 0.5 + 0.25 + _rng.nextDouble() * 0.50 * 0.5)
                    .clamp(0.08, 0.92));
            break;
          default: // Wide support run – open a channel
            double wideX = (goRight
                    ? 0.58 + _rng.nextDouble() * 0.20
                    : 0.22 + _rng.nextDouble() * 0.20)
                .clamp(0.06, 0.94);
            p.moveTarget = Pos(
                wideX,
                _rng.nextBool()
                    ? 0.12 + _rng.nextDouble() * 0.16
                    : 0.72 + _rng.nextDouble() * 0.16);
            break;
        }
        _applySeparation(p);
        return;
      }

      // ── MID (legacy): midfield support ──────────────────────────────────────
      if (p.role == 'MID' && shouldUpdate && bo != null) {
        int teamLane = p.isHome ? _homeLane : _awayLane;
        const midZones = [
          [0.28, 0.72], // lane 0 default
          [0.15, 0.85], // lane 1 (stretch wide)
          [0.50, 0.50], // lane 2 (central)
        ];
        double channelY = midZones[teamLane][(p.playerIndex == 3) ? 0 : 1];
        // Orta saha rakip ceza sahasına koşar; oskilasyon ile sürekli hareket
        double targetX = (goRight
                ? 0.68 + sin(tick * 0.028 + p.playerIndex) * 0.16
                : 0.32 - sin(tick * 0.028 + p.playerIndex) * 0.16)
            .clamp(0.48, 0.96);
        p.moveTarget = Pos(targetX, channelY);
        _applySeparation(p);
        return;
      }

      // DEF + others: hold formation shape relative to ball
      if (shouldUpdate && bo != null) {
        Pos spread = _spreadPosition(p, bo.pos);
        // Stable home-base blend (no random) – prevents constant jitter
        p.moveTarget = Pos(
          (spread.x * 0.7 + p.homeBase.x * 0.3).clamp(0.04, 0.96),
          (spread.y * 0.75 + p.homeBase.y * 0.25).clamp(0.04, 0.96),
        );
        _applySeparation(p);
      }
    } else {
      // ── SAVUNMA: compact mid/low block ──
      bool shouldUpdate = (tick % 4 == p.playerIndex % 4);
      if (bo != null && shouldUpdate) {
        bool goRight = p.isHome;
        // Each role drops to a defensive compactness zone
        double blockX;
        switch (p.role) {
          case 'ST':
          case 'FWD':
            // ST presses high – close down the GK/DEF
            blockX = (bo.pos.x + (goRight ? -0.12 : 0.12)).clamp(0.10, 0.90);
            break;
          case 'WING':
            // Wingers track back hard – cover wide channels
            blockX = (bo.pos.x + (goRight ? -0.10 : 0.10)).clamp(0.08, 0.92);
            break;
          case 'CAM':
            // CAM drops to mid-block – protects between lines
            blockX = goRight
                ? (bo.pos.x - 0.06).clamp(0.32, 0.62)
                : (bo.pos.x + 0.06).clamp(0.38, 0.68);
            break;
          case 'MID':
            // Mid-block: stay between ball and our goal
            blockX = goRight
                ? (bo.pos.x - 0.08).clamp(0.28, 0.60)
                : (bo.pos.x + 0.08).clamp(0.40, 0.72);
            break;
          default:
            blockX = p.moveTarget.x; // DEF handled by man-marking above
        }
        double channelBias = p.homeBase.y;
        p.moveTarget = Pos(
          blockX,
          (bo.pos.y * 0.45 + channelBias * 0.55).clamp(0.06, 0.94),
        );
        // Close-range interception attempt
        if (p.pos.dist(bo.pos) < 0.052) {
          if (_rng.nextInt(100) < max(8, p.defStat - bo.dribbleStat + 32)) {
            _beenTackled(bo, p);
          }
        }
      } else if (bo == null && shouldUpdate) {
        // Ball in flight – move to intercept general area
        p.moveTarget = Pos(
          (ballRef.x + (p.isHome ? -0.07 : 0.07)).clamp(0.05, 0.95),
          (ballRef.y * 0.6 + p.homeBase.y * 0.4).clamp(0.05, 0.95),
        );
      }
    }

    _constrainByTactic(p);
    _applySeparation(p);
  }

  /// Takım arkadaşlarıyla yığılmayı önlemek için hafif itme uygular
  void _applySeparation(SimPlayer p) {
    var myTeam = p.isHome ? homeTeam : awayTeam;
    for (var t in myTeam) {
      if (t == p || t == ball.owner) continue;
      double ddx = p.moveTarget.x - t.pos.x;
      double ddy = p.moveTarget.y - t.pos.y;
      double dd = sqrt(ddx * ddx + ddy * ddy);
      if (dd < 0.09 && dd > 0.001) {
        double push = (0.09 - dd) * 0.55;
        p.moveTarget.x = (p.moveTarget.x + ddx / dd * push).clamp(0.04, 0.96);
        p.moveTarget.y = (p.moveTarget.y + ddy / dd * push).clamp(0.04, 0.96);
      }
    }
    // Top sahibinin etrafında yığılmayı önle – kopararak pozisyon al
    if (ball.owner != null &&
        ball.owner != p &&
        ball.owner!.isHome == p.isHome) {
      double ddx = p.moveTarget.x - ball.owner!.pos.x;
      double ddy = p.moveTarget.y - ball.owner!.pos.y;
      double dd = sqrt(ddx * ddx + ddy * ddy);
      if (dd < 0.13 && dd > 0.001) {
        double push = (0.13 - dd) * 0.40;
        p.moveTarget.x = (p.moveTarget.x + ddx / dd * push).clamp(0.04, 0.96);
        p.moveTarget.y = (p.moveTarget.y + ddy / dd * push).clamp(0.04, 0.96);
      }
    }
  }

  void _constrainByTactic(SimPlayer p) {
    if (p.role == 'GK') return;
    TacticStyle tac = _myTactic(p.isHome);
    bool goRight = p.isHome;

    // defLine slider: only applies to player's team (home side when !isPlayerTeamAway)
    bool isPlayerTeam = p.isHome != widget.isPlayerTeamAway;
    double effDefLine = isPlayerTeam ? _defLineVal : 0.5;

    if (tac == TacticStyle.defensive && p.role == 'DEF') {
      double cap = 0.28 + effDefLine * 0.10;
      p.moveTarget.x = goRight
          ? p.moveTarget.x.clamp(0.04, cap)
          : p.moveTarget.x.clamp(1.0 - cap, 0.96);
    }
    if (tac == TacticStyle.counter &&
        p.role == 'DEF' &&
        ball.owner != null &&
        ball.owner!.isHome != p.isHome) {
      double cap = 0.20 + effDefLine * 0.12;
      p.moveTarget.x = goRight
          ? p.moveTarget.x.clamp(0.04, cap)
          : p.moveTarget.x.clamp(1.0 - cap, 0.96);
    }
    // Hücum taktiği: defans hattı ileri çekilir
    if (tac == TacticStyle.attack && p.role == 'DEF') {
      bool ownBall = ball.owner != null && ball.owner!.isHome == p.isHome;
      if (ownBall) {
        double lo = 0.22 + effDefLine * 0.16;
        p.moveTarget.x = goRight
            ? p.moveTarget.x.clamp(lo, 0.66)
            : p.moveTarget.x.clamp(1.0 - 0.66, 1.0 - lo);
      }
    }
    // Yüksek Baskı: defans hattı rakip yarısına kadar yükselir
    if (tac == TacticStyle.highPress && p.role == 'DEF') {
      bool defending = ball.owner != null && ball.owner!.isHome != p.isHome;
      if (defending) {
        double lo = 0.30 + effDefLine * 0.18;
        p.moveTarget.x = goRight
            ? p.moveTarget.x.clamp(lo, 0.72)
            : p.moveTarget.x.clamp(1.0 - 0.72, 1.0 - lo);
      }
    }
    // Width slider: FWD/MID spread wider on pitch when set high (player team only)
    if (isPlayerTeam &&
        _widthVal > 0.6 &&
        (p.role == 'FWD' ||
            p.role == 'MID' ||
            p.role == 'ST' ||
            p.role == 'WING' ||
            p.role == 'CAM')) {
      double push = (_widthVal - 0.5) * 0.28;
      double wideY = p.homeBase.y > 0.5
          ? (p.homeBase.y + push).clamp(0.06, 0.94)
          : (p.homeBase.y - push).clamp(0.06, 0.94);
      p.moveTarget.y = (p.moveTarget.y * 0.72 + wideY * 0.28).clamp(0.06, 0.94);
    }
  }

  void _moveToward(SimPlayer p) {
    double dx = p.moveTarget.x - p.pos.x;
    double dy = p.moveTarget.y - p.pos.y;
    double d = sqrt(dx * dx + dy * dy);
    if (d < 0.004) {
      // Near target: gentle sinusoidal idle sway – drift back toward homeBase,
      // NOT toward the ball (prevents clustering around the owner).
      if (p != ball.owner) {
        double angle = tick * 0.09 + p.playerIndex * 1.31;
        // Drift back toward formation pos to avoid stacking near the ball
        double homeDx = (p.homeBase.x - p.pos.x) * 0.004;
        double homeDy = (p.homeBase.y - p.pos.y) * 0.004;
        p.moveTarget.x =
            (p.moveTarget.x + cos(angle) * 0.002 + homeDx).clamp(0.04, 0.96);
        p.moveTarget.y =
            (p.moveTarget.y + sin(angle) * 0.002 + homeDy).clamp(0.04, 0.96);
      }
      p.vx *= 0.70;
      p.vy *= 0.70;
      return;
    }

    double baseSpd =
        (0.0038 + (p.stats['İçgüç'] ?? p.stats['Hız'] ?? 10) * 0.000155) *
            _speedFactor() *
            p.stamina.clamp(0.72, 1.0);

    // Sürüş sırasında hafif hız artışı – top önde taşınırken daha kararlı
    if (p.isDribbling) baseSpd *= 1.22;

    double targetVx = (dx / d) * baseSpd;
    double targetVy = (dy / d) * baseSpd;

    // FM26-style inertia – smooth acceleration (lower = more buttery glide)
    // Sürüşte daha sert tutma (accel artırıldı) → ani durmalar azalır
    final double accel = p.isDribbling ? 0.20 : 0.13;
    p.vx += (targetVx - p.vx) * accel;
    p.vy += (targetVy - p.vy) * accel;

    // Cap to max speed
    double spd = sqrt(p.vx * p.vx + p.vy * p.vy);
    double maxSpd = baseSpd * 1.6;
    if (spd > maxSpd) {
      p.vx = p.vx / spd * maxSpd;
      p.vy = p.vy / spd * maxSpd;
    }

    p.pos.x = (p.pos.x + p.vx).clamp(0.01, 0.99);
    p.pos.y = (p.pos.y + p.vy).clamp(0.02, 0.98);
  }

  double _speedFactor() {
    // Dramatic slow-motion during shot flight
    if (ball.phase == BallPhase.shotFlight || _shotSlowMoTicks > 40) {
      return 0.10; // ~10x slower – very cinematic
    }
    if (_shotSlowMoTicks > 0) {
      // Ease back to normal speed after shot resolves
      double ease = _shotSlowMoTicks / 40.0;
      double base = speed == MatchSpeed.slow
          ? 0.09
          : speed == MatchSpeed.fast
              ? 1.10
              : 0.38;
      return base * (1.0 - ease * 0.65);
    }
    if (speed == MatchSpeed.slow) return 0.09; // Very slow – highly realistic
    if (speed == MatchSpeed.fast) return 1.10;
    return 0.38; // Medium
  }

  /// Pass flight ticks multiplier – slow mode makes passes visually longer
  double _passTicksMult() {
    if (speed == MatchSpeed.slow) return 2.8;
    if (speed == MatchSpeed.fast) return 0.55;
    return 1.0;
  }

  /// How many engine ticks between automatic passes (scaled to speed)
  int _scaledPassEvery(int base) {
    if (speed == MatchSpeed.slow) return (base * 4.5).round();
    if (speed == MatchSpeed.fast) return max(3, (base * 0.65).round());
    return base;
  }

  // ─── LOG ────────────────────────────────────────────────────────────────────

  void _log(String msg, Color color) {
    logs.insert(0, LogEntry(msg, color, matchMinute.toInt()));
    if (logs.length > 22) logs.removeLast();
  }

  /// Picks a random variant string from [variants] so commentary doesn't repeat.
  void _logVariant(List<String> variants, Color color) {
    _log(variants[_rng.nextInt(variants.length)], color);
  }

  // ── GOAL COMMENTARY – varied Turkish football phrases ──────────────────────
  final List<String> _goalComments = [
    '⚽🔥 GOL! ',
    '⚽💥 MUAZZAM GOL! ',
    '🎉🔥 GOOOL! ',
    '⚽✨ HARIKA GOL! ',
    '💫 İNANILMAZ! ',
    '🚀 SÜPERGOL! ',
    '⚽ GOL! GOL! GOL! ',
    '🏆 NET ÇATLADI! ',
    '💎 MÜKEMMEL! ',
    '🌟 GOOOOOL! ',
  ];

  // ── SAVE COMMENTARY ─────────────────────────────────────────────────────────
  final List<String> _saveComments = [
    '🧤 Muhteşem kurtarış! ',
    '🧤 İnanılmaz! ',
    '🧤 Hayat kurtardı! ',
    '🤲 El kaçırdı! ',
    '🧤 Parmak ucu! ',
    '🧤 GK durdu! ',
    '🦁 Aslan gibi! ',
    '🧤 Engelleyemez mi? ',
  ];

  // ─── END MATCH ──────────────────────────────────────────────────────────────

  void _endMatch() {
    if (isMatchOver) return;
    isMatchOver = true;
    _ticker?.stop();
    setState(() {});

    bool playerHome = !widget.isPlayerTeamAway;
    int myG = playerHome ? homeScore : awayScore;
    int oppG = playerHome ? awayScore : homeScore;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onMatchEnd(MatchResult(
          myGoals: myG,
          oppGoals: oppG,
          isWin: myG > oppG,
          isDraw: myG == oppG,
          highlights: List.from(logs),
        ));
      }
    });
  }

  // ─── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080F),
      body: Stack(children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.15,
            child: Image.asset('assets/pale2.jpg', fit: BoxFit.cover),
          ),
        ),
        Column(children: [
          _scoreBar(),
          _liveStatsBand(),
          _speedBar(),
          Expanded(child: _pitch()),
          _logPanel(),
        ]),
        // Manager Panel Overlay
        if (_panelOpen) _managerPanelOverlay(),
        // Manager FAB – bottom-right above log panel
        Positioned(
          bottom: 116,
          right: 10,
          child: _managerFAB(),
        ),
      ]),
    );
  }

  Widget _scoreBar() {
    bool playerHome = !widget.isPlayerTeamAway;
    int myG = playerHome ? homeScore : awayScore;
    int oppG = playerHome ? awayScore : homeScore;
    double progress = isStarted ? (matchMinute / 90.0).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 70,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1620), Color(0xFF0E1E30), Color(0xFF0A1620)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border(bottom: BorderSide(color: Color(0xFF1A2D4A))),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            Text('$myG',
                style: GoogleFonts.russoOne(
                    fontSize: 52,
                    color: Colors.cyanAccent,
                    shadows: [
                      const Shadow(color: Colors.cyan, blurRadius: 16)
                    ])),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                isMatchOver
                    ? 'BİTTİ'
                    : isStarted
                        ? "${matchMinute.toStringAsFixed(0)}'"
                        : '00\'',
                style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              if (!isStarted) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _startMatch,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00C853), Color(0xFF00E5FF)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('BAŞLAT',
                        style: GoogleFonts.orbitron(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ]),
            Text('$oppG',
                style: GoogleFonts.russoOne(
                    fontSize: 52,
                    color: Colors.redAccent,
                    shadows: [
                      const Shadow(color: Colors.red, blurRadius: 16)
                    ])),
          ]),
        ),
        // Match time progress bar
        SizedBox(
          height: 4,
          child: LayoutBuilder(builder: (_, box) {
            return Stack(
              children: [
                Container(color: const Color(0xFF0D1820)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: box.maxWidth * progress,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: matchMinute > 75
                          ? [Colors.redAccent, Colors.orangeAccent]
                          : [
                              Colors.cyanAccent.withOpacity(0.7),
                              Colors.blueAccent
                            ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _speedBar() {
    return Container(
      height: 50,
      color: const Color(0xFF0E0E18),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('HIZ: ',
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ...MatchSpeed.values.map((s) => GestureDetector(
              onTap: () => setState(() => speed = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: speed == s
                      ? s.color.withOpacity(0.22)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color:
                          speed == s ? s.color : Colors.white.withOpacity(0.14),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.label,
                        style: TextStyle(
                            color: speed == s ? s.color : Colors.white38,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Text('${s.durationSeconds}sn',
                        style: TextStyle(
                            color: (speed == s ? s.color : Colors.white38)
                                .withOpacity(0.7),
                            fontSize: 8,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
              ),
            )),
      ]),
    );
  }

  Widget _pitch() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF1B6620),
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: LayoutBuilder(builder: (ctx, box) {
        double w = box.maxWidth, h = box.maxHeight;
        return Stack(clipBehavior: Clip.hardEdge, children: [
          CustomPaint(size: Size(w, h), painter: _PitchPainter()),
          // Goals
          Positioned(
              left: 0, top: h * 0.36, child: _goalBox(w * 0.025, h * 0.28)),
          Positioned(
              right: 0, top: h * 0.36, child: _goalBox(w * 0.025, h * 0.28)),
          // Players
          ...homeTeam.map((p) => _playerDot(p, Colors.redAccent, w, h,
              isMyTeam: !widget.isPlayerTeamAway)),
          ...awayTeam.map((p) => _playerDot(p, Colors.cyanAccent, w, h,
              isMyTeam: widget.isPlayerTeamAway)),
          // Pass-flight destination line
          if (ball.phase == BallPhase.passFlight && ball.passTarget != null)
            CustomPaint(
              size: Size(w, h),
              painter: _PassLinePainter(
                ball.pos,
                ball.passTo,
                w,
                h,
                ball.owner?.isHome ?? true,
              ),
            ),
          // Ball trail (always-on)
          if (_ballTrail.length > 1)
            CustomPaint(
              size: Size(w, h),
              painter: _BallTrailPainter(_ballTrail, w, h,
                  ball.phase == BallPhase.shotFlight, ball.isRocketShot),
            ),
          // Shot particles
          if (_shotParticles.isNotEmpty)
            CustomPaint(
              size: Size(w, h),
              painter: _ParticlePainter(_shotParticles, w, h),
            ),
          // Ball
          _ballDot(w, h),
          // Free-kick spot indicator
          if (_isFreeKick)
            Positioned(
              left: (_freeKickPos.x * w - 12).clamp(0.0, w - 24),
              top: (_freeKickPos.y * h - 12).clamp(0.0, h - 24),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.85), width: 2),
                  color: Colors.red.withOpacity(0.12),
                ),
              ),
            ),
          // Rocket slow-mo / freeze overlay
          if (ball.isRocketShot &&
              (_rocketFreezeTicks > 0 ||
                  ball.phase == BallPhase.shotFlight ||
                  _shotSlowMoTicks > 40))
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.redAccent.withOpacity(0.85), width: 1.2),
                ),
                child: Text(
                  _rocketFreezeTicks > 0 ? '❄️ FREEZE' : '🚀 ROCKET',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5),
                ),
              ),
            ),
          // Shot effect
          if (_shootEffectActive && _shootEffectPlayer != null)
            _shootEffectOverlay(_shootEffectPlayer!, w, h),
          // GK save animation
          if (_gkSaveActive && _gkSavingPlayer != null)
            _gkSaveOverlay(_gkSavingPlayer!, w, h),
          // Goal flash
          if (isGoal) _goalFlash(),
          // Match over overlay
          if (isMatchOver) _matchOverlay(),
        ]);
      }),
    );
  }

  Widget _goalBox(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white54, width: 1.5),
          color: Colors.white12,
        ),
      );

  // ── SHOOT EFFECT OVERLAY ────────────────────────────────────────────────────
  Widget _shootEffectOverlay(SimPlayer shooter, double w, double h) {
    double tFrac = (_shootEffectTimer / 60.0).clamp(0.0, 1.0);
    double pulse = sin(_shootEffectTimer * 0.32).abs();
    double scale = 0.80 + pulse * 0.45;
    double opacity = tFrac < 0.25 ? tFrac * 4 : 1.0;
    return Positioned(
      left: (shooter.pos.x * w - 40).clamp(0.0, w - 80),
      top: (shooter.pos.y * h - 66).clamp(0.0, h - 84),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: scale,
              child: const Text('⚽', style: TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFF7B1FA2)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.55 + pulse * 0.30),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
                border: Border.all(
                    color: Colors.yellowAccent.withOpacity(0.75), width: 1.2),
              ),
              child: const Text(
                'ŞUUUT!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 5,
                        offset: Offset(0.5, 0.5))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GK SAVE OVERLAY ─────────────────────────────────────────────────────────
  Widget _gkSaveOverlay(SimPlayer gk, double w, double h) {
    double tFrac = (_gkSaveTimer / 72.0).clamp(0.0, 1.0);
    double pulse = sin(_gkSaveTimer * 0.28).abs();
    double scale = 0.85 + pulse * 0.35;
    // Fade out in last quarter
    double opacity = tFrac < 0.25 ? tFrac * 4 : 1.0;
    return Positioned(
      left: (gk.pos.x * w - 38).clamp(0.0, w - 76),
      top: (gk.pos.y * h - 62).clamp(0.0, h - 80),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: scale,
              child: const Text('🧤', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BCD4), Color(0xFF006064)],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.55 + pulse * 0.30),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.70), width: 1.2),
              ),
              child: const Text(
                'KURTARIŞ!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                  shadows: [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0.5, 0.5))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Jersey numbers: GK(1) DEF-L(2) DEF-R(3) CAM(10) WING-L(7) WING-R(11) ST(9)
  static const _jerseyNums = [1, 2, 3, 10, 7, 11, 9];

  Widget _playerDot(SimPlayer p, Color base, double w, double h,
      {bool isMyTeam = false}) {
    bool hasBall = (ball.owner == p);
    bool isMarking = (p.markTarget != null);
    Color c = p.isPressing ? Colors.orangeAccent : base;
    // Wall-run blink: player flashes when about to fire rocket shot
    bool isWallRunner = ball.isWallRunActive && ball.wallRunner == p;
    bool blinkHide =
        isWallRunner && p.isPassShoot; // isPassShoot used as blink signal
    int jerseyNum = _jerseyNums[p.playerIndex.clamp(0, 6)];
    // My team players rendered larger
    double dotSize = isMyTeam ? 36.0 : 28.0;
    double markSize = isMyTeam ? 44.0 : 34.0;
    double glowSize = isMyTeam ? 48.0 : 38.0;
    double jerseyFont = isMyTeam ? 13.0 : 10.0;
    double nameFont = isMyTeam ? 9.0 : 7.5;
    double halfDot = dotSize / 2;
    // Role badge color
    Color roleColor = p.role == 'GK'
        ? Colors.yellowAccent
        : p.role == 'DEF'
            ? Colors.lightBlueAccent
            : p.role == 'CAM'
                ? Colors.greenAccent
                : p.role == 'ST'
                    ? Colors.redAccent
                    : p.role == 'WING'
                        ? Colors.orangeAccent
                        : c;

    return Positioned(
      left: (p.pos.x * w - halfDot - 4).clamp(0.0, w - dotSize - 8),
      top: (p.pos.y * h - halfDot - 8).clamp(0.0, h - dotSize - 20),
      child: Opacity(
        opacity: blinkHide ? 0.10 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Dribble glow: orange aura when player is dribbling
                if (p.isDribbling)
                  Container(
                    width: glowSize + 8,
                    height: glowSize + 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withOpacity(0.72),
                          blurRadius: 18,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                // Marking indicator ring
                if (isMarking && !p.isDribbling)
                  Container(
                    width: markSize,
                    height: markSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.yellowAccent.withOpacity(0.50),
                          width: 1.2),
                    ),
                  ),
                // Ball-possession glow ring
                if (hasBall)
                  Container(
                    width: glowSize,
                    height: glowSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.92), width: 2.2),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.white.withOpacity(0.60),
                            blurRadius: 12,
                            spreadRadius: 3)
                      ],
                    ),
                  ),
                // Main player circle with 3D radial gradient
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.lerp(Colors.white, c, 0.45)!,
                        c,
                        c.withOpacity(0.80),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                      center: const Alignment(-0.40, -0.40),
                    ),
                    border: Border.all(
                        color: hasBall
                            ? Colors.white
                            : Colors.black.withOpacity(0.55),
                        width: hasBall ? 2.4 : 1.2),
                    boxShadow: [
                      BoxShadow(
                          color: c.withOpacity(hasBall ? 0.90 : 0.40),
                          blurRadius: hasBall ? 16 : 8)
                    ],
                  ),
                  child: Center(
                    child: Text('$jerseyNum',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: jerseyFont,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0.5, 0.5))
                            ])),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Role badge strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(3),
                border:
                    Border.all(color: roleColor.withOpacity(0.55), width: 0.7),
              ),
              child: Text(
                p.data.name.length > (isMyTeam ? 9 : 7)
                    ? '${p.data.name.substring(0, isMyTeam ? 8 : 6)}.'
                    : p.data.name,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: nameFont,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 4)
                    ]),
              ),
            ),
            const SizedBox(height: 1),
            // FM26-style velocity direction arrow
            _velocityArrow(p, c),
          ],
        ),
      ), // closes Opacity
    );
  }

  Widget _velocityArrow(SimPlayer p, Color c) {
    double sp = sqrt(p.vx * p.vx + p.vy * p.vy);
    if (sp < 0.00050) return const SizedBox(height: 6);
    double angle = atan2(p.vy, p.vx);
    // Scale arrow length with speed
    double arrowLen = (sp * 2200).clamp(7.0, 18.0);
    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: arrowLen,
        height: 5,
        child: CustomPaint(painter: _ArrowPainter(c.withOpacity(0.70))),
      ),
    );
  }

  Widget _ballDot(double w, double h) {
    // During owned phase use the visual orbit offset so ball orbits just outside player
    Pos bp = (ball.owner != null && ball.phase == BallPhase.owned)
        ? Pos(
            (ball.pos.x + ball.ballDispDx).clamp(0.01, 0.99),
            (ball.pos.y + ball.ballDispDy).clamp(0.02, 0.98),
          )
        : ball.pos;
    bool isShotBall = ball.phase == BallPhase.shotFlight;
    bool isRocket = isShotBall && ball.isRocketShot;
    double size = isShotBall ? 19 : 15;

    return Positioned(
      left: (bp.x * w - size / 2).clamp(0.0, w - size),
      top: (bp.y * h - size / 2).clamp(0.0, h - size),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shot halo glow (orange → red for rocket)
          if (isShotBall)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: const Duration(milliseconds: 150),
              builder: (_, v, __) => Container(
                width: size + 22,
                height: size + 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (isRocket ? Colors.redAccent : Colors.orangeAccent)
                        .withOpacity(v * 0.95),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isRocket ? Colors.red : const Color(0xFFFF6D00))
                          .withOpacity(v * 0.80),
                      blurRadius: 22,
                      spreadRadius: 7,
                    ),
                    BoxShadow(
                      color: (isRocket ? Colors.deepOrange : Colors.yellow)
                          .withOpacity(v * 0.45),
                      blurRadius: 40,
                      spreadRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
          // Black & white soccer ball base
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isShotBall
                    ? (isRocket
                        ? [
                            Colors.orange.shade100,
                            Colors.redAccent,
                            const Color(0xFF8B0000)
                          ]
                        : [
                            Colors.yellow.shade100,
                            const Color(0xFFFF6D00),
                            const Color(0xFF8B2500)
                          ])
                    : [
                        Colors.white,
                        Colors.grey.shade200,
                        Colors.grey.shade500
                      ],
                stops: const [0.0, 0.55, 1.0],
                center: const Alignment(-0.38, -0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: isShotBall
                      ? (isRocket
                          ? Colors.red.withOpacity(1.0)
                          : Colors.orange.withOpacity(0.95))
                      : Colors.black26,
                  blurRadius: isShotBall ? 28 : 8,
                  spreadRadius: isShotBall ? 5 : 2,
                ),
              ],
            ),
            child: isShotBall
                ? null
                : ClipOval(
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _SoccerBallPainter(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _goalFlash() {
    return AnimatedBuilder(
      animation: _goalAnim,
      builder: (_, __) => Container(
        color: Colors.yellowAccent.withOpacity((1 - _goalAnim.value) * 0.32),
        child: Center(
          child: Text(
            goalCelebText,
            textAlign: TextAlign.center,
            style: GoogleFonts.russoOne(
              fontSize: 38,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.amber, blurRadius: 20)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _matchOverlay() {
    bool playerHome = !widget.isPlayerTeamAway;
    int myG = playerHome ? homeScore : awayScore;
    int oppG = playerHome ? awayScore : homeScore;
    String result = myG > oppG
        ? 'GALİBİYET'
        : myG == oppG
            ? 'BERABERLİK'
            : 'MAĞLUBİYET';
    Color rc = myG > oppG
        ? Colors.greenAccent
        : myG == oppG
            ? Colors.amber
            : Colors.redAccent;

    return Container(
      color: Colors.black.withOpacity(0.70),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(result,
              style: GoogleFonts.russoOne(
                  fontSize: 44,
                  color: rc,
                  shadows: [Shadow(color: rc, blurRadius: 20)])),
          const SizedBox(height: 8),
          Text('$myG - $oppG',
              style: GoogleFonts.orbitron(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _logPanel() {
    return Container(
      height: 105,
      color: const Color(0xFF09091280),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: logs.length,
        itemBuilder: (_, i) {
          var e = logs[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.2),
            child: Text(
              "${e.minute}'  ${e.msg}",
              style: TextStyle(
                  color: e.color, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LIVE STATS BAND (just below score bar)
  // ════════════════════════════════════════════════════════════════

  Widget _liveStatsBand() {
    bool playerHome = !widget.isPlayerTeamAway;
    int totalPoss = _homePossessionTicks + _awayPossessionTicks;
    double myPossRatio = totalPoss > 0
        ? (playerHome ? _homePossessionTicks : _awayPossessionTicks) / totalPoss
        : 0.5;
    int myPoss = (myPossRatio * 100).round();
    int myShots = playerHome ? _homeShots : _awayShots;
    int oppShots = playerHome ? _awayShots : _homeShots;

    return Container(
      height: 26,
      color: const Color(0xFF0A0A18),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text('$myPoss%',
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(children: [
                Expanded(
                  flex: myPoss.clamp(1, 99),
                  child: Container(
                      height: 5, color: Colors.cyanAccent.withOpacity(0.7)),
                ),
                Expanded(
                  flex: (100 - myPoss).clamp(1, 99),
                  child: Container(
                      height: 5, color: Colors.redAccent.withOpacity(0.6)),
                ),
              ]),
            ),
          ),
          const SizedBox(width: 4),
          Text('${100 - myPoss}%',
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Icon(Icons.sports_soccer, size: 10, color: Colors.white38),
          const SizedBox(width: 3),
          Text('$myShots–$oppShots',
              style: const TextStyle(color: Colors.white60, fontSize: 9)),
          const SizedBox(width: 6),
          Text('ŞUT',
              style: const TextStyle(color: Colors.white24, fontSize: 8)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // MANAGER FAB
  // ════════════════════════════════════════════════════════════════

  Widget _managerFAB() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _panelOpen = !_panelOpen;
          if (_panelOpen)
            _panelAnim.forward(from: 0);
          else
            _panelAnim.reverse();
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: _panelOpen
                ? [Colors.redAccent, Colors.red.shade700]
                : [const Color(0xFF0066FF), const Color(0xFF00C8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_panelOpen ? Colors.red : Colors.blue).withOpacity(0.5),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _panelOpen ? Icons.close_rounded : Icons.manage_accounts_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // MANAGER PANEL OVERLAY
  // ════════════════════════════════════════════════════════════════

  Widget _managerPanelOverlay() {
    return AnimatedBuilder(
      animation: _panelAnim,
      builder: (_, child) => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: MediaQuery.of(context).size.height * 0.64,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: _panelAnim, curve: Curves.easeOutCubic)),
          child: child!,
        ),
      ),
      child: _managerPanel(),
    );
  }

  Widget _managerPanel() {
    bool playerHome = !widget.isPlayerTeamAway;
    int myG = playerHome ? homeScore : awayScore;
    int oppG = playerHome ? awayScore : homeScore;
    TacticStyle curTac = playerHome
        ? (_liveHomeTactic ?? widget.myTactic)
        : (_liveAwayTactic ?? widget.myTactic);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C0C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF1E3A6E), width: 1.5),
          left: BorderSide(color: Color(0xFF1A2D4A), width: 0.5),
          right: BorderSide(color: Color(0xFF1A2D4A), width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '⚽ YÖNETİCİ PANELİ',
                  style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: curTac.color.withOpacity(0.15),
                      border: Border.all(
                          color: curTac.color.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(curTac.label,
                        style: TextStyle(
                            color: curTac.color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text("$myG–$oppG  ${matchMinute.toInt()}'",
                      style: GoogleFonts.russoOne(
                          color: Colors.white70, fontSize: 12)),
                ]),
              ],
            ),
          ),
          // Tab bar
          SizedBox(
            height: 38,
            child: Row(children: [
              _panelTabBtn(0, '📊 ÖZET'),
              _panelTabBtn(1, '🎯 TAKTİK'),
              _panelTabBtn(2, '👥 KADRO'),
              _panelTabBtn(3, '📈 ANALİZ'),
            ]),
          ),
          Container(height: 1, color: const Color(0xFF1E3A6E)),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: [
                _statsTab(),
                _tacticsTab(),
                _squadTab(),
                _analysisTab(),
              ][_panelTab],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelTabBtn(int idx, String label) {
    bool active = _panelTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _panelTab = idx),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF0066FF).withOpacity(0.16)
                : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: active ? Colors.cyanAccent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.cyanAccent : Colors.white38,
              fontSize: 9.5,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TAB 0 – ÖZET (STATS)
  // ════════════════════════════════════════════════════════════════

  Widget _statsTab() {
    bool playerHome = !widget.isPlayerTeamAway;
    int totalPoss = _homePossessionTicks + _awayPossessionTicks;
    double myPossRatio = totalPoss > 0
        ? (playerHome ? _homePossessionTicks : _awayPossessionTicks) / totalPoss
        : 0.5;
    int myPoss = (myPossRatio * 100).round();
    int myShots = playerHome ? _homeShots : _awayShots;
    int oppShots = playerHome ? _awayShots : _homeShots;
    int myShotsOT = playerHome ? _homeShotsOnTarget : _awayShotsOnTarget;
    int oppShotsOT = playerHome ? _awayShotsOnTarget : _homeShotsOnTarget;
    int myPasses = playerHome ? _homePassesCmpl : _awayPassesCmpl;
    int oppPasses = playerHome ? _awayPassesCmpl : _homePassesCmpl;
    int myPassAtt = playerHome ? _homePassesAtt : _awayPassesAtt;
    int oppPassAtt = playerHome ? _awayPassesAtt : _homePassesAtt;
    int myPassAcc = myPassAtt > 0 ? ((myPasses / myPassAtt) * 100).round() : 0;
    int oppPassAcc =
        oppPassAtt > 0 ? ((oppPasses / oppPassAtt) * 100).round() : 0;
    int myCorners = playerHome ? _homeCorners : _awayCorners;
    int oppCorners = playerHome ? _awayCorners : _homeCorners;
    int myFouls = playerHome ? _homeFouls : _awayFouls;
    int oppFouls = playerHome ? _awayFouls : _homeFouls;
    int myYellows = playerHome ? _homeYellows : _awayYellows;
    int oppYellows = playerHome ? _awayYellows : _homeYellows;
    int myReds = playerHome ? _homeReds : _awayReds;
    int oppReds = playerHome ? _awayReds : _homeReds;
    int myTackles = playerHome ? _homeTackles : _awayTackles;
    int oppTackles = playerHome ? _awayTackles : _homeTackles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statBar('TOPLA OYNAMA', myPoss, 100 - myPoss,
            unit: '%', myColor: Colors.cyanAccent, oppColor: Colors.redAccent),
        _statBar('ŞUT', myShots, oppShots,
            myColor: Colors.orangeAccent, oppColor: Colors.red),
        _statBar('İSABETLİ ŞUT', myShotsOT, oppShotsOT,
            myColor: Colors.greenAccent, oppColor: Colors.redAccent),
        _statBar('TAMAMLANAN PAS', myPasses, oppPasses,
            myColor: Colors.lightBlueAccent, oppColor: Colors.pinkAccent),
        _statBar('PAS DOĞRULUĞU', myPassAcc, oppPassAcc,
            unit: '%', myColor: Colors.blueAccent, oppColor: Colors.pinkAccent),
        _statBar('KAZANILAN TOP', myTackles, oppTackles,
            myColor: Colors.tealAccent, oppColor: Colors.deepOrangeAccent),
        _statBar('KORNER', myCorners, oppCorners,
            myColor: Colors.purpleAccent, oppColor: Colors.redAccent),
        _statBar('FAUL', myFouls, oppFouls,
            myColor: Colors.orangeAccent,
            oppColor: Colors.redAccent,
            reversed: true),
        _statBar('SARI KART', myYellows, oppYellows,
            myColor: Colors.yellowAccent,
            oppColor: Colors.redAccent,
            reversed: true),
        _statBar('KIRMIZI KART', myReds, oppReds,
            myColor: Colors.redAccent,
            oppColor: Colors.redAccent,
            reversed: true),
        const SizedBox(height: 10),
        _recentEvents(),
      ],
    );
  }

  Widget _statBar(
    String label,
    int my,
    int opp, {
    String unit = '',
    Color myColor = Colors.cyanAccent,
    Color oppColor = Colors.redAccent,
    bool reversed = false,
  }) {
    int total = my + opp;
    double myRatio = total > 0 ? my / total : 0.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$my$unit',
                  style: TextStyle(
                      color: myColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 8.5,
                      letterSpacing: 0.8)),
              Text('$opp$unit',
                  style: TextStyle(
                      color: oppColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Row(children: [
              Expanded(
                flex: (myRatio * 100).round().clamp(1, 99),
                child: Container(height: 6, color: myColor.withOpacity(0.82)),
              ),
              Expanded(
                flex: ((1 - myRatio) * 100).round().clamp(1, 99),
                child: Container(height: 6, color: oppColor.withOpacity(0.68)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _recentEvents() {
    var recent = logs.take(6).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SON ANLAR',
            style: GoogleFonts.orbitron(
                color: Colors.white24, fontSize: 7.5, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        ...recent.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text("${e.minute}'",
                      style: TextStyle(
                          color: e.color,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(e.msg,
                      style: TextStyle(
                          color: e.color.withOpacity(0.85), fontSize: 8.5),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            )),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TAB 1 – TAKTİK
  // ════════════════════════════════════════════════════════════════

  Widget _tacticsTab() {
    bool playerHome = !widget.isPlayerTeamAway;
    TacticStyle curTac = playerHome
        ? (_liveHomeTactic ?? widget.myTactic)
        : (_liveAwayTactic ?? widget.myTactic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OYUN SİSTEMİ',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TacticStyle.values.map((t) {
            bool active = curTac == t;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (playerHome)
                    _liveHomeTactic = t;
                  else
                    _liveAwayTactic = t;
                  _log('🔄 Taktik: ${t.label}', Colors.cyanAccent);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? t.color.withOpacity(0.22)
                      : Colors.white.withOpacity(0.05),
                  border: Border.all(
                      color: active ? t.color : Colors.white24,
                      width: active ? 2 : 1),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: active
                      ? [
                          BoxShadow(
                              color: t.color.withOpacity(0.35), blurRadius: 10)
                        ]
                      : [],
                ),
                child: Text(t.label,
                    style: TextStyle(
                      color: active ? t.color : Colors.white54,
                      fontSize: 10,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        Text('SAVUNMA HATTI',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
        _sliderRow('DERİN', 'YÜKSEK', _defLineVal,
            (v) => setState(() => _defLineVal = v), Colors.redAccent),
        const SizedBox(height: 10),
        Text('BASIN BAŞLAMA ÇİZGİSİ',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
        _sliderRow('DÜŞÜK', 'YÜKSEK', _pressLineVal,
            (v) => setState(() => _pressLineVal = v), Colors.orangeAccent),
        const SizedBox(height: 10),
        Text('GENİŞLİK',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
        _sliderRow('DAR', 'GENİŞ', _widthVal,
            (v) => setState(() => _widthVal = v), Colors.cyanAccent),
        const SizedBox(height: 10),
        Text('TEMPO',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
        _sliderRow('YAVAŞ', 'DİREKT', _tempoVal,
            (v) => setState(() => _tempoVal = v), Colors.yellowAccent),
        const SizedBox(height: 10),
        // Current shape summary
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AKTİF ŞEKL',
                  style: GoogleFonts.orbitron(
                      color: Colors.white38, fontSize: 7.5, letterSpacing: 1)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _tacBadge(
                    'Savunma Hattı',
                    _defLineVal < 0.35
                        ? 'Derin'
                        : _defLineVal > 0.65
                            ? 'Yüksek'
                            : 'Normal',
                    Colors.redAccent),
                _tacBadge(
                    'Baskı',
                    _pressLineVal < 0.35
                        ? 'Az'
                        : _pressLineVal > 0.65
                            ? 'Yüksek'
                            : 'Orta',
                    Colors.orangeAccent),
                _tacBadge(
                    'Genişlik',
                    _widthVal < 0.35
                        ? 'Dar'
                        : _widthVal > 0.65
                            ? 'Geniş'
                            : 'Normal',
                    Colors.cyanAccent),
                _tacBadge(
                    'Tempo',
                    _tempoVal < 0.35
                        ? 'Yavaş'
                        : _tempoVal > 0.65
                            ? 'Direkt'
                            : 'Orta',
                    Colors.yellowAccent),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tacBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 7)),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(value,
              style: TextStyle(
                  color: color, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _sliderRow(String left, String right, double value,
      ValueChanged<double> onChanged, Color color) {
    return Row(
      children: [
        SizedBox(
            width: 44,
            child: Text(left,
                style: const TextStyle(color: Colors.white38, fontSize: 8),
                textAlign: TextAlign.right)),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color.withOpacity(0.8),
              inactiveTrackColor: Colors.white10,
              thumbColor: color,
              overlayColor: color.withOpacity(0.18),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 3,
            ),
            child: Slider(value: value, onChanged: onChanged, min: 0, max: 1),
          ),
        ),
        SizedBox(
            width: 44,
            child: Text(right,
                style: const TextStyle(color: Colors.white38, fontSize: 8))),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  TAB 2 – KADRO / SUBSTITUTIONS
  // ════════════════════════════════════════════════════════════════

  Widget _squadTab() {
    bool playerHome = !widget.isPlayerTeamAway;
    var myTeam = playerHome ? homeTeam : awayTeam;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DEĞİŞİKLİKLER',
                style: GoogleFonts.orbitron(
                    color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _subsUsed >= _maxSubs
                    ? Colors.red.withOpacity(0.18)
                    : Colors.green.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _subsUsed >= _maxSubs
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    width: 1),
              ),
              child: Text('$_subsUsed / $_maxSubs',
                  style: TextStyle(
                    color: _subsUsed >= _maxSubs
                        ? Colors.redAccent
                        : Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (_subCandidate != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.10),
              border: Border.all(color: Colors.orangeAccent, width: 1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(children: [
              const Icon(Icons.swap_vert_rounded,
                  color: Colors.orangeAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                    '${_subCandidate!.data.name} çıkacak → yerine kim girecek?',
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 10)),
              ),
              GestureDetector(
                onTap: () => setState(() => _subCandidate = null),
                child: const Icon(Icons.cancel_outlined,
                    color: Colors.white38, size: 18),
              ),
            ]),
          ),
        ],
        ...myTeam.map((p) {
          bool isSubbed = _subbedPlayers.contains(p);
          bool isSelected = _subCandidate == p;
          var ins = _insights[p.data.name] ?? _PlayerInsight();
          double stamFill =
              ((p.stamina.clamp(0.72, 1.0) - 0.72) / 0.28).clamp(0.0, 1.0);
          Color stamColor = stamFill > 0.6
              ? Colors.greenAccent
              : stamFill > 0.3
                  ? Colors.orangeAccent
                  : Colors.redAccent;

          return GestureDetector(
            onTap: () {
              if (isSubbed || !isStarted || _subsUsed >= _maxSubs) return;
              setState(() {
                if (_subCandidate == null) {
                  _subCandidate = p;
                } else if (_subCandidate == p) {
                  _subCandidate = null;
                } else {
                  _executeSubstitution(_subCandidate!, p);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 5),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.orange.withOpacity(0.12)
                    : isSubbed
                        ? Colors.white.withOpacity(0.02)
                        : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSelected
                      ? Colors.orangeAccent
                      : isSubbed
                          ? Colors.white10
                          : Colors.white.withOpacity(0.10),
                  width: 1,
                ),
              ),
              child: Row(children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: playerHome
                        ? Colors.redAccent.withOpacity(0.25)
                        : Colors.cyanAccent.withOpacity(0.25),
                  ),
                  child: Center(
                    child: Text(
                      '${_jerseyNums[p.playerIndex.clamp(0, 6)]}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.data.name,
                        style: TextStyle(
                          color: isSubbed ? Colors.white30 : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          decoration:
                              isSubbed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Row(children: [
                        Text(p.role,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 8)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 54,
                          height: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: stamFill,
                              backgroundColor: Colors.white10,
                              color: stamColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${(stamFill * 100).round()}%',
                            style: TextStyle(color: stamColor, fontSize: 7)),
                      ]),
                    ],
                  ),
                ),
                // Rating badge
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: ins.ratingColor.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: ins.ratingColor.withOpacity(0.55), width: 1),
                  ),
                  child: Center(
                    child: Text(ins.ratingStr,
                        style: TextStyle(
                            color: ins.ratingColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 4),
                // Action button
                if (isSubbed)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text('↓ ÇIKTI',
                        style: TextStyle(color: Colors.white24, fontSize: 8)),
                  )
                else if (isStarted && _subsUsed < _maxSubs)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.orangeAccent.withOpacity(0.25)
                          : _subCandidate != null
                              ? Colors.greenAccent.withOpacity(0.15)
                              : Colors.blue.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? Colors.orangeAccent
                            : _subCandidate != null
                                ? Colors.greenAccent
                                : Colors.blueAccent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isSelected
                          ? 'İPTAL'
                          : _subCandidate != null
                              ? 'GİR ↑'
                              : 'SEÇ',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.orangeAccent
                            : _subCandidate != null
                                ? Colors.greenAccent
                                : Colors.lightBlueAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ]),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _executeSubstitution(SimPlayer goingOff, SimPlayer comingOn) {
    if (_subsUsed >= _maxSubs) return;
    _subbedPlayers.add(goingOff);
    _subsUsed++;
    _subCandidate = null;

    // Transfer ball possession if needed
    if (ball.owner == goingOff) ball.owner = comingOn;

    // Transfer position
    comingOn.pos.set(goingOff.pos);
    comingOn.moveTarget.set(goingOff.homeBase);
    comingOn.stamina = 1.0; // substitute comes on fresh

    // Send subbed off player off pitch
    goingOff.pos = Pos(-5.0, -5.0);
    goingOff.moveTarget = Pos(-5.0, -5.0);

    setState(() {});
    _log(
        '🔄 ↓${goingOff.data.name}  ↑${comingOn.data.name}', Colors.cyanAccent);
  }

  // ════════════════════════════════════════════════════════════════
  //  TAB 3 – ANALİZ
  // ════════════════════════════════════════════════════════════════

  Widget _analysisTab() {
    bool playerHome = !widget.isPlayerTeamAway;
    var myTeam = (playerHome ? homeTeam : awayTeam)
        .where((p) => !_subbedPlayers.contains(p))
        .toList()
      ..sort((a, b) {
        double ra = _insights[a.data.name]?.rating ?? 6.5;
        double rb = _insights[b.data.name]?.rating ?? 6.5;
        return rb.compareTo(ra);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('OYUNCU ANALİZİ',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 8, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        ...myTeam.map((p) {
          var ins = _insights[p.data.name] ?? _PlayerInsight();
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: ins.ratingColor.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: ins.ratingColor, width: 1.5),
                ),
                child: Center(
                  child: Text(ins.ratingStr,
                      style: TextStyle(
                          color: ins.ratingColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.data.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    Text(p.role,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 8)),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        _insightChip(
                            '${ins.passes} PAS', Colors.lightBlueAccent),
                        _insightChip('${ins.shots} Ş.', Colors.orangeAccent),
                        _insightChip('${ins.tackles} TOP', Colors.tealAccent),
                        if (ins.keyPasses > 0)
                          _insightChip(
                              '${ins.keyPasses} KILIT', Colors.yellowAccent),
                        if (ins.goals > 0)
                          _insightChip(
                              '${ins.goals} GOL ⚽', Colors.greenAccent),
                      ],
                    ),
                  ],
                ),
              ),
              // Star rating (5-star FM26 style)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  double threshold = 4.5 + i * 1.0;
                  return Icon(
                    ins.rating >= threshold + 0.5
                        ? Icons.star_rounded
                        : ins.rating >= threshold
                            ? Icons.star_half_rounded
                            : Icons.star_outline_rounded,
                    color: ins.ratingColor,
                    size: 11,
                  );
                }),
              ),
            ]),
          );
        }),
        const SizedBox(height: 10),
        _keyMomentsList(),
      ],
    );
  }

  Widget _insightChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.38), width: 0.8),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }

  Widget _keyMomentsList() {
    var highlights = logs
        .where((l) =>
            l.msg.contains('GOL') ||
            l.msg.contains('kurtardı') ||
            l.msg.contains('Sar') ||
            l.msg.contains('Faul') ||
            l.msg.contains('Korner'))
        .take(7)
        .toList();
    if (highlights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KRİTİK ANLAR',
            style: GoogleFonts.orbitron(
                color: Colors.white38, fontSize: 7.5, letterSpacing: 1.2)),
        const SizedBox(height: 5),
        ...highlights.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: e.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text("${e.minute}'",
                      style: TextStyle(
                          color: e.color,
                          fontSize: 8,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(e.msg,
                      style: TextStyle(
                          color: e.color.withOpacity(0.85), fontSize: 9),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
            )),
      ],
    );
  }
}

// ─── BALL TRAIL PAINTER ──────────────────────────────────────────────────────────

class _BallTrailPainter extends CustomPainter {
  final List<Pos> trail;
  final double w, h;
  final bool isShot;
  final bool isRocket;
  _BallTrailPainter(this.trail, this.w, this.h,
      [this.isShot = false, this.isRocket = false]);

  @override
  void paint(Canvas canvas, Size size) {
    if (trail.length < 2) return;
    final int len = trail.length;
    for (int i = 0; i < len - 1; i++) {
      double t = (i + 1) / len;
      final double opa = isShot ? t * 0.80 : t * 0.28;
      final double sw =
          isShot ? (t * 10).clamp(1.5, 10.0) : (t * 4).clamp(1.0, 4.0);
      final Color lineColor = isRocket
          ? Color.lerp(Colors.deepOrange, Colors.redAccent, t)!.withOpacity(opa)
          : isShot
              ? Color.lerp(Colors.yellow, Colors.orangeAccent, t)!
                  .withOpacity(opa)
              : Colors.white.withOpacity(opa);
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, isShot ? (isRocket ? 5.0 : 4.0) : 2.0);
      canvas.drawLine(
        Offset(trail[i].x * w, trail[i].y * h),
        Offset(trail[i + 1].x * w, trail[i + 1].y * h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BallTrailPainter old) => true;
}

// ─── PASS LINE PAINTER ────────────────────────────────────────────────────────

class _PassLinePainter extends CustomPainter {
  final Pos from, to;
  final double w, h;
  final bool isHome;
  _PassLinePainter(this.from, this.to, this.w, this.h, this.isHome);

  @override
  void paint(Canvas canvas, Size size) {
    final color = isHome
        ? Colors.redAccent.withOpacity(0.45)
        : Colors.cyanAccent.withOpacity(0.45);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    // Dashed line: 10px on, 5px off
    const double dashLen = 10, gapLen = 5;
    Offset a = Offset(from.x * w, from.y * h);
    Offset b = Offset(to.x * w, to.y * h);
    double dx = b.dx - a.dx, dy = b.dy - a.dy;
    double total = sqrt(dx * dx + dy * dy);
    if (total < 1) return;
    double nx = dx / total, ny = dy / total;
    double drawn = 0;
    bool drawing = true;
    while (drawn < total) {
      double seg = drawing ? dashLen : gapLen;
      double end = (drawn + seg).clamp(0, total);
      if (drawing) {
        canvas.drawLine(
          Offset(a.dx + nx * drawn, a.dy + ny * drawn),
          Offset(a.dx + nx * end, a.dy + ny * end),
          paint,
        );
      }
      drawn += seg;
      drawing = !drawing;
    }
    // Destination dot
    canvas.drawCircle(
        b,
        4.0,
        Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_PassLinePainter old) => true;
}

// ─── PITCH PAINTER ──────────────────────────────────────────────────────────

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width, h = size.height;

    // ── Base grass fill ──
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1B6620));

    // ── FM-style vertical mowing stripes ──
    const int numStripes = 14;
    double stripeW = w / numStripes;
    for (int i = 0; i < numStripes; i++) {
      final stripePaint = Paint()
        ..color = (i.isEven ? const Color(0xFF1E7A24) : const Color(0xFF186018))
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(i * stripeW, 0, stripeW, h), stripePaint);
    }

    final p = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Center line
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), p);
    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.155, p);
    // Center dot
    p.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), 4.5, p);
    p.style = PaintingStyle.stroke;
    // Penalty boxes
    canvas.drawRect(Rect.fromLTWH(0, h * 0.22, w * 0.17, h * 0.56), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.83, h * 0.22, w * 0.17, h * 0.56), p);
    // Small boxes (6-yard box)
    canvas.drawRect(Rect.fromLTWH(0, h * 0.355, w * 0.058, h * 0.29), p);
    canvas.drawRect(
        Rect.fromLTWH(w * 0.942, h * 0.355, w * 0.058, h * 0.29), p);
    // Penalty spots
    p.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.12, h * 0.5), 3.5, p);
    canvas.drawCircle(Offset(w * 0.88, h * 0.5), 3.5, p);
    p.style = PaintingStyle.stroke;
    // Penalty arc
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.12, h * 0.5),
            width: h * 0.28,
            height: h * 0.28),
        -1.0,
        2.0,
        false,
        p);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(w * 0.88, h * 0.5),
            width: h * 0.28,
            height: h * 0.28),
        2.1,
        2.0,
        false,
        p);
    // ─── KÖşE YAYLARI: her köşede çeyrek daire (HaxBall gerçekçilik) ─────────
    double cornerR = h * 0.042;
    // Sol-üst
    canvas.drawArc(Rect.fromLTWH(-cornerR, -cornerR, cornerR * 2, cornerR * 2),
        0, 1.5708, false, p);
    // Sol-alt
    canvas.drawArc(
        Rect.fromLTWH(-cornerR, h - cornerR, cornerR * 2, cornerR * 2),
        -1.5708,
        1.5708,
        false,
        p);
    // Sağ-üst
    canvas.drawArc(
        Rect.fromLTWH(w - cornerR, -cornerR, cornerR * 2, cornerR * 2),
        1.5708,
        1.5708,
        false,
        p);
    // Sağ-alt
    canvas.drawArc(
        Rect.fromLTWH(w - cornerR, h - cornerR, cornerR * 2, cornerR * 2),
        3.14159,
        1.5708,
        false,
        p);

    // ─── MERKEZ DAİRE DOLGU: hafif saydam yeşil ──────────────────────────────
    canvas.drawCircle(
        Offset(w / 2, h / 2),
        h * 0.155,
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..style = PaintingStyle.fill);

    // Touch line & goal line (border)
    canvas.drawRect(Rect.fromLTWH(1, 1, w - 2, h - 2), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── ARROW PAINTER (velocity direction indicator) ────────────────────────────

class _ArrowPainter extends CustomPainter {
  final Color color;
  _ArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width, size.height / 2)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}

// ─── ITERABLE EXT ────────────────────────────────────────────────────────────

extension IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var e in this) if (test(e)) return e;
    return null;
  }
}

// ─── SHOT PARTICLE ───────────────────────────────────────────────────────────

class _ShotParticle {
  double x, y, vx, vy, life;
  final Color color;
  _ShotParticle(this.x, this.y, this.vx, this.vy, this.life, this.color);
}

// ─── PARTICLE PAINTER ────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final List<_ShotParticle> particles;
  final double w, h;
  _ParticlePainter(this.particles, this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.life <= 0) continue;
      final paint = Paint()
        ..color = p.color.withOpacity((p.life).clamp(0.0, 1.0) * 0.92)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      final double r = (p.life * 5.5).clamp(1.0, 5.5);
      canvas.drawCircle(Offset(p.x * w, p.y * h), r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─── SOCCER BALL PAINTER ───────────────────────────────────────────────────

class _SoccerBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.72)
      ..style = PaintingStyle.fill;

    // Draw simplified black patches to mimic a classic soccer ball
    // Central pentagon
    _drawPatch(canvas, paint, size, r * 0.50, r * 0.50, r * 0.28);
    // Surrounding patches (6 positions)
    for (int i = 0; i < 5; i++) {
      double angle = (i * 2 * 3.14159 / 5) - 1.57;
      double px = r + cos(angle) * r * 0.54;
      double py = r + sin(angle) * r * 0.54;
      _drawPatch(canvas, paint, size, px, py, r * 0.20);
    }
  }

  void _drawPatch(
      Canvas canvas, Paint paint, Size size, double cx, double cy, double pr) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      double a = (i * 2 * 3.14159 / 6) - 0.52;
      double px = cx + cos(a) * pr;
      double py = cy + sin(a) * pr;
      if (i == 0)
        path.moveTo(px, py);
      else
        path.lineTo(px, py);
    }
    path.close();
    // Only draw within circle bounds
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}
