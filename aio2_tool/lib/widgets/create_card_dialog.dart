import 'package:flutter/material.dart';
import '../widgets/icon_card.dart';
import '../data/card_types.dart';

/// Dialog for creating new card with type selection
class CreateCardDialog extends StatefulWidget {
  final Function(CardType)? onCardTypeSelected;

  const CreateCardDialog({
    Key? key,
    this.onCardTypeSelected,
  }) : super(key: key);

  @override
  State<CreateCardDialog> createState() => _CreateCardDialogState();
}

class _CreateCardDialogState extends State<CreateCardDialog> {
  CardType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final allTypes = CardTypeRegistry.getAllTypes();

    return Dialog(
      backgroundColor: const Color(0xFF25252D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Colors.amber,
          width: 2,
        ),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'YENİ KART OLUŞTUR',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade300,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'Kart türünü seçin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 20),

            // Card types grid
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: allTypes.length,
                itemBuilder: (context, index) {
                  final cardInfo = allTypes[index];
                  final isSelected = _selectedType == cardInfo.type;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedType = cardInfo.type);
                    },
                    child: Stack(
                      children: [
                        _buildCardPreview(cardInfo),
                        if (isSelected)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.amber.shade500,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Selected card info
            if (_selectedType != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      CardTypeRegistry.getInfo(_selectedType!).name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CardTypeRegistry.getInfo(_selectedType!).color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CardTypeRegistry.getInfo(_selectedType!).description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'İPTAL',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedType != null
                        ? () {
                            widget.onCardTypeSelected?.call(_selectedType!);
                            Navigator.pop(context);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      disabledBackgroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OLUŞTUR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview(CardTypeInfo cardInfo) {
    // Tüm kart tipleri PNG arka plan kullanıyor
    // backgroundImagePath varsa PNG göster, yoksa varsayılan ikon kart
    if (cardInfo.backgroundImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          cardInfo.backgroundImagePath!,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => IconCard(
            icon: cardInfo.icon,
            title: cardInfo.turkishName.split(' ')[0],
            iconColor: cardInfo.color,
            size: double.infinity,
          ),
        ),
      );
    }
    return IconCard(
      icon: cardInfo.icon,
      title: cardInfo.turkishName.split(' ')[0],
      iconColor: cardInfo.color,
      size: double.infinity,
    );
  }
}

/// Helper function to show the create card dialog
Future<CardType?> showCreateCardDialog(BuildContext context) async {
  return showDialog<CardType?>(
    context: context,
    builder: (context) => CreateCardDialog(
      onCardTypeSelected: (type) {
        Navigator.pop(context, type);
      },
    ),
  );
}
