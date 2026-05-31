/// An interruption event (TECH_ARCH §8.2).
class Interruption {
  final String id;
  final String title;
  final String description;
  final int energyEffect;
  final int kpiEffect;
  final int interviewEffect;
  final int suspicionEffect;
  final String log;
  final int? minDay;
  final bool weekendExcluded;

  const Interruption({
    required this.id,
    required this.title,
    required this.description,
    this.energyEffect = 0,
    this.kpiEffect = 0,
    this.interviewEffect = 0,
    this.suspicionEffect = 0,
    required this.log,
    this.minDay,
    this.weekendExcluded = false,
  });

  factory Interruption.fromJson(Map<String, dynamic> json) {
    final effects = json['effects'] as Map<String, dynamic>? ?? {};
    return Interruption(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      energyEffect: effects['energy'] as int? ?? 0,
      kpiEffect: effects['kpi'] as int? ?? 0,
      interviewEffect: effects['interview'] as int? ?? 0,
      suspicionEffect: effects['suspicion'] as int? ?? 0,
      log: json['log'] as String,
      minDay: json['minDay'] as int?,
      weekendExcluded: json['weekendExcluded'] as bool? ?? false,
    );
  }
}
