import '../entities/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<void> saveHabit(Habit habit);
  Future<void> deleteHabit(String id);
}
