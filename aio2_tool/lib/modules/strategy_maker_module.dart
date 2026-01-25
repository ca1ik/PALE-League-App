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

  // Oyuncular (Pozisyonları)
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
      StrategyPlayer(id: "t1_1", number: 1, pos: const Offset(0.1, 0.5)),
      StrategyPlayer(id: "t1_3", number: 3, pos: const Offset(0.25, 0.3)),
      StrategyPlayer(id: "t1_6", number: 6, pos: const Offset(0.25, 0.7)),
      StrategyPlayer(id: "t1_10", number: 10, pos: const Offset(0.45, 0.5)),
      StrategyPlayer(id: "t1_7", number: 7, pos: const Offset(0.6, 0.2)),
      StrategyPlayer(id: "t1_11", number: 11, pos: const Offset(0.6, 0.8)),
      StrategyPlayer(id: "t1_9", number: 9, pos: const Offset(0.75, 0.5)),
    ];
    
    team2 = [
      StrategyPlayer(id: "t2_1", number: 1, pos: const Offset(0.9, 0.5)),
      StrategyPlayer(id: "t2_3", number: 3, pos: const Offset(0.75, 0.3)),
      StrategyPlayer(id: "t2_6", number: 6, pos: const Offset(0.75, 0.7)),
      StrategyPlayer(id: "t2_10", number: 10, pos: const Offset(0.55, 0.5)),
      StrategyPlayer(id: "t2_7", number: 7, pos: const Offset(0.4, 0.2)),
      StrategyPlayer(id: "t2_11", number: 11, pos: const Offset(0.4, 0.8)),
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
            decoration: BoxDecoration(color: const Color(0xFF15151A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _toolBtn(Icons.rotate_90_degrees_ccw, "Yön", () => setState(() => isHorizontal = !isHorizontal)),
                _toolBtn(Icons.groups, "Rakip", () => setState(() => showOpponent = !showOpponent)),
                _toolBtn(Icons.brush, "Çizim", () => setState(() => isDrawingMode = !isDrawingMode), isActive: isDrawingMode),
                _toolBtn(Icons.title, "Yazı Ekle", _addText),
                _toolBtn(Icons.undo, "Geri Al", () { if(paths.isNotEmpty) setState(() => paths.removeLast()); }),
                _toolBtn(Icons.delete, "Temizle", () => setState(() { paths.clear(); texts.clear(); _resetPlayers(); })),
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
                    child: GestureDetector(
                      onPanStart: isDrawingMode ? (d) {
                         RenderBox box = context.findRenderObject() as RenderBox;
                         Offset local = box.globalToLocal(d.globalPosition);
                         // Düzeltme: local koordinatları aspect ratio içindeki container'a göre değil tüm ekrana göre alıyor olabilir.
                         // Basitlik için gesture detector stack içinde olacak.
                      } : null,
                      child: Stack(
                        children: [
                          // Çizim Katmanı
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: isDrawingMode ? (d) {
                                setState(() {
                                  currentPath = DrawingPath(color: arrowColor, points: [d.localPosition]);
                                });
                              } : null,
                              onPanUpdate: isDrawingMode ? (d) {
                                setState(() {
                                  currentPath?.points.add(d.localPosition);
                                });
                              } : null,
                              onPanEnd: isDrawingMode ? (d) {
                                if (currentPath != null) {
                                  setState(() {
                                    paths.add(currentPath!);
                                    currentPath = null;
                                  });
                                }
                              } : null,
                              child: CustomPaint(
                                painter: StrategyPainter(paths: paths, currentPath: currentPath),
                              ),
                            ),
                          ),

                          // Oyuncular (Takım 1)
                          ...team1.map((p) => _buildDraggablePlayer(p, team1Color)),
                          
                          // Oyuncular (Takım 2 - Opsiyonel)
                          if (showOpponent)
                             ...team2.map((p) => _buildDraggablePlayer(p, team2Color)),

                          // Yazılar
                          ...texts.map((t) => _buildDraggableText(t)),
                        ],
                      ),
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
            decoration: BoxDecoration(color: const Color(0xFF15151A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AYARLAR", style: GoogleFonts.orbitron(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text("Saha Tipi", style: GoogleFonts.poppins(color: Colors.grey)),
                  Row(
                    children: [
                      _colorBtn(Colors.green, () => setState(() => pitchStyle = 0)),
                      _colorBtn(const Color(0xFF1A1A2E), () => setState(() => pitchStyle = 1)),
                      _colorBtn(Colors.white, () => setState(() => pitchStyle = 2)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Forma Renkleri", style: GoogleFonts.poppins(color: Colors.grey)),
                  Row(
                    children: [
                      _colorBtn(Colors.red, () => setState(() => team1Color = Colors.red)),
                      _colorBtn(Colors.blue, () => setState(() => team1Color = Colors.blue)),
                      _colorBtn(Colors.orange, () => setState(() => team1Color = Colors.orange)),
                      _colorBtn(Colors.white, () => setState(() => team1Color = Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Ok Rengi", style: GoogleFonts.poppins(color: Colors.grey)),
                  Row(
                    children: [
                      _colorBtn(Colors.yellow, () => setState(() => arrowColor = Colors.yellow)),
                      _colorBtn(Colors.white, () => setState(() => arrowColor = Colors.white)),
                      _colorBtn(Colors.black, () => setState(() => arrowColor = Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text("Oyuncu Boyutu", style: GoogleFonts.poppins(color: Colors.grey)),
                  Slider(
                    value: playerSize, min: 20, max: 60, activeColor: Colors.cyanAccent,
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

  Widget _toolBtn(IconData icon, String tip, VoidCallback onTap, {bool isActive = false}) {
    return Tooltip(
      message: tip,
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.cyanAccent : Colors.white70),
        onPressed: onTap,
        style: IconButton.styleFrom(backgroundColor: isActive ? Colors.cyanAccent.withOpacity(0.2) : null),
      ),
    );
  }

  Widget _colorBtn(Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(width: 30, height: 30, margin: const EdgeInsets.all(5), decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1))),
    );
  }

  BoxDecoration _getPitchDecoration() {
    Color bg;
    if (pitchStyle == 0) bg = const Color(0xFF2E7D32); // Çim
    else if (pitchStyle == 1) bg = const Color(0xFF1A1A2E); // Koyu Taktik
    else bg = Colors.white; // Beyaz Tahta

    Color lines = pitchStyle == 2 ? Colors.black : Colors.white54;

    return BoxDecoration(
      color: bg,
      border: Border.all(color: lines, width: 3),
      // Basit Saha Çizgileri (Geliştirilebilir)
      image: pitchStyle == 0 ? const DecorationImage(image: AssetImage('assets/pitch_texture.png'), fit: BoxFit.cover, opacity: 0.3) : null,
    );