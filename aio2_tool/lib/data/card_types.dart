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
  thunderstruck,
  pclPro,
  evolution,
  toty,
  endOfAnEra,
  staff,
  pclChampion,
  pelChampion,
  peclChampion,
  funCupChampion,
  draftChampion,
  classicVII,
  trickster,
  fmPro,
  dreamchasers,
  awardWinners,
  teamTurkey,
  birthday,
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
    CardType.thunderstruck: CardTypeInfo(
      type: CardType.thunderstruck,
      name: 'THUNDERSTRUCK',
      turkishName: 'Yıldırım',
      icon: Icons.flash_on,
      color: const Color(0xFFFFD700),
      description: 'Thunderstruck - Elektrik yıldırımları ve şok dalgaları',
    ),
    CardType.pclPro: CardTypeInfo(
      type: CardType.pclPro,
      name: 'PCL PRO',
      turkishName: 'PCL Pro',
      icon: Icons.workspace_premium,
      color: const Color(0xFF1E3A8A),
      description: 'PCL Pro - Profesyonel lig kartı',
    ),
    CardType.evolution: CardTypeInfo(
      type: CardType.evolution,
      name: 'EVOLUTION',
      turkishName: 'Evrim',
      icon: Icons.trending_up,
      color: const Color(0xFF10B981),
      description: 'Evolution - Gelişim ve dönüşüm kartı',
    ),
    CardType.toty: CardTypeInfo(
      type: CardType.toty,
      name: 'TOTY',
      turkishName: 'Yılın Takımı',
      icon: Icons.emoji_events,
      color: const Color(0xFFFFD700),
      description: 'TOTY - Yılın Takımı premium kartı',
    ),
    CardType.endOfAnEra: CardTypeInfo(
      type: CardType.endOfAnEra,
      name: 'END OF AN ERA',
      turkishName: 'Efsane Veda',
      icon: Icons.history,
      color: const Color(0xFF9CA3AF),
      description: 'End of an Era - Efsane oyuncuların veda kartı',
    ),
    CardType.staff: CardTypeInfo(
      type: CardType.staff,
      name: 'STAFF',
      turkishName: 'Personel',
      icon: Icons.badge,
      color: const Color(0xFF1E40AF),
      description: 'Staff - Özel personel kartı',
    ),
    CardType.pclChampion: CardTypeInfo(
      type: CardType.pclChampion,
      name: 'PCL CHAMPION',
      turkishName: 'PCL Şampiyonu',
      icon: Icons.military_tech,
      color: const Color(0xFFDC2626),
      description: 'PCL Champion - PCL şampiyonluk kartı',
    ),
    CardType.pelChampion: CardTypeInfo(
      type: CardType.pelChampion,
      name: 'PEL CHAMPION',
      turkishName: 'PEL Şampiyonu',
      icon: Icons.stars,
      color: const Color(0xFF3B82F6),
      description: 'PEL Champion - PEL şampiyonluk kartı',
    ),
    CardType.peclChampion: CardTypeInfo(
      type: CardType.peclChampion,
      name: 'PECL CHAMPION',
      turkishName: 'PECL Şampiyonu',
      icon: Icons.workspace_premium,
      color: const Color(0xFFF97316),
      description: 'PECL Champion - PECL şampiyonluk kartı',
    ),
    CardType.funCupChampion: CardTypeInfo(
      type: CardType.funCupChampion,
      name: 'FUNCUP CHAMPION',
      turkishName: 'FunCup Şampiyonu',
      icon: Icons.celebration,
      color: const Color(0xFFEC4899),
      description: 'FunCup Champion - Eğlence kupası şampiyonu',
    ),
    CardType.draftChampion: CardTypeInfo(
      type: CardType.draftChampion,
      name: 'DRAFT CHAMPION',
      turkishName: 'Draft Şampiyonu',
      icon: Icons.psychology,
      color: const Color(0xFF059669),
      description: 'Draft Champion - Draft şampiyonluk kartı',
    ),
    CardType.classicVII: CardTypeInfo(
      type: CardType.classicVII,
      name: 'CLASSIC VII',
      turkishName: 'Klasik VII',
      icon: Icons.auto_stories,
      color: const Color(0xFF92400E),
      description: 'Classic VII - Vintage klasik kart',
    ),
    CardType.trickster: CardTypeInfo(
      type: CardType.trickster,
      name: 'TRICKSTER',
      turkishName: 'Hilebaz',
      icon: Icons.auto_fix_high,
      color: const Color(0xFFD946EF),
      description: 'Trickster - Hile ve yetenek kartı',
    ),
    CardType.fmPro: CardTypeInfo(
      type: CardType.fmPro,
      name: 'FM PRO',
      turkishName: 'FM Pro',
      icon: Icons.sports_soccer,
      color: const Color(0xFF047857),
      description: 'FM Pro - Football Manager profesyonel kartı',
    ),
    CardType.dreamchasers: CardTypeInfo(
      type: CardType.dreamchasers,
      name: 'DREAMCHASERS',
      turkishName: 'Rüya Avcıları',
      icon: Icons.nights_stay,
      color: const Color(0xFF6366F1),
      description: 'Dreamchasers - Rüya avcıları galaksi kartı',
    ),
    CardType.awardWinners: CardTypeInfo(
      type: CardType.awardWinners,
      name: 'AWARD WINNERS',
      turkishName: 'Ödül Kazananlar',
      icon: Icons.emoji_events,
      color: const Color(0xFFFBBF24),
      description: 'Award Winners - Ödül kazananlar kartı',
    ),
    CardType.teamTurkey: CardTypeInfo(
      type: CardType.teamTurkey,
      name: 'TEAM TURKEY',
      turkishName: 'Türkiye Milli',
      icon: Icons.flag,
      color: const Color(0xFFDC2626),
      description: 'Team Turkey - Türkiye Milli Takım kartı',
    ),
    CardType.birthday: CardTypeInfo(
      type: CardType.birthday,
      name: 'BIRTHDAY',
      turkishName: 'Doğum Günü',
      icon: Icons.cake,
      color: const Color(0xFFFBBF24),
      description: 'Birthday - Doğum günü özel kartı',
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
