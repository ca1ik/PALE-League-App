import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// --- ADAPTERLER ---
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
      chemistryStyle: reader.read() ?? "Temel",
      cardType: reader.read() ?? "Temel",
      seasons: (reader.read() as List?)?.cast<SeasonStat>() ?? [],
      recLink: reader.read() ?? "",
      manualGoals: reader.read() ?? 0,
      manualAssists: reader.read() ?? 0,
      manualMatches: reader.read() ?? 0,
      manualPasses: reader.read() ?? 0,
      manualKeyPasses: reader.read() ?? 0,
      manualShots: reader.read() ?? 0,
      manualPossession: reader.read() ?? 50);
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
      ..write(obj.manualPasses)
      ..write(obj.manualKeyPasses)
      ..write(obj.manualShots)
      ..write(obj.manualPossession);
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
  int manualGoals,
      manualAssists,
      manualMatches,
      manualPasses,
      manualKeyPasses,
      manualShots,
      manualPossession;

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
      this.manualPasses = 0,
      this.manualKeyPasses = 0,
      this.manualShots = 0,
      this.manualPossession = 50});

  int get kitNumber {
    if (position.contains("GK")) return 1;
    if (position.contains("CDM")) return 6;
    if (position.contains("CAM")) return 10;
    if (position.contains("RW") || position.contains("LW")) return 7;
    if (position.contains("ST")) return 9;
    return 99;
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

  Map<String, int> getCardStats() {
    if (stats.isEmpty)
      return {"PAC": 50, "SHO": 50, "PAS": 50, "DRI": 50, "DEF": 50, "PHY": 50};
    return {
      "PAC": _getAvg(statSegments["1. Top Sürme & Fizik"]!.sublist(0, 4)),
      "SHO": _getAvg(statSegments["2. Şut & Zihinsel"]!),
      "PAS": _getAvg(statSegments["4. Pas & Vizyon"]!),
      "DRI": _getAvg(["Top Sürme", "Teknik", "Çeviklik", "Denge"]),
      "DEF": _getAvg(statSegments["3. Savunma & Güç"]!),
      "PHY": _getAvg(["Güç", "Saldırganlık", "Sert Duruş", "Duvar Kabiliyeti"])
    };
  }

  void calculateRating() {
    if (stats.isEmpty) {
      rating = 50;
      return;
    }
    var cs = getCardStats();
    double total = (cs["PAC"]! * 1.2 +
        cs["SHO"]! * 1.5 +
        cs["PAS"]! * 1.0 +
        cs["DRI"]! * 1.2 +
        cs["DEF"]! * 0.2 +
        cs["PHY"]! * 0.8);
    rating = (total / 5.9).round().clamp(1, 99);
    if (cardType == "TOTS" || cardType == "BALLOND'OR")
      rating = (rating + 3).clamp(1, 99);
    if (cardType == "BAD") rating = (rating - 30).clamp(1, 60);
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
    int passes = manualPasses > 0 ? manualPasses : (cs['PAS']! * 1.5).toInt();
    int shots = manualShots > 0 ? manualShots : (cs['SHO']! / 4).toInt();
    int possession = manualPossession > 0
        ? manualPossession
        : (cs['DRI']! / 1.8).toInt().clamp(30, 70);
    return {
      "Pas": "$passes",
      "İsabetli Pas": "${(passes * 0.8).toInt()}",
      "Kilit Pas": manualKeyPasses > 0
          ? "$manualKeyPasses"
          : "${(cs['PAS']! / 15).toStringAsFixed(1)}",
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
      if (stats.containsKey(k) && stats[k] != null) {
        s += stats[k]!;
        c++;
      }
    }
    return c == 0 ? 50 : (s / c).round();
  }
}

final Map<String, List<Map<String, String>>> playStyleCategories = {
  "Bitirici": [
    {
      "name": "GameChanger",
      "label": "Oyun Kurucu/Yaratıcı",
      "desc": "Sıradışı bitirişler ve yaratıcı vuruşlar."
    },
    {
      "name": "Acrobatic",
      "label": "Akrobatik",
      "desc": "Akrobatik paslar ve estetik vuruşlar."
    },
    {
      "name": "PowerShot",
      "label": "Sert Şut",
      "desc": "Ceza sahası dışından sert şutlar."
    },
    {
      "name": "FinesseShot",
      "label": "Plase Şut",
      "desc": "Köşelere isabetli ve kaliteli şutlar."
    }
  ],
  "Pas": [
    {
      "name": "IncisivePass",
      "label": "Keskin Pas",
      "desc": "Savunmayı yaran koşturucu paslar."
    },
    {
      "name": "PingedPass",
      "label": "Adrese Teslim",
      "desc": "Hızlı ve sert adrese teslim paslar."
    },
    {
      "name": "LongBallPass",
      "label": "Uzun Pas",
      "desc": "Uzaktaki oyuncuya nokta atışı paslar."
    },
    {
      "name": "TikiTaka",
      "label": "Tiki Taka",
      "desc": "İlk vuruşta isabetli kısa paslar."
    },
    {
      "name": "WhippedPass",
      "label": "Kırbaçlanmış Pas",
      "desc": "Hızlı ve sert ceza sahası ortaları."
    },
    {
      "name": "Inventive",
      "label": "Yaratıcı",
      "desc": "Zekice ve tahmin edilemez paslar."
    }
  ],
  "Savunma/Fiziksel": [
    {"name": "Jockey", "label": "Jokey", "desc": "Bire bir mücadele uzmanı."},
    {
      "name": "Block",
      "label": "Engelleyici",
      "desc": "Esnek ve markajlayarak blok yapma."
    },
    {
      "name": "Intercept",
      "label": "Top Kesici",
      "desc": "Topu kapma ve sahip olma yeteneği."
    },
    {
      "name": "Anticipate",
      "label": "Sezgici",
      "desc": "Düşük hata oranıyla top çalma."
    },
    {
      "name": "Bruiser",
      "label": "Kavgacı",
      "desc": "Bodyleme ve fiziksel top kazanma."
    },
    {
      "name": "AerialFortress",
      "label": "Hava Hakimiyeti",
      "desc": "Sert paslara kontrollü hava tepkisi."
    }
  ],
  "Dripling": [
    {
      "name": "Technical",
      "label": "Teknik",
      "desc": "Teknik top sürme becerisi."
    },
    {"name": "Rapid", "label": "Ani", "desc": "Rakibi hızla ekarte etme."},
    {
      "name": "FirstTouch",
      "label": "İlk Dokunuş",
      "desc": "Zor pozisyonlarda isabetli kontrol."
    },
    {
      "name": "Trickster",
      "label": "Hilebaz/Sanatçı",
      "desc": "Yetenekli duvar hareketleri."
    },
    {
      "name": "PressProven",
      "label": "Baskı Yemez",
      "desc": "Fiziksel baskı altında hakimiyet."
    },
    {
      "name": "QuickStep",
      "label": "Hızlı Adım",
      "desc": "Topla birlikte hızlı dripling."
    }
  ],
  "Kaleci": [
    {
      "name": "FarReach",
      "label": "Uzak Erişim/Atış",
      "desc": "Uzaktan paslarla hedefleme."
    },
    {
      "name": "Footwork",
      "label": "Ayak Hareketleri",
      "desc": "Kaliteli pas atan pasör kaleci."
    },
    {
      "name": "CrossClaimer",
      "label": "Çapraz Muhafız",
      "desc": "Markajla top kesen kaleci."
    },
    {
      "name": "RushOut",
      "label": "Dışarı Terk",
      "desc": "Agresif şut/pas engelleme."
    },
  ]
};

final List<Map<String, dynamic>> metaPlaystyles = [
  {
    "role": "(1) GK Metas",
    "styles":
        "Ayak Hareketleri - Çapraz Muhafız - Dışarı Terk - Uzak Erişim/Atış"
  },
  {
    "role": "(3-6) CDM Metas",
    "styles":
        "Sezgici - Kavgacı - Engelleyici - Jokey - Adrese Teslim - Top Kesici"
  },
  {
    "role": "(10) CAM Metas",
    "styles":
        "Keskin Pas - Tiki Taka - Adrese Teslim - Oyun Kurucu/Yaratıcı - Yaratıcı - Sert Şut - Teknik"
  },
  {
    "role": "(7-11) RW/LW Metas",
    "styles":
        "Hilebaz/Sanatçı - Oyun Kurucu/Yaratıcı - Hızlı Adım - Ani - Teknik - Sert Şut - Plase Şut - Yaratıcı"
  },
  {
    "role": "(9) ST Metas",
    "styles":
        "Plase Şut - Sert Şut - Baskı Yemez - Keskin Pas - İlk Dokunuş - Hava Hakimiyeti"
  },
];

final Map<String, String> cardTypeDescriptions = {
  "Temel": "Standart oyuncu kartı.",
  "TOTW": "Haftanın Takımı.",
  "TOTS": "Sezonun Takımı.",
  "MVP": "En Değerli Oyuncu.",
  "STAR": "Yıldız Oyuncu.",
  "BALLOND'OR": "Sezonun Oyuncusu.",
  "BAD": "Facia Performans.",
  "TOTM": "Ayın Takımı."
};

final Map<String, String> roleDescriptions = {
  "Çizgi Kalecisi": "Refleks kurtarışları yapar.",
  "Süpürücü Kaleci": "Defans arkası toplara çıkar.",
  "Oyun Kurucu Kaleci": "Geriden oyun kurar.",
  "Savunmatik": "Önceliği defans güvenliğidir.",
  "Libero": "En arkada serbest oynar.",
  "Oyun Kurucu Stoper": "Topu oyuna sokar.",
  "Tutucu": "Defans önünü süpürür.",
  "Derin Oyun Kurucu": "Geriden oyun kurar.",
  "Savaşçı": "Rakibi yıpratır.",
  "Oyun Kurucu": "Takımın beyni konumu.",
  "Box to Box": "İki ceza sahası arası mekik dokur.",
  "Mezzala": "Yarı kanat, yaratıcı merkez oyuncusu.",
  "Gölge Forvet": "Forvet arkasından gol arayan oyuncu.",
  "Enganche": "Klasik 10 numara tarzı oyun kurucu.",
  "İç Forvet": "Kanattan içeri kat edip şut çeker.",
  "Kanat Oyuncusu": "Çizgiye inip orta yapmaya odaklanır.",
  "Gizli Forvet": "Geri planda kalıp sürpriz goller arar.",
  "Avcı Forvet": "Ceza sahası içi bitiriciliğe odaklanır.",
  "Hedef Forvet": "Top saklayıp arkadaşlarına servis yapar.",
  "Yanlış 9": "Forvet görünüp orta sahaya yardıma gelir.",
  "Kanat Bek": "Hücuma katkı veren savunma oyuncusu.",
  "Hücum Bek": "Neredeyse kanat gibi oynayan bek."
};

final List<String> availablePlayStyles = playStyleCategories.values
    .expand((element) => element.map((e) => e["name"]!))
    .toList();
final Map<String, String> playStyleTranslationsReverse = playStyleCategories
    .values
    .expand((e) => e)
    .fold({}, (map, e) => map..[e["name"]!] = e["label"]!);
final List<String> cardTypes = [
  "Temel",
  "TOTW",
  "TOTM",
  "TOTS",
  "MVP",
  "STAR",
  "BALLOND'OR",
  "BAD"
];

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
final List<String> availablePositions = roleCategories.keys.toList();

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
  "Gözcü": {"Hız": 2, "Top Kapma": 3, "Markaj": 3, "Güç": 2},
  "Çapa": {"Hız": 2, "Savunma Farkındalığı": 2, "Güç": 4},
  "Katalizör": {"Hız": 3, "Pas": 3, "Ara Pas": 2},
  "Gladyatör": {"Bitiricilik": 3, "Savunma Farkındalığı": 3, "Güç": 2}
};
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
  ]
};

// Takım İsimleri ve Logo Dosya Eşleştirmesi
final Map<String, String> teamLogos = {
  "Bursa Spor": "assets/takimlar/bursaspor.png",
  "Chelsea": "assets/takimlar/chelsea.png",
  "Fenerbahçe": "assets/takimlar/fenerbahçe.png",
  "Invicta": "assets/takimlar/invicta.png",
  "It Spor": "assets/takimlar/itspor.png",
  "Juventus": "assets/takimlar/juventus.png",
  "Livorno": "assets/takimlar/livorno.png",
  "Maximilian": "assets/takimlar/maximilian.png",
  "CA RIVER PLATE": "assets/takimlar/riverplate.png",
  "Shamrock Rovers": "assets/takimlar/shamrock.png",
  "Tiyatro FC": "assets/takimlar/tiyatro.png",
  "Toulouse": "assets/takimlar/toulouse.png",
  "Werder Weremem": "assets/takimlar/werderweremem.png",
  "Takımsız": "", // Logo yok
  "La Mama de Nico": "",
  "Theis FC": ""
};

final List<String> availableTeams = teamLogos.keys.toList();
