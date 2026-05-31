import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/utils/weekend.dart';

void main() {
  group('isWeekend', () {
    for (final d in [6, 7, 13, 14, 20, 21, 27, 28]) {
      test('day $d is a weekend', () {
        expect(isWeekend(d), true);
      });
    }

    for (final d in [1, 2, 3, 4, 5, 8, 10, 12, 15, 18, 22, 25, 29, 30]) {
      test('day $d is a weekday', () {
        expect(isWeekend(d), false);
      });
    }
  });
}
