import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/player_data.dart';

class CreatePlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  final bool isNewVersion;
  final Function? onSave;

  const CreatePlayerDialog(
      {super.key, this.playerToEdit, this.isNewVersion = false, this.onSave});
  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  final _recLinkController = TextEditingController();
  String _pos = "ST",
      _team = "Takımsız",
      _role = "Seçiniz",
      _chem = "Temel",
      _type = "Temel";
  int _skillMoves = 3;
  int _mGoals = 0, _mAssists = 0, _mMatches = 0;
  int _mPasses = 0, _mKeyPasses = 0, _mShots = 0, _mPossession = 50;

  late TabController _tabController;
  final Map<String, int> _stats = {};
  final Map<String, bool> _ps = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    if (widget.playerToEdit != null) {
      var p = widget.playerToEdit!;
      _nameController.text = p.name;
      _valueController.text = p.marketValue;
      _recLinkController.text = p.recLink;
      _pos = p.position;
      _team = p.team;
      _role = p.role;
      _skillMoves = p.skillMoves;
      _chem = p.chemistryStyle;
      _type = p.cardType;
      _mGoals = p.manualGoals;
      _mAssists = p.manualAssists;
      _mMatches = p.manualMatches;
      _mPasses = p.manualPasses;
      _mKeyPasses = p.manualKeyPasses;
      _mShots = p.manualShots;
      _mPossession = p.manualPossession;
      _stats.addAll(p.stats);
      for (var s in p.playstyles) _ps[s.name] = s.isGold;
    } else {
      for (var l in statSegments.values) for (var s in l) _stats[s] = 50;
      _role = roleCategories["ST"]!.first;
      _chem = chemistryBonuses.keys.first;
      _type = cardTypes.first;
      _team = availableTeams.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: const Color(0xFF101014),
        child: Container(
            width: 900,
            height: 800,
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(
                  widget.playerToEdit == null || widget.isNewVersion
                      ? "YENİ KART OLUŞTUR"
                      : "KARTI DÜZENLE",
                  style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.cyanAccent,
                  labelColor: Colors.cyanAccent,
                  unselectedLabelColor: Colors.grey,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: "KİMLİK"),
                    Tab(text: "İSTATİSTİK"),
                    Tab(text: "FİZİK & TOP"),
                    Tab(text: "ŞUT"),
                    Tab(text: "DEFANS"),
                    Tab(text: "PAS")
                  ]),
              Expanded(
                  child: TabBarView(controller: _tabController, children: [
                SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      _field(_nameController, "Ad Soyad"),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _dropdown("Takım", availableTeams, _team,
                                (v) => _team = v!)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _field(_valueController, "Piyasa Değeri"))
                      ]),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: _dropdown(
                                "Mevki",
                                availablePositions,
                                _pos,
                                (v) => setState(() {
                                      _pos = v!;
                                      _role =
                                          roleCategories[_pos]?.first ?? "Yok";
                                    }))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dropdown(
                                "Rol",
                                roleCategories[_pos] ?? ["Yok"],
                                _role,
                                (v) => _role = v!)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dropdown(
                                "Kimya",
                                chemistryBonuses.keys.toList(),
                                _chem,
                                (v) => _chem = v!)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _dropdown("Kart Tipi", cardTypes, _type,
                                (v) => _type = v!))
                      ]),
                      const SizedBox(height: 20),
                      _field(
                          _recLinkController, "Maç Kaydı Linki (İsteğe Bağlı)"),
                      const SizedBox(height: 20),
                      const Text("YETENEK YILDIZI",
                          style: TextStyle(color: Colors.amber)),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              5,
                              (i) => IconButton(
                                  icon: Icon(
                                      i < _skillMoves
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber),
                                  onPressed: () =>
                                      setState(() => _skillMoves = i + 1)))),
                      const Divider(color: Colors.white24),
                      const Text("OYUN STİLLERİ",
                          style: TextStyle(color: Colors.white70)),
                      Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: availablePlayStyles
                              .map((ps) => _psChip(ps))
                              .toList())
                    ])),
                SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      const Text("SEZON PERFORMANSI (MANUEL GİRİŞ)",
                          style: TextStyle(
                              color: Colors.cyanAccent, fontSize: 18)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: _counterRow("MAÇ SAYISI", _mMatches,
                                (v) => setState(() => _mMatches = v))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _counterRow("GOL", _mGoals,
                                (v) => setState(() => _mGoals = v))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _counterRow("ASİST", _mAssists,
                                (v) => setState(() => _mAssists = v))),
                      ]),
                      Row(children: [
                        Expanded(
                            child: _counterRow("PAS", _mPasses,
                                (v) => setState(() => _mPasses = v))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _counterRow("KİLİT PAS", _mKeyPasses,
                                (v) => setState(() => _mKeyPasses = v))),
                      ]),
                      Row(children: [
                        Expanded(
                            child: _counterRow("ŞUT", _mShots,
                                (v) => setState(() => _mShots = v))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _counterRow(
                                "TOPLA OYNAMA %",
                                _mPossession,
                                (v) => setState(
                                    () => _mPossession = v.clamp(0, 100)))),
                      ]),
                    ])),
                _statPage("1. Top Sürme & Fizik"),
                _statPage("2. Şut & Zihinsel"),
                _statPage("3. Savunma & Güç"),
                _statPage("4. Pas & Vizyon")
              ])),
              ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15)),
                  child: const Text("KAYDET",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)))
            ])));
  }

  Widget _counterRow(String label, int value, Function(int) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => value > 0 ? onChanged(value - 1) : null,
              icon:
                  const Icon(Icons.remove, color: Colors.redAccent, size: 20)),
          const SizedBox(width: 10),
          Text("$value",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add, color: Colors.greenAccent, size: 20)),
        ])
      ]),
    );
  }

  Widget _statPage(String k) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Wrap(
          spacing: 30,
          runSpacing: 20,
          children: (statSegments[k] ?? [])
              .map((s) => SizedBox(
                  width: 200,
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s,
                              style: const TextStyle(color: Colors.white70)),
                          Text("${_stats[s]}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))
                        ]),
                    Slider(
                        value: _stats[s]!.toDouble(),
                        min: 1,
                        max: 99,
                        activeColor: _getColor(_stats[s]!),
                        onChanged: (v) => setState(() => _stats[s] = v.toInt()))
                  ])))
              .toList()));
  Widget _field(TextEditingController c, String l) => TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: l, filled: true, fillColor: Colors.white10));
  Widget _dropdown(String l, List<String> i, String v, Function(String?) c) =>
      DropdownButtonFormField<String>(
          value: v,
          items:
              i.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: c,
          dropdownColor: const Color(0xFF1E1E24),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              labelText: l, filled: true, fillColor: Colors.white10));
  Widget _psChip(String n) {
    bool s = _ps.containsKey(n);
    bool g = s && _ps[n]!;
    return GestureDetector(
        onTap: () => setState(() => s ? _ps.remove(n) : _ps[n] = false),
        onLongPress: () => setState(() => _ps[n] = true),
        child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                color: s
                    ? (g ? Colors.amber.withOpacity(0.2) : Colors.white24)
                    : Colors.transparent,
                border: Border.all(
                    color:
                        s ? (g ? Colors.amber : Colors.white) : Colors.white12),
                borderRadius: BorderRadius.circular(5)),
            child: Image.asset("assets/Playstyles/${g ? "${n}Plus" : n}.png",
                width: 30,
                height: 30,
                errorBuilder: (c, e, x) =>
                    const Icon(Icons.help, size: 30, color: Colors.white54))));
  }

  Color _getColor(int v) {
    return v > 85
        ? Colors.greenAccent
        : (v > 70 ? Colors.lightGreen : Colors.orange);
  }

  void _save() {
    if (_nameController.text.isEmpty) return;
    List<PlayStyle> ps =
        _ps.entries.map((e) => PlayStyle(e.key, isGold: e.value)).toList();
    Player p = (widget.isNewVersion || widget.playerToEdit == null)
        ? Player(name: "", rating: 0, position: "", playstyles: [])
        : widget.playerToEdit!;
    p.name = _nameController.text;
    p.marketValue = _valueController.text;
    p.position = _pos;
    p.team = _team;
    p.role = _role;
    p.skillMoves = _skillMoves;
    p.chemistryStyle = _chem;
    p.cardType = _type;
    p.recLink = _recLinkController.text;
    p.stats = Map.from(_stats);
    p.playstyles = ps;
    p.manualGoals = _mGoals;
    p.manualAssists = _mAssists;
    p.manualMatches = _mMatches;
    p.manualPasses = _mPasses;
    p.manualKeyPasses = _mKeyPasses;
    p.manualShots = _mShots;
    p.manualPossession = _mPossession;
    p.calculateRating();
    var box = Hive.box<Player>('palehax_manager_db');
    if (widget.playerToEdit == null || widget.isNewVersion)
      box.add(p);
    else
      p.save();
    if (widget.onSave != null) widget.onSave!();
    Navigator.pop(context);
  }
}
