import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class GamesHubView extends StatefulWidget {
  const GamesHubView({super.key});
  @override
  State<GamesHubView> createState() => _GamesHubViewState();
}

class _GamesHubViewState extends State<GamesHubView> {
  String activeGame = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("PALEHAX GAME HUB",
            style: GoogleFonts.orbitron(
                color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
      ),
      body: activeGame.isEmpty ? _buildGameMenu() : _buildActiveGameLobby(),
    );
  }

  Widget _buildGameMenu() {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      children: [
        _gameCard("SPEED CLICKER", Icons.touch_app, Colors.blue, true),
        _gameCard("OKEY 101", Icons.table_restaurant, Colors.green, false),
        _gameCard("UNO", Icons.style, Colors.red, false),
        _gameCard("BATAK", Icons.videogame_asset, Colors.grey, false),
        _gameCard("VAMPİR KÖYLÜ", Icons.nightlight_round, Colors.purple, false),
        _gameCard("PAPAZ KAÇTI", Icons.person_off, Colors.orange, false),
        _gameCard("VAMPİR KÖYLÜ", Icons.nightlight_round, Colors.purple,
            true), // true yaptık        _gameCard("PAPAZ KAÇTI", Icons.person_off, Colors.orange, false),
      ],
    );
  }

  Widget _gameCard(String title, IconData icon, Color color, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (isActive) {
          setState(() => activeGame = title);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bu oyun henüz yapım aşamasında!")));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(title,
                style: GoogleFonts.russoOne(color: Colors.white, fontSize: 16)),
            if (!isActive)
              Container(
                margin: const EdgeInsets.only(top: 5), // DÜZELTİLDİ
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(5)),
                child: const Text("YAKINDA",
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGameLobby() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.blueAccent.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$activeGame LOBİSİ",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => setState(() => activeGame = "")),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.black12,
                  child: ListView(
                    children: [
                      _roomItem("Oda #123", "3/4", true),
                      _roomItem("PaleHax Turnuva", "1/10", false),
                      ListTile(
                        leading: const Icon(Icons.add_circle,
                            color: Colors.greenAccent),
                        title: const Text("Oda Kur",
                            style: TextStyle(color: Colors.greenAccent)),
                        onTap: () {},
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: _SpeedClickerGame(),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _roomItem(String name, String count, bool locked) {
    return ListTile(
      leading: Icon(locked ? Icons.lock : Icons.lock_open,
          color: locked ? Colors.red : Colors.green),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: Text(count, style: const TextStyle(color: Colors.white54)),
      onTap: () {},
    );
  }
}

class _SpeedClickerGame extends StatefulWidget {
  @override
  State<_SpeedClickerGame> createState() => _SpeedClickerGameState();
}

class _SpeedClickerGameState extends State<_SpeedClickerGame> {
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
          if (timeLeft > 0) {
            timeLeft--;
          } else {
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
      setState(() {
        score++;
      });
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("SKOR: $score",
              style: GoogleFonts.russoOne(fontSize: 60, color: Colors.white)),
          Text("SÜRE: $timeLeft",
              style: const TextStyle(color: Colors.amber, fontSize: 30)),
          const SizedBox(height: 30),
          if (!isPlaying)
            ElevatedButton(
                onPressed: startGame,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20)),
                child: const Text("BAŞLA (X ile Oyna)",
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))
          else
            Column(
              children: [
                const Text("Klavyedeki 'X' tuşuna bas!",
                    style: TextStyle(color: Colors.white, fontSize: 20)),
                const SizedBox(height: 20),
                Container(
                  width: 150,
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.5), blurRadius: 20)
                      ]),
                  child: const Text("X",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 80,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            )
        ],
      ),
    );
  }
}
