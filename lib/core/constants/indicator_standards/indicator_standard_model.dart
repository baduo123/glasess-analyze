import 'package:flutter/material.dart';

enum IndicatorType {
  numeric,
  text,
  option,
  boolean,
}

enum AbnormalLevel {
  normal,
  mild,
  moderate,
  severe,
}

class IndicatorRange {
  final AbnormalLevel level;
  final double? minValue;
  final double? maxValue;
  final String interpretation;
  final List<String> possibleCauses;
  final List<String> recommendations;
  final Color displayColor;

  const IndicatorRange({
    required this.level,
    this.minValue,
    this.maxValue,
    required this.interpretation,
    this.possibleCauses = const [],
    this.recommendations = const [],
    required this.displayColor,
  });

  bool contains(double value) {
    if (minValue != null && value < minValue!) return false;
    if (maxValue != null && value > maxValue!) return false;
    return true;
  }
}

class IndicatorStandard {
  final String id;
  final String name;
  final String unit;
  final IndicatorType type;
  final List<IndicatorRange> ranges;
  final String description;
  final bool isRequired;
  final bool isBinocular;

  const IndicatorStandard({
    required this.id,
    required this.name,
    required this.unit,
    required this.type,
    required this.ranges,
    required this.description,
    this.isRequired = true,
    this.isBinocular = true,
  });

  IndicatorRange? checkValue(double value) {
    for (final range in ranges) {
      if (range.contains(value)) {
        return range.level == AbnormalLevel.normal ? null : range;
      }
    }
    return null;
  }
}
