import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/eco_design_system.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({
    super.key,
    required this.userId,
    this.onTapScan,
  });

  final String userId;
  final VoidCallback? onTapScan;

  @override
  State<LedgerPage> createState() =>
      _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDate = DateTime.now();

  static const Color backgroundColor =
      EcoColors.background;

  static const Color primaryColor =
      EcoColors.primary;

  static const Color darkGreen =
      EcoColors.secondary;

  static const Color cardColor =
      Color(0xFFFFFFFF);

  static const Color textColor =
      EcoColors.text;

  static const Color subTextColor =
      EcoColors.muted;

  static const Color expenseColor =
      EcoColors.danger;

  @override
  Widget build(BuildContext context) {
    final receiptsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('receipts');

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: receiptsRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState();
            }

            final receipts = snapshot.data?.docs
                    .map(
                      (doc) =>
                          LedgerReceipt.fromDoc(doc),
                    )
                    .toList() ??
                [];

            receipts.sort(
              (a, b) => b.purchasedAt.compareTo(
                a.purchasedAt,
              ),
            );

            final monthReceipts = receipts
                .where(
                  (receipt) => _isSameMonth(
                    receipt.purchasedAt,
                    _selectedMonth,
                  ),
                )
                .toList();

            final weekRange =
                _weekRangeOf(_selectedDate);

            final weekReceipts =
                receipts.where((receipt) {
              final date = receipt.purchasedAt;

              return !date.isBefore(
                    weekRange.start,
                  ) &&
                  date.isBefore(weekRange.end);
            }).toList();

            final dayReceipts = receipts
                .where(
                  (receipt) => _isSameDay(
                    receipt.purchasedAt,
                    _selectedDate,
                  ),
                )
                .toList();

            final monthTotal =
                _sumTotal(monthReceipts);

            final weekTotal =
                _sumTotal(weekReceipts);

            final dayTotal =
                _sumTotal(dayReceipts);

            return RefreshIndicator(
              color: primaryColor,
              onRefresh: () async {
                setState(() {});
              },
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  124,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 20),
                    _buildMonthSummaryCard(
                      monthTotal,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCards(
                      weekTotal: weekTotal,
                      dayTotal: dayTotal,
                    ),
                    const SizedBox(height: 24),
                    _buildDateNavigator(),
                    const SizedBox(height: 24),
                    _buildDailyList(
                      dayReceipts,
                      itemCount:
                          _sumItemCount(dayReceipts),
                    ),
                    const SizedBox(height: 20),
                    const _LedgerTipCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          '가계부',
          style: TextStyle(
            color: textColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.05,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '영수증과 직접 입력으로 소비 내역을 관리해요.',
          style: TextStyle(
            color: subTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSummaryCard(
    int monthTotal,
  ) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(
              alpha: 0.18,
            ),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -68,
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
            left: -52,
            bottom: -80,
            child: Container(
              width: 165,
              height: 165,
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
              22,
              22,
              25,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleIconButton(
                      icon:
                          Icons.chevron_left_rounded,
                      onTap: _goPreviousMonth,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _formatMonth(
                            _selectedMonth,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w600,
                            letterSpacing: -0.25,
                          ),
                        ),
                      ),
                    ),
                    _CircleIconButton(
                      icon:
                          Icons.chevron_right_rounded,
                      onTap: _goNextMonth,
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                const Center(
                  child: Text(
                    '월 소비',
                    style: TextStyle(
                      color: Color(0xFFD8E8D4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Center(
                  child: Text(
                    _formatWon(monthTotal),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1,
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

  Widget _buildSummaryCards({
    required int weekTotal,
    required int dayTotal,
  }) {
    return Row(
      children: [
        Expanded(
          child: _LedgerSummaryCard(
            title: '선택 주 소비',
            value: _formatWon(weekTotal),
            icon: Icons.date_range_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LedgerSummaryCard(
            title: '선택일 소비',
            value: _formatWon(dayTotal),
            icon: Icons.today_rounded,
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
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: EcoColors.line,
              ),
            ),
            child: Center(
              child: Text(
                _formatDateWithWeekday(
                  _selectedDate,
                ),
                style: const TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.35,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SmallRoundButton(
          icon: Icons.chevron_right_rounded,
          onTap: _goNextDay,
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: _goToday,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: primaryColor.withValues(
                  alpha: 0.18,
                ),
              ),
            ),
            child: const Text(
              '오늘',
              style: TextStyle(
                color: darkGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyList(
    List<LedgerReceipt> receipts, {
    required int itemCount,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatShortDate(_selectedDate)} 소비 내역',
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.45,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '영수증 ${receipts.length}개 · 품목 $itemCount개',
                    style: const TextStyle(
                      color: subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed:
                  _showManualEntrySheet,
              style: FilledButton.styleFrom(
                backgroundColor:
                    primaryColor.withValues(
                  alpha: 0.12,
                ),
                foregroundColor: darkGreen,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 19,
              ),
              label: const Text(
                '직접 추가',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (receipts.isEmpty)
          _buildEmptyState()
        else
          ...receipts.map(
            (receipt) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child: _ReceiptCard(
                receipt: receipt,
                onTap: () =>
                    _showReceiptDetail(
                  receipt,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        32,
        22,
        32,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: EcoColors.line,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: primaryColor.withValues(
              alpha: 0.65,
            ),
            size: 44,
          ),
          const SizedBox(height: 14),
          const Text(
            '선택한 날짜의 소비 기록이 없습니다.',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 7),
          const Text(
            '영수증을 분석하면 소비 내역이\n가계부에 자동으로 저장돼요.',
            style: TextStyle(
              color: subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: widget.onTapScan,
            style: FilledButton.styleFrom(
              backgroundColor: darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(
              Icons.camera_alt_outlined,
              size: 20,
            ),
            label: const Text(
              '영수증 분석하기',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
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
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showManualEntrySheet() {
    final titleController =
        TextEditingController();

    final amountController =
        TextEditingController();

    final memoController =
        TextEditingController();

    String selectedCategory = '기타';
    DateTime selectedDate = _selectedDate;

    final categories = [
      '식품',
      '음료',
      '생활용품',
      '일회용품',
      '전자제품',
      '교통',
      '카페',
      '기타',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor:
          EcoColors.background,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (
            context,
            setModalState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 18,
                bottom: MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .grey.shade300,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            999,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    const Text(
                      '지출 추가',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 24,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '영수증 없이 소비 내역을 직접 기록해요.',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                    const SizedBox(
                      height: 22,
                    ),
                    _ManualInputField(
                      controller:
                          titleController,
                      label: '내용 / 매장명',
                      hintText:
                          '예: 스타벅스, 편의점, 점심식사',
                      icon: Icons
                          .storefront_rounded,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    _ManualInputField(
                      controller:
                          amountController,
                      label: '금액',
                      hintText: '예: 5500',
                      icon:
                          Icons.payments_rounded,
                      keyboardType:
                          TextInputType.number,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const Text(
                      '카테고리',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                      ),
                      decoration:
                          BoxDecoration(
                        color: cardColor,
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                        border: Border.all(
                          color:
                              EcoColors.line,
                        ),
                      ),
                      child:
                          DropdownButtonHideUnderline(
                        child:
                            DropdownButton<String>(
                          value:
                              selectedCategory,
                          isExpanded: true,
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                          items: categories
                              .map(
                                (category) =>
                                    DropdownMenuItem(
                                  value:
                                      category,
                                  child: Text(
                                    category,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setModalState(() {
                              selectedCategory =
                                  value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    const Text(
                      '날짜',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      onTap: () async {
                        final picked =
                            await showDatePicker(
                          context: context,
                          initialDate:
                              selectedDate,
                          firstDate:
                              DateTime(2020),
                          lastDate:
                              DateTime(2100),
                        );

                        if (picked ==
                            null) {
                          return;
                        }

                        setModalState(() {
                          selectedDate =
                              picked;
                        });
                      },
                      child: Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        decoration:
                            BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                          border:
                              Border.all(
                            color:
                                EcoColors.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .calendar_month_rounded,
                              color:
                                  darkGreen,
                              size: 22,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              _formatDateWithWeekday(
                                selectedDate,
                              ),
                              style:
                                  const TextStyle(
                                color:
                                    textColor,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    _ManualInputField(
                      controller:
                          memoController,
                      label: '메모',
                      hintText: '선택 입력',
                      icon: Icons
                          .edit_note_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    SizedBox(
                      width:
                          double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await _saveManualEntry(
                            context:
                                context,
                            title:
                                titleController
                                    .text,
                            amountText:
                                amountController
                                    .text,
                            category:
                                selectedCategory,
                            memo:
                                memoController
                                    .text,
                            selectedDate:
                                selectedDate,
                          );
                        },
                        style:
                            FilledButton
                                .styleFrom(
                          backgroundColor:
                              darkGreen,
                          foregroundColor:
                              Colors.white,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              18,
                            ),
                          ),
                        ),
                        child: const Text(
                          '저장하기',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      amountController.dispose();
      memoController.dispose();
    });
  }

  Future<void> _saveManualEntry({
    required BuildContext context,
    required String title,
    required String amountText,
    required String category,
    required String memo,
    required DateTime selectedDate,
  }) async {
    final messenger =
        ScaffoldMessenger.of(context);

    final navigator =
        Navigator.of(context);

    final trimmedTitle = title.trim();

    final amount = int.tryParse(
      amountText.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      ),
    );

    if (trimmedTitle.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '내용 또는 매장명을 입력해주세요.',
          ),
        ),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '금액을 올바르게 입력해주세요.',
          ),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final purchasedAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      now.hour,
      now.minute,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('receipts')
          .add({
        'storeName': trimmedTitle,
        'totalAmount': amount,
        'totalPrice': amount,
        'purchasedAt':
            Timestamp.fromDate(purchasedAt),
        'createdAt':
            FieldValue.serverTimestamp(),
        'source': 'manual',
        'memo': memo.trim(),
        'items': [
          {
            'itemName': trimmedTitle,
            'name': trimmedTitle,
            'category': category,
            'price': amount,
          },
        ],
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDate = selectedDate;
        _selectedMonth = DateTime(
          selectedDate.year,
          selectedDate.month,
        );
      });

      navigator.pop();

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            '지출 내역이 추가되었습니다.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '지출 내역 저장에 실패했습니다. $error',
          ),
        ),
      );
    }
  }

  void _showReceiptDetail(
    LedgerReceipt receipt,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          EcoColors.background,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (
            context,
            scrollController,
          ) {
            return SingleChildScrollView(
              controller:
                  scrollController,
              padding:
                  const EdgeInsets.fromLTRB(
                22,
                18,
                22,
                32,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(
                          999,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  Text(
                    receipt.storeName,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(
                      receipt.purchasedAt,
                    ),
                    style: const TextStyle(
                      color: subTextColor,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color: cardColor,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '총 금액',
                          style: TextStyle(
                            color:
                                subTextColor,
                            fontSize: 14,
                            fontWeight:
                                FontWeight
                                    .w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatWon(
                            receipt.totalAmount,
                          ),
                          style:
                              const TextStyle(
                            color:
                                expenseColor,
                            fontSize: 21,
                            fontWeight:
                                FontWeight
                                    .w700,
                            letterSpacing:
                                -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  const Text(
                    '품목',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  if (receipt.items.isEmpty)
                    const Text(
                      '품목 정보가 없습니다.',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    )
                  else
                    ...receipt.items.map(
                      (item) => Container(
                        margin:
                            const EdgeInsets
                                .only(
                          bottom: 10,
                        ),
                        padding:
                            const EdgeInsets
                                .all(
                          16,
                        ),
                        decoration:
                            BoxDecoration(
                          color: cardColor,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            18,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    item.name,
                                    style:
                                        const TextStyle(
                                      color:
                                          textColor,
                                      fontSize:
                                          16,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    item.category
                                            .isEmpty
                                        ? '미분류'
                                        : item
                                            .category,
                                    style:
                                        const TextStyle(
                                      color:
                                          subTextColor,
                                      fontSize:
                                          13,
                                      fontWeight:
                                          FontWeight
                                              .w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatWon(
                                item.price,
                              ),
                              style:
                                  const TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight:
                                    FontWeight
                                        .w700,
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
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );

      _selectedDate = _safeDateInMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        _selectedDate.day,
      );
    });
  }

  void _goNextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );

      _selectedDate = _safeDateInMonth(
        _selectedMonth.year,
        _selectedMonth.month,
        _selectedDate.day,
      );
    });
  }

  void _goPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(
        const Duration(days: 1),
      );

      _selectedMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month,
      );
    });
  }

  void _goNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(
        const Duration(days: 1),
      );

      _selectedMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month,
      );
    });
  }

  void _goToday() {
    final now = DateTime.now();

    setState(() {
      _selectedDate = now;
      _selectedMonth = DateTime(
        now.year,
        now.month,
      );
    });
  }

  int _sumTotal(
    List<LedgerReceipt> receipts,
  ) {
    return receipts.fold(
      0,
      (sum, receipt) =>
          sum + receipt.totalAmount,
    );
  }

  int _sumItemCount(
    List<LedgerReceipt> receipts,
  ) {
    return receipts.fold(
      0,
      (sum, receipt) =>
          sum + receipt.items.length,
    );
  }

  DateTimeRange _weekRangeOf(
    DateTime date,
  ) {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final start = normalized.subtract(
      Duration(
        days: normalized.weekday - 1,
      ),
    );

    final end = start.add(
      const Duration(days: 7),
    );

    return DateTimeRange(
      start: start,
      end: end,
    );
  }

  bool _isSameMonth(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month;
  }

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  DateTime _safeDateInMonth(
    int year,
    int month,
    int day,
  ) {
    final lastDay =
        DateTime(year, month + 1, 0).day;

    final safeDay =
        day > lastDay ? lastDay : day;

    return DateTime(
      year,
      month,
      safeDay,
    );
  }

  String _formatWon(int amount) {
    return '₩${_formatNumber(amount)}';
  }

  String _formatNumber(int number) {
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

  String _formatMonth(DateTime date) {
    return '${date.year}년 ${date.month}월';
  }

  String _formatShortDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  String _formatDateWithWeekday(
    DateTime date,
  ) {
    const weekdays = [
      '월',
      '화',
      '수',
      '목',
      '금',
      '토',
      '일',
    ];

    return '${date.month}월 ${date.day}일 '
        '${weekdays[date.weekday - 1]}요일';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour
        .toString()
        .padLeft(2, '0');

    final minute = date.minute
        .toString()
        .padLeft(2, '0');

    return '${date.year}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')} '
        '$hour:$minute';
  }
}

class _LedgerSummaryCard
    extends StatelessWidget {
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
    return EcoCard(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        18,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _LedgerPageState
                  .primaryColor
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color:
                  _LedgerPageState.darkGreen,
              size: 22,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: _LedgerPageState
                  .subTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color:
                  _LedgerPageState.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
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
        '${receipt.purchasedAt.hour.toString().padLeft(2, '0')}:'
        '${receipt.purchasedAt.minute.toString().padLeft(2, '0')}';

    return Material(
      color: _LedgerPageState.cardColor,
      borderRadius:
          BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(20),
            border: Border.all(
              color: EcoColors.line,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _LedgerPageState
                      .primaryColor
                      .withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color:
                      _LedgerPageState.darkGreen,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.storeName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LedgerPageState
                            .textColor,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt.itemSummary,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _LedgerPageState
                            .subTextColor,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    '₩${_comma(receipt.totalAmount)}',
                    style: const TextStyle(
                      color: _LedgerPageState
                          .expenseColor,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      color: _LedgerPageState
                          .subTextColor,
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w500,
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

class _LedgerTipCard extends StatelessWidget {
  const _LedgerTipCard();

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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.82,
              ),
              borderRadius:
                  BorderRadius.circular(14),
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
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '영수증 스캔과 직접 입력 기록을 날짜별로 함께 확인할 수 있어요.',
                  style: TextStyle(
                    color: EcoColors.muted,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w500,
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

class _CircleIconButton
    extends StatelessWidget {
  const _CircleIconButton({
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.14,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}

class _SmallRoundButton
    extends StatelessWidget {
  const _SmallRoundButton({
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _LedgerPageState.cardColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: EcoColors.line,
          ),
        ),
        child: Icon(
          icon,
          color:
              _LedgerPageState.darkGreen,
          size: 23,
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
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc,
  ) {
    final data = doc.data();

    final items =
        _readItems(data['items']);

    final totalAmount =
        _readIntAny([
      data['totalAmount'],
      data['totalPrice'],
      data['total'],
      data['amount'],
      data['price'],
    ]);

    return LedgerReceipt(
      id: doc.id,
      storeName: _readStringAny(
        [
          data['storeName'],
          data['store'],
          data['placeName'],
          data['merchantName'],
          data['marketName'],
        ],
        fallback: '상호명 없음',
      ),
      purchasedAt: _readDateAny([
        data['purchasedAt'],
        data['createdAt'],
        data['savedAt'],
        data['date'],
      ]),
      totalAmount: totalAmount > 0
          ? totalAmount
          : items.fold(
              0,
              (sum, item) =>
                  sum + item.price,
            ),
      items: items,
    );
  }

  static List<LedgerItem> _readItems(
    dynamic value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
              LedgerItem.fromMap(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  static String _readStringAny(
    List<dynamic> values, {
    required String fallback,
  }) {
    for (final value in values) {
      if (value is String &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  static int _readIntAny(
    List<dynamic> values,
  ) {
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
      return int.tryParse(
            value.replaceAll(
              RegExp(r'[^0-9-]'),
              '',
            ),
          ) ??
          0;
    }

    return 0;
  }

  static DateTime _readDateAny(
    List<dynamic> values,
  ) {
    for (final value in values) {
      final parsed = _readDate(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  static DateTime? _readDate(
    dynamic value,
  ) {
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
      return DateTime
          .fromMillisecondsSinceEpoch(
        value,
      );
    }

    return null;
  }
}

class _ManualInputField
    extends StatelessWidget {
  const _ManualInputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _LedgerPageState
                .textColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(
              icon,
              color: _LedgerPageState
                  .primaryColor,
            ),
            filled: true,
            fillColor:
                _LedgerPageState.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide: BorderSide(
                color: _LedgerPageState
                    .primaryColor
                    .withValues(
                  alpha: 0.14,
                ),
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide: BorderSide(
                color: _LedgerPageState
                    .primaryColor
                    .withValues(
                  alpha: 0.14,
                ),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide:
                  const BorderSide(
                color: _LedgerPageState
                    .primaryColor,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
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

  factory LedgerItem.fromMap(
    Map<String, dynamic> data,
  ) {
    return LedgerItem(
      name: _readStringAny(
        [
          data['itemName'],
          data['name'],
          data['originalName'],
          data['normalizedName'],
          data['productName'],
        ],
        fallback: '품목명 없음',
      ),
      category: _readStringAny(
        [
          data['category'],
          data['categoryName'],
        ],
        fallback: '',
      ),
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
      if (value is String &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  static int _readIntAny(
    List<dynamic> values,
  ) {
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
      return int.tryParse(
            value.replaceAll(
              RegExp(r'[^0-9-]'),
              '',
            ),
          ) ??
          0;
    }

    return 0;
  }
}