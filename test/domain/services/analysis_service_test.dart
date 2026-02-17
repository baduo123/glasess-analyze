import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/domain/services/analysis_service.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/core/constants/indicator_standards/indicator_standard_model.dart';

void main() {
  group('AnalysisService', () {
    late AnalysisService analysisService;

    setUp(() {
      analysisService = AnalysisService();
    });

    group('getStandardsForType', () {
      test('should return standards for standardFullSet exam type', () {
        final standards = analysisService.getStandardsForType(ExamType.standardFullSet);

        expect(standards, isNotEmpty);
        expect(standards.length, equals(8));
      });

      test('should cache standards for subsequent calls', () {
        final standards1 = analysisService.getStandardsForType(ExamType.standardFullSet);
        final standards2 = analysisService.getStandardsForType(ExamType.standardFullSet);

        expect(identical(standards1, standards2), isTrue);
      });

      test('should return empty list for unknown exam type', () {
        final standards = analysisService.getStandardsForType(ExamType.custom);

        expect(standards, isEmpty);
      });
    });

    group('analyze - 正常值分析', () {
      test('should return normal assessment when all values are normal', () {
        final examRecord = ExamRecord(
          id: 'test-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 1.2,
            'va_far_uncorrected_os': 1.0,
            'amp_od': 8.0,
            'amp_os': 7.5,
            'sph_od': 0.0,
            'sph_os': 0.25,
            'iop_od': 15.0,
            'iop_os': 16.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.examId, equals('test-001'));
        expect(result.abnormalities, isEmpty);
        expect(result.totalIndicators, equals(8));
        expect(result.abnormalCount, equals(0));
        expect(result.overallAssessment, contains('所有检查指标均在正常范围内'));
        expect(result.keyFindings, isEmpty);
        expect(result.comprehensiveSuggestions, isEmpty);
      });

      test('should handle empty indicator values', () {
        final examRecord = ExamRecord(
          id: 'test-002',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {},
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities, isEmpty);
        expect(result.abnormalCount, equals(0));
      });

      test('should handle null indicator values', () {
        final examRecord = ExamRecord(
          id: 'test-003',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: null,
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities, isEmpty);
        expect(result.abnormalCount, equals(0));
      });
    });

    group('analyze - 轻度异常检测', () {
      test('should detect mild visual acuity decrease', () {
        final examRecord = ExamRecord(
          id: 'test-004',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.8,
            'va_far_uncorrected_os': 0.7,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalCount, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.mild), isTrue);
        expect(result.overallAssessment, contains('轻度异常'));
      });

      test('should detect mild myopia', () {
        final examRecord = ExamRecord(
          id: 'test-005',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'sph_od': -2.0,
            'sph_os': -1.5,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.mild), isTrue);
        expect(result.abnormalities.every((a) => a.interpretation.contains('轻度近视')), isTrue);
      });

      test('should detect mild IOP elevation', () {
        final examRecord = ExamRecord(
          id: 'test-006',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'iop_od': 23.0,
            'iop_os': 24.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.mild), isTrue);
        expect(result.abnormalities.every((a) => a.interpretation.contains('眼压轻度升高')), isTrue);
      });

      test('should detect mild amplitude decrease', () {
        final examRecord = ExamRecord(
          id: 'test-007',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'amp_od': 6.0,
            'amp_os': 5.5,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.mild), isTrue);
      });

      test('should detect low IOP', () {
        final examRecord = ExamRecord(
          id: 'test-008',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'iop_od': 8.0,
            'iop_os': 7.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.mild), isTrue);
        expect(result.abnormalities.every((a) => a.interpretation.contains('眼压偏低')), isTrue);
      });
    });

    group('analyze - 中度异常检测', () {
      test('should detect moderate visual acuity decrease', () {
        final examRecord = ExamRecord(
          id: 'test-009',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.4,
            'va_far_uncorrected_os': 0.3,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.moderate), isTrue);
        expect(result.overallAssessment, contains('中度异常'));
      });

      test('should detect moderate myopia', () {
        final examRecord = ExamRecord(
          id: 'test-010',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'sph_od': -4.5,
            'sph_os': -5.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.moderate), isTrue);
        expect(result.abnormalities.every((a) => a.interpretation.contains('中度近视')), isTrue);
      });

      test('should detect moderate IOP elevation', () {
        final examRecord = ExamRecord(
          id: 'test-011',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'iop_od': 28.0,
            'iop_os': 26.5,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.moderate), isTrue);
      });

      test('should detect moderate amplitude decrease', () {
        final examRecord = ExamRecord(
          id: 'test-012',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'amp_od': 4.0,
            'amp_os': 3.5,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.moderate), isTrue);
      });
    });

    group('analyze - 重度异常检测', () {
      test('should detect severe visual acuity decrease', () {
        final examRecord = ExamRecord(
          id: 'test-013',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.1,
            'va_far_uncorrected_os': 0.05,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.severe), isTrue);
        expect(result.overallAssessment, contains('重度异常'));
        expect(result.overallAssessment, contains('尽快就医'));
      });

      test('should detect high myopia', () {
        final examRecord = ExamRecord(
          id: 'test-014',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'sph_od': -8.0,
            'sph_os': -10.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.severe), isTrue);
        expect(result.abnormalities.every((a) => a.interpretation.contains('高度近视')), isTrue);
      });

      test('should detect severe IOP elevation', () {
        final examRecord = ExamRecord(
          id: 'test-015',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'iop_od': 35.0,
            'iop_os': 32.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.severe), isTrue);
        expect(result.abnormalities.every((a) => a.interpretation.contains('眼压重度升高')), isTrue);
      });

      test('should detect severe amplitude decrease', () {
        final examRecord = ExamRecord(
          id: 'test-016',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'amp_od': 2.0,
            'amp_os': 1.5,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.severe), isTrue);
      });
    });

    group('analyze - 边界条件', () {
      test('should handle boundary value at exact normal minimum', () {
        final examRecord = ExamRecord(
          id: 'test-017',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 1.0,
            'amp_od': 7.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities, isEmpty);
      });

      test('should handle boundary value just below normal minimum', () {
        final examRecord = ExamRecord(
          id: 'test-018',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.99,
            'amp_od': 6.99,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.mild), isTrue);
      });

      test('should handle boundary between mild and moderate', () {
        final examRecord = ExamRecord(
          id: 'test-019',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.5,
            'amp_od': 4.9,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.moderate), isTrue);
      });

      test('should handle boundary between moderate and severe', () {
        final examRecord = ExamRecord(
          id: 'test-020',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.2,
            'amp_od': 2.9,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.abnormalities.every((a) => a.level == AbnormalLevel.severe), isTrue);
      });

      test('should handle zero values', () {
        final examRecord = ExamRecord(
          id: 'test-021',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.0,
            'sph_od': 0.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(1));
        expect(result.abnormalities.first.indicatorId, equals('va_far_uncorrected_od'));
        expect(result.abnormalities.first.level, equals(AbnormalLevel.severe));
      });

      test('should handle negative sphere values', () {
        final examRecord = ExamRecord(
          id: 'test-022',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'sph_od': -0.25,
            'sph_os': -0.49,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities, isEmpty);
      });

      test('should ignore non-numeric indicator values', () {
        final examRecord = ExamRecord(
          id: 'test-023',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 'invalid',
            'sph_od': null,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities, isEmpty);
      });
    });

    group('analyze - 综合评估', () {
      test('should prioritize severe abnormalities in overall assessment', () {
        final examRecord = ExamRecord(
          id: 'test-024',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.1,
            'sph_od': -1.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.abnormalities.length, equals(2));
        expect(result.overallAssessment, contains('重度异常'));
        expect(result.overallAssessment, contains('1 项指标重度异常'));
      });

      test('should extract key findings correctly', () {
        final examRecord = ExamRecord(
          id: 'test-025',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.8,
            'sph_od': -2.0,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.keyFindings.length, equals(2));
        expect(result.keyFindings.any((f) => f.contains('裸眼远视力（右眼）')), isTrue);
        expect(result.keyFindings.any((f) => f.contains('球镜（右眼）')), isTrue);
      });

      test('should generate comprehensive suggestions from all abnormalities', () {
        final examRecord = ExamRecord(
          id: 'test-026',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.8,
            'va_far_uncorrected_os': 0.7,
          },
        );

        final result = analysisService.analyze(examRecord);

        expect(result.comprehensiveSuggestions, isNotEmpty);
        expect(result.comprehensiveSuggestions, contains('验光检查'));
        expect(result.comprehensiveSuggestions, contains('排除眼部器质性病变'));
      });

      test('should deduplicate suggestions', () {
        final examRecord = ExamRecord(
          id: 'test-027',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.8,
            'va_far_uncorrected_os': 0.7,
          },
        );

        final result = analysisService.analyze(examRecord);

        final uniqueSuggestions = result.comprehensiveSuggestions.toSet();
        expect(result.comprehensiveSuggestions.length, equals(uniqueSuggestions.length));
      });
    });

    group('AbnormalIndicator', () {
      test('should create AbnormalIndicator with all required fields', () {
        final indicator = AbnormalIndicator(
          indicatorId: 'test_id',
          indicatorName: '测试指标',
          inputValue: 5.0,
          unit: 'D',
          level: AbnormalLevel.moderate,
          interpretation: '中度异常',
          possibleCauses: ['原因1', '原因2'],
          recommendations: ['建议1', '建议2'],
        );

        expect(indicator.indicatorId, equals('test_id'));
        expect(indicator.indicatorName, equals('测试指标'));
        expect(indicator.inputValue, equals(5.0));
        expect(indicator.unit, equals('D'));
        expect(indicator.level, equals(AbnormalLevel.moderate));
        expect(indicator.interpretation, equals('中度异常'));
        expect(indicator.possibleCauses, equals(['原因1', '原因2']));
        expect(indicator.recommendations, equals(['建议1', '建议2']));
      });
    });

    group('AnalysisResult', () {
      test('should create AnalysisResult with all required fields', () {
        final now = DateTime.now();
        final result = AnalysisResult(
          examId: 'exam-001',
          analyzedAt: now,
          abnormalities: [],
          overallAssessment: '正常',
          keyFindings: [],
          comprehensiveSuggestions: [],
          totalIndicators: 8,
          abnormalCount: 0,
        );

        expect(result.examId, equals('exam-001'));
        expect(result.analyzedAt, equals(now));
        expect(result.abnormalities, isEmpty);
        expect(result.overallAssessment, equals('正常'));
        expect(result.keyFindings, isEmpty);
        expect(result.comprehensiveSuggestions, isEmpty);
        expect(result.totalIndicators, equals(8));
        expect(result.abnormalCount, equals(0));
      });
    });
  });
}
