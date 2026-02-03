import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SpeedClickerGame extends StatefulWidget {
  final VoidCallback onExit;
  const SpeedClickerGame({super.key, required this.onExit});
  @override
  State<SpeedClickerGame> createState() => _SpeedClickerGameState();
}

class _SpeedClickerGameState extends State<SpeedClickerGame> {
  int score = 0;
  bool isPlaying = false;
  int timeLeft = 10;
  Timer? _timer;
  final FocusNode _gameFocus = FocusNode();

  void startGame() {
    setState(() {
      score = 0;
      timeLeft = 10;
      isPlaying = true;
    });
    FocusScope.of(context).requestFocus(_gameFocus);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          if (timeLeft > 0)
            timeLeft--;
          else {
            isPlaying = false;
            t.cancel();
          }
        });
      } else {
        t.cancel();
      }
    });
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (!isPlaying) return;
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyX) {
      setState(() => score++);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _gameFocus,
      onKey: _handleKeyPress,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("SKOR: $score",
                  style: GoogleFonts.russoOne(
                      fontSize: 80, color: Colors.cyanAccent)),
              Text("SÜRE: $timeLeft",
                  style:
                      GoogleFonts.orbitron(color: Colors.amber, fontSize: 40)),
              const SizedBox(height: 50),
              if (!isPlaying)
                ElevatedButton(
                    onPressed: startGame,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 20)),
                    child: const Text("BAŞLA",
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)))
              else
                Column(children: [
                  const Text("Klavyedeki 'X' tuşuna bas!",
                      style: TextStyle(color: Colors.white54, fontSize: 20)),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                      duration: const Duration(milliseconds: 50),
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.red.withOpacity(0.8),
                                blurRadius: score % 2 == 0 ? 30 : 10)
                          ]),
                      child: const Center(
                          child: Text("X",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold))))
                ]),
              const SizedBox(height: 50),
              TextButton(
                  onPressed: widget.onExit,
                  child: const Text("ÇIKIŞ",
                      style: TextStyle(color: Colors.white30)))
            ],
          ),
        ),
      ),
    );
  }
}
