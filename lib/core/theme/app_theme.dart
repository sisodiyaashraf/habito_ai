import 'package:flutter/material.dart';

class HabitoTheme {
  // --- NEURAL NIGHT (Dark Mode) ---
  static ThemeData get darkTheme {
    const Color primary = Colors.cyanAccent;
    const Color secondary = Colors.purpleAccent;
    const Color surface = Color(0xFF0D1117);
    const Color background = Color(0xFF03050B);

    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        outline: Colors.white10,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white70),
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 14,
          color: Colors.white60,
        ),
        labelSmall: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          color: Colors.white38,
          letterSpacing: 1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary.withValues(alpha: 0.1),
          foregroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          side: const BorderSide(color: primary, width: 1),
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Orbitron', fontSize: 10),
        unselectedLabelStyle: TextStyle(fontFamily: 'Orbitron', fontSize: 10),
      ),
    );
  }

  // --- CYBER DAY (Light Mode) ---
  static ThemeData get lightTheme {
    const Color primary = Color(0xFF0EA5E9); // Vibrant Sky Blue
    const Color secondary = Color(0xFF6366F1); // Indigo
    const Color surface = Colors.white;
    const Color background = Color(0xFFF1F5F9); // Updated: Deep Slate background base
    const Color onSurface = Color(0xFF0F172A); // Deep Slate

    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: surface,
      hintColor: onSurface.withValues(alpha: 0.38),
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: Color(0xFF475569), // Slate Grey
        outline: Color(0xFFCBD5E1), // Slightly darker border for contrast
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: onSurface),
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: 2,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: onSurface,
          letterSpacing: 1,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 16,
          color: onSurface,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 14,
          color: Color(0xFF475569),
        ),
        labelSmall: TextStyle(
          fontFamily: 'SpaceMono',
          fontSize: 10,
          color: Color(0xFF64748B), // Slightly darker for better visibility
          letterSpacing: 1,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0, // Flat futuristic style
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white, // Opaque surface for navigation
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Orbitron', fontSize: 10),
        unselectedLabelStyle: TextStyle(fontFamily: 'Orbitron', fontSize: 10),
        elevation: 8,
      ),
      iconTheme: const IconThemeData(color: onSurface),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
    );
  }
}
