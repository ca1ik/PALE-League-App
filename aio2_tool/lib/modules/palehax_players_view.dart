import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../data/player_data.dart';
import '../ui/glass_box.dart';
import '../providers/language_provider.dart';

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
    // V3 KUTUSU (Yeni veri yapısı için)
    playerBox = Hive.box<Player>('palehax_players_v3');
    if (playerBox.isNotEmpty) {
      selectedPlayer = playerBox.getAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlayerDialog,
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(lang.translate('ui_create_player'),
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder(
        valueListenable: playerBox.listenable(),
        builder: (context, Box<Player> box, _) {
          final players = box.values.toList();

          if (players.isEmpty) {
            return const Center(
                child: Text("Veritabanı hazırlanıyor...",
                    style: TextStyle(color: Colors.white)));
          }

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
                    Text(lang.translate('ui_squad_list'),
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
                                        // Takım ismini listede de gösterelim
                                        Text("${p.position} | ${p.team}",
                                            style: GoogleFonts.poppins(
                                                color: Colors.white54,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
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
                        // 1. OYUNCU KARTI
                        GlassBox(
                          width: double.infinity,
                          height: 260,
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
                                    // SİYAH FORMA NO
                                    Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
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
                                            fontSize: 90, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 40),
                                    // BİLGİLER
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
                                                    fontSize: 60,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getRatingColor(
                                                        selectedPlayer!
                                                            .rating))),
                                            const SizedBox(width: 20),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.white24)),
                                              child: Text(
                                                  selectedPlayer!.position,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 24)),
                                            ),
                                            const SizedBox(width: 15),
                                            // TAKIM ETİKETİ (YENİ)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                  color: Colors.blueAccent
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color:
                                                          Colors.blueAccent)),
                                              child: Text(
                                                  selectedPlayer!.team
                                                      .toUpperCase(),
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.blueAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                        Text(selectedPlayer!.name.toUpperCase(),
                                            style: GoogleFonts.orbitron(
                                                fontSize: 30,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.5)),
                                        const SizedBox(height: 10),
                                        // PİYASA DEĞERİ
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15, vertical: 5),
                                          decoration: BoxDecoration(
                                              color: Colors.greenAccent
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: Colors.greenAccent)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.monetization_on,
                                                  color: Colors.greenAccent,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(selectedPlayer!.marketValue,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.greenAccent,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16)),
                                            ],
                                          ),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 2. PLAYSTYLES
                        Text(lang.translate('ui_playstyles'),
                            style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                letterSpacing: 2,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: selectedPlayer!.playstyles.map((ps) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Tooltip(
                                  message: ps.name +
                                      (ps.isGold ? " (PlayStyle+)" : ""),
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF15151A),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                          color: ps.isGold
                                              ? const Color(0xFFFFD700)
                                              : Colors.white12,
                                          width: ps.isGold ? 3 : 1),
                                      boxShadow: ps.isGold
                                          ? [
                                              BoxShadow(
                                                  color: Colors.amber
                                                      .withOpacity(0.4),
                                                  blurRadius: 15)
                                            ]
                                          : [],
                                    ),
                                    child: Image.asset(
                                      ps.assetPath,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.help_outline,
                                                  color: Colors.white24),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  lang.translate('ps_${ps.name}'),
                                  style: GoogleFonts.poppins(
                                      color: ps.isGold
                                          ? const Color(0xFFFFD700)
                                          : Colors.white60,
                                      fontSize: 11,
                                      fontWeight: ps.isGold
                                          ? FontWeight.bold
                                          : FontWeight.normal),
                                )
                              ],
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 30),

                        // 3. MAÇ ANALİZİ
                        Text(lang.translate('ui_match_analysis'),
                            style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                letterSpacing: 2,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: selectedPlayer!.matches.map((match) {
                              return Container(
                                width: 160,
                                margin: const EdgeInsets.only(right: 15),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(match.opponent,
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 5),
                                    Text("FT: ${match.score}",
                                        style: GoogleFonts.sourceCodePro(
                                            color: Colors.cyanAccent,
                                            fontSize: 12)),
                                    const Divider(color: Colors.white12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _statBadge(
                                            "G", match.goals, Colors.green),
                                        _statBadge(
                                            "A", match.assists, Colors.blue),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 50),
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

  Widget _statBadge(String label, int value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text("$value",
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 90) return const Color(0xFF00FFC2);
    if (rating >= 85) return const Color(0xFFA6FF00);
    if (rating >= 80) return Colors.amber;
    return Colors.white;
  }

  void _showCreatePlayerDialog() {
    showDialog(
        context: context, builder: (context) => const CreatePlayerDialog());
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
  final _valueController = TextEditingController();
  String _selectedPosition = "ST";
  String _selectedTeam = "Takımsız"; // YENİ: Takım Seçimi
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
        height: 750,
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
                            child: _field(_nameController, "Oyuncu Adı")),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 1,
                            child: _field(_ratingController, "Reyting",
                                num: true)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Piyasa Değeri
                    _field(_valueController, "Piyasa Değeri (Örn: 10M €)"),
                    const SizedBox(height: 15),

                    // YENİ: Takım Seçimi
                    Text("Takım",
                        style: GoogleFonts.poppins(color: Colors.grey)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTeam,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E1E24),
                          style: const TextStyle(color: Colors.white),
                          items: availableTeams
                              .map((team) => DropdownMenuItem(
                                  value: team, child: Text(team)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedTeam = val!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),
                    // Mevki Seçimi
                    Text("Mevki",
                        style: GoogleFonts.poppins(color: Colors.grey)),
                    Wrap(
                      spacing: 8,
                      children: availablePositions
                          .map((pos) => ChoiceChip(
                                label: Text(pos),
                                selected: _selectedPosition == pos,
                                onSelected: (val) =>
                                    setState(() => _selectedPosition = pos),
                                selectedColor: Colors.cyanAccent,
                                backgroundColor: Colors.white10,
                                labelStyle: TextStyle(
                                    color: _selectedPosition == pos
                                        ? Colors.black
                                        : Colors.white),
                              ))
                          .toList(),
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    // PlayStyles
                    Text("PlayStyles (Tek Tık: Gümüş, Uzun Bas: Altın)",
                        style: GoogleFonts.poppins(color: Colors.cyanAccent)),
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
                          onTap: () => setState(() => isSelected
                              ? _selectedPlayStyles.remove(psName)
                              : _selectedPlayStyles[psName] = false),
                          onLongPress: () => setState(
                              () => _selectedPlayStyles[psName] = true),
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
                            child: Image.asset(
                                "assets/Playstyles/${isGold ? "${psName}Plus" : psName}.png",
                                width: 40,
                                height: 40),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
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
                          color: Colors.black, fontWeight: FontWeight.bold)))
            ])
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool num = false}) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      keyboardType: num ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none)),
    );
  }

  void _savePlayer() {
    if (_nameController.text.isEmpty) return;
    final newPlayer = Player(
      name: _nameController.text,
      rating: int.tryParse(_ratingController.text) ?? 75,
      position: _selectedPosition,
      marketValue:
          _valueController.text.isEmpty ? "N/A" : _valueController.text,
      team: _selectedTeam, // Takım Kaydı
      playstyles: _selectedPlayStyles.entries
          .map((e) => PlayStyle(e.key, isGold: e.value))
          .toList(),
    );
    Hive.box<Player>('palehax_players_v3').add(newPlayer);
    Navigator.pop(context);
  }
}
