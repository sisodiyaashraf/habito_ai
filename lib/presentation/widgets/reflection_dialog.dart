import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';

class ReflectionDialog extends StatefulWidget {
  final String habitId;
  const ReflectionDialog({super.key, required this.habitId});

  @override
  State<ReflectionDialog> createState() => _ReflectionDialogState();
}

class _ReflectionDialogState extends State<ReflectionDialog> {
  int _selectedMood = 3; // Neutral default
  final TextEditingController _noteController = TextEditingController();

  final List<IconData> _moodIcons = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Text(
        "NEURAL REFLECTION",
        style: TextStyle(
          color: Colors.cyanAccent,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Current Neural State:",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              5,
              (index) => IconButton(
                icon: Icon(
                  _moodIcons[index],
                  color: _selectedMood == index + 1
                      ? Colors.cyanAccent
                      : Colors.white24,
                ),
                onPressed: () => setState(() => _selectedMood = index + 1),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Enter protocol notes...",
              hintStyle: const TextStyle(color: Colors.white10),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<HabitProvider>().logReflection(
              widget.habitId,
              _noteController.text,
              _selectedMood,
            );
            Navigator.pop(context);
          },
          child: const Text(
            "SYNC REFLECTION",
            style: TextStyle(color: Colors.cyanAccent),
          ),
        ),
      ],
    );
  }
}
