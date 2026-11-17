import 'package:flutter/material.dart';

enum ShopItemType {
  streakShield,
  xpOverdrive,
  corePurifier,
  mysteryDataPack,
  themeCosmetic,
}

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int costBits;
  final IconData icon;
  final Color accentColor;
  final ShopItemType type;
  final String? badgeText;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.costBits,
    required this.icon,
    required this.accentColor,
    required this.type,
    this.badgeText,
  });

  static const List<ShopItem> catalog = [
    ShopItem(
      id: 'item_streak_shield',
      name: 'STREAK SHIELD PROTOCOL',
      description: 'Protects your active streak from resetting if you miss a daily sync cycle.',
      costBits: 150,
      icon: Icons.shield_rounded,
      accentColor: Color(0xFF38BDF8), // Cyan
      type: ShopItemType.streakShield,
      badgeText: 'ESSENTIAL',
    ),
    ShopItem(
      id: 'item_xp_overdrive',
      name: '2X XP OVERDRIVE BOOST',
      description: 'Supercharges neural synchronization, granting 2x XP for the next 24 hours.',
      costBits: 220,
      icon: Icons.flash_on_rounded,
      accentColor: Color(0xFFF59E0B), // Amber Gold
      type: ShopItemType.xpOverdrive,
      badgeText: 'BOOST',
    ),
    ShopItem(
      id: 'item_data_pack',
      name: 'ENCRYPTED DATA POD',
      description: 'Summons an encrypted high-grade Bot Card ready for immediate decryption.',
      costBits: 120,
      icon: Icons.inventory_2_rounded,
      accentColor: Color(0xFFA855F7), // Purple
      type: ShopItemType.mysteryDataPack,
      badgeText: 'LOOT',
    ),
    ShopItem(
      id: 'item_core_purifier',
      name: 'NEURAL CORE PURIFIER',
      description: 'Stabilizes Hive squad connection, clearing system strain and glitches.',
      costBits: 180,
      icon: Icons.healing_rounded,
      accentColor: Color(0xFF10B981), // Emerald
      type: ShopItemType.corePurifier,
      badgeText: 'TACTICAL',
    ),
  ];
}
