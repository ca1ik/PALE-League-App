import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

// ============================================================================
// HIVE ADAPTERLERİ (GÜVENLİ TİP DÖNÜŞÜMLÜ)
// ============================================================================

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 1;

  @override
  Player read(BinaryReader reader) {
    return Player(
      name: reader.read() ?? "İsimsiz",
      rating: reader.read() ?? 50,
      position: reader.read() ?? "GEN",
      // LİSTE OKUMA DÜZELTİLDİ:
      playstyles:
          (reader.read() as List?)?.whereType<PlayStyle>().toList() ?? [],
      marketValue: reader.read() ?? "N/A",
      matches: (reader.read() as List?)?.whereType<MatchStat>().toList() ?? [],
      team: reader.read() ?? "Takımsız",
      // MAP OKUMA DÜZELTİLDİ:
      stats: (reader.read() as Map?)
              ?.map((k, v) => MapEntry(k.toString(), v as int)) ??
          {},
      role: reader.read() ?? "Yok",
      skillMoves: reader.read() ?? 3,
      country: reader.read() ?? "Türkiye",
      chemistryStyle: reader.read() ?? "Temel",
      cardType: reader.read() ?? "Temel",
      seasons: (reader.read() as List?)?.whereType<SeasonStat>().toList() ?? [],
      recLink: reader.read() ?? "",
      manualGoals: reader.read() ?? 0,
      manualAssists: reader.read() ?? 0,
      manualMatches: reader.read() ?? 0,
      instruction: reader.read() ?? "Balanced",
      style: reader.read() ?? "Temel",
      styleTier: reader.read() ?? 0,
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
      ..write(obj.instruction)
      ..write(obj.style)
      ..write(obj.styleTier);
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
  String style; // YENİ: Oyun Stili (Örn: Kanat Oyuncusu)
  int styleTier; // YENİ: 0=Yok, 1=+, 2=++

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
      this.instruction = "Balanced",
      this.style = "Temel",
      this.styleTier = 0});

  // --- HESAPLAMA METODLARI (Crash Proof) ---

  Map<String, int> getFMStatsCalculated() {
    var raw = getCardStats();
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

  // Returns a simple numeric map of gameplay-relevant stats for the
  // match engine (fallbacks to reasonable defaults when keys are missing).
  Map<String, int> getFMStats() {
    return {
      'Hız': stats['Hız'] ?? 10,
      'Dripling':
          stats['Top Sürme'] ?? stats['Teknik'] ?? stats['Dripling'] ?? 10,
      'Defans': stats['Savunma Farkındalığı'] ?? stats['Top Kapma'] ?? 10,
      'Pozisyon': stats['Pozisyon Alma'] ?? 10,
      'Şut': stats['Bitiricilik'] ?? stats['Şut Gücü'] ?? 10,
      'Pas': stats['Pas'] ?? 10,
      'Fizik': stats['Güç'] ?? 10,
      'Refleks': stats['Reflex'] ?? stats['Refleks'] ?? 10,
    };
  }
}

// GLOBALLER
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
final List<String> gkStatsList = [
  "Refleks",
  "Çizgi Kaleciliği",
  "Pozisyon Alma",
  "Uzun Pas",
  "Kısa Pas"
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
// Global chemistry styles available for quick selection in editor
final List<String> globalChemistryStyles = [
  "Temel",
  "Omurga",
  "Çapa",
  "Mimar",
  "Sanatçı",
  "Katalizör",
  "Gladyatör",
  "Muhafız",
  "Motor",
  "Güçlü",
  "Gözcü",
  "Gölge",
  "Bitirici",
  "Oyun Kurucu",
  "Keskin Nişancı",
  "Şahin",
  "Maestro",
  "Avcı"
];
// Icon mapping for chemistry styles (used in editor UI)
final Map<String, IconData> chemistryIcons = {
  "Temel": Icons.circle_outlined,
  "Mimar": Icons.engineering,
  "Maestro": Icons.music_note,
  "Playmaker": Icons.sports_soccer,
  "Anchor": Icons.anchor,
  "Engine": Icons.bolt,
  "Hızlı": Icons.flash_on,
  "Güçlü": Icons.fitness_center,
};
final List<String> globalRoles = [
  "Kaptan",
  "Yedek",
  "Rotasyon",
  "Yıldız",
  "Genç Yetenek"
];
final Map<String, String> teamLogos = {
  "Takımsız": "",
  "Bursa Spor": "assets/takimlar/bursaspor.png",
  "Chelsea": "assets/takimlar/chelsea.png",
  "Fenerbahçe": "assets/takimlar/fenerbahce.png",
  "Invicta": "assets/takimlar/invicta.png",
  "İtspor": "assets/takimlar/itspor.png",
  "Juventus": "assets/takimlar/juventus.png",
  "Livorno": "assets/takimlar/livorno.png",
  "Maximilian": "assets/takimlar/maximilian.png",
  "River Plate": "assets/takimlar/river.png",
  "Shamrock Rovers": "assets/takimlar/shamrock.png",
  "Tiyatro FC": "assets/takimlar/tiyatro.png",
  "Toulouse": "assets/takimlar/toulouse.png",
  "Werder Weremem": "assets/takimlar/werderweremem.png",
};
final Map<String, List<String>> roleCategories = {
  "(1) GK": ["Çizgi Kalecisi"],
  "(9) ST": ["Hedef Forvet"]
};

// Dil Değişimi İçin Notifier
final ValueNotifier<String> paleHaxLangNotifier = ValueNotifier("TR");

// ============================================================================
// LOCALIZATION MANAGER
// ============================================================================

class PaleHaxLoc {
  static String get lang => paleHaxLangNotifier.value;

  static final Map<String, Map<String, String>> _ui = {
    "TR": {
      "OYUNCULAR": "OYUNCULAR",
      "TAKIMLAR": "TAKIMLAR",
      "VİTRİN": "VİTRİN",
      "AI ANALİZ": "AI ANALİZ",
      "OYUN STİLLERİ": "OYUN STİLLERİ",
      "KART TİPLERİ": "KART TİPLERİ",
      "ROLLER": "ROLLER",
      "PROFİL": "PROFİL",
      "ULTIMATE ANALİZ": "ULTIMATE ANALİZ",
      "YENİ OYUNCU": "YENİ OYUNCU",
      "GLOBAL KARTLAR": "GLOBAL KARTLAR",
      "VİTRİN TAKIMLARI": "VİTRİN TAKIMLARI",
      "DETAYLI ANALİZ": "DETAYLI ANALİZ",
      "SEZON PERFORMANSI": "SEZON PERFORMANSI",
      "MAÇ EKLE": "MAÇ EKLE",
      "KAYDET": "KAYDET",
      "İPTAL": "İPTAL",
      "SİL": "SİL",
      "DÜZENLE": "DÜZENLE",
      "KAPAT": "KAPAT",
      "GÖSTER": "GÖSTER",
      "SONRAKİ": "SONRAKİ",
      "GECE FAZI": "GECE FAZI",
      "GÜNDÜZ FAZI": "GÜNDÜZ FAZI",
      "OYUN STİLLERİ (WIKI)": "OYUN STİLLERİ (WIKI)",
      "İLK OYUNCUYU EKLE": "İLK OYUNCUYU EKLE",
      "OYUNCUNUN DİĞER KARTLARI": "OYUNCUNUN DİĞER KARTLARI",
      "KADRO DEĞERİ": "KADRO DEĞERİ",
      "Kaptan Yap": "Kaptan Yap",
      "Yeni Versiyon Oluştur": "Yeni Versiyon Oluştur",
      "Kartı Düzenle": "Kartı Düzenle",
      "Kartı Sil": "Kartı Sil",
      "Mevcut kartın özelliklerini değiştirir.":
          "Mevcut kartın özelliklerini değiştirir.",
      "Örn: TOTS, TOTW gibi yeni bir kart çıkarır.":
          "Örn: TOTS, TOTW gibi yeni bir kart çıkarır.",
      "TOPLAM GOL": "TOPLAM GOL",
      "TOPLAM ASİST": "TOPLAM ASİST",
      "MAÇ SAYISI": "MAÇ SAYISI",
      "Henüz maç girilmedi.": "Henüz maç girilmedi.",
      "YÜKSELİŞTE 📈": "YÜKSELİŞTE 📈",
      "DÜŞÜŞTE 📉": "DÜŞÜŞTE 📉",
      "DENGELİ": "DENGELİ",
      "Kimya": "Kimya",
      "Rol": "Rol",
      "Stil": "Stil",
      "Yetenek": "Yetenek",
      "Zayıf Ayak": "Zayıf Ayak",
      "Değer": "Değer",
      "UYGULAMA": "UYGULAMA",
      "WEB SİTESİ": "WEB SİTESİ",
      "V7 META ANALİZİ": "V7 META ANALİZİ",
      "Bitirici": "Bitirici",
      "Pas": "Pas",
      "Savunma/Fiziksel": "Savunma/Fiziksel",
      "Dripling": "Dripling",
      "Kaleci": "Kaleci",
      "Ara...": "Ara...",
      "Tümü": "Tümü",
      "Reyting": "Reyting",
      "A-Z": "A-Z",
      "En Yeni": "En Yeni",
      "Görüntü kaydedildi!": "Görüntü kaydedildi!",
      "TAKIM İSMİ": "TAKIM İSMİ",
      "İNDİR (PNG)": "İNDİR (PNG)",
      "Oyuncu Ara...": "Oyuncu Ara...",
      "YENİ OYUNCU OLUŞTUR": "YENİ OYUNCU OLUŞTUR",
      "OYUNCUYU DÜZENLE": "OYUNCUYU DÜZENLE",
      "Takım": "Takım",
      "Pozisyon": "Pozisyon",
      "Kart Tipi": "Kart Tipi",
      "Kimya Stili": "Kimya Stili",
      "Piyasa Değeri (M€)": "Piyasa Değeri (M€)",
      "Oyun Stili": "Oyun Stili",
      "Yetenek & Zayıf Ayak": "Yetenek & Zayıf Ayak",
      "İSTATİSTİKLER": "İSTATİSTİKLER",
      "NORMAL PS": "NORMAL PS",
      "PLUS PS": "PLUS PS",
      "SEÇİLENLERİ TEMİZLE": "SEÇİLENLERİ TEMİZLE",
      "Ad Soyad": "Ad Soyad",
      "Ekle": "Ekle",
      "İptal": "İptal",
      "Bu oyuncunun kartı henüz oluşturulmamış.":
          "Bu oyuncunun kartı henüz oluşturulmamış.",
      "DETAYLI OYUNCU ANALİZİ": "DETAYLI OYUNCU ANALİZİ",
      "Yeni Oyuncu": "Yeni Oyuncu",
      "Sil": "Sil",
      "AI_ANALIZ_BASLIK": "AI ANALİZ",
      "AI_ANALIZ_EDIT": "Analizi Düzenle",
      "AI_ANALIZ_KAYDET": "KAYDET",
      "AI_ANALIZ_IPTAL": "İptal",
    },
    "EN": {
      "OYUNCULAR": "PLAYERS",
      "TAKIMLAR": "TEAMS",
      "VİTRİN": "SHOWCASE",
      "AI ANALİZ": "AI ANALYSIS",
      "OYUN STİLLERİ": "PLAYSTYLES",
      "KART TİPLERİ": "CARD TYPES",
      "ROLLER": "ROLES",
      "PROFİL": "PROFILE",
      "ULTIMATE ANALİZ": "ULTIMATE ANALYSIS",
      "YENİ OYUNCU": "NEW PLAYER",
      "GLOBAL KARTLAR": "GLOBAL CARDS",
      "VİTRİN TAKIMLARI": "SQUAD BUILDER",
      "DETAYLI ANALİZ": "DETAILED ANALYSIS",
      "SEZON PERFORMANSI": "SEASON PERFORMANCE",
      "MAÇ EKLE": "ADD MATCH",
      "KAYDET": "SAVE",
      "İPTAL": "CANCEL",
      "SİL": "DELETE",
      "DÜZENLE": "EDIT",
      "KAPAT": "CLOSE",
      "GÖSTER": "SHOW",
      "SONRAKİ": "NEXT",
      "GECE FAZI": "NIGHT PHASE",
      "GÜNDÜZ FAZI": "DAY PHASE",
      "OYUN STİLLERİ (WIKI)": "PLAYSTYLES (WIKI)",
      "İLK OYUNCUYU EKLE": "ADD FIRST PLAYER",
      "OYUNCUNUN DİĞER KARTLARI": "OTHER CARDS",
      "KADRO DEĞERİ": "SQUAD VALUE",
      "Kaptan Yap": "Make Captain",
      "Yeni Versiyon Oluştur": "Create New Version",
      "Kartı Düzenle": "Edit Card",
      "Kartı Sil": "Delete Card",
      "Mevcut kartın özelliklerini değiştirir.":
          "Modifies current card attributes.",
      "Örn: TOTS, TOTW gibi yeni bir kart çıkarır.":
          "Creates a new card like TOTS, TOTW.",
      "TOPLAM GOL": "TOTAL GOALS",
      "TOPLAM ASİST": "TOTAL ASSISTS",
      "MAÇ SAYISI": "MATCHES",
      "Henüz maç girilmedi.": "No matches entered yet.",
      "YÜKSELİŞTE 📈": "RISING 📈",
      "DÜŞÜŞTE 📉": "FALLING 📉",
      "DENGELİ": "BALANCED",
      "Kimya": "Chem",
      "Rol": "Role",
      "Stil": "Style",
      "Yetenek": "Skill",
      "Zayıf Ayak": "Weak Foot",
      "Değer": "Value",
      "UYGULAMA": "APP",
      "WEB SİTESİ": "WEBSITE",
      "V7 META ANALİZİ": "V7 META ANALYSIS",
      "Bitirici": "Finishing",
      "Pas": "Passing",
      "Savunma/Fiziksel": "Def/Phys",
      "Dripling": "Dribbling",
      "Kaleci": "Goalkeeper",
      "Ara...": "Search...",
      "Tümü": "All",
      "Reyting": "Rating",
      "A-Z": "A-Z",
      "En Yeni": "Newest",
      "Görüntü kaydedildi!": "Image saved!",
      "TAKIM İSMİ": "TEAM NAME",
      "İNDİR (PNG)": "DOWNLOAD (PNG)",
      "Oyuncu Ara...": "Search Player...",
      "YENİ OYUNCU OLUŞTUR": "CREATE NEW PLAYER",
      "OYUNCUYU DÜZENLE": "EDIT PLAYER",
      "Takım": "Team",
      "Pozisyon": "Position",
      "Kart Tipi": "Card Type",
      "Kimya Stili": "Chem Style",
      "Piyasa Değeri (M€)": "Market Value (M€)",
      "Oyun Stili": "PlayStyle",
      "Yetenek & Zayıf Ayak": "Skill & Weak Foot",
      "İSTATİSTİKLER": "STATS",
      "NORMAL PS": "NORMAL PS",
      "PLUS PS": "PLUS PS",
      "SEÇİLENLERİ TEMİZLE": "CLEAR SELECTED",
      "Ad Soyad": "Name",
      "Ekle": "Add",
      "İptal": "Cancel",
      "Bu oyuncunun kartı henüz oluşturulmamış.": "Card not created yet.",
      "DETAYLI OYUNCU ANALİZİ": "DETAILED PLAYER ANALYSIS",
      "Yeni Oyuncu": "New Player",
      "Sil": "Delete",
      "AI_ANALIZ_BASLIK": "AI ANALYSIS",
      "AI_ANALIZ_EDIT": "Edit Analysis",
      "AI_ANALIZ_KAYDET": "SAVE",
      "AI_ANALIZ_IPTAL": "Cancel",
    },
    "SP": {
      "OYUNCULAR": "JUGADORES",
      "TAKIMLAR": "EQUIPOS",
      "VİTRİN": "ESCAPARATE",
      "AI ANALİZ": "ANÁLISIS IA",
      "OYUN STİLLERİ": "ESTILOS DE JUEGO",
      "KART TİPLERİ": "TIPOS DE CARTA",
      "ROLLER": "ROLES",
      "PROFİL": "PERFIL",
      "ULTIMATE ANALİZ": "ANÁLISIS ULTIMATE",
      "YENİ OYUNCU": "NUEVO JUGADOR",
      "GLOBAL KARTLAR": "CARTAS GLOBALES",
      "VİTRİN TAKIMLARI": "CONSTRUCTOR DE EQUIPOS",
      "DETAYLI ANALİZ": "ANÁLISIS DETALLADO",
      "SEZON PERFORMANSI": "RENDIMIENTO DE TEMPORADA",
      "MAÇ EKLE": "AÑADIR PARTIDO",
      "KAYDET": "GUARDAR",
      "İPTAL": "CANCELAR",
      "SİL": "ELIMINAR",
      "DÜZENLE": "EDITAR",
      "KAPAT": "CERRAR",
      "GÖSTER": "MOSTRAR",
      "SONRAKİ": "SIGUIENTE",
      "GECE FAZI": "FASE NOCTURNA",
      "GÜNDÜZ FAZI": "FASE DIURNA",
      "OYUN STİLLERİ (WIKI)": "ESTILOS DE JUEGO (WIKI)",
      "İLK OYUNCUYU EKLE": "AÑADIR PRIMER JUGADOR",
      "OYUNCUNUN DİĞER KARTLARI": "OTRAS CARTAS",
      "KADRO DEĞERİ": "VALOR DE PLANTILLA",
      "Kaptan Yap": "Hacer Capitán",
      "Yeni Versiyon Oluştur": "Crear Nueva Versión",
      "Kartı Düzenle": "Editar Carta",
      "Kartı Sil": "Eliminar Carta",
      "Mevcut kartın özelliklerini değiştirir.":
          "Modifica los atributos actuales.",
      "Örn: TOTS, TOTW gibi yeni bir kart çıkarır.":
          "Crea una nueva carta como TOTS, TOTW.",
      "TOPLAM GOL": "GOLES TOTALES",
      "TOPLAM ASİST": "ASISTENCIAS TOTALES",
      "MAÇ SAYISI": "PARTIDOS",
      "Henüz maç girilmedi.": "Aún no hay partidos.",
      "YÜKSELİŞTE 📈": "SUBIENDO 📈",
      "DÜŞÜŞTE 📉": "BAJANDO 📉",
      "DENGELİ": "EQUILIBRADO",
      "Kimya": "Química",
      "Rol": "Rol",
      "Stil": "Estilo",
      "Yetenek": "Habilidad",
      "Zayıf Ayak": "Pie Débil",
      "Değer": "Valor",
      "UYGULAMA": "APLICACIÓN",
      "WEB SİTESİ": "SITIO WEB",
      "V7 META ANALİZİ": "ANÁLISIS META V7",
      "Bitirici": "Finalización",
      "Pas": "Pase",
      "Savunma/Fiziksel": "Def/Fís",
      "Dripling": "Regate",
      "Kaleci": "Portero",
      "Ara...": "Buscar...",
      "Tümü": "Todos",
      "Reyting": "Valoración",
      "A-Z": "A-Z",
      "En Yeni": "Más Nuevos",
      "Görüntü kaydedildi!": "¡Imagen guardada!",
      "TAKIM İSMİ": "NOMBRE DEL EQUIPO",
      "İNDİR (PNG)": "DESCARGAR (PNG)",
      "Oyuncu Ara...": "Buscar Jugador...",
      "YENİ OYUNCU OLUŞTUR": "CREAR NUEVO JUGADOR",
      "OYUNCUYU DÜZENLE": "EDITAR JUGADOR",
      "Takım": "Equipo",
      "Pozisyon": "Posición",
      "Kart Tipi": "Tipo de Carta",
      "Kimya Stili": "Estilo de Química",
      "Piyasa Değeri (M€)": "Valor de Mercado (M€)",
      "Oyun Stili": "Estilo de Juego",
      "Yetenek & Zayıf Ayak": "Habilidad y Pie Débil",
      "İSTATİSTİKLER": "ESTADÍSTICAS",
      "NORMAL PS": "NORMAL PS",
      "PLUS PS": "PLUS PS",
      "SEÇİLENLERİ TEMİZLE": "LIMPIAR SELECCIONADOS",
      "Ad Soyad": "Nombre",
      "Ekle": "Añadir",
      "İptal": "Cancelar",
      "Bu oyuncunun kartı henüz oluşturulmamış.": "Carta aún no creada.",
      "DETAYLI OYUNCU ANALİZİ": "ANÁLISIS DETALLADO DEL JUGADOR",
      "Yeni Oyuncu": "Nuevo Jugador",
      "Sil": "Eliminar",
      "AI_ANALIZ_BASLIK": "ANÁLISIS IA",
      "AI_ANALIZ_EDIT": "Editar Análisis",
      "AI_ANALIZ_KAYDET": "GUARDAR",
      "AI_ANALIZ_IPTAL": "Cancelar",
    }
  };

  static final Map<String, Map<String, String>> _stats = {
    "TR": {}, // Default keys are TR
    "EN": {
      "Hız": "Pace",
      "Hızlanma": "Acceleration",
      "Çeviklik": "Agility",
      "Denge": "Balance",
      "Top Sürme": "Dribbling",
      "Duvar Kabiliyeti": "Hold Up",
      "Teknik": "Technique",
      "Şut Gücü": "Shot Power",
      "Pozisyon Alma": "Positioning",
      "Bitiricilik": "Finishing",
      "Uzaktan Şut": "Long Shots",
      "Soğukkanlılık": "Composure",
      "Karar Alma": "Decisions",
      "Roket Şut": "Rocket Shot",
      "Top Kapma": "Tackling",
      "Savunma Farkındalığı": "Def. Awareness",
      "Sert Duruş": "Stand Tackle",
      "Güç": "Strength",
      "Saldırganlık": "Aggression",
      "Markaj": "Marking",
      "Top Kesme": "Interception",
      "Pas": "Passing",
      "Ara Pas": "Through Ball",
      "Takım Oyunu": "Teamwork",
      "Görüş": "Vision",
      "Topsuz Alan": "Off the Ball",
      "Orta Yapma": "Crossing",
      "Top Kontrolü": "Ball Control",
      "Refleks": "Reflexes",
      "Çizgi Kaleciliği": "Diving",
      "Uzun Pas": "Kicking",
      "Kısa Pas": "Handling",
      "1e1 Savunma": "1v1",
      "1. Top Sürme & Fizik": "1. Dribbling & Physical",
      "2. Şut & Zihinsel": "2. Shooting & Mental",
      "3. Savunma & Güç": "3. Defense & Strength",
      "4. Pas & Vizyon": "4. Passing & Vision",
      "KALECİLİK": "GOALKEEPING",
      "FİZİKSEL": "PHYSICAL",
      "ZİHİNSEL": "MENTAL"
    },
    "SP": {
      "Hız": "Ritmo",
      "Hızlanma": "Aceleración",
      "Çeviklik": "Agilidad",
      "Denge": "Equilibrio",
      "Top Sürme": "Regate",
      "Duvar Kabiliyeti": "Juego de Espaldas",
      "Teknik": "Técnica",
      "Şut Gücü": "Potencia Tiro",
      "Pozisyon Alma": "Posicionamiento",
      "Bitiricilik": "Definición",
      "Uzaktan Şut": "Tiros Lejanos",
      "Soğukkanlılık": "Compostura",
      "Karar Alma": "Decisiones",
      "Roket Şut": "Tiro Cohete",
      "Top Kapma": "Entradas",
      "Savunma Farkındalığı": "Conciencia Def.",
      "Sert Duruş": "Robo",
      "Güç": "Fuerza",
      "Saldırganlık": "Agresividad",
      "Markaj": "Marcaje",
      "Top Kesme": "Intercepción",
      "Pas": "Pase",
      "Ara Pas": "Pase al Hueco",
      "Takım Oyunu": "Trabajo Equipo",
      "Görüş": "Visión",
      "Topsuz Alan": "Desmarque",
      "Orta Yapma": "Centros",
      "Top Kontrolü": "Control Balón",
      "Refleks": "Reflejos",
      "Çizgi Kaleciliği": "Estirada",
      "Uzun Pas": "Saque",
      "Kısa Pas": "Manejo",
      "1e1 Savunma": "1v1",
      "1. Top Sürme & Fizik": "1. Regate y Físico",
      "2. Şut & Zihinsel": "2. Tiro y Mental",
      "3. Savunma & Güç": "3. Defensa y Fuerza",
      "4. Pas & Vizyon": "4. Pase y Visión",
      "KALECİLİK": "PORTERO",
      "FİZİKSEL": "FÍSICO",
      "ZİHİNSEL": "MENTAL"
    }
  };

  static String txt(String key) {
    return _ui[lang]?[key] ?? key;
  }

  static String stat(String key) {
    if (lang == "TR") return key;
    return _stats[lang]?[key] ?? key;
  }

  // --- DYNAMIC TRANSLATIONS FOR PLAYSTYLES, ROLES, ETC. ---

  static final Map<String, Map<String, String>> _descriptions = {
    "TR": {
      // PlayStyles
      "ps_desc_GameChanger": "Sıradışı bitirişler ve yaratıcı vuruşlar.",
      "ps_desc_Acrobatic": "Akrobatik paslar ve estetik vuruşlar.",
      "ps_desc_PowerShot": "Ceza sahası dışından sert şutlar.",
      "ps_desc_FinesseShot": "Köşelere isabetli ve kaliteli şutlar.",
      "ps_desc_ChipShot": "Kaleciyi önde yakalayan aşırtma vuruşlar.",
      "ps_desc_IncisivePass": "Savunmayı yaran koşturucu paslar.",
      "ps_desc_PingedPass": "Hızlı ve sert adrese teslim paslar.",
      "ps_desc_LongBallPass": "Uzaktaki oyuncuya nokta atışı paslar.",
      "ps_desc_TikiTaka": "İlk vuruşta isabetli kısa paslar.",
      "ps_desc_WhippedPass": "Hızlı ve sert ceza sahası ortaları.",
      "ps_desc_Inventive": "Zekice ve tahmin edilemez paslar.",
      "ps_desc_Jockey": "Bire bir mücadele uzmanı.",
      "ps_desc_Block": "Esnek ve markajlayarak blok yapma.",
      "ps_desc_Intercept": "Topu kapma ve sahip olma yeteneği.",
      "ps_desc_Anticipate": "Düşük hata oranıyla top çalma.",
      "ps_desc_Bruiser": "Bodyleme ve fiziksel top kazanma.",
      "ps_desc_AerialFortress": "Sert paslara kontrollü hava tepkisi.",
      "ps_desc_Technical": "Teknik top sürme becerisi.",
      "ps_desc_Rapid": "Rakibi hızla ekarte etme.",
      "ps_desc_FirstTouch": "Zor pozisyonlarda isabetli kontrol.",
      "ps_desc_Trickster": "Yetenekli duvar hareketleri.",
      "ps_desc_PressProven": "Fiziksel baskı altında hakimiyet.",
      "ps_desc_QuickStep": "Topla birlikte hızlı dripling.",
      "ps_desc_FarReach": "Uzak köşelere uzanabilir.",
      "ps_desc_Footwork": "Kaliteli pas atan pasör kaleci.",
      "ps_desc_CrossClaimer": "Markajla top kesen kaleci.",
      "ps_desc_RushOut": "Agresif şut/pas engelleme.",
      // Roles
      "role_desc_Çizgi Kalecisi": "Refleks kurtarışları yapar.",
      "role_desc_Süpürücü Kaleci": "Defans arkası toplara çıkar.",
      "role_desc_Oyun Kurucu Kaleci": "Geriden oyun kurar.",
      "role_desc_Savunmatik": "Önceliği defans güvenliğidir.",
      "role_desc_Libero": "En arkada serbest oynar.",
      "role_desc_Oyun Kurucu Stoper": "Topu oyuna sokar.",
      "role_desc_Tutucu": "Defans önünü süpürür.",
      "role_desc_Derin Oyun Kurucu": "Geriden oyun kurar.",
      "role_desc_Savaşçı": "Rakibi yıpratır.",
      "role_desc_Oyun Kurucu": "Takımın beyni konumu.",
      "role_desc_Box to Box": "İki ceza sahası arası mekik dokur.",
      "role_desc_Mezzala": "Yarı kanat, yaratıcı merkez oyuncusu.",
      "role_desc_Gölge Forvet": "Forvet arkasından gol arayan oyuncu.",
      "role_desc_Enganche": "Klasik 10 numara tarzı oyun kurucu.",
      "role_desc_İç Forvet": "Kanattan içeri kat edip şut çeker.",
      "role_desc_Kanat Oyuncusu": "Çizgiye inip orta yapmaya odaklanır.",
      "role_desc_Gizli Forvet": "Geri planda kalıp sürpriz goller arar.",
      "role_desc_Avcı Forvet": "Ceza sahası içi bitiriciliğe odaklanır.",
      "role_desc_Hedef Forvet": "Top saklayıp arkadaşlarına servis yapar.",
      "role_desc_Yanlış 9": "Forvet görünüp orta sahaya yardıma gelir.",
      "role_desc_Kanat Bek": "Hücuma katkı veren savunma oyuncusu.",
      "role_desc_Hücum Bek": "Neredeyse kanat gibi oynayan bek.",
      // Card Types
      "card_desc_Temel": "Standart oyuncu kartı.",
      "card_desc_TOTW": "Haftanın Takımı.",
      "card_desc_TOTS": "Sezonun Takımı.",
      "card_desc_MVP": "En Değerli Oyuncu.",
      "card_desc_STAR": "Yıldız Oyuncu.",
      "card_desc_BALLOND'OR": "Sezonun Oyuncusu.",
      "card_desc_BAD": "Facia Performans.",
      "card_desc_TOTM": "Ayın Takımı.",
    },
    "EN": {
      // PlayStyles
      "ps_desc_GameChanger": "Exceptional finishing and creative shots.",
      "ps_desc_Acrobatic": "Acrobatic passes and aesthetic shots.",
      "ps_desc_PowerShot": "Powerful shots from outside the box.",
      "ps_desc_FinesseShot": "Accurate and quality shots to corners.",
      "ps_desc_ChipShot": "Chip shots catching the keeper off guard.",
      "ps_desc_IncisivePass": "Through balls that split the defense.",
      "ps_desc_PingedPass": "Fast and accurate delivered passes.",
      "ps_desc_LongBallPass": "Pinpoint passes to distant players.",
      "ps_desc_TikiTaka": "Accurate short passes on first touch.",
      "ps_desc_WhippedPass": "Fast and hard crosses into the box.",
      "ps_desc_Inventive": "Clever and unpredictable passes.",
      "ps_desc_Jockey": "Expert in 1v1 duels.",
      "ps_desc_Block": "Flexible blocking with marking.",
      "ps_desc_Intercept": "Ability to intercept and possess the ball.",
      "ps_desc_Anticipate": "Stealing ball with low error rate.",
      "ps_desc_Bruiser": "Physical ball winning and bodying.",
      "ps_desc_AerialFortress": "Controlled aerial response to hard passes.",
      "ps_desc_Technical": "Technical dribbling skills.",
      "ps_desc_Rapid": "Beating opponents with speed.",
      "ps_desc_FirstTouch": "Accurate control in difficult positions.",
      "ps_desc_Trickster": "Skilled wall movements.",
      "ps_desc_PressProven": "Composure under physical pressure.",
      "ps_desc_QuickStep": "Fast dribbling with the ball.",
      "ps_desc_FarReach": "Can reach far corners.",
      "ps_desc_Footwork": "Passing goalkeeper with quality distribution.",
      "ps_desc_CrossClaimer": "Keeper intercepting with marking.",
      "ps_desc_RushOut": "Aggressive shot/pass prevention.",
      // Roles
      "role_desc_Çizgi Kalecisi": "Makes reflex saves.",
      "role_desc_Süpürücü Kaleci": "Sweeps balls behind defense.",
      "role_desc_Oyun Kurucu Kaleci": "Builds play from the back.",
      "role_desc_Savunmatik": "Priority is defensive security.",
      "role_desc_Libero": "Plays freely at the back.",
      "role_desc_Oyun Kurucu Stoper": "Distributes ball into play.",
      "role_desc_Tutucu": "Sweeps in front of defense.",
      "role_desc_Derin Oyun Kurucu": "Deep-lying playmaker.",
      "role_desc_Savaşçı": "Wears down the opponent.",
      "role_desc_Oyun Kurucu": "The brain of the team.",
      "role_desc_Box to Box": "Shuttles between two boxes.",
      "role_desc_Mezzala": "Half-winger, creative central player.",
      "role_desc_Gölge Forvet": "Seeks goals from behind striker.",
      "role_desc_Enganche": "Classic number 10 playmaker.",
      "role_desc_İç Forvet": "Cuts inside from wing to shoot.",
      "role_desc_Kanat Oyuncusu": "Focuses on crossing from the line.",
      "role_desc_Gizli Forvet": "Stays back and seeks surprise goals.",
      "role_desc_Avcı Forvet": "Focuses on finishing inside the box.",
      "role_desc_Hedef Forvet": "Holds ball and serves teammates.",
      "role_desc_Yanlış 9": "Looks like striker, helps midfield.",
      "role_desc_Kanat Bek": "Defender contributing to attack.",
      "role_desc_Hücum Bek": "Full-back playing almost like a winger.",
      // Card Types
      "card_desc_Temel": "Standard player card.",
      "card_desc_TOTW": "Team of the Week.",
      "card_desc_TOTS": "Team of the Season.",
      "card_desc_MVP": "Most Valuable Player.",
      "card_desc_STAR": "Star Player.",
      "card_desc_BALLOND'OR": "Player of the Season.",
      "card_desc_BAD": "Disaster Performance.",
      "card_desc_TOTM": "Team of the Month.",
    },
    "SP": {
      // PlayStyles
      "ps_desc_GameChanger": "Finalización excepcional y tiros creativos.",
      "ps_desc_Acrobatic": "Pases acrobáticos y tiros estéticos.",
      "ps_desc_PowerShot": "Tiros potentes desde fuera del área.",
      "ps_desc_FinesseShot": "Tiros precisos y de calidad a las esquinas.",
      "ps_desc_ChipShot": "Vaselinas que sorprenden al portero.",
      "ps_desc_IncisivePass": "Pases al hueco que rompen la defensa.",
      "ps_desc_PingedPass": "Pases rápidos y precisos.",
      "ps_desc_LongBallPass": "Pases milimétricos a jugadores lejanos.",
      "ps_desc_TikiTaka": "Pases cortos precisos al primer toque.",
      "ps_desc_WhippedPass": "Centros rápidos y fuertes al área.",
      "ps_desc_Inventive": "Pases inteligentes e impredecibles.",
      "ps_desc_Jockey": "Experto en duelos 1v1.",
      "ps_desc_Block": "Bloqueo flexible con marcaje.",
      "ps_desc_Intercept": "Capacidad para interceptar y poseer el balón.",
      "ps_desc_Anticipate": "Robo de balón con baja tasa de error.",
      "ps_desc_Bruiser": "Ganancia física de balón y cuerpo a cuerpo.",
      "ps_desc_AerialFortress": "Respuesta aérea controlada a pases fuertes.",
      "ps_desc_Technical": "Habilidades de regate técnico.",
      "ps_desc_Rapid": "Superar oponentes con velocidad.",
      "ps_desc_FirstTouch": "Control preciso en posiciones difíciles.",
      "ps_desc_Trickster": "Movimientos de pared hábiles.",
      "ps_desc_PressProven": "Compostura bajo presión física.",
      "ps_desc_QuickStep": "Regate rápido con el balón.",
      "ps_desc_FarReach": "Puede alcanzar esquinas lejanas.",
      "ps_desc_Footwork": "Portero pasador con distribución de calidad.",
      "ps_desc_CrossClaimer": "Portero interceptando con marcaje.",
      "ps_desc_RushOut": "Prevención agresiva de tiros/pases.",
      // Roles
      "role_desc_Çizgi Kalecisi": "Realiza paradas de reflejos.",
      "role_desc_Süpürücü Kaleci": "Barre balones detrás de la defensa.",
      "role_desc_Oyun Kurucu Kaleci": "Construye juego desde atrás.",
      "role_desc_Savunmatik": "La prioridad es la seguridad defensiva.",
      "role_desc_Libero": "Juega libremente en la parte trasera.",
      "role_desc_Oyun Kurucu Stoper": "Distribuye el balón al juego.",
      "role_desc_Tutucu": "Barre delante de la defensa.",
      "role_desc_Derin Oyun Kurucu": "Organizador retrasado.",
      "role_desc_Savaşçı": "Desgasta al oponente.",
      "role_desc_Oyun Kurucu": "El cerebro del equipo.",
      "role_desc_Box to Box": "Se mueve entre las dos áreas.",
      "role_desc_Mezzala": "Medio extremo, jugador central creativo.",
      "role_desc_Gölge Forvet": "Busca goles desde atrás del delantero.",
      "role_desc_Enganche": "Clásico número 10 organizador.",
      "role_desc_İç Forvet": "Corta hacia adentro desde la banda para tirar.",
      "role_desc_Kanat Oyuncusu": "Se centra en cruzar desde la línea.",
      "role_desc_Gizli Forvet": "Se queda atrás y busca goles sorpresa.",
      "role_desc_Avcı Forvet": "Se centra en finalizar dentro del área.",
      "role_desc_Hedef Forvet": "Aguanta el balón y sirve a compañeros.",
      "role_desc_Yanlış 9": "Parece delantero, ayuda al medio campo.",
      "role_desc_Kanat Bek": "Defensor que contribuye al ataque.",
      "role_desc_Hücum Bek": "Lateral que juega casi como extremo.",
      // Card Types
      "card_desc_Temel": "Carta de jugador estándar.",
      "card_desc_TOTW": "Equipo de la Semana.",
      "card_desc_TOTS": "Equipo de la Temporada.",
      "card_desc_MVP": "Jugador Más Valioso.",
      "card_desc_STAR": "Jugador Estrella.",
      "card_desc_BALLOND'OR": "Jugador de la Temporada.",
      "card_desc_BAD": "Rendimiento Desastroso.",
      "card_desc_TOTM": "Equipo del Mes.",
    }
  };

  static String getDesc(String key) {
    return _descriptions[lang]?[key] ?? _descriptions["TR"]?[key] ?? key;
  }

  // --- AI ANALYSIS SENTENCES ---
  static final Map<String, Map<String, String>> _aiSentences = {
    "TR": {
      "ai_sho_85":
          "Sezon içerisinde attığı gollerin kalitesi ve bitiriciliği ile rakip kalecilerin korkulu rüyası.",
      "ai_sho_75":
          "Boşlukları kollayıp doğru açıdan vurduğunda affetmeyen bir bitirici.",
      "ai_pas_85":
          "Oyun görüşü o kadar üst düzey ki, attığı milimetrik paslarla takımını bir maestro gibi yönetiyor.",
      "ai_dri_85":
          "Top ayağına yapıştığında durdurulması imkansız, adam eksiltme konusunda tam bir sanatçı.",
      "ai_def_85":
          "Savunmada adeta bir duvar; kademe anlayışı ve top çalma yeteneğiyle geçit vermiyor.",
      "ai_phy_85":
          "İkili mücadelelerdeki fiziksel üstünlüğü ile sahada dominasyon kuruyor.",
      "ai_pac_90":
          "Rüzgarın oğlu! Savunma arkasına yaptığı koşularda onu yakalamak neredeyse imkansız.",
      "ai_style_tier2": "Dünya çapında bir",
      "ai_style_tier1": "Elit seviyede bir",
      "ai_style_perf":
          "Oyun stili olarak tam anlamıyla {tier} {style} performansı sergiliyor.",
      "ai_style_master":
          "Bu rolde o kadar ustalaşmış ki, taktik tahtasında ismi yazılan ilk oyunculardan.",
      "ai_default":
          "Sahada görevini layıkıyla yapan, takım oyununa sadık bir profil çiziyor.",
    },
    "EN": {
      "ai_sho_85":
          "A nightmare for goalkeepers with the quality of goals and finishing shown throughout the season.",
      "ai_sho_75":
          "An unforgiving finisher when finding space and striking from the right angle.",
      "ai_pas_85":
          "Vision is so high level, manages the team like a maestro with millimetric passes.",
      "ai_dri_85":
          "Impossible to stop when the ball sticks to feet, a true artist in beating opponents.",
      "ai_def_85":
          "Like a wall in defense; does not let anyone pass with positioning and tackling ability.",
      "ai_phy_85":
          "Establishes domination on the field with physical superiority in duels.",
      "ai_pac_90":
          "Son of the wind! Almost impossible to catch on runs behind the defense.",
      "ai_style_tier2": "World class",
      "ai_style_tier1": "Elite level",
      "ai_style_perf":
          "Displays a truly {tier} {style} performance as a playstyle.",
      "ai_style_master":
          "So mastered in this role that they are one of the first names on the tactics board.",
      "ai_default":
          "Draws a profile loyal to team play, performing duties properly on the field.",
    },
    "SP": {
      "ai_sho_85":
          "Una pesadilla para los porteros con la calidad de goles y definición mostrada durante la temporada.",
      "ai_sho_75":
          "Un finalizador implacable cuando encuentra espacio y golpea desde el ángulo correcto.",
      "ai_pas_85":
          "La visión es de tan alto nivel, maneja al equipo como un maestro con pases milimétricos.",
      "ai_dri_85":
          "Imposible de parar cuando el balón se pega a los pies, un verdadero artista regateando.",
      "ai_def_85":
          "Como un muro en defensa; no deja pasar a nadie con su posicionamiento y capacidad de robo.",
      "ai_phy_85":
          "Establece dominación en el campo con superioridad física en los duelos.",
      "ai_pac_90":
          "¡Hijo del viento! Casi imposible de atrapar en carreras detrás de la defensa.",
      "ai_style_tier2": "Clase mundial",
      "ai_style_tier1": "Nivel élite",
      "ai_style_perf":
          "Muestra un rendimiento verdaderamente {tier} de {style} como estilo de juego.",
      "ai_style_master":
          "Tan dominado en este rol que es uno de los primeros nombres en la pizarra táctica.",
      "ai_default":
          "Dibuja un perfil leal al juego de equipo, cumpliendo sus deberes adecuadamente en el campo.",
    }
  };

  static String ai(String key, {Map<String, String>? params}) {
    String text = _aiSentences[lang]?[key] ?? _aiSentences["TR"]?[key] ?? key;
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll("{$k}", v);
      });
    }
    return text;
  }
}

// YENİ: Türkçe Kimya Çevirileri
final Map<String, String> chemistryTranslations = {
  "Basic": "Temel",
  "Sniper": "Keskin Nişancı",
  "Finisher": "Bitirici",
  "Deadeye": "Gözü Kara",
  "Marksman": "Nişancı",
  "Hawk": "Şahin",
  "Artist": "Sanatçı",
  "Architect": "Mimar",
  "Powerhouse": "Güç Deposu",
  "Maestro": "Maestro",
  "Engine": "Motor",
  "Sentinel": "Nöbetçi",
  "Guardian": "Muhafız",
  "Gladiator": "Gladyatör",
  "Backbone": "Omurga",
  "Anchor": "Çapa",
  "Hunter": "Avcı",
  "Catalyst": "Katalizör",
  "Shadow": "Gölge",
  "GK Basic": "KL Temel",
  "Wall": "Duvar",
  "Shield": "Kalkan",
  "Cat": "Kedi",
  "Glove": "Eldiven"
};

// YENİ: Stil Seçenekleri
final Map<String, List<String>> styleOptions = {
  "GK": ["Çizgi Kaleci", "Süpürücü Kaleci", "Topla Oynayan Kaleci"],
  "DEF": ["Çakılı Defans", "Dengeli Defans", "Pasör Defans", "Tutucu Defans"],
  "MID": ["Box to Box", "Oyun Kurucu", "Derin Oyun Kurucu", "Yarı Kanat OS"],
  "WING": [
    "Kanat Oyuncusu",
    "İç Forvet",
    "Gizli Forvet",
    "Avcı Forvet",
    "Geniş Oyun Kurucu"
  ],
  "FWD": [
    "False 9",
    "Avcı Forvet",
    "Gizli Forvet",
    "Hedef Forvet",
    "Gelişmiş Forvet"
  ]
};

// YENİ: Pozisyon Listesi (Sınırlandırılmış)

const List<String> positions = [
  "(1) GK",
  "(3) CB",
  "(6) CDM",
  "(10) CAM",
  "(7) RW",
  "(11) LW",
  "(9) ST"
];
