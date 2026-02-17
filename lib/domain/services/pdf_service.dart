import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../../data/models/patient.dart';

/// PDF导出服务类
/// 用于生成视功能分析报告PDF
class PDFService {
  static final PDFService _instance = PDFService._internal();
  factory PDFService() => _instance;
  PDFService._internal();

  // PDF文档主题色
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF2196F3);
  static const PdfColor _secondaryColor = PdfColor.fromInt(0xFF757575);
  static const PdfColor _successColor = PdfColor.fromInt(0xFF4CAF50);
  static const PdfColor _warningColor = PdfColor.fromInt(0xFFFF9800);
  static const PdfColor _dangerColor = PdfColor.fromInt(0xFFF44336);

  /// 导出检查报告为PDF
  /// 
  /// [patient] - 患者信息
  /// [examRecord] - 检查记录
  /// [analysisResults] - 分析结果数据
  /// [outputPath] - 可选的输出路径，不提供则保存到应用文档目录
  Future<String> exportToPDF({
    required Patient patient,
    required ExamRecord examRecord,
    required Map<String, dynamic> analysisResults,
    String? outputPath,
  }) async {
    try {
      developer.log('开始生成PDF报告: ${patient.name}');
      
      // 创建PDF文档
      final pdf = pw.Document();

      // 添加报告页面
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader(context),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildReportTitle(),
            pw.SizedBox(height: 20),
            _buildPatientInfo(patient, examRecord),
            pw.SizedBox(height: 20),
            _buildExamInfo(examRecord),
            pw.SizedBox(height: 20),
            _buildAnalysisResults(analysisResults),
            pw.SizedBox(height: 20),
            _buildConclusions(analysisResults),
            pw.SizedBox(height: 20),
            _buildRecommendations(analysisResults),
            pw.SizedBox(height: 30),
            _buildSignatureSection(),
          ],
        ),
      );

      // 生成PDF字节
      final bytes = await pdf.save();

      // 确定保存路径
      String filePath;
      if (outputPath != null) {
        filePath = outputPath;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'report_${patient.name}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
        filePath = '${directory.path}/reports/$fileName';
      }

      // 确保目录存在
      final file = File(filePath);
      await file.parent.create(recursive: true);

      // 写入文件
      await file.writeAsBytes(bytes);

      developer.log('PDF报告生成成功: $filePath');
      return filePath;
    } catch (e, stackTrace) {
      developer.log('PDF生成失败', error: e, stackTrace: stackTrace);
      throw Exception('PDF生成失败: $e');
    }
  }

  /// 构建页眉
  pw.Widget _buildHeader(pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '视功能分析报告',
            style: pw.TextStyle(
              fontSize: 14,
              color: _primaryColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Vision Analyzer Pro',
            style: pw.TextStyle(
              fontSize: 10,
              color: _secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建页脚
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _secondaryColor, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            '本报告仅供参考，不作为医疗诊断依据',
            style: pw.TextStyle(
              fontSize: 8,
              color: _secondaryColor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
          pw.Text(
            '第 ${context.pageNumber} 页 / 共 ${context.pagesCount} 页',
            style: pw.TextStyle(
              fontSize: 8,
              color: _secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建报告标题
  pw.Widget _buildReportTitle() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            '视功能分析报告',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Vision Function Analysis Report',
            style: pw.TextStyle(
              fontSize: 12,
              color: _secondaryColor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建患者信息部分
  pw.Widget _buildPatientInfo(Patient patient, ExamRecord examRecord) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF5F5F5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '患者信息',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              _buildInfoRow('姓名', patient.name, '性别', patient.gender),
              _buildInfoRow('年龄', '${patient.age}岁', '电话', patient.phone ?? '未提供'),
            ],
          ),
          if (patient.note != null && patient.note!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              '备注: ${patient.note}',
              style: pw.TextStyle(
                fontSize: 10,
                color: _secondaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建信息行
  pw.TableRow _buildInfoRow(String label1, String value1, String label2, String value2) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            label1,
            style: pw.TextStyle(
              fontSize: 10,
              color: _secondaryColor,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            value1,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            label2,
            style: pw.TextStyle(
              fontSize: 10,
              color: _secondaryColor,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Text(
            value2,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建检查信息部分
  pw.Widget _buildExamInfo(ExamRecord examRecord) {
    final dateFormat = DateFormat('yyyy年MM月dd日 HH:mm');
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _primaryColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '检查信息',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildExamInfoItem('检查类型', _getExamTypeName(examRecord.examType)),
              ),
              pw.Expanded(
                child: _buildExamInfoItem('检查日期', dateFormat.format(examRecord.examDate)),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildExamInfoItem('报告编号', examRecord.id.substring(0, 8).toUpperCase()),
              ),
              pw.Expanded(
                child: _buildExamInfoItem('生成时间', dateFormat.format(DateTime.now())),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建检查信息项
  pw.Widget _buildExamInfoItem(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            color: _secondaryColor,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 获取检查类型名称
  String _getExamTypeName(ExamType type) {
    switch (type) {
      case ExamType.standardFullSet:
        return '全套视功能检查';
      case ExamType.binocularVision:
        return '双眼视功能检查';
      case ExamType.amblyopiaScreening:
        return '弱视筛查';
      case ExamType.asthenopiaAssessment:
        return '视疲劳评估';
      case ExamType.custom:
        return '自定义检查';
      default:
        return '未知类型';
    }
  }

  /// 构建分析结果部分
  pw.Widget _buildAnalysisResults(Map<String, dynamic> analysisResults) {
    final indicators = analysisResults['indicators'] as List<dynamic>? ?? [];
    
    if (indicators.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '检测指标',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE0E0E0)),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // 表头
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _primaryColor),
              children: [
                _buildTableHeaderCell('指标名称'),
                _buildTableHeaderCell('测量值'),
                _buildTableHeaderCell('参考范围'),
                _buildTableHeaderCell('状态'),
              ],
            ),
            // 数据行
            ...indicators.map((indicator) {
              final status = indicator['status'] as String? ?? 'normal';
              return pw.TableRow(
                children: [
                  _buildTableCell(indicator['name'] ?? '-'),
                  _buildTableCell('${indicator['value'] ?? '-'} ${indicator['unit'] ?? ''}'),
                  _buildTableCell(indicator['reference'] ?? '-'),
                  _buildStatusCell(status),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  /// 构建表格表头单元格
  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFFFFFFFF),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 构建表格单元格
  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 构建状态单元格
  pw.Widget _buildStatusCell(String status) {
    PdfColor color;
    String text;
    
    switch (status) {
      case 'normal':
        color = _successColor;
        text = '正常';
        break;
      case 'warning':
        color = _warningColor;
        text = '警告';
        break;
      case 'abnormal':
        color = _dangerColor;
        text = '异常';
        break;
      default:
        color = _secondaryColor;
        text = status;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// 构建结论部分
  pw.Widget _buildConclusions(Map<String, dynamic> analysisResults) {
    final conclusions = analysisResults['conclusions'] as List<dynamic>? ?? [];
    
    if (conclusions.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '分析结论',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF5F5F5),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: conclusions.asMap().entries.map((entry) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${entry.key + 1}. ',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        entry.value.toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建建议部分
  pw.Widget _buildRecommendations(Map<String, dynamic> analysisResults) {
    final recommendations = analysisResults['recommendations'] as List<dynamic>? ?? [];
    
    if (recommendations.isEmpty) {
      return pw.Container();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '专业建议',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _primaryColor, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: recommendations.asMap().entries.map((entry) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 6,
                      height: 6,
                      margin: const pw.EdgeInsets.only(top: 4, right: 8),
                      decoration: pw.BoxDecoration(
                        color: _primaryColor,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        entry.value.toString(),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// 构建签名部分
  pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              '检查医师: _________________',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 15),
            pw.Text(
              '签字日期: _________________',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  /// 分享PDF文件
  Future<void> sharePDF(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('PDF文件不存在');
      }
      
      // 这里可以集成share_plus插件实现分享功能
      developer.log('准备分享PDF: $filePath');
    } catch (e) {
      throw Exception('分享PDF失败: $e');
    }
  }

  /// 获取所有已生成的报告列表
  Future<List<File>> getAllReports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${directory.path}/reports');
      
      if (!await reportsDir.exists()) {
        return [];
      }

      final files = await reportsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.pdf'))
          .map((entity) => entity as File)
          .toList();

      // 按修改时间排序（最新的在前）
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      throw Exception('获取报告列表失败: $e');
    }
  }

  /// 删除PDF报告
  Future<void> deleteReport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        developer.log('PDF报告已删除: $filePath');
      }
    } catch (e) {
      throw Exception('删除报告失败: $e');
    }
  }
}
