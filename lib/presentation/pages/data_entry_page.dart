import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../domain/services/analysis_service.dart';
import 'analysis_report_page.dart';

class DataEntryPage extends StatefulWidget {
  final ExamType examType;

  const DataEntryPage({
    super.key,
    required this.examType,
  });

  @override
  State<DataEntryPage> createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  final AnalysisService _analysisService = AnalysisService();
  final Map<String, dynamic> _indicatorValues = {};
  final Map<String, TextEditingController> _controllers = {};
  List<IndicatorStandard> _standards = [];

  @override
  void initState() {
    super.initState();
    _standards = _analysisService.getStandardsForType(widget.examType);
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final standard in _standards) {
      if (standard.type == IndicatorType.numeric) {
        _controllers[standard.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据录入'),
        actions: [
          TextButton.icon(
            onPressed: _saveDraft,
            icon: const Icon(Icons.save_outlined, color: Colors.white),
            label: const Text('保存草稿', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _standards.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _standards.length,
              itemBuilder: (context, index) {
                final standard = _standards[index];
                return _buildIndicatorCard(standard);
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _analyzeData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '开始分析',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(IndicatorStandard standard) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    standard.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (standard.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '必填',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              standard.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            if (standard.type == IndicatorType.numeric)
              TextField(
                controller: _controllers[standard.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: '请输入数值',
                  suffixText: standard.unit,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    final numValue = double.tryParse(value);
                    if (numValue != null) {
                      setState(() {
                        _indicatorValues[standard.id] = numValue;
                      });
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _saveDraft() {
    // TODO: 实现保存草稿逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('草稿已保存')),
    );
  }

  void _analyzeData() {
    if (_indicatorValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少输入一项数据')),
      );
      return;
    }

    final examRecord = ExamRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      examType: widget.examType,
      examDate: DateTime.now(),
      createdAt: DateTime.now(),
      indicatorValues: _indicatorValues,
    );

    final analysisResult = _analysisService.analyze(examRecord);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisReportPage(
          examRecord: examRecord,
          analysisResult: analysisResult,
        ),
      ),
    );
  }
}
