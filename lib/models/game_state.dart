import 'ending_type.dart';
import 'log_entry.dart';
import 'action_stats.dart';

/// The central game state (TECH_ARCH §2.1).
///
/// Immutable value object. All mutations go through GameNotifier (M3).

class GameState {
  // Core stats [0, 100]
  final int energy;
  final int kpi;
  final int interview;
  final int suspicion;

  // Time
  final int day; // [1, 30]
  final GamePhase phase;

  // History
  final List<String> eventHistory;
  final List<LogEntry> logs;

  // Save metadata
  final String version;
  final int savedAt;
  final ActionStats actionStats;

  // Runtime
  final String? currentEventId;
  final String? ending; // stores EndingType.label or null

  // Patch-F01/F02: modifier & interruption & suspicion pressure
  final String? dayModifier;
  final String? interruption;
  final String? suspicionPressure;

  // Patch-F03: buff/debuff status
  final List<String> activeStatuses;

  // Patch-F04: streak tracking
  final String streakActionId;
  final int streakCount;

  // Patch-F05: skill system
  final int skillPoints;
  final List<String> skills;
  final bool showWeekReview;

  // UI flag
  final bool skipAllTyping;

  // Intro video (transient — not serialised)
  final bool showIntroVideo;

  const GameState({
    required this.energy,
    required this.kpi,
    required this.interview,
    required this.suspicion,
    required this.day,
    required this.phase,
    this.eventHistory = const [],
    this.logs = const [],
    this.version = gameVersion,
    this.savedAt = 0,
    this.actionStats = ActionStats.zero,
    this.currentEventId,
    this.ending,
    this.dayModifier,
    this.interruption,
    this.suspicionPressure,
    this.activeStatuses = const [],
    this.streakActionId = '',
    this.streakCount = 0,
    this.skillPoints = 0,
    this.skills = const [],
    this.showWeekReview = false,
    this.skipAllTyping = false,
    this.showIntroVideo = false,
  });

  static const String gameVersion = '2.0.0';

  /// Fresh game initial state (TECH_ARCH §2.2).
  static const GameState initial = GameState(
    energy: 75,
    kpi: 50,
    interview: 10,
    suspicion: 20,
    day: 1,
    phase: GamePhase.title,
  );

  GameState copyWith({
    int? energy,
    int? kpi,
    int? interview,
    int? suspicion,
    int? day,
    GamePhase? phase,
    List<String>? eventHistory,
    List<LogEntry>? logs,
    String? version,
    int? savedAt,
    ActionStats? actionStats,
    Object? currentEventId = _sentinel,
    Object? ending = _sentinel,
    Object? dayModifier = _sentinel,
    Object? interruption = _sentinel,
    Object? suspicionPressure = _sentinel,
    List<String>? activeStatuses,
    String? streakActionId,
    int? streakCount,
    int? skillPoints,
    List<String>? skills,
    bool? showWeekReview,
    bool? skipAllTyping,
    bool? showIntroVideo,
  }) {
    return GameState(
      energy: energy ?? this.energy,
      kpi: kpi ?? this.kpi,
      interview: interview ?? this.interview,
      suspicion: suspicion ?? this.suspicion,
      day: day ?? this.day,
      phase: phase ?? this.phase,
      eventHistory: eventHistory ?? this.eventHistory,
      logs: logs ?? this.logs,
      version: version ?? this.version,
      savedAt: savedAt ?? this.savedAt,
      actionStats: actionStats ?? this.actionStats,
      currentEventId: identical(currentEventId, _sentinel)
          ? this.currentEventId
          : currentEventId as String?,
      ending: identical(ending, _sentinel) ? this.ending : ending as String?,
      dayModifier: identical(dayModifier, _sentinel)
          ? this.dayModifier
          : dayModifier as String?,
      interruption: identical(interruption, _sentinel)
          ? this.interruption
          : interruption as String?,
      suspicionPressure: identical(suspicionPressure, _sentinel)
          ? this.suspicionPressure
          : suspicionPressure as String?,
      activeStatuses: activeStatuses ?? this.activeStatuses,
      streakActionId: streakActionId ?? this.streakActionId,
      streakCount: streakCount ?? this.streakCount,
      skillPoints: skillPoints ?? this.skillPoints,
      skills: skills ?? this.skills,
      showWeekReview: showWeekReview ?? this.showWeekReview,
      skipAllTyping: skipAllTyping ?? this.skipAllTyping,
      showIntroVideo: showIntroVideo ?? this.showIntroVideo,
    );
  }

  static const _sentinel = Object();

  Map<String, dynamic> toJson() => {
    'energy': energy,
    'kpi': kpi,
    'interview': interview,
    'suspicion': suspicion,
    'day': day,
    'phase': phase.label,
    'eventHistory': eventHistory,
    'logs': logs.map((l) => l.toJson()).toList(),
    'version': version,
    'savedAt': savedAt,
    'actionStats': actionStats.toJson(),
    'currentEventId': currentEventId,
    'ending': ending,
    'dayModifier': dayModifier,
    'interruption': interruption,
    'suspicionPressure': suspicionPressure,
    'activeStatuses': activeStatuses,
    'streakActionId': streakActionId,
    'streakCount': streakCount,
    'skillPoints': skillPoints,
    'skills': skills,
    'showWeekReview': showWeekReview,
  };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final phaseStr = json['phase'] as String? ?? 'TITLE';
    return GameState(
      energy: json['energy'] as int? ?? 75,
      kpi: json['kpi'] as int? ?? 50,
      interview: json['interview'] as int? ?? 10,
      suspicion: json['suspicion'] as int? ?? 20,
      day: json['day'] as int? ?? 1,
      phase: GamePhase.values.firstWhere(
        (p) => p.label == phaseStr,
        orElse: () => GamePhase.title,
      ),
      eventHistory:
          (json['eventHistory'] as List<dynamic>?)?.cast<String>() ?? [],
      logs:
          (json['logs'] as List<dynamic>?)
              ?.map((l) => LogEntry.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      version: json['version'] as String? ?? gameVersion,
      savedAt: json['savedAt'] as int? ?? 0,
      actionStats: json['actionStats'] != null
          ? ActionStats.fromJson(json['actionStats'] as Map<String, dynamic>)
          : ActionStats.zero,
      currentEventId: json['currentEventId'] as String?,
      ending: json['ending'] as String?,
      dayModifier: json['dayModifier'] as String?,
      interruption: json['interruption'] as String?,
      suspicionPressure: json['suspicionPressure'] as String?,
      activeStatuses:
          (json['activeStatuses'] as List<dynamic>?)?.cast<String>() ?? [],
      streakActionId: json['streakActionId'] as String? ?? '',
      streakCount: json['streakCount'] as int? ?? 0,
      skillPoints: json['skillPoints'] as int? ?? 0,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? [],
      showWeekReview: json['showWeekReview'] as bool? ?? false,
    );
  }
}
