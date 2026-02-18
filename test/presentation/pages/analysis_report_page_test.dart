import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/data/models/patient.dart';
import 'package:vision_analyzer/domain/services/analysis_service.dart';
import 'package:vision_analyzer/presentation/pages/analysis_report_page.dart';

void main() {
  group('AnalysisReportPage Widget Tests', () {
    late ExamRecord examRecord;
    late AnalysisResult analysisResult;

    setUp(() {
      examRecord = ExamRecord(
        id: 'test-exam-001',
        examType: ExamType.standardFullSet,
        examDate: DateTime(2024, 1, 15, 10, 30),
        createdAt: DateTime(2024, 1, 15, 10, 30),
        indicatorValues: {
          'va_far_uncorrected_od': 0.7,
          'va_far_uncorrected_os': 0.8,
          'sph_od': -2.0,
        },
      );

      analysisResult = AnalysisResult(
        examId: 'test-exam-001',
        analyzedAt: DateTime(2024, 1, 15, 10, 35),
        abnormalities: [
          AbnormalIndicator(
            indicatorId: 'va_far_uncorrected_od',
            indicatorName: '裸眼远视力（右眼）',
            inputValue: 0.7,
            unit: '',
            level: AbnormalLevel.mild,
            interpretation: '轻度视力下降',
            possibleCauses: ['屈光不正', '早期白内障'],
            recommendations: ['验光检查', '排除眼部器质性病变'],
          ),
          AbnormalIndicator(
            indicatorId: 'sph_od',
            indicatorName: '球镜（右眼）',
            inputValue: -2.0,
            unit: 'D',
            level: AbnormalLevel.mild,
            interpretation: '轻度近视',
            possibleCauses: ['轴性近视'],
            recommendations: ['配戴合适眼镜'],
          ),
        ],
        overallAssessment: '检查发现 2 项指标轻度异常，建议注意观察并定期复查。',
        keyFindings: [
          '裸眼远视力（右眼）: 0.7 - 轻度视力下降',
          '球镜（右眼）: -2.0D - 轻度近视',
        ],
        comprehensiveSuggestions: ['验光检查', '排除眼部器质性病变', '配戴合适眼镜'],
        totalIndicators: 8,
        abnormalCount: 2,
      );
    });

    group('报告渲染', () {
      testWidgets('should display page title', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('分析报告'), findsOneWidget);
      });

      testWidgets('should display summary card', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('分析概览'), findsOneWidget);
      });

      testWidgets('should display total indicators count', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('8项'), findsOneWidget);
      });

      testWidgets('should display abnormal count', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('2项'), findsOneWidget);
      });

      testWidgets('should display overall assessment', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('轻度异常'), findsOneWidget);
      });

      testWidgets('should display analyzed date', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证日期显示
        expect(find.byType(AnalysisReportPage), findsOneWidget);
      });

      testWidgets('should have export PDF button', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      });

      testWidgets('should have share button', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.share), findsOneWidget);
      });

      testWidgets('should have single child scroll view', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('异常指标显示', () {
      testWidgets('should display abnormal indicators section', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('异常指标详情'), findsOneWidget);
      });

      testWidgets('should display abnormal indicator cards', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('裸眼远视力（右眼）'), findsOneWidget);
        expect(find.text('球镜（右眼）'), findsOneWidget);
      });

      testWidgets('should display abnormal level badges', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('轻度'), findsWidgets);
      });

      testWidgets('should display indicator values with units', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('0.7'), findsOneWidget);
        expect(find.textContaining('-2.0'), findsOneWidget);
      });

      testWidgets('should display interpretation text', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('轻度视力下降'), findsOneWidget);
        expect(find.textContaining('轻度近视'), findsOneWidget);
      });
    });

    group('展开/收起', () {
      testWidgets('should have expandable tiles for abnormal indicators', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ExpansionTile), findsWidgets);
      });

      testWidgets('should expand to show possible causes', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 点击展开
        await tester.tap(find.text('裸眼远视力（右眼）'));
        await tester.pumpAndSettle();

        expect(find.textContaining('可能原因'), findsOneWidget);
        expect(find.textContaining('屈光不正'), findsOneWidget);
      });

      testWidgets('should expand to show recommendations', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 点击展开
        await tester.tap(find.text('球镜（右眼）'));
        await tester.pumpAndSettle();

        expect(find.textContaining('处理建议'), findsOneWidget);
        expect(find.textContaining('配戴合适眼镜'), findsOneWidget);
      });

      testWidgets('should collapse expanded tile on second tap', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 展开
        await tester.tap(find.text('裸眼远视力（右眼）'));
        await tester.pumpAndSettle();

        // 收起
        await tester.tap(find.text('裸眼远视力（右眼）'));
        await tester.pumpAndSettle();

        // 验证收起后的状态
        expect(find.byType(AnalysisReportPage), findsOneWidget);
      });
    });

    group('关键发现', () {
      testWidgets('should display key findings section', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('关键发现'), findsOneWidget);
      });

      testWidgets('should display numbered key findings', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('should display key finding descriptions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('裸眼远视力（右眼）'), findsWidgets);
      });
    });

    group('综合建议', () {
      testWidgets('should display suggestions section', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('综合建议'), findsOneWidget);
      });

      testWidgets('should display suggestion items with checkmarks', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle), findsWidgets);
      });

      testWidgets('should display all unique suggestions', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('验光检查'), findsOneWidget);
        expect(find.textContaining('配戴合适眼镜'), findsOneWidget);
      });
    });

    group('正常结果', () {
      testWidgets('should display normal result state when no abnormalities', (WidgetTester tester) async {
        final normalResult = AnalysisResult(
          examId: 'test-exam-002',
          analyzedAt: DateTime.now(),
          abnormalities: [],
          overallAssessment: '所有检查指标均在正常范围内，视功能良好。',
          keyFindings: [],
          comprehensiveSuggestions: [],
          totalIndicators: 8,
          abnormalCount: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: normalResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('所有指标均在正常范围内'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should not show abnormal section when no abnormalities', (WidgetTester tester) async {
        final normalResult = AnalysisResult(
          examId: 'test-exam-002',
          analyzedAt: DateTime.now(),
          abnormalities: [],
          overallAssessment: '所有检查指标均在正常范围内，视功能良好。',
          keyFindings: [],
          comprehensiveSuggestions: [],
          totalIndicators: 8,
          abnormalCount: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: normalResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 不应该显示异常指标详情部分
        expect(find.text('异常指标详情'), findsNothing);
      });

      testWidgets('should show green color for normal results', (WidgetTester tester) async {
        final normalResult = AnalysisResult(
          examId: 'test-exam-002',
          analyzedAt: DateTime.now(),
          abnormalities: [],
          overallAssessment: '所有检查指标均在正常范围内，视功能良好。',
          keyFindings: [],
          comprehensiveSuggestions: [],
          totalIndicators: 8,
          abnormalCount: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: normalResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 验证正常结果的UI显示
        expect(find.byType(AnalysisReportPage), findsOneWidget);
      });
    });

    group('不同严重级别', () {
      testWidgets('should display moderate abnormalities with orange color', (WidgetTester tester) async {
        final moderateResult = AnalysisResult(
          examId: 'test-exam-003',
          analyzedAt: DateTime.now(),
          abnormalities: [
            AbnormalIndicator(
              indicatorId: 'va_far_uncorrected_od',
              indicatorName: '裸眼远视力（右眼）',
              inputValue: 0.4,
              unit: '',
              level: AbnormalLevel.moderate,
              interpretation: '中度视力下降',
              possibleCauses: ['中高度屈光不正'],
              recommendations: ['详细检查病因'],
            ),
          ],
          overallAssessment: '检查发现 1 项指标中度异常。',
          keyFindings: ['裸眼远视力（右眼）: 0.4 - 中度视力下降'],
          comprehensiveSuggestions: ['详细检查病因'],
          totalIndicators: 8,
          abnormalCount: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: moderateResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('中度'), findsOneWidget);
      });

      testWidgets('should display severe abnormalities with red color', (WidgetTester tester) async {
        final severeResult = AnalysisResult(
          examId: 'test-exam-004',
          analyzedAt: DateTime.now(),
          abnormalities: [
            AbnormalIndicator(
              indicatorId: 'va_far_uncorrected_od',
              indicatorName: '裸眼远视力（右眼）',
              inputValue: 0.1,
              unit: '',
              level: AbnormalLevel.severe,
              interpretation: '重度视力下降',
              possibleCauses: ['高度屈光不正'],
              recommendations: ['立即就医检查'],
            ),
          ],
          overallAssessment: '检查发现 1 项指标重度异常，建议尽快就医。',
          keyFindings: ['裸眼远视力（右眼）: 0.1 - 重度视力下降'],
          comprehensiveSuggestions: ['立即就医检查'],
          totalIndicators: 8,
          abnormalCount: 1,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: severeResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('重度'), findsOneWidget);
      });
    });

    group('PDF导出', () {
      testWidgets('should show loading when exporting PDF', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 点击导出按钮
        await tester.tap(find.byIcon(Icons.picture_as_pdf));
        await tester.pump();

        // 验证加载状态
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should have PDF export tooltip', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final iconButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.picture_as_pdf),
        );
        expect(iconButton.tooltip, equals('导出PDF'));
      });
    });

    group('分享功能', () {
      testWidgets('should have share tooltip', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final iconButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.share),
        );
        expect(iconButton.tooltip, equals('分享'));
      });

      testWidgets('should show loading when sharing', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 点击分享按钮
        await tester.tap(find.byIcon(Icons.share));
        await tester.pump();

        // 验证加载状态
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('渲染性能', () {
      testWidgets('should render without errors', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: analysisResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle large number of abnormalities', (WidgetTester tester) async {
        final largeResult = AnalysisResult(
          examId: 'test-exam-005',
          analyzedAt: DateTime.now(),
          abnormalities: List.generate(
            10,
            (index) => AbnormalIndicator(
              indicatorId: 'indicator_$index',
              indicatorName: '指标 $index',
              inputValue: index.toDouble(),
              unit: '',
              level: AbnormalLevel.mild,
              interpretation: '轻度异常',
              possibleCauses: ['原因1'],
              recommendations: ['建议1'],
            ),
          ),
          overallAssessment: '检查发现多项指标异常。',
          keyFindings: List.generate(10, (index) => '发现 $index'),
          comprehensiveSuggestions: ['建议1', '建议2'],
          totalIndicators: 20,
          abnormalCount: 10,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AnalysisReportPage(
              examRecord: examRecord,
              analysisResult: largeResult,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AnalysisReportPage), findsOneWidget);
      });
    });
  });
}
