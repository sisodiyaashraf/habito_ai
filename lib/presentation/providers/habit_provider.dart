import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../data/models/achievement_model.dart';
import '../widgets/reward_animation_widget.dart';
import '../widgets/rewardcontent.dart';
import 'hive_provider.dart';
import 'notification_provider.dart';
import '../../core/services/notifications/persona_scheduler.dart';
import '../../main.dart'; // IMPORT NAVIGATOR KEY

class HabitProvider extends ChangeNotifier {
  final HabitRepository habitRepository;

  HabitProvider({required this.habitRepository});

  List<Habit> _habits = [];
  List<Achievement> _achievements = [];

  // --- Neural History & Vault ---
  List<Map<String, dynamic>> _systemLogs = [];
  List<Map<String, dynamic>> get systemLogs => _systemLogs.reversed.map((log) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(log);
    if (map['timestamp'] is String) {
      map['timestamp'] = DateTime.parse(map['timestamp']);
    }
    if (map['icon_code'] != null) {
      map['icon'] = IconData(map['icon_code'], fontFamily: 'MaterialIcons');
    }
    return map;
  }).toList();
  List<Achievement> get achievements => _achievements;

  // --- State Flags ---
  bool _shouldCelebrate = false;
  bool _hasLeveledUp = false;
  bool get shouldCelebrate => _shouldCelebrate;
  bool get hasLeveledUp => _hasLeveledUp;

  // --- XP & Evolution ---
  int _totalXP = 0;
  int get totalXP => _totalXP;
  int get currentLevel => (_totalXP / 500).floor() + 1;
  double get levelProgress => (_totalXP % 500) / 500;

  // --- PUBLIC ACCESSORS ---

  /// Returns the list of habits sorted: Incomplete first, then by Priority
  List<Habit> get habits {
    final today = _normalizeDate(DateTime.now());
    return List<Habit>.from(_habits)..sort((a, b) {
      bool aDone = a.completionDates.any((d) => _isSameDay(d, today));
      bool bDone = b.completionDates.any((d) => _isSameDay(d, today));

      if (aDone && !bDone) return 1;
      if (!aDone && bDone) return -1;

      return b.priority.compareTo(a.priority);
    });
  }

  /// Determines XP multiplier based on current highest streak
  double get streakMultiplier {
    int streak = highestStreak;
    if (streak >= 7) return 2.0; // Legendary Consistency
    if (streak >= 3) return 1.5; // Optimized Sync
    return 1.0; // Baseline
  }

  // --- Stability Metrics ---
  double get dayStability => _calculateStabilityForDuration(1);
  double get weekStability => _calculateStabilityForDuration(7);
  double get monthStability => _calculateStabilityForDuration(30);

  // --- Analytics Getters ---

  double get averageCompletionRate {
    if (_habits.isEmpty) return 0.0;
    int totalPossible = 0;
    int actual = 0;
    DateTime now = DateTime.now();

    for (var habit in _habits) {
      for (int i = 0; i < 7; i++) {
        DateTime checkDate = now.subtract(Duration(days: i));
        if (habit.scheduledDays.contains(checkDate.weekday)) {
          totalPossible++;
          if (habit.completionDates.any((d) => _isSameDay(d, checkDate))) {
            actual++;
          }
        }
      }
    }
    return totalPossible == 0 ? 0.0 : (actual / totalPossible).clamp(0.0, 1.0);
  }

  int get highestStreak {
    if (_habits.isEmpty) return 0;
    return _habits
        .map((h) => calculateStreak(h.completionDates))
        .fold(0, (max, streak) => streak > max ? streak : max);
  }

  Map<String, dynamic> get weeklyPeakAnalysis {
    if (_habits.isEmpty) return {'day': 'N/A', 'score': 0.0};
    double maxScore = -1.0;
    DateTime peakDate = DateTime.now();

    for (int i = 0; i < 7; i++) {
      DateTime date = DateTime.now().subtract(Duration(days: i));
      double dayScore = 0;
      for (var h in _habits) {
        dayScore += h.isGoalMet(date) ? 1.0 : 0.0;
      }
      dayScore /= (_habits.isEmpty ? 1 : _habits.length);
      if (dayScore > maxScore) {
        maxScore = dayScore;
        peakDate = date;
      }
    }
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return {'day': days[peakDate.weekday - 1], 'score': maxScore};
  }

  // --- Neural Interaction Methods ---

  Future<void> addHabit(
    String name, {
    String description = "",
    required int dailyTarget,
    required String category,
    required String priority,
    required TimeOfDay reminderTime,
    required List<int> scheduledDays,
    required bool isNotificationsEnabled,
    required bool isTimerEnabled,
    int? timerMinutes,
    required BuildContext context,
  }) async {
    final formattedTime =
        "${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}";
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      category: category,
      priority: priority,
      dailyTarget: dailyTarget,
      unit: isTimerEnabled ? "mins" : "units",
      isTimerEnabled: isTimerEnabled,
      timerMinutes: timerMinutes,
      completionDates: [],
      currentValue: 0.0,
      reminderTime: formattedTime,
      scheduledDays: scheduledDays,
      isNotificationsEnabled: isNotificationsEnabled,
    );

    await habitRepository.saveHabit(newHabit);
    await loadHabits();

    _addLog(
      "NEW PROTOCOL",
      "Initiated: ${name.toUpperCase()}",
      _getIconForCategory(category),
    );
    _checkAchievements();
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    await habitRepository.deleteHabit(id);
    await loadHabits();
    _addLog("PROTOCOL DELETED", "Protocol terminated.", Icons.delete_outline_rounded);
    notifyListeners();
  }

  Future<void> logReflection(String id, String note, int mood) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final today = _normalizeDate(DateTime.now());

    Map<DateTime, String> updatedNotes = Map.from(habit.dailyNotes)
      ..[today] = note;
    Map<DateTime, int> updatedMoods = Map.from(habit.dailyMood)..[today] = mood;

    _habits[index] = habit.copyWith(
      dailyNotes: updatedNotes,
      dailyMood: updatedMoods,
    );
    await habitRepository.saveHabit(_habits[index]);

    _addLog(
      "REFLECTION_ARCHIVED",
      "Neural state sync captured.",
      Icons.psychology_rounded,
    );
    notifyListeners();
  }

  IconData _getIconForCategory(String category) {
    switch (category.toUpperCase()) {
      case 'CODING':
        return Icons.code_rounded;
      case 'STUDY':
        return Icons.menu_book_rounded;
      case 'FITNESS':
      case 'SPORTS':
        return Icons.fitness_center_rounded;
      case 'MEDITATION':
        return Icons.self_improvement_rounded;
      default:
        return Icons.rocket_launch_rounded;
    }
  }

  Future<bool> shouldShowGuide(String screenKey) async {
    final box = await Hive.openBox('settings');
    return !box.get('seen_guide_$screenKey', defaultValue: false);
  }

  Future<void> markGuideAsSeen(String screenKey) async {
    final box = await Hive.openBox('settings');
    await box.put('seen_guide_$screenKey', true);
    notifyListeners();
  }

  // --- Core Methods ---

  Future<void> loadHabits() async {
    try {
      _habits = await habitRepository.getAllHabits();
      final box = await Hive.openBox('settings');
      _totalXP = box.get('total_xp', defaultValue: 0);
      
      // Load Achievements
      final List? savedAchievements = box.get('achievements');
      if (savedAchievements != null) {
        _achievements = savedAchievements
            .map((e) => Achievement.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _initDefaultAchievements();
      }

      // Load System Logs
      final List? savedLogs = box.get('system_logs');
      if (savedLogs != null) {
        _systemLogs = savedLogs.map((log) => Map<String, dynamic>.from(log)).toList();
      }

      _addLog("NEURAL LINK", "Protocols synchronized.", Icons.sensors);
      notifyListeners();
    } catch (e) {
      _addLog(
        "UPLINK ERROR",
        "Failure reading local data.",
        Icons.error_outline,
      );
    }
  }

  void _initDefaultAchievements() {
    _achievements = [
      Achievement(id: 'first_habit', title: 'FIRST PROTOCOL', description: 'Initialize your first habit.', icon: Icons.rocket_launch_rounded),
      Achievement(id: '7_day_streak', title: 'CONSISTENCY CORE', description: 'Maintain a 7-day streak.', icon: Icons.bolt_rounded),
      Achievement(id: 'level_5', title: 'LEVEL 5 SENTINEL', description: 'Reach level 5.', icon: Icons.grade_rounded),
      Achievement(id: 'level_10', title: 'NEURAL OVERLORD', description: 'Reach level 10.', icon: Icons.workspace_premium_rounded),
      Achievement(id: '10_habits', title: 'PROTOCOL MASTER', description: 'Have 10 active habits.', icon: Icons.format_list_bulleted_rounded),
    ];
  }

  Future<void> _saveAchievements() async {
    final box = await Hive.openBox('settings');
    await box.put('achievements', _achievements.map((e) => e.toJson()).toList());
  }

  Future<void> addXP(int amount) async {
    int boostedAmount = (amount * streakMultiplier).round();
    int oldLevel = currentLevel;
    _totalXP += boostedAmount;

    final box = await Hive.openBox('settings');
    await box.put('total_xp', _totalXP);

    if (currentLevel > oldLevel) {
      _hasLeveledUp = true;
      HapticFeedback.vibrate();
      _addLog(
        "SYSTEM UPGRADE",
        "Neural Level $currentLevel reached.",
        Icons.bolt_rounded,
      );
      _checkAchievements();
    }
    notifyListeners();
  }

  void _checkAchievements() {
    bool updated = false;
    
    // Check First Habit
    if (_habits.isNotEmpty) {
      updated |= _unlockAchievement('first_habit');
    }
    
    // Check 7 Day Streak
    if (highestStreak >= 7) {
      updated |= _unlockAchievement('7_day_streak');
    }
    
    // Check Levels
    if (currentLevel >= 5) {
      updated |= _unlockAchievement('level_5');
    }
    if (currentLevel >= 10) {
      updated |= _unlockAchievement('level_10');
    }
    
    // Check Habit Count
    if (_habits.length >= 10) {
      updated |= _unlockAchievement('10_habits');
    }

    if (updated) {
      _saveAchievements();
      notifyListeners();
    }
  }

  bool _unlockAchievement(String id) {
    final index = _achievements.indexWhere((a) => a.id == id);
    if (index != -1 && !_achievements[index].isUnlocked) {
      _achievements[index] = _achievements[index].copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      _addLog("ACHIEVEMENT UNLOCKED", _achievements[index].title, Icons.emoji_events_rounded);
      return true;
    }
    return false;
  }

  // --- Habit Interaction (Reward Protocol) ---

  Future<void> updateHabitProgress(
    String id,
    double value,
    BuildContext context,
  ) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final today = _normalizeDate(DateTime.now());

    double newProgress = (habit.currentValue + value).clamp(
      0.0,
      habit.dailyTarget.toDouble(),
    );
    bool wasMet = habit.currentValue >= habit.dailyTarget;
    bool isMetNow = newProgress >= habit.dailyTarget;
    bool alreadyDoneToday = habit.completionDates.any(
      (d) => _isSameDay(d, today),
    );

    if (isMetNow && !wasMet && !alreadyDoneToday) {
      // Trigger Completion Logic
      await toggleHabit(id, context);
    } else {
      _habits[index] = habit.copyWith(currentValue: newProgress);
      await habitRepository.saveHabit(_habits[index]);
      notifyListeners();
    }
    _checkSystemIntegrity(context);
  }

  Future<void> toggleHabit(String id, BuildContext context) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final today = _normalizeDate(DateTime.now());
    List<DateTime> updatedDates = List.from(habit.completionDates);
    bool wasDone = updatedDates.any((d) => _isSameDay(d, today));

    if (!wasDone) {
      updatedDates.add(DateTime.now());
      // Remove from ignored if previously marked ignored today
      List<DateTime> updatedIgnored = habit.ignoredDates.where((d) => !_isSameDay(d, today)).toList();

      int completedToday =
          _habits
              .where((h) => h.completionDates.any((d) => _isSameDay(d, today)))
              .length +
          1;

      RewardContent reward = (completedToday >= 8)
          ? RewardGenerator.getRandomGold()
          : RewardGenerator.getRandom();

      final DateTime rewardTimestamp = DateTime.now();

      _habits[index] = habit.copyWith(
        completionDates: updatedDates,
        ignoredDates: updatedIgnored,
        currentValue: habit.dailyTarget.toDouble(),
      );
      await habitRepository.saveHabit(_habits[index]);

      _addLog(
        "SYNC_SUCCESS",
        "${habit.name} verified.",
        Icons.verified_user_rounded,
        reward: reward,
        timestamp: rewardTimestamp,
      );

      _showRewardDialog(reward, rewardTimestamp);

      final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
      final hiveProvider = Provider.of<HiveProvider>(context, listen: false);
      PersonaScheduler.showInstantPersonaNudge(
        persona: hiveProvider.activePersona,
        title: "SYNC COMPLETE",
        body: notificationProvider.getCompletionMessage(hiveProvider.activePersona, habit.name),
      );

      await addXP(reward.points);
      _checkAchievements();
    } else {
      // Toggle off / Uncheck for today
      updatedDates.removeWhere((d) => _isSameDay(d, today));
      _habits[index] = habit.copyWith(
        completionDates: updatedDates,
        currentValue: 0.0,
      );
      await habitRepository.saveHabit(_habits[index]);

      _addLog(
        "PROTOCOL UNCHECKED",
        "${habit.name} reset for today.",
        Icons.remove_circle_outline_rounded,
      );

      final navContext = navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text("${habit.name.toUpperCase()} // PROTOCOL_RESET_FOR_TODAY", 
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 10),
            ),
            backgroundColor: Colors.white12,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    _syncWithHiveProvider(context);
    notifyListeners();
  }

  /// Mark habit as ignored/terminated by user for today
  Future<void> ignoreOrTerminateHabit(String id, BuildContext context) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final today = _normalizeDate(DateTime.now());
    
    // Remove from completed if completed today
    List<DateTime> updatedCompletions = habit.completionDates.where((d) => !_isSameDay(d, today)).toList();
    List<DateTime> updatedIgnored = List.from(habit.ignoredDates);
    if (!updatedIgnored.any((d) => _isSameDay(d, today))) {
      updatedIgnored.add(DateTime.now());
    }

    _habits[index] = habit.copyWith(
      completionDates: updatedCompletions,
      ignoredDates: updatedIgnored,
      currentValue: 0.0,
    );
    await habitRepository.saveHabit(_habits[index]);

    _addLog(
      "PROTOCOL TERMINATED",
      "${habit.name} bypassed by operator.",
      Icons.cancel_outlined,
    );

    final hiveProvider = Provider.of<HiveProvider>(context, listen: false);
    PersonaScheduler.showInstantPersonaNudge(
      persona: hiveProvider.activePersona,
      title: "PROTOCOL TERMINATED",
      body: "WARNING: '${habit.name}' was terminated. System strain elevated.",
    );

    _syncWithHiveProvider(context);
    _checkSystemIntegrity(context);
    notifyListeners();
  }

  void _syncWithHiveProvider(BuildContext context) {
    try {
      final hiveProvider = Provider.of<HiveProvider>(context, listen: false);
      hiveProvider.updateUserSyncRate(averageCompletionRate);
    } catch (_) {}
  }

  void _showRewardDialog(RewardContent reward, DateTime timestamp) {
    // Attempt to show dialog immediately if context is available
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      RewardAnimationWidget.show(context, reward);
      return;
    }

    // Fallback with retries if context is temporarily unavailable
    int retries = 0;
    void tryShow() {
      final retryContext = navigatorKey.currentContext;
      if (retryContext != null && retryContext.mounted) {
        RewardAnimationWidget.show(retryContext, reward);
      } else if (retries < 5) {
        retries++;
        Future.delayed(const Duration(milliseconds: 100), tryShow);
      }
    }
    Future.delayed(const Duration(milliseconds: 100), tryShow);
  }

  Future<void> collectBotCard(DateTime timestamp) async {
    final String tsString = timestamp.toIso8601String();
    final index = _systemLogs.indexWhere(
      (log) => log['timestamp'] == tsString,
    );
    if (index != -1) {
      _systemLogs[index]['is_collected'] = true;
      await _saveLogs();
      notifyListeners();
      HapticFeedback.lightImpact();
    }
  }

  // --- Management & Utilities ---

  Future<void> _saveLogs() async {
    final box = await Hive.openBox('settings');
    await box.put('system_logs', _systemLogs);
  }

  void _addLog(
    String title,
    String description,
    IconData icon, {
    RewardContent? reward,
    DateTime? timestamp,
  }) {
    _systemLogs.add({
      'title': title.toUpperCase(),
      'description': description,
      'icon_code': icon.codePoint,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'reward_bot_id': reward?.botName,
      'reward_image_path': reward?.frontImagePath,
      'reward_back_path': reward?.backImagePath,
      'reward_color': reward?.themeColor.value,
      'reward_points': reward?.points,
      'is_rare': reward?.isRare ?? false,
      'is_collected': reward != null ? true : false, // Automatically collected if it's a reward
    });
    _saveLogs();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  DateTime _normalizeDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.map(_normalizeDate).toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 0;
    var current = _normalizeDate(DateTime.now());
    if (!_isSameDay(sorted.first, current) &&
        !_isSameDay(sorted.first, current.subtract(const Duration(days: 1))))
      return 0;
    for (var date in sorted) {
      if (_isSameDay(date, current)) {
        streak++;
        current = current.subtract(const Duration(days: 1));
      } else if (date.isBefore(current))
        break;
    }
    return streak;
  }

  void _checkSystemIntegrity(BuildContext context) {
    if (!context.mounted) return;
    final hive = Provider.of<HiveProvider>(context, listen: false);
    hive.setGlitchState(dayStability < 0.20);
  }

  double _calculateStabilityForDuration(int days) {
    if (_habits.isEmpty) return 0.0;
    int total = 0, actual = 0;
    DateTime now = DateTime.now();
    for (var habit in _habits) {
      for (int i = 0; i < days; i++) {
        DateTime date = now.subtract(Duration(days: i));
        if (habit.scheduledDays.contains(date.weekday)) {
          total++;
          if (habit.completionDates.any((d) => _isSameDay(d, date))) actual++;
        }
      }
    }
    return total == 0 ? 0.0 : (actual / total).clamp(0.0, 1.0);
  }

  void resetCelebration() => _shouldCelebrate = false;
  void resetLevelUp() {
    _hasLeveledUp = false;
    notifyListeners();
  }

  Future<void> resetProgress() async {
    _habits = [];
    _achievements = [];
    _systemLogs = [];
    _totalXP = 0;

    final box = await Hive.openBox('settings');
    await box.delete('total_xp');
    await box.delete('achievements');
    await box.delete('system_logs');

    await habitRepository.clearAllHabits();
    _initDefaultAchievements();
    _addLog(
      "SECURITY OVERRIDE",
      "System purge complete. All data wiped.",
      Icons.warning_amber_rounded,
    );
    notifyListeners();
  }
}
