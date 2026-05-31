import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/logic/action_pool.dart';
import 'package:frontend_survival/models/game_state.dart';
import 'package:frontend_survival/data/game_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GameData.init();
  });

  GameState makeState({
    int energy = 75,
    int day = 5,
    List<String> skills = const [],
  }) {
    return GameState.initial.copyWith(
      energy: energy,
      day: day,
      skills: skills,
    );
  }

  group('sampleActionPool', () {
    test('returns exactly 4 actions', () {
      final pool = sampleActionPool(makeState(), GameData.actions, []);
      expect(pool.length, 4);
    });

    test('contains at least 2 core actions', () {
      for (int i = 0; i < 10; i++) {
        final pool = sampleActionPool(makeState(), GameData.actions, []);
        final coreCount = pool.where((a) => a.core).length;
        expect(coreCount, greaterThanOrEqualTo(2), reason: 'Run $i: core=$coreCount');
      }
    });

    test('contains at least 1 rest (positive energy) action', () {
      for (int i = 0; i < 10; i++) {
        final pool = sampleActionPool(makeState(), GameData.actions, []);
        expect(pool.any((a) => a.energyEffect > 0), true, reason: 'Run $i');
      }
    });

    test('contains at least 1 work (negative energy) action', () {
      for (int i = 0; i < 10; i++) {
        final pool = sampleActionPool(makeState(), GameData.actions, []);
        expect(pool.any((a) => a.energyEffect < 0), true, reason: 'Run $i');
      }
    });

    test('excludes FIX_BUG when energy <= 20', () {
      final pool = sampleActionPool(makeState(energy: 15), GameData.actions, []);
      expect(pool.any((a) => a.id == 'FIX_BUG'), false);
    });

    test('includes FIX_BUG when energy > 20', () {
      int found = 0;
      for (int i = 0; i < 20; i++) {
        final pool = sampleActionPool(makeState(energy: 50), GameData.actions, []);
        if (pool.any((a) => a.id == 'FIX_BUG')) found++;
      }
      // FIX_BUG should appear at least sometimes when eligible
      expect(found, greaterThan(0));
    });

    test('returns no duplicate actions', () {
      for (int i = 0; i < 10; i++) {
        final pool = sampleActionPool(makeState(), GameData.actions, []);
        final ids = pool.map((a) => a.id).toSet();
        expect(ids.length, 4, reason: 'Run $i had duplicates: ${pool.map((a) => a.id)}');
      }
    });

    test('includes ARCH_REDESIGN when TECH_T3 is owned and energy > 45', () {
      int found = 0;
      for (int i = 0; i < 30; i++) {
        final pool = sampleActionPool(
          makeState(energy: 60, skills: ['TECH_T3']),
          GameData.actions,
          ['TECH_T3'],
        );
        if (pool.any((a) => a.id == 'ARCH_REDESIGN')) found++;
      }
      // ARCH_REDESIGN should appear sometimes (conditional, not guaranteed every sample)
      expect(found, greaterThan(0));
    });

    test('includes ALLIANCE when SOCIAL_T3 is owned', () {
      int found = 0;
      for (int i = 0; i < 30; i++) {
        final pool = sampleActionPool(
          makeState(skills: ['SOCIAL_T3']),
          GameData.actions,
          ['SOCIAL_T3'],
        );
        if (pool.any((a) => a.id == 'ALLIANCE')) found++;
      }
      expect(found, greaterThan(0));
    });
  });
}
