import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ending_type.dart';
import '../data/game_data.dart';
import 'providers.dart';

/// Which visual theme is active.
enum GameThemeMode { dark, light, danger }

/// Per-theme color values.
class GameThemeColors {
  // Backgrounds
  final Color bgDeep;
  final Color bgPanel;
  final Color bgSurface;
  final Color terminalBg;
  final Color barBg;
  final Color glassOverlay;
  final Color glassBorder;
  final Color dividerColor;

  // Text
  final Color textPrimary;
  final Color textMuted;
  final Color textDim;

  // Neon (slightly muted on light bg for eye comfort)
  final Color neonGreen;
  final Color neonCyan;
  final Color neonAmber;
  final Color neonRed;
  final Color neonMagenta;

  const GameThemeColors({
    required this.bgDeep,
    required this.bgPanel,
    required this.bgSurface,
    required this.terminalBg,
    required this.barBg,
    required this.glassOverlay,
    required this.glassBorder,
    required this.dividerColor,
    required this.textPrimary,
    required this.textMuted,
    required this.textDim,
    required this.neonGreen,
    required this.neonCyan,
    required this.neonAmber,
    required this.neonRed,
    required this.neonMagenta,
  });
}

/// The resolved theme for the current frame — computed from GameState.
class GameTheme {
  final GameThemeMode mode;
  final GameThemeColors colors;

  const GameTheme._({required this.mode, required this.colors});

  // ---- Colour presets ----

  static const _dark = GameThemeColors(
    bgDeep: Color(0xFF0D0D0D),
    bgPanel: Color(0xFF111116),
    bgSurface: Color(0xFF18181F),
    terminalBg: Color(0xFF0A0A0F),
    barBg: Color(0xFF1A1A24),
    glassOverlay: Color(0x80000000), // black 0.5 — stronger blur
    glassBorder: Color(0x26FFFFFF), // white 0.15 — more visible edge
    dividerColor: Color(0xFF2A2A35),
    textPrimary: Color(0xFFE0E0E0),
    textMuted: Color(0xFF666680),
    textDim: Color(0xFF444444),
    neonGreen: Color(0xFF00FF9F),
    neonCyan: Color(0xFF00FFFF),
    neonAmber: Color(0xFFFFB800),
    neonRed: Color(0xFFFF0040),
    neonMagenta: Color(0xFFFF0080),
  );

  // Warm off-white morning — bright terminal without pure #FFF
  static const _light = GameThemeColors(
    bgDeep: Color(0xFFD8D8E2),
    bgPanel: Color(0xFFDEDEE6),
    bgSurface: Color(0xFFE4E4EA),
    terminalBg: Color(0xFFD0D0DA),
    barBg: Color(0xFFCCCCD6),
    glassOverlay: Color(0x40FFFFFF),
    glassBorder: Color(0x59FFFFFF),
    dividerColor: Color(0xFFC0C0CC),
    textPrimary: Color(0xFF1A1A28),
    textMuted: Color(0xFF505068),
    textDim: Color(0xFF888898),
    neonGreen: Color(0xFF00CC7F),
    neonCyan: Color(0xFF00CCCC),
    neonAmber: Color(0xFFCC9400),
    neonRed: Color(0xFFCC0033),
    neonMagenta: Color(0xFFCC0066),
  );

  static const _danger = GameThemeColors(
    bgDeep: Color(0xFF140408),
    bgPanel: Color(0xFF1E0610),
    bgSurface: Color(0xFF280A18),
    terminalBg: Color(0xFF0C0204),
    barBg: Color(0xFF240610),
    glassOverlay: Color(0x80300006), // deep crimson ~50% — strong red glass
    glassBorder: Color(0x80FF0030), // neonRed 0.5 — bold red border
    dividerColor: Color(0xFF300C18),
    textPrimary: Color(0xFFE0E0E0),
    textMuted: Color(0xFF666680),
    textDim: Color(0xFF444444),
    neonGreen: Color(0xFF00FF9F),
    neonCyan: Color(0xFF00FFFF),
    neonAmber: Color(0xFFFFB800),
    neonRed: Color(0xFFFF0040),
    neonMagenta: Color(0xFFFF0080),
  );

  // ---- Derived ThemeData for AnimatedTheme ----

  ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: 'Fira Code',
      scaffoldBackgroundColor: colors.bgDeep,
      colorScheme: const ColorScheme.dark().copyWith(
        surface: colors.bgPanel,
      ),
      appBarTheme: AppBarTheme(backgroundColor: colors.bgPanel),
    );
  }

  // ---- Pure computation from GameState ----

  static GameTheme compute({
    required GamePhase phase,
    required String? currentEventId,
    required String? suspicionPressure,
    required String? interruption,
    required int energy,
    required int kpi,
  }) {
    // Priority 1: Danger — high-risk event, pressure, or critical stats
    bool isDanger = false;
    if (suspicionPressure != null) {
      isDanger = true;
    } else if (currentEventId != null) {
      final ev = GameData.events.where((e) => e.id == currentEventId).firstOrNull;
      if (ev != null && ev.highRisk) isDanger = true;
    }
    if (energy <= 10 || kpi <= 10) isDanger = true;

    if (isDanger) return GameTheme._(mode: GameThemeMode.danger, colors: _danger);

    // Priority 2: Light — MORNING / OPENING / interruption
    if (phase == GamePhase.morning || phase == GamePhase.opening || interruption != null) {
      return GameTheme._(mode: GameThemeMode.light, colors: _light);
    }

    // Priority 3: Dark — everything else
    return GameTheme._(mode: GameThemeMode.dark, colors: _dark);
  }
}

/// Riverpod provider — recomputed every frame from GameState.
final themeProvider = Provider<GameTheme>((ref) {
  final s = ref.watch(gameProvider);
  return GameTheme.compute(
    phase: s.phase,
    currentEventId: s.currentEventId,
    suspicionPressure: s.suspicionPressure,
    interruption: s.interruption,
    energy: s.energy,
    kpi: s.kpi,
  );
});
