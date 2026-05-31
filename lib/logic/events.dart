import 'dart:math';
import '../models/game_event.dart';
import '../models/game_state.dart';
import '../utils/weekend.dart';

final _random = Random();

/// Check if a serialized event condition is met by current game state.
bool isEventConditionMet(EventCondition? condition, GameState state) {
  if (condition == null) return true;
  if (condition.minDay != null && state.day < condition.minDay!) return false;
  if (condition.maxDay != null && state.day > condition.maxDay!) return false;
  if (condition.minSuspicion != null && state.suspicion < condition.minSuspicion!) return false;
  if (condition.maxSuspicion != null && state.suspicion > condition.maxSuspicion!) return false;
  if (condition.minKpi != null && state.kpi < condition.minKpi!) return false;
  if (condition.maxKpi != null && state.kpi > condition.maxKpi!) return false;
  if (condition.minInterview != null && state.interview < condition.minInterview!) return false;
  if (condition.maxInterview != null && state.interview > condition.maxInterview!) return false;
  return true;
}

/// Sample a random event (TECH_ARCH §5.1).
///
/// Returns a GameEvent or null (no event triggered).
/// Algorithm:
///  1. Null chance: 10% base, 5% when suspicion >= 80
///  2. Filter eligible events by condition
///  3. Weight adjustment: 50% decay for previous, highRisk boost at high suspicion
///  4. Weighted random selection
GameEvent? sampleEvent(GameState state, List<GameEvent> allEvents) {
  // Step 1: Null chance
  final nullChance = state.suspicion >= 80 ? 0.05 : 0.1;
  if (_random.nextDouble() < nullChance) return null;

  // Step 2: Filter eligible events
  final eligible = allEvents.where((e) {
    if (!isEventConditionMet(e.condition, state)) return false;
    // Weekends filter out high-risk events
    if (e.highRisk && isWeekend(state.day)) return false;
    return true;
  }).toList();
  if (eligible.isEmpty) return null;

  // Step 3: Apply weight adjustments
  final weighted = eligible.map((e) {
    double w = e.weight.toDouble();
    // 3a: 50% decay for previously triggered events
    if (state.eventHistory.contains(e.id)) w *= 0.5;
    // 3b: Progressive highRisk boost
    if (e.highRisk && state.suspicion >= 80) {
      w *= 3;
    } else if (e.highRisk && state.suspicion >= 50) {
      w *= 2;
    }
    return (event: e, weight: w);
  }).toList();

  // Step 4: Weighted random selection
  final totalWeight = weighted.fold<double>(0, (sum, w) => sum + w.weight);
  double rand = _random.nextDouble() * totalWeight;
  for (final w in weighted) {
    rand -= w.weight;
    if (rand <= 0) return w.event;
  }

  // Floating point fallback
  return eligible.last;
}
