import 'package:flutter/material.dart';
import 'colors.dart';

/// Pre-built neon text and box styles matching the Web CSS classes
/// (.neon-green, .neon-cyan, .neon-red, .neon-amber, .neon-magenta).
///
/// Also covers .glow-box-* and .text-red-flash equivalents.

abstract final class NeonStyles {
  // ---- Neon Glow Text Shadows ----

  static List<Shadow> _glow(Color color, {double radius = 7, double spread = 20}) {
    return [
      Shadow(color: color, blurRadius: radius),
      Shadow(color: color.withAlpha(100), blurRadius: spread),
    ];
  }

  static TextStyle green(double size) => TextStyle(
        color: AppColors.neonGreen,
        fontSize: size,
        shadows: _glow(AppColors.neonGreen),
      );

  static TextStyle cyan(double size) => TextStyle(
        color: AppColors.neonCyan,
        fontSize: size,
        shadows: _glow(AppColors.neonCyan),
      );

  static TextStyle red(double size) => TextStyle(
        color: AppColors.neonRed,
        fontSize: size,
        shadows: _glow(AppColors.neonRed),
      );

  static TextStyle amber(double size) => TextStyle(
        color: AppColors.neonAmber,
        fontSize: size,
        shadows: _glow(AppColors.neonAmber),
      );

  static TextStyle magenta(double size) => TextStyle(
        color: AppColors.neonMagenta,
        fontSize: size,
        shadows: _glow(AppColors.neonMagenta),
      );

  // ---- Box Glow Decorations ----

  static BoxDecoration glowBoxGreen({BorderRadius? borderRadius}) => BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonGreen.withAlpha(100)),
        boxShadow: [
          BoxShadow(color: AppColors.neonGreen.withAlpha(75), blurRadius: 8),
        ],
      );

  static BoxDecoration glowBoxRed({BorderRadius? borderRadius}) => BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonRed.withAlpha(150)),
        boxShadow: [
          BoxShadow(color: AppColors.neonRed.withAlpha(125), blurRadius: 12),
        ],
      );

  static BoxDecoration glowBoxCyan({BorderRadius? borderRadius}) => BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonCyan.withAlpha(100)),
        boxShadow: [
          BoxShadow(color: AppColors.neonCyan.withAlpha(75), blurRadius: 8),
        ],
      );
}
