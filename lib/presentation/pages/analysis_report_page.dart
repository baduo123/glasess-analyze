import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/patient.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/services/analysis_service.dart';
import '../../domain/services/pdf_service.dart';
import 'patient_list_page.dart';
import 'patient_detail_page.dart';

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
  bool _isSavingToPatient = false;

  final PDFService _pdfService = PDFService();
  final PatientRepository _patientRepository = PatientRepository();
  final ExamRepository _examRepository = ExamRepository();

  Future<void> _exportPDF() async {
    setState(() => _isExporting = true);

    try {
      // 如果有患者ID，获取患者信息生成更完整的PDF
      Patient? patient;
      if (widget.examRecord.patientId != null) {
        patient = await _patientRepository.getPatientById(widget.examRecord.patientId!);
      }

      // 构建分析结果数据
      final analysisResults = _buildAnalysisResultsData();

      // 使用PDFService生成PDF
      final filePath = await _pdfService.exportToPDF(
        patient: patient ?? _createTempPatient(),
        examRecord: widget.examRecord,
        analysisResults: analysisResults,
      );

      // 更新检查记录，保存PDF路径
      if (widget.examRecord.patientId != null) {
        await _examRepository.updateExam(
          widget.examRecord.id,
          pdfPath: filePath,
        );
      }

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
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Map<String, dynamic> _buildAnalysisResultsData() {
    final result = widget.analysisResult;

    // 构建指标列表
    final indicators = <Map<String, dynamic>>[];
    for (final abnormal in result.abnormalities) {
      indicators.add({
        'name': abnormal.indicatorName,
        'value': abnormal.inputValue,
        'unit': abnormal.unit,
        'reference': _getReferenceRange(abnormal),
        'status': _getStatusFromLevel(abnormal.level),
      });
    }

    // 添加正常指标
    final abnormalIds = result.abnormalities.map((a) => a.indicatorId).toSet();
    for (final entry in widget.examRecord.indicatorValues?.entries ?? []) {
      if (!abnormalIds.contains(entry.key)) {
        indicators.add({
          'name': entry.key,
          'value': entry.value,
          'unit': '',
          'reference': '正常范围',
          'status': 'normal',
        });
      }
    }

    return {
      'indicators': indicators,
      'conclusions': result.keyFindings,
      'recommendations': result.comprehensiveSuggestions.toList(),
    };
  }

  String _getReferenceRange(AbnormalIndicator abnormal) {
    // 简化处理，实际应该从标准配置中获取
    return '参考范围';
  }

  String _getStatusFromLevel(AbnormalLevel level) {
    switch (level) {
      case AbnormalLevel.mild:
        return 'warning';
      case AbnormalLevel.moderate:
      case AbnormalLevel.severe:
        return 'abnormal';
      default:
        return 'normal';
    }
  }

  Patient _createTempPatient() {
    return Patient(
      id: 'temp',
      name: '临时患者',
      age: 0,
      gender: '未知',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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

  Future<void> _saveToPatient() async {
    if (widget.examRecord.patientId != null) {
      // 已经有患者关联
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('此检查已关联到患者')),
      );
      return;
    }

    setState(() => _isSavingToPatient = true);

    try {
      // 显示患者选择对话框
      final selectedPatient = await _showPatientSelectionDialog();

      if (selectedPatient != null) {
        // 更新检查记录的患者ID
        await _examRepository.updateExam(
          widget.examRecord.id,
          patientId: selectedPatient.id,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已保存到患者: ${selectedPatient.name}'),
              action: SnackBarAction(
                label: '查看',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDetailPage(patient: selectedPatient),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSavingToPatient = false);
    }
  }

  Future<Patient?> _showPatientSelectionDialog() async {
    return showDialog<Patient>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择患者'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<Patient>>(
            future: _patientRepository.getAllPatients(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('加载失败: ${snapshot.error}'));
              }

              final patients = snapshot.data ?? [];

              if (patients.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('暂无患者'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToCreatePatient();
                        },
                        child: const Text('创建患者'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(patient.name[0]),
                    ),
                    title: Text(patient.name),
                    subtitle: Text('${patient.age}岁 · ${patient.gender}'),
                    onTap: () => Navigator.pop(context, patient),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToCreatePatient();
            },
            child: const Text('创建新患者'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreatePatient() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientListPage(),
      ),
    );
  }

  Future<void> _printReport() async {
    try {
      // 使用printing插件打印报告
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('准备打印...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打印失败: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析报告'),
        actions: [
          if (_isExporting || _isSharing || _isSavingToPatient)
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
            if (widget.examRecord.patientId == null)
              IconButton(
                onPressed: _saveToPatient,
                icon: const Icon(Icons.save_alt),
                tooltip: '保存到患者',
              ),
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
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'save_to_patient':
                    _saveToPatient();
                    break;
                  case 'print':
                    _printReport();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (widget.examRecord.patientId == null)
                  const PopupMenuItem(
                    value: 'save_to_patient',
                    child: Row(
                      children: [
                        Icon(Icons.person_add),
                        SizedBox(width: 8),
                        Text('保存到患者'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('打印'),
                    ],
                  ),
                ),
              ],
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
            if (widget.examRecord.patientId == null) ...[
              _buildSaveToPatientCard(),
              const SizedBox(height: 16),
            ],
            if (widget.analysisResult.abnormalities.isNotEmpty) ...[
              _buildAbnormalIndicatorsSection(),
              const SizedBox(height: 16),
            ],
            _buildKeyFindingsSection(),
            const SizedBox(height: 16),
            _buildSuggestionsSection(),
            const SizedBox(height: 32),
            _buildBottomActionButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveToPatientCard() {
    return Card(
      elevation: 1,
      color: Colors.blue[50],
      child: InkWell(
        onTap: _isSavingToPatient ? null : _saveToPatient,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _isSavingToPatient
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue[700],
                        ),
                      )
                    : Icon(Icons.person_add, color: Colors.blue[700]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '保存到患者',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '将此检查报告关联到患者档案',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.blue[700]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionButtons() {
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
            onPressed: _isSharing ? null : _shareReport,
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.share),
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
