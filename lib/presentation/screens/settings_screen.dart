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
import '../providers/ai_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hiveProvider = context.watch<HiveProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final aiProvider = context.watch<AIProvider>();
    final habitProvider = context.read<HabitProvider>();

    final Color themeColor = hiveProvider.hiveStability < 0.3
        ? Colors.redAccent
        : Colors.cyanAccent;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      FadeInLeft(child: _buildSectionHeader(context, "NEURAL PERSONA")),
                      const SizedBox(height: 15),
                      _buildPersonaSelector(
                        context,
                        hiveProvider,
                        notificationProvider,
                        habitProvider,
                        themeColor,
                      ),

                      FadeInLeft(
                        delay: const Duration(milliseconds: 200),
                        child: _buildSectionHeader(context, "SYSTEM THEME"),
                      ),
                      const SizedBox(height: 15),
                      _buildThemeSelector(context, hiveProvider, themeColor),

                      const SizedBox(height: 40),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 300),
                        child: _buildSectionHeader(context, "STEALTH PROTOCOLS"),
                      ),
                      const SizedBox(height: 15),
                      _buildStealthToggles(context, notificationProvider, themeColor),

                      const SizedBox(height: 40),
                      FadeInLeft(
                        delay: const Duration(milliseconds: 400),
                        child: _buildSectionHeader(context, "COMMANDER PROFILE"),
                      ),
                      const SizedBox(height: 15),
                      _buildProfileCard(context, hiveProvider, themeColor),

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
    final themeData = Theme.of(context);
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
          color: themeData.colorScheme.onSurface.withOpacity(0.9),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: themeData.colorScheme.onSurface.withOpacity(0.54),
          size: 18,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'SpaceMono',
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.24),
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPersonaSelector(
    BuildContext context,
    HiveProvider hive,
    NotificationProvider notify,
    HabitProvider habits,
    Color themeColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: _glassDecoration(context),
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
              color: isSelected ? themeColor : theme.colorScheme.onSurface.withOpacity(0.1),
              size: 18,
            ),
            title: Text(
              persona.name.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.38),
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            trailing: isSelected
                ? Flash(child: Icon(Icons.bolt, color: themeColor, size: 16))
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStealthToggles(BuildContext context, NotificationProvider notify, Color themeColor) {
    return Container(
      decoration: _glassDecoration(context),
      child: Column(
        children: [
          _buildToggle(
            context,
            "GHOST MODE",
            "Auto-DND when tasks are critical",
            notify.isGhostModeEnabled,
            (val) => notify.toggleGhostMode(val),
            themeColor,
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), height: 1),
          _buildToggle(
            context,
            "STEALTH MODE",
            "UI cloaking for focus operations",
            notify.isStealthModeEnabled,
            (val) => notify.toggleStealthMode(val),
            themeColor,
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), height: 1),
          _buildToggle(
            context,
            "STEALTH AUDIO",
            "Silence all neural blips",
            notify.isMuteEnabled,
            (val) => notify.toggleMute(val),
            themeColor,
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(
    BuildContext context,
    String title,
    String sub,
    bool val,
    Function(bool) onChanged,
    Color themeColor,
  ) {
    final theme = Theme.of(context);
    return SwitchListTile(
      value: val,
      onChanged: (v) {
        HapticFeedback.selectionClick();
        onChanged(v);
      },
      activeColor: themeColor,
      title: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        sub,
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.24), fontSize: 10),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, HiveProvider hive, Color themeColor) {
    final theme = Theme.of(context);
    final ai = context.watch<AIProvider>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: themeColor.withOpacity(0.1),
            backgroundImage: ai.userImagePath.isNotEmpty ? AssetImage(ai.userImagePath) : null,
            child: ai.userImagePath.isEmpty
                ? Icon(Icons.person, color: themeColor)
                : null,
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hive.userName.toUpperCase(),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                "RANK: SENTINEL",
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.24),
                  fontSize: 10,
                  fontFamily: 'SpaceMono',
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.qr_code_2, color: theme.colorScheme.onSurface.withOpacity(0.24)),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, HiveProvider hive, Color themeColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: _glassDecoration(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hive.isDarkMode ? "NEURAL NIGHT" : "CYBER DAY",
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hive.isDarkMode ? "OPTIMIZED FOR LOW-LIGHT SYNC" : "MAX VISIBILITY PROTOCOL",
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.24), fontSize: 8),
              ),
            ],
          ),
          
          GestureDetector(
            onTap: hive.toggleDarkMode,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 70,
              height: 35,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: hive.isDarkMode ? Colors.black26 : Colors.blueAccent.withOpacity(0.1),
                border: Border.all(
                  color: hive.isDarkMode ? Colors.white10 : Colors.blueAccent.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 400),
                    alignment: hive.isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hive.isDarkMode ? Colors.cyanAccent : Colors.amberAccent,
                        boxShadow: [
                          BoxShadow(
                            color: (hive.isDarkMode ? Colors.cyanAccent : Colors.amberAccent).withOpacity(0.4),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Icon(
                        hive.isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
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
