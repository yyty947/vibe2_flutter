/// A skill node in the 4-branch × 3-tier tree (TECH_ARCH §8.7).
class SkillDef {
  final String id;
  final String name;
  final String branch;
  final int tier;
  final int cost;
  final String? requires;
  final Map<String, double> effects;
  final String icon;
  final String description;
  final String? unlocksAction;
  final String? unlocksEvent;
  final String? enablesAction;

  const SkillDef({
    required this.id,
    required this.name,
    required this.branch,
    required this.tier,
    required this.cost,
    this.requires,
    required this.effects,
    required this.icon,
    required this.description,
    this.unlocksAction,
    this.unlocksEvent,
    this.enablesAction,
  });

  factory SkillDef.fromJson(Map<String, dynamic> json) {
    final rawEffects = json['effects'] as Map<String, dynamic>? ?? {};
    final Map<String, double> effects = {};
    for (final entry in rawEffects.entries) {
      effects[entry.key] = (entry.value as num).toDouble();
    }
    return SkillDef(
      id: json['id'] as String,
      name: json['name'] as String,
      branch: json['branch'] as String,
      tier: json['tier'] as int,
      cost: json['cost'] as int,
      requires: json['requires'] as String?,
      effects: effects,
      icon: json['icon'] as String,
      description: json['description'] as String,
      unlocksAction: json['unlocksAction'] as String?,
      unlocksEvent: json['unlocksEvent'] as String?,
      enablesAction: json['enablesAction'] as String?,
    );
  }
}
