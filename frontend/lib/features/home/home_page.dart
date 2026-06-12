import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../dashboard/carbon_dashboard_page.dart';
import '../ranking/model/ranking_user.dart';
import '../ranking/service/ranking_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.userId,
    required this.onTapScan,
    required this.onTapEcoPlaceMap,
  });

  static const Color backgroundColor = Color(0xFFF7FAF2);
  static const Color primaryColor = Color(0xFF3B713B);
  static const Color darkGreen = Color(0xFF244D2A);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF222820);
  static const Color subTextColor = Color(0xFF5A6358);

  final String userId;
  final VoidCallback onTapScan;
  final VoidCallback onTapEcoPlaceMap;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RankingService _rankingService = RankingService();

  late Future<RankingUser?> _currentUserFuture;

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

  Future<void> _refresh() async {
    setState(() {
      _currentUserFuture = _fetchCurrentUser();
    });

    try {
      await _currentUserFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: HomePage.backgroundColor,
      child: SafeArea(
        child: FutureBuilder<RankingUser?>(
          future: _currentUserFuture,
          builder: (context, rankingSnapshot) {
            final currentUser = rankingSnapshot.data;

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _receiptsRef.snapshots(),
              builder: (context, receiptSnapshot) {
                if (receiptSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: HomePage.primaryColor,
                    ),
                  );
                }

                if (receiptSnapshot.hasError) {
                  return const Center(
                    child: Text(
                      '홈 정보를 불러오지 못했습니다.',
                      style: TextStyle(
                        color: HomePage.subTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }

                final receipts = receiptSnapshot.data?.docs
                        .map((doc) => DashboardReceipt.fromDoc(doc))
                        .toList() ??
                    [];

                receipts.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

                final dashboardData = DashboardData.fromReceipts(receipts);
                final recentRecords = RecentConsumption.fromReceipts(receipts);

                return RefreshIndicator(
                  color: HomePage.primaryColor,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _CarbonSummaryCard(
                          ecoPoint: currentUser?.ecoPoint,
                          monthlyCarbonScore:
                              dashboardData.monthlyCarbonScore,
                          weeklyAmount: dashboardData.weeklyAmount,
                          topCategory: dashboardData.topCategory,
                          onTapDetail: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CarbonDashboardPage(
                                  userId: widget.userId,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 26),
                        _buildQuickButtons(),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '최근 소비 기록',
                                style: TextStyle(
                                  color: HomePage.textColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onTapScan,
                              child: const Text(
                                '스캔하기',
                                style: TextStyle(
                                  color: HomePage.primaryColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (recentRecords.isEmpty)
                          const _EmptyRecentPanel()
                        else
                          ...recentRecords.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 11),
                              child: _RecentRecordTile(record: record),
                            ),
                          ),
                        const SizedBox(height: 26),
                        _RecommendationMoveCard(
                          onTap: widget.onTapEcoPlaceMap,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ECO',
          style: TextStyle(
            color: HomePage.darkGreen,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 6),
        Text(
          '나의 탄소 소비를 한눈에 확인해요',
          style: TextStyle(
            color: HomePage.subTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickButtons() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: '영수증 스캔',
            description: '소비 기록 추가',
            icon: Icons.camera_alt_outlined,
            onTap: widget.onTapScan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: '추천 보기',
            description: '친환경 장소 확인',
            icon: Icons.eco_rounded,
            onTap: widget.onTapEcoPlaceMap,
          ),
        ),
      ],
    );
  }
}

class _CarbonSummaryCard extends StatelessWidget {
  const _CarbonSummaryCard({
    required this.ecoPoint,
    required this.monthlyCarbonScore,
    required this.weeklyAmount,
    required this.topCategory,
    required this.onTapDetail,
  });

  final int? ecoPoint;
  final int monthlyCarbonScore;
  final int weeklyAmount;
  final String topCategory;
  final VoidCallback onTapDetail;

  @override
  Widget build(BuildContext context) {
    final categoryText = topCategory.isEmpty ? '-' : topCategory;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: HomePage.darkGreen,
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
            '이번 달 탄소 소비 점수',
            style: TextStyle(
              color: Color(0xFFD8E8D4),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$monthlyCarbonScore점',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  '내 에코 포인트',
                  style: TextStyle(
                    color: Color(0xFFD8E8D4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  ecoPoint == null ? '-' : '${_formatNumber(ecoPoint!)} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniInfoBox(
                  title: '이번 주 소비',
                  value: _formatWon(weeklyAmount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoBox(
                  title: '주의 카테고리',
                  value: categoryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTapDetail,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: HomePage.darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '탄소 대시보드 자세히 보기',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoBox extends StatelessWidget {
  const _MiniInfoBox({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFD8E8D4),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomePage.cardColor,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: HomePage.primaryColor,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: HomePage.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: HomePage.subTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  const _RecentRecordTile({
    required this.record,
  });

  final RecentConsumption record;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomePage.cardColor,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HomePage.primaryColor.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: HomePage.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: HomePage.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomePage.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.category} · ${_formatWon(record.amount)} · ${_formatShortDate(record.purchasedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: HomePage.subTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${record.carbonScore}점',
                style: const TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationMoveCard extends StatelessWidget {
  const _RecommendationMoveCard({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.teal.shade50,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          child: const Row(
            children: [
              Icon(
                Icons.eco_rounded,
                size: 34,
                color: HomePage.primaryColor,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '친환경 장소 추천 보기',
                      style: TextStyle(
                        color: HomePage.textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '내 소비를 바탕으로 친환경 장소를 확인해요.',
                      style: TextStyle(
                        color: HomePage.subTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: HomePage.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentPanel extends StatelessWidget {
  const _EmptyRecentPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: HomePage.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: HomePage.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: HomePage.primaryColor,
            size: 42,
          ),
          SizedBox(height: 12),
          Text(
            '아직 소비 기록이 없습니다.',
            style: TextStyle(
              color: HomePage.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '영수증을 스캔하거나 가계부에 직접 기록해보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HomePage.subTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentConsumption {
  const RecentConsumption({
    required this.title,
    required this.category,
    required this.amount,
    required this.carbonScore,
    required this.purchasedAt,
  });

  final String title;
  final String category;
  final int amount;
  final int carbonScore;
  final DateTime purchasedAt;

  static List<RecentConsumption> fromReceipts(
    List<DashboardReceipt> receipts,
  ) {
    return receipts.take(3).map((receipt) {
      final firstItem = receipt.items.isEmpty ? null : receipt.items.first;

      final totalCarbonScore = receipt.items.fold<int>(
        0,
        (sum, item) => sum + item.carbonScore,
      );

      final title = firstItem == null || firstItem.name.trim().isEmpty
          ? receipt.storeName
          : firstItem.name;

      final category = firstItem == null || firstItem.category.trim().isEmpty
          ? '미분류'
          : firstItem.category;

      return RecentConsumption(
        title: title,
        category: category,
        amount: receipt.totalAmount,
        carbonScore: totalCarbonScore,
        purchasedAt: receipt.purchasedAt,
      );
    }).toList();
  }
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

String _formatShortDate(DateTime date) {
  return '${date.month}월 ${date.day}일';
}