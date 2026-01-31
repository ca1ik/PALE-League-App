import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart'; // ARTIK TÜM LİSTELER BURADAN GELİYOR
import '../ui/fc_animated_card.dart';

// Sadece bu dosyaya özel kısıtlanmış mevki listesi
const List<String> allowedPositions = [
  "(1) GK",
  "(3-6) CDM",
  "(10) CAM",
  "(7) RW",
  "(11) LW",
  "(9) ST"
];

class CreatePlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  final bool isNewVersion;
  final Function(Player?) onSave;

  const CreatePlayerDialog(
      {super.key,
      this.playerToEdit,
      this.isNewVersion = false,
      required this.onSave});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  final _formKey = GlobalKey<FormState>();

  late String name;
  late int rating;
  late String position;
  late String team;
  late String role;
  late String cardType;
  late String marketValue;
  late String recLink;

  Map<String, int> stats = {};
  List<PlayStyle> playstyles = [];
  final TextEditingController _quickRatingCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Varsayılanları player_data.dart'tan çekiyoruz (HATA ÇÖZÜLDÜ)
    String defaultPosition = allowedPositions.first;
    String defaultTeam = teamLogos.keys.first;
    String defaultRole = roleCategories[defaultPosition]?.first ?? "Belirsiz";
    String defaultCardType = globalCardTypes.first;

    if (widget.playerToEdit != null) {
      final p = widget.playerToEdit!;
      name = p.name;
      rating = p.rating;
      position =
          allowedPositions.contains(p.position) ? p.position : defaultPosition;
      team = teamLogos.keys.contains(p.team) ? p.team : defaultTeam;

      List<String> validRoles = roleCategories[position] ?? [];
      role = validRoles.contains(p.role)
          ? p.role
          : (validRoles.isNotEmpty ? validRoles.first : "Belirsiz");

      cardType = widget.isNewVersion ? "TOTW" : p.cardType;
      marketValue = p.marketValue;
      recLink = p.recLink;
      stats = Map.from(p.stats);
      playstyles = List.from(p.playstyles);
    } else {
      name = "";
      rating = 75;
      position = defaultPosition;
      team = defaultTeam;
      role = defaultRole;
      cardType = defaultCardType;
      marketValue = "€1M";
      recLink = "";
      _initializeStats();
    }
  }

  void _initializeStats() {
    for (var s in gkSkillStats) stats[s] = 75;
    for (var s in gkPassStats) stats[s] = 75;
    statSegments.forEach((key, list) {
      for (var s in list) stats[s] = 75;
    });
  }

  void _applyQuickRating(String val) {
    int? r = int.tryParse(val);
    if (r != null) {
      setState(() {
        if (position.contains("GK") || position.contains("(1)")) {
          for (var s in gkSkillStats) stats[s] = r;
          for (var s in gkPassStats) stats[s] = r;
        } else {
          statSegments.forEach((key, list) {
            for (var s in list) stats[s] = r;
          });
        }
        rating = r;
      });
    }
  }

  void _recalculateRating() {
    Player temp = Player(
        name: name,
        rating: 0,
        position: position,
        playstyles: [],
        cardType: cardType,
        team: team,
        stats: stats,
        role: role);
    temp.calculateSmartRating();
    setState(() {
      rating = temp.rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isGK = position.contains("GK") || position.contains("(1)");
    List<String> currentRoles = roleCategories[position] ?? ["Belirsiz"];

    return Dialog(
      backgroundColor: const Color(0xFF15151E),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 1300,
        height: 850,
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(
              flex: 3,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("ÖNİZLEME",
                        style: GoogleFonts.orbitron(
                            color: Colors.cyanAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    FCAnimatedCard(
                        player: Player(
                            name: name.isEmpty ? "OYUNCU" : name,
                            rating: rating,
                            position: position,
                            playstyles: playstyles,
                            cardType: cardType,
                            team: team,
                            stats: stats,
                            role: role)),
                    const SizedBox(height: 20),
                    Container(
                        width: 200,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber)),
                        child: Column(children: [
                          const Text("HIZLI REYTİNG SETİ",
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          TextField(
                              controller: _quickRatingCtrl,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  hintText: "82",
                                  hintStyle: TextStyle(color: Colors.white24),
                                  border: InputBorder.none,
                                  isDense: true),
                              onChanged: _applyQuickRating)
                        ]))
                  ])),
          const VerticalDivider(color: Colors.white10, width: 40),
          Expanded(
              flex: 5,
              child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text("KİMLİK BİLGİLERİ",
                            style: GoogleFonts.orbitron(
                                color: Colors.white, fontSize: 16)),
                        const Divider(color: Colors.white24),
                        Row(children: [
                          Expanded(
                              child: _buildTextField("Ad Soyad", name,
                                  (v) => setState(() => name = v))),
                          const SizedBox(width: 15),
                          Expanded(
                              child: _buildDropdown(
                                  "Pozisyon", position, allowedPositions, (v) {
                            setState(() {
                              position = v!;
                              List<String> newRoles =
                                  roleCategories[position] ?? ["Belirsiz"];
                              role = newRoles.first;
                              _recalculateRating();
                            });
                          }))
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                              child: _buildDropdown(
                                  "Takım",
                                  team,
                                  teamLogos.keys.toList(),
                                  (v) => setState(() => team = v!))),
                          const SizedBox(width: 15),
                          Expanded(
                              child: _buildDropdown(
                                  "Kart Tipi",
                                  cardType,
                                  globalCardTypes,
                                  (v) => setState(() => cardType = v!))),
                          const SizedBox(width: 15),
                          Expanded(
                              child: _buildDropdown("Rol", role, currentRoles,
                                  (v) => setState(() => role = v!)))
                        ]),
                        const SizedBox(height: 30),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isGK ? "KALECİ STATLARI" : "OYUNCU STATLARI",
                                  style: GoogleFonts.orbitron(
                                      color: Colors.greenAccent, fontSize: 16)),
                              ElevatedButton.icon(
                                  onPressed: _recalculateRating,
                                  icon: const Icon(Icons.calculate),
                                  label: const Text("OTO-HESAPLA"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent))
                            ]),
                        const Divider(color: Colors.white24),
                        if (isGK) _buildGKSliders() else _buildNormalSliders(),
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    widget.onSave(Player(
                                        name: name,
                                        rating: rating,
                                        position: position,
                                        playstyles: playstyles,
                                        cardType: cardType,
                                        team: team,
                                        stats: stats,
                                        role: role,
                                        marketValue: marketValue,
                                        recLink: recLink));
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.greenAccent),
                                child: const Text("KAYDET",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18))))
                      ]))))
        ]),
      ),
    );
  }

  Widget _buildGKSliders() {
    return Column(children: [
      _buildStatGroup("KALECİ BECERİLERİ", gkSkillStats, Colors.orange),
      _buildStatGroup("PAS & MENTAL", gkPassStats, Colors.blue)
    ]);
  }

  Widget _buildNormalSliders() {
    return Column(
        children: statSegments.entries
            .map((e) => _buildStatGroup(e.key, e.value, Colors.cyanAccent))
            .toList());
  }

  Widget _buildStatGroup(String t, List<String> l, Color c) {
    return Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            border: Border.all(color: c.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
              spacing: 20,
              runSpacing: 10,
              children: l
                  .map((k) => SizedBox(
                      width: 180,
                      child: Row(children: [
                        Expanded(
                            child: Text(k,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12))),
                        SizedBox(
                            width: 80,
                            child: TextFormField(
                                initialValue: (stats[k] ?? 75).toString(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.all(8),
                                    border: OutlineInputBorder(),
                                    filled: true,
                                    fillColor: Colors.black26),
                                onChanged: (v) {
                                  int? val = int.tryParse(v);
                                  if (val != null) stats[k] = val;
                                }))
                      ])))
                  .toList())
        ]));
  }

  Widget _buildTextField(String l, String i, Function(String) c) {
    return TextFormField(
        initialValue: i,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            labelText: l,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        onChanged: c);
  }

  Widget _buildDropdown(
      String l, String v, List<String> i, Function(String?) c) {
    String safeVal = i.contains(v) ? v : (i.isNotEmpty ? i.first : "");
    return DropdownButtonFormField<String>(
        value: safeVal,
        dropdownColor: const Color(0xFF1E1E24),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            labelText: l,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
        items: i
            .map((e) => DropdownMenuItem(
                value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: c);
  }
}
