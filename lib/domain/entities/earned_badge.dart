import 'dart:ui';

import 'package:flutter/material.dart';

class EarnedBadge {
  final String id;
  final String title;
  final String icon;
  final DateTime dateEarned;
  final String description;
  final Color rarityColor;

  EarnedBadge({
    required this.id,
    required this.title,
    required this.icon,
    required this.dateEarned,
    required this.description,
    this.rarityColor = Colors.cyanAccent,
  });
}
