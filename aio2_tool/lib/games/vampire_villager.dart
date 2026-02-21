import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VampireVillagerGame extends StatefulWidget {
  const VampireVillagerGame({super.key});

  @override
  State<VampireVillagerGame> createState() => _VampireVillagerGameState();
}

enum GamePhase { setup, roleView, night, day, gameOver }

enum Role { villager, vampire, doctor }

class Player {
  String name;
  Role role;
  bool isAlive;
  bool isProtected; // Doktor tarafından korundu mu?

  Player(
      {required this.name,
      this.role = Role.villager,
      this.isAlive = true,
      this.isProtected = false});
}

class _VampireVillagerGameState extends State<VampireVillagerGame> {
  GamePhase _phase = GamePhase.setup;
  List<Player> _players = [];
  final TextEditingController _nameController = TextEditingController();
  int _vampireCount = 1;
  int _doctorCount = 1;
  String _logText = "Oyun Başladı.";
  int _dayCount = 1;

  // Rol Gösterme Sırası için
  int _roleRevealIndex = 0;
  bool _isRoleVisible = false;

  // --- SETUP ---
  void _addPlayer() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _players.add(Player(name: _nameController.text.trim()));
        _nameController.clear();
      });
    }
  }

  void _assignRoles() {
    if (_players.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("En az 3 oyuncu gerekli!")));
      return;
    }

    // Reset
    for (var p in _players) {
      p.role = Role.villager;
      p.isAlive = true;
    }

    var rng = Random();
    int assignedVamps = 0;
    int assignedDocs = 0;

    // Vampir Ata
    while (assignedVamps < _vampireCount) {
      int idx = rng.nextInt(_players.length);
      if (_players[idx].role == Role.villager) {
        _players[idx].role = Role.vampire;
        assignedVamps++;
      }
    }

    // Doktor Ata
    while (assignedDocs < _doctorCount) {
      int idx = rng.nextInt(_players.length);
      if (_players[idx].role == Role.villager) {
        // Sadece köylü olanı doktor yap
        _players[idx].role = Role.doctor;
        assignedDocs++;
      }
    }

    setState(() {
      _phase = GamePhase.roleView;
      _roleRevealIndex = 0;
    });
  }

  // --- OYUN DÖNGÜSÜ ---
  void _nextPhase() {
    setState(() {
      if (_phase == GamePhase.night) {
        // Gündüze Geçiş (Gece Olaylarını İşle)
        for (var p in _players) {
          if (!p.isAlive) continue; // Zaten ölü
          // Burada basitlik adına manuel öldürme yapıyoruz
          // Gerçek mantıkta Vampirlerin seçimi burada işlenirdi
          p.isProtected = false; // Koruma sıfırlanır
        }
        _logText = "☀️ GÜN $_dayCount BAŞLADI!\nLütfen ölenleri işaretleyin.";
        _dayCount++;
        _phase = GamePhase.day;
      } else if (_phase == GamePhase.day) {
        // Geceye Geçiş
        _logText =
            "🌙 GECE $_dayCount\nHerkes uyusun. Vampirler uyanıp birini seçsin.";
        _phase = GamePhase.night;
      }
    });
    _checkWinCondition();
  }

  void _toggleLife(Player p) {
    if (_phase == GamePhase.roleView) return;
    setState(() {
      p.isAlive = !p.isAlive;
      _logText =
          p.isAlive ? "${p.name} canlandırıldı." : "${p.name} öldürüldü!";
    });
    _checkWinCondition();
  }

  void _checkWinCondition() {
    int vamps =
        _players.where((p) => p.isAlive && p.role == Role.vampire).length;
    int others =
        _players.where((p) => p.isAlive && p.role != Role.vampire).length;

    if (vamps == 0) {
      _showGameOver("KÖYLÜLER KAZANDI! 🎉");
    } else if (vamps >= others) {
      _showGameOver("VAMPİRLER KAZANDI! 🩸");
    }
  }

  void _showGameOver(String msg) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
              backgroundColor: Colors.black87,
              title: Text("OYUN BİTTİ",
                  style: GoogleFonts.russoOne(color: Colors.white)),
              content: Text(msg,
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(c);
                      setState(() {
                        _phase = GamePhase.setup;
                        _players.clear();
                        _dayCount = 1;
                      });
                    },
                    child: const Text("YENİ OYUN"))
              ],
            ));
  }

  // --- UI PARÇALARI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0505), // Kan kırmızısı koyu tema
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text("VAMPİR KÖYLÜ YÖNETİCİSİ",
            style:
                GoogleFonts.butcherman(color: Colors.redAccent, fontSize: 24)),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case GamePhase.setup:
        return _buildSetup();
      case GamePhase.roleView:
        return _buildRoleReveal();
      case GamePhase.night:
      case GamePhase.day:
        return _buildGameLoop();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSetup() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                hintText: "Oyuncu Adı Girin...",
                hintStyle: const TextStyle(color: Colors.white30),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.redAccent),
                    onPressed: _addPlayer),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10))),
            onSubmitted: (_) => _addPlayer(),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _counter("Vampir Sayısı", _vampireCount,
                (v) => setState(() => _vampireCount = v)),
            _counter("Doktor Sayısı", _doctorCount,
                (v) => setState(() => _doctorCount = v)),
          ]),
          const Divider(color: Colors.redAccent),
          Expanded(
            child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (c, i) => ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: Text(_players[i].name,
                          style: const TextStyle(color: Colors.white)),
                      trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              setState(() => _players.removeAt(i))),
                    )),
          ),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
              onPressed: _players.length >= 3 ? _assignRoles : null,
              child: const Text("ROLLERİ DAĞIT VE BAŞLA",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _counter(String label, int val, Function(int) onChange) {
    return Column(children: [
      Text(label, style: const TextStyle(color: Colors.white70)),
      Row(children: [
        IconButton(
            icon: const Icon(Icons.remove, color: Colors.white),
            onPressed: () => onChange(max(0, val - 1))),
        Text("$val",
            style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => onChange(val + 1)),
      ])
    ]);
  }

  Widget _buildRoleReveal() {
    Player currentP = _players[_roleRevealIndex];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("TELEFONU ŞU KİŞİYE VER:",
              style: GoogleFonts.orbitron(color: Colors.white54)),
          const SizedBox(height: 20),
          Text(currentP.name.toUpperCase(),
              style: GoogleFonts.russoOne(color: Colors.white, fontSize: 40)),
          const SizedBox(height: 50),
          if (_isRoleVisible) ...[
            Icon(_getRoleIcon(currentP.role),
                size: 100, color: _getRoleColor(currentP.role)),
            Text(_getRoleName(currentP.role),
                style: GoogleFonts.butcherman(
                    color: _getRoleColor(currentP.role), fontSize: 40)),
            const SizedBox(height: 20),
            const Text("Rolünü gördüysen devam et.",
                style: TextStyle(color: Colors.white54)),
          ] else ...[
            const Icon(Icons.fingerprint, size: 80, color: Colors.white24),
            const Text("Rolü görmek için basılı tut veya tıkla",
                style: TextStyle(color: Colors.white24)),
          ],
          const SizedBox(height: 50),
          GestureDetector(
            onLongPress: () => setState(() => _isRoleVisible = true),
            onLongPressUp: () => setState(() => _isRoleVisible = false),
            onTap: () {
              if (_isRoleVisible) {
                setState(() {
                  _isRoleVisible = false;
                  if (_roleRevealIndex < _players.length - 1) {
                    _roleRevealIndex++;
                  } else {
                    _phase = GamePhase.night; // Herkes gördüyse geceye geç
                    _logText = "🌙 GECE BAŞLADI. Herkes uyusun!";
                  }
                });
              } else {
                setState(() => _isRoleVisible = true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                  color: _isRoleVisible ? Colors.green : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color:
                            _isRoleVisible ? Colors.greenAccent : Colors.black,
                        blurRadius: 20)
                  ]),
              child: Text(_isRoleVisible ? "SONRAKİ >" : "GÖSTER",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGameLoop() {
    bool isNight = _phase == GamePhase.night;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color:
                  isNight ? const Color(0xFF0A0A10) : const Color(0xFFFFF5E0),
              border: const Border(bottom: BorderSide(color: Colors.white12))),
          child: Column(
            children: [
              Icon(isNight ? Icons.nightlight_round : Icons.wb_sunny,
                  size: 50,
                  color: isNight ? Colors.purpleAccent : Colors.orange),
              const SizedBox(height: 10),
              Text(isNight ? "GECE FAZI" : "GÜNDÜZ FAZI",
                  style: GoogleFonts.russoOne(
                      color: isNight ? Colors.white : Colors.black,
                      fontSize: 24)),
              Text(_logText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isNight ? Colors.white70 : Colors.black87)),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10),
            itemCount: _players.length,
            itemBuilder: (c, i) {
              final p = _players[i];
              return GestureDetector(
                onTap: () => _toggleLife(p), // Yönetici tıklar öldürür/diriltir
                child: Opacity(
                  opacity: p.isAlive ? 1.0 : 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: p.isAlive
                                ? (p.role == Role.vampire && !isNight
                                    ? Colors.white10
                                    : _getRoleColor(p.role))
                                : Colors.red,
                            width: 2)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(p.isAlive ? Icons.person : Icons.cancel,
                            size: 40, color: Colors.white),
                        const SizedBox(height: 5),
                        Text(p.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        // Yönetici rolü her zaman görür (silik şekilde)
                        Text(p.isAlive ? _getRoleName(p.role) : "ÖLDÜ",
                            style:
                                TextStyle(color: Colors.white30, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(15),
                backgroundColor: isNight ? Colors.orange : Colors.purple),
            onPressed: _nextPhase,
            icon: Icon(isNight ? Icons.wb_sunny : Icons.nightlight_round),
            label: Text(isNight ? "GÜNDÜZE GEÇ" : "GECEYE GEÇ",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )
      ],
    );
  }

  IconData _getRoleIcon(Role r) {
    switch (r) {
      case Role.vampire:
        return Icons.bloodtype;
      case Role.doctor:
        return Icons.medical_services;
      default:
        return Icons.person;
    }
  }

  String _getRoleName(Role r) {
    switch (r) {
      case Role.vampire:
        return "VAMPİR";
      case Role.doctor:
        return "DOKTOR";
      default:
        return "KÖYLÜ";
    }
  }

  Color _getRoleColor(Role r) {
    switch (r) {
      case Role.vampire:
        return Colors.red;
      case Role.doctor:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}
