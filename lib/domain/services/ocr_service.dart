import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// OCR识别结果模型
class OCRResult {
  final bool success;
  final String? text;
  final Map<String, dynamic>? structuredData;
  final String? errorMessage;

  OCRResult({
    required this.success,
    this.text,
    this.structuredData,
    this.errorMessage,
  });

  factory OCRResult.success({
    String? text,
    Map<String, dynamic>? structuredData,
  }) {
    return OCRResult(
      success: true,
      text: text,
      structuredData: structuredData,
    );
  }

  factory OCRResult.failure(String errorMessage) {
    return OCRResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// OCR服务类
/// 支持百度AI OCR和腾讯云OCR
class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  // 百度AI OCR配置（需要替换为实际的API Key和Secret Key）
  static const String _baiduApiKey = 'YOUR_BAIDU_API_KEY';
  static const String _baiduSecretKey = 'YOUR_BAIDU_SECRET_KEY';
  static const String _baiduTokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const String _baiduOcrUrl = 'https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic';
  static const String _baiduAccurateOcrUrl = 'https://aip.baidubce.com/rest/2.0/ocr/v1/accurate_basic';

  // 腾讯云OCR配置（需要替换为实际的SecretId和SecretKey）
  static const String _tencentSecretId = 'YOUR_TENCENT_SECRET_ID';
  static const String _tencentSecretKey = 'YOUR_TENCENT_SECRET_KEY';
  static const String _tencentOcrUrl = 'https://ocr.tencentcloudapi.com';

  String? _baiduAccessToken;
  DateTime? _tokenExpireTime;

  /// 识别检查单图片
  /// 
  /// [imagePath] - 图片文件路径
  /// [provider] - OCR提供商: 'baidu' 或 'tencent'
  Future<OCRResult> recognizeMedicalReport(String imagePath, {String provider = 'baidu'}) async {
    try {
      developer.log('开始OCR识别: $imagePath, 提供商: $provider');
      
      final file = File(imagePath);
      if (!await file.exists()) {
        return OCRResult.failure('图片文件不存在');
      }

      if (provider == 'baidu') {
        return await _recognizeWithBaidu(file);
      } else if (provider == 'tencent') {
        return await _recognizeWithTencent(file);
      } else {
        return OCRResult.failure('不支持的OCR提供商: $provider');
      }
    } catch (e, stackTrace) {
      developer.log('OCR识别失败', error: e, stackTrace: stackTrace);
      return OCRResult.failure('OCR识别失败: $e');
    }
  }

  /// 使用百度AI OCR识别
  Future<OCRResult> _recognizeWithBaidu(File imageFile) async {
    try {
      // 获取访问令牌
      final token = await _getBaiduAccessToken();
      if (token == null) {
        return OCRResult.failure('获取百度OCR访问令牌失败');
      }

      // 读取图片并转换为base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 调用百度OCR API
      final response = await http.post(
        Uri.parse('$_baiduAccurateOcrUrl?access_token=$token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'image': base64Image,
          'detect_direction': 'true',
          'probability': 'true',
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['error_code'] != null) {
          return OCRResult.failure('百度OCR错误: ${result['error_msg']}');
        }

        // 提取文本
        final wordsResult = result['words_result'] as List<dynamic>?;
        if (wordsResult == null || wordsResult.isEmpty) {
          return OCRResult.failure('未识别到文本内容');
        }

        final StringBuffer textBuffer = StringBuffer();
        for (final item in wordsResult) {
          textBuffer.writeln(item['words']);
        }

        final recognizedText = textBuffer.toString();
        
        // 解析结构化数据
        final structuredData = _parseMedicalReport(recognizedText);

        return OCRResult.success(
          text: recognizedText,
          structuredData: structuredData,
        );
      } else {
        return OCRResult.failure('百度OCR请求失败: ${response.statusCode}');
      }
    } catch (e) {
      return OCRResult.failure('百度OCR识别失败: $e');
    }
  }

  /// 使用腾讯云OCR识别
  Future<OCRResult> _recognizeWithTencent(File imageFile) async {
    try {
      // 读取图片并转换为base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 构建请求
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = jsonEncode({
        'ImageBase64': base64Image,
      });

      // 构建签名（简化版，实际生产环境需要完整的签名实现）
      final headers = await _buildTencentHeaders(payload, timestamp);

      final response = await http.post(
        Uri.parse(_tencentOcrUrl),
        headers: headers,
        body: payload,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['Response']['Error'] != null) {
          return OCRResult.failure('腾讯云OCR错误: ${result['Response']['Error']['Message']}');
        }

        final textDetections = result['Response']['TextDetections'] as List<dynamic>?;
        if (textDetections == null || textDetections.isEmpty) {
          return OCRResult.failure('未识别到文本内容');
        }

        final StringBuffer textBuffer = StringBuffer();
        for (final item in textDetections) {
          textBuffer.writeln(item['DetectedText']);
        }

        final recognizedText = textBuffer.toString();
        final structuredData = _parseMedicalReport(recognizedText);

        return OCRResult.success(
          text: recognizedText,
          structuredData: structuredData,
        );
      } else {
        return OCRResult.failure('腾讯云OCR请求失败: ${response.statusCode}');
      }
    } catch (e) {
      return OCRResult.failure('腾讯云OCR识别失败: $e');
    }
  }

  /// 获取百度访问令牌
  Future<String?> _getBaiduAccessToken() async {
    try {
      // 检查现有令牌是否有效
      if (_baiduAccessToken != null && 
          _tokenExpireTime != null && 
          DateTime.now().isBefore(_tokenExpireTime!)) {
        return _baiduAccessToken;
      }

      final response = await http.post(
        Uri.parse(_baiduTokenUrl),
        body: {
          'grant_type': 'client_credentials',
          'client_id': _baiduApiKey,
          'client_secret': _baiduSecretKey,
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _baiduAccessToken = result['access_token'];
        final expiresIn = result['expires_in'] as int? ?? 2592000;
        _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600));
        return _baiduAccessToken;
      }
      return null;
    } catch (e) {
      developer.log('获取百度访问令牌失败', error: e);
      return null;
    }
  }

  /// 构建腾讯云请求头（简化版）
  Future<Map<String, String>> _buildTencentHeaders(String payload, int timestamp) async {
    // 注意：这是简化版，实际生产环境需要完整的TC3-HMAC-SHA256签名实现
    return {
      'Content-Type': 'application/json',
      'X-TC-Action': 'GeneralBasicOCR',
      'X-TC-Version': '2018-11-19',
      'X-TC-Timestamp': timestamp.toString(),
      'X-TC-Region': 'ap-beijing',
      'Authorization': 'TC3-HMAC-SHA256 Credential=$_tencentSecretId',
    };
  }

  /// 解析医疗检查单文本，提取结构化数据
  Map<String, dynamic> _parseMedicalReport(String text) {
    final Map<String, dynamic> data = {};
    
    try {
      // 按行分割
      final lines = text.split('\n');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        // 提取VA（视力）
        if (_containsAny(trimmedLine, ['视力', 'VA', 'Visual Acuity'])) {
          _extractVisionAcuity(trimmedLine, data);
        }
        
        // 提取球镜度数
        if (_containsAny(trimmedLine, ['球镜', 'SPH', 'Sphere'])) {
          _extractSphericalPower(trimmedLine, data);
        }
        
        // 提取柱镜度数
        if (_containsAny(trimmedLine, ['柱镜', 'CYL', 'Cylinder'])) {
          _extractCylindricalPower(trimmedLine, data);
        }
        
        // 提取轴位
        if (_containsAny(trimmedLine, ['轴位', 'AX', 'Axis', '轴向'])) {
          _extractAxis(trimmedLine, data);
        }
        
        // 提取瞳距
        if (_containsAny(trimmedLine, ['瞳距', 'PD', 'Pupil Distance'])) {
          _extractPupilDistance(trimmedLine, data);
        }
        
        // 提取眼压
        if (_containsAny(trimmedLine, ['眼压', 'IOP', 'Intraocular Pressure'])) {
          _extractIntraocularPressure(trimmedLine, data);
        }
      }
    } catch (e) {
      developer.log('解析医疗检查单失败', error: e);
    }

    return data;
  }

  /// 提取视力数据
  void _extractVisionAcuity(String line, Map<String, dynamic> data) {
    final regex = RegExp(r'(\d+\.?\d*)');
    final matches = regex.allMatches(line);
    
    if (matches.isNotEmpty) {
      final values = matches.map((m) => m.group(0)).toList();
      if (values.length >= 2) {
        data['vision_right'] = values[0];
        data['vision_left'] = values[1];
      } else if (values.length == 1) {
        data['vision'] = values[0];
      }
    }
  }

  /// 提取球镜度数
  void _extractSphericalPower(String line, Map<String, dynamic> data) {
    final regex = RegExp(r'([+-]?\d+\.?\d*)');
    final matches = regex.allMatches(line);
    
    if (matches.isNotEmpty) {
      final values = matches.map((m) => m.group(0)).toList();
      if (values.length >= 2) {
        data['sph_right'] = values[0];
        data['sph_left'] = values[1];
      }
    }
  }

  /// 提取柱镜度数
  void _extractCylindricalPower(String line, Map<String, dynamic> data) {
    final regex = RegExp(r'([+-]?\d+\.?\d*)');
    final matches = regex.allMatches(line);
    
    if (matches.isNotEmpty) {
      final values = matches.map((m) => m.group(0)).toList();
      if (values.length >= 2) {
        data['cyl_right'] = values[0];
        data['cyl_left'] = values[1];
      }
    }
  }

  /// 提取轴位
  void _extractAxis(String line, Map<String, dynamic> data) {
    final regex = RegExp(r'(\d+)');
    final matches = regex.allMatches(line);
    
    if (matches.isNotEmpty) {
      final values = matches.map((m) => m.group(0)).toList();
      if (values.length >= 2) {
        data['axis_right'] = values[0];
        data['axis_left'] = values[1];
      }
    }
  }

  /// 提取瞳距
  void _extractPupilDistance(String line, Map<String, dynamic> data) {
    final regex = RegExp(r'(\d+\.?\d*)');
    final match = regex.firstMatch(line);
    if (match != null) {
      data['pd'] = match.group(0);
    }
  }

  /// 提取眼压
  void _extractIntraocularPressure(String line, Map<String, dynamic> data) {
    final regex = RegExp(r'(\d+\.?\d*)');
    final matches = regex.allMatches(line);
    
    if (matches.isNotEmpty) {
      final values = matches.map((m) => m.group(0)).toList();
      if (values.length >= 2) {
        data['iop_right'] = values[0];
        data['iop_left'] = values[1];
      } else if (values.length == 1) {
        data['iop'] = values[0];
      }
    }
  }

  /// 检查字符串是否包含任一关键词
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.toLowerCase().contains(keyword.toLowerCase()));
  }

  /// 配置百度OCR API密钥
  void configureBaiduOCR({required String apiKey, required String secretKey}) {
    // 注意：实际应用中应该使用安全存储
    // 这里仅作为示例
  }

  /// 配置腾讯云OCR API密钥
  void configureTencentOCR({required String secretId, required String secretKey}) {
    // 注意：实际应用中应该使用安全存储
    // 这里仅作为示例
  }
}
