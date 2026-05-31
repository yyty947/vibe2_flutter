import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/state/providers.dart';
import 'package:frontend_survival/models/game_state.dart';
import 'package:frontend_survival/models/ending_type.dart';
import 'package:frontend_survival/models/log_entry.dart';
import 'package:frontend_survival/data/game_data.dart';
import 'package:frontend_survival/logic/endings.dart' as endings;

/// Helper: directly set state to a specific snapshot (bypasses transitions).
void _setState(ProviderContainer c, GameState s) {
  c.read(gameProvider.notifier).setStateForTest(s);
}

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
  // Initial state & basic phase transitions
  // ============================================================

  group('GameNotifier — initial state', () {
    test('build returns GameState.initial', () {
      final c = _container();
      final s = c.read(gameProvider);
      expect(s.energy, 75);
      expect(s.kpi, 50);
      expect(s.interview, 10);
      expect(s.suspicion, 20);
      expect(s.day, 1);
      expect(s.phase, GamePhase.title);
      expect(s.logs, isEmpty);
      expect(s.version, GameState.gameVersion);
    });
  });

  group('GameNotifier — startNewGame', () {
    test('sets phase to OPENING and savedAt > 0', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      final s = c.read(gameProvider);
      expect(s.phase, GamePhase.opening);
      expect(s.day, 1);
      expect(s.savedAt, greaterThan(0));
    });
  });

  group('GameNotifier — continueGameFrom', () {
    test('restores saved state and sets phase to OPENING', () {
      final c = _container();
      final saved = GameState.initial.copyWith(
        energy: 42,
        kpi: 55,
        day: 10,
        eventHistory: ['EV_001'],
      );
      c.read(gameProvider.notifier).continueGameFrom(saved);
      final s = c.read(gameProvider);
      expect(s.phase, GamePhase.opening);
      expect(s.energy, 42);
      expect(s.kpi, 55);
      expect(s.day, 10);
      expect(s.eventHistory, ['EV_001']);
    });

    test('discards save with mismatched version', () {
      final c = _container();
      final saved = GameState.initial.copyWith(version: '0.5.0', day: 20);
      c.read(gameProvider.notifier).continueGameFrom(saved);
      final s = c.read(gameProvider);
      expect(s.day, 1); // fresh game
      expect(s.phase, GamePhase.opening);
    });
  });

  group('GameNotifier — skipOpening', () {
    test('transitions OPENING → MORNING', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      expect(c.read(gameProvider).phase, GamePhase.morning);
    });

    test('ignores call when not in OPENING', () {
      final c = _container();
      c.read(gameProvider.notifier).skipOpening(); // TITLE state
      expect(c.read(gameProvider).phase, GamePhase.title); // unchanged
    });
  });

  // ============================================================
  // selectAction
  // ============================================================

  group('GameNotifier — selectAction', () {
    test('applies energy effect with clamp', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      // WRITE_CODE: energy -10
      c.read(gameProvider.notifier).selectAction('WRITE_CODE');
      final s = c.read(gameProvider);
      expect(s.energy, 65); // 75 - 10
      expect(s.kpi, 56); // 50 + WRITE_CODE 5 boosted by initial TRUSTED status
    });

    test('transitions MORNING → AFTERNOON', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).selectAction('SLACK');
      expect(c.read(gameProvider).phase, GamePhase.afternoon);
    });

    test('transitions AFTERNOON → EVENT', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).selectAction('SLACK'); // morning→afternoon
      c
          .read(gameProvider.notifier)
          .selectAction('WRITE_CODE'); // afternoon→event
      expect(c.read(gameProvider).phase, GamePhase.event);
    });

    test('blocks FIX_BUG when energy <= 20', () {
      final c = _container();
      _setState(
        c,
        GameState.initial.copyWith(phase: GamePhase.morning, energy: 15),
      );
      c.read(gameProvider.notifier).selectAction('FIX_BUG');
      expect(c.read(gameProvider).energy, 15); // blocked, no change
    });

    test('adds log entry after action', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).selectAction('WRITE_CODE');
      expect(c.read(gameProvider).logs, isNotEmpty);
      // At least one log has COMMIT type (the action feedback)
      expect(
        c.read(gameProvider).logs.any((l) => l.type == LogType.commit),
        true,
      );
    });

    test('increments actionStats for WRITE_CODE', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).selectAction('WRITE_CODE');
      expect(c.read(gameProvider).actionStats.writeCode, 1);
      expect(c.read(gameProvider).actionStats.fixBug, 0);
    });

    test('tracks action streak', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).selectAction('WRITE_CODE');
      expect(c.read(gameProvider).streakActionId, 'WRITE_CODE');
      expect(c.read(gameProvider).streakCount, 1);
    });
  });

  // ============================================================
  // selectEventOption & skipEvent
  // ============================================================

  group('GameNotifier — selectEventOption', () {
    test('applies event effects and advances to SETTLEMENT', () {
      final c = _container();
      c
          .read(gameProvider.notifier)
          .setStateForTest(
            GameState.initial.copyWith(
              phase: GamePhase.event,
              currentEventId: GameData.events[0].id,
            ),
          );
      // Verify pre-condition
      expect(c.read(gameProvider).phase, GamePhase.event);
      expect(c.read(gameProvider).currentEventId, isNotNull);

      c.read(gameProvider.notifier).selectEventOption(0);
      final s = c.read(gameProvider);
      expect(s.phase, GamePhase.settlement);
      expect(s.currentEventId, isNull);
    });
  });

  group('GameNotifier — skipEvent', () {
    test('skips event and advances to SETTLEMENT', () {
      final c = _container();
      _setState(c, GameState.initial.copyWith(phase: GamePhase.event));
      c.read(gameProvider.notifier).skipEvent();
      expect(c.read(gameProvider).phase, GamePhase.settlement);
    });
  });

  // ============================================================
  // runSettlement
  // ============================================================

  group('GameNotifier — runSettlement', () {
    test('drains 5 energy and advances to next day', () {
      final c = _container();
      _setState(
        c,
        GameState.initial.copyWith(
          phase: GamePhase.settlement,
          energy: 30,
          day: 5,
        ),
      );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).energy, 25);
      expect(c.read(gameProvider).day, 6);
      expect(c.read(gameProvider).phase, GamePhase.opening);
    });

    test('triggers BE_DEATH when energy reaches 0 after drain', () {
      final c = _container();
      _setState(
        c,
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

    test('triggers BE_FIRED when KPI reaches 0', () {
      final c = _container();
      _setState(
        c,
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

    test('triggers GE_OFFER when interview >= 80 and suspicion < 85', () {
      final c = _container();
      _setState(
        c,
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

    test('blocks GE_OFFER when suspicion >= 85 (Patch-F02)', () {
      final c = _container();
      _setState(
        c,
        GameState.initial.copyWith(
          phase: GamePhase.settlement,
          energy: 50,
          kpi: 50,
          interview: 85,
          suspicion: 90,
          day: 5,
        ),
      );
      c.read(gameProvider.notifier).runSettlement();
      expect(c.read(gameProvider).ending, isNull); // Not GE_OFFER
    });

    test('Day 30: HE_KING with perfect stats', () {
      final c = _container();
      _setState(
        c,
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

    test('Day 30: BE_FIRED as catch-all (Patch-011)', () {
      final c = _container();
      _setState(
        c,
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

    test(
      'Day 30: daily check runs first (Patch-010: energy=4 → BE_DEATH before HE_KING)',
      () {
        final c = _container();
        _setState(
          c,
          GameState.initial.copyWith(
            phase: GamePhase.settlement,
            energy: 4, // -5 drain → 0 → BE_DEATH
            kpi: 80, // would be HE_KING
            interview: 50,
            suspicion: 20,
            day: 30,
          ),
        );
        c.read(gameProvider.notifier).runSettlement();
        expect(c.read(gameProvider).ending, EndingType.beDeath.label);
      },
    );
  });

  // ============================================================
  // restart
  // ============================================================

  group('GameNotifier — restart', () {
    test('resets state to initial', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).skipOpening();
      c.read(gameProvider.notifier).restart();
      final s = c.read(gameProvider);
      expect(s.phase, GamePhase.title);
      expect(s.day, 1);
      expect(s.energy, 75);
      expect(s.logs, isEmpty);
    });
  });

  // ============================================================
  // Helpers
  // ============================================================

  group('GameNotifier — helpers', () {
    test('addLog appends a log entry', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).addLog(LogType.alert, 'test message');
      final s = c.read(gameProvider);
      expect(s.logs.length, 2); // startNewGame logs the initial TRUSTED status
      expect(s.logs.last.message, 'test message');
      expect(s.logs.last.type, LogType.alert);
    });

    test('applyEffects updates stats with clamp', () {
      final c = _container();
      c.read(gameProvider.notifier).startNewGame();
      c.read(gameProvider.notifier).applyEffects({'energy': -100, 'kpi': 200});
      final s = c.read(gameProvider);
      expect(s.energy, 0); // clamped
      expect(s.kpi, 100); // clamped
    });

    test('setPhase changes phase', () {
      final c = _container();
      c.read(gameProvider.notifier).setPhase(GamePhase.ending);
      expect(c.read(gameProvider).phase, GamePhase.ending);
    });
  });

  // ============================================================
  // Static ending checks
  // ============================================================

  group('Endings (logic/endings.dart)', () {
    test('checkDailyEnding BE_DEATH when energy=0', () {
      final r = endings.checkDailyEnding(0, 50, 30, 40);
      expect(r, EndingType.beDeath.label);
    });

    test('checkDailyEnding BE_FIRED when kpi=0', () {
      final r = endings.checkDailyEnding(50, 0, 30, 40);
      expect(r, EndingType.beFired.label);
    });

    test('checkDailyEnding GE_OFFER blocked by suspicion >= 85', () {
      final r = endings.checkDailyEnding(50, 50, 85, 90);
      expect(r, isNull);
    });

    test('checkFinalEnding HE_KING', () {
      final r = endings.checkFinalEnding(40, 85, 50, 20);
      expect(r, EndingType.heKing.label);
    });

    test('checkFinalEnding NE_PEACE', () {
      final r = endings.checkFinalEnding(30, 40, 50, 50);
      expect(r, EndingType.nePeace.label);
    });

    test('checkFinalEnding BE_FIRED catch-all', () {
      final r = endings.checkFinalEnding(10, 10, 20, 80);
      expect(r, EndingType.beFired.label);
    });
  });
}
