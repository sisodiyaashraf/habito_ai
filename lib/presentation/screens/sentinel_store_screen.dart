import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../../domain/entities/shop_item.dart';
import '../../core/services/game_audio_service.dart';

class SentinelTheme {
  final String name;
  final String description;
  final Color primaryColor;
  final int xpRequired;
  final String assetPath;

  const SentinelTheme({
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.xpRequired,
    required this.assetPath,
  });
}

class SentinelStoreScreen extends StatefulWidget {
  const SentinelStoreScreen({super.key});

  @override
  State<SentinelStoreScreen> createState() => _SentinelStoreScreenState();
}

class _SentinelStoreScreenState extends State<SentinelStoreScreen> {
  int _selectedTab = 0; // 0: Tactical Protocols, 1: Visual Themes

  final List<SentinelTheme> availableThemes = const [
    SentinelTheme(
      name: "NEON_PULSE",
      description: "Standard issue sentinel cyan. High visibility optic wavelength.",
      primaryColor: Colors.cyanAccent,
      xpRequired: 0,
      assetPath: "assets/previews/cyan.png",
    ),
    SentinelTheme(
      name: "BLOOD_MOON",
      description: "Crisis response crimson. Enhances adrenaline & focus response.",
      primaryColor: Colors.redAccent,
      xpRequired: 1500,
      assetPath: "assets/previews/red.png",
    ),
    SentinelTheme(
      name: "AMETHYST_VOID",
      description: "Deep stealth purple spectrum for covert focus operations.",
      primaryColor: Colors.purpleAccent,
      xpRequired: 3000,
      assetPath: "assets/previews/purple.png",
    ),
    SentinelTheme(
      name: "GOLDEN_LEGACY",
      description: "The ultimate prestige status symbol for supreme sentinels.",
      primaryColor: Color(0xFFFFD700),
      xpRequired: 7000,
      assetPath: "assets/previews/gold.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final habit = context.watch<HabitProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "SENTINEL_BLACK_MARKET",
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildUserBalance(habit),

          // Tab Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavTab("TACTICAL PROTOCOLS", 0),
                  ),
                  Expanded(
                    child: _buildNavTab("THEME SPECTRUMS", 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Content List
          Expanded(
            child: _selectedTab == 0
                ? _buildTacticalItemsList(habit, theme)
                : _buildThemesList(habit, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(String title, int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        GameAudioService().playBlip();
        setState(() => _selectedTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.cyanAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.cyanAccent : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBalance(HabitProvider habit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond_rounded, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "NEURAL BITS",
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${habit.neuralCredits} BITS",
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "TOTAL SYNCS",
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white38,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${habit.totalXP} XP",
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.amberAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalItemsList(HabitProvider habit, ThemeData theme) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: ShopItem.catalog.length,
      itemBuilder: (context, index) {
        final item = ShopItem.catalog[index];
        final canAfford = habit.neuralCredits >= item.costBits;

        return FadeInUp(
          delay: Duration(milliseconds: index * 60),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: item.accentColor.withValues(alpha: canAfford ? 0.35 : 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: item.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(item.icon, color: item.accentColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (item.badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: item.accentColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badgeText!,
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: item.accentColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 8,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${item.costBits} BITS",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: canAfford ? Colors.cyanAccent : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: canAfford
                      ? () async {
                          HapticFeedback.mediumImpact();
                          await habit.buyShopItem(item, context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford
                        ? item.accentColor.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    foregroundColor: canAfford ? item.accentColor : Colors.white24,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: canAfford ? item.accentColor : Colors.transparent,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    canAfford ? "ACQUIRE" : "LOCKED",
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemesList(HabitProvider habit, ThemeData theme) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      itemCount: availableThemes.length,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: index * 60),
          child: _buildThemeCard(context, availableThemes[index], habit),
        );
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    SentinelTheme stheme,
    HabitProvider habit,
  ) {
    bool isLocked = habit.totalXP < stheme.xpRequired;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? Colors.white10
              : stheme.primaryColor.withValues(alpha: 0.35),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          stheme.name,
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: isLocked ? Colors.white24 : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            stheme.description,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              color: Colors.white38,
              fontSize: 8,
            ),
          ),
        ),
        trailing: isLocked
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white24, size: 18),
                  const SizedBox(height: 2),
                  Text(
                    "${stheme.xpRequired} XP",
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white24,
                      fontSize: 8,
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: () {
                  GameAudioService().playChime();
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: stheme.primaryColor,
                      content: Text(
                        "TERMINAL THEME '${stheme.name}' SYNCHRONIZED",
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: stheme.primaryColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text(
                  "APPLY",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
      ),
    );
  }
}
