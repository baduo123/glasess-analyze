import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/core/utils/age_utils.dart';

void main() {
  group('AgeUtils', () {
    group('getGroup', () {
      test('returns child for age 0-18', () {
        expect(AgeUtils.getGroup(0), AgeGroup.child);
        expect(AgeUtils.getGroup(10), AgeGroup.child);
        expect(AgeUtils.getGroup(18), AgeGroup.child);
      });

      test('returns adult for age 19-64', () {
        expect(AgeUtils.getGroup(19), AgeGroup.adult);
        expect(AgeUtils.getGroup(30), AgeGroup.adult);
        expect(AgeUtils.getGroup(64), AgeGroup.adult);
      });

      test('returns elderly for age 65+', () {
        expect(AgeUtils.getGroup(65), AgeGroup.elderly);
        expect(AgeUtils.getGroup(80), AgeGroup.elderly);
        expect(AgeUtils.getGroup(100), AgeGroup.elderly);
      });

      test('throws error for negative age', () {
        expect(() => AgeUtils.getGroup(-1), throwsArgumentError);
      });
    });

    group('getGroupName', () {
      test('returns correct group name', () {
        expect(AgeUtils.getGroupName(10), '儿童(0-18岁)');
        expect(AgeUtils.getGroupName(30), '成人(19-64岁)');
        expect(AgeUtils.getGroupName(70), '老人(65岁以上)');
      });
    });

    group('getAgeGroupId', () {
      test('returns correct group ID', () {
        expect(AgeUtils.getAgeGroupId(10), 1); // child
        expect(AgeUtils.getAgeGroupId(30), 2); // adult
        expect(AgeUtils.getAgeGroupId(70), 3); // elderly
      });
    });

    group('calculateAMPAgeBased', () {
      test('calculates AMP using Hoffman formula', () {
        // AMP = 18.5 - 0.3 * age
        expect(AgeUtils.calculateAMPAgeBased(20), closeTo(12.5, 0.1));
        expect(AgeUtils.calculateAMPAgeBased(40), closeTo(6.5, 0.1));
        expect(AgeUtils.calculateAMPAgeBased(60), closeTo(0.5, 0.1));
      });

      test('clamps AMP to minimum 0', () {
        expect(AgeUtils.calculateAMPAgeBased(100), 0.0);
      });
    });

    group('getExpectedVA', () {
      test('returns 1.0 for child and adult', () {
        expect(AgeUtils.getExpectedVA(10), 1.0);
        expect(AgeUtils.getExpectedVA(30), 1.0);
      });

      test('returns 0.8 for elderly', () {
        expect(AgeUtils.getExpectedVA(70), 0.8);
      });
    });

    group('isChild/isAdult/isElderly', () {
      test('correctly identifies age groups', () {
        expect(AgeUtils.isChild(10), true);
        expect(AgeUtils.isAdult(10), false);
        expect(AgeUtils.isElderly(10), false);

        expect(AgeUtils.isChild(30), false);
        expect(AgeUtils.isAdult(30), true);
        expect(AgeUtils.isElderly(30), false);

        expect(AgeUtils.isChild(70), false);
        expect(AgeUtils.isAdult(70), false);
        expect(AgeUtils.isElderly(70), true);
      });
    });

    group('getAgeSpecificNotes', () {
      test('returns different notes for different age groups', () {
        final childNotes = AgeUtils.getAgeSpecificNotes(10);
        final adultNotes = AgeUtils.getAgeSpecificNotes(30);
        final elderlyNotes = AgeUtils.getAgeSpecificNotes(70);

        expect(childNotes.isNotEmpty, true);
        expect(adultNotes.isNotEmpty, true);
        expect(elderlyNotes.isNotEmpty, true);

        expect(childNotes, isNot(equals(adultNotes)));
        expect(adultNotes, isNot(equals(elderlyNotes)));
      });
    });
  });
}
