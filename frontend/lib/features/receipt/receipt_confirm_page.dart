import 'package:flutter/material.dart';

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
  State<ReceiptConfirmPage> createState() => _ReceiptConfirmPageState();
}

class _ReceiptConfirmPageState extends State<ReceiptConfirmPage> {
  late List<Map<String, dynamic>> _editableItems;


  @override
  void initState() {
    super.initState();

    final items = widget.analysisResult['items'];

    _editableItems = items is List
        ? items.map<Map<String, dynamic>>((item) {
            final map = Map<String, dynamic>.from(item as Map);

            return {
              'originalName': map['originalName'] ?? map['name'] ?? '',
              'price': map['price'] ?? 0,
            };
          }).toList()
        : [];
  }

  void _saveFinalReceipt() {
    final finalItems = _editableItems
        .map<Map<String, dynamic>>((item) {
          final name = '${item['originalName'] ?? ''}'.trim();
          final price = _parsePrice(item['price']);

          return {
            'name': name,
            'price': price,
          };
        })
        .where((item) {
          final name = '${item['name'] ?? ''}'.trim();
          final price = item['price'] as int;

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
          storeName: '${widget.analysisResult['storeName'] ?? ''}',
          purchasedAt: widget.analysisResult['purchasedAt'],
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

    final text = value.toString().replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(text) ?? 0;
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
        title: const Text('품목 확인'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditableItemList(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saveFinalReceipt,
              icon: const Icon(Icons.save_outlined),
              label: const Text('최종 영수증 저장'),
            ),
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
}