import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_survival/services/save_service.dart';
import 'package:frontend_survival/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('save/load round-trip', () {
    test('full state round-trip: save → load → verify all fields', () async {
      final original = GameState.initial.copyWith(
        energy: 33, kpi: 67, interview: 45, suspicion: 55,
        day: 18,
        eventHistory: ['EV_001', 'EV_005', 'EV_012'],
        currentEventId: null as Object?,
        ending: null as Object?,
        activeStatuses: ['TRUSTED', 'UNDER_SURVEIL'],
        streakActionId: 'STUDY',
        streakCount: 3,
        skillPoints: 8,
        skills: ['ENERGY_T1', 'TECH_T1', 'SOCIAL_T1'],
        dayModifier: 'MOD_BOSS_AWAY' as Object?,
        savedAt: 1712345678000,
      );

      await SaveService.save(original);
      final loaded = await SaveService.load();

      expect(loaded, isNotNull);
      expect(loaded!.energy, 33);
      expect(loaded.kpi, 67);
      expect(loaded.interview, 45);
      expect(loaded.suspicion, 55);
      expect(loaded.day, 18);
      expect(loaded.eventHistory, ['EV_001', 'EV_005', 'EV_012']);
      expect(loaded.activeStatuses, ['TRUSTED', 'UNDER_SURVEIL']);
      expect(loaded.streakActionId, 'STUDY');
      expect(loaded.streakCount, 3);
      expect(loaded.skillPoints, 8);
      expect(loaded.skills, ['ENERGY_T1', 'TECH_T1', 'SOCIAL_T1']);
      expect(loaded.dayModifier, 'MOD_BOSS_AWAY');
      expect(loaded.savedAt, 1712345678000);
      expect(loaded.currentEventId, isNull);
      expect(loaded.ending, isNull);
    });

    test('save and clear round-trip', () async {
      await SaveService.save(GameState.initial.copyWith(day: 10));
      expect(await SaveService.hasSave(), true);
      await SaveService.clear();
      expect(await SaveService.hasSave(), false);
      expect(await SaveService.load(), isNull);
    });

    test('version mismatch discards save', () async {
      final old = GameState.initial.copyWith(version: '0.1.0', day: 25);
      await SaveService.save(old);
      expect(await SaveService.load(), isNull);
    });

    test('corrupted JSON returns null gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('frontend-survival-save', '{{corrupted');
      expect(await SaveService.load(), isNull);
    });

    test('empty save returns null', () async {
      expect(await SaveService.load(), isNull);
    });

    test('save key is consistent', () async {
      await SaveService.save(GameState.initial);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('frontend-survival-save'), true);
    });

    test('multiple save cycles do not corrupt data', () async {
      for (int day = 1; day <= 5; day++) {
        final state = GameState.initial.copyWith(day: day, energy: 80 - day * 5);
        await SaveService.save(state);
        final loaded = await SaveService.load();
        expect(loaded, isNotNull);
        expect(loaded!.day, day);
      }
    });

    test('clear is idempotent', () async {
      await SaveService.clear();
      await SaveService.clear();
      expect(await SaveService.hasSave(), false);
    });
  });
}
