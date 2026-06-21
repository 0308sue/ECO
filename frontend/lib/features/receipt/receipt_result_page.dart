import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';
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
    required this.onTapEcoPlaceMap,
  });

  final String userId;
  final String storeName;
  final dynamic purchasedAt;
  final String ocrText;
  final List<Map<String, dynamic>> ocrLines;
  final List<Map<String, dynamic>> items;
  final VoidCallback onTapEcoPlaceMap;

  @override
  State<ReceiptResultPage> createState() =>
      _ReceiptResultPageState();
}

class _ReceiptResultPageState
    extends State<ReceiptResultPage> {
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

      final decodedBody = utf8.decode(
        response.bodyBytes,
      );

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
            _errorMessage =
                '저장 결과 형식이 올바르지 않습니다.';
            _isSaving = false;
          });
        }
      } else {
        setState(() {
          _errorMessage =
              '저장 오류 ${response.statusCode}: '
              '$decodedBody';
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
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 300,
          ),
          child: _buildBody(),
        ),
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
    return SingleChildScrollView(
      key: const ValueKey('saving'),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: '영수증 저장',
            subtitle: '소비 내역을 분석하고 있어요.',
          ),
          const SizedBox(height: 20),
          _buildSavingCard(),
          const SizedBox(height: 14),
          EcoCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 15,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EcoColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
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
                        '탄소 소비 분석 중',
                        style: TextStyle(
                          color: EcoColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '잠시만 기다려 주세요.',
                        style: TextStyle(
                          color: EcoColors.muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingCard() {
    return EcoCard(
      color: EcoColors.secondary,
      radius: 28,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -44,
              top: -58,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -70,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 36,
              ),
              child: Column(
                children: [
                  _SavingIndicator(),
                  SizedBox(height: 22),
                  Text(
                    '영수증을 저장하고 있어요',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '품목을 분류하고 탄소 배출량을\n계산하는 중입니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD5E7DA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      key: const ValueKey('error'),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: '저장 결과',
            subtitle: '영수증 저장 상태를 확인해요.',
          ),
          const SizedBox(height: 20),
          EcoCard(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color:
                        Theme.of(context).colorScheme.error,
                    size: 41,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '영수증을 저장하지 못했어요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: EcoColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _errorMessage ??
                      '알 수 없는 오류가 발생했습니다.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: EcoColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveReceipt,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          EcoColors.secondary,
                      foregroundColor: Colors.white,
                      minimumSize:
                          const Size.fromHeight(52),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 20,
                    ),
                    label: const Text(
                      '다시 시도',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: '분석 결과',
            subtitle: '이번 소비의 탄소 정보를 확인해요.',
          ),
          const SizedBox(height: 20),
          _buildSuccessCard(summary),
          const SizedBox(height: 26),
          RecommendationResultSection(
            savedResult: savedResult,
            onTapEcoPlaceMap: widget.onTapEcoPlaceMap,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(
    Map<String, dynamic> summary,
  ) {
    final topCategory =
        '${summary['topCategory'] ?? ''}'.trim();

    return EcoCard(
      color: EcoColors.secondary,
      radius: 28,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -66,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -42,
              bottom: -70,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.035,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                24,
              ),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.15,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 43,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '저장이 완료되었어요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    '소비 내역과 탄소 배출량 분석이 완료되었습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD5E7DA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  if (topCategory.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    EcoPill(
                      label: '주요 카테고리 · $topCategory',
                      icon: Icons.category_outlined,
                      background: Colors.white.withValues(
                        alpha: 0.15,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(
                      alpha: 0.14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: '총 금액',
                          value: _formatWon(
                            summary['totalPrice'],
                          ),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _SummaryMetric(
                          label: '탄소 배출량',
                          value: _formatCarbon(
                            summary[
                                'totalEstimatedCarbonKg'],
                          ),
                          icon: Icons.cloud_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryMetric(
                          label: '평균 탄소 점수',
                          value: _displayValue(
                            summary['averageCarbonScore'],
                          ),
                          icon: Icons.eco_outlined,
                        ),
                      ),
                      const _MetricDivider(),
                      Expanded(
                        child: _SummaryMetric(
                          label: '품목 수',
                          value:
                              '${_displayValue(summary['itemCount'])}개',
                          icon:
                              Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.maybePop(
            context,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: EcoColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: EcoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatWon(dynamic value) {
    final amount = _parseNumber(value);

    if (amount == null) {
      return '-';
    }

    return '${_comma(amount.round())}원';
  }

  String _formatCarbon(dynamic value) {
    final carbon = _parseNumber(value);

    if (carbon == null) {
      return '-';
    }

    return '${_compactNumber(carbon)}kg';
  }

  String _displayValue(dynamic value) {
    if (value == null) {
      return '-';
    }

    if (value is num) {
      return _compactNumber(
        value.toDouble(),
      );
    }

    final text = value.toString().trim();

    return text.isEmpty ? '-' : text;
  }

  double? _parseNumber(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  String _compactNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(2)
        .replaceFirst(
          RegExp(r'0+$'),
          '',
        )
        .replaceFirst(
          RegExp(r'\.$'),
          '',
        );
  }

  String _comma(int number) {
    final value = number.abs().toString();

    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;

      buffer.write(value[i]);

      if (reverseIndex > 1 &&
          reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return number < 0
        ? '-$buffer'
        : buffer.toString();
  }
}

class _SavingIndicator extends StatelessWidget {
  const _SavingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.14,
        ),
        shape: BoxShape.circle,
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 4,
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFD5E7DA),
          size: 18,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFD5E7DA),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: Colors.white.withValues(
        alpha: 0.14,
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: EcoColors.line,
            ),
            boxShadow: EcoShadow.soft,
          ),
          child: Icon(
            icon,
            color: EcoColors.text,
            size: 27,
          ),
        ),
      ),
    );
  }
}