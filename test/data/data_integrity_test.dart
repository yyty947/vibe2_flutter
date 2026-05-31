import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  test('All 10 JSON data files are loadable and parseable', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const files = [
      'assets/data/actions.json',
      'assets/data/events.json',
      'assets/data/openings.json',
      'assets/data/endings.json',
      'assets/data/modifiers.json',
      'assets/data/interruptions.json',
      'assets/data/pressure-events.json',
      'assets/data/status-conditions.json',
      'assets/data/skills.json',
      'assets/data/event-categories.json',
    ];

    for (final path in files) {
      final raw = await rootBundle.loadString(path);
      final parsed = jsonDecode(raw);
      expect(parsed, isNotNull, reason: '$path failed to parse');
    }
  });

  test('actions.json has 12 actions', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString('assets/data/actions.json');
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, 12);
    expect(list[0]['id'], 'WRITE_CODE');
  });

  test('events.json has 65 events with 14 high-risk', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString('assets/data/events.json');
    final list = jsonDecode(raw) as List<dynamic>;
    expect(list.length, 65);
    final highRiskCount = list.where((e) => e['highRisk'] == true).length;
    expect(highRiskCount, 14);
  });

  test('openings.json has 30 days', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString('assets/data/openings.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    expect(map.length, 30);
    expect(map['1'], isNotNull);
    expect(map['30'], isNotNull);
  });

  test('endings.json has all 5 endings', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final raw = await rootBundle.loadString('assets/data/endings.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    expect(map.length, 5);
    for (final key in ['BE_DEATH', 'BE_FIRED', 'GE_OFFER', 'NE_PEACE', 'HE_KING']) {
      expect(map[key], isNotNull, reason: 'Missing ending: $key');
    }
  });
}
