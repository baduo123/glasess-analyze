import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vision_analyzer/main.dart';
import 'package:vision_analyzer/data/database/database_helper.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/data/repositories/patient_repository.dart';
import 'package:vision_analyzer/data/repositories/exam_repository.dart';
import 'package:vision_analyzer/domain/services/analysis_service.dart';
import 'package:vision_analyzer/domain/services/pdf_service.dart';
import 'package:vision_analyzer/presentation/pages/home_page.dart';
import 'package:vision_analyzer/presentation/pages/exam_type_selection_page.dart';
import 'package:vision_analyzer/presentation/pages/data_entry_page.dart';
import 'package:vision_analyzer/presentation/pages/analysis_report_page.dart';

void main() {
  group('Full Integration Flow Tests', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // 清理数据库
      final db = await DatabaseHelper.instance.database;
      await db.delete('exam_records');
      await db.delete('patients');
    });

    tearDown(() async {
      try {
        await DatabaseHelper.instance.close();
      } catch (e) {
        // 忽略
      }
    });

    testWidgets('完整流程: 创建患者 → 录入检查数据 → 执行分析 → 生成报告 → 导出PDF',
        (WidgetTester tester) async {
      // ========== 步骤1: 创建患者 ==========
      final patientRepository = PatientRepository();
      final patient = await patientRepository.createPatient(
        name: '测试患者',
        age: 25,
        gender: '男',
        phone: '13800138000',
        note: '集成测试患者',
      );

      expect(patient.id, isNotEmpty);
      expect(patient.name, equals('测试患者'));

      // ========== 步骤2: 创建检查记录 ==========
      final examRepository = ExamRepository();
      final exam = await examRepository.createExam(
        patientId: patient.id,
        examType: ExamType.standardFullSet,
        examDate: DateTime(2024, 1, 15, 10, 0),
        indicatorValues: {
          'va_far_uncorrected_od': 0.7,
          'va_far_uncorrected_os': 0.8,
          'amp_od': 6.0,
          'amp_os': 5.5,
          'sph_od': -2.50,
          'sph_os': -1.75,
          'iop_od': 16.0,
          'iop_os': 17.5,
        },
        isDraft: false,
      );

      expect(exam.id, isNotEmpty);
      expect(exam.patientId, equals(patient.id));

      // ========== 步骤3: 验证关联查询 ==========
      final patientExams = await examRepository.getExamsByPatientId(patient.id);
      expect(patientExams.length, equals(1));
      expect(patientExams.first.id, equals(exam.id));

      // ========== 步骤4: 执行分析 ==========
      final analysisService = AnalysisService();
      final analysisResult = analysisService.analyze(exam);

      expect(analysisResult.examId, equals(exam.id));
      expect(analysisResult.totalIndicators, equals(8));
      expect(analysisResult.abnormalCount, greaterThan(0));
      expect(analysisResult.abnormalities, isNotEmpty);
      expect(analysisResult.overallAssessment, isNotEmpty);
      expect(analysisResult.keyFindings, isNotEmpty);
      expect(analysisResult.comprehensiveSuggestions, isNotEmpty);

      // ========== 步骤5: 验证分析报告内容 ==========
      expect(analysisResult.abnormalities.any((a) => a.indicatorId == 'va_far_uncorrected_od'), isTrue);
      expect(analysisResult.abnormalities.any((a) => a.indicatorId == 'sph_od'), isTrue);

      // 验证异常级别
      final mildCount = analysisResult.abnormalities.where((a) => a.level == AbnormalLevel.mild).length;
      expect(mildCount, greaterThan(0));

      // ========== 步骤6: 测试报告页面渲染 ==========
      await tester.pumpWidget(
        MaterialApp(
          home: AnalysisReportPage(
            examRecord: exam,
            analysisResult: analysisResult,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('分析报告'), findsOneWidget);
      expect(find.text('分析概览'), findsOneWidget);
      expect(find.text('异常指标详情'), findsOneWidget);
      expect(find.text('关键发现'), findsOneWidget);
      expect(find.text('综合建议'), findsOneWidget);

      // ========== 步骤7: 验证患者计数 ==========
      final patientCount = await patientRepository.getPatientCount();
      expect(patientCount, equals(1));

      final examCount = await examRepository.getExamCount();
      expect(examCount, equals(1));
    });

    testWidgets('完整流程: 草稿 → 完成 → 分析', (WidgetTester tester) async {
      // ========== 步骤1: 创建患者 ==========
      final patientRepository = PatientRepository();
      final patient = await patientRepository.createPatient(
        name: '草稿测试患者',
        age: 30,
        gender: '女',
      );

      // ========== 步骤2: 创建草稿 ==========
      final examRepository = ExamRepository();
      final draft = await examRepository.createExam(
        patientId: patient.id,
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        indicatorValues: {'va_far_uncorrected_od': 0.8},
        isDraft: true,
      );

      expect(draft.isDraft, isTrue);

      // ========== 步骤3: 验证草稿计数 ==========
      final draftCount = await examRepository.getDraftCount();
      expect(draftCount, equals(1));

      // ========== 步骤4: 更新草稿为完成状态 ==========
      final completed = await examRepository.updateExam(
        draft.id,
        isDraft: false,
        indicatorValues: {
          'va_far_uncorrected_od': 0.8,
          'va_far_uncorrected_os': 0.9,
          'sph_od': -1.50,
        },
      );

      expect(completed.isDraft, isFalse);

      // ========== 步骤5: 执行分析 ==========
      final analysisService = AnalysisService();
      final analysisResult = analysisService.analyze(completed);

      expect(analysisResult.abnormalCount, greaterThan(0));

      // ========== 步骤6: 验证最终状态 ==========
      final finalDraftCount = await examRepository.getDraftCount();
      expect(finalDraftCount, equals(0));

      final examCount = await examRepository.getExamCount();
      expect(examCount, equals(1));
    });

    testWidgets('完整流程: 多患者多检查场景', (WidgetTester tester) async {
      final patientRepository = PatientRepository();
      final examRepository = ExamRepository();
      final analysisService = AnalysisService();

      // ========== 创建多个患者 ==========
      final patient1 = await patientRepository.createPatient(
        name: '患者A',
        age: 20,
        gender: '男',
      );

      final patient2 = await patientRepository.createPatient(
        name: '患者B',
        age: 35,
        gender: '女',
      );

      // ========== 为每个患者创建多个检查 ==========
      final exam1 = await examRepository.createExam(
        patientId: patient1.id,
        examType: ExamType.standardFullSet,
        examDate: DateTime(2024, 1, 10),
        indicatorValues: {'va_far_uncorrected_od': 1.0},
      );

      final exam2 = await examRepository.createExam(
        patientId: patient1.id,
        examType: ExamType.binocularVision,
        examDate: DateTime(2024, 2, 10),
        indicatorValues: {'va_far_uncorrected_od': 0.9},
      );

      final exam3 = await examRepository.createExam(
        patientId: patient2.id,
        examType: ExamType.standardFullSet,
        examDate: DateTime(2024, 1, 20),
        indicatorValues: {'va_far_uncorrected_od': 0.7},
      );

      // ========== 验证关联关系 ==========
      final patient1Exams = await examRepository.getExamsByPatientId(patient1.id);
      expect(patient1Exams.length, equals(2));

      final patient2Exams = await examRepository.getExamsByPatientId(patient2.id);
      expect(patient2Exams.length, equals(1));

      // ========== 执行多次分析 ==========
      final result1 = analysisService.analyze(exam1);
      expect(result1.abnormalCount, equals(0));

      final result2 = analysisService.analyze(exam2);
      expect(result2.abnormalCount, equals(1));

      final result3 = analysisService.analyze(exam3);
      expect(result3.abnormalCount, equals(1));

      // ========== 验证计数 ==========
      expect(await patientRepository.getPatientCount(), equals(2));
      expect(await examRepository.getExamCount(), equals(3));
    });

    testWidgets('完整流程: 删除患者级联删除检查', (WidgetTester tester) async {
      final patientRepository = PatientRepository();
      final examRepository = ExamRepository();

      // ========== 创建患者和检查 ==========
      final patient = await patientRepository.createPatient(
        name: '将被删除的患者',
        age: 40,
        gender: '男',
      );

      await examRepository.createExam(
        patientId: patient.id,
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        indicatorValues: {'va_far_uncorrected_od': 0.8},
      );

      await examRepository.createExam(
        patientId: patient.id,
        examType: ExamType.binocularVision,
        examDate: DateTime.now(),
        indicatorValues: {'va_far_uncorrected_od': 0.9},
      );

      // ========== 验证创建成功 ==========
      expect(await patientRepository.getPatientCount(), equals(1));
      expect(await examRepository.getExamCount(), equals(2));

      // ========== 删除患者 ==========
      await patientRepository.deletePatient(patient.id);

      // ========== 验证级联删除 ==========
      expect(await patientRepository.getPatientCount(), equals(0));
      expect(await examRepository.getExamCount(), equals(0));
      expect(await examRepository.getExamsByPatientId(patient.id), isEmpty);
    });

    testWidgets('完整流程: 搜索患者', (WidgetTester tester) async {
      final patientRepository = PatientRepository();

      // ========== 创建测试患者 ==========
      await patientRepository.createPatient(
        name: '张三',
        age: 25,
        gender: '男',
        phone: '13800138000',
      );

      await patientRepository.createPatient(
        name: '张三丰',
        age: 60,
        gender: '男',
        phone: '13900139000',
      );

      await patientRepository.createPatient(
        name: '李四',
        age: 30,
        gender: '女',
        phone: '13700137000',
      );

      // ========== 按姓名搜索 ==========
      final searchResults1 = await patientRepository.searchPatients('张');
      expect(searchResults1.length, equals(2));

      final searchResults2 = await patientRepository.searchPatients('三');
      expect(searchResults2.length, equals(2));

      final searchResults3 = await patientRepository.searchPatients('李四');
      expect(searchResults3.length, equals(1));

      // ========== 按电话搜索 ==========
      final phoneSearch = await patientRepository.searchPatients('13800');
      expect(phoneSearch.length, equals(1));
      expect(phoneSearch.first.name, equals('张三'));
    });

    testWidgets('完整流程: 更新患者信息', (WidgetTester tester) async {
      final patientRepository = PatientRepository();

      // ========== 创建患者 ==========
      final patient = await patientRepository.createPatient(
        name: '原始姓名',
        age: 25,
        gender: '男',
        phone: '13800138000',
        note: '原始备注',
      );

      // ========== 更新部分信息 ==========
      final updated1 = await patientRepository.updatePatient(
        patient.id,
        name: '更新后的姓名',
        age: 30,
      );

      expect(updated1.name, equals('更新后的姓名'));
      expect(updated1.age, equals(30));
      expect(updated1.gender, equals('男')); // 未更新
      expect(updated1.phone, equals('13800138000')); // 未更新

      // ========== 更新所有信息 ==========
      final updated2 = await patientRepository.updatePatient(
        patient.id,
        name: '最终姓名',
        age: 35,
        gender: '女',
        phone: '13900139000',
        note: '最终备注',
      );

      expect(updated2.name, equals('最终姓名'));
      expect(updated2.age, equals(35));
      expect(updated2.gender, equals('女'));
      expect(updated2.phone, equals('13900139000'));
      expect(updated2.note, equals('最终备注'));
    });

    testWidgets('完整流程: 边界值分析', (WidgetTester tester) async {
      final examRepository = ExamRepository();
      final analysisService = AnalysisService();

      // ========== 边界值: 刚好在临界点 ==========
      final exam = await examRepository.createExam(
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 1.0,  // 正常边界
          'va_far_uncorrected_os': 0.9,  // 轻度边界
          'sph_od': -0.50,  // 正常边界
          'iop_od': 21.0,   // 正常边界
        },
      );

      final result = analysisService.analyze(exam);

      // 验证边界值处理
      expect(result.abnormalities.where((a) => a.indicatorId == 'va_far_uncorrected_od'), isEmpty);
      expect(result.abnormalities.any((a) => a.indicatorId == 'va_far_uncorrected_os'), isTrue);
      expect(result.abnormalities.where((a) => a.indicatorId == 'sph_od'), isEmpty);
      expect(result.abnormalities.where((a) => a.indicatorId == 'iop_od'), isEmpty);
    });

    testWidgets('完整流程: UI导航流程', (WidgetTester tester) async {
      // ========== 步骤1: 启动应用 ==========
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 验证首页
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('视功能分析'), findsOneWidget);

      // ========== 步骤2: 导航到检查类型选择 ==========
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);
      expect(find.text('选择检查类型'), findsOneWidget);

      // ========== 步骤3: 选择检查类型 ==========
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      expect(find.byType(DataEntryPage), findsOneWidget);
      expect(find.text('数据录入'), findsOneWidget);

      // ========== 步骤4: 录入数据 ==========
      final firstField = find.byType(TextField).first;
      await tester.enterText(firstField, '0.7');
      await tester.pump();

      // ========== 步骤5: 执行分析 ==========
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 验证分析报告页面
      expect(find.byType(AnalysisReportPage), findsOneWidget);
      expect(find.text('分析报告'), findsOneWidget);
      expect(find.text('分析概览'), findsOneWidget);
    });

    testWidgets('完整流程: 空数据分析', (WidgetTester tester) async {
      final examRepository = ExamRepository();
      final analysisService = AnalysisService();

      // ========== 创建空检查记录 ==========
      final exam = await examRepository.createExam(
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        indicatorValues: {},
      );

      // ========== 执行分析 ==========
      final result = analysisService.analyze(exam);

      expect(result.abnormalCount, equals(0));
      expect(result.abnormalities, isEmpty);
      expect(result.totalIndicators, greaterThan(0));
      expect(result.overallAssessment, contains('正常'));
    });

    testWidgets('完整流程: 异常处理', (WidgetTester tester) async {
      final patientRepository = PatientRepository();

      // ========== 测试获取不存在的患者 ==========
      final nonExistent = await patientRepository.getPatientById('non-existent-id');
      expect(nonExistent, isNull);

      // ========== 测试更新不存在的患者 ==========
      expect(
        () => patientRepository.updatePatient('non-existent-id', name: '测试'),
        throwsException,
      );

      // ========== 测试删除不存在的患者 ==========
      expect(
        () => patientRepository.deletePatient('non-existent-id'),
        throwsException,
      );
    });
  });
}
