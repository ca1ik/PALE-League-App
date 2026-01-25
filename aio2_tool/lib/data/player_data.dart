import 'package:hive/hive.dart';

// --- ADAPTERLER AYNI KALIYOR ---
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
      skillMoves: reader.read() ?? 3);
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
  MatchStat read(BinaryReader reader) =>
      MatchStat(reader.read(), reader.read(), reader.read(), reader.read());
  @override
  void write(BinaryWriter writer, MatchStat obj) {
    writer.write(obj.opponent);
    writer.write(obj.score);
    writer.write(obj.goals);
    writer.write(obj.assists);
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
  MatchStat(this.opponent, this.score, this.goals, this.assists);
}

class StrategyModel {
  final String name;
  final String jsonData;
  StrategyModel({required this.name, required this.jsonData});
}

class Player {
  final String name;
  int rating;
  final String position;
  final List<PlayStyle> playstyles;
  final String marketValue;
  final List<MatchStat> matches;
  final String team;
  final Map<String, int> stats;
  final String role;
  final int skillMoves;
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
      this.skillMoves = 3});

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

  // Otomatik Rating Hesaplama
  void calculateRating() {
    if (stats.isEmpty) return;
    double wPace = 1, wShoot = 1, wPass = 1, wDrib = 1, wDef = 1, wPhy = 1;
    if (position == "GK") {
      rating = stats.values.reduce((a, b) => a + b) ~/ stats.length;
      return;
    }
    if (["CB", "LB", "RB"].contains(position)) {
      wDef = 2.2;
      wPhy = 1.8;
      wPace = 1.1;
    } else if (["CDM", "CM"].contains(position)) {
      wPass = 2.2;
      wDef = 1.5;
      wPhy = 1.5;
    } else if (["CAM", "LW", "RW"].contains(position)) {
      wDrib = 2.0;
      wPass = 1.5;
      wPace = 1.5;
      wShoot = 1.2;
    } else if (position == "ST") {
      wShoot = 2.5;
      wPhy = 1.2;
      wPace = 1.5;
    }

    double avgPace = _getAvg(
        statSegments["1. Top Sürme & Fizik"]!); // Segment isimleri aşağıda
    double avgShoot = _getAvg(statSegments["2. Şut & Zihinsel"]!);
    double avgDef = _getAvg(statSegments["3. Savunma & Güç"]!);
    double avgPass = _getAvg(statSegments["4. Pas & Vizyon"]!);

    // Basit bir ağırlıklandırma (Kategorik ortalamalara göre)
    double total =
        (avgPace * wPace + avgShoot * wShoot + avgPass * wPass + avgDef * wDef);
    double weights = wPace + wShoot + wPass + wDef;
    rating = (total / weights).round().clamp(1, 99);
  }

  double _getAvg(List<String> keys) {
    int s = 0, c = 0;
    for (var k in keys) {
      if (stats.containsKey(k)) {
        s += stats[k]!;
        c++;
      }
    }
    return c == 0 ? 50 : s / c;
  }
}

// --- STATİK VERİLER (GÜNCELLENDİ: TEKNİK YER DEĞİŞTİRDİ) ---
final Map<String, List<String>> statSegments = {
  "1. Top Sürme & Fizik": [
    "Hız",
    "Hızlanma",
    "Çeviklik",
    "Denge",
    "Top Sürme",
    "Duvar Kabiliyeti",
    "Teknik"
  ], // Teknik buraya geldi
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
    "Markaj"
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
  "CB": ["Çok Yönlü", "Oyun Kurucu Stoper", "Savunmatik"],
  "LB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü"],
  "RB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü"],
  "CDM": ["Tutucu", "Derin Oyun Kurucu", "Savaşçı"],
  "CM": ["Box to Box", "Oyun Kurucu", "Mezzala"],
  "CAM": ["Oyun Kurucu", "Gölge Forvet", "Enganche"],
  "LW": ["İç Forvet", "Kanat Oyuncusu"],
  "RW": ["İç Forvet", "Kanat Oyuncusu"],
  "ST": ["Hedef Forvet", "Gizli Forvet", "Avcı Forvet", "Yanlış 9"]
};

final List<Player> defaultPlayers =
    []; // Boş başlatıyoruz, Main.dart dolduruyor
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
