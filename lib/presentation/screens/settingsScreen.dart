import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';

// Providers
import '../../core/services/personality_constants.dart';
import '../providers/hive_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/habit_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveProvider = context.watch<HiveProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final habitProvider = context.read<HabitProvider>();

    final Color themeColor = hiveProvider.hiveStability < 0.3
        ? Colors.redAccent
        : Colors.cyanAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlow(themeColor.withOpacity(0.1)),
          ),

          CustomScrollView(
            slivers: [
              // --- PASS CONTEXT HERE ---
              _buildAppBar(context, themeColor),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInLeft(child: _buildSectionHeader("NEURAL PERSONA")),
                      const SizedBox(height: 15),
                      _buildPersonaSelector(
                        hiveProvider,
                        notificationProvider,
                        habitProvider,
                        themeColor,
                      ),

                      const SizedBox(height: 40),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 200),
                        child: _buildSectionHeader("STEALTH PROTOCOLS"),
                      ),
                      const SizedBox(height: 15),
                      _buildStealthToggles(notificationProvider, themeColor),

                      const SizedBox(height: 40),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 400),
                        child: _buildSectionHeader("COMMANDER PROFILE"),
                      ),
                      const SizedBox(height: 15),
                      _buildProfileCard(hiveProvider, themeColor),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- UPDATED APP BAR WITH CONTEXT ---
  Widget _buildAppBar(BuildContext context, Color theme) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: true,
      title: Text(
        "CORE SETTINGS",
        style: TextStyle(
          fontFamily: 'Orbitron',
          letterSpacing: 4,
          fontSize: 14,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white54,
          size: 18,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          // RETREAT PROTOCOL: Navigates back to ProfileScreen
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'SpaceMono',
        color: Colors.white24,
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPersonaSelector(
    HiveProvider hive,
    NotificationProvider notify,
    HabitProvider habits,
    Color theme,
  ) {
    return Container(
      decoration: _glassDecoration(),
      child: Column(
        children: HandlerPersona.values.map((persona) {
          final isSelected = hive.activePersona == persona;
          return ListTile(
            onTap: () async {
              HapticFeedback.heavyImpact();
              hive.setPersona(persona);
              await notify.scheduleDailySmartNudges(habits.habits, persona);
            },
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme : Colors.white10,
              size: 18,
            ),
            title: Text(
              persona.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            trailing: isSelected
                ? Flash(child: Icon(Icons.bolt, color: theme, size: 16))
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStealthToggles(NotificationProvider notify, Color theme) {
    return Container(
      decoration: _glassDecoration(),
      child: Column(
        children: [
          _buildToggle(
            "GHOST MODE",
            "Auto-DND when tasks are critical",
            notify.isGhostModeEnabled,
            (val) => notify.toggleGhostMode(val),
            theme,
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1),
          _buildToggle(
            "STEALTH AUDIO",
            "Silence all neural blips",
            notify.isMuteEnabled,
            (val) => notify.toggleMute(val),
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    String title,
    String sub,
    bool val,
    Function(bool) onChanged,
    Color theme,
  ) {
    return SwitchListTile(
      value: val,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      activeColor: theme,
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(color: Colors.white24, fontSize: 10),
      ),
    );
  }

  Widget _buildProfileCard(HiveProvider hive, Color theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: theme.withOpacity(0.1),
            child: Icon(Icons.person, color: theme),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hive.userName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const Text(
                "RANK: SENTINEL",
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.qr_code_2, color: Colors.white24),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 50)],
      ),
    );
  }
}
