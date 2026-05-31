/// Prerequisite check for an action (e.g. energy > 20 for FIX_BUG).
class ActionPrerequisite {
  final String field;
  final String operator;
  final int value;

  const ActionPrerequisite({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory ActionPrerequisite.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ActionPrerequisite(field: '', operator: '', value: 0);
    return ActionPrerequisite(
      field: json['field'] as String? ?? '',
      operator: json['operator'] as String? ?? '',
      value: json['value'] as int? ?? 0,
    );
  }
}

/// Conditional unlock criteria for an action.
class ActionCondition {
  final int? minDay;
  final int? minKpi;
  final int? maxKpi;
  final bool weekendOnly;
  final String? requiresSkill;

  const ActionCondition({
    this.minDay,
    this.minKpi,
    this.maxKpi,
    this.weekendOnly = false,
    this.requiresSkill,
  });

  factory ActionCondition.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ActionCondition();
    return ActionCondition(
      minDay: json['minDay'] as int?,
      minKpi: json['minKpi'] as int?,
      maxKpi: json['maxKpi'] as int?,
      weekendOnly: json['weekendOnly'] as bool? ?? false,
      requiresSkill: json['requiresSkill'] as String?,
    );
  }
}

/// A single action definition (GAME_CONTENT §1).
class ActionDef {
  final String id;
  final String label;
  final int energyEffect;
  final int kpiEffect;
  final int interviewEffect;
  final int suspicionEffect;
  final ActionPrerequisite? prerequisite;
  final String log;
  final bool core;
  final ActionCondition? condition;

  const ActionDef({
    required this.id,
    required this.label,
    required this.energyEffect,
    required this.kpiEffect,
    required this.interviewEffect,
    required this.suspicionEffect,
    this.prerequisite,
    required this.log,
    this.core = false,
    this.condition,
  });

  /// Whether the prerequisite is blocking given a stat value.
  bool isBlockedBy(int statValue) {
    if (prerequisite == null || prerequisite!.field.isEmpty) return false;
    if (prerequisite!.operator == '>') return statValue <= prerequisite!.value;
    return false;
  }

  factory ActionDef.fromJson(Map<String, dynamic> json) {
    final effects = json['effects'] as Map<String, dynamic>;
    return ActionDef(
      id: json['id'] as String,
      label: json['label'] as String,
      energyEffect: effects['energy'] as int? ?? 0,
      kpiEffect: effects['kpi'] as int? ?? 0,
      interviewEffect: effects['interview'] as int? ?? 0,
      suspicionEffect: effects['suspicion'] as int? ?? 0,
      prerequisite: json['prerequisite'] != null
          ? ActionPrerequisite.fromJson(json['prerequisite'] as Map<String, dynamic>?)
          : null,
      log: json['log'] as String? ?? '',
      core: json['core'] as bool? ?? false,
      condition: json['condition'] != null
          ? ActionCondition.fromJson(json['condition'] as Map<String, dynamic>?)
          : null,
    );
  }
}
