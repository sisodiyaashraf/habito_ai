import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_provider.dart';

class PersonaSelector extends StatelessWidget {
  const PersonaSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NEURAL PERSONALITY",
            style: TextStyle(
              color: Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPersonaChip(
                context,
                AIPersonality.gentle,
                "GENTLE",
                Colors.greenAccent,
              ),
              _buildPersonaChip(
                context,
                AIPersonality.neutral,
                "NEUTRAL",
                Colors.cyanAccent,
              ),
              _buildPersonaChip(
                context,
                AIPersonality.brutal,
                "BRUTAL",
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaChip(
    BuildContext context,
    AIPersonality persona,
    String label,
    Color color,
  ) {
    // Watch the provider to rebuild when the persona changes
    final currentPersona = context.watch<AIProvider>().currentPersona;
    final bool isSelected = currentPersona == persona;

    return GestureDetector(
      onTap: () {
        Feedback.forTap(context); // Subtle haptic feedback
        context.read<AIProvider>().setPersona(persona);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
