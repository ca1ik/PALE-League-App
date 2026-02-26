import 'package:flutter/material.dart';

// --- MODELLER ---

class PlayStyle {
  final String name;
  final bool isGold;

  PlayStyle(this.name, {this.isGold = false});

  // JSON serileştirme için basit bir yapı
  @override
  String toString() => name;
}

class SeasonStats {
  final String season;
  final double avgRating;
  final int goals;
  final int assists;
  final bool isMVP;

  SeasonStats({
    required this.season,
    required this.avgRating,
    required this.goals,
    required this.assists,
    this.isMVP = false,
  });
}

class MatchStat {
  final String opponent;
  final double rating;
  final int goals;
  final int assists;

  MatchStat({
    required this.opponent,
    required this.rating,
    required this.goals,
    required this.assists,
  });
}

class Player {
  final String name;
  final int rating;
  final String position;
  final String team;
  final String cardType;
  final String role;
  final List<PlayStyle> playstyles;
  final Map<String, int> stats;
  final String recLink;
  final String marketValue;
  final int skillMoves;
  final String chemistryStyle;

  // Manuel İstatistikler
  final int manualGoals;
  final int manualAssists;
  final List<MatchStat> manualMatches;
  final List<SeasonStats> seasons;

  Player({
    required this.name,
    required this.rating,
    required this.position,
    required this.team,
    this.cardType = "Temel",
    this.role = "Yedek",
    this.playstyles = const [],
    this.stats = const {},
    this.recLink = "",
    this.marketValue = "€1.0M",
    this.skillMoves = 3,
    this.chemistryStyle = "Basic",
    this.manualGoals = 0,
    this.manualAssists = 0,
    this.manualMatches = const [],
    this.seasons = const [],
  });

  // Drift veritabanı ile uyumluluk için getter'lar
  List<MatchStat> get matches => manualMatches;

  // Simülasyon istatistikleri (Eğer veri yoksa rastgele/varsayılan üretir)
  Map<String, String> getSimulationStats() {
    return {
      'Gol': manualGoals.toString(),
      'Asist': manualAssists.toString(),
      'Pas': "${stats['Pas'] ?? 70}",
      'İsabetli Pas': "${(stats['Pas'] ?? 70) - 5}",
      'Kilit Pas': "${(stats['Pas'] ?? 70) ~/ 10}",
      'Şut': "${stats['Şut'] ?? 60}",
      'Topla Oynama': "%${(stats['Dripling'] ?? 50) ~/ 1.5}",
    };
  }

  // Saha pozisyonu (Mini harita için)
  Offset getPitchPosition() {
    if (position.contains("GK")) return const Offset(0.5, 0.9);
    if (position.contains("LB")) return const Offset(0.2, 0.7);
    if (position.contains("RB")) return const Offset(0.8, 0.7);
    if (position.contains("CB")) return const Offset(0.5, 0.75);
    if (position.contains("CDM")) return const Offset(0.5, 0.6);
    if (position.contains("CM")) return const Offset(0.5, 0.5);
    if (position.contains("LM") || position.contains("LW"))
      return const Offset(0.2, 0.3);
    if (position.contains("RM") || position.contains("RW"))
      return const Offset(0.8, 0.3);
    if (position.contains("CAM")) return const Offset(0.5, 0.35);
    if (position.contains("ST") || position.contains("CF"))
      return const Offset(0.5, 0.15);
    return const Offset(0.5, 0.5);
  }
}

// --- SABİT LİSTELER ---

const List<String> positions = [
  "(1) GK",
  "(2) RB",
  "(3) CB",
  "(4) CB",
  "(5) LB",
  "(6) CDM",
  "(7) RM",
  "(8) CM",
  "(10) CAM",
  "(11) LM",
  "(7) RW",
  "(11) LW",
  "(9) ST",
  "(9) CF"
];

const List<String> globalCardTypes = [
  "Temel",
  "TOTW",
  "TOTM",
  "TOTS",
  "MVP",
  "STAR",
  "BALLONDOR",
  "BAD",
  "ICON",
  "RAMADAN",
  "FUTURE STARS",
  "WINTER",
  "THUNDERSTRUCK",
  "PCL PRO",
  "EVOLUTION",
  "EVOLUTION PLUS",
  "END OF AN ERA",
  "STAFF",
  "PCL CHAMPION",
  "PEL CHAMPION",
  "PECL CHAMPION",
  "FUNCUP CHAMPION",
  "CLASSIC VII",
  "DEFENDER",
  "MIDFIELDER",
  "STRIKER",
  "ELO CHAMPION",
  "TRICKSTER",
  "FM PRO",
  "IQ",
  "KING",
  "TOTS ICON",
  "TRAILBRAZERS",
  "ULTIMATE",
  "VS CHAMPION",
  "DREAMCHASERS",
  "AWARD WINNERS",
  "BIRTHDAY",
];

// İstatistik Segmentleri (Detaylı analiz için)
final Map<String, List<String>> statSegments = {
  "Hücum": ["Bitiricilik", "Şut Gücü", "Uzaktan Şut", "Vole", "Penaltı"],
  "Teknik": ["Top Kontrolü", "Dripling", "Falso", "Serbest Vuruş", "Kısa Pas"],
  "Fizik": ["Hızlanma", "Sprint Hızı", "Çeviklik", "Denge", "Reaksiyon"],
  "Güç": ["Zıplama", "Dayanıklılık", "Güç", "Agresiflik"],
  "Zeka": ["Oyun Görüşü", "Pozisyon Alma", "Soğukkanlılık"],
  "Savunma": ["Top Çalma", "Kayarak Müdahale", "Markaj", "Pas Arası"],
  "Kaleci": ["Refleks", "Uçma", "Elle Oyun", "Ayak", "Yer Tutma"]
};

// Takım Logoları (Assets klasöründe olduklarını varsayıyoruz)
final Map<String, String> teamLogos = {
  "Toulouse": "assets/takimlar/toulouse.png",
  "Livorno": "assets/takimlar/livorno.png",
  "Werder Weremem": "assets/takimlar/werder.png",
  "Maximilian": "assets/takimlar/maximilian.png",
  "Invicta": "assets/takimlar/invicta.png",
  "Bursa Spor": "assets/takimlar/bursaspor.png",
  "Fenerbahçe": "assets/takimlar/fenerbahce.png",
  "CA RIVER PLATE": "assets/takimlar/riverplate.png",
  "Shamrock Rovers": "assets/takimlar/shamrock.png",
  "Chelsea": "assets/takimlar/chelsea.png",
  "It Spor": "assets/takimlar/itspor.png",
  "Tiyatro FC": "assets/takimlar/tiyatro.png",
  "Juventus": "assets/takimlar/juventus.png",
};

// Rol Kategorileri
final Map<String, List<String>> roleCategories = {
  "GK (Kaleci)": ["Çizgi Kalecisi", "Süpürücü Kaleci", "Oyun Kurucu Kaleci"],
  "CDM/CB (Savunma)": [
    "Savunmatik",
    "Libero",
    "Oyun Kurucu Stoper",
    "Tutucu",
    "Derin Oyun Kurucu",
    "Savaşçı"
  ],
  "CM/CAM (Orta Saha)": [
    "Oyun Kurucu",
    "Box to Box",
    "Mezzala",
    "Gölge Forvet",
    "Enganche"
  ],
  "RW/LW (Kanat)": [
    "İç Forvet",
    "Kanat Oyuncusu",
    "Gizli Forvet",
    "Kanat Bek",
    "Hücum Bek"
  ],
  "ST (Forvet)": ["Avcı Forvet", "Hedef Forvet", "Yanlış 9"]
};
