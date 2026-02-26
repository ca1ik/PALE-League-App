import 'package:flutter/material.dart';

/// Card type definitions with icons, colors, and metadata
enum CardType {
  temel,
  totw,
  totm,
  tots,
  mvp,
  star,
  ballondor,
  bad,
  icon,
  ramadan,
  futureStars,
  winter,
  thunderstruck,
  pclPro,
  evolution,
  evolutionPlus,
  endOfAnEra,
  staff,
  pclChampion,
  pelChampion,
  peclChampion,
  funCupChampion,
  classicVII,
  defender,
  midfielder,
  striker,
  eloChampion,
  trickster,
  fmPro,
  iq,
  king,
  totsIcon,
  trailbrazers,
  ultimate,
  vsChampion,
  dreamchasers,
  awardWinners,
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
    CardType.temel: CardTypeInfo(
      type: CardType.temel,
      name: 'TEMEL',
      turkishName: 'Temel',
      icon: Icons.circle_outlined,
      color: Colors.white70,
      description: 'Standart oyuncu kartı.',
      backgroundImagePath: 'assets/cards/s/Temel.png',
    ),
    CardType.totw: CardTypeInfo(
      type: CardType.totw,
      name: 'TOTW',
      turkishName: 'Haftanın Takımı',
      icon: Icons.calendar_today,
      color: Colors.amber,
      description: 'Haftanın Takımı kartı.',
      backgroundImagePath: 'assets/cards/s/TOTW.png',
    ),
    CardType.totm: CardTypeInfo(
      type: CardType.totm,
      name: 'TOTM',
      turkishName: 'Ayın Takımı',
      icon: Icons.date_range,
      color: const Color(0xFFE91E63),
      description: 'Ayın Takımı kartı.',
      backgroundImagePath: 'assets/cards/s/TOTM.png',
    ),
    CardType.tots: CardTypeInfo(
      type: CardType.tots,
      name: 'TOTS',
      turkishName: 'Sezonun Takımı',
      icon: Icons.star,
      color: Colors.cyanAccent,
      description: 'Sezonun Takımı kartı.',
      backgroundImagePath: 'assets/cards/s/TOTS.png',
    ),
    CardType.mvp: CardTypeInfo(
      type: CardType.mvp,
      name: 'MVP',
      turkishName: 'En Değerli Oyuncu',
      icon: Icons.emoji_events,
      color: Colors.redAccent,
      description: 'En Değerli Oyuncu kartı.',
      backgroundImagePath: 'assets/cards/s/MVP.png',
    ),
    CardType.star: CardTypeInfo(
      type: CardType.star,
      name: 'STAR',
      turkishName: 'Yıldız',
      icon: Icons.star_border,
      color: Colors.cyan,
      description: 'Yıldız Oyuncu kartı.',
      backgroundImagePath: 'assets/cards/s/STAR.png',
    ),
    CardType.ballondor: CardTypeInfo(
      type: CardType.ballondor,
      name: 'BALLONDOR',
      turkishName: "Ballon d'Or",
      icon: Icons.sports_soccer,
      color: Colors.amberAccent,
      description: "Ballon d'Or - Sezonun en iyi oyuncusu.",
      backgroundImagePath: 'assets/cards/s/Ballondor.png',
    ),
    CardType.bad: CardTypeInfo(
      type: CardType.bad,
      name: 'BAD',
      turkishName: 'Facia',
      icon: Icons.thumb_down,
      color: Colors.pinkAccent,
      description: 'Facia performans kartı.',
      backgroundImagePath: 'assets/cards/s/BAD.png',
    ),
    CardType.icon: CardTypeInfo(
      type: CardType.icon,
      name: 'ICON',
      turkishName: 'İkon',
      icon: Icons.image,
      color: Colors.amber.shade700,
      description: 'ICON kartı - Efsane oyuncu.',
      backgroundImagePath: 'assets/cards/icon.png',
    ),
    CardType.ramadan: CardTypeInfo(
      type: CardType.ramadan,
      name: 'RAMADAN',
      turkishName: 'Ramazan',
      icon: Icons.nightlight_round,
      color: const Color(0xFF8B00FF),
      description: 'Ramazan özel kartı.',
      backgroundImagePath: 'assets/cards/s/Ramadan.png',
    ),
    CardType.futureStars: CardTypeInfo(
      type: CardType.futureStars,
      name: 'FUTURE STARS',
      turkishName: 'Gelecek Yıldızları',
      icon: Icons.auto_awesome,
      color: const Color(0xFF00FFFF),
      description: 'Gelecek Yıldızları kartı.',
      backgroundImagePath: 'assets/cards/s/Future Stars.png',
    ),
    CardType.winter: CardTypeInfo(
      type: CardType.winter,
      name: 'WINTER',
      turkishName: 'Kış',
      icon: Icons.ac_unit,
      color: const Color(0xFF00FF7F),
      description: 'Winter kartı - Buzul kristalleri ve kar taneleri.',
      backgroundImagePath: 'assets/cards/s/Winter.png',
    ),
    CardType.thunderstruck: CardTypeInfo(
      type: CardType.thunderstruck,
      name: 'THUNDERSTRUCK',
      turkishName: 'Yıldırım',
      icon: Icons.flash_on,
      color: const Color(0xFFFFD700),
      description: 'Thunderstruck - Elektrik yıldırımları ve şok dalgaları.',
      backgroundImagePath: 'assets/cards/s/Thunderstuck.png',
    ),
    CardType.pclPro: CardTypeInfo(
      type: CardType.pclPro,
      name: 'PCL PRO',
      turkishName: 'PCL Pro',
      icon: Icons.workspace_premium,
      color: const Color(0xFF1E3A8A),
      description: 'PCL Pro - Profesyonel lig kartı.',
      backgroundImagePath: 'assets/cards/s/PCLPro.png',
    ),
    CardType.evolution: CardTypeInfo(
      type: CardType.evolution,
      name: 'EVOLUTION',
      turkishName: 'Evrim',
      icon: Icons.trending_up,
      color: const Color(0xFF10B981),
      description: 'Evolution - Gelişim ve dönüşüm kartı.',
      backgroundImagePath: 'assets/cards/s/Evolution.png',
    ),
    CardType.evolutionPlus: CardTypeInfo(
      type: CardType.evolutionPlus,
      name: 'EVOLUTION PLUS',
      turkishName: 'Evrim Plus',
      icon: Icons.auto_awesome_motion,
      color: const Color(0xFFA78BFA),
      description: 'Evolution Plus - Yükseltilmiş evrim kartı.',
      backgroundImagePath: 'assets/cards/s/EvolutionPlus.png',
    ),
    CardType.endOfAnEra: CardTypeInfo(
      type: CardType.endOfAnEra,
      name: 'END OF AN ERA',
      turkishName: 'Efsane Veda',
      icon: Icons.history,
      color: const Color(0xFF9CA3AF),
      description: 'End of an Era - Efsane oyuncuların veda kartı.',
      backgroundImagePath: 'assets/cards/s/EndofanEra.png',
    ),
    CardType.staff: CardTypeInfo(
      type: CardType.staff,
      name: 'STAFF',
      turkishName: 'Personel',
      icon: Icons.badge,
      color: const Color(0xFF1E40AF),
      description: 'Staff - Özel personel kartı.',
      backgroundImagePath: 'assets/cards/s/Staff.png',
    ),
    CardType.pclChampion: CardTypeInfo(
      type: CardType.pclChampion,
      name: 'PCL CHAMPION',
      turkishName: 'PCL Şampiyonu',
      icon: Icons.military_tech,
      color: const Color(0xFFDC2626),
      description: 'PCL Champion - PCL şampiyonluk kartı.',
      backgroundImagePath: 'assets/cards/s/PCLChamp.png',
    ),
    CardType.pelChampion: CardTypeInfo(
      type: CardType.pelChampion,
      name: 'PEL CHAMPION',
      turkishName: 'PEL Şampiyonu',
      icon: Icons.stars,
      color: const Color(0xFF3B82F6),
      description: 'PEL Champion - PEL şampiyonluk kartı.',
      backgroundImagePath: 'assets/cards/s/PELChamp.png',
    ),
    CardType.peclChampion: CardTypeInfo(
      type: CardType.peclChampion,
      name: 'PECL CHAMPION',
      turkishName: 'PECL Şampiyonu',
      icon: Icons.workspace_premium,
      color: const Color(0xFFF97316),
      description: 'PECL Champion - PECL şampiyonluk kartı.',
      backgroundImagePath: 'assets/cards/s/PECLChamp.png',
    ),
    CardType.funCupChampion: CardTypeInfo(
      type: CardType.funCupChampion,
      name: 'FUNCUP CHAMPION',
      turkishName: 'FunCup Şampiyonu',
      icon: Icons.celebration,
      color: const Color(0xFFEC4899),
      description: 'FunCup Champion - Eğlence kupası şampiyonu.',
      backgroundImagePath: 'assets/cards/s/FuncupChampion.png',
    ),
    CardType.classicVII: CardTypeInfo(
      type: CardType.classicVII,
      name: 'CLASSIC VII',
      turkishName: 'Klasik VII',
      icon: Icons.auto_stories,
      color: const Color(0xFF92400E),
      description: 'Classic VII - Vintage klasik kart.',
      backgroundImagePath: 'assets/cards/s/ClassicVII.png',
    ),
    CardType.defender: CardTypeInfo(
      type: CardType.defender,
      name: 'DEFENDER',
      turkishName: 'Defansçı',
      icon: Icons.shield,
      color: const Color(0xFF60A5FA),
      description: 'Defans odaklı özel kart.',
      backgroundImagePath: 'assets/cards/s/DEFENDER.png',
    ),
    CardType.midfielder: CardTypeInfo(
      type: CardType.midfielder,
      name: 'MIDFIELDER',
      turkishName: 'Orta Saha',
      icon: Icons.sports_soccer,
      color: const Color(0xFF34D399),
      description: 'Orta saha odaklı özel kart.',
      backgroundImagePath: 'assets/cards/s/MIDFIELDER.png',
    ),
    CardType.striker: CardTypeInfo(
      type: CardType.striker,
      name: 'STRIKER',
      turkishName: 'Forvet',
      icon: Icons.sports_soccer,
      color: const Color(0xFFF87171),
      description: 'Forvet odaklı özel kart.',
      backgroundImagePath: 'assets/cards/s/STRIKER.png',
    ),
    CardType.eloChampion: CardTypeInfo(
      type: CardType.eloChampion,
      name: 'ELO CHAMPION',
      turkishName: 'ELO Şampiyonu',
      icon: Icons.military_tech,
      color: const Color(0xFF93C5FD),
      description: 'ELO şampiyonu kartı.',
      backgroundImagePath: 'assets/cards/s/ELOChamp.png',
    ),
    CardType.trickster: CardTypeInfo(
      type: CardType.trickster,
      name: 'TRICKSTER',
      turkishName: 'Hilebaz',
      icon: Icons.auto_fix_high,
      color: const Color(0xFFD946EF),
      description: 'Trickster - Hile ve yetenek kartı.',
      backgroundImagePath: 'assets/cards/s/trickster.png',
    ),
    CardType.fmPro: CardTypeInfo(
      type: CardType.fmPro,
      name: 'FM PRO',
      turkishName: 'FM Pro',
      icon: Icons.sports_soccer,
      color: const Color(0xFF047857),
      description: 'FM Pro - Football Manager profesyonel kartı.',
      backgroundImagePath: 'assets/cards/s/FMPro.png',
    ),
    CardType.iq: CardTypeInfo(
      type: CardType.iq,
      name: 'IQ',
      turkishName: 'IQ',
      icon: Icons.psychology,
      color: const Color(0xFF22D3EE),
      description: 'IQ - Oyun zekası odaklı özel kart.',
      backgroundImagePath: 'assets/cards/s/IQ.png',
    ),
    CardType.king: CardTypeInfo(
      type: CardType.king,
      name: 'KING',
      turkishName: 'Kral',
      icon: Icons.workspace_premium,
      color: const Color(0xFFFFD700),
      description: 'KING - Seçkin seviye kral kartı.',
      backgroundImagePath: 'assets/cards/s/KING.png',
    ),
    CardType.totsIcon: CardTypeInfo(
      type: CardType.totsIcon,
      name: 'TOTS ICON',
      turkishName: 'TOTS İkon',
      icon: Icons.auto_awesome,
      color: const Color(0xFF38BDF8),
      description: 'TOTS Icon - Sezonun takımı ikonik sürüm.',
      backgroundImagePath: 'assets/cards/s/TOTSIcon.png',
    ),
    CardType.trailbrazers: CardTypeInfo(
      type: CardType.trailbrazers,
      name: 'TRAILBRAZERS',
      turkishName: 'Trailbrazers',
      icon: Icons.local_fire_department,
      color: const Color(0xFFFB923C),
      description: 'Trailbrazers - Yol açan özel seri kart.',
      backgroundImagePath: 'assets/cards/s/Trailbrazers.png',
    ),
    CardType.ultimate: CardTypeInfo(
      type: CardType.ultimate,
      name: 'ULTIMATE',
      turkishName: 'Ultimate',
      icon: Icons.diamond,
      color: const Color(0xFFC4B5FD),
      description: 'Ultimate - Ultra premium kart tipi.',
      backgroundImagePath: 'assets/cards/s/Ultimate.png',
    ),
    CardType.vsChampion: CardTypeInfo(
      type: CardType.vsChampion,
      name: 'VS CHAMPION',
      turkishName: 'VS Şampiyon',
      icon: Icons.verified,
      color: const Color(0xFF86EFAC),
      description: 'VS Champion - VS mod şampiyon kartı.',
      backgroundImagePath: 'assets/cards/s/VS Champion.png',
    ),
    CardType.dreamchasers: CardTypeInfo(
      type: CardType.dreamchasers,
      name: 'DREAMCHASERS',
      turkishName: 'Rüya Avcıları',
      icon: Icons.nights_stay,
      color: const Color(0xFF6366F1),
      description: 'Dreamchasers - Rüya avcıları galaksi kartı.',
      backgroundImagePath: 'assets/cards/s/Dreamchasers.png',
    ),
    CardType.awardWinners: CardTypeInfo(
      type: CardType.awardWinners,
      name: 'AWARD WINNERS',
      turkishName: 'Ödül Kazananlar',
      icon: Icons.emoji_events,
      color: const Color(0xFFFBBF24),
      description: 'Award Winners - Ödül kazananlar kartı.',
      backgroundImagePath: 'assets/cards/s/AwardWinner.png',
    ),
    CardType.birthday: CardTypeInfo(
      type: CardType.birthday,
      name: 'BIRTHDAY',
      turkishName: 'Doğum Günü',
      icon: Icons.cake,
      color: const Color(0xFFFBBF24),
      description: 'Birthday - Doğum günü özel kartı.',
      backgroundImagePath: 'assets/cards/s/Birthday.png',
    ),
  };

  /// Get card info by type
  static CardTypeInfo getInfo(CardType type) {
    return _registry[type] ?? _registry[CardType.temel]!;
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
