import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../data/player_data.dart';

// =============================================================================
// NATBALL 3D – Perspektifli 3D futbol oyunu (HaxBall 3D tarzı)
// Sınırsız FPS | Ownership tabanlı top | Exponential damping
// Kale ağları gerçek zamanlı animasyon | Gol'de ağ uçuşur
// =============================================================================

// ─── Sabitler ────────────────────────────────────────────────────────────────
const double _k3FieldW = 1.0; // normalize alan genişliği
const double _k3FieldH = 1.0; // normalize alan yüksekliği (ekran)
const double _k3GoalDepth = 0.08; // kale derinliği (perspektif)
const double _k3GoalHalfW = 0.16; // kale yarı-yükseklik
const double _k3PlayerAccel = 0.0020;
const double _k3PlayerDamp = 0.74;
const double _k3MaxSpeed = 0.0080;
const double _k3BallFric = 0.980;
const double _k3BallBounce = 0.70;
const double _k3ShootPower = 0.036;
const double _k3PassPower = 0.022;
const double _k3AiAccel = 0.0016;
const double _k3PickupR = 0.032;
const double _k3StealRange = 0.040;
const double _k3PlayerR = 0.014;
const double _k3BallR = 0.010;
const double _k3MatchDur = 180.0; // 3 dakika
const double _k3GkRange = 0.16;
// Kale Y sınırları (saha yüksekliğinin %34-%66)
const double _k3GoalY1 = 0.34;
const double _k3GoalY2 = 0.66;

// ─── Perspektif yardımcıları ─────────────────────────────────────────────────
// Saha koordinatları:
//   fieldX ∈ [0,1]: sol kale → sağ kale
//   fieldY ∈ [0,1]: uzak kenar (arka) → yakın kenar (ön)
// Stadyum kamerası: biraz yukarıdan hafif eğim, yatay geniş görünüm

// Perspektif ölçek: y=0 (uzak) → daha küçük, y=1 (yakın) → daha büyük
double _perspScale(double y, {double near = 1.18, double far = 0.60}) {
  return far + (near - far) * y;
}

Offset _project(double fieldX, double fieldY, Size sz) {
  // Horizon yüksekliği: ekranın %18'i
  const double horizonRatio = 0.18;
  // Alt kenar: ekranın %96'sı (neredeyse dibe kadar)
  const double bottomRatio = 0.96;
  // Saha yan marjinler (perspektifle değişir)
  const double leftMarginFar = 0.08; // uzakta saha sol kenarı
  const double rightMarginFar = 0.92; // uzakta saha sağ kenarı
  const double leftMarginNear = 0.01; // yakında saha sol kenarı
  const double rightMarginNear = 0.99; // yakında saha sağ kenarı

  // Y ekranı: horizon → alt arasında linear
  double screenY =
      sz.height * (horizonRatio + (bottomRatio - horizonRatio) * fieldY);

  // X: uzak kenarda daralmış, yakın kenarda genişlemiş trapez
  double leftEdge =
      sz.width * (leftMarginFar + (leftMarginNear - leftMarginFar) * fieldY);
  double rightEdge =
      sz.width * (rightMarginFar + (rightMarginNear - rightMarginFar) * fieldY);
  double screenX = leftEdge + (rightEdge - leftEdge) * fieldX;

  return Offset(screenX, screenY);
}

double _projRadius(double fieldY, double baseR, Size sz) {
  return baseR * sz.width * _perspScale(fieldY);
}

// =============================================================================
// VERİ SINIFLARI
// =============================================================================
class _P3 {
  String name;
  double x, y; // saha koord (0-1)
  double vx = 0, vy = 0;
  double facingAngle;
  final bool isHuman;
  final bool isTeamA;
  final double homeX, homeY;
  final bool isGk;
  double _aiPassSec = 0.0;
  bool _isJumping = false;
  double _jumpPhase = 0.0; // 0..1 (jump arc)
  double _jumpZ = 0.0; // vizüel yükseklik

  _P3({
    required this.name,
    required this.x,
    required this.y,
    required this.isHuman,
    required this.isTeamA,
    required this.homeX,
    required this.homeY,
    this.isGk = false,
  }) : facingAngle = isTeamA ? 0.0 : pi;
}

class _Ball3 {
  double x = 0.5, y = 0.5;
  double vx = 0, vy = 0;
  double z = 0.0; // yükseklik
  double vz = 0.0;
  _P3? owner;
}

// Kale ağı partikülleri
class _NetParticle {
  double x, y;
  double vx, vy;
  double life; // 0..1
  double size;
  Color color;
  _NetParticle(
      this.x, this.y, this.vx, this.vy, this.life, this.size, this.color);
}

// Chat
class _Chat3 {
  final String sender;
  final String text;
  _Chat3(this.sender, this.text);
}

// =============================================================================
// ANA WİDGET
// =============================================================================
class NatBall3DGameView extends StatefulWidget {
  final List<Player> myTeam;
  final List<Player> oppTeam;
  final VoidCallback onExit;

  const NatBall3DGameView({
    super.key,
    required this.myTeam,
    required this.oppTeam,
    required this.onExit,
  });

  @override
  State<NatBall3DGameView> createState() => _NatBall3DState();
}

class _NatBall3DState extends State<NatBall3DGameView>
    with TickerProviderStateMixin {
  final _rng = Random();
  Ticker? _ticker;
  Duration _lastFrame = Duration.zero;

  late List<_P3> _teamA;
  late List<_P3> _teamB;
  late _P3 _human;
  final _Ball3 _ball = _Ball3();

  final Set<LogicalKeyboardKey> _keys = {};
  final FocusNode _focusNode = FocusNode();

  int _scoreA = 0, _scoreB = 0;
  double _elapsedSec = 0;
  bool _isGoal = false;
  String _goalText = '';
  double _goalPauseSec = 0;
  bool _isMatchOver = false;
  double _dt = 1 / 60.0;
  double _fps = 0;

  // Kontrol
  double _kickCooldownSec = 0;
  double _xDoubleTapSec = 0;
  bool _xWasHeld = false;
  bool _shiftWasHeld = false;
  bool _zWasHeld = false;
  bool _humanWantsPass = false;

  // Ağ partikülleri
  final List<_NetParticle> _netParticles = [];
  bool _netAnimActive = false;

  // GK save
  bool _gkSaveAnim = false;
  double _gkSaveSec = 0;

  // Nickname
  bool _showNick = true;
  final TextEditingController _nickCtrl = TextEditingController();

  // Fullscreen
  bool _isFullscreen = false;

  // Chat
  bool _isChatOpen = false;
  final TextEditingController _chatInput = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final List<_Chat3> _chatMessages = [];
  final ScrollController _chatScroll = ScrollController();

  // Dinamik marker
  _P3? _humanMarker;

  @override
  void initState() {
    super.initState();
    _initGame();
    _ticker = createTicker(_onTick);
    _ticker!.start();
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker?.dispose();
    _focusNode.dispose();
    _chatFocusNode.dispose();
    _nickCtrl.dispose();
    _chatInput.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  // ─── INIT ────────────────────────────────────────────────────────────────
  void _initGame() {
    _scoreA = 0;
    _scoreB = 0;
    _elapsedSec = 0;
    _isGoal = false;
    _isMatchOver = false;
    _kickCooldownSec = 0;
    _xDoubleTapSec = 0;
    _xWasHeld = false;
    _shiftWasHeld = false;
    _zWasHeld = false;
    _humanWantsPass = false;
    _gkSaveAnim = false;
    _gkSaveSec = 0;
    _netParticles.clear();
    _netAnimActive = false;
    _keys.clear();
    _buildPlayers();
    _kickoff(teamAStarts: true);
  }

  void _buildPlayers() {
    final baseXA = [0.07, 0.20, 0.20, 0.38, 0.52, 0.52, 0.72];
    final baseYA = [0.50, 0.28, 0.72, 0.50, 0.20, 0.80, 0.50];
    final namesA = _safeNames(widget.myTeam, 7);
    _teamA = List.generate(
        7,
        (i) => _P3(
              name: namesA[i],
              x: baseXA[i],
              y: baseYA[i],
              isHuman: i == 6,
              isTeamA: true,
              homeX: baseXA[i],
              homeY: baseYA[i],
              isGk: i == 0,
            ));
    _human = _teamA[6];

    final baseXB = [0.93, 0.80, 0.80, 0.62, 0.48, 0.48, 0.28];
    final baseYB = [0.50, 0.28, 0.72, 0.50, 0.20, 0.80, 0.50];
    final namesB = _safeNames(widget.oppTeam, 7);
    _teamB = List.generate(
        7,
        (i) => _P3(
              name: namesB[i],
              x: baseXB[i],
              y: baseYB[i],
              isHuman: false,
              isTeamA: false,
              homeX: baseXB[i],
              homeY: baseYB[i],
              isGk: i == 0,
            ));
  }

  List<String> _safeNames(List<Player> players, int count) {
    final out = players.map((p) => p.name).toList();
    while (out.length < count) out.add('Player${out.length + 1}');
    return out.take(count).toList();
  }

  void _kickoff({required bool teamAStarts}) {
    for (var p in [..._teamA, ..._teamB]) {
      p.x = p.isTeamA ? p.homeX.clamp(0.05, 0.47) : p.homeX.clamp(0.53, 0.95);
      p.y = p.homeY;
      p.vx = 0;
      p.vy = 0;
      p.facingAngle = p.isTeamA ? 0.0 : pi;
      p._aiPassSec = 0.10 + _rng.nextDouble() * 0.25;
      p._isJumping = false;
      p._jumpZ = 0;
    }
    _ball.x = 0.5;
    _ball.y = 0.5;
    _ball.vx = 0;
    _ball.vy = 0;
    _ball.z = 0;
    _ball.vz = 0;
    _ball.owner = teamAStarts ? _human : _teamB[3];
    _kickCooldownSec = 0;
  }

  // ─── GAME LOOP ───────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final dt = ((elapsed - _lastFrame).inMicroseconds / 1e6).clamp(0.0, 0.05)
        as double;
    _lastFrame = elapsed;
    if (dt > 0) _fps = _fps * 0.9 + (1.0 / dt) * 0.1;
    _simStep(dt);
    setState(() {});
  }

  void _simStep(double dt) {
    _dt = dt.clamp(0.001, 0.05);
    if (_showNick) return;
    if (_isChatOpen) return;
    if (_isMatchOver) return;

    if (_isGoal) {
      _goalPauseSec -= dt;
      // Ağ partikülleri güncelle
      _updateNetParticles(dt);
      if (_goalPauseSec <= 0) {
        _isGoal = false;
        _netParticles.clear();
        _netAnimActive = false;
        _kickoff(teamAStarts: _scoreB > _scoreA);
      }
      return;
    }

    if (_gkSaveAnim) {
      _gkSaveSec -= dt;
      if (_gkSaveSec <= 0) _gkSaveAnim = false;
    }

    _elapsedSec += dt;
    if (_elapsedSec >= _k3MatchDur) {
      _isMatchOver = true;
      return;
    }

    if (_kickCooldownSec > 0) _kickCooldownSec -= dt;
    if (_xDoubleTapSec > 0) _xDoubleTapSec -= dt;

    _updateHuman();
    for (var p in _teamA) {
      if (!p.isHuman) _updateAiTeammate(p);
    }
    _updateHumanMarker();
    for (var p in _teamB) {
      _updateAiOpponent(p);
    }

    _checkPickup();
    _updateBall();
    _updateJumps(dt);
    _checkGoal();
  }

  // ─── AĞLAR PARTİKÜL ─────────────────────────────────────────────────────
  void _spawnNetParticles(bool isRightGoal) {
    _netAnimActive = true;
    for (int i = 0; i < 80; i++) {
      double baseX = isRightGoal ? 0.94 : 0.06;
      double baseY = _k3GoalY1 + _rng.nextDouble() * (_k3GoalY2 - _k3GoalY1);
      double vx = (isRightGoal ? 1 : -1) * (_rng.nextDouble() * 0.008 + 0.002);
      double vy = (_rng.nextDouble() - 0.5) * 0.012;
      Color c = i % 3 == 0
          ? Colors.white.withOpacity(0.9)
          : i % 3 == 1
              ? Colors.white.withOpacity(0.5)
              : (isRightGoal ? Colors.lightBlueAccent : Colors.redAccent)
                  .withOpacity(0.7);
      _netParticles.add(_NetParticle(
        baseX,
        baseY,
        vx,
        vy,
        1.0,
        _rng.nextDouble() * 4 + 1.5,
        c,
      ));
    }
  }

  void _updateNetParticles(double dt) {
    for (var p in _netParticles) {
      p.x += p.vx * dt * 60;
      p.y += p.vy * dt * 60;
      p.vy += 0.0003 * dt * 60; // hafif yerçekimi
      p.life -= dt * 0.6;
    }
    _netParticles.removeWhere((p) => p.life <= 0);
  }

  // ─── İNSAN GİRİŞ ────────────────────────────────────────────────────────
  void _updateHuman() {
    double mx = 0, my = 0;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft)) mx -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowRight)) mx += 1;
    if (_keys.contains(LogicalKeyboardKey.arrowUp)) my -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowDown)) my += 1;

    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    final double dampF =
        (pow(_k3PlayerDamp, dtScale) as double).clamp(0.0, 1.0);

    if (mx != 0 || my != 0) {
      double len = sqrt(mx * mx + my * my);
      mx /= len;
      my /= len;
      _human.vx += mx * _k3PlayerAccel * dtScale;
      _human.vy += my * _k3PlayerAccel * dtScale;
      final double target = atan2(my, mx);
      final double turn = (0.30 * dtScale).clamp(0.0, 1.0);
      _human.facingAngle = _lerpAngle(_human.facingAngle, target, turn);
    } else {
      final double spd = sqrt(_human.vx * _human.vx + _human.vy * _human.vy);
      if (spd > _k3MaxSpeed * 0.15) {
        final double va = atan2(_human.vy, _human.vx);
        _human.facingAngle =
            _lerpAngle(_human.facingAngle, va, (0.09 * dtScale).clamp(0, 1));
      }
    }
    _human.vx = (_human.vx * dampF).clamp(-_k3MaxSpeed, _k3MaxSpeed);
    _human.vy = (_human.vy * dampF).clamp(-_k3MaxSpeed, _k3MaxSpeed);
    _human.x =
        (_human.x + _human.vx * dtScale).clamp(_k3PlayerR, 1 - _k3PlayerR);
    _human.y =
        (_human.y + _human.vy * dtScale).clamp(_k3PlayerR, 1 - _k3PlayerR);

    bool xNow = _keys.contains(LogicalKeyboardKey.keyX);
    bool shNow = _keys.contains(LogicalKeyboardKey.shiftLeft) ||
        _keys.contains(LogicalKeyboardKey.shiftRight);
    bool xFired = xNow && !_xWasHeld && _kickCooldownSec <= 0;
    bool shFired = shNow && !_shiftWasHeld && _kickCooldownSec <= 0;
    _xWasHeld = xNow;
    _shiftWasHeld = shNow;

    bool zNow = _keys.contains(LogicalKeyboardKey.keyZ);
    bool zFired = zNow && !_zWasHeld;
    _zWasHeld = zNow;
    if (zFired && _ball.owner != _human) {
      _humanWantsPass = true;
      for (var p in _teamA) {
        if (!p.isHuman && _ball.owner == p) p._aiPassSec = 0;
      }
    }

    if (_ball.owner == _human) {
      _ball.x =
          _human.x + cos(_human.facingAngle) * (_k3PlayerR + _k3BallR + 0.003);
      _ball.y =
          _human.y + sin(_human.facingAngle) * (_k3PlayerR + _k3BallR + 0.003);
      _ball.z = 0;

      if (xFired) {
        if (_xDoubleTapSec > 0) {
          bool nearWall = _human.y < 0.12 ||
              _human.y > 0.88 ||
              _human.x < 0.12 ||
              _human.x > 0.88;
          if (nearWall) {
            _wallRocket();
          } else {
            _cornerTrick();
          }
          _xDoubleTapSec = 0;
        } else {
          _humanShoot();
          _xDoubleTapSec = 0.26;
          // Şut sırasında zıpla
          _human._isJumping = true;
          _human._jumpPhase = 0;
        }
        _kickCooldownSec = 0.38;
      } else if (shFired) {
        _humanWallPass();
        _kickCooldownSec = 0.38;
      }
    } else if (_ball.owner == null) {
      double bd = sqrt(pow(_human.x - _ball.x, 2) + pow(_human.y - _ball.y, 2));
      if (bd < _k3PickupR * 2.2) {
        if (xFired) {
          _humanShootLoose();
          _xDoubleTapSec = 0.28;
          _kickCooldownSec = 0.38;
        } else if (shFired) {
          _humanWallPassLoose();
          _kickCooldownSec = 0.38;
        }
      }
    } else if (_ball.owner!.isTeamA && !_ball.owner!.isHuman) {
      if (xFired || shFired) {
        _ball.owner!._aiPassSec = 0;
        _kickCooldownSec = 0.25;
      }
    } else if (!_ball.owner!.isTeamA) {
      if (xFired || shFired) {
        double d = sqrt(pow(_human.x - _ball.owner!.x, 2) +
            pow(_human.y - _ball.owner!.y, 2));
        if (d < _k3StealRange) {
          _ball.owner = _human;
          _kickCooldownSec = 0.50;
        }
      }
    }
  }

  void _humanShoot() {
    _ball.owner = null;
    const double goalX = 1.0, goalY = 0.5;
    double toGoalAngle = atan2(goalY - _human.y, goalX - _human.x);
    double diff = _normalizeAngle(_human.facingAngle - toGoalAngle).abs();
    bool isPower = diff < pi / 2.5;
    double power = isPower ? _k3ShootPower * 1.7 : _k3ShootPower;
    double targetY = goalY + (_rng.nextDouble() - 0.5) * 0.16;
    double dx = isPower ? goalX - _human.x : cos(_human.facingAngle);
    double dy = isPower ? targetY - _human.y : sin(_human.facingAngle);
    double len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) len = 0.001;
    _ball.vx = (dx / len) * power;
    _ball.vy = (dy / len) * power;
    // Şuta hafif topspin: z'ye yükseklik ver
    _ball.vz = _rng.nextDouble() * 0.018 + 0.005;
  }

  void _humanShootLoose() {
    _ball.owner = null;
    _ball.vx = cos(_human.facingAngle) * _k3ShootPower * 0.9;
    _ball.vy = sin(_human.facingAngle) * _k3ShootPower * 0.9;
    _ball.vz = 0.008;
  }

  void _wallRocket() {
    _ball.owner = null;
    double goalY =
        _k3GoalY1 + _rng.nextDouble() * (_k3GoalY2 - _k3GoalY1 - 0.06) + 0.03;
    double dx = 1.0 - _human.x, dy = goalY - _human.y;
    double len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) len = 0.001;
    _ball.vx = (dx / len) * _k3ShootPower * 2.8;
    _ball.vy = (dy / len) * _k3ShootPower * 2.8;
    _ball.vz = 0.020;
    _ball.x = _human.x;
    _ball.y = _human.y;
  }

  void _cornerTrick() {
    _ball.owner = null;
    double cx = _human.x < 0.5 ? 0.05 : 0.95;
    double cy = _human.y < 0.5 ? 0.05 : 0.95;
    double dx = cx - _human.x, dy = cy - _human.y;
    double len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) len = 0.001;
    _ball.vx = (dx / len) * _k3PassPower * 3.5;
    _ball.vy = (dy / len) * _k3PassPower * 3.5;
    _ball.vz = 0.012;
  }

  void _humanWallPass() {
    _ball.owner = null;
    double wx = _human.x < 0.5 ? 0.02 : 0.98;
    double dx = wx - _human.x, dy = 0;
    double len = (dx.abs()).clamp(0.001, 1.0);
    _ball.vx = (dx / len) * _k3PassPower * 3.6;
    _ball.vy = _human.vy * 0.8;
    _ball.vz = 0.010;
    _ball.x = _human.x;
    _ball.y = _human.y;
  }

  void _humanWallPassLoose() => _humanWallPass();

  // ─── AI TAKIMCI ──────────────────────────────────────────────────────────
  void _updateAiTeammate(_P3 p) {
    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);

    if (_ball.owner == p) {
      p._aiPassSec -= _dt;
      bool teamHasBall = _teamA.any((t) => _ball.owner == t);
      if (teamHasBall) {
        double fwdX = (p.homeX + 0.15).clamp(0.3, 0.85);
        _aiMoveTo(p, fwdX, p.homeY, dtScale);
      }

      if (p._aiPassSec <= 0) {
        if (_humanWantsPass || p.x > 0.68) {
          _doPassToHuman(p);
        } else {
          _aiShootOrPass(p);
        }
        _humanWantsPass = false;
        p._aiPassSec = 0.18 + _rng.nextDouble() * 0.28;
      }
    } else if (_ball.owner == null) {
      _aiMoveTo(p, _ball.x, _ball.y, dtScale);
    } else if (_ball.owner!.isTeamA) {
      if (_humanWantsPass && _ball.owner != _human) {
        _aiMoveTo(p, _human.x - 0.08, _human.y, dtScale);
      } else {
        double fwdX = (p.homeX + 0.18).clamp(0.3, 0.85);
        _aiMoveTo(p, fwdX, p.homeY, dtScale);
      }
    } else {
      _aiMoveTo(p, p.homeX, p.homeY, dtScale);
    }
  }

  void _doPassToHuman(_P3 passer) {
    _passBallTo(passer, _human);
  }

  void _aiShootOrPass(_P3 p) {
    if (p.x > 0.72) {
      _ball.owner = null;
      double goalY = 0.5 + (_rng.nextDouble() - 0.5) * 0.18;
      double dx = 1.0 - p.x, dy = goalY - p.y;
      double len = sqrt(dx * dx + dy * dy);
      if (len < 0.001) len = 0.001;
      _ball.vx = (dx / len) * _k3ShootPower * 1.4;
      _ball.vy = (dy / len) * _k3ShootPower * 1.4;
      _ball.vz = 0.008;
    } else {
      _passBallTo(p, _human);
    }
  }

  void _passBallTo(_P3 passer, _P3 target) {
    double dist =
        sqrt(pow(target.x - passer.x, 2) + pow(target.y - passer.y, 2));
    double power =
        (_k3PassPower + dist * 0.40).clamp(_k3PassPower, _k3PassPower * 2.5);
    double flightF = dist / power;
    double px = (target.x + target.vx * flightF).clamp(0.05, 0.95);
    double py = (target.y + target.vy * flightF).clamp(0.05, 0.95);
    double dx = px - passer.x, dy = py - passer.y;
    double len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) len = 0.001;
    _ball.owner = null;
    _ball.vx = (dx / len) * power;
    _ball.vy = (dy / len) * power;
    _ball.vz = 0.005 + dist * 0.02;
    _ball.x = passer.x;
    _ball.y = passer.y;
  }

  // ─── AI MARKER (insan için) ───────────────────────────────────────────────
  void _updateHumanMarker() {
    if (_humanMarker == null && _teamB.isNotEmpty) {
      _humanMarker = _teamB.reduce((a, b) {
        double da = sqrt(pow(a.x - _human.x, 2) + pow(a.y - _human.y, 2));
        double db = sqrt(pow(b.x - _human.x, 2) + pow(b.y - _human.y, 2));
        return da < db ? a : b;
      });
    }
  }

  // ─── AI RAKIP ────────────────────────────────────────────────────────────
  void _updateAiOpponent(_P3 p) {
    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    bool teamHasBall = _teamB.any((t) => _ball.owner == t);

    if (_ball.owner == p) {
      p._aiPassSec -= _dt;
      if (p._aiPassSec <= 0) {
        if (p.x < 0.28) {
          _ball.owner = null;
          double goalY = 0.5 + (_rng.nextDouble() - 0.5) * 0.18;
          double dx = 0.0 - p.x, dy = goalY - p.y;
          double len = sqrt(dx * dx + dy * dy);
          if (len < 0.001) len = 0.001;
          _ball.vx = (dx / len) * _k3ShootPower * 1.4;
          _ball.vy = (dy / len) * _k3ShootPower * 1.4;
          _ball.vz = 0.008;
        } else {
          _P3 target = _teamB.firstWhere((t) => t != p && !t.isGk,
              orElse: () => _teamB[0]);
          _passBallTo(p, target);
        }
        p._aiPassSec = 0.20 + _rng.nextDouble() * 0.30;
      } else {
        _aiMoveTo(p, p.x - 0.01, p.y, dtScale);
      }
      _ball.x = p.x + cos(p.facingAngle) * (_k3PlayerR + _k3BallR + 0.002);
      _ball.y = p.y + sin(p.facingAngle) * (_k3PlayerR + _k3BallR + 0.002);
    } else if (teamHasBall) {
      double fwdX = (p.homeX - 0.12).clamp(0.15, 0.70);
      _aiMoveTo(p, fwdX, p.homeY, dtScale);
    } else if (_ball.owner == null) {
      if (!p.isGk)
        _aiMoveTo(p, _ball.x, _ball.y, dtScale);
      else
        _gkLogicFor(p, isTeamA: false);
    } else if (_ball.owner!.isTeamA) {
      if (p.isGk) {
        _gkLogicFor(p, isTeamA: false);
      } else {
        double mx = _ball.owner!.x + _human.x * 0.5 + p.homeX * 0.3;
        double my = _ball.owner!.y * 0.4 + p.homeY * 0.6;
        _aiMoveTo(p, mx / 1.3, my, dtScale);
      }
    } else {
      _aiMoveTo(p, p.homeX, p.homeY, dtScale);
    }
  }

  void _gkLogicFor(_P3 gk, {required bool isTeamA}) {
    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    double gkX = isTeamA ? 0.07 : 0.93;
    double targetY = _ball.y.clamp(_k3GoalY1 + 0.04, _k3GoalY2 - 0.04);

    if (_rng.nextDouble() < 0.04 * _dt * 60) {
      _ball.owner = gk;
      gk._isJumping = true;
      gk._jumpPhase = 0;
      _gkSaveAnim = true;
      _gkSaveSec = 1.2;
    } else {
      _aiMoveTo(gk, gkX, targetY, dtScale);
    }
  }

  void _aiMoveTo(_P3 p, double tx, double ty, double dtScale) {
    double dx = tx - p.x, dy = ty - p.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 0.004) return;
    double nx = dx / dist, ny = dy / dist;
    p.vx += nx * _k3AiAccel * dtScale;
    p.vy += ny * _k3AiAccel * dtScale;
    final double dampF = (pow(_k3PlayerDamp, dtScale) as double).clamp(0, 1);
    p.vx = (p.vx * dampF).clamp(-_k3MaxSpeed, _k3MaxSpeed);
    p.vy = (p.vy * dampF).clamp(-_k3MaxSpeed, _k3MaxSpeed);
    p.x = (p.x + p.vx * dtScale).clamp(_k3PlayerR, 1 - _k3PlayerR);
    p.y = (p.y + p.vy * dtScale).clamp(_k3PlayerR, 1 - _k3PlayerR);
    p.facingAngle = atan2(dy, dx);
  }

  // ─── PICKUP ──────────────────────────────────────────────────────────────
  void _checkPickup() {
    if (_ball.owner != null) return;
    for (var p in [..._teamA, ..._teamB]) {
      if (p == _ball.owner) continue;
      double d = sqrt(pow(p.x - _ball.x, 2) + pow(p.y - _ball.y, 2));
      if (d < _k3PickupR && _ball.z < 0.05) {
        _ball.owner = p;
        _ball.vx = 0;
        _ball.vy = 0;
        _ball.vz = 0;
        break;
      }
    }
  }

  // ─── TOP FİZİĞİ ──────────────────────────────────────────────────────────
  void _updateBall() {
    if (_ball.owner != null) return;
    final dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    final fricF = (pow(_k3BallFric, dtScale) as double).clamp(0, 1);
    _ball.vx *= fricF;
    _ball.vy *= fricF;

    // Yerçekimi
    _ball.vz -= 0.0018 * dtScale;
    _ball.z += _ball.vz * dtScale;
    if (_ball.z <= 0) {
      _ball.z = 0;
      if (_ball.vz < -0.004) {
        _ball.vz = -_ball.vz * 0.52; // sekme
      } else {
        _ball.vz = 0;
      }
    }

    _ball.x = (_ball.x + _ball.vx * dtScale).clamp(0.0, 1.0);
    _ball.y = (_ball.y + _ball.vy * dtScale).clamp(0.0, 1.0);

    // Duvar sekemeleri
    if (_ball.x <= _k3BallR) {
      _ball.vx = _ball.vx.abs() * _k3BallBounce;
      _ball.x = _k3BallR;
    }
    if (_ball.x >= 1 - _k3BallR) {
      _ball.vx = -_ball.vx.abs() * _k3BallBounce;
      _ball.x = 1 - _k3BallR;
    }
    if (_ball.y <= _k3BallR) {
      _ball.vy = _ball.vy.abs() * _k3BallBounce;
      _ball.y = _k3BallR;
    }
    if (_ball.y >= 1 - _k3BallR) {
      _ball.vy = -_ball.vy.abs() * _k3BallBounce;
      _ball.y = 1 - _k3BallR;
    }
  }

  // ─── ZIPLAMA ─────────────────────────────────────────────────────────────
  void _updateJumps(double dt) {
    for (var p in [..._teamA, ..._teamB]) {
      if (p._isJumping) {
        p._jumpPhase += dt * 3.5;
        if (p._jumpPhase >= 1.0) {
          p._isJumping = false;
          p._jumpPhase = 0;
          p._jumpZ = 0;
        } else {
          p._jumpZ = sin(p._jumpPhase * pi) * 0.022;
        }
      }
    }
  }

  // ─── GOL KONTROLÜ ────────────────────────────────────────────────────────
  void _checkGoal() {
    bool inGoalY = _ball.y >= _k3GoalY1 && _ball.y <= _k3GoalY2;
    bool goalA = _ball.x <= 0.01 && inGoalY && _ball.z < 0.12;
    bool goalB = _ball.x >= 0.99 && inGoalY && _ball.z < 0.12;

    if (goalA || goalB) {
      if (goalB) {
        _scoreA++;
        _goalText = '⚽ GOL! ${_human.name}';
        _spawnNetParticles(true); // sağ kaleye gol
      } else {
        _scoreB++;
        _goalText = '😔 RAKİP GOL!';
        _spawnNetParticles(false); // sol kaleye gol
      }
      _ball.owner = null;
      _ball.vx = 0;
      _ball.vy = 0;
      _ball.z = 0;
      _isGoal = true;
      _goalPauseSec = 3.0;
    }
  }

  // ─── YARDIMCILAR ─────────────────────────────────────────────────────────
  double _normalizeAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }

  double _lerpAngle(double from, double to, double t) {
    return from + _normalizeAngle(to - from) * t;
  }

  // ─── CHAT ────────────────────────────────────────────────────────────────
  void _sendChat() {
    final text = _chatInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_Chat3(_human.name, text));
      _chatInput.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScroll.hasClients) {
          _chatScroll.animateTo(_chatScroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut);
        }
      });
    });
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: !_showNick,
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _keys.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _keys.remove(event.logicalKey);
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f11) {
          _isFullscreen = !_isFullscreen;
          windowManager.setFullScreen(_isFullscreen);
        }
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.quoteSingle ||
                event.logicalKey == LogicalKeyboardKey.quote)) {
          setState(() {
            _isChatOpen = !_isChatOpen;
            if (_isChatOpen) {
              _chatInput.clear();
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _chatFocusNode.requestFocus());
            } else {
              _focusNode.requestFocus();
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          // 3D Saha
          Positioned.fill(child: _build3DArena()),
          // HUD
          if (!_isFullscreen) ...[
            _buildHUD(),
            _buildHint(),
            Positioned(
              bottom: 10,
              right: 16,
              child: Text('FPS: ${_fps.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white24, fontSize: 9)),
            ),
          ],
          if (_isGoal) _buildGoalOverlay(),
          if (_isMatchOver) _buildMatchOver(),
          if (!_isFullscreen && _gkSaveAnim) _buildGkLabel(),
          if (!_showNick) _buildChatPanel(),
          if (_showNick) _buildNickOverlay(),
        ]),
      ),
    );
  }

  // ─── 3D ARENA ────────────────────────────────────────────────────────────
  Widget _build3DArena() {
    return LayoutBuilder(builder: (ctx, box) {
      final sz = Size(box.maxWidth, box.maxHeight);
      return CustomPaint(
        size: sz,
        painter: _Arena3DPainter(
          teamA: _teamA,
          teamB: _teamB,
          ball: _ball,
          human: _human,
          netParticles: _netParticles,
          netAnimActive: _netAnimActive,
        ),
      );
    });
  }

  // ─── HUD ─────────────────────────────────────────────────────────────────
  Widget _buildHUD() {
    double rem = (_k3MatchDur - _elapsedSec).clamp(0, _k3MatchDur);
    int mins = rem.toInt() ~/ 60;
    int secs = rem.toInt() % 60;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: widget.onExit,
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white38, size: 17),
          ),
          const SizedBox(width: 12),
          _scoreBox(_scoreA, Colors.lightBlueAccent),
          const SizedBox(width: 10),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text('NATBALL 3D',
                style: GoogleFonts.orbitron(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            Text(
                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style:
                    GoogleFonts.orbitron(color: Colors.white70, fontSize: 17)),
          ]),
          const SizedBox(width: 10),
          _scoreBox(_scoreB, Colors.redAccent),
        ]),
      ),
    );
  }

  Widget _scoreBox(int score, Color color) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        border: Border.all(color: color.withOpacity(0.55), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text('$score',
            style: GoogleFonts.orbitron(
                color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHint() {
    return Positioned(
      bottom: 10,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          '← → ↑ ↓ Hareket  |  X Şut  |  Çift-X: Roket  |  Shift: Duvar Pas  |  Z: Pas İste  |  \" Chat  |  F11: Tam Ekran',
          style: TextStyle(color: Colors.white38, fontSize: 9),
        ),
      ),
    );
  }

  // ─── GOL OVERLAY ────────────────────────────────────────────────────────
  Widget _buildGoalOverlay() {
    bool isOurs = _goalText.contains('GOL!') && !_goalText.contains('RAKİP');
    Color c = isOurs ? Colors.greenAccent : Colors.redAccent;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.8), width: 2.5),
          boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 40)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_goalText,
              style: GoogleFonts.orbitron(
                  color: c, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$_scoreA  –  $_scoreB',
              style: GoogleFonts.orbitron(color: Colors.white54, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildGkLabel() {
    return Positioned(
      top: 62,
      left: 0,
      right: 0,
      child: Center(
        child: Text('🧤 KURTARIŞ!',
            style: GoogleFonts.orbitron(
                color: Colors.amberAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ─── MAÇ SONU ───────────────────────────────────────────────────────────
  Widget _buildMatchOver() {
    bool won = _scoreA > _scoreB;
    bool draw = _scoreA == _scoreB;
    String result = won
        ? '🏆 KAZANDIN!'
        : draw
            ? '🤝 BERABERE'
            : '😔 KAYBETTİN';
    Color col = won
        ? Colors.amber
        : draw
            ? Colors.white70
            : Colors.redAccent;
    return Center(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: col.withOpacity(0.75), width: 2),
          boxShadow: [BoxShadow(color: col.withOpacity(0.25), blurRadius: 40)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(result,
              style: GoogleFonts.orbitron(
                  color: col, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('$_scoreA – $_scoreB',
              style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _overBtn(
              label: 'REMATCH',
              color: Colors.greenAccent,
              onTap: () => setState(() => _initGame())),
          const SizedBox(height: 10),
          _overBtn(
              label: 'ÇIKIŞ', color: Colors.redAccent, onTap: widget.onExit),
        ]),
      ),
    );
  }

  Widget _overBtn(
      {required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(label,
              style: GoogleFonts.orbitron(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 2)),
        ),
      ),
    );
  }

  // ─── CHAT PANELİ ─────────────────────────────────────────────────────────
  Widget _buildChatPanel() {
    return Positioned(
      bottom: 36,
      left: 16,
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_chatMessages.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.60),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: ListView.builder(
                controller: _chatScroll,
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: _chatMessages.length,
                itemBuilder: (_, i) {
                  final msg = _chatMessages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RichText(
                        text: TextSpan(children: [
                      TextSpan(
                          text: '${msg.sender}: ',
                          style: GoogleFonts.orbitron(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: msg.text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                    ])),
                  );
                },
              ),
            ),
          if (_isChatOpen)
            Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.6), width: 1.4),
              ),
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${_human.name}: ',
                      style: GoogleFonts.orbitron(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (e) {
                      if (e is KeyDownEvent &&
                          e.logicalKey == LogicalKeyboardKey.enter) _sendChat();
                      if (e is KeyDownEvent &&
                          (e.logicalKey == LogicalKeyboardKey.quoteSingle ||
                              e.logicalKey == LogicalKeyboardKey.quote)) {
                        setState(() {
                          _isChatOpen = false;
                          _focusNode.requestFocus();
                        });
                      }
                    },
                    child: TextField(
                      controller: _chatInput,
                      focusNode: _chatFocusNode,
                      maxLength: 80,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendChat(),
                    ),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  // ─── NİCKNAME OVERLAY ────────────────────────────────────────────────────
  Widget _buildNickOverlay() {
    final teamANames =
        _teamA.where((p) => !p.isHuman).map((p) => p.name).toList();
    final teamBNames = _teamB.map((p) => p.name).toList();
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.90),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 520,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFF060E1F),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.65), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.22),
                      blurRadius: 50,
                      spreadRadius: 6)
                ],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('NATBALL',
                    style: GoogleFonts.orbitron(
                        color: Colors.greenAccent,
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 2),
                Text('3D',
                    style: GoogleFonts.orbitron(
                        color: Colors.greenAccent,
                        fontSize: 46,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('7 vs 7  •  Perspektif 3D  •  Ağ Animasyonu',
                    style: GoogleFonts.orbitron(
                        color: Colors.white24,
                        fontSize: 9,
                        letterSpacing: 1.5)),
                const Divider(color: Colors.white12, height: 30, thickness: 1),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                  color: Colors.lightBlueAccent,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('Takımın',
                              style: GoogleFonts.orbitron(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.12),
                            border: Border.all(
                                color: Colors.greenAccent.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(children: [
                            const Icon(Icons.person,
                                color: Colors.greenAccent, size: 13),
                            const SizedBox(width: 5),
                            Text('SEN',
                                style: GoogleFonts.orbitron(
                                    color: Colors.greenAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                        ...teamANames.map((n) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(n,
                                  style: GoogleFonts.orbitron(
                                      color: Colors.lightBlueAccent
                                          .withOpacity(0.8),
                                      fontSize: 9)),
                            )),
                      ])),
                  const SizedBox(width: 16),
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('VS',
                          style: GoogleFonts.orbitron(
                              color: Colors.white24,
                              fontSize: 14,
                              fontWeight: FontWeight.bold))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Rakip',
                                  style: GoogleFonts.orbitron(
                                      color: Colors.redAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 6),
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle)),
                            ]),
                        const SizedBox(height: 8),
                        ...teamBNames.map((n) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 3),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(n,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.orbitron(
                                      color: Colors.redAccent.withOpacity(0.8),
                                      fontSize: 9)),
                            )),
                      ])),
                ]),
                const Divider(color: Colors.white12, height: 30, thickness: 1),
                Text('NİCKNAMENİ GİR',
                    style: GoogleFonts.orbitron(
                        color: Colors.white60, fontSize: 13, letterSpacing: 2)),
                const SizedBox(height: 14),
                TextField(
                  controller: _nickCtrl,
                  autofocus: true,
                  maxLength: 16,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'OYUNCU',
                    hintStyle: GoogleFonts.orbitron(
                        color: Colors.white24, fontSize: 18),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.greenAccent.withOpacity(0.8), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                  onSubmitted: (_) => _confirmNick(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmNick,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('OYNA',
                        style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 3)),
                  ),
                ),
                const SizedBox(height: 12),
                Text('F11 → Tam Ekran  •  " → Chat',
                    style: GoogleFonts.orbitron(
                        color: Colors.white24, fontSize: 9, letterSpacing: 1)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmNick() {
    final nick = _nickCtrl.text.trim();
    setState(() {
      _human.name = nick.isEmpty ? 'SEN' : nick;
      _showNick = false;
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }
}

// =============================================================================
// 3D ARENA PAINTER – Perspektifli çizim
// =============================================================================
class _Arena3DPainter extends CustomPainter {
  final List<_P3> teamA;
  final List<_P3> teamB;
  final _Ball3 ball;
  final _P3 human;
  final List<_NetParticle> netParticles;
  final bool netAnimActive;

  const _Arena3DPainter({
    required this.teamA,
    required this.teamB,
    required this.ball,
    required this.human,
    required this.netParticles,
    required this.netAnimActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawField(canvas, size);
    _drawGoals(canvas, size);
    _drawFieldLines(canvas, size);
    _drawNetParticles(canvas, size);
    // Tüm nesne z-sıralı çizilsin: y'ye göre
    List<_P3> allPlayers = [...teamA, ...teamB];
    allPlayers.sort((a, b) => a.y.compareTo(b.y));
    for (var p in allPlayers) {
      _drawShadow(canvas, size, p.x, p.y);
    }
    _drawBallShadow(canvas, size);
    for (var p in allPlayers) {
      _drawPlayer(canvas, size, p);
    }
    _drawBall(canvas, size);
  }

  // Gökyüzü + stadyum arka planı
  void _drawSky(Canvas canvas, Size size) {
    // Tüm arka plan
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF040A14),
    );
    // Gökyüzü gradyanı (üstten horizon'a kadar)
    final horizonY = size.height * 0.18;
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF060F22),
        const Color(0xFF0A1830),
        const Color(0xFF0D2040),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, horizonY),
      Paint()
        ..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, horizonY)),
    );
    // Stadyum tribün çizgisi (horizon)
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..strokeWidth = 1.0,
    );
    // Stadyum flaş ışıkları efekti
    for (int i = 0; i < 5; i++) {
      double lx = size.width * (0.1 + i * 0.2);
      canvas.drawCircle(
        Offset(lx, horizonY * 0.4),
        size.width * 0.012,
        Paint()
          ..color = Colors.white.withOpacity(0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
  }

  // Saha zemini
  void _drawField(Canvas canvas, Size size) {
    // Trapez saha: perspektif
    final path = Path();
    Offset tl = _project(0, 0, size);
    Offset tr = _project(1, 0, size);
    Offset br = _project(1, 1, size);
    Offset bl = _project(0, 1, size);
    path.moveTo(tl.dx, tl.dy);
    path.lineTo(tr.dx, tr.dy);
    path.lineTo(br.dx, br.dy);
    path.lineTo(bl.dx, bl.dy);
    path.close();

    // Zemin ana renk
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFF0C3012),
    );

    // Çim şeritleri yatay (perspektifli): her şerit biraz farklı yeşil
    for (int i = 0; i < 10; i++) {
      double y0 = i / 10.0, y1 = (i + 1) / 10.0;
      final stripe = Path();
      Offset s0 = _project(0, y0, size);
      Offset s1 = _project(1, y0, size);
      Offset s2 = _project(1, y1, size);
      Offset s3 = _project(0, y1, size);
      stripe.moveTo(s0.dx, s0.dy);
      stripe.lineTo(s1.dx, s1.dy);
      stripe.lineTo(s2.dx, s2.dy);
      stripe.lineTo(s3.dx, s3.dy);
      stripe.close();
      Color stripeColor = i % 2 == 0
          ? const Color(0xFF0E3814).withOpacity(0.85)
          : const Color(0xFF0A2A0F).withOpacity(0.85);
      canvas.drawPath(stripe, Paint()..color = stripeColor);
    }
  }

  // Saha çizgileri
  void _drawFieldLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Orta çizgi
    Offset mt = _project(0.5, 0, size);
    Offset mb = _project(0.5, 1, size);
    canvas.drawLine(mt, mb, linePaint);

    // Orta daire (ellipse)
    _drawPerspEllipse(canvas, size, 0.5, 0.5, 0.12, 0.04, linePaint);

    // Ceza sahaları
    _drawPenaltyBox(canvas, size, isLeft: true, linePaint: linePaint);
    _drawPenaltyBox(canvas, size, isLeft: false, linePaint: linePaint);

    // Dış çerçeve
    Path border = Path();
    border.moveTo(_project(0, 0, size).dx, _project(0, 0, size).dy);
    border.lineTo(_project(1, 0, size).dx, _project(1, 0, size).dy);
    border.lineTo(_project(1, 1, size).dx, _project(1, 1, size).dy);
    border.lineTo(_project(0, 1, size).dx, _project(0, 1, size).dy);
    border.close();
    canvas.drawPath(border, linePaint..strokeWidth = 1.8);
  }

  void _drawPerspEllipse(Canvas canvas, Size size, double cx, double cy,
      double rx, double ry, Paint paint) {
    final path = Path();
    const int segments = 32;
    for (int i = 0; i <= segments; i++) {
      double angle = (i / segments) * 2 * pi;
      double fx = cx + cos(angle) * rx;
      double fy = cy + sin(angle) * ry;
      Offset pt = _project(fx, fy, size);
      if (i == 0)
        path.moveTo(pt.dx, pt.dy);
      else
        path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  void _drawPenaltyBox(Canvas canvas, Size size,
      {required bool isLeft, required Paint linePaint}) {
    double x0 = isLeft ? 0.0 : 0.78;
    double x1 = isLeft ? 0.22 : 1.0;
    double y0 = 0.24, y1 = 0.76;
    Path box = Path();
    box.moveTo(_project(x0, y0, size).dx, _project(x0, y0, size).dy);
    box.lineTo(_project(x1, y0, size).dx, _project(x1, y0, size).dy);
    box.lineTo(_project(x1, y1, size).dx, _project(x1, y1, size).dy);
    box.lineTo(_project(x0, y1, size).dx, _project(x0, y1, size).dy);
    box.close();
    canvas.drawPath(
        box,
        linePaint
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);
  }

  // Kaleler
  void _drawGoals(Canvas canvas, Size size) {
    _drawOneGoal(canvas, size, isLeft: true);
    _drawOneGoal(canvas, size, isLeft: false);
  }

  void _drawOneGoal(Canvas canvas, Size size, {required bool isLeft}) {
    // Kale saha koordinatları
    double frontX = isLeft ? 0.0 : 1.0;
    double backX = isLeft ? -0.11 : 1.11; // kale derinliği saha dışına uzanır

    double gy1 = _k3GoalY1;
    double gy2 = _k3GoalY2;

    // 4 ön köşe (saha düzlemi, z=0)
    Offset fTL = _project(frontX, gy1, size); // ön sol üst
    Offset fBL = _project(frontX, gy2, size); // ön sağ üst
    Offset bTL = _project(backX, gy1, size); // arka sol üst
    Offset bBL = _project(backX, gy2, size); // arka sağ üst

    // Kale yüksekliği (perspektife göre)
    double fTH = _projRadius(gy1, 0.050, size); // ön sol yükseklik
    double fBH = _projRadius(gy2, 0.050, size); // ön sağ yükseklik
    double bTH =
        _projRadius(gy1, 0.050, size) * 0.72; // arka sol yükseklik (daha küçük)
    double bBH = _projRadius(gy2, 0.050, size) * 0.72; // arka sağ yükseklik

    // 8 köşe noktası
    Offset ftl = Offset(fTL.dx, fTL.dy - fTH); // ön sol üst üst
    Offset fbl = Offset(fBL.dx, fBL.dy - fBH); // ön sağ üst üst
    Offset btl = Offset(bTL.dx, bTL.dy - bTH); // arka sol üst üst
    Offset bbl = Offset(bBL.dx, bBL.dy - bBH); // arka sağ üst üst

    // Zemin köşeleri
    Offset ftr = fTL; // ön sol alt
    Offset fbr = fBL; // ön sağ alt
    Offset btr = bTL; // arka sol alt
    Offset bbr = bBL; // arka sağ alt

    Color netColor = isLeft
        ? const Color(0xFFFF4444).withOpacity(0.15)
        : const Color(0xFF44BBFF).withOpacity(0.15);
    Color postColor = Colors.white.withOpacity(0.92);
    Color backPostColor = Colors.white.withOpacity(0.55);

    // ── Ağ dolgusu (arka + yan + üst yüzler) ───────────────────────────────
    // Arka yüz
    Path backFace = Path()
      ..moveTo(btl.dx, btl.dy)
      ..lineTo(bbl.dx, bbl.dy)
      ..lineTo(bbr.dx, bbr.dy)
      ..lineTo(btr.dx, btr.dy)
      ..close();
    canvas.drawPath(backFace, Paint()..color = netColor.withOpacity(0.25));

    // Üst yüz
    Path topFace = Path()
      ..moveTo(ftl.dx, ftl.dy)
      ..lineTo(fbl.dx, fbl.dy)
      ..lineTo(bbl.dx, bbl.dy)
      ..lineTo(btl.dx, btl.dy)
      ..close();
    canvas.drawPath(topFace, Paint()..color = netColor.withOpacity(0.18));

    // Sol–sağ yan yüzler
    Path sideFace1 = Path()
      ..moveTo(ftl.dx, ftl.dy)
      ..lineTo(ftr.dx, ftr.dy)
      ..lineTo(btr.dx, btr.dy)
      ..lineTo(btl.dx, btl.dy)
      ..close();
    canvas.drawPath(sideFace1, Paint()..color = netColor.withOpacity(0.12));

    Path sideFace2 = Path()
      ..moveTo(fbl.dx, fbl.dy)
      ..lineTo(fbr.dx, fbr.dy)
      ..lineTo(bbr.dx, bbr.dy)
      ..lineTo(bbl.dx, bbl.dy)
      ..close();
    canvas.drawPath(sideFace2, Paint()..color = netColor.withOpacity(0.12));

    // ── Kale ağı çizgileri ──────────────────────────────────────────────────
    Paint netLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.22)
      ..strokeWidth = 0.65
      ..style = PaintingStyle.stroke;

    // Arka yüz ağ - yatay çizgiler
    for (int j = 0; j <= 5; j++) {
      double t = j / 5.0;
      Offset L = Offset.lerp(btl, btr, t)!;
      Offset R = Offset.lerp(bbl, bbr, t)!;
      canvas.drawLine(L, R, netLinePaint);
    }
    // Arka yüz ağ - dikey çizgiler
    for (int i = 0; i <= 6; i++) {
      double t = i / 6.0;
      Offset T = Offset.lerp(btl, bbl, t)!;
      Offset B = Offset.lerp(btr, bbr, t)!;
      canvas.drawLine(T, B, netLinePaint);
    }

    // Üst yüz ağ - boyuna çizgiler (ön-arka)
    for (int i = 0; i <= 6; i++) {
      double t = i / 6.0;
      Offset F = Offset.lerp(ftl, fbl, t)!;
      Offset B = Offset.lerp(btl, bbl, t)!;
      canvas.drawLine(F, B, netLinePaint);
    }
    // Üst yüz ağ - enine çizgiler (sol-sağ)
    for (int j = 1; j <= 3; j++) {
      double t = j / 4.0;
      Offset L = Offset.lerp(ftl, btl, t)!;
      Offset R = Offset.lerp(fbl, bbl, t)!;
      canvas.drawLine(L, R, netLinePaint);
    }

    // Sol yan ağ
    for (int j = 0; j <= 5; j++) {
      double t = j / 5.0;
      Offset T = Offset.lerp(ftl, ftr, t)!;
      Offset B = Offset.lerp(btl, btr, t)!;
      canvas.drawLine(T, B, netLinePaint);
    }
    // Sağ yan ağ
    for (int j = 0; j <= 5; j++) {
      double t = j / 5.0;
      Offset T = Offset.lerp(fbl, fbr, t)!;
      Offset B = Offset.lerp(bbl, bbr, t)!;
      canvas.drawLine(T, B, netLinePaint);
    }

    // ── Direkler ────────────────────────────────────────────────────────────
    Paint pp = Paint()
      ..color = postColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    Paint bpp = Paint()
      ..color = backPostColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Ön çerçeve (kalın)
    canvas.drawLine(fTL, ftl, pp); // sol direk
    canvas.drawLine(fBL, fbl, pp); // sağ direk
    canvas.drawLine(ftl, fbl, pp); // üst çıta

    // Arka çerçeve (ince)
    canvas.drawLine(bTL, btl, bpp);
    canvas.drawLine(bBL, bbl, bpp);
    canvas.drawLine(btl, bbl, bpp);

    // Yanal bağlantılar
    canvas.drawLine(ftl, btl, bpp); // üst sol
    canvas.drawLine(fbl, bbl, bpp); // üst sağ
    canvas.drawLine(fTL, bTL, bpp); // alt sol
    canvas.drawLine(fBL, bBL, bpp); // alt sağ

    // Ön kale glow
    Color glowColor = isLeft ? Colors.redAccent : Colors.lightBlueAccent;
    canvas.drawLine(
      fTL,
      fBL,
      Paint()
        ..color = glowColor.withOpacity(0.30)
        ..strokeWidth = 8.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
  }

  // Oyuncu gölgesi
  void _drawShadow(Canvas canvas, Size size, double fx, double fy) {
    Offset pos = _project(fx, fy, size);
    double r = _projRadius(fy, _k3PlayerR, size);
    canvas.drawOval(
        Rect.fromCenter(center: pos, width: r * 2.2, height: r * 0.6),
        Paint()..color = Colors.black.withOpacity(0.35));
  }

  // Top gölgesi
  void _drawBallShadow(Canvas canvas, Size size) {
    if (ball.owner != null) return;
    Offset pos = _project(ball.x, ball.y, size);
    double r = _projRadius(ball.y, _k3BallR, size);
    double shadowR = r * (1.0 + ball.z * 4);
    canvas.drawOval(
        Rect.fromCenter(
            center: pos, width: shadowR * 2.4, height: shadowR * 0.7),
        Paint()
          ..color =
              Colors.black.withOpacity((0.4 - ball.z * 2).clamp(0.05, 0.4)));
  }

  // Oyuncu çizimi
  void _drawPlayer(Canvas canvas, Size size, _P3 p) {
    double visualY = p.y - p._jumpZ;
    Offset pos = _project(p.x, visualY, size);
    double r = _projRadius(p.y, _k3PlayerR, size);

    Color bodyColor = p.isTeamA ? Colors.lightBlueAccent : Colors.redAccent;
    if (p.isHuman) bodyColor = Colors.greenAccent;

    // Beden glow
    canvas.drawCircle(
        pos,
        r * 1.4,
        Paint()
          ..color = bodyColor.withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Beden
    canvas.drawCircle(pos, r, Paint()..color = bodyColor.withOpacity(0.88));

    // İç daire
    canvas.drawCircle(
        pos, r * 0.55, Paint()..color = Colors.black.withOpacity(0.35));

    // GK farklı renk
    if (p.isGk) {
      canvas.drawCircle(
          pos, r * 0.38, Paint()..color = Colors.yellowAccent.withOpacity(0.7));
    }

    // Yön çizgisi
    Offset dir =
        Offset(cos(p.facingAngle) * r * 0.78, sin(p.facingAngle) * r * 0.78);
    canvas.drawLine(
        pos,
        pos + dir,
        Paint()
          ..color = Colors.white.withOpacity(0.75)
          ..strokeWidth = 1.5);

    // İsim etiketi
    final tp = TextPainter(
      text: TextSpan(
        text: p.name.length > 6 ? p.name.substring(0, 6) : p.name,
        style: TextStyle(
          color: p.isHuman ? Colors.greenAccent : Colors.white.withOpacity(0.7),
          fontSize: r * 0.9,
          fontWeight: p.isHuman ? FontWeight.bold : FontWeight.normal,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - r - tp.height - 1));

    // Human'ın üstüne ok
    if (p.isHuman) {
      Paint arrowPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.85)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      double ay = pos.dy - r - 6;
      canvas.drawPath(
          Path()
            ..moveTo(pos.dx - 5, ay - 4)
            ..lineTo(pos.dx, ay - 9)
            ..lineTo(pos.dx + 5, ay - 4),
          arrowPaint);
    }
  }

  // Top çizimi
  void _drawBall(Canvas canvas, Size size) {
    double visualY = ball.y - ball.z * 0.3;
    Offset pos = _project(ball.x, visualY, size);
    double r = _projRadius(ball.y, _k3BallR, size) * (1.0 + ball.z * 1.5);

    // Parlama
    canvas.drawCircle(
        pos,
        r * 1.8,
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // Derisi
    canvas.drawCircle(pos, r, Paint()..color = Colors.white);

    // Beşgenler (basit çizgisel)
    canvas.drawCircle(
        pos,
        r * 0.62,
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }

  // Ağ partikülleri
  void _drawNetParticles(Canvas canvas, Size size) {
    for (var p in netParticles) {
      Offset pos = _project(p.x, p.y, size);
      canvas.drawCircle(pos, p.size * _perspScale(p.y),
          Paint()..color = p.color.withOpacity(p.life.clamp(0, 1)));
    }
  }

  @override
  bool shouldRepaint(covariant _Arena3DPainter old) => true;
}
