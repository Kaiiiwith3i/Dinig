import 'package:flutter/material.dart';

/// The "Signal No." palette (chosen 2026-10-13): bulletin white, navy ink,
/// and a red that only means an alert. One tint, navy, drives every control.
// ponytail: the "Blue" names predate this palette and now hold navy tints.
// Rename them (primaryBlue -> tint) the next time the screens are reworked.
class DinigColors {
  static const Color primaryBlue = Color(0xFF12203A);
  static const Color darkNavy = Color(0xFF12203A);
  static const Color lightBlue = Color(0xFFE6E9F0);
  static const Color softBlue = Color(0xFFEEF1F6);

  static const Color emergencyRed = Color(0xFFE5202E);
  static const Color emergencyDarkRed = Color(0xFF7F1D1D);
  static const Color emergencyDarkBg = Color(0xFF1A0A0A);

  static const Color statusGreen = Color(0xFF16A34A);
  static const Color statusAmber = Color(0xFFD97706);

  static const Color bgCanvas = Color(0xFFF3F4F7);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF12203A);
  static const Color textSecondary = Color(0xFF5A6479);
  static const Color borderLight = Color(0xFFE3E6EC);
}

class DinigTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: DinigColors.bgCanvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DinigColors.primaryBlue,
          primary: DinigColors.primaryBlue,
          surface: DinigColors.cardSurface,
          error: DinigColors.emergencyRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: DinigColors.cardSurface,
          foregroundColor: DinigColors.darkNavy,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: DinigColors.darkNavy,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: CardThemeData(
          color: DinigColors.cardSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: DinigColors.borderLight),
          ),
        ),
      );
}
