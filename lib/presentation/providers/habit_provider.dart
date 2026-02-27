import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/services/notification_service.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../widgets/RewardScratchDialog.dart';
import '../widgets/rewardcontent.dart';
import 'hive_provider.dart';

class HabitProvider extends ChangeNotifier {
  final HabitRepository habitRepository;

  HabitProvider({required this.habitRepository});

  List<Habit> _habits = [];

  // --- Neural History & Vault ---
  final List<Map<String, dynamic>> _systemLogs = [];
  List<Map<String, dynamic>> get systemLogs => _systemLogs.reversed.toList();

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

  // --- Stability Metrics ---
  double get dayStability => _calculateStabilityForDuration(1);
  double get weekStability => _calculateStabilityForDuration(7);
  double get monthStability => _calculateStabilityForDuration(30);

  // --- RESTORED: Analytics Getters for HUD ---

  /// Calculates overall completion percentage for the current week
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

  /// Finds the longest active streak across all protocols
  int get highestStreak {
    if (_habits.isEmpty) return 0;
    return _habits
        .map((h) => calculateStreak(h.completionDates))
        .fold(0, (max, streak) => streak > max ? streak : max);
  }

  /// Analyzes activity peaks over the last 7 days for the Radar HUD
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
      "Mood index $mood captured for ${habit.name}.",
      Icons.psychology,
    );
    notifyListeners();
  }

  Future<void> loadHabits() async {
    try {
      _habits = await habitRepository.getAllHabits();
      final box = await Hive.openBox('settings');
      _totalXP = box.get('total_xp', defaultValue: 0);
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

  void _checkSystemIntegrity(BuildContext context) {
    if (!context.mounted) return;
    final hive = Provider.of<HiveProvider>(context, listen: false);
    hive.setGlitchState(dayStability < 0.20);
  }

  Future<void> addXP(int amount) async {
    int oldLevel = currentLevel;
    _totalXP += amount;
    final box = await Hive.openBox('settings');
    await box.put('total_xp', _totalXP);
    if (currentLevel > oldLevel) {
      _hasLeveledUp = true;
      _addLog(
        "SYSTEM UPGRADE",
        "Neural capacity Level $currentLevel reached.",
        Icons.bolt_rounded,
      );
    }
    notifyListeners();
  }

  // --- Habit Interaction ---

  Future<void> updateHabitProgress(
    String id,
    double value,
    BuildContext context,
  ) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final habit = _habits[index];
    final hive = Provider.of<HiveProvider>(context, listen: false);

    double newProgress = (habit.currentValue + value).clamp(
      0.0,
      habit.dailyTarget.toDouble(),
    );
    bool wasMet = habit.currentValue >= habit.dailyTarget;
    bool isMetNow = newProgress >= habit.dailyTarget;
    List<DateTime> updatedDates = List.from(habit.completionDates);

    if (isMetNow && !wasMet) {
      updatedDates.add(DateTime.now());
      final reward = RewardGenerator.getRandom();
      if (context.mounted)
        RewardScratchDialog.show(context, reward, DateTime.now());
      await addXP(reward.points);
      hive.updateMissionProgress(context, 0.05);
      hive.triggerSquadReaction(habit.name, true);
      _addLog(
        "BOT_DECRYPTED",
        "Acquired ${reward.botName} card.",
        Icons.memory,
        reward: reward,
      );
    }

    _habits[index] = habit.copyWith(
      currentValue: newProgress,
      completionDates: updatedDates,
    );
    await habitRepository.saveHabit(_habits[index]);
    notifyListeners();
    _checkSystemIntegrity(context);
  }

  // Inside HabitProvider class...

  Future<void> toggleHabit(String id, BuildContext context) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final habit = _habits[index];
    final today = _normalizeDate(DateTime.now());
    List<DateTime> updatedDates = List.from(habit.completionDates);
    bool wasDone = updatedDates.any((d) => _isSameDay(d, today));

    if (!wasDone) {
      updatedDates.add(DateTime.now());

      // 1. Calculate how many habits are completed TODAY
      int completedToday =
          _habits.where((h) {
            return h.completionDates.any((d) => _isSameDay(d, today));
          }).length +
          1; // +1 for the current one

      // 2. Logic: One habit = One Card. 8-10 habits = Gold Card.
      RewardContent generatedReward;
      if (completedToday >= 8) {
        // Force get the Golden Sentinel if the user is a high achiever
        generatedReward = RewardGenerator.getRandomGold();
      } else {
        generatedReward = RewardGenerator.getRandom();
      }

      // 3. Show the scratch dialog
      if (context.mounted) {
        RewardScratchDialog.show(context, generatedReward, DateTime.now());
      }

      // 4. Archive for Motivation/Vault
      _addLog(
        "SYNC_SUCCESS",
        "${habit.name} verified.",
        Icons.verified_user_rounded,
        reward: generatedReward,
      );
    }

    _habits[index] = habit.copyWith(completionDates: updatedDates);
    await habitRepository.saveHabit(_habits[index]);
    notifyListeners();
  }
  // Inside HabitProvider class

  /// Marks a bot card as collected so it moves from GameHub to Archive
  Future<void> collectBotCard(DateTime timestamp) async {
    final index = _systemLogs.indexWhere(
      (log) => log['timestamp'] == timestamp,
    );
    if (index != -1) {
      // We add a 'is_collected' flag to the log
      _systemLogs[index]['is_collected'] = true;

      // Persist this change to Hive if you are using it for logs
      // var box = await Hive.openBox('system_logs');
      // await box.put('logs', _systemLogs);

      notifyListeners();
      HapticFeedback.lightImpact();
    }
  }

  // --- Management & Utilities ---

  Future<void> addHabit(
    String name, {
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
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      priority: priority,
      dailyTarget: dailyTarget,
      unit: isTimerEnabled ? "mins" : "units",
      isTimerEnabled: isTimerEnabled,
      timerMinutes: timerMinutes,
      completionDates: [],
      currentValue: 0.0,
      reminderTime: "${reminderTime.hour}:${reminderTime.minute}",
      scheduledDays: scheduledDays,
      isNotificationsEnabled: isNotificationsEnabled,
    );
    await habitRepository.saveHabit(newHabit);
    await loadHabits();
    _addLog("NEW PROTOCOL", "Initiated: $name", _getIconForCategory(category));
  }

  IconData _getIconForCategory(String category) {
    switch (category.toUpperCase()) {
      case 'CODING':
        return Icons.code;
      case 'STUDY':
        return Icons.menu_book;
      case 'FITNESS':
        return Icons.fitness_center;
      default:
        return Icons.rocket_launch;
    }
  }

  void _addLog(
    String title,
    String description,
    IconData icon, {
    RewardContent? reward,
  }) {
    _systemLogs.add({
      'title': title.toUpperCase(),
      'description': description,
      'icon': icon,
      'timestamp': DateTime.now(),
      'reward_bot_id': reward?.botName,
      'reward_image_path': reward?.frontImagePath,
      'reward_back_path': reward?.backImagePath,
      'reward_color': reward?.themeColor.value,
      'reward_points': reward?.points,
      'is_rare': reward?.isRare ?? false,
    });
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

  void resetCelebration() => _shouldCelebrate = false;
  void resetLevelUp() => _hasLeveledUp = false;
}
