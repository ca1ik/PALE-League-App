import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import '../data/player_data.dart';
import 'glass_box.dart';

class PlayerEditor extends StatefulWidget {
  final Player? playerToEdit;
  const PlayerEditor({super.key, this.playerToEdit});

  @override
  State<PlayerEditor> createState() => _PlayerEditorState();
}

class _PlayerEditorState extends State<PlayerEditor> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  int rating = 75;
  String position = positionsList[0];
  String team = teamList[0].name;
  String cardType = cardTypesList[0];
  String role = rolesList[0];
  String chemistry = chemistryList[0];
  int kitNumber = 7;

  // YENİ: Seçilen PlayStyle'ları tutacak liste
  List<PlayStyle> _selectedPlayStyles = [];

  // İstatistikler
  int pac = 70, sho = 70, pas = 70, dri = 70, def = 70, phy = 70;
  // Kaleci İstatistikleri
  int div = 70, han = 70, kic = 70, ref = 70, pos = 70;

  @override
  void initState() {
    super.initState();
    if (widget.playerToEdit != null) {
      final p = widget.playerToEdit!;
      name = p.name;
      rating = p.rating;
      position = p.position;
      team = p.team;
      cardType = p.cardType;
      role = p.role;
      chemistry = p.chemistryStyle;
      kitNumber = p.kitNumber;
      _selectedPlayStyles = List.from(p.playstyles); // Mevcutları yükle

      if (p.stats.containsKey('PAC')) {
        pac = p.stats['PAC']!;
        sho = p.stats['SHO']!;
        pas = p.stats['PAS']!;
        dri = p.stats['DRI']!;
        def = p.stats['DEF']!;
        phy = p.stats['PHY']!;
      }
      if (p.stats.containsKey('DIV')) {
        div = p.stats['DIV']!;
        han = p.stats['HAN']!;
        kic = p.stats['KIC']!;
        ref = p.stats['REF']!;
        pos = p.stats['POS']!;
      }
    } else {
      name = "";
    }
  }

  void _savePlayer() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    Map<String, int> stats = position.contains("GK")
        ? {'DIV': div, 'HAN': han, 'KIC': kic, 'REF': ref, 'POS': pos}
        : {
            'PAC': pac,
            'SHO': sho,
            'PAS': pas,
            'DRI': dri,
            'DEF': def,
            'PHY': phy
          };

    final newPlayer = Player(
      id: widget.playerToEdit?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      rating: rating,
      position: position,
      team: team,
      cardType: cardType,
      role: role,
      marketValue: "Hesaplanıyor...",
      stats: stats,
      playstyles: _selectedPlayStyles, // Seçilenleri kaydet
      chemistryStyle: chemistry,
      kitNumber: kitNumber,
    );

    final box = Hive.box<Player>('palehax_players_v9');
    if (widget.playerToEdit != null) {
      // Düzenleme modu: Mevcut key'i bul ve güncelle
      final key = box.keys.firstWhere((k) => box.get(k)?.id == newPlayer.id);
      box.put(key, newPlayer);
    } else {
      // Yeni ekleme modu
      box.add(newPlayer);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oyuncu başarıyla kaydedildi!")));
  }

  @override
  Widget build(BuildContext context) {
    bool isGK = position.contains("GK");
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
            widget.playerToEdit == null ? "Oyuncu Oluştur" : "Oyuncu Düzenle",
            style: GoogleFonts.orbitron(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: GlassBox(
          width: 900,
          height: 700,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Temel Bilgiler Row'u (Kısaltıldı, aynı kalacak)
                    _buildBasicInfoRow(),
                    const SizedBox(height: 20),
                    // Dropdownlar Row'u (Kısaltıldı, aynı kalacak)
                    _buildDropdownsRow(),
                    const SizedBox(height: 20),

                    // --- YENİ: PLAYSTYLES SEÇİM ALANI ---
                    Text("PlayStyles (Oyun Tarzları)",
                        style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent, fontSize: 16)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white12)),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: playStylesList.map((ps) {
                          final isSelected = _selectedPlayStyles
                              .any((selected) => selected.name == ps.name);
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(ps.assetPath,
                                    width: 20,
                                    height: 20,
                                    errorBuilder: (c, e, s) => Icon(Icons.star,
                                        size: 20,
                                        color: ps.isGold
                                            ? Colors.amber
                                            : Colors.white)),
                                const SizedBox(width: 5),
                                Text(ps.name,
                                    style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white)),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  // Eğer gold ise, diğer gold'u kaldır (sadece 1 gold olabilir kuralı varsa)
                                  if (ps.isGold) {
                                    _selectedPlayStyles.removeWhere(
                                        (element) => element.isGold);
                                  }
                                  _selectedPlayStyles.add(ps);
                                } else {
                                  _selectedPlayStyles.removeWhere(
                                      (element) => element.name == ps.name);
                                }
                              });
                            },
                            backgroundColor: Colors.black45,
                            selectedColor: ps.isGold
                                ? Colors.amberAccent
                                : Colors.cyanAccent,
                            checkmarkColor: Colors.black,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // İstatistikler Başlığı
                    Text(
                        isGK
                            ? "Kaleci İstatistikleri"
                            : "Oyuncu İstatistikleri",
                        style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent, fontSize: 18)),
                    const SizedBox(height: 15),
                    // İstatistik Sliderları
                    isGK ? _buildGKStats() : _buildPlayerStats(),

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _savePlayer,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            textStyle: GoogleFonts.orbitron(
                                fontWeight: FontWeight.bold)),
                        icon: const Icon(Icons.save),
                        label: const Text("KAYDET"),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Yardımcı Widgetlar (Önceki koddan aynen alındı) ---
  Widget _buildBasicInfoRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildTextField("Oyuncu Adı", (v) => name = v!,
              initialValue: name),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSlider(
              "Reyting", rating, 40, 99, (v) => setState(() => rating = v)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSlider("Forma No", kitNumber, 1, 99,
              (v) => setState(() => kitNumber = v)),
        ),
      ],
    );
  }

  Widget _buildDropdownsRow() {
    return Row(
      children: [
        Expanded(
            child: _buildDropdown("Pozisyon", positionsList, position,
                (v) => setState(() => position = v!))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildDropdown("Takım", teamList.map((e) => e.name).toList(),
                team, (v) => setState(() => team = v!))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildDropdown("Kart Tipi", cardTypesList, cardType,
                (v) => setState(() => cardType = v!))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildDropdown(
                "Rol", rolesList, role, (v) => setState(() => role = v!))),
        const SizedBox(width: 10),
        Expanded(
            child: _buildDropdown("Kimya", chemistryList, chemistry,
                (v) => setState(() => chemistry = v!))),
      ],
    );
  }

  Widget _buildPlayerStats() {
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: _buildSlider("PAC (Hız)", pac, 30, 99, (v) => pac = v)),
          const SizedBox(width: 15),
          Expanded(
              child: _buildSlider("SHO (Şut)", sho, 30, 99, (v) => sho = v))
        ]),
        Row(children: [
          Expanded(
              child: _buildSlider("PAS (Pas)", pas, 30, 99, (v) => pas = v)),
          const SizedBox(width: 15),
          Expanded(
              child:
                  _buildSlider("DRI (Dribbling)", dri, 30, 99, (v) => dri = v))
        ]),
        Row(children: [
          Expanded(
              child: _buildSlider("DEF (Defans)", def, 30, 99, (v) => def = v)),
          const SizedBox(width: 15),
          Expanded(
              child: _buildSlider("PHY (Fizik)", phy, 30, 99, (v) => phy = v))
        ]),
      ],
    );
  }

  Widget _buildGKStats() {
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: _buildSlider("DIV (Uzanma)", div, 30, 99, (v) => div = v)),
          const SizedBox(width: 15),
          Expanded(
              child:
                  _buildSlider("HAN (Elle Tutma)", han, 30, 99, (v) => han = v))
        ]),
        Row(children: [
          Expanded(
              child: _buildSlider("KIC (Vuruş)", kic, 30, 99, (v) => kic = v)),
          const SizedBox(width: 15),
          Expanded(
              child: _buildSlider("REF (Refleks)", ref, 30, 99, (v) => ref = v))
        ]),
        Row(children: [
          Expanded(
              child:
                  _buildSlider("POS (Pozisyon)", pos, 30, 99, (v) => pos = v)),
          const SizedBox(width: 15),
          Spacer()
        ]),
      ],
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved,
      {String? initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
      ),
      validator: (v) => v!.isEmpty ? "Bu alan zorunludur" : null,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFF1E1E24),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
      ),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSlider(String label, int value, double min, double max,
      Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            Text("$value",
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min,
          max: max,
          activeColor: Colors.cyanAccent,
          inactiveColor: Colors.white10,
          onChanged: (v) => setState(() => onChanged(v.toInt())),
        ),
      ],
    );
  }
}
