import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  HabitModel({
    required super.id,
    required super.name,
    super.description = "",
    super.completionDates = const [],
    super.ignoredDates = const [],
    super.dailyTarget = 1,
    super.category = "CODING",
    super.priority = "MEDIUM",
    super.unit = "units",
    super.currentValue = 0.0,
    super.isTimerEnabled = false,
    super.timerMinutes,
    super.reminderTime = "09:00",
    super.scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
    super.isNotificationsEnabled = true,
    super.dailyNotes = const {},
    super.dailyMood = const {},
    super.totalTimeTracked = Duration.zero,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'completionDates': completionDates.map((e) => e.toIso8601String()).toList(),
    'ignoredDates': ignoredDates.map((e) => e.toIso8601String()).toList(),
    'dailyTarget': dailyTarget,
    'category': category,
    'priority': priority,
    'unit': unit,
    'currentValue': currentValue,
    'isTimerEnabled': isTimerEnabled,
    'timerMinutes': timerMinutes,
    'reminderTime': reminderTime,
    'scheduledDays': scheduledDays,
    'isNotificationsEnabled': isNotificationsEnabled,
    'dailyNotes': dailyNotes.map((key, value) => MapEntry(key.toIso8601String(), value)),
    'dailyMood': dailyMood.map((key, value) => MapEntry(key.toIso8601String(), value)),
    'totalTimeTracked': totalTimeTracked.inSeconds,
  };

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? "",
      completionDates: (json['completionDates'] as List? ?? [])
          .map((e) => DateTime.parse(e))
          .toList(),
      ignoredDates: (json['ignoredDates'] as List? ?? [])
          .map((e) => DateTime.parse(e))
          .toList(),
      dailyTarget: json['dailyTarget'] ?? 1,
      category: json['category'] ?? "CODING",
      priority: json['priority'] ?? "MEDIUM",
      unit: json['unit'] ?? "units",
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      isTimerEnabled: json['isTimerEnabled'] ?? false,
      timerMinutes: json['timerMinutes'],
      reminderTime: json['reminderTime'] ?? "09:00",
      scheduledDays: List<int>.from(
        json['scheduledDays'] ?? [1, 2, 3, 4, 5, 6, 7],
      ),
      isNotificationsEnabled: json['isNotificationsEnabled'] ?? true,
      dailyNotes: (json['dailyNotes'] as Map? ?? {}).map(
        (key, value) => MapEntry(DateTime.parse(key), value as String),
      ),
      dailyMood: (json['dailyMood'] as Map? ?? {}).map(
        (key, value) => MapEntry(DateTime.parse(key), value as int),
      ),
      totalTimeTracked: Duration(seconds: json['totalTimeTracked'] ?? 0),
    );
  }
}
