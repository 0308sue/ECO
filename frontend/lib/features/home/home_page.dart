import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.userId,
    required this.onTapScan,
    required this.onTapEcoPlaceMap,
  });

  final String userId;
  final VoidCallback onTapScan;
  final VoidCallback onTapEcoPlaceMap;

  static const Color backgroundColor = Color(0xFFF7FAF2);
  static const Color primaryColor = Color(0xFF3B713B);
  static const Color textColor = Color(0xFF222820);
  static const Color subTextColor = Color(0xFF5A6358);
  static const Color cardColor = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: _buildHomeBody(context),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopArea(),
            const SizedBox(height: 28),
            _buildMainActionButton(
              icon: Icons.document_scanner_rounded,
              title: '영수증 OCR 분석하기',
              subtitle: '영수증을 촬영하고 탄소 점수를 확인해보세요.',
              onTap: onTapScan,
            ),
            const SizedBox(height: 28),
            _buildSectionTitle('친환경 추천'),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.shopping_bag_rounded,
              title: '대체품 추천 보기',
              subtitle: '소비 품목을 바탕으로 친환경 대체품을 확인해요.',
              onTap: () {
                _showPreparingMessage(context, '대체품 추천 페이지 연결 예정');
              },
            ),
            const SizedBox(height: 12),
            _FeatureTile(
              icon: Icons.map_rounded,
              title: '주변 친환경 장소 보기',
              subtitle: '제로웨이스트샵, 리필샵 등 주변 장소를 확인해요.',
              onTap: onTapEcoPlaceMap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArea() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ECO 홈',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: HomePage.textColor,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: 24),
        Text(
          '오늘도 친환경 소비를 기록해볼까요?',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            color: HomePage.textColor,
            height: 1.4,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '영수증 분석부터 친환경 장소 추천까지 한 번에 확인해요.',
          style: TextStyle(
            fontSize: 16,
            color: HomePage.subTextColor,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMainActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: HomePage.primaryColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: HomePage.textColor,
        letterSpacing: -0.5,
      ),
    );
  }

  void _showPreparingMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: HomePage.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: HomePage.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: HomePage.textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: HomePage.subTextColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: HomePage.subTextColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}