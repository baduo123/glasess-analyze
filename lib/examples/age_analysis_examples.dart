/// 智能年龄分析系统使用示例
/// 
/// 这个文件展示了如何在应用程序中使用新的年龄分析功能

import 'package:flutter/material.dart';
import '../core/utils/age_utils.dart';
import '../data/models/patient.dart';
import '../domain/services/age_based_analysis_service.dart';
import '../domain/services/analysis_service.dart';
import '../presentation/widgets/age_specific_badge.dart';

/// 示例 1: 基本年龄分组使用
void exampleBasicAgeGrouping() {
  const patientAge = 25;
  
  // 获取年龄组
  final ageGroup = AgeUtils.getGroup(patientAge);
  print('年龄组: $ageGroup'); // AgeGroup.adult
  
  // 获取年龄组名称
  final groupName = AgeUtils.getGroupName(patientAge);
  print('年龄组名称: $groupName'); // "成人(19-64岁)"
  
  // 获取年龄组ID
  final groupId = AgeUtils.getAgeGroupId(patientAge);
  print('年龄组ID: $groupId'); // 2
  
  // 检查年龄组
  final isAdult = AgeUtils.isAdult(patientAge);
  print('是否成人: $isAdult'); // true
}

/// 示例 2: 计算调节幅度预期值
void exampleCalculateAMP() {
  const patientAge = 40;
  
  // 使用Hoffman公式计算预期调节幅度
  // AMP = 18.5 - 0.3 * age
  final expectedAMP = AgeUtils.calculateAMPAgeBased(patientAge);
  print('40岁患者预期调节幅度: ${expectedAMP.toStringAsFixed(1)}D'); // 6.5D
}

/// 示例 3: 获取视力标准
void exampleGetVAStandard() {
  const childAge = 8;
  const elderlyAge = 75;
  
  final childVA = AgeUtils.getExpectedVA(childAge);
  final elderlyVA = AgeUtils.getExpectedVA(elderlyAge);
  
  print('儿童预期视力: $childVA'); // 1.0
  print('老人预期视力: $elderlyVA'); // 0.8
}

/// 示例 4: 使用基础AnalysisService进行年龄分析
void exampleBasicAnalysisWithAge() {
  final service = AnalysisService();
  
  final patient = Patient(
    id: 'p-001',
    name: '张三',
    age: 45,
    gender: '男',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final examRecord = ExamRecord(
    id: 'exam-001',
    patientId: patient.id,
    examType: ExamType.standardFullSet,
    examDate: DateTime.now(),
    createdAt: DateTime.now(),
    indicatorValues: {
      'va_far_uncorrected_od': 0.9,
      'va_far_uncorrected_os': 1.0,
      'amp_od': 4.5,
      'amp_os': 4.8,
    },
  );
  
  // 使用患者年龄进行分析
  final result = service.analyze(examRecord, patientAge: patient.age);
  
  print('分析结果:');
  print('总体评估: ${result.overallAssessment}');
  print('异常指标数: ${result.abnormalCount}');
}

/// 示例 5: 使用AgeBasedAnalysisService进行详细分析
void exampleDetailedAgeBasedAnalysis() {
  final service = AgeBasedAnalysisService();
  
  final patient = Patient(
    id: 'p-002',
    name: '李四',
    age: 65,
    gender: '女',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final examRecord = ExamRecord(
    id: 'exam-002',
    patientId: patient.id,
    examType: ExamType.standardFullSet,
    examDate: DateTime.now(),
    createdAt: DateTime.now(),
    indicatorValues: {
      'va_far_uncorrected_od': 0.85,
      'va_far_uncorrected_os': 0.9,
      'amp_od': 2.0,
      'amp_os': 2.2,
      'iop_od': 20.0,
      'iop_os': 21.0,
    },
  );
  
  // 使用analyzeWithPatient进行完整分析
  final result = service.analyzeWithPatient(examRecord, patient);
  
  print('年龄分析结果:');
  print('患者年龄: ${result.patientAge}岁');
  print('年龄组: ${result.ageGroupName}');
  print('总体评估: ${result.overallAssessment}');
  print('年龄校正: ${result.ageBasedAdjustments}');
}

/// 示例 6: 在UI中使用AgeSpecificBadge
class ExampleAgeBadgeUsage extends StatelessWidget {
  final Patient patient;
  
  const ExampleAgeBadgeUsage({
    super.key,
    required this.patient,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 完整版本徽章
        AgeSpecificBadge(
          age: patient.age,
          showDescription: true,
          onTap: () {
            // 显示年龄详细信息
          },
        ),
        
        const SizedBox(height: 16),
        
        // 紧凑版本徽章
        AgeSpecificBadge(
          age: patient.age,
          isCompact: true,
        ),
        
        const SizedBox(height: 16),
        
        // 年龄组芯片
        AgeGroupChip(
          age: patient.age,
        ),
        
        const SizedBox(height: 16),
        
        // 年龄相关建议卡片
        AgeBasedInfoCard(
          age: patient.age,
        ),
        
        const SizedBox(height: 16),
        
        // 年龄分组说明图例
        const AgeAnalysisLegend(),
      ],
    );
  }
}

/// 示例 7: 完整的分析报告页面使用
class ExampleAnalysisReportIntegration extends StatelessWidget {
  final Patient patient;
  final ExamRecord examRecord;
  
  const ExampleAnalysisReportIntegration({
    super.key,
    required this.patient,
    required this.examRecord,
  });
  
  @override
  Widget build(BuildContext context) {
    final service = AgeBasedAnalysisService();
    final result = service.analyzeWithPatient(examRecord, patient);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('分析报告'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 患者信息卡片
            _buildPatientCard(),
            
            const SizedBox(height: 16),
            
            // 年龄分析卡片
            _buildAgeAnalysisCard(),
            
            const SizedBox(height: 16),
            
            // 分析结果
            _buildAnalysisResults(result),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPatientCard() {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person),
        ),
        title: Text(patient.name),
        subtitle: Text('${patient.age}岁 · ${patient.gender}'),
        trailing: AgeSpecificBadge(
          age: patient.age,
          isCompact: true,
        ),
      ),
    );
  }
  
  Widget _buildAgeAnalysisCard() {
    return Builder(
      builder: (context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: AgeUtils.getGroupColor(patient.age),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '年龄分析',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AgeSpecificBadge(
                age: patient.age,
                showDescription: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnalysisResults(AgeBasedAnalysisResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基于${result.ageGroupName}标准',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(result.overallAssessment),
          ],
        ),
      ),
    );
  }
}


