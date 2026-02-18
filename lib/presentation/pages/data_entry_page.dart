import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../domain/services/analysis_service.dart';
import 'analysis_report_page.dart';
import 'camera_scan_page.dart';

class DataEntryPage extends StatefulWidget {
  final ExamType examType;
  final String? patientId;
  final Map<String, dynamic>? prefilledData;

  const DataEntryPage({
    super.key,
    required this.examType,
    this.patientId,
    this.prefilledData,
  });

  @override
  State<DataEntryPage> createState() => _DataEntryPageState();
}

class _DataEntryPageState extends State<DataEntryPage> {
  final AnalysisService _analysisService = AnalysisService();
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _indicatorValues = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _errorMessages = {};
  List<IndicatorStandard> _standards = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _standards = _analysisService.getStandardsForType(widget.examType);
    _initializeControllers();
    _applyPrefilledData();
  }

  void _initializeControllers() {
    for (final standard in _standards) {
      if (standard.type == IndicatorType.numeric) {
        _controllers[standard.id] = TextEditingController();
        _errorMessages[standard.id] = null;
      }
    }
  }

  void _applyPrefilledData() {
    if (widget.prefilledData != null) {
      widget.prefilledData!.forEach((key, value) {
        final standard = _standards.firstWhere(
          (s) => s.name.contains(key) || s.id == key,
          orElse: () => IndicatorStandard(
            id: key,
            name: key,
            description: '',
            unit: '',
            type: IndicatorType.numeric,
            isRequired: false,
            ranges: [],
          ),
        );
        if (_controllers.containsKey(standard.id) && value != null) {
          _controllers[standard.id]!.text = value.toString();
          final numValue = double.tryParse(value.toString());
          if (numValue != null) {
            _indicatorValues[standard.id] = numValue;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _validateField(String standardId, String value, IndicatorStandard standard) {
    String? error;
    
    if (value.isEmpty) {
      if (standard.isRequired) {
        error = '${standard.name}为必填项';
      }
    } else {
      final numValue = double.tryParse(value);
      if (numValue == null) {
        error = '请输入有效的数值';
      } else if (standard.minValue != null && numValue < standard.minValue!) {
        error = '数值不能小于 ${standard.minValue}';
      } else if (standard.maxValue != null && numValue > standard.maxValue!) {
        error = '数值不能大于 ${standard.maxValue}';
      }
      
      if (error == null) {
        _indicatorValues[standardId] = numValue;
      }
    }
    
    setState(() {
      _errorMessages[standardId] = error;
    });
  }

  Future<void> _importFromOCR() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScanPage(),
      ),
    );

    if (result != null && result.containsKey('extractedData')) {
      final extractedData = result['extractedData'] as Map<String, dynamic>;
      _applyOCRData(extractedData);
    }
  }

  void _applyOCRData(Map<String, dynamic> extractedData) {
    int importedCount = 0;
    
    extractedData.forEach((key, value) {
      // 尝试匹配指标名称
      for (final standard in _standards) {
        if (standard.name.contains(key) || key.contains(standard.name)) {
          if (_controllers.containsKey(standard.id) && value != null) {
            final numValue = double.tryParse(value.toString());
            if (numValue != null) {
              _controllers[standard.id]!.text = value.toString();
              _indicatorValues[standard.id] = numValue;
              importedCount++;
              break;
            }
          }
        }
      }
    });

    if (importedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $importedCount 项数据')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('未能识别到匹配的检查数据，请手动输入'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
      body: Form(
        key: _formKey,
        child: _standards.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _standards.length + 1, // +1 for OCR import button
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildOCRImportCard();
                  }
                  final standard = _standards[index - 1];
                  return _buildIndicatorCard(standard);
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _analyzeData,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    '开始分析',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildOCRImportCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: Colors.blue[50],
      child: InkWell(
        onTap: _importFromOCR,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.blue[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '从OCR导入',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '拍照识别检查单，自动填充数据',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.blue[700],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorCard(IndicatorStandard standard) {
    final hasError = _errorMessages[standard.id] != null;
    
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
            if (standard.normalRanges.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '参考范围: ${_getReferenceRangeText(standard)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (standard.type == IndicatorType.numeric)
              TextFormField(
                controller: _controllers[standard.id],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: standard.minValue != null && standard.maxValue != null
                      ? '${standard.minValue} - ${standard.maxValue}'
                      : '请输入数值',
                  suffixText: standard.unit.isNotEmpty ? standard.unit : null,
                  suffixStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  errorText: _errorMessages[standard.id],
                  prefixIcon: standard.unit.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            standard.unit,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : null,
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : Colors.grey[300]!,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: hasError ? Colors.red : Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  helperText: standard.minValue != null || standard.maxValue != null
                      ? '有效范围: ${standard.minValue ?? "无下限"} - ${standard.maxValue ?? "无上限"}'
                      : null,
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                onChanged: (value) => _validateField(standard.id, value, standard),
                validator: (value) {
                  if (standard.isRequired && (value == null || value.isEmpty)) {
                    return '${standard.name}不能为空';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getReferenceRangeText(IndicatorStandard standard) {
    if (standard.normalRanges.isEmpty) return '';

    final range = standard.normalRanges.first;
    if (range.minValue != null && range.maxValue != null) {
      return '${range.minValue} - ${range.maxValue} ${standard.unit}';
    } else if (range.minValue != null) {
      return '≥ ${range.minValue} ${standard.unit}';
    } else if (range.maxValue != null) {
      return '≤ ${range.maxValue} ${standard.unit}';
    }
    return '';
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
        const SnackBar(
          content: Text('请至少输入一项数据'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 验证必填项
    bool hasMissingRequired = false;
    for (final standard in _standards) {
      if (standard.isRequired && !_indicatorValues.containsKey(standard.id)) {
        hasMissingRequired = true;
        setState(() {
          _errorMessages[standard.id] = '此项为必填';
        });
      }
    }

    if (hasMissingRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写所有必填项'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final examRecord = ExamRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      patientId: widget.patientId,
      examType: widget.examType,
      examDate: DateTime.now(),
      createdAt: DateTime.now(),
      indicatorValues: _indicatorValues,
    );

    final analysisResult = _analysisService.analyze(examRecord);

    setState(() => _isLoading = false);

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
