import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- YENİ KLASÖR YAPISINA GÖRE IMPORTLAR ---
import 'games/okey101_game.dart';
import 'games/uno_game.dart';
import 'games/batak_game.dart';
import 'games/papazkacti_game.dart';
import 'games/speed_clicker_game.dart';
import 'games/vampire_villager.dart'; // Vampir Köylü de games klasöründe

class GamesHubView extends StatefulWidget {
  const GamesHubView({super.key});
  @override
  State<GamesHubView> createState() => _GamesHubViewState();
}

class _GamesHubViewState extends State<GamesHubView> {
  String activeGame = ""; // Hangi oyunun açık olduğunu tutar

  @override
  Widget build(BuildContext context) {
    // Seçilen oyuna göre ilgili dosyayı açar
    if (activeGame == "OKEY 101") return Okey101Game(onExit: _exitGame);
    if (activeGame == "UNO") return UnoGame(onExit: _exitGame);
    if (activeGame == "BATAK") return BatakGame(onExit: _exitGame);
    if (activeGame == "PAPAZ KAÇTI") return PapazKactiGame(onExit: _exitGame);
    if (activeGame == "SPEED CLICKER")
      return SpeedClickerGame(onExit: _exitGame);

    // Eğer oyun seçilmemişse Ana Menüyü göster
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("PALEHAX GAME HUB",
            style: GoogleFonts.orbitron(
                color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Eğer sidebar kullanıyorsan burası boş kalabilir veya sidebar kontrolü eklenebilir
          },
        ),
      ),
      body: _buildGameMenu(),
    );
  }

  // Oyundan çıkıp menüye dönme fonksiyonu
  void _exitGame() {
    setState(() => activeGame = "");
  }

  Widget _buildGameMenu() {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(30),
      crossAxisSpacing: 30,
      mainAxisSpacing: 30,
      children: [
        _gameCard("SPEED CLICKER", Icons.touch_app, Colors.blue, true),
        _gameCard("OKEY 101", Icons.apps, Colors.orange, true),
        _gameCard("UNO", Icons.style, Colors.red, true),
        _gameCard("BATAK", Icons.spades, Colors.green, true),
        _gameCard("VAMPİR KÖYLÜ", Icons.nightlight_round, Colors.purple, true),
        _gameCard("PAPAZ KAÇTI", Icons.person_off, Colors.pink, true),
      ],
    );
  }

  Widget _gameCard(String title, IconData icon, Color color, bool isActive) {
    return GestureDetector(
      onTap: () {
        // Vampir Köylü özel bir sayfa olduğu için Navigator ile açıyoruz
        if (title == "VAMPİR KÖYLÜ") {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const VampireVillagerGame()));
          return;
        }

        // Diğer oyunlar widget değişimi ile açılıyor
        if (isActive) {
          setState(() => activeGame = title);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Bu oyun yapım aşamasında!")));
        }
      },
      child: Container(
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2)
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 15),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.russoOne(color: Colors.white, fontSize: 18)),
            if (!isActive)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
}
