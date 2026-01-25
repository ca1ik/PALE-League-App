import 'dart:math';
import 'package:hive/hive.dart';

// --- HIVE ADAPTERLERİ ---
class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;
  @override
  Player read(BinaryReader reader) => Player(
      name: reader.read(),
      rating: reader.read(),
      position: reader.read(),
      playstyles: (reader.read() as List).cast<PlayStyle>(),
      marketValue: reader.read(),
      matches: (reader.read() as List).cast<MatchStat>(),
      team: reader.read(),
      stats: (reader.read() as Map?)?.cast<String, int>() ?? {},
      role: reader.read() ?? "Yok",
      skillMoves: reader.read() ?? 3,
      country: reader.read() ?? "Türkiye",
      chemistryStyle: reader.read() ?? "Temel");
  @override
  void write(BinaryWriter writer, Player obj) {
    writer.write(obj.name);
    writer.write(obj.rating);
    writer.write(obj.position);
    writer.write(obj.playstyles);
    writer.write(obj.marketValue);
    writer.write(obj.matches);
    writer.write(obj.team);
    writer.write(obj.stats);
    writer.write(obj.role);
    writer.write(obj.skillMoves);
    writer.write(obj.country);
    writer.write(obj.chemistryStyle);
  }
}

class PlayStyleAdapter extends TypeAdapter<PlayStyle> {
  @override
  final int typeId = 2;
  @override
  PlayStyle read(BinaryReader reader) =>
      PlayStyle(reader.read(), isGold: reader.read());
  @override
  void write(BinaryWriter writer, PlayStyle obj) {
    writer.write(obj.name);
    writer.write(obj.isGold);
  }
}

class MatchStatAdapter extends TypeAdapter<MatchStat> {
  @override
  final int typeId = 3;
  @override
  MatchStat read(BinaryReader reader) => MatchStat(reader.read(), reader.read(),
      reader.read(), reader.read(), reader.read());
  @override
  void write(BinaryWriter writer, MatchStat obj) {
    writer.write(obj.opponent);
    writer.write(obj.score);
    writer.write(obj.goals);
    writer.write(obj.assists);
    writer.write(obj.rating);
  }
}

class StrategyAdapter extends TypeAdapter<StrategyModel> {
  @override
  final int typeId = 4;
  @override
  StrategyModel read(BinaryReader reader) =>
      StrategyModel(name: reader.read(), jsonData: reader.read());
  @override
  void write(BinaryWriter writer, StrategyModel obj) {
    writer.write(obj.name);
    writer.write(obj.jsonData);
  }
}

// --- MODELLER ---
class PlayStyle {
  final String name;
  final bool isGold;
  PlayStyle(this.name, {this.isGold = false});
  String get assetPath =>
      "assets/Playstyles/${isGold ? "${name}Plus" : name}.png";
}

class MatchStat {
  final String opponent;
  final String score;
  final int goals;
  final int assists;
  final double rating;
  MatchStat(this.opponent, this.score, this.goals, this.assists, this.rating);
}

class StrategyModel extends HiveObject {
  final String name;
  final String jsonData;
  StrategyModel({required this.name, required this.jsonData});
}

// --- PLAYER SINIFI ---
class Player extends HiveObject {
  String name;
  int rating;
  String position;
  List<PlayStyle> playstyles;
  String marketValue;
  List<MatchStat> matches;
  String team;
  Map<String, int> stats;
  String role;
  int skillMoves;
  String country;
  String chemistryStyle; // YENİ: Kimya Stili

  Player(
      {required this.name,
      required this.rating,
      required this.position,
      required this.playstyles,
      this.marketValue = "N/A",
      this.matches = const [],
      this.team = "Takımsız",
      this.stats = const {},
      this.role = "Yok",
      this.skillMoves = 3,
      this.country = "Türkiye",
      this.chemistryStyle = "Temel"});

  int get kitNumber {
    switch (position.toUpperCase()) {
      case 'GK':
        return 1;
      case 'CB':
        return 3;
      case 'CDM':
        return 6;
      case 'CM':
        return 10;
      case 'RW':
        return 7;
      case 'LW':
        return 11;
      case 'ST':
        return 9;
      default:
        return 99;
    }
  }

  // Segment Ortalamaları
  Map<String, int> getCardStats() {
    return {
      "PAC": _getAvg(statSegments["1. Top Sürme & Fizik"]!.sublist(0, 4)),
      "SHO": _getAvg(statSegments["2. Şut & Zihinsel"]!),
      "PAS": _getAvg(statSegments["4. Pas & Vizyon"]!),
      "DRI": _getAvg(["Top Sürme", "Teknik", "Çeviklik", "Denge"]),
      "DEF": _getAvg(statSegments["3. Savunma & Güç"]!),
      "PHY": _getAvg(["Güç", "Saldırganlık", "Sert Duruş", "Duvar Kabiliyeti"]),
    };
  }

  void calculateRating() {
    if (stats.isEmpty) return;
    var cs = getCardStats();
    double total = (cs["PAC"]! * 1.2 +
        cs["SHO"]! * 1.5 +
        cs["PAS"]! * 1.0 +
        cs["DRI"]! * 1.2 +
        cs["DEF"]! * 0.2 +
        cs["PHY"]! * 0.8);
    // Kimya bonusu reytingi hafif etkilesin (Opsiyonel)
    rating = (total / 5.9).round().clamp(1, 99);
  }

  void generateRandomMatches() {
    final random = Random();
    matches = List.generate(5, (index) {
      int g = position == "GK"
          ? 0
          : (position == "ST" ? random.nextInt(3) : random.nextInt(2));
      int a = random.nextInt(2);
      double r = 6.0 + random.nextDouble() * 4.0;
      return MatchStat(
          "Hafta ${5 - index}",
          "${random.nextInt(4)}-${random.nextInt(4)}",
          g,
          a,
          double.parse(r.toStringAsFixed(1)));
    });
  }

  int _getAvg(List<String> keys) {
    int s = 0, c = 0;
    for (var k in keys) {
      if (stats.containsKey(k)) {
        s += stats[k]!;
        c++;
      }
    }
    return c == 0 ? 50 : (s / c).round();
  }
}

// --- KİMYA STİLLERİ VE BONUSLARI (YENİ) ---
final Map<String, Map<String, int>> chemistryBonuses = {
  "Temel": {
    "Hız": 2,
    "Çeviklik": 1,
    "Savunma Farkındalığı": 2,
    "Bitiricilik": 1
  },
  "Omurga": {"Top Kesme": 4, "Savunma Farkındalığı": 3, "Güç": 3},
  "Motor": {"Hız": 2, "Pas": 4, "Ara Pas": 2, "Görüş": 1, "Güç": 1},
  "Muhafız": {
    "Güç": 4,
    "Soğukkanlılık": 2,
    "Savunma Farkındalığı": 3,
    "Top Kesme": 1
  },
  "Güçlü": {"Güç": 5, "Savunma Farkındalığı": 3, "Hız": 1, "Saldırganlık": 2},
  "Gölge": {
    "Güç": 1,
    "Savunma Farkındalığı": 3,
    "Hız": 3,
    "Pas": 1,
    "Soğukkanlılık": 2
  },
  "Mimar": {
    "Pas": 4,
    "Ara Pas": 2,
    "Görüş": 3,
    "Çeviklik": 2,
    "Top Kontrolü": 2
  },
  "Sanatçı": {"Pas": 2, "Ara Pas": 2, "Görüş": 3, "Çeviklik": 3, "Teknik": 4},
  "Nişancı": {"Bitiricilik": 4, "Şut Gücü": 3, "Görüş": 2, "Güç": 1},
  "Maestro": {"Pas": 4, "Ara Pas": 4, "Görüş": 4},
  "Avcı": {"Bitiricilik": 3, "Hız": 3, "Çeviklik": 3, "Görüş": 2},
  "Keskin Nişancı": {"Bitiricilik": 5, "Şut Gücü": 4, "Görüş": 2},
  "Şahin": {"Bitiricilik": 2, "Hız": 5, "Şut Gücü": 2, "Güç": 3},
  "Bitirici": {"Bitiricilik": 6, "Hız": 3, "Şut Gücü": 3, "Güç": 1},
};

// --- DİĞER LİSTELER ---
final Map<String, List<String>> statSegments = {
  "1. Top Sürme & Fizik": [
    "Hız",
    "Hızlanma",
    "Çeviklik",
    "Denge",
    "Top Sürme",
    "Duvar Kabiliyeti",
    "Teknik"
  ],
  "2. Şut & Zihinsel": [
    "Şut Gücü",
    "Pozisyon Alma",
    "Bitiricilik",
    "Uzaktan Şut",
    "Soğukkanlılık",
    "Karar Alma"
  ],
  "3. Savunma & Güç": [
    "Top Kapma",
    "Savunma Farkındalığı",
    "Sert Duruş",
    "Güç",
    "Saldırganlık",
    "Markaj",
    "Top Kesme"
  ],
  "4. Pas & Vizyon": [
    "Pas",
    "Ara Pas",
    "Takım Oyunu",
    "Görüş",
    "Topsuz Alan",
    "Orta Yapma",
    "Top Kontrolü"
  ],
};

final Map<String, List<String>> roleCategories = {
  "GK": ["Çizgi Kalecisi", "Süpürücü Kaleci", "Oyun Kurucu Kaleci"],
  "CB": ["Çok Yönlü", "Oyun Kurucu Stoper", "Savunmatik", "Libero"],
  "LB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü"],
  "RB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü"],
  "CDM": ["Tutucu", "Derin Oyun Kurucu", "Savaşçı"],
  "CM": ["Box to Box", "Oyun Kurucu", "Mezzala"],
  "CAM": ["Oyun Kurucu", "Gölge Forvet", "Enganche"],
  "LW": ["İç Forvet", "Kanat Oyuncusu"],
  "RW": ["İç Forvet", "Kanat Oyuncusu"],
  "ST": ["Hedef Forvet", "Gizli Forvet", "Avcı Forvet", "Yanlış 9"]
};

final List<Player> defaultPlayers = [];
final List<String> availableTeams = [
  "Takımsız",
  "Livorno",
  "Toulouse",
  "Invicta",
  "Maximilian",
  "Werder Weremem",
  "Bursa Spor",
  "CA RIVER PLATE",
  "Fenerbahçe",
  "Shamrock Rovers",
  "Chelsea",
  "It Spor",
  "Tiyatro FC",
  "La Mama de Nico",
  "Juventus",
  "Theis FC"
];
final List<String> availablePlayStyles = [
  "Acrobatic",
  "AerialFortress",
  "Anticipate",
  "Block",
  "Bruiser",
  "CrossClaimer",
  "FarReach",
  "FinesseShot",
  "FirstTouch",
  "Footwork",
  "GameChanger",
  "IncisivePass",
  "Intercept",
  "Inventive",
  "Jockey",
  "LongBallPass",
  "PingedPass",
  "PowerShot",
  "PressProven",
  "QuickStep",
  "Rapid",
  "RushOut",
  "SlideTackle",
  "Technical",
  "TikiTaka",
  "Trickster",
  "WhippedPass"
];
final List<String> availablePositions = [
  "GK",
  "CB",
  "LB",
  "RB",
  "CDM",
  "CM",
  "CAM",
  "LW",
  "RW",
  "ST"
];
