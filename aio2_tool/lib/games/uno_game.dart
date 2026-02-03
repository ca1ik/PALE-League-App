import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnoGame extends StatefulWidget {
  final VoidCallback onExit;
  const UnoGame({super.key, required this.onExit});
  @override
  State<UnoGame> createState() => _UnoGameState();
}

class _UnoGameState extends State<UnoGame> {
  List<UnoCardModel> myHand = [];
  UnoCardModel? centerCard;

  @override
  void initState() {
    super.initState();
    _dealCards();
  }

  void _dealCards() {
    var rng = Random();
    List<Color> colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
    myHand = List.generate(
        7,
        (i) => UnoCardModel(
            color: colors[rng.nextInt(4)], value: "${rng.nextInt(9)}"));
    centerCard =
        UnoCardModel(color: colors[rng.nextInt(4)], value: "${rng.nextInt(9)}");
    setState(() {});
  }

  void _playCard(UnoCardModel card) {
    if (card.color == centerCard!.color || card.value == centerCard!.value) {
      setState(() {
        myHand.remove(card);
        centerCard = card;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Bu kartı oynayamazsın!",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      body: Stack(
        children: [
          Positioned.fill(
              child: Opacity(
                  opacity: 0.1,
                  child: Image.asset("assets/takimlar/palehax.png",
                      repeat: ImageRepeat.repeat,
                      errorBuilder: (c, e, s) => Container()))),
          Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: widget.onExit)),
          Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      7,
                      (i) => Container(
                          margin: const EdgeInsets.all(2),
                          width: 40,
                          height: 60,
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: Colors.white)))))),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCardUI(centerCard!, scale: 1.5),
                const SizedBox(width: 50),
                GestureDetector(
                  onTap: () => setState(() => myHand
                      .add(UnoCardModel(color: Colors.yellow, value: "+2"))),
                  child: Container(
                      width: 80,
                      height: 120,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 3)),
                      child: const Center(
                          child: Text("UNO",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)))),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 150,
              child: Center(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  children: myHand
                      .map((card) => Draggable<UnoCardModel>(
                            data: card,
                            feedback: Transform.rotate(
                                angle: -0.1,
                                child: _buildCardUI(card, scale: 1.1)),
                            childWhenDragging: Opacity(
                                opacity: 0.3, child: _buildCardUI(card)),
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: _buildCardUI(card)),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
          Center(
            child: DragTarget<UnoCardModel>(
              onAccept: (card) => _playCard(card),
              builder: (context, candidates, rejected) {
                return Container(
                    width: 150, height: 200, color: Colors.transparent);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCardUI(UnoCardModel card, {double scale = 1.0}) {
    return Container(
      width: 80 * scale,
      height: 120 * scale,
      decoration: BoxDecoration(
          color: card.color,
          borderRadius: BorderRadius.circular(10 * scale),
          border: Border.all(color: Colors.white, width: 4 * scale),
          boxShadow: [
            BoxShadow(
                color: Colors.black45,
                blurRadius: 5 * scale,
                offset: Offset(2 * scale, 2 * scale))
          ]),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              width: 50 * scale,
              height: 90 * scale,
              transform: Matrix4.rotationZ(0.4),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24, width: 2),
                  borderRadius: BorderRadius.circular(40))),
          Text(card.value,
              style: GoogleFonts.permanentMarker(
                  fontSize: 40 * scale,
                  color: Colors.white,
                  shadows: [const Shadow(color: Colors.black, blurRadius: 2)]))
        ],
      ),
    );
  }
}

class UnoCardModel {
  final Color color;
  final String value;
  UnoCardModel({required this.color, required this.value});
}
