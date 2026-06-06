import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

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

          return {
            'name': name,
            'price': price,
          };
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
        headers: {
          'Content-Type': 'application/json',
        },
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

    final text = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(text) ?? 0;
  }

  Map<String, dynamic>? get _summary {
    final summary = _savedResult?['summary'];
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
        title: const Text('품목 확인'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditableItemList(),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _saveFinalReceipt,
              child: Text(_isSaving ? '저장 중...' : '최종 저장'),
            ),
            if (_savedResult != null) ...[
              const SizedBox(height: 20),
              _buildReceiptIdCard(),
              const SizedBox(height: 12),
              if (summary != null) _buildSummaryCard(summary),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditableItemList() {
    if (_editableItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '품목 후보가 없습니다.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('품목 직접 추가'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '품목 후보 확인',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('추가'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'OCR 결과가 틀릴 수 있으니 품목명과 가격을 확인한 뒤 최종 저장해 주세요.',
            ),
            const SizedBox(height: 12),
            ...List.generate(_editableItems.length, (index) {
              final item = _editableItems[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        initialValue: '${item['originalName'] ?? ''}',
                        decoration: const InputDecoration(
                          labelText: '품목명',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          item['originalName'] = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: '${item['price'] ?? 0}',
                        decoration: const InputDecoration(
                          labelText: '가격',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          item['price'] = _parsePrice(value);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeItem(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
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
          'receiptId: ${_savedResult?['receiptId'] ?? '-'}\n'
          'userId: ${_savedResult?['userId'] ?? '-'}',
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
}