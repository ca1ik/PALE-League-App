import 'package:flutter/material.dart';
import '../widgets/icon_card.dart';

/// Demo page for Icon Cards
/// Shows various card types with icons and animations
class IconCardShowcase extends StatefulWidget {
  const IconCardShowcase({Key? key}) : super(key: key);

  @override
  State<IconCardShowcase> createState() => _IconCardShowcaseState();
}

class _IconCardShowcaseState extends State<IconCardShowcase> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A1F),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A2A35), Color(0xFF1A1A1F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                'ICON KARTLAR',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade400,
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                // Spade Card
                IconCard(
                  icon: Icons.diamond_outlined,
                  title: 'SPADE',
                  subtitle: 'Örümcek',
                  iconColor: Colors.deepPurpleAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'SPADE - Örümcek'),
                ),

                // Heart Card
                IconCard(
                  icon: Icons.favorite_outline,
                  title: 'HEART',
                  subtitle: 'Kalp',
                  iconColor: Colors.redAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'HEART - Kalp'),
                ),

                // Diamond Card
                IconCard(
                  icon: Icons.diamond,
                  title: 'DIAMOND',
                  subtitle: 'Karo',
                  iconColor: Colors.blueAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'DIAMOND - Karo'),
                ),

                // Club Card
                IconCard(
                  icon: Icons.favorite,
                  title: 'CLUB',
                  subtitle: 'Sinek',
                  iconColor: Colors.greenAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'CLUB - Sinek'),
                ),

                // Magic Card
                IconCard(
                  icon: Icons.auto_awesome,
                  title: 'MAGIC',
                  subtitle: 'Büyü',
                  iconColor: Colors.cyanAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'MAGIC - Büyü'),
                ),

                // Treasure Card
                IconCard(
                  icon: Icons.diamond,
                  title: 'TREASURE',
                  subtitle: 'Hazine',
                  iconColor: Colors.orangeAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'TREASURE - Hazine'),
                ),

                // Wild Card
                IconCard(
                  icon: Icons.star,
                  title: 'WILD',
                  subtitle: 'Joker',
                  iconColor: Colors.yellowAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'WILD - Joker'),
                ),

                // Special Card
                IconCard(
                  icon: Icons.shield,
                  title: 'SPECIAL',
                  subtitle: 'Özel',
                  iconColor: Colors.lightBlueAccent,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'SPECIAL - Özel'),
                ),

                // New Card Plus
                IconCard(
                  icon: Icons.add_circle_outline,
                  title: 'YENİ KART',
                  subtitle: 'Oluştur',
                  iconColor: Colors.amber.shade300,
                  size: 130,
                  onTap: () => _showCardInfo(context, 'YENİ KART OLUŞTUR'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCardInfo(BuildContext context, String cardName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$cardName seçildi!'),
        backgroundColor: Colors.amber.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
