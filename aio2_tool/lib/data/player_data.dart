import 'package:hive/hive.dart';

// --- HIVE ADAPTERLERİ ---
class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;
  @override
  Player read(BinaryReader reader) {
    return Player(
      name: reader.read(),
      rating: reader.read(),
      position: reader.read(),
      playstyles: (reader.read() as List).cast<PlayStyle>(),
      marketValue: reader.read(),
      matches: (reader.read() as List).cast<MatchStat>(),
      team: reader.read(),
      stats: (reader.read() as Map?)?.cast<String, int>() ?? {}, // YENİ
      role: reader.read() ?? "Yok", // YENİ
      skillMoves: reader.read() ?? 3, // YENİ
    );
  }

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
  final String
      jsonData; // Oyuncu pozisyonları ve okları JSON string olarak tutacağız
  StrategyModel({required this.name, required this.jsonData});
}

class Player {
  final String name;
  int rating; // Artık hesaplanabilir olduğu için final değil
  final String position;
  final List<PlayStyle> playstyles;
  final String marketValue;
  final List<MatchStat> matches;
  final String team;
  final Map<String, int> stats; // Detaylı İstatistikler (0-99)
  final String role; // Seçilen Rol
  final int skillMoves; // 1-5 Yıldız

  Player({
    required this.name,
    required this.rating,
    required this.position,
    required this.playstyles,
    this.marketValue = "N/A",
    this.matches = const [],
    this.team = "Takımsız",
    this.stats = const {},
    this.role = "Yok",
    this.skillMoves = 3,
  });

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

  // --- REYTİNG HESAPLAMA ALGORİTMASI ---
  void calculateRating() {
    if (stats.isEmpty) return;

    // Ağırlıklar (Mevkiye göre)
    double wPace = 1.0, wShoot = 1.0, wPass = 1.0, wDrib = 1.0, wDef = 1.0;

    if (position == "GK") {
      // Kaleci algoritması (Basitleştirilmiş: Refleksler vs stats içinde olmadığı için genel ortalama)
      rating = stats.values.reduce((a, b) => a + b) ~/ stats.length;
      return;
    } else if (["CB", "LB", "RB", "CDM"].contains(position)) {
      wDef = 2.0;
      wPace = 1.2;
      wPass = 1.1;
      wShoot = 0.5;
      wDrib = 0.8;
    } else if (["CM", "CAM"].contains(position)) {
      wPass = 2.0;
      wDrib = 1.5;
      wShoot = 1.2;
      wPace = 1.0;
      wDef = 0.8;
    } else if (["LW", "RW", "ST"].contains(position)) {
      wShoot = 2.0;
      wPace = 1.5;
      wDrib = 1.5;
      wPass = 1.0;
      wDef = 0.2;
    }

    // Kategorik Ortalamalar
    double avgPace = _getAvg(["Hız", "Hızlanma", "Çeviklik", "Denge"]);
    double avgShoot =
        _getAvg(["Bitiricilik", "Şut Gücü", "Pozisyon Alma", "Uzaktan Şut"]);
    double avgPass = _getAvg(["Pas", "Ara Pas", "Görüş", "Orta Yapma"]);
    double avgDrib =
        _getAvg(["Top Sürme", "Top Kontrolü", "Teknik", "Soğukkanlılık"]);
    double avgDef = _getAvg(["Top Kapma", "Markaj", "Güç", "Saldırganlık"]);

    double totalScore = (avgPace * wPace) +
        (avgShoot * wShoot) +
        (avgPass * wPass) +
        (avgDrib * wDrib) +
        (avgDef * wDef);
    double totalWeight = wPace + wShoot + wPass + wDrib + wDef;

    rating = (totalScore / totalWeight).round().clamp(1, 99);
  }

  double _getAvg(List<String> keys) {
    int sum = 0;
    int count = 0;
    for (var key in keys) {
      if (stats.containsKey(key)) {
        sum += stats[key]!;
        count++;
      }
    }
    return count == 0 ? 50 : sum / count;
  }
}

// --- STATİK VERİLER ---
final Map<String, List<String>> roleCategories = {
  "GK": ["Çizgi Kalecisi", "Süpürücü Kaleci", "Oyun Kurucu Kaleci"],
  "CB": ["Çok Yönlü", "Oyun Kurucu Stoper", "Savunmatik"],
  "LB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü"],
  "RB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü"],
  "CDM": ["Tutucu", "Derin Oyun Kurucu", "Savaşçı"],
  "CM": ["Box to Box", "Oyun Kurucu", "Mezzala"],
  "CAM": ["Oyun Kurucu", "Gölge Forvet", "Enganche"],
  "LW": ["İç Forvet", "Kanat Oyuncusu", "Yırtıcı Kanat"],
  "RW": ["İç Forvet", "Kanat Oyuncusu", "Yırtıcı Kanat"],
  "ST": [
    "Hedef Forvet",
    "Gizli Forvet",
    "Avcı Forvet",
    "Yanlış 9",
    "Yırtıcı Forvet"
  ],
};

final Map<String, List<String>> statSegments = {
  "1. Top Sürme & Fizik": [
    "Hız",
    "Hızlanma",
    "Çeviklik",
    "Denge",
    "Top Sürme",
    "Duvar Kabiliyeti"
  ],
  "2. Şut & Zihinsel": [
    "Şut Gücü",
    "Pozisyon Alma",
    "Bitiricilik",
    "Uzaktan Şut",
    "Soğukkanlılık"
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
    "Karar Alma",
    "Orta Yapma",
    "Top Kontrolü"
  ],
};

// Varsayılan oyuncular (Eski liste korundu)
final List<Player> defaultPlayers = [
  // ... Eski oyuncu listesi (stats boş olarak gelir, sorun değil) ...
];

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
