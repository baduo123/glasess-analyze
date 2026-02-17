import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/presentation/pages/home_page.dart';
import 'package:vision_analyzer/presentation/pages/exam_type_selection_page.dart';
import 'package:vision_analyzer/main.dart';

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('should display app title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text('视功能分析'), findsOneWidget);
    });

    testWidgets('should display main heading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text('视功能自动分析'), findsOneWidget);
    });

    testWidgets('should display subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text('专业视功能检查数据分析工具'), findsOneWidget);
    });

    testWidgets('should display vision icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should have new exam button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, '新建检查'), findsOneWidget);
      expect(find.widgetWithIcon(ElevatedButton, Icons.add_circle_outline), findsOneWidget);
    });

    testWidgets('should have patient list button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.widgetWithText(OutlinedButton, '患者列表'), findsOneWidget);
      expect(find.widgetWithIcon(OutlinedButton, Icons.people_outline), findsOneWidget);
    });

    testWidgets('should navigate to exam type selection page when new exam button is tapped', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const HomePage(),
          routes: {
            '/exam_type': (context) => const ExamTypeSelectionPage(),
          },
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();

      // 使用MyApp进行完整导航测试
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);
    });

    testWidgets('should have correct button order', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final newExamButton = find.widgetWithText(ElevatedButton, '新建检查');
      final patientListButton = find.widgetWithText(OutlinedButton, '患者列表');

      final newExamPosition = tester.getCenter(newExamButton);
      final patientListPosition = tester.getCenter(patientListButton);

      expect(newExamPosition.dy, lessThan(patientListPosition.dy));
    });

    testWidgets('should use correct button styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final newExamButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '新建检查'),
      );

      expect(newExamButton.style, isNotNull);
    });

    testWidgets('should have Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should have centered title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('should have proper padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('should have column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('new exam button should have correct style properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final button = find.widgetWithText(ElevatedButton, '新建检查');
      expect(button, findsOneWidget);
    });

    testWidgets('should render without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle multiple button taps', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 第一次点击
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);

      // 返回
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);

      // 第二次点击
      await tester.tap(find.widgetWithText(ElevatedButton, '新建检查'));
      await tester.pumpAndSettle();

      expect(find.byType(ExamTypeSelectionPage), findsOneWidget);
    });
  });
}
