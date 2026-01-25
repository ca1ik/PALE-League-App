import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'strategy_maker_module.dart';
import 'squad_builder_module.dart';

class ChallengeHub extends StatelessWidget {
  const ChallengeHub({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 0, // Tab barı aşağı alıyoruz
          bottom: const TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.draw), text: "STRATEJİ TAHTASI"),
              Tab(icon: Icon(Icons.people_alt), text: "KADRO YARAT & TOTW"),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            StrategyMakerModule(), // Eski Taktik Tahtası
            SquadBuilderModule(), // Yeni Kadro Kurucu
          ],
        ),
      ),
    );
  }
}
