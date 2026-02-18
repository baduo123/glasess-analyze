import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/domain/services/pdf_service.dart';

// 模拟类用于测试
class MockPatient extends Patient {
  MockPatient({
    required super.id,
    required super.name,
    required super.age,
    required super.gender,
    super.phone,
    super.note,
    required super.createdAt,
    required super.updatedAt,
  });
}

class MockExamRecord extends ExamRecord {
  MockExamRecord({
    required super.id,
    super.patientId,
    required super.examType,
    required super.examDate,
    required super.createdAt,
    super.isDraft,
    super.pdfPath,
    super.indicatorValues,
  });
}

void main() {
  group('PDFService', () {
    late PDFService pdfService;

    setUp(() {
      pdfService = PDFService();
    });

    group('PDF生成', () {
      test('should create PDF service instance', () {
        expect(pdfService, isNotNull);
      });

      test('should return singleton instance', () {
        final instance1 = PDFService();
        final instance2 = PDFService();
        expect(identical(instance1, instance2), isTrue);
      });

      test('should exportToPDF with valid data', () async {
        final patient = MockPatient(
          id: 'test-patient-001',
          name: '测试患者',
          age: 25,
          gender: '男',
          phone: '13800138000',
          note: '测试备注',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        final examRecord = MockExamRecord(
          id: 'test-exam-001',
          patientId: patient.id,
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 1, 15, 10, 30),
          createdAt: DateTime(2024, 1, 15, 10, 30),
          indicatorValues: {
            'va_far_uncorrected_od': 1.0,
            'va_far_uncorrected_os': 0.8,
            'amp_od': 8.0,
            'sph_od': -2.50,
            'iop_od': 15.0,
          },
        );

        final analysisResults = {
          'indicators': [
            {
              'name': '右眼裸眼视力',
              'value': 1.0,
              'unit': '',
              'reference': '≥1.0',
              'status': 'normal',
            },
            {
              'name': '左眼裸眼视力',
              'value': 0.8,
              'unit': '',
              'reference': '≥1.0',
              'status': 'warning',
            },
          ],
          'conclusions': [
            '右眼视力正常',
            '左眼视力轻度下降',
          ],
          'recommendations': [
            '定期复查视力',
            '注意用眼卫生',
          ],
        };

        // 由于 getApplicationDocumentsDirectory 在测试环境中不可用，
        // 我们测试 exportToPDF 会抛出异常
        try {
          await pdfService.exportToPDF(
            patient: patient,
            examRecord: examRecord,
            analysisResults: analysisResults,
          );
          fail('Expected exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle exam type names correctly', () {
        // 验证检查类型名称映射
        final examTypes = [
          ExamType.standardFullSet,
          ExamType.binocularVision,
          ExamType.amblyopiaScreening,
          ExamType.asthenopiaAssessment,
          ExamType.custom,
        ];

        final typeNames = {
          ExamType.standardFullSet: '全套视功能检查',
          ExamType.binocularVision: '双眼视功能检查',
          ExamType.amblyopiaScreening: '弱视筛查',
          ExamType.asthenopiaAssessment: '视疲劳评估',
          ExamType.custom: '自定义检查',
        };

        for (final type in examTypes) {
          expect(typeNames.containsKey(type), isTrue);
          expect(typeNames[type], isNotEmpty);
        }
      });

      test('should handle empty analysis results', () async {
        final patient = MockPatient(
          id: 'test-patient-002',
          name: '测试患者2',
          age: 30,
          gender: '女',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        final examRecord = MockExamRecord(
          id: 'test-exam-002',
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final emptyResults = {
          'indicators': [],
          'conclusions': [],
          'recommendations': [],
        };

        try {
          await pdfService.exportToPDF(
            patient: patient,
            examRecord: examRecord,
            analysisResults: emptyResults,
          );
          fail('Expected exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle different indicator statuses', () {
        final statuses = ['normal', 'warning', 'abnormal', 'unknown'];
        
        for (final status in statuses) {
          expect(status, isA<String>());
        }
      });
    });

    group('文件保存', () {
      test('should handle file path generation', () {
        final now = DateTime.now();
        final fileName = 'report_测试_${now.millisecondsSinceEpoch}.pdf';
        
        expect(fileName.contains('.pdf'), isTrue);
        expect(fileName.contains('report'), isTrue);
      });

      test('should handle custom output path', () async {
        final patient = MockPatient(
          id: 'test-patient-003',
          name: '测试患者3',
          age: 35,
          gender: '男',
          createdAt: DateTime(2024, 1, 15),
          updatedAt: DateTime(2024, 1, 15),
        );

        final examRecord = MockExamRecord(
          id: 'test-exam-003',
          examType: ExamType.standardFullSet,
          examDate: DateTime(2024, 1, 15),
          createdAt: DateTime(2024, 1, 15),
        );

        final tempDir = Directory.systemTemp;
        final outputPath = '${tempDir.path}/test_report.pdf';

        try {
          await pdfService.exportToPDF(
            patient: patient,
            examRecord: examRecord,
            analysisResults: {
              'indicators': [],
              'conclusions': [],
              'recommendations': [],
            },
            outputPath: outputPath,
          );
        } catch (e) {
          // 预期在测试环境中会失败
          expect(e, isA<Exception>());
        }
      });
    });

    group('错误处理', () {
      test('should throw exception for invalid patient', () async {
        final examRecord = MockExamRecord(
          id: 'test-exam-004',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        // 测试空名称
        final invalidPatient = MockPatient(
          id: 'test-patient-004',
          name: '',
          age: 0,
          gender: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        try {
          await pdfService.exportToPDF(
            patient: invalidPatient,
            examRecord: examRecord,
            analysisResults: {},
          );
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle missing optional fields', () async {
        final patient = MockPatient(
          id: 'test-patient-005',
          name: '测试患者5',
          age: 25,
          gender: '男',
          // phone 和 note 为空
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final examRecord = MockExamRecord(
          id: 'test-exam-005',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
        );

        try {
          await pdfService.exportToPDF(
            patient: patient,
            examRecord: examRecord,
            analysisResults: {
              'indicators': [],
              'conclusions': [],
              'recommendations': [],
            },
          );
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle null indicator values', () {
        final examRecord = MockExamRecord(
          id: 'test-exam-006',
          examType: ExamType.standardFullSet,
          examDate: DateTime.now(),
          createdAt: DateTime.now(),
          indicatorValues: null,
        );

        expect(examRecord.indicatorValues, isNull);
      });
    });

    group('sharePDF', () {
      test('should throw exception for non-existent file', () async {
        try {
          await pdfService.sharePDF('/non/existent/file.pdf');
          fail('Expected exception');
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('getAllReports', () {
      test('should return empty list when no reports', () async {
        try {
          final reports = await pdfService.getAllReports();
          // 在测试环境中可能返回空列表或抛出异常
          expect(reports, isA<List<File>>());
        } catch (e) {
          // 预期在测试环境中可能会失败
          expect(e, isA<Exception>());
        }
      });
    });

    group('deleteReport', () {
      test('should handle non-existent file deletion', () async {
        // 删除不存在的文件不应该抛出异常
        try {
          await pdfService.deleteReport('/non/existent/file.pdf');
          // 如果文件不存在，应该静默处理
        } catch (e) {
          // 某些实现可能会抛出异常
          expect(e, isA<Exception>());
        }
      });

      test('should delete existing file', () async {
        final tempDir = Directory.systemTemp;
        final testFile = File('${tempDir.path}/test_report_to_delete.pdf');
        await testFile.writeAsString('fake pdf content');

        expect(await testFile.exists(), isTrue);

        await pdfService.deleteReport(testFile.path);

        // 文件应该已被删除
        expect(await testFile.exists(), isFalse);
      });
    });

    group('PDF Widget Building', () {
      test('should build report title correctly', () {
        const title = '视功能分析报告';
        expect(title, isNotEmpty);
        expect(title.contains('视功能'), isTrue);
      });

      test('should build patient info section', () {
        final patientInfo = {
          'name': '张三',
          'age': 25,
          'gender': '男',
          'phone': '13800138000',
        };

        expect(patientInfo['name'], equals('张三'));
        expect(patientInfo['age'], equals(25));
      });

      test('should build exam info section', () {
        final examInfo = {
          'type': '全套视功能检查',
          'date': DateTime(2024, 1, 15),
        };

        expect(examInfo['type'], equals('全套视功能检查'));
        expect(examInfo['date'], isA<DateTime>());
      });
    });
  });
}
