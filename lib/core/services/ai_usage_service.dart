import 'package:hive_flutter/hive_flutter.dart';

class AIUsageService {
  static const String _boxName = 'ai_usage';
  static const String _dailyCountKey = 'daily_count';
  static const String _hourlyCountKey = 'hourly_count';
  static const String _lastDailyResetKey = 'last_daily_reset';
  static const String _lastHourlyResetKey = 'last_hourly_reset';

  // Conservative limits for free tier safety
  static const int dailyLimit = 50;
  static const int hourlyLimit = 15;

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
    _checkAndResetLimits();
  }

  void _checkAndResetLimits() {
    final now = DateTime.now();

    // Check Daily Reset
    final lastDailyResetStr = _box.get(_lastDailyResetKey);
    if (lastDailyResetStr == null) {
      _box.put(_lastDailyResetKey, now.toIso8601String());
      _box.put(_dailyCountKey, 0);
    } else {
      final lastDailyReset = DateTime.parse(lastDailyResetStr);
      if (now.day != lastDailyReset.day ||
          now.month != lastDailyReset.month ||
          now.year != lastDailyReset.year) {
        _box.put(_lastDailyResetKey, now.toIso8601String());
        _box.put(_dailyCountKey, 0);
      }
    }

    // Check Hourly Reset
    final lastHourlyResetStr = _box.get(_lastHourlyResetKey);
    if (lastHourlyResetStr == null) {
      _box.put(_lastHourlyResetKey, now.toIso8601String());
      _box.put(_hourlyCountKey, 0);
    } else {
      final lastHourlyReset = DateTime.parse(lastHourlyResetStr);
      if (now.difference(lastHourlyReset).inHours >= 1) {
        _box.put(_lastHourlyResetKey, now.toIso8601String());
        _box.put(_hourlyCountKey, 0);
      }
    }
  }

  bool get isLimitExceeded {
    _checkAndResetLimits();
    final dailyCount = _box.get(_dailyCountKey, defaultValue: 0);
    final hourlyCount = _box.get(_hourlyCountKey, defaultValue: 0);
    return dailyCount >= dailyLimit || hourlyCount >= hourlyLimit;
  }

  void incrementUsage() {
    _checkAndResetLimits();
    final dailyCount = _box.get(_dailyCountKey, defaultValue: 0);
    final hourlyCount = _box.get(_hourlyCountKey, defaultValue: 0);
    _box.put(_dailyCountKey, dailyCount + 1);
    _box.put(_hourlyCountKey, hourlyCount + 1);
  }

  num get dailyRemaining =>
      dailyLimit - _box.get(_dailyCountKey, defaultValue: 0);
  num get hourlyRemaining =>
      hourlyLimit - _box.get(_hourlyCountKey, defaultValue: 0);
}
