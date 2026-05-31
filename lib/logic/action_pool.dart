import 'dart:math';
import '../models/action_def.dart';
import '../models/game_state.dart';
import '../utils/weekend.dart';

final _random = Random();

/// Shuffle a list in place (Fisher-Yates).
List<T> _shuffle<T>(List<T> list) {
  final a = [...list];
  for (int i = a.length - 1; i > 0; i--) {
    final j = _random.nextInt(i + 1);
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  return a;
}

/// Sample 4 actions for a phase from the full action pool.
///
/// Rules:
/// - At least 2 core actions
/// - At least 1 positive-energy (rest-like) action
/// - At least 1 negative-energy (work-like) action
/// - Core actions that fail prerequisites are excluded
List<ActionDef> sampleActionPool(
  GameState state,
  List<ActionDef> allActions,
  List<String> activeSkills,
) {
  // Partition actions
  final coreEligible = allActions.where((a) {
    if (!a.core) return false;
    if (a.prerequisite != null && a.isBlockedBy(state.energy)) return false;
    return true;
  }).toList();

  final condEligible = allActions.where((a) {
    if (a.core) return false;
    if (a.prerequisite != null && a.isBlockedBy(state.energy)) return false;
    return _isConditionMet(a.condition, state, activeSkills);
  }).toList();

  // Step 1: Pick core actions (2-4)
  final maxCore = coreEligible.length.clamp(0, 4);
  if (maxCore < 2) {
    // Edge case: not enough core actions (e.g., FIX_BUG locked by low energy)
    final allEligible = [...coreEligible, ...condEligible];
    final shuffled = _shuffle(allEligible);
    return _shuffle(shuffled.take(4).toList());
  }

  final coreCount = (2 + _random.nextInt(maxCore - 1)).clamp(0, 4);
  final shuffledCore = _shuffle(coreEligible);
  final pickedCore = shuffledCore.take(coreCount).toList();

  // Step 2: Fill remaining slots from conditional pool
  final remaining = (4 - pickedCore.length).clamp(0, 4);
  final shuffledCond = _shuffle(condEligible);
  final pickedCond = shuffledCond.take(remaining.clamp(0, shuffledCond.length)).toList();

  final result = [...pickedCore, ...pickedCond];

  // Step 3: Ensure at least 1 rest (positive energy) and 1 work (negative energy)
  final hasRest = result.any((a) => a.energyEffect > 0);
  final hasWork = result.any((a) => a.energyEffect < 0);

  // If missing rest, try to replace a non-core action with a rest action
  if (!hasRest) {
    final allRest = [
      ...condEligible.where((a) => a.energyEffect > 0),
      ...coreEligible.where((a) => a.energyEffect > 0),
    ];
    if (allRest.isNotEmpty) {
      final nonCoreIdx = result.indexWhere((a) => !a.core);
      if (nonCoreIdx >= 0) {
        final rest = _shuffle(allRest).first;
        if (!result.any((a) => a.id == rest.id)) {
          result[nonCoreIdx] = rest;
        }
      }
    }
  }

  if (!hasWork) {
    final allWork = [
      ...coreEligible.where((a) => a.energyEffect < 0),
      ...condEligible.where((a) => a.energyEffect < 0),
    ];
    if (allWork.isNotEmpty) {
      final nonCoreIdx = result.indexWhere((a) => !a.core);
      if (nonCoreIdx >= 0) {
        final work = _shuffle(allWork).first;
        if (!result.any((a) => a.id == work.id)) {
          result[nonCoreIdx] = work;
        }
      }
    }
  }

  return _shuffle(result);
}

bool _isConditionMet(ActionCondition? cond, GameState state, List<String> skills) {
  if (cond == null) return true;
  if (cond.minDay != null && state.day < cond.minDay!) return false;
  if (cond.minKpi != null && state.kpi < cond.minKpi!) return false;
  if (cond.maxKpi != null && state.kpi >= cond.maxKpi!) return false;
  if (cond.weekendOnly && !isWeekend(state.day)) return false;
  if (cond.requiresSkill != null && !skills.contains(cond.requiresSkill)) return false;
  return true;
}
