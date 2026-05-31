import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/models/ending_type.dart';
import 'package:frontend_survival/logic/game_loop.dart';

void main() {
  // ============================================================
  // isValidTransition — legal transitions
  // ============================================================

  group('isValidTransition — legal', () {
    test('TITLE → OPENING (new game)', () {
      expect(isValidTransition(GamePhase.title, GamePhase.opening), true);
    });

    test('OPENING → MORNING (opening skipped)', () {
      expect(isValidTransition(GamePhase.opening, GamePhase.morning), true);
    });

    test('MORNING → AFTERNOON (morning action)', () {
      expect(isValidTransition(GamePhase.morning, GamePhase.afternoon), true);
    });

    test('AFTERNOON → EVENT (afternoon action)', () {
      expect(isValidTransition(GamePhase.afternoon, GamePhase.event), true);
    });

    test('EVENT → SETTLEMENT (event resolved)', () {
      expect(isValidTransition(GamePhase.event, GamePhase.settlement), true);
    });

    test('SETTLEMENT → ENDING (ending triggered)', () {
      expect(isValidTransition(GamePhase.settlement, GamePhase.ending), true);
    });

    test('SETTLEMENT → OPENING (no ending, next day)', () {
      expect(isValidTransition(GamePhase.settlement, GamePhase.opening), true);
    });

    test('ENDING → TITLE (restart)', () {
      expect(isValidTransition(GamePhase.ending, GamePhase.title), true);
    });
  });

  // ============================================================
  // isValidTransition — illegal transitions (≥15)
  // ============================================================

  group('isValidTransition — illegal', () {
    test('MORNING → TITLE (no reverse to title)', () {
      expect(isValidTransition(GamePhase.morning, GamePhase.title), false);
    });

    test('AFTERNOON → TITLE (no reverse to title)', () {
      expect(isValidTransition(GamePhase.afternoon, GamePhase.title), false);
    });

    test('EVENT → TITLE (no reverse to title)', () {
      expect(isValidTransition(GamePhase.event, GamePhase.title), false);
    });

    test('EVENT → OPENING (no skip settlement)', () {
      expect(isValidTransition(GamePhase.event, GamePhase.opening), false);
    });

    test('MORNING → EVENT (no skip afternoon)', () {
      expect(isValidTransition(GamePhase.morning, GamePhase.event), false);
    });

    test('AFTERNOON → SETTLEMENT (no skip event)', () {
      expect(isValidTransition(GamePhase.afternoon, GamePhase.settlement), false);
    });

    test('MORNING → SETTLEMENT (no double skip)', () {
      expect(isValidTransition(GamePhase.morning, GamePhase.settlement), false);
    });

    test('OPENING → EVENT (no skip morning/afternoon)', () {
      expect(isValidTransition(GamePhase.opening, GamePhase.event), false);
    });

    test('OPENING → AFTERNOON (no skip morning)', () {
      expect(isValidTransition(GamePhase.opening, GamePhase.afternoon), false);
    });

    test('OPENING → SETTLEMENT (no skip all)', () {
      expect(isValidTransition(GamePhase.opening, GamePhase.settlement), false);
    });

    test('TITLE → MORNING (must go through opening)', () {
      expect(isValidTransition(GamePhase.title, GamePhase.morning), false);
    });

    test('TITLE → SETTLEMENT (must go through game)', () {
      expect(isValidTransition(GamePhase.title, GamePhase.settlement), false);
    });

    test('TITLE → ENDING (no direct to ending)', () {
      expect(isValidTransition(GamePhase.title, GamePhase.ending), false);
    });

    test('ENDING → OPENING (only TITLE allowed from ENDING)', () {
      expect(isValidTransition(GamePhase.ending, GamePhase.opening), false);
    });

    test('ENDING → MORNING (only TITLE allowed from ENDING)', () {
      expect(isValidTransition(GamePhase.ending, GamePhase.morning), false);
    });

    test('ENDING → SETTLEMENT (only TITLE allowed from ENDING)', () {
      expect(isValidTransition(GamePhase.ending, GamePhase.settlement), false);
    });

    test('EVENT → MORNING (no reverse)', () {
      expect(isValidTransition(GamePhase.event, GamePhase.morning), false);
    });

    test('AFTERNOON → MORNING (no reverse)', () {
      expect(isValidTransition(GamePhase.afternoon, GamePhase.morning), false);
    });
  });

  // ============================================================
  // getNextPhase — valid triggers
  // ============================================================

  group('getNextPhase — valid triggers', () {
    test('new_game from TITLE → OPENING', () {
      expect(getNextPhase(GamePhase.title, 'new_game'), GamePhase.opening);
    });

    test('continue from TITLE → OPENING', () {
      expect(getNextPhase(GamePhase.title, 'continue'), GamePhase.opening);
    });

    test('opening_end from OPENING → MORNING', () {
      expect(getNextPhase(GamePhase.opening, 'opening_end'), GamePhase.morning);
    });

    test('morning_action from MORNING → AFTERNOON', () {
      expect(getNextPhase(GamePhase.morning, 'morning_action'), GamePhase.afternoon);
    });

    test('afternoon_action from AFTERNOON → EVENT', () {
      expect(getNextPhase(GamePhase.afternoon, 'afternoon_action'), GamePhase.event);
    });

    test('event_done from EVENT → SETTLEMENT', () {
      expect(getNextPhase(GamePhase.event, 'event_done'), GamePhase.settlement);
    });

    test('ending_triggered from SETTLEMENT → ENDING', () {
      expect(getNextPhase(GamePhase.settlement, 'ending_triggered'), GamePhase.ending);
    });

    test('no_ending from SETTLEMENT → OPENING', () {
      expect(getNextPhase(GamePhase.settlement, 'no_ending'), GamePhase.opening);
    });

    test('restart from ENDING → TITLE', () {
      expect(getNextPhase(GamePhase.ending, 'restart'), GamePhase.title);
    });
  });

  // ============================================================
  // getNextPhase — invalid triggers (returns null)
  // ============================================================

  group('getNextPhase — invalid triggers', () {
    test('new_game not from TITLE returns null', () {
      expect(getNextPhase(GamePhase.morning, 'new_game'), isNull);
    });

    test('morning_action not from MORNING returns null', () {
      expect(getNextPhase(GamePhase.afternoon, 'morning_action'), isNull);
    });

    test('afternoon_action not from AFTERNOON returns null', () {
      expect(getNextPhase(GamePhase.morning, 'afternoon_action'), isNull);
    });

    test('restart not from ENDING returns null', () {
      expect(getNextPhase(GamePhase.title, 'restart'), isNull);
    });

    test('unknown trigger returns null', () {
      expect(getNextPhase(GamePhase.morning, 'bogus'), isNull);
    });
  });

  // ============================================================
  // Full game cycle simulation
  // ============================================================

  group('full game cycle', () {
    test('TITLE → Day 2 OPENING via all 7 phases', () {
      // Simulate a complete day cycle using isValidTransition
      final steps = [
        (GamePhase.title, GamePhase.opening),       // new_game
        (GamePhase.opening, GamePhase.morning),      // opening_end
        (GamePhase.morning, GamePhase.afternoon),    // morning_action
        (GamePhase.afternoon, GamePhase.event),      // afternoon_action
        (GamePhase.event, GamePhase.settlement),     // event_done
        (GamePhase.settlement, GamePhase.opening),   // no_ending → Day 2
      ];

      for (final (from, to) in steps) {
        expect(isValidTransition(from, to), true, reason: '$from → $to');
      }
    });

    test('TITLE → ENDING → TITLE complete round trip', () {
      expect(isValidTransition(GamePhase.title, GamePhase.opening), true);
      // ... (game plays out)
      expect(isValidTransition(GamePhase.settlement, GamePhase.ending), true);
      expect(isValidTransition(GamePhase.ending, GamePhase.title), true);
    });
  });
}
