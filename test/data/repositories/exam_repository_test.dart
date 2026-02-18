import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vision_analyzer/data/database/database_helper.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/data/repositories/exam_repository.dart';

void main() {
  group('ExamRepository', () {
    late ExamRepository examRepository;
    late DatabaseHelper databaseHelper;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      examRepository = ExamRepository();
      databaseHelper = DatabaseHelper.instance;
      
      // 清理数据库
      final db = await databaseHelper.database;
      await db.delete('exam_records');
      await db.delete('patients');
    });

    tearDown(() async {
      try {
        final db = await databaseHelper.database;
        await db.close();
      } catch (e) {
        // 忽略关闭错误
      }
    });

    group('createExam', () {
      test('should create exam with valid data', () async {
        final exam = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 1, 15),
        );

        expect(exam, isNotNull);
        expect(exam.id, isNotEmpty);
        expect(exam.examType, equals(ExamType.standardFullSet));
        expect(exam.examDate, equals(DateTime(2024, 1, 15)));
        expect(exam.isDraft, isFalse);
      });

      test('should create exam with patientId', () async {
        final exam = await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.binocularVision,
          examDate: DateTime.now(),
        );

        expect(exam.patientId, equals('patient-001'));
        expect(exam.examType, equals(ExamType.binocularVision));
      });

      test('should create exam with indicator values', () async {
        final indicatorValues = {
          'va_far_uncorrected_od': 1.0,
          'va_far_uncorrected_os': 0.8,
          'sph_od': -2.0,
        };

        final exam = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: indicatorValues,
        );

        expect(exam.indicatorValues, equals(indicatorValues));
      });

      test('should create draft exam', () async {
        final exam = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        expect(exam.isDraft, isTrue);
      });

      test('should assign unique IDs to different exams', () async {
        final exam1 = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        final exam2 = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        expect(exam1.id, isNot(equals(exam2.id)));
      });

      test('should handle all exam types', () async {
        for (final type in ExamType.values) {
          final exam = await examRepository.createExam(
            examType: type,
            examDate: DateTime.now(),
          );

          expect(exam.examType, equals(type));
        }
      });
    });

    group('getExamsByPatientId', () {
      test('should return empty list when no exams exist', () async {
        final exams = await examRepository.getExamsByPatientId('patient-001');
        expect(exams, isEmpty);
      });

      test('should return exams for specific patient', () async {
        await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.binocularVision,
          examDate: DateTime.now(),
        );

        await examRepository.createExam(
          patientId: 'patient-002',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        final exams = await examRepository.getExamsByPatientId('patient-001');

        expect(exams.length, equals(2));
        expect(exams.every((e) => e.patientId == 'patient-001'), isTrue);
      });

      test('should order exams by exam_date DESC', () async {
        await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 1, 1),
        );

        await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 3, 1),
        );

        await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 2, 1),
        );

        final exams = await examRepository.getExamsByPatientId('patient-001');

        expect(exams.length, equals(3));
        expect(exams[0].examDate, equals(DateTime(2024, 3, 1)));
        expect(exams[1].examDate, equals(DateTime(2024, 2, 1)));
        expect(exams[2].examDate, equals(DateTime(2024, 1, 1)));
      });
    });

    group('getExamById', () {
      test('should return exam by id', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: {'va': 1.0},
        );

        final exam = await examRepository.getExamById(created.id);

        expect(exam, isNotNull);
        expect(exam!.id, equals(created.id));
        expect(exam.examType, equals(ExamType.standardFullSet));
      });

      test('should parse indicator values correctly', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 1.0,
            'sph_od': -2.5,
          },
        );

        final exam = await examRepository.getExamById(created.id);

        expect(exam!.indicatorValues, isNotNull);
        expect(exam.indicatorValues!['va_far_uncorrected_od'], equals(1.0));
        expect(exam.indicatorValues!['sph_od'], equals(-2.5));
      });

      test('should return null for non-existent id', () async {
        final exam = await examRepository.getExamById('non-existent-id');
        expect(exam, isNull);
      });
    });

    group('getAllExams', () {
      test('should return all exams', () async {
        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        await examRepository.createExam(
          examType: ExamType.binocularVision,
          examDate: DateTime.now(),
        );

        final exams = await examRepository.getAllExams();

        expect(exams.length, equals(2));
      });

      test('should filter by draft status', () async {
        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: false,
        );

        await examRepository.createExam(
          examType: ExamType.binocularVision,
          examDate: DateTime.now(),
          isDraft: true,
        );

        final drafts = await examRepository.getAllExams(isDraft: true);
        final nonDrafts = await examRepository.getAllExams(isDraft: false);

        expect(drafts.length, equals(2));
        expect(nonDrafts.length, equals(1));
        expect(drafts.every((e) => e.isDraft), isTrue);
        expect(nonDrafts.every((e) => !e.isDraft), isTrue);
      });
    });

    group('updateExam', () {
      test('should update exam type', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        final updated = await examRepository.updateExam(
          created.id,
          examType: ExamType.binocularVision,
        );

        expect(updated.examType, equals(ExamType.binocularVision));
      });

      test('should update draft status', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        final updated = await examRepository.updateExam(
          created.id,
          isDraft: false,
        );

        expect(updated.isDraft, isFalse);
      });

      test('should update indicator values', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: {'va': 0.8},
        );

        final updated = await examRepository.updateExam(
          created.id,
          indicatorValues: {'va': 1.0, 'sph': -2.0},
        );

        expect(updated.indicatorValues!['va'], equals(1.0));
        expect(updated.indicatorValues!['sph'], equals(-2.0));
      });

      test('should update pdf path', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        final updated = await examRepository.updateExam(
          created.id,
          pdfPath: '/path/to/report.pdf',
        );

        expect(updated.pdfPath, equals('/path/to/report.pdf'));
      });

      test('should throw exception when exam does not exist', () async {
        expect(
          () => examRepository.updateExam(
            'non-existent-id',
            examType: ExamType.standardFullSet,
          ),
          throwsException,
        );
      });

      test('should preserve unchanged fields', () async {
        final created = await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 1, 15),
          indicatorValues: {'va': 1.0},
        );

        final updated = await examRepository.updateExam(
          created.id,
          isDraft: true,
        );

        expect(updated.patientId, equals('patient-001'));
        expect(updated.examType, equals(ExamType.standardFullSet));
        expect(updated.examDate, equals(DateTime(2024, 1, 15)));
        expect(updated.indicatorValues!['va'], equals(1.0));
      });
    });

    group('deleteExam', () {
      test('should delete exam by id', () async {
        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        await examRepository.deleteExam(created.id);

        final exam = await examRepository.getExamById(created.id);
        expect(exam, isNull);
      });

      test('should throw exception when exam does not exist', () async {
        expect(
          () => examRepository.deleteExam('non-existent-id'),
          throwsException,
        );
      });

      test('should decrease exam count after deletion', () async {
        final exam1 = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        final countBefore = await examRepository.getExamCount();
        expect(countBefore, equals(2));

        await examRepository.deleteExam(exam1.id);

        final countAfter = await examRepository.getExamCount();
        expect(countAfter, equals(1));
      });
    });

    group('Draft Functionality', () {
      test('should save draft with partial data', () async {
        final draft = await examRepository.createExam(
          patientId: 'patient-001',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: {
            'va_far_uncorrected_od': 0.8,
            // 其他指标未完成
          },
          isDraft: true,
        );

        expect(draft.isDraft, isTrue);
        expect(draft.indicatorValues!.length, equals(1));
      });

      test('should get draft count', () async {
        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: false,
        );

        final draftCount = await examRepository.getDraftCount();
        expect(draftCount, equals(2));
      });

      test('should convert draft to completed exam', () async {
        final draft = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: {'va': 0.8},
          isDraft: true,
        );

        final completed = await examRepository.updateExam(
          draft.id,
          isDraft: false,
          indicatorValues: {
            'va': 0.8,
            'sph': -2.0,
            'cyl': -1.0,
          },
        );

        expect(completed.isDraft, isFalse);
        expect(completed.indicatorValues!.length, equals(3));
      });

      test('should handle empty draft', () async {
        final draft = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        expect(draft.isDraft, isTrue);
        expect(draft.indicatorValues, isNull);
      });

      test('should retrieve only drafts', () async {
        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: true,
        );

        await examRepository.createExam(
          examType: ExamType.binocularVision,
          examDate: DateTime.now(),
          isDraft: true,
        );

        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          isDraft: false,
        );

        final drafts = await examRepository.getAllExams(isDraft: true);

        expect(drafts.length, equals(2));
        expect(drafts.every((e) => e.isDraft), isTrue);
      });
    });

    group('getExamCount', () {
      test('should return 0 when no exams', () async {
        final count = await examRepository.getExamCount();
        expect(count, equals(0));
      });

      test('should return correct count', () async {
        await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
        );

        await examRepository.createExam(
          examType: ExamType.binocularVision,
          examDate: DateTime.now(),
        );

        await examRepository.createExam(
          examType: ExamType.amblyopiaScreening,
          examDate: DateTime.now(),
        );

        final count = await examRepository.getExamCount();
        expect(count, equals(3));
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final instance1 = ExamRepository();
        final instance2 = ExamRepository();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('JSON Parsing', () {
      test('should handle invalid indicator values JSON', () async {
        final db = await databaseHelper.database;
        
        // 直接插入无效的JSON
        await db.insert('exam_records', {
          'id': 'exam-invalid',
          'exam_type': 'standardFullSet',
          'exam_date': DateTime.now().millisecondsSinceEpoch,
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'is_draft': 0,
          'indicator_values': 'invalid json',
        });

        final exam = await examRepository.getExamById('exam-invalid');

        expect(exam, isNotNull);
        expect(exam!.indicatorValues, isNull);
      });

      test('should handle complex nested indicator values', () async {
        final complexValues = {
          'va': {'od': 1.0, 'os': 0.8},
          'sph': {'od': -2.0, 'os': -1.5},
          'history': [1.0, 0.9, 0.8],
        };

        final created = await examRepository.createExam(
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          indicatorValues: complexValues,
        );

        final exam = await examRepository.getExamById(created.id);

        expect(exam!.indicatorValues, isNotNull);
        expect(exam.indicatorValues!['va'], isA<Map<String, dynamic>>());
        expect(exam.indicatorValues!['history'], isA<List<dynamic>>());
      });
    });
  });
}
