enum AugmentCategory { theme, persona, module }

class Augmentation {
  final String id;
  final String title;
  final String description;
  final int xpCost;
  final AugmentCategory category;
  final bool isLocked;

  Augmentation({
    required this.id,
    required this.title,
    required this.description,
    required this.xpCost,
    required this.category,
    this.isLocked = true,
  });
}
