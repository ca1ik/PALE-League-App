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
      stats: (reader.read() as Map?)?.cast<String, int>() ?? {},
      role: reader.read() ?? "Yok",
      skillMoves: reader.read() ?? 3,
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

// --- VERİ MODELLERİ ---
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
  final String jsonData; // Oyuncu pozisyonları JSON string olarak tutulur
  StrategyModel({required this.name, required this.jsonData});
}

class Player {
  final String name;
  int rating; // Hesaplanabilir olduğu için mutable
  final String position;
  final List<PlayStyle> playstyles;
  final String marketValue;
  final List<MatchStat> matches;
  final String team;

  // YENİ ÖZELLİKLER
  final Map<String, int> stats; // 0-99 arası değerler
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

  // --- GELİŞMİŞ REYTİNG ALGORİTMASI ---
  void calculateRating() {
    if (stats.isEmpty) return;

    // Ağırlık Katsayıları
    double wPace = 1.0,
        wShoot = 1.0,
        wPass = 1.0,
        wDrib = 1.0,
        wDef = 1.0,
        wPhy = 1.0;

    // Mevkiye göre ağırlık belirleme
    switch (position) {
      case "GK":
        // Kaleci için basit ortalama (Refleks vs statları olmadığı için)
        rating = stats.values.reduce((a, b) => a + b) ~/ stats.length;
        return;
      case "CB":
      case "LB":
      case "RB":
        wDef = 2.2;
        wPhy = 1.8;
        wPace = 1.1;
        wPass = 0.8;
        wDrib = 0.5;
        wShoot = 0.2;
        break;
      case "CDM":
        wDef = 2.0;
        wPhy = 1.8;
        wPass = 1.5;
        wPace = 0.8;
        wDrib = 0.8;
        wShoot = 0.5;
        break;
      case "CM":
      case "CAM":
        wPass = 2.2;
        wDrib = 1.8;
        wShoot = 1.2;
        wPace = 1.0;
        wDef = 0.8;
        wPhy = 0.8;
        break;
      case "LW":
      case "RW":
        wPace = 2.2;
        wDrib = 2.0;
        wShoot = 1.5;
        wPass = 1.2;
        wPhy = 0.5;
        wDef = 0.2;
        break;
      case "ST":
        wShoot = 2.5;
        wPhy = 1.2;
        wPace = 1.5;
        wDrib = 1.2;
        wPass = 0.8;
        wDef = 0.1;
        break;
    }

    // Segment Ortalamaları
    double avgPace = _getAvg(["Hız", "Hızlanma", "Çeviklik", "Denge"]);
    double avgShoot =
        _getAvg(["Bitiricilik", "Şut Gücü", "Pozisyon Alma", "Uzaktan Şut"]);
    double avgPass =
        _getAvg(["Pas", "Ara Pas", "Görüş", "Orta Yapma", "Karar Alma"]);
    double avgDrib =
        _getAvg(["Top Sürme", "Top Kontrolü", "Teknik", "Soğukkanlılık"]);
    double avgDef =
        _getAvg(["Top Kapma", "Markaj", "Savunma Farkındalığı", "Top Kesme"]);
    double avgPhy =
        _getAvg(["Güç", "Saldırganlık", "Sert Duruş", "Duvar Kabiliyeti"]);

    // Ağırlıklı Ortalama Hesaplama
    double totalScore = (avgPace * wPace) +
        (avgShoot * wShoot) +
        (avgPass * wPass) +
        (avgDrib * wDrib) +
        (avgDef * wDef) +
        (avgPhy * wPhy);
    double totalWeight = wPace + wShoot + wPass + wDrib + wDef + wPhy;

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
    return count == 0 ? 50.0 : sum / count;
  }
}

// --- STATİK LİSTELER ---
final Map<String, List<String>> roleCategories = {
  "GK": ["Çizgi Kalecisi", "Süpürücü Kaleci", "Oyun Kurucu Kaleci"],
  "CB": ["Çok Yönlü", "Oyun Kurucu Stoper", "Savunmatik", "Libero"],
  "LB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü Bek", "Defansif Bek"],
  "RB": ["Kanat Bek", "Hücum Bek", "Çok Yönlü Bek", "Defansif Bek"],
  "CDM": ["Tutucu", "Derin Oyun Kurucu", "Savaşçı Orta Saha", "Regista"],
  "CM": ["Box to Box", "Oyun Kurucu", "Mezzala", "İki Yönlü"],
  "CAM": ["Oyun Kurucu", "Gölge Forvet", "Enganche", "Ofansif Orta Saha"],
  "LW": ["İç Forvet", "Kanat Oyuncusu", "Yırtıcı Kanat", "Ters Ayaklı Kanat"],
  "RW": ["İç Forvet", "Kanat Oyuncusu", "Yırtıcı Kanat", "Ters Ayaklı Kanat"],
  "ST": [
    "Hedef Forvet",
    "Gizli Forvet",
    "Avcı Forvet",
    "Yanlış 9",
    "Yırtıcı Forvet",
    "Pivot"
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
    "Markaj",
    "Top Kesme"
  ],
  "4. Pas & Vizyon": [
    "Pas",
    "Ara Pas",
    "Takım Oyunu",
    "Görüş",
    "Topsuz Alan",
    "Karar Alma",
    "Orta Yapma",
    "Top Kontrolü",
    "Teknik"
  ],
};

// V4 İçin Varsayılan Oyuncular
final List<Player> defaultPlayers = [
  Player(
    name: "Ronaldo Иazário de Lima",
    rating: 94,
    position: "LW",
    marketValue: "120M €",
    team: "Takımsız",
    role: "İç Forvet",
    skillMoves: 5,
    stats: {"Hız": 95, "Bitiricilik": 96, "Top Sürme": 97, "Teknik": 98},
    matches: [
      MatchStat("Barcelona", "3-1", 1, 2),
      MatchStat("Real Madrid", "2-2", 0, 2)
    ],
    playstyles: [
      PlayStyle("Trickster", isGold: true),
      PlayStyle("Technical"),
      PlayStyle("Rapid")
    ],
  ),
  // ... Diğer oyuncular da benzer formatta eklenebilir
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
