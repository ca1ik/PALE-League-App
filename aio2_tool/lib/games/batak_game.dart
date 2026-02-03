import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BatakGame extends StatefulWidget {
  final VoidCallback onExit;
  const BatakGame({super.key, required this.onExit});
  @override
  State<BatakGame> createState() => _BatakGameState();
}

class _BatakGameState extends State<BatakGame> {
  int bid = 0;
  bool biddingPhase = true;
  List<String> myHand = [
    "♠A",
    "♠K",
    "♥Q",
    "♦10",
    "♣5",
    "♠7",
    "♥2",
    "♦A",
    "♣K",
    "♠10",
    "♠2",
    "♥5",
    "♦Q"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      body: Stack(
        children: [
          Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: widget.onExit)),
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12, width: 2)),
              child: Center(
                child: biddingPhase
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Text("İHALE: ${bid == 0 ? '?' : bid}",
                            style: GoogleFonts.rye(
                                fontSize: 40, color: Colors.amber)),
                        const SizedBox(height: 10),
                        if (bid > 0)
                          ElevatedButton(
                              onPressed: () =>
                                  setState(() => biddingPhase = false),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber),
                              child: const Text("BAŞLA",
                                  style: TextStyle(color: Colors.black)))
                      ])
                    : const Icon(Icons.spades, size: 80, color: Colors.black26),
              ),
            ),
          ),
          if (biddingPhase)
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [4, 5, 6, 7, 8, 9, 10, 11]
                        .map((val) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: ActionChip(
                                label: Text("$val"),
                                backgroundColor:
                                    bid == val ? Colors.amber : Colors.white,
                                onPressed: () => setState(() => bid = val),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: -30,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: myHand.length,
                itemBuilder: (c, i) {
                  return Align(
                    alignment: Alignment.topCenter,
                    widthFactor: 0.6,
                    child: GestureDetector(
                      onTap: () {
                        if (!biddingPhase) setState(() => myHand.removeAt(i));
                      },
                      child: _buildClassicCard(myHand[i]),
                    ),
                  );
                },
              ),
            ),
          ),
          const Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Icon(Icons.person, color: Colors.white, size: 40)),
          const Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Icon(Icons.person, color: Colors.white, size: 40)),
          const Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Icon(Icons.person, color: Colors.white, size: 40)),
        ],
      ),
    );
  }

  Widget _buildClassicCard(String text) {
    bool isRed = text.contains("♥") || text.contains("♦");
    return Container(
      width: 90,
      height: 130,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
          boxShadow: const [
            BoxShadow(
                color: Colors.black54, blurRadius: 5, offset: Offset(2, 2))
          ]),
      child: Center(
          child: Text(text,
              style: GoogleFonts.rye(
                  fontSize: 24, color: isRed ? Colors.red : Colors.black))),
    );
  }
}
