import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/logic/events.dart';
import 'package:frontend_survival/models/game_event.dart';
import 'package:frontend_survival/models/game_state.dart';
import 'package:frontend_survival/data/game_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await GameData.init();
  });

  GameState makeState({
    int energy = 50,
    int kpi = 50,
    int interview = 30,
    int suspicion = 40,
    int day = 5,
    List<String> eventHistory = const [],
  }) {
    return GameState.initial.copyWith(
      energy: energy,
      kpi: kpi,
      interview: interview,
      suspicion: suspicion,
      day: day,
      eventHistory: eventHistory,
    );
  }

  group('isEventConditionMet', () {
    test('null condition always returns true', () {
      expect(isEventConditionMet(null, makeState()), true);
    });

    test('minDay filters correctly', () {
      final cond = EventCondition(minDay: 10);
      expect(isEventConditionMet(cond, makeState(day: 5)), false);
      expect(isEventConditionMet(cond, makeState(day: 15)), true);
      expect(isEventConditionMet(cond, makeState(day: 10)), true);
    });

    test('maxDay filters correctly', () {
      final cond = EventCondition(maxDay: 20);
      expect(isEventConditionMet(cond, makeState(day: 25)), false);
      expect(isEventConditionMet(cond, makeState(day: 15)), true);
    });

    test('minSuspicion filters correctly', () {
      final cond = EventCondition(minSuspicion: 60);
      expect(isEventConditionMet(cond, makeState(suspicion: 40)), false);
      expect(isEventConditionMet(cond, makeState(suspicion: 70)), true);
    });
  });

  group('sampleEvent', () {
    test('returns null ~10% of the time at normal suspicion', () {
      int nullCount = 0;
      for (int i = 0; i < 200; i++) {
        final result = sampleEvent(makeState(), GameData.events);
        if (result == null) nullCount++;
      }
      final rate = nullCount / 200;
      expect(rate, greaterThan(0.03)); // at least 3%
      expect(rate, lessThan(0.20)); // at most 20%
    });

    test('returns null ~5% of the time at suspicion >= 80', () {
      int nullCount = 0;
      for (int i = 0; i < 200; i++) {
        final result = sampleEvent(makeState(suspicion: 85), GameData.events);
        if (result == null) nullCount++;
      }
      final rate = nullCount / 200;
      expect(rate, greaterThan(0.01));
      expect(rate, lessThan(0.12));
    });

    test('returns a valid GameEvent most of the time', () {
      int eventCount = 0;
      for (int i = 0; i < 50; i++) {
        final result = sampleEvent(makeState(), GameData.events);
        if (result != null) eventCount++;
      }
      expect(eventCount, greaterThan(30)); // ~90% expected
    });

    test('respects eventHistory by reducing weight for seen events', () {
      // Force a specific event to have been seen
      final seenEvent = GameData.events[0];
      final state = makeState(eventHistory: [seenEvent.id]);

      int seenCount = 0;
      for (int i = 0; i < 100; i++) {
        final result = sampleEvent(state, GameData.events);
        if (result?.id == seenEvent.id) seenCount++;
      }
      // Should appear significantly less than others due to 50% weight decay
      expect(seenCount, lessThan(30));
    });

    test('returns event from eligible pool (not outside condition range)', () {
      // Events with maxDay < current day should not appear
      for (int i = 0; i < 50; i++) {
        final result = sampleEvent(makeState(day: 1), GameData.events);
        if (result != null) {
          final c = result.condition;
          if (c != null && c.minDay != null) {
            expect(c.minDay!, lessThanOrEqualTo(1));
          }
        }
      }
    });

    test('highRisk events have boosted weight at high suspicion', () {
      int highRiskCountNormal = 0;
      int highRiskCountHigh = 0;

      for (int i = 0; i < 100; i++) {
        final r1 = sampleEvent(makeState(suspicion: 30), GameData.events);
        if (r1?.highRisk == true) highRiskCountNormal++;

        final r2 = sampleEvent(makeState(suspicion: 90), GameData.events);
        if (r2?.highRisk == true) highRiskCountHigh++;
      }

      // High suspicion should produce more highRisk events
      expect(highRiskCountHigh, greaterThan(highRiskCountNormal));
    });

    test('returns null when no events are eligible', () {
      // Day 1 with a condition requiring minDay > 30 — impossible to satisfy
      // Actually all events are eligible on day 1 since conditions are optional
      // Test with an empty event list
      final result = sampleEvent(makeState(), []);
      expect(result, isNull);
    });
  });
}
