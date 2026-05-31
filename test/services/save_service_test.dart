import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_survival/services/save_service.dart';
import 'package:frontend_survival/models/game_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SaveService', () {
    test('hasSave returns false when no save exists', () async {
      expect(await SaveService.hasSave(), false);
    });

    test('save and hasSave', () async {
      await SaveService.save(GameState.initial.copyWith(day: 5, energy: 60));
      expect(await SaveService.hasSave(), true);
    });

    test('load returns null when no save exists', () async {
      expect(await SaveService.load(), isNull);
    });

    test('save and load round-trip preserves all fields', () async {
      final original = GameState.initial.copyWith(
        energy: 42,
        kpi: 55,
        interview: 33,
        suspicion: 28,
        day: 12,
        eventHistory: ['EV_001', 'EV_005'],
        activeStatuses: ['TRUSTED'],
        streakActionId: 'STUDY',
        streakCount: 2,
        skillPoints: 5,
        skills: ['ENERGY_T1'],
      );
      await SaveService.save(original);

      final loaded = await SaveService.load();
      expect(loaded, isNotNull);
      expect(loaded!.energy, 42);
      expect(loaded.kpi, 55);
      expect(loaded.interview, 33);
      expect(loaded.suspicion, 28);
      expect(loaded.day, 12);
      expect(loaded.eventHistory, ['EV_001', 'EV_005']);
      expect(loaded.activeStatuses, ['TRUSTED']);
      expect(loaded.streakActionId, 'STUDY');
      expect(loaded.streakCount, 2);
      expect(loaded.skillPoints, 5);
      expect(loaded.skills, ['ENERGY_T1']);
    });

    test('load returns null for corrupted JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('frontend-survival-save', 'not valid json{{{');
      expect(await SaveService.load(), isNull);
    });

    test('load returns null for mismatched version', () async {
      final old = GameState.initial.copyWith(version: '0.5.0');
      await SaveService.save(old);
      expect(await SaveService.load(), isNull);
    });

    test('clear removes the save', () async {
      await SaveService.save(GameState.initial.copyWith(day: 3));
      expect(await SaveService.hasSave(), true);
      await SaveService.clear();
      expect(await SaveService.hasSave(), false);
    });

    test('clear is idempotent (no error when no save)', () async {
      await SaveService.clear(); // should not throw
      expect(await SaveService.hasSave(), false);
    });
  });
}
