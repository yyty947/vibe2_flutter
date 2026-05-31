import '../models/ending_type.dart';

/// Phase transition rules. Mapping: current phase → set of allowed target phases.
/// TECH_ARCH §3.2 / AGENTS.md §4.2.
const legalTransitions = <GamePhase, Set<GamePhase>>{
  GamePhase.title: {GamePhase.opening},
  GamePhase.opening: {GamePhase.morning},
  GamePhase.morning: {GamePhase.afternoon},
  GamePhase.afternoon: {GamePhase.event},
  GamePhase.event: {GamePhase.settlement},
  GamePhase.settlement: {GamePhase.ending, GamePhase.opening},
  GamePhase.ending: {GamePhase.title},
};

/// Validate that [from] → [to] is a legal phase transition.
bool isValidTransition(GamePhase from, GamePhase to) {
  return legalTransitions[from]?.contains(to) ?? false;
}

/// Get the expected next phase for a given trigger action.
/// Returns `null` if the trigger is not valid from [current].
GamePhase? getNextPhase(GamePhase current, String trigger) {
  switch (trigger) {
    case 'new_game':
    case 'continue':
      return current == GamePhase.title ? GamePhase.opening : null;
    case 'opening_end':
      return current == GamePhase.opening ? GamePhase.morning : null;
    case 'morning_action':
      return current == GamePhase.morning ? GamePhase.afternoon : null;
    case 'afternoon_action':
      return current == GamePhase.afternoon ? GamePhase.event : null;
    case 'event_done':
      return current == GamePhase.event ? GamePhase.settlement : null;
    case 'ending_triggered':
      return current == GamePhase.settlement ? GamePhase.ending : null;
    case 'no_ending':
      return current == GamePhase.settlement ? GamePhase.opening : null;
    case 'restart':
      return current == GamePhase.ending ? GamePhase.title : null;
    default:
      return null;
  }
}
