import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/ai_provider.dart';

class NeuralCustomizerScreen extends StatefulWidget {
  const NeuralCustomizerScreen({super.key});

  @override
  State<NeuralCustomizerScreen> createState() => _NeuralCustomizerScreenState();
}

class _NeuralCustomizerScreenState extends State<NeuralCustomizerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF03050B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "NEURAL CUSTOMIZER",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          indicatorWeight: 1,
          dividerColor: Colors.white10,
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 9,
            letterSpacing: 1.5,
          ),
          tabs: const [
            Tab(text: "VISUALS"),
            Tab(text: "LOGIC"),
            Tab(text: "MODULES"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildThemeSelector(ai),
          _buildPersonaSelector(ai),
          _buildModuleToggles(),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(AIProvider ai) {
    final themes = [
      {'id': 'cyan_core', 'name': 'CYAN CORE', 'color': Colors.cyanAccent},
      {'id': 'amethyst', 'name': 'AMETHYST', 'color': Colors.purpleAccent},
      {
        'id': 'amber_alert',
        'name': 'AMBER ALERT',
        'color': Colors.orangeAccent,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = ai.activeThemeId == theme['id'];
        final Color themeColor = theme['color'] as Color;

        return FadeInLeft(
          delay: Duration(milliseconds: index * 100),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ai.updateTheme(theme['id'] as String);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeColor.withOpacity(0.08)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? themeColor
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeColor,
                      boxShadow: [
                        BoxShadow(
                          color: themeColor.withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    theme['name'] as String,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: isSelected ? Colors.white : Colors.white60,
                      letterSpacing: 2,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: themeColor,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonaSelector(AIProvider ai) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      children: AIPersonality.values.map((p) {
        final isSelected = ai.activePersonaEnum == p;
        return FadeInUp(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              ai.setPersona(p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.cyanAccent.withOpacity(0.08)
                    : Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: isSelected
                                ? Colors.cyanAccent
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "NEURAL FEEDBACK: ${p.name.toUpperCase()} MODE",
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected ? Colors.cyanAccent : Colors.white10,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModuleToggles() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.extension_off_rounded,
            color: Colors.white.withOpacity(0.05),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            "NO EXTERNAL MODULES DETECTED",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white24,
              fontSize: 9,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
