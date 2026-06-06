import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import 'receipt_confirm_page.dart';

class ReceiptScanPage extends StatefulWidget {
  const ReceiptScanPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

class _ReceiptScanPageState extends State<ReceiptScanPage> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isProcessing = false;
  String _statusMessage = '영수증 이미지를 선택하거나 촬영해 주세요.';

  Future<void> _pickAndProcessImage(ImageSource source) async {
    if (_isProcessing) {
      return;
    }

    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) {
      return;
    }

    setState(() {
      _selectedImage = File(image.path);
      _isProcessing = true;
      _statusMessage = 'OCR 텍스트를 추출하는 중입니다...';
    });

    try {
      final ocrResult = await _recognizeText(_selectedImage!);

      if (ocrResult.ocrText.trim().isEmpty) {
        _showMessage('인식된 텍스트가 없습니다. 더 선명한 이미지를 사용해 주세요.');
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = '품목 후보를 추출하는 중입니다...';
      });

      final analysisResult = await _sendOcrTextToBackend(
        ocrText: ocrResult.ocrText,
        ocrLines: ocrResult.ocrLines,
      );

      if (!mounted) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptConfirmPage(
            userId: widget.userId,
            ocrText: ocrResult.ocrText,
            ocrLines: ocrResult.ocrLines,
            analysisResult: analysisResult,
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _statusMessage = '영수증 이미지를 선택하거나 촬영해 주세요.';
      });
    } catch (e) {
      _showMessage('$e');
      setState(() {
        _statusMessage = '처리 중 오류가 발생했습니다. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<_ReceiptOcrResult> _recognizeText(File imageFile) async {
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await textRecognizer.processImage(inputImage);

      final extractedLines = <Map<String, dynamic>>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final box = line.boundingBox;

          extractedLines.add({
            'text': line.text,
            'x': box.left,
            'y': box.top,
            'width': box.width,
            'height': box.height,
          });
        }
      }

      extractedLines.sort((a, b) {
        final yCompare = (a['y'] as num).compareTo(b['y'] as num);
        if (yCompare != 0) {
          return yCompare;
        }

        return (a['x'] as num).compareTo(b['x'] as num);
      });

      return _ReceiptOcrResult(
        ocrText: recognizedText.text,
        ocrLines: extractedLines,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  Future<Map<String, dynamic>> _sendOcrTextToBackend({
    required String ocrText,
    required List<Map<String, dynamic>> ocrLines,
  }) async {
    final response = await http.post(
      Uri.parse(receiptOcrTextUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': widget.userId,
        'ocrText': ocrText,
        'ocrLines': ocrLines,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    }

    throw Exception('백엔드 오류 ${response.statusCode}: $decodedBody');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 OCR 분석'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickAndProcessImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('카메라로 촬영'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickAndProcessImage(ImageSource.gallery),
              icon: const Icon(Icons.photo),
              label: const Text('갤러리에서 선택'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 260,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('선택된 영수증 이미지가 없습니다.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        _selectedImage!,
        height: 260,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_isProcessing) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
            ] else ...[
              const Icon(Icons.receipt_long_outlined),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(_statusMessage),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptOcrResult {
  const _ReceiptOcrResult({
    required this.ocrText,
    required this.ocrLines,
  });

  final String ocrText;
  final List<Map<String, dynamic>> ocrLines;
}