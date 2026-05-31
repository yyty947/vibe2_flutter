/// Terminal log type (TECH_ARCH §2.1).
enum LogType {
  info('INFO'),
  warning('WARNING'),
  alert('ALERT'),
  commit('COMMIT'),
  bugfix('BUGFIX'),
  study('STUDY'),
  slack('SLACK');

  const LogType(this.label);
  final String label;

  static LogType fromString(String s) {
    for (final t in LogType.values) {
      if (t.label == s) return t;
    }
    return LogType.info;
  }
}

/// A single terminal log entry.
class LogEntry {
  final int day;
  final LogType type;
  final String message;

  const LogEntry({
    required this.day,
    required this.type,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'type': type.label,
        'message': message,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        day: json['day'] as int,
        type: LogType.fromString(json['type'] as String),
        message: json['message'] as String,
      );
}
