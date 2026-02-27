import 'package:flutter/material.dart';
import 'dart:math';

class RewardContent {
  final String botName;
  final String frontImagePath; // The Bot Card Front
  final String backImagePath; // The Bot Card Back (Quote Lines)
  final IconData icon; // HUD System Icon
  final int points; // Neural XP Reward
  final Color themeColor; // UI Accent Color
  final bool isRare; // Legendary Status

  RewardContent({
    required this.botName,
    required this.frontImagePath,
    required this.backImagePath,
    required this.icon,
    required this.points,
    required this.themeColor,
    this.isRare = false,
  });
}

class RewardGenerator {
  static final List<RewardContent> _rewards = [
    // --- PRODUCTIVITY NODES ---
    RewardContent(
      botName: "BRAIN-BO",
      frontImagePath: "assets/bots_images/brain_bot.png",
      backImagePath: "assets/bots_images/brain_bot2.png",
      icon: Icons.psychology_rounded,
      points: 150,
      themeColor: Colors.cyanAccent,
    ),
    //--- PHYSICAL & ENERGY ---
    RewardContent(
      botName: "HARDWARE-BOT",
      frontImagePath: "assets/bots_images/hardware_bot.png",
      backImagePath: "assets/bots_images/hardware_bot2.png",
      icon: Icons.memory_rounded,
      points: 70,
      themeColor: Colors.orangeAccent,
    ),
    RewardContent(
      botName: "CLEAN-BOT",
      frontImagePath: "assets/bots_images/clean_bot.png",
      backImagePath: "assets/bots_images/clean_bot2.png",
      icon: Icons.cleaning_services_rounded,
      points: 75,
      themeColor: Colors.indigoAccent,
    ),
    RewardContent(
      botName: "FOCUS-BOT",
      frontImagePath: "assets/bots_images/focusbot.png",
      backImagePath: "assets/bots_images/focusbot2.png",
      icon: Icons.center_focus_strong_rounded,
      points: 70,
      themeColor: Colors.white,
    ),
    RewardContent(
      botName: "BREATH-BOT",
      frontImagePath: "assets/bots_images/breath_bot.png",
      backImagePath: "assets/bots_images/breath_bot2.png",
      icon: Icons.wind_power_rounded,
      points: 50,
      themeColor: Colors.lightBlueAccent,
    ),
    RewardContent(
      botName: "BUG-BOT",
      frontImagePath: "assets/bots_images/bugbot.png",
      backImagePath: "assets/bots_images/bugbot2.png",
      icon: Icons.bug_report_rounded,
      points: 60,
      themeColor: Colors.lightGreenAccent,
    ),

    RewardContent(
      botName: "CLOCK-BOT",
      frontImagePath: "assets/bots_images/clock_bot.png",
      backImagePath: "assets/bots_images/clock_bot2.png",
      icon: Icons.timer_rounded,
      points: 60,
      themeColor: Colors.pinkAccent,
    ),
    RewardContent(
      botName: "BUILDER-BOT",
      frontImagePath: "assets/bots_images/builder_bot.png",
      backImagePath: "assets/bots_images/builder_bot2.png",
      icon: Icons.architecture_rounded,
      points: 65,
      themeColor: Colors.deepOrangeAccent,
    ),
    RewardContent(
      botName: "FINISH-BOT",
      frontImagePath: "assets/bots_images/finish_bot.png",
      backImagePath: "assets/bots_images/finish_bot2.png",
      icon: Icons.flag_circle_rounded,
      points: 95,
      themeColor: Colors.lightBlueAccent,
    ),
    RewardContent(
      botName: "CHART-BOT",
      frontImagePath: "assets/bots_images/chart_bot.png",
      backImagePath: "assets/bots_images/chart_bot2.png",
      icon: Icons.show_chart_rounded,
      points: 80,
      themeColor: Colors.cyan,
    ),
    RewardContent(
      botName: "BUILD-BOT",
      frontImagePath: "assets/bots_images/build_bot.png",
      backImagePath: "assets/bots_images/build_bot2.png",
      icon: Icons.construction_rounded,
      points: 75,
      themeColor: Colors.brown,
    ),
    RewardContent(
      botName: "ASTRO-BOT",
      frontImagePath: "assets/bots_images/astro_bot.png",
      backImagePath: "assets/bots_images/astro_bot2.png",
      icon: Icons.rocket_launch_rounded,
      points: 200,
      themeColor: Colors.blueAccent,
    ),
    RewardContent(
      botName: "GEAR-SYNC",
      frontImagePath: "assets/bots_images/gearbot.png",
      backImagePath: "assets/bots_images/gearbot2.png",
      icon: Icons.settings_suggest_rounded,
      points: 175,
      themeColor: Colors.tealAccent,
    ),

    // --- ENERGY NODES ---
    RewardContent(
      botName: "STEAM-CORE",
      frontImagePath: "assets/bots_images/steam_bot.png",
      backImagePath: "assets/bots_images/steam_bot2.png",
      icon: Icons.air_rounded,
      points: 250,
      themeColor: Colors.redAccent,
    ),
    RewardContent(
      botName: "POWER-CELL",
      frontImagePath: "assets/bots_images/power_bot.png",
      backImagePath: "assets/bots_images/power_bot2.png",
      icon: Icons.battery_charging_full_rounded,
      points: 300,
      themeColor: Colors.greenAccent,
    ),

    // --- ZEN NODES ---
    RewardContent(
      botName: "ZEN-SENTINEL",
      frontImagePath: "assets/bots_images/zenbot.png",
      backImagePath: "assets/bots_images/zenbot2.png",
      icon: Icons.self_improvement_rounded,
      points: 400,
      themeColor: Colors.purpleAccent,
    ),
    RewardContent(
      botName: "VOID-EXPLORER",
      frontImagePath: "assets/bots_images/explorerbot.png",
      backImagePath: "assets/bots_images/explorerbot2.png",
      icon: Icons.explore_rounded,
      points: 350,
      themeColor: Colors.amberAccent,
    ),

    // --- THE LEGENDARY ANOMALY ---
    RewardContent(
      botName: "GOLDEN-SENTINEL",
      frontImagePath: "assets/bots_images/gold_bot.png",
      backImagePath: "assets/bots_images/gold_bot2.png",
      icon: Icons.auto_awesome_rounded,
      points: 1000,
      themeColor: const Color(0xFFFFD700),
      isRare: true,
    ),
  ];

  /// FIX: Returns the Legendary Gold Bot for 8+ daily completions
  static RewardContent getRandomGold() {
    return _rewards.firstWhere(
      (r) => r.isRare && r.botName == "GOLDEN-SENTINEL",
      orElse: () => _rewards.last, // Fallback to last reward if not found
    );
  }

  /// FIX: Finder helper for the Neural Vault to reconstruct history
  static RewardContent getByName(String name) {
    return _rewards.firstWhere(
      (r) => r.botName == name,
      orElse: () => _rewards.first, // Fallback to default
    );
  }

  /// Returns a random reward based on rarity weightage
  static RewardContent getRandom() {
    final random = Random().nextInt(100);

    // 8% chance for Legendary/Rare Anomalies in standard draw
    if (random < 8) {
      final rares = _rewards.where((r) => r.isRare).toList();
      return rares[Random().nextInt(rares.length)];
    }

    // Standard pool
    final commons = _rewards.where((r) => !r.isRare).toList();
    return commons[Random().nextInt(commons.length)];
  }
}
