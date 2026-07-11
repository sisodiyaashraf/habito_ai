import 'package:hive/hive.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../models/habit_model.dart';

class HabitRepositoryImpl implements HabitRepository {
  final String _boxName = 'habito_box';

  @override
  Future<List<Habit>> getAllHabits() async {
    final box = await Hive.openBox(_boxName);
    // Convert Hive dynamic list to List<Habit>
    return box.values
        .map((item) => HabitModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> saveHabit(Habit habit) async {
    final box = await Hive.openBox(_boxName);
    final model = HabitModel(
      id: habit.id,
      name: habit.name,
      description: habit.description,
      completionDates: habit.completionDates,
      ignoredDates: habit.ignoredDates,
      dailyTarget: habit.dailyTarget,
      category: habit.category,
      priority: habit.priority,
      unit: habit.unit,
      currentValue: habit.currentValue,
      isTimerEnabled: habit.isTimerEnabled,
      timerMinutes: habit.timerMinutes,
      reminderTime: habit.reminderTime,
      scheduledDays: habit.scheduledDays,
      isNotificationsEnabled: habit.isNotificationsEnabled,
      dailyNotes: habit.dailyNotes,
      dailyMood: habit.dailyMood,
      totalTimeTracked: habit.totalTimeTracked,
    );
    await box.put(habit.id, model.toJson());
  }

  @override
  Future<void> deleteHabit(String id) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(id);
  }

  @override
  Future<void> clearAllHabits() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
