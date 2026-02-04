import 'dart:math';
import 'package:flutter/material.dart';
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
  Player read(BinaryReader reader) {
      role: reader.read() ?? "Yok",
      skillMoves: reader.read() ?? 3,
      country: reader.read() ?? "Türkiye",
      chemistryStyle: reader.read() ?? "Temel",
      cardType: reader.read() ?? "Temel",
      seasons: (reader.read() as List?)?.cast<SeasonStat>() ?? [],
      recLink: reader.read() ?? "",
      manualGoals: reader.read() ?? 0,
      manualAssists: reader.read() ?? 0,
      manualMatches: reader.read() ?? 0,
      instruction: reader.read() ?? "Balanced");
  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..write(obj.name)
      ..write(obj.rating)
      ..write(obj.position)
      ..write(obj.playstyles)
      ..write(obj.marketValue)
      ..write(obj.matches)
      ..write(obj.team)
      ..write(obj.stats)
      ..write(obj.role)
      ..write(obj.skillMoves)
      ..write(obj.country)
      ..write(obj.chemistryStyle)
      ..write(obj.cardType)
      ..write(obj.seasons)
      ..write(obj.recLink)
      ..write(obj.manualGoals)
      ..write(obj.manualAssists)
      ..write(obj.manualMatches)
      ..write(obj.instruction);
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

class SeasonStatAdapter extends TypeAdapter<SeasonStat> {
  @override
  final int typeId = 5;
  @override
  SeasonStat read(BinaryReader reader) => SeasonStat(reader.read(),
      reader.read(), reader.read(), reader.read(), reader.read());
  @override
  void write(BinaryWriter writer, SeasonStat obj) {
    writer.write(obj.season);
    writer.write(obj.avgRating);
    writer.write(obj.goals);
    writer.write(obj.assists);
    writer.write(obj.isMVP);
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
  String get assetPath => isGold
      ? "assets/Playstyles/plus/${name}Plus.png"
      : "assets/Playstyles/$name.png";
}

class MatchStat {
  final String opponent;
  final String score;
  final int goals;
  final int assists;
  final double rating;
  MatchStat(this.opponent, this.score, this.goals, this.assists, this.rating);
}

class SeasonStat {
  final String season;
  final double avgRating;
  final int goals;
  final int assists;
  final bool isMVP;
  SeasonStat(this.season, this.avgRating, this.goals, this.assists, this.isMVP);
}

class StrategyModel extends HiveObject {
  final String name;
  final String jsonData;
  StrategyModel({required this.name, required this.jsonData});
}

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
  String chemistryStyle;
  String cardType;
  String recLink;
  List<SeasonStat> seasons;
  int manualGoals, manualAssists, manualMatches;
  String instruction;

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
      this.chemistryStyle = "Temel",
      this.cardType = "Temel",
      this.seasons = const [],
      this.recLink = "",
      this.manualGoals = 0,
      this.manualAssists = 0,
      this.manualMatches = 0,
      this.instruction = "Balanced"});

  // --- GETTERLAR VE HESAPLAMALAR ---

  int get kitNumber {
    if (position.contains("GK")) return 1;
    if (position.contains("CDM")) return 6;
    if (position.contains("CAM")) return 10;
    if (position.contains("RW")) return 7;
    if (position.contains("LW")) return 11;
    if (position.contains("CB") || position.contains("DEF")) return 4;
    return 9;
  }

  int getCardTierStars() {
    switch (cardType) {
      case "TOTS":
        return 5;
      case "BALLOND'OR":
      case "STAR":
        return 4;
      case "MVP":
        return 3;
      case "TOTW":
      case "TOTM":
        return 1;
      default:
        return 0;
    }
  }

  // --- FM TARZI STATLAR (1-20) ---
  Map<String, int> getFMStats() {
    // Ham verileri 0-99 alıp 1-20'ye çeviriyoruz
    var raw = getCardStats();

    // Özel hesaplamalar (Karma özellikler)
    int rawPos = ((raw['DEF']! + raw['PAS']!) / 2).round();
    int rawVis = ((raw['PAS']! + raw['DRI']!) / 2).round();

    return {
      "Hız": (raw['PAC']! / 5).round().clamp(1, 20),
      "Şut": (raw['SHO']! / 5).round().clamp(1, 20),
      "Pas": (raw['PAS']! / 5).round().clamp(1, 20),
      "Dripling": (raw['DRI']! / 5).round().clamp(1, 20),
      "Defans": (raw['DEF']! / 5).round().clamp(1, 20),
      "Fizik": (raw['PHY']! / 5).round().clamp(1, 20),
      "Pozisyon": (rawPos / 5).round().clamp(1, 20),
      "Vizyon": (rawVis / 5).round().clamp(1, 20),
    };
  }

  void calculateSmartRating() {
    if (stats.isEmpty) {
      rating = 50;
      return;
    }
    if (position.contains("GK") || position.contains("(1)")) {
      double gkSkillAvg = _getAvgDouble(gkSkillStats);
      double gkPassAvg = _getAvgDouble(gkPassStats);
      rating = ((gkSkillAvg * 0.70) + (gkPassAvg * 0.30)).round().clamp(1, 99);
      return;
    }
    double dribbling = _getAvgDouble(
        ["Top Sürme", "Teknik", "Çeviklik", "Denge", "Hız", "Hızlanma"]);
    double shooting = _getAvgDouble(statSegments["2. Şut & Zihinsel"]!);
    double defense = _getAvgDouble(statSegments["3. Savunma & Güç"]!);
    double passing = _getAvgDouble(statSegments["4. Pas & Vizyon"]!);

    String numStr = position.replaceAll(RegExp(r'[^0-9]'), '');
    int pNum = int.tryParse(numStr) ?? 9;

    double wDrib = 0.25, wShoot = 0.25, wDef = 0.25, wPass = 0.25;
    if (pNum >= 3 && pNum <= 6) {
      wDrib = 0.20;
      wShoot = 0.10;
      wDef = 0.50;
      wPass = 0.30;
    } else if (pNum == 10) {
      wDrib = 0.25;
      wShoot = 0.20;
      wDef = 0.15;
      wPass = 0.40;
    } else if (pNum == 7 || pNum == 11) {
      wDrib = 0.45;
      wShoot = 0.25;
      wDef = 0.05;
      wPass = 0.25;
    } else if (pNum == 9) {
      wDrib = 0.28;
      wShoot = 0.45;
      wDef = 0.02;
      wPass = 0.25;
    }

    double weightedTotal = (dribbling * wDrib) +
        (shooting * wShoot) +
        (defense * wDef) +
        (passing * wPass);
    double totalWeight = wDrib + wShoot + wDef + wPass;
    rating = (weightedTotal / totalWeight).round().clamp(1, 99);
    if (cardType == "TOTS" || cardType == "BALLOND'OR")
      rating = (rating + 3).clamp(1, 99);
    if (cardType == "BAD") rating = (rating - 25).clamp(1, 60);
  }

  Map<String, int> getCardStats() {
    if (stats.isEmpty) {
      // Statlar boşsa Rating üzerinden tahmini değerler üret
      int base = rating;
      if (base < 40) base = 40;
      return {
        "PAC": base - 5,
        "SHO": base - 10,
        "PAS": base - 5,
        "DRI": base,
        "DEF": base - 30,
        "PHY": base - 10
      };
    }

    if (position.contains("GK") || position.contains("(1)")) {
      return {
        "REF": stats["Reflex"] ?? 50,
        "1v1": stats["1e1 Savunma"] ?? 50,
        "DIV": stats["Çizgide Kurtarış"] ?? 50,
        "HAN": stats["Top Kontrolü"] ?? 50,
        "KIC": stats["Güç"] ?? 50,
        "POS": stats["Pozisyon Alma"] ?? 50,
      };
    }
    return {
      "PAC": _getAvg(statSegments["1. Top Sürme & Fizik"]!.sublist(0, 4)),
      "SHO": _getAvg(statSegments["2. Şut & Zihinsel"]!),
      "PAS": _getAvg(statSegments["4. Pas & Vizyon"]!),
      "DRI": _getAvg(["Top Sürme", "Teknik", "Çeviklik", "Denge"]),
      "DEF": _getAvg(statSegments["3. Savunma & Güç"]!),
      "PHY": _getAvg(["Güç", "Saldırganlık", "Sert Duruş", "Duvar Kabiliyeti"])
    };
  }

  Offset getPitchPosition() {
    if (position.contains("GK")) return const Offset(0.5, 0.9);
    if (position.contains("CDM")) return const Offset(0.5, 0.65);
    if (position.contains("CAM")) return const Offset(0.5, 0.45);
    if (position.contains("LW")) return const Offset(0.2, 0.25);
    if (position.contains("RW")) return const Offset(0.8, 0.25);
    if (position.contains("ST")) return const Offset(0.5, 0.15);
    return const Offset(0.5, 0.5);
  }

  Map<String, String> getSimulationStats() {
    var cs = getCardStats();
    if (position.contains("GK")) {
      return {
        "Pas": "${stats['Pas'] ?? 50}",
        "Refleks": "${stats['Reflex'] ?? 50}",
        "Gol": "$manualGoals",
        "Asist": "$manualAssists",
        "Maç": "$manualMatches"
      };
    }
    int passes = (cs['PAS']! * 1.5).toInt();
    int shots = (cs['SHO']! / 4).toInt();
    int possession = (cs['DRI']! / 1.8).toInt().clamp(30, 70);
    return {
      "Pas": "$passes",
      "İsabetli Pas": "${(passes * 0.8).toInt()}",
      "Kilit Pas": "${(cs['PAS']! / 15).toStringAsFixed(1)}",
      "Şut": "$shots",
      "Gol": "$manualGoals",
      "Asist": "$manualAssists",
      "Maç": "$manualMatches",
      "Topla Oynama": "$possession%"
    };
  }

  int _getAvg(List<String> keys) {
    if (stats.isEmpty) return 50;
    int s = 0, c = 0;
    for (var k in keys) {
      if (stats.containsKey(k)) {
        s += stats[k]!;
        c++;
      }
    }
    return c == 0 ? 50 : (s / c).round();
  }

  double _getAvgDouble(List<String> keys) {
    if (stats.isEmpty) return 50.0;
    int s = 0, c = 0;
    for (var k in keys) {
      s += stats[k] ?? 60;
      c++;
    }
    return c == 0 ? 50.0 : (s / c);
  }
}

// --- GLOBAL LİSTELER ---
final List<String> gkSkillStats = [
  "Reflex",
  "1e1 Savunma",
  "Çizgide Kurtarış",
  "Sert Duruş",
  "Güç"
];
final List<String> gkPassStats = [
  "Pas",
  "Top Kontrolü",
  "Görüş",
  "Topsuz Alan",
  "Soğukkanlılık",
  "Karar Alma",
  "Pozisyon Alma"
];

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
    "Karar Alma",
    "Roket Şut"
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
  ]
};

final List<String> globalCardTypes = [
  "Temel",
  "TOTW",
  "TOTM",
  "TOTS",
  "MVP",
  "STAR",
  "BALLOND'OR",
  "BAD"
];
final List<String> globalRoles = [
  "Kaptan",
  "Yedek",
  "Rotasyon",
  "Yıldız",
  "Genç Yetenek"
];

final Map<String, String> teamLogos = {
  "Bursa Spor": "assets/takimlar/bursaspor.png",
  "CA RIVER PLATE": "assets/takimlar/riverplate.png",
  "Chelsea": "assets/takimlar/chelsea.png",
  "Fenerbahçe": "assets/takimlar/fenerbahce.png",
  "Invicta": "assets/takimlar/invicta.png",
  "It Spor": "assets/takimlar/itspor.png",
  "Juventus": "assets/takimlar/juventus.png",
  "Livorno": "assets/takimlar/livorno.png",
  "Maximilian": "assets/takimlar/maximilian.png",
  "Shamrock Rovers": "assets/takimlar/shamrock.png",
  "Tiyatro FC": "assets/takimlar/tiyatro.png",
  "Toulouse": "assets/takimlar/toulouse.png",
  "Werder Weremem": "assets/takimlar/werderweremem.png",
  "Takımsız": ""
};

final Map<String, List<String>> roleCategories = {
  "(1) GK": ["Çizgi Kalecisi", "Süpürücü Kaleci", "Oyun Kurucu Kaleci"],
  "(3-6) CDM": [
    "Savunmatik",
    "Libero",
    "Oyun Kurucu Stoper",
    "Tutucu",
    "Derin Oyun Kurucu",
    "Savaşçı"
  ],
  "(10) CAM": [
    "Oyun Kurucu",
    "Box to Box",
    "Mezzala",
    "Gölge Forvet",
    "Enganche"
  ],
  "(7) RW": ["İç Forvet", "Kanat Oyuncusu", "Gizli Forvet", "Avcı Forvet"],
  "(11) LW": ["İç Forvet", "Kanat Oyuncusu", "Gizli Forvet", "Avcı Forvet"],
  "(9) ST": ["Hedef Forvet", "Avcı Forvet", "Yanlış 9", "Gölge Forvet"]
};
