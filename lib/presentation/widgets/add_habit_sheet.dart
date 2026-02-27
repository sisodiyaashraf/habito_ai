import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/habit_provider.dart';

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

  String _selectedCategory = "CODING";
  String _selectedPriority = "MEDIUM";
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  bool _isTimerTask = false;
  int _timerMinutes = 25;
  bool _notificationsEnabled = true;

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

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      HapticFeedback.heavyImpact();

      // FIXED: Passing context as required by updated HabitProvider
      context.read<HabitProvider>().addHabit(
        name,
        dailyTarget: int.tryParse(_targetController.text) ?? 1,
        category: _selectedCategory,
        priority: _selectedPriority,
        reminderTime: _reminderTime,
        scheduledDays: _selectedDays,
        isNotificationsEnabled: _notificationsEnabled,
        isTimerEnabled: _isTimerTask,
        timerMinutes: _isTimerTask ? _timerMinutes : null,
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
            color: const Color(0xFF060912).withOpacity(0.95),
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
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 30),
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

  // --- UI COMPONENTS ---

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
            HapticFeedback.selectionClick(); // Tactile feedback
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
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
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

  // Helper builders...
  Widget _buildSectionLabel(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
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

  Widget _buildCyberTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
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
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _reminderTime.format(context),
                    style: const TextStyle(color: Colors.white38, fontSize: 9),
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
              style: TextStyle(color: Colors.cyanAccent, fontSize: 10),
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

  Widget _buildTargetInput() {
    return _buildCyberTextField(
      controller: _targetController,
      hint: "Daily Target (e.g., 5)",
      icon: Icons.track_changes_rounded,
      isNumber: true,
    );
  }

  Widget _buildTimerPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "DURATION",
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => setState(
                  () => _timerMinutes > 5 ? _timerMinutes -= 5 : null,
                ),
                icon: const Icon(Icons.remove, color: Colors.cyanAccent),
              ),
              Text(
                "$_timerMinutes MIN",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _timerMinutes += 5),
                icon: const Icon(Icons.add, color: Colors.cyanAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }

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
