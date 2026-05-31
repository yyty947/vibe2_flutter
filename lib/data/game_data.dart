import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/action_def.dart';
import '../models/game_event.dart';
import '../models/day_modifier.dart';
import '../models/interruption.dart';
import '../models/pressure_event.dart';
import '../models/status_condition.dart';
import '../models/skill_def.dart';
import '../models/event_category.dart';

/// Synchronous access to parsed game data after [init] is called once.
class GameData {
  static List<ActionDef>? _actions;
  static List<GameEvent>? _events;
  static Map<String, String>? _openings;
  static Map<String, Map<String, String>>? _endings;
  static List<DayModifier>? _modifiers;
  static List<Interruption>? _interruptions;
  static List<PressureEvent>? _pressureEvents;
  static List<StatusCondition>? _statusConditions;
  static List<SkillDef>? _skills;
  static List<EventCategory>? _eventCategories;

  /// Load all JSON data files. Call once at startup.
  static Future<void> init() async {
    _actions = await _loadList('assets/data/actions.json', ActionDef.fromJson);
    _events = await _loadList('assets/data/events.json', GameEvent.fromJson);
    _openings = await _loadStringMap('assets/data/openings.json');
    _endings = await _loadNestedMap('assets/data/endings.json');
    _modifiers = await _loadList(
      'assets/data/modifiers.json',
      DayModifier.fromJson,
    );
    _interruptions = await _loadList(
      'assets/data/interruptions.json',
      Interruption.fromJson,
    );
    _pressureEvents = await _loadList(
      'assets/data/pressure-events.json',
      PressureEvent.fromJson,
    );
    _statusConditions = await _loadList(
      'assets/data/status-conditions.json',
      StatusCondition.fromJson,
    );
    _skills = await _loadList('assets/data/skills.json', SkillDef.fromJson);
    _eventCategories = await _loadCategories(
      'assets/data/event-categories.json',
    );

    // Preload all background images to avoid decode stalls during crossfades
    await _precacheBg('assets/backgrounds/morning.png');
    await _precacheBg('assets/backgrounds/afternoon.png');
    await _precacheBg('assets/backgrounds/daily-work.png');
    await _precacheBg('assets/backgrounds/office-politics.png');
    await _precacheBg('assets/backgrounds/tech-crisis.png');
    await _precacheBg('assets/backgrounds/personal-growth.png');
    await _precacheBg('assets/backgrounds/high-risk.png');
    await _precacheBg('assets/backgrounds/QTE.png');
  }

  // --- Synchronous getters (valid after init) ---

  static List<ActionDef> get actions => _actions!;
  static List<GameEvent> get events => _events!;
  static Map<String, String> get openings => _openings!;
  static Map<String, Map<String, String>> get endings => _endings!;
  static List<DayModifier> get modifiers => _modifiers!;
  static List<Interruption> get interruptions => _interruptions!;
  static List<PressureEvent> get pressureEvents => _pressureEvents!;
  static List<StatusCondition> get statusConditions => _statusConditions!;
  static List<SkillDef> get skills => _skills!;
  static List<EventCategory> get eventCategories => _eventCategories!;

  /// Find the category that contains a given event ID.
  static EventCategory? categoryForEvent(String eventId) {
    for (final cat in _eventCategories!) {
      if (cat.events.contains(eventId)) return cat;
    }
    return null;
  }

  // --- Internal loaders ---

  static Future<List<T>> _loadList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = await rootBundle.loadString(path);
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, String>> _loadStringMap(String path) async {
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v.toString()));
  }

  static Future<Map<String, Map<String, String>>> _loadNestedMap(
    String path,
  ) async {
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) {
      final inner = v as Map<String, dynamic>;
      return MapEntry(k, inner.map((ik, iv) => MapEntry(ik, iv.toString())));
    });
  }

  static Future<List<EventCategory>> _loadCategories(String path) async {
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.entries
        .map(
          (e) => EventCategory.fromJsonEntry(
            e.key,
            e.value as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<void> _precacheBg(String path) async {
    // Force asset into memory so Image.asset finds it cached
    await rootBundle.load(path);
  }
}
