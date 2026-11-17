import 'package:flutter/material.dart';

enum OperativeTier {
  recruit,
  cyberOperative,
  commander,
  neuralArchon,
  transcendentSentinel,
}

class RPGStats {
  final double discipline;
  final double focus;
  final double vitality;
  final double willpower;
  final double neuralSync;
  final int combatPower;
  final int level;
  final int streak;

  const RPGStats({
    required this.discipline,
    required this.focus,
    required this.vitality,
    required this.willpower,
    required this.neuralSync,
    required this.combatPower,
    required this.level,
    required this.streak,
  });

  OperativeTier get tier {
    if (level >= 35) return OperativeTier.transcendentSentinel;
    if (level >= 20) return OperativeTier.neuralArchon;
    if (level >= 10) return OperativeTier.commander;
    if (level >= 5) return OperativeTier.cyberOperative;
    return OperativeTier.recruit;
  }

  String get rankTitle {
    switch (tier) {
      case OperativeTier.transcendentSentinel:
        return "TRANSCENDENT SENTINEL";
      case OperativeTier.neuralArchon:
        return "NEURAL ARCHON";
      case OperativeTier.commander:
        return "CYBER COMMANDER";
      case OperativeTier.cyberOperative:
        return "CYBER OPERATIVE";
      case OperativeTier.recruit:
        return "RECRUIT INITIATE";
    }
  }

  String get rankBadge {
    switch (tier) {
      case OperativeTier.transcendentSentinel:
        return "👑";
      case OperativeTier.neuralArchon:
        return "🔮";
      case OperativeTier.commander:
        return "⚔️";
      case OperativeTier.cyberOperative:
        return "⚡";
      case OperativeTier.recruit:
        return "🔰";
    }
  }

  Color get rankColor {
    switch (tier) {
      case OperativeTier.transcendentSentinel:
        return const Color(0xFFFFD700); // Gold
      case OperativeTier.neuralArchon:
        return const Color(0xFFC084FC); // Purple neon
      case OperativeTier.commander:
        return const Color(0xFFF97316); // Orange fire
      case OperativeTier.cyberOperative:
        return const Color(0xFF38BDF8); // Cyan
      case OperativeTier.recruit:
        return const Color(0xFF34D399); // Emerald
    }
  }

  static String getGrade(double value) {
    if (value >= 95) return "S+";
    if (value >= 85) return "S";
    if (value >= 70) return "A";
    if (value >= 50) return "B";
    if (value >= 30) return "C";
    return "D";
  }

  static Color getGradeColor(String grade) {
    switch (grade) {
      case "S+":
      case "S":
        return const Color(0xFFFFD700);
      case "A":
        return const Color(0xFF38BDF8);
      case "B":
        return const Color(0xFF34D399);
      case "C":
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
