import 'package:flutter/material.dart';
import 'indicator_standard_model.dart';

/// 视疲劳评估检查标准
class AsthenopiaAssessmentStandards {
  static List<IndicatorStandard> getStandards() {
    return [
      // 调节灵敏度（右眼）
      IndicatorStandard(
        id: 'facility_od',
        name: '调节灵敏度（右眼）',
        unit: 'cpm',
        type: IndicatorType.numeric,
        description: '每分钟调节循环次数',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 12.0,
            interpretation: '调节灵敏度正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 8.0,
            maxValue: 11.9,
            interpretation: '调节灵敏度轻度下降',
            possibleCauses: ['调节疲劳', '用眼过度'],
            recommendations: ['注意用眼休息', '视觉训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 5.0,
            maxValue: 7.9,
            interpretation: '调节灵敏度中度下降',
            possibleCauses: ['调节功能障碍', '视疲劳'],
            recommendations: ['系统视觉训练', '药物治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 4.9,
            interpretation: '调节灵敏度重度下降',
            possibleCauses: ['严重调节功能障碍'],
            recommendations: ['立即就医', '全面检查'],
            displayColor: Colors.red,
          ),
        ],
      ),

      // 调节灵敏度（左眼）
      IndicatorStandard(
        id: 'facility_os',
        name: '调节灵敏度（左眼）',
        unit: 'cpm',
        type: IndicatorType.numeric,
        description: '每分钟调节循环次数',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 12.0,
            interpretation: '调节灵敏度正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 8.0,
            maxValue: 11.9,
            interpretation: '调节灵敏度轻度下降',
            possibleCauses: ['调节疲劳', '用眼过度'],
            recommendations: ['注意用眼休息', '视觉训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 5.0,
            maxValue: 7.9,
            interpretation: '调节灵敏度中度下降',
            possibleCauses: ['调节功能障碍', '视疲劳'],
            recommendations: ['系统视觉训练', '药物治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 4.9,
            interpretation: '调节灵敏度重度下降',
            possibleCauses: ['严重调节功能障碍'],
            recommendations: ['立即就医', '全面检查'],
            displayColor: Colors.red,
          ),
        ],
      ),

      // 正负相对调节（PRA）
      IndicatorStandard(
        id: 'pra',
        name: '负相对调节（PRA）',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '在40cm处能放松的最大调节量',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: -2.50,
            interpretation: 'PRA正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: -1.75,
            maxValue: -2.49,
            interpretation: 'PRA轻度不足',
            possibleCauses: ['调节紧张', '集合不足'],
            recommendations: ['调节放松训练', '视觉训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: -1.00,
            maxValue: -1.74,
            interpretation: 'PRA中度不足',
            possibleCauses: ['调节功能障碍', '视疲劳'],
            recommendations: ['系统视觉训练', '必要时药物'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: -0.99,
            interpretation: 'PRA重度不足',
            possibleCauses: ['严重调节功能障碍'],
            recommendations: ['立即就医', '综合干预'],
            displayColor: Colors.red,
          ),
        ],
      ),

      // 正相对调节（NRA）
      IndicatorStandard(
        id: 'nra',
        name: '正相对调节（NRA）',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '在40cm处能刺激的最大调节量',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 1.75,
            maxValue: 2.50,
            interpretation: 'NRA正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            maxValue: 1.74,
            interpretation: 'NRA轻度不足',
            possibleCauses: ['调节疲劳', '老视早期症状'],
            recommendations: ['调节训练', '注意休息'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            maxValue: 1.00,
            interpretation: 'NRA中度不足',
            possibleCauses: ['调节功能障碍'],
            recommendations: ['系统视觉训练'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 2.51,
            maxValue: 3.00,
            interpretation: 'NRA轻度偏高',
            possibleCauses: ['调节放松过度'],
            recommendations: ['观察', '必要时复查'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 3.01,
            interpretation: 'NRA明显偏高',
            possibleCauses: ['调节功能异常'],
            recommendations: ['详细检查'],
            displayColor: Colors.orange,
          ),
        ],
      ),

      // 集合近点
      IndicatorStandard(
        id: 'npc',
        name: '集合近点',
        unit: 'cm',
        type: IndicatorType.numeric,
        description: '能维持双眼单视的最近距离',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            maxValue: 6.0,
            interpretation: '集合近点正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 6.1,
            maxValue: 8.0,
            interpretation: '集合近点轻度后退',
            possibleCauses: ['集合功能轻度不足'],
            recommendations: ['集合训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 8.1,
            maxValue: 10.0,
            interpretation: '集合近点明显后退',
            possibleCauses: ['集合功能不足'],
            recommendations: ['系统集合训练'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            minValue: 10.1,
            interpretation: '集合近点严重后退',
            possibleCauses: ['严重集合功能障碍'],
            recommendations: ['立即就医', '综合干预'],
            displayColor: Colors.red,
          ),
        ],
      ),
    ];
  }
}
