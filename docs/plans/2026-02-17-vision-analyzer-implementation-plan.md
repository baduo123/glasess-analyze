# 视功能自动分析App实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 使用 Flutter 开发一款支持手动录入和拍照识别的视功能分析App，自动生成专业分析报告

**Architecture:** 采用分层架构（Presentation/Business Logic/Data），支持多检查类型模板，指标标准库存储在 Dart 文件中便于管理，使用 SQLite 本地存储患者数据和检查记录

**Tech Stack:** Flutter 3.x + Dart, Riverpod 状态管理, SQLite 本地数据库, 百度AI OCR, pdf 插件

---

## 前置准备

### Task 0: 安装必要技能

**Files:**
- 安装: `jeffallan/claude-skills@flutter-expert`
- 安装: `madteacher/mad-agents-skills@flutter-architecture`

**Step 1: 安装 Flutter 专家技能**

```bash
npx skills add jeffallan/claude-skills@flutter-expert -g -y
```

**Step 2: 安装 Flutter 架构技能**

```bash
npx skills add madteacher/mad-agents-skills@flutter-architecture -g -y
```

**Step 3: 验证安装**

运行：
```bash
npx skills list
```

预期：显示已安装的技能列表包含 flutter-expert 和 flutter-architecture

---

## 第一阶段：项目初始化

### Task 1: 创建 Flutter 项目

**Files:**
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/pubspec.yaml`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/main.dart`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/android/app/build.gradle`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/ios/Runner/Info.plist`

**Step 1: 创建 Flutter 项目**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
flutter create --org com.vision --project-name vision_analyzer .
```

预期输出：
```
Creating project ....
  .gitignore (created)
  pubspec.yaml (created)
  ...
Running "flutter pub get"...
Wrote 127 files.
All done!
```

**Step 2: 验证项目结构**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && ls -la
```

预期输出：包含 lib/, android/, ios/, pubspec.yaml 等目录

**Step 3: 运行初始项目测试**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter test
```

预期：测试通过

**Step 4: 提交初始项目**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git init
git add .
git commit -m "Initial Flutter project setup"
```

---

### Task 2: 配置依赖项

**Files:**
- Modify: `/Users/wanlongyi/project/vibe_project/glasess-analyze/pubspec.yaml`

**Step 1: 添加核心依赖**

修改 pubspec.yaml，添加依赖项：

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  
  # 状态管理
  flutter_riverpod: ^2.4.9
  
  # 数据库
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # PDF 生成
  pdf: ^3.10.7
  printing: ^5.11.1
  
  # 网络请求（OCR API）
  http: ^1.1.0
  
  # 相机和图像
  image_picker: ^1.0.7
  image_cropper: ^5.0.1
  
  # 工具
  uuid: ^4.2.2
  intl: ^0.18.1
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
```

**Step 2: 获取依赖**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter pub get
```

预期：所有依赖下载成功

**Step 3: 提交**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git add pubspec.yaml
git commit -m "Add core dependencies"
```

---

## 第二阶段：核心模型与数据层

### Task 3: 创建核心数据模型

**Files:**
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/data/models/patient.dart`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/data/models/exam_record.dart`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/data/models/indicator_standard.dart`

**Step 1: 创建患者模型**

```dart
// lib/data/models/patient.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'patient.freezed.dart';
part 'patient.g.dart';

@freezed
class Patient with _$Patient {
  const factory Patient({
    required String id,
    required String name,
    required int age,
    required String gender,
    String? phone,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Patient;

  factory Patient.fromJson(Map<String, Object?> json) =>
      _$PatientFromJson(json);
}
```

**Step 2: 创建检查记录模型**

```dart
// lib/data/models/exam_record.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam_record.freezed.dart';
part 'exam_record.g.dart';

enum ExamType {
  standardFullSet,
  binocularVision,
  amblyopiaScreening,
  asthenopiaAssessment,
  custom,
}

@freezed
class ExamRecord with _$ExamRecord {
  const factory ExamRecord({
    required String id,
    String? patientId,
    required ExamType examType,
    required DateTime examDate,
    required DateTime createdAt,
    @Default(false) bool isDraft,
    String? pdfPath,
    Map<String, dynamic>? indicatorValues,
  }) = _ExamRecord;

  factory ExamRecord.fromJson(Map<String, Object?> json) =>
      _$ExamRecordFromJson(json);
}
```

**Step 3: 生成代码**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter pub run build_runner build --delete-conflicting-outputs
```

预期：生成 patient.freezed.dart, patient.g.dart 等文件

**Step 4: 提交**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git add lib/data/models/
git commit -m "Add core data models with freezed"
```

---

### Task 4: 创建 SQLite 数据库

**Files:**
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/data/database/database_helper.dart`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/test/data/database/database_helper_test.dart`

**Step 1: 编写数据库帮助类**

```dart
// lib/data/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vision_analyzer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';
    const integerNullable = 'INTEGER';

    await db.execute('''
      CREATE TABLE patients (
        id $idType,
        name $textType,
        age $integerNullable,
        gender $textNullable,
        phone $textNullable,
        note $textNullable,
        created_at $integerType,
        updated_at $integerType
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_records (
        id $idType,
        patient_id $textNullable,
        exam_type $textType,
        exam_date $integerType,
        created_at $integerType,
        is_draft $integerType DEFAULT 0,
        pdf_path $textNullable,
        indicator_values $textNullable,
        FOREIGN KEY (patient_id) REFERENCES patients(id)
      )
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
```

**Step 2: 编写测试**

```dart
// test/data/database/database_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/data/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    test('should create database instance', () async {
      final db = await DatabaseHelper.instance.database;
      expect(db, isNotNull);
      expect(db.isOpen, true);
    });

    test('should create tables', () async {
      final db = await DatabaseHelper.instance.database;
      
      // 验证表是否存在
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toList();
      expect(tableNames, contains('patients'));
      expect(tableNames, contains('exam_records'));
    });
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });
}
```

**Step 3: 添加测试依赖**

在 pubspec.yaml 的 dev_dependencies 中添加：
```yaml
dev_dependencies:
  sqflite_common_ffi: ^2.3.2
```

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter pub get
```

**Step 4: 运行测试**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter test test/data/database/database_helper_test.dart
```

预期：测试通过

**Step 5: 提交**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git add lib/data/database/ test/data/database/
git commit -m "Add SQLite database helper with tests"
```

---

## 第三阶段：指标标准库

### Task 5: 创建视功能指标标准库

**Files:**
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/core/constants/indicator_standards/indicator_standard_model.dart`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/core/constants/indicator_standards/standard_full_set.dart`

**Step 1: 创建指标标准模型**

```dart
// lib/core/constants/indicator_standards/indicator_standard_model.dart
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
```

**Step 2: 创建标准全套指标库**

```dart
// lib/core/constants/indicator_standards/standard_full_set.dart
import 'package:flutter/material.dart';
import 'indicator_standard_model.dart';

class StandardFullSetStandards {
  static List<IndicatorStandard> getStandards() {
    return [
      // 视力指标 - 裸眼远视力
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
      
      // 调节幅度
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
      
      // 添加更多指标...
    ];
  }
}
```

**Step 3: 提交**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git add lib/core/constants/
git commit -m "Add indicator standards model and standard full set"
```

---

## 第四阶段：分析引擎

### Task 6: 创建分析引擎

**Files:**
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/domain/services/analysis_service.dart`
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/test/domain/services/analysis_service_test.dart`

**Step 1: 编写分析服务**

```dart
// lib/domain/services/analysis_service.dart
import '../../core/constants/indicator_standards/indicator_standard_model.dart';
import '../../data/models/exam_record.dart';

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
```

**Step 2: 编写测试**

```dart
// test/domain/services/analysis_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vision_analyzer/domain/services/analysis_service.dart';
import 'package:vision_analyzer/data/models/exam_record.dart';
import 'package:vision_analyzer/core/constants/indicator_standards/indicator_standard_model.dart';

void main() {
  group('AnalysisService', () {
    late AnalysisService analysisService;

    setUp(() {
      analysisService = AnalysisService();
    });

    test('should return empty abnormalities for normal values', () {
      final record = ExamRecord(
        id: 'test-1',
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 1.2,
          'amp_od': 10.0,
        },
      );

      final result = analysisService.analyze(record);

      expect(result.abnormalCount, 0);
      expect(result.abnormalities, isEmpty);
    });

    test('should detect mild abnormality', () {
      final record = ExamRecord(
        id: 'test-2',
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 0.8, // 轻度异常
        },
      );

      final result = analysisService.analyze(record);

      expect(result.abnormalCount, 1);
      expect(result.abnormalities.first.level, AbnormalLevel.mild);
    });

    test('should detect severe abnormality', () {
      final record = ExamRecord(
        id: 'test-3',
        examType: ExamType.standardFullSet,
        examDate: DateTime.now(),
        createdAt: DateTime.now(),
        indicatorValues: {
          'va_far_uncorrected_od': 0.1, // 重度异常
        },
      );

      final result = analysisService.analyze(record);

      expect(result.abnormalCount, 1);
      expect(result.abnormalities.first.level, AbnormalLevel.severe);
    });
  });
}
```

**Step 3: 运行测试**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter test test/domain/services/analysis_service_test.dart
```

预期：测试通过

**Step 4: 提交**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git add lib/domain/services/ test/domain/services/
git commit -m "Add analysis engine service with tests"
```

---

## 第五阶段：UI 界面

### Task 7: 创建首页

**Files:**
- Create: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/presentation/pages/home_page.dart`
- Modify: `/Users/wanlongyi/project/vibe_project/glasess-analyze/lib/main.dart`

**Step 1: 创建首页**

```dart
// lib/presentation/pages/home_page.dart
import 'package:flutter/material.dart';
import 'exam_type_selection_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视功能分析'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo 区域
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.visibility,
                size: 64,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 32),
            
            // 应用名称
            const Text(
              '视功能自动分析',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '专业视功能检查数据分析工具',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            
            // 新建检查按钮
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExamTypeSelectionPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                '新建检查',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 患者列表按钮
            OutlinedButton.icon(
              onPressed: () {
                // TODO: 导航到患者列表
              },
              icon: const Icon(Icons.people_outline),
              label: const Text(
                '患者列表',
                style: TextStyle(fontSize: 18),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 2: 创建检查类型选择页**

```dart
// lib/presentation/pages/exam_type_selection_page.dart
import 'package:flutter/material.dart';
import '../../data/models/exam_record.dart';
import 'data_entry_page.dart';

class ExamTypeSelectionPage extends StatelessWidget {
  const ExamTypeSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final examTypes = [
      _ExamTypeInfo(
        type: ExamType.standardFullSet,
        name: '标准眼科全套',
        description: '包含视力、屈光、眼压、调节、集合、融像等全套检查',
        icon: Icons.medical_services,
        color: Colors.blue,
        estimatedTime: '15-20分钟',
        indicatorCount: 25,
      ),
      _ExamTypeInfo(
        type: ExamType.binocularVision,
        name: '视功能专项',
        description: '专注双眼视功能评估，适合视疲劳和双眼视异常检查',
        icon: Icons.remove_red_eye,
        color: Colors.green,
        estimatedTime: '10-15分钟',
        indicatorCount: 15,
      ),
      _ExamTypeInfo(
        type: ExamType.amblyopiaScreening,
        name: '儿童弱视筛查',
        description: '针对儿童特点的检查组合，早期发现弱视',
        icon: Icons.child_care,
        color: Colors.orange,
        estimatedTime: '10分钟',
        indicatorCount: 12,
      ),
      _ExamTypeInfo(
        type: ExamType.asthenopiaAssessment,
        name: '视疲劳评估',
        description: '针对视疲劳相关指标的综合评估',
        icon: Icons.tired,
        color: Colors.purple,
        estimatedTime: '8-12分钟',
        indicatorCount: 10,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择检查类型'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请选择要进行的检查类型：',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: examTypes.length,
                itemBuilder: (context, index) {
                  final type = examTypes[index];
                  return _ExamTypeCard(
                    info: type,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DataEntryPage(examType: type.type),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamTypeInfo {
  final ExamType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String estimatedTime;
  final int indicatorCount;

  _ExamTypeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.estimatedTime,
    required this.indicatorCount,
  });
}

class _ExamTypeCard extends StatelessWidget {
  final _ExamTypeInfo info;
  final VoidCallback onTap;

  const _ExamTypeCard({
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          info.estimatedTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.format_list_numbered, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${info.indicatorCount}项指标',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 3: 更新 main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'presentation/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '视功能分析',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
```

**Step 4: 运行应用测试**

运行：
```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze && flutter run
```

预期：应用启动，显示首页界面

**Step 5: 提交**

```bash
cd /Users/wanlongyi/project/vibe_project/glasess-analyze
git add lib/presentation/pages/ lib/main.dart
git commit -m "Add home page and exam type selection page"
```

---

## 后续任务（简要说明）

### Task 8: 创建数据录入页
- 分组表单展示各指标
- 支持手动输入和拍照识别入口
- 实时数据校验

### Task 9: 集成 OCR 拍照识别
- 相机权限配置
- 图片裁剪和预处理
- 集成百度AI/腾讯云 OCR API

### Task 10: 创建分析报告页
- 展示所有指标结果
- 颜色标记异常
- 显示医学解读和建议

### Task 11: 实现 PDF 导出
- 生成专业格式 PDF
- 保存到本地并支持分享

### Task 12: 创建患者管理功能
- 患者列表、详情页
- 历史记录查看
- 趋势图表展示

### Task 13: 完善指标标准库
- 补充所有视功能指标
- 配置完整的正常值和异常分级

---

## 执行建议

**建议按以下顺序执行：**
1. 完成 Task 0-7（基础框架）
2. 每完成一个 Task 后运行 `flutter test` 确保测试通过
3. 在真机或模拟器上测试 UI 交互
4. 使用 `git commit` 频繁提交

**测试策略：**
- 单元测试：针对分析引擎、数据处理逻辑
- Widget 测试：针对核心 UI 组件
- 集成测试：针对完整用户流程

**下一步：** 调用 `superpowers:executing-plans` 技能逐任务执行此计划
