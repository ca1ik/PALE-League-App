import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/player_data.dart';
import '../ui/fc_animated_card.dart';

// --- WIKI SEKME İÇERİĞİ ---
class SubTabPlayStyles extends StatefulWidget {
  const SubTabPlayStyles({super.key});
  @override
  State<SubTabPlayStyles> createState() => _SubTabPlayStylesState();
}

class _SubTabPlayStylesState extends State<SubTabPlayStyles>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // LEDLİ META KUTUSU
          AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.cyanAccent.withOpacity(
                                0.5 + (_pulseController.value * 0.5)),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.cyanAccent.withOpacity(
                                  0.2 + (_pulseController.value * 0.3)),
                              blurRadius: 20,
                              spreadRadius: 2)
                        ]),
                    child: Column(children: [
                      Text("V7 META ANALİZİ",
                          style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                              shadows: [
                                const Shadow(color: Colors.cyan, blurRadius: 15)
                              ])),
                      const SizedBox(height: 25),
                      ...metaPlaystyles.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 180,
                                    child: Text(m['role'],
                                        style: GoogleFonts.russoOne(
                                            color: Colors.cyanAccent,
                                            fontSize: 18))),
                                Expanded(
                                    child: Text(m['styles'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            height: 1.4)))
                              ])))
                    ]));
              }),
          // KATEGORİLER
          ...playStyleCategories.entries.map((entry) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(entry.key,
                        style: GoogleFonts.orbitron(
                            color: Colors.greenAccent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold))),
                GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 2.8,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10),
                    itemCount: entry.value.length,
                    itemBuilder: (c, i) {
                      var ps = entry.value[i];
                      return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24)),
                          child: Row(children: [
                            Image.asset("assets/Playstyles/${ps['name']}.png",
                                width: 45,
                                height: 45,
                                errorBuilder: (c, e, s) => const Icon(
                                    Icons.help,
                                    color: Colors.white,
                                    size: 30)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  Text(ps['label']!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16)),
                                  Text(ps['desc']!,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis)
                                ]))
                          ]));
                    }),
                const SizedBox(height: 30)
              ]))
        ]));
  }
}

// --- KARTLAR SEKME İÇERİĞİ ---
class SubTabCardTypes extends StatelessWidget {
  const SubTabCardTypes({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        padding: const EdgeInsets.all(30),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.7,
            crossAxisSpacing: 30,
            mainAxisSpacing: 30),
        itemCount: cardTypes.length,
        itemBuilder: (c, i) {
          String type = cardTypes[i];
          // DUMMY KART (Gerçek görünüm)
          Player dummyP = Player(
              name: "ÖRNEK",
              rating: 90,
              position: "ST",
              playstyles: [],
              cardType: type,
              chemistryStyle: "Temel",
              team: "PaleHax",
              role: "Golcü",
              matches: [],
              seasons: []);
          return GestureDetector(
              onTap: () => _showCardDetail(context, type, dummyP),
              child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Column(children: [
                    Expanded(
                        child: Transform.scale(
                            scale: 0.9, child: FCAnimatedCard(player: dummyP))),
                    const SizedBox(height: 10),
                    Text(type,
                        style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold))
                  ])));
        });
  }

  void _showCardDetail(BuildContext context, String type, Player p) {
    showDialog(
        context: context,
        builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
                width: 400,
                height: 600,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(type,
                          style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 30,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Transform.scale(
                          scale: 1.1, child: FCAnimatedCard(player: p)),
                      const SizedBox(height: 40),
                      Text(cardTypeDescriptions[type] ?? "",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white10),
                          child: const Text("KAPAT",
                              style: TextStyle(color: Colors.white)))
                    ]))));
  }
}

// --- ROLLER SEKME İÇERİĞİ ---
class SubTabRoles extends StatelessWidget {
  const SubTabRoles({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(30),
        children: roleCategories.entries
            .map((e) =>
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.key,
                      style: GoogleFonts.orbitron(
                          color: Colors.amber,
                          fontSize: 26,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ...e.value.map((r) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r,
                                style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 5),
                            Text(
                                roleDescriptions[r] ??
                                    "Bu rol hakkında detaylı bilgi wiki sayfasında.",
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14))
                          ]))),
                  const Divider(color: Colors.white24, height: 50)
                ]))
            .toList());
  }
}
