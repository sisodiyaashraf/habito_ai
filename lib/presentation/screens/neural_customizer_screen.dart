import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/ai_provider.dart';
import '../widgets/sentinel_identity_hud.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "NEURAL CUSTOMIZER",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 2,
          dividerColor: Colors.transparent,
          labelColor: theme.colorScheme.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            letterSpacing: 1.5,
          ),
          tabs: const [
            Tab(text: "IDENTITY"),
            Tab(text: "VISUALS"),
            Tab(text: "LOGIC"),
            Tab(text: "MODULES"),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildLivePreview(ai, theme),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIdentitySettings(context, ai),
                    _buildThemeSelector(context, ai),
                    _buildPersonaSelector(context, ai),
                    _buildModuleToggles(context, ai),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLivePreview(AIProvider ai, ThemeData theme) {
    final themeData = _getThemeData(ai.activeThemeId);
    final Color themeColor = themeData['color'] as Color;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            themeColor.withValues(alpha: 0.5),
            Colors.transparent,
            themeColor.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            child: Row(
              children: [
                SentinelIdentityHUD(
                  size: 90,
                  label: ai.userName.toUpperCase(),
                  subLabel: ai.sentinelId,
                  themeColor: themeColor,
                  progress: 0.65, // Mock progress for preview
                  imagePath: ai.userImagePath,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              "SENTINEL ID: ${ai.sentinelId}",
                              style: TextStyle(
                                fontFamily: 'SpaceMono',
                                color: themeColor.withValues(alpha: 0.7),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "ACTIVE",
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 6,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ai.userName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "NEURAL PERSONA: ${ai.activePersonaEnum.name.toUpperCase()}",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: themeColor,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentitySettings(BuildContext context, AIProvider ai) {
    final theme = Theme.of(context);
    final themeData = _getThemeData(ai.activeThemeId);
    final Color themeColor = themeData['color'] as Color;
    final TextEditingController nameController = TextEditingController(
      text: ai.userName,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        FadeInUp(
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CALLSIGN CALIBRATION",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  onChanged: (val) => ai.setUserName(val),
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: themeColor,
                    ),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.shuffle_rounded, color: themeColor),
                      onPressed: () {
                        ai.randomizeIdentity();
                        nameController.text = ai.userName;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // NEURAL AVATAR SELECTOR
        FadeInUp(
          delay: const Duration(milliseconds: 50),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NEURAL AVATAR UPLINK",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10, // Show first 10 bots as options
                    itemBuilder: (context, index) {
                      final images = [
                        "assets/bots_images/brain_bot.png",
                        "assets/bots_images/hardware_bot.png",
                        "assets/bots_images/clean_bot.png",
                        "assets/bots_images/focusbot.png",
                        "assets/bots_images/breath_bot.png",
                        "assets/bots_images/bugbot.png",
                        "assets/bots_images/clock_bot.png",
                        "assets/bots_images/builder_bot.png",
                        "assets/bots_images/finish_bot.png",
                        "assets/bots_images/astro_bot.png",
                      ];
                      final imagePath = images[index];
                      final isSelected = ai.userImagePath == imagePath;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ai.setUserImage(imagePath);
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 15),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected
                                  ? themeColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FadeInUp(
          delay: const Duration(milliseconds: 100),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SYSTEM ID TELEMETRY",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTelemetryRow("SENTINEL_UID", ai.sentinelId, themeColor),
                const SizedBox(height: 12),
                _buildTelemetryRow(
                  "ENCRYPTION_LVL",
                  "AES-256-QUANTUM",
                  themeColor,
                ),
                const SizedBox(height: 12),
                _buildTelemetryRow("LAST_SYNC", "T-MINUS 00:00", themeColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontFamily: 'SpaceMono', color: color.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontFamily: 'SpaceMono', color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getThemeData(String id) {
    final themes = [
      {'id': 'cyan_core', 'name': 'CYAN CORE', 'color': Colors.cyanAccent, 'desc': 'High-performance neural interface.'},
      {'id': 'amethyst', 'name': 'AMETHYST', 'color': Colors.purpleAccent, 'desc': 'Deep focus and creativity mode.'},
      {'id': 'amber_alert', 'name': 'AMBER ALERT', 'color': Colors.orangeAccent, 'desc': 'Emergency efficiency protocol.'},
    ];
    return themes.firstWhere((t) => t['id'] == id);
  }

  Widget _buildThemeSelector(BuildContext context, AIProvider ai) {
    final theme = Theme.of(context);
    final themes = [
      {'id': 'cyan_core', 'name': 'CYAN CORE', 'color': Colors.cyanAccent, 'desc': 'Optimal balance for daily synchronization.'},
      {'id': 'amethyst', 'name': 'AMETHYST', 'color': Colors.purpleAccent, 'desc': 'Enhanced aesthetic for late-night focus.'},
      {'id': 'amber_alert', 'name': 'AMBER ALERT', 'color': Colors.orangeAccent, 'desc': 'Maximum visibility for critical tasks.'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final themeData = themes[index];
        final isSelected = ai.activeThemeId == themeData['id'];
        final Color themeColor = themeData['color'] as Color;

        return FadeInLeft(
          delay: Duration(milliseconds: index * 100),
          child: GestureDetector(
            onTap: () => ai.updateTheme(themeData['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? themeColor.withValues(alpha: 0.1) : theme.colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? themeColor : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 15)] : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeColor, width: 2),
                    ),
                    child: Icon(Icons.palette_outlined, color: themeColor, size: 20),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          themeData['name'] as String,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: isSelected ? themeColor : theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          themeData['desc'] as String,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) FadeIn(child: Icon(Icons.check_circle, color: themeColor, size: 24)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPersonaSelector(BuildContext context, AIProvider ai) {
    final theme = Theme.of(context);
    final personaData = {
      AIPersonality.gentle: {
        'desc': 'Supportive and encouraging feedback.',
        'icon': Icons.favorite_outline_rounded,
        'color': Colors.greenAccent,
      },
      AIPersonality.neutral: {
        'desc': 'Efficient and data-driven analytics.',
        'icon': Icons.insights_rounded,
        'color': Colors.blueAccent,
      },
      AIPersonality.brutal: {
        'desc': 'Hardcore discipline and sharp roasts.',
        'icon': Icons.bolt_rounded,
        'color': Colors.redAccent,
      },
    };

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: AIPersonality.values.map((p) {
        final isSelected = ai.activePersonaEnum == p;
        final data = personaData[p]!;
        final Color color = data['color'] as Color;

        return FadeInUp(
          child: GestureDetector(
            onTap: () => ai.setPersona(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.1) : theme.colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(data['icon'] as IconData, color: color, size: 24),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            color: isSelected ? color : theme.colorScheme.onSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data['desc'] as String,
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<AIPersonality>(
                    value: p,
                    groupValue: ai.activePersonaEnum,
                    onChanged: (val) => ai.setPersona(val!),
                    activeColor: color,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModuleToggles(BuildContext context, AIProvider ai) {
    final theme = Theme.of(context);
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      children: [
        _buildModuleCard(
          "HAPTIC FEEDBACK",
          "Tactile neural response systems.",
          Icons.vibration_rounded,
          ai.isHapticEnabled,
          (val) => ai.toggleHaptic(val),
          theme,
        ),
        _buildModuleCard(
          "GLITCH EFFECTS",
          "Visual artifacts for stability feedback.",
          Icons.grid_view_rounded,
          ai.isGlitchEnabled,
          (val) => ai.toggleGlitch(val),
          theme,
        ),
        _buildModuleCard(
          "VOICE MODULATION",
          "Synthesized persona audio responses.",
          Icons.settings_voice_rounded,
          ai.isVoiceModulationEnabled,
          (val) => ai.toggleVoice(val),
          theme,
        ),
        const SizedBox(height: 20),
        Center(
          child: Opacity(
            opacity: 0.3,
            child: Column(
              children: [
                Icon(Icons.lock_clock_rounded, size: 30, color: theme.colorScheme.onSurface),
                const SizedBox(height: 10),
                Text(
                  "MORE MODULES UNLOCK AT LVL 10",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 8,
                    letterSpacing: 2,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.7), size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
            activeThumbColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
