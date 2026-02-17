import 'dart:developer' as developer;
import '../../data/models/patient.dart';
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../services/pdf_service.dart';
import '../services/analysis_service.dart';

/// 生成PDF报告用例
class GeneratePDFReportUseCase {
  final PatientRepository _patientRepository;
  final ExamRepository _examRepository;
  final PDFService _pdfService;
  final AnalysisService _analysisService;

  GeneratePDFReportUseCase({
    PatientRepository? patientRepository,
    ExamRepository? examRepository,
    PDFService? pdfService,
    AnalysisService? analysisService,
  })  : _patientRepository = patientRepository ?? PatientRepository(),
        _examRepository = examRepository ?? ExamRepository(),
        _pdfService = pdfService ?? PDFService(),
        _analysisService = analysisService ?? AnalysisService();

  /// 执行PDF报告生成
  /// 
  /// [patientId] - 患者ID
  /// [examId] - 检查记录ID
  /// [outputPath] - 可选的自定义输出路径
  Future<String> execute({
    required String patientId,
    required String examId,
    String? outputPath,
  }) async {
    try {
      developer.log('GeneratePDFReportUseCase: 开始生成PDF报告');
      developer.log('  患者ID: $patientId');
      developer.log('  检查ID: $examId');

      // 1. 获取患者信息
      final patient = await _patientRepository.getPatientById(patientId);
      if (patient == null) {
        throw Exception('患者不存在: $patientId');
      }
      developer.log('  已获取患者信息: ${patient.name}');

      // 2. 获取检查记录
      final examRecord = await _examRepository.getExamById(examId);
      if (examRecord == null) {
        throw Exception('检查记录不存在: $examId');
      }
      developer.log('  已获取检查记录');

      // 3. 分析检查数据
      final analysisResults = await _analyzeExamData(examRecord);
      developer.log('  检查数据分析完成');

      // 4. 生成PDF
      final pdfPath = await _pdfService.exportToPDF(
        patient: patient,
        examRecord: examRecord,
        analysisResults: analysisResults,
        outputPath: outputPath,
      );

      // 5. 更新检查记录，保存PDF路径
      await _examRepository.updateExam(
        examId,
        pdfPath: pdfPath,
      );

      developer.log('GeneratePDFReportUseCase: PDF报告生成成功 - $pdfPath');
      return pdfPath;
    } catch (e, stackTrace) {
      developer.log('GeneratePDFReportUseCase: PDF报告生成失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 分析检查数据，生成报告所需数据
  Future<Map<String, dynamic>> _analyzeExamData(ExamRecord examRecord) async {
    final indicatorValues = examRecord.indicatorValues ?? {};
    
    // 分析指标数据
    final indicators = <Map<String, dynamic>>[];
    final conclusions = <String>[];
    final recommendations = <String>[];

    // 视力分析
    if (indicatorValues.containsKey('vision_right') || 
        indicatorValues.containsKey('vision_left')) {
      final visionRight = indicatorValues['vision_right'];
      final visionLeft = indicatorValues['vision_left'];
      
      indicators.add({
        'name': '视力 (右眼)',
        'value': visionRight ?? '-',
        'unit': '',
        'reference': '>= 1.0',
        'status': _getVisionStatus(visionRight),
      });
      
      indicators.add({
        'name': '视力 (左眼)',
        'value': visionLeft ?? '-',
        'unit': '',
        'reference': '>= 1.0',
        'status': _getVisionStatus(visionLeft),
      });

      // 视力相关结论
      if (visionRight != null && _parseVision(visionRight) < 1.0) {
        conclusions.add('右眼视力偏低 (${visionRight})，建议进一步检查。');
      }
      if (visionLeft != null && _parseVision(visionLeft) < 1.0) {
        conclusions.add('左眼视力偏低 (${visionLeft})，建议进一步检查。');
      }
    }

    // 球镜度数分析
    if (indicatorValues.containsKey('sph_right') || 
        indicatorValues.containsKey('sph_left')) {
      final sphRight = indicatorValues['sph_right'];
      final sphLeft = indicatorValues['sph_left'];
      
      indicators.add({
        'name': '球镜度数 (右眼)',
        'value': sphRight ?? '-',
        'unit': 'D',
        'reference': '0.00 ± 0.50',
        'status': _getDiopterStatus(sphRight),
      });
      
      indicators.add({
        'name': '球镜度数 (左眼)',
        'value': sphLeft ?? '-',
        'unit': 'D',
        'reference': '0.00 ± 0.50',
        'status': _getDiopterStatus(sphLeft),
      });

      // 屈光度相关结论
      if (sphRight != null && _parseDiopter(sphRight) != 0) {
        final diopter = _parseDiopter(sphRight);
        if (diopter > 0) {
          conclusions.add('右眼远视 ${diopter.abs().toStringAsFixed(2)}D。');
        } else if (diopter < 0) {
          conclusions.add('右眼近视 ${diopter.abs().toStringAsFixed(2)}D。');
        }
      }
    }

    // 柱镜度数分析
    if (indicatorValues.containsKey('cyl_right') || 
        indicatorValues.containsKey('cyl_left')) {
      final cylRight = indicatorValues['cyl_right'];
      final cylLeft = indicatorValues['cyl_left'];
      
      indicators.add({
        'name': '柱镜度数 (右眼)',
        'value': cylRight ?? '-',
        'unit': 'D',
        'reference': '0.00 ± 0.50',
        'status': _getDiopterStatus(cylRight),
      });
      
      indicators.add({
        'name': '柱镜度数 (左眼)',
        'value': cylLeft ?? '-',
        'unit': 'D',
        'reference': '0.00 ± 0.50',
        'status': _getDiopterStatus(cylLeft),
      });
    }

    // 眼压分析
    if (indicatorValues.containsKey('iop_right') || 
        indicatorValues.containsKey('iop_left')) {
      final iopRight = indicatorValues['iop_right'];
      final iopLeft = indicatorValues['iop_left'];
      
      indicators.add({
        'name': '眼压 (右眼)',
        'value': iopRight ?? '-',
        'unit': 'mmHg',
        'reference': '10-21',
        'status': _getIOPStatus(iopRight),
      });
      
      indicators.add({
        'name': '眼压 (左眼)',
        'value': iopLeft ?? '-',
        'unit': 'mmHg',
        'reference': '10-21',
        'status': _getIOPStatus(iopLeft),
      });
    }

    // 生成建议
    if (conclusions.isNotEmpty) {
      recommendations.addAll([
        '建议定期进行视功能检查，每6-12个月复查一次。',
        '注意用眼卫生，避免长时间近距离用眼，每40-50分钟休息10分钟。',
        '保持良好的用眼习惯，读书写字时保持30cm以上的距离。',
        '适当增加户外活动时间，建议每天户外活动2小时以上。',
      ]);

      // 根据异常情况添加特定建议
      if (indicators.any((i) => i['name'].toString().contains('视力') && 
          i['status'] == 'abnormal')) {
        recommendations.add('建议到专业眼科机构进行进一步检查，必要时验光配镜。');
      }

      if (indicators.any((i) => i['name'].toString().contains('眼压') && 
          i['status'] == 'abnormal')) {
        recommendations.add('眼压异常需要引起重视，建议尽快到眼科进行详细检查，排除青光眼等疾病。');
      }
    } else {
      recommendations.add('视功能检查结果基本正常，请继续保持良好的用眼习惯。');
      recommendations.add('建议定期进行视功能检查，每6-12个月复查一次。');
    }

    return {
      'indicators': indicators,
      'conclusions': conclusions.isEmpty ? ['检查结果基本正常，未见明显异常。'] : conclusions,
      'recommendations': recommendations,
      'examType': examRecord.examType.name,
      'examDate': examRecord.examDate.toIso8601String(),
    };
  }

  /// 获取视力状态
  String _getVisionStatus(dynamic vision) {
    if (vision == null) return 'normal';
    
    try {
      final value = _parseVision(vision.toString());
      if (value >= 1.0) return 'normal';
      if (value >= 0.6) return 'warning';
      return 'abnormal';
    } catch (e) {
      return 'normal';
    }
  }

  /// 获取屈光度状态
  String _getDiopterStatus(dynamic diopter) {
    if (diopter == null) return 'normal';
    
    try {
      final value = _parseDiopter(diopter.toString()).abs();
      if (value <= 0.50) return 'normal';
      if (value <= 3.00) return 'warning';
      return 'abnormal';
    } catch (e) {
      return 'normal';
    }
  }

  /// 获取眼压状态
  String _getIOPStatus(dynamic iop) {
    if (iop == null) return 'normal';
    
    try {
      final value = double.parse(iop.toString());
      if (value >= 10 && value <= 21) return 'normal';
      if ((value >= 8 && value < 10) || (value > 21 && value <= 24)) return 'warning';
      return 'abnormal';
    } catch (e) {
      return 'normal';
    }
  }

  /// 解析视力值
  double _parseVision(String vision) {
    // 处理分数形式如 5/10 或 20/40
    if (vision.contains('/')) {
      final parts = vision.split('/');
      if (parts.length == 2) {
        final numerator = double.tryParse(parts[0]) ?? 0;
        final denominator = double.tryParse(parts[1]) ?? 1;
        return numerator / denominator;
      }
    }
    // 直接解析小数
    return double.tryParse(vision) ?? 0;
  }

  /// 解析屈光度
  double _parseDiopter(String diopter) {
    return double.tryParse(diopter.toString().replaceAll('+', '')) ?? 0;
  }

  /// 批量生成PDF报告
  /// 
  /// [patientId] - 患者ID
  /// [examIds] - 检查记录ID列表
  Future<List<String>> executeBatch({
    required String patientId,
    required List<String> examIds,
  }) async {
    final results = <String>[];
    
    for (final examId in examIds) {
      try {
        final path = await execute(
          patientId: patientId,
          examId: examId,
        );
        results.add(path);
      } catch (e) {
        developer.log('批量生成PDF失败: examId=$examId', error: e);
        // 继续处理其他检查记录
      }
    }

    return results;
  }
}

/// 导出报告用例组合类
class ReportUseCases {
  final GeneratePDFReportUseCase generatePDFReport;

  ReportUseCases({
    PatientRepository? patientRepository,
    ExamRepository? examRepository,
    PDFService? pdfService,
    AnalysisService? analysisService,
  }) : generatePDFReport = GeneratePDFReportUseCase(
          patientRepository: patientRepository,
          examRepository: examRepository,
          pdfService: pdfService,
          analysisService: analysisService,
        );
}
