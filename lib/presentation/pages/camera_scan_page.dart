import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/ocr_service.dart';

/// OCR识别进度状态
enum OCRProgressStatus {
  idle,
  preparing,
  uploading,
  recognizing,
  parsing,
  completed,
  error,
}

/// OCR进度信息
class OCRProgress {
  final OCRProgressStatus status;
  final String message;
  final double progress;

  const OCRProgress({
    required this.status,
    required this.message,
    this.progress = 0.0,
  });

  static const OCRProgress idle = OCRProgress(
    status: OCRProgressStatus.idle,
    message: '准备就绪',
    progress: 0.0,
  );
}

/// 相机扫描页面
/// 用于拍照或选择图片进行OCR识别
/// 支持百度、腾讯和DashScope大模型OCR
class CameraScanPage extends StatefulWidget {
  final bool showResultConfirmation;
  final String ocrProvider;

  const CameraScanPage({
    super.key,
    this.showResultConfirmation = true,
    this.ocrProvider = 'dashscope',
  });

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocrService = OCRService();

  File? _selectedImage;
  bool _isProcessing = false;
  String? _errorMessage;
  OCRResult? _ocrResult;
  OCRProgress _progress = OCRProgress.idle;

  /// 更新进度状态
  void _updateProgress(OCRProgress progress) {
    if (mounted) {
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (photo != null) {
        _setImage(File(photo.path));
      }
    } catch (e) {
      _showError('拍照失败: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 90,
      );

      if (image != null) {
        _setImage(File(image.path));
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }

  void _setImage(File imageFile) {
    setState(() {
      _selectedImage = imageFile;
      _errorMessage = null;
      _ocrResult = null;
      _progress = OCRProgress.idle;
    });
  }

  Future<void> _processOCR() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _progress = const OCRProgress(
        status: OCRProgressStatus.preparing,
        message: '准备图片...',
        progress: 0.1,
      );
    });

    try {
      // 模拟进度更新（因为实际的OCR服务不支持进度回调）
      _simulateProgress();

      final result = await _ocrService.recognizeMedicalReport(
        _selectedImage!.path,
        provider: widget.ocrProvider,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _ocrResult = result;
          _progress = result.success
              ? const OCRProgress(
                  status: OCRProgressStatus.completed,
                  message: '识别完成',
                  progress: 1.0,
                )
              : OCRProgress(
                  status: OCRProgressStatus.error,
                  message: result.errorMessage ?? '识别失败',
                  progress: 0.0,
                );
        });

        if (result.success) {
          if (widget.showResultConfirmation) {
            _showResultConfirmationDialog(result);
          } else {
            Navigator.pop(context, {
              'success': true,
              'data': result.structuredData,
            });
          }
        } else {
          _showError(result.errorMessage ?? '识别失败');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _progress = OCRProgress(
            status: OCRProgressStatus.error,
            message: '识别失败: $e',
            progress: 0.0,
          );
        });
        _showError('OCR识别失败: $e');
      }
    }
  }

  /// 模拟进度更新
  void _simulateProgress() async {
    final stages = [
      const OCRProgress(
        status: OCRProgressStatus.preparing,
        message: '准备图片...',
        progress: 0.1,
      ),
      const OCRProgress(
        status: OCRProgressStatus.uploading,
        message: '上传图片...',
        progress: 0.3,
      ),
      const OCRProgress(
        status: OCRProgressStatus.recognizing,
        message: 'AI识别中（支持手写体）...',
        progress: 0.6,
      ),
      const OCRProgress(
        status: OCRProgressStatus.parsing,
        message: '解析数据...',
        progress: 0.9,
      ),
    ];

    for (final stage in stages) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isProcessing) break;
      _updateProgress(stage);
    }
  }

  void _showResultConfirmationDialog(OCRResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('识别结果确认'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DashScope AI识别到的数据：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(result.structuredData?.entries ?? {}.entries).map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${e.key}: ${e.value}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              if (result.structuredData == null ||
                  result.structuredData!.isEmpty)
                const Text(
                  '未识别到结构化数据',
                  style: TextStyle(color: Colors.orange),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('重新拍摄'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, {
                'success': true,
                'data': result.structuredData,
              });
            },
            child: const Text('确认使用'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '知道了',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识别'),
        actions: [
          if (_selectedImage != null && !_isProcessing)
            TextButton.icon(
              onPressed: _processOCR,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('开始识别', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_selectedImage!, fit: BoxFit.contain),
                      if (_isProcessing)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _progress.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 200,
                                  child: LinearProgressIndicator(
                                    value: _progress.progress,
                                    backgroundColor: Colors.white24,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '请选择或拍摄检查单',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '支持手写体和印刷体',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('拍照'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('相册'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
