import 'package:flutter/material.dart';

/// Card type definitions with icons, colors, and metadata
enum CardType {
  spade,
  heart,
  diamond,
  club,
  magic,
  treasure,
  wild,
  special,
  icon,
  ramadan,
  futureStars,
  fantasy,
  winter,
  heroes,
}

/// Card metadata and styling
class CardTypeInfo {
  final CardType type;
  final String name;
  final String turkishName;
  final IconData icon;
  final Color color;
  final String description;
  final String? backgroundImagePath;

  CardTypeInfo({
    required this.type,
    required this.name,
    required this.turkishName,
    required this.icon,
    required this.color,
    required this.description,
    this.backgroundImagePath,
  });
}

/// Card type registry with all available card types
class CardTypeRegistry {
  static final Map<CardType, CardTypeInfo> _registry = {
    CardType.spade: CardTypeInfo(
      type: CardType.spade,
      name: 'SPADE',
      turkishName: 'Örümcek',
      icon: Icons.diamond_outlined,
      color: Colors.deepPurpleAccent,
      description: 'Standart spade kartı - Stratejik oyunlar için ideal',
    ),
    CardType.heart: CardTypeInfo(
      type: CardType.heart,
      name: 'HEART',
      turkishName: 'Kalp',
      icon: Icons.favorite_outline,
      color: Colors.redAccent,
      description: 'Kalp kartı - Duygu temelli etkileşimler',
    ),
    CardType.diamond: CardTypeInfo(
      type: CardType.diamond,
      name: 'DIAMOND',
      turkishName: 'Karo',
      icon: Icons.diamond,
      color: Colors.blueAccent,
      description: 'Karo kartı - Hazine ve değerli şeyler için',
    ),
    CardType.club: CardTypeInfo(
      type: CardType.club,
      name: 'CLUB',
      turkishName: 'Sinek',
      icon: Icons.favorite,
      color: Colors.greenAccent,
      description: 'Sinek kartı - Hızlı oyunlar için',
    ),
    CardType.magic: CardTypeInfo(
      type: CardType.magic,
      name: 'MAGIC',
      turkishName: 'Büyü',
      icon: Icons.auto_awesome,
      color: Colors.cyanAccent,
      description: 'Büyü kartı - Özel güçler ve efektler',
    ),
    CardType.treasure: CardTypeInfo(
      type: CardType.treasure,
      name: 'TREASURE',
      turkishName: 'Hazine',
      icon: Icons.diamond,
      color: Colors.orangeAccent,
      description: 'Hazine kartı - Nadir ve değerli kartlar',
    ),
    CardType.wild: CardTypeInfo(
      type: CardType.wild,
      name: 'WILD',
      turkishName: 'Joker',
      icon: Icons.star,
      color: Colors.yellowAccent,
      description: 'Joker kartı - Herhangi bir kart yerine geçebilir',
    ),
    CardType.special: CardTypeInfo(
      type: CardType.special,
      name: 'SPECIAL',
      turkishName: 'Özel',
      icon: Icons.shield,
      color: Colors.lightBlueAccent,
      description: 'Özel kartı - Sinırlı ve güçlü efektler',
    ),
    CardType.icon: CardTypeInfo(
      type: CardType.icon,
      name: 'ICON',
      turkishName: 'İkon',
      icon: Icons.image,
      color: Colors.amber.shade700,
      description: 'ICON kartı - Özel arka plan görseli ile',
      backgroundImagePath: 'assets/cards/icon.png',
    ),
    CardType.ramadan: CardTypeInfo(
      type: CardType.ramadan,
      name: 'RAMADAN',
      turkishName: 'Ramazan',
      icon: Icons.nightlight_round,
      color: const Color(0xFF8B00FF),
      description:
          'Ramazan özel kartı - Ay-yıldız motifleri ve mistik efektler',
    ),
    CardType.futureStars: CardTypeInfo(
      type: CardType.futureStars,
      name: 'FUTURE STARS',
      turkishName: 'Gelecek Yıldızları',
      icon: Icons.auto_awesome,
      color: const Color(0xFF00FFFF),
      description: 'Gelecek Yıldızları - Neon hologram ve dijital efektler',
    ),
    CardType.fantasy: CardTypeInfo(
      type: CardType.fantasy,
      name: 'FANTASY',
      turkishName: 'Fantezi',
      icon: Icons.auto_fix_high,
      color: const Color(0xFFFF00FF),
      description: 'Fantasy kartı - Mistik aura ve sihirli partiküller',
    ),
    CardType.winter: CardTypeInfo(
      type: CardType.winter,
      name: 'WINTER',
      turkishName: 'Kış',
      icon: Icons.ac_unit,
      color: const Color(0xFF00FF7F),
      description: 'Winter kartı - Buzul kristalleri ve kar taneleri',
    ),
    CardType.heroes: CardTypeInfo(
      type: CardType.heroes,
      name: 'HEROES',
      turkishName: 'Kahramanlar',
      icon: Icons.local_fire_department,
      color: const Color(0xFFFF0000),
      description: 'Heroes kartı - Ateş patlaması ve alev efektleri',
    ),
  };

  /// Get card info by type
  static CardTypeInfo getInfo(CardType type) {
    return _registry[type] ?? _registry[CardType.special]!;
  }

  /// Get all card types
  static List<CardTypeInfo> getAllTypes() {
    return _registry.values.toList();
  }

  /// Get card type by name
  static CardTypeInfo? getByName(String name) {
    try {
      final type = CardType.values
          .firstWhere((e) => e.name.toUpperCase() == name.toUpperCase());
      return _registry[type];
    } catch (_) {
      return null;
    }
  }

  /// Add custom card type
  static void registerCustomType(CardTypeInfo info) {
    _registry[info.type] = info;
  }
}
