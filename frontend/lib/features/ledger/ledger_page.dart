import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({
    super.key,
    required this.userId,
    this.onTapScan,
  });

  final String userId;
  final VoidCallback? onTapScan;

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  static const Color backgroundColor = Color(0xFFF7FAF2);
  static const Color primaryColor = Color(0xFF3B713B);
  static const Color darkGreen = Color(0xFF244D2A);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF222820);
  static const Color subTextColor = Color(0xFF5A6358);
  static const Color expenseColor = Color(0xFFD95D59);

  @override
  Widget build(BuildContext context) {
    final receiptsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('receipts');

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: receiptsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final receipts = snapshot.data?.docs
                    .map((doc) => LedgerReceipt.fromDoc(doc))
                    .toList() ??
                [];

            receipts.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

            final monthReceipts = receipts
                .where((receipt) => _isSameMonth(receipt.purchasedAt, _selectedMonth))
                .toList();

            final weekRange = _weekRangeOf(_selectedDate);
            final weekReceipts = receipts.where((receipt) {
              final date = receipt.purchasedAt;
              return !date.isBefore(weekRange.start) &&
                  date.isBefore(weekRange.end);
            }).toList();

            final dayReceipts = receipts
                .where((receipt) => _isSameDay(receipt.purchasedAt, _selectedDate))
                .toList();

            final monthTotal = _sumTotal(monthReceipts);
            final weekTotal = _sumTotal(weekReceipts);
            final dayTotal = _sumTotal(dayReceipts);

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(monthTotal),
                    const SizedBox(height: 18),
                    _buildSummaryCards(
                      weekTotal: weekTotal,
                      dayTotal: dayTotal,
                      receiptCount: dayReceipts.length,
                      itemCount: _sumItemCount(dayReceipts),
                    ),
                    const SizedBox(height: 22),
                    _buildDateNavigator(),
                    const SizedBox(height: 16),
                    _buildDailyList(dayReceipts),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int monthTotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '가계부',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.chevron_left_rounded,
                onTap: _goPreviousMonth,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    _formatMonth(_selectedMonth),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _CircleIconButton(
                icon: Icons.chevron_right_rounded,
                onTap: _goNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            '월 소비',
            style: TextStyle(
              color: Color(0xFFD8E8D4),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatWon(monthTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards({
    required int weekTotal,
    required int dayTotal,
    required int receiptCount,
    required int itemCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LedgerSummaryCard(
                title: '이번 주 소비',
                value: _formatWon(weekTotal),
                icon: Icons.date_range_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LedgerSummaryCard(
                title: '하루 소비',
                value: _formatWon(dayTotal),
                icon: Icons.today_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: primaryColor,
                size: 26,
              ),
              const SizedBox(width: 12),
              Text(
                '선택 날짜 기록',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '영수증 $receiptCount개 · 품목 $itemCount개',
                style: const TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateNavigator() {
    return Row(
      children: [
        _SmallRoundButton(
          icon: Icons.chevron_left_rounded,
          onTap: _goPreviousDay,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Text(
                _formatDateWithWeekday(_selectedDate),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SmallRoundButton(
          icon: Icons.chevron_right_rounded,
          onTap: _goNextDay,
        ),
        const SizedBox(width: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _goToday,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              '오늘',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyList(List<LedgerReceipt> receipts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_formatShortDate(_selectedDate)} 소비 내역',
          style: const TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (receipts.isEmpty)
          _buildEmptyState()
        else
          ...receipts.map(
            (receipt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReceiptCard(
                receipt: receipt,
                onTap: () => _showReceiptDetail(receipt),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 34, 22, 34),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: primaryColor.withValues(alpha: 0.65),
            size: 46,
          ),
          const SizedBox(height: 16),
          const Text(
            '선택한 날짜의 영수증 기록이 없습니다.',
            style: TextStyle(
              color: textColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            '영수증을 분석하면 소비 내역이\n가계부에 자동으로 저장돼요.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 14,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.onTapScan,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('영수증 분석하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Text(
        '가계부를 불러오지 못했습니다.',
        style: TextStyle(
          color: subTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showReceiptDetail(LedgerReceipt receipt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    receipt.storeName,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(receipt.purchasedAt),
                    style: const TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '총 금액',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatWon(receipt.totalAmount),
                          style: const TextStyle(
                            color: expenseColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    '품목',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (receipt.items.isEmpty)
                    const Text(
                      '품목 정보가 없습니다.',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 15,
                      ),
                    )
                  else
                    ...receipt.items.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.category.isEmpty ? '미분류' : item.category,
                                    style: const TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatWon(item.price),
                              style: const TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _goPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDate = _safeDateInMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        _selectedDate.day,
      );
    });
  }

  void _goNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDate = _safeDateInMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        _selectedDate.day,
      );
    });
  }

  void _goPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _selectedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  void _goNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _selectedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    });
  }

  void _goToday() {
    final now = DateTime.now();

    setState(() {
      _selectedDate = now;
      _selectedMonth = DateTime(now.year, now.month);
    });
  }

  int _sumTotal(List<LedgerReceipt> receipts) {
    return receipts.fold(0, (sum, receipt) => sum + receipt.totalAmount);
  }

  int _sumItemCount(List<LedgerReceipt> receipts) {
    return receipts.fold(0, (sum, receipt) => sum + receipt.items.length);
  }

  DateTimeRange _weekRangeOf(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = normalized.subtract(Duration(days: normalized.weekday - 1));
    final end = start.add(const Duration(days: 7));
    return DateTimeRange(start: start, end: end);
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _safeDateInMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day > lastDay ? lastDay : day;
    return DateTime(year, month, safeDay);
  }

  String _formatWon(int amount) {
    return '₩${_formatNumber(amount)}';
  }

  String _formatNumber(int number) {
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

  String _formatMonth(DateTime date) {
    return '${date.year}년 ${date.month}월';
  }

  String _formatShortDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _formatDateWithWeekday(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${date.month}월 ${date.day}일 ${weekdays[date.weekday - 1]}요일';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} $hour:$minute';
  }
}

class _LedgerSummaryCard extends StatelessWidget {
  const _LedgerSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: _LedgerPageState.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _LedgerPageState.primaryColor,
            size: 26,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _LedgerPageState.subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _LedgerPageState.textColor,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.receipt,
    required this.onTap,
  });

  final LedgerReceipt receipt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time =
        '${receipt.purchasedAt.hour.toString().padLeft(2, '0')}:${receipt.purchasedAt.minute.toString().padLeft(2, '0')}';

    return Material(
      color: _LedgerPageState.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _LedgerPageState.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: _LedgerPageState.primaryColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.storeName,
                      style: const TextStyle(
                        color: _LedgerPageState.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      receipt.itemSummary,
                      style: const TextStyle(
                        color: _LedgerPageState.subTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₩${_comma(receipt.totalAmount)}',
                    style: const TextStyle(
                      color: _LedgerPageState.expenseColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      color: _LedgerPageState.subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

class _SmallRoundButton extends StatelessWidget {
  const _SmallRoundButton({
    required this.icon,
    required this.onTap,
  });

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
          color: _LedgerPageState.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: _LedgerPageState.primaryColor.withValues(alpha: 0.16),
          ),
        ),
        child: Icon(
          icon,
          color: _LedgerPageState.primaryColor,
          size: 25,
        ),
      ),
    );
  }
}

class LedgerReceipt {
  const LedgerReceipt({
    required this.id,
    required this.storeName,
    required this.purchasedAt,
    required this.totalAmount,
    required this.items,
  });

  final String id;
  final String storeName;
  final DateTime purchasedAt;
  final int totalAmount;
  final List<LedgerItem> items;

  String get itemSummary {
    if (items.isEmpty) {
      return '품목 정보 없음';
    }

    if (items.length == 1) {
      return items.first.name;
    }

    return '${items.first.name} 외 ${items.length - 1}개';
  }

  factory LedgerReceipt.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final items = _readItems(data['items']);

    final totalAmount = _readIntAny([
      data['totalAmount'],
      data['totalPrice'],
      data['total'],
      data['amount'],
      data['price'],
    ]);

    return LedgerReceipt(
      id: doc.id,
      storeName: _readStringAny([
        data['storeName'],
        data['store'],
        data['placeName'],
        data['merchantName'],
        data['marketName'],
      ], fallback: '상호명 없음'),
      purchasedAt: _readDateAny([
        data['purchasedAt'],
        data['createdAt'],
        data['savedAt'],
        data['date'],
      ]),
      totalAmount: totalAmount > 0
          ? totalAmount
          : items.fold(0, (sum, item) => sum + item.price),
      items: items,
    );
  }

  static List<LedgerItem> _readItems(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => LedgerItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  static String _readStringAny(
    List<dynamic> values, {
    required String fallback,
  }) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  static int _readIntAny(List<dynamic> values) {
    for (final value in values) {
      final parsed = _readInt(value);

      if (parsed > 0) {
        return parsed;
      }
    }

    return 0;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
    }

    return 0;
  }

  static DateTime _readDateAny(List<dynamic> values) {
    for (final value in values) {
      final parsed = _readDate(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return null;
  }
}

class LedgerItem {
  const LedgerItem({
    required this.name,
    required this.category,
    required this.price,
  });

  final String name;
  final String category;
  final int price;

  factory LedgerItem.fromMap(Map<String, dynamic> data) {
    return LedgerItem(
      name: _readStringAny([
        data['itemName'],
        data['name'],
        data['originalName'],
        data['normalizedName'],
        data['productName'],
      ], fallback: '품목명 없음'),
      category: _readStringAny([
        data['category'],
        data['categoryName'],
      ], fallback: ''),
      price: _readIntAny([
        data['price'],
        data['amount'],
        data['totalPrice'],
        data['unitPrice'],
      ]),
    );
  }

  static String _readStringAny(
    List<dynamic> values, {
    required String fallback,
  }) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  static int _readIntAny(List<dynamic> values) {
    for (final value in values) {
      final parsed = _readInt(value);

      if (parsed > 0) {
        return parsed;
      }
    }

    return 0;
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(value.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
    }

    return 0;
  }
}