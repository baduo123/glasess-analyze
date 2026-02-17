# 视功能自动分析App设计文档

**日期：** 2026-02-17  
**项目：** 视功能自动分析App  
**技术方案：** Flutter 跨平台开发

---

## 1. 项目概述

### 1.1 项目目标
开发一款面向眼科医生/验光师的视功能分析App，帮助专业人员：
- 快速录入患者视功能检查数据（手动输入或拍照识别）
- 自动分析各项指标是否异常
- 生成包含诊断解读和处理建议的专业报告
- 可选建立患者档案，追踪历史变化趋势

### 1.2 核心价值
**痛点解决：**
- 无需背诵大量视功能指标标准值
- 无需翻阅资料查找异常对应的意义
- 自动化分析节省时间，提高效率
- 标准化报告提升专业形象

### 1.3 目标用户
- 眼科医生
- 验光师
- 视光中心工作人员

---

## 2. 功能需求

### 2.1 核心功能

#### A. 检查类型选择
用户可在开始检查时选择分析模板：
- **标准眼科全套**：基础视力、屈光、眼压 + 双眼视功能全项
- **视功能专项**：专注双眼视功能评估
- **儿童弱视筛查**：针对儿童特点的检查组合
- **视疲劳评估**：针对视疲劳相关指标
- **自定义**：用户可选择需要的指标组合

#### B. 数据录入
1. **手动录入**：
   - 分组表单展示（基础信息、视力、屈光、调节、集合、融像等）
   - 实时校验输入合法性
   - 支持保存草稿

2. **拍照识别**：
   - 调用相机拍摄检查单
   - OCR 识别关键数据（集成百度AI/腾讯云OCR）
   - 自动填充表单 + 用户确认修正

#### C. 智能分析引擎
- 根据检查类型加载对应的指标标准库
- 自动比对输入值与正常范围
- 分级标注：正常（绿）/ 轻度异常（黄）/ 中度异常（橙）/ 重度异常（红）
- 每项异常提供：医学解释 + 可能原因 + 处理建议

#### D. 报告生成
- **App内报告**：彩色标记 + 详细解读
- **PDF导出**：专业格式，可打印分享
- **分享功能**：微信/邮件分享报告

#### E. 患者管理（可选功能）
- 新建/编辑患者档案
- 历史检查记录查看
- 趋势分析图表

---

## 3. 系统架构

### 3.1 技术架构

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
│  │  首页   │ │ 录入页  │ │  报告页   │ │
│  └─────────┘ └─────────┘ └───────────┘ │
│  ┌─────────┐ ┌─────────┐ ┌───────────┐ │
│  │ 患者页  │ │ 历史页  │ │  设置页   │ │
│  └─────────┘ └─────────┘ └───────────┘ │
└─────────────────────────────────────────┘
                   │
┌─────────────────────────────────────────┐
│           Business Logic Layer          │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │ 检查类型管理  │  │   指标分析引擎   │ │
│  └──────────────┘  └─────────────────┘ │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │  OCR识别服务  │  │   PDF生成服务   │ │
│  └──────────────┘  └─────────────────┘ │
└─────────────────────────────────────────┘
                   │
┌─────────────────────────────────────────┐
│            Data Layer                   │
│  ┌──────────────┐  ┌─────────────────┐ │
│  │ SQLite本地库  │  │  指标标准库配置  │ │
│  └──────────────┘  └─────────────────┘ │
└─────────────────────────────────────────┘
```

### 3.2 项目结构

```
lib/
├── main.dart                          # 应用入口
├── app.dart                           # 应用配置
├── core/
│   ├── constants/
│   │   ├── indicator_standards/       # 各类型指标标准库
│   │   │   ├── standard_full_set.dart # 标准全套
│   │   │   ├── binocular_vision.dart  # 视功能专项
│   │   │   ├── amblyopia_screening.dart # 儿童弱视
│   │   │   └── asthenopia_assessment.dart # 视疲劳
│   │   ├── app_constants.dart         # 应用常量
│   │   └── errors.dart                # 错误定义
│   ├── theme/
│   │   ├── app_theme.dart             # 主题配置
│   │   └── app_colors.dart            # 颜色定义
│   └── utils/
│       ├── validators.dart            # 输入验证
│       └── extensions.dart            # 扩展方法
├── data/
│   ├── models/
│   │   ├── patient.dart               # 患者模型
│   │   ├── exam_record.dart           # 检查记录
│   │   ├── indicator_value.dart       # 指标值
│   │   └── analysis_result.dart       # 分析结果
│   ├── database/
│   │   ├── database_helper.dart       # 数据库帮助类
│   │   └── tables/                    # 表定义
│   └── repositories/
│       ├── patient_repository.dart
│       └── exam_repository.dart
├── domain/
│   ├── entities/                      # 领域实体
│   ├── services/
│   │   ├── ocr_service.dart           # OCR识别
│   │   ├── pdf_service.dart           # PDF生成
│   │   └── analysis_service.dart      # 分析引擎
│   └── usecases/
│       ├── analyze_exam.dart          # 分析检查
│       ├── generate_report.dart       # 生成报告
│       └── export_pdf.dart            # 导出PDF
├── presentation/
│   ├── pages/
│   │   ├── home_page.dart             # 首页
│   │   ├── exam_type_selection_page.dart # 检查类型选择
│   │   ├── data_entry_page.dart       # 数据录入
│   │   ├── camera_scan_page.dart      # 拍照识别
│   │   ├── analysis_report_page.dart  # 分析报告
│   │   ├── patient_list_page.dart     # 患者列表
│   │   ├── patient_detail_page.dart   # 患者详情
│   │   └── settings_page.dart         # 设置
│   ├── widgets/
│   │   ├── indicator_input.dart       # 指标输入组件
│   │   ├── abnormal_badge.dart        # 异常标记
│   │   ├── analysis_card.dart         # 分析卡片
│   │   └── chart_widgets.dart         # 图表组件
│   └── providers/
│       ├── exam_provider.dart         # 检查状态
│       ├── patient_provider.dart      # 患者状态
│       └── settings_provider.dart     # 设置状态
└── main.dart
```

---

## 4. 数据模型

### 4.1 患者模型

```dart
class Patient {
  final String id;                      // UUID
  final String name;                    // 姓名
  final int age;                        // 年龄
  final String gender;                  // 性别
  final String? phone;                  // 电话（可选）
  final String? note;                   // 备注（可选）
  final DateTime createdAt;             // 创建时间
  final DateTime updatedAt;             // 更新时间
  final List<ExamRecord> examRecords;   // 检查记录列表
}
```

### 4.2 检查记录模型

```dart
class ExamRecord {
  final String id;                      // UUID
  final String patientId;               // 关联患者ID
  final ExamType examType;              // 检查类型
  final DateTime examDate;              // 检查日期
  final DateTime createdAt;             // 记录创建时间
  
  // 基础信息
  final BasicInfo basicInfo;            // 基础信息
  
  // 各项指标数据（根据检查类型，部分可能为空）
  final VisualAcuityData? visualAcuity;     // 视力
  final RefractionData? refraction;         // 屈光度
  final IOPData? iop;                       // 眼压
  final AccommodationData? accommodation;   // 调节功能
  final ConvergenceData? convergence;       // 集合功能
  final FusionData? fusion;                 // 融像功能
  final StereopsisData? stereopsis;         // 立体视
  final EyeMovementData? eyeMovement;       // 眼球运动
  
  // 分析结果
  final AnalysisResult? analysisResult;     // 分析结果（分析后填充）
  
  // 报告相关
  final String? pdfPath;                    // PDF文件路径
  final bool isDraft;                       // 是否草稿
}

enum ExamType {
  standardFullSet,      // 标准眼科全套
  binocularVision,      // 视功能专项
  amblyopiaScreening,   // 儿童弱视筛查
  asthenopiaAssessment, // 视疲劳评估
  custom,               // 自定义
}
```

### 4.3 指标标准定义

```dart
class IndicatorStandard {
  final String id;                      // 指标ID
  final String name;                    // 指标名称
  final String unit;                    // 单位
  final IndicatorType type;             // 指标类型
  final List<IndicatorRange> ranges;    // 分级范围定义
  final String description;             // 指标说明
  final bool isRequired;                // 是否必填
}

class IndicatorRange {
  final String level;                   // 级别：normal/mild/moderate/severe
  final double? minValue;               // 最小值（包含，null表示无下限）
  final double? maxValue;               // 最大值（包含，null表示无上限）
  final String interpretation;          // 医学解读
  final List<String> possibleCauses;    // 可能原因
  final List<String> recommendations;   // 处理建议
  final Color displayColor;             // 显示颜色
}

enum IndicatorType {
  numeric,      // 数值型
  text,         // 文本型
  option,       // 选项型
  boolean,      // 布尔型
}
```

### 4.4 分析结果模型

```dart
class AnalysisResult {
  final String examId;                      // 关联检查ID
  final DateTime analyzedAt;                // 分析时间
  final List<AbnormalIndicator> abnormalities; // 异常指标列表
  final String overallAssessment;           // 总体评估
  final List<String> keyFindings;           // 关键发现
  final List<String> comprehensiveSuggestions; // 综合建议
  final int totalIndicators;                // 总指标数
  final int abnormalCount;                  // 异常数
  final Map<String, int> abnormalByLevel;   // 各级别异常统计
}

class AbnormalIndicator {
  final String indicatorId;                 // 指标ID
  final String indicatorName;               // 指标名称
  final dynamic inputValue;                 // 输入值
  final String unit;                        // 单位
  final String level;                       // 异常级别
  final String interpretation;              // 医学解读
  final List<String> possibleCauses;        // 可能原因
  final List<String> recommendations;       // 处理建议
  final Color displayColor;                 // 显示颜色
}
```

---

## 5. 核心功能设计

### 5.1 检查类型与指标库

#### A. 标准眼科全套（Standard Full Set）
包含以下指标组：

**基础视力检查：**
- 裸眼视力（远/近）
- 矫正视力（远/近）
- 针孔视力

**屈光检查：**
- 球镜（右眼/左眼）
- 柱镜（右眼/左眼）
- 轴位（右眼/左眼）
- 等效球镜

**眼压检查：**
- 非接触眼压（右眼/左眼）

**调节功能：**
- 调节幅度（右眼/左眼）
- 调节灵活度（右眼/左眼）
- 调节反应（MEM法）
- 相对调节（NRA/PRA）
- 调节近点

**集合功能：**
- 集合近点（NPC）
- 远距水平隐斜
- 近距水平隐斜
- AC/A 比值

**融像功能：**
- 远距融像范围（BI/BO）
- 近距融像范围（BI/BO）

**立体视：**
- 立体视锐度

#### B. 视功能专项（Binocular Vision）
专注双眼视功能：
- 调节幅度
- 调节灵活度
- 调节反应
- 相对调节（NRA/PRA）
- 集合近点
- 远/近水平隐斜
- AC/A
- 远/近融像范围
- 立体视锐度

#### C. 儿童弱视筛查（Amblyopia Screening）
针对儿童特点：
- 视力检查
- 屈光检查
- 眼位检查（斜视）
- 眼球运动检查
- 抑制检查（Worth 4点）
- 立体视检查
- 注视性质

#### D. 视疲劳评估（Asthenopia Assessment）
视疲劳相关指标：
- 调节幅度
- 调节灵活度
- 集合近点
- 近距隐斜
- AC/A
- 近距融像范围
- 调节反应
- 问卷评估（可选）

### 5.2 指标标准库设计

指标标准采用 Dart 代码文件配置，便于版本管理和扩展：

```dart
// constants/indicator_standards/standard_full_set.dart

class StandardFullSetStandards {
  static List<IndicatorStandard> getStandards() {
    return [
      // 视力指标
      IndicatorStandard(
        id: 'va_far_uncorrected',
        name: '裸眼远视力',
        unit: '',
        type: IndicatorType.numeric,
        ranges: [
          IndicatorRange(
            level: 'normal',
            minValue: 1.0,
            maxValue: null,
            interpretation: '视力正常',
            possibleCauses: [],
            recommendations: ['继续保持良好用眼习惯'],
            displayColor: Colors.green,
          ),
          IndicatorRange(
            level: 'mild',
            minValue: 0.6,
            maxValue: 0.9,
            interpretation: '轻度视力下降',
            possibleCauses: ['屈光不正', '早期白内障', '轻度角膜病变'],
            recommendations: ['验光检查', '排除眼部器质性病变'],
            displayColor: Colors.yellow,
          ),
          // ... 其他级别
        ],
        description: '未矫正状态下的远距离视力',
        isRequired: true,
      ),
      // ... 其他指标
    ];
  }
}
```

### 5.3 分析引擎逻辑

```dart
class AnalysisEngine {
  // 根据检查类型获取对应的标准库
  List<IndicatorStandard> getStandardsForType(ExamType type) {
    switch (type) {
      case ExamType.standardFullSet:
        return StandardFullSetStandards.getStandards();
      case ExamType.binocularVision:
        return BinocularVisionStandards.getStandards();
      // ... 其他类型
    }
  }
  
  // 执行分析
  AnalysisResult analyze(ExamRecord record) {
    final standards = getStandardsForType(record.examType);
    final abnormalities = <AbnormalIndicator>[];
    
    for (final standard in standards) {
      final value = record.getIndicatorValue(standard.id);
      if (value == null) continue; // 跳过未填写的指标
      
      final abnormal = checkIndicator(standard, value);
      if (abnormal != null) {
        abnormalities.add(abnormal);
      }
    }
    
    return AnalysisResult(
      examId: record.id,
      analyzedAt: DateTime.now(),
      abnormalities: abnormalities,
      overallAssessment: generateOverallAssessment(abnormalities),
      keyFindings: extractKeyFindings(abnormalities),
      comprehensiveSuggestions: generateSuggestions(abnormalities),
      totalIndicators: standards.length,
      abnormalCount: abnormalities.length,
      abnormalByLevel: countByLevel(abnormalities),
    );
  }
  
  // 检查单个指标
  AbnormalIndicator? checkIndicator(IndicatorStandard standard, dynamic value) {
    for (final range in standard.ranges) {
      if (isValueInRange(value, range)) {
        if (range.level == 'normal') return null;
        
        return AbnormalIndicator(
          indicatorId: standard.id,
          indicatorName: standard.name,
          inputValue: value,
          unit: standard.unit,
          level: range.level,
          interpretation: range.interpretation,
          possibleCauses: range.possibleCauses,
          recommendations: range.recommendations,
          displayColor: range.displayColor,
        );
      }
    }
    return null;
  }
}
```

### 5.4 OCR 拍照识别流程

```
1. 用户点击"拍照录入"
   ↓
2. 调用相机拍照（支持裁剪、旋转）
   ↓
3. 图片预处理（去噪、增强对比度）
   ↓
4. 调用OCR API（百度AI/腾讯云）
   ↓
5. 解析识别结果，提取关键数据
   ↓
6. 匹配到对应指标，自动填充表单
   ↓
7. 用户确认/修正识别结果
   ↓
8. 保存数据
```

**OCR 服务集成：**

```dart
class OCRService {
  final String apiKey;
  final String secretKey;
  
  // 识别检查单
  Future<Map<String, dynamic>> recognizeExamSheet(String imagePath) async {
    // 1. 获取Access Token
    final token = await getAccessToken();
    
    // 2. 调用OCR API
    final response = await http.post(
      Uri.parse('https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'access_token': token,
        'image': base64Encode(File(imagePath).readAsBytesSync()),
      },
    );
    
    // 3. 解析结果
    final result = jsonDecode(response.body);
    return parseExamData(result);
  }
  
  // 解析检查单数据（根据模板匹配）
  Map<String, dynamic> parseExamData(Map<String, dynamic> ocrResult) {
    final words = ocrResult['words_result'] as List;
    final Map<String, dynamic> extracted = {};
    
    // 根据关键词匹配提取数据
    for (final word in words) {
      final text = word['words'] as String;
      // 匹配视力：VA、视力、Vision 等关键词
      // 匹配屈光度：SPH、球镜、DS 等关键词
      // ...
    }
    
    return extracted;
  }
}
```

### 5.5 PDF 报告生成

**报告模板设计：**

```dart
class PDFService {
  Future<String> generateReport(ExamRecord record) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(record),
          _buildPatientInfo(record),
          _buildExamSummary(record),
          _buildIndicatorsTable(record),
          _buildAbnormalAnalysis(record),
          _buildRecommendations(record),
          _buildFooter(),
        ],
      ),
    );
    
    // 保存文件
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/report_${record.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }
  
  pw.Widget _buildHeader(ExamRecord record) {
    return pw.Header(
      level: 0,
      child: pw.Text(
        '视功能检查分析报告',
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
      ),
    );
  }
  
  pw.Widget _buildIndicatorsTable(ExamRecord record) {
    return pw.Table.fromTextArray(
      headers: ['指标名称', '右眼', '左眼', '单位', '结果'],
      data: record.getIndicatorsList().map((indicator) {
        return [
          indicator.name,
          indicator.odValue ?? '-',
          indicator.osValue ?? '-',
          indicator.unit,
          indicator.statusLabel,
        ];
      }).toList(),
    );
  }
  
  // ... 其他构建方法
}
```

---

## 6. UI/UX 设计

### 6.1 页面流程

```
启动
 ↓
首页
 ├─ 新建检查 ──→ 选择检查类型 ──→ 数据录入方式 ──→ 手动录入/拍照识别
 │                                                      ↓
 │                                              填写/确认数据
 │                                                      ↓
 │                                              分析报告页
 │                                                      │
 │                      ├─ 保存为草稿                    │
 │                      ├─ 生成报告 ──→ PDF预览/导出    │
 │                      └─ 关联患者（可选）               │
 │
 └─ 患者列表 ──→ 患者详情 ──→ 历史记录 ──→ 对比分析
        ↓
   搜索/筛选
```

### 6.2 关键页面说明

**1. 首页**
- Logo + 应用名称
- 大按钮：新建检查
- 次要按钮：查看患者列表
- 最近检查记录快捷入口

**2. 检查类型选择页**
- 卡片式布局展示4种检查类型
- 每种类型显示：名称、描述、预计时间、包含指标数
- 自定义选项

**3. 数据录入页**
- 分组标签页切换（基础/视力/屈光/调节/集合/融像）
- 每项指标：名称 + 输入框 + 单位 + 帮助提示
- 右眼/左眼并排输入
- 底部浮动按钮：保存草稿 / 开始分析

**4. 分析报告页**
- 顶部：检查日期、患者信息
- 总体评估卡片：正常/轻度/中度/重度统计
- 异常指标列表：颜色标记 + 展开查看详情
- 关键发现总结
- 处理建议列表
- 操作按钮：导出PDF / 分享 / 关联患者

**5. 患者列表页**
- 搜索框
- 患者卡片列表：姓名、年龄、上次检查时间、检查次数
- 点击进入详情

**6. 患者详情页**
- 患者基本信息
- 历史检查记录时间轴
- 趋势图表（关键指标变化曲线）
- 新建检查按钮

### 6.3 设计规范

**颜色系统：**
- 主色：医疗蓝 `#1976D2`
- 成功/正常：绿色 `#4CAF50`
- 警告/轻度：黄色 `#FFC107`
- 警告/中度：橙色 `#FF9800`
- 危险/重度：红色 `#F44336`
- 背景：浅灰 `#F5F5F5`
- 文字：深灰 `#212121` / 中灰 `#757575`

**字体：**
- 标题：18-24sp，加粗
- 正文：14-16sp
- 辅助文字：12sp

**间距：**
- 页面边距：16dp
- 卡片内边距：16dp
- 元素间距：8-12dp

---

## 7. 数据存储

### 7.1 SQLite 数据库设计

**表结构：**

```sql
-- 患者表
CREATE TABLE patients (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    age INTEGER,
    gender TEXT,
    phone TEXT,
    note TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 检查记录表
CREATE TABLE exam_records (
    id TEXT PRIMARY KEY,
    patient_id TEXT,
    exam_type TEXT NOT NULL,
    exam_date INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    is_draft INTEGER DEFAULT 0,
    pdf_path TEXT,
    FOREIGN KEY (patient_id) REFERENCES patients(id)
);

-- 指标数据表（存储所有指标值）
CREATE TABLE indicator_values (
    id TEXT PRIMARY KEY,
    exam_id TEXT NOT NULL,
    indicator_id TEXT NOT NULL,
    od_value TEXT,
    os_value TEXT,
    FOREIGN KEY (exam_id) REFERENCES exam_records(id)
);

-- 分析结果表
CREATE TABLE analysis_results (
    id TEXT PRIMARY KEY,
    exam_id TEXT NOT NULL UNIQUE,
    analyzed_at INTEGER NOT NULL,
    overall_assessment TEXT,
    key_findings TEXT, -- JSON
    comprehensive_suggestions TEXT, -- JSON
    total_indicators INTEGER,
    abnormal_count INTEGER,
    FOREIGN KEY (exam_id) REFERENCES exam_records(id)
);

-- 异常指标详情表
CREATE TABLE abnormal_indicators (
    id TEXT PRIMARY KEY,
    analysis_id TEXT NOT NULL,
    indicator_id TEXT NOT NULL,
    indicator_name TEXT NOT NULL,
    input_value TEXT,
    unit TEXT,
    level TEXT NOT NULL,
    interpretation TEXT,
    possible_causes TEXT, -- JSON
    recommendations TEXT, -- JSON
    FOREIGN KEY (analysis_id) REFERENCES analysis_results(id)
);
```

---

## 8. 错误处理与边界情况

### 8.1 输入验证

- **空值处理**：必填项未填写时提示，选填项允许为空
- **数值范围验证**：防止输入不合理的数值（如视力 > 2.0）
- **格式验证**：屈光度格式、日期格式等
- **逻辑验证**：右眼/左眼数据一致性检查

### 8.2 OCR 识别失败

- 识别失败时提示用户
- 提供手动录入入口
- 允许重新拍照

### 8.3 网络异常

- OCR 服务调用失败时提示
- PDF 生成失败时提示并允许重试
- 离线状态下仅支持本地功能

### 8.4 数据安全

- 患者数据本地存储，不上传云端
- 导出 PDF 时提示隐私保护
- 定期备份提醒

---

## 9. 技能清单

在开发过程中，以下技能可用于辅助：

**核心开发：**
- `jeffallan/claude-skills@flutter-expert` - Flutter 专家技能
- `madteacher/mad-agents-skills@flutter-architecture` - 架构设计
- `alinaqi/claude-bootstrap@flutter` - 项目启动

**功能实现：**
- `anthropics/skills@pdf` - PDF 生成处理
- `letta-ai/skills@code-from-image` - OCR 实现参考

**测试：**
- `madteacher/mad-agents-skills@flutter-testing` - Flutter 测试
- `aj-geddes/useful-ai-prompts@mobile-app-testing` - 移动应用测试

**设计：**
- `majiayu000/claude-arsenal@app-ui-design` - App UI 设计
- `madteacher/mad-agents-skills@flutter-adaptive-ui` - 自适应UI

**计划：**
- `writing-plans` - 创建详细实施计划

---

## 10. 后续步骤

1. **调用 `writing-plans` 技能** - 创建详细的实施计划
2. **初始化 Flutter 项目** - 使用 `flutter create` 创建项目
3. **安装必要技能** - 安装 Flutter 相关技能
4. **迭代开发** - 按模块逐步实现功能
5. **测试与优化** - 编写测试用例，优化用户体验

---

**文档版本：** v1.0  
**最后更新：** 2026-02-17
