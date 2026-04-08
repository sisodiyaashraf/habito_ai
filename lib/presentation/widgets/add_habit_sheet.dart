import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';
import '../providers/ai_provider.dart';

class AddHabitSheet extends StatefulWidget {
  const AddHabitSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black87,
      builder: (context) => const AddHabitSheet(),
    );
  }

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController(
    text: "1",
  );
  final TextEditingController _customTimerController = TextEditingController();

  String _selectedCategory = "CODING";
  String _selectedPriority = "MEDIUM";
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  final List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];

  bool _isTimerTask = false;
  bool _isCustomTimer = false;
  int _timerMinutes = 25;
  final bool _notificationsEnabled = true;

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
    _targetController.dispose();
    _customTimerController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      HapticFeedback.heavyImpact();

      // Resolve final timer value based on selection mode
      int finalMinutes = _timerMinutes;
      if (_isTimerTask && _isCustomTimer) {
        finalMinutes =
            int.tryParse(_customTimerController.text) ?? _timerMinutes;
      }

      context.read<HabitProvider>().addHabit(
        name,
        dailyTarget: int.tryParse(_targetController.text) ?? 1,
        category: _selectedCategory,
        priority: _selectedPriority,
        reminderTime: _reminderTime,
        scheduledDays: _selectedDays,
        isNotificationsEnabled: _notificationsEnabled,
        isTimerEnabled: _isTimerTask,
        timerMinutes: _isTimerTask ? finalMinutes : null,
        context: context,
      );

      Navigator.pop(context);
    } else {
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF03050B),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border: Border.all(color: Colors.cyanAccent.withOpacity(0.15)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                _buildHandleBar(),
                const Text(
                  "PROTOCOL INITIALIZATION",
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAISuggestButton(),
                const SizedBox(height: 20),
                _buildCyberTextField(
                  controller: _nameController,
                  hint: "Protocol Label (e.g., Deep Work)",
                  icon: Icons.rocket_launch_rounded,
                ),
                const SizedBox(height: 25),
                _buildSectionLabel("NEURAL DOMAIN"),
                _buildCategoryGrid(),
                const SizedBox(height: 25),
                _buildSectionLabel("PRIORITY LEVEL"),
                _buildPrioritySelector(),
                const SizedBox(height: 25),
                _buildNotificationModule(),
                const SizedBox(height: 25),
                _buildSectionLabel("SCHEDULED DAYS"),
                _buildDaySelector(),
                const SizedBox(height: 30),
                _buildTaskModeToggle(),
                const SizedBox(height: 25),
                _isTimerTask ? _buildTimerPicker() : _buildTargetInput(),
                const SizedBox(height: 40),
                _buildInitializeButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- REVERSE TIME PRESETS & CUSTOM INPUT ---
  Widget _buildTimerPicker() {
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
                label: "CUSTOM",
                isSelected: _isCustomTimer,
                activeColor: Colors.purpleAccent,
                onTap: () => setState(() => _isCustomTimer = true),
              ),
            ],
          ),
        ),
        if (_isCustomTimer)
          FadeInDown(
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildCyberTextField(
                controller: _customTimerController,
                hint: "Enter custom minutes...",
                icon: Icons.edit_calendar_rounded,
                isNumber: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = Colors.cyanAccent,
  }) {
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
              ? activeColor.withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : Colors.white10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            color: isSelected ? activeColor : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- REMAINING UI COMPONENTS ---

  Widget _buildAISuggestButton() {
    final ai = context.watch<AIProvider>();
    final habitProvider = context.read<HabitProvider>();
    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();
        final suggestion = await ai.generateHabitSuggestion(
          habitProvider.currentLevel,
        );
        final cleanName = suggestion
            .split(':')
            .first
            .replaceAll('"', '')
            .trim();
        setState(() => _nameController.text = cleanName);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ai.isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyanAccent,
                ),
              )
            else
              const Icon(
                Icons.psychology_alt_rounded,
                color: Colors.cyanAccent,
                size: 16,
              ),
            const SizedBox(width: 10),
            const Text(
              "AI SUGGEST PROTOCOL",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.cyanAccent,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.2,
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
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.cyanAccent.withOpacity(0.1)
                  : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? Colors.cyanAccent : Colors.white10,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'],
                  size: 14,
                  color: selected ? Colors.cyanAccent : Colors.white24,
                ),
                const SizedBox(width: 8),
                Text(
                  cat['name'],
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: selected ? Colors.white : Colors.white24,
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

  Widget _buildPrioritySelector() {
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
                    ? Colors.cyanAccent.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? Colors.cyanAccent : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  p,
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    color: selected ? Colors.cyanAccent : Colors.white24,
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

  Widget _buildNotificationModule() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: Colors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "REMINDER UPLINK",
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _reminderTime.format(context),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          TextButton(
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
              );
              if (picked != null) setState(() => _reminderTime = picked);
            },
            child: const Text(
              "SET TIME",
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: Colors.cyanAccent,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        int dayNum = index + 1;
        bool selected = _selectedDays.contains(dayNum);
        return GestureDetector(
          onTap: () {
            setState(() {
              selected
                  ? _selectedDays.remove(dayNum)
                  : _selectedDays.add(dayNum);
            });
          },
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Colors.cyanAccent : Colors.transparent,
              border: Border.all(
                color: selected ? Colors.cyanAccent : Colors.white10,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  color: selected ? Colors.black : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTaskModeToggle() {
    return Row(
      children: [
        _modeBtn("QUANTITY", Icons.numbers, !_isTimerTask),
        const SizedBox(width: 15),
        _modeBtn("TIMER", Icons.timer_outlined, _isTimerTask),
      ],
    );
  }

  Widget _modeBtn(String label, IconData icon, bool selected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isTimerTask = label == "TIMER"),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? Colors.cyanAccent : Colors.white10,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.cyanAccent : Colors.white24,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: selected ? Colors.white : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(
        fontFamily: 'SpaceMono',
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white10),
        prefixIcon: Icon(icon, color: Colors.cyanAccent, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.02),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }

  Widget _buildTargetInput() {
    return _buildCyberTextField(
      controller: _targetController,
      hint: "Daily Target (e.g., 5)",
      icon: Icons.track_changes_rounded,
      isNumber: true,
    );
  }

  Widget _buildSectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white24,
          fontSize: 8,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
  Widget _buildHandleBar() => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(bottom: 25),
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(10),
    ),
  );
  Widget _buildInitializeButton() {
    return FadeInUp(
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
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
