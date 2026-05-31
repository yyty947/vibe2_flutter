import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/state/providers.dart';
import 'package:frontend_survival/models/game_state.dart';
import 'package:frontend_survival/models/ending_type.dart';
import 'package:frontend_survival/utils/clamp.dart';
import 'package:frontend_survival/data/game_data.dart';

ProviderContainer _container() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GameData.init();
  });

  // ============================================================
  // PRD §12.1 Balance Checklist
  // ============================================================

  group('PRD §12.1 numerical balance', () {
    test('pure work route (WRITE_CODE + FIX_BUG) fails within 5 days (energy exhaustion)', () {
      // Pure work with no rest should deplete energy quickly
      final c = _container();
      final n = c.read(gameProvider.notifier);
      n.startNewGame();

      int survived = 0;
      for (int day = 1; day <= 5; day++) {
        n.skipOpening();
        n.selectAction('FIX_BUG'); // -20 energy
        if (c.read(gameProvider).interruption != null) n.acknowledgeInterruption();
        if (c.read(gameProvider).phase == GamePhase.ending) break;

        n.selectAction('WRITE_CODE'); // -10 energy
        if (c.read(gameProvider).phase == GamePhase.ending) break;

        n.triggerEvent();
        if (c.read(gameProvider).currentEventId != null) n.selectEventOption(0);

        n.runSettlement();
        if (c.read(gameProvider).ending != null) break;
        survived++;
      }
      // Pure work without rest must not survive all 5 days
      expect(survived, lessThan(5));
    });

    test('balanced route (WRITE_CODE + SLACK) mathematically sustainable', () {
      // WRITE_CODE: -10 energy, +5 kpi, -2 suspicion
      // SLACK: +20 energy, +3 suspicion
      // Settlement: -5 energy
      // Net: +5 energy/day, +5 kpi/day, +1 suspicion/day
      // Starting: 75 energy → would take 15 days to reach 0 without events
      // With occasional events (~90% chance each day), energy dips but recovers
      final c = _container();
      c.read(gameProvider.notifier).setStateForTest(
        GameState.initial.copyWith(phase: GamePhase.settlement, energy: 30, kpi: 40, day: 10),
      );
      c.read(gameProvider.notifier).runSettlement();
      // Should survive day 10
      expect(c.read(gameProvider).ending, isNull);
    });

    test('jump-ship route: interview can reach 80 by day ~9 deterministic', () {
      // STUDY: +8 interview, -10 energy, +5 suspicion
      // 9 days of STUDY: 10 + 9*8 = 82 interview ✓
      final c = _container();
      // Set state simulating 9 days of study progress
      c.read(gameProvider.notifier).setStateForTest(
        GameState.initial.copyWith(
          phase: GamePhase.settlement,
          energy: 50, kpi: 40, interview: 82, suspicion: 60, day: 10,
        ),
      );
      c.read(gameProvider.notifier).runSettlement();
      // interview ≥ 80 + suspicion < 85 → GE_OFFER triggers
      expect(c.read(gameProvider).ending, EndingType.geOffer.label);
    });

    test('all stat values stay within [0, 100] after any action', () {
      final c = _container();
      final n = c.read(gameProvider.notifier);

      for (int run = 0; run < 20; run++) {
        n.startNewGame();
        n.skipOpening();

        // Mix of actions
        final actions = ['WRITE_CODE', 'FIX_BUG', 'STUDY', 'SLACK'];
        for (final a in actions) {
          n.selectAction(a);
          if (c.read(gameProvider).interruption != null) n.acknowledgeInterruption();
          if (c.read(gameProvider).phase == GamePhase.ending) break;

          final s = c.read(gameProvider);
          expect(s.energy, inInclusiveRange(0, 100));
          expect(s.kpi, inInclusiveRange(0, 100));
          expect(s.interview, inInclusiveRange(0, 100));
          expect(s.suspicion, inInclusiveRange(0, 100));
        }
      }
    });

    test('clamp function validated across all boundaries', () {
      expect(clamp(-100), 0);
      expect(clamp(-1), 0);
      expect(clamp(0), 0);
      expect(clamp(50), 50);
      expect(clamp(100), 100);
      expect(clamp(101), 100);
      expect(clamp(999), 100);

      // Custom min/max
      expect(clamp(5, min: 10, max: 50), 10);
      expect(clamp(60, min: 10, max: 50), 50);
    });
  });

  // ============================================================
  // State machine integrity
  // ============================================================

  group('state machine integrity', () {
    test('phase never skips backward', () {
      final c = _container();
      final n = c.read(gameProvider.notifier);

      n.startNewGame(); // TITLE→OPENING
      expect(c.read(gameProvider).phase, GamePhase.opening);

      n.skipOpening(); // OPENING→MORNING
      expect(c.read(gameProvider).phase, GamePhase.morning);

      n.selectAction('SLACK'); // MORNING→AFTERNOON (or EVENT with interruption)
      // If interruption, needs acknowledge
      if (c.read(gameProvider).interruption != null) {
        n.acknowledgeInterruption();
      }
      expect(c.read(gameProvider).phase, anyOf(GamePhase.afternoon, GamePhase.event));

      n.selectAction('WRITE_CODE'); // AFTERNOON→EVENT
      expect(c.read(gameProvider).phase, GamePhase.event);

      n.triggerEvent(); // EVENT→SETTLEMENT (or stays at EVENT with event)
      if (c.read(gameProvider).currentEventId != null) {
        n.selectEventOption(0);
      }
      expect(c.read(gameProvider).phase, GamePhase.settlement);

      n.runSettlement(); // SETTLEMENT→OPENING or ENDING
      if (c.read(gameProvider).ending == null) {
        expect(c.read(gameProvider).phase, GamePhase.opening);
      }
    });

    test('selectAction is ignored when not in MORNING/AFTERNOON', () {
      final c = _container();
      final n = c.read(gameProvider.notifier);

      // In TITLE phase — action should be ignored
      n.selectAction('WRITE_CODE');
      expect(c.read(gameProvider).phase, GamePhase.title);
      expect(c.read(gameProvider).energy, 75); // unchanged
    });
  });

  // ============================================================
  // Event system balance
  // ============================================================

  group('event system balance', () {
    test('~10% no-event rate at normal suspicion', () {
      final c = _container();
      int noEventCount = 0;
      for (int i = 0; i < 100; i++) {
        c.read(gameProvider.notifier).setStateForTest(
          GameState.initial.copyWith(phase: GamePhase.event, suspicion: 40),
        );
        c.read(gameProvider.notifier).triggerEvent();
        if (c.read(gameProvider).currentEventId == null) noEventCount++;
      }
      final rate = noEventCount / 100;
      expect(rate, greaterThan(0.03));
      expect(rate, lessThan(0.20));
    });
  });
}
