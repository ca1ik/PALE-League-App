import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Okey101Game extends StatefulWidget {
  final VoidCallback onExit;
  const Okey101Game({super.key, required this.onExit});
  @override
  State<Okey101Game> createState() => _Okey101GameState();
}

class _Okey101GameState extends State<Okey101Game> {
  List<OkeyTileModel> myRack = [];

  @override
  void initState() {
    super.initState();
    _dealTiles();
  }

  void _dealTiles() {
    var rng = Random();
    List<Color> colors = [Colors.red, Colors.black, Colors.blue, Colors.orange];
    myRack = List.generate(
        21,
        (index) => OkeyTileModel(
            id: index,
            number: rng.nextInt(13) + 1,
            color: colors[rng.nextInt(4)]));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                          colors: [Colors.green[700]!, Colors.green[900]!],
                          radius: 1.2)))),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("OKEY 101",
                    style: GoogleFonts.righteous(
                        fontSize: 60, color: Colors.white24)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text(
                      "Taşları sürükleyerek dizebilirsin.\nÇift tıklayarak ters çevirebilirsin.",
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                    onPressed: _dealTiles,
                    child: const Text("TAŞLARI KARIŞTIR"))
              ],
            ),
          ),
          Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: widget.onExit)),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 140,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63),
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                      top: BorderSide(color: Colors.brown[300]!, width: 5),
                      bottom: BorderSide(color: Colors.brown[900]!, width: 5)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 5))
                  ]),
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = myRack.removeAt(oldIndex);
                    myRack.insert(newIndex, item);
                  });
                },
                children: myRack.map((tile) => _buildTile(tile)).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTile(OkeyTileModel tile) {
    return GestureDetector(
      key: ValueKey(tile.id),
      onDoubleTap: () => setState(() => tile.isFaceUp = !tile.isFaceUp),
      child: Container(
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(2, 2))
            ]),
        child: Center(
          child: tile.isFaceUp
              ? Text("${tile.number}",
                  style: GoogleFonts.russoOne(fontSize: 28, color: tile.color))
              : const Icon(Icons.circle, size: 10, color: Colors.orangeAccent),
        ),
      ),
    );
  }
}

class OkeyTileModel {
  final int id;
  final int number;
  final Color color;
  bool isFaceUp;
  OkeyTileModel(
      {required this.id,
      required this.number,
      required this.color,
      this.isFaceUp = true});
}
