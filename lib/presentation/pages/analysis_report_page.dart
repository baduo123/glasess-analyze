import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import '../../domain/services/analysis_service.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';

class AnalysisReportPage extends StatelessWidget {
  final ExamRecord examRecord;
  final AnalysisResult analysisResult;

  const AnalysisReportPage({
    super.key,
    required this.examRecord,
    required this.analysisResult,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析报告'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 导出PDF
            },
            icon: const Icon(Icons.picture_as_pdf),
          ),
          IconButton(
            onPressed: () {
              // TODO: 分享
            },
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            if (analysisResult.abnormalities.isNotEmpty) ...[
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分析概览',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('检查项目总数', '${analysisResult.totalIndicators}项'),
            _buildStatRow('异常指标数', '${analysisResult.abnormalCount}项'),
            const Divider(height: 24),
            Text(
              analysisResult.overallAssessment,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
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
        const Text(
          '异常指标详情',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analysisResult.abnormalities.map((abnormal) => _buildAbnormalCard(abnormal)),
      ],
    );
  }

  Widget _buildAbnormalCard(AbnormalIndicator abnormal) {
    Color levelColor;
    String levelText;
    
    switch (abnormal.level) {
      case AbnormalLevel.mild:
        levelColor = Colors.yellow.shade700;
        levelText = '轻度';
        break;
      case AbnormalLevel.moderate:
        levelColor = Colors.orange;
        levelText = '中度';
        break;
      case AbnormalLevel.severe:
        levelColor = Colors.red;
        levelText = '重度';
        break;
      default:
        levelColor = Colors.grey;
        levelText = '未知';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ExpansionTile(
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
        subtitle: Text(
          '数值: ${abnormal.inputValue}${abnormal.unit}',
          style: TextStyle(
            color: Colors.grey[600],
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
                  _buildDetailItem('可能原因', abnormal.possibleCauses.join('\n• ')),
                if (abnormal.recommendations.isNotEmpty)
                  _buildDetailItem('处理建议', abnormal.recommendations.join('\n• ')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content.startsWith('•') ? content : '• $content',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[800],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关键发现',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (analysisResult.keyFindings.isEmpty)
              Text(
                '所有指标均在正常范围内',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...analysisResult.keyFindings.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key + 1}. ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '综合建议',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (analysisResult.comprehensiveSuggestions.isEmpty)
              Text(
                '继续保持良好用眼习惯，定期进行视力检查',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...analysisResult.comprehensiveSuggestions.toSet().toList().asMap().entries.map((entry) {
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entry.value),
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
