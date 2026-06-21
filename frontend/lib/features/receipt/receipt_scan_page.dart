import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';
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

  String _statusMessage =
      '영수증 이미지를 선택하거나 촬영해 주세요.';

  Future<void> _pickAndProcessImage(
    ImageSource source,
  ) async {
    if (_isProcessing) {
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: source,
    );

    if (image == null) {
      return;
    }

    setState(() {
      _selectedImage = File(image.path);
      _isProcessing = true;
      _statusMessage = 'OCR 텍스트를 추출하는 중입니다...';
    });

    try {
      final ocrResult = await _recognizeText(
        _selectedImage!,
      );

      if (ocrResult.ocrText.trim().isEmpty) {
        _showMessage(
          '인식된 텍스트가 없습니다. 더 선명한 이미지를 사용해 주세요.',
        );
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
        _statusMessage =
            '영수증 이미지를 선택하거나 촬영해 주세요.';
      });
    } catch (e) {
      _showMessage('$e');

      setState(() {
        _statusMessage =
            '처리 중 오류가 발생했습니다. 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<_ReceiptOcrResult> _recognizeText(
    File imageFile,
  ) async {
    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final inputImage = InputImage.fromFilePath(
        imageFile.path,
      );

      final recognizedText =
          await textRecognizer.processImage(inputImage);

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
        final yCompare = (a['y'] as num).compareTo(
          b['y'] as num,
        );

        if (yCompare != 0) {
          return yCompare;
        }

        return (a['x'] as num).compareTo(
          b['x'] as num,
        );
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

    final decodedBody = utf8.decode(
      response.bodyBytes,
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return jsonDecode(decodedBody)
          as Map<String, dynamic>;
    }

    throw Exception(
      '백엔드 오류 ${response.statusCode}: $decodedBody',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            136,
          ),
          children: [
            const Text(
              '영수증 스캔',
              style: TextStyle(
                color: EcoColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '영수증 전체가 보이도록 촬영하면\n소비 내역과 탄소 점수를 분석해요.',
              style: TextStyle(
                color: EcoColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            _buildImagePreview(),

            const SizedBox(height: 12),

            _buildStatusCard(),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickAndProcessImage(
                        ImageSource.camera,
                      ),
              style: FilledButton.styleFrom(
                backgroundColor: EcoColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    EcoColors.secondary.withValues(
                  alpha: 0.45,
                ),
                disabledForegroundColor:
                    Colors.white.withValues(
                  alpha: 0.75,
                ),
                minimumSize: const Size.fromHeight(54),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(
                Icons.camera_alt_outlined,
                size: 21,
              ),
              label: const Text(
                '카메라로 촬영',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _pickAndProcessImage(
                        ImageSource.gallery,
                      ),
              style: OutlinedButton.styleFrom(
                foregroundColor: EcoColors.secondary,
                disabledForegroundColor:
                    EcoColors.muted,
                side: const BorderSide(
                  color: EcoColors.line,
                ),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(
                Icons.photo_outlined,
                size: 21,
              ),
              label: const Text(
                '갤러리에서 선택',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const _ScanTipCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF17231D),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.04,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF53645A),
                    size: 48,
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 32,
              right: 32,
              top: 32,
              bottom: 32,
              child: _ReceiptFrame(),
            ),
            Align(
              alignment: const Alignment(0, 0.80),
              child: Text(
                '영수증 전체가 보이도록 맞춰주세요',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.62,
                  ),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Image.file(
        _selectedImage!,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildStatusCard() {
    return EcoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      child: Row(
        children: [
          if (_isProcessing) ...[
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: EcoColors.primary,
              ),
            ),
            const SizedBox(width: 12),
          ] else ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: EcoColors.primary.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: EcoColors.secondary,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
          ],
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(
                color: EcoColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                height: 1.35,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: EcoColors.primary.withValues(
            alpha: 0.78,
          ),
          width: 2.5,
        ),
      ),
    );
  }
}

class _ScanTipCard extends StatelessWidget {
  const _ScanTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.82,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: EcoColors.secondary,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'TIP!',
                  style: TextStyle(
                    color: EcoColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '빛 반사를 피하고 영수증의 위아래가 잘리지 않도록 촬영하면 더 정확하게 인식돼요.',
                  style: TextStyle(
                    color: EcoColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                    height: 1.45,
                  ),
                ),
              ],
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