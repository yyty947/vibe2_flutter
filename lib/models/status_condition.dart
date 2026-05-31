/// A trigger condition for a status effect ("energy >= 80").
class StatusTrigger {
  final String stat;
  final String operator; // '>=' or '<='
  final int value;

  const StatusTrigger({required this.stat, required this.operator, required this.value});

  factory StatusTrigger.fromJson(Map<String, dynamic> json) => StatusTrigger(
        stat: json['stat'] as String,
        operator: json['operator'] as String,
        value: json['value'] as int,
      );
}

/// Multiplier effects applied by a status condition.
class StatusEffects {
  final double? kpiGainMultiplier;
  final double? energyCostMultiplier;
  final double? suspicionGainMultiplier;
  final double? interviewGainMultiplier;
  final double? allGainMultiplier;

  const StatusEffects({
    this.kpiGainMultiplier,
    this.energyCostMultiplier,
    this.suspicionGainMultiplier,
    this.interviewGainMultiplier,
    this.allGainMultiplier,
  });

  factory StatusEffects.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StatusEffects();
    return StatusEffects(
      kpiGainMultiplier: (json['kpiGainMultiplier'] as num?)?.toDouble(),
      energyCostMultiplier: (json['energyCostMultiplier'] as num?)?.toDouble(),
      suspicionGainMultiplier: (json['suspicionGainMultiplier'] as num?)?.toDouble(),
      interviewGainMultiplier: (json['interviewGainMultiplier'] as num?)?.toDouble(),
      allGainMultiplier: (json['allGainMultiplier'] as num?)?.toDouble(),
    );
  }
}

/// Tooltip data for a status condition.
class StatusTooltip {
  final String title;
  final String effect;
  final String flavor;

  const StatusTooltip({required this.title, required this.effect, required this.flavor});

  factory StatusTooltip.fromJson(Map<String, dynamic> json) => StatusTooltip(
        title: json['title'] as String,
        effect: json['effect'] as String,
        flavor: json['flavor'] as String,
      );
}

/// A buff or debuff status condition (TECH_ARCH §8.4).
class StatusCondition {
  final String id;
  final String name;
  final String type; // 'buff' | 'debuff'
  final int priority;
  final List<StatusTrigger> triggers;
  final StatusEffects effects;
  final String icon;
  final StatusTooltip tooltip;

  const StatusCondition({
    required this.id,
    required this.name,
    required this.type,
    required this.priority,
    required this.triggers,
    required this.effects,
    required this.icon,
    required this.tooltip,
  });

  bool get isBuff => type == 'buff';

  factory StatusCondition.fromJson(Map<String, dynamic> json) => StatusCondition(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        priority: json['priority'] as int? ?? 1,
        triggers: (json['triggers'] as List<dynamic>)
            .map((t) => StatusTrigger.fromJson(t as Map<String, dynamic>))
            .toList(),
        effects: StatusEffects.fromJson(json['effects'] as Map<String, dynamic>?),
        icon: json['icon'] as String? ?? 'ShieldCheck',
        tooltip: StatusTooltip.fromJson(json['tooltip'] as Map<String, dynamic>),
      );
}
