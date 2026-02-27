import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../domain/entities/augmentation.dart';
import '../providers/habit_provider.dart';

class NeuralMarketplaceScreen extends StatelessWidget {
  const NeuralMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();

    // Mock inventory of available upgrades
    final List<Augmentation> shopItems = [
      Augmentation(
        id: '1',
        title: 'AMETHYST PROTOCOL',
        description: 'Deep purple terminal theme with neon accents.',
        xpCost: 500,
        category: AugmentCategory.theme,
      ),
      Augmentation(
        id: '2',
        title: 'THE ARCHITECT',
        description: 'New AI Persona: Highly technical and precision-oriented.',
        xpCost: 1200,
        category: AugmentCategory.persona,
      ),
      Augmentation(
        id: '3',
        title: 'PULSE MODULE',
        description:
            'Visualizes habit streaks as a living heartbeat on the Hub.',
        xpCost: 2000,
        category: AugmentCategory.module,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "NEURAL MARKETPLACE",
          style: TextStyle(letterSpacing: 4, fontSize: 12),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                "${provider.totalXP} XP",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1, // Single column for detailed shop items
          mainAxisExtent: 120,
          mainAxisSpacing: 15,
        ),
        itemCount: shopItems.length,
        itemBuilder: (context, index) {
          final item = shopItems[index];
          final canAfford = provider.totalXP >= item.xpCost;

          return FadeInRight(
            delay: Duration(milliseconds: index * 100),
            child: _buildShopTile(item, canAfford),
          );
        },
      ),
    );
  }

  Widget _buildShopTile(Augmentation item, bool canAfford) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: canAfford
              ? Colors.cyanAccent.withOpacity(0.2)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          _getCategoryIcon(item.category),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${item.xpCost} XP",
                style: TextStyle(
                  color: canAfford ? Colors.cyanAccent : Colors.redAccent,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 5),
              Icon(
                canAfford ? Icons.add_shopping_cart : Icons.lock_outline,
                size: 18,
                color: canAfford ? Colors.cyanAccent : Colors.white10,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(AugmentCategory category) {
    IconData icon;
    switch (category) {
      case AugmentCategory.theme:
        icon = Icons.palette_outlined;
        break;
      case AugmentCategory.persona:
        icon = Icons.psychology_outlined;
        break;
      case AugmentCategory.module:
        icon = Icons.extension_outlined;
        break;
    }
    return Icon(icon, color: Colors.cyanAccent, size: 24);
  }
}
