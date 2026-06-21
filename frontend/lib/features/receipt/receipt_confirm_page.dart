import 'package:flutter/material.dart';

import '../../core/theme/eco_design_system.dart';
import 'receipt_result_page.dart';

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
  State<ReceiptConfirmPage> createState() =>
      _ReceiptConfirmPageState();
}

class _ReceiptConfirmPageState
    extends State<ReceiptConfirmPage> {
  late List<Map<String, dynamic>> _editableItems;

  @override
  void initState() {
    super.initState();

    final items = widget.analysisResult['items'];

    _editableItems = items is List
        ? items.map<Map<String, dynamic>>((item) {
            final map = item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{};

            return {
              'originalName':
                  map['originalName'] ?? map['name'] ?? '',
              'price': map['price'] ?? 0,
            };
          }).toList()
        : [];
  }

  void _saveFinalReceipt() {
    FocusScope.of(context).unfocus();

    final finalItems = _editableItems
        .map<Map<String, dynamic>>((item) {
          final name =
              '${item['originalName'] ?? ''}'.trim();

          final price = _parsePrice(
            item['price'],
          );

          return {
            'name': name,
            'price': price,
          };
        })
        .where((item) {
          final name =
              '${item['name'] ?? ''}'.trim();

          final price =
              _parsePrice(item['price']);

          return name.isNotEmpty && price > 0;
        })
        .toList();

    if (finalItems.isEmpty) {
      _showMessage(
        '저장할 품목이 없습니다. 품목명과 가격을 확인해 주세요.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptResultPage(
          userId: widget.userId,
          storeName:
              '${widget.analysisResult['storeName'] ?? ''}',
          purchasedAt:
              widget.analysisResult['purchasedAt'],
          ocrText: widget.ocrText,
          ocrLines: widget.ocrLines,
          items: finalItems,
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _editableItems.add({
        'originalName': '',
        'price': 0,
      });
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

    final text = value
        .toString()
        .replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );

    return int.tryParse(text) ?? 0;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            34,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildOverviewCard(),
              const SizedBox(height: 18),
              _buildEditableItemList(),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saveFinalReceipt,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      EcoColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize:
                      const Size.fromHeight(54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(
                  Icons.save_outlined,
                  size: 21,
                ),
                label: const Text(
                  '최종 영수증 저장',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
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
          onTap: () =>
              Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                '품목 확인',
                style: TextStyle(
                  color: EcoColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.9,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '인식된 내용을 확인하고 저장해요.',
                style: TextStyle(
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

  Widget _buildOverviewCard() {
    final rawStoreName =
        '${widget.analysisResult['storeName'] ?? ''}'
            .trim();

    final storeName = rawStoreName.isEmpty
        ? '영수증'
        : rawStoreName;

    final total = _editableItems.fold<int>(
      0,
      (sum, item) {
        return sum +
            _parsePrice(item['price']);
      },
    );

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
              top: -56,
              child: Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 24,
              bottom: 20,
              child: Icon(
                Icons.receipt_long_outlined,
                color: Colors.white.withValues(
                  alpha: 0.06,
                ),
                size: 90,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '인식 품목 ${_editableItems.length}개',
                              style: const TextStyle(
                                color:
                                    Color(0xFFD5E7DA),
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '예상 결제 금액',
                    style: TextStyle(
                      color: Color(0xFFD5E7DA),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatWon(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
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

  Widget _buildEditableItemList() {
    if (_editableItems.isEmpty) {
      return EcoCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Text(
              '품목 후보가 없습니다.',
              style: TextStyle(
                color: EcoColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '영수증에서 품목을 찾지 못했어요. 직접 추가해 주세요.',
              style: TextStyle(
                color: EcoColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addItem,
              icon: const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label: const Text(
                '품목 직접 추가',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return EcoCard(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      '품목 후보',
                      style: TextStyle(
                        color: EcoColors.text,
                        fontSize: 20,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      '이름과 금액을 확인한 뒤 저장해 주세요.',
                      style: TextStyle(
                        color: EcoColors.muted,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text('추가'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      EcoColors.secondary,
                  textStyle:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ...List.generate(
            _editableItems.length,
            _buildItemEditor,
          ),
        ],
      ),
    );
  }

  Widget _buildItemEditor(int index) {
    final item = _editableItems[index];

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EcoColors.background,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: EcoColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: TextFormField(
              initialValue:
                  '${item['originalName'] ?? ''}',
              decoration:
                  _inputDecoration('품목명'),
              textInputAction:
                  TextInputAction.next,
              onChanged: (value) {
                item['originalName'] = value;
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue:
                  '${item['price'] ?? 0}',
              decoration:
                  _inputDecoration('가격'),
              keyboardType:
                  TextInputType.number,
              onChanged: (value) {
                setState(() {
                  item['price'] =
                      _parsePrice(value);
                });
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () =>
                _removeItem(index),
            color: EcoColors.muted,
            icon: const Icon(
              Icons.delete_outline_rounded,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: EcoColors.muted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: EcoColors.primary,
          width: 1.4,
        ),
      ),
    );
  }

  String _formatWon(int amount) {
    return '${_comma(amount)}원';
  }

  String _comma(int number) {
    final value =
        number.abs().toString();

    final buffer = StringBuffer();

    for (int i = 0;
        i < value.length;
        i++) {
      final reverseIndex =
          value.length - i;

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

class _RoundIconButton
    extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(999),
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
    );
  }
}