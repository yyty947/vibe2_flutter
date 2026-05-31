import 'qte_config.dart';

/// An effect applied to one of the four core stats.
class EventEffect {
  final String type; // ENERGY | KPI | INTERVIEW | SUSPICION
  final int value;

  const EventEffect({required this.type, required this.value});

  factory EventEffect.fromJson(Map<String, dynamic> json) => EventEffect(
        type: json['type'] as String,
        value: json['value'] as int,
      );
}

/// One of two options in an event.
class EventOption {
  final String text;
  final List<EventEffect> effects;
  final String log;

  const EventOption({required this.text, required this.effects, required this.log});

  factory EventOption.fromJson(Map<String, dynamic> json) => EventOption(
        text: json['text'] as String,
        effects: (json['effects'] as List<dynamic>)
            .map((e) => EventEffect.fromJson(e as Map<String, dynamic>))
            .toList(),
        log: json['log'] as String,
      );
}

/// Serialized condition for event eligibility.
class EventCondition {
  final int? minDay;
  final int? maxDay;
  final int? minSuspicion;
  final int? maxSuspicion;
  final int? minKpi;
  final int? maxKpi;
  final int? minInterview;
  final int? maxInterview;

  const EventCondition({
    this.minDay,
    this.maxDay,
    this.minSuspicion,
    this.maxSuspicion,
    this.minKpi,
    this.maxKpi,
    this.minInterview,
    this.maxInterview,
  });

  factory EventCondition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EventCondition();
    return EventCondition(
      minDay: json['minDay'] as int?,
      maxDay: json['maxDay'] as int?,
      minSuspicion: json['minSuspicion'] as int?,
      maxSuspicion: json['maxSuspicion'] as int?,
      minKpi: json['minKpi'] as int?,
      maxKpi: json['maxKpi'] as int?,
      minInterview: json['minInterview'] as int?,
      maxInterview: json['maxInterview'] as int?,
    );
  }
}

/// A single game event (GAME_CONTENT §3).
///
/// When [qteConfig] is non-null this event renders as a QTE mini-game
/// instead of the standard A/B option buttons.
class GameEvent {
  final String id;
  final String title;
  final String description;
  final int weight;
  final bool highRisk;
  final EventCondition? condition;
  final EventOption optionA;
  final EventOption optionB;
  final QteConfig? qteConfig;

  const GameEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.weight,
    this.highRisk = false,
    this.condition,
    required this.optionA,
    required this.optionB,
    this.qteConfig,
  });

  factory GameEvent.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as List<dynamic>;
    return GameEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      weight: json['weight'] as int? ?? 100,
      highRisk: json['highRisk'] as bool? ?? false,
      condition: json['condition'] != null
          ? EventCondition.fromJson(json['condition'] as Map<String, dynamic>?)
          : null,
      optionA: EventOption.fromJson(options[0] as Map<String, dynamic>),
      optionB: EventOption.fromJson(options[1] as Map<String, dynamic>),
      qteConfig: json['qteConfig'] != null
          ? QteConfig.fromJson(json['qteConfig'] as Map<String, dynamic>)
          : null,
    );
  }
}
