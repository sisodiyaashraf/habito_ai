import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  HabitModel({
    required String id,
    required String name,
    List<DateTime> completionDates = const [],
    int dailyTarget = 1,
  }) : super(
         id: id,
         name: name,
         completionDates: completionDates,
         dailyTarget: dailyTarget,
       );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'completionDates': completionDates.map((e) => e.toIso8601String()).toList(),
    'dailyTarget': dailyTarget,
  };

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'],
      name: json['name'],
      completionDates: (json['completionDates'] as List)
          .map((e) => DateTime.parse(e))
          .toList(),
      dailyTarget: json['dailyTarget'],
    );
  }
}
