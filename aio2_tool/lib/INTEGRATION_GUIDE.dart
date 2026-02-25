/// Quick Integration Guide for Icon Card System
/// 
/// This file shows how to quickly integrate IconCard into your existing app.
/// 
/// OPTION 1: Show Create Card Dialog
/// ====================================
/// 
/// void openCardCreator() async {
///   final selectedType = await showCreateCardDialog(context);
///   if (selectedType != null) {
///     // Handle selected card type
///     print('User created: ${selectedType.name}');
///   }
/// }
/// 
/// 
/// OPTION 2: Add to Existing Page
/// ====================================
/// 
/// import 'widgets/icon_card.dart';
/// import 'data/card_types.dart';
/// 
/// class MyPage extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return ListView(
///       children: [
///         IconCard(
///           icon: Icons.diamond,
///           title: 'KARO',
///           subtitle: 'Diamond',
///           iconColor: Colors.blueAccent,
///           onTap: () => print('Card tapped!'),
///         ),
///       ],
///     );
///   }
/// }
/// 
/// 
/// OPTION 3: Grid Display
/// ====================================
/// 
/// import 'widgets/icon_card.dart';
/// import 'data/card_types.dart';
/// 
/// class CardGrid extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     final allCards = CardTypeRegistry.getAllTypes();
///     
///     return GridView.count(
///       crossAxisCount: 3,
///       children: allCards.map((cardInfo) {
///         return IconCard(
///           icon: cardInfo.icon,
///           title: cardInfo.turkishName,
///           subtitle: cardInfo.name,
///           iconColor: cardInfo.color,
///           onTap: () => _handleCardSelect(cardInfo),
///         );
///       }).toList(),
///     );
///   }
/// }
/// 
/// 
/// OPTION 4: Custom Card Types
/// ====================================
/// 
/// import 'data/card_types.dart';
/// 
/// void setupCustomCards() {
///   final mythic = CardTypeInfo(
///     type: CardType.special,
///     name: 'MYTHIC',
///     turkishName: 'Efsanevi',
///     icon: Icons.star,
///     color: Colors.purpleAccent,
///     description: 'Ultra rare card type',
///   );
///   
///   CardTypeRegistry.registerCustomType(mythic);
/// }
/// 
/// 
/// OPTION 5: Full Example (Recommended for first test)
/// ====================================
/// 
/// To see full example with all features:
/// -> Open: lib/screens/card_types_example.dart
/// -> In main.dart, change home to: CardTypesExample()
/// -> Run: flutter run -d windows
/// 
/// This shows:
/// - Grid display
/// - Create new card dialog
/// - Card details view
/// - Delete functionality
/// - View all types
