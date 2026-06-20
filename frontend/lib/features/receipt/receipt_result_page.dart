import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../recommendation/recommendation_result_page.dart';

class ReceiptResultPage extends StatefulWidget {
  const ReceiptResultPage({
    super.key,
    required this.userId,
    required this.storeName,
    required this.purchasedAt,
    required this.ocrText,
    required this.ocrLines,
    required this.items,
  });

  final String userId;
  final String storeName;
  final dynamic purchasedAt;
  final String ocrText;
  final List<Map<String, dynamic>> ocrLines;
  final List<Map<String, dynamic>> items;

  @override
  State<ReceiptResultPage> createState() => _ReceiptResultPageState();
}

class _ReceiptResultPageState extends State<ReceiptResultPage> {
  bool _isSaving = true;
  String? _errorMessage;

  Map<String, dynamic>? _savedResult;

  @override
  void initState() {
    super.initState();
    _saveReceipt();
  }

  Future<void> _saveReceipt() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(receiptSaveUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'storeName': widget.storeName,
          'purchasedAt': widget.purchasedAt,
          'ocrText': widget.ocrText,
          'ocrLines': widget.ocrLines,
          'items': widget.items,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (!mounted) {
        return;
      }

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        final decoded = jsonDecode(decodedBody);

        if (decoded is Map) {
          setState(() {
            _savedResult =
                Map<String, dynamic>.from(decoded);
            _isSaving = false;
          });
        } else {
          setState(() {
            _errorMessage = '저장 결과 형식이 올바르지 않습니다.';
            _isSaving = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              '저장 오류 ${response.statusCode}: $decodedBody';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = '저장 요청 오류: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장 결과'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSaving) {
      return _buildSavingView();
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_savedResult != null) {
      return _buildSuccessView();
    }

    return const SizedBox.shrink();
  }

  Widget _buildSavingView() {
    return const Center(
      key: ValueKey('saving'),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                strokeWidth: 5,
              ),
            ),
            SizedBox(height: 24),
            Text(
              '영수증을 저장하고 있어요',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '소비 내역과 탄소 배출량을 분석하는 중입니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              '영수증을 저장하지 못했어요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage ?? '알 수 없는 오류가 발생했습니다.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saveReceipt,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final savedResult = _savedResult!;

    final summaryValue = savedResult['summary'];

    final summary = summaryValue is Map
        ? Map<String, dynamic>.from(summaryValue)
        : <String, dynamic>{};

    return SingleChildScrollView(
      key: const ValueKey('success'),
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 60,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '저장이 완료되었어요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '저장된 소비 내역을 기준으로\n친환경 대안을 추천해 드릴게요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),

          _buildSummaryCard(summary),

          const SizedBox(height: 32),

          RecommendationResultSection(
            savedResult: savedResult,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    Map<String, dynamic> summary,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이번 소비 요약',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '총 금액: ${summary['totalPrice'] ?? '-'}원',
            ),
            const SizedBox(height: 6),
            Text(
              '총 추정 탄소량: '
              '${summary['totalEstimatedCarbonKg'] ?? '-'}kg CO₂-eq',
            ),
            const SizedBox(height: 6),
            Text(
              '평균 탄소 점수: '
              '${summary['averageCarbonScore'] ?? '-'}',
            ),
            const SizedBox(height: 6),
            Text(
              '품목 수: ${summary['itemCount'] ?? '-'}개',
            ),
            const SizedBox(height: 6),
            Text(
              '주요 카테고리: '
              '${summary['topCategory'] ?? '-'}',
            ),
          ],
        ),
      ),
    );
  }
}