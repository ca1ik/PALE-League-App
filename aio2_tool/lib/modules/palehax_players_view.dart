import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart'; // Az önce oluşturduğumuz veri dosyası
import '../ui/glass_box.dart'; // Cam efekti için

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});

  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  Player? selectedPlayer; // Seçili oyuncu

  @override
  void initState() {
    super.initState();
    selectedPlayer = paleHaxPlayers[0]; // İlk oyuncuyu seçili yap
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // --- SOL: OYUNCU LİSTESİ ---
        Container(
          width: 300,
          margin: const EdgeInsets.only(right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "SQUAD LIST",
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: paleHaxPlayers.length,
                  itemBuilder: (context, index) {
                    final p = paleHaxPlayers[index];
                    final isSelected = selectedPlayer == p;
                    return GestureDetector(
                      onTap: () => setState(() => selectedPlayer = p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color:
                                isSelected ? Colors.cyanAccent : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Reyting Kutusu
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                "${p.rating}",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: _getRatingColor(p.rating),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // İsim ve Mevki
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    p.position,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // --- SAĞ: OYUNCU KARTI & DETAYLAR ---
        if (selectedPlayer != null)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜST KART
                  GlassBox(
                    width: double.infinity,
                    height: 220,
                    child: Stack(
                      children: [
                        // Arka plan gradient
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black,
                                  _getRatingColor(selectedPlayer!.rating)
                                      .withOpacity(0.3)
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Row(
                            children: [
                              // Oyuncu Resmi (Circle)
                              Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white24, width: 2),
                                  image: DecorationImage(
                                    image:
                                        NetworkImage(selectedPlayer!.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              // Detaylar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "${selectedPlayer!.rating}",
                                        style: GoogleFonts.oswald(
                                          fontSize: 50,
                                          fontWeight: FontWeight.bold,
                                          color: _getRatingColor(
                                              selectedPlayer!.rating),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          border:
                                              Border.all(color: Colors.white24),
                                        ),
                                        child: Text(
                                          selectedPlayer!.position,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    selectedPlayer!.name.toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  Text(
                    "PLAYSTYLES",
                    style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // PLAYSTYLES LİSTESİ (Wrap ile)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: selectedPlayer!.playstyles.map((ps) {
                      return Tooltip(
                        message: ps.name, // Üzerine gelince isim yazar
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15151A),
                            borderRadius: BorderRadius.circular(10),
                            // SARI İSE ALTIN ÇERÇEVE
                            border: Border.all(
                              color: ps.isGold
                                  ? const Color(0xFFFFD700)
                                  : Colors.white12,
                              width: ps.isGold ? 2 : 1,
                            ),
                            boxShadow: ps.isGold
                                ? [
                                    BoxShadow(
                                        color: Colors.amber.withOpacity(0.4),
                                        blurRadius: 10)
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Resim olmadığı için ikon kullanıyoruz,
                              // Resim eklemek istersen Icon yerine Image.asset(ps.iconAsset) kullan.
                              Icon(
                                ps.isGold
                                    ? Icons.verified
                                    : Icons.circle, // GEÇİCİ İKON
                                // BURAYA RESİM GELECEK: Image.asset("assets/playstyles/${ps.name}.png", width: 20)
                                color: ps.isGold
                                    ? const Color(0xFFFFD700)
                                    : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                ps.name,
                                style: GoogleFonts.poppins(
                                  color:
                                      ps.isGold ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: ps.isGold
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          )
      ],
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 90) return const Color(0xFF00FFC2); // Turkuaz/Yeşil
    if (rating >= 85) return const Color(0xFFA6FF00); // Lime
    if (rating >= 80) return Colors.amber;
    return Colors.white;
  }
}
