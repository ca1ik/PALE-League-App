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
      team: reader.read(), // YENİ: Takım okuma
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
    writer.write(obj.team); // YENİ: Takım yazma
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

class Player {
  final String name;
  final int rating;
  final String position;
  final List<PlayStyle> playstyles;
  final String marketValue;
  final List<MatchStat> matches;
  final String team; // YENİ ALAN

  Player({
    required this.name,
    required this.rating,
    required this.position,
    required this.playstyles,
    this.marketValue = "N/A",
    this.matches = const [],
    this.team = "Takımsız", // Varsayılan
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
}

// --- TAKIM LİSTESİ (Resimden alındı) ---
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

// --- VARSAYILAN OYUNCULAR ---
final List<Player> defaultPlayers = [
  Player(
    name: "Ronaldo Иazário de Lima",
    rating: 94,
    position: "LW",
    marketValue: "120M €",
    team: "Takımsız", // İSTEK
    matches: [
      MatchStat("Barcelona", "3-1", 1, 2),
      MatchStat("Real Madrid", "2-2", 0, 2),
      MatchStat("Juventus", "2-0", 2, 0),
      MatchStat("Milan", "4-3", 1, 2),
      MatchStat("Inter", "2-1", 1, 1)
    ],
    playstyles: [
      PlayStyle("Trickster", isGold: true),
      PlayStyle("Technical"), PlayStyle("Rapid"), PlayStyle("QuickStep"),
      PlayStyle("FirstTouch"), PlayStyle("FinesseShot"),
      PlayStyle("PowerShot"), // DÜZELTİLDİ
      PlayStyle("Acrobatic"), PlayStyle("GameChanger"), PlayStyle("PingedPass"),
    ],
  ),
  Player(
    name: "Restes",
    rating: 83,
    position: "GK",
    marketValue: "45M €",
    team: "Toulouse", // İSTEK
    matches: [MatchStat("Lyon", "1-0", 0, 0), MatchStat("PSG", "0-3", 0, 0)],
    playstyles: [
      PlayStyle("FarReach", isGold: true),
      PlayStyle("RushOut"),
      PlayStyle("Jockey"),
      PlayStyle("LongBallPass")
    ],
  ),
  Player(
    name: "Sung",
    rating: 94,
    position: "ST",
    marketValue: "110M €",
    team: "Toulouse", // İSTEK
    matches: [
      MatchStat("Bayern", "1-1", 1, 0),
      MatchStat("Dortmund", "3-0", 2, 1)
    ],
    playstyles: [
      PlayStyle("GameChanger", isGold: true),
      PlayStyle("Technical"),
      PlayStyle("FirstTouch"),
      PlayStyle("TikiTaka"),
      PlayStyle("FinesseShot"),
      PlayStyle("PingedPass"),
      PlayStyle("IncisivePass"),
      PlayStyle("PressProven"),
      PlayStyle("AerialFortress")
    ],
  ),
  Player(
    name: "Sauron",
    rating: 89,
    position: "CB",
    marketValue: "85M €",
    team: "Fenerbahçe", // İSTEK
    playstyles: [
      PlayStyle("Jockey", isGold: true),
      PlayStyle("PingedPass"),
      PlayStyle("TikiTaka"),
      PlayStyle("Intercept"),
      PlayStyle("Anticipate"),
      PlayStyle("Bruiser")
    ],
  ),
  Player(
    name: "MADRICHAA",
    rating: 95,
    position: "RW",
    marketValue: "150M €",
    team: "Maximilian", // İSTEK
    playstyles: [
      PlayStyle("Rapid", isGold: true),
      PlayStyle("Technical"),
      PlayStyle("QuickStep"),
      PlayStyle("Trickster"),
      PlayStyle("FirstTouch"),
      PlayStyle("FinesseShot"),
      PlayStyle("PowerShot"),
      PlayStyle("Acrobatic"),
      PlayStyle("GameChanger"),
      PlayStyle("PingedPass"),
      PlayStyle("AerialFortress")
    ],
  ),
];

// Playstyle isimleri (DÜZELTİLDİ: PowerShot)
final List<String> availablePlayStyles = [
  "Acrobatic", "AerialFortress", "Anticipate", "Block", "Bruiser",
  "CrossClaimer", "FarReach", "FinesseShot", "FirstTouch", "Footwork",
  "GameChanger", "IncisivePass", "Intercept", "Inventive", "Jockey",
  "LongBallPass", "PingedPass", "PowerShot", "PressProven",
  "QuickStep", // PowerShot düzeltildi
  "Rapid", "RushOut", "SlideTackle", "Technical", "TikiTaka",
  "Trickster", "WhippedPass"
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
