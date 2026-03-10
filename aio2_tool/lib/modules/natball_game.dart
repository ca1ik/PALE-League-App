import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../data/player_data.dart';

// =============================================================================
// NATBALL – İnsan kontrollü mini futbol oyunu (HaxBall tarzı)
// Takım A (mavi) = oyuncu + 6 yapay-zeka; Sağa hücum eder (gol x=1)
// Takım B (kırmızı) = 7 yapay-zeka;  Sola hücum eder (gol x=0)
// Kontroller: Yön tuşları hareket | X şut | Shift pas
// =============================================================================

// ─── Sabitler ──────────────────────────────────────────────────────────────
const double _kGoalY1 = 0.34;
const double _kGoalY2 = 0.66;
const double _kPlayerR = 0.012; // oyuncu yarıçapı
const double _kBallR = 0.009; // top yarıçapı
const double _kPickupR = 0.030; // sahiplik alma menzili
const double _kStealRange = 0.038; // çalma menzili
const double _kPlayerAccel = 0.0009; // ivme – yavaş ve kontrollü
const double _kPlayerDamp = 0.82; // durma sönümü
const double _kMaxSpeed = 0.005; // maks oyuncu hızı
const double _kBallFric = 0.972; // top sürtünmesi
const double _kBallBounce = 0.65; // duvar sekmesi
const double _kShootPower = 0.025; // şut gücü
const double _kPassPower = 0.015; // pas gücü
const double _kAiAccel = 0.0009;
const double _kMatchDurationSec = 120.0;
const double _kGkRange = 0.15;

// =============================================================================
// OYUNCU VERİSİ
// =============================================================================
class _NbPlayer {
  String name;
  double x, y;
  double vx = 0, vy = 0;
  double facingAngle;
  final bool isHuman;
  final bool isTeamA;
  final double homeX, homeY;
  final bool isGk;
  double _aiPassSec = 0.0;

  _NbPlayer({
    required this.name,
    required this.x,
    required this.y,
    required this.isHuman,
    required this.isTeamA,
    required this.homeX,
    required this.homeY,
    this.isGk = false,
  }) : facingAngle = isTeamA ? 0 : pi;
}

// =============================================================================
// TOP VERİSİ
// =============================================================================
class _NbBall {
  double x = 0.5, y = 0.5;
  double vx = 0, vy = 0;
  _NbPlayer? owner; // topa sahip oyuncu (null = serbest)
}

// =============================================================================
// CHAT MESAJI
// =============================================================================
class _ChatMessage {
  final String sender;
  final String text;
  final bool isSystem;
  _ChatMessage(this.sender, this.text, {this.isSystem = false});
}

// =============================================================================
// ANA WİDGET
// =============================================================================
class NatBallGameView extends StatefulWidget {
  final List<Player> myTeam;
  final List<Player> oppTeam;
  final VoidCallback onExit;

  const NatBallGameView({
    super.key,
    required this.myTeam,
    required this.oppTeam,
    required this.onExit,
  });

  @override
  State<NatBallGameView> createState() => _NatBallGameViewState();
}

// =============================================================================
// OYUN DURUMU
// =============================================================================
class _NatBallGameViewState extends State<NatBallGameView>
    with TickerProviderStateMixin {
  final _rng = Random();
  Ticker? _ticker;
  Duration _lastFrame = Duration.zero;

  late List<_NbPlayer> _teamA;
  late List<_NbPlayer> _teamB;
  late _NbPlayer _human;
  final _NbBall _ball = _NbBall();

  final Set<LogicalKeyboardKey> _keys = {};
  final FocusNode _focusNode = FocusNode();

  int _scoreA = 0, _scoreB = 0;
  double _elapsedSec = 0;
  bool _isGoal = false;
  String _goalText = '';
  double _goalPauseSec = 0;
  bool _isMatchOver = false;

  // İnsan kontrol – saniye cinsinden (FPS bağımsız)
  double _kickCooldownSec = 0.0;
  double _xDoubleTapSec = 0.0;
  double _runToBallSec = 0.0;
  bool _xWasHeld = false;
  bool _shiftWasHeld = false;
  bool _zWasHeld = false;
  bool _humanWantsPass = false;

  // GK animasyonu
  bool _gkSaveAnim = false;
  double _gkSaveSec = 0.0;

  // FPS / dt takibi
  double _fps = 0;
  double _dt = 1 / 60.0;

  // Dinamik markajcı
  _NbPlayer? _humanMarker;

  // Nickname
  bool _showNicknameInput = true;
  bool _isFullscreen = false;
  final TextEditingController _nickCtrl = TextEditingController();

  // Chat
  bool _isChatOpen = false;
  final TextEditingController _chatInputCtrl = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final List<_ChatMessage> _chatMessages = [];
  final ScrollController _chatScrollCtrl = ScrollController();

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
    _chatInputCtrl.dispose();
    _chatScrollCtrl.dispose();
    super.dispose();
  }

  // ─── OYUNU BAŞLAT ───────────────────────────────────────────────────────────
  void _initGame() {
    _scoreA = 0;
    _scoreB = 0;
    _elapsedSec = 0;
    _isGoal = false;
    _isMatchOver = false;
    _kickCooldownSec = 0;
    _xDoubleTapSec = 0;
    _runToBallSec = 0;
    _xWasHeld = false;
    _shiftWasHeld = false;
    _zWasHeld = false;
    _humanWantsPass = false;
    _gkSaveAnim = false;
    _gkSaveSec = 0;
    _keys.clear();
    _buildPlayers();
    _kickoff(teamAStarts: true);
  }

  void _buildPlayers() {
    // ── Takım A: Oyuncu + 6 Yapay-zeka ───────────────────────────────────────
    //  İnsan = Forvet (indeks 6)
    //  [GK, DEF-L, DEF-R, MID, WING-L, WING-R, FWD=insan]
    final baseXA = [0.06, 0.19, 0.19, 0.40, 0.55, 0.55, 0.74];
    final baseYA = [0.50, 0.27, 0.73, 0.50, 0.17, 0.83, 0.50];
    final namesA = _safeNames(widget.myTeam, 7);
    _teamA = List.generate(7, (i) {
      return _NbPlayer(
        name: namesA[i],
        x: baseXA[i],
        y: baseYA[i],
        isHuman: i == 6,
        isTeamA: true,
        homeX: baseXA[i],
        homeY: baseYA[i],
        isGk: i == 0,
      );
    });
    _human = _teamA[6];

    // ── Takım B: 7 Yapay-zeka ─────────────────────────────────────────────────
    final baseXB = [0.94, 0.81, 0.81, 0.60, 0.45, 0.45, 0.26];
    final baseYB = [0.50, 0.27, 0.73, 0.50, 0.17, 0.83, 0.50];
    final namesB = _safeNames(widget.oppTeam, 7);
    _teamB = List.generate(7, (i) {
      return _NbPlayer(
        name: namesB[i],
        x: baseXB[i],
        y: baseYB[i],
        isHuman: false,
        isTeamA: false,
        homeX: baseXB[i],
        homeY: baseYB[i],
        isGk: i == 0,
      );
    });
  }

  List<String> _safeNames(List<Player> players, int count) {
    final out = <String>[];
    for (var p in players) {
      out.add(p.name);
    }
    while (out.length < count) {
      out.add('Player${out.length + 1}');
    }
    return out.take(count).toList();
  }

  void _kickoff({required bool teamAStarts}) {
    for (var p in [..._teamA, ..._teamB]) {
      p.x = p.isTeamA ? p.homeX.clamp(0.05, 0.48) : p.homeX.clamp(0.52, 0.95);
      p.y = p.homeY;
      p.vx = 0;
      p.vy = 0;
      p.facingAngle = p.isTeamA ? 0 : pi;
      p._aiPassSec = 0.10 + _rng.nextDouble() * 0.25;
    }
    _ball.x = 0.5;
    _ball.y = 0.5;
    _ball.vx = 0;
    _ball.vy = 0;
    _ball.owner = teamAStarts ? _human : _teamB[3];
    _kickCooldownSec = 0;
    _runToBallSec = 0;
  }

  // ─── OYUN DÖNGÜSÜ – Sınırsız FPS ──────────────────────────────────────────
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
    if (_showNicknameInput) return;
    if (_isChatOpen) return; // chat açıkken oyun durur
    if (_isMatchOver) return;

    if (_isGoal) {
      _goalPauseSec -= dt;
      if (_goalPauseSec <= 0) {
        _isGoal = false;
        _kickoff(teamAStarts: _scoreB > _scoreA); // gol yiyen devam eder
      }
      return;
    }

    if (_gkSaveAnim) {
      _gkSaveSec -= dt;
      if (_gkSaveSec <= 0) _gkSaveAnim = false;
    }

    _elapsedSec += dt;
    if (_elapsedSec >= _kMatchDurationSec) {
      _isMatchOver = true;
      return;
    }

    if (_kickCooldownSec > 0) _kickCooldownSec -= dt;
    if (_xDoubleTapSec > 0) _xDoubleTapSec -= dt;
    if (_runToBallSec > 0) _runToBallSec -= dt;

    _updateHuman();

    for (var p in _teamA) {
      if (p.isHuman) continue;
      _updateAiTeammate(p);
    }

    _updateHumanMarker();
    for (var p in _teamB) {
      _updateAiOpponent(p);
    }

    _checkPickup();
    _updateBall();
    _checkGoal();
  }

  // ─── İNSAN GİRİŞİ ──────────────────────────────────────────────────────────
  void _updateHuman() {
    double mx = 0, my = 0;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft)) mx -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowRight)) mx += 1;
    if (_keys.contains(LogicalKeyboardKey.arrowUp)) my -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowDown)) my += 1;

    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    // Exponential damping = truly FPS-independent
    final double dampF = (pow(_kPlayerDamp, dtScale) as double).clamp(0.0, 1.0);
    if (mx != 0 || my != 0) {
      double len = sqrt(mx * mx + my * my);
      mx /= len;
      my /= len;
      _human.vx += mx * _kPlayerAccel * dtScale;
      _human.vy += my * _kPlayerAccel * dtScale;
      // Bakış açısı hedefe yumuşak dönüş – 8 yön yerine sonsuz ara açıdan geçer
      final double targetAngle = atan2(my, mx);
      final double turnRate = (0.32 * dtScale).clamp(0.0, 1.0);
      _human.facingAngle =
          _lerpAngle(_human.facingAngle, targetAngle, turnRate);
    } else {
      // Tuş bırakıldıktan sonra momentum sırasında hız vektörüne hizalan
      final double spd = sqrt(_human.vx * _human.vx + _human.vy * _human.vy);
      if (spd > _kMaxSpeed * 0.18) {
        final double velAngle = atan2(_human.vy, _human.vx);
        final double coastTurn = (0.10 * dtScale).clamp(0.0, 1.0);
        _human.facingAngle =
            _lerpAngle(_human.facingAngle, velAngle, coastTurn);
      }
    }
    _human.vx = (_human.vx * dampF).clamp(-_kMaxSpeed, _kMaxSpeed);
    _human.vy = (_human.vy * dampF).clamp(-_kMaxSpeed, _kMaxSpeed);
    _human.x =
        (_human.x + _human.vx * dtScale).clamp(_kPlayerR, 1.0 - _kPlayerR);
    _human.y =
        (_human.y + _human.vy * dtScale).clamp(_kPlayerR, 1.0 - _kPlayerR);

    bool xNow = _keys.contains(LogicalKeyboardKey.keyX);
    bool shNow = _keys.contains(LogicalKeyboardKey.shiftLeft) ||
        _keys.contains(LogicalKeyboardKey.shiftRight);
    bool xFired = xNow && !_xWasHeld && _kickCooldownSec <= 0;
    bool shFired = shNow && !_shiftWasHeld && _kickCooldownSec <= 0;
    _xWasHeld = xNow;
    _shiftWasHeld = shNow;

    // ── Z tuşu: anında pas iste ───────────────────────────────────────────────
    bool zNow = _keys.contains(LogicalKeyboardKey.keyZ);
    bool zFired = zNow && !_zWasHeld;
    _zWasHeld = zNow;
    if (zFired) {
      if (_ball.owner != _human) {
        _humanWantsPass = true;
        for (var p in _teamA) {
          if (!p.isHuman && _ball.owner == p) {
            p._aiPassSec = 0; // hemen pas at
          }
        }
      }
    }

    // ── İnsan topa sahip ─────────────────────────────────────────────────────
    if (_ball.owner == _human) {
      // Top insanın önünde gezinir
      _ball.x =
          _human.x + cos(_human.facingAngle) * (_kPlayerR + _kBallR + 0.003);
      _ball.y =
          _human.y + sin(_human.facingAngle) * (_kPlayerR + _kBallR + 0.003);

      if (xFired) {
        if (_xDoubleTapSec > 0) {
          // Çift-X: duvara yakınsa roket şut, değilse köşe numarası
          bool nearWall = _human.y < 0.12 ||
              _human.y > 0.88 ||
              _human.x < 0.12 ||
              _human.x > 0.88;
          if (nearWall) {
            _humanWallRocket();
          } else {
            _humanCornerTrick();
          }
          _xDoubleTapSec = 0;
        } else {
          _humanShoot();
          _xDoubleTapSec = 0.28;
        }
        _kickCooldownSec = 0.40;
      } else if (shFired) {
        _humanWallPass();
        _kickCooldownSec = 0.40;
      }
    }
    // ── Top serbest → yakınsa vur ─────────────────────────────────────────────
    else if (_ball.owner == null) {
      double bd = sqrt(pow(_human.x - _ball.x, 2) + pow(_human.y - _ball.y, 2));
      if (bd < _kPickupR * 2.2) {
        if (xFired) {
          if (_xDoubleTapSec > 0) {
            _humanCornerTrick();
            _xDoubleTapSec = 0;
          } else {
            _humanShootLoose();
            _xDoubleTapSec = 0.30;
          }
          _kickCooldownSec = 0.40;
        } else if (shFired) {
          _humanWallPassLoose();
          _kickCooldownSec = 0.40;
        }
      }
    }
    // ── Takım arkadaşı sahipse → pas iste ────────────────────────────────────
    else if (_ball.owner!.isTeamA && !_ball.owner!.isHuman) {
      if (xFired || shFired) {
        _ball.owner!._aiPassSec = 0;
        _kickCooldownSec = 0.28;
      }
    }
    // ── Rakip sahipse → çal ───────────────────────────────────────────────────
    else if (!_ball.owner!.isTeamA) {
      if (xFired || shFired) {
        double d = sqrt(pow(_human.x - _ball.owner!.x, 2) +
            pow(_human.y - _ball.owner!.y, 2));
        if (d < _kStealRange) {
          _ball.owner = _human;
          _kickCooldownSec = 0.53;
        }
      }
    }
  }

  void _humanShoot() {
    _ball.owner = null;
    const double goalX = 1.0, goalY = 0.5;
    double toGoalAngle = atan2(goalY - _human.y, goalX - _human.x);
    double diff = (_normalizeAngle(_human.facingAngle - toGoalAngle)).abs();
    bool isPower = diff < (pi / 2.5);
    double power = isPower ? _kShootPower * 1.65 : _kShootPower;
    double targetY = goalY + (_rng.nextDouble() - 0.5) * 0.18;
    double dx = isPower ? goalX - _human.x : cos(_human.facingAngle);
    double dy = isPower ? targetY - _human.y : sin(_human.facingAngle);
    double len = sqrt(dx * dx + dy * dy);
    if (len == 0) len = 0.001;
    _ball.vx = (dx / len) * power;
    _ball.vy = (dy / len) * power;
    _ball.x = _human.x;
    _ball.y = _human.y;
  }

  void _humanShootLoose() {
    _ball.vx = cos(_human.facingAngle) * _kShootPower * 0.9;
    _ball.vy = sin(_human.facingAngle) * _kShootPower * 0.9;
  }

  void _humanWallPass() {
    _ball.owner = null;
    double dTop = _human.y, dBot = 1.0 - _human.y;
    double dLeft = _human.x, dRight = 1.0 - _human.x;
    double minD = [dTop, dBot, dLeft, dRight].reduce(min);
    double mirrorX, mirrorY;
    if (minD == dTop) {
      mirrorX = _human.x;
      mirrorY = -_human.y;
    } else if (minD == dBot) {
      mirrorX = _human.x;
      mirrorY = 2.0 - _human.y;
    } else if (minD == dLeft) {
      mirrorX = -_human.x;
      mirrorY = _human.y;
    } else {
      mirrorX = 2.0 - _human.x;
      mirrorY = _human.y;
    }
    double dx = mirrorX - _human.x;
    double dy = mirrorY - _human.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;
    _ball.vx = (dx / dist) * _kPassPower * 3.8;
    _ball.vy = (dy / dist) * _kPassPower * 3.8;
    _ball.x = _human.x;
    _ball.y = _human.y;
    _runToBallSec = 1.2;
  }

  void _humanWallPassLoose() {
    double dTop = _ball.y, dBot = 1.0 - _ball.y;
    double dLeft = _ball.x, dRight = 1.0 - _ball.x;
    double minD = [dTop, dBot, dLeft, dRight].reduce(min);
    double mirrorX, mirrorY;
    if (minD == dTop) {
      mirrorX = _ball.x;
      mirrorY = -_ball.y;
    } else if (minD == dBot) {
      mirrorX = _ball.x;
      mirrorY = 2.0 - _ball.y;
    } else if (minD == dLeft) {
      mirrorX = -_ball.x;
      mirrorY = _ball.y;
    } else {
      mirrorX = 2.0 - _ball.x;
      mirrorY = _ball.y;
    }
    double dx = mirrorX - _ball.x;
    double dy = mirrorY - _ball.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;
    _ball.vx = (dx / dist) * _kPassPower * 3.8;
    _ball.vy = (dy / dist) * _kPassPower * 3.8;
    _runToBallSec = 1.2;
  }

  void _humanCornerTrick() {
    _ball.owner = null;
    const corners = [
      [0.01, 0.01],
      [0.99, 0.01],
      [0.01, 0.99],
      [0.99, 0.99]
    ];
    double bestD = double.infinity;
    double cx = 0.01, cy = 0.01;
    for (var c in corners) {
      double d = sqrt(pow(_human.x - c[0], 2) + pow(_human.y - c[1], 2));
      if (d < bestD) {
        bestD = d;
        cx = c[0];
        cy = c[1];
      }
    }
    double dx = cx - _human.x, dy = cy - _human.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;
    // Köşeye güçlü şut – sekerken yeterli hız kalacak şekilde
    _ball.vx = (dx / dist) * _kShootPower * 3.4;
    _ball.vy = (dy / dist) * _kShootPower * 3.4;
    _ball.x = _human.x;
    _ball.y = _human.y;
    _runToBallSec = 2.0; // oyuncu dönen topa koşsun
  }

  // Duvara yakın çift-X → kaleye roket şut
  void _humanWallRocket() {
    _ball.owner = null;
    const double goalX = 1.0;
    // Kale aralığında rastgele nokta hedef
    double goalY = _kGoalY1 +
        (_rng.nextDouble() * (_kGoalY2 - _kGoalY1) * 0.8) +
        (_kGoalY2 - _kGoalY1) * 0.1;
    double dx = goalX - _human.x;
    double dy = goalY - _human.y;
    double len = sqrt(dx * dx + dy * dy);
    if (len == 0) len = 0.001;
    _ball.vx = (dx / len) * _kShootPower * 2.7; // roket güç
    _ball.vy = (dy / len) * _kShootPower * 2.7;
    _ball.x = _human.x;
    _ball.y = _human.y;
  }

  // ─── TAKIM A YAPAY-ZEKASI ──────────────────────────────────────────────────
  void _updateAiTeammate(_NbPlayer p) {
    if (p.isGk) {
      _updateTeamAGk(p);
      return;
    }

    double tx, ty;

    if (_ball.owner == p) {
      // Rakip kaleye yakınsa doğrudan şut çek
      if (p.x > 0.72) {
        _aiTeamAShoot(p);
        return;
      }
      _doTeamPassToHuman(p);
      return;
    }

    if (_runToBallSec > 0) {
      tx = _ball.x;
      ty = _ball.y;
    } else if (_ball.owner == null) {
      double humanDist =
          sqrt(pow(_human.x - _ball.x, 2) + pow(_human.y - _ball.y, 2));
      if (humanDist > 0.20) {
        tx = _ball.x;
        ty = _ball.y;
      } else {
        tx = p.homeX * 0.6 + _ball.x * 0.4;
        ty = p.homeY * 0.6 + _ball.y * 0.4;
      }
    } else if (_ball.owner!.isTeamA) {
      // İleri pozisyon al – paslık yarat
      double forwardX =
          (_ball.x + 0.12 + (p.homeX - 0.5) * 0.18).clamp(0.10, 0.90);
      tx = forwardX;
      ty = p.homeY;
    } else {
      tx = p.homeX * 0.85;
      ty = p.homeY;
    }
    _aiMoveTo(p, tx, ty, _kAiAccel);
  }

  void _updateTeamAGk(_NbPlayer gk) {
    double tx = gk.homeX;
    double ty = _ball.y.clamp(gk.homeY - _kGkRange, gk.homeY + _kGkRange);
    _aiMoveTo(gk, tx, ty, _kAiAccel * 1.1);
    if (_ball.owner == null) {
      double d = sqrt(pow(gk.x - _ball.x, 2) + pow(gk.y - _ball.y, 2));
      if (d < _kPickupR * 1.5) {
        _ball.owner = gk;
        _gkSaveAnim = true;
        _gkSaveSec = 0.67;
      }
    }
    if (_ball.owner == gk && _rng.nextDouble() < 0.08 * _dt * 60) {
      _doTeamPassToHuman(gk);
    }
  }

  void _doTeamPassToHuman(_NbPlayer passer) {
    passer._aiPassSec -= _dt;
    if (passer._aiPassSec > 0 && !_humanWantsPass) {
      // Topa sahipken ileri doğru süre
      double tx = (passer.x + 0.07).clamp(0.05, 0.90);
      _aiMoveTo(passer, tx, passer.homeY + (_rng.nextDouble() - 0.5) * 0.04,
          _kAiAccel * 0.55);
      return;
    }

    // Pas zamanı – kime atacağına karar ver
    passer._aiPassSec = 0.17 + _rng.nextDouble() * 0.30;

    // İnsan pas istiyorsa veya yakınsa → ona at
    double distToHuman =
        sqrt(pow(_human.x - passer.x, 2) + pow(_human.y - passer.y, 2));
    bool passToHuman =
        _humanWantsPass || distToHuman < 0.28 || _rng.nextInt(100) < 55;

    if (passToHuman) {
      _humanWantsPass = false;
      _passBallTo(passer, _human);
      return;
    }

    // En iyi konumdaki takım arkadaşını bul (ileri + açık)
    _NbPlayer? best;
    double bestScore = double.infinity;
    for (var t in _teamA) {
      if (t == passer || t.isGk || t.isHuman) continue;
      double d = sqrt(pow(t.x - passer.x, 2) + pow(t.y - passer.y, 2));
      if (d < 0.08) continue; // çok yakın, gerek yok
      double score = d - t.x * 0.6; // ileri oyuncular tercihli
      if (score < bestScore) {
        bestScore = score;
        best = t;
      }
    }

    if (best != null) {
      _passBallTo(passer, best);
    } else {
      _humanWantsPass = false;
      _passBallTo(passer, _human);
    }
  }

  void _passBallTo(_NbPlayer passer, _NbPlayer target) {
    _ball.owner = null;
    double dist =
        sqrt(pow(target.x - passer.x, 2) + pow(target.y - passer.y, 2));
    double power =
        (_kPassPower + dist * 0.45).clamp(_kPassPower, _kPassPower * 2.4);
    // Öncül pas: top geldikten sonra hedefin olacağı yeri hesapla
    double flightFactor = dist / power; // ≈ kare sayısı
    double predictX = (target.x + target.vx * flightFactor).clamp(0.05, 0.95);
    double predictY = (target.y + target.vy * flightFactor).clamp(0.05, 0.95);
    double dx = predictX - passer.x + (_rng.nextDouble() - 0.5) * 0.035;
    double dy = predictY - passer.y + (_rng.nextDouble() - 0.5) * 0.035;
    double d = sqrt(dx * dx + dy * dy);
    if (d == 0) d = 0.001;
    _ball.vx = (dx / d) * power;
    _ball.vy = (dy / d) * power;
    _ball.x = passer.x;
    _ball.y = passer.y;
  }

  void _aiTeamAShoot(_NbPlayer p) {
    _ball.owner = null;
    double dx = 1.0 - p.x + (_rng.nextDouble() - 0.5) * 0.12;
    double dy = 0.5 - p.y + (_rng.nextDouble() - 0.5) * 0.14;
    double len = sqrt(dx * dx + dy * dy);
    if (len == 0) len = 0.001;
    _ball.vx = (dx / len) * _kShootPower * 1.45;
    _ball.vy = (dy / len) * _kShootPower * 1.45;
    _ball.x = p.x;
    _ball.y = p.y;
  }

  // ─── TAKIM B YAPAY-ZEKASI ──────────────────────────────────────────────────
  void _updateAiOpponent(_NbPlayer p) {
    if (p.isGk) {
      _updateTeamBGk(p);
      return;
    }

    double tx, ty;

    if (_ball.owner == p) {
      bool canShoot = p.x < 0.30;
      p._aiPassSec -= _dt;
      if (canShoot && p._aiPassSec <= 0) {
        _aiShoot(p);
        p._aiPassSec = 0.47 + _rng.nextDouble() * 0.37;
      } else if (!canShoot && p._aiPassSec <= 0) {
        _aiTeamBPass(p);
        p._aiPassSec = 0.33 + _rng.nextDouble() * 0.30;
      } else {
        tx = 0.10 + _rng.nextDouble() * 0.04;
        ty = 0.38 + _rng.nextDouble() * 0.24;
        _aiMoveTo(p, tx, ty, _kAiAccel);
      }
      return;
    }

    if (p == _humanMarker) {
      const double gx = 0.03, gy = 0.50;
      double ddx = gx - _human.x, ddy = gy - _human.y;
      double ddist = sqrt(ddx * ddx + ddy * ddy);
      if (ddist < 0.001) ddist = 0.001;
      tx = _human.x + (ddx / ddist) * 0.12;
      ty = _human.y + (ddy / ddist) * 0.12;
      _aiMoveTo(p, tx, ty, _kAiAccel * 1.05);
      return;
    }

    final int bIdx = _teamB.indexOf(p);
    if (bIdx > 0 && bIdx < _teamA.length) {
      tx = _teamA[bIdx].x - 0.06;
      ty = _teamA[bIdx].y;
      _aiMoveTo(p, tx, ty, _kAiAccel * 0.95);
      return;
    }

    _aiMoveTo(p, p.homeX + 0.04, p.homeY, _kAiAccel);
  }

  void _updateTeamBGk(_NbPlayer gk) {
    double tx = gk.homeX;
    double ty = _ball.y.clamp(gk.homeY - _kGkRange, gk.homeY + _kGkRange);
    _aiMoveTo(gk, tx, ty, _kAiAccel * 1.05);
    if (_ball.owner == null) {
      double d = sqrt(pow(gk.x - _ball.x, 2) + pow(gk.y - _ball.y, 2));
      if (d < _kPickupR * 1.4) {
        _ball.owner = gk;
        _gkSaveAnim = true;
        _gkSaveSec = 0.67;
      }
    }
    if (_ball.owner == gk && _rng.nextDouble() < 0.07 * _dt * 60) {
      _aiClearBall(gk);
    }
  }

  void _aiShoot(_NbPlayer p) {
    _ball.owner = null;
    double dx = 0.0 - p.x + (_rng.nextDouble() - 0.5) * 0.14;
    double dy = 0.5 - p.y + (_rng.nextDouble() - 0.5) * 0.14;
    double len = sqrt(dx * dx + dy * dy);
    if (len == 0) len = 0.001;
    _ball.vx = (dx / len) * _kShootPower * 1.25;
    _ball.vy = (dy / len) * _kShootPower * 1.25;
    _ball.x = p.x;
    _ball.y = p.y;
  }

  void _aiTeamBPass(_NbPlayer passer) {
    _NbPlayer? target;
    double bestScore = double.infinity;
    for (var t in _teamB) {
      if (t == passer || t.isGk) continue;
      double dist = sqrt(pow(t.x - passer.x, 2) + pow(t.y - passer.y, 2));
      double score = dist + t.x * 0.35;
      if (score < bestScore) {
        bestScore = score;
        target = t;
      }
    }
    if (target == null) {
      _aiShoot(passer);
      return;
    }
    _ball.owner = null;
    double dx = target.x - passer.x + (_rng.nextDouble() - 0.5) * 0.05;
    double dy = target.y - passer.y + (_rng.nextDouble() - 0.5) * 0.05;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;
    double power =
        (_kPassPower + dist * 0.38).clamp(_kPassPower, _kPassPower * 2.2);
    _ball.vx = (dx / dist) * power;
    _ball.vy = (dy / dist) * power;
    _ball.x = passer.x;
    _ball.y = passer.y;
  }

  void _aiClearBall(_NbPlayer gk) {
    _ball.owner = null;
    _ball.vx = _kPassPower * 1.5 * (gk.isTeamA ? 1 : -1);
    _ball.vy = (_rng.nextDouble() - 0.5) * _kPassPower;
    _ball.x = gk.x;
    _ball.y = gk.y;
  }

  // ─── YARDIMCILAR ────────────────────────────────────────────────────────────
  void _updateHumanMarker() {
    _humanMarker = null;
    double nearestD = double.infinity;
    for (var p in _teamB) {
      if (p.isGk) continue;
      double d = sqrt(pow(p.x - _human.x, 2) + pow(p.y - _human.y, 2));
      if (d < nearestD) {
        nearestD = d;
        _humanMarker = p;
      }
    }
  }

  void _aiMoveTo(_NbPlayer p, double tx, double ty, double accel) {
    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    // Exponential damping = truly FPS-independent
    final double dampF = (pow(_kPlayerDamp, dtScale) as double).clamp(0.0, 1.0);
    double dx = tx - p.x, dy = ty - p.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 0.005) {
      p.vx *= dampF;
      p.vy *= dampF;
    } else {
      p.vx += (dx / dist) * accel * dtScale;
      p.vy += (dy / dist) * accel * dtScale;
      p.facingAngle = atan2(dy, dx);
    }
    p.vx = (p.vx * dampF).clamp(-_kMaxSpeed, _kMaxSpeed);
    p.vy = (p.vy * dampF).clamp(-_kMaxSpeed, _kMaxSpeed);
    p.x = (p.x + p.vx * dtScale).clamp(_kPlayerR, 1.0 - _kPlayerR);
    p.y = (p.y + p.vy * dtScale).clamp(_kPlayerR, 1.0 - _kPlayerR);
  }

  // ─── SAHİPLİK KONTROLÜ ──────────────────────────────────────────────────────
  void _checkPickup() {
    if (_ball.owner != null) return;
    double ballSpd = sqrt(_ball.vx * _ball.vx + _ball.vy * _ball.vy);
    // Köşe numarası veya duvar pası sonrası dönen topa koşarken daha yüksek hızda yakala
    double speedLimit = _runToBallSec > 0 ? 0.050 : 0.012;
    if (ballSpd > speedLimit) return;
    _NbPlayer? closest;
    double closestDist = double.infinity;
    for (var p in [..._teamA, ..._teamB]) {
      double d = sqrt(pow(p.x - _ball.x, 2) + pow(p.y - _ball.y, 2));
      if (d < closestDist) {
        closestDist = d;
        closest = p;
      }
    }
    if (closest != null && closestDist < _kPickupR) {
      _ball.owner = closest;
      if (!closest.isHuman) {
        closest._aiPassSec = 0.10 + _rng.nextDouble() * 0.23;
      }
    }
  }

  // ─── TOP FİZİĞİ ─────────────────────────────────────────────────────────────
  void _updateBall() {
    if (_ball.owner != null) return; // sahip taşıyor

    final double dtScale = (_dt * 60.0).clamp(0.0, 2.0);
    // Exponential friction = truly FPS-independent
    final double fricF = (pow(_kBallFric, dtScale) as double).clamp(0.0, 1.0);
    _ball.x += _ball.vx * dtScale;
    _ball.y += _ball.vy * dtScale;
    _ball.vx *= fricF;
    _ball.vy *= fricF;

    if (_ball.y < _kBallR) {
      _ball.y = _kBallR;
      _ball.vy = _ball.vy.abs() * _kBallBounce;
    } else if (_ball.y > 1.0 - _kBallR) {
      _ball.y = 1.0 - _kBallR;
      _ball.vy = -_ball.vy.abs() * _kBallBounce;
    }
    if (_ball.x < _kBallR) {
      if (!(_ball.y >= _kGoalY1 && _ball.y <= _kGoalY2)) {
        _ball.x = _kBallR;
        _ball.vx = _ball.vx.abs() * _kBallBounce;
      }
    }
    if (_ball.x > 1.0 - _kBallR) {
      if (!(_ball.y >= _kGoalY1 && _ball.y <= _kGoalY2)) {
        _ball.x = 1.0 - _kBallR;
        _ball.vx = -_ball.vx.abs() * _kBallBounce;
      }
    }
  }

  // ─── GOL KONTROLÜ ───────────────────────────────────────────────────────────
  void _checkGoal() {
    if (_ball.owner != null) return; // sahipte top kale üzerinden geçemez
    if (_ball.x > 1.0 && _ball.y >= _kGoalY1 && _ball.y <= _kGoalY2) {
      _scoreA++;
      _goalText = '⚽ GOL! Sen Attın!';
      _triggerGoal();
      return;
    }
    if (_ball.x < 0.0 && _ball.y >= _kGoalY1 && _ball.y <= _kGoalY2) {
      _scoreB++;
      _goalText = '😔 Gol Yedik!';
      _triggerGoal();
    }
  }

  void _triggerGoal() {
    _isGoal = true;
    _goalPauseSec = 2.2;
    _ball.owner = null;
    _ball.vx = 0;
    _ball.vy = 0;
    _ball.x = 0.5;
    _ball.y = 0.5;
  }

  double _normalizeAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }

  /// Açıyı (radyan) t oranlı lerp ile hedef açıya döndürür.
  /// Kısa yolu seçer (–π … π arası döner).
  double _lerpAngle(double from, double to, double t) {
    final double diff = _normalizeAngle(to - from);
    return from + diff * t;
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: !_showNicknameInput,
      onKeyEvent: (event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          _keys.add(event.logicalKey);
        } else if (event is KeyUpEvent) {
          _keys.remove(event.logicalKey);
        }
        // F11 → tam ekran aç/kapat
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.f11) {
          _isFullscreen = !_isFullscreen;
          windowManager.setFullScreen(_isFullscreen);
        }
        // " tuşu → chat aç/kapat
        if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.quoteSingle ||
            event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.quote) {
          setState(() {
            _isChatOpen = !_isChatOpen;
            if (_isChatOpen) {
              _chatInputCtrl.clear();
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
        body: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Stack(children: [
            // Saha
            Positioned.fill(child: _buildArena()),
            // Tam ekran modunda sadece saha göster
            if (!_isFullscreen) ...[
              // HUD (skor / süre)
              _buildHUD(),
              // Kontrol ipucu
              _buildControlsHint(),
              // FPS sayacı
              Positioned(
                bottom: 10,
                right: 16,
                child: Text(
                  'FPS: ${_fps.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white30, fontSize: 9),
                ),
              ),
            ],
            // Gol animasyonu
            if (_isGoal) _buildGoalOverlay(),
            // Maç sonu
            if (_isMatchOver) _buildMatchOverScreen(),
            // GK kurtarış
            if (!_isFullscreen && _gkSaveAnim) _buildGkSaveLabel(),
            // Chat
            if (!_showNicknameInput) _buildChatOverlay(),
            // Nickname giriş ekranı
            if (_showNicknameInput) _buildNicknameOverlay(),
          ]),
        ),
      ),
    );
  }

  Widget _buildNicknameOverlay() {
    // Takım isimleri (nickname girilmeden önce mevcut isimler)
    final teamANames =
        _teamA.where((p) => !p.isHuman).map((p) => p.name).toList();
    final teamBNames = _teamB.map((p) => p.name).toList();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 520,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.65), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.22),
                      blurRadius: 40,
                      spreadRadius: 4),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Başlık
                  Text('NATBALL',
                      style: GoogleFonts.orbitron(
                          color: Colors.greenAccent,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5)),
                  const SizedBox(height: 6),
                  Text('7 vs 7 – Tam Sahada',
                      style: GoogleFonts.orbitron(
                          color: Colors.white38,
                          fontSize: 11,
                          letterSpacing: 2)),
                  const Divider(
                      color: Colors.white12, height: 32, thickness: 1),

                  // Takım önizlemesi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Takım A
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
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
                            // Oyuncunun kendisi
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
                                      horizontal: 10, vertical: 5),
                                  margin: const EdgeInsets.only(bottom: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlueAccent
                                        .withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(n,
                                      style: GoogleFonts.orbitron(
                                          color: Colors.lightBlueAccent
                                              .withOpacity(0.8),
                                          fontSize: 10)),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // VS ayraç
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('VS',
                            style: GoogleFonts.orbitron(
                                color: Colors.white24,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      // Takım B
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
                                      decoration: BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle)),
                                ]),
                            const SizedBox(height: 8),
                            ...teamBNames.map((n) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  margin: const EdgeInsets.only(bottom: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(n,
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.orbitron(
                                          color:
                                              Colors.redAccent.withOpacity(0.8),
                                          fontSize: 10)),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(
                      color: Colors.white12, height: 32, thickness: 1),

                  // Nickname giriş
                  Text('NİCKNAMENİ GİR',
                      style: GoogleFonts.orbitron(
                          color: Colors.white60,
                          fontSize: 13,
                          letterSpacing: 2)),
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
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.greenAccent.withOpacity(0.8),
                            width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                    ),
                    onSubmitted: (_) => _confirmNickname(),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _confirmNickname,
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
                  const SizedBox(height: 14),
                  Text('F11 → Tam Ekran',
                      style: GoogleFonts.orbitron(
                          color: Colors.white24,
                          fontSize: 9,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmNickname() {
    final nick = _nickCtrl.text.trim();
    setState(() {
      _human.name = nick.isEmpty ? 'SEN' : nick;
      _showNicknameInput = false;
    });
    // Oyun sahası klavye odağını al
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Widget _buildArena() {
    return LayoutBuilder(builder: (ctx, box) {
      return CustomPaint(
        size: Size(box.maxWidth, box.maxHeight),
        painter: _NatBallPainter(
          teamA: _teamA,
          teamB: _teamB,
          ball: _ball,
          human: _human,
          goalY1: _kGoalY1,
          goalY2: _kGoalY2,
        ),
      );
    });
  }

  Widget _buildHUD() {
    double remaining =
        (_kMatchDurationSec - _elapsedSec).clamp(0, _kMatchDurationSec);
    int mins = remaining.toInt() ~/ 60;
    int secs = remaining.toInt() % 60;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.78),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Geri butonu
            GestureDetector(
              onTap: widget.onExit,
              child: Container(
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white54, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            // Score A
            _scoreBox(_scoreA, Colors.lightBlueAccent, isLeft: true),
            const SizedBox(width: 10),
            // Timer + Başlık
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('NATBALL',
                  style: GoogleFonts.orbitron(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              Text(
                '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style:
                    GoogleFonts.orbitron(color: Colors.white70, fontSize: 17),
              ),
            ]),
            const SizedBox(width: 10),
            // Score B
            _scoreBox(_scoreB, Colors.redAccent, isLeft: false),
          ],
        ),
      ),
    );
  }

  Widget _scoreBox(int score, Color color, {required bool isLeft}) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        border: Border.all(color: color.withOpacity(0.55), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$score',
          style: GoogleFonts.orbitron(
              color: color, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildControlsHint() {
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
          '← → ↑ ↓ Hareket  |  X Şut  |  Çift-X Duvarda: Roket Şut  |  Shift Duvar Pas  |  X/Shift Çal  |  Z Pas İste  |  " Chat',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ),
    );
  }

  // ─── CHAT ─────────────────────────────────────────────────────────────────
  void _sendChatMessage() {
    final text = _chatInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _chatMessages.add(_ChatMessage(_human.name, text));
      _chatInputCtrl.clear();
      // Kaydır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_chatScrollCtrl.hasClients) {
          _chatScrollCtrl.animateTo(
            _chatScrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Widget _buildChatOverlay() {
    return Positioned(
      bottom: 36,
      left: 16,
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mesaj listesi (son 8 mesaj)
          if (_chatMessages.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.62),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: ListView.builder(
                controller: _chatScrollCtrl,
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: _chatMessages.length,
                itemBuilder: (_, i) {
                  final msg = _chatMessages[i];
                  if (msg.isSystem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(msg.text,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                              fontStyle: FontStyle.italic)),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: '${msg.sender}: ',
                          style: GoogleFonts.orbitron(
                              color: Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: msg.text,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          // Giriş alanı (sadece chat açıkken görünür)
          if (_isChatOpen)
            Container(
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.6), width: 1.4),
              ),
              child: Row(
                children: [
                  // Prefix: nickname:
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${_human.name}: ',
                      style: GoogleFonts.orbitron(
                          color: Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Metin girişi
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (e) {
                        if (e is KeyDownEvent &&
                            e.logicalKey == LogicalKeyboardKey.enter) {
                          _sendChatMessage();
                        }
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
                        controller: _chatInputCtrl,
                        focusNode: _chatFocusNode,
                        maxLength: 80,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendChatMessage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoalOverlay() {
    bool isOurs = _goalText.contains('Sen');
    Color c = isOurs ? Colors.greenAccent : Colors.redAccent;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.withOpacity(0.75), width: 2.5),
          boxShadow: [BoxShadow(color: c.withOpacity(0.35), blurRadius: 35)],
        ),
        child: Text(
          _goalText,
          style: GoogleFonts.orbitron(
              color: c, fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildGkSaveLabel() {
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

  Widget _buildMatchOverScreen() {
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
        width: 340,
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
                  color: col, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Text('$_scoreA – $_scoreB',
              style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 26),
          // Tekrar oyna
          _overBtn(
            label: 'TEKRAR OYNA',
            color: Colors.greenAccent,
            onTap: () => setState(() => _initGame()),
          ),
          const SizedBox(height: 10),
          // Çıkış
          _overBtn(
            label: 'ÇIKIŞ',
            color: Colors.redAccent,
            onTap: widget.onExit,
          ),
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
                  color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTER – SAHA ÇİZİMİ
// =============================================================================
class _NatBallPainter extends CustomPainter {
  final List<_NbPlayer> teamA, teamB;
  final _NbBall ball;
  final _NbPlayer human;
  final double goalY1, goalY2;

  _NatBallPainter({
    required this.teamA,
    required this.teamB,
    required this.ball,
    required this.human,
    required this.goalY1,
    required this.goalY2,
  });

  late double _aL, _aT, _aW, _aH; // arena bounds in screen pixels
  static const double _hudH = 55.0;

  @override
  void paint(Canvas canvas, Size size) {
    _aL = 18;
    _aT = _hudH + 6;
    _aW = size.width - 36;
    _aH = size.height - _aT - 10;

    _drawField(canvas);
    _drawGoals(canvas);
    _drawPlayers(canvas, teamB);
    _drawPlayers(canvas, teamA);
    _drawBall(canvas);
  }

  Offset _s(double nx, double ny) => Offset(_aL + nx * _aW, _aT + ny * _aH);

  double _r(double n) => n * (_aW + _aH) / 2;

  void _drawField(Canvas canvas) {
    // Zemin
    canvas.drawRect(Rect.fromLTWH(_aL, _aT, _aW, _aH),
        Paint()..color = const Color(0xFF1A5E20));

    // Açık-koyu şerit
    final stripe = Paint()..color = const Color(0xFF1D6825);
    double sw = _aW / 10;
    for (int i = 0; i < 10; i += 2) {
      canvas.drawRect(Rect.fromLTWH(_aL + i * sw, _aT, sw, _aH), stripe);
    }

    final linePaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Dış çizgi
    canvas.drawRect(Rect.fromLTWH(_aL, _aT, _aW, _aH), linePaint);

    // Orta çizgi
    canvas.drawLine(Offset(_aL + _aW / 2, _aT),
        Offset(_aL + _aW / 2, _aT + _aH), linePaint);

    // Orta daire
    canvas.drawCircle(
        Offset(_aL + _aW / 2, _aT + _aH / 2), _aW * 0.12, linePaint);
    canvas.drawCircle(Offset(_aL + _aW / 2, _aT + _aH / 2), 4,
        Paint()..color = Colors.white38);

    // Ceza sahaları
    double paW = _aW * 0.12;
    double paH = _aH * 0.44;
    double paY = _aT + (_aH - paH) / 2;
    canvas.drawRect(Rect.fromLTWH(_aL, paY, paW, paH), linePaint);
    canvas.drawRect(Rect.fromLTWH(_aL + _aW - paW, paY, paW, paH), linePaint);
  }

  void _drawGoals(Canvas canvas) {
    double gy1 = _aT + goalY1 * _aH;
    double gy2 = _aT + goalY2 * _aH;
    double gH = gy2 - gy1;
    double gW = _aW * 0.032;

    final goalFill = Paint()..color = Colors.white.withOpacity(0.12);
    final goalBorder = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Sol kale (takım A'nın kalesi, takım B gol atar)
    final lGoal = Rect.fromLTWH(_aL - gW, gy1, gW, gH);
    canvas.drawRect(lGoal, goalFill);
    canvas.drawRect(lGoal, goalBorder);

    // Sağ kale (takım B'nin kalesi, takım A gol atar)
    final rGoal = Rect.fromLTWH(_aL + _aW, gy1, gW, gH);
    canvas.drawRect(rGoal, goalFill);
    canvas.drawRect(rGoal, goalBorder);
  }

  void _drawPlayers(Canvas canvas, List<_NbPlayer> team) {
    for (var p in team) {
      _drawPlayer(canvas, p);
    }
  }

  void _drawPlayer(Canvas canvas, _NbPlayer p) {
    final pos = _s(p.x, p.y);
    final double pr = _r(_kPlayerR);

    // Topa sahipse → ince parlayan halka
    if (p == ball.owner) {
      canvas.drawCircle(
          pos,
          pr + 5.0,
          Paint()
            ..color = (p.isTeamA ? Colors.lightBlueAccent : Colors.orangeAccent)
                .withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0);
    }

    Color base = p.isTeamA ? const Color(0xFF0D47A1) : const Color(0xFFB71C1C);
    Color accent = p.isTeamA ? Colors.lightBlueAccent : Colors.redAccent;

    // Gölge
    canvas.drawCircle(
        pos.translate(1.5, 1.5), pr, Paint()..color = Colors.black38);

    // Ana daire
    canvas.drawCircle(pos, pr, Paint()..color = base);

    // İç parlaklık
    canvas.drawCircle(
        pos, pr * 0.60, Paint()..color = accent.withOpacity(0.30));

    // Bakış yönü noktası
    final faceDot = pos +
        Offset(cos(p.facingAngle) * pr * 0.58, sin(p.facingAngle) * pr * 0.58);
    canvas.drawCircle(
        faceDot, pr * 0.28, Paint()..color = Colors.white.withOpacity(0.85));

    // ── İNSAN OYUNCU: belirgin beyaz dış halka ─────────────────────────────
    if (p.isHuman) {
      // Kalın beyaz ring (pr oranına göre)
      canvas.drawCircle(
          pos,
          pr + 3.0,
          Paint()
            ..color = Colors.white.withOpacity(0.95)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2);
      // Yeşil aura halkası
      canvas.drawCircle(
          pos,
          pr + 7.0,
          Paint()
            ..color = Colors.greenAccent.withOpacity(0.55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);

      // "SEN" etiketi (üstte)
      _drawText(
          canvas, pos.translate(0, -pr - 12), 'SEN', Colors.greenAccent, 8,
          bold: true);
    }

    // İsim etiketi (altta)
    String displayName =
        p.name.length > 8 ? '${p.name.substring(0, 7)}.' : p.name;
    _drawText(canvas, pos.translate(0, pr + 4), displayName,
        p.isHuman ? Colors.white : Colors.white60, p.isHuman ? 8 : 7,
        bold: p.isHuman);
  }

  void _drawBall(Canvas canvas) {
    final pos = _s(ball.x, ball.y);
    final double br = _r(_kBallR);

    // Gölge
    canvas.drawCircle(pos.translate(1.2, 1.2), br * 1.15,
        Paint()..color = Colors.black.withOpacity(0.40));

    // Beyaz zemin
    canvas.drawCircle(pos, br, Paint()..color = Colors.white);

    final blackPaint = Paint()..color = Colors.black;

    // ── Siyah-beyaz futbol topu desen ────────────────────────────────────────
    // Merkez siyah beşgen
    final cPath = Path();
    for (int i = 0; i < 5; i++) {
      double a = i * 2 * pi / 5 - pi / 2;
      double rx = pos.dx + cos(a) * br * 0.38;
      double ry = pos.dy + sin(a) * br * 0.38;
      if (i == 0)
        cPath.moveTo(rx, ry);
      else
        cPath.lineTo(rx, ry);
    }
    cPath.close();
    canvas.drawPath(cPath, blackPaint);

    // 5 çevre siyah beşgen yamalar
    for (int i = 0; i < 5; i++) {
      double ca = i * 2 * pi / 5 - pi / 10;
      final hc = pos + Offset(cos(ca) * br * 0.76, sin(ca) * br * 0.76);
      final pPath = Path();
      for (int j = 0; j < 5; j++) {
        double pa = ca + j * 2 * pi / 5;
        double rx2 = hc.dx + cos(pa) * br * 0.27;
        double ry2 = hc.dy + sin(pa) * br * 0.27;
        if (j == 0)
          pPath.moveTo(rx2, ry2);
        else
          pPath.lineTo(rx2, ry2);
      }
      pPath.close();
      canvas.drawPath(pPath, blackPaint);
    }

    // Dış sınır çizgisi
    canvas.drawCircle(
        pos,
        br,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7);
  }

  void _drawText(
      Canvas canvas, Offset center, String text, Color color, double fontSize,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center.translate(-tp.width / 2, -tp.height / 2));
  }

  @override
  bool shouldRepaint(_NatBallPainter old) => true;
}
