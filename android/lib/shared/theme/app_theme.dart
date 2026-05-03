import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // brand colors
  static const _primary   = Color(0xFF2D6A4F);  // deep green
  static const _secondary = Color(0xFF40916C);
  static const _accent    = Color(0xFF52B788);
  static const _error     = Color(0xFFE63946);
  static const _warning   = Color(0xFFF4A261);
  static const _surface   = Color(0xFFF8F9FA);
  static const _onPrimary = Color(0xFFFFFFFF);

  static final light = ThemeData(
    useMaterial3:     true,
    colorScheme:      ColorScheme.fromSeed(
      seedColor:      _primary,
      brightness:     Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _primary,
      foregroundColor: _onPrimary,
      elevation:       0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: _onPrimary,
        minimumSize:     const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled:    true,
      fillColor: _surface,
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );

  static final dark = ThemeData(
    useMaterial3: true,
    colorScheme:  ColorScheme.fromSeed(
      seedColor:  _primary,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        minimumSize:     const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
