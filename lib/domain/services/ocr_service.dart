import 'dart:async';
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
  String _baiduApiKey = 'YOUR_BAIDU_API_KEY';
  String _baiduSecretKey = 'YOUR_BAIDU_SECRET_KEY';
  static const String _baiduTokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const String _baiduOcrUrl = 'https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic';
  static const String _baiduAccurateOcrUrl = 'https://aip.baidubce.com/rest/2.0/ocr/v1/accurate_basic';

  // 腾讯云OCR配置（需要替换为实际的SecretId和SecretKey）
  String _tencentSecretId = 'YOUR_TENCENT_SECRET_ID';
  String _tencentSecretKey = 'YOUR_TENCENT_SECRET_KEY';
  static const String _tencentOcrUrl = 'https://ocr.tencentcloudapi.com';

  String? _baiduAccessToken;
  DateTime? _tokenExpireTime;

  // 超时和重试配置
  static const Duration _connectionTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);

  /// 带重试机制的HTTP请求
  Future<http.Response> _httpPostWithRetry(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    int attempts = 0;
    
    while (attempts < _maxRetries) {
      try {
        final response = await http.post(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        ).timeout(_receiveTimeout);
        
        return response;
      } on TimeoutException {
        attempts++;
        developer.log('HTTP请求超时，重试 $attempts/$_maxRetries', name: 'OCRService');
        if (attempts >= _maxRetries) {
          throw TimeoutException('请求超时，已重试 $_maxRetries 次');
        }
        await Future.delayed(_retryDelay * attempts);
      } on SocketException catch (e) {
        attempts++;
        developer.log('网络错误，重试 $attempts/$_maxRetries: $e', name: 'OCRService');
        if (attempts >= _maxRetries) {
          throw Exception('网络连接失败，请检查网络设置');
        }
        await Future.delayed(_retryDelay * attempts);
      }
    }
    
    throw Exception('请求失败');
  }

  /// 识别检查单图片
  /// 
  /// [imagePath] - 图片文件路径
  /// [provider] - OCR提供商: 'baidu' 或 'tencent'，使用 'demo' 启用演示模式
  Future<OCRResult> recognizeMedicalReport(String imagePath, {String provider = 'demo'}) async {
    try {
      developer.log('开始OCR识别: $imagePath, 提供商: $provider', name: 'OCRService');
      
      // 演示模式：返回模拟数据
      if (provider == 'demo') {
        return await _recognizeDemo(imagePath);
      }
      
      final file = File(imagePath);
      if (!await file.exists()) {
        return OCRResult.failure('图片文件不存在: $imagePath');
      }

      // 检查文件大小（限制10MB）
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        return OCRResult.failure('图片文件过大，请压缩后重试（最大10MB）');
      }

      if (provider == 'baidu') {
        return await _recognizeWithBaidu(file);
      } else if (provider == 'tencent') {
        return await _recognizeWithTencent(file);
      } else {
        return OCRResult.failure('不支持的OCR提供商: $provider');
      }
    } on TimeoutException {
      return OCRResult.failure('OCR识别超时，请检查网络连接后重试');
    } on SocketException {
      return OCRResult.failure('网络连接失败，请检查网络设置');
    } catch (e, stackTrace) {
      developer.log('OCR识别失败', error: e, stackTrace: stackTrace, name: 'OCRService');
      return OCRResult.failure('OCR识别失败: $e');
    }
  }

  /// 演示模式：模拟OCR识别
  /// 返回预设的检查单数据用于测试（匹配实际检查单）
  Future<OCRResult> _recognizeDemo(String imagePath) async {
    developer.log('使用演示模式进行OCR识别', name: 'OCRService');
    
    // 模拟网络延迟
    await Future.delayed(const Duration(seconds: 2));
    
    // 返回与检查单匹配的数据
    return OCRResult.success(
      text: '案例分析 男孩18岁 全矫 OD -3.00DS 1.0 OS -3.50DS 1.0 远眼位13exo 近眼位2exo AC/A 8 NPC 6cm NRA +2.25 PRA -2.25 OD 12D OS 12D',
      structuredData: {
        // 患者信息
        'patient_name': '案例患者',
        'patient_age': 18,
        'patient_gender': '男',
        
        // 全矫视力
        'va_far_corrected_od': 1.0,
        'va_far_corrected_os': 1.0,
        
        // 屈光度（全矫）
        'sph_od': -3.00,
        'sph_os': -3.50,
        'cyl_od': 0.0,
        'cyl_os': 0.0,
        
        // 眼位
        'distance_phoria': 13.0,  // 13exo
        'near_phoria': 2.0,       // 2exo
        
        // AC/A和NPC
        'aca_ratio': 8.0,
        'npc': 6.0,               // 6cm
        
        // 相对调节
        'nra': 2.25,              // +2.25
        'pra': -2.25,             // -2.25
        
        // 调节幅度
        'amp_od': 12.0,           // 12D
        'amp_os': 12.0,           // 12D
        
        // 调节灵活度（Flipper）
        'flipper_od': 12.0,       // 12cpm
        'flipper_os': 12.0,       // 12cpm
      },
    );
  }

  /// 使用百度AI OCR识别
  Future<OCRResult> _recognizeWithBaidu(File imageFile) async {
    try {
      // 获取访问令牌
      final token = await _getBaiduAccessToken();
      if (token == null) {
        return OCRResult.failure('获取百度OCR访问令牌失败，请检查API密钥配置');
      }

      // 读取图片并转换为base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 检查base64大小
      if (base64Image.length > 4 * 1024 * 1024) {
        return OCRResult.failure('图片Base64编码后超过4MB，请压缩后重试');
      }

      // 调用百度OCR API（带重试）
      final response = await _httpPostWithRetry(
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
          final errorMsg = result['error_msg'] ?? '未知错误';
          developer.log('百度OCR API错误: ${result['error_code']} - $errorMsg', name: 'OCRService');
          return OCRResult.failure('百度OCR错误: $errorMsg');
        }

        // 提取文本
        final wordsResult = result['words_result'] as List<dynamic>?;
        if (wordsResult == null || wordsResult.isEmpty) {
          return OCRResult.failure('未识别到文本内容，请确保图片清晰且包含文字');
        }

        final StringBuffer textBuffer = StringBuffer();
        for (final item in wordsResult) {
          textBuffer.writeln(item['words']);
        }

        final recognizedText = textBuffer.toString();
        
        // 解析结构化数据
        final structuredData = _parseMedicalReport(recognizedText);

        developer.log('百度OCR识别成功，识别到 ${wordsResult.length} 行文本', name: 'OCRService');

        return OCRResult.success(
          text: recognizedText,
          structuredData: structuredData,
        );
      } else if (response.statusCode == 401) {
        // Token过期，清除缓存并重试
        _baiduAccessToken = null;
        _tokenExpireTime = null;
        return OCRResult.failure('访问令牌已过期，请重试');
      } else {
        return OCRResult.failure('百度OCR请求失败，状态码: ${response.statusCode}');
      }
    } on TimeoutException {
      return OCRResult.failure('百度OCR识别超时，请检查网络连接');
    } catch (e, stackTrace) {
      developer.log('百度OCR识别失败', error: e, stackTrace: stackTrace, name: 'OCRService');
      return OCRResult.failure('百度OCR识别失败: $e');
    }
  }

  /// 使用腾讯云OCR识别
  Future<OCRResult> _recognizeWithTencent(File imageFile) async {
    try {
      // 读取图片并转换为base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 检查base64大小
      if (base64Image.length > 4 * 1024 * 1024) {
        return OCRResult.failure('图片Base64编码后超过4MB，请压缩后重试');
      }

      // 构建请求
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = jsonEncode({
        'ImageBase64': base64Image,
      });

      // 构建签名（简化版，实际生产环境需要完整的签名实现）
      final headers = await _buildTencentHeaders(payload, timestamp);

      // 调用腾讯云OCR API（带重试）
      final response = await _httpPostWithRetry(
        Uri.parse(_tencentOcrUrl),
        headers: headers,
        body: payload,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['Response']['Error'] != null) {
          final errorMsg = result['Response']['Error']['Message'] ?? '未知错误';
          developer.log('腾讯云OCR API错误: $errorMsg', name: 'OCRService');
          return OCRResult.failure('腾讯云OCR错误: $errorMsg');
        }

        final textDetections = result['Response']['TextDetections'] as List<dynamic>?;
        if (textDetections == null || textDetections.isEmpty) {
          return OCRResult.failure('未识别到文本内容，请确保图片清晰且包含文字');
        }

        final StringBuffer textBuffer = StringBuffer();
        for (final item in textDetections) {
          textBuffer.writeln(item['DetectedText']);
        }

        final recognizedText = textBuffer.toString();
        final structuredData = _parseMedicalReport(recognizedText);

        developer.log('腾讯云OCR识别成功，识别到 ${textDetections.length} 个文本区域', name: 'OCRService');

        return OCRResult.success(
          text: recognizedText,
          structuredData: structuredData,
        );
      } else if (response.statusCode == 401) {
        return OCRResult.failure('腾讯云OCR认证失败，请检查API密钥配置');
      } else {
        return OCRResult.failure('腾讯云OCR请求失败，状态码: ${response.statusCode}');
      }
    } on TimeoutException {
      return OCRResult.failure('腾讯云OCR识别超时，请检查网络连接');
    } catch (e, stackTrace) {
      developer.log('腾讯云OCR识别失败', error: e, stackTrace: stackTrace, name: 'OCRService');
      return OCRResult.failure('腾讯云OCR识别失败: $e');
    }
  }

  /// 获取百度访问令牌
  Future<String?> _getBaiduAccessToken() async {
    try {
      // 检查现有令牌是否有效（提前1小时过期）
      if (_baiduAccessToken != null && 
          _tokenExpireTime != null && 
          DateTime.now().isBefore(_tokenExpireTime!)) {
        developer.log('使用缓存的百度访问令牌', name: 'OCRService');
        return _baiduAccessToken;
      }

      // 检查API密钥是否已配置
      if (_baiduApiKey == 'YOUR_BAIDU_API_KEY' || 
          _baiduSecretKey == 'YOUR_BAIDU_SECRET_KEY') {
        developer.log('百度OCR API密钥未配置', name: 'OCRService');
        return null;
      }

      final response = await http.post(
        Uri.parse(_baiduTokenUrl),
        body: {
          'grant_type': 'client_credentials',
          'client_id': _baiduApiKey,
          'client_secret': _baiduSecretKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _baiduAccessToken = result['access_token'];
        final expiresIn = result['expires_in'] as int? ?? 2592000;
        // 提前1小时过期，避免边界问题
        _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600));
        developer.log('获取百度访问令牌成功，有效期至: $_tokenExpireTime', name: 'OCRService');
        return _baiduAccessToken;
      } else {
        developer.log('获取百度访问令牌失败，状态码: ${response.statusCode}', name: 'OCRService');
        return null;
      }
    } on TimeoutException {
      developer.log('获取百度访问令牌超时', name: 'OCRService');
      return null;
    } catch (e, stackTrace) {
      developer.log('获取百度访问令牌失败', error: e, stackTrace: stackTrace, name: 'OCRService');
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
  /// 
  /// [apiKey] - 百度AI平台的API Key
  /// [secretKey] - 百度AI平台的Secret Key
  void configureBaiduOCR({required String apiKey, required String secretKey}) {
    if (apiKey.isEmpty || secretKey.isEmpty) {
      throw ArgumentError('API Key和Secret Key不能为空');
    }
    
    _baiduApiKey = apiKey;
    _baiduSecretKey = secretKey;
    
    // 清除缓存的token，下次请求时会重新获取
    _baiduAccessToken = null;
    _tokenExpireTime = null;
    
    developer.log('百度OCR API密钥已配置', name: 'OCRService');
  }

  /// 配置腾讯云OCR API密钥
  /// 
  /// [secretId] - 腾讯云SecretId
  /// [secretKey] - 腾讯云SecretKey
  void configureTencentOCR({required String secretId, required String secretKey}) {
    if (secretId.isEmpty || secretKey.isEmpty) {
      throw ArgumentError('SecretId和SecretKey不能为空');
    }
    
    _tencentSecretId = secretId;
    _tencentSecretKey = secretKey;
    
    developer.log('腾讯云OCR API密钥已配置', name: 'OCRService');
  }

  /// 清除所有缓存
  void clearCache() {
    _baiduAccessToken = null;
    _tokenExpireTime = null;
    developer.log('OCR缓存已清除', name: 'OCRService');
  }

  /// 获取当前配置状态
  Map<String, bool> getConfigurationStatus() {
    return {
      'baidu_configured': _baiduApiKey != 'YOUR_BAIDU_API_KEY' && 
                         _baiduSecretKey != 'YOUR_BAIDU_SECRET_KEY',
      'tencent_configured': _tencentSecretId != 'YOUR_TENCENT_SECRET_ID' && 
                           _tencentSecretKey != 'YOUR_TENCENT_SECRET_KEY',
      'baidu_token_valid': _baiduAccessToken != null && 
                          _tokenExpireTime != null && 
                          DateTime.now().isBefore(_tokenExpireTime!),
    };
  }
}
