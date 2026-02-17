import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/data/models/patient.dart';

void main() {
  group('Patient Model', () {
    late Patient testPatient;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30, 0);
      testPatient = Patient(
        id: 'patient-001',
        name: '张三',
        age: 25,
        gender: '男',
        phone: '13800138000',
        note: '测试患者备注',
        createdAt: testDate,
        updatedAt: testDate,
      );
    });

    group('Constructor', () {
      test('should create Patient with all required fields', () {
        expect(testPatient.id, equals('patient-001'));
        expect(testPatient.name, equals('张三'));
        expect(testPatient.age, equals(25));
        expect(testPatient.gender, equals('男'));
        expect(testPatient.phone, equals('13800138000'));
        expect(testPatient.note, equals('测试患者备注'));
        expect(testPatient.createdAt, equals(testDate));
        expect(testPatient.updatedAt, equals(testDate));
      });

      test('should create Patient with null optional fields', () {
        final patient = Patient(
          id: 'patient-002',
          name: '李四',
          age: 30,
          gender: '女',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(patient.phone, isNull);
        expect(patient.note, isNull);
      });

      test('should handle different age values', () {
        final child = Patient(
          id: 'child-001',
          name: '儿童',
          age: 5,
          gender: '男',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final elderly = Patient(
          id: 'elder-001',
          name: '老人',
          age: 80,
          gender: '女',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(child.age, equals(5));
        expect(elderly.age, equals(80));
      });

      test('should handle different gender values', () {
        final male = Patient(
          id: 'male-001',
          name: '男患者',
          age: 30,
          gender: '男',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final female = Patient(
          id: 'female-001',
          name: '女患者',
          age: 30,
          gender: '女',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(male.gender, equals('男'));
        expect(female.gender, equals('女'));
      });
    });

    group('toJson', () {
      test('should serialize Patient to JSON correctly', () {
        final json = testPatient.toJson();

        expect(json['id'], equals('patient-001'));
        expect(json['name'], equals('张三'));
        expect(json['age'], equals(25));
        expect(json['gender'], equals('男'));
        expect(json['phone'], equals('13800138000'));
        expect(json['note'], equals('测试患者备注'));
        expect(json['created_at'], equals(testDate.millisecondsSinceEpoch));
        expect(json['updated_at'], equals(testDate.millisecondsSinceEpoch));
      });

      test('should serialize Patient with null fields to JSON correctly', () {
        final patient = Patient(
          id: 'patient-003',
          name: '王五',
          age: 35,
          gender: '男',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = patient.toJson();

        expect(json['id'], equals('patient-003'));
        expect(json['name'], equals('王五'));
        expect(json['age'], equals(35));
        expect(json['gender'], equals('男'));
        expect(json['phone'], isNull);
        expect(json['note'], isNull);
        expect(json['created_at'], equals(testDate.millisecondsSinceEpoch));
        expect(json['updated_at'], equals(testDate.millisecondsSinceEpoch));
      });

      test('should serialize dates as milliseconds since epoch', () {
        final json = testPatient.toJson();

        expect(json['created_at'], isA<int>());
        expect(json['updated_at'], isA<int>());
        expect(json['created_at'], equals(1705319400000));
      });
    });

    group('fromJson', () {
      test('should deserialize JSON to Patient correctly', () {
        final json = {
          'id': 'patient-004',
          'name': '赵六',
          'age': 28,
          'gender': '女',
          'phone': '13900139000',
          'note': '备注信息',
          'created_at': testDate.millisecondsSinceEpoch,
          'updated_at': testDate.millisecondsSinceEpoch,
        };

        final patient = Patient.fromJson(json);

        expect(patient.id, equals('patient-004'));
        expect(patient.name, equals('赵六'));
        expect(patient.age, equals(28));
        expect(patient.gender, equals('女'));
        expect(patient.phone, equals('13900139000'));
        expect(patient.note, equals('备注信息'));
        expect(patient.createdAt, equals(testDate));
        expect(patient.updatedAt, equals(testDate));
      });

      test('should deserialize JSON with null fields correctly', () {
        final json = {
          'id': 'patient-005',
          'name': '钱七',
          'age': 40,
          'gender': '男',
          'phone': null,
          'note': null,
          'created_at': testDate.millisecondsSinceEpoch,
          'updated_at': testDate.millisecondsSinceEpoch,
        };

        final patient = Patient.fromJson(json);

        expect(patient.id, equals('patient-005'));
        expect(patient.name, equals('钱七'));
        expect(patient.age, equals(40));
        expect(patient.gender, equals('男'));
        expect(patient.phone, isNull);
        expect(patient.note, isNull);
      });

      test('should convert milliseconds to DateTime correctly', () {
        final json = {
          'id': 'patient-006',
          'name': '孙八',
          'age': 22,
          'gender': '女',
          'created_at': 1705319400000,
          'updated_at': 1705319400000,
        };

        final patient = Patient.fromJson(json);

        expect(patient.createdAt, equals(DateTime(2024, 1, 15, 10, 30, 0)));
        expect(patient.updatedAt, equals(DateTime(2024, 1, 15, 10, 30, 0)));
      });
    });

    group('Round-trip serialization', () {
      test('should maintain data integrity through serialization cycle', () {
        final json = testPatient.toJson();
        final reconstructed = Patient.fromJson(json);

        expect(reconstructed.id, equals(testPatient.id));
        expect(reconstructed.name, equals(testPatient.name));
        expect(reconstructed.age, equals(testPatient.age));
        expect(reconstructed.gender, equals(testPatient.gender));
        expect(reconstructed.phone, equals(testPatient.phone));
        expect(reconstructed.note, equals(testPatient.note));
        expect(reconstructed.createdAt, equals(testPatient.createdAt));
        expect(reconstructed.updatedAt, equals(testPatient.updatedAt));
      });

      test('should handle edge case dates through serialization cycle', () {
        final epoch = DateTime.fromMillisecondsSinceEpoch(0);
        final patient = Patient(
          id: 'epoch-test',
          name: 'Epoch',
          age: 0,
          gender: '未知',
          createdAt: epoch,
          updatedAt: epoch,
        );

        final json = patient.toJson();
        final reconstructed = Patient.fromJson(json);

        expect(reconstructed.createdAt, equals(epoch));
        expect(reconstructed.updatedAt, equals(epoch));
      });

      test('should handle future dates through serialization cycle', () {
        final future = DateTime(2030, 12, 31, 23, 59, 59);
        final patient = Patient(
          id: 'future-test',
          name: 'Future',
          age: 100,
          gender: '男',
          createdAt: future,
          updatedAt: future,
        );

        final json = patient.toJson();
        final reconstructed = Patient.fromJson(json);

        expect(reconstructed.createdAt, equals(future));
        expect(reconstructed.updatedAt, equals(future));
      });
    });
  });

  group('ExamRecord Model', () {
    late ExamRecord testExamRecord;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 2, 20, 14, 0, 0);
      testExamRecord = ExamRecord(
        id: 'exam-001',
        patientId: 'patient-001',
        examType: ExamType.standardFullSet,
        examDate: testDate,
        createdAt: testDate,
        isDraft: false,
        pdfPath: '/path/to/report.pdf',
        indicatorValues: {
          'va_far_uncorrected_od': 1.0,
          'va_far_uncorrected_os': 0.8,
          'sph_od': -2.0,
        },
      );
    });

    group('Constructor', () {
      test('should create ExamRecord with all required fields', () {
        expect(testExamRecord.id, equals('exam-001'));
        expect(testExamRecord.patientId, equals('patient-001'));
        expect(testExamRecord.examType, equals(ExamType.standardFullSet));
        expect(testExamRecord.examDate, equals(testDate));
        expect(testExamRecord.createdAt, equals(testDate));
        expect(testExamRecord.isDraft, isFalse);
        expect(testExamRecord.pdfPath, equals('/path/to/report.pdf'));
        expect(testExamRecord.indicatorValues, isA<Map<String, dynamic>>());
        expect(testExamRecord.indicatorValues!.length, equals(3));
      });

      test('should create ExamRecord with default values', () {
        final exam = ExamRecord(
          id: 'exam-002',
          examType: ExamType.binocularVision,
          examDate: testDate,
          createdAt: testDate,
        );

        expect(exam.patientId, isNull);
        expect(exam.isDraft, isFalse);
        expect(exam.pdfPath, isNull);
        expect(exam.indicatorValues, isNull);
      });

      test('should handle all exam types', () {
        final types = [
          ExamType.standardFullSet,
          ExamType.binocularVision,
          ExamType.amblyopiaScreening,
          ExamType.asthenopiaAssessment,
          ExamType.custom,
        ];

        for (var type in types) {
          final exam = ExamRecord(
            id: 'exam-${type.name}',
            examType: type,
            examDate: testDate,
            createdAt: testDate,
          );

          expect(exam.examType, equals(type));
        }
      });

      test('should handle draft status', () {
        final draft = ExamRecord(
          id: 'exam-draft',
          examType: ExamType.standardFullSet,
          examDate: testDate,
          createdAt: testDate,
          isDraft: true,
        );

        expect(draft.isDraft, isTrue);
      });
    });

    group('toJson', () {
      test('should serialize ExamRecord to JSON correctly', () {
        final json = testExamRecord.toJson();

        expect(json['id'], equals('exam-001'));
        expect(json['patient_id'], equals('patient-001'));
        expect(json['exam_type'], equals('standardFullSet'));
        expect(json['exam_date'], equals(testDate.millisecondsSinceEpoch));
        expect(json['created_at'], equals(testDate.millisecondsSinceEpoch));
        expect(json['is_draft'], equals(0));
        expect(json['pdf_path'], equals('/path/to/report.pdf'));
        expect(json['indicator_values'], isA<String>());
      });

      test('should serialize isDraft as integer', () {
        final draft = ExamRecord(
          id: 'exam-003',
          examType: ExamType.standardFullSet,
          examDate: testDate,
          createdAt: testDate,
          isDraft: true,
        );

        final json = draft.toJson();

        expect(json['is_draft'], equals(1));
      });

      test('should serialize null indicator values correctly', () {
        final exam = ExamRecord(
          id: 'exam-004',
          examType: ExamType.standardFullSet,
          examDate: testDate,
          createdAt: testDate,
          indicatorValues: null,
        );

        final json = exam.toJson();

        expect(json['indicator_values'], isNull);
      });

      test('should serialize all exam types to string names', () {
        for (var type in ExamType.values) {
          final exam = ExamRecord(
            id: 'exam-${type.name}',
            examType: type,
            examDate: testDate,
            createdAt: testDate,
          );

          final json = exam.toJson();
          expect(json['exam_type'], equals(type.name));
        }
      });
    });

    group('fromJson', () {
      test('should deserialize JSON to ExamRecord correctly', () {
        final json = {
          'id': 'exam-005',
          'patient_id': 'patient-002',
          'exam_type': 'standardFullSet',
          'exam_date': testDate.millisecondsSinceEpoch,
          'created_at': testDate.millisecondsSinceEpoch,
          'is_draft': 0,
          'pdf_path': '/reports/exam-005.pdf',
          'indicator_values': {'va': 1.0},
        };

        final exam = ExamRecord.fromJson(json);

        expect(exam.id, equals('exam-005'));
        expect(exam.patientId, equals('patient-002'));
        expect(exam.examType, equals(ExamType.standardFullSet));
        expect(exam.examDate, equals(testDate));
        expect(exam.createdAt, equals(testDate));
        expect(exam.isDraft, isFalse);
        expect(exam.pdfPath, equals('/reports/exam-005.pdf'));
      });

      test('should deserialize draft status correctly', () {
        final jsonDraft = {
          'id': 'exam-006',
          'exam_type': 'standardFullSet',
          'exam_date': testDate.millisecondsSinceEpoch,
          'created_at': testDate.millisecondsSinceEpoch,
          'is_draft': 1,
        };

        final exam = ExamRecord.fromJson(jsonDraft);

        expect(exam.isDraft, isTrue);
      });

      test('should default to standardFullSet for unknown exam types', () {
        final json = {
          'id': 'exam-007',
          'exam_type': 'unknownType',
          'exam_date': testDate.millisecondsSinceEpoch,
          'created_at': testDate.millisecondsSinceEpoch,
          'is_draft': 0,
        };

        final exam = ExamRecord.fromJson(json);

        expect(exam.examType, equals(ExamType.standardFullSet));
      });

      test('should handle null optional fields correctly', () {
        final json = {
          'id': 'exam-008',
          'exam_type': 'binocularVision',
          'exam_date': testDate.millisecondsSinceEpoch,
          'created_at': testDate.millisecondsSinceEpoch,
          'is_draft': 0,
          'patient_id': null,
          'pdf_path': null,
          'indicator_values': null,
        };

        final exam = ExamRecord.fromJson(json);

        expect(exam.patientId, isNull);
        expect(exam.pdfPath, isNull);
        expect(exam.indicatorValues, isNull);
      });

      test('should handle all exam type names', () {
        final typeTests = {
          'standardFullSet': ExamType.standardFullSet,
          'binocularVision': ExamType.binocularVision,
          'amblyopiaScreening': ExamType.amblyopiaScreening,
          'asthenopiaAssessment': ExamType.asthenopiaAssessment,
          'custom': ExamType.custom,
        };

        typeTests.forEach((typeName, expectedType) {
          final json = {
            'id': 'exam-$typeName',
            'exam_type': typeName,
            'exam_date': testDate.millisecondsSinceEpoch,
            'created_at': testDate.millisecondsSinceEpoch,
            'is_draft': 0,
          };

          final exam = ExamRecord.fromJson(json);
          expect(exam.examType, equals(expectedType));
        });
      });
    });

    group('Round-trip serialization', () {
      test('should maintain data integrity through serialization cycle', () {
        final json = testExamRecord.toJson();
        final reconstructed = ExamRecord.fromJson(json);

        expect(reconstructed.id, equals(testExamRecord.id));
        expect(reconstructed.patientId, equals(testExamRecord.patientId));
        expect(reconstructed.examType, equals(testExamRecord.examType));
        expect(reconstructed.examDate, equals(testExamRecord.examDate));
        expect(reconstructed.createdAt, equals(testExamRecord.createdAt));
        expect(reconstructed.isDraft, equals(testExamRecord.isDraft));
        expect(reconstructed.pdfPath, equals(testExamRecord.pdfPath));
      });

      test('should handle complex indicator values', () {
        final exam = ExamRecord(
          id: 'complex-exam',
          examType: ExamType.standardFullSet,
          examDate: testDate,
          createdAt: testDate,
          indicatorValues: {
            'numeric': 5.5,
            'integer': 10,
            'string': 'test',
            'nested': {'key': 'value'},
            'list': [1, 2, 3],
          },
        );

        final json = exam.toJson();
        final reconstructed = ExamRecord.fromJson(json);

        expect(reconstructed.id, equals(exam.id));
      });
    });
  });

  group('ExamType enum', () {
    test('should contain all expected values', () {
      expect(ExamType.values, contains(ExamType.standardFullSet));
      expect(ExamType.values, contains(ExamType.binocularVision));
      expect(ExamType.values, contains(ExamType.amblyopiaScreening));
      expect(ExamType.values, contains(ExamType.asthenopiaAssessment));
      expect(ExamType.values, contains(ExamType.custom));
      expect(ExamType.values.length, equals(5));
    });

    test('should have correct string names', () {
      expect(ExamType.standardFullSet.name, equals('standardFullSet'));
      expect(ExamType.binocularVision.name, equals('binocularVision'));
      expect(ExamType.amblyopiaScreening.name, equals('amblyopiaScreening'));
      expect(ExamType.asthenopiaAssessment.name, equals('asthenopiaAssessment'));
      expect(ExamType.custom.name, equals('custom'));
    });
  });
}
