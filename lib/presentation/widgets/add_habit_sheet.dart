import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/hive_provider.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Theme.of(context).colorScheme.shadow.withOpacity(0.5),
      builder: (context) => const AddHabitSheet(),
    );
  }

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customTimerController = TextEditingController();
  final TextEditingController _customCountController = TextEditingController();

  String _selectedCategory = "CODING";
  String _selectedPriority = "MEDIUM";
  TimeOfDay _reminderTime = TimeOfDay.now();
  final List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  bool _notificationsEnabled = true;
  bool _isTimerMode = true; // true = Timer Duration, false = Target Count
  bool _isSubmitting = false;

  bool _isCustomTimer = false;
  int _timerMinutes = 25;

  bool _isCustomCount = false;
  int _targetCount = 1;

  final List<Map<String, dynamic>> _categories = [
    {"name": "CODING", "icon": Icons.code_rounded},
    {"name": "MEDITATION", "icon": Icons.self_improvement_rounded},
    {"name": "SPORTS", "icon": Icons.fitness_center_rounded},
    {"name": "STUDY", "icon": Icons.menu_book_rounded},
    {"name": "SLEEP", "icon": Icons.bedtime_rounded},
    {"name": "LEARNING", "icon": Icons.psychology_rounded},
    {"name": "SKILLS", "icon": Icons.bolt_rounded},
    {"name": "HOBBY", "icon": Icons.palette_rounded},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customTimerController.dispose();
    _customCountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "ERROR: Protocol Label required.",
            style: TextStyle(fontFamily: 'SpaceMono', fontSize: 11),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    try {
      int finalDailyTarget = 1;
      int? finalTimerMinutes;

      if (_isTimerMode) {
        int minutes = _timerMinutes;
        if (_isCustomTimer) {
          minutes = int.tryParse(_customTimerController.text) ?? _timerMinutes;
        }
        if (minutes <= 0) minutes = 15;
        finalTimerMinutes = minutes;
        finalDailyTarget = minutes;
      } else {
        int count = _targetCount;
        if (_isCustomCount) {
          count = int.tryParse(_customCountController.text) ?? _targetCount;
        }
        if (count <= 0) count = 1;
        finalDailyTarget = count;
        finalTimerMinutes = null;
      }

      List<int> daysToSave = _selectedDays.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : List.from(_selectedDays);

      final habitProvider = context.read<HabitProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      final hiveProvider = context.read<HiveProvider>();

      await habitProvider.addHabit(
        name,
        description: description,
        dailyTarget: finalDailyTarget,
        category: _selectedCategory,
        priority: _selectedPriority,
        reminderTime: _reminderTime,
        scheduledDays: daysToSave,
        isNotificationsEnabled: _notificationsEnabled,
        isTimerEnabled: _isTimerMode,
        timerMinutes: finalTimerMinutes,
        context: context,
      );

      final reminderStr = _reminderTime.format(context);

      // 1. Instantly trigger a push notification confirming task creation!
      if (_notificationsEnabled) {
        await notificationProvider.showTaskCreatedNotification(
          name,
          reminderStr,
          hiveProvider.activePersona,
        );
      }

      // 2. Pop modal immediately for zero UI lag
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "PROTOCOL INITIALIZED & UPLINK SYNCED [$reminderStr]",
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 11, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }

      // 3. Recalibrate full neural schedule asynchronously in background without blocking UI
      notificationProvider.scheduleDailySmartNudges(
        habitProvider.habits,
        hiveProvider.activePersona,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "UPLINK ERROR: Failed to initialize protocol: $e",
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 10),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                _buildHandleBar(theme),
                Text(
                  "PROTOCOL INITIALIZATION",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAISuggestButton(theme),
                const SizedBox(height: 20),
                _buildCyberTextField(
                  context,
                  controller: _nameController,
                  hint: "Protocol Label (e.g., Deep Work)",
                  icon: Icons.rocket_launch_rounded,
                ),
                const SizedBox(height: 12),
                _buildCyberTextField(
                  context,
                  controller: _descriptionController,
                  hint: "Mission Briefing (Optional Description)",
                  icon: Icons.description_rounded,
                ),
                const SizedBox(height: 22),
                _buildSectionLabel(theme, "NEURAL DOMAIN"),
                _buildCategoryGrid(theme),
                const SizedBox(height: 22),
                _buildSectionLabel(theme, "PRIORITY LEVEL"),
                _buildPrioritySelector(theme),
                const SizedBox(height: 22),
                _buildSectionLabel(theme, "REMINDER UPLINK & TIME"),
                _buildNotificationModule(theme),
                const SizedBox(height: 22),
                _buildSectionLabel(theme, "SCHEDULED DAYS"),
                _buildDaySelector(theme),
                const SizedBox(height: 25),
                _buildSectionLabel(theme, "PROTOCOL EXECUTION MODE"),
                _buildModeSelector(theme),
                const SizedBox(height: 16),
                if (_isTimerMode) _buildTimerPicker(theme) else _buildCountPicker(theme),
                const SizedBox(height: 35),
                _buildInitializeButton(theme),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isTimerMode = true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _isTimerMode
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.surface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isTimerMode
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: _isTimerMode ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 16,
                    color: _isTimerMode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TIMER DURATION",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: _isTimerMode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isTimerMode = false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: !_isTimerMode
                    ? theme.colorScheme.secondary.withOpacity(0.15)
                    : theme.colorScheme.surface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: !_isTimerMode
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outline.withOpacity(0.3),
                  width: !_isTimerMode ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ads_click_rounded,
                    size: 16,
                    color: !_isTimerMode
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "TARGET COUNT",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: !_isTimerMode
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerPicker(ThemeData theme) {
    final List<int> presets = [15, 25, 45, 60];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...presets.map((time) {
                bool isSelected = _timerMinutes == time && !_isCustomTimer;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildTimeChip(
                    theme,
                    label: "$time MIN",
                    isSelected: isSelected,
                    onTap: () => setState(() {
                      _timerMinutes = time;
                      _isCustomTimer = false;
                    }),
                  ),
                );
              }),
              _buildTimeChip(
                theme,
                label: "CUSTOM",
                isSelected: _isCustomTimer,
                activeColor: theme.colorScheme.secondary,
                onTap: () => setState(() => _isCustomTimer = true),
              ),
            ],
          ),
        ),
        if (_isCustomTimer)
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildCyberTextField(
                context,
                controller: _customTimerController,
                hint: "Enter custom duration in minutes...",
                icon: Icons.edit_calendar_rounded,
                isNumber: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountPicker(ThemeData theme) {
    final List<int> presets = [1, 3, 5, 10];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...presets.map((count) {
                bool isSelected = _targetCount == count && !_isCustomCount;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildTimeChip(
                    theme,
                    label: "$count SYNCS",
                    isSelected: isSelected,
                    activeColor: theme.colorScheme.secondary,
                    onTap: () => setState(() {
                      _targetCount = count;
                      _isCustomCount = false;
                    }),
                  ),
                );
              }),
              _buildTimeChip(
                theme,
                label: "CUSTOM",
                isSelected: _isCustomCount,
                activeColor: theme.colorScheme.secondary,
                onTap: () => setState(() => _isCustomCount = true),
              ),
            ],
          ),
        ),
        if (_isCustomCount)
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildCyberTextField(
                context,
                controller: _customCountController,
                hint: "Enter custom target completions...",
                icon: Icons.tune_rounded,
                isNumber: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeChip(
    ThemeData theme, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : theme.colorScheme.onSurface.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: isSelected ? color : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildAISuggestButton(ThemeData theme) {
    final ai = context.watch<AIProvider>();
    final habitProvider = context.read<HabitProvider>();
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final suggestionJson = await ai.generateHabitSuggestion(
          habitProvider.currentLevel,
        );

        try {
          final Map<String, dynamic> data = jsonDecode(suggestionJson);
          setState(() {
            _nameController.text = data['name'] ?? "";
            if (data['description'] != null) {
              _descriptionController.text = data['description'];
            }
            _selectedCategory = (data['category'] ?? "CODING").toUpperCase();
            _selectedPriority = (data['priority'] ?? "MEDIUM").toUpperCase();
            _isTimerMode = true;
            _timerMinutes = 25; 
            _isCustomTimer = false;
          });

          if (mounted && data['justification'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("AI BRIEFING: ${data['justification']}"),
                backgroundColor: theme.colorScheme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (e) {
          final cleanName = suggestionJson
              .split(':')
              .first
              .replaceAll('"', '')
              .replaceAll('{', '')
              .replaceAll('}', '')
              .trim();
          setState(() {
            _nameController.text = cleanName.length > 20 ? "Deep Focus" : cleanName;
            _timerMinutes = 25;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          boxShadow: [
            if (ai.isLoading)
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ai.isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            else
              Icon(
                Icons.psychology_alt_rounded,
                color: theme.colorScheme.primary,
                size: 16,
              ),
            const SizedBox(width: 10),
            Text(
              ai.isLoading ? "ANALYZING NEURAL DATA..." : "AI SUGGEST PROTOCOL",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: theme.colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.0,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        bool selected = _selectedCategory == cat['name'];
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedCategory = cat['name']);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withOpacity(0.12)
                  : theme.colorScheme.surface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.outline.withOpacity(0.15),
                width: selected ? 2 : 1,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: -2,
                  )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'],
                  size: selected ? 18 : 15,
                  color: selected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
                ),
                const SizedBox(width: 8),
                Text(
                  cat['name'],
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: selected 
                      ? theme.colorScheme.onSurface 
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrioritySelector(ThemeData theme) {
    final priorities = ["LOW", "MEDIUM", "HIGH"];
    return Row(
      children: priorities.map((p) {
        bool selected = _selectedPriority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedPriority = p);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  p,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotificationModule(ThemeData theme) {
    final timeFormatted = _reminderTime.format(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _notificationsEnabled
            ? theme.colorScheme.primary.withOpacity(0.05)
            : theme.colorScheme.surface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _notificationsEnabled
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: _notificationsEnabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "REMINDER UPLINK",
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              color: theme.colorScheme.onSurface,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _notificationsEnabled
                                ? "DAILY AT $timeFormatted"
                                : "UPLINK DISABLED",
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              color: _notificationsEnabled
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Switch.adaptive(
                value: _notificationsEnabled,
                activeTrackColor: theme.colorScheme.primary,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _notificationsEnabled = val);
                },
              ),
            ],
          ),
          if (_notificationsEnabled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, thickness: 0.5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "SPECIFIC ALARM TIME:",
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(Icons.access_time_rounded, size: 14, color: theme.colorScheme.primary),
                  label: Text(
                    "SET ($timeFormatted)",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: theme.colorScheme.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDaySelector(ThemeData theme) {
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            int dayNum = index + 1;
            bool selected = _selectedDays.contains(dayNum);
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  selected
                      ? _selectedDays.remove(dayNum)
                      : _selectedDays.add(dayNum);
                });
              },
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? theme.colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    days[index],
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShortcutPill(theme, "ALL DAYS", () {
              setState(() {
                _selectedDays.clear();
                _selectedDays.addAll([1, 2, 3, 4, 5, 6, 7]);
              });
            }),
            const SizedBox(width: 8),
            _buildShortcutPill(theme, "WEEKDAYS", () {
              setState(() {
                _selectedDays.clear();
                _selectedDays.addAll([1, 2, 3, 4, 5]);
              });
            }),
            const SizedBox(width: 8),
            _buildShortcutPill(theme, "WEEKENDS", () {
              setState(() {
                _selectedDays.clear();
                _selectedDays.addAll([6, 7]);
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildShortcutPill(ThemeData theme, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCyberTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        fontFamily: 'SpaceMono',
        color: theme.colorScheme.onSurface,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3), fontSize: 12),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 18),
        filled: true,
        fillColor: theme.colorScheme.surface.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Orbitron',
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontSize: 9,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  Widget _buildHandleBar(ThemeData theme) => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: theme.colorScheme.outline.withOpacity(0.3),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  Widget _buildInitializeButton(ThemeData theme) {
    return FadeInUp(
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.25),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "INITIALIZING...",
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : const Text(
                  "INITIALIZE PROTOCOL",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }
}
