import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/logic/action_resolver.dart';
import 'package:frontend_survival/models/game_state.dart';
import 'package:frontend_survival/data/game_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GameData.init();
  });

  // ============================================================
  // Streak penalty
  // ============================================================

  group('streak penalty', () {
    test('SLACK: 1st use = +20 energy', () {
      final s = GameState.initial.copyWith(streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, 20);
    });

    test('SLACK: 2nd consecutive = +14 energy', () {
      final s = GameState.initial.copyWith(streakActionId: 'SLACK', streakCount: 2);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, 14);
    });

    test('SLACK: 3rd consecutive = +8 energy', () {
      final s = GameState.initial.copyWith(streakActionId: 'SLACK', streakCount: 3);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, 8);
    });

    test('SLACK: 4th+ consecutive = +3 energy', () {
      final s = GameState.initial.copyWith(streakActionId: 'SLACK', streakCount: 5);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, 3);
    });

    test('WRITE_CODE: 1st use = -10 energy, +5 kpi, -2 suspicion', () {
      final s = GameState.initial.copyWith(streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'WRITE_CODE'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, -10);
      expect(result.deltas.kpi, 5);
      expect(result.deltas.suspicion, -2);
    });

    test('Different action resets streak (no penalty)', () {
      // Streak is STUDY but player picks SLACK — no penalty
      final s = GameState.initial.copyWith(streakActionId: 'STUDY', streakCount: 3);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      // Should use SLACK base value (tier 1, not penalized)
      expect(result.deltas.energy, 20);
    });

    test('FIX_BUG 1st use = -20 energy, +15 kpi', () {
      final s = GameState.initial.copyWith(streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'FIX_BUG'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, -20);
      expect(result.deltas.kpi, 15);
    });
  });

  // ============================================================
  // Weekend bonus
  // ============================================================

  group('weekend bonus', () {
    test('SLACK on weekend gives +5 extra energy', () {
      final s = GameState.initial.copyWith(day: 6, streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, 25); // 20 + 5
    });

    test('STUDY on weekend gives +3 extra interview', () {
      final s = GameState.initial.copyWith(day: 7, streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'STUDY'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.interview, 11); // 8 + 3
    });

    test('No weekend bonus on weekday (day 5)', () {
      final s = GameState.initial.copyWith(day: 5, streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'SLACK'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.deltas.energy, 20); // base only
    });
  });

  // ============================================================
  // Spot check (probabilistic — test that it CAN fire with extreme stats)
  // ============================================================

  group('spot check', () {
    test('no spot check when suspicion < 70', () {
      final s = GameState.initial.copyWith(suspicion: 50, streakActionId: '', streakCount: 0);
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'STUDY'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [],
      );
      expect(result.spotCheckLog, isNull);
    });
  });

  // ============================================================
  // Skill passives
  // ============================================================

  group('skill passives', () {
    test('ENERGY_T1 reduces energy cost by 10%', () {
      final s = GameState.initial.copyWith(streakActionId: '', streakCount: 0);
      final energyT1 = GameData.skills.firstWhere((sk) => sk.id == 'ENERGY_T1');
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'WRITE_CODE'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [energyT1],
      );
      // WRITE_CODE base: -10 * (1 - 0.10) = -9
      expect(result.deltas.energy, -9);
    });

    test('TECH_T1 increases KPI gain by 10%', () {
      final s = GameState.initial.copyWith(streakActionId: '', streakCount: 0);
      final techT1 = GameData.skills.firstWhere((sk) => sk.id == 'TECH_T1');
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'WRITE_CODE'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [techT1],
      );
      // WRITE_CODE base kpi: 5 * (1 + 0.10) = 5.5 round = 6
      expect(result.deltas.kpi, 6);
    });

    test('INTERVIEW_T1 increases interview gain by 10%', () {
      final s = GameState.initial.copyWith(streakActionId: '', streakCount: 0);
      final ivT1 = GameData.skills.firstWhere((sk) => sk.id == 'INTERVIEW_T1');
      final result = resolveActionEffects(
        action: GameData.actions.firstWhere((a) => a.id == 'STUDY'),
        state: s,
        modifier: null,
        activeStatuses: [],
        skills: [ivT1],
      );
      // STUDY base interview: 8 * (1 + 0.10) = 8.8 round = 9
      expect(result.deltas.interview, 9);
    });
  });
}
