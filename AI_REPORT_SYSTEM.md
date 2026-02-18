# AI大模型综合报告系统

## 功能概述

本系统集成了DashScope AI大模型（通义千问）能力，为视功能检查提供专业的AI分析报告。

## 核心功能

### 1. AI报告服务 (`ai_report_service.dart`)

- **模型**: 使用 qwen-turbo 或 qwen-max
- **输入**: 患者信息 + 多项检查数据（最多4项）
- **输出**: 结构化JSON报告，包含:
  - 总体评估
  - 关键发现
  - 年龄相关分析
  - 异常指标列表
  - 专业建议
  - 随访计划
  - 风险评估

### 2. 综合报告页面 (`comprehensive_report_page.dart`)

- 美观的结构化报告展示
- 支持PDF导出
- 支持分享功能
- 卡片式布局，层次分明

### 3. 多项检查录入 (`multi_exam_entry_page.dart`)

- 支持选择1-4项检查
- 分步录入向导
- 实时进度显示
- OCR自动导入支持

### 4. 检查类型标准

支持以下检查类型的标准化数据:
- 全套视功能检查
- 双眼视功能检查
- 弱视筛查
- 视疲劳评估

## 快速开始

### 配置API Key

1. 获取 DashScope API Key (https://dashscope.aliyun.com/)
2. 修改 `lib/domain/services/ai_report_service.dart`:

```dart
static const String _apiKey = 'your-actual-api-key';
```

### 生成AI报告

```dart
import 'package:vision_analyzer/domain/services/ai_report_service.dart';

// 创建患者和检查数据
final patient = Patient(...);
final examItems = [
  ExamDataItem(examType: ExamType.standardFullSet, ...),
  ExamDataItem(examType: ExamType.binocularVision, ...),
];

// 生成报告
final result = await AIReportService().generateComprehensiveReport(
  patient,
  examItems,
);
```

### 显示报告页面

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ComprehensiveReportPage(
      patient: patient,
      examItems: examItems,
    ),
  ),
);
```

### 使用多项检查录入

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MultiExamEntryPage(),
  ),
);
```

## 集成到现有流程

数据录入页面现在支持两种方式:

1. **标准分析** - 基于规则的传统分析报告
2. **AI综合报告** - AI生成的专业报告

在录入数据后点击"开始分析"，系统会弹出选择对话框，用户可以选择报告类型。

## 文件结构

```
lib/
├── domain/
│   └── services/
│       ├── ai_report_service.dart        # AI报告服务
│       ├── ai_report_example.dart        # 使用示例
│       └── analysis_service.dart         # 分析服务(已更新)
├── presentation/
│   └── pages/
│       ├── comprehensive_report_page.dart # 综合报告页面
│       ├── multi_exam_entry_page.dart     # 多项检查录入
│       └── data_entry_page.dart          # 数据录入(已更新)
└── core/constants/indicator_standards/
    ├── binocular_vision_standards.dart    # 双眼视功能标准
    ├── amblyopia_screening_standards.dart # 弱视筛查标准
    └── asthenopia_assessment_standards.dart # 视疲劳标准
```

## 注意事项

1. 默认API Key为占位符，使用前需要替换为实际Key
2. 如未配置API Key，系统将使用内置的默认分析逻辑
3. 建议在网络良好的环境下使用AI报告功能
4. AI生成的报告仅供参考，不作为医疗诊断依据

## 后续优化建议

1. 添加报告历史记录功能
2. 支持报告模板自定义
3. 集成更多AI模型选择
4. 添加报告批注功能
5. 支持多语言报告生成
