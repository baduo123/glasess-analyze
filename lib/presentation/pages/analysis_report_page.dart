import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/patient.dart';
import '../../domain/services/analysis_service.dart';

class AnalysisReportPage extends StatefulWidget {
  final ExamRecord examRecord;
  final AnalysisResult analysisResult;

  const AnalysisReportPage({
    super.key,
    required this.examRecord,
    required this.analysisResult,
  });

  @override
  State<AnalysisReportPage> createState() => _AnalysisReportPageState();
}

class _AnalysisReportPageState extends State<AnalysisReportPage> {
  bool _isExporting = false;
  bool _isSharing = false;

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);

    try {
      final pdf = await _generatePDF();
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/视功能分析报告_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF导出成功'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () => _shareFile(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<pw.Document> _generatePDF() async {
    final pdf = pw.Document();
    final result = widget.analysisResult;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 标题
              pw.Center(
                child: pw.Text(
                  '视功能分析报告',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // 分析日期
              pw.Text(
                '分析日期: ${DateFormat('yyyy年MM月dd日').format(result.analyzedAt)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // 分析概览
              pw.Text(
                '分析概览',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('检查项目总数: ${result.totalIndicators}项'),
              pw.Text('异常指标数: ${result.abnormalCount}项'),
              pw.SizedBox(height: 10),
              pw.Text(
                result.overallAssessment,
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              
              // 异常指标详情
              if (result.abnormalities.isNotEmpty) ...[
                pw.Text(
                  '异常指标详情',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...result.abnormalities.map((abnormal) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        abnormal.indicatorName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('数值: ${abnormal.inputValue}${abnormal.unit}'),
                      pw.Text('级别: ${_getLevelText(abnormal.level)}'),
                      pw.Text('解读: ${abnormal.interpretation}'),
                      if (abnormal.possibleCauses.isNotEmpty)
                        pw.Text('可能原因: ${abnormal.possibleCauses.join(", ")}'),
                      if (abnormal.recommendations.isNotEmpty)
                        pw.Text('建议: ${abnormal.recommendations.join(", ")}'),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }),
                pw.SizedBox(height: 10),
              ],
              
              // 关键发现
              pw.Text(
                '关键发现',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (result.keyFindings.isEmpty)
                pw.Text('所有指标均在正常范围内')
              else
                ...result.keyFindings.asMap().entries.map((entry) {
                  return pw.Text('${entry.key + 1}. ${entry.value}');
                }),
              pw.SizedBox(height: 20),
              
              // 综合建议
              pw.Text(
                '综合建议',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (result.comprehensiveSuggestions.isEmpty)
                pw.Text('继续保持良好用眼习惯，定期进行视力检查')
              else
                ...result.comprehensiveSuggestions.toSet().toList().map((suggestion) {
                  return pw.Text('• $suggestion');
                }),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  String _getLevelText(AbnormalLevel level) {
    switch (level) {
      case AbnormalLevel.mild:
        return '轻度';
      case AbnormalLevel.moderate:
        return '中度';
      case AbnormalLevel.severe:
        return '重度';
      default:
        return '未知';
    }
  }

  Future<void> _shareReport() async {
    setState(() => _isSharing = true);

    try {
      // 生成分享文本
      final buffer = StringBuffer();
      buffer.writeln('【视功能分析报告】');
      buffer.writeln('分析日期: ${DateFormat('yyyy年MM月dd日').format(widget.analysisResult.analyzedAt)}');
      buffer.writeln('');
      buffer.writeln(widget.analysisResult.overallAssessment);
      buffer.writeln('');
      
      if (widget.analysisResult.keyFindings.isNotEmpty) {
        buffer.writeln('【关键发现】');
        for (var i = 0; i < widget.analysisResult.keyFindings.length; i++) {
          buffer.writeln('${i + 1}. ${widget.analysisResult.keyFindings[i]}');
        }
        buffer.writeln('');
      }
      
      if (widget.analysisResult.comprehensiveSuggestions.isNotEmpty) {
        buffer.writeln('【建议】');
        final suggestions = widget.analysisResult.comprehensiveSuggestions.toSet().toList();
        for (var suggestion in suggestions) {
          buffer.writeln('• $suggestion');
        }
      }

      await Share.share(
        buffer.toString(),
        subject: '视功能分析报告',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Future<void> _shareFile(String filePath) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '视功能分析报告',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析报告'),
        actions: [
          if (_isExporting || _isSharing)
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
          else ...[
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            if (widget.analysisResult.abnormalities.isNotEmpty) ...[
              _buildAbnormalIndicatorsSection(),
              const SizedBox(height: 16),
            ],
            _buildKeyFindingsSection(),
            const SizedBox(height: 16),
            _buildSuggestionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final result = widget.analysisResult;
    final hasAbnormalities = result.abnormalCount > 0;
    
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: hasAbnormalities
                ? [Colors.orange[50]!, Colors.white]
                : [Colors.green[50]!, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasAbnormalities ? Colors.orange[100] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      hasAbnormalities ? Icons.warning_amber : Icons.check_circle,
                      color: hasAbnormalities ? Colors.orange[700] : Colors.green[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '分析概览',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy年MM月dd日 HH:mm').format(result.analyzedAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildStatRow('检查项目总数', '${result.totalIndicators}项', Icons.format_list_numbered),
              _buildStatRow('异常指标数', '${result.abnormalCount}项', Icons.error_outline, 
                valueColor: hasAbnormalities ? Colors.orange[700] : Colors.green[700]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  result.overallAssessment,
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

  Widget _buildStatRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbnormalIndicatorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text(
              '异常指标详情',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.analysisResult.abnormalities.map((abnormal) => _buildAbnormalCard(abnormal)),
      ],
    );
  }

  Widget _buildAbnormalCard(AbnormalIndicator abnormal) {
    Color levelColor;
    String levelText;
    IconData levelIcon;
    
    switch (abnormal.level) {
      case AbnormalLevel.mild:
        levelColor = Colors.yellow.shade700;
        levelText = '轻度';
        levelIcon = Icons.info_outline;
        break;
      case AbnormalLevel.moderate:
        levelColor = Colors.orange;
        levelText = '中度';
        levelIcon = Icons.warning_amber;
        break;
      case AbnormalLevel.severe:
        levelColor = Colors.red;
        levelText = '重度';
        levelIcon = Icons.error_outline;
        break;
      default:
        levelColor = Colors.grey;
        levelText = '未知';
        levelIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: levelColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(levelIcon, color: levelColor, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                abnormal.indicatorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                levelText,
                style: TextStyle(
                  color: levelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            '数值: ${abnormal.inputValue}${abnormal.unit}',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem('医学解读', abnormal.interpretation),
                if (abnormal.possibleCauses.isNotEmpty)
                  _buildDetailItem('可能原因', '• ${abnormal.possibleCauses.join('\n• ')}'),
                if (abnormal.recommendations.isNotEmpty)
                  _buildDetailItem('处理建议', '• ${abnormal.recommendations.join('\n• ')}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFindingsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
            const SizedBox(height: 16),
            if (widget.analysisResult.keyFindings.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '所有指标均在正常范围内',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...widget.analysisResult.keyFindings.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
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
                            fontSize: 15,
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

  Widget _buildSuggestionsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.green[700]),
                const SizedBox(width: 8),
                const Text(
                  '综合建议',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.analysisResult.comprehensiveSuggestions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '继续保持良好用眼习惯，定期进行视力检查',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...widget.analysisResult.comprehensiveSuggestions.toSet().toList().asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
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
                            fontSize: 15,
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
}
