import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/eco_design_system.dart';
import '../ranking/model/ranking_user.dart';
import '../ranking/service/ranking_service.dart';

class CarbonDashboardPage extends StatefulWidget {
  const CarbonDashboardPage({
    super.key,
    required this.userId,
    this.onTapHome,
  });

  final String userId;
  final VoidCallback? onTapHome;

  @override
  State<CarbonDashboardPage> createState() => _CarbonDashboardPageState();
}

class _CarbonDashboardPageState extends State<CarbonDashboardPage> {
  static const Color backgroundColor = EcoColors.background;
  static const Color primaryColor = EcoColors.primary;
  static const Color textColor = EcoColors.text;
  static const Color subTextColor = EcoColors.muted;
  static const Color cardColor = Colors.white;

  final RankingService _rankingService = RankingService();

  late final Future<RankingUser?> _currentUserFuture;

  @override
  void initState() {
    super.initState();
    _currentUserFuture = _fetchCurrentUser();
  }

  Future<RankingUser?> _fetchCurrentUser() async {
    final users = await _rankingService.fetchTopUsers(limit: 120);

    for (final user in users) {
      if (user.id == widget.userId) {
        return user;
      }
    }

    return null;
  }

  CollectionReference<Map<String, dynamic>> get _receiptsRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('receipts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: FutureBuilder<RankingUser?>(
        future: _currentUserFuture,
        builder: (context, rankingSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _receiptsRef.snapshots(),
            builder: (context, receiptSnapshot) {
              if (receiptSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                );
              }

              if (receiptSnapshot.hasError) {
                return const Center(
                  child: Text('탄소 대시보드를 불러오지 못했습니다.'),
                );
              }

              final receipts = receiptSnapshot.data?.docs
                      .map((doc) => DashboardReceipt.fromDoc(doc))
                      .toList() ??
                  [];

              receipts.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

              final dashboardData = DashboardData.fromReceipts(receipts);
              final currentUser = rankingSnapshot.data;

              return _buildDashboard(
                data: dashboardData,
                currentUser: currentUser,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDashboard({
    required DashboardData data,
    required RankingUser? currentUser,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 58, 20, 112),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '탄소 대시보드',
                  style: TextStyle(
                    color: EcoColors.text,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              _DashboardHomeButton(
                onTap: () {
                  if (widget.onTapHome != null) {
                    widget.onTapHome!();
                    return;
                  }
                  Navigator.of(context).maybePop();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '소비 데이터를 탄소 관점에서 분석했어요.',
            style: TextStyle(
              color: EcoColors.muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _TotalCarbonCard(
            ecoPoint: currentUser?.ecoPoint,
            carbonScore: data.monthlyCarbonScore,
            carbonDiffFromLastMonth: data.carbonDiffFromLastMonth,
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: EcoStatTile(
                  label: '이번 주 소비',
                  value: '₩${_formatNumber(data.weeklyAmount)}',
                  icon: Icons.date_range_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EcoStatTile(
                  label: '이번 달 품목',
                  value: '${data.monthlyItemCount}개',
                  icon: Icons.receipt_long_rounded,
                  accent: EcoColors.accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const EcoSectionHeader(title: '카테고리별 탄소 점수'),
          const SizedBox(height: 14),

          if (data.categoryScores.isEmpty)
            _EmptyPanel(
              message: '이번 달 소비 기록이 없어 카테고리 점수를 계산할 수 없습니다.',
            )
          else
            ...data.categoryScores.entries.map(
              (entry) => _CategoryScoreBar(
                category: entry.key,
                score: entry.value,
                maxScore: data.maxCategoryScore,
              ),
            ),

          const SizedBox(height: 28),

          const EcoSectionHeader(title: '탄소 점수 높은 품목'),
          const SizedBox(height: 14),

          if (data.topItems.isEmpty)
            _EmptyPanel(
              message: '아직 표시할 품목이 없습니다.',
            )
          else
            ...data.topItems.map(
              (item) => _TopCarbonItemTile(item: item),
            ),

          const SizedBox(height: 28),

          _EcoTipCard(
            topCategory: data.topCategory,
          ),
        ],
      ),
    );
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
}

class _TotalCarbonCard extends StatelessWidget {
  const _TotalCarbonCard({
    required this.ecoPoint,
    required this.carbonScore,
    required this.carbonDiffFromLastMonth,
  });

  final int? ecoPoint;
  final int carbonScore;
  final int carbonDiffFromLastMonth;

  @override
  Widget build(BuildContext context) {
    final diffText = carbonDiffFromLastMonth > 0
        ? '지난달보다 ${carbonDiffFromLastMonth}점 증가했어요.'
        : carbonDiffFromLastMonth < 0
            ? '지난달보다 ${carbonDiffFromLastMonth.abs()}점 감소했어요.'
            : '지난달과 탄소 소비 점수가 같아요.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EcoColors.secondary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: EcoColors.secondary.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 달 탄소 소비 점수',
            style: TextStyle(
              color: Color(0xFFCDE2D4),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$carbonScore점',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            diffText,
            style: TextStyle(
              color: carbonDiffFromLastMonth > 0
                  ? EcoColors.accent
                  : EcoColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: EcoColors.secondary,
                ),
                const SizedBox(width: 10),
                const Text(
                  '내 에코 포인트',
                  style: TextStyle(
                    color: EcoColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  ecoPoint == null ? '-' : '$ecoPoint pts',
                  style: const TextStyle(
                    color: EcoColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
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

class _DashboardHomeButton extends StatelessWidget {
  const _DashboardHomeButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: EcoShadow.soft,
          ),
          child: const Icon(
            Icons.home_outlined,
            color: EcoColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _SmallSummaryCard extends StatelessWidget {
  const _SmallSummaryCard({
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _CarbonDashboardPageState.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            color: _CarbonDashboardPageState.primaryColor,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: _CarbonDashboardPageState.subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: _CarbonDashboardPageState.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryScoreBar extends StatelessWidget {
  const _CategoryScoreBar({
    required this.category,
    required this.score,
    required this.maxScore,
  });

  final String category;
  final int score;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore == 0 ? 0.0 : score / maxScore;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: EcoCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: EcoColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '$score점',
                  style: const TextStyle(
                    color: EcoColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: EcoColors.line,
                color: EcoColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCarbonItemTile extends StatelessWidget {
  const _TopCarbonItemTile({
    required this.item,
  });

  final DashboardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CarbonDashboardPageState.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.line),
        boxShadow: EcoShadow.soft,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: EcoColors.accent,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: _CarbonDashboardPageState.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category.isEmpty ? '미분류' : item.category,
                  style: const TextStyle(
                    color: _CarbonDashboardPageState.subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.carbonScore}점',
            style: const TextStyle(
              color: EcoColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EcoTipCard extends StatelessWidget {
  const _EcoTipCard({
    required this.topCategory,
  });

  final String topCategory;

  @override
  Widget build(BuildContext context) {
    final message = topCategory.isEmpty
        ? '소비 기록이 쌓이면 탄소 소비 패턴을 분석해드려요.'
        : '$topCategory 소비가 가장 높아요. 대체 소비를 고려해볼 수 있어요.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EcoColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.eco_rounded,
            color: EcoColors.secondary,
            size: 30,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _CarbonDashboardPageState.textColor,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _CarbonDashboardPageState.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _CarbonDashboardPageState.subTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.monthlyCarbonScore,
    required this.lastMonthCarbonScore,
    required this.weeklyAmount,
    required this.monthlyItemCount,
    required this.categoryScores,
    required this.topItems,
  });

  final int monthlyCarbonScore;
  final int lastMonthCarbonScore;
  final int weeklyAmount;
  final int monthlyItemCount;
  final Map<String, int> categoryScores;
  final List<DashboardItem> topItems;

  int get carbonDiffFromLastMonth {
    return monthlyCarbonScore - lastMonthCarbonScore;
  }

  int get maxCategoryScore {
    if (categoryScores.isEmpty) {
      return 0;
    }

    return categoryScores.values.reduce((a, b) => a > b ? a : b);
  }

  String get topCategory {
    if (categoryScores.isEmpty) {
      return '';
    }

    final entries = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.first.key;
  }

  factory DashboardData.fromReceipts(List<DashboardReceipt> receipts) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    final monthReceipts = receipts
        .where((receipt) => _isSameMonth(receipt.purchasedAt, currentMonth))
        .toList();

    final lastMonthReceipts = receipts
        .where((receipt) => _isSameMonth(receipt.purchasedAt, lastMonth))
        .toList();

    final weekRange = _weekRangeOf(now);
    final weekReceipts = receipts.where((receipt) {
      final date = receipt.purchasedAt;
      return !date.isBefore(weekRange.start) && date.isBefore(weekRange.end);
    }).toList();

    final monthlyItems = monthReceipts.expand((receipt) => receipt.items).toList();
    final lastMonthItems =
        lastMonthReceipts.expand((receipt) => receipt.items).toList();

    final categoryScores = <String, int>{};

    for (final item in monthlyItems) {
      final category = item.category.isEmpty ? '미분류' : item.category;
      categoryScores[category] =
          (categoryScores[category] ?? 0) + item.carbonScore;
    }

    final topItems = [...monthlyItems]
      ..sort((a, b) => b.carbonScore.compareTo(a.carbonScore));

    return DashboardData(
      monthlyCarbonScore: monthlyItems.fold(
        0,
        (sum, item) => sum + item.carbonScore,
      ),
      lastMonthCarbonScore: lastMonthItems.fold(
        0,
        (sum, item) => sum + item.carbonScore,
      ),
      weeklyAmount: weekReceipts.fold(
        0,
        (sum, receipt) => sum + receipt.totalAmount,
      ),
      monthlyItemCount: monthlyItems.length,
      categoryScores: categoryScores,
      topItems: topItems.take(5).toList(),
    );
  }

  static bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  static DateTimeRange _weekRangeOf(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = normalized.subtract(Duration(days: normalized.weekday - 1));
    final end = start.add(const Duration(days: 7));

    return DateTimeRange(start: start, end: end);
  }
}

class DashboardReceipt {
  const DashboardReceipt({
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
  final List<DashboardItem> items;

  factory DashboardReceipt.fromDoc(
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

    return DashboardReceipt(
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

  static List<DashboardItem> _readItems(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => DashboardItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class DashboardItem {
  const DashboardItem({
    required this.name,
    required this.category,
    required this.price,
    required this.carbonScore,
  });

  final String name;
  final String category;
  final int price;
  final int carbonScore;

  factory DashboardItem.fromMap(Map<String, dynamic> data) {
    final category = _readStringAny([
      data['category'],
      data['categoryName'],
    ], fallback: '');

    final savedCarbonScore = _readIntAny([
      data['carbonScore'],
      data['carbonPoint'],
      data['ecoScore'],
      data['score'],
    ]);

    return DashboardItem(
      name: _readStringAny([
        data['itemName'],
        data['name'],
        data['originalName'],
        data['normalizedName'],
        data['productName'],
      ], fallback: '품목명 없음'),
      category: category,
      price: _readIntAny([
        data['price'],
        data['amount'],
        data['totalPrice'],
        data['unitPrice'],
      ]),
      carbonScore: savedCarbonScore > 0
          ? savedCarbonScore
          : _carbonScoreByCategory(category),
    );
  }
}

String _readStringAny(
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

int _readIntAny(List<dynamic> values) {
  for (final value in values) {
    final parsed = _readInt(value);

    if (parsed > 0) {
      return parsed;
    }
  }

  return 0;
}

int _readInt(dynamic value) {
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

DateTime _readDateAny(List<dynamic> values) {
  for (final value in values) {
    final parsed = _readDate(value);

    if (parsed != null) {
      return parsed;
    }
  }

  return DateTime.now();
}

DateTime? _readDate(dynamic value) {
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

int _carbonScoreByCategory(String category) {
  if (category.contains('일회용')) {
    return 5;
  }

  if (category.contains('식품')) {
    return 4;
  }

  if (category.contains('전자')) {
    return 4;
  }

  if (category.contains('음료')) {
    return 3;
  }

  if (category.contains('카페')) {
    return 3;
  }

  if (category.contains('교통')) {
    return 3;
  }

  if (category.contains('생활')) {
    return 2;
  }

  return 1;
}
