import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// ============================================================================
// YARDIMCI EXTENSION (LİSTE DÖNÜŞÜMÜ İÇİN)
// ============================================================================
extension ListDynamicCast on List<dynamic> {
  List<T> dynamicCast<T>() {
    return map((e) => e as T).toList();
  }
}

// ============================================================================
// HIVE ADAPTERLERİ (GÜVENLİ VERSİYON)
// ============================================================================

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    // Verileri sırayla okuyoruz
    final name = reader.read();
    final rating = reader.read();
    final position = reader.read();

    // HATA DÜZELTME: Liste tip dönüşümü güvenli hale getirildi
    var rawPlaystyles = reader.read();
    List<PlayStyle> safePlaystyles = [];
    if (rawPlaystyles is List) {
      safePlaystyles = rawPlaystyles.whereType<PlayStyle>().toList();
    }

    final marketValue = reader.read();

    // MatchStat listesi güvenli okuma
    var rawMatches = reader.read();
    List<MatchStat> safeMatches = [];
    if (rawMatches is List) {
      safeMatches = rawMatches.whereType<MatchStat>().toList();
    }

    final team = reader.read();

    // Map güvenli okuma
    var rawStats = reader.read();
    Map<String, int> safeStats = {};
    if (rawStats is Map) {
      safeStats = rawStats.map((k, v) => MapEntry(k.toString(), v as int));
    }

    final role = reader.read() ?? "Yok";
    final skillMoves = reader.read() ?? 3;
    final country = reader.read() ?? "Türkiye";
    final chemistryStyle = reader.read() ?? "Temel";
    final cardType = reader.read() ?? "Temel";

    // SeasonStat güvenli okuma
    var rawSeasons = reader.read();
    List<SeasonStat> safeSeasons = [];
    if (rawSeasons is List) {
      safeSeasons = rawSeasons.whereType<SeasonStat>().toList();
    }

    final recLink = reader.read() ?? "";
    final manualGoals = reader.read() ?? 0;
    final manualAssists = reader.read() ?? 0;
    final manualMatches = reader.read() ?? 0;
    final instruction = reader.read() ?? "Balanced";

    return Player(
      name: name,
      rating: rating,
      position: position,
      playstyles: safePlaystyles,
      marketValue: marketValue,
      matches: safeMatches,
      team: team,
      stats: safeStats,
      role: role,
      skillMoves: skillMoves,
      country: country,
      chemistryStyle: chemistryStyle,
      cardType: cardType,
      seasons: safeSeasons,
      recLink: recLink,
      manualGoals: manualGoals,
      manualAssists: manualAssists,
      manualMatches: manualMatches,
      instruction: instruction,
    );
  }

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

// ============================================================================
// VERİ MODELLERİ
// ============================================================================

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

  // --- HESAPLAMA METODLARI ---

  Map<String, int> getFMStats() {
    var raw = getCardStats();
    // Null safety: ?? 50 ekleyerek null hatasını önlüyoruz
    int toFM(int? val) => ((val ?? 50) / 5.0).round().clamp(1, 20);

    int pas = raw['PAS'] ?? 50;
    int def = raw['DEF'] ?? 50;
    int sho = raw['SHO'] ?? 50;
    int dri = raw['DRI'] ?? 50;

    int intelligence = ((pas + def) / 2).round();
    int composure = ((sho + dri) / 2).round();

    return {
      "Hız": toFM(raw['PAC']),
      "Şut": toFM(raw['SHO']),
      "Pas": toFM(raw['PAS']),
      "Dripling": toFM(raw['DRI']),
      "Defans": toFM(raw['DEF']),
      "Fizik": toFM(raw['PHY']),
      "Pozisyon": toFM((intelligence * 0.7 + def * 0.3).toInt()),
      "Vizyon": toFM((pas * 0.8 + dri * 0.2).toInt()),
      "Refleks": position.contains("GK")
          ? toFM(stats['Reflex'] ?? rating)
          : toFM(rating - 40),
      "Teknik": toFM((dri + pas) ~/ 2),
      "Karar": toFM(composure),
    };
  }

  Map<String, int> getCardStats() {
    if (stats.isEmpty) {
      int r = rating;
      return {
        "PAC": r - 5,
        "SHO": r - 10,
        "PAS": r - 5,
        "DRI": r,
        "DEF": r - 30,
        "PHY": r - 10
      };
    }
    if (position.contains("GK") || position.contains("(1)")) {
      return {
        "REF": stats["Reflex"] ?? 50,
        "DIV": stats["Çizgide Kurtarış"] ?? 50,
        "HAN": stats["Top Kontrolü"] ?? 50,
        "KIC": stats["Güç"] ?? 50,
        "POS": stats["Pozisyon Alma"] ?? 50,
        "1v1": stats["1e1 Savunma"] ?? 50,
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
    if (position.contains("DEF") || position.contains("CB"))
      return const Offset(0.5, 0.75);
    if (position.contains("MID") || position.contains("CM"))
      return const Offset(0.5, 0.5);
    if (position.contains("FWD") || position.contains("ST"))
      return const Offset(0.5, 0.15);
    return const Offset(0.5, 0.5);
  }

  Map<String, String> getSimulationStats() {
    return {
      "Gol": "$manualGoals",
      "Asist": "$manualAssists",
      "Maç": "$manualMatches",
      "Puan": matches.isNotEmpty
          ? (matches.fold(0.0, (s, m) => s + m.rating) / matches.length)
              .toStringAsFixed(1)
          : "N/A"
    };
  }

  void calculateSmartRating() {
    if (stats.isEmpty) return;
    int total = 0;
    int c = 0;
    stats.forEach((k, v) {
      if (v > 0) {
        total += v;
        c++;
      }
    });
    if (c > 0) rating = (total / c).round().clamp(1, 99);
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

  int get kitNumber =>
      position.contains("GK") ? 1 : (position.contains("ST") ? 9 : 10);

  int getCardTierStars() {
    if (["TOTS", "BALLOND'OR"].contains(cardType)) return 5;
    if (["STAR", "MVP"].contains(cardType)) return 4;
    return 1;
  }
}

// Global Listeler
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
final Map<String, String> teamLogos = {"Takımsız": ""};
final Map<String, List<String>> roleCategories = {
  "(1) GK": ["Çizgi Kalecisi"],
  "(9) ST": ["Hedef Forvet"]
};
