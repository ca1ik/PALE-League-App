import 'package:flutter/material.dart';
import '../widgets/icon_card.dart';
import '../widgets/create_card_dialog.dart';
import '../data/card_types.dart';

/// Complete example showing how to use IconCard and card type system
class CardTypesExamplePage extends StatefulWidget {
  const CardTypesExamplePage({Key? key}) : super(key: key);

  @override
  State<CardTypesExamplePage> createState() => _CardTypesExamplePageState();
}

class _CardTypesExamplePageState extends State<CardTypesExamplePage> {
  List<CardType> userCards = [
    CardType.temel,
    CardType.totw,
    CardType.tots,
    CardType.mvp,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1F),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2A2A35), Color(0xFF1A1A1F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'KART TİPLERİ SİSTEMİ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade400,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${userCards.length} kart sahibisiniz',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),

          // Expanded content with user's cards
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: userCards.length + 1,
              itemBuilder: (context, index) {
                // Add button (last item)
                if (index == userCards.length) {
                  return GestureDetector(
                    onTap: _createNewCard,
                    child: IconCard(
                      icon: Icons.add_circle_outline,
                      title: 'YENİ',
                      subtitle: 'KART',
                      iconColor: Colors.amber.shade300,
                      size: double.infinity,
                      onTap: _createNewCard,
                    ),
                  );
                }

                final cardType = userCards[index];
                final cardInfo = CardTypeRegistry.getInfo(cardType);

                return GestureDetector(
                  onLongPress: () => _deleteCard(index),
                  child: Tooltip(
                    message: cardInfo.description,
                    child: IconCard(
                      icon: cardInfo.icon,
                      title: cardInfo.turkishName.split(' ')[0],
                      subtitle: cardInfo.name,
                      iconColor: cardInfo.color,
                      backgroundImagePath: cardInfo.backgroundImagePath,
                      size: double.infinity,
                      onTap: () => _viewCardDetails(cardInfo),
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons at bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _createNewCard,
                    icon: Icon(Icons.add, color: Colors.amber.shade300),
                    label: Text(
                      'YENİ KART EKLE',
                      style: TextStyle(color: Colors.amber.shade300),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.amber.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _viewAllCardTypes,
                    icon: const Icon(Icons.grid_view),
                    label: const Text('TÜM KARTLARI GÖR'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewCard() async {
    final selectedType = await showCreateCardDialog(context);
    if (selectedType != null && mounted) {
      setState(() {
        if (!userCards.contains(selectedType)) {
          userCards.add(selectedType);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${CardTypeRegistry.getInfo(selectedType).turkishName} kartı eklendi!',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteCard(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF25252D),
        title: const Text(
          'KARTI SİL',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '${CardTypeRegistry.getInfo(userCards[index]).turkishName} kartını silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () {
              setState(() => userCards.removeAt(index));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kart silindi'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('SİL'),
          ),
        ],
      ),
    );
  }

  void _viewCardDetails(CardTypeInfo cardInfo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF25252D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconCard(
                icon: cardInfo.icon,
                title: cardInfo.turkishName.split(' ')[0],
                subtitle: cardInfo.name,
                iconColor: cardInfo.color,
                size: 180,
              ),
              const SizedBox(height: 20),
              Text(
                cardInfo.name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: cardInfo.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cardInfo.turkishName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cardInfo.color.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  cardInfo.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('KAPAT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewAllCardTypes() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF25252D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TÜM KART TİPLERİ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade300,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: CardTypeRegistry.getAllTypes().length,
                  itemBuilder: (context, index) {
                    final cardInfo = CardTypeRegistry.getAllTypes()[index];
                    return IconCard(
                      icon: cardInfo.icon,
                      title: cardInfo.turkishName.split(' ')[0],
                      subtitle: cardInfo.name,
                      iconColor: cardInfo.color,
                      size: double.infinity,
                      onTap: () {
                        Navigator.pop(context);
                        _viewCardDetails(cardInfo);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber.shade600,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('KAPAT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
