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

  // Visual & marking state
  bool isPassShoot = false;
  int passShootTimer = 0;
  int playerIndex = 0; // 0=GK,1-2=DEF,3-4=MID,5-6=FWD
  SimPlayer? markTarget; // assigned man-marking target

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

  // Shot-flight state
  bool shotWillGoal = false;
  bool shotOnTarget = false;
  SimPlayer? shotGk;
  String shotShooterName = '';
  bool shotIsHome = false;

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
  int _shotSlowMoTicks = 0;

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
    // Tüm oyuncuları baz pozisyonlara sıfırla
    for (var p in [...homeTeam, ...awayTeam]) {
      p.pos.set(p.homeBase);
      p.moveTarget.set(p.homeBase);
      p.isPressing = false;
      p.pressTimer = 0;
      p.isCornering = false;
      p.isPassShoot = false;
      p.passShootTimer = 0;
      p.markTarget = null;
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
    _shotSlowMoTicks = 0;

    SimPlayer kicker = byTeam.firstWhere(
      (p) => p.role == 'FWD',
      orElse: () => byTeam.last,
    );
    kicker.pos.set(Pos(0.5, 0.5));
    ball.owner = kicker;

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

    if (_shotSlowMoTicks > 0) _shotSlowMoTicks--;

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

    // ── OWNER MOVEMENT: HaxBall-style – lateral/diagonal runs with forward intent ──
    int moveMode = tick % 18;
    if (moveMode < 6) {
      // Charge forward – main advance
      owner.moveTarget = Pos(
        (owner.pos.x + (goRight ? 0.035 : -0.035)).clamp(0.01, 0.99),
        (owner.pos.y + (_rng.nextDouble() - 0.5) * 0.04).clamp(0.02, 0.98),
      );
    } else if (moveMode < 10) {
      // Lateral drift – create passing angle
      owner.moveTarget = Pos(
        (owner.pos.x + (goRight ? 0.010 : -0.010)).clamp(0.01, 0.99),
        (owner.pos.y + (_rng.nextDouble() - 0.5) * 0.10).clamp(0.02, 0.98),
      );
    } else if (moveMode < 13) {
      // Hold position briefly – look for pass
      owner.moveTarget = Pos(
        owner.pos.x,
        owner.pos.y + (_rng.nextDouble() - 0.5) * 0.03,
      );
    } else {
      // Diagonal run – forward + lateral
      double diagY = (owner.homeBase.y > 0.5 ? 1 : -1) * 0.06;
      owner.moveTarget = Pos(
        (owner.pos.x + (goRight ? 0.028 : -0.028)).clamp(0.01, 0.99),
        (owner.pos.y + diagY + (_rng.nextDouble() - 0.5) * 0.03)
            .clamp(0.02, 0.98),
      );
    }

    // Yakın baskı yapanlar
    var pressers = opp.where((o) => o.pos.dist(owner.pos) < 0.11).toList();

    // ── GK pasla temizle ──
    if (owner.role == 'GK') {
      owner.moveTarget.set(owner.homeBase);
      if (tick % 20 == 0) _tryPass(owner, team, preferFwd: false);
      return;
    }

    TacticStyle myTac = _myTactic(owner.isHome);

    // ── DUVAR PAS: kenar çizgisine yakınken köşeye çekilip içe pas ──
    bool nearSideWall = owner.pos.y < 0.09 || owner.pos.y > 0.91;
    bool notInBox = goRight ? owner.pos.x < 0.78 : owner.pos.x > 0.22;
    if (nearSideWall && notInBox && pressers.isEmpty && _rng.nextInt(100) < 3) {
      var closeMates = team
          .where((t) =>
              t != owner && t.role != 'GK' && t.pos.dist(owner.pos) < 0.28)
          .toList();
      if (closeMates.isNotEmpty) {
        closeMates.sort(
            (a, b) => a.pos.dist(owner.pos).compareTo(b.pos.dist(owner.pos)));
        _log('🧱 ${owner.data.name} duvara oynadı!', Colors.tealAccent);
        _execPass(owner, closeMates.first);
        return;
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
      if (tick % 12 == 0 || pressers.isNotEmpty) {
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    if (owner.instruction.constantRuns) {
      owner.moveTarget = Pos(goalX, 0.35 + _rng.nextDouble() * 0.30);
    }

    // ── ŞUT (PAS ÖNCE YAKLAŞIM) ──
    bool inBox = goRight ? owner.pos.x > 0.78 : owner.pos.x < 0.22;
    if (inBox && !owner.instruction.passOnly) {
      // Önce yakın takım arkadaşına pas ver → gol pasla gelsin
      bool hasOpenBoxMate = team.any((t) =>
          t != owner &&
          t.role != 'GK' &&
          t.pos.dist(owner.pos) < 0.22 &&
          opp.every((o) => o.pos.dist(t.pos) > 0.10));
      if (hasOpenBoxMate && _rng.nextInt(100) < 48) {
        if (_tryPass(owner, team, preferFwd: false, boxPass: true)) return;
      }

      int shootChance = _calcShootChance(myTac, owner.role, pressers.length);
      if (_rng.nextInt(100) < shootChance) {
        _shoot(owner, gk);
        return;
      }
    }

    // ── MÜDAHALE RİSKİ ──
    if (pressers.isNotEmpty) {
      var tackler = pressers.first;
      int defSk = tackler.defStat;
      int driSk = owner.dribbleStat;
      if (_rng.nextInt(100) < max(8, defSk - driSk + 35)) {
        _beenTackled(owner, tackler);
        return;
      }
      // Baskı altında → pas
      if (_rng.nextInt(100) < 65) {
        if (_tryPass(owner, team, preferFwd: true)) return;
      }
    }

    // ── DÜZENLI PAS (sık sık – canlı maç hissi) ──
    int passEvery = myTac == TacticStyle.tikiTaka
        ? 8 // tiki-taka: çok sık pas
        : myTac == TacticStyle.gegen
            ? 11
            : myTac == TacticStyle.highPress
                ? 9
                : 11;
    if (tick % passEvery == 0) {
      _tryPass(owner, team, preferFwd: true);
    }

    // ── GENİŞ KANAT DEĞİŞİMİ ──
    if (tick % 34 == 0) {
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
      {bool preferFwd = false, bool boxPass = false}) {
    var opts = team.where((t) => t != passer && t.role != 'GK').toList();
    if (opts.isEmpty) return false;

    bool goRight = passer.isHome;
    var oppTeam = passer.isHome ? awayTeam : homeTeam;
    SimPlayer? best;
    double bestS = -9999;

    for (var t in opts) {
      double s = 0;

      // İleriye pas tercihi – HaxBall tarzı: geri pas da olabilir
      if (preferFwd) {
        double fwdDist =
            goRight ? t.pos.x - passer.pos.x : passer.pos.x - t.pos.x;
        // Reduced bias from 100 → 45: backward/sideways passes become viable
        s += fwdDist * 45;
      }

      // Ceza alanı içi pas: yakın ve açık oyuncuyu tercih et
      if (boxPass) {
        double d2 = passer.pos.dist(t.pos);
        if (d2 < 0.22) s += 80;
      }

      // Açık oyuncu: yakınında rakip yok (markajdan kurtulmuş)
      bool open = oppTeam.every((o) => o.pos.dist(t.pos) > 0.12);
      if (open) s += 70;

      // Farklı Y bölgesinde (yayılma): yoğunlaşmayı önle
      double yDiff = (t.pos.y - passer.pos.y).abs();
      if (yDiff > 0.18) s += 30;

      if (t.role == 'FWD') s += 40;
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

    // LED ring şut efekti
    shooter.isPassShoot = true;
    shooter.passShootTimer = 45;

    bool goRight = shooter.isHome;

    // Determine GK save outcome upfront
    int reflex = gk.reflexStat;
    bool is1v1 = (shooter.isHome ? homeTeam : awayTeam)
        .where((p) => p.role == 'DEF' && p.pos.dist(shooter.pos) < 0.18)
        .isEmpty;
    int saveChance = max(8, (reflex * 0.44).round() + (is1v1 ? 0 : 20));
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
      // On-target: aim within goal mouth with small variation
      goalY = 0.38 + _rng.nextDouble() * 0.24;
    }

    // Launch ball as shot flight
    ball.owner = null;
    ball.phase = BallPhase.shotFlight;
    ball.passFrom.set(shooter.pos);
    ball.passTo = Pos(goalX, goalY);
    ball.passTicksTotal = 28;
    ball.passTicksRemaining = 28;
    ball.pos.set(shooter.pos);

    // Engage slow motion
    _shotSlowMoTicks = 55;
  }

  // ─── SHOT FLIGHT ────────────────────────────────────────────────────────────

  void _shotFlightPhase() {
    ball.passTicksRemaining--;
    double t = 1.0 - (ball.passTicksRemaining / ball.passTicksTotal);
    ball.pos.set(ball.passFrom.lerp(ball.passTo, t));

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
          ball.phase = BallPhase.free;
          ball.pos.set(ball.passTo);
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

    _log('🧤 ${gk.data.name} kurtardı!', Colors.cyanAccent);
    ball.pos.set(gk.pos);

    int outcome = _rng.nextInt(100);

    if (outcome < 35) {
      // ── RICOCHET: ball bounces to a random position near goal ──
      // Home team attacks right (x→1), away team attacks left (x→0)
      bool nearRightGoal = ball.shotIsHome; // home shoots at right goal
      double rebX = nearRightGoal
          ? 0.78 + _rng.nextDouble() * 0.10 // near right goal mouth
          : 0.10 + _rng.nextDouble() * 0.10; // near left goal mouth
      double rebY = 0.28 + _rng.nextDouble() * 0.44;
      ball.owner = null;
      ball.phase = BallPhase.free;
      ball.pos = Pos(rebX, rebY);
      _log('💥 Top sekti! Herkes bölgeye!', Colors.orangeAccent);
    } else if (outcome < 65) {
      // ── DISTRIBUTION: GK throws to nearest open teammate ──
      var ownTeam = gk.isHome ? homeTeam : awayTeam;
      var targets = ownTeam.where((p) => p != gk && p.role != 'GK').toList();
      if (targets.isNotEmpty) {
        targets
            .sort((a, b) => a.pos.dist(gk.pos).compareTo(b.pos.dist(gk.pos)));
        SimPlayer recv = targets.first;
        _log('🧤➡ ${gk.data.name} atışla ${recv.data.name}\'e dağıttı',
            Colors.lightBlueAccent);
        ball.owner = null;
        ball.phase = BallPhase.passFlight;
        ball.passFrom.set(gk.pos);
        ball.passTo.set(recv.pos);
        ball.passTarget = recv;
        ball.passTicksTotal = max(16, (gk.pos.dist(recv.pos) * 70).round());
        ball.passTicksRemaining = ball.passTicksTotal;
      } else {
        // Fallback: GK holds
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
    if (homeScored)
      homeScore++;
    else
      awayScore++;
    goalCelebText = '⚽ GOOOL!\n$scorer\n${homeScore} - ${awayScore}';
    _log('⚽🔥 GOL! $scorer  $homeScore-$awayScore', Colors.yellowAccent);

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

    // DEF: rakibin FWD/kanat oyuncularını tutar
    // DEF index 1 → opp FWD index 5 veya 6 (playerIndex eşleşmesi)
    if (p.role == 'DEF') {
      var oppFwds = opp.where((o) => o.role == 'FWD').toList();
      if (oppFwds.isEmpty) return null;
      oppFwds.sort((a, b) => a.playerIndex.compareTo(b.playerIndex));
      int pick = (p.playerIndex == 1) ? 0 : (oppFwds.length > 1 ? 1 : 0);
      return oppFwds[pick.clamp(0, oppFwds.length - 1)];
    }

    // MID: rakip orta sahaları tutar
    if (p.role == 'MID') {
      var oppMids = opp.where((o) => o.role == 'MID').toList();
      if (oppMids.isEmpty) {
        // Orta saha yoksa DEF'e baskı
        var oppDefs = opp.where((o) => o.role == 'DEF').toList();
        if (oppDefs.isEmpty) return null;
        oppDefs.sort((a, b) => a.pos.dist(p.pos).compareTo(b.pos.dist(p.pos)));
        return oppDefs.first;
      }
      oppMids.sort((a, b) => a.playerIndex.compareTo(b.playerIndex));
      int pick = (p.playerIndex == 3) ? 0 : (oppMids.length > 1 ? 1 : 0);
      return oppMids[pick.clamp(0, oppMids.length - 1)];
    }

    // FWD: rakip DEF'i tutar (savunmaya çekilince)
    if (p.role == 'FWD') {
      bool defending = ball.owner != null && ball.owner!.isHome != p.isHome;
      if (!defending) return null;
      var oppDefs = opp.where((o) => o.role == 'DEF').toList();
      if (oppDefs.isEmpty) return null;
      oppDefs.sort((a, b) => a.playerIndex.compareTo(b.playerIndex));
      int pick = (p.playerIndex == 5) ? 0 : (oppDefs.length > 1 ? 1 : 0);
      return oppDefs[pick.clamp(0, oppDefs.length - 1)];
    }

    return null;
  }

  // Takım toplu olduğunda yayılma pozisyonunu hesapla
  Pos _spreadPosition(SimPlayer p, Pos ballPos) {
    bool goRight = p.isHome;
    // Her oyuncuya sahadaki farklı dilim verilir (yığılmayı önler)
    // Y dilimi: playerIndex 0-6 → 0.10, 0.22, 0.78, 0.18, 0.82, 0.28, 0.72
    const spreadY = [0.50, 0.22, 0.78, 0.14, 0.86, 0.30, 0.70];
    double ty = spreadY[p.playerIndex.clamp(0, 6)];

    double tx;
    switch (p.role) {
      case 'GK':
        return p.homeBase.copy();
      case 'DEF':
        // Savunma hattını biraz ilerlet ama dikkatli kal
        tx = goRight
            ? (ballPos.x - 0.22).clamp(0.08, 0.40)
            : (ballPos.x + 0.22).clamp(0.60, 0.92);
        break;
      case 'MID':
        // Topu taşıyan oyuncunun arkasında veya yanında, geniş aç
        tx = goRight
            ? (ballPos.x - 0.06).clamp(0.30, 0.72)
            : (ballPos.x + 0.06).clamp(0.28, 0.70);
        break;
      case 'FWD':
        // İleri koş, geniş açıl
        tx = goRight
            ? (ballPos.x + 0.16).clamp(0.52, 0.92)
            : (ballPos.x - 0.16).clamp(0.08, 0.48);
        break;
      default:
        tx = p.homeBase.x;
    }
    return Pos(tx, ty);
  }

  void _updateMovementTarget(SimPlayer p) {
    // During shot flight: players subtly shift (anticipate rebound) during slow-mo
    if (ball.phase == BallPhase.shotFlight) {
      if (tick % 7 == p.playerIndex % 7) {
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

    if (ball.owner == null) return;
    var bo = ball.owner!;
    bool ownTeamHasBall = (bo.isHome == p.isHome);

    // ── OTOMATİK MAN-MARKING sistemi ──
    // Markaj hedefini güncelle (sadece savunma pozisyonundayken)
    SimPlayer? autoMark = _resolveMarkTarget(p);
    p.markTarget = autoMark;

    if (!ownTeamHasBall && autoMark != null && p.role != 'GK') {
      // Rakibi gölgele - biraz önünde dur
      double shadowX = autoMark.pos.x + (p.isHome ? -0.04 : 0.04);
      double shadowY = autoMark.pos.y;
      p.moveTarget = Pos(
        shadowX.clamp(0.04, 0.96),
        shadowY.clamp(0.04, 0.96),
      );
      // Yakın geçişte müdahale
      if (p.pos.dist(autoMark.pos) < 0.052) {
        if (_rng.nextInt(100) < max(8, p.defStat - bo.dribbleStat + 30)) {
          _beenTackled(bo, p);
        }
      }
      _constrainByTactic(p);
      _applySeparation(p);
      return;
    }

    if (ownTeamHasBall) {
      // ── TAKIM TOPLU: yayılma pozisyonu al ──
      if (p.role == 'GK') {
        // GK markaj yapabilir veya kalesinde durabilir
        if (autoMark != null) {
          // GK rakip FWD'yi takip et ama kaleyi bırakma
          double gx = p.homeBase.x;
          double gy =
              (autoMark.pos.y * 0.4 + p.homeBase.y * 0.6).clamp(0.28, 0.72);
          p.moveTarget = Pos(gx, gy);
        } else {
          p.moveTarget.set(p.homeBase);
        }
      } else {
        // Yayılma + pas almak için konum al – her tick güncelle (canlı hareket)
        Pos spread = _spreadPosition(p, bo.pos);
        p.moveTarget = Pos(
          (spread.x + (_rng.nextDouble() - 0.5) * 0.04).clamp(0.04, 0.96),
          (spread.y + (_rng.nextDouble() - 0.5) * 0.03).clamp(0.04, 0.96),
        );
      }
    } else {
      // ── SAVUNMA: GK kalesinde ──
      if (p.role == 'GK') {
        double idealY = bo.pos.y.clamp(0.26, 0.74);
        p.moveTarget = Pos(p.homeBase.x, idealY);
      } else {
        // Orta saha/FWD için topun yakınına baskı
        p.moveTarget = Pos(
          (bo.pos.x + (p.isHome ? -0.10 : 0.10)).clamp(0.05, 0.95),
          bo.pos.y + (_rng.nextDouble() - 0.5) * 0.12,
        );
        // Yakın geçişte müdahale
        if (p.pos.dist(bo.pos) < 0.05) {
          if (_rng.nextInt(100) < max(8, p.defStat - bo.dribbleStat + 32)) {
            _beenTackled(bo, p);
          }
        }
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
    // Slow motion during shot flight
    if (ball.phase == BallPhase.shotFlight || _shotSlowMoTicks > 40) {
      return 0.28; // ~3x slower – cinematic slow-mo
    }
    if (_shotSlowMoTicks > 0) {
      // Ease back to normal speed after shot resolves
      double ease = _shotSlowMoTicks / 40.0;
      double base = speed == MatchSpeed.slow
          ? 0.36
          : speed == MatchSpeed.fast
              ? 1.45
              : 0.78;
      return base * (1.0 - ease * 0.65);
    }
    if (speed == MatchSpeed.slow) return 0.36;
    if (speed == MatchSpeed.fast) return 1.45;
    return 0.78;
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
          ...homeTeam.map((p) => _playerDot(p, Colors.redAccent, w, h)),
          ...awayTeam.map((p) => _playerDot(p, Colors.cyanAccent, w, h)),
          // Ball
          _ballDot(w, h),
          // Slow-motion overlay
          if (ball.phase == BallPhase.shotFlight || _shotSlowMoTicks > 40)
            Positioned(
              top: 8,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.6), width: 1),
                ),
                child: Text(
                  '🎬 SLOW MO',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
            ),
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
    bool isMarking = (p.markTarget != null);
    Color c = p.isPressing ? Colors.orangeAccent : base;
    bool ledActive = p.isPassShoot;

    return Positioned(
      left: (p.pos.x * w - 13).clamp(0.0, w - 26),
      top: (p.pos.y * h - 16).clamp(0.0, h - 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // LED ring when passing or shooting
              if (ledActive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: 0.0),
                  duration: const Duration(milliseconds: 420),
                  builder: (_, v, __) => Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(v * 0.95),
                        width: 2.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(v * 0.85),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              // Marking indicator ring
              if (isMarking && !ledActive)
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.yellowAccent.withOpacity(0.55),
                        width: 1.2),
                  ),
                ),
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
            ],
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
    bool inFlight = ball.phase == BallPhase.passFlight ||
        ball.phase == BallPhase.shotFlight;
    Pos bp = inFlight ? ball.pos : (ball.owner?.pos ?? ball.pos);
    bool isShotBall = ball.phase == BallPhase.shotFlight;
    Color bc = ball.phase == BallPhase.cornerDelay
        ? Colors.purpleAccent
        : isShotBall
            ? Colors.orangeAccent
            : Colors.white;
    double size = isShotBall ? 16 : 14;
    return Positioned(
      left: (bp.x * w - size / 2).clamp(0.0, w - size),
      top: (bp.y * h - size / 2).clamp(0.0, h - size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bc,
          boxShadow: [
            BoxShadow(
                color: bc.withOpacity(isShotBall ? 1.0 : 0.9),
                blurRadius: isShotBall ? 18 : 10,
                spreadRadius: isShotBall ? 4 : 2)
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
