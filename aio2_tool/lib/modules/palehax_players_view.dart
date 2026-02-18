import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';

// Kendi proje yapına göre bu importları kontrol et
import '../data/player_data.dart' as pd;
import '../data/player_data.dart' show Player, PlayStyle;
import '../services/database_service.dart';
import '../ui/fc_animated_card.dart';
import 'pale_webview.dart';

// ============================================================================
// BÖLÜM 1: ANA VIEW
// ============================================================================

class PaleHaxPlayersView extends StatefulWidget {
  const PaleHaxPlayersView({super.key});
  @override
  State<PaleHaxPlayersView> createState() => _PaleHaxPlayersViewState();
}

class _PaleHaxPlayersViewState extends State<PaleHaxPlayersView> {
  @override
  Widget build(BuildContext context) {
    final database = Provider.of<AppDatabase>(context);
    // TabController kaldırıldı, tek sayfa akışı kullanıyoruz
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _SubTabPlayers(database: database),
    );
  }
}

// ============================================================================
// BÖLÜM 2: OYUNCU LİSTESİ VE DETAY YÖNETİMİ
// ============================================================================

class _SubTabPlayers extends StatefulWidget {
  final AppDatabase database;
  const _SubTabPlayers({required this.database});
  @override
  State<_SubTabPlayers> createState() => _SubTabPlayersState();
}

class _SubTabPlayersState extends State<_SubTabPlayers> {
  Player? selectedPlayer;

  // Veritabanından gelen veriyi modele çeviren güvenli fonksiyon
  Player _convert(dynamic t) {
    Map<String, int> st = {};
    List<PlayStyle> ps = [];
    try {
      st = Map<String, int>.from(jsonDecode(t.statsJson));
    } catch (_) {}
    try {
      var l = jsonDecode(t.playStylesJson) as List;
      ps = l.map((e) => PlayStyle(e.toString())).toList();
    } catch (_) {}

    return Player(
      name: t.name,
      rating: t.rating,
      position: t.position,
      playstyles: ps,
      cardType: t.cardType,
      team: t.team,
      stats: st,
      role: t.role,
      recLink: t.recLink ?? "",
      manualGoals: t.manualGoals,
      manualAssists: t.manualAssists,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
        stream: widget.database.watchAllPlayers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final all = snapshot.data!.map(_convert).toList();

          if (all.isEmpty) {
            return Center(
                child: ElevatedButton(
                    onPressed: () =>
                        _showEditor(context, null, (p) => _save(p, true)),
                    child: const Text("İLK OYUNCUYU EKLE")));
          }

          // Seçili oyuncu yoksa ilkini seç
          if (selectedPlayer == null ||
              !all.any((p) => p.name == selectedPlayer!.name)) {
            selectedPlayer = all.first;
          } else {
            selectedPlayer =
                all.firstWhere((p) => p.name == selectedPlayer!.name);
          }

          Player displayPlayer = selectedPlayer!;

          return Row(children: [
            // --- SOL MENÜ (OYUNCU LİSTESİ) ---
            Container(
                width: 280,
                decoration: BoxDecoration(
                    color: const Color(0xFF0D0D12),
                    border: Border(
                        right:
                            BorderSide(color: Colors.white.withOpacity(0.1)))),
                child: Column(children: [
                  // Global Kartlar ve Yeni Oyuncu Butonları
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          _buildMenuButton(
                            "GLOBAL KARTLAR",
                            Icons.public,
                            Colors.purpleAccent,
                            () => _showGlobal(context, widget.database, (pT) {
                              // Globalden seçileni yeni oyuncu olarak ekle veya göster
                              _showEditor(
                                  context, _convert(pT), (p) => _save(p, true));
                            }),
                          ),
                          const SizedBox(height: 10),
                          _buildMenuButton(
                            "YENİ OYUNCU",
                            Icons.person_add,
                            Colors.cyanAccent,
                            () => _showEditor(
                                context, null, (p) => _save(p, true)),
                            textColor: Colors.black,
                          ),
                        ],
                      )),
                  const Divider(color: Colors.white12),
                  // Oyuncu Listesi
                  Expanded(
                      child: ListView.builder(
                          itemCount: all.length,
                          itemBuilder: (c, i) {
                            final p = all[i];
                            bool isSelected = selectedPlayer?.name == p.name &&
                                selectedPlayer?.cardType == p.cardType;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                  onTap: () => setState(() {
                                        selectedPlayer = p;
                                      }),
                                  leading: Text("${p.rating}",
                                      style: GoogleFonts.russoOne(
                                          color: _getRatingColor(p.rating),
                                          fontSize: 20)),
                                  title: Text(p.name,
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.white70,
                                          fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(p.cardType,
                                      style: TextStyle(
                                          color: _getCardColor(p.cardType),
                                          fontSize: 10)),
                                  trailing: isSelected
                                      ? const Icon(Icons.arrow_forward_ios,
                                          color: Colors.cyanAccent, size: 14)
                                      : null),
                            );
                          }))
                ])),

            // --- SAĞ TARAF (PROFIL DETAY) ---
            Expanded(
                child: Container(
              color: const Color(0xFF16161E), // Modern koyu arka plan
              child: _ViewUltimate(
                player: displayPlayer,
                onEdit: () =>
                    _showEditor(context, displayPlayer, (p) => _save(p, false)),
                onDelete: () => _delete(displayPlayer),
                onStatsUpdate: (goals, assists) {
                  // Manuel maç eklenince burası tetiklenir ve DB güncellenir
                  int newGoals = displayPlayer.manualGoals + goals;
                  int newAssists = displayPlayer.manualAssists + assists;

                  Player updated = Player(
                      name: displayPlayer.name,
                      rating: displayPlayer.rating,
                      position: displayPlayer.position,
                      team: displayPlayer.team,
                      cardType: displayPlayer.cardType,
                      playstyles: displayPlayer.playstyles,
                      stats: displayPlayer.stats,
                      role: displayPlayer.role,
                      recLink: displayPlayer.recLink,
                      manualGoals: newGoals,
                      manualAssists: newAssists,
                      skillMoves: displayPlayer.skillMoves,
                      chemistryStyle: displayPlayer.chemistryStyle);
                  _save(updated, false);
                },
              ),
            ))
          ]);
        });
  }

  Widget _buildMenuButton(
      String text, IconData icon, Color color, VoidCallback onTap,
      {Color textColor = Colors.white}) {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(text,
                  style: GoogleFonts.russoOne(color: textColor, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void _save(Player p, bool isNew) async {
    dynamic companion = PlayerTablesCompanion(
      name: drift.Value(p.name),
      rating: drift.Value(p.rating),
      position: drift.Value(p.position),
      team: drift.Value(p.team),
      cardType: drift.Value(p.cardType),
      role: drift.Value(p.role),
      marketValue: drift.Value(p.marketValue),
      statsJson: drift.Value(jsonEncode(p.stats)),
      playStylesJson:
          drift.Value(jsonEncode(p.playstyles.map((e) => e.name).toList())),
      recLink: drift.Value(p.recLink),
      manualGoals: drift.Value(p.manualGoals),
      manualAssists: drift.Value(p.manualAssists),
    );
    await widget.database.insertPlayer(companion);
    setState(() {});
  }

  void _delete(Player p) async {
    await widget.database.deletePlayerByNameAndType(p.name, p.cardType);
    setState(() {
      selectedPlayer = null;
    });
  }
}

// ============================================================================
// BÖLÜM 3: ULTIMATE PROFİL GÖRÜNÜMÜ (YENİLENMİŞ TASARIM)
// ============================================================================

class _ViewUltimate extends StatefulWidget {
  final Player player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int, int) onStatsUpdate;

  const _ViewUltimate({
    required this.player,
    required this.onEdit,
    required this.onDelete,
    required this.onStatsUpdate,
  });

  @override
  State<_ViewUltimate> createState() => _ViewUltimateState();
}

class _ViewUltimateState extends State<_ViewUltimate> {
  late TextEditingController _aiCommentController;
  bool _isEditingComment = false;

  @override
  void initState() {
    super.initState();
    _aiCommentController = TextEditingController();
    _generateAIAnalysis();
  }

  @override
  void didUpdateWidget(covariant _ViewUltimate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player.name != widget.player.name) {
      _generateAIAnalysis();
    }
  }

  void _generateAIAnalysis() {
    // "Ballandıra ballandıra" anlatan yapay zeka mantığı
    Player p = widget.player;
    StringBuffer sb = StringBuffer();

    sb.write("${p.name}, sahada varlığını hissettiren bir ${p.role}. ");

    // İstatistik Analizi
    if ((p.stats['Şut Gücü'] ?? 0) > 85) {
      sb.write(
          "Ayağından çıkan toplar adeta bir füze! Mesafe tanımaksızın kalecileri avlayabilen ölümcül bir bitirici. ");
    }
    if ((p.stats['Kısa Pas'] ?? 0) > 88) {
      sb.write(
          "Oyun görüşü ve pas kalitesiyle takımın beyni. İğne deliğinden pas geçirerek oyunu çözer. ");
    }
    if ((p.stats['Dripling'] ?? 0) > 90) {
      sb.write(
          "Top ayağına yapışıyor! Rakip savunmayı ipe dizercesine geçen, durdurulması imkansız bir dribling ustası. ");
    }
    if ((p.stats['Top Çalma'] ?? 0) > 85) {
      sb.write(
          "Savunmada geçit vermeyen bir duvar. Kritik müdahaleleriyle takımını ipten alır. ");
    }

    // Playstyle Analizi
    if (p.playstyles.isNotEmpty) sb.write("\n\n");
    for (var ps in p.playstyles) {
      if (ps.name == "PowerShot")
        sb.write("PowerShot özelliğiyle fileleri yırtacak şutlar çıkarır. ");
      if (ps.name == "Technical")
        sb.write(
            "Technical yeteneği sayesinde dar alanlarda büyücülük yapar. ");
      if (ps.name == "TikiTaka")
        sb.write("Tiki-Taka oyununun merkezinde, topu asla kaybetmez. ");
      if (ps.name == "Rapid")
        sb.write(
            "Rüzgar gibi hızlı! Savunma arkasına yaptığı koşularla kabus olur. ");
      if (ps.name == "FinesseShot")
        sb.write(
            "Plase vuruşları bir sanat eseri gibidir, kaleciyi çaresiz bırakır. ");
      if (ps.name == "Intercept")
        sb.write(
            "Topu mıknatıs gibi çeker, pas arası yapma konusunda uzmandır. ");
    }

    _aiCommentController.text = sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    bool isGK = widget.player.position.contains("GK");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SOL KOLON (KART VE DETAYLAR) ---
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KART VE TEMEL BİLGİLER
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FCAnimatedCard(player: widget.player, animateOnHover: true),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(widget.player.name.toUpperCase(),
                                  style: GoogleFonts.russoOne(
                                      fontSize: 42,
                                      color: Colors.white,
                                      height: 1)),
                              PopupMenuButton(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white54),
                                color: const Color(0xFF1E1E24),
                                itemBuilder: (c) => [
                                  PopupMenuItem(
                                    onTap: widget.onEdit,
                                    child: const Row(children: [
                                      Icon(Icons.edit,
                                          color: Colors.cyanAccent),
                                      SizedBox(width: 10),
                                      Text("Düzenle",
                                          style: TextStyle(color: Colors.white))
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    onTap: widget.onDelete,
                                    child: const Row(children: [
                                      Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      SizedBox(width: 10),
                                      Text("Sil",
                                          style: TextStyle(color: Colors.white))
                                    ]),
                                  ),
                                ],
                              )
                            ],
                          ),
                          Text(
                              "${widget.player.position} | ${widget.player.team}",
                              style: GoogleFonts.montserrat(
                                  fontSize: 20, color: Colors.white70)),

                          const SizedBox(height: 30),

                          // PLAYSTYLES (İkon + İsim)
                          Text("OYUN STİLLERİ",
                              style: GoogleFonts.russoOne(
                                  fontSize: 16, color: Colors.amber)),
                          const SizedBox(height: 10),
                          _buildPlayStylesList(widget.player),
                        ],
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 40),
                const Divider(color: Colors.white12),

                // PROFİL DETAYLARI
                Text("PROFİL DETAYLARI",
                    style: GoogleFonts.russoOne(
                        fontSize: 24, color: Colors.white)),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: [
                    _buildInfoTag(Icons.science, "Kimya",
                        widget.player.chemistryStyle, Colors.purpleAccent),
                    _buildInfoTag(Icons.theater_comedy, "Rol",
                        widget.player.role, Colors.orangeAccent),
                    _buildInfoTag(
                        Icons.star,
                        "Yetenek",
                        "${widget.player.skillMoves} Yıldız",
                        Colors.yellowAccent),
                    _buildInfoTag(Icons.euro, "Değer",
                        widget.player.marketValue, Colors.greenAccent),
                  ],
                ),

                const SizedBox(height: 30),

                // İSTATİSTİKLER (KATEGORİZE)
                ...pd.statSegments.entries.map((entry) {
                  String category = entry.key;
                  List<String> statsList = entry.value;
                  if (isGK && !['Kaleci', 'Fizik', 'Zeka'].contains(category))
                    return const SizedBox.shrink();
                  if (!isGK && category == 'Kaleci')
                    return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Icon(Icons.bar_chart,
                              color: Colors.cyanAccent.withOpacity(0.7),
                              size: 18),
                          const SizedBox(width: 8),
                          Text(category.toUpperCase(),
                              style: GoogleFonts.russoOne(
                                  color: Colors.cyanAccent, fontSize: 16)),
                        ]),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: statsList.map((statName) {
                          int value = widget.player.stats[statName] ?? 0;
                          return _buildModernStatBox(statName, value);
                        }).toList(),
                      ),
                      const SizedBox(height: 15),
                    ],
                  );
                }).toList(),

                // MANUEL MAÇ İSTATİSTİKLERİ VE GRAFİK
                const SizedBox(height: 30),
                _buildSeasonStatsSection(),
              ],
            ),
          ),

          const SizedBox(width: 30),

          // --- SAĞ KOLON (YAPAY ZEKA YORUMU) ---
          Expanded(
            flex: 3,
            child: Container(
              height: 600,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("YAPAY ZEKA ANALİZİ",
                          style: GoogleFonts.orbitron(
                              color: Colors.redAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(
                            _isEditingComment ? Icons.check : Icons.edit_note,
                            color: Colors.white54),
                        onPressed: () => setState(
                            () => _isEditingComment = !_isEditingComment),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: TextField(
                      controller: _aiCommentController,
                      enabled: _isEditingComment,
                      maxLines: null,
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 15, height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Yapay zeka yorumu bekleniyor...",
                        hintStyle: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                  if (!_isEditingComment)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text("Natroff AI v2.0",
                          style: GoogleFonts.orbitron(
                              color: Colors.white24, fontSize: 10)),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // PlayStyle İkonları ve İsimleri
  Widget _buildPlayStylesList(Player p) {
    if (p.playstyles.isEmpty)
      return const Text("Yok", style: TextStyle(color: Colors.white54));
    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: p.playstyles.map((ps) {
        // İkon yolu - Plus ise farklı klasörden
        String iconPath = ps.isGold
            ? "assets/Playstyles/plus/${ps.name}Plus.png"
            : ps.assetPath;

        return Column(
          children: [
            Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: ps.isGold
                        ? Colors.amber.withOpacity(0.1)
                        : Colors.white10,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ps.isGold ? Colors.amber : Colors.white24,
                        width: 2),
                    boxShadow: ps.isGold
                        ? [
                            BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 10)
                          ]
                        : []),
                child: Image.asset(iconPath,
                    color: ps.isGold ? null : Colors.white70)),
            const SizedBox(height: 5),
            Text(ps.name,
                style: GoogleFonts.montserrat(
                    color: ps.isGold ? Colors.amber : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold))
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInfoTag(IconData i, String l, String v, Color c) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
            color: c.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, color: c, size: 18),
          const SizedBox(width: 10),
          Text("$l: ", style: const TextStyle(color: Colors.white70)),
          Text(v,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold))
        ]));
  }

  Widget _buildModernStatBox(String l, int v) {
    Color c = v >= 90
        ? Colors.greenAccent
        : (v >= 80 ? Colors.green : (v >= 70 ? Colors.amber : Colors.red));
    return Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.3))),
        child: Column(children: [
          Text("$v", style: GoogleFonts.russoOne(fontSize: 22, color: c)),
          Text(l,
              style: const TextStyle(fontSize: 9, color: Colors.white54),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis)
        ]));
  }

  // --- MANUEL MAÇ İSTATİSTİKLERİ VE GRAFİK ---
  Widget _buildSeasonStatsSection() {
    int goals = widget.player.manualGoals;
    int assists = widget.player.manualAssists;
    int contribution = goals + assists;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SEZON PERFORMANSI (Manuel Giriş)",
                  style:
                      GoogleFonts.russoOne(color: Colors.white, fontSize: 18)),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (c) => _AddMatchDialog(
                            onAdd: (g, a, r) {
                              widget.onStatsUpdate(g, a); // DB'yi güncelle
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(
                                      "Maç eklendi! Toplam: ${goals + g} Gol, ${assists + a} Asist")));
                            },
                          ));
                },
                icon: const Icon(Icons.add_circle, color: Colors.black),
                label: const Text("MAÇ EKLE",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBigStat("GOL", "$goals", Colors.greenAccent),
              _buildBigStat("ASİST", "$assists", Colors.blueAccent),
              _buildBigStat(
                  "TOPLAM KATKI", "$contribution", Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 20),
          // Grafik (Basit Bar Grafik Simülasyonu)
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (index) {
                // Rastgele ama tutarlı bir grafik (ID bazlı seed)
                // Gerçek maç geçmişi olmadığı için görsel zenginlik
                var r = Random(widget.player.name.length + index);
                double height = 20 + r.nextInt(80).toDouble();
                double rating = 5 + r.nextInt(5).toDouble();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("$rating",
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 10)),
                    Container(
                      width: 15,
                      height: height,
                      decoration: BoxDecoration(
                          color: rating >= 8
                              ? Colors.greenAccent
                              : (rating >= 6 ? Colors.amber : Colors.red),
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    const SizedBox(height: 5),
                    Text("M${index + 1}",
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 10)),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
              child: Text("Son 10 Maç Reyting Grafiği",
                  style: TextStyle(color: Colors.white24, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildBigStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.russoOne(fontSize: 32, color: color)),
        Text(label,
            style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white54))
      ],
    );
  }
}

class _AddMatchDialog extends StatelessWidget {
  final Function(int, int, double) onAdd;
  _AddMatchDialog({required this.onAdd});

  final TextEditingController gC = TextEditingController();
  final TextEditingController aC = TextEditingController();
  final TextEditingController rC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      title: const Text("Maç İstatistiği Ekle",
          style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _input("Gol", gC),
          _input("Asist", aC),
          _input("Reyting (0.0 - 10.0)", rC),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal")),
        ElevatedButton(
            onPressed: () {
              onAdd(int.tryParse(gC.text) ?? 0, int.tryParse(aC.text) ?? 0,
                  double.tryParse(rC.text) ?? 0.0);
              Navigator.pop(context);
            },
            child: const Text("Ekle"))
      ],
    );
  }

  Widget _input(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24)),
        ),
      ),
    );
  }
}

// ============================================================================
// BÖLÜM 4: EDİTÖR VE GLOBAL KARTLAR
// ============================================================================

void _showEditor(BuildContext context, Player? p, Function(Player) onSave) {
  showDialog(
      context: context,
      builder: (context) => CreatePlayerDialog(
          playerToEdit: p,
          onSave: (player) {
            if (player != null) onSave(player);
          }));
}

void _showGlobal(
    BuildContext context, AppDatabase db, Function(dynamic) onSelect) {
  showDialog(
      context: context,
      builder: (c) => Dialog(
          backgroundColor: const Color(0xFF0D0D12),
          child: Container(
              width: 1100,
              height: 850,
              padding: const EdgeInsets.all(25),
              child: Column(children: [
                Text("GLOBAL KART HAVUZU",
                    style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                // ÖZEL KARTLAR VİTRİNİ (TOTS, MVP vs.)
                Container(
                  height: 320, // Vitrin Yüksekliği
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("⭐ ÖZEL KOLEKSİYON (TOTS / MVP / STAR)",
                          style: GoogleFonts.russoOne(
                              color: Colors.amber, fontSize: 16)),
                      const SizedBox(height: 15),
                      Expanded(
                        child: StreamBuilder<List<dynamic>>(
                            stream: db.watchFilteredPlayers(
                                searchQuery: "",
                                cardTypeFilter: "Tümü",
                                sortOption: "Reyting"),
                            builder: (c, sn) {
                              if (!sn.hasData)
                                return const Center(
                                    child: CircularProgressIndicator());
                              // Sadece özel kartları filtrele
                              var specials = sn.data!
                                  .where((p) => [
                                        "TOTS",
                                        "MVP",
                                        "STAR",
                                        "BALLOND'OR"
                                      ].contains(p.cardType))
                                  .toList();
                              if (specials.isEmpty)
                                return const Center(
                                    child: Text("Özel kart bulunamadı.",
                                        style:
                                            TextStyle(color: Colors.white54)));
                              return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: specials.length,
                                  itemBuilder: (c, i) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: GestureDetector(
                                        onTap: () {
                                          onSelect(specials[i]);
                                          Navigator.pop(c);
                                        },
                                        child: Transform.scale(
                                            scale: 0.9,
                                            child: FCAnimatedCard(
                                                player:
                                                    _staticConvert(specials[i]),
                                                animateOnHover: true)),
                                      ),
                                    );
                                  });
                            }),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),
                const Text("TÜM KARTLAR",
                    style: TextStyle(color: Colors.white54)),
                Expanded(
                    child: StreamBuilder<List<dynamic>>(
                        stream: db.watchFilteredPlayers(
                            searchQuery: "",
                            cardTypeFilter: "Tümü",
                            sortOption: "Reyting"),
                        builder: (c, sn) {
                          if (!sn.hasData)
                            return const Center(
                                child: CircularProgressIndicator());
                          return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6, childAspectRatio: 0.6),
                              itemCount: sn.data!.length,
                              itemBuilder: (c, i) {
                                return GestureDetector(
                                    onTap: () {
                                      onSelect(sn.data![i]);
                                      Navigator.pop(c);
                                    },
                                    child: Transform.scale(
                                        scale: 0.85,
                                        child: FCAnimatedCard(
                                            player:
                                                _staticConvert(sn.data![i]))));
                              });
                        }))
              ]))));
}

// Yardımcı statik dönüştürücü (Global pencere için)
Player _staticConvert(dynamic t) {
  Map<String, int> st = {};
  List<PlayStyle> ps = [];
  try {
    st = Map<String, int>.from(jsonDecode(t.statsJson));
  } catch (_) {}
  try {
    var l = jsonDecode(t.playStylesJson) as List;
    ps = l.map((e) => PlayStyle(e.toString())).toList();
  } catch (_) {}
  return Player(
      name: t.name,
      rating: t.rating,
      position: t.position,
      playstyles: ps,
      cardType: t.cardType,
      team: t.team,
      stats: st,
      role: t.role,
      manualGoals: t.manualGoals,
      manualAssists: t.manualAssists);
}

// ============================================================================
// BÖLÜM 5: CREATE PLAYER DIALOG (TAKIM LOGOLU)
// ============================================================================

class CreatePlayerDialog extends StatefulWidget {
  final Player? playerToEdit;
  final Function(Player?) onSave;

  const CreatePlayerDialog(
      {super.key, this.playerToEdit, required this.onSave});

  @override
  State<CreatePlayerDialog> createState() => _CreatePlayerDialogState();
}

class _CreatePlayerDialogState extends State<CreatePlayerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _ratingController;
  late TextEditingController _recLinkController;

  String selectedPosition = "(9) ST";
  String selectedCardType = "Temel";
  String selectedRole = "Avcı Forvet";
  String selectedTeam = "Takımsız";
  List<PlayStyle> selectedPlayStyles = [];
  Map<String, int> stats = {};

  @override
  void initState() {
    super.initState();
    Player p = widget.playerToEdit ??
        Player(
            name: "",
            rating: 75,
            position: "(9) ST",
            playstyles: [],
            cardType: "Temel",
            team: "Takımsız");
    _nameController = TextEditingController(text: p.name);
    _ratingController = TextEditingController(text: p.rating.toString());
    _recLinkController = TextEditingController(text: p.recLink);
    selectedPosition = p.position;
    selectedCardType = p.cardType;
    selectedRole = p.role;
    // Takım logosu var mı kontrol et, yoksa varsayılanı seç
    selectedTeam = pd.teamLogos.containsKey(p.team)
        ? p.team
        : (pd.teamLogos.keys.isNotEmpty ? pd.teamLogos.keys.first : "Takımsız");
    selectedPlayStyles = List.from(p.playstyles);
    stats = Map<String, int>.from(p.stats);
    if (stats.isEmpty)
      pd.statSegments.values.expand((e) => e).forEach((s) => stats[s] = 50);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E24),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 1000,
        height: 800,
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          Text(
              widget.playerToEdit == null
                  ? "YENİ OYUNCU OLUŞTUR"
                  : "OYUNCUYU DÜZENLE",
              style: GoogleFonts.orbitron(
                  color: Colors.cyanAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white24, height: 30),
          Expanded(
            child: Row(children: [
              // SOL: Temel Bilgiler
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _input("Ad Soyad", _nameController),
                        _input("Reyting", _ratingController, isNum: true),

                        // TAKIM SEÇİMİ (LOGOLU)
                        const Text("Takım",
                            style:
                                TextStyle(color: Colors.white54, fontSize: 12)),
                        Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white12)),
                          child: DropdownButton<String>(
                            value: selectedTeam,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2C2C35),
                            underline: const SizedBox(),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (v) => setState(() => selectedTeam = v!),
                            items: pd.teamLogos.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: Row(children: [
                                  Image.asset(e.value,
                                      width: 24,
                                      height: 24,
                                      errorBuilder: (c, e, s) =>
                                          const Icon(Icons.shield, size: 16)),
                                  const SizedBox(width: 10),
                                  Text(e.key)
                                ]),
                              );
                            }).toList(),
                          ),
                        ),

                        _dropdown("Pozisyon", pd.positions, selectedPosition,
                            (v) => setState(() => selectedPosition = v!)),
                        _dropdown(
                            "Kart Tipi",
                            pd.globalCardTypes,
                            selectedCardType,
                            (v) => setState(() => selectedCardType = v!)),
                        _dropdown(
                            "Rol",
                            roleDescriptions.keys.toList(),
                            selectedRole,
                            (v) => setState(() => selectedRole = v!)),
                        _input("Video Linki", _recLinkController),
                      ]),
                ),
              ),
              const VerticalDivider(width: 40, color: Colors.white10),
              // SAĞ: İstatistikler ve Playstyle
              Expanded(
                  flex: 2,
                  child: DefaultTabController(
                      length: 2,
                      child: Column(children: [
                        const TabBar(indicatorColor: Colors.cyanAccent, tabs: [
                          Tab(text: "İSTATİSTİKLER"),
                          Tab(text: "OYUN STİLLERİ")
                        ]),
                        Expanded(
                          child: TabBarView(children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 20),
                              child: Wrap(
                                  spacing: 20,
                                  runSpacing: 20,
                                  children:
                                      pd.statSegments.entries.map((entry) {
                                    return Container(
                                      width: 250,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(entry.key,
                                                style: const TextStyle(
                                                    color: Colors.amber,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 10),
                                            ...entry.value.map((s) =>
                                                Row(children: [
                                                  Expanded(
                                                      flex: 2,
                                                      child: Text(s,
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .white70,
                                                                  fontSize:
                                                                      12))),
                                                  Expanded(
                                                      flex: 3,
                                                      child: Slider(
                                                          value:
                                                              (stats[s] ?? 50)
                                                                  .toDouble(),
                                                          min: 0,
                                                          max: 99,
                                                          activeColor:
                                                              Colors.cyanAccent,
                                                          inactiveColor:
                                                              Colors.white10,
                                                          onChanged: (v) =>
                                                              setState(() =>
                                                                  stats[s] = v
                                                                      .toInt()))),
                                                  Text("${stats[s] ?? 50}",
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold))
                                                ]))
                                          ]),
                                    );
                                  }).toList()),
                            ),
                            SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 20),
                              child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: playStyleCategories.values
                                      .expand((e) => e)
                                      .map((psData) {
                                    bool isSelected = selectedPlayStyles
                                        .any((p) => p.name == psData['name']);
                                    bool isGold = isSelected &&
                                        selectedPlayStyles
                                            .firstWhere(
                                                (p) => p.name == psData['name'])
                                            .isGold;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            if (!isGold) {
                                              selectedPlayStyles.removeWhere(
                                                  (p) =>
                                                      p.name == psData['name']);
                                              selectedPlayStyles.add(PlayStyle(
                                                  psData['name']!,
                                                  isGold: true));
                                            } else {
                                              selectedPlayStyles.removeWhere(
                                                  (p) =>
                                                      p.name == psData['name']);
                                            }
                                          } else {
                                            selectedPlayStyles.add(PlayStyle(
                                                psData['name']!,
                                                isGold: false));
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                            color: isSelected
                                                ? (isGold
                                                    ? Colors.amber
                                                        .withOpacity(0.2)
                                                    : Colors.cyanAccent
                                                        .withOpacity(0.2))
                                                : Colors.white10,
                                            border: Border.all(
                                                color: isSelected
                                                    ? (isGold
                                                        ? Colors.amber
                                                        : Colors.cyanAccent)
                                                    : Colors.transparent),
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                  isGold
                                                      ? Icons.star
                                                      : Icons.check,
                                                  size: 14,
                                                  color: isGold
                                                      ? Colors.amber
                                                      : Colors.cyanAccent),
                                              const SizedBox(width: 5),
                                              Text(psData['label']!,
                                                  style: TextStyle(
                                                      color: isSelected
                                                          ? Colors.white
                                                          : Colors.white54,
                                                      fontSize: 12))
                                            ]),
                                      ),
                                    );
                                  }).toList()),
                            )
                          ]),
                        )
                      ])))
            ]),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("İPTAL",
                    style: TextStyle(color: Colors.white54))),
            const SizedBox(width: 20),
            ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save, color: Colors.black),
                label: const Text("KAYDET",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15)))
          ])
        ]),
      ),
    );
  }

  void _submit() {
    if (_nameController.text.isEmpty) return;
    Player newP = Player(
      name: _nameController.text,
      rating: int.tryParse(_ratingController.text) ?? 75,
      position: selectedPosition,
      team: selectedTeam,
      cardType: selectedCardType,
      playstyles: selectedPlayStyles,
      stats: stats,
      role: selectedRole,
      recLink: _recLinkController.text,
      manualGoals: widget.playerToEdit?.manualGoals ?? 0,
      manualAssists: widget.playerToEdit?.manualAssists ?? 0,
    );
    widget.onSave(newP);
    Navigator.pop(context);
  }

  Widget _input(String label, TextEditingController c, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black26,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String val,
      Function(String?) onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: items.contains(val) ? val : items.first,
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white))))
            .toList(),
        onChanged: onChange,
        dropdownColor: const Color(0xFF2C2C35),
        decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black26,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}

// Renk yardımcıları
Color _getRatingColor(int r) =>
    r >= 90 ? const Color(0xFF00FFC2) : (r >= 80 ? Colors.amber : Colors.white);
Color _getCardColor(String t) {
  switch (t) {
    case "TOTS":
      return Colors.cyanAccent;
    case "BALLOND'OR":
      return Colors.amber;
    case "MVP":
      return Colors.redAccent;
    default:
      return Colors.white54;
  }
}
