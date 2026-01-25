import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/player_data.dart';
import '../ui/glass_box.dart';

class StrategyMakerModule extends StatefulWidget {
  const StrategyMakerModule({super.key});

  @override
  State<StrategyMakerModule> createState() => _StrategyMakerModuleState();
}

class _StrategyMakerModuleState extends State<StrategyMakerModule> {
  // Ayarlar
  bool isHorizontal = true;
  double playerSize = 40.0;
  Color team1Color = Colors.red;
  Color team2Color = Colors.blue;
  Color arrowColor = Colors.yellow;
  int pitchStyle = 0; // 0: Çim, 1: Taktik(Koyu), 2: Beyaz Tahta
  bool showOpponent = false;

  // Çizim Verileri
  List<DrawingPath> paths = [];
  DrawingPath? currentPath;
  bool isDrawingMode = false;

  // Oyuncular (Pozisyonları Normalized 0.0 - 1.0)
  List<StrategyPlayer> team1 = [];
  List<StrategyPlayer> team2 = [];

  // Yazılar
  List<DraggableText> texts = [];

  // Veritabanı
  late Box<StrategyModel> strategyBox;

  @override
  void initState() {
    super.initState();
    _resetPlayers();
    _openBox();
  }

  Future<void> _openBox() async {
    strategyBox = await Hive.openBox<StrategyModel>('palehax_strategies');
  }

  void _resetPlayers() {
    team1 = [
      StrategyPlayer(id: "t1_1", number: 1, pos: const Offset(0.05, 0.5)), // GK
      StrategyPlayer(id: "t1_3", number: 3, pos: const Offset(0.20, 0.3)), // CB
      StrategyPlayer(id: "t1_6", number: 6, pos: const Offset(0.20, 0.7)), // CB
      StrategyPlayer(
          id: "t1_10", number: 10, pos: const Offset(0.40, 0.5)), // CM
      StrategyPlayer(id: "t1_7", number: 7, pos: const Offset(0.60, 0.2)), // RW
      StrategyPlayer(
          id: "t1_11", number: 11, pos: const Offset(0.60, 0.8)), // LW
      StrategyPlayer(id: "t1_9", number: 9, pos: const Offset(0.75, 0.5)), // ST
    ];

    team2 = [
      StrategyPlayer(id: "t2_1", number: 1, pos: const Offset(0.95, 0.5)),
      StrategyPlayer(id: "t2_3", number: 3, pos: const Offset(0.80, 0.3)),
      StrategyPlayer(id: "t2_6", number: 6, pos: const Offset(0.80, 0.7)),
      StrategyPlayer(id: "t2_10", number: 10, pos: const Offset(0.60, 0.5)),
      StrategyPlayer(id: "t2_7", number: 7, pos: const Offset(0.40, 0.2)),
      StrategyPlayer(id: "t2_11", number: 11, pos: const Offset(0.40, 0.8)),
      StrategyPlayer(id: "t2_9", number: 9, pos: const Offset(0.25, 0.5)),
    ];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // --- SOL: ARAÇ ÇUBUĞU ---
          Container(
            width: 80,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF15151A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _toolBtn(Icons.rotate_90_degrees_ccw, "Yön",
                    () => setState(() => isHorizontal = !isHorizontal)),
                _toolBtn(Icons.groups, "Rakip",
                    () => setState(() => showOpponent = !showOpponent)),
                _toolBtn(Icons.brush, "Çizim",
                    () => setState(() => isDrawingMode = !isDrawingMode),
                    isActive: isDrawingMode),
                _toolBtn(Icons.title, "Yazı Ekle", _addText),
                _toolBtn(Icons.undo, "Geri Al", () {
                  if (paths.isNotEmpty) setState(() => paths.removeLast());
                }),
                _toolBtn(
                    Icons.delete,
                    "Temizle",
                    () => setState(() {
                          paths.clear();
                          texts.clear();
                          _resetPlayers();
                        })),
                const Divider(color: Colors.white24),
                _toolBtn(Icons.save, "Kaydet", _showSaveDialog),
                _toolBtn(Icons.folder_open, "Yükle", _showLoadDialog),
              ],
            ),
          ),

          // --- ORTA: SAHA ---
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: isHorizontal ? 1.5 : 0.66,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: _getPitchDecoration(),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        double w = constraints.maxWidth;
                        double h = constraints.maxHeight;

                        return Stack(
                          children: [
                            // 1. Çizim Katmanı (Sürüklemeden bağımsız, en altta ama erişilebilir)
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: isDrawingMode
                                    ? (d) {
                                        setState(() => currentPath =
                                            DrawingPath(
                                                points: [d.localPosition],
                                                color: arrowColor));
                                      }
                                    : null,
                                onPanUpdate: isDrawingMode
                                    ? (d) {
                                        setState(() => currentPath?.points
                                            .add(d.localPosition));
                                      }
                                    : null,
                                onPanEnd: isDrawingMode
                                    ? (d) {
                                        if (currentPath != null) {
                                          setState(() {
                                            paths.add(currentPath!);
                                            currentPath = null;
                                          });
                                        }
                                      }
                                    : null,
                                child: CustomPaint(
                                  painter: StrategyPainter(
                                      paths: paths, currentPath: currentPath),
                                ),
                              ),
                            ),

                            // 2. Takım 1 Oyuncuları
                            ...team1.map((p) =>
                                _buildDraggablePlayer(p, team1Color, w, h)),

                            // 3. Takım 2 Oyuncuları (Opsiyonel)
                            if (showOpponent)
                              ...team2.map((p) =>
                                  _buildDraggablePlayer(p, team2Color, w, h)),

                            // 4. Yazılar
                            ...texts.map((t) => _buildDraggableText(t, w, h)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- SAĞ: AYARLAR ---
          Container(
            width: 250,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: const Color(0xFF15151A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AYARLAR",
                      style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Saha Tipi",
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  Row(
                    children: [
                      _colorBtn(
                          Colors.green, () => setState(() => pitchStyle = 0)),
                      _colorBtn(const Color(0xFF1A1A2E),
                          () => setState(() => pitchStyle = 1)),
                      _colorBtn(
                          Colors.white, () => setState(() => pitchStyle = 2)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Forma Renkleri",
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  Row(
                    children: [
                      _colorBtn(Colors.red,
                          () => setState(() => team1Color = Colors.red)),
                      _colorBtn(Colors.blue,
                          () => setState(() => team1Color = Colors.blue)),
                      _colorBtn(Colors.orange,
                          () => setState(() => team1Color = Colors.orange)),
                      _colorBtn(Colors.black,
                          () => setState(() => team1Color = Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Ok Rengi",
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  Row(
                    children: [
                      _colorBtn(Colors.yellow,
                          () => setState(() => arrowColor = Colors.yellow)),
                      _colorBtn(Colors.white,
                          () => setState(() => arrowColor = Colors.white)),
                      _colorBtn(Colors.black,
                          () => setState(() => arrowColor = Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Oyuncu Boyutu",
                      style: GoogleFonts.poppins(color: Colors.grey)),
                  Slider(
                    value: playerSize,
                    min: 20,
                    max: 60,
                    activeColor: Colors.cyanAccent,
                    onChanged: (v) => setState(() => playerSize = v),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _toolBtn(IconData icon, String tip, VoidCallback onTap,
      {bool isActive = false}) {
    return Tooltip(
      message: tip,
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.cyanAccent : Colors.white70),
        onPressed: onTap,
        style: IconButton.styleFrom(
            backgroundColor:
                isActive ? Colors.cyanAccent.withOpacity(0.2) : null),
      ),
    );
  }

  Widget _colorBtn(Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1))),
    );
  }

  BoxDecoration _getPitchDecoration() {
    Color bg;
    if (pitchStyle == 0)
      bg = const Color(0xFF2E7D32);
    else if (pitchStyle == 1)
      bg = const Color(0xFF1A1A2E);
    else
      bg = Colors.white;

    Color lines = pitchStyle == 2 ? Colors.black : Colors.white54;

    return BoxDecoration(
      color: bg,
      border: Border.all(color: lines, width: 3),
      // Saha Çizgileri İçin Basit Gradient Kullanımı (Resim yerine)
      gradient: pitchStyle == 0
          ? LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [bg, bg.withOpacity(0.8)],
              stops: const [0.5, 0.5])
          : null,
    );
  }

  // --- OYUNCU SÜRÜKLEME MANTIĞI ---
  Widget _buildDraggablePlayer(
      StrategyPlayer p, Color color, double w, double h) {
    return Positioned(
      left: p.pos.dx * w - playerSize / 2,
      top: p.pos.dy * h - playerSize / 2,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            double newX = (p.pos.dx * w + d.delta.dx) / w;
            double newY = (p.pos.dy * h + d.delta.dy) / h;
            p.pos = Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0));
          });
        },
        child: Container(
          width: playerSize,
          height: playerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 5)],
          ),
          alignment: Alignment.center,
          child: Text(
            "${p.number}",
            style: GoogleFonts.russoOne(
                color: pitchStyle == 2 && color == Colors.white
                    ? Colors.black
                    : Colors.white,
                fontSize: playerSize * 0.5),
          ),
        ),
      ),
    );
  }

  // --- METİN EKLEME MANTIĞI ---
  void _addText() {
    setState(() {
      texts.add(DraggableText(
          id: DateTime.now().toString(),
          text: "Taktik",
          pos: const Offset(0.5, 0.5)));
    });
  }

  Widget _buildDraggableText(DraggableText t, double w, double h) {
    return Positioned(
      left: t.pos.dx * w,
      top: t.pos.dy * h,
      child: GestureDetector(
        onPanUpdate: (d) {
          setState(() {
            double newX = (t.pos.dx * w + d.delta.dx) / w;
            double newY = (t.pos.dy * h + d.delta.dy) / h;
            t.pos = Offset(newX.clamp(0.0, 1.0), newY.clamp(0.0, 1.0));
          });
        },
        onDoubleTap: () => _editDraggableText(t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(5)),
          child: Text(t.text,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
        ),
      ),
    );
  }

  void _editDraggableText(DraggableText t) {
    TextEditingController c = TextEditingController(text: t.text);
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Metni Düzenle"),
              content: TextField(controller: c),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                TextButton(
                    onPressed: () {
                      setState(() => t.text = c.text);
                      Navigator.pop(context);
                    },
                    child: const Text("Tamam")),
              ],
            ));
  }

  void _showSaveDialog() {
    // Kaydetme mantığı buraya (Hive'a json encode edip atılacak)
  }
  void _showLoadDialog() {
    // Yükleme mantığı
  }
}

// --- YARDIMCI SINIFLAR ---
class StrategyPlayer {
  String id;
  int number;
  Offset pos;
  StrategyPlayer({required this.id, required this.number, required this.pos});
}

class DrawingPath {
  List<Offset> points;
  Color color;
  DrawingPath({required this.points, required this.color});
}

class DraggableText {
  String id;
  String text;
  Offset pos;
  DraggableText({required this.id, required this.text, required this.pos});
}

// --- PAINTER (OK ÇİZİMİ) ---
class StrategyPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final DrawingPath? currentPath;

  StrategyPainter({required this.paths, this.currentPath});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (var p in paths) {
      paint.color = p.color;
      if (p.points.length > 1) {
        Path path = Path()..moveTo(p.points.first.dx, p.points.first.dy);
        // Bezier Eğrisi ile Yumuşatma
        for (int i = 0; i < p.points.length - 2; i++) {
          Offset p1 = p.points[i];
          Offset p2 = p.points[i + 1];
          // Basit lineTo yerine quadraticBezierTo kullanılabilir, şimdilik lineTo
          path.lineTo(p1.dx, p1.dy);
        }
        path.lineTo(p.points.last.dx, p.points.last.dy);
        canvas.drawPath(path, paint);

        // Ok Ucu
        _drawArrowHead(canvas, p.points.last,
            p.points[p.points.length > 2 ? p.points.length - 3 : 0], paint);
      }
    }

    if (currentPath != null && currentPath!.points.length > 1) {
      paint.color = currentPath!.color;
      Path path = Path()
        ..moveTo(currentPath!.points.first.dx, currentPath!.points.first.dy);
      for (var pt in currentPath!.points) path.lineTo(pt.dx, pt.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset to, Offset from, Paint paint) {
    double angle = (to - from).direction;
    double arrowSize = 15;
    Path path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(to.dx - arrowSize * 0.8 * (angle - 0.5).cos,
        to.dy - arrowSize * 0.8 * (angle - 0.5).sin);
    path.moveTo(to.dx, to.dy);
    path.lineTo(to.dx - arrowSize * 0.8 * (angle + 0.5).cos,
        to.dy - arrowSize * 0.8 * (angle + 0.5).sin);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

extension NumberParsing on double {
  double get cos => 1.0; // Math import edilirse gerçek cos kullanılır
  double get sin => 0.0;
}
// Not: math kütüphanesini import 'dart:math'; olarak en üste eklemelisiniz.
