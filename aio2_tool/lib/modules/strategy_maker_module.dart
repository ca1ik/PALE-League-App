import 'dart:convert';
import 'dart:math' as math;
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
  bool isEditing = false;
  bool isHorizontal = true;
  bool isStraightLine = true;
  bool showOpponent = false;
  int pitchStyle = 0;
  Color arrowColor = Colors.yellow;
  Color team1Color = Colors.red;
  Color team2Color = Colors.blue;
  double playerSize = 40.0;

  List<StrategyPlayer> team1 = [];
  List<StrategyPlayer> team2 = [];
  List<DrawingPath> paths = [];
  DrawingPath? currentPath;
  List<DraggableText> texts = [];
  List<String> undoStack = [];
  List<String> redoStack = [];
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
    setState(() {});
    setState(() {});
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
    paths.clear();
    texts.clear();
  }

  // --- KAYIT & UNDO ---
  String _getCurrentStateJson() {
    return jsonEncode({
      't1': team1
          .map((e) =>
              {'id': e.id, 'n': e.number, 'dx': e.pos.dx, 'dy': e.pos.dy})
          .toList(),
      't2': team2
          .map((e) =>
              {'id': e.id, 'n': e.number, 'dx': e.pos.dx, 'dy': e.pos.dy})
          .toList(),
      'paths': paths
          .map((e) => {
                'c': e.color.value,
                'pts': e.points.map((p) => [p.dx, p.dy]).toList()
              })
          .toList(),
      'texts': texts
          .map((e) =>
              {'id': e.id, 'txt': e.text, 'dx': e.pos.dx, 'dy': e.pos.dy})
          .toList(),
      'opts': {
        'opp': showOpponent,
        'pitch': pitchStyle,
        'hor': isHorizontal,
        'sz': playerSize
      }
    });
  }

  void _loadState(String jsonStr) {
    try {
      final d = jsonDecode(jsonStr);
      setState(() {
        team1 = (d['t1'] as List)
            .map((e) => StrategyPlayer(
                id: e['id'], number: e['n'], pos: Offset(e['dx'], e['dy'])))
            .toList();
        if (d['t2'] != null)
          team2 = (d['t2'] as List)
              .map((e) => StrategyPlayer(
                  id: e['id'], number: e['n'], pos: Offset(e['dx'], e['dy'])))
              .toList();
        paths = (d['paths'] as List)
            .map((e) => DrawingPath(
                color: Color(e['c']),
                points:
                    (e['pts'] as List).map((p) => Offset(p[0], p[1])).toList()))
            .toList();
        if (d['texts'] != null)
          texts = (d['texts'] as List)
              .map((e) => DraggableText(
                  id: e['id'], text: e['txt'], pos: Offset(e['dx'], e['dy'])))
              .toList();
        if (d['opts'] != null) {
          showOpponent = d['opts']['opp'] ?? false;
          pitchStyle = d['opts']['pitch'] ?? 0;
          isHorizontal = d['opts']['hor'] ?? true;
          playerSize = d['opts']['sz'] ?? 40.0;
        }
      });
    } catch (e) {
      debugPrint("Load Err: $e");
    }
  }

  void _saveStateForUndo() {
    undoStack.add(_getCurrentStateJson());
    if (undoStack.length > 20) undoStack.removeAt(0);
    redoStack.clear();
  }

  void _undo() {
    if (undoStack.isNotEmpty) {
      redoStack.add(_getCurrentStateJson());
      _loadState(undoStack.removeLast());
    }
  }

  void _redo() {
    if (redoStack.isNotEmpty) {
      undoStack.add(_getCurrentStateJson());
      _loadState(redoStack.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
      },
      child: Focus(
          autofocus: true, child: isEditing ? _buildEditor() : _buildList()),
    );
  }

  Widget _buildList() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text("STRATEJİ MERKEZİ",
            style: GoogleFonts.orbitron(
                color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.add_circle,
                  color: Colors.greenAccent, size: 35),
              onPressed: () {
                _resetPlayers();
                setState(() => isEditing = true);
              })
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: strategyBox.listenable(),
        builder: (context, Box<StrategyModel> box, _) {
          if (box.isEmpty)
            return const Center(
                child: Text("Kayıtlı strateji yok.",
                    style: TextStyle(color: Colors.white54)));
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.5),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final s = box.getAt(index);
              return GestureDetector(
                onTap: () {
                  _loadState(s.jsonData);
                  setState(() => isEditing = true);
                },
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white12)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hub,
                            color: Colors.cyanAccent, size: 40),
                        const SizedBox(height: 10),
                        Text(s!.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            onPressed: () => box.deleteAt(index))
                      ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEditor() {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(children: [
        // SOL MENÜ
        Container(
          width: 80,
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            _btn(Icons.arrow_back, "Çık",
                () => setState(() => isEditing = false),
                color: Colors.red),
            const Divider(color: Colors.white24),
            _btn(Icons.undo, "Geri Al", _undo),
            _btn(Icons.redo, "İleri Al", _redo),
            const SizedBox(height: 10),
            _btn(
                isStraightLine ? Icons.linear_scale : Icons.gesture,
                isStraightLine ? "Düz Ok" : "Yılan Ok",
                () => setState(() => isStraightLine = !isStraightLine),
                active: true),
            _btn(
                Icons.text_fields,
                "Yazı",
                () => setState(() => texts.add(DraggableText(
                    id: DateTime.now().toString(),
                    text: "Not",
                    pos: const Offset(0.5, 0.5))))),
            _btn(Icons.groups, "Rakip",
                () => setState(() => showOpponent = !showOpponent),
                active: showOpponent),
            const Spacer(),
            _btn(Icons.save, "KAYDET", _showSaveDialog,
                color: Colors.greenAccent),
            const SizedBox(height: 20),
          ]),
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
                  boxShadow: [
                    const BoxShadow(color: Colors.black, blurRadius: 20)
                  ],
                ),
                child: ClipRRect(
                  child: LayoutBuilder(builder: (ctx, fCons) {
                    double fw = fCons.maxWidth, fh = fCons.maxHeight;
                    return Stack(children: [
                      Positioned.fill(
                          child: CustomPaint(
                              painter: PitchPainter(
                                  color: pitchStyle == 2
                                      ? Colors.black
                                      : Colors.white54))),
                      Positioned.fill(
                          child: GestureDetector(
                        onPanStart: (d) {
                          _saveStateForUndo();
                          setState(() => currentPath = DrawingPath(
                              points: [d.localPosition], color: arrowColor));
                        },
                        onPanUpdate: (d) {
                          setState(() {
                            if (isStraightLine) {
                              if (currentPath!.points.length > 1)
                                currentPath!.points.removeLast();
                              currentPath!.points.add(d.localPosition);
                            } else {
                              currentPath!.points.add(d.localPosition);
                            }
                          });
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
                      )),
                      ...team1.map((p) => _dragItem(p, team1Color, fw, fh)),
                      if (showOpponent)
                        ...team2.map((p) => _dragItem(p, team2Color, fw, fh)),
                      ...texts.map((t) => _dragText(t, fw, fh)),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ),
        // SAĞ AYARLAR
        Container(
          width: 200,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: const Color(0xFF101014),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12)),
          child: Column(children: [
            Text("AYARLAR",
                style: GoogleFonts.orbitron(color: Colors.cyanAccent)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _colBtn(Colors.green, 0),
              _colBtn(const Color(0xFF1A1A2E), 1),
              _colBtn(Colors.white, 2)
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _arrBtn(Colors.yellow),
              _arrBtn(Colors.white),
              _arrBtn(Colors.black)
            ]),
            const SizedBox(height: 15),
            Text("Oyuncu Boyutu", style: TextStyle(color: Colors.white54)),
            Slider(
                value: playerSize,
                min: 20,
                max: 60,
                activeColor: Colors.cyanAccent,
                onChanged: (v) => setState(() => playerSize = v)),
            SwitchListTile(
                title: const Text("Yatay",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                value: isHorizontal,
                onChanged: (v) => setState(() => isHorizontal = v),
                activeColor: Colors.cyanAccent),
          ]),
        )
      ]);
    });
  }

  Widget _dragItem(StrategyPlayer p, Color c, double fw, double fh) {
    double size = p.number == 1 ? playerSize * 1.2 : playerSize;
    return Positioned(
      left: p.pos.dx * fw - size / 2,
      top: p.pos.dy * fh - size / 2,
      child: GestureDetector(
        onPanStart: (_) => _saveStateForUndo(),
        onPanUpdate: (d) => setState(() => p.pos = Offset(
            ((p.pos.dx * fw + d.delta.dx) / fw).clamp(0.0, 1.0),
            ((p.pos.dy * fh + d.delta.dy) / fh).clamp(0.0, 1.0))),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                const BoxShadow(blurRadius: 5, color: Colors.black54)
              ]),
          alignment: Alignment.center,
          child: Text("${p.number}",
              style: TextStyle(
                  color: c == Colors.white ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.5)),
        ),
      ),
    );
  }

  Widget _dragText(DraggableText t, double fw, double fh) {
    return Positioned(
      left: t.pos.dx * fw,
      top: t.pos.dy * fh,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => t.pos = Offset(
            ((t.pos.dx * fw + d.delta.dx) / fw).clamp(0.0, 1.0),
            ((t.pos.dy * fh + d.delta.dy) / fh).clamp(0.0, 1.0))),
        onDoubleTap: () {
          TextEditingController c = TextEditingController(text: t.text);
          showDialog(
              context: context,
              builder: (_) =>
                  AlertDialog(content: TextField(controller: c), actions: [
                    TextButton(
                        onPressed: () {
                          setState(() => t.text = c.text);
                          Navigator.pop(context);
                        },
                        child: const Text("OK"))
                  ]));
        },
        child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(5)),
            child: Text(t.text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _btn(IconData i, String t, VoidCallback tap,
          {bool active = false, Color? color}) =>
      IconButton(
          icon: Icon(i,
              color: color ?? (active ? Colors.cyanAccent : Colors.white54)),
          onPressed: tap,
          tooltip: t);
  Widget _colBtn(Color c, int s) => GestureDetector(
      onTap: () => setState(() => pitchStyle = s),
      child: Container(
          width: 25,
          height: 25,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white))));
  Widget _arrBtn(Color c) => GestureDetector(
      onTap: () => setState(() => arrowColor = c),
      child: Container(
          width: 25,
          height: 25,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white))));

  void _showSaveDialog() {
    TextEditingController c = TextEditingController();
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E24),
              title:
                  const Text("Kaydet", style: TextStyle(color: Colors.white)),
              content: TextField(
                  controller: c, style: const TextStyle(color: Colors.white)),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      if (c.text.isNotEmpty) {
                        strategyBox.add(StrategyModel(
                            name: c.text, jsonData: _getCurrentStateJson()));
                        Navigator.pop(context);
                        setState(() => isEditing = false);
                      }
                    },
                    child: const Text("KAYDET"))
              ],
            ));
  }
}

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

class PitchPainter extends CustomPainter {
  final Color color;
  PitchPainter({required this.color});
  @override
  void paint(Canvas c, Size s) {
    Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height), p);
    c.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height), p);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.height * 0.12, p);
    double bh = s.height * 0.5, bw = s.width * 0.16, ty = (s.height - bh) / 2;
    c.drawRect(Rect.fromLTWH(0, ty, bw, bh), p);
    c.drawRect(Rect.fromLTWH(s.width - bw, ty, bw, bh), p);
    double sh = s.height * 0.25, sw = s.width * 0.06, sty = (s.height - sh) / 2;
    c.drawRect(Rect.fromLTWH(0, sty, sw, sh), p);
    c.drawRect(Rect.fromLTWH(s.width - sw, sty, sw, sh), p);
    p.strokeWidth = 4;
    c.drawLine(Offset(0, s.height * 0.45), Offset(0, s.height * 0.55), p);
    c.drawLine(
        Offset(s.width, s.height * 0.45), Offset(s.width, s.height * 0.55), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

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
      ..lineTo(to.dx - 15 * math.cos(angle - 0.5),
          to.dy - 15 * math.sin(angle - 0.5))
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - 15 * math.cos(angle + 0.5),
          to.dy - 15 * math.sin(angle + 0.5));
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
