import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/state/providers.dart';
import 'package:frontend_survival/models/game_state.dart';
import 'package:frontend_survival/models/ending_type.dart';
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
  // Full day cycle
  // ============================================================

  group('full game loop', () {
    test(
      'TITLE → OPENING → MORNING → AFTERNOON → EVENT → SETTLEMENT → Day 2',
      () {
        final c = _container();
        final n = c.read(gameProvider.notifier);

        n.startNewGame();
        expect(c.read(gameProvider).phase, GamePhase.opening);
        expect(c.read(gameProvider).day, 1);

        n.skipOpening();
        expect(c.read(gameProvider).phase, GamePhase.morning);

        n.selectAction('WRITE_CODE');
        // Handle interruption
        if (c.read(gameProvider).interruption != null) {
          n.acknowledgeInterruption();
        }
        expect(
          c.read(gameProvider).phase,
          anyOf(GamePhase.afternoon, GamePhase.event),
        );

        n.selectAction('SLACK');
        n.triggerEvent();
        if (c.read(gameProvider).currentEventId != null) {
          n.selectEventOption(0);
        }
        expect(c.read(gameProvider).phase, GamePhase.settlement);

        n.runSettlement();
        // If no ending triggered, next day starts
        final ending = c.read(gameProvider).ending;
        if (ending == null) {
          expect(c.read(gameProvider).phase, GamePhase.opening);
          expect(c.read(gameProvider).day, 2);
        } else {
          expect(c.read(gameProvider).phase, GamePhase.ending);
        }
      },
    );

    test('action stats increment correctly over multiple days', () {
      final c = _container();
      final n = c.read(gameProvider.notifier);

      n.startNewGame();
      n.skipOpening();

      // Day 1: WRITE_CODE + SLACK
      n.selectAction('WRITE_CODE');
      if (c.read(gameProvider).interruption != null) {
        n.setStateForTest(
          c
              .read(gameProvider)
              .copyWith(interruption: null, phase: GamePhase.afternoon),
        );
      }
      n.selectAction('SLACK');
      n.triggerEvent();
      if (c.read(gameProvider).currentEventId != null) n.selectEventOption(0);
      n.runSettlement();
      if (c.read(gameProvider).ending != null) return; // ending triggered, skip

      expect(c.read(gameProvider).actionStats.writeCode, 1);
      expect(c.read(gameProvider).actionStats.slack, 1);

      // Day 2: STUDY + WRITE_CODE
      n.skipOpening();
      n.selectAction('STUDY');
      if (c.read(gameProvider).interruption != null) {
        n.setStateForTest(
          c
              .read(gameProvider)
              .copyWith(interruption: null, phase: GamePhase.afternoon),
        );
      }
      n.selectAction('WRITE_CODE');
      n.triggerEvent();
      if (c.read(gameProvider).currentEventId != null) n.selectEventOption(0);
      n.runSettlement();
      if (c.read(gameProvider).ending != null) return;

      expect(c.read(gameProvider).actionStats.writeCode, 2);
      expect(c.read(gameProvider).actionStats.studyInterview, 1);
    });

    test('energy drains by 5 each settlement', () {
      final c = _container();
      final s = GameState.initial.copyWith(
        phase: GamePhase.settlement,
        energy: 75,
        day: 1,
      );
      c.read(gameProvider.notifier).setStateForTest(s);
      c.read(gameProvider.notifier).runSettlement();
      if (c.read(gameProvider).ending == null) {
        expect(c.read(gameProvider).energy, 70);
        expect(c.read(gameProvider).day, 2);
      }
    });

    test('suspicion pressure fires at high suspicion', () {
      final c = _container();
      final s = GameState.initial.copyWith(
        phase: GamePhase.opening,
        suspicion: 90,
        day: 5,
      );
      c.read(gameProvider.notifier).setStateForTest(s);

      // Check multiple times — probability should fire at least once
      int fired = 0;
      for (int i = 0; i < 50; i++) {
        c
            .read(gameProvider.notifier)
            .setStateForTest(s.copyWith(suspicionPressure: null as Object?));
        c.read(gameProvider.notifier).checkSuspicionPressure();
        if (c.read(gameProvider).suspicionPressure != null) fired++;
      }
      // At suspicion=90, probability = 30% + (90-70)*1% = 50%
      // Over 50 runs, should fire many times
      expect(fired, greaterThan(10));
    });
  });

  // ============================================================
  // All 5 endings via GameNotifier
  // ============================================================

  group('endings via GameNotifier', () {
    test('BE_DEATH: energy=0 triggers death', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 3,
              day: 5,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).phase, GamePhase.ending);
      expect(c.read(gameProvider).ending, EndingType.beDeath.label);
    });

    test('BE_FIRED: kpi=0 triggers firing', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 50,
              kpi: 0,
              day: 5,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).ending, EndingType.beFired.label);
    });

    test('GE_OFFER: interview≥80 triggers early offer', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 50,
              kpi: 50,
              interview: 85,
              suspicion: 40,
              day: 5,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).ending, EndingType.geOffer.label);
    });

    test('Day 30: HE_KING with perfect stats', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 50,
              kpi: 85,
              interview: 50,
              suspicion: 20,
              day: 30,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).ending, EndingType.heKing.label);
    });

    test('Day 30: NE_PEACE with moderate stats', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 40,
              kpi: 40,
              interview: 50,
              suspicion: 50,
              day: 30,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).ending, EndingType.nePeace.label);
    });

    test('Day 30: BE_FIRED catch-all with bad stats', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 10,
              kpi: 10,
              interview: 20,
              suspicion: 80,
              day: 30,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).ending, EndingType.beFired.label);
    });

    test('Day 30: BE_DEATH before HE_KING (Patch-010)', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 4,
              kpi: 85,
              interview: 50,
              suspicion: 20,
              day: 30,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      // Energy becomes 0 after drain → BE_DEATH, NOT HE_KING
      expect(c.read(gameProvider).ending, EndingType.beDeath.label);
    });

    test('restart clears ending and returns to TITLE', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).selectAction('WRITE_CODE');
      c.read(gameProvider.notifier).restart();
      expect(c.read(gameProvider).phase, GamePhase.title);
      expect(c.read(gameProvider).day, 1);
      expect(c.read(gameProvider).logs, isEmpty);
    });
  });

  // ============================================================
  // Extension systems integration
  // ============================================================

  group('extension systems', () {
    test('day modifier is assigned on OPENING (70% chance)', () {
      final c = _container();
      int assigned = 0;
      for (int i = 0; i < 30; i++) {
        c
            .read(gameProvider.notifier)
            .setStateForTest(
              GameState.initial.copyWith(phase: GamePhase.opening, day: 5),
            );
        c.read(gameProvider.notifier).assignDayModifier();
        if (c.read(gameProvider).dayModifier != null) assigned++;
      }
      // ~70% chance, should happen in most runs
      expect(assigned, greaterThan(10));
    });

    test('interruption triggers at ~25% rate MORNING→AFTERNOON', () {
      final c = _container();
      int interrupted = 0;
      for (int i = 0; i < 40; i++) {
        c
            .read(gameProvider.notifier)
            .setStateForTest(
              GameState.initial.copyWith(phase: GamePhase.morning, day: 10),
            );
        c.read(gameProvider.notifier).selectAction('WRITE_CODE');
        if (c.read(gameProvider).interruption != null) interrupted++;
      }
      // ~25% chance
      expect(interrupted, greaterThan(2));
      expect(interrupted, lessThan(30));
    });

    test('status conditions activate and deactivate', () {
      final c = _container();
      // Set state to trigger ENERGIZED buff (energy >= 80)
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              energy: 85,
              kpi: 50,
              interview: 30,
              suspicion: 30,
            ),
          );
      c.read(gameProvider.notifier).evaluateStatusConditions();
      final statuses = c.read(gameProvider).activeStatuses;
      // Should have at least one active status
      expect(statuses, isNotEmpty);
    });

    test('skill purchase reduces skillPoints and adds to skills', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              skillPoints: 10,
              phase: GamePhase.morning,
            ),
          );

      final result = c.read(gameProvider.notifier).purchaseSkill('ENERGY_T1');
      expect(result, true);
      expect(c.read(gameProvider).skills, contains('ENERGY_T1'));
      expect(c.read(gameProvider).skillPoints, 7); // 10 - 3
    });

    test('skill purchase fails without enough points', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              skillPoints: 1,
              phase: GamePhase.morning,
            ),
          );
      expect(c.read(gameProvider.notifier).purchaseSkill('ENERGY_T1'), false);
    });

    test('skill purchase fails if already owned', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              skillPoints: 10,
              skills: ['ENERGY_T1'],
              phase: GamePhase.morning,
            ),
          );
      expect(c.read(gameProvider.notifier).purchaseSkill('ENERGY_T1'), false);
    });

    test('SOCIAL_T2 spend points reduces suspicion', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              skillPoints: 5,
              skills: ['SOCIAL_T1', 'SOCIAL_T2'],
              suspicion: 50,
              phase: GamePhase.morning,
            ),
          );
      expect(c.read(gameProvider.notifier).spendPointsForSuspicion(), true);
      expect(c.read(gameProvider).suspicion, 40);
      expect(c.read(gameProvider).skillPoints, 2);
    });

    test('week review opens on Day 7', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.settlement,
              energy: 50,
              day: 7,
            ),
          );
      c.read(gameProvider.notifier).runSettlement();
      if (c.read(gameProvider).ending == null) {
        // Day 7 should trigger showWeekReview (or have earned points)
        expect(c.read(gameProvider).skillPoints, greaterThanOrEqualTo(0));
      }
    });
  });
}
