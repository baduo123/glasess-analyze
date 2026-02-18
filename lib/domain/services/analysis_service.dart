import 'package:flutter/material.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../core/constants/indicator_standards/standard_full_set.dart';
import '../../core/constants/indicator_standards/binocular_vision_standards.dart';
import '../../core/constants/indicator_standards/amblyopia_screening_standards.dart';
import '../../core/constants/indicator_standards/asthenopia_assessment_standards.dart';
import '../../core/utils/age_utils.dart';
import '../../data/models/patient.dart';

class AbnormalIndicator {
  final String indicatorId;
  final String indicatorName;
  final dynamic inputValue;
  final String unit;
  final AbnormalLevel level;
  final String interpretation;
  final List<String> possibleCauses;
  final List<String> recommendations;

  AbnormalIndicator({
    required this.indicatorId,
    required this.indicatorName,
    required this.inputValue,
    required this.unit,
    required this.level,
    required this.interpretation,
    required this.possibleCauses,
    required this.recommendations,
  });
}

class AnalysisResult {
  final String examId;
  final DateTime analyzedAt;
  final List<AbnormalIndicator> abnormalities;
  final String overallAssessment;
  final List<String> keyFindings;
  final List<String> comprehensiveSuggestions;
  final int totalIndicators;
  final int abnormalCount;

  AnalysisResult({
    required this.examId,
    required this.analyzedAt,
    required this.abnormalities,
    required this.overallAssessment,
    required this.keyFindings,
    required this.comprehensiveSuggestions,
    required this.totalIndicators,
    required this.abnormalCount,
  });
}

class AnalysisService {
  final Map<ExamType, List<IndicatorStandard>> _standardsCache = {};

  List<IndicatorStandard> getStandardsForType(ExamType type, {int? patientAge}) {
    if (_standardsCache.containsKey(type) && patientAge == null) {
      return _standardsCache[type]!;
    }

    List<IndicatorStandard> standards;
    switch (type) {
      case ExamType.standardFullSet:
        standards = StandardFullSetStandards.getStandards();
        break;
      case ExamType.binocularVision:
        standards = BinocularVisionStandards.getStandards();
        break;
      case ExamType.amblyopiaScreening:
        standards = AmblyopiaScreeningStandards.getStandards();
        break;
      case ExamType.asthenopiaAssessment:
        standards = AsthenopiaAssessmentStandards.getStandards();
        break;
      default:
        standards = [];
    }

    if (patientAge != null) {
      standards = _adjustStandardsForAge(standards, patientAge);
    } else {
      _standardsCache[type] = standards;
    }

    return standards;
  }

  List<IndicatorStandard> _adjustStandardsForAge(List<IndicatorStandard> standards, int age) {
    final ageGroup = AgeUtils.getGroup(age);
    final adjustedStandards = <IndicatorStandard>[];

    for (final standard in standards) {
      final adjusted = _applyAgeAdjustment(standard, age, ageGroup);
      adjustedStandards.add(adjusted);
    }

    return adjustedStandards;
  }

  IndicatorStandard _applyAgeAdjustment(IndicatorStandard standard, int age, AgeGroup ageGroup) {
    if (standard.id.contains('amp')) {
      return _adjustAMPForAge(standard, age);
    } else if (standard.id.contains('va')) {
      return _adjustVAForAge(standard, ageGroup);
    }
    return standard;
  }

  IndicatorStandard _adjustAMPForAge(IndicatorStandard standard, int age) {
    final expectedAMP = AgeUtils.calculateAMPAgeBased(age);
    final ranges = <IndicatorRange>[
      IndicatorRange(
        level: AbnormalLevel.normal,
        minValue: expectedAMP * 0.85,
        interpretation: '调节幅度正常（预期值 ${expectedAMP.toStringAsFixed(1)}D）',
        displayColor: Colors.green,
      ),
      IndicatorRange(
        level: AbnormalLevel.mild,
        minValue: expectedAMP * 0.65,
        maxValue: expectedAMP * 0.84,
        interpretation: '调节幅度轻度下降',
        possibleCauses: ['调节疲劳', '早期调节功能减退'],
        recommendations: ['视觉训练', '注意休息用眼'],
        displayColor: Colors.yellow.shade700,
      ),
      IndicatorRange(
        level: AbnormalLevel.moderate,
        minValue: expectedAMP * 0.45,
        maxValue: expectedAMP * 0.64,
        interpretation: '调节幅度中度下降',
        possibleCauses: ['调节不足', '老视早期症状'],
        recommendations: ['渐进多焦点镜片', '视觉训练'],
        displayColor: Colors.orange,
      ),
      IndicatorRange(
        level: AbnormalLevel.severe,
        maxValue: expectedAMP * 0.44,
        interpretation: '调节幅度重度下降',
        possibleCauses: ['严重调节不足', '老视', '神经系统疾病'],
        recommendations: ['立即就医', '全面检查'],
        displayColor: Colors.red,
      ),
    ];

    return IndicatorStandard(
      id: standard.id,
      name: standard.name,
      unit: standard.unit,
      type: standard.type,
      ranges: ranges,
      description: '${standard.description}（已根据年龄 $age 岁调整）',
      isRequired: standard.isRequired,
      isBinocular: standard.isBinocular,
    );
  }

  IndicatorStandard _adjustVAForAge(IndicatorStandard standard, AgeGroup ageGroup) {
    final expectedVA = ageGroup == AgeGroup.elderly ? 0.8 : 1.0;

    final ranges = <IndicatorRange>[
      IndicatorRange(
        level: AbnormalLevel.normal,
        minValue: expectedVA,
        interpretation: '视力正常',
        displayColor: Colors.green,
      ),
      IndicatorRange(
        level: AbnormalLevel.mild,
        minValue: expectedVA * 0.6,
        maxValue: expectedVA * 0.99,
        interpretation: '轻度视力下降',
        possibleCauses: ['屈光不正', ageGroup == AgeGroup.elderly ? '早期白内障' : '轻度角膜病变'],
        recommendations: ['验光检查', '排除眼部器质性病变'],
        displayColor: Colors.yellow.shade700,
      ),
      IndicatorRange(
        level: AbnormalLevel.moderate,
        minValue: expectedVA * 0.3,
        maxValue: expectedVA * 0.59,
        interpretation: '中度视力下降',
        possibleCauses: ['中高度屈光不正', ageGroup == AgeGroup.elderly ? '白内障' : '角膜病变'],
        recommendations: ['详细检查病因', '必要时配镜或治疗'],
        displayColor: Colors.orange,
      ),
      IndicatorRange(
        level: AbnormalLevel.severe,
        maxValue: expectedVA * 0.29,
        interpretation: '重度视力下降',
        possibleCauses: ['高度屈光不正', ageGroup == AgeGroup.elderly ? '严重器质性病变' : '弱视'],
        recommendations: ['立即就医检查', '积极治疗'],
        displayColor: Colors.red,
      ),
    ];

    return IndicatorStandard(
      id: standard.id,
      name: standard.name,
      unit: standard.unit,
      type: standard.type,
      ranges: ranges,
      description: '${standard.description}（已根据年龄组调整，预期视力 $expectedVA）',
      isRequired: standard.isRequired,
      isBinocular: standard.isBinocular,
    );
  }

  AnalysisResult analyze(ExamRecord record, {int? patientAge}) {
    final standards = getStandardsForType(record.examType, patientAge: patientAge);
    final abnormalities = <AbnormalIndicator>[];
    final values = record.indicatorValues ?? {};

    for (final standard in standards) {
      final value = values[standard.id];
      if (value == null) continue;

      if (standard.type == IndicatorType.numeric && value is num) {
        final range = standard.checkValue(value.toDouble());
        if (range != null) {
          abnormalities.add(AbnormalIndicator(
            indicatorId: standard.id,
            indicatorName: standard.name,
            inputValue: value,
            unit: standard.unit,
            level: range.level,
            interpretation: range.interpretation,
            possibleCauses: range.possibleCauses,
            recommendations: range.recommendations,
          ));
        }
      }
    }

    return AnalysisResult(
      examId: record.id,
      analyzedAt: DateTime.now(),
      abnormalities: abnormalities,
      overallAssessment: _generateOverallAssessment(abnormalities, patientAge),
      keyFindings: _extractKeyFindings(abnormalities),
      comprehensiveSuggestions: _generateSuggestions(abnormalities, patientAge),
      totalIndicators: standards.length,
      abnormalCount: abnormalities.length,
    );
  }

  String _generateOverallAssessment(List<AbnormalIndicator> abnormalities, int? patientAge) {
    String assessment;
    if (abnormalities.isEmpty) {
      assessment = '所有检查指标均在正常范围内，视功能良好';
    } else {
      final severeCount = abnormalities.where((a) => a.level == AbnormalLevel.severe).length;
      final moderateCount = abnormalities.where((a) => a.level == AbnormalLevel.moderate).length;

      if (severeCount > 0) {
        assessment = '检查发现 $severeCount 项指标重度异常，建议尽快就医进行详细检查和治疗';
      } else if (moderateCount > 0) {
        assessment = '检查发现 $moderateCount 项指标中度异常，建议进一步检查并采取相应干预措施';
      } else {
        assessment = '检查发现 ${abnormalities.length} 项指标轻度异常，建议注意观察并定期复查';
      }
    }

    if (patientAge != null) {
      final ageGroupName = AgeUtils.getGroupName(patientAge);
      assessment += '（基于$ageGroupName标准）。';
    } else {
      assessment += '。';
    }

    return assessment;
  }

  List<String> _extractKeyFindings(List<AbnormalIndicator> abnormalities) {
    return abnormalities.map((a) =>
      '${a.indicatorName}: ${a.inputValue}${a.unit} - ${a.interpretation}'
    ).toList();
  }

  List<String> _generateSuggestions(List<AbnormalIndicator> abnormalities, int? patientAge) {
    final suggestions = <String>{};
    for (final abnormal in abnormalities) {
      suggestions.addAll(abnormal.recommendations);
    }

    if (patientAge != null) {
      suggestions.addAll(AgeUtils.getAgeSpecificNotes(patientAge));
    }

    return suggestions.toList();
  }
}
