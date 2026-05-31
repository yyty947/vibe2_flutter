import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/models/ending_type.dart';
import 'package:frontend_survival/models/log_entry.dart';
import 'package:frontend_survival/models/action_stats.dart';
import 'package:frontend_survival/models/action_def.dart';
import 'package:frontend_survival/models/game_event.dart';
import 'package:frontend_survival/models/day_modifier.dart';
import 'package:frontend_survival/models/interruption.dart';
import 'package:frontend_survival/models/pressure_event.dart';
import 'package:frontend_survival/models/status_condition.dart';
import 'package:frontend_survival/models/skill_def.dart';
import 'package:frontend_survival/models/game_state.dart';

Future<List<dynamic>> _loadList(String path) async {
  final raw = await rootBundle.loadString(path);
  return jsonDecode(raw) as List<dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---- Enums ----

  group('GamePhase', () {
    test('has exactly 7 phases', () {
      expect(GamePhase.values.length, 7);
    });
    test('correct label strings', () {
      expect(GamePhase.title.label, 'TITLE');
      expect(GamePhase.opening.label, 'OPENING');
      expect(GamePhase.morning.label, 'MORNING');
      expect(GamePhase.afternoon.label, 'AFTERNOON');
      expect(GamePhase.event.label, 'EVENT');
      expect(GamePhase.settlement.label, 'SETTLEMENT');
      expect(GamePhase.ending.label, 'ENDING');
    });
  });

  group('EndingType', () {
    test('has exactly 5 endings', () {
      expect(EndingType.values.length, 5);
    });
    test('correct label strings', () {
      expect(EndingType.beDeath.label, 'BE_DEATH');
      expect(EndingType.beFired.label, 'BE_FIRED');
      expect(EndingType.geOffer.label, 'GE_OFFER');
      expect(EndingType.nePeace.label, 'NE_PEACE');
      expect(EndingType.heKing.label, 'HE_KING');
    });
  });

  group('LogType', () {
    test('fromString returns correct type', () {
      expect(LogType.fromString('INFO'), LogType.info);
      expect(LogType.fromString('WARNING'), LogType.warning);
      expect(LogType.fromString('ALERT'), LogType.alert);
      expect(LogType.fromString('COMMIT'), LogType.commit);
      expect(LogType.fromString('BUGFIX'), LogType.bugfix);
      expect(LogType.fromString('STUDY'), LogType.study);
      expect(LogType.fromString('SLACK'), LogType.slack);
    });
    test('fromString returns info for unknown type', () {
      expect(LogType.fromString('GARBAGE'), LogType.info);
    });
  });

  // ---- Data objects ----

  group('ActionStats', () {
    test('zero has all zeros', () {
      expect(ActionStats.zero.writeCode, 0);
      expect(ActionStats.zero.fixBug, 0);
      expect(ActionStats.zero.studyInterview, 0);
      expect(ActionStats.zero.slack, 0);
    });
    test('copyWith updates individual fields', () {
      final s = ActionStats.zero.copyWith(writeCode: 3);
      expect(s.writeCode, 3);
      expect(s.fixBug, 0);
    });
    test('toJson / fromJson round-trip', () {
      final s = ActionStats(writeCode: 5, fixBug: 2, studyInterview: 8, slack: 1);
      final json = s.toJson();
      final s2 = ActionStats.fromJson(json);
      expect(s2.writeCode, 5);
      expect(s2.fixBug, 2);
      expect(s2.studyInterview, 8);
      expect(s2.slack, 1);
    });
  });

  group('LogEntry', () {
    test('toJson / fromJson round-trip', () {
      final e = LogEntry(day: 3, type: LogType.commit, message: 'PR merged');
      final json = e.toJson();
      final e2 = LogEntry.fromJson(json);
      expect(e2.day, 3);
      expect(e2.type, LogType.commit);
      expect(e2.message, 'PR merged');
    });
  });

  // ---- JSON deserialization from real data files ----

  group('ActionDef.fromJson', () {
    late List<ActionDef> actions;
    setUpAll(() async {
      final list = await _loadList('assets/data/actions.json');
      actions = list.map((e) => ActionDef.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 12 actions', () => expect(actions.length, 12));

    test('core actions loaded correctly', () {
      final wc = actions.firstWhere((a) => a.id == 'WRITE_CODE');
      expect(wc.label, '写业务代码');
      expect(wc.energyEffect, -10);
      expect(wc.kpiEffect, 5);
      expect(wc.interviewEffect, 0);
      expect(wc.suspicionEffect, -2);
      expect(wc.core, true);
      expect(wc.prerequisite, isNull);
    });

    test('FIX_BUG has prerequisite energy > 20', () {
      final fb = actions.firstWhere((a) => a.id == 'FIX_BUG');
      expect(fb.prerequisite?.field, 'energy');
      expect(fb.prerequisite?.operator, '>');
      expect(fb.prerequisite?.value, 20);
      expect(fb.isBlockedBy(10), true);
      expect(fb.isBlockedBy(25), false);
      expect(fb.isBlockedBy(20), true); // > not >=
    });

    test('conditional action has condition', () {
      final mentor = actions.firstWhere((a) => a.id == 'MENTOR');
      expect(mentor.core, isNot(true));
      expect(mentor.condition?.minDay, 3);
      expect(mentor.condition?.minKpi, 40);
    });

    test('ARCH_REDESIGN requires skill TECH_T3', () {
      final arch = actions.firstWhere((a) => a.id == 'ARCH_REDESIGN');
      expect(arch.condition?.requiresSkill, 'TECH_T3');
      expect(arch.prerequisite?.value, 45);
    });
  });

  group('GameEvent.fromJson', () {
    late List<GameEvent> events;
    setUpAll(() async {
      final list = await _loadList('assets/data/events.json');
      events = list.map((e) => GameEvent.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 65 events', () => expect(events.length, 65));

    test('every event has exactly 2 options (A and B)', () {
      for (final ev in events) {
        expect(ev.optionA.text, isNotEmpty);
        expect(ev.optionB.text, isNotEmpty);
        // QTE events store effects in qteConfig, options may be empty
        if (ev.qteConfig == null) {
          expect(ev.optionA.effects, isNotEmpty);
          expect(ev.optionB.effects, isNotEmpty);
        }
      }
    });

    test('14 high-risk events', () {
      final hr = events.where((e) => e.highRisk).toList();
      expect(hr.length, 14);
    });

    test('EV_002 is high-risk HR meeting', () {
      final ev = events.firstWhere((e) => e.id == 'EV_002');
      expect(ev.highRisk, true);
      expect(ev.title, contains('HR'));
    });
  });

  group('DayModifier.fromJson', () {
    late List<DayModifier> mods;
    setUpAll(() async {
      final list = await _loadList('assets/data/modifiers.json');
      mods = list.map((e) => DayModifier.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 12 modifiers', () => expect(mods.length, 12));
    test('each has an id and weight', () {
      for (final m in mods) {
        expect(m.id, isNotEmpty);
        expect(m.weight, greaterThan(0));
      }
    });
  });

  group('Interruption.fromJson', () {
    late List<Interruption> intrs;
    setUpAll(() async {
      final list = await _loadList('assets/data/interruptions.json');
      intrs = list.map((e) => Interruption.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 8 interruptions', () => expect(intrs.length, 8));
    test('each has a log message', () {
      for (final i in intrs) {
        expect(i.log, isNotEmpty);
      }
    });
  });

  group('PressureEvent.fromJson', () {
    late List<PressureEvent> pes;
    setUpAll(() async {
      final list = await _loadList('assets/data/pressure-events.json');
      pes = list.map((e) => PressureEvent.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 6 pressure events', () => expect(pes.length, 6));
    test('each has minSuspicion >= 70', () {
      for (final p in pes) {
        expect(p.minSuspicion, greaterThanOrEqualTo(70));
      }
    });
  });

  group('StatusCondition.fromJson', () {
    late List<StatusCondition> scs;
    setUpAll(() async {
      final list = await _loadList('assets/data/status-conditions.json');
      scs = list.map((e) => StatusCondition.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 8 status conditions', () => expect(scs.length, 8));
    test('4 buffs and 4 debuffs', () {
      expect(scs.where((s) => s.isBuff).length, 4);
      expect(scs.where((s) => !s.isBuff).length, 4);
    });
    test('each has at least one trigger', () {
      for (final s in scs) {
        expect(s.triggers, isNotEmpty);
      }
    });
  });

  group('SkillDef.fromJson', () {
    late List<SkillDef> skills;
    setUpAll(() async {
      final list = await _loadList('assets/data/skills.json');
      skills = list.map((e) => SkillDef.fromJson(e as Map<String, dynamic>)).toList();
    });

    test('loads 12 skills', () => expect(skills.length, 12));
    test('4 branches × 3 tiers', () {
      for (final branch in ['energy', 'tech', 'social', 'interview']) {
        final bs = skills.where((s) => s.branch == branch).toList();
        expect(bs.length, 3);
        expect(bs.any((s) => s.tier == 1), true);
        expect(bs.any((s) => s.tier == 2), true);
        expect(bs.any((s) => s.tier == 3), true);
      }
    });
    test('T1 skills have no prerequisite', () {
      for (final s in skills.where((s) => s.tier == 1)) {
        expect(s.requires, isNull);
      }
    });
    test('T2/T3 skills require previous tier', () {
      for (final s in skills.where((s) => s.tier > 1)) {
        expect(s.requires, isNotNull);
      }
    });
  });

  // ---- GameState ----

  group('GameState', () {
    test('initial state values match TECH_ARCH §2.2', () {
      const s = GameState.initial;
      expect(s.energy, 75);
      expect(s.kpi, 50);
      expect(s.interview, 10);
      expect(s.suspicion, 20);
      expect(s.day, 1);
      expect(s.phase, GamePhase.title);
      expect(s.version, GameState.gameVersion);
      expect(s.eventHistory, isEmpty);
      expect(s.logs, isEmpty);
      expect(s.activeStatuses, isEmpty);
      expect(s.skills, isEmpty);
      expect(s.skillPoints, 0);
      expect(s.ending, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const s = GameState.initial;
      final s2 = s.copyWith(energy: 50);
      expect(s2.energy, 50);
      expect(s2.kpi, 50); // unchanged
      expect(s2.day, 1); // unchanged
    });

    test('toJson / fromJson round-trip', () {
      const s = GameState(
        energy: 30,
        kpi: 60,
        interview: 45,
        suspicion: 25,
        day: 12,
        phase: GamePhase.morning,
        eventHistory: ['EV_001', 'EV_005'],
        activeStatuses: ['TRUSTED'],
        streakActionId: 'STUDY',
        streakCount: 2,
        skillPoints: 5,
        skills: ['ENERGY_T1'],
      );
      final json = s.toJson();
      final s2 = GameState.fromJson(json);
      expect(s2.energy, 30);
      expect(s2.kpi, 60);
      expect(s2.interview, 45);
      expect(s2.suspicion, 25);
      expect(s2.day, 12);
      expect(s2.phase, GamePhase.morning);
      expect(s2.eventHistory, ['EV_001', 'EV_005']);
      expect(s2.activeStatuses, ['TRUSTED']);
      expect(s2.streakActionId, 'STUDY');
      expect(s2.streakCount, 2);
      expect(s2.skillPoints, 5);
      expect(s2.skills, ['ENERGY_T1']);
    });

    test('fromJson handles minimal JSON', () {
      final s = GameState.fromJson({});
      expect(s.energy, 75);
      expect(s.phase, GamePhase.title);
    });
  });
}
