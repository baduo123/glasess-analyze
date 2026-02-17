import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../core/constants/indicator_standards/standard_full_set.dart';
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

  List<IndicatorStandard> getStandardsForType(ExamType type) {
    if (_standardsCache.containsKey(type)) {
      return _standardsCache[type]!;
    }

    List<IndicatorStandard> standards;
    switch (type) {
      case ExamType.standardFullSet:
        standards = StandardFullSetStandards.getStandards();
        break;
      default:
        standards = [];
    }

    _standardsCache[type] = standards;
    return standards;
  }

  AnalysisResult analyze(ExamRecord record) {
    final standards = getStandardsForType(record.examType);
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
      overallAssessment: _generateOverallAssessment(abnormalities),
      keyFindings: _extractKeyFindings(abnormalities),
      comprehensiveSuggestions: _generateSuggestions(abnormalities),
      totalIndicators: standards.length,
      abnormalCount: abnormalities.length,
    );
  }

  String _generateOverallAssessment(List<AbnormalIndicator> abnormalities) {
    if (abnormalities.isEmpty) {
      return '所有检查指标均在正常范围内，视功能良好。';
    }

    final severeCount = abnormalities.where((a) => a.level == AbnormalLevel.severe).length;
    final moderateCount = abnormalities.where((a) => a.level == AbnormalLevel.moderate).length;
    
    if (severeCount > 0) {
      return '检查发现 $severeCount 项指标重度异常，建议尽快就医进行详细检查和治疗。';
    } else if (moderateCount > 0) {
      return '检查发现 $moderateCount 项指标中度异常，建议进一步检查并采取相应干预措施。';
    } else {
      return '检查发现 ${abnormalities.length} 项指标轻度异常，建议注意观察并定期复查。';
    }
  }

  List<String> _extractKeyFindings(List<AbnormalIndicator> abnormalities) {
    return abnormalities.map((a) => 
      '${a.indicatorName}: ${a.inputValue}${a.unit} - ${a.interpretation}'
    ).toList();
  }

  List<String> _generateSuggestions(List<AbnormalIndicator> abnormalities) {
    final suggestions = <String>{};
    for (final abnormal in abnormalities) {
      suggestions.addAll(abnormal.recommendations);
    }
    return suggestions.toList();
  }
}
