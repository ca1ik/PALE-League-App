import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class ScraperService {
  static const String baseUrl = "https://palehaxball.com";

  static Future<Map<String, dynamic>> fetchTeamDetails(String teamSlug) async {
    try {
      final url = Uri.parse("$baseUrl/takim/$teamSlug");
      final response = await http.get(url);
      if (response.statusCode != 200) return {};

      var document = parser.parse(response.body);

      // 1. Kadro Değerini Çek
      String marketValue = "Bilinmiyor";
      var cells = document.querySelectorAll('td');
      for (var c in cells) {
        if (c.text.contains("€")) {
          marketValue = c.text.trim();
          break;
        }
      }

      // 2. Oyuncuları Çek (player-row ve strong yapısı)
      List<Map<String, dynamic>> players = [];
      var rows = document.querySelectorAll('.player-row');

      for (var row in rows) {
        var info = row.querySelector('.player-row__info .strong');
        if (info != null) {
          String raw = info.text.trim();
          bool isCaptain = raw.contains('⭐') || info.innerHtml.contains('⭐');
          String clean = raw.replaceAll('⭐', '').trim();
          if (clean.isNotEmpty) {
            players.add({"name": clean, "isCaptain": isCaptain});
          }
        }
      }

      // Kaptanlar en üste
      players.sort(
          (a, b) => (b['isCaptain'] ? 1 : 0).compareTo(a['isCaptain'] ? 1 : 0));

      return {"marketValue": marketValue, "players": players.take(18).toList()};
    } catch (e) {
      return {"marketValue": "Hata", "players": []};
    }
  }

  static Future<List<Map<String, dynamic>>> fetchStandings() async {
    try {
      final url = Uri.parse("$baseUrl/puan");
      final response = await http.get(url);
      if (response.statusCode != 200) return [];
      var doc = parser.parse(response.body);
      List<Map<String, dynamic>> res = [];
      var rows = doc.querySelectorAll('table tr');
      for (int i = 1; i < rows.length; i++) {
        var c = rows[i].querySelectorAll('td');
        if (c.length >= 7) {
          res.add({
            "rank": c[0].text.trim(),
            "team": c[1].text.trim(),
            "played": c[2].text.trim(),
            "won": c[3].text.trim(),
            "drawn": c[4].text.trim(),
            "lost": c[5].text.trim(),
            "gd": c.length > 8 ? c[8].text.trim() : "-",
            "points": c[c.length - 1].text.trim(),
          });
        }
      }
      return res;
    } catch (e) {
      return [];
    }
  }
}
