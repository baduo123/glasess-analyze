import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/patient.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../domain/services/analysis_service.dart';
import '../../domain/services/ai_report_service.dart';
import 'comprehensive_report_page.dart';
import 'camera_scan_page.dart';


/// 多项检查录入页面
/// 支持选择1-4项检查并分步录入
class MultiExamEntryPage extends StatefulWidget {
  final String? patientId;

  const MultiExamEntryPage({
    super.key,
    this.patientId,
  });

  @override
  State<MultiExamEntryPage> createState() => _MultiExamEntryPageState();
}

class _MultiExamEntryPageState extends State<MultiExamEntryPage> {
  final AnalysisService _analysisService = AnalysisService();
  
  // 步骤控制
  int _currentStep = 0;
  
  // 选中的检查类型（最多4个）
  final List<ExamType> _selectedExamTypes = [];
  
  // 每步的检查数据
  final Map<int, Map<String, dynamic>> _stepData = {};
  final Map<int, Map<String, TextEditingController>> _stepControllers = {};
  final Map<int, Map<String, String?>> _stepErrors = {};
  
  bool _isLoading = false;
  Patient? _patient;

  // 可用的检查类型列表
  final List<Map<String, dynamic>> _availableExamTypes = [
    {
      'type': ExamType.standardFullSet,
      'name': '全套视功能检查',
      'icon': Icons.visibility,
      'color': Colors.blue,
      'description': '包含视力、眼压、屈光等全面检查',
    },
    {
      'type': ExamType.binocularVision,
      'name': '双眼视功能检查',
      'icon': Icons.remove_red_eye,
      'color': Colors.purple,
      'description': '评估双眼协调和融合功能',
    },
    {
      'type': ExamType.amblyopiaScreening,
      'name': '弱视筛查',
      'icon': Icons.child_care,
      'color': Colors.orange,
      'description': '儿童弱视早期筛查',
    },
    {
      'type': ExamType.asthenopiaAssessment,
      'name': '视疲劳评估',
      'icon': Icons.bedtime,
      'color': Colors.teal,
      'description': '评估用眼疲劳程度',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    if (widget.patientId != null) {
      // 加载患者信息
      // 实际项目中应该从Repository加载
      setState(() {
        _patient = Patient(
          id: widget.patientId!,
          name: '患者',
          age: 30,
          gender: '男',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    }
  }

  @override
  void dispose() {
    // 释放所有controller
    for (final controllers in _stepControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _initializeStepControllers(int step) {
    if (_stepControllers.containsKey(step)) return;

    final examType = _selectedExamTypes[step];
    final standards = _analysisService.getStandardsForType(examType);
    
    final controllers = <String, TextEditingController>{};
    final errors = <String, String?>{};
    
    for (final standard in standards) {
      if (standard.type == IndicatorType.numeric) {
        controllers[standard.id] = TextEditingController();
        errors[standard.id] = null;
      }
    }
    
    _stepControllers[step] = controllers;
    _stepErrors[step] = errors;
    _stepData[step] = {};
  }

  void _validateField(int step, String standardId, String value, IndicatorStandard standard) {
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
        _stepData[step]![standardId] = numValue;
      }
    }
    
    setState(() {
      _stepErrors[step]![standardId] = error;
    });
  }

  Future<void> _importFromOCR(int step) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScanPage(),
      ),
    );

    if (result != null && result.containsKey('extractedData')) {
      final extractedData = result['extractedData'] as Map<String, dynamic>;
      _applyOCRData(step, extractedData);
    }
  }

  void _applyOCRData(int step, Map<String, dynamic> extractedData) {
    final examType = _selectedExamTypes[step];
    final standards = _analysisService.getStandardsForType(examType);
    int importedCount = 0;
    
    extractedData.forEach((key, value) {
      for (final standard in standards) {
        if (standard.name.contains(key) || key.contains(standard.name)) {
          final controller = _stepControllers[step]![standard.id];
          if (controller != null && value != null) {
            final numValue = double.tryParse(value.toString());
            if (numValue != null) {
              controller.text = value.toString();
              _stepData[step]![standard.id] = numValue;
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

  void _toggleExamType(ExamType type) {
    setState(() {
      if (_selectedExamTypes.contains(type)) {
        _selectedExamTypes.remove(type);
      } else if (_selectedExamTypes.length < 4) {
        _selectedExamTypes.add(type);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('最多只能选择4项检查'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    });
  }

  void _goToNextStep() {
    if (_currentStep == 0) {
      // 检查类型选择步骤
      if (_selectedExamTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请至少选择一项检查'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      setState(() {
        _currentStep = 1;
        _initializeStepControllers(0);
      });
    } else if (_currentStep <= _selectedExamTypes.length) {
      // 数据录入步骤
      if (!_validateCurrentStep()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请填写所有必填项'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (_currentStep < _selectedExamTypes.length) {
        setState(() {
          _currentStep++;
          _initializeStepControllers(_currentStep - 1);
        });
      } else {
        // 最后一步，生成报告
        _generateReport();
      }
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) return true;
    
    final stepIndex = _currentStep - 1;
    final examType = _selectedExamTypes[stepIndex];
    final standards = _analysisService.getStandardsForType(examType);
    
    bool isValid = true;
    for (final standard in standards) {
      if (standard.isRequired) {
        if (!_stepData[stepIndex]!.containsKey(standard.id)) {
          setState(() {
            _stepErrors[stepIndex]![standard.id] = '此项为必填';
          });
          isValid = false;
        }
      }
    }
    
    return isValid;
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);

    try {
      // 构建检查数据项列表
      final examItems = <ExamDataItem>[];
      for (int i = 0; i < _selectedExamTypes.length; i++) {
        examItems.add(ExamDataItem(
          examType: _selectedExamTypes[i],
          indicatorValues: _stepData[i]!,
          examDate: DateTime.now(),
        ));
      }

      // 使用临时患者或实际患者
      final patient = _patient ?? Patient(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: '临时患者',
        age: 30,
        gender: '未知',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 导航到综合报告页面
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ComprehensiveReportPage(
              patient: patient,
              examItems: examItems,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成报告失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goToPreviousStep,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在生成报告...'),
                ],
              ),
            )
          : _buildBody(),
      bottomNavigationBar: _currentStep > 0
          ? _buildBottomNavigation()
          : null,
    );
  }

  String _getAppBarTitle() {
    if (_currentStep == 0) {
      return '选择检查项目';
    } else {
      return '录入数据 ($_currentStep/${_selectedExamTypes.length})';
    }
  }

  Widget _buildBody() {
    if (_currentStep == 0) {
      return _buildExamTypeSelection();
    } else {
      return _buildDataEntryStep();
    }
  }

  Widget _buildExamTypeSelection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '请选择需要录入的检查项目（最多4项）',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _availableExamTypes.length,
            itemBuilder: (context, index) {
              final examType = _availableExamTypes[index];
              final isSelected = _selectedExamTypes.contains(examType['type']);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 4 : 1,
                color: isSelected ? examType['color'].withOpacity(0.1) : null,
                child: InkWell(
                  onTap: () => _toggleExamType(examType['type']),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: examType['color'].withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            examType['icon'],
                            color: examType['color'],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                examType['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                examType['description'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleExamType(examType['type']),
                          activeColor: examType['color'],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedExamTypes.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '开始录入 (${_selectedExamTypes.length}项检查)',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDataEntryStep() {
    final stepIndex = _currentStep - 1;
    final examType = _selectedExamTypes[stepIndex];
    final examTypeInfo = _availableExamTypes.firstWhere(
      (e) => e['type'] == examType,
    );
    final standards = _analysisService.getStandardsForType(examType);
    final controllers = _stepControllers[stepIndex] ?? {};
    final errors = _stepErrors[stepIndex] ?? {};

    return Column(
      children: [
        // 进度指示器
        LinearProgressIndicator(
          value: _currentStep / (_selectedExamTypes.length + 1),
          backgroundColor: Colors.grey[200],
        ),
        // 当前检查类型标题
        Container(
          padding: const EdgeInsets.all(16.0),
          color: (examTypeInfo['color'] as Color).withOpacity(0.1),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (examTypeInfo['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  examTypeInfo['icon'],
                  color: examTypeInfo['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examTypeInfo['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '步骤 $_currentStep / ${_selectedExamTypes.length}',
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
        ),
        // OCR导入按钮
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            color: Colors.blue[50],
            child: InkWell(
              onTap: () => _importFromOCR(stepIndex),
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
          ),
        ),
        // 数据录入表单
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: standards.length,
            itemBuilder: (context, index) {
              final standard = standards[index];
              return _buildIndicatorCard(
                stepIndex,
                standard,
                controllers[standard.id],
                errors[standard.id],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorCard(
    int step,
    IndicatorStandard standard,
    TextEditingController? controller,
    String? error,
  ) {
    final hasError = error != null;
    
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
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '请输入数值',
                suffixText: standard.unit.isNotEmpty ? standard.unit : null,
                errorText: error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red : Colors.grey[300]!,
                  ),
                ),
              ),
              onChanged: (value) => _validateField(step, standard.id, value, standard),
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

  Widget _buildBottomNavigation() {
    final isLastStep = _currentStep == _selectedExamTypes.length;
    
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goToPreviousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('上一步'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isLastStep ? '生成AI报告' : '下一步',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
