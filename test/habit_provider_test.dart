import 'package:flutter_test/flutter_test.dart';
import 'package:habito_ai/domain/entities/habit.dart';
import 'package:habito_ai/presentation/providers/habit_provider.dart';
import 'package:habito_ai/domain/repositories/habit_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive_test/hive_test.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

void main() {
  late HabitProvider habitProvider;
  late MockHabitRepository mockHabitRepository;

  setUp(() async {
    await setUpTestHive();
    mockHabitRepository = MockHabitRepository();
    habitProvider = HabitProvider(habitRepository: mockHabitRepository);
    
    // Stub for saveHabit
    registerFallbackValue(Habit(id: 'fake', name: 'fake'));
    when(() => mockHabitRepository.saveHabit(any())).thenAnswer((_) async => {});
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  group('HabitProvider Tests', () {
    test('loadHabits should load habits from repository', () async {
      final habits = [
        Habit(id: '1', name: 'Test Habit', category: 'CODING'),
      ];
      when(() => mockHabitRepository.getAllHabits()).thenAnswer((_) async => habits);

      await habitProvider.loadHabits();

      expect(habitProvider.habits.length, 1);
      expect(habitProvider.habits.first.name, 'Test Habit');
    });

    test('logReflection should update habit and save', () async {
      final habit = Habit(id: '1', name: 'Test Habit');
      when(() => mockHabitRepository.getAllHabits()).thenAnswer((_) async => [habit]);
      
      await habitProvider.loadHabits();
      await habitProvider.logReflection('1', 'Feeling good', 4);

      verify(() => mockHabitRepository.saveHabit(any())).called(1);
      final updatedHabit = habitProvider.habits.first;
      expect(updatedHabit.dailyNotes.values.contains('Feeling good'), true);
      expect(updatedHabit.dailyMood.values.contains(4), true);
    });
  });
}
