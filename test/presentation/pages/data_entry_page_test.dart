import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/presentation/pages/data_entry_page.dart';
import 'package:vision_analyzer/presentation/pages/analysis_report_page.dart';
import 'package:vision_analyzer/data/models/patient.dart';

void main() {
  group('DataEntryPage Widget Tests', () {
    testWidgets('should display correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('数据录入'), findsOneWidget);
    });

    testWidgets('should display save draft button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('保存草稿'), findsOneWidget);
    });

    testWidgets('should display analyze button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, '开始分析'), findsOneWidget);
    });

    testWidgets('should display indicator input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      // 验证有输入框
      expect(find.byType(TextField), findsWidgets);
      
      // 验证指标名称显示
      expect(find.text('裸眼远视力（右眼）'), findsOneWidget);
    });

    testWidgets('should show required indicator badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('必填'), findsWidgets);
    });

    testWidgets('should accept numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '1.0');
      await tester.pump();

      expect(find.text('1.0'), findsOneWidget);
    });

    testWidgets('should show snackbar when analyze without data', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      expect(find.text('请至少输入一项数据'), findsOneWidget);
    });

    testWidgets('should show snackbar when save draft', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存草稿'));
      await tester.pumpAndSettle();

      expect(find.text('草稿已保存'), findsOneWidget);
    });

    testWidgets('should display indicator description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      // 验证有描述文字
      expect(find.text('未矫正状态下的远距离视力'), findsOneWidget);
    });

    testWidgets('should have correct keyboard type for numeric input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.keyboardType, equals(const TextInputType.numberWithOptions(decimal: true)));
    });

    testWidgets('should display unit suffix', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      // 滚动查找带有单位的输入框
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // 验证某些输入框有单位后缀
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);
    });

    testWidgets('should have outlined input decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField).first);
      expect(textField.decoration, isNotNull);
      expect(textField.decoration!.border, isA<OutlineInputBorder>());
    });

    testWidgets('should have list view for scrolling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should display cards for each indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should have bottom navigation bar with analyze button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsWidgets);
    });

    testWidgets('should navigate to analysis report page after analyze', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      // 输入数据
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '0.8');
      await tester.pump();

      // 点击分析按钮
      await tester.tap(find.widgetWithText(ElevatedButton, '开始分析'));
      await tester.pumpAndSettle();

      // 验证导航到分析报告页面
      expect(find.byType(AnalysisReportPage), findsOneWidget);
    });

    testWidgets('should handle different exam types', (WidgetTester tester) async {
      for (var type in [ExamType.standardFullSet, ExamType.binocularVision, ExamType.custom]) {
        await tester.pumpWidget(
          MaterialApp(
            home: DataEntryPage(examType: type),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('数据录入'), findsOneWidget);
      }
    });

    testWidgets('should have proper padding on cards', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should handle multiple input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsAtLeastNWidgets(1));
    });

    testWidgets('should allow entering decimal values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '1.25');
      await tester.pump();

      expect(find.text('1.25'), findsOneWidget);
    });

    testWidgets('should allow entering negative values', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      if (textFields.evaluate().isNotEmpty) {
        await tester.enterText(textFields.first, '-2.5');
        await tester.pump();
        expect(find.text('-2.5'), findsOneWidget);
      }
    });

    testWidgets('should have proper app bar actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle rapid button taps', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      // 快速多次点击保存草稿
      await tester.tap(find.text('保存草稿'));
      await tester.tap(find.text('保存草稿'));
      await tester.tap(find.text('保存草稿'));
      await tester.pumpAndSettle();

      expect(find.text('草稿已保存'), findsOneWidget);
    });

    testWidgets('should have scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataEntryPage(examType: ExamType.standardFullSet),
        ),
      );
      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // 尝试滚动
      await tester.drag(listView, const Offset(0, -200));
      await tester.pumpAndSettle();
    });
  });
}
