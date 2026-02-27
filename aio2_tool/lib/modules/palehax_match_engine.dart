import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// =============================================================================
// ENUMS & EXTENSIONS
// =============================================================================

enum MatchSpeed { fast, medium, slow }

extension MatchSpeedExt on MatchSpeed {
  int get durationSeconds => this == MatchSpeed.fast
      ? 15
      : this == MatchSpeed.medium
          ? 40
          : 90;
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
// BALL
// =============================================================================

enum BallPhase { owned, passFlight, cornerDelay, free }

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

  // Corner state
  bool cornerForHome = false;
  int cornerCountdown = 0;
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
  Timer? _gameTimer;
  late AnimationController _goalAnim;
  List<LogEntry> logs = [];

  @override
  void initState() {
    super.initState();
    _goalAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _initGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _goalAnim.dispose();
    super.dispose();
  }

  // ─── INIT ───────────────────────────────────────────────────────────────────

  void _initGame() {
    ball = Ball();
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
  }

  void _buildTeam(
    List<Player> players,
    List<SimPlayer> target,
    bool isHome,
    TacticStyle tactic,
    Map<int, PlayerInstruction> instructions,
  ) {
    target.clear();

    // Sort so GK is index 0, DEF 1-2, MID 3-4, FWD 5-6
    var sorted = List<Player>.from(players)
      ..sort((a, b) => _posScore(a.position).compareTo(_posScore(b.position)));

    // Base positions for home (attacking rightward, x inches toward 1.0)
    // Format: [GK, DEF-L, DEF-R, MID-CL, MID-CR, FWD-L, FWD-R]
    final baseX = [0.06, 0.22, 0.22, 0.44, 0.44, 0.72, 0.72];
    final baseY = [0.50, 0.28, 0.72, 0.22, 0.78, 0.32, 0.68];

    // Tactic depth adjustments
    double xBias = 0;
    if (tactic == TacticStyle.attack) xBias = 0.07;
    if (tactic == TacticStyle.defensive) xBias = -0.08;
    if (tactic == TacticStyle.counter) xBias = -0.05;
    if (tactic == TacticStyle.highPress) xBias = 0.10;
    if (tactic == TacticStyle.gegen) xBias = 0.04;

    for (int i = 0; i < min(sorted.length, 7); i++) {
      double bx = (isHome ? baseX[i] : 1.0 - baseX[i]);
      double by = baseY[i];

      // Apply tactic bias (not for GK)
      if (i > 0) {
        bx = (bx + (isHome ? xBias : -xBias)).clamp(0.05, 0.95);
      }

      // Wide instruction squeezes to extreme y
      PlayerInstruction instr = (instructions[i] ?? PlayerInstruction()).copy();
      bool isWinger = (i == 3 || i == 5); // MID-L, FWD-L
      bool isRightWinger = (i == 4 || i == 6);
      if (instr.stayWide) {
        by = isWinger
            ? 0.06
            : isRightWinger
                ? 0.94
                : by;
      }

      String role = i == 0
          ? 'GK'
          : i < 3
              ? 'DEF'
              : i < 5
                  ? 'MID'
                  : 'FWD';

      target.add(SimPlayer(
        data: sorted[i],
        startPos: Pos(bx, by),
        isHome: isHome,
        role: role,
        instruction: instr,
      ));
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
    // Reset ball to center
    ball.phase = BallPhase.owned;
    ball.pos = Pos(0.5, 0.5);

    SimPlayer kicker = byTeam.firstWhere(
      (p) => p.role == 'FWD',
      orElse: () => byTeam.last,
    );
    kicker.pos.set(Pos(0.5, 0.5));
    ball.owner = kicker;

    // Reset everyone else to home base
    for (var p in [...homeTeam, ...awayTeam]) {
      if (p != kicker) p.moveTarget.set(p.homeBase);
    }

    _log('🎾 Santral: ${kicker.data.name}', Colors.greenAccent);
  }

  // ─── GAME LOOP ──────────────────────────────────────────────────────────────

  void _startMatch() {
    if (isStarted) return;
    isStarted = true;
    _gameTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _onTick());
  }

  void _onTick() {
    if (!mounted || isMatchOver) return;

    tick++;
    matchMinute = (tick / speed.totalTicks * 90.0).clamp(0, 90);

    if (!isGoal) _simulate();

    if (tick >= speed.totalTicks && !isMatchOver) {
      _gameTimer?.cancel();
      _endMatch();
      return;
    }

    if (tick % 3 == 0) setState(() {});
  }

  // ─── SIMULATION ─────────────────────────────────────────────────────────────

  void _simulate() {
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
    }

    // Move all non-owner players
    for (var p in [...homeTeam, ...awayTeam]) {
      if (p != ball.owner) {
        _updateMovementTarget(p);
        _moveToward(p);
      }
    }

    // Owner moves toward their current target too, ball follows
    if (ball.owner != null && ball.phase == BallPhase.owned) {
      _moveToward(ball.owner!);
      ball.pos.set(ball.owner!.pos);
    }
  }

  // ─── OWNED PHASE ────────────────────────────────────────────────────────────

  void _ownedPhase() {
    var owner = ball.owner;
    if (owner == null) {
      ball.phase = BallPhase.free;
      return;
    }

    bool goRight = owner.isHome;
    double goalX = goRight ? 0.97 : 0.03;
    var opp = owner.isHome ? awayTeam : homeTeam;
    var team = owner.isHome ? homeTeam : awayTeam;
    var gk = opp.firstWhere((p) => p.role == 'GK', orElse: () => opp.first);

    // Progress toward goal
    owner.moveTarget = Pos(
      (owner.pos.x + (goRight ? 0.03 : -0.03)).clamp(0.01, 0.99),
      (owner.pos.y + (_rng.nextDouble() - 0.5) * 0.03).clamp(0.02, 0.98),
    );

    // Close pressers
    var pressers = opp.where((o) => o.pos.dist(owner.pos) < 0.11).toList();

    // GK plays conservatively
    if (owner.role == 'GK') {
      owner.moveTarget.set(owner.homeBase);
      if (tick % 25 == 0) _tryPass(owner, team, preferFwd: false);
      return;
    }

    TacticStyle myTac = _myTactic(owner.isHome);

    // ── INSTRUCTION OVERRIDES ──
    if (owner.instruction.stayWide) {
      owner.moveTarget = Pos(goalX, owner.pos.y);
      bool nearLine = goRight ? owner.pos.x > 0.80 : owner.pos.x < 0.20;
      if (nearLine) {
        _cross(owner, team);
        return;
      }
    }

    if (owner.instruction.passOnly) {
      if (tick % 14 == 0 || pressers.isNotEmpty) {
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    if (owner.instruction.constantRuns) {
      owner.moveTarget = Pos(goalX, 0.35 + _rng.nextDouble() * 0.30);
    }

    // ── SHOOT DECISION ──
    bool inBox = goRight ? owner.pos.x > 0.78 : owner.pos.x < 0.22;
    if (inBox && !owner.instruction.passOnly) {
      int shootChance = _calcShootChance(myTac, owner.role, pressers.length);
      if (_rng.nextInt(100) < shootChance) {
        _shoot(owner, gk);
        return;
      }
    }

    // ── TACKLE RISK ──
    if (pressers.isNotEmpty) {
      // Tackle attempt
      var tackler = pressers.first;
      int defSk = tackler.defStat;
      int driSk = owner.dribbleStat;
      if (_rng.nextInt(100) < max(8, defSk - driSk + 35)) {
        _beenTackled(owner, tackler);
        return;
      }
      // Under pressure → pass
      if (_rng.nextInt(100) < 60) {
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    // ── REGULAR PASS ──
    int passEvery = myTac == TacticStyle.tikiTaka
        ? 16
        : myTac == TacticStyle.gegen
            ? 22
            : 20;
    if (tick % passEvery == 0) {
      _tryPass(owner, team, preferFwd: true);
    }

    // ── WIDE SWITCH ──
    if (tick % 38 == 0) {
      var winers =
          team.where((t) => t.instruction.stayWide && t != owner).toList();
      if (winers.isNotEmpty) {
        _execPass(owner, winers[_rng.nextInt(winers.length)]);
      }
    }
  }

  int _calcShootChance(TacticStyle tac, String role, int pressers) {
    int base = role == 'FWD'
        ? 32
        : role == 'MID'
            ? 18
            : 8;
    if (tac == TacticStyle.attack) base += 22;
    if (tac == TacticStyle.defensive) base -= 14;
    if (tac == TacticStyle.tikiTaka) base -= 8;
    if (pressers > 1) base += 18;
    return base.clamp(5, 82);
  }

  TacticStyle _myTactic(bool isHome) {
    return isHome
        ? (widget.isPlayerTeamAway ? widget.oppTactic : widget.myTactic)
        : (widget.isPlayerTeamAway ? widget.myTactic : widget.oppTactic);
  }

  // ─── PASS ───────────────────────────────────────────────────────────────────

  bool _tryPass(SimPlayer passer, List<SimPlayer> team,
      {bool preferFwd = false}) {
    var opts = team.where((t) => t != passer && t.role != 'GK').toList();
    if (opts.isEmpty) return false;

    bool goRight = passer.isHome;
    SimPlayer? best;
    double bestS = -9999;

    for (var t in opts) {
      double s = 0;

      if (preferFwd) {
        double fwdDist =
            goRight ? t.pos.x - passer.pos.x : passer.pos.x - t.pos.x;
        s += fwdDist * 120;
      }

      var oppTeam = passer.isHome ? awayTeam : homeTeam;
      bool open = oppTeam.every((o) => o.pos.dist(t.pos) > 0.09);
      if (open) s += 55;
      if (t.role == 'FWD') s += 35;
      if (t.instruction.stayWide) s += 28;

      double d = passer.pos.dist(t.pos);
      if (d > 0.58) s -= 75;
      if (d < 0.04) s -= 25;

      if (s > bestS) {
        bestS = s;
        best = t;
      }
    }

    if (best == null) return false;
    _execPass(passer, best);
    return true;
  }

  void _execPass(SimPlayer passer, SimPlayer target) {
    int psk = passer.passStat;
    int err = max(5, 100 - psk); // 90-stat → 10% error

    if (_rng.nextInt(100) < err) {
      // Intercepted?
      var opp = passer.isHome ? awayTeam : homeTeam;
      SimPlayer? intr =
          opp.firstWhereOrNull((o) => o.pos.dist(target.pos) < 0.18);
      if (intr != null && _rng.nextInt(100) < 42) {
        ball.owner = intr;
        ball.phase = BallPhase.owned;
        ball.pos.set(intr.pos);
        _log('❌ Pas kesildi! ${intr.data.name} kaptı', Colors.redAccent);
        _maybeTriggerGegen(passer.isHome);
        return;
      }
    }

    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(passer.pos);
    ball.passTo.set(target.pos);
    ball.passTarget = target;
    ball.passTicksTotal = max(10, (passer.pos.dist(target.pos) * 75).round());
    ball.passTicksRemaining = ball.passTicksTotal;
    ball.pos.set(passer.pos);
    _log('✓ ${passer.data.name} → ${target.data.name}', Colors.lightBlueAccent);
  }

  // ─── PASS FLIGHT ────────────────────────────────────────────────────────────

  void _passFlightPhase() {
    ball.passTicksRemaining--;
    double t = 1.0 - (ball.passTicksRemaining / ball.passTicksTotal);
    ball.pos.set(ball.passFrom.lerp(ball.passTo, t));

    if (ball.passTicksRemaining > 0) return;

    SimPlayer? recv = ball.passTarget;
    if (recv == null) {
      ball.phase = BallPhase.free;
      return;
    }

    // Can an opponent intercept?
    var opp = recv.isHome ? awayTeam : homeTeam;
    SimPlayer? rival = opp.firstWhereOrNull(
        (o) => o.pos.dist(ball.pos) < recv.pos.dist(ball.pos) - 0.04);
    if (rival != null && _rng.nextInt(100) < 28) {
      ball.owner = rival;
      ball.phase = BallPhase.owned;
      ball.pos.set(rival.pos);
      _log('⚔️ ${rival.data.name} arasına girdi!', Colors.orangeAccent);
      _maybeTriggerGegen(recv.isHome);
      return;
    }

    ball.owner = recv;
    ball.phase = BallPhase.owned;
    ball.pos.set(recv.pos);
  }

  // ─── CROSS ──────────────────────────────────────────────────────────────────

  void _cross(SimPlayer crosser, List<SimPlayer> team) {
    bool goRight = crosser.isHome;
    var targets = team
        .where((t) => t != crosser && (t.role == 'FWD' || t.role == 'MID'))
        .toList();
    if (targets.isEmpty) return;

    var tgt = targets.reduce((a, b) =>
        (a.role == 'FWD' ? 0 : 1).compareTo(b.role == 'FWD' ? 0 : 1) <= 0
            ? a
            : b);

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
    ball.passTicksTotal = 45;
    ball.passTicksRemaining = 45;
  }

  // ─── SHOOT ──────────────────────────────────────────────────────────────────

  void _shoot(SimPlayer shooter, SimPlayer gk) {
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

    bool goRight = shooter.isHome;

    if (!onTarget) {
      _log('❌ İskalık! ${shooter.data.name}', Colors.grey);
      ball.owner = null;
      ball.phase = BallPhase.free;
      // Check for corner: shot missed wide near baseline
      bool nearBase = goRight ? shooter.pos.x > 0.72 : shooter.pos.x < 0.28;
      if (nearBase && _rng.nextBool()) {
        _triggerCorner(!shooter.isHome, shooter.pos.y);
      } else {
        ball.pos.set(gk.pos);
        ball.owner = gk;
        ball.phase = BallPhase.owned;
        _log('${gk.data.name} topu aldı', Colors.grey);
      }
      return;
    }

    // On target: GK save check
    int reflex = gk.reflexStat;
    // 1v1 save%: reflexStat * 0.44  =>  90 stat → 40% save, 60% GK error
    // With cover (defenders nearby): add 20%
    bool is1v1 = (shooter.isHome ? homeTeam : awayTeam)
        .where((p) => p.role == 'DEF' && p.pos.dist(shooter.pos) < 0.18)
        .isEmpty;
    int saveChance = max(8, (reflex * 0.44).round() + (is1v1 ? 0 : 20));

    if (_rng.nextInt(100) < saveChance) {
      _log('🧤 ${gk.data.name} kurtardı!', Colors.cyanAccent);
      ball.owner = gk;
      ball.phase = BallPhase.owned;
      ball.pos.set(gk.pos);
    } else {
      _goal(shooter.isHome, shooter.data.name);
    }
  }

  // ─── GOAL ───────────────────────────────────────────────────────────────────

  void _goal(bool homeScored, String scorer) {
    isGoal = true;
    if (homeScored)
      homeScore++;
    else
      awayScore++;
    goalCelebText = '⚽ GOOOL!\n$scorer\n${homeScore} - ${awayScore}';
    _log('⚽🔥 GOL! $scorer  $homeScore-$awayScore', Colors.yellowAccent);
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
  }

  void _cornerDelayPhase() {
    ball.cornerCountdown--;
    if (ball.cornerCountdown > 0) return;

    var taking = ball.cornerForHome ? homeTeam : awayTeam;
    var recv = taking.where((p) => p != ball.owner && p.role != 'GK').toList();
    if (recv.isEmpty) {
      ball.phase = BallPhase.free;
      return;
    }

    var target = recv
        .reduce((a, b) => a.pos.dist(ball.pos) < b.pos.dist(ball.pos) ? a : b);

    if (ball.owner != null) ball.owner!.isCornering = false;
    _log('⤴ Korner ortaya gönderildi!', Colors.purpleAccent);

    ball.owner = null;
    ball.phase = BallPhase.passFlight;
    ball.passFrom.set(ball.pos);
    ball.passTo.set(target.moveTarget);
    ball.passTarget = target;
    ball.passTicksTotal = 52;
    ball.passTicksRemaining = 52;
  }

  // ─── FREE BALL ──────────────────────────────────────────────────────────────

  void _freeBallPhase() {
    var all = [...homeTeam, ...awayTeam];
    SimPlayer? nearest;
    double minD = 999;
    for (var p in all) {
      p.moveTarget.set(ball.pos);
      double d = p.pos.dist(ball.pos);
      if (d < minD) {
        minD = d;
        nearest = p;
      }
    }
    if (nearest != null && minD < 0.055) {
      ball.owner = nearest;
      ball.phase = BallPhase.owned;
      ball.pos.set(nearest.pos);
      _log('⚽ ${nearest.data.name} topu aldı',
          nearest.isHome ? Colors.lightBlue : Colors.redAccent);
    }
  }

  // ─── TACKLE ─────────────────────────────────────────────────────────────────

  void _beenTackled(SimPlayer owner, SimPlayer tackler) {
    if (_rng.nextInt(100) < max(15, tackler.defStat - owner.dribbleStat + 38)) {
      ball.owner = tackler;
      ball.phase = BallPhase.owned;
      ball.pos.set(tackler.pos);
      _log('⚔️ ${tackler.data.name} topladı!', Colors.orangeAccent);
      _maybeTriggerGegen(owner.isHome);
    }
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

  void _updateMovementTarget(SimPlayer p) {
    // Gegenpres overrides everything
    if (p.isPressing) {
      p.pressTimer--;
      if (p.pressTimer <= 0) {
        p.isPressing = false;
        p.moveTarget.set(p.homeBase);
      } else
        p.moveTarget.set(ball.pos);
      return;
    }

    // Wide instruction
    if (p.instruction.stayWide) {
      bool isLeft = p.homeBase.y < 0.5;
      p.moveTarget.y = isLeft ? 0.07 : 0.93;
      if (ball.owner != null) {
        p.moveTarget.x =
            (ball.owner!.pos.x + (p.isHome ? 0.10 : -0.10)).clamp(0.08, 0.92);
      }
      return;
    }

    // Marking instruction
    if (p.instruction.marking) {
      var opp = p.isHome ? awayTeam : homeTeam;
      if (opp.isNotEmpty) {
        var mark =
            opp.reduce((a, b) => a.pos.dist(p.pos) < b.pos.dist(p.pos) ? a : b);
        p.moveTarget = Pos(mark.pos.x + (p.isHome ? -0.04 : 0.04), mark.pos.y);
      }
      return;
    }

    // Constant runs
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

    if (ball.owner == null) return;
    var bo = ball.owner!;

    if (bo.isHome == p.isHome) {
      // Teammate
      switch (p.role) {
        case 'GK':
          p.moveTarget.set(p.homeBase);
          break;
        case 'DEF':
          p.moveTarget =
              Pos(p.homeBase.x, p.homeBase.y + (bo.pos.y - 0.5) * 0.15);
          break;
        case 'MID':
          p.moveTarget = Pos(
            (bo.pos.x + (p.isHome ? -0.06 : 0.06)).clamp(0.05, 0.95),
            bo.pos.y + (_rng.nextDouble() - 0.5) * 0.22,
          );
          break;
        case 'FWD':
          p.moveTarget = Pos(
            (bo.pos.x + (p.isHome ? 0.14 : -0.14)).clamp(0.05, 0.95),
            bo.pos.y + (_rng.nextDouble() - 0.5) * 0.28,
          );
          break;
      }
    } else {
      // Opponent
      if (p.role == 'GK') {
        double idealY = bo.pos.y.clamp(0.26, 0.74);
        p.moveTarget = Pos(p.homeBase.x, idealY);
      } else {
        p.moveTarget = Pos(
          (bo.pos.x + (p.isHome ? -0.10 : 0.10)).clamp(0.05, 0.95),
          bo.pos.y + (_rng.nextDouble() - 0.5) * 0.14,
        );
        // Inline intercept
        if (p.pos.dist(bo.pos) < 0.05) {
          if (_rng.nextInt(100) < max(8, p.defStat - bo.dribbleStat + 32)) {
            _beenTackled(bo, p);
          }
        }
      }
    }

    _constrainByTactic(p);
  }

  void _constrainByTactic(SimPlayer p) {
    if (p.role == 'GK') return;
    TacticStyle tac = _myTactic(p.isHome);
    bool goRight = p.isHome;

    if (tac == TacticStyle.defensive && p.role == 'DEF') {
      p.moveTarget.x = goRight
          ? p.moveTarget.x.clamp(0.04, 0.36)
          : p.moveTarget.x.clamp(0.64, 0.96);
    }
    if (tac == TacticStyle.counter &&
        p.role == 'DEF' &&
        ball.owner != null &&
        ball.owner!.isHome != p.isHome) {
      p.moveTarget.x = goRight
          ? p.moveTarget.x.clamp(0.04, 0.30)
          : p.moveTarget.x.clamp(0.70, 0.96);
    }
  }

  void _moveToward(SimPlayer p) {
    double dx = p.moveTarget.x - p.pos.x;
    double dy = p.moveTarget.y - p.pos.y;
    double d = sqrt(dx * dx + dy * dy);
    if (d < 0.001) return;

    double spd = (0.005 + (p.stats['Hız'] ?? 10) * 0.00014) * _speedFactor();
    double step = min(d, spd);
    p.pos.x = (p.pos.x + dx / d * step).clamp(0.01, 0.99);
    p.pos.y = (p.pos.y + dy / d * step).clamp(0.02, 0.98);
  }

  double _speedFactor() {
    if (speed == MatchSpeed.slow) return 0.65;
    if (speed == MatchSpeed.fast) return 1.45;
    return 1.0;
  }

  // ─── LOG ────────────────────────────────────────────────────────────────────

  void _log(String msg, Color color) {
    logs.insert(0, LogEntry(msg, color, matchMinute.toInt()));
    if (logs.length > 22) logs.removeLast();
  }

  // ─── END MATCH ──────────────────────────────────────────────────────────────

  void _endMatch() {
    if (isMatchOver) return;
    isMatchOver = true;
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
      body: Column(children: [
        _scoreBar(),
        _speedBar(),
        Expanded(child: _pitch()),
        _logPanel(),
      ]),
    );
  }

  Widget _scoreBar() {
    bool playerHome = !widget.isPlayerTeamAway;
    int myG = playerHome ? homeScore : awayScore;
    int oppG = playerHome ? awayScore : homeScore;

    return Container(
      height: 76,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0C1824), Color(0xFF162238)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF223358))),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Text('$myG',
            style: GoogleFonts.russoOne(
                fontSize: 54,
                color: Colors.cyanAccent,
                shadows: [const Shadow(color: Colors.cyan, blurRadius: 14)])),
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            isMatchOver ? 'BİTTİ' : "${matchMinute.toStringAsFixed(0)}'",
            style: GoogleFonts.orbitron(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                fontSize: 54,
                color: Colors.redAccent,
                shadows: [const Shadow(color: Colors.red, blurRadius: 14)])),
      ]),
    );
  }

  Widget _speedBar() {
    return Container(
      height: 38,
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
                child: Text(s.label,
                    style: TextStyle(
                        color: speed == s ? s.color : Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
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
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(color: Colors.white24, width: 2),
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
          ...homeTeam.map((p) => _playerDot(p, Colors.cyanAccent, w, h)),
          ...awayTeam.map((p) => _playerDot(p, Colors.redAccent, w, h)),
          // Ball
          _ballDot(w, h),
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

  Widget _playerDot(SimPlayer p, Color base, double w, double h) {
    bool hasBall = (ball.owner == p);
    Color c = p.isPressing ? Colors.orangeAccent : base;
    return Positioned(
      left: (p.pos.x * w - 13).clamp(0.0, w - 26),
      top: (p.pos.y * h - 16).clamp(0.0, h - 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withOpacity(0.88),
              border: Border.all(
                  color: hasBall ? Colors.white : Colors.black87,
                  width: hasBall ? 2.5 : 1),
              boxShadow: [
                BoxShadow(
                    color: c.withOpacity(hasBall ? 0.9 : 0.4),
                    blurRadius: hasBall ? 10 : 5)
              ],
            ),
            child: Center(
              child: Text(p.role[0],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Text(
            p.data.name.length > 6
                ? '${p.data.name.substring(0, 5)}.'
                : p.data.name,
            style:
                TextStyle(color: c, fontSize: 7, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _ballDot(double w, double h) {
    Pos bp = ball.phase == BallPhase.passFlight
        ? ball.pos
        : (ball.owner?.pos ?? ball.pos);
    Color bc = ball.phase == BallPhase.cornerDelay
        ? Colors.purpleAccent
        : Colors.white;
    return Positioned(
      left: (bp.x * w - 7).clamp(0.0, w - 14),
      top: (bp.y * h - 7).clamp(0.0, h - 14),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bc,
          boxShadow: [
            BoxShadow(
                color: bc.withOpacity(0.9), blurRadius: 10, spreadRadius: 2)
          ],
        ),
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
}

// ─── PITCH PAINTER ──────────────────────────────────────────────────────────

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double w = size.width, h = size.height;
    // Center line
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), p);
    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.15, p);
    // Center dot
    p.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), 4, p);
    p.style = PaintingStyle.stroke;
    // Penalty boxes
    canvas.drawRect(Rect.fromLTWH(0, h * 0.23, w * 0.16, h * 0.54), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.84, h * 0.23, w * 0.16, h * 0.54), p);
    // Small boxes
    canvas.drawRect(Rect.fromLTWH(0, h * 0.36, w * 0.055, h * 0.28), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.945, h * 0.36, w * 0.055, h * 0.28), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── ITERABLE EXT ────────────────────────────────────────────────────────────

extension IterableFirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var e in this) if (test(e)) return e;
    return null;
  }
}
