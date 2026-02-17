# 视功能分析App - API接口文档

## M1里程碑后端功能完成

---

## 1. 数据仓库层 (Repository Layer)

### 1.1 PatientRepository

**文件位置**: `lib/data/repositories/patient_repository.dart`

#### 方法列表

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `createPatient` | name, age, gender, phone?, note? | `Future<Patient>` | 创建新患者 |
| `getPatientById` | id: String | `Future<Patient?>` | 根据ID获取患者 |
| `getAllPatients` | searchQuery?: String | `Future<List<Patient>>` | 获取所有患者（支持搜索） |
| `updatePatient` | id, name?, age?, gender?, phone?, note? | `Future<Patient>` | 更新患者信息 |
| `deletePatient` | id: String | `Future<void>` | 删除患者及关联检查记录 |
| `searchPatients` | query: String | `Future<List<Patient>>` | 搜索患者 |
| `getPatientCount` | - | `Future<int>` | 获取患者总数 |

#### 使用示例

```dart
final patientRepo = PatientRepository();

// 创建患者
final patient = await patientRepo.createPatient(
  name: '张三',
  age: 25,
  gender: '男',
  phone: '13800138000',
);

// 获取患者列表
final patients = await patientRepo.getAllPatients(searchQuery: '张');
```

---

### 1.2 ExamRepository

**文件位置**: `lib/data/repositories/exam_repository.dart`

#### 方法列表

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `createExam` | patientId?, examType, examDate, indicatorValues?, isDraft? | `Future<ExamRecord>` | 创建检查记录 |
| `getExamById` | id: String | `Future<ExamRecord?>` | 根据ID获取检查记录 |
| `getExamsByPatientId` | patientId: String | `Future<List<ExamRecord>>` | 获取患者的所有检查记录 |
| `getAllExams` | isDraft?: bool | `Future<List<ExamRecord>>` | 获取所有检查记录 |
| `updateExam` | id, patientId?, examType?, examDate?, indicatorValues?, isDraft?, pdfPath? | `Future<ExamRecord>` | 更新检查记录 |
| `deleteExam` | id: String | `Future<void>` | 删除检查记录 |
| `getDraftCount` | - | `Future<int>` | 获取草稿数量 |
| `getExamCount` | - | `Future<int>` | 获取检查记录总数 |

#### 使用示例

```dart
final examRepo = ExamRepository();

// 创建检查记录
final exam = await examRepo.createExam(
  patientId: 'patient-uuid',
  examType: ExamType.standardFullSet,
  examDate: DateTime.now(),
  indicatorValues: {
    'vision_right': '1.0',
    'vision_left': '0.8',
  },
);

// 获取患者的检查记录
final exams = await examRepo.getExamsByPatientId('patient-uuid');
```

---

## 2. 服务层 (Service Layer)

### 2.1 OCRService

**文件位置**: `lib/domain/services/ocr_service.dart`

#### 功能说明
支持百度AI OCR和腾讯云OCR两种识别引擎，可自动识别检查单并提取结构化数据。

#### 方法列表

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `recognizeMedicalReport` | imagePath, provider?: 'baidu'\|'tencent' | `Future<OCRResult>` | 识别医疗检查单 |
| `configureBaiduOCR` | apiKey, secretKey | `void` | 配置百度OCR |
| `configureTencentOCR` | secretId, secretKey | `void` | 配置腾讯云OCR |

#### OCRResult 结构

```dart
class OCRResult {
  final bool success;           // 识别是否成功
  final String? text;           // 识别的完整文本
  final Map<String, dynamic>? structuredData;  // 结构化数据
  final String? errorMessage;   // 错误信息
}
```

#### 支持识别的字段

- `vision_right` / `vision_left` - 视力
- `sph_right` / `sph_left` - 球镜度数
- `cyl_right` / `cyl_left` - 柱镜度数
- `axis_right` / `axis_left` - 轴位
- `pd` - 瞳距
- `iop_right` / `iop_left` - 眼压

#### 使用示例

```dart
final ocrService = OCRService();

// 配置API密钥（实际应从安全存储读取）
ocrService.configureBaiduOCR(
  apiKey: 'YOUR_API_KEY',
  secretKey: 'YOUR_SECRET_KEY',
);

// 识别图片
final result = await ocrService.recognizeMedicalReport(
  '/path/to/image.jpg',
  provider: 'baidu',
);

if (result.success) {
  print('识别文本: ${result.text}');
  print('视力数据: ${result.structuredData?['vision_right']}');
} else {
  print('识别失败: ${result.errorMessage}');
}
```

---

### 2.2 PDFService

**文件位置**: `lib/domain/services/pdf_service.dart`

#### 功能说明
生成专业的视功能分析PDF报告，包含患者信息、检查数据、分析结论和建议。

#### 方法列表

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `exportToPDF` | patient, examRecord, analysisResults, outputPath? | `Future<String>` | 导出PDF报告 |
| `sharePDF` | filePath: String | `Future<void>` | 分享PDF文件 |
| `getAllReports` | - | `Future<List<File>>` | 获取所有报告列表 |
| `deleteReport` | filePath: String | `Future<void>` | 删除报告 |

#### 使用示例

```dart
final pdfService = PDFService();

// 生成PDF报告
final pdfPath = await pdfService.exportToPDF(
  patient: patient,
  examRecord: examRecord,
  analysisResults: {
    'indicators': [...],
    'conclusions': [...],
    'recommendations': [...],
  },
);

print('PDF已生成: $pdfPath');

// 获取所有报告
final reports = await pdfService.getAllReports();
```

---

## 3. 用例层 (UseCase Layer)

### 3.1 患者管理用例

**文件位置**: `lib/domain/usecases/manage_patients.dart`

#### CreatePatientUseCase - 创建患者

```dart
final useCase = CreatePatientUseCase();
final patient = await useCase.execute(
  name: '张三',
  age: 25,
  gender: '男',
  phone: '13800138000',
  note: '首次检查',
);
```

#### GetPatientListUseCase - 获取患者列表

```dart
final useCase = GetPatientListUseCase();
final patients = await useCase.execute(searchQuery: '张');
```

#### GetPatientDetailUseCase - 获取患者详情

```dart
final useCase = GetPatientDetailUseCase();
final patient = await useCase.execute('patient-uuid');
```

#### UpdatePatientUseCase - 更新患者信息

```dart
final useCase = UpdatePatientUseCase();
final patient = await useCase.execute(
  'patient-uuid',
  phone: '13900139000',
  note: '已更新联系方式',
);
```

#### DeletePatientUseCase - 删除患者

```dart
final useCase = DeletePatientUseCase();
await useCase.execute('patient-uuid');
```

#### SearchPatientsUseCase - 搜索患者

```dart
final useCase = SearchPatientsUseCase();
final patients = await useCase.execute('张三');
```

#### PatientUseCases - 用例组合类

```dart
final useCases = PatientUseCases();

// 使用各种用例
final patient = await useCases.createPatient.execute(...);
final patients = await useCases.getPatientList.execute();
await useCases.deletePatient.execute('patient-uuid');
```

---

### 3.2 报告生成用例

**文件位置**: `lib/domain/usecases/generate_report.dart`

#### GeneratePDFReportUseCase - 生成PDF报告

```dart
final useCase = GeneratePDFReportUseCase();

// 生成单份报告
final pdfPath = await useCase.execute(
  patientId: 'patient-uuid',
  examId: 'exam-uuid',
);

// 批量生成报告
final paths = await useCase.executeBatch(
  patientId: 'patient-uuid',
  examIds: ['exam-1', 'exam-2', 'exam-3'],
);
```

#### ReportUseCases - 用例组合类

```dart
final useCases = ReportUseCases();
final pdfPath = await useCases.generatePDFReport.execute(
  patientId: 'patient-uuid',
  examId: 'exam-uuid',
);
```

---

## 4. 数据模型

### 4.1 Patient 模型

```dart
class Patient {
  final String id;           // UUID
  final String name;         // 姓名
  final int age;             // 年龄
  final String gender;       // 性别
  final String? phone;       // 电话
  final String? note;        // 备注
  final DateTime createdAt;  // 创建时间
  final DateTime updatedAt;  // 更新时间
}
```

### 4.2 ExamRecord 模型

```dart
class ExamRecord {
  final String id;                    // UUID
  final String? patientId;            // 关联患者ID
  final ExamType examType;            // 检查类型
  final DateTime examDate;            // 检查日期
  final DateTime createdAt;           // 创建时间
  final bool isDraft;                 // 是否为草稿
  final String? pdfPath;              // PDF文件路径
  final Map<String, dynamic>? indicatorValues;  // 指标值
}
```

### 4.3 ExamType 枚举

```dart
enum ExamType {
  standardFullSet,      // 全套视功能检查
  binocularVision,      // 双眼视功能检查
  amblyopiaScreening,   // 弱视筛查
  asthenopiaAssessment, // 视疲劳评估
  custom,               // 自定义检查
}
```

---

## 5. 错误处理

所有仓库和用例都包含错误处理机制：

```dart
try {
  final patient = await patientRepo.createPatient(...);
} catch (e) {
  // 处理错误
  print('创建患者失败: $e');
}
```

### 常见错误类型

- `ArgumentError` - 参数验证失败
- `Exception` - 业务逻辑错误（如记录不存在）
- 数据库操作错误

---

## 6. 单例模式

所有Repository和Service类都使用单例模式：

```dart
// 获取单例实例
final patientRepo = PatientRepository();
final examRepo = ExamRepository();
final ocrService = OCRService();
final pdfService = PDFService();
```

---

## 7. 依赖关系

```
presentation/
  └── 调用 usecases/
      └── 调用 repositories/ 和 services/
          └── 调用 database/
```

---

## 8. 注意事项

1. **API密钥安全**: OCR服务的API密钥应存储在安全的地方（如环境变量或安全存储），不应硬编码在代码中。

2. **文件权限**: PDF导出需要文件系统权限，确保在AndroidManifest.xml和Info.plist中配置相应权限。

3. **数据库迁移**: 如果修改了数据模型，需要处理数据库版本升级。

4. **错误日志**: 所有错误都会通过`dart:developer`的log函数记录，便于调试。

---

## 9. 文件清单

### 新建文件
- `lib/data/repositories/patient_repository.dart`
- `lib/data/repositories/exam_repository.dart`
- `lib/domain/services/ocr_service.dart`
- `lib/domain/services/pdf_service.dart`
- `lib/domain/usecases/manage_patients.dart`
- `lib/domain/usecases/generate_report.dart`
- `docs/api_documentation.md` (本文档)

### 现有文件
- `lib/data/models/patient.dart`
- `lib/data/database/database_helper.dart`
- `lib/domain/services/analysis_service.dart`

---

**文档版本**: 1.0  
**最后更新**: 2026-02-17  
**里程碑**: M1 - 核心功能完善
