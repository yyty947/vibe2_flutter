import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

/// Save system (TECH_ARCH §12 / AGENTS.md §4.5).
///
/// Key: `frontend-survival-save`
/// Stores the full GameState as JSON in SharedPreferences.
class SaveService {
  static const _key = 'frontend-survival-save';

  /// Persist the current game state.
  static Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.toJson());
    await prefs.setString(_key, json);
  }

  /// Load a saved game state, or null if no save exists.
  static Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final state = GameState.fromJson(map);

      // Version check: discard if version mismatch
      if (state.version != GameState.gameVersion) return null;

      return state;
    } catch (_) {
      return null;
    }
  }

  /// Check if a save exists.
  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  /// Clear the save (called when game ends).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
