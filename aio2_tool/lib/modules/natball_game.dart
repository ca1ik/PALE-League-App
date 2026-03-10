import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';

// =============================================================================
// NATBALL – İnsan kontrollü mini futbol oyunu (HaxBall tarzı)
// Takım A (mavi) = oyuncu + 6 yapay-zeka; Sağa hücum eder (gol x=1)
// Takım B (kırmızı) = 7 yapay-zeka;  Sola hücum eder (gol x=0)
// Kontroller: Yön tuşları hareket | X şut | Shift pas
// =============================================================================

// ─── Sabitler ─────────────────────────────────────────────────────────────────
const double _kGoalY1 = 0.38; // kale açıklığı üst sınırı (normalize)
const double _kGoalY2 = 0.62; // kale açıklığı alt sınırı (normalize)
const double _kPlayerR = 0.012; // oyuncu yarıçapı
const double _kBallR = 0.006; // top yarıçapı
const double _kNatBallPickupR = 0.026; // top alma mesafesi
const double _kShootPower = 0.020; // şut başlangıç hızı – HaxBall gibi
const double _kPassPower = 0.012; // pas başlangıç hızı
const double _kPlayerAccel = 0.0011; // oyuncu ivme – yavaş/HaxBall
const double _kPlayerDamp = 0.78; // oyuncu hız sönümleme
const double _kBallFric = 0.983; // top sürtünme (daha fazla)
const double _kBallBounce = 1.00; // mükemmel yansıma (enerji kaybı yok)
const double _kAiAccel = 0.0011; // yapay-zeka ivmesi – oyuncuyla eşit
const double _kMaxSpeed = 0.0070; // maksimum hız – HaxBall gibi yavaş
const double _kAiPassChancePct = 5; // her tick'teki pas olasılığı (%)
const double _kMatchDurationSec = 120.0; // maç süresi
const double _kGkRange = 0.14; // kaleci çalışma yarıçapı
const double _kStealRange = 0.038; // top çalma mesafesi (insan → rakip)

// =============================================================================
// OYUNCU VERİSİ
// =============================================================================
class _NbPlayer {
  String name;
  double x, y;
  double vx = 0, vy = 0;
  double facingAngle; // radyan; 0=sağ, π=sol
  final bool isHuman;
  final bool isTeamA;
  final double homeX, homeY;
  final bool isGk;

  // Yapay zeka – takım arkadaşı pas sayacı
  int _aiPassCountdown = 0;

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
  _NbPlayer? owner;
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
  double _accumulator = 0;
  static const double _simDt = 1.0 / 60.0;

  late List<_NbPlayer> _teamA; // insan + 6 yapay-zeka
  late List<_NbPlayer> _teamB; // 7 yapay-zeka rakip
  late _NbPlayer _human; // insan oyuncusu
  final _NbBall _ball = _NbBall();

  // Klavye durumu
  final Set<LogicalKeyboardKey> _keys = {};
  final FocusNode _focusNode = FocusNode();

  int _scoreA = 0, _scoreB = 0;
  double _elapsedSec = 0;
  bool _isGoal = false;
  String _goalText = '';
  int _goalPauseTicks = 0;
  bool _isMatchOver = false;

  // İnsan pas attıktan sonra takım arkadaşları topa koşsun
  int _runToBallTicks = 0;

  // Şut/pas soğuma sayacı
  int _kickCooldown = 0;

  // Double-tap X (köşe triği)
  bool _xHeld = false;
  bool _shiftHeld = false;
  int _xDoubleTapWindow = 0;

  // GK kayıt animasyonu
  bool _gkSaveAnim = false;
  int _gkSaveTimer = 0;

  // Dinamik insan markajcısı (her tick güncellenir)
  _NbPlayer? _humanMarker;

  // Nickname girişi
  bool _showNicknameInput = true;
  final TextEditingController _nickCtrl = TextEditingController();

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
    _nickCtrl.dispose();
    super.dispose();
  }

  // ─── OYUNU BAŞLAT ───────────────────────────────────────────────────────────
  void _initGame() {
    _scoreA = 0;
    _scoreB = 0;
    _elapsedSec = 0;
    _isGoal = false;
    _isMatchOver = false;
    _runToBallTicks = 0;
    _kickCooldown = 0;
    _xHeld = false;
    _shiftHeld = false;
    _xDoubleTapWindow = 0;
    _gkSaveAnim = false;
    _gkSaveTimer = 0;
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
      out.add('P${out.length + 1}');
    }
    return out.take(count).toList();
  }

  void _kickoff({required bool teamAStarts}) {
    // Oyuncuları kendi yarılarına döndür
    for (var p in [..._teamA, ..._teamB]) {
      double kx =
          p.isTeamA ? p.homeX.clamp(0.05, 0.48) : p.homeX.clamp(0.52, 0.95);
      p.x = kx;
      p.y = p.homeY;
      p.vx = 0;
      p.vy = 0;
      p.facingAngle = p.isTeamA ? 0 : pi;
    }
    // Topu merkeze, başlayan takımın forvetine ver
    _ball.x = 0.5;
    _ball.y = 0.5;
    _ball.vx = 0;
    _ball.vy = 0;
    if (teamAStarts) {
      _human.x = 0.5;
      _human.y = 0.5;
      _ball.owner = _human;
    } else {
      _ball.owner = _teamB[6]; // Rakip forvet
      _teamB[6].x = 0.5;
      _teamB[6].y = 0.5;
    }
  }

  // ─── OYUN DÖNGÜSÜ ───────────────────────────────────────────────────────────
  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final wallDt = (elapsed - _lastFrame).inMicroseconds / 1e6;
    _lastFrame = elapsed;
    _accumulator += wallDt.clamp(0.0, 0.1);
    while (_accumulator >= _simDt) {
      _accumulator -= _simDt;
      _simStep();
    }
    setState(() {});
  }

  void _simStep() {
    if (_showNicknameInput) return; // Nickname girilmeden oyun başlamaz
    if (_isMatchOver) return;

    if (_isGoal) {
      _goalPauseTicks--;
      if (_goalPauseTicks <= 0) {
        _isGoal = false;
        _kickoff(teamAStarts: _ball.x > 0.5); // gol yeyen takım başlar
      }
      return;
    }

    if (_gkSaveAnim) {
      _gkSaveTimer--;
      if (_gkSaveTimer <= 0) _gkSaveAnim = false;
    }

    _elapsedSec += _simDt;
    if (_elapsedSec >= _kMatchDurationSec) {
      _isMatchOver = true;
      return;
    }

    if (_kickCooldown > 0) _kickCooldown--;
    if (_runToBallTicks > 0) _runToBallTicks--;

    // İnsan hareketi
    _updateHuman();

    // Takım A yapay-zeka
    for (var p in _teamA) {
      if (p.isHuman) continue;
      _updateAiTeammate(p);
    }

    // Takım B yapay-zeka
    // En yakın B oyuncusunu dinamik insan markajcısı olarak seç
    _humanMarker = null;
    double _nearestBDist = double.infinity;
    for (var p in _teamB) {
      if (p.isGk || _ball.owner == p) continue;
      final double d = sqrt(pow(p.x - _human.x, 2) + pow(p.y - _human.y, 2));
      if (d < _nearestBDist) {
        _nearestBDist = d;
        _humanMarker = p;
      }
    }
    for (var p in _teamB) {
      _updateAiOpponent(p);
    }

    // Top fiziği
    _updateBall();

    // Top sahiplik kontrolü
    _checkPickup();

    // Gol kontrolü
    _checkGoal();
  }

  // ─── İNSAN GİRİŞİ ──────────────────────────────────────────────────────────
  void _updateHuman() {
    double mx = 0, my = 0;
    if (_keys.contains(LogicalKeyboardKey.arrowLeft)) mx -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowRight)) mx += 1;
    if (_keys.contains(LogicalKeyboardKey.arrowUp)) my -= 1;
    if (_keys.contains(LogicalKeyboardKey.arrowDown)) my += 1;

    if (mx != 0 || my != 0) {
      double len = sqrt(mx * mx + my * my);
      mx /= len;
      my /= len;
      _human.vx += mx * _kPlayerAccel;
      _human.vy += my * _kPlayerAccel;
      _human.facingAngle = atan2(my, mx);
    }

    // Hız sınırlama + sönümleme
    _human.vx = (_human.vx * _kPlayerDamp).clamp(-_kMaxSpeed, _kMaxSpeed);
    _human.vy = (_human.vy * _kPlayerDamp).clamp(-_kMaxSpeed, _kMaxSpeed);

    // Hareket
    _human.x = (_human.x + _human.vx).clamp(_kPlayerR, 1.0 - _kPlayerR);
    _human.y = (_human.y + _human.vy).clamp(_kPlayerR, 1.0 - _kPlayerR);

    // Tuş durumu – tek basış tespiti (key-repeat'i engeller)
    bool xNow = _keys.contains(LogicalKeyboardKey.keyX);
    bool shiftNow = _keys.contains(LogicalKeyboardKey.shiftLeft) ||
        _keys.contains(LogicalKeyboardKey.shiftRight);
    bool xFired = xNow && !_xHeld && _kickCooldown == 0;
    bool shiftFired = shiftNow && !_shiftHeld && _kickCooldown == 0;
    if (_xDoubleTapWindow > 0) _xDoubleTapWindow--;
    _xHeld = xNow;
    _shiftHeld = shiftNow;

    // ── Topa sahipse → taşı + vuruş ──────────────────────────────────────────
    if (_ball.owner == _human) {
      _ball.x =
          _human.x + cos(_human.facingAngle) * (_kPlayerR + _kBallR + 0.003);
      _ball.y =
          _human.y + sin(_human.facingAngle) * (_kPlayerR + _kBallR + 0.003);

      if (xFired) {
        if (_xDoubleTapWindow > 0) {
          _humanCornerTrick(); // Double-tap X → köşe triği
          _xDoubleTapWindow = 0;
        } else {
          _humanShoot();
          _xDoubleTapWindow = 18; // 18 tick içinde tekrar X → köşe triği
        }
        _kickCooldown = 26;
      } else if (shiftFired) {
        _humanWallPass();
        _kickCooldown = 26;
      }
    }
    // ── Top serbest → yakınsa X/Shift ile vur ────────────────────────────────
    else if (_ball.owner == null) {
      double bd = sqrt(pow(_human.x - _ball.x, 2) + pow(_human.y - _ball.y, 2));
      if (bd < _kNatBallPickupR * 2.4) {
        if (xFired) {
          if (_xDoubleTapWindow > 0) {
            _humanCornerTrick();
            _xDoubleTapWindow = 0;
          } else {
            _humanShootLoose();
            _xDoubleTapWindow = 18;
          }
          _kickCooldown = 24;
        } else if (shiftFired) {
          _humanWallPassLoose();
          _kickCooldown = 24;
        }
      }
    }
    // ── Takım arkadaşı topa sahipse → X/Shift ile hemen pas iste ─────────────
    else if (_ball.owner!.isTeamA && !_ball.owner!.isHuman) {
      if (xFired || shiftFired) {
        _ball.owner!._aiPassCountdown = 0;
        _kickCooldown = 18;
      }
    }
    // ── Rakip topa sahipse → yakınsa X/Shift ile çal ─────────────────────────
    else if (!_ball.owner!.isTeamA) {
      if (xFired || shiftFired) {
        double d = sqrt(pow(_human.x - _ball.owner!.x, 2) +
            pow(_human.y - _ball.owner!.y, 2));
        if (d < _kStealRange) {
          _ball.owner = _human;
          _kickCooldown = 32;
        }
      }
    }
  }

  // ─── İNSAN ŞUT ─────────────────────────────────────────────────────────────
  void _humanShoot() {
    _ball.owner = null;

    const double goalX = 1.0; // Rakip kale sağda
    const double goalY = 0.5;

    // İnsan kaledeki açıya mı bakıyor?
    double toGoalAngle = atan2(goalY - _human.y, goalX - _human.x);
    double diff = (_normalizeAngle(_human.facingAngle - toGoalAngle)).abs();
    bool isPowerShot = diff < (pi / 2.5); // 72 derece içinde güçlü şut

    double power = isPowerShot ? _kShootPower * 1.65 : _kShootPower;

    double targetY = goalY + (_rng.nextDouble() - 0.5) * 0.18;
    double dx = goalX - _human.x;
    double dy = targetY - _human.y;
    double len = sqrt(dx * dx + dy * dy);
    if (len == 0) len = 0.001;

    if (!isPowerShot) {
      // Baktığı yöne doğru vur
      dx = cos(_human.facingAngle);
      dy = sin(_human.facingAngle);
      len = 1.0;
    }

    _ball.vx = (dx / len) * power;
    _ball.vy = (dy / len) * power;
    _ball.x = _human.x;
    _ball.y = _human.y;
  }

  // ─── BOŞ TOP VURUŞU (top serbest, sahpsiz) ──────────────────────────────────
  void _humanShootLoose() {
    _ball.vx = cos(_human.facingAngle) * _kShootPower * 0.9;
    _ball.vy = sin(_human.facingAngle) * _kShootPower * 0.9;
  }

  void _humanWallPassLoose() {
    double dTop = _ball.y;
    double dBot = 1.0 - _ball.y;
    double dLeft = _ball.x;
    double dRight = 1.0 - _ball.x;
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
    _ball.vx = (dx / dist) * _kPassPower * 2.8;
    _ball.vy = (dy / dist) * _kPassPower * 2.8;
    _runToBallTicks = 60;
  }

  // ─── KÖŞE TRİĞİ – Double-tap X ──────────────────────────────────────────────
  // Top en yakın köşeye çapraz atılır; bounce=1.0 ile duvarlarda hiç enerji
  // kaybetmeden yansır ve oyuncuya geri döner.
  void _humanCornerTrick() {
    _ball.owner = null;
    const cs = [
      [0.01, 0.01],
      [0.99, 0.01],
      [0.01, 0.99],
      [0.99, 0.99]
    ];
    double bestDist = double.infinity;
    double cx = 0.01, cy = 0.01;
    for (var c in cs) {
      double d = sqrt(pow(_human.x - c[0], 2) + pow(_human.y - c[1], 2));
      if (d < bestDist) {
        bestDist = d;
        cx = c[0];
        cy = c[1];
      }
    }
    double dx = cx - _human.x;
    double dy = cy - _human.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;
    _ball.vx = (dx / dist) * _kShootPower * 2.4;
    _ball.vy = (dy / dist) * _kShootPower * 2.4;
    _ball.x = _human.x;
    _ball.y = _human.y;
  }

  // ─── İNSAN DUVAR PASI (Shift) ────────────────────────────────────────────────
  // Top en yakın duvara gider, sekrep geri bana gelir (bilardo yansıması)
  void _humanWallPass() {
    _ball.owner = null;

    double dTop = _human.y;
    double dBot = 1.0 - _human.y;
    double dLeft = _human.x;
    double dRight = 1.0 - _human.x;
    double minD = [dTop, dBot, dLeft, dRight].reduce(min);

    // Duvar üzerindeki ayna noktası: top buraya gidince yansıyıp bana gelir
    double mirrorX, mirrorY;
    if (minD == dTop) {
      mirrorX = _human.x;
      mirrorY = -_human.y; // y=0 üzerinde ayna
    } else if (minD == dBot) {
      mirrorX = _human.x;
      mirrorY = 2.0 - _human.y; // y=1 üzerinde ayna
    } else if (minD == dLeft) {
      mirrorX = -_human.x; // x=0 üzerinde ayna
      mirrorY = _human.y;
    } else {
      mirrorX = 2.0 - _human.x; // x=1 üzerinde ayna
      mirrorY = _human.y;
    }

    double dx = mirrorX - _human.x;
    double dy = mirrorY - _human.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;

    double power = _kPassPower * 2.8;
    _ball.vx = (dx / dist) * power;
    _ball.vy = (dy / dist) * power;
    _ball.x = _human.x;
    _ball.y = _human.y;

    // Takım arkadaşları ~1 sn boyunca topa yaklaşsın
    _runToBallTicks = 60;
  }

  // ─── TAKIM A YAPAY-ZEKASI (takım arkadaşı) ─────────────────────────────────
  void _updateAiTeammate(_NbPlayer p) {
    // Kaleciyse → kalede kal
    if (p.isGk) {
      _updateTeamAGk(p);
      return;
    }

    double tx, ty;

    if (_ball.owner == p) {
      // Topa sahipse: her zaman insana pas at
      _doTeamPassToHuman(p);
      return;
    }

    if (_runToBallTicks > 0) {
      // İnsan pas attıktan sonra → topa koş
      tx = _ball.x;
      ty = _ball.y;
    } else if (_ball.owner == null) {
      // Top serbest → insan uzaksa yaklaş
      double humanDist =
          sqrt(pow(_human.x - _ball.x, 2) + pow(_human.y - _ball.y, 2));
      if (humanDist > 0.22) {
        tx = _ball.x;
        ty = _ball.y;
      } else {
        // Destek pozisyonu
        tx = p.homeX * 0.6 + _ball.x * 0.4;
        ty = p.homeY * 0.6 + _ball.y * 0.4;
      }
    } else if (_ball.owner!.isTeamA) {
      // Takım arkadaşı topa sahip → destek pozisyonu
      tx = (_ball.x + p.homeX + 0.05) / 2;
      ty = p.homeY + (_rng.nextDouble() - 0.5) * 0.08;
    } else {
      // Rakip topa sahip → savunma
      tx = p.homeX * 0.85;
      ty = p.homeY;
    }

    _aiMoveTo(p, tx, ty, _kAiAccel);
  }

  // Takım A kalecisi
  void _updateTeamAGk(_NbPlayer gk) {
    double tx = gk.homeX;
    double ty = _ball.y.clamp(gk.homeY - _kGkRange, gk.homeY + _kGkRange);
    _aiMoveTo(gk, tx, ty, _kAiAccel * 1.1);

    // Top yakın ve sahip olmayan: toplu al
    if (_ball.owner == null) {
      double d = sqrt(pow(gk.x - _ball.x, 2) + pow(gk.y - _ball.y, 2));
      if (d < _kNatBallPickupR * 1.5) {
        _ball.owner = gk; // kurtarış
        _gkSaveAnim = true;
        _gkSaveTimer = 40;
      }
    }

    // Kurtarıştaysa → topa pas at insana
    if (_ball.owner == gk && _rng.nextInt(100) < 8) {
      _doTeamPassToHuman(gk);
    }
  }

  // Takım A – topa sahip yapay-zeka insana pas at
  void _doTeamPassToHuman(_NbPlayer passer) {
    passer._aiPassCountdown--;
    if (passer._aiPassCountdown > 0) {
      // Bekle, insana doğru yavaşça ilerle
      _aiMoveTo(passer, _human.x * 0.4 + passer.homeX * 0.6, passer.homeY,
          _kAiAccel * 0.5);
      return;
    }
    // Sayaç sıfırsa pas at
    passer._aiPassCountdown =
        18 + _rng.nextInt(20); // 18-37 tick bekle sonra tekrar

    _ball.owner = null;
    double dx = _human.x - passer.x + (_rng.nextDouble() - 0.5) * 0.07;
    double dy = _human.y - passer.y + (_rng.nextDouble() - 0.5) * 0.07;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist == 0) dist = 0.001;
    double power =
        (_kPassPower + dist * 0.55).clamp(_kPassPower, _kPassPower * 2.2);

    _ball.vx = (dx / dist) * power;
    _ball.vy = (dy / dist) * power;
    _ball.x = passer.x;
    _ball.y = passer.y;
  }

  // ─── TAKIM B YAPAY-ZEKASI (rakip) ──────────────────────────────────────────
  void _updateAiOpponent(_NbPlayer p) {
    if (p.isGk) {
      _updateTeamBGk(p);
      return;
    }

    double tx, ty;

    // ── Topa sahipse → saldır ─────────────────────────────────────────────────
    if (_ball.owner == p) {
      bool canShoot = p.x < 0.30;
      p._aiPassCountdown--;
      if (canShoot && p._aiPassCountdown <= 0) {
        _aiShoot(p);
        p._aiPassCountdown = 28 + _rng.nextInt(22);
      } else if (!canShoot && p._aiPassCountdown <= 0) {
        _aiTeamBPass(p);
        p._aiPassCountdown = 20 + _rng.nextInt(18);
      } else {
        tx = 0.10 + _rng.nextDouble() * 0.04;
        ty = 0.38 + _rng.nextDouble() * 0.24;
        _aiMoveTo(p, tx, ty, _kAiAccel);
      }
      return;
    }

    // ── En yakın B oyuncusu: insanı uzaktan açı kapatır ──────────────────────
    if (p == _humanMarker) {
      // İnsan ile B kalesi (x≈0) arasında, 0.12 mesafede dur → pasını kes
      const double gx = 0.03, gy = 0.50;
      double ddx = gx - _human.x;
      double ddy = gy - _human.y;
      double ddist = sqrt(ddx * ddx + ddy * ddy);
      if (ddist < 0.001) ddist = 0.001;
      const double coverDist = 0.12;
      tx = _human.x + (ddx / ddist) * coverDist;
      ty = _human.y + (ddy / ddist) * coverDist;
      _aiMoveTo(p, tx, ty, _kAiAccel * 1.05);
      return;
    }

    // ── Diğerleri: adam adama markaj – karşılıklı A oyuncusunu takip et ──────
    final int bIdx = _teamB.indexOf(p);
    if (bIdx > 0 && bIdx < _teamA.length) {
      final _NbPlayer markA = _teamA[bIdx];
      // A oyuncusunun B kalesine bakan tarafında biraz önünde dur
      tx = markA.x - 0.06;
      ty = markA.y;
      _aiMoveTo(p, tx, ty, _kAiAccel * 0.95);
      return;
    }

    // ── Fallback: ev pozisyonu ────────────────────────────────────────────────
    tx = p.homeX + 0.04;
    ty = p.homeY;
    _aiMoveTo(p, tx, ty, _kAiAccel);
  }

  void _updateTeamBGk(_NbPlayer gk) {
    double tx = gk.homeX;
    double ty = _ball.y.clamp(gk.homeY - _kGkRange, gk.homeY + _kGkRange);
    _aiMoveTo(gk, tx, ty, _kAiAccel * 1.05);

    if (_ball.owner == null) {
      double d = sqrt(pow(gk.x - _ball.x, 2) + pow(gk.y - _ball.y, 2));
      if (d < _kNatBallPickupR * 1.4) {
        _ball.owner = gk;
        _gkSaveAnim = true;
        _gkSaveTimer = 40;
      }
    }

    if (_ball.owner == gk && _rng.nextInt(100) < 7) {
      _aiClearBall(gk);
    }
  }

  void _aiShoot(_NbPlayer p) {
    _ball.owner = null;
    double goalX = 0.0;
    double goalY = 0.5;
    double dx = goalX - p.x + (_rng.nextDouble() - 0.5) * 0.14;
    double dy = goalY - p.y + (_rng.nextDouble() - 0.5) * 0.14;
    double len = sqrt(dx * dx + dy * dy);
    if (len == 0) len = 0.001;
    _ball.vx = (dx / len) * _kShootPower * 1.25;
    _ball.vy = (dy / len) * _kShootPower * 1.25;
    _ball.x = p.x;
    _ball.y = p.y;
  }

  void _aiClearBall(_NbPlayer gk) {
    // Rakipten uzağa uzun pas at
    _ball.owner = null;
    _ball.vx = _kPassPower * 1.5 * (gk.isTeamA ? 1 : -1);
    _ball.vy = (_rng.nextDouble() - 0.5) * _kPassPower;
    _ball.x = gk.x;
    _ball.y = gk.y;
  }

  // ─── TAKIM B İÇ PASI ──────────────────────────────────────────────────────────
  // Takım B oyuncusu topa sahipken en önde duran takım arkadaşına pas atar
  void _aiTeamBPass(_NbPlayer passer) {
    _NbPlayer? target;
    double bestScore = double.infinity;
    for (var t in _teamB) {
      if (t == passer || t.isGk) continue;
      double dist = sqrt(pow(t.x - passer.x, 2) + pow(t.y - passer.y, 2));
      // Küçük x = daha önde (B için sol yön = gol yönü)
      double xBonus = t.x * 0.35;
      double score = dist + xBonus;
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

  bool _isNearestToBall(List<_NbPlayer> team, _NbPlayer p) {
    double myDist = sqrt(pow(p.x - _ball.x, 2) + pow(p.y - _ball.y, 2));
    for (var q in team) {
      if (q == p) continue;
      double d = sqrt(pow(q.x - _ball.x, 2) + pow(q.y - _ball.y, 2));
      if (d < myDist) return false;
    }
    return true;
  }

  void _aiMoveTo(_NbPlayer p, double tx, double ty, double accel) {
    double dx = tx - p.x;
    double dy = ty - p.y;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist < 0.005) {
      p.vx *= _kPlayerDamp;
      p.vy *= _kPlayerDamp;
    } else {
      p.vx += (dx / dist) * accel;
      p.vy += (dy / dist) * accel;
      p.facingAngle = atan2(dy, dx);
    }
    p.vx = (p.vx * _kPlayerDamp).clamp(-_kMaxSpeed, _kMaxSpeed);
    p.vy = (p.vy * _kPlayerDamp).clamp(-_kMaxSpeed, _kMaxSpeed);
    p.x = (p.x + p.vx).clamp(_kPlayerR, 1.0 - _kPlayerR);
    p.y = (p.y + p.vy).clamp(_kPlayerR, 1.0 - _kPlayerR);
  }

  // ─── TOP FİZİĞİ ─────────────────────────────────────────────────────────────
  void _updateBall() {
    if (_ball.owner != null) return; // Sahip taşıyor, ayrıca güncellenmiyor

    _ball.x += _ball.vx;
    _ball.y += _ball.vy;
    _ball.vx *= _kBallFric;
    _ball.vy *= _kBallFric;

    // Üst/Alt duvar sekmesi
    if (_ball.y < _kBallR) {
      _ball.y = _kBallR;
      _ball.vy = -_ball.vy * _kBallBounce;
    }
    if (_ball.y > 1.0 - _kBallR) {
      _ball.y = 1.0 - _kBallR;
      _ball.vy = -_ball.vy * _kBallBounce;
    }

    // Sol duvar (kale alanı hariç)
    if (_ball.x < _kBallR) {
      bool inGoal = _ball.y >= _kGoalY1 && _ball.y <= _kGoalY2;
      if (!inGoal) {
        _ball.x = _kBallR;
        _ball.vx = -_ball.vx * _kBallBounce;
      }
    }
    // Sağ duvar (kale alanı hariç)
    if (_ball.x > 1.0 - _kBallR) {
      bool inGoal = _ball.y >= _kGoalY1 && _ball.y <= _kGoalY2;
      if (!inGoal) {
        _ball.x = 1.0 - _kBallR;
        _ball.vx = -_ball.vx * _kBallBounce;
      }
    }

    // Oyuncu → topa itme (sahip olmayan oyuncularda)
    for (var p in [..._teamA, ..._teamB]) {
      double dx = _ball.x - p.x;
      double dy = _ball.y - p.y;
      double dist = sqrt(dx * dx + dy * dy);
      double minD = _kBallR + _kPlayerR;
      if (dist < minD && dist > 0.001) {
        double nx = dx / dist;
        double ny = dy / dist;
        double spd = sqrt(_ball.vx * _ball.vx + _ball.vy * _ball.vy);
        spd = max(spd, 0.007);
        _ball.vx = nx * spd * 1.3;
        _ball.vy = ny * spd * 1.3;
        _ball.x = p.x + nx * (minD + 0.002);
        _ball.y = p.y + ny * (minD + 0.002);
      }
    }
  }

  // ─── SAHİPLİK KONTROLÜ ──────────────────────────────────────────────────────
  void _checkPickup() {
    if (_ball.owner != null) return;
    double ballSpd = sqrt(_ball.vx * _ball.vx + _ball.vy * _ball.vy);
    if (ballSpd > 0.032) return; // Top çok hızlıyken sahiplik olmaz

    _NbPlayer? closest;
    double closestDist = double.infinity;
    for (var p in [..._teamA, ..._teamB]) {
      double d = sqrt(pow(p.x - _ball.x, 2) + pow(p.y - _ball.y, 2));
      if (d < closestDist) {
        closestDist = d;
        closest = p;
      }
    }
    if (closest != null && closestDist < _kNatBallPickupR) {
      _ball.owner = closest;
      // Topa yeni sahip olan yapay zeka için pas sayacını tazele
      if (!closest.isHuman) {
        closest._aiPassCountdown = 8 + _rng.nextInt(14);
      }
    }
  }

  // ─── GOL KONTROLÜ ───────────────────────────────────────────────────────────
  void _checkGoal() {
    // Sağ kale: Takım A gol atar (x > 1, y ∈ [_kGoalY1, _kGoalY2])
    if (_ball.x > 1.0 && _ball.y >= _kGoalY1 && _ball.y <= _kGoalY2) {
      _scoreA++;
      _goalText = '⚽ GOL! Sen attın!';
      _triggerGoal();
      return;
    }
    // Sol kale: Takım B gol atar
    if (_ball.x < 0.0 && _ball.y >= _kGoalY1 && _ball.y <= _kGoalY2) {
      _scoreB++;
      _goalText = '😔 Gol Yedik!';
      _triggerGoal();
    }
  }

  void _triggerGoal() {
    _isGoal = true;
    _goalPauseTicks = 130; // ~2.2 saniye
    _ball.owner = null;
    _ball.vx = 0;
    _ball.vy = 0;
  }

  // ─── YARDIMCI ───────────────────────────────────────────────────────────────
  double _normalizeAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
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
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          child: Stack(children: [
            // Saha
            Positioned.fill(child: _buildArena()),
            // HUD (skor / süre)
            _buildHUD(),
            // Kontrol ipucu
            _buildControlsHint(),
            // Gol animasyonu
            if (_isGoal) _buildGoalOverlay(),
            // Maç sonu
            if (_isMatchOver) _buildMatchOverScreen(),
            // GK kurtarış
            if (_gkSaveAnim) _buildGkSaveLabel(),
            // Nickname giriş ekranı
            if (_showNicknameInput) _buildNicknameOverlay(),
          ]),
        ),
      ),
    );
  }

  Widget _buildNicknameOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.6), width: 1.6),
              boxShadow: [
                BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.18),
                    blurRadius: 24,
                    spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NATBALL',
                    style: GoogleFonts.orbitron(
                        color: Colors.greenAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3)),
                const SizedBox(height: 8),
                Text('Nicknameni gir',
                    style: GoogleFonts.orbitron(
                        color: Colors.white54, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 24),
                TextField(
                  controller: _nickCtrl,
                  autofocus: true,
                  maxLength: 16,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                      color: Colors.white, fontSize: 14, letterSpacing: 1.5),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'OYUNCU',
                    hintStyle: GoogleFonts.orbitron(
                        color: Colors.white24, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.greenAccent.withOpacity(0.7),
                          width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _confirmNickname(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmNickname,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('OYNA',
                        style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 2)),
                  ),
                ),
              ],
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
          '← → ↑ ↓ Hareket  |  X Şut  |  Shift Duvar Pas  |  X/Shift (rakip yakın) Top Çal',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
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

    Color base = p.isTeamA
        ? const Color(0xFF0D47A1) // koyu mavi
        : const Color(0xFFB71C1C); // koyu kırmızı
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
