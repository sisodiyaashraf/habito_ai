import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/history_analytics_header.dart';
import '../widgets/mood_trend_chart.dart';
import '../widgets/robot_guide_overlay.dart';
import 'neural_archive_screen.dart';
import '../../core/utils/responsive.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isGuideVisible = false;
  int _guideStepIndex = 0;

  final List<Map<String, String>> _historySequence = [
    {
      'label': 'MISSION_VAULT',
      'message':
          'Welcome to the Mission Vault. This encrypted archive stores every neural sync and system event recorded by your OS.',
    },
    {
      'label': 'LIFETIME_METRICS',
      'message':
          'These telemetry data points represent your total evolution. Monitor your aggregate XP and system efficiency here.',
    },
    {
      'label': 'STABILITY_TREND',
      'message':
          'The Neural Stability graph visualizes your consistency over time. Sharp drops indicate system fatigue or missed syncs.',
    },
    {
      'label': 'PROTOCOL_LOGS',
      'message':
          'This chronological feed provides detailed oversight of every protocol initiated. Tap a log to review historical data.',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkHistoryGuide());
  }

  Future<void> _checkHistoryGuide() async {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    bool shouldShow = await habitProvider.shouldShowGuide('history');
    if (shouldShow && mounted) {
      setState(() {
        _isGuideVisible = true;
        _guideStepIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final logs = habitProvider.systemLogs;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          "MISSION VAULT",
          style: TextStyle(
            fontFamily: 'Orbitron',
            letterSpacing: 4,
            fontSize: Responsive.scaleText(context, 14),
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.shield_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NeuralArchiveScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSyncIndicator(habitProvider.habits.isNotEmpty, theme),

              _buildHighlightWrapper(
                theme,
                isActive: _isGuideVisible && _guideStepIndex == 1,
                child: const HistoryAnalyticsHeader(),
              ),

              _buildHighlightWrapper(
                theme,
                isActive: _isGuideVisible && _guideStepIndex == 2,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.scalePadding(context, 20),
                  vertical: 10,
                ),
                child: const MoodTrendChart(),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), height: 1),
              ),

              Expanded(
                child: _buildHighlightWrapper(
                  theme,
                  isActive: _isGuideVisible && _guideStepIndex == 3,
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                  child: logs.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          itemCount: logs.length,
                          padding: const EdgeInsets.fromLTRB(5, 10, 5, 120),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return _buildLogEntry(
                              log,
                              habitProvider.streakMultiplier,
                              theme,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),

          if (_isGuideVisible)
            RobotGuideOverlay(
              label: _historySequence[_guideStepIndex]['label']!,
              message:
                  _historySequence[_historySequence.length > _guideStepIndex
                      ? _guideStepIndex
                      : 0]['message']!,
              onDismiss: () {
                setState(() {
                  if (_guideStepIndex < _historySequence.length - 1) {
                    _guideStepIndex++;
                    HapticFeedback.lightImpact();
                  } else {
                    _isGuideVisible = false;
                    context.read<HabitProvider>().markGuideAsSeen('history');
                    HapticFeedback.mediumImpact();
                  }
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightWrapper(
    ThemeData theme, {
    required Widget child,
    required bool isActive,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.8)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  Widget _buildSyncIndicator(bool isActive, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.1),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? "NEURAL LINK: SYNCHRONIZED" : "LINK OFFLINE",
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: Responsive.scaleText(context, 8),
              color: isActive
                  ? theme.colorScheme.primary.withValues(alpha: 0.6)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.1),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(Map<String, dynamic> log, double currentMultiplier, ThemeData theme) {
    final bool isXPUpload = log['title'] == 'XP_UPLOAD';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isXPUpload
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isXPUpload
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              log['icon'] ?? Icons.history,
              color: isXPUpload ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.24),
              size: Responsive.scaleText(context, 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (log['title'] as String).toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        color: isXPUpload ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        fontSize: Responsive.scaleText(context, 10),
                        letterSpacing: 1,
                      ),
                    ),
                    if (isXPUpload && currentMultiplier > 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${currentMultiplier}x",
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: Responsive.scaleText(context, 8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  log['description'],
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: Responsive.scaleText(context, 10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('HH:mm | dd MMM').format(log['timestamp']),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    fontSize: Responsive.scaleText(context, 8),
                    fontFamily: 'SpaceMono',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            "VAULT EMPTY: NO LOGS DETECTED",
            style: TextStyle(
              fontFamily: 'Orbitron',
              color: theme.colorScheme.onSurface.withValues(alpha: 0.24),
              letterSpacing: 2,
              fontSize: Responsive.scaleText(context, 10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
