import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/patient.dart';
import '../../domain/services/ai_report_service.dart';
import '../../domain/services/pdf_service.dart';
import '../../data/repositories/patient_repository.dart';
import '../widgets/loading_overlay.dart';

/// 综合报告展示页面
/// 展示AI生成的结构化视功能分析报告
class ComprehensiveReportPage extends StatefulWidget {
  final Patient patient;
  final List<ExamDataItem> examItems;

  const ComprehensiveReportPage({
    super.key,
    required this.patient,
    required this.examItems,
  });

  @override
  State<ComprehensiveReportPage> createState() => _ComprehensiveReportPageState();
}

class _ComprehensiveReportPageState extends State<ComprehensiveReportPage> {
  final AIReportService _aiService = AIReportService();
  final PDFService _pdfService = PDFService();
  
  AIAnalysisResult? _result;
  bool _isLoading = true;
  String? _error;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await _aiService.generateComprehensiveReport(
        widget.patient,
        widget.examItems,
      );

      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPDF() async {
    if (_result == null) return;

    setState(() => _isExporting = true);

    try {
      // 构建分析结果数据
      final analysisResults = _buildAnalysisResultsData();

      // 创建临时检查记录
      final examRecord = ExamRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        patientId: widget.patient.id,
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: _getAllIndicatorValues(),
      );

      // 生成PDF
      final filePath = await _pdfService.exportToPDF(
        patient: widget.patient,
        examRecord: examRecord,
        analysisResults: analysisResults,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF导出成功'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Map<String, dynamic> _buildAnalysisResultsData() {
    if (_result == null) return {};

    final indicators = <Map<String, dynamic>>[];
    
    // 添加所有指标
    for (final exam in widget.examItems) {
      exam.indicatorValues.forEach((key, value) {
        // 检查是否为异常指标
        final abnormal = _result!.abnormalIndicators
            .firstWhere((a) => a.name == key, 
                orElse: () => AbnormalIndicatorAI(
                  name: key, 
                  value: value.toString(), 
                  status: '正常', 
                  interpretation: ''
                ));
        
        indicators.add({
          'name': key,
          'value': value,
          'unit': '',
          'reference': abnormal.status,
          'status': abnormal.status == '正常' ? 'normal' : 'abnormal',
        });
      });
    }

    return {
      'indicators': indicators,
      'conclusions': _result!.keyFindings,
      'recommendations': _result!.recommendations,
    };
  }

  Map<String, dynamic> _getAllIndicatorValues() {
    final values = <String, dynamic>{};
    for (final exam in widget.examItems) {
      values.addAll(exam.indicatorValues);
    }
    return values;
  }

  Future<void> _shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '${widget.patient.name} - 视功能综合报告',
    );
  }

  Future<void> _shareReport() async {
    if (_result == null) return;

    final buffer = StringBuffer();
    buffer.writeln('【视功能综合报告】');
    buffer.writeln('患者：${widget.patient.name}');
    buffer.writeln('年龄：${widget.patient.age}岁');
    buffer.writeln('性别：${widget.patient.gender}');
    buffer.writeln('生成时间：${DateFormat('yyyy年MM月dd日').format(_result!.generatedAt)}');
    buffer.writeln('');
    buffer.writeln('【总体评估】');
    buffer.writeln(_result!.overallAssessment);
    buffer.writeln('');
    
    if (_result!.keyFindings.isNotEmpty) {
      buffer.writeln('【关键发现】');
      for (var i = 0; i < _result!.keyFindings.length; i++) {
        buffer.writeln('${i + 1}. ${_result!.keyFindings[i]}');
      }
      buffer.writeln('');
    }
    
    if (_result!.abnormalIndicators.isNotEmpty) {
      buffer.writeln('【异常指标】');
      for (final abnormal in _result!.abnormalIndicators) {
        buffer.writeln('• ${abnormal.name}: ${abnormal.value} (${abnormal.status})');
        buffer.writeln('  ${abnormal.interpretation}');
      }
      buffer.writeln('');
    }
    
    if (_result!.recommendations.isNotEmpty) {
      buffer.writeln('【建议】');
      for (final suggestion in _result!.recommendations) {
        buffer.writeln('• $suggestion');
      }
    }

    await Share.share(
      buffer.toString(),
      subject: '${widget.patient.name} - 视功能综合报告',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI综合报告'),
        actions: [
          if (_isExporting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else if (_result != null) ...[
            IconButton(
              onPressed: _exportPDF,
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: '导出PDF',
            ),
            IconButton(
              onPressed: _shareReport,
              icon: const Icon(Icons.share),
              tooltip: '分享',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI正在生成报告...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              '生成报告失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return const Center(child: Text('无法生成报告'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPatientInfoCard(),
          const SizedBox(height: 16),
          _buildOverallAssessmentCard(),
          const SizedBox(height: 16),
          _buildKeyFindingsCard(),
          const SizedBox(height: 16),
          _buildAgeAnalysisCard(),
          const SizedBox(height: 16),
          if (_result!.abnormalIndicators.isNotEmpty) ...[
            _buildAbnormalIndicatorsCard(),
            const SizedBox(height: 16),
          ],
          _buildRiskAssessmentCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
          _buildFollowUpCard(),
          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patient.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.patient.age}岁 · ${widget.patient.gender}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _buildInfoItem('检查项目', '${widget.examItems.length}项'),
                  _buildInfoItem('生成时间', 
                    DateFormat('MM/dd HH:mm').format(_result!.generatedAt)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAssessmentCard() {
    final hasAbnormal = _result!.abnormalIndicators.isNotEmpty;
    
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAbnormal ? Colors.orange[200]! : Colors.green[200]!,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasAbnormal ? Icons.assessment : Icons.check_circle,
                    color: hasAbnormal ? Colors.orange[700] : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '总体评估',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: hasAbnormal ? Colors.orange[700] : Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasAbnormal ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _result!.overallAssessment,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyFindingsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  '关键发现',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._result!.keyFindings.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeAnalysisCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.purple[700]),
                const SizedBox(width: 8),
                const Text(
                  '年龄相关分析',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result!.ageSpecificAnalysis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbnormalIndicatorsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red[700]),
                const SizedBox(width: 8),
                const Text(
                  '异常指标',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_result!.abnormalIndicators.length}项',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  children: [
                    _buildTableHeader('指标名称'),
                    _buildTableHeader('数值'),
                    _buildTableHeader('状态'),
                  ],
                ),
                ..._result!.abnormalIndicators.map((indicator) {
                  return TableRow(
                    children: [
                      _buildTableCell(indicator.name, isBold: true),
                      _buildTableCell(indicator.value),
                      _buildStatusCell(indicator.status),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            ..._result!.abnormalIndicators.map((indicator) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indicator.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      indicator.interpretation,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color color;
    if (status.contains('正常')) {
      color = Colors.green;
    } else if (status.contains('轻度') || status.contains('偏低') || status.contains('偏高')) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRiskAssessmentCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.teal[700]),
                const SizedBox(width: 8),
                const Text(
                  '风险评估',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result!.riskAssessment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  '专业建议',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._result!.recommendations.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                const Text(
                  '随访计划',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _result!.followUpPlan,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportPDF,
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: const Text('导出PDF'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareReport,
            icon: const Icon(Icons.share),
            label: const Text('分享报告'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
