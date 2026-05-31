/// A suspicion pressure morning event (TECH_ARCH §8.3).
class PressureEvent {
  final String id;
  final String title;
  final String description;
  final int energyEffect;
  final int kpiEffect;
  final int interviewEffect;
  final int suspicionEffect;
  final String log;
  final int minSuspicion;
  final int weight;

  const PressureEvent({
    required this.id,
    required this.title,
    required this.description,
    this.energyEffect = 0,
    this.kpiEffect = 0,
    this.interviewEffect = 0,
    this.suspicionEffect = 0,
    required this.log,
    required this.minSuspicion,
    required this.weight,
  });

  factory PressureEvent.fromJson(Map<String, dynamic> json) {
    final effects = json['effects'] as Map<String, dynamic>? ?? {};
    return PressureEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      energyEffect: effects['energy'] as int? ?? 0,
      kpiEffect: effects['kpi'] as int? ?? 0,
      interviewEffect: effects['interview'] as int? ?? 0,
      suspicionEffect: effects['suspicion'] as int? ?? 0,
      log: json['log'] as String,
      minSuspicion: json['minSuspicion'] as int? ?? 70,
      weight: json['weight'] as int? ?? 100,
    );
  }
}
