import 'package:flutter/material.dart';
import '../domain/services/ai_report_service.dart';
import '../data/models/patient.dart';

/// AI报告服务使用示例
class AIReportExample {
  
  /// 示例1: 生成AI综合报告
  static Future<void> generateComprehensiveReport() async {
    final aiService = AIReportService();
    
    // 创建患者
    final patient = Patient(
      id: 'patient_001',
      name: '张三',
      age: 30,
      gender: '男',
      phone: '13800138000',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    // 创建检查数据
    final examItems = [
      ExamDataItem(
        examType: ExamType.standardFullSet,
        indicatorValues: {
          'va_far_uncorrected_od': 0.8,
          'va_far_uncorrected_os': 1.0,
          'iop_od': 16.0,
          'iop_os': 15.0,
          'sph_od': -2.50,
          'sph_os': -1.00,
        },
        examDate: DateTime.now(),
      ),
      ExamDataItem(
        examType: ExamType.binocularVision,
        indicatorValues: {
          'phoria_distance': 2.0,
          'fusion_divergence': 8.0,
          'fusion_convergence': 20.0,
        },
        examDate: DateTime.now(),
      ),
    ];
    
    // 生成报告
    try {
      final result = await aiService.generateComprehensiveReport(
        patient,
        examItems,
      );
      
      print('总体评估: ${result.overallAssessment}');
      print('关键发现: ${result.keyFindings}');
      print('异常指标: ${result.abnormalIndicators.length}项');
      print('建议: ${result.recommendations}');
    } catch (e) {
      print('生成报告失败: $e');
    }
  }
  
  /// 示例2: 单检查类型的快速报告
  static Future<void> generateQuickReport() async {
    final aiService = AIReportService();
    
    final patient = Patient(
      id: 'patient_002',
      name: '李四',
      age: 25,
      gender: '女',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final examItem = ExamDataItem(
      examType: ExamType.amblyopiaScreening,
      indicatorValues: {
        'va_corrected_od': 0.9,
        'va_corrected_os': 0.6,
        'anisometropia': 2.0,
        'stereopsis': 80.0,
      },
      examDate: DateTime.now(),
    );
    
    final result = await aiService.generateComprehensiveReport(
      patient,
      [examItem],
    );
    
    print('风险评估: ${result.riskAssessment}');
    print('随访计划: ${result.followUpPlan}');
  }
}

/// 使用说明
/// 
/// 1. 配置API Key:
///    在 ai_report_service.dart 中设置 _apiKey:
///    static const String _apiKey = 'your-actual-api-key';
///
/// 2. 基础使用:
///    final result = await AIReportService().generateComprehensiveReport(
///      patient,
///      examItems,
///    );
///
/// 3. 在页面中显示:
///    Navigator.push(
///      context,
///      MaterialPageRoute(
///        builder: (context) => ComprehensiveReportPage(
///          patient: patient,
///          examItems: examItems,
///        ),
///      ),
///    );
///
/// 4. 多项检查录入:
///    Navigator.push(
///      context,
///      MaterialPageRoute(
///        builder: (context) => MultiExamEntryPage(),
///      ),
///    );
