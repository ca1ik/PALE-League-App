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
  bool isFMView = false; // Sadece Görüntülemede Toggle

  @override
  void initState() {
    super.initState();
    playerBox = Hive.box<Player>('palehax_players_v4');
    if (playerBox.isNotEmpty) selectedPlayer = playerBox.getAt(0);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
            context: context, builder: (c) => const CreatePlayerDialog()),
        label: const Text("OYUNCU OLUŞTUR",
            style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.cyanAccent)),
        elevation: 10,
      ).getApplicationGradient(), // Extension yazılabilir veya Container ile sarılabilir
      body: ValueListenableBuilder(
        valueListenable: playerBox.listenable(),
        builder: (context, Box<Player> box, _) {
          final players = box.values.toList();
          if (players.isEmpty)
            return const Center(
                child: Text("Veritabanı boş.",
                    style: TextStyle(color: Colors.white)));
          if (selectedPlayer == null && players.isNotEmpty)
            selectedPlayer = players.first;

          return Row(
            children: [
              // --- SOL: LİSTE ---
              Container(
                width: 300,
                margin: const EdgeInsets.only(right: 20),
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    bool isSel = selectedPlayer == p;
                    return GestureDetector(
                      onTap: () => setState(() => selectedPlayer = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          gradient: isSel
                              ? const LinearGradient(colors: [
                                  Color(0xFF00C6FF),
                                  Color(0xFF0072FF)
                                ])
                              : null,
                          color: isSel ? null : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border:
                              isSel ? null : Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Text("${p.rating}",
                                style: GoogleFonts.russoOne(
                                    fontSize: 20,
                                    color: isSel
                                        ? Colors.white
                                        : _getRatingColor(p.rating))),
                            const SizedBox(width: 15),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  Text("${p.position} | ${p.team}",
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ])
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- SAĞ: PROFİL ---
              if (selectedPlayer != null)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ÜST KART
                        GlassBox(
                          width: double.infinity,
                          height: 280,
                          child: Stack(
                            children: [
                              Positioned(
                                  right: 20,
                                  top: 20,
                                  child: IconButton(
                                      icon: Icon(
                                          isFMView
                                              ? Icons.looks_two
                                              : Icons.looks_one,
                                          color: Colors.white),
                                      tooltip: "FC / FM Görünümü",
                                      onPressed: () => setState(
                                          () => isFMView = !isFMView))),
                              Padding(
                                padding: const EdgeInsets.all(30),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black,
                                          border: Border.all(
                                              color: _getRatingColor(
                                                  selectedPlayer!.rating),
                                              width: 3)),
                                      alignment: Alignment.center,
                                      child: Text(
                                          "${selectedPlayer!.kitNumber}",
                                          style: GoogleFonts.russoOne(
                                              fontSize: 80,
                                              color: Colors.white)),
                                    ),
                                    const SizedBox(width: 30),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(selectedPlayer!.name.toUpperCase(),
                                            style: GoogleFonts.orbitron(
                                                fontSize: 35,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                        Row(
                                          children: [
                                            _badge(selectedPlayer!.position,
                                                Colors.blueAccent),
                                            const SizedBox(width: 10),
                                            _badge(selectedPlayer!.role,
                                                Colors.purpleAccent),
                                            const SizedBox(width: 10),
                                            Text(selectedPlayer!.marketValue,
                                                style: const TextStyle(
                                                    color: Colors.greenAccent,
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 15),
                                        // ORTALAMALAR (Genel Bakış)
                                        Row(
                                          children: [
                                            _statPreview(
                                                "PAC",
                                                _getCategoryAvg(
                                                    "1. Top Sürme & Fizik")),
                                            _statPreview(
                                                "SHO",
                                                _getCategoryAvg(
                                                    "2. Şut & Zihinsel")),
                                            _statPreview(
                                                "DEF",
                                                _getCategoryAvg(
                                                    "3. Savunma & Güç")),
                                            _statPreview(
                                                "PAS",
                                                _getCategoryAvg(
                                                    "4. Pas & Vizyon")),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // BUTONLAR: DETAYLAR
                        ElevatedButton.icon(
                          onPressed: () => _showDetailsDialog(context),
                          icon:
                              const Icon(Icons.analytics, color: Colors.white),
                          label: const Text("DETAYLI ANALİZ & STATLAR",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side:
                                    const BorderSide(color: Colors.cyanAccent)),
                          ),
                        ),

                        // PLAYSTYLES
                        const SizedBox(height: 20),
                        Wrap(
                            spacing: 15,
                            runSpacing: 15,
                            children: selectedPlayer!.playstyles
                                .map((ps) => Image.asset(ps.assetPath,
                                    width: 70, height: 70))
                                .toList()),
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

  Widget _badge(String text, Color c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: c.withOpacity(0.2),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: c)),
      child:
          Text(text, style: TextStyle(color: c, fontWeight: FontWeight.bold)));

  Widget _statPreview(String label, int val) {
    int displayVal = isFMView ? (val / 5).round() : val; // FM Dönüşümü Burada
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        Text("$displayVal",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
      ]),
    );
  }

  int _getCategoryAvg(String cat) {
    if (selectedPlayer == null || selectedPlayer!.stats.isEmpty) return 0;
    List<String> keys = statSegments[cat] ?? [];
    int sum = 0, c = 0;
    for (var k in keys) {
      if (selectedPlayer!.stats.containsKey(k)) {
        sum += selectedPlayer!.stats[k]!;
        c++;
      }
    }
    return c == 0 ? 0 : sum ~/ c;
  }

  Color _getRatingColor(int r) {
    return r >= 90
        ? const Color(0xFF00FFC2)
        : (r >= 80 ? Colors.amber : Colors.white);
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
              backgroundColor: const Color(0xFF101014),
              child: Container(
                width: 700,
                height: 600,
                padding: const EdgeInsets.all(20),
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      Text("${selectedPlayer!.name} - DETAYLI RAPOR",
                          style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent, fontSize: 20)),
                      const TabBar(tabs: [
                        Tab(text: "Fizik & Top"),
                        Tab(text: "Şut"),
                        Tab(text: "Defans"),
                        Tab(text: "Pas")
                      ]),
                      Expanded(
                        child: TabBarView(
                          children: statSegments.keys.map((key) {
                            return ListView(
                              padding: const EdgeInsets.all(20),
                              children:
                                  (statSegments[key] ?? []).map((statName) {
                                int val = selectedPlayer!.stats[statName] ?? 50;
                                int disp = isFMView
                                    ? (val / 5).round()
                                    : val; // FM Dönüşümü
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(statName,
                                          style: const TextStyle(
                                              color: Colors.white70)),
                                      Container(
                                        width: 200,
                                        height: 10,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: LinearProgressIndicator(
                                            value: val / 99,
                                            backgroundColor: Colors.white10,
                                            color: _getRatingColor(val)),
                                      ),
                                      Text("$disp",
                                          style: TextStyle(
                                              color: _getRatingColor(val),
                                              fontWeight: FontWeight.bold))
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }).toList(),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ));
  }
}

// Extension to simulate Gradient Button simply
extension WidgetExt on Widget {
  Widget getApplicationGradient() => this;
}

// --- OYUNCU OLUŞTURMA (Basitleştirilmiş FC Modu - Hata Yok) ---
class CreatePlayerDialog extends StatefulWidget {
  const CreatePlayerDialog({super.key});
  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  // ... (Değişkenler aynı) ...
  final _nameController = TextEditingController();
  final _valController = TextEditingController();
  String _pos = "ST";
  String _team = "Takımsız";
  String _role = "Seçiniz";
  final Map<String, int> _stats = {};
  final Map<String, bool> _ps = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF101014),
      child: Container(
        width: 800,
        height: 800,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("YENİ TRANSFER",
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent, fontSize: 24)),
            // ... (İnputlar aynı, Slider'lar 1-99 arası sabit) ...
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: statSegments.entries.map((entry) {
                    return Column(
                      children: [
                        Text(entry.key,
                            style: const TextStyle(color: Colors.blueAccent)),
                        Wrap(
                            spacing: 20,
                            children: entry.value.map((s) {
                              int v = _stats[s] ?? 50;
                              return SizedBox(
                                  width: 150,
                                  child: Column(children: [
                                    Text(s,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10)),
                                    Slider(
                                        value: v.toDouble(),
                                        min: 1,
                                        max: 99,
                                        onChanged: (val) => setState(
                                            () => _stats[s] = val.toInt())),
                                    Text("$v",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold))
                                  ]));
                            }).toList())
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            ElevatedButton(onPressed: _save, child: const Text("KAYDET"))
          ],
        ),
      ),
    );
  }

  void _save() {
    final p = Player(
        name: _nameController.text,
        rating: 0,
        position: _pos,
        playstyles: [],
        stats: _stats,
        team: _team,
        role: _role,
        marketValue: _valController.text);
    p.calculateRating();
    Hive.box<Player>('palehax_players_v4').add(p);
    Navigator.pop(context);
  }
}
