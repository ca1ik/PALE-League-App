import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/player_data.dart';
import '../ui/glass_box.dart';

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});

  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  Player? selectedPlayer;
  late Box<Player> playerBox;

  @override
  void initState() {
    super.initState();
    playerBox = Hive.box<Player>('palehax_players');
    if (playerBox.isNotEmpty) {
      selectedPlayer = playerBox.getAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlayerDialog,
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("Oyuncu Oluştur",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder(
        valueListenable: playerBox.listenable(),
        builder: (context, Box<Player> box, _) {
          final players = box.values.toList();

          if (players.isEmpty) {
            return const Center(
                child: Text("Oyuncu bulunamadı.",
                    style: TextStyle(color: Colors.white)));
          }

          // Seçili oyuncu silindiyse veya null ise ilkini seç
          if (selectedPlayer == null || !players.contains(selectedPlayer)) {
            if (players.isNotEmpty) selectedPlayer = players.first;
          }

          return Row(
            children: [
              // --- SOL: LİSTE ---
              Container(
                width: 300,
                margin: const EdgeInsets.only(right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SQUAD LIST",
                        style: GoogleFonts.orbitron(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                            letterSpacing: 2)),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final p = players[index];
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
                                    color: isSelected
                                        ? Colors.cyanAccent
                                        : Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(5)),
                                    child: Text("${p.rating}",
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: _getRatingColor(p.rating),
                                            fontSize: 16)),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                            overflow: TextOverflow.ellipsis),
                                        Text(p.position,
                                            style: GoogleFonts.poppins(
                                                color: Colors.white54,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  // Silme butonu (İsteğe bağlı)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.white24, size: 18),
                                    onPressed: () {
                                      box.deleteAt(index);
                                      if (players.isEmpty)
                                        setState(() => selectedPlayer = null);
                                    },
                                  )
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

              // --- SAĞ: DETAYLAR ---
              if (selectedPlayer != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassBox(
                          width: double.infinity,
                          height: 240,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black,
                                        _getRatingColor(selectedPlayer!.rating)
                                            .withOpacity(0.2)
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
                                    // --- PROFİL RESMİ (FORMA NUMARASI) ---
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black, // Simsiyah zemin
                                          border: Border.all(
                                              color: _getRatingColor(
                                                  selectedPlayer!.rating),
                                              width: 4),
                                          boxShadow: [
                                            BoxShadow(
                                                color: _getRatingColor(
                                                        selectedPlayer!.rating)
                                                    .withOpacity(0.5),
                                                blurRadius: 20)
                                          ]),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "${selectedPlayer!.kitNumber}",
                                        style: GoogleFonts.russoOne(
                                          fontSize: 80,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Text("${selectedPlayer!.rating}",
                                                style: GoogleFonts.oswald(
                                                    fontSize: 50,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getRatingColor(
                                                        selectedPlayer!
                                                            .rating))),
                                            const SizedBox(width: 15),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                  border: Border.all(
                                                      color: Colors.white24)),
                                              child: Text(
                                                  selectedPlayer!.position,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 20)),
                                            ),
                                          ],
                                        ),
                                        Text(selectedPlayer!.name.toUpperCase(),
                                            style: GoogleFonts.orbitron(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.5)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text("PLAYSTYLES",
                            style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                letterSpacing: 2,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        // PLAYSTYLE GÖSTERİMİ
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: selectedPlayer!.playstyles.map((ps) {
                            return Tooltip(
                              message:
                                  ps.name + (ps.isGold ? " (PlayStyle+)" : ""),
                              child: Container(
                                width: 50,
                                height: 50,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15151A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: ps.isGold
                                          ? const Color(0xFFFFD700)
                                          : Colors.white12,
                                      width: ps.isGold ? 2 : 1),
                                  boxShadow: ps.isGold
                                      ? [
                                          BoxShadow(
                                              color:
                                                  Colors.amber.withOpacity(0.4),
                                              blurRadius: 10)
                                        ]
                                      : [],
                                ),
                                child: Image.asset(
                                  ps.assetPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.help_outline,
                                          color: Colors.white24),
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
        },
      ),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 90) return const Color(0xFF00FFC2);
    if (rating >= 85) return const Color(0xFFA6FF00);
    if (rating >= 80) return Colors.amber;
    return Colors.white;
  }

  // --- OYUNCU OLUŞTURMA PANELİ ---
  void _showCreatePlayerDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreatePlayerDialog(),
    );
  }
}

class CreatePlayerDialog extends StatefulWidget {
  const CreatePlayerDialog({super.key});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  final _nameController = TextEditingController();
  final _ratingController = TextEditingController();
  String _selectedPosition = "ST";

  // Seçilen Playstyle'lar (Adı -> Gold mu?)
  final Map<String, bool> _selectedPlayStyles = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101014),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24)),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("OYUNCU OLUŞTUR",
                style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İsim ve Reyting
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDec("Oyuncu Adı"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _ratingController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: _inputDec("Reyting"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Mevki Seçimi
                    Text("Mevki",
                        style: GoogleFonts.poppins(color: Colors.grey)),
                    Wrap(
                      spacing: 8,
                      children: availablePositions.map((pos) {
                        final isSelected = _selectedPosition == pos;
                        return ChoiceChip(
                          label: Text(pos),
                          selected: isSelected,
                          onSelected: (val) =>
                              setState(() => _selectedPosition = pos),
                          selectedColor: Colors.cyanAccent,
                          labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white),
                          backgroundColor: Colors.white10,
                        );
                      }).toList(),
                    ),

                    const Divider(color: Colors.white24, height: 30),

                    // PlayStyles Seçimi
                    Text("PlayStyles (Tıkla Seç, Çift Tıkla Gold Yap)",
                        style: GoogleFonts.poppins(color: Colors.cyanAccent)),
                    const SizedBox(height: 5),
                    Text(
                        "Tek Tık: Gümüş | Uzun Bas: Altın | Tekrar Tık: Kaldır",
                        style: GoogleFonts.poppins(
                            color: Colors.grey, fontSize: 10)),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availablePlayStyles.map((psName) {
                        final isSelected =
                            _selectedPlayStyles.containsKey(psName);
                        final isGold =
                            isSelected && _selectedPlayStyles[psName] == true;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPlayStyles.remove(psName);
                              } else {
                                _selectedPlayStyles[psName] =
                                    false; // Gümüş ekle
                              }
                            });
                          },
                          onLongPress: () {
                            setState(() {
                              _selectedPlayStyles[psName] = true; // Altın yap
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: isSelected
                                    ? (isGold
                                        ? Colors.amber.withOpacity(0.2)
                                        : Colors.white24)
                                    : Colors.transparent,
                                border: Border.all(
                                    color: isSelected
                                        ? (isGold ? Colors.amber : Colors.white)
                                        : Colors.white12,
                                    width: isGold ? 2 : 1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              children: [
                                Image.asset(
                                  // Önizleme için asset yolunu oluşturuyoruz
                                  "assets/Playstyles/${isGold ? "${psName}Plus" : psName}.png",
                                  width: 30, height: 30,
                                  errorBuilder: (c, e, s) => const Icon(
                                      Icons.help,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(psName,
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: isGold
                                            ? Colors.amber
                                            : Colors.white70))
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal",
                        style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                  onPressed: _savePlayer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent),
                  child: const Text("OLUŞTUR",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  void _savePlayer() {
    if (_nameController.text.isEmpty) return;

    final newPlayer = Player(
      name: _nameController.text,
      rating: int.tryParse(_ratingController.text) ?? 75,
      position: _selectedPosition,
      playstyles: _selectedPlayStyles.entries
          .map((e) => PlayStyle(e.key, isGold: e.value))
          .toList(),
    );

    // Hive'a Kaydet
    Hive.box<Player>('palehax_players').add(newPlayer);

    Navigator.pop(context);
  }
}
