import 'package:flutter/material.dart';
import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../core/utils/age_utils.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/patient.dart';
import 'analysis_service.dart';

class AgeBasedStandard {
  final String indicatorId;
  final int ageGroupId;
  final double? minValue;
  final double? maxValue;
  final String formula;
  final List<String> notes;
  final Map<String, dynamic>? additionalParams;

  AgeBasedStandard({
    required this.indicatorId,
    required this.ageGroupId,
    this.minValue,
    this.maxValue,
    this.formula = '',
    this.notes = const [],
    this.additionalParams,
  });

  factory AgeBasedStandard.fromMap(Map<String, dynamic> map) {
    return AgeBasedStandard(
      indicatorId: map['indicator_id'] as String,
      ageGroupId: map['age_group_id'] as int,
      minValue: map['min_value'] != null ? (map['min_value'] as num).toDouble() : null,
      maxValue: map['max_value'] != null ? (map['max_value'] as num).toDouble() : null,
      formula: map['formula'] as String? ?? '',
      notes: map['notes'] != null ? List<String>.from(map['notes']) : [],
      additionalParams: map['additional_params'] != null
          ? Map<String, dynamic>.from(map['additional_params'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'indicator_id': indicatorId,
      'age_group_id': ageGroupId,
      'min_value': minValue,
      'max_value': maxValue,
      'formula': formula,
      'notes': notes,
      'additional_params': additionalParams,
    };
  }
}

class AgeBasedAnalysisResult extends AnalysisResult {
  final int patientAge;
  final AgeGroup ageGroup;
  final String ageGroupName;
  final Map<String, dynamic> ageBasedAdjustments;

  AgeBasedAnalysisResult({
    required super.examId,
    required super.analyzedAt,
    required super.abnormalities,
    required super.overallAssessment,
    required super.keyFindings,
    required super.comprehensiveSuggestions,
    required super.totalIndicators,
    required super.abnormalCount,
    required this.patientAge,
    required this.ageGroup,
    required this.ageGroupName,
    required this.ageBasedAdjustments,
  });
}

class AgeBasedAnalysisService extends AnalysisService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  AgeBasedAnalysisResult analyzeWithPatient(ExamRecord record, Patient patient) {
    final age = patient.age;
    final ageGroup = AgeUtils.getGroup(age);
    final ageGroupId = AgeUtils.getAgeGroupId(age);
    final ageGroupName = AgeUtils.getGroupName(age);

    final standards = getStandardsForTypeWithAge(record.examType, age, ageGroupId);
    final abnormalities = <AbnormalIndicator>[];
    final values = record.indicatorValues ?? {};
    final ageBasedAdjustments = <String, dynamic>{};

    for (final standard in standards) {
      final value = values[standard.id];
      if (value == null) continue;

      if (standard.type == IndicatorType.numeric && value is num) {
        final ageBasedStandard = _getAgeBasedStandardForIndicator(standard.id, ageGroupId, age);
        final adjustedValue = _applyAgeBasedFormula(value.toDouble(), ageBasedStandard, age);

        ageBasedAdjustments[standard.id] = {
          'originalValue': value,
          'adjustedValue': adjustedValue,
          'formula': ageBasedStandard?.formula ?? '',
          'ageGroupId': ageGroupId,
        };

        final range = standard.checkValue(adjustedValue);
        if (range != null) {
          abnormalities.add(AbnormalIndicator(
            indicatorId: standard.id,
            indicatorName: standard.name,
            inputValue: value,
            unit: standard.unit,
            level: range.level,
            interpretation: _getAgeBasedInterpretation(
              range.interpretation,
              ageBasedStandard,
              age,
            ),
            possibleCauses: _getAgeBasedPossibleCauses(
              range.possibleCauses,
              standard.id,
              ageGroup,
            ),
            recommendations: _getAgeBasedRecommendations(
              range.recommendations,
              standard.id,
              ageGroup,
            ),
          ));
        }
      }
    }

    final ageBasedSuggestions = _generateAgeBasedSuggestions(abnormalities, age, ageGroup);

    return AgeBasedAnalysisResult(
      examId: record.id,
      analyzedAt: DateTime.now(),
      abnormalities: abnormalities,
      overallAssessment: _generateAgeBasedOverallAssessment(abnormalities, age, ageGroup),
      keyFindings: _extractAgeBasedKeyFindings(abnormalities, ageGroup),
      comprehensiveSuggestions: ageBasedSuggestions,
      totalIndicators: standards.length,
      abnormalCount: abnormalities.length,
      patientAge: age,
      ageGroup: ageGroup,
      ageGroupName: ageGroupName,
      ageBasedAdjustments: ageBasedAdjustments,
    );
  }

  List<IndicatorStandard> getStandardsForTypeWithAge(ExamType type, int age, int ageGroupId) {
    final baseStandards = getStandardsForType(type);
    final adjustedStandards = <IndicatorStandard>[];

    for (final standard in baseStandards) {
      final adjustedStandard = _adjustStandardForAge(standard, age, ageGroupId);
      adjustedStandards.add(adjustedStandard);
    }

    return adjustedStandards;
  }

  IndicatorStandard _adjustStandardForAge(IndicatorStandard standard, int age, int ageGroupId) {
    if (standard.id.contains('amp')) {
      return _adjustAMPStandard(standard, age);
    } else if (standard.id.contains('va')) {
      return _adjustVAStandard(standard, ageGroupId);
    } else if (standard.id.contains('sph')) {
      return _adjustSPHStandard(standard, ageGroupId);
    } else if (standard.id.contains('iop')) {
      return _adjustIOPStandard(standard, ageGroupId);
    }
    return standard;
  }

  IndicatorStandard _adjustAMPStandard(IndicatorStandard standard, int age) {
    final expectedAMP = AgeUtils.calculateAMPAgeBased(age);
    final ranges = <IndicatorRange>[
      IndicatorRange(
        level: AbnormalLevel.normal,
        minValue: expectedAMP * 0.85,
        interpretation: '调节幅度正常（基于年龄预期值 ${expectedAMP.toStringAsFixed(1)}D）',
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

  IndicatorStandard _adjustVAStandard(IndicatorStandard standard, int ageGroupId) {
    final expectedVA = ageGroupId == 3 ? 0.8 : 1.0;

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
        possibleCauses: ['屈光不正', ageGroupId == 3 ? '早期白内障' : '轻度角膜病变'],
        recommendations: ['验光检查', '排除眼部器质性病变'],
        displayColor: Colors.yellow.shade700,
      ),
      IndicatorRange(
        level: AbnormalLevel.moderate,
        minValue: expectedVA * 0.3,
        maxValue: expectedVA * 0.59,
        interpretation: '中度视力下降',
        possibleCauses: ['中高度屈光不正', ageGroupId == 3 ? '白内障' : '角膜病变'],
        recommendations: ['详细检查病因', '必要时配镜或治疗'],
        displayColor: Colors.orange,
      ),
      IndicatorRange(
        level: AbnormalLevel.severe,
        maxValue: expectedVA * 0.29,
        interpretation: '重度视力下降',
        possibleCauses: ['高度屈光不正', ageGroupId == 3 ? '严重器质性病变' : '弱视'],
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

  IndicatorStandard _adjustSPHStandard(IndicatorStandard standard, int ageGroupId) {
    final ranges = List<IndicatorRange>.from(standard.ranges);

    if (ageGroupId == 3) {
      for (int i = 0; i < ranges.length; i++) {
        final range = ranges[i];
        if (range.level != AbnormalLevel.normal) {
          ranges[i] = IndicatorRange(
            level: range.level,
            minValue: range.minValue,
            maxValue: range.maxValue,
            interpretation: '${range.interpretation}（老人需排除白内障引起的屈光度变化）',
            possibleCauses: [...range.possibleCauses, '白内障'],
            recommendations: [...range.recommendations, '建议检查晶状体透明度'],
            displayColor: range.displayColor,
          );
        }
      }
    }

    return IndicatorStandard(
      id: standard.id,
      name: standard.name,
      unit: standard.unit,
      type: standard.type,
      ranges: ranges,
      description: ageGroupId == 3
          ? '${standard.description}（老人需考虑白内障影响）'
          : standard.description,
      isRequired: standard.isRequired,
      isBinocular: standard.isBinocular,
    );
  }

  IndicatorStandard _adjustIOPStandard(IndicatorStandard standard, int ageGroupId) {
    final ranges = List<IndicatorRange>.from(standard.ranges);

    if (ageGroupId == 3) {
      for (int i = 0; i < ranges.length; i++) {
        final range = ranges[i];
        if (range.level != AbnormalLevel.normal) {
          ranges[i] = IndicatorRange(
            level: range.level,
            minValue: range.minValue,
            maxValue: range.maxValue,
            interpretation: '${range.interpretation}（老人需排除青光眼）',
            possibleCauses: [...range.possibleCauses, '青光眼'],
            recommendations: [...range.recommendations, '建议进行青光眼筛查'],
            displayColor: range.displayColor,
          );
        }
      }
    }

    return IndicatorStandard(
      id: standard.id,
      name: standard.name,
      unit: standard.unit,
      type: standard.type,
      ranges: ranges,
      description: ageGroupId == 3
          ? '${standard.description}（老人需考虑青光眼风险）'
          : standard.description,
      isRequired: standard.isRequired,
      isBinocular: standard.isBinocular,
    );
  }

  AgeBasedStandard? _getAgeBasedStandardForIndicator(String indicatorId, int ageGroupId, int age) {
    return AgeBasedStandard(
      indicatorId: indicatorId,
      ageGroupId: ageGroupId,
      formula: _getFormulaForIndicator(indicatorId),
      notes: _getNotesForIndicator(indicatorId, ageGroupId),
    );
  }

  String _getFormulaForIndicator(String indicatorId) {
    if (indicatorId.contains('amp')) {
      return 'AMP = 18.5 - 0.3 × age';
    }
    return '';
  }

  List<String> _getNotesForIndicator(String indicatorId, int ageGroupId) {
    final notes = <String>[];

    if (indicatorId.contains('amp') && ageGroupId == 3) {
      notes.add('老年人调节幅度随年龄显著下降，属正常生理现象');
    } else if (indicatorId.contains('va') && ageGroupId == 3) {
      notes.add('老年人视力标准适当放宽至0.8');
    } else if (indicatorId.contains('sph') && ageGroupId == 3) {
      notes.add('老人屈光度变化需警惕白内障');
    } else if (indicatorId.contains('iop') && ageGroupId == 3) {
      notes.add('老人眼压异常需排除青光眼');
    }

    return notes;
  }

  double _applyAgeBasedFormula(double value, AgeBasedStandard? standard, int age) {
    if (standard == null || standard.formula.isEmpty) {
      return value;
    }

    if (standard.indicatorId.contains('amp')) {
      return value;
    }

    return value;
  }

  String _getAgeBasedInterpretation(String baseInterpretation, AgeBasedStandard? standard, int age) {
    if (standard == null) {
      return baseInterpretation;
    }

    return baseInterpretation;
  }

  List<String> _getAgeBasedPossibleCauses(List<String> baseCauses, String indicatorId, AgeGroup ageGroup) {
    final causes = List<String>.from(baseCauses);

    switch (ageGroup) {
      case AgeGroup.child:
        if (indicatorId.contains('va')) {
          causes.addAll(['弱视', '先天性眼病']);
        }
        break;
      case AgeGroup.elderly:
        if (indicatorId.contains('va')) {
          causes.addAll(['白内障', '黄斑变性', '青光眼']);
        } else if (indicatorId.contains('amp')) {
          causes.addAll(['老视', '年龄相关性调节功能下降']);
        } else if (indicatorId.contains('iop')) {
          causes.addAll(['青光眼', '眼压调节功能减退']);
        }
        break;
      case AgeGroup.adult:
        break;
    }

    return causes.toSet().toList();
  }

  List<String> _getAgeBasedRecommendations(List<String> baseRecommendations, String indicatorId, AgeGroup ageGroup) {
    final recommendations = List<String>.from(baseRecommendations);

    switch (ageGroup) {
      case AgeGroup.child:
        recommendations.addAll([
          '家长需关注孩子用眼习惯',
          '保证充足的户外活动时间',
        ]);
        break;
      case AgeGroup.elderly:
        recommendations.addAll([
          '建议每半年进行一次全面的眼科检查',
          '关注老年常见眼病（白内障、青光眼、黄斑变性）',
        ]);
        break;
      case AgeGroup.adult:
        recommendations.addAll([
          '建议每年进行一次眼科检查',
          '注意用眼卫生，避免视疲劳',
        ]);
        break;
    }

    return recommendations.toSet().toList();
  }

  String _generateAgeBasedOverallAssessment(List<AbnormalIndicator> abnormalities, int age, AgeGroup ageGroup) {
    if (abnormalities.isEmpty) {
      return '所有检查指标均在正常范围内，视功能良好（基于${AgeUtils.getGroupNameByGroup(ageGroup)}标准）。';
    }

    final severeCount = abnormalities.where((a) => a.level == AbnormalLevel.severe).length;
    final moderateCount = abnormalities.where((a) => a.level == AbnormalLevel.moderate).length;

    String assessment;
    if (severeCount > 0) {
      assessment = '检查发现 $severeCount 项指标重度异常，建议尽快就医进行详细检查和治疗。';
    } else if (moderateCount > 0) {
      assessment = '检查发现 $moderateCount 项指标中度异常，建议进一步检查并采取相应干预措施。';
    } else {
      assessment = '检查发现 ${abnormalities.length} 项指标轻度异常，建议注意观察并定期复查。';
    }

    assessment += '\n\n【年龄相关提示】${AgeUtils.getAgeGroupDescription(age)}';

    return assessment;
  }

  List<String> _extractAgeBasedKeyFindings(List<AbnormalIndicator> abnormalities, AgeGroup ageGroup) {
    final findings = abnormalities.map((a) =>
      '${a.indicatorName}: ${a.inputValue}${a.unit} - ${a.interpretation}'
    ).toList();

    if (ageGroup == AgeGroup.elderly) {
      findings.add('注：老人各项指标已按老年标准评估');
    }

    return findings;
  }

  List<String> _generateAgeBasedSuggestions(List<AbnormalIndicator> abnormalities, int age, AgeGroup ageGroup) {
    final suggestions = <String>{};

    for (final abnormal in abnormalities) {
      suggestions.addAll(abnormal.recommendations);
    }

    suggestions.addAll(AgeUtils.getAgeSpecificNotes(age));

    return suggestions.toList();
  }

  Future<List<AgeBasedStandard>> _getAgeBasedStandardsFromMySQL(int ageGroupId) async {
    try {
      final db = await _databaseHelper.database;
      final results = await db.query(
        'age_based_standards',
        where: 'age_group_id = ?',
        whereArgs: [ageGroupId],
      );

      return results.map((map) => AgeBasedStandard.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  double _calculateWithFormula(double value, String formula) {
    if (formula.isEmpty) {
      return value;
    }

    if (formula.contains('18.5 - 0.3 * age')) {
      return value;
    }

    return value;
  }
}
