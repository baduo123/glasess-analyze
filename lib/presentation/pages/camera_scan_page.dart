import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/ocr_service.dart';

/// 相机扫描页面
/// 用于拍照或选择图片进行OCR识别
class CameraScanPage extends StatefulWidget {
  final bool showResultConfirmation;

  const CameraScanPage({
    super.key,
    this.showResultConfirmation = true,
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
    });
  }

  Future<void> _processOCR() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result = await _ocrService.recognizeMedicalReport(_selectedImage!.path);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _ocrResult = result;
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
        setState(() => _isProcessing = false);
        _showError('OCR识别失败: $e');
      }
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
              const Text('识别到的数据：', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(result.structuredData?.entries ?? {}.entries).map((e) => 
                Text('${e.key}: ${e.value}')
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
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('拍照识别'),
        actions: [
          if (_selectedImage != null)
            TextButton.icon(
              onPressed: _isProcessing ? null : _processOCR,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('开始识别', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.contain)
                : const Center(child: Text('请选择或拍摄检查单')),
          ),
          if (_isProcessing)
            const LinearProgressIndicator(),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red[100],
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('拍照'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFromGallery,
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
