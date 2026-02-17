import 'package:flutter/material.dart';
import 'indicator_standard_model.dart';

class StandardFullSetStandards {
  static List<IndicatorStandard> getStandards() {
    return [
      // 视力指标 - 裸眼远视力（右眼）
      IndicatorStandard(
        id: 'va_far_uncorrected_od',
        name: '裸眼远视力（右眼）',
        unit: '',
        type: IndicatorType.numeric,
        description: '未矫正状态下的远距离视力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 1.0,
            interpretation: '视力正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 0.6,
            maxValue: 0.9,
            interpretation: '轻度视力下降',
            possibleCauses: ['屈光不正', '早期白内障', '轻度角膜病变'],
            recommendations: ['验光检查', '排除眼部器质性病变'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 0.3,
            maxValue: 0.5,
            interpretation: '中度视力下降',
            possibleCauses: ['中高度屈光不正', '白内障', '角膜病变'],
            recommendations: ['详细检查病因', '必要时配镜或治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 0.2,
            interpretation: '重度视力下降',
            possibleCauses: ['高度屈光不正', '严重器质性病变', '弱视'],
            recommendations: ['立即就医检查', '积极治疗'],
            displayColor: Colors.red,
          ),
        ],
      ),
      
      // 视力指标 - 裸眼远视力（左眼）
      IndicatorStandard(
        id: 'va_far_uncorrected_os',
        name: '裸眼远视力（左眼）',
        unit: '',
        type: IndicatorType.numeric,
        description: '未矫正状态下的远距离视力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 1.0,
            interpretation: '视力正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 0.6,
            maxValue: 0.9,
            interpretation: '轻度视力下降',
            possibleCauses: ['屈光不正', '早期白内障', '轻度角膜病变'],
            recommendations: ['验光检查', '排除眼部器质性病变'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 0.3,
            maxValue: 0.5,
            interpretation: '中度视力下降',
            possibleCauses: ['中高度屈光不正', '白内障', '角膜病变'],
            recommendations: ['详细检查病因', '必要时配镜或治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 0.2,
            interpretation: '重度视力下降',
            possibleCauses: ['高度屈光不正', '严重器质性病变', '弱视'],
            recommendations: ['立即就医检查', '积极治疗'],
            displayColor: Colors.red,
          ),
        ],
      ),
      
      // 调节幅度（右眼）
      IndicatorStandard(
        id: 'amp_od',
        name: '调节幅度（右眼）',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '眼睛能够调节的最大屈光力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 7.0,
            interpretation: '调节幅度正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 5.0,
            maxValue: 6.9,
            interpretation: '调节幅度轻度下降',
            possibleCauses: ['调节疲劳', '早期老视', '轻度调节功能障碍'],
            recommendations: ['视觉训练', '注意休息'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 3.0,
            maxValue: 4.9,
            interpretation: '调节幅度中度下降',
            possibleCauses: ['调节不足', '老视', '调节功能障碍'],
            recommendations: ['渐进多焦点镜片', '视觉训练', '必要时用药'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 2.9,
            interpretation: '调节幅度重度下降',
            possibleCauses: ['严重调节不足', '高级老视', '神经系统疾病'],
            recommendations: ['立即就医', '全面检查'],
            displayColor: Colors.red,
          ),
        ],
      ),
      
      // 调节幅度（左眼）
      IndicatorStandard(
        id: 'amp_os',
        name: '调节幅度（左眼）',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '眼睛能够调节的最大屈光力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 7.0,
            interpretation: '调节幅度正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 5.0,
            maxValue: 6.9,
            interpretation: '调节幅度轻度下降',
            possibleCauses: ['调节疲劳', '早期老视', '轻度调节功能障碍'],
            recommendations: ['视觉训练', '注意休息'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 3.0,
            maxValue: 4.9,
            interpretation: '调节幅度中度下降',
            possibleCauses: ['调节不足', '老视', '调节功能障碍'],
            recommendations: ['渐进多焦点镜片', '视觉训练', '必要时用药'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: 2.9,
            interpretation: '调节幅度重度下降',
            possibleCauses: ['严重调节不足', '高级老视', '神经系统疾病'],
            recommendations: ['立即就医', '全面检查'],
            displayColor: Colors.red,
          ),
        ],
      ),
      
      // 屈光度 - 球镜（右眼）
      IndicatorStandard(
        id: 'sph_od',
        name: '球镜（右眼）',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '近视或远视度数',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: -0.50,
            maxValue: 0.50,
            interpretation: '屈光度正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: -3.00,
            maxValue: -0.51,
            interpretation: '轻度近视',
            possibleCauses: ['轴性近视', '曲率性近视'],
            recommendations: ['配戴合适眼镜', '注意用眼卫生'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: -6.00,
            maxValue: -3.01,
            interpretation: '中度近视',
            possibleCauses: ['轴性近视'],
            recommendations: ['配戴合适眼镜', '定期复查'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: -6.01,
            interpretation: '高度近视',
            possibleCauses: ['病理性近视', '遗传性近视'],
            recommendations: ['定期眼底检查', '避免剧烈运动', '必要时手术'],
            displayColor: Colors.red,
          ),
        ],
      ),
      
      // 屈光度 - 球镜（左眼）
      IndicatorStandard(
        id: 'sph_os',
        name: '球镜（左眼）',
        unit: 'D',
        type: IndicatorType.numeric,
        description: '近视或远视度数',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: -0.50,
            maxValue: 0.50,
            interpretation: '屈光度正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: -3.00,
            maxValue: -0.51,
            interpretation: '轻度近视',
            possibleCauses: ['轴性近视', '曲率性近视'],
            recommendations: ['配戴合适眼镜', '注意用眼卫生'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: -6.00,
            maxValue: -3.01,
            interpretation: '中度近视',
            possibleCauses: ['轴性近视'],
            recommendations: ['配戴合适眼镜', '定期复查'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            maxValue: -6.01,
            interpretation: '高度近视',
            possibleCauses: ['病理性近视', '遗传性近视'],
            recommendations: ['定期眼底检查', '避免剧烈运动', '必要时手术'],
            displayColor: Colors.red,
          ),
        ],
      ),
      
      // 眼压（右眼）
      IndicatorStandard(
        id: 'iop_od',
        name: '眼压（右眼）',
        unit: 'mmHg',
        type: IndicatorType.numeric,
        description: '眼球内部压力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 10.0,
            maxValue: 21.0,
            interpretation: '眼压正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 22.0,
            maxValue: 25.0,
            interpretation: '眼压轻度升高',
            possibleCauses: ['高眼压症', '早期青光眼'],
            recommendations: ['定期复查眼压', '监测视野'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 26.0,
            maxValue: 30.0,
            interpretation: '眼压中度升高',
            possibleCauses: ['青光眼', '眼部炎症'],
            recommendations: ['青光眼筛查', '必要时降眼压治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            minValue: 31.0,
            interpretation: '眼压重度升高',
            possibleCauses: ['急性青光眼', '继发性青光眼'],
            recommendations: ['立即就医', '紧急降眼压治疗'],
            displayColor: Colors.red,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            maxValue: 9.0,
            interpretation: '眼压偏低',
            possibleCauses: ['低眼压', '眼球萎缩'],
            recommendations: ['检查病因', '排除眼部疾病'],
            displayColor: Colors.yellow,
          ),
        ],
      ),
      
      // 眼压（左眼）
      IndicatorStandard(
        id: 'iop_os',
        name: '眼压（左眼）',
        unit: 'mmHg',
        type: IndicatorType.numeric,
        description: '眼球内部压力',
        ranges: [
          IndicatorRange(
            level: AbnormalLevel.normal,
            minValue: 10.0,
            maxValue: 21.0,
            interpretation: '眼压正常',
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            minValue: 22.0,
            maxValue: 25.0,
            interpretation: '眼压轻度升高',
            possibleCauses: ['高眼压症', '早期青光眼'],
            recommendations: ['定期复查眼压', '监测视野'],
            displayColor: Colors.yellow,
          ),
          IndicatorRange(
            level: AbnormalLevel.moderate,
            minValue: 26.0,
            maxValue: 30.0,
            interpretation: '眼压中度升高',
            possibleCauses: ['青光眼', '眼部炎症'],
            recommendations: ['青光眼筛查', '必要时降眼压治疗'],
            displayColor: Colors.orange,
          ),
          IndicatorRange(
            level: AbnormalLevel.severe,
            minValue: 31.0,
            interpretation: '眼压重度升高',
            possibleCauses: ['急性青光眼', '继发性青光眼'],
            recommendations: ['立即就医', '紧急降眼压治疗'],
            displayColor: Colors.red,
          ),
          IndicatorRange(
            level: AbnormalLevel.mild,
            maxValue: 9.0,
            interpretation: '眼压偏低',
            possibleCauses: ['低眼压', '眼球萎缩'],
            recommendations: ['检查病因', '排除眼部疾病'],
            displayColor: Colors.yellow,
          ),
        ],
      ),
    ];
  }
}
