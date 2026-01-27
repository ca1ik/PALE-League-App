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
      manualPossession: reader.read() ?? 0);
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
    writer.write(obj.cardType);
    writer.write(obj.seasons);
    writer.write(obj.recLink);
    writer.write(obj.manualGoals);
    writer.write(obj.manualAssists);
    writer.write(obj.manualMatches);
    writer.write(obj.manualPasses);
    writer.write(obj.manualKeyPasses);
    writer.write(obj.manualShots);
    writer.write(obj.manualPossession);
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
    if (stats.isEmpty) return;
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
    if (cardType == "BAD") rating = (rating - 10).clamp(1, 99);
  }

  void generateRandomMatchesAndSeasons() {
    if (manualMatches == 0) {
      final random = Random();
      manualMatches = 5;
      manualGoals = random.nextInt(5);
      manualAssists = random.nextInt(5);
      matches = List.generate(
          5,
          (index) => MatchStat(
              "Hafta ${5 - index}",
              "${random.nextInt(4)}-${random.nextInt(4)}",
              random.nextInt(2),
              random.nextInt(2),
              7.5));
    }
  }

  Offset getPitchPosition() {
    switch (position) {
      case "GK":
        return const Offset(0.5, 0.9);
      case "CB":
        return const Offset(0.5, 0.75);
      case "LB":
        return const Offset(0.2, 0.7);
      case "RB":
        return const Offset(0.8, 0.7);
      case "CDM":
        return const Offset(0.5, 0.6);
      case "CM":
        return const Offset(0.5, 0.5);
      case "CAM":
        return const Offset(0.5, 0.35);
      case "LW":
        return const Offset(0.2, 0.25);
      case "RW":
        return const Offset(0.8, 0.25);
      case "ST":
        return const Offset(0.5, 0.15);
      default:
        return const Offset(0.5, 0.5);
    }
  }

  Map<String, String> getSimulationStats() {
    var cs = getCardStats();
    return {
      "Pas": manualMatches == 0
          ? "${(cs['PAS']! * 2.5).toInt()}"
          : "$manualPasses",
      "İsabetli Pas": manualMatches == 0
          ? "${(cs['PAS']! * 1.8).toInt()}"
          : "${(manualPasses * 0.8).toInt()}",
      "Kilit Pas": manualMatches == 0
          ? "${(cs['PAS']! / 10).toStringAsFixed(1)}"
          : "$manualKeyPasses",
      "Şut":
          manualMatches == 0 ? "${(cs['SHO']! / 5).toInt()}" : "$manualShots",
      "Gol": "$manualGoals",
      "Asist": "$manualAssists",
      "Maç": "$manualMatches",
      "Topla Oynama": manualMatches == 0
          ? "${(cs['DRI']! / 1.5).toInt()}%"
          : "$manualPossession%"
    };
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

// --- WIKI & STATİK VERİLER ---
final Map<String, List<Map<String, String>>> playStyleCategories = {
  "Bitirici": [
    {
      "name": "GameChanger",
      "label": "Oyun Kurucu/Yaratıcı",
      "desc":
          "Sıradışı ve alışılmadık bitirişleriyle tanınan, yaratıcı ve tahmin edilemez vuruşlarda üstün başarı gösteren bir oyuncu."
    },
    {
      "name": "Acrobatic",
      "label": "Akrobatik",
      "desc":
          "Akrobatik paslar, top uzaklaştırmalar ve şutlar yapmaya meyilli bir oyuncu."
    },
    {
      "name": "PowerShot",
      "label": "Sert Şut",
      "desc": "Ceza sahası dışından sert şutlar atmasıyla tanınan bir oyuncu."
    },
    {
      "name": "FinesseShot",
      "label": "Plase Şut",
      "desc":
          "Kaleye şut çekerken topu köşelere göndermeye çalışmasıyla bilinen aynı zamanda kaliteli şutör bir oyuncu."
    }
  ],
  "Pas": [
    {
      "name": "IncisivePass",
      "label": "Keskin Pas",
      "desc":
          "Savunmayı yaran paslarıyla takım arkadaşının koşarak topa ulaşmasını sağlayan bir oyuncu."
    },
    {
      "name": "PingedPass",
      "label": "Adrese Teslim",
      "desc": "Hızlı ve sert adrese teslim paslarıyla tanınan bir oyuncu."
    },
    {
      "name": "LongBallPass",
      "label": "Uzun Pas",
      "desc":
          "Uzaktaki oyuncuya sert ve nokta atışı pas yaplarıyla tanınan bir oyuncu."
    },
    {
      "name": "TikiTaka",
      "label": "Tiki Taka",
      "desc":
          "İlk vuruşta isabetli ve kısa paslarıyla tanınan Barça ruhlu bir oyuncu."
    },
    {
      "name": "WhippedPass",
      "label": "İçe Pas/Kırbaçlanmış Pas",
      "desc":
          "Ceza sahasına yüksek hızda ve sert ortalar yapmasıyla tanınan bir oyuncu."
    },
    {
      "name": "Inventive",
      "label": "Yaratıcı",
      "desc":
          "Yaratıcı paslarıyla ve zekice, tahmin edilemez kombinasyonlar yapabilme yeteneğiyle tanınan bir oyuncu."
    }
  ],
  "Savunma/Fiziksel": [
    {
      "name": "Jockey",
      "label": "Jokey",
      "desc": "Bire bir mücadelelerde başarılı olmasıyla tanınan bir oyuncu."
    },
    {
      "name": "Block",
      "label": "Engelleyici",
      "desc": "Esnek ve markajlayarak yaptığı bloklarla tanınan bir oyuncu."
    },
    {
      "name": "Intercept",
      "label": "Top Kesici",
      "desc":
          "Topu kapma ve topa sahip olma konusunda yetenekli olduğu bilinen bir oyuncu."
    },
    {
      "name": "Anticipate",
      "label": "Sezgici",
      "desc":
          "Topa sahip olma konusunda yüksek başarı oranına ve düşük hata yapma oranına sahip bir oyuncu."
    },
    {
      "name": "Bruiser",
      "label": "Kavgacı",
      "desc":
          "Fiziksel/Bodyleme konusunda topu kazanma/kontrol etmesiyle tanınan bir oyuncu."
    },
    {
      "name": "AerialFortress",
      "label": "Hava Hakimiyeti",
      "desc":
          "Hücumda/Defansta etkili, gelen sert paslara kontrollü ve isabetli tepki vermesiyle tanınan bir oyuncu."
    }
  ],
  "Dripling": [
    {
      "name": "Technical",
      "label": "Teknik",
      "desc":
          "Rakibini genellikle teknik top sürme becerisiyle (neredeyse hiç beceri/duvar hareketi yapmadan) alt etmeye çalışan oyuncu."
    },
    {
      "name": "Rapid",
      "label": "Ani",
      "desc":
          "Rakibini dripling ve hızıyla ekarte etmesiyle tanınan bir oyuncu."
    },
    {
      "name": "FirstTouch",
      "label": "İlk Dokunuş",
      "desc":
          "Zorlu pozisyonlarda isabetli ilk dokunuş kontrolüyle tanınan bir oyuncu."
    },
    {
      "name": "Trickster",
      "label": "Hilebaz/Sanatçı",
      "desc":
          "Bire bir mücadelelerde yetenekli duvar hareketleri sergileyebilmesiyle tanınan bir oyuncu."
    },
    {
      "name": "PressProven",
      "label": "Baskı Yemez",
      "desc":
          "Rakibin fiziksel baskısı altında sırtı dönük topa hakimiyetiyle tanınan oyuncu."
    },
    {
      "name": "QuickStep",
      "label": "Hızlı Adım",
      "desc":
          "Topla birlikte hızlı dripling'e geçme yeteneğiyle tanınan bir oyuncu."
    }
  ],
  "Kaleci": [
    {
      "name": "FarReach",
      "label": "Uzak Erişim/Atış",
      "desc":
          "Kaleci, uzaktan attığı paslarla daha uzaktaki oyuncuları hedefleyebilir."
    },
    {
      "name": "Footwork",
      "label": "Ayak Hareketleri",
      "desc":
          "Pasör özelliğiyle kaliteli paslar atmasıyla bilinen kaleci oyuncu."
    },
    {
      "name": "CrossClaimer",
      "label": "Çapraz Muhafız",
      "desc":
          "Öndeki rakibini markaj altına alarak top kesmesiyle bilinen kaleci oyuncu."
    },
    {
      "name": "RushOut",
      "label": "Dışarı Terk",
      "desc":
          "Ceza sahasından çıkarken daha agresif davranarak, pasları veya şutları önde engellemesiyle bilinen kaleci oyuncu."
    },
  ]
};

final List<Map<String, dynamic>> metaPlaystyles = [
  {
    "role": "(1) GK Metas",
    "styles": "Ayak Hareketleri - Çapraz Muhafız - Dışarı Terk - Uzak Erişim"
  },
  {
    "role": "(3-6) CB-CDM Metas",
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
  "Temel": "Standart oyuncu kartı. Başlangıç seviyesi.",
  "TOTW":
      "Haftanın Takımı. Ligde haftanın en iyi performansını gösteren oyunculara verilir.",
  "TOTS":
      "Sezonun Takımı. Sezon boyunca üstün performans gösteren elit oyuncular.",
  "MVP": "En Değerli Oyuncu. Maçın veya turnuvanın yıldızı.",
  "STAR": "Yıldız Oyuncu. Takımın kilit isimleri.",
  "BALLOND'OR": "Yılın en iyi futbolcusu ödülü. En prestijli kart.",
  "BAD": "Kötü performans veya cezalı kart.",
  "TOTM": "Ayın Takımı oyuncusu."
};

// EKSİK OLAN KISIM EKLENDİ
final Map<String, String> roleDescriptions = {
  "Çizgi Kalecisi": "Çizgide kalarak refleksleriyle kurtarış yapar.",
  "Süpürücü Kaleci": "Defans arkasına atılan toplara çıkar.",
  "Oyun Kurucu Kaleci": "Ayaklarını iyi kullanır, oyunu geriden kurar.",
  "Libero": "Defansın en arkasında serbest oynar.",
  "Çok Yönlü": "Hem savunma hem hücum özelliklerini dengeli kullanır.",
  "Savunmatik": "Önceliği defans güvenliğidir.",
  "Oyun Kurucu Stoper": "Topu oyuna sokmada becerilidir.",
  "Kanat Bek": "Hücuma sıkça katılır.",
  "Hücum Bek": "Kanat forvet gibi oynar.",
  "Tutucu": "Defans önünü süpürür.",
  "Derin Oyun Kurucu": "Geriden oyun kurar.",
  "Savaşçı": "Fiziksel gücüyle rakibi yıpratır.",
  "Oyun Kurucu": "Takımın beyni, pas dağıtımını yönetir.",
  "Box to Box": "İki ceza sahası arasında mekik dokur.",
  "Mezzala": "Yarı kanat, yarı merkez oyuncusu.",
  "Gölge Forvet": "Forvet arkasında gol arar.",
  "Enganche": "Klasik 10 numara, az koşar çok pas atar.",
  "Kanat Oyuncusu": "Çizgiye inip orta yapar.",
  "İç Forvet": "Kanattan içeri kat edip şut arar.",
  "Hedef Forvet": "Fiziksel gücüyle top saklar, kafa toplarına hakimdir.",
  "Avcı Forvet": "Ceza sahası içinde bitiriciliğe odaklanır.",
  "Gizli Forvet": "Arkadan gelip sürpriz goller atar.",
  "Yanlış 9": "Forvet gibi görünür ama derine gelir.",
};

final List<String> availablePlayStyles = playStyleCategories.values
    .expand((element) => element.map((e) => e["name"]!))
    .toList();
// playStyleTranslations view tarafında kullanılıyor, burası doğru.
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
  "Bitirici": {"Bitiricilik": 6, "Hız": 3, "Şut Gücü": 3, "Güç": 1}
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
