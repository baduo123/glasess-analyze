import 'package:flutter/material.dart';
import 'indicator_standard_model.dart';

/// 双眼视功能检查标准
class BinocularVisionStandards {
  static List<IndicatorStandard> getStandards() {
    return [
      // 隐斜
      IndicatorStandard(
        id: 'phoria_distance',
        name: '远距离隐斜',
        unit: 'Δ',
        type: IndicatorType.numeric,
        description: '远距离眼位偏斜量',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: -2.0,
            maxValue: 2.0,
            interpretation: '眼位正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: -6.0,
            maxValue: -2.1,
            interpretation: '轻度外隐斜',
            possibleCauses: ['调节不足', '集合不足'],
            recommendations: ['视觉训练', '棱镜矫正'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 2.1,
            maxValue: 6.0,
            interpretation: '轻度内隐斜',
            possibleCauses: ['调节过度', '集合过度'],
            recommendations: ['视觉训练', '放松调节'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            maxValue: -6.1,
            interpretation: '外隐斜明显',
            possibleCauses: ['集合功能不足', '调节功能障碍'],
            recommendations: ['集合训练', '必要时棱镜'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 6.1,
            interpretation: '内隐斜明显',
            possibleCauses: ['集合过度', '调节痉挛'],
            recommendations: ['调节放松训练', '散瞳验光'],
            displayColor: Colors.orange,
          ),
        ],
      ),

      // 融合范围 - 发散
      IndicatorStandard(
        id: 'fusion_divergence',
        name: '融合范围（发散）',
        unit: 'Δ',
        type: IndicatorType.numeric,
        description: '负融像性集合范围',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 6.0,
            interpretation: '融合范围正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 3.0,
            maxValue: 5.9,
            interpretation: '融合范围轻度下降',
            possibleCauses: ['融像功能不足'],
            recommendations: ['融像训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            maxValue: 2.9,
            interpretation: '融合范围明显下降',
            possibleCauses: ['融像功能障碍'],
            recommendations: ['系统视觉训练'],
            displayColor: Colors.orange,
          ),
        ],
      ),

      // 融合范围 - 集合
      IndicatorStandard(
        id: 'fusion_convergence',
        name: '融合范围（集合）',
        unit: 'Δ',
        type: IndicatorType.numeric,
        description: '正融像性集合范围',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 15.0,
            interpretation: '融合范围正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 10.0,
            maxValue: 14.9,
            interpretation: '融合范围轻度下降',
            possibleCauses: ['集合功能不足'],
            recommendations: ['集合训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            maxValue: 9.9,
            interpretation: '融合范围明显下降',
            possibleCauses: ['集合功能障碍'],
            recommendations: ['系统视觉训练', '必要时棱镜'],
            displayColor: Colors.orange,
          ),
        ],
      ),

      // AC/A 比率
      IndicatorStandard(
        id: 'ac_a_ratio',
        name: 'AC/A 比率',
        unit: 'Δ/D',
        type: IndicatorType.numeric,
        description: '调节性集合与调节之比',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 3.0,
            maxValue: 5.0,
            interpretation: 'AC/A正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            maxValue: 2.9,
            interpretation: 'AC/A偏低',
            possibleCauses: ['集合不足'],
            recommendations: ['集合训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 5.1,
            maxValue: 7.0,
            interpretation: 'AC/A偏高',
            possibleCauses: ['集合过度'],
            recommendations: ['调节放松训练'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 7.1,
            interpretation: 'AC/A明显偏高',
            possibleCauses: ['集合过度', '调节异常'],
            recommendations: ['详细检查', '系统治疗'],
            displayColor: Colors.orange,
          ),
        ],
      ),
    ];
  }
}
