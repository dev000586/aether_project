// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

/// Centralized theme definition.
/// Dark futuristic MMORPG aesthetic — deep navy + electric cyan + ember amber.
class AppTheme {
  AppTheme._();

  // Core palette
  static const Color backgroundDeep = Color(0xFF06080F);
  static const Color backgroundCard = Color(0xFF0D1117);
  static const Color backgroundElevated = Color(0xFF161B22);
  static const Color borderSubtle = Color(0xFF21262D);
  static const Color borderActive = Color(0xFF30363D);

  // Primary accent — electric cyan
  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentCyanDim = Color(0xFF0891B2);

  // Danger / boss accent — ember amber
  static const Color accentAmber = Color(0xFFFFB020);
  static const Color accentAmberDim = Color(0xFFD97706);

  // Success / join
  static const Color accentGreen = Color(0xFF2ECC71);
  static const Color accentGreenDim = Color(0xFF1A8A4A);

  // Error
  static const Color accentRed = Color(0xFFEF4444);

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDeep,
        colorScheme: const ColorScheme.dark(
          primary: accentCyan,
          secondary: accentAmber,
          error: accentRed,
          surface: backgroundCard,
          onPrimary: backgroundDeep,
          onSecondary: backgroundDeep,
          onSurface: textPrimary,
        ),
        cardTheme: const CardThemeData(
          color: backgroundCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            side: BorderSide(color: borderSubtle),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'monospace',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -1.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 0.5,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            letterSpacing: 1.2,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: textSecondary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: backgroundElevated,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentCyan, width: 1.5),
          ),
          hintStyle: const TextStyle(color: textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentCyan,
            foregroundColor: backgroundDeep,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: backgroundElevated,
          contentTextStyle: TextStyle(color: textPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            side: BorderSide(color: borderActive),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dividerTheme: const DividerThemeData(
          color: borderSubtle,
          thickness: 1,
        ),
      );
}
