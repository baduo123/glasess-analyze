import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/main.dart';
import 'package:vision_analyzer/presentation/pages/home_page.dart';
import 'package:vision_analyzer/presentation/pages/exam_type_selection_page.dart';
import 'package:vision_analyzer/presentation/pages/data_entry_page.dart';
import 'package:vision_analyzer/presentation/pages/analysis_report_page.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/domain/services/analysis_service.dart';

void main() {
  group('Integration Tests - Complete User Flow', () {
    testWidgets('完整流程: 新建检查 → 录入数据 → 分析 → 查看报告', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 步骤1: 验证首页显示
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('视功能分析'), findsOneWidget);
      expect(find.text('视功能自动分析'), findsOneWidget);
      expect(find.text('专业视功能检查数据分析工具'), findsOneWidget);

      // 步骤2: 点击"新建检查"按钮
      expect(find.widgetWithText(ElevatedButton, '新建检查'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();

      // 步骤3: 验证导航到检查类型选择页面
      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);
      expect(find.text('选择检查类型'), findsOneWidget);

      // 步骤4: 选择"标准全套检查"
      expect(find.text('标准全套检查'), findsOneWidget);
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      // 步骤5: 验证导航到数据录入页面
      expect(find.byType(DataEntryPage), findsOneWidget);
      expect(find.text('数据录入'), findsOneWidget);

      // 步骤6: 录入视力数据
      final vaOdField = find.widgetWithText(TextField, '请输入数值').first;
      await tester.enterText(vaOdField, '0.8');
      await tester.pump();

      // 步骤7: 向下滚动找到更多输入字段
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 步骤8: 点击"开始分析"按钮
      expect(find.widgetWithText(ElevatedButton, '开始分析'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 步骤9: 验证导航到分析报告页面
      expect(find.byType(AnalysisReportPage), findsOneWidget);
      expect(find.text('分析报告'), findsOneWidget);
      expect(find.text('分析概览'), findsOneWidget);
    });

    testWidgets('完整流程: 录入正常数据并得到正常结果', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 导航到数据录入页面
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      // 录入所有正常值数据
      final textFields = find.byType(TextField);
      
      // 录入多个正常值
      for (int i = 0; i < 5; i++) {
        if (i > 0) {
          await tester.drag(find.byType(ListView), const Offset(0, -200));
          await tester.pumpAndSettle();
        }
        
        final field = textFields.at(i);
        if (finderIsVisible(tester, field)) {
          await tester.enterText(field, '1.0');
          await tester.pump();
        }
      }

      // 点击分析
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 验证分析结果页面显示
      expect(find.byType(AnalysisReportPage), findsOneWidget);
    });

    testWidgets('完整流程: 录入异常数据并查看异常报告', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 导航到数据录入页面
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      // 录入异常视力值
      final firstField = find.widgetWithText(TextField, '请输入数值').first;
      await tester.enterText(firstField, '0.3');
      await tester.pump();

      // 点击分析
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 验证分析报告页面
      expect(find.byType(AnalysisReportPage), findsOneWidget);
      expect(find.text('分析概览'), findsOneWidget);
    });

    testWidgets('流程: 尝试不录入数据直接分析应该提示错误', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 导航到数据录入页面
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      // 直接点击分析，不录入数据
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 验证显示错误提示
      expect(find.text('请至少输入一项数据'), findsOneWidget);
    });

    testWidgets('流程: 保存草稿功能', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 导航到数据录入页面
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      // 录入一些数据
      final firstField = find.widgetWithText(TextField, '请输入数值').first;
      await tester.enterText(firstField, '0.9');
      await tester.pump();

      // 点击保存草稿
      await tester.tap(find.text('保存草稿'));
      await tester.pumpAndSettle();

      // 验证显示草稿保存成功提示
      expect(find.text('草稿已保存'), findsOneWidget);
    });

    testWidgets('流程: 分析报告页面元素验证', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 导航到数据录入页面
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();

      // 录入异常数据
      final firstField = find.widgetWithText(TextField, '请输入数值').first;
      await tester.enterText(firstField, '0.1');
      await tester.pump();

      // 点击分析
      await tester.ensureVisible(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 验证分析报告页面元素
      expect(find.text('分析概览'), findsOneWidget);
      expect(find.textContaining('检查项目总数'), findsOneWidget);
      expect(find.textContaining('异常指标数'), findsOneWidget);

      // 验证报告操作按钮
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('AnalysisService integration test', (WidgetTester tester) async {
      final analysisService = AnalysisService();

      // 创建测试数据
      final examRecord = ExamRecord(
        id: 'integration-test-001',
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 0.5,
          'va_far_uncorrected_os': 1.0,
          'amp_od': 8.0,
          'amp_os': 7.0,
          'sph_od': -4.0,
          'sph_os': 0.0,
          'iop_od': 15.0,
          'iop_os': 20.0,
        },
      );

      // 执行分析
      final result = analysisService.analyze(examRecord);

      // 验证分析结果
      expect(result.examId, equals('integration-test-001'));
      expect(result.totalIndicators, equals(8));
      expect(result.abnormalCount, greaterThan(0));
      expect(result.abnormalities, isNotEmpty);
      expect(result.overallAssessment, isNotEmpty);
      expect(result.keyFindings, isNotEmpty);
    });

    testWidgets('Multiple indicators analysis flow', (WidgetTester tester) async {
      final analysisService = AnalysisService();

      // 测试多种异常级别组合
      final examRecord = ExamRecord(
        id: 'multi-level-test',
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 0.8, // mild
          'va_far_uncorrected_os': 0.4, // moderate
          'sph_od': -8.0, // severe
        },
      );

      final result = analysisService.analyze(examRecord);

      // 验证包含所有级别的异常
      expect(result.abnormalities.length, equals(3));
      expect(
        result.abnormalities.any((a) => a.level == AbnormalLevel.mild),
        isTrue,
      );
      expect(
        result.abnormalities.any((a) => a.level == AbnormalLevel.moderate),
        isTrue,
      );
      expect(
        result.abnormalities.any((a) => a.level == AbnormalLevel.severe),
        isTrue,
      );

      // 验证整体评估优先显示重度异常
      expect(result.overallAssessment, contains('重度异常'));
    });

    testWidgets('Navigation flow test', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 验证首页
      expect(find.byType(HomePage), findsOneWidget);

      // 导航到检查类型选择
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);

      // 返回首页
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);

      // 再次导航
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();
      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);

      // 选择检查类型
      await tester.tap(find.text('标准全套检查'));
      await tester.pumpAndSettle();
      expect(find.byType(DataEntryPage), findsOneWidget);
    });
  });
}

// 辅助函数: 检查finder是否在可视范围内
bool finderIsVisible(WidgetTester tester, Finder finder) {
  try {
    final element = finder.evaluate().first;
    final renderObject = element.renderObject;
    if (renderObject is RenderBox) {
      final position = renderObject.localToGlobal(Offset.zero);
      return position.dy >= 0 && position.dy <= 800;
    }
    return true;
  } catch (e) {
    return false;
  }
}
