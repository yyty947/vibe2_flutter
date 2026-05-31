import 'dart:math';
import '../models/action_def.dart';
import '../models/game_state.dart';
import '../models/day_modifier.dart';
import '../models/status_condition.dart';
import '../models/skill_def.dart';
import '../utils/weekend.dart';

final _random = Random();

/// Streak penalty table (TECH_ARCH §8.5 / Patch-F04).
const streakTable = <String, Map<int, _StreakEntry>>{
  'SLACK': {
    1: _StreakEntry(energy: 20, kpi: 0, suspicion: 3),
    2: _StreakEntry(energy: 14, kpi: 0, suspicion: 5),
    3: _StreakEntry(energy: 8, kpi: 0, suspicion: 7),
    4: _StreakEntry(energy: 3, kpi: 0, suspicion: 10),
  },
  'STUDY': {
    1: _StreakEntry(energy: -10, kpi: 0, suspicion: 5),
    2: _StreakEntry(energy: -13, kpi: 0, suspicion: 7),
    3: _StreakEntry(energy: -16, kpi: 0, suspicion: 9),
    4: _StreakEntry(energy: -20, kpi: 0, suspicion: 12),
  },
  'WRITE_CODE': {
    1: _StreakEntry(energy: -10, kpi: 5, suspicion: -2),
    2: _StreakEntry(energy: -13, kpi: 5, suspicion: -1),
    3: _StreakEntry(energy: -16, kpi: 5, suspicion: 0),
    4: _StreakEntry(energy: -20, kpi: 5, suspicion: 1),
  },
  'FIX_BUG': {
    1: _StreakEntry(energy: -20, kpi: 15, suspicion: 0),
    2: _StreakEntry(energy: -25, kpi: 15, suspicion: 0),
    3: _StreakEntry(energy: -30, kpi: 10, suspicion: 0),
    4: _StreakEntry(energy: -35, kpi: 5, suspicion: 0),
  },
};

class _StreakEntry {
  final int energy;
  final int kpi;
  final int suspicion;
  const _StreakEntry({required this.energy, required this.kpi, required this.suspicion});
}

/// Result of a spot check (immediate suspicion penalty).
class SpotCheckResult {
  final int deltaEnergy;
  final int deltaKpi;
  final int deltaInterview;
  final int deltaSuspicion;
  final String? log;

  const SpotCheckResult({
    this.deltaEnergy = 0,
    this.deltaKpi = 0,
    this.deltaInterview = 0,
    this.deltaSuspicion = 0,
    this.log,
  });

  static const empty = SpotCheckResult();
}

/// Raw action delta values after all modifiers.
class ActionDelta {
  final int energy;
  final int kpi;
  final int interview;
  final int suspicion;

  const ActionDelta({
    required this.energy,
    required this.kpi,
    required this.interview,
    required this.suspicion,
  });
}

/// Complete result of resolving an action.
class ActionResolveResult {
  final ActionDelta deltas;
  final String? spotCheckLog;

  const ActionResolveResult({required this.deltas, this.spotCheckLog});
}

/// Resolve an action into final clamped deltas by applying the full effect chain:
///  1. Streak penalty
///  2. Spot check (immediate penalty)
///  3. Day modifier
///  4. Weekend bonus
///  5. Status conditions (buff/debuff)
///  6. Skill passives
ActionResolveResult resolveActionEffects({
  required ActionDef action,
  required GameState state,
  required DayModifier? modifier,
  required List<StatusCondition> activeStatuses,
  required List<SkillDef> skills,
}) {
  // ---- Step 1: Streak-adjusted base (only if same action) ----
  final isSameAction = state.streakActionId == action.id;
  final effectiveStreak = isSameAction ? state.streakCount : 1;
  final table = streakTable[action.id];
  int energy, kpi, suspicion;

  if (table != null && effectiveStreak > 1) {
    final tier = effectiveStreak.clamp(1, 4);
    final entry = table[tier]!;
    energy = entry.energy;
    kpi = entry.kpi;
    suspicion = entry.suspicion;
  } else {
    energy = action.energyEffect;
    kpi = action.kpiEffect;
    suspicion = action.suspicionEffect;
  }
  int interview = action.interviewEffect;

  // ---- Step 2: Spot check ----
  final spot = _checkSpotCheck(state.suspicion, action.id);
  energy += spot.deltaEnergy;
  kpi += spot.deltaKpi;
  interview += spot.deltaInterview;
  suspicion += spot.deltaSuspicion;

  // ---- Step 3: Day modifier ----
  if (modifier != null) {
    final me = modifier.effects;
    if (me.energyMultiplier != null) energy = (energy * me.energyMultiplier!).round();
    if (me.kpiMultiplier != null) kpi = (kpi * me.kpiMultiplier!).round();
    if (me.interviewMultiplier != null) interview = (interview * me.interviewMultiplier!).round();
    if (me.suspicionMultiplier != null) suspicion = (suspicion * me.suspicionMultiplier!).round();
    if (me.slackEnergyBoost != null && action.id == 'SLACK') energy += me.slackEnergyBoost!;
    if (me.slackSuspicionBoost != null && action.id == 'SLACK') suspicion += me.slackSuspicionBoost!;
  }

  // ---- Step 4: Weekend bonus ----
  if (isWeekend(state.day)) {
    if (action.id == 'SLACK') energy += 5;
    if (action.id == 'STUDY') interview += 3;
  }

  // ---- Step 5: Status conditions ----
  double kpiGainMul = 1, energyCostMul = 1, suspicionGainMul = 1;
  double interviewGainMul = 1, allGainMul = 1;

  for (final sc in activeStatuses) {
    final e = sc.effects;
    final isWorkAction = action.id == 'WRITE_CODE' || action.id == 'FIX_BUG';
    final kpiGainFromCond = sc.id == 'CORE_MEMBER'
        ? (isWorkAction ? e.kpiGainMultiplier : null)
        : e.kpiGainMultiplier;
    if (kpiGainFromCond != null) kpiGainMul += kpiGainFromCond;
    if (e.energyCostMultiplier != null) energyCostMul += e.energyCostMultiplier!;
    if (e.suspicionGainMultiplier != null) suspicionGainMul += e.suspicionGainMultiplier!;
    if (e.interviewGainMultiplier != null) interviewGainMul += e.interviewGainMultiplier!;
    if (e.allGainMultiplier != null) allGainMul += e.allGainMultiplier!;
  }

  if (kpi > 0) kpi = (kpi * kpiGainMul * allGainMul).round();
  if (energy < 0) energy = (energy * energyCostMul).round();
  if (energy > 0) energy = (energy * allGainMul).round();
  if (suspicion > 0) suspicion = (suspicion * suspicionGainMul).round();
  if (interview > 0) interview = (interview * interviewGainMul * allGainMul).round();

  // ---- Step 6: Skill passives ----
  for (final skill in skills) {
    final se = skill.effects;
    if (se['energyCostMultiplier'] != null && energy < 0) {
      energy = (energy * (1 + se['energyCostMultiplier']!)).round();
    }
    if (se['slackEnergyBoost'] != null && action.id == 'SLACK') {
      energy += se['slackEnergyBoost']!.toInt();
    }
    if (se['kpiGainMultiplier'] != null && kpi > 0) {
      kpi = (kpi * (1 + se['kpiGainMultiplier']!)).round();
    }
    if (se['writeCodeEnergyDiscount'] != null && action.id == 'WRITE_CODE' && energy < 0) {
      energy = (energy + se['writeCodeEnergyDiscount']!).round();
    }
    if (se['suspicionGainMultiplier'] != null && suspicion > 0) {
      suspicion = (suspicion * (1 + se['suspicionGainMultiplier']!)).round();
    }
    if (se['interviewGainMultiplier'] != null && interview > 0) {
      interview = (interview * (1 + se['interviewGainMultiplier']!)).round();
    }
    if (se['studySuspicionDiscount'] != null && action.id == 'STUDY') {
      suspicion = (suspicion - se['studySuspicionDiscount']!).round();
    }
  }

  return ActionResolveResult(
    deltas: ActionDelta(energy: energy, kpi: kpi, interview: interview, suspicion: suspicion),
    spotCheckLog: spot.log,
  );
}

/// Immediate suspicion penalty for risky actions at high suspicion (Patch-F04).
SpotCheckResult _checkSpotCheck(int suspicion, String actionId) {
  if (suspicion < 70) return SpotCheckResult.empty;

  if (actionId == 'STUDY') {
    if (suspicion >= 85 && _random.nextDouble() < 0.7) {
      return const SpotCheckResult(
        deltaInterview: -4,
        deltaSuspicion: 8,
        log: '[ALERT] Leader从背后拍了你一下："在忙什么呢？" 你手忙脚乱关了LeetCode。',
      );
    }
    if (_random.nextDouble() < 0.4) {
      return const SpotCheckResult(
        deltaSuspicion: 5,
        log: '[WARNING] 你切屏刷题时感觉到背后有人在看…',
      );
    }
  }

  if (actionId == 'SLACK') {
    if (suspicion >= 85 && _random.nextDouble() < 0.5) {
      return const SpotCheckResult(
        deltaEnergy: -20,
        deltaKpi: -5,
        deltaSuspicion: 5,
        log: '[ALERT] 有人向HR举报你天天摸鱼。Leader叫你进会议室，今天白摸了。',
      );
    }
    if (_random.nextDouble() < 0.3) {
      return const SpotCheckResult(
        deltaEnergy: -10,
        deltaSuspicion: 3,
        log: '[WARNING] HR正好路过你的工位，你赶紧切回了IDE。',
      );
    }
  }

  return SpotCheckResult.empty;
}
