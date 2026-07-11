import 'package:flutter_test/flutter_test.dart';
import 'package:habito_ai/data/models/habit_model.dart';
import 'package:habito_ai/domain/entities/habit.dart';

void main() {
  group('HabitModel Serialization Tests', () {
    test('HabitModel should correctly serialize and deserialize all fields', () {
      final today = DateTime(2026, 6, 16);
      final habit = HabitModel(
        id: '1',
        name: 'Test Habit',
        dailyNotes: {today: 'Note 1'},
        dailyMood: {today: 5},
        totalTimeTracked: const Duration(minutes: 30),
      );

      final json = habit.toJson();
      
      expect(json['dailyNotes'], isA<Map>());
      expect(json['dailyNotes'][today.toIso8601String()], 'Note 1');
      expect(json['dailyMood'][today.toIso8601String()], 5);
      expect(json['totalTimeTracked'], 1800);

      final decoded = HabitModel.fromJson(json);

      expect(decoded.dailyNotes[today], 'Note 1');
      expect(decoded.dailyMood[today], 5);
      expect(decoded.totalTimeTracked.inMinutes, 30);
      expect(decoded.name, 'Test Habit');
    });
  });
}
