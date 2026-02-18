import 'package:flutter/material.dart';
import 'indicator_standard_model.dart';

/// 弱视筛查检查标准
class AmblyopiaScreeningStandards {
  static List<IndicatorStandard> getStandards() {
    return [
      // 矫正视力（右眼）
      IndicatorStandard(
        id: 'va_corrected_od',
        name: '矫正视力（右眼）',
        unit: '',
        type: IndicatorType.numeric,
        description: '配戴最佳矫正镜片后的视力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 0.8,
            interpretation: '矫正视力正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 0.5,
            maxValue: 0.79,
            interpretation: '轻度弱视可能',
            possibleCauses: ['屈光不正', '轻度弱视'],
            recommendations: ['详细检查', '必要时配镜'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 0.2,
            maxValue: 0.49,
            interpretation: '中度弱视',
            possibleCauses: ['屈光参差', '斜视性弱视'],
            recommendations: ['弱视治疗', '遮盖疗法', '视觉训练'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 0.19,
            interpretation: '重度弱视',
            possibleCauses: ['先天性因素', '严重屈光不正'],
            recommendations: ['立即弱视治疗', '综合干预'],
            displayColor: Colors.red,
          ),
        ],
      ),

      // 矫正视力（左眼）
      IndicatorStandard(
        id: 'va_corrected_os',
        name: '矫正视力（左眼）',
        unit: '',
        type: IndicatorType.numeric,
        description: '配戴最佳矫正镜片后的视力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 0.8,
            interpretation: '矫正视力正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 0.5,
            maxValue: 0.79,
            interpretation: '轻度弱视可能',
            possibleCauses: ['屈光不正', '轻度弱视'],
            recommendations: ['详细检查', '必要时配镜'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 0.2,
            maxValue: 0.49,
            interpretation: '中度弱视',
            possibleCauses: ['屈光参差', '斜视性弱视'],
            recommendations: ['弱视治疗', '遮盖疗法', '视觉训练'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 0.19,
            interpretation: '重度弱视',
            possibleCauses: ['先天性因素', '严重屈光不正'],
            recommendations: ['立即弱视治疗', '综合干预'],
            displayColor: Colors.red,
          ),
        ],
      ),

      // 屈光参差
      IndicatorStandard(
        id: 'anisometropia',
        name: '屈光参差',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '两眼屈光度数的差异',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            maxValue: 1.5,
            interpretation: '屈光参差在正常范围',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 1.51,
            maxValue: 2.5,
            interpretation: '轻度屈光参差',
            possibleCauses: ['两眼发育差异'],
            recommendations: ['矫正视力', '定期复查'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 2.51,
            maxValue: 4.0,
            interpretation: '中度屈光参差',
            possibleCauses: ['两眼发育不平衡', '可能导致弱视'],
            recommendations: ['配镜矫正', '弱视筛查'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            minValue: 4.01,
            interpretation: '高度屈光参差',
            possibleCauses: ['明显发育差异', '弱视风险高'],
            recommendations: ['立即配镜', '弱视治疗', '定期随访'],
            displayColor: Colors.red,
          ),
        ],
      ),

      // 立体视锐度
      IndicatorStandard(
        id: 'stereopsis',
        name: '立体视锐度',
        unit: 'arcsec',
        type: IndicatorType.numeric,
        description: '立体视觉的敏锐程度',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            maxValue: 60.0,
            interpretation: '立体视正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 61.0,
            maxValue: 100.0,
            interpretation: '立体视轻度下降',
            possibleCauses: ['轻度斜视', '屈光不正'],
            recommendations: ['视觉训练', '矫正屈光不正'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 101.0,
            maxValue: 200.0,
            interpretation: '立体视中度下降',
            possibleCauses: ['斜视', '弱视'],
            recommendations: ['详细检查', '系统治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            minValue: 201.0,
            interpretation: '立体视严重下降',
            possibleCauses: ['严重斜视', '单眼抑制'],
            recommendations: ['立即治疗', '综合干预'],
            displayColor: Colors.red,
          ),
        ],
      ),
    ];
  }
}
