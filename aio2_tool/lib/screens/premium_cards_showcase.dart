import 'package:flutter/material.dart';
import '../widgets/icon_card.dart';
import '../widgets/premium_cards/ramadan_card.dart';
import '../widgets/premium_cards/future_stars_card.dart';
import '../widgets/premium_cards/fantasy_card.dart';
import '../widgets/premium_cards/winter_card.dart';
import '../widgets/premium_cards/heroes_card.dart';

/// Premium Cards Showcase
/// Displays all premium card types with their unique animations
class PremiumCardsShowcase extends StatelessWidget {
  const PremiumCardsShowcase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PREMIUM CARDS',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'ICON',
              'Altın kristal patlaması, premium parıltı efektleri',
              IconCard(
                icon: Icons.image,
                title: 'ICON',
                subtitle: 'Premium',
                size: 200,
                backgroundImagePath: 'assets/cards/icon.png',
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'RAMADAN',
              'Mor-altın gradient, ay-yıldız motifleri, mistik partiküller',
              const RamadanCard(
                icon: Icons.nightlight_round,
                title: 'RAMADAN',
                subtitle: 'Special',
                size: 200,
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'FUTURE STARS',
              'Cyan-mavi neon hologram, dijital grid, tarama efektleri',
              const FutureStarsCard(
                icon: Icons.auto_awesome,
                title: 'FUTURE',
                subtitle: 'Stars',
                size: 200,
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'FANTASY',
              'Magenta-mor mistik aura, sihirli partiküller, spiral efektler',
              const FantasyCard(
                icon: Icons.auto_fix_high,
                title: 'FANTASY',
                subtitle: 'Mystical',
                size: 200,
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'WINTER',
              'Yeşil-buz mavisi, buzul kristalleri, kar taneleri',
              const WinterCard(
                icon: Icons.ac_unit,
                title: 'WINTER',
                subtitle: 'Frozen',
                size: 200,
              ),
            ),
            const SizedBox(height: 40),
            _buildSection(
              'HEROES',
              'Kırmızı-turuncu ateş teması, alev patlaması, yoğun ısı efektleri',
              const HeroesCard(
                icon: Icons.local_fire_department,
                title: 'HEROES',
                subtitle: 'Legendary',
                size: 200,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Center(child: card),
      ],
    );
  }
}
