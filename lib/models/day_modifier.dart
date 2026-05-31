/// Modifier effect multipliers applied to action deltas.
class ModifierEffects {
  final double? energyMultiplier;
  final double? kpiMultiplier;
  final double? interviewMultiplier;
  final double? suspicionMultiplier;
  final int? slackEnergyBoost;
  final int? slackSuspicionBoost;
  final int? settlementDrainBonus;

  const ModifierEffects({
    this.energyMultiplier,
    this.kpiMultiplier,
    this.interviewMultiplier,
    this.suspicionMultiplier,
    this.slackEnergyBoost,
    this.slackSuspicionBoost,
    this.settlementDrainBonus,
  });

  factory ModifierEffects.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModifierEffects();
    return ModifierEffects(
      energyMultiplier: (json['energyMultiplier'] as num?)?.toDouble(),
      kpiMultiplier: (json['kpiMultiplier'] as num?)?.toDouble(),
      interviewMultiplier: (json['interviewMultiplier'] as num?)?.toDouble(),
      suspicionMultiplier: (json['suspicionMultiplier'] as num?)?.toDouble(),
      slackEnergyBoost: json['slackEnergyBoost'] as int?,
      slackSuspicionBoost: json['slackSuspicionBoost'] as int?,
      settlementDrainBonus: json['settlementDrainBonus'] as int?,
    );
  }
}

/// A daily modifier that tweaks action effects (TECH_ARCH §8.1).
class DayModifier {
  final String id;
  final String label;
  final String description;
  final ModifierEffects effects;
  final int? minDay;
  final int? maxDay;
  final int weight;

  const DayModifier({
    required this.id,
    required this.label,
    required this.description,
    required this.effects,
    this.minDay,
    this.maxDay,
    required this.weight,
  });

  factory DayModifier.fromJson(Map<String, dynamic> json) => DayModifier(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String,
        effects: ModifierEffects.fromJson(json['effects'] as Map<String, dynamic>?),
        minDay: json['minDay'] as int?,
        maxDay: json['maxDay'] as int?,
        weight: json['weight'] as int? ?? 100,
      );
}
