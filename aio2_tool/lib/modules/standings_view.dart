import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scraper_service.dart';
import 'pale_webview.dart'; // Bu dosyanın aşağıda verdiğim kodla oluşturulduğundan emin ol

class StandingsView extends StatefulWidget {
  const StandingsView({super.key});
  @override
  State<StandingsView> createState() => _StandingsViewState();
}

class _StandingsViewState extends State<StandingsView> {
  bool isWeb = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text("LİG PUAN DURUMU",
                style: GoogleFonts.orbitron(
                    color: Colors.cyanAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            Container(
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  _btn("APP", !isWeb, () => setState(() => isWeb = false)),
                  _btn("WEB", isWeb, () => setState(() => isWeb = true)),
                ])),
          ]),
        ),
        Expanded(
            child: isWeb
                // DÜZELTME: 'const' kelimesi kaldırıldı.
                ? const PaleWebView(url: "https://palehaxball.com/puan")
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: ScraperService.fetchStandings(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.cyanAccent));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text("Veri alınamadı veya liste boş.",
                                style: TextStyle(color: Colors.white)));
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Theme(
                            data: Theme.of(context)
                                .copyWith(dividerColor: Colors.white10),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                  Colors.cyanAccent.withOpacity(0.1)),
                              columns: const [
                                DataColumn(
                                    label: Text("#",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("TAKIM",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("O",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("G",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("B",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("M",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("AV",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                                DataColumn(
                                    label: Text("P",
                                        style: TextStyle(
                                            color: Colors.cyanAccent))),
                              ],
                              rows: snapshot.data!
                                  .map((row) => DataRow(cells: [
                                        // DÜZELTME: .toString() eklenerek tip güvenliği sağlandı
                                        DataCell(Text(
                                            row['rank']?.toString() ?? "-",
                                            style: const TextStyle(
                                                color: Colors.white70))),
                                        DataCell(Text(
                                            row['team']?.toString() ?? "-",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold))),
                                        DataCell(Text(
                                            row['played']?.toString() ?? "0",
                                            style: const TextStyle(
                                                color: Colors.white70))),
                                        DataCell(Text(
                                            row['won']?.toString() ?? "0",
                                            style: const TextStyle(
                                                color: Colors.greenAccent))),
                                        DataCell(Text(
                                            row['drawn']?.toString() ?? "0",
                                            style: const TextStyle(
                                                color: Colors.white70))),
                                        DataCell(Text(
                                            row['lost']?.toString() ?? "0",
                                            style: const TextStyle(
                                                color: Colors.redAccent))),
                                        DataCell(Text(
                                            row['gd']?.toString() ?? "0",
                                            style: const TextStyle(
                                                color: Colors.white70))),
                                        DataCell(Text(
                                            row['points']?.toString() ?? "0",
                                            style: GoogleFonts.orbitron(
                                                color: Colors.cyanAccent,
                                                fontWeight: FontWeight.bold))),
                                      ]))
                                  .toList(),
                            ),
                          ),
                        ),
                      );
                    }))
      ]),
    );
  }

  Widget _btn(String t, bool a, VoidCallback o) => GestureDetector(
      onTap: o,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
              color: a ? Colors.cyanAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(20)),
          child: Text(t,
              style: TextStyle(
                  color: a ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold))));
}
