import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final DateTime? unlockedAt;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.unlockedAt,
    this.isUnlocked = false,
  });

  Achievement copyWith({
    DateTime? unlockedAt,
    bool? isUnlocked,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'icon_code': icon.codePoint,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'isUnlocked': isUnlocked,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      icon: IconData(json['icon_code'], fontFamily: 'MaterialIcons'),
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}
