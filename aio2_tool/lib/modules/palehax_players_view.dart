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
  // ... (Bu kısım öncekiyle benzer, sadece yeni özellikleri entegre ediyoruz)
  // Yer darlığı sebebiyle sadece CreatePlayerDialog'un yeni halini veriyorum.
  // Ana ekran aynı kalabilir veya Statları göstermek için güncellenebilir.

  // Ana ekran kodları öncekiyle aynı, sadece CreatePlayerDialog çağrısı değişti.
  // Buraya tam dosyayı sığdırmak zor olacağı için CreatePlayerDialog'u tam veriyorum.
  // Bunu mevcut dosyadaki CreatePlayerDialog class'ının yerine yapıştırın.

  Player? selectedPlayer;
  late Box<Player> playerBox;

  @override
  void initState() {
    super.initState();
    playerBox = Hive.box<Player>('palehax_players_v4'); // V4 Kutu
    if (playerBox.isNotEmpty) selectedPlayer = playerBox.getAt(0);
  }

  // ... Build metodu önceki gibi ...
  @override
  Widget build(BuildContext context) {
    // ... Scaffold ve Liste yapısı aynı ...
    // Tek fark FAB butonu:
    return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showDialog(
              context: context, builder: (c) => const CreatePlayerDialog()),
          label: const Text("Oyuncu Oluştur"),
          icon: const Icon(Icons.add),
          backgroundColor: Colors.cyanAccent,
        ),
        body: ValueListenableBuilder(
            valueListenable: playerBox.listenable(),
            builder: (context, Box<Player> box, _) {
              // ... Liste ve Detay görünümü aynı ...
              // Detay görünümünde STATLARI göstermek istersen buraya ekleyebilirsin.
              return Container(); // Placeholder
            }));
  }
}

// --- YENİ GELİŞMİŞ OYUNCU OLUŞTURUCU ---
class CreatePlayerDialog extends StatefulWidget {
  const CreatePlayerDialog({super.key});
  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();

  String _selectedPosition = "ST";
  String _selectedTeam = "Takımsız";
  String _selectedRole = "Seçiniz";
  int _skillMoves = 3;
  bool isFMMode = false; // FC vs FM Modu

  final Map<String, bool> _selectedPlayStyles = {};

  // Detaylı İstatistikler (Key: Stat Adı, Value: Değer)
  final Map<String, int> _stats = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 5, vsync: this); // Temel + 4 Stat Grubu
    _updateRole();
  }

  void _updateRole() {
    setState(() {
      _selectedRole = roleCategories[_selectedPosition]?.first ?? "Yok";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101014),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24)),
      child: Container(
        width: 900,
        height: 800,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("OYUNCU OLUŞTURUCU",
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                // FC/FM Toggle
                GestureDetector(
                  onTap: () => setState(() => isFMMode = !isFMMode),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: isFMMode
                                ? [Colors.purple, Colors.deepPurple]
                                : [Colors.green, Colors.teal]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: isFMMode
                                  ? Colors.purpleAccent
                                  : Colors.greenAccent,
                              blurRadius: 10)
                        ]),
                    child: Text(isFMMode ? "Mod: FM (1-20)" : "Mod: FC (1-99)",
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.cyanAccent,
              labelColor: Colors.cyanAccent,
              unselectedLabelColor: Colors.grey,
              isScrollable: true,
              tabs: const [
                Tab(text: "Temel & Rol"),
                Tab(text: "Top Sürme"),
                Tab(text: "Şut"),
                Tab(text: "Savunma"),
                Tab(text: "Pas"),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. SEKME: TEMEL BİLGİLER
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _field(_nameController, "Oyuncu Adı"),
                        const SizedBox(height: 10),
                        _field(_valueController, "Piyasa Değeri"),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                                child: _dropdown("Mevki", availablePositions,
                                    _selectedPosition, (v) {
                              _selectedPosition = v!;
                              _updateRole();
                            })),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _dropdown("Takım", availableTeams,
                                    _selectedTeam, (v) => _selectedTeam = v!)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Rol Seçimi
                        Text("Rol",
                            style:
                                GoogleFonts.poppins(color: Colors.cyanAccent)),
                        Wrap(
                          spacing: 8,
                          children: (roleCategories[_selectedPosition] ?? [])
                              .map((role) => ChoiceChip(
                                    label: Text(role),
                                    selected: _selectedRole == role,
                                    onSelected: (v) =>
                                        setState(() => _selectedRole = role),
                                    selectedColor: Colors.cyanAccent,
                                    backgroundColor: Colors.white10,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        // Skill Moves
                        Text("Yetenek Hareketleri",
                            style:
                                GoogleFonts.poppins(color: Colors.cyanAccent)),
                        Row(
                            children: List.generate(
                                5,
                                (i) => IconButton(
                                      icon: Icon(
                                          i < _skillMoves
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber),
                                      onPressed: () =>
                                          setState(() => _skillMoves = i + 1),
                                    ))),
                        const Divider(color: Colors.white24),
                        // Playstyles
                        const Text(
                            "PlayStyles (Tıkla: Gümüş, Basılı Tut: Altın)",
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 5),
                        Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: availablePlayStyles
                                .map((ps) => _playstyleChip(ps))
                                .toList()),
                      ],
                    ),
                  ),

                  // 2. SEKME: TOP SÜRME (Segment 1)
                  _statPage("1. Top Sürme & Fizik"),
                  // 3. SEKME: ŞUT (Segment 2)
                  _statPage("2. Şut & Zihinsel"),
                  // 4. SEKME: SAVUNMA (Segment 3)
                  _statPage("3. Savunma & Güç"),
                  // 5. SEKME: PAS (Segment 4)
                  _statPage("4. Pas & Vizyon"),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("İptal",
                      style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: _savePlayer,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15)),
                child: const Text("ANALİZ ET & OLUŞTUR",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              )
            ]),
          ],
        ),
      ),
    );
  }

  Widget _statPage(String segmentKey) {
    List<String> stats = statSegments[segmentKey] ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: stats.map((statName) {
          int val = _stats[statName] ?? (isFMMode ? 10 : 50);
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(statName, style: const TextStyle(color: Colors.white)),
                  Text("$val",
                      style: TextStyle(
                          color: _getStatColor(val),
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: val.toDouble(),
                min: isFMMode ? 1 : 1,
                max: isFMMode ? 20 : 99,
                activeColor: _getStatColor(val),
                onChanged: (v) => setState(() => _stats[statName] = v.toInt()),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _getStatColor(int val) {
    double percent = isFMMode ? val / 20.0 : val / 99.0;
    if (percent > 0.85) return Colors.greenAccent;
    if (percent > 0.70) return Colors.lightGreen;
    if (percent > 0.50) return Colors.orange;
    return Colors.red;
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
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

  Widget _dropdown(String label, List<String> items, String value,
      Function(String?) onChange) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              color: Colors.white10, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E24),
              style: const TextStyle(color: Colors.white),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => onChange(v)),
            ),
          ),
        )
      ],
    );
  }

  Widget _playstyleChip(String name) {
    bool isSelected = _selectedPlayStyles.containsKey(name);
    bool isGold = isSelected && _selectedPlayStyles[name]!;
    return GestureDetector(
      onTap: () => setState(() => isSelected
          ? _selectedPlayStyles.remove(name)
          : _selectedPlayStyles[name] = false),
      onLongPress: () => setState(() => _selectedPlayStyles[name] = true),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            color: isSelected
                ? (isGold ? Colors.amber.withOpacity(0.2) : Colors.white24)
                : Colors.transparent,
            border: Border.all(
                color: isSelected
                    ? (isGold ? Colors.amber : Colors.white)
                    : Colors.white12),
            borderRadius: BorderRadius.circular(8)),
        child: Image.asset(
            "assets/Playstyles/${isGold ? "${name}Plus" : name}.png",
            width: 35,
            height: 35),
      ),
    );
  }

  void _savePlayer() {
    if (_nameController.text.isEmpty) return;

    // Eğer FM Modundaysa verileri 99 skalasına çevirip kaydedelim
    Map<String, int> finalStats = {};
    _stats.forEach((key, value) {
      finalStats[key] = isFMMode ? (value * 5) - 1 : value; // Basit çeviri
    });

    final newPlayer = Player(
      name: _nameController.text,
      rating: 0, // CalculateRating ile hesaplanacak
      position: _selectedPosition,
      marketValue:
          _valueController.text.isEmpty ? "N/A" : _valueController.text,
      team: _selectedTeam,
      stats: finalStats,
      role: _selectedRole,
      skillMoves: _skillMoves,
      playstyles: _selectedPlayStyles.entries
          .map((e) => PlayStyle(e.key, isGold: e.value))
          .toList(),
    );

    newPlayer.calculateRating(); // OTOMATİK HESAPLAMA

    Hive.box<Player>('palehax_players_v4').add(newPlayer);
    Navigator.pop(context);
  }
}
