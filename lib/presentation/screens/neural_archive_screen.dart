import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';
import '../../data/models/achievement_model.dart';
import '../widgets/rewardcontent.dart';

class NeuralArchiveScreen extends StatefulWidget {
  const NeuralArchiveScreen({super.key});

  @override
  State<NeuralArchiveScreen> createState() => _NeuralArchiveScreenState();
}

class _NeuralArchiveScreenState extends State<NeuralArchiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final theme = Theme.of(context);

    final botArchives = habitProvider.systemLogs
        .where(
          (log) => log['reward_bot_id'] != null && log['is_collected'] == true,
        )
        .where(
          (log) => log['reward_bot_id'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "NEURAL ARCHIVE",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: 14,
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
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
          labelStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
          tabs: const [
            Tab(text: "BOT_CARDS"),
            Tab(text: "ACHIEVEMENTS"),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withOpacity(0.02),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(theme),
              if (_tabController.index == 0) _buildCollectionProgress(botArchives.length, theme),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBotCards(context, botArchives),
                    _buildAchievements(context, habitProvider.achievements),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionProgress(int collectedCount, ThemeData theme) {
    // There are 18 unique bots in RewardGenerator (including Golden-Sentinel)
    const int totalBots = 18;
    final double progress = (collectedCount / totalBots).clamp(0.0, 1.0);

    return FadeInDown(
      delay: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "UNIT_COLLECTION_STATUS",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "$collectedCount / $totalBots",
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: theme.colorScheme.onSurface,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: "SEARCH_ARCHIVES...",
            hintStyle: TextStyle(
              fontFamily: 'SpaceMono',
              color: theme.colorScheme.onSurface.withOpacity(0.2),
              fontSize: 10,
              letterSpacing: 1,
            ),
            border: InputBorder.none,
            icon: Icon(
              Icons.search_rounded,
              color: theme.colorScheme.primary.withOpacity(0.5),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotCards(
    BuildContext context,
    List<Map<String, dynamic>> botArchives,
  ) {
    if (botArchives.isEmpty)
      return _buildEmptyState(
        context,
        "NO_DATA_PACKS",
        "COMPLETE HABITS TO DECRYPT UNITS",
      );

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: botArchives.length,
      itemBuilder: (context, index) {
        final log = botArchives[index];
        final themeColor = Color(
          log['reward_color'] ?? Colors.cyanAccent.value,
        );
        final timestamp = log['timestamp'] is DateTime ? log['timestamp'] as DateTime : DateTime.parse(log['timestamp'].toString());

        return ZoomIn(
          delay: Duration(milliseconds: index * 30),
          duration: const Duration(milliseconds: 500),
          child: _buildFullBleedCard(
            context,
            botName: log['reward_bot_id'],
            frontPath: log['reward_image_path'],
            backPath: log['reward_back_path'],
            themeColor: themeColor,
            timestamp: timestamp,
          ),
        );
      },
    );
  }

  Widget _buildAchievements(
    BuildContext context,
    List<Achievement> achievements,
  ) {
    final filteredAchievements = achievements
        .where(
          (a) => a.title.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    if (filteredAchievements.isEmpty)
      return _buildEmptyState(
        context,
        "NO_ACHIEVEMENTS",
        "COMPLETE MISSIONS TO UNLOCK",
      );

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        return FadeInLeft(
          delay: Duration(milliseconds: index * 50),
          child: _buildAchievementTile(context, achievement),
        );
      },
    );
  }

  Widget _buildAchievementTile(BuildContext context, Achievement achievement) {
    final theme = Theme.of(context);
    final isUnlocked = achievement.isUnlocked;
    final color = isUnlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          if (isUnlocked)
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(achievement.icon, color: color, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: isUnlocked
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 8,
                  ),
                ),
                if (isUnlocked && achievement.unlockedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "SYNC_DATE: ${achievement.unlockedAt!.day}/${achievement.unlockedAt!.month}/${achievement.unlockedAt!.year}",
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUnlocked)
            Icon(
              Icons.verified_rounded,
              color: theme.colorScheme.primary,
              size: 18,
            )
          else
            Icon(
              Icons.lock_outline_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildFullBleedCard(
    BuildContext context, {
    required String botName,
    required String frontPath,
    required String backPath,
    required Color themeColor,
    required DateTime timestamp,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showCardDetails(context, botName, frontPath, themeColor);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: themeColor.withOpacity(0.15),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              _buildCardImage(context, frontPath),
              // Gradient Overlay for depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        themeColor.withOpacity(0.05),
                        themeColor.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        border: Border(
                          top: Border.all(
                            color: themeColor.withOpacity(0.2),
                          ).top,
                        ),
                      ),
                      child: Text(
                        botName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          color: themeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardDetails(
    BuildContext context,
    String name,
    String image,
    Color color,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Card Details",
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: FadeInScale(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(image, height: 250, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "TACTICAL_UNIT_ID",
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: color.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "This tactical unit was decrypted after a series of successful protocol synchronizations. It represents peak efficiency and neural stability.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "CLOSE",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            context.read<AIProvider>().setUserImage(image);
                            Navigator.pop(context);
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "IDENTITY_SHELL_UPDATED: $name",
                                  style: const TextStyle(fontFamily: 'SpaceMono'),
                                ),
                                backgroundColor: color.withOpacity(0.8),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "SET AS PROFILE",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardImage(BuildContext context, String path) {
    return SizedBox.expand(
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeIn(
            duration: const Duration(seconds: 2),
            child: Icon(
              Icons.lock_outline_rounded,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              letterSpacing: 5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class FadeInScale extends StatefulWidget {
  final Widget child;
  const FadeInScale({super.key, required this.child});

  @override
  State<FadeInScale> createState() => _FadeInScaleState();
}

class _FadeInScaleState extends State<FadeInScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
