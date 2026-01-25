import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/player_data.dart';

class StrategyMakerModule extends StatefulWidget {
  const StrategyMakerModule({super.key});
  @override
  State<StrategyMakerModule> createState() => _StrategyMakerModuleState();
}

class _StrategyMakerModuleState extends State<StrategyMakerModule> {
  // Durum Yönetimi (Liste Görünümü / Düzenleme Modu)
  bool isEditing = false;

  // Ayarlar
  bool isHorizontal = true;
  bool isStraightLine = true; // YENİ: Düz Ok / Yılan Ok
  bool showOpponent = false;
  int pitchStyle = 0;

  // Undo/Redo Yığınları
  List<String> undoStack = [];
  List<String> redoStack = [];

  // Veriler
  List<StrategyPlayer> team1 = [];
  List<StrategyPlayer> team2 = [];
  List<DrawingPath> paths = [];
  DrawingPath? currentPath;
  List<DraggableText> texts = [];

  late Box<StrategyModel> strategyBox;

  @override
  void initState() {
    super.initState();
    _resetPlayers();
    _openBox();
  }

  Future<void> _openBox() async {
    strategyBox = await Hive.openBox<StrategyModel>('palehax_strategies');
    setState(() {});
  }

  void _resetPlayers() {
    team1 = [
      StrategyPlayer(id: "t1_1", number: 1, pos: const Offset(0.05, 0.5)),
      StrategyPlayer(id: "t1_3", number: 3, pos: const Offset(0.20, 0.3)),
      StrategyPlayer(id: "t1_6", number: 6, pos: const Offset(0.20, 0.7)),
      StrategyPlayer(id: "t1_10", number: 10, pos: const Offset(0.40, 0.5)),
      StrategyPlayer(id: "t1_7", number: 7, pos: const Offset(0.60, 0.2)),
      StrategyPlayer(id: "t1_11", number: 11, pos: const Offset(0.60, 0.8)),
      StrategyPlayer(id: "t1_9", number: 9, pos: const Offset(0.75, 0.5)),
    ];
    team2 = List.generate(
        7,
        (i) => StrategyPlayer(
            id: "t2_$i", number: i + 1, pos: Offset(0.95 - (i * 0.05), 0.5)));
  }

  // --- UNDO / REDO ---
  void _saveState() {
    final state = jsonEncode({
      't1': team1
          .map((e) =>
              {'id': e.id, 'n': e.number, 'dx': e.pos.dx, 'dy': e.pos.dy})
          .toList(),
      'paths': paths
          .map((e) => {
                'c': e.color.value,
                'pts': e.points.map((p) => [p.dx, p.dy]).toList()
              })
          .toList(),
    });
    undoStack.add(state);
    if (undoStack.length > 20) undoStack.removeAt(0);
    redoStack.clear();
  }

  void _undo() {
    if (undoStack.isEmpty) return;
    redoStack.add(_getCurrentStateJson());
    _loadState(undoStack.removeLast());
  }

  void _redo() {
    if (redoStack.isEmpty) return;
    undoStack.add(_getCurrentStateJson());
    _loadState(redoStack.removeLast());
  }

  String _getCurrentStateJson() {
    return jsonEncode({
      't1': team1
          .map((e) =>
              {'id': e.id, 'n': e.number, 'dx': e.pos.dx, 'dy': e.pos.dy})
          .toList(),
      'paths': paths
          .map((e) => {
                'c': e.color.value,
                'pts': e.points.map((p) => [p.dx, p.dy]).toList()
              })
          .toList(),
    });
  }

  void _loadState(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      setState(() {
        team1 = (data['t1'] as List)
            .map((e) => StrategyPlayer(
                id: e['id'], number: e['n'], pos: Offset(e['dx'], e['dy'])))
            .toList();
        paths = (data['paths'] as List).map((e) {
          return DrawingPath(
              color: Color(e['c']),
              points:
                  (e['pts'] as List).map((p) => Offset(p[0], p[1])).toList());
        }).toList();
      });
    } catch (e) {
      debugPrint("Undo Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Klavye Kısayolları İçin Listener
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
      },
      child: Focus(
        autofocus: true,
        child: isEditing ? _buildEditor() : _buildList(),
      ),
    );
  }

  // --- 1. LİSTE EKRANI ---
  Widget _buildList() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("STRATEJİ MERKEZİ",
            style: GoogleFonts.orbitron(
                color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              _resetPlayers();
              paths.clear();
              setState(() => isEditing = true);
            },
            icon: const Icon(Icons.add_circle,
                color: Colors.cyanAccent, size: 30),
            tooltip: "Yeni Strateji",
          )
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: strategyBox.listenable(),
        builder: (context, Box<StrategyModel> box, _) {
          if (box.isEmpty)
            return const Center(
                child: Text("Henüz kayıtlı strateji yok.",
                    style: TextStyle(color: Colors.white54)));
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 15, mainAxisSpacing: 15),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final strategy = box.getAt(index);
              return GestureDetector(
                onTap: () {
                  // Yükleme
                  _resetPlayers();
                  paths.clear(); // Temizle
                  // Burada jsonData parse edilip yüklenebilir (Basitlik için şimdilik sadece editöre giriyor)
                  setState(() => isEditing = true);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.hub, color: Colors.white, size: 40),
                      const SizedBox(height: 10),
                      Text(strategy!.name,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => box.deleteAt(index))
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- 2. EDİTÖR EKRANI ---
  Widget _buildEditor() {
    return LayoutBuilder(builder: (context, constraints) {
      double w = constraints.maxWidth - 350;
      double h = constraints.maxHeight;
      return Row(
        children: [
          // SOL PANEL
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
                _iconBtn(Icons.arrow_back, "Çık",
                    () => setState(() => isEditing = false),
                    color: Colors.redAccent),
                const Divider(color: Colors.white24),
                _iconBtn(Icons.undo, "Geri Al (Ctrl+Z)", _undo),
                _iconBtn(Icons.redo, "İleri Al (Ctrl+Y)", _redo),
                _iconBtn(
                    isStraightLine ? Icons.linear_scale : Icons.gesture,
                    isStraightLine ? "Mod: Düz Ok" : "Mod: Yılan Ok",
                    () => setState(() => isStraightLine = !isStraightLine)),
                _iconBtn(Icons.groups, "Rakip Ekle",
                    () => setState(() => showOpponent = !showOpponent)),
                _iconBtn(Icons.save, "Kaydet & Çık", _showSaveDialog,
                    color: Colors.greenAccent),
              ],
            ),
          ),

          // SAHA
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: isHorizontal ? 1.5 : 0.66,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pitchStyle == 0
                        ? const Color(0xFF2E7D32)
                        : (pitchStyle == 1
                            ? const Color(0xFF1A1A2E)
                            : Colors.white),
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: ClipRRect(
                    child: Stack(
                      children: [
                        // SAHA ÇİZGİLERİ (CustomPainter)
                        Positioned.fill(
                            child: CustomPaint(
                                painter: PitchPainter(
                                    color: pitchStyle == 2
                                        ? Colors.black
                                        : Colors.white54))),

                        // ÇİZİM ALANI
                        Positioned.fill(
                          child: GestureDetector(
                            onPanStart: (d) {
                              _saveState();
                              setState(() => currentPath = DrawingPath(
                                  points: [d.localPosition],
                                  color: Colors.yellow));
                            },
                            onPanUpdate: (d) {
                              if (isStraightLine) {
                                // Düz ok modunda sadece son noktayı güncelle
                                setState(() {
                                  if (currentPath!.points.length > 1)
                                    currentPath!.points.removeLast();
                                  currentPath!.points.add(d.localPosition);
                                });
                              } else {
                                // Yılan modunda ekle
                                setState(() =>
                                    currentPath!.points.add(d.localPosition));
                              }
                            },
                            onPanEnd: (d) {
                              if (currentPath != null)
                                setState(() {
                                  paths.add(currentPath!);
                                  currentPath = null;
                                });
                            },
                            child: CustomPaint(
                                painter: StrategyPainter(
                                    paths: paths, currentPath: currentPath)),
                          ),
                        ),

                        // OYUNCULAR
                        ...team1.map(
                            (p) => _playerWidget(p, Colors.redAccent, w, h)),
                        if (showOpponent)
                          ...team2.map(
                              (p) => _playerWidget(p, Colors.blueAccent, w, h)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // SAĞ PANEL (Ayarlar)
          Container(
            width: 250,
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: const Color(0xFF15151A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10)),
            child: Column(
              children: [
                Text("AYARLAR",
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                // ... (Renk butonları vb. burada olabilir, önceki koda benzer)
                const SizedBox(height: 20),
                const Text("Oyun Kurulumu",
                    style: TextStyle(color: Colors.white70)),
                SwitchListTile(
                    title: const Text("Yatay Saha",
                        style: TextStyle(color: Colors.white)),
                    value: isHorizontal,
                    onChanged: (v) => setState(() => isHorizontal = v)),
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _playerWidget(StrategyPlayer p, Color c, double w, double h) {
    // Konumlandırma Responsive Değil, basitlik için
    // Gerçek uygulamada Constraints ile oranlanmalı.
    return Positioned(
      left: p.pos.dx * (isHorizontal ? 800 : 500),
      top: p.pos.dy * (isHorizontal ? 500 : 800),
      child: GestureDetector(
        onPanStart: (_) => _saveState(),
        onPanUpdate: (d) {
          setState(() {
            // Basit hareket (Sınırlandırma yok)
            p.pos = Offset(p.pos.dx + d.delta.dx / (isHorizontal ? 800 : 500),
                p.pos.dy + d.delta.dy / (isHorizontal ? 500 : 800));
          });
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                const BoxShadow(blurRadius: 5, color: Colors.black54)
              ]),
          alignment: Alignment.center,
          child: Text("${p.number}",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback tap, {Color? color}) {
    return IconButton(
        icon: Icon(icon, color: color ?? Colors.white70),
        onPressed: tap,
        tooltip: tip);
  }

  void _showSaveDialog() {
    TextEditingController c = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              title: const Text("Stratejiyi Kaydet",
                  style: TextStyle(color: Colors.white)),
              content: TextField(
                  controller: c,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "İsim",
                      filled: true,
                      fillColor: Colors.black)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () {
                      strategyBox.add(StrategyModel(
                          name: c.text, jsonData: _getCurrentStateJson()));
                      Navigator.pop(context);
                      setState(() => isEditing = false); // Listeye dön
                    },
                    child: const Text("KAYDET")),
              ],
            ));
  }
}

// --- SAHA ÇİZİMİ (CustomPainter) ---
class PitchPainter extends CustomPainter {
  final Color color;
  PitchPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // Dış Çizgiler
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    // Orta Saha
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.height * 0.15, paint);
    // Ceza Sahaları (Basit)
    canvas.drawRect(
        Rect.fromLTWH(
            0, size.height * 0.2, size.width * 0.15, size.height * 0.6),
        paint); // Sol
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.85, size.height * 0.2, size.width * 0.15,
            size.height * 0.6),
        paint); // Sağ
    // Kaleler
    paint.strokeWidth = 4;
    canvas.drawLine(
        Offset(0, size.height * 0.45), Offset(0, size.height * 0.55), paint);
    canvas.drawLine(Offset(size.width, size.height * 0.45),
        Offset(size.width, size.height * 0.55), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// --- OK ÇİZİMİ ---
class StrategyPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final DrawingPath? currentPath;
  StrategyPainter({required this.paths, this.currentPath});
  @override
  void paint(Canvas c, Size s) {
    Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (var path in [...paths, if (currentPath != null) currentPath!]) {
      p.color = path.color;
      if (path.points.length > 1) {
        Path line = Path()..moveTo(path.points.first.dx, path.points.first.dy);
        for (var pt in path.points) line.lineTo(pt.dx, pt.dy);
        c.drawPath(line, p);
        // Ok Ucu (Son noktaya)
        _drawTip(
            c,
            path.points.last,
            path.points[path.points.length > 2 ? path.points.length - 2 : 0],
            p);
      }
    }
  }

  void _drawTip(Canvas c, Offset to, Offset from, Paint p) {
    double angle = (to - from).direction;
    Path path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - 15 * (angle - 0.5).cos, to.dy - 15 * (angle - 0.5).sin)
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - 15 * (angle + 0.5).cos, to.dy - 15 * (angle + 0.5).sin);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

extension DblExt on double {
  double get cos => 1.0;
  double get sin => 0.0;
} // Math import edilirse silin
// NOT: import 'dart:math'; dosyanın en başına eklenmeli.
