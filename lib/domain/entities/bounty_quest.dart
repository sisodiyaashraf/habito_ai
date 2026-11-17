import 'package:flutter/material.dart';

class BountyQuest {
  final String id;
  final String title;
  final String description;
  final String category; // 'completion', 'timer', 'priority', 'reflection'
  final int currentProgress;
  final int targetProgress;
  final int xpReward;
  final int creditsReward;
  final bool isClaimed;
  final int iconCode;

  const BountyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.currentProgress,
    required this.targetProgress,
    required this.xpReward,
    required this.creditsReward,
    this.isClaimed = false,
    required this.iconCode,
  });

  bool get isCompleted => currentProgress >= targetProgress;
  double get progressRatio => targetProgress > 0 
      ? (currentProgress / targetProgress).clamp(0.0, 1.0) 
      : 0.0;
  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  BountyQuest copyWith({
    int? currentProgress,
    bool? isClaimed,
  }) {
    return BountyQuest(
      id: id,
      title: title,
      description: description,
      category: category,
      currentProgress: currentProgress ?? this.currentProgress,
      targetProgress: targetProgress,
      xpReward: xpReward,
      creditsReward: creditsReward,
      isClaimed: isClaimed ?? this.isClaimed,
      iconCode: iconCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'currentProgress': currentProgress,
    'targetProgress': targetProgress,
    'xpReward': xpReward,
    'creditsReward': creditsReward,
    'isClaimed': isClaimed,
    'iconCode': iconCode,
  };

  factory BountyQuest.fromJson(Map<String, dynamic> json) {
    return BountyQuest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      targetProgress: (json['targetProgress'] as num?)?.toInt() ?? 1,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 50,
      creditsReward: (json['creditsReward'] as num?)?.toInt() ?? 15,
      isClaimed: json['isClaimed'] as bool? ?? false,
      iconCode: (json['iconCode'] as num?)?.toInt() ?? Icons.bolt_rounded.codePoint,
    );
  }
}
