import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_state.dart';
import '../models/ending_type.dart';
import '../models/log_entry.dart';
import '../models/action_stats.dart';
import '../models/day_modifier.dart';
import '../utils/clamp.dart';
import '../data/game_data.dart';
import '../models/qte_config.dart';
import '../services/audio_manager.dart';
import '../logic/game_loop.dart';
import '../logic/endings.dart' as endings;
import '../logic/action_resolver.dart' show resolveActionEffects;
import '../logic/events.dart' show sampleEvent;
import '../logic/status_evaluator.dart' show computeActiveStatuses;

final _random = Random();

/// Central game state notifier (TECH_ARCH §3).
///
/// All state mutations flow through this single Notifier.
/// Components read state via [gameProvider]; they call methods on
/// `ref.read(gameProvider.notifier)` to dispatch actions.
class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() => GameState.initial;

  // ============================================================
  // Phase transitions
  // ============================================================

  /// Start a brand-new game.
  void startNewGame() {
    state = GameState.initial.copyWith(
      phase: GamePhase.opening,
      savedAt: DateTime.now().millisecondsSinceEpoch,
    );
    evaluateStatusConditions();
  }

  /// Continue from a previously saved state.
  void continueGameFrom(GameState saved) {
    if (saved.version != GameState.gameVersion) {
      // Version mismatch — discard save, start fresh
      startNewGame();
      return;
    }
    state = saved.copyWith(phase: GamePhase.opening);
    evaluateStatusConditions();
  }

  /// Start the intro video (New Game only).
  void startIntroVideo() {
    state = state.copyWith(showIntroVideo: true);
    AudioManager().stopAll();
  }

  /// Called when the intro video finishes or is skipped.
  void finishIntroVideo() {
    state = state.copyWith(showIntroVideo: false);
    startNewGame();
    assignDayModifier();
    checkSuspicionPressure();
  }

  /// Skip the opening typewriter and enter MORNING.
  void skipOpening() {
    if (state.phase != GamePhase.opening) return;
    assert(isValidTransition(state.phase, GamePhase.morning));
    state = state.copyWith(phase: GamePhase.morning);
  }

  /// Player selects an action in MORNING or AFTERNOON.
  void selectAction(String actionId) {
    if (state.phase != GamePhase.morning && state.phase != GamePhase.afternoon) return;

    final action = GameData.actions.cast<dynamic>().firstWhere(
      (a) => (a as dynamic).id == actionId,
      orElse: () => null as dynamic,
    );
    if (action == null) return;

    // Prerequisite check
    final prereq = (action as dynamic).prerequisite;
    if (prereq != null && prereq.field == 'energy' && prereq.operator == '>') {
      if (state.energy <= prereq.value) return;
    }

    // Build modifier instance
    final modifierId = state.dayModifier;
    DayModifier? modifier;
    if (modifierId != null) {
      modifier = GameData.modifiers.cast<dynamic>().firstWhere(
        (m) => (m as dynamic).id == modifierId,
        orElse: () => null as dynamic,
      ) as dynamic;
    }

    // Collect active statuses and skills
    final activeSCs = GameData.statusConditions
        .where((sc) => state.activeStatuses.contains(sc.id))
        .toList();
    final ownedSkills = GameData.skills
        .where((s) => state.skills.contains(s.id))
        .toList();

    // Resolve full effect chain
    final resolved = resolveActionEffects(
      action: action,
      state: state,
      modifier: modifier,
      activeStatuses: activeSCs,
      skills: ownedSkills,
    );
    final d = resolved.deltas;

    // Update action stats
    ActionStats newStats = state.actionStats;
    switch (actionId) {
      case 'WRITE_CODE': newStats = newStats.copyWith(writeCode: newStats.writeCode + 1);
      case 'FIX_BUG': newStats = newStats.copyWith(fixBug: newStats.fixBug + 1);
      case 'STUDY': newStats = newStats.copyWith(studyInterview: newStats.studyInterview + 1);
      case 'SLACK': newStats = newStats.copyWith(slack: newStats.slack + 1);
    }

    // Track streak
    final newStreakId = actionId;
    final newStreakCount = state.streakActionId == actionId ? state.streakCount + 1 : 1;

    // Phase transition
    final isFromMorning = state.phase == GamePhase.morning;
    final nextPhase = isFromMorning ? GamePhase.afternoon : GamePhase.event;

    // Interruption check (MORNING→AFTERNOON only, 25% chance)
    String? interruption;
    if (isFromMorning && _random.nextDouble() < 0.25) {
      final eligible = GameData.interruptions.where((i) {
        if (i.minDay != null && state.day < i.minDay!) return false;
        if (i.weekendExcluded && _isWeekend(state.day)) return false;
        return true;
      }).toList();
      if (eligible.isNotEmpty) {
        interruption = eligible[_random.nextInt(eligible.length)].id;
      }
    }

    final logMsg = (action as dynamic).log as String;

    assert(isValidTransition(state.phase, nextPhase));
    state = state.copyWith(
      energy: clamp(state.energy + d.energy),
      kpi: clamp(state.kpi + d.kpi),
      interview: clamp(state.interview + d.interview),
      suspicion: clamp(state.suspicion + d.suspicion),
      phase: nextPhase,
      actionStats: newStats,
      streakActionId: newStreakId,
      streakCount: newStreakCount,
      interruption: interruption,
    );

    _appendLog(_actionLogType(actionId), _stripLogPrefix(logMsg));

    // Spot check log
    if (resolved.spotCheckLog != null) {
      _appendLog(LogType.warning, resolved.spotCheckLog!);
    }

    // Streak warning
    if (newStreakCount >= 3) {
      final label = (action as dynamic).label as String;
      _appendLog(LogType.warning, '连选惩罚: 第$newStreakCount次选择$label，收益已大幅衰减');
    } else if (newStreakCount == 2) {
      final label = (action as dynamic).label as String;
      _appendLog(LogType.info, '连续选择$label将导致收益递减。');
    }

    // Interruption log
    if (interruption != null) {
      final intr = GameData.interruptions.firstWhere((i) => i.id == interruption);
      _appendLog(LogType.warning, '[打断] ${intr.title}');
    }

    evaluateStatusConditions();
  }

  /// Player chooses an event option.
  void selectEventOption(int optionIndex) {
    if (state.phase != GamePhase.event || state.currentEventId == null) return;

    final eventId = state.currentEventId!;
    final event = GameData.events.firstWhere((e) => e.id == eventId);

    final option = optionIndex == 0 ? event.optionA : event.optionB;
    final logMsg = option.log;

    int deltaEnergy = 0, deltaKpi = 0, deltaInterview = 0, deltaSuspicion = 0;
    for (final eff in option.effects) {
      final value = eff.value;
      switch (eff.type) {
        case 'ENERGY': deltaEnergy += value;
        case 'KPI': deltaKpi += value;
        case 'INTERVIEW': deltaInterview += value;
        case 'SUSPICION': deltaSuspicion += value;
      }
    }

    final eventHistory = [...state.eventHistory, eventId];

    assert(isValidTransition(state.phase, GamePhase.settlement));
    state = state.copyWith(
      energy: clamp(state.energy + deltaEnergy),
      kpi: clamp(state.kpi + deltaKpi),
      interview: clamp(state.interview + deltaInterview),
      suspicion: clamp(state.suspicion + deltaSuspicion),
      eventHistory: eventHistory,
      currentEventId: null,
      phase: GamePhase.settlement,
    );

    final parsed = _parseLogPrefix(logMsg);
    _appendLog(parsed.$1, parsed.$2);

    evaluateStatusConditions();
  }

  /// Skip the event (no event drawn or player bypasses).
  void skipEvent() {
    if (state.phase != GamePhase.event) return;
    assert(isValidTransition(state.phase, GamePhase.settlement));
    state = state.copyWith(currentEventId: null, phase: GamePhase.settlement);
    if (!state.logs.any((l) => l.message.contains('波澜不惊'))) {
      _appendLog(LogType.info, '今天波澜不惊，什么也没发生。');
    }
  }

  /// Daily settlement (AGENTS.md §4.3 / Patch-010, Patch-011).
  void runSettlement() {
    if (state.phase != GamePhase.settlement) return;

    // Step 1: Daily energy drain
    final newEnergy = clamp(state.energy - 5);

    // Step 2: checkDailyEnding (all days including Day 30 — Patch-010)
    final dailyEnding = endings.checkDailyEnding(newEnergy, state.kpi, state.interview, state.suspicion);

    // Step 3: If no daily ending AND day === 30, run final ending
    String? endingLabel;
    if (dailyEnding != null) {
      endingLabel = dailyEnding;
    } else if (state.day == 30) {
      endingLabel = endings.checkFinalEnding(newEnergy, state.kpi, state.interview, state.suspicion);
    }

    if (endingLabel != null) {
      // Step 4: Trigger ending
      assert(isValidTransition(state.phase, GamePhase.ending));
      state = state.copyWith(energy: newEnergy, ending: endingLabel, phase: GamePhase.ending);
    } else {
      // Step 5: Earn skill points (Day 7/14/21) then advance day
      earnSkillPoints();
      final isReviewDay = state.day == 7 || state.day == 14 || state.day == 21;
      assert(isValidTransition(state.phase, GamePhase.opening));
      state = state.copyWith(
        energy: newEnergy,
        day: state.day + 1,
        phase: GamePhase.opening,
        savedAt: DateTime.now().millisecondsSinceEpoch,
        dayModifier: null,
        showWeekReview: isReviewDay,
      );
      evaluateStatusConditions();
    }
  }

  /// Return to title screen and clear state.
  /// Available from any phase (via TopBar restart button).
  void restart() {
    state = GameState.initial;
  }

  // ============================================================
  // Modifier & Interruption (basic)
  // ============================================================

  /// Assign a random day modifier (70% chance, not on Day 30).
  void assignDayModifier() {
    if (state.day >= 30 || _random.nextDouble() >= 0.7) return;

    final eligible = GameData.modifiers.where((m) {
      if (m.minDay != null && state.day < m.minDay!) return false;
      if (m.maxDay != null && state.day > m.maxDay!) return false;
      return true;
    }).toList();
    if (eligible.isEmpty) return;

    final totalWeight = eligible.fold(0, (sum, m) => sum + m.weight);
    var rand = _random.nextDouble() * totalWeight;
    for (final m in eligible) {
      rand -= m.weight;
      if (rand <= 0) {
        state = state.copyWith(dayModifier: m.id);
        _appendLog(LogType.info, '[今日状态] ${m.label} — ${m.description}');
        return;
      }
    }
    state = state.copyWith(dayModifier: eligible.last.id);
  }

  /// Acknowledge and apply an interruption effect.
  void acknowledgeInterruption() {
    final interruptionId = state.interruption;
    if (interruptionId == null) return;

    final intr = GameData.interruptions.firstWhere(
      (i) => i.id == interruptionId,
      orElse: () => GameData.interruptions.first,
    );

    state = state.copyWith(
      energy: clamp(state.energy + intr.energyEffect),
      kpi: clamp(state.kpi + intr.kpiEffect),
      interview: clamp(state.interview + intr.interviewEffect),
      suspicion: clamp(state.suspicion + intr.suspicionEffect),
      interruption: null,
      phase: GamePhase.event,
    );

    _appendLog(LogType.warning, intr.log);

    evaluateStatusConditions();
  }

  // ============================================================
  // Suspicion pressure
  // ============================================================

  /// Check if a suspicion pressure event fires this morning.
  void checkSuspicionPressure() {
    if (state.suspicion < 70) return;
    final probability = 0.3 + (state.suspicion - 70) * 0.01;
    if (_random.nextDouble() >= probability) return;

    final eligible = GameData.pressureEvents
        .where((p) => state.suspicion >= p.minSuspicion)
        .toList();
    if (eligible.isEmpty) return;

    final totalWeight = eligible.fold(0, (sum, p) => sum + p.weight);
    var rand = _random.nextDouble() * totalWeight;
    for (final p in eligible) {
      rand -= p.weight;
      if (rand <= 0) {
        state = state.copyWith(suspicionPressure: p.id);
        return;
      }
    }
    state = state.copyWith(suspicionPressure: eligible.last.id);
  }

  /// Acknowledge and apply a suspicion pressure effect.
  void acknowledgePressure() {
    final pressureId = state.suspicionPressure;
    if (pressureId == null) return;

    final p = GameData.pressureEvents.firstWhere(
      (p) => p.id == pressureId,
      orElse: () => GameData.pressureEvents.first,
    );

    state = state.copyWith(
      energy: clamp(state.energy + p.energyEffect),
      kpi: clamp(state.kpi + p.kpiEffect),
      interview: clamp(state.interview + p.interviewEffect),
      suspicion: clamp(state.suspicion + p.suspicionEffect),
      suspicionPressure: null,
    );

    _appendLog(LogType.alert, p.log);

    evaluateStatusConditions();
  }

  // ============================================================
  // QTE (Quick Time Event)
  // ============================================================

  /// Resolve a QTE event result and apply stat deltas.
  void resolveQteEvent(String eventId, QteResult result) {
    if (state.phase != GamePhase.event) return;

    final event = GameData.events.where((e) => e.id == eventId).firstOrNull;
    if (event == null || event.qteConfig == null) return;

    final deltas = event.qteConfig!.deltasFor(result);
    int deltaEnergy = 0, deltaKpi = 0, deltaInterview = 0, deltaSuspicion = 0;
    for (final entry in deltas.entries) {
      final v = (entry.value as num).toInt();
      switch (entry.key) {
        case 'ENERGY': deltaEnergy += v;
        case 'KPI': deltaKpi += v;
        case 'INTERVIEW': deltaInterview += v;
        case 'SUSPICION': deltaSuspicion += v;
      }
    }

    // QTE-specific log messages
    final logMsg = switch (result) {
      QteResult.perfect => '像素级居中！不愧是 CSS 大师',
      QteResult.good => 'margin: 0 auto 勉强能看',
      QteResult.miss => event.qteConfig!.tauntPool[_random.nextInt(event.qteConfig!.tauntPool.length)],
    };
    final logType = switch (result) {
      QteResult.perfect => LogType.commit,
      QteResult.good => LogType.info,
      QteResult.miss => LogType.warning,
    };

    final eventHistory = [...state.eventHistory, eventId];

    assert(isValidTransition(state.phase, GamePhase.settlement));
    state = state.copyWith(
      energy: clamp(state.energy + deltaEnergy),
      kpi: clamp(state.kpi + deltaKpi),
      interview: clamp(state.interview + deltaInterview),
      suspicion: clamp(state.suspicion + deltaSuspicion),
      eventHistory: eventHistory,
      currentEventId: null,
      phase: GamePhase.settlement,
    );

    _appendLog(logType, logMsg);

    evaluateStatusConditions();
  }

  // ============================================================
  // Status conditions
  // ============================================================

  /// Re-evaluate active buffs/debuffs after stat changes.
  void evaluateStatusConditions() {
    final newStatuses = computeActiveStatuses(state, GameData.statusConditions);
    final added = newStatuses.where((id) => !state.activeStatuses.contains(id)).toList();
    final removed = state.activeStatuses.where((id) => !newStatuses.contains(id)).toList();
    if (added.isEmpty && removed.isEmpty) return;

    state = state.copyWith(activeStatuses: newStatuses);

    for (final id in added) {
      final cond = GameData.statusConditions.where((c) => c.id == id).firstOrNull;
      if (cond != null) {
        final label = cond.isBuff ? '↑' : '↓';
        _appendLog(LogType.info, '[状态] $label ${cond.name} — ${cond.tooltip.flavor}');
      }
    }
    for (final id in removed) {
      final cond = GameData.statusConditions.where((c) => c.id == id).firstOrNull;
      if (cond != null) {
        _appendLog(LogType.info, '[状态] ✕ ${cond.name} 已消失');
      }
    }
  }

  // ============================================================
  // Skills
  // ============================================================

  /// Award skill points on Day 7/14/21.
  void earnSkillPoints() {
    final day = state.day;
    if (day != 7 && day != 14 && day != 21) return;

    int points;
    if (day == 7) {
      points = 3 + state.kpi ~/ 30;
    } else if (day == 14) {
      points = 5 + state.kpi ~/ 25;
    } else {
      points = 8 + state.kpi ~/ 20;
    }

    if (points > 0) {
      state = state.copyWith(skillPoints: state.skillPoints + points);
      _appendLog(LogType.info, '[周度复盘] Day $day 结算：获得 $points 成长点。当前共 ${state.skillPoints} 点。');
    }
  }

  /// Purchase a skill node.
  bool purchaseSkill(String skillId) {
    final skill = GameData.skills.cast<dynamic>().firstWhere(
      (s) => (s as dynamic).id == skillId,
      orElse: () => null as dynamic,
    );
    if (skill == null) return false;
    if (state.skills.contains(skillId)) return false;

    final requires = (skill as dynamic).requires as String?;
    if (requires != null && !state.skills.contains(requires)) return false;

    final cost = (skill as dynamic).cost as int;
    if (state.skillPoints < cost) return false;

    state = state.copyWith(
      skillPoints: state.skillPoints - cost,
      skills: [...state.skills, skillId],
    );

    _appendLog(LogType.info, '[技能] 习得 ${(skill as dynamic).name}！${(skill as dynamic).description}');
    return true;
  }

  /// Refund a purchased skill (undo purchase).
  bool refundSkill(String skillId) {
    final skill = GameData.skills.cast<dynamic>().firstWhere(
      (s) => (s as dynamic).id == skillId,
      orElse: () => null as dynamic,
    );
    if (skill == null) return false;
    if (!state.skills.contains(skillId)) return false;

    final cost = (skill as dynamic).cost as int;
    state = state.copyWith(
      skillPoints: state.skillPoints + cost,
      skills: state.skills.where((id) => id != skillId).toList(),
    );

    _appendLog(LogType.info, '[技能] 撤销 ${(skill as dynamic).name}，返还 $cost 成长点。');
    return true;
  }

  /// Spend 3 skill points to reduce suspicion by 10 (requires SOCIAL_T2).
  bool spendPointsForSuspicion() {
    if (!state.skills.contains('SOCIAL_T2')) return false;
    if (state.skillPoints < 3) return false;
    if (state.suspicion <= 10) return false;

    state = state.copyWith(
      skillPoints: state.skillPoints - 3,
      suspicion: clamp(state.suspicion - 10),
    );
    _appendLog(LogType.info, '消耗 3 成长点，怀疑度降低 10 点。');
    return true;
  }

  /// Close the week review modal and proceed to MORNING.
  void closeWeekReview() {
    state = state.copyWith(showWeekReview: false, phase: GamePhase.morning);
  }

  // ============================================================
  // Testing
  // ============================================================

  /// Directly set state for testing purposes.
  /// Bypasses all transition validation — use only in tests.
  // ignore: use_setters_to_change_properties
  void setStateForTest(GameState s) {
    state = s;
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Sample an event for the current day. Called when entering EVENT phase.
  /// If an event is drawn, sets currentEventId; otherwise skips to SETTLEMENT.
  void triggerEvent() {
    if (state.phase != GamePhase.event) return;

    // Fixed QTE days (5/10/15/20/25): guarantee a QTE event
    const qteFixedDays = {5, 10, 15, 20, 25};
    if (qteFixedDays.contains(state.day)) {
      final qteEvents = GameData.events.where((e) => e.qteConfig != null).toList();
      if (qteEvents.isNotEmpty) {
        final picked = qteEvents[_random.nextInt(qteEvents.length)];
        state = state.copyWith(currentEventId: picked.id as Object?);
        return;
      }
    }

    final event = sampleEvent(state, GameData.events);
    if (event != null) {
      state = state.copyWith(currentEventId: event.id as Object?);
    } else {
      skipEvent();
    }
  }

  void setCurrentEventId(String? id) {
    state = state.copyWith(currentEventId: id as Object?);
  }

  void addLog(LogType type, String message) {
    _appendLog(type, message);
  }

  void applyEffects(Map<String, int> effects) {
    int? energy, kpi, interview, suspicion;
    for (final entry in effects.entries) {
      switch (entry.key) {
        case 'energy': energy = clamp(state.energy + entry.value);
        case 'kpi': kpi = clamp(state.kpi + entry.value);
        case 'interview': interview = clamp(state.interview + entry.value);
        case 'suspicion': suspicion = clamp(state.suspicion + entry.value);
      }
    }
    state = state.copyWith(
      energy: energy ?? state.energy,
      kpi: kpi ?? state.kpi,
      interview: interview ?? state.interview,
      suspicion: suspicion ?? state.suspicion,
    );
  }

  void setPhase(GamePhase phase) {
    state = state.copyWith(phase: phase);
  }

  // ============================================================
  // Internal
  // ============================================================

  void _appendLog(LogType type, String message) {
    final entry = LogEntry(day: state.day, type: type, message: message);
    state = state.copyWith(logs: [...state.logs, entry]);
  }

  static LogType _actionLogType(String actionId) {
    switch (actionId) {
      case 'WRITE_CODE': return LogType.commit;
      case 'FIX_BUG': return LogType.bugfix;
      case 'STUDY': return LogType.study;
      case 'SLACK': return LogType.slack;
      default: return LogType.info;
    }
  }

  static bool _isWeekend(int day) {
    const weekends = {6, 7, 13, 14, 20, 21, 27, 28};
    return weekends.contains(day);
  }

  static String _stripLogPrefix(String raw) {
    final match = RegExp(r'^\[(\w+)\]\s*([\s\S]*)').firstMatch(raw);
    if (match != null) return match.group(2)!;
    return raw;
  }

  static (LogType, String) _parseLogPrefix(String raw) {
    final match = RegExp(r'^\[(\w+)\]\s*([\s\S]*)').firstMatch(raw);
    if (match != null) {
      final typeStr = match.group(1)!;
      final msg = match.group(2)!;
      for (final t in LogType.values) {
        if (t.label == typeStr) return (t, msg);
      }
    }
    return (LogType.info, raw);
  }
}
