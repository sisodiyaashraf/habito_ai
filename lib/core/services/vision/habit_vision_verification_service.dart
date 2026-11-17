import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../presentation/providers/habit_provider.dart';
import 'camera_vision_service.dart';

/// Service to analyze the real-time AI object detection stream,
/// verifying habits when target items are sustained with high confidence,
/// and throttling/debouncing to prevent double-logging.
class HabitVisionVerificationService {
  final HabitProvider habitProvider;
  final BuildContext context;
  final void Function(bool isDetecting)? onActivityStateChanged;
  final VoidCallback? onVerified;

  // Track the sustained object state
  String? _sustainedLabel;
  DateTime? _firstSeenTime;
  bool _isCooldownActive = false;
  Timer? _cooldownTimer;

  // Repetition Counting state
  double? _lastY;
  bool _isMovingDown = false;
  double _peakY = 0.0;
  double _valleyY = 0.0;
  DateTime _lastRepTime = DateTime.now();

  // Configuration thresholds
  static const double _minConfidence = 0.70;
  static const Duration _sustainedDuration = Duration(seconds: 2);
  static const Duration _debouncerCooldown = Duration(seconds: 5);

  final ValueNotifier<String> statusMessage = ValueNotifier<String>("ALIGN TARGET ITEM IN VIEWPORT");
  final ValueNotifier<double> sustainProgress = ValueNotifier<double>(0.0);

  HabitVisionVerificationService({
    required this.habitProvider,
    required this.context,
    this.onActivityStateChanged,
    this.onVerified,
  });

  /// Entry point to process fresh detection boxes.
  void analyzeDetections(List<DetectionBox> detections) {
    if (_isCooldownActive) return;

    // 1. Search for verification candidates (book, cup, bottle, home good, food, fashion, plant, object) with >_minConfidence
    DetectionBox? target;
    for (final det in detections) {
      final label = det.label.toLowerCase();
      bool isMatch = label.contains('book') ||
                     label.contains('cup') ||
                     label.contains('bottle') ||
                     label.contains('home good') ||
                     label.contains('food') ||
                     label.contains('fashion') ||
                     label.contains('plant') ||
                     label.contains('object') ||
                     label.contains('target');
      if (isMatch && det.confidence >= _minConfidence) {
        target = det;
        break; // Process the first high-confidence match
      }
    }

    // Try to find if the user has a repetition-based physical habit
    bool isRepetitionHabit = false;
    for (final habit in habitProvider.habits) {
      final name = habit.name.toLowerCase();
      final cat = habit.category.toLowerCase();
      if (name.contains('push') || name.contains('squat') || name.contains('sit') || name.contains('rep') || name.contains('fitness') || cat.contains('fitness') || cat.contains('gym')) {
        isRepetitionHabit = true;
        break;
      }
    }

    // 2. Sustainment & Verification Logic
    if (target != null) {
      onActivityStateChanged?.call(true); // Stop alarm: User activity detected!

      if (isRepetitionHabit) {
        // Track vertical movement reps!
        final double centerY = target.y + (target.height / 2);
        if (_lastY != null) {
          final double deltaY = centerY - _lastY!;
          final timeDiff = DateTime.now().difference(_lastRepTime);

          if (deltaY > 8.0) { // Moving Down
            if (!_isMovingDown) {
              _isMovingDown = true;
              _valleyY = centerY;
            } else if (centerY > _valleyY) {
              _valleyY = centerY;
            }
          } else if (deltaY < -8.0) { // Moving Up
            if (_isMovingDown) {
              // Direction changed from down to up!
              final double amplitude = _valleyY - _peakY;
              // Check for a significant movement amplitude and ensure debouncing (min 500ms between reps)
              if (amplitude > 20.0 && timeDiff.inMilliseconds > 500) {
                _triggerRepetitionVerification();
                _lastRepTime = DateTime.now();
              }
              _isMovingDown = false;
              _peakY = centerY;
            } else if (centerY < _peakY) {
              _peakY = centerY;
            }
          }
        } else {
          _peakY = centerY;
          _valleyY = centerY;
        }
        _lastY = centerY;
      } else {
        final label = target.label.toLowerCase();
        if (_sustainedLabel == label) {
          // Already tracking this item; check sustained duration
          final elapsed = DateTime.now().difference(_firstSeenTime!);
          final double progress = (elapsed.inMilliseconds / _sustainedDuration.inMilliseconds).clamp(0.0, 1.0);
          sustainProgress.value = progress;

          statusMessage.value = "VERIFYING ${label.toUpperCase()} PROTOCOL... ${(progress * 100).toInt()}%";

          if (elapsed >= _sustainedDuration) {
            // Trigger the Habit Verified action!
            _triggerHabitVerification(label);
          }
        } else {
          // Found a new item, start the sustain stopwatch
          _sustainedLabel = label;
          _firstSeenTime = DateTime.now();
          sustainProgress.value = 0.0;
          statusMessage.value = "LOCKING ONTO ${label.toUpperCase()}...";
        }
      }
    } else {
      onActivityStateChanged?.call(false); // Restart alarm: User activity stopped!
      
      // Reset rep-tracking temp state
      _lastY = null;
      _isMovingDown = false;

      if (isRepetitionHabit) {
        // Find the active repetition habit to display correct progress
        for (final habit in habitProvider.habits) {
          final name = habit.name.toLowerCase();
          final cat = habit.category.toLowerCase();
          if (name.contains('push') || name.contains('squat') || name.contains('sit') || name.contains('rep') || name.contains('fitness') || cat.contains('fitness') || cat.contains('gym')) {
            final double progress = (habit.currentValue / habit.dailyTarget).clamp(0.0, 1.0);
            sustainProgress.value = progress;
            statusMessage.value = "ALIGN USER IN CAMERA: ${habit.currentValue.toInt()} / ${habit.dailyTarget} REPS";
            break;
          }
        }
      } else {
        _sustainedLabel = null;
        _firstSeenTime = null;
        sustainProgress.value = 0.0;
        statusMessage.value = "ALIGN TARGET ITEM IN VIEWPORT";
      }
    }
  }

  void _triggerRepetitionVerification() async {
    // Find the repetition habit
    String? matchedHabitId;
    for (final habit in habitProvider.habits) {
      final name = habit.name.toLowerCase();
      final cat = habit.category.toLowerCase();
      if (name.contains('push') || name.contains('squat') || name.contains('sit') || name.contains('rep') || name.contains('fitness') || cat.contains('fitness') || cat.contains('gym')) {
        matchedHabitId = habit.id;
        break;
      }
    }

    if (matchedHabitId == null && habitProvider.habits.isNotEmpty) {
      matchedHabitId = habitProvider.habits.first.id;
    }

    if (matchedHabitId != null) {
      final habit = habitProvider.habits.firstWhere((h) => h.id == matchedHabitId);
      final double newValue = habit.currentValue + 1;

      // Vibrate to confirm rep
      HapticFeedback.lightImpact();

      await habitProvider.updateHabitProgress(matchedHabitId, newValue, context);

      // Calculate progress percentage
      final double progress = (newValue / habit.dailyTarget).clamp(0.0, 1.0);
      sustainProgress.value = progress;
      statusMessage.value = "REP DETECTED: ${newValue.toInt()} / ${habit.dailyTarget} (${(progress * 100).toInt()}%)";

      if (newValue >= habit.dailyTarget) {
        onVerified?.call(); // Alarm off permanently, victory chime, navigate pop!
      }
    }
  }

  /// Locate the respective habit model and verify progress in database.
  void _triggerHabitVerification(String itemLabel) async {
    _isCooldownActive = true;
    sustainProgress.value = 1.0;
    statusMessage.value = "VERIFIED! DOWNLINKING PROGRESS...";

    // Map item type to specific category/name habits in the local DB/Provider
    String targetCategory = "GENERAL";
    String actionName = "Visual Verification";

    if (itemLabel.contains('book')) {
      targetCategory = "READING";
      actionName = "Read Book";
    } else if (itemLabel.contains('cup') || itemLabel.contains('bottle') || itemLabel.contains('food')) {
      targetCategory = "HYDRATION";
      actionName = "Hydrate";
    }

    debugPrint("HabitVisionVerificationService: Triggering action $actionName");

    // Attempt to locate a matching habit in the local provider state
    String? matchedHabitId;
    for (final habit in habitProvider.habits) {
      if (habit.category.toUpperCase() == targetCategory ||
          habit.name.toLowerCase().contains(itemLabel) ||
          (targetCategory == "GENERAL" && habitProvider.habits.length == 1)) {
        matchedHabitId = habit.id;
        break;
      }
    }

    // If no matching habit exists, default to the first one available or log a general success
    if (matchedHabitId == null && habitProvider.habits.isNotEmpty) {
      matchedHabitId = habitProvider.habits.first.id;
    }

    if (matchedHabitId != null) {
      // 3. Update the local counter state safely via habitProvider
      final habit = habitProvider.habits.firstWhere((h) => h.id == matchedHabitId);
      final double newValue = habit.currentValue + 1;
      
      // Update either partial progress or trigger full verification
      await habitProvider.updateHabitProgress(matchedHabitId, newValue, context);
      onVerified?.call();
    }

    // Reset sustain states
    _sustainedLabel = null;
    _firstSeenTime = null;

    // Start Cooldown / Debouncer Timer to prevent multiple logs in succession
    _cooldownTimer = Timer(_debouncerCooldown, () {
      _isCooldownActive = false;
      sustainProgress.value = 0.0;
      statusMessage.value = "SYSTEM LOCKED. ALIGN NEXT ITEM.";
    });
  }

  void dispose() {
    _cooldownTimer?.cancel();
  }
}
