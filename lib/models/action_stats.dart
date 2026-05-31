/// Player action history counters (TECH_ARCH §2.1).
class ActionStats {
  final int writeCode;
  final int fixBug;
  final int studyInterview;
  final int slack;

  const ActionStats({
    this.writeCode = 0,
    this.fixBug = 0,
    this.studyInterview = 0,
    this.slack = 0,
  });

  static const zero = ActionStats();

  ActionStats copyWith({int? writeCode, int? fixBug, int? studyInterview, int? slack}) {
    return ActionStats(
      writeCode: writeCode ?? this.writeCode,
      fixBug: fixBug ?? this.fixBug,
      studyInterview: studyInterview ?? this.studyInterview,
      slack: slack ?? this.slack,
    );
  }

  Map<String, dynamic> toJson() => {
        'writeCode': writeCode,
        'fixBug': fixBug,
        'studyInterview': studyInterview,
        'slack': slack,
      };

  factory ActionStats.fromJson(Map<String, dynamic> json) => ActionStats(
        writeCode: json['writeCode'] as int? ?? 0,
        fixBug: json['fixBug'] as int? ?? 0,
        studyInterview: json['studyInterview'] as int? ?? 0,
        slack: json['slack'] as int? ?? 0,
      );
}
