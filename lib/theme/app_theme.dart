import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Direct color constants to avoid nullable map lookup errors (e.g., Colors.grey[900])
  static const Color _primary = Color(0xFF2563EB);
  static const Color _surface = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(
    0xFF111827,
  ); // Equivalent to grey[900]
  static const Color _textSecondary = Color(
    0xFF4B5563,
  ); // Equivalent to grey[600]
  static const Color _textTertiary = Color(
    0xFF6B7280,
  ); // Equivalent to grey[500]
  static const Color _borderColor = Color(
    0xFFD1D5DB,
  ); // Equivalent to grey[300]
  static const Color _chipBg = Color(0xFFF3F4F6); // Equivalent to grey[100]
  static const Color _dividerColor = Color(
    0xFFE5E7EB,
  ); // Equivalent to grey[200]

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: _surface,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _textPrimary,
      elevation: 0,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _borderColor, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: _borderColor),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _chipBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textSecondary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _textSecondary),
      bodyMedium: TextStyle(fontSize: 14, color: _textSecondary),
      bodySmall: TextStyle(fontSize: 12, color: _textTertiary),
    ),

    dividerTheme: const DividerThemeData(
      color: _dividerColor,
      thickness: 1,
      space: 1,
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    iconTheme: const IconThemeData(color: _textSecondary, size: 24),
  );
}
