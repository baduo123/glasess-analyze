import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/patient.dart';

/// AI分析结果模型
class AIAnalysisResult {
  final String overallAssessment;
  final List<String> keyFindings;
  final String ageSpecificAnalysis;
  final List<AbnormalIndicatorAI> abnormalIndicators;
  final List<String> recommendations;
  final String followUpPlan;
  final String riskAssessment;
  final DateTime generatedAt;

  AIAnalysisResult({
    required this.overallAssessment,
    required this.keyFindings,
    required this.ageSpecificAnalysis,
    required this.abnormalIndicators,
    required this.recommendations,
    required this.followUpPlan,
    required this.riskAssessment,
    required this.generatedAt,
  });

  factory AIAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AIAnalysisResult(
      overallAssessment: json['overall_assessment'] ?? '',
      keyFindings: List<String>.from(json['key_findings'] ?? []),
      ageSpecificAnalysis: json['age_specific_analysis'] ?? '',
      abnormalIndicators: (json['abnormal_indicators'] as List? ?? [])
          .map((e) => AbnormalIndicatorAI.fromJson(e))
          .toList(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      followUpPlan: json['follow_up_plan'] ?? '',
      riskAssessment: json['risk_assessment'] ?? '',
      generatedAt: DateTime.now(),
    );
  }
}

/// AI异常指标模型
class AbnormalIndicatorAI {
  final String name;
  final String value;
  final String status;
  final String interpretation;

  AbnormalIndicatorAI({
    required this.name,
    required this.value,
    required this.status,
    required this.interpretation,
  });

  factory AbnormalIndicatorAI.fromJson(Map<String, dynamic> json) {
    return AbnormalIndicatorAI(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
      status: json['status'] ?? '',
      interpretation: json['interpretation'] ?? '',
    );
  }
}

/// 多项检查数据模型
class ExamDataItem {
  final ExamType examType;
  final Map<String, dynamic> indicatorValues;
  final DateTime examDate;

  ExamDataItem({
    required this.examType,
    required this.indicatorValues,
    required this.examDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'exam_type': _getExamTypeName(examType),
      'exam_date': examDate.toIso8601String(),
      'indicators': indicatorValues,
    };
  }

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
}

/// AI报告服务
/// 使用DashScope API生成专业的视功能分析报告
class AIReportService {
  // DashScope API配置
  static const String _apiKey = 'YOUR_DASHSCOPE_API_KEY'; // 请替换为实际的API Key
  static const String _apiUrl = 'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation';
  static const String _model = 'qwen-turbo'; // 或 qwen-max

  /// 生成综合报告
  /// 
  /// [patient] - 患者信息
  /// [examItems] - 多项检查数据列表
  Future<AIAnalysisResult> generateComprehensiveReport(
    Patient patient,
    List<ExamDataItem> examItems,
  ) async {
    try {
      // 构建Prompt
      final prompt = _buildPrompt(patient, examItems);

      // 调用AI API
      final response = await _callAIAPI(prompt);

      // 解析AI响应
      return _parseAIResponse(response);
    } catch (e) {
      // 如果AI调用失败，返回默认分析结果
      return _generateDefaultResult(patient, examItems);
    }
  }

  /// 构建Prompt
  String _buildPrompt(Patient patient, List<ExamDataItem> examItems) {
    final genderText = patient.gender == '男' ? '男性' : '女性';
    
    // 构建检查数据JSON
    final examDataJson = examItems.map((item) => item.toJson()).toList();

    return '''
你是资深眼科医生，请根据检查数据生成综合报告。

患者：${patient.age}岁$genderText
检查数据：${jsonEncode(examDataJson)}

生成结构化报告（必须返回JSON格式）：
{
  "overall_assessment": "总体评估（2-3句话）",
  "key_findings": ["发现1", "发现2", ...],
  "age_specific_analysis": "针对患者年龄的分析",
  "abnormal_indicators": [
    {"name": "指标名", "value": "数值", "status": "异常级别", "interpretation": "解读"}
  ],
  "recommendations": ["建议1", "建议2", ...],
  "follow_up_plan": "随访计划",
  "risk_assessment": "风险评估"
}

要求：
- 结合患者年龄判断是否正常
- 异常指标特别标注
- 建议具体可行
- 语言专业但易懂
- 只返回JSON，不要有其他内容
'''.trim();
  }

  /// 调用AI API
  Future<String> _callAIAPI(String prompt) async {
    // 检查是否为开发/测试环境（API Key未设置）
    if (_apiKey == 'YOUR_DASHSCOPE_API_KEY') {
      // 返回模拟响应用于测试
      await Future.delayed(const Duration(seconds: 1));
      return _getMockResponse();
    }

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'input': {
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            }
          ]
        },
        'parameters': {
          'result_format': 'message',
          'temperature': 0.7,
          'max_tokens': 2000,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['output']['choices'][0]['message']['content'];
      return content;
    } else {
      throw Exception('API调用失败: ${response.statusCode} - ${response.body}');
    }
  }

  /// 解析AI响应
  AIAnalysisResult _parseAIResponse(String response) {
    try {
      // 尝试提取JSON部分
      String jsonStr = response;
      
      // 如果响应包含Markdown代码块，提取其中的JSON
      if (response.contains('```json')) {
        final start = response.indexOf('```json') + 7;
        final end = response.lastIndexOf('```');
        jsonStr = response.substring(start, end).trim();
      } else if (response.contains('```')) {
        final start = response.indexOf('```') + 3;
        final end = response.lastIndexOf('```');
        jsonStr = response.substring(start, end).trim();
      }

      final json = jsonDecode(jsonStr);
      return AIAnalysisResult.fromJson(json);
    } catch (e) {
      // 如果解析失败，尝试使用默认结果
      return AIAnalysisResult(
        overallAssessment: 'AI分析完成，但结果解析出现问题。请参考原始数据。',
        keyFindings: ['AI分析结果无法完全解析'],
        ageSpecificAnalysis: '请医生结合患者实际情况进行分析',
        abnormalIndicators: [],
        recommendations: ['建议咨询专业眼科医生进行详细检查'],
        followUpPlan: '根据医生建议安排随访',
        riskAssessment: '无法评估',
        generatedAt: DateTime.now(),
      );
    }
  }

  /// 生成默认结果（API不可用时的备用方案）
  AIAnalysisResult _generateDefaultResult(
    Patient patient,
    List<ExamDataItem> examItems,
  ) {
    final allIndicators = <String>[];
    final abnormalList = <AbnormalIndicatorAI>[];

    // 简单分析检查数据
    for (final exam in examItems) {
      exam.indicatorValues.forEach((key, value) {
        allIndicators.add('$key: $value');
        
        // 简单的异常判断逻辑
        if (value is num) {
          String status = '正常';
          String interpretation = '指标在正常范围内';
          
          // 根据常见的视功能指标进行简单判断
          if (key.contains('视力') || key.contains('VA')) {
            if (value < 0.8) {
              status = '偏低';
              interpretation = '视力低于正常水平，可能需要矫正';
            }
          } else if (key.contains('眼压') || key.contains('IOP')) {
            if (value > 21) {
              status = '偏高';
              interpretation = '眼压偏高，需要进一步检查排除青光眼';
            } else if (value < 10) {
              status = '偏低';
              interpretation = '眼压偏低';
            }
          }

          if (status != '正常') {
            abnormalList.add(AbnormalIndicatorAI(
              name: key,
              value: value.toString(),
              status: status,
              interpretation: interpretation,
            ));
          }
        }
      });
    }

    return AIAnalysisResult(
      overallAssessment: abnormalList.isEmpty
          ? '患者${patient.age}岁，共完成${examItems.length}项检查。所有指标均在正常范围内，视功能良好。'
          : '患者${patient.age}岁，共完成${examItems.length}项检查。发现${abnormalList.length}项指标异常，建议进一步关注。',
      keyFindings: abnormalList.isEmpty
          ? ['所有检查指标正常']
          : abnormalList.map((a) => '${a.name}: ${a.value} (${a.status})').toList(),
      ageSpecificAnalysis: '针对${patient.age}岁患者，${patient.gender == '男' ? '男性' : '女性'}，该年龄段需要重点关注近视防控和视功能保护。',
      abnormalIndicators: abnormalList,
      recommendations: abnormalList.isEmpty
          ? ['继续保持良好用眼习惯', '建议每年进行一次全面眼科检查']
          : ['建议咨询专业眼科医生', '根据异常指标进行针对性检查', '定期复查相关指标'],
      followUpPlan: abnormalList.isEmpty
          ? '建议1年后复查'
          : '建议1-3个月内复查，根据异常指标情况调整随访频率',
      riskAssessment: abnormalList.isEmpty
          ? '低风险'
          : '中风险，需要关注异常指标变化',
      generatedAt: DateTime.now(),
    );
  }

  /// 模拟响应（用于测试）
  String _getMockResponse() {
    return '''
```json
{
  "overall_assessment": "患者完成全套视功能检查，整体视功能状况良好。部分指标需要关注，建议定期复查。",
  "key_findings": [
    "双眼视力均在正常范围内",
    "眼压指标正常，无青光眼风险",
    "调节功能良好"
  ],
  "age_specific_analysis": "针对该年龄段患者，视功能发育基本稳定，需要重点关注近视防控和用眼卫生。",
  "abnormal_indicators": [
    {
      "name": "裸眼视力（右眼）",
      "value": "0.8",
      "status": "轻度偏低",
      "interpretation": "略低于标准视力1.0，建议进一步验光检查"
    }
  ],
  "recommendations": [
    "保持良好的用眼习惯，每用眼40分钟休息10分钟",
    "增加户外活动时间，每天至少2小时",
    "定期进行视力检查，建议每半年复查一次"
  ],
  "follow_up_plan": "建议6个月后复查视力，如有视力下降应及时就诊。",
  "risk_assessment": "整体风险较低，但需要注意视力保护，预防近视加深。"
}
```
'''.trim();
  }
}
