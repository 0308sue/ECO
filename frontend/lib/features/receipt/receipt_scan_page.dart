import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/theme/eco_design_system.dart';
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
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 112),
          children: [
            const Text(
              '영수증 스캔',
              style: TextStyle(
                color: EcoColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '영수증을 프레임 안에 맞추면 소비 탄소 점수를 분석해요.',
              style: TextStyle(
                color: EcoColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),
            _buildImagePreview(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickAndProcessImage(ImageSource.camera),
              style: FilledButton.styleFrom(
                backgroundColor: EcoColors.secondary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text(
                '카메라로 스캔',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickAndProcessImage(ImageSource.gallery),
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoColors.secondary,
                side: const BorderSide(color: EcoColors.line),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.photo_outlined),
              label: const Text(
                '갤러리에서 업로드',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 24),
            const _ResultPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 330,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF171D1A),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF46504A),
                  size: 64,
                ),
              ),
            ),
            const Positioned(
              left: 36,
              right: 36,
              top: 38,
              bottom: 38,
              child: _ReceiptFrame(),
            ),
            Align(
              alignment: const Alignment(0, 0.78),
              child: Text(
                '프레임 안에 영수증을 맞춰주세요',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Image.file(
        _selectedImage!,
        height: 330,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildStatusCard() {
    return EcoCard(
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
            const Icon(
              Icons.receipt_long_outlined,
              color: EcoColors.secondary,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(
                color: EcoColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptFrame extends StatelessWidget {
  const _ReceiptFrame();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: EcoColors.primary.withValues(alpha: 0.72),
          width: 3,
        ),
      ),
    );
  }
}

class _ResultPreviewCard extends StatelessWidget {
  const _ResultPreviewCard();

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.all(18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '분석 결과 미리보기',
            style: TextStyle(
              color: EcoColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          Text(
            '스캔 후 매장명, 총 금액, 탄소 점수, 에코 등급을 확인하고 저장할 수 있어요.',
            style: TextStyle(
              color: EcoColors.muted,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
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
