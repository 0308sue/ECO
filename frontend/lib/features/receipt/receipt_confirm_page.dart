import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';
import '../recommendation/recommendation_result_page.dart';

class ReceiptConfirmPage extends StatefulWidget {
  const ReceiptConfirmPage({
    super.key,
    required this.userId,
    required this.ocrText,
    required this.ocrLines,
    required this.analysisResult,
  });

  final String userId;
  final String ocrText;
  final List<Map<String, dynamic>> ocrLines;
  final Map<String, dynamic> analysisResult;

  @override
  State<ReceiptConfirmPage> createState() => _ReceiptConfirmPageState();
}

class _ReceiptConfirmPageState extends State<ReceiptConfirmPage> {
  late List<Map<String, dynamic>> _editableItems;

  Map<String, dynamic>? _savedResult;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final items = widget.analysisResult['items'];

    _editableItems = items is List
        ? items.map((item) {
            final map = item as Map<String, dynamic>;

            return {
              'originalName': map['originalName'] ?? map['name'] ?? '',
              'price': map['price'] ?? 0,
            };
          }).toList()
        : [];
  }

  Future<void> _saveFinalReceipt() async {
    final finalItems = _editableItems
        .map((item) {
          final name = '${item['originalName'] ?? ''}'.trim();
          final price = _parsePrice(item['price']);

          return {'name': name, 'price': price};
        })
        .where((item) {
          final name = '${item['name']}'.trim();
          final price = item['price'] as int;

          return name.isNotEmpty && price > 0;
        })
        .toList();

    if (finalItems.isEmpty) {
      _showMessage('저장할 품목이 없습니다. 품목명과 가격을 확인해 주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final response = await http.post(
        Uri.parse(receiptSaveUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'storeName': widget.analysisResult['storeName'],
          'purchasedAt': widget.analysisResult['purchasedAt'],
          'ocrText': widget.ocrText,
          'ocrLines': widget.ocrLines,
          'items': finalItems,
        }),
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(decodedBody) as Map<String, dynamic>;

        setState(() {
          _savedResult = result;
        });

        _showMessage('영수증이 최종 저장되었습니다.');
      } else {
        _showMessage('저장 오류 ${response.statusCode}: $decodedBody');
      }
    } catch (e) {
      _showMessage('저장 요청 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _addItem() {
    setState(() {
      _editableItems.add({'originalName': '', 'price': 0});
    });
  }

  void _removeItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
    });
  }

  int _parsePrice(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final text = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(text) ?? 0;
  }

  Map<String, dynamic>? get _summary {
    final summary = _savedResult?['summary'];
    return summary is Map<String, dynamic> ? summary : null;
  }

  void _openRecommendationResult() {
    final savedResult = _savedResult;

    if (savedResult == null) {
      _showMessage('저장된 영수증 정보가 없습니다.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendationResultPage(savedResult: savedResult),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildOverviewCard(),
              const SizedBox(height: 18),
              _buildEditableItemList(),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSaving ? null : _saveFinalReceipt,
                style: FilledButton.styleFrom(
                  backgroundColor: EcoColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _isSaving ? '저장 중...' : '최종 저장',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (_savedResult != null) ...[
                const SizedBox(height: 22),
                if (summary != null) _buildSummaryCard(summary),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openRecommendationResult,
                  style: FilledButton.styleFrom(
                    backgroundColor: EcoColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.eco_outlined),
                  label: const Text(
                    '추천 결과 보기',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '품목 확인',
                style: TextStyle(
                  color: EcoColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '인식된 내용을 확인하고 저장해요',
                style: TextStyle(
                  color: EcoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard() {
    final storeName = '${widget.analysisResult['storeName'] ?? '영수증'}';
    final total = _editableItems.fold<int>(
      0,
      (sum, item) => sum + _parsePrice(item['price']),
    );

    return EcoCard(
      color: EcoColors.secondary,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '인식 품목 ${_editableItems.length}개',
                      style: const TextStyle(
                        color: Color(0xFFD5E7DA),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            '예상 결제 금액',
            style: TextStyle(
              color: Color(0xFFD5E7DA),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatWon(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableItemList() {
    if (_editableItems.isEmpty) {
      return EcoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '품목 후보가 없습니다.',
              style: TextStyle(
                color: EcoColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '영수증에서 품목을 찾지 못했어요. 직접 추가해 주세요.',
              style: TextStyle(
                color: EcoColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add_rounded),
              label: const Text('품목 직접 추가'),
            ),
          ],
        ),
      );
    }

    return EcoCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '품목 후보',
                      style: TextStyle(
                        color: EcoColors.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '이름과 금액만 확인하면 저장할 수 있어요.',
                      style: TextStyle(
                        color: EcoColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('추가'),
                style: TextButton.styleFrom(
                  foregroundColor: EcoColors.secondary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...List.generate(_editableItems.length, _buildItemEditor),
        ],
      ),
    );
  }

  Widget _buildItemEditor(int index) {
    final item = _editableItems[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EcoColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              initialValue: '${item['originalName'] ?? ''}',
              decoration: _inputDecoration('품목명'),
              onChanged: (value) {
                item['originalName'] = value;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: '${item['price'] ?? 0}',
              decoration: _inputDecoration('가격'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                item['price'] = _parsePrice(value);
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _removeItem(index),
            color: EcoColors.muted,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EcoColors.primary, width: 1.4),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return EcoCard(
      border: Border.all(color: EcoColors.primary.withValues(alpha: 0.28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '저장 완료',
                  style: TextStyle(
                    color: EcoColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              EcoPill(
                label: '분석 완료',
                icon: Icons.check_rounded,
                background: EcoColors.primary.withValues(alpha: 0.14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: '총 금액',
                  value: '${summary['totalPrice'] ?? '-'}원',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: '탄소 점수',
                  value: '${summary['averageCarbonScore'] ?? '-'}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: '품목',
                  value: '${summary['itemCount'] ?? '-'}개',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  label: '주요 카테고리',
                  value: '${summary['topCategory'] ?? '-'}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWon(int amount) {
    return '${_comma(amount)}원';
  }

  String _comma(int number) {
    final value = number.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;
      buffer.write(value[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return number < 0 ? '-$buffer' : buffer.toString();
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: EcoColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: EcoColors.line),
          boxShadow: EcoShadow.soft,
        ),
        child: Icon(icon, color: EcoColors.text, size: 28),
      ),
    );
  }
}
