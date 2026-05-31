import 'package:flutter/material.dart';

/// Cyberpunk Terminal color palette (UI_DESIGN_SYSTEM §2).
///
/// All colors match the Web CSS variables exactly.

// ---- Background Layers ----
abstract final class AppColors {
  /// Deep background (#0D0D0D)
  static const bgDeep = Color(0xFF0D0D0D);

  /// Panel / Sidebar / TopBar background (#111116)
  static const bgPanel = Color(0xFF111116);

  /// Surface / Button / Card / Input background (#18181F)
  static const bgSurface = Color(0xFF18181F);

  /// Elevated / Hover state background (#1E1E28)
  static const bgElevated = Color(0xFF1E1E28);

  // ---- Neon Semantic Colors ----
  /// Primary / Success (#00FF9F)
  static const neonGreen = Color(0xFF00FF9F);

  /// Info / Tech (#00FFFF)
  static const neonCyan = Color(0xFF00FFFF);

  /// Warning / Medium risk (#FFB800)
  static const neonAmber = Color(0xFFFFB800);

  /// Danger / Critical (#FF0040)
  static const neonRed = Color(0xFFFF0040);

  /// Accent / Glitch effects (#FF0080)
  static const neonMagenta = Color(0xFFFF0080);

  // ---- Text Layers ----
  /// Primary text (#E0E0E0)
  static const textPrimary = Color(0xFFE0E0E0);

  /// Muted / Secondary text (#666680)
  static const textMuted = Color(0xFF666680);

  /// Dim / Weakest text (#444444)
  static const textDim = Color(0xFF444444);

  // ---- Borders ----
  /// Standard border (#2A2A35)
  static const borderDim = Color(0xFF2A2A35);

  /// Glow border uses neon colors with alpha, applied per-context.
}
