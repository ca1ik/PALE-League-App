class PlayStyle {
  final String name;
  final bool isGold; // Sarı mı (En özel yetenek)
  // İkon adı (assets/playstyles/ klasöründe bu isimle resim aranacak)
  String get iconAsset =>
      "assets/playstyles/${name.toLowerCase().replaceAll(' ', '_')}.png";

  PlayStyle(this.name, {this.isGold = false});
}

class Player {
  final String name;
  final int rating;
  final String position;
  final String imageUrl; // Profil resmi (URL veya Asset)
  final List<PlayStyle> playstyles;

  Player({
    required this.name,
    required this.rating,
    required this.position,
    required this.imageUrl,
    required this.playstyles,
  });
}

// --- OYUNCU LİSTESİ ---
final List<Player> paleHaxPlayers = [
  Player(
    name: "Ronaldo Иazário de Lima",
    rating: 94,
    position: "LW",
    imageUrl:
        "https://futbin.com/content/fifa24/img/players/238395.png?v=22", // Örnek URL
    playstyles: [
      PlayStyle("Trickster", isGold: true), // SARI
      PlayStyle("Technical"),
      PlayStyle("Rapid"),
      PlayStyle("Quick Step"),
      PlayStyle("First Touch"),
      PlayStyle("Finesse Shot"),
      PlayStyle("Power Shoot"), // Not: FC24'te Power Shot
      PlayStyle("Acrobatic"),
      PlayStyle("Game Changer"), // Özel isim
      PlayStyle("Pinged Pass"),
    ],
  ),
  Player(
    name: "Restes",
    rating: 83,
    position: "GK",
    imageUrl: "https://futbin.com/content/fifa24/img/players/274567.png?v=22",
    playstyles: [
      PlayStyle("Far Reach", isGold: true), // SARI
      PlayStyle("Rush Out"),
      PlayStyle("Jockey"), // Kalecide Jockey olmaz ama isteğin üzerine ekledim
      PlayStyle("Long Ball Pass"),
    ],
  ),
  Player(
    name: "Sung",
    rating: 94,
    position: "ST",
    imageUrl: "https://futbin.com/content/fifa24/img/players/200104.png?v=22",
    playstyles: [
      PlayStyle("Game Changer", isGold: true), // SARI
      PlayStyle("Technical"),
      PlayStyle("First Touch"),
      PlayStyle("Tiki Taka"),
      PlayStyle("Finesse Shot"),
      PlayStyle("Pinged Pass"),
      PlayStyle("Incisive Pass"),
      PlayStyle("Press Proven"),
      PlayStyle("Aerial Fortress"),
    ],
  ),
  Player(
    name: "Sauron",
    rating: 89,
    position: "CB",
    imageUrl: "https://futbin.com/content/fifa24/img/players/203376.png?v=22",
    playstyles: [
      PlayStyle("Jockey", isGold: true), // SARI
      PlayStyle("Pinged Pass"),
      PlayStyle("Tiki Taka"),
      PlayStyle("Intercept"),
      PlayStyle("Anticipate"),
      PlayStyle("Bruiser"),
    ],
  ),
  Player(
    name: "MADRICHAA",
    rating: 95,
    position: "RW",
    imageUrl: "https://futbin.com/content/fifa24/img/players/239085.png?v=22",
    playstyles: [
      PlayStyle("Rapid", isGold: true), // SARI
      PlayStyle("Technical"),
      PlayStyle("Quick Step"),
      PlayStyle("Trickster"),
      PlayStyle("First Touch"),
      PlayStyle("Finesse Shot"),
      PlayStyle("Power Shoot"),
      PlayStyle("Acrobatic"),
      PlayStyle("Game Changer"),
      PlayStyle("Pinged Pass"),
      PlayStyle("Aerial Fortress"),
    ],
  ),
];
