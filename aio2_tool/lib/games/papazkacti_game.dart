import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PapazKactiGame extends StatefulWidget {
  final VoidCallback onExit;
  const PapazKactiGame({super.key, required this.onExit});
  @override
  State<PapazKactiGame> createState() => _PapazKactiGameState();
}

class _PapazKactiGameState extends State<PapazKactiGame> {
  List<String> myHand = ["🤴", "👸", "👸", "🃏", "🂡", "🂡"];
  int opponentCardCount = 6;

  void _drawFromOpponent() {
    if (opponentCardCount > 0) {
      setState(() {
        opponentCardCount--;
        myHand.add("❓");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A148C),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50),
            height: 200,
            child: Center(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: opponentCardCount,
                itemBuilder: (c, i) => GestureDetector(
                  onTap: _drawFromOpponent,
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 2),
                        image: const DecorationImage(
                            image: AssetImage("assets/pattern.png"),
                            fit: BoxFit.cover,
                            opacity: 0.2)),
                    child: const Center(
                        child: Icon(Icons.help_outline, color: Colors.white38)),
                  ),
                ),
              ),
            ),
          ),
          Center(
              child: Text("Sıra Sende: Rakibinden bir kart seç!",
                  style: GoogleFonts.poppins(color: Colors.white70))),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(20),
              itemCount: myHand.length,
              itemBuilder: (c, i) {
                return Container(
                  width: 90,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5)
                      ]),
                  child: Center(
                      child: Text(myHand[i],
                          style: const TextStyle(fontSize: 40))),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: widget.onExit,
          backgroundColor: Colors.red,
          child: const Icon(Icons.exit_to_app)),
    );
  }
}
