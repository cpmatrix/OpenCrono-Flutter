import 'package:flutter/material.dart';

class AppTheme {
  static const Color _bg = Color(0xFF0B121A);
  static const Color _surface = Color(0xFF131D28);
  static const Color _surfaceAlt = Color(0xFF1B2735);
  static const Color _accent = Color(0xFF41B6A6);

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _bg,
    colorScheme: const ColorScheme.dark(
      primary: _accent,
      secondary: Color(0xFF7BC8BD),
      surface: _surface,
      onSurface: Colors.white,
      onPrimary: Color(0xFF041014),
      onSecondary: Color(0xFF041014),
      error: Color(0xFFF07178),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _bg,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF90A4B8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: const Color(0xFF041014),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFFD7E2ED)),
    ),
  );
}
