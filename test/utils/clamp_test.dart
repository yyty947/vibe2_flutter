import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/utils/clamp.dart';

void main() {
  group('clamp', () {
    test('returns 0 for negative values', () {
      expect(clamp(-5), 0);
      expect(clamp(-1), 0);
      expect(clamp(-100), 0);
    });

    test('returns 100 for overflow values', () {
      expect(clamp(120), 100);
      expect(clamp(101), 100);
      expect(clamp(999), 100);
    });

    test('returns the value unchanged when within range', () {
      expect(clamp(50), 50);
      expect(clamp(0), 0);
      expect(clamp(100), 100);
      expect(clamp(75), 75);
    });

    test('supports custom min/max', () {
      expect(clamp(5, min: 10, max: 50), 10);
      expect(clamp(60, min: 10, max: 50), 50);
      expect(clamp(30, min: 10, max: 50), 30);
    });
  });
}
