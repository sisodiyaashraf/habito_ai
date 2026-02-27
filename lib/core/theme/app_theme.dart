import 'package:flutter/material.dart';

class HabitoTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0A0E21),
      primaryColor: Colors.cyanAccent,
      colorScheme: const ColorScheme.dark(
        primary: Colors.cyanAccent,
        secondary: Colors.purpleAccent,
        surface: Color(0xFF1D1E33),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
      ),
      // Modern Glassmorphism-style buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent.withOpacity(0.2),
          foregroundColor: Colors.cyanAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
