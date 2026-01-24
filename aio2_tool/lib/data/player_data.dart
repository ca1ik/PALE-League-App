import 'package:hive/hive.dart';

// --- HIVE ADAPTERLERİ (Veritabanı Kaydı İçin) ---
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
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer.write(obj.name);
    writer.write(obj.rating);
    writer.write(obj.position);
    writer.write(obj.playstyles);
  }
}

class PlayStyleAdapter extends TypeAdapter<PlayStyle> {
  @override
  final int typeId = 2;

  @override
  PlayStyle read(BinaryReader reader) {
    return PlayStyle(
      reader.read(),
      isGold: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, PlayStyle obj) {
    writer.write(obj.name);
    writer.write(obj.isGold);
  }
}

// --- VERİ MODELLERİ ---
class PlayStyle {
  final String
      name; // Örn: "Rapid" (Dosya adı Rapid.png veya RapidPlus.png olmalı)
  final bool isGold;

  PlayStyle(this.name, {this.isGold = false});

  // Resim yolunu dinamik olarak belirle
  String get assetPath {
    // Eğer Gold ise sonuna 'Plus' ekle
    final fileName = isGold ? "${name}Plus" : name;
    return "assets/Playstyles/$fileName.png";
  }
}

class Player {
  final String name;
  final int rating;
  final String position;
  final List<PlayStyle> playstyles;

  Player({
    required this.name,
    required this.rating,
    required this.position,
    required this.playstyles,
  });

  // Mevkiye göre forma numarası
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
        return 99; // Bilinmeyen mevki
    }
  }
}

// --- VARSAYILAN OYUNCULAR (Veritabanı boşsa bunlar yüklenecek) ---
final List<Player> defaultPlayers = [
  Player(
    name: "Ronaldo Иazário de Lima",
    rating: 94,
    position: "LW",
    playstyles: [
      PlayStyle("Trickster", isGold: true),
      PlayStyle("Technical"), PlayStyle("Rapid"),
      PlayStyle("QuickStep"), // Dosya adlarına dikkat (Boşluksuz)
      PlayStyle("FirstTouch"), PlayStyle("FinesseShot"), PlayStyle("PowerShot"),
      PlayStyle("Acrobatic"), PlayStyle("GameChanger"), PlayStyle("PingedPass"),
    ],
  ),
  Player(
    name: "Restes",
    rating: 83,
    position: "GK",
    playstyles: [
      PlayStyle("FarReach", isGold: true),
      PlayStyle("RushOut"),
      PlayStyle("Jockey"),
      PlayStyle("LongBallPass"),
    ],
  ),
  Player(
    name: "Sung",
    rating: 94,
    position: "ST",
    playstyles: [
      PlayStyle("GameChanger", isGold: true),
      PlayStyle("Technical"),
      PlayStyle("FirstTouch"),
      PlayStyle("TikiTaka"),
      PlayStyle("FinesseShot"),
      PlayStyle("PingedPass"),
      PlayStyle("IncisivePass"),
      PlayStyle("PressProven"),
      PlayStyle("AerialFortress"),
    ],
  ),
  Player(
    name: "Sauron",
    rating: 89,
    position: "CB",
    playstyles: [
      PlayStyle("Jockey", isGold: true),
      PlayStyle("PingedPass"),
      PlayStyle("TikiTaka"),
      PlayStyle("Intercept"),
      PlayStyle("Anticipate"),
      PlayStyle("Bruiser"),
    ],
  ),
  Player(
    name: "MADRICHAA",
    rating: 95,
    position: "RW",
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
      PlayStyle("AerialFortress"),
    ],
  ),
];

// --- SEÇİLEBİLİR PLAYSTYLE LİSTESİ (Dosya adlarıyla birebir aynı olmalı) ---
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
