/// QTE (Quick Time Event) result grades.
enum QteResult {
  perfect,
  good,
  miss,
}

/// Configuration for a QTE mini-game event.
///
/// All speed/time values are base values; they are scaled by the
/// player's current suspicion level at runtime.
class QteConfig {
  /// Base movement speed in px/s (before suspicion scaling).
  final double speedBase;

  /// Additional speed per suspicion point.
  final double speedSuspicionScale;

  /// Base time limit in milliseconds.
  final int timeLimitMs;

  /// Milliseconds reduced per suspicion point.
  final int timeLimitSuspicionReduce;

  /// Maximum offset in logical pixels for a Perfect result.
  final double perfectThreshold;

  /// Maximum offset for a Good result. Anything higher is Miss.
  final double goodThreshold;

  /// Random taunts shown on a Miss result.
  final List<String> tauntPool;

  /// Stat deltas keyed by result grade: { "perfect": {"kpi": 12, ...}, ... }
  final Map<String, Map<String, int>> effects;

  const QteConfig({
    required this.speedBase,
    required this.speedSuspicionScale,
    required this.timeLimitMs,
    required this.timeLimitSuspicionReduce,
    this.perfectThreshold = 8.0,
    this.goodThreshold = 24.0,
    required this.tauntPool,
    required this.effects,
  });

  factory QteConfig.fromJson(Map<String, dynamic> json) {
    return QteConfig(
      speedBase: (json['speedBase'] as num).toDouble(),
      speedSuspicionScale: (json['speedSuspicionScale'] as num).toDouble(),
      timeLimitMs: json['timeLimitMs'] as int,
      timeLimitSuspicionReduce: json['timeLimitSuspicionReduce'] as int? ?? 40,
      perfectThreshold: (json['perfectThreshold'] as num?)?.toDouble() ?? 8.0,
      goodThreshold: (json['goodThreshold'] as num?)?.toDouble() ?? 24.0,
      tauntPool: (json['tauntPool'] as List<dynamic>).cast<String>(),
      effects: (json['effects'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as Map<String, dynamic>).map(
          (sk, sv) => MapEntry(sk, sv as int),
        )),
      ),
    );
  }

  /// Compute runtime speed based on current suspicion.
  double effectiveSpeed(int suspicion) => speedBase + suspicion * speedSuspicionScale;

  /// Compute runtime time limit in ms, clamped to a minimum of 2500ms.
  int effectiveTimeLimit(int suspicion) {
    final v = timeLimitMs - suspicion * timeLimitSuspicionReduce;
    return v < 2500 ? 2500 : v;
  }

  /// Get stat deltas for a result grade.
  Map<String, int> deltasFor(QteResult result) {
    final key = result.name; // "perfect", "good", "miss"
    return effects[key] ?? {};
  }
}
