/// An event category mapping events to background images (TECH_ARCH §8.8).
class EventCategory {
  final String id;
  final String label;
  final String background;
  final List<String> events;

  const EventCategory({
    required this.id,
    required this.label,
    required this.background,
    required this.events,
  });

  factory EventCategory.fromJsonEntry(String id, Map<String, dynamic> json) {
    return EventCategory(
      id: id,
      label: json['label'] as String,
      background: json['background'] as String,
      events: (json['events'] as List<dynamic>).cast<String>(),
    );
  }
}
