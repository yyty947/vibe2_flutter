import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_survival/models/ending_type.dart';
import 'package:frontend_survival/logic/endings.dart';

void main() {
  group('checkDailyEnding', () {
    test('BE_DEATH when energy=0', () {
      expect(checkDailyEnding(0, 50, 30, 40), EndingType.beDeath.label);
    });

    test('BE_DEATH when energy=-1 (clamped would be 0)', () {
      expect(checkDailyEnding(-1, 50, 30, 40), EndingType.beDeath.label);
    });

    test('BE_FIRED when kpi=0', () {
      expect(checkDailyEnding(50, 0, 30, 40), EndingType.beFired.label);
    });

    test('BE_DEATH takes priority over BE_FIRED', () {
      // Both energy=0 and kpi=0 — death wins
      expect(checkDailyEnding(0, 0, 30, 40), EndingType.beDeath.label);
    });

    test('GE_OFFER when interview>=80 and suspicion<85', () {
      expect(checkDailyEnding(50, 50, 85, 40), EndingType.geOffer.label);
    });

    test('GE_OFFER at interview=80 (boundary)', () {
      expect(checkDailyEnding(50, 50, 80, 40), EndingType.geOffer.label);
    });

    test('GE_OFFER blocked by suspicion>=85 (Patch-F02)', () {
      expect(checkDailyEnding(50, 50, 85, 85), isNull);
    });

    test('GE_OFFER blocked at suspicion=85 exactly', () {
      expect(checkDailyEnding(50, 50, 85, 85), isNull);
    });

    test('GE_OFFER allowed at suspicion=84 (boundary)', () {
      expect(checkDailyEnding(50, 50, 85, 84), EndingType.geOffer.label);
    });

    test('BE_DEATH takes priority over GE_OFFER', () {
      expect(checkDailyEnding(0, 50, 85, 30), EndingType.beDeath.label);
    });

    test('BE_FIRED takes priority over GE_OFFER', () {
      expect(checkDailyEnding(50, 0, 85, 30), EndingType.beFired.label);
    });

    test('returns null for moderate stats', () {
      expect(checkDailyEnding(50, 50, 50, 50), isNull);
    });

    test('returns null at interview=79 (below threshold)', () {
      expect(checkDailyEnding(50, 50, 79, 40), isNull);
    });
  });

  group('checkFinalEnding', () {
    test('HE_KING with perfect stats', () {
      expect(checkFinalEnding(40, 85, 50, 20), EndingType.heKing.label);
    });

    test('HE_KING at boundaries: kpi=80, suspicion=29, energy=20', () {
      expect(checkFinalEnding(20, 80, 50, 29), EndingType.heKing.label);
    });

    test('HE_KING blocked at kpi=79', () {
      // Falls through to GE_OFFER
      expect(checkFinalEnding(40, 79, 65, 20), EndingType.geOffer.label);
    });

    test('HE_KING blocked at suspicion=30', () {
      expect(checkFinalEnding(40, 85, 50, 30), isNot(EndingType.heKing.label));
    });

    test('GE_OFFER with interview>=60 and suspicion<70', () {
      expect(checkFinalEnding(30, 40, 65, 40), EndingType.geOffer.label);
    });

    test('GE_OFFER blocked by suspicion>=70', () {
      // Both GE_OFFER and NE_PEACE require suspicion < 70 → falls to BE_FIRED
      expect(checkFinalEnding(30, 40, 65, 75), EndingType.beFired.label);
    });

    test('NE_PEACE with moderate stats', () {
      expect(checkFinalEnding(30, 40, 50, 50), EndingType.nePeace.label);
    });

    test('NE_PEACE blocked at kpi=29', () {
      expect(checkFinalEnding(30, 29, 50, 50), EndingType.beFired.label);
    });

    test('BE_FIRED is catch-all (Patch-011)', () {
      expect(checkFinalEnding(10, 10, 20, 80), EndingType.beFired.label);
    });

    test('checkFinalEnding never returns null', () {
      // All paths must return an ending
      final r = checkFinalEnding(10, 10, 20, 80);
      expect(r, isNotNull);
    });
  });
}
