import '../models/game_state.dart';
import '../models/status_condition.dart';

/// Compute which status conditions are currently active.
/// Same-domain conditions: highest priority buff wins, highest priority debuff wins.
/// Buff and debuff can coexist (they're from different types).
List<String> computeActiveStatuses(GameState state, List<StatusCondition> allConditions) {
  // Group by domain (determined by first trigger stat)
  final byDomain = <String, List<StatusCondition>>{};

  for (final cond in allConditions) {
    final allMet = cond.triggers.every((t) {
      final val = _statValue(state, t.stat);
      if (t.operator == '>=') return val >= t.value;
      return val <= t.value;
    });
    if (!allMet) continue;

    final domain = cond.triggers.first.stat;
    byDomain.putIfAbsent(domain, () => []).add(cond);
  }

  // For each domain, pick highest-priority buff and highest-priority debuff
  final result = <String>[];
  for (final entries in byDomain.values) {
    final buffs = entries.where((e) => e.isBuff).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    final debuffs = entries.where((e) => !e.isBuff).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    if (buffs.isNotEmpty) result.add(buffs.first.id);
    if (debuffs.isNotEmpty) result.add(debuffs.first.id);
  }

  return result;
}

int _statValue(GameState state, String stat) {
  return switch (stat) {
    'energy' => state.energy,
    'kpi' => state.kpi,
    'interview' => state.interview,
    'suspicion' => state.suspicion,
    _ => 0,
  };
}
