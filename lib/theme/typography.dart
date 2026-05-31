import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared fonts. Share Tech Mono for HUD/titles; Fira Code for body/terminal.
abstract final class AppFonts {
  static const _hudFamily = 'Share Tech Mono';
  static const _codeFamily = 'Fira Code';

  /// HUD / Title style using Share Tech Mono.
  static TextStyle hud(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.shareTechMono(
      fontSize: size,
      color: color,
      fontWeight: weight,
      decoration: TextDecoration.none,
    );
  }

  /// Code / Body / Terminal style using Fira Code.
  static TextStyle code(double size, {Color? color, FontWeight? weight}) {
    return GoogleFonts.firaCode(
      fontSize: size,
      color: color,
      fontWeight: weight,
      decoration: TextDecoration.none,
    );
  }

  static String get hudFamily => _hudFamily;
  static String get codeFamily => _codeFamily;
}
