import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';

class ReceiptOcrPage extends StatefulWidget {
  const ReceiptOcrPage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<ReceiptOcrPage> createState() => _ReceiptOcrPageState();
}

class _ReceiptOcrPageState extends State<ReceiptOcrPage> {
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String _ocrText = '';
  List<Map<String, dynamic>> _ocrLines = [];
  Map<String, dynamic>? _analysisResult;

  bool _isRecognizing = false;
  bool _isSending = false;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image == null) {
      return;
    }

    setState(() {
      _selectedImage = File(image.path);
      _ocrText = '';
      _ocrLines = [];
      _analysisResult = null;
    });
  }

  Future<void> _recognizeText() async {
    if (_selectedImage == null) {
      _showMessage('먼저 영수증 이미지를 선택해 주세요.');
      return;
    }

    setState(() {
      _isRecognizing = true;
      _ocrText = '';
      _analysisResult = null;
    });

    final textRecognizer = TextRecognizer(
      script: TextRecognitionScript.korean,
    );

    try {
      final inputImage = InputImage.fromFilePath(_selectedImage!.path);
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

      setState(() {
        _ocrText = recognizedText.text;
        _ocrLines = extractedLines;
      });

      if (_ocrText.trim().isEmpty) {
        _showMessage('인식된 텍스트가 없습니다. 더 선명한 이미지를 사용해 주세요.');
      }
    } catch (e) {
      _showMessage('OCR 처리 오류: $e');
    } finally {
      await textRecognizer.close();

      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    }
  }

  Future<void> _sendToBackend() async {
    if (_ocrText.trim().isEmpty) {
      _showMessage('먼저 OCR 텍스트를 추출해 주세요.');
      return;
    }

    setState(() {
      _isSending = true;
      _analysisResult = null;
    });

    try {
      final response = await http.post(
        Uri.parse(receiptOcrTextUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'ocrText': _ocrText,
          'ocrLines': _ocrLines,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _analysisResult = jsonDecode(decodedBody) as Map<String, dynamic>;
        });

        _showMessage('영수증 분석이 완료되었습니다.');
      } else {
        _showMessage('백엔드 오류 ${response.statusCode}: $decodedBody');
      }
    } catch (e) {
      _showMessage('백엔드 요청 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  List<dynamic> get _items {
    final items = _analysisResult?['items'];
    return items is List ? items : [];
  }

  Map<String, dynamic>? get _summary {
    final summary = _analysisResult?['summary'];
    return summary is Map<String, dynamic> ? summary : null;
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
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 OCR 분석'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 12),
            _buildImageButtons(),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _isRecognizing ? null : _recognizeText,
              child: Text(_isRecognizing ? 'OCR 처리 중...' : 'OCR 텍스트 추출'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _isSending ? null : _sendToBackend,
              child: Text(_isSending ? '분석 요청 중...' : '백엔드 분석 요청'),
            ),
            const SizedBox(height: 20),
            _buildOcrTextCard(),
            const SizedBox(height: 20),
            if (_analysisResult != null) ...[
              _buildReceiptIdCard(),
              const SizedBox(height: 12),
              if (summary != null) _buildSummaryCard(summary),
              const SizedBox(height: 12),
              _buildItemList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('선택된 영수증 이미지가 없습니다.'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        _selectedImage!,
        height: 240,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo),
            label: const Text('갤러리 선택'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('카메라 촬영'),
          ),
        ),
      ],
    );
  }

  Widget _buildOcrTextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
            'OCR 텍스트 / 라인 ${_ocrLines.length}개',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
            const SizedBox(height: 8),
            SelectableText(
              _ocrText.isEmpty ? '아직 추출된 텍스트가 없습니다.' : _ocrText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptIdCard() {
    return Card(
      child: ListTile(
        title: const Text('저장 정보'),
        subtitle: Text(
          'receiptId: ${_analysisResult?['receiptId'] ?? '-'}\n'
          'userId: ${_analysisResult?['userId'] ?? '-'}',
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('영수증 요약', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('총 금액: ${summary['totalPrice']}원'),
            Text('총 추정 탄소량: ${summary['totalEstimatedCarbonGram']}g CO₂-eq'),
            Text('총 추정 탄소량: ${summary['totalEstimatedCarbonKg']}kg CO₂-eq'),
            Text('평균 탄소 점수: ${summary['averageCarbonScore']}'),
            Text('품목 수: ${summary['itemCount']}개'),
            Text('주요 카테고리: ${summary['topCategory']}'),
            Text('주요 세부 카테고리: ${summary['topSubCategory']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    if (_items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('분석된 품목이 없습니다.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('품목별 분석 결과', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._items.map((item) {
          final map = item as Map<String, dynamic>;

          return Card(
            child: ListTile(
              title: Text('${map['originalName']}'),
              subtitle: Text(
                '가격: ${map['price']}원\n'
                '분류: ${map['category']} / ${map['subCategory']}\n'
                '추정 탄소량: ${map['estimatedCarbonGram']}g CO₂-eq\n'
                '점수: ${map['carbonScore']}',
              ),
            ),
          );
        }),
      ],
    );
  }
}