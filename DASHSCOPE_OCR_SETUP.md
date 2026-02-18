# DashScope OCR 配置说明

## 概述
本项目已集成DashScope大模型OCR服务，支持手写体眼科检查单的智能识别。

## 配置方法

### 方法1：环境变量（推荐桌面端/后端）
```bash
export DASHSCOPE_API_KEY="your-api-key-here"
```

### 方法2：配置文件（推荐移动端）
1. 编辑 `assets/config/.env` 文件
2. 替换API Key：
```
DASHSCOPE_API_KEY=your-actual-api-key-here
```

## 获取API Key
1. 访问 [DashScope控制台](https://dashscope.aliyun.com/)
2. 注册/登录阿里云账号
3. 创建API Key
4. 复制Key到配置中

## 使用方法

### 基本使用
```dart
import 'lib/domain/services/ocr_service.dart';

final ocrService = OCRService();

// 使用DashScope识别
final result = await ocrService.recognizeMedicalReport(
  imagePath,
  provider: 'dashscope',
);

if (result.success) {
  print('识别结果: ${result.structuredData}');
} else {
  print('识别失败: ${result.errorMessage}');
}
```

### 直接使用DashScope方法
```dart
final result = await ocrService.recognizeWithDashScope(imagePath);
```

## 支持的检查类型
1. **标准眼科全套**：视力、屈光度、眼压
2. **视功能专项**：调节、集合、AC/A等
3. **儿童弱视筛查**：视力、屈光、眼位
4. **视疲劳评估**：调节、集合相关

## 返回数据格式
```json
{
  "patient_info": {
    "age": 18,
    "gender": "男"
  },
  "standard_full_set": {
    "va_uncorrected_od": 0.5,
    "va_uncorrected_os": 0.6,
    "sph_od": -3.00,
    "sph_os": -3.50,
    "cyl_od": -0.50,
    "cyl_os": -0.25,
    "iop_od": 16,
    "iop_os": 15
  },
  "binocular_vision": {
    "distance_phoria": -13,
    "near_phoria": -2,
    "aca_ratio": 8,
    "npc": 6,
    "nra": 2.25,
    "pra": -2.25,
    "amp_od": 12,
    "amp_os": 12
  }
}
```

## 故障排除

### API Key未配置
错误信息：`DashScope API Key未配置`
- 检查环境变量或配置文件
- 确认Key格式正确

### 401错误
- API Key无效或已过期
- 检查阿里云账户余额

### 429错误
- 请求过于频繁
- 稍后重试或升级服务套餐

## 模型信息
- **模型**: qwen-vl-max
- **提供商**: 阿里云DashScope
- **支持**: 手写体 + 印刷体
