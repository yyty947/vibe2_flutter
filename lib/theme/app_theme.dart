import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';

/// Central theme configuration.
abstract final class AppTheme {
  static String get fontHud => AppFonts.hudFamily;
  static String get fontCode => AppFonts.codeFamily;

  static ThemeData get dark {
    final textTheme = TextTheme(
      bodyLarge: AppFonts.code(16, color: AppColors.textPrimary),
      bodyMedium: AppFonts.code(14, color: AppColors.textPrimary),
      bodySmall: AppFonts.code(12, color: AppColors.textMuted),
      titleLarge: AppFonts.hud(20, color: AppColors.neonGreen),
      titleMedium: AppFonts.hud(16, color: AppColors.neonGreen),
      titleSmall: AppFonts.hud(14, color: AppColors.neonGreen),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.bgPanel,
        primary: AppColors.neonGreen,
        secondary: AppColors.neonCyan,
        error: AppColors.neonRed,
      ),
      fontFamily: AppFonts.codeFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPanel,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleTextStyle: AppFonts.hud(14, color: AppColors.neonGreen),
      ),
      // Kill all text decorations globally
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.neonGreen,
      ),
    );
  }
}
