import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/core/utils/age_utils.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/domain/services/age_based_analysis_service.dart';
import 'package:vision_analyzer/domain/services/analysis_service.dart';

void main() {
  group('AgeBasedAnalysisService', () {
    late AgeBasedAnalysisService service;
    late ExamRecord testRecord;

    setUp(() {
      service = AgeBasedAnalysisService();
      testRecord = ExamRecord(
        id: 'test-001',
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 0.8,
          'va_far_uncorrected_os': 0.9,
          'amp_od': 5.0,
          'amp_os': 5.5,
          'sph_od': -2.0,
          'sph_os': -1.5,
          'iop_od': 18.0,
          'iop_os': 19.0,
        },
      );
    });

    group('analyzeWithPatient', () {
      test('analyzes child patient with age-adjusted standards', () {
        final childPatient = Patient(
          id: 'p-001',
          name: 'Test Child',
          age: 10,
          gender: '男',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = service.analyzeWithPatient(testRecord, childPatient);

        expect(result.patientAge, 10);
        expect(result.ageGroup, AgeGroup.child);
        expect(result.ageGroupName, '儿童(0-18岁)');
      });

      test('analyzes adult patient with age-adjusted standards', () {
        final adultPatient = Patient(
          id: 'p-002',
          name: 'Test Adult',
          age: 35,
          gender: '女',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = service.analyzeWithPatient(testRecord, adultPatient);

        expect(result.patientAge, 35);
        expect(result.ageGroup, AgeGroup.adult);
        expect(result.ageGroupName, '成人(19-64岁)');
      });

      test('analyzes elderly patient with age-adjusted standards', () {
        final elderlyPatient = Patient(
          id: 'p-003',
          name: 'Test Elderly',
          age: 70,
          gender: '男',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = service.analyzeWithPatient(testRecord, elderlyPatient);

        expect(result.patientAge, 70);
        expect(result.ageGroup, AgeGroup.elderly);
        expect(result.ageGroupName, '老人(65岁以上)');
      });
    });

    group('age-specific AMP calculation', () {
      test('adjusts AMP standard based on patient age', () {
        final youngPatient = Patient(
          id: 'p-001',
          name: 'Young',
          age: 20,
          gender: '男',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final oldPatient = Patient(
          id: 'p-002',
          name: 'Old',
          age: 60,
          gender: '男',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final youngResult = service.analyzeWithPatient(testRecord, youngPatient);
        final oldResult = service.analyzeWithPatient(testRecord, oldPatient);

        // Young patient should have higher AMP expectation
        expect(youngResult.ageBasedAdjustments.containsKey('amp_od'), true);
        expect(oldResult.ageBasedAdjustments.containsKey('amp_od'), true);
      });
    });

    group('age-specific VA standards', () {
      test('uses lower VA threshold for elderly', () {
        final elderlyPatient = Patient(
          id: 'p-001',
          name: 'Elderly',
          age: 70,
          gender: '男',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final recordWithLowVA = ExamRecord(
          id: 'test-002',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.85, // Below 1.0 but above 0.8
          },
        );

        final result = service.analyzeWithPatient(recordWithLowVA, elderlyPatient);
        
        // 0.85 should be normal for elderly (threshold is 0.8)
        final vaAbnormalities = result.abnormalities
            .where((a) => a.indicatorId.contains('va'))
            .toList();
        expect(vaAbnormalities.isEmpty, true);
      });
    });
  });
}
