import 'package:flutter/material.dart';

class Habit {
  final String id;
  final String name;
  final List<DateTime> completionDates;

  // Domain & Ranking
  final String category; // e.g., 'CODING', 'MEDITATION', 'SPORTS', 'SLEEP'
  final String priority; // 'LOW', 'MEDIUM', 'HIGH'

  // Goal Management
  final int dailyTarget;
  final double currentValue;
  final String unit;

  // Task Type & Timer Features
  final bool isTimerEnabled;
  final int? timerMinutes; // Specific duration for Timer tasks

  // Notification & Scheduling Logic
  final String reminderTime; // Stored as "HH:mm"
  final List<int> scheduledDays; // [1, 2, 3, 4, 5, 6, 7] (Mon-Sun)
  final bool isNotificationsEnabled;

  // Reflective Journaling
  final Map<DateTime, String> dailyNotes;
  final Map<DateTime, int> dailyMood;

  // Built-in Timer State
  final Duration totalTimeTracked;

  Habit({
    required this.id,
    required this.name,
    this.category = "GENERAL",
    this.priority = "MEDIUM",
    this.completionDates = const [],
    this.dailyTarget = 1,
    this.currentValue = 0.0,
    this.unit = "syncs",
    this.isTimerEnabled = false,
    this.timerMinutes,
    this.reminderTime = "09:00",
    this.scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
    this.isNotificationsEnabled = true,
    this.dailyNotes = const {},
    this.dailyMood = const {},
    this.totalTimeTracked = Duration.zero,
  });

  /// Calculates progress as a percentage (0.0 to 1.0)
  double get progressPercent =>
      dailyTarget > 0 ? (currentValue / dailyTarget).clamp(0.0, 1.0) : 0.0;

  /// Checks if this is a complex goal or a simple toggle
  bool get isQuantifiable => dailyTarget > 1 || isTimerEnabled;

  /// Total times this protocol was fully synchronized
  int get totalCompletions => completionDates.length;

  /// Checks if the protocol is scheduled for a specific day
  /// [weekday] corresponds to DateTime.weekday (1=Monday, 7=Sunday)
  bool isScheduledFor(int weekday) => scheduledDays.contains(weekday);

  /// Critical Helper: Checks if the goal was met on a specific date.
  bool isGoalMet(DateTime date) {
    return completionDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  /// Creates a copy of the habit with updated fields for immutable state updates.
  Habit copyWith({
    String? id,
    String? name,
    String? category,
    String? priority,
    List<DateTime>? completionDates,
    int? dailyTarget,
    double? currentValue,
    String? unit,
    bool? isTimerEnabled,
    int? timerMinutes,
    String? reminderTime,
    List<int>? scheduledDays,
    bool? isNotificationsEnabled,
    Map<DateTime, String>? dailyNotes,
    Map<DateTime, int>? dailyMood,
    Duration? totalTimeTracked,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      completionDates: completionDates ?? this.completionDates,
      dailyTarget: dailyTarget ?? this.dailyTarget,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      isTimerEnabled: isTimerEnabled ?? this.isTimerEnabled,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      reminderTime: reminderTime ?? this.reminderTime,
      scheduledDays: scheduledDays ?? this.scheduledDays,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
      dailyNotes: dailyNotes ?? this.dailyNotes,
      dailyMood: dailyMood ?? this.dailyMood,
      totalTimeTracked: totalTimeTracked ?? this.totalTimeTracked,
    );
  }
}
