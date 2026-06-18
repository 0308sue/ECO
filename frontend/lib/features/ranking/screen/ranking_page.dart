import 'package:flutter/material.dart';

import '../model/ranking_user.dart';
import '../service/ranking_service.dart';

class RankingPage extends StatelessWidget {
  RankingPage({
    super.key,
    required this.currentUserId,
    RankingService? rankingService,
  }) : _rankingService = rankingService ?? RankingService();

  static const Color _backgroundColor = Color(0xFFF8FBF2);
  static const Color _primaryColor = Color(0xFF23552D);
  static const Color _secondaryGreen = Color(0xFF416F49);
  static const Color _textColor = Color(0xFF1D251D);
  static const Color _mutedTextColor = Color(0xFF5F695E);
  static const Color _creamColor = Color(0xFFFFF2D9);

  final String currentUserId;
  final RankingService _rankingService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: StreamBuilder<List<RankingUser>>(
          stream: _rankingService.watchTopUsers(limit: 120),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _primaryColor),
              );
            }

            if (snapshot.hasError) {
              return _RankingEmptyState(
                icon: Icons.error_outline_rounded,
                title: '랭킹을 불러오지 못했습니다.',
                message: '${snapshot.error}',
              );
            }

            final users = snapshot.data ?? const [];
            if (users.isEmpty) {
              return const _RankingEmptyState(
                icon: Icons.emoji_events_outlined,
                title: '아직 이번 달 랭킹이 없습니다.',
                message: '이번 달 영수증을 올리면 랭킹에 표시됩니다.',
              );
            }

            final currentUser = _findCurrentUser(users);
            final topUser = users.first;
            final topUsers = users.take(10).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
              children: [
                const _RankingHeader(),
                const SizedBox(height: 24),
                _MyRankingDashboard(
                  currentUser: currentUser,
                  participantCount: users.length,
                  topUser: topUser,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetricCard(
                        icon: Icons.emoji_events_outlined,
                        title: '이번 달 1위',
                        value: topUser.nickname,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiniMetricCard(
                        icon: Icons.eco_outlined,
                        title: '최고 포인트',
                        value: '${_formatNumber(topUser.ecoPoint)} pts',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Users',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: _textColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    Text(
                      '이번 달',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _secondaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...topUsers.map(
                  (user) => _RankingCard(
                    user: user,
                    isCurrentUser: user.id == currentUserId,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  RankingUser? _findCurrentUser(List<RankingUser> users) {
    for (final user in users) {
      if (user.id == currentUserId) {
        return user;
      }
    }
    return null;
  }
}

class _RankingHeader extends StatelessWidget {
  const _RankingHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ECO',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: RankingPage._primaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '이번 달 에코 랭킹을 한눈에 확인해요',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: RankingPage._mutedTextColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MyRankingDashboard extends StatelessWidget {
  const _MyRankingDashboard({
    required this.currentUser,
    required this.participantCount,
    required this.topUser,
  });

  final RankingUser? currentUser;
  final int participantCount;
  final RankingUser topUser;

  @override
  Widget build(BuildContext context) {
    final rankText = currentUser == null ? '순위 없음' : '${currentUser!.rank}위';
    final pointText = currentUser == null
        ? '0 pts'
        : '${_formatNumber(currentUser!.ecoPoint)} pts';
    final gradeText = currentUser?.grade ?? '기록 없음';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: RankingPage._primaryColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: RankingPage._primaryColor.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번 달 나의 랭킹',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            rankText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            decoration: BoxDecoration(
              color: RankingPage._secondaryGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    '내 에코 포인트',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  pointText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
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
                child: _GreenInfoTile(
                  title: '참여 유저',
                  value: '$participantCount명',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GreenInfoTile(title: '내 등급', value: gradeText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '현재 1위 ${topUser.nickname} · ${_formatNumber(topUser.ecoPoint)} pts',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: RankingPage._primaryColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GreenInfoTile extends StatelessWidget {
  const _GreenInfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RankingPage._secondaryGreen,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 126),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: RankingPage._secondaryGreen, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: RankingPage._textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: RankingPage._mutedTextColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  const _RankingCard({required this.user, required this.isCurrentUser});

  final RankingUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isCurrentUser
              ? RankingPage._secondaryGreen.withValues(alpha: 0.52)
              : const Color(0xFFE5EBDD),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: user.rank),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: RankingPage._textColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrentUser ? '나의 이번 달 기록' : '이번 달 친환경 소비 기록',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RankingPage._mutedTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: RankingPage._creamColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${_formatNumber(user.ecoPoint)} pts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFFF6326),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: isTopThree
            ? RankingPage._primaryColor
            : RankingPage._primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: isTopThree
            ? Icon(
                Icons.emoji_events_outlined,
                color: Colors.white,
                size: rank == 1 ? 28 : 24,
              )
            : Text(
                '$rank',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: RankingPage._primaryColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _RankingEmptyState extends StatelessWidget {
  const _RankingEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RankingPage._backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: RankingPage._primaryColor),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: RankingPage._textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: RankingPage._mutedTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}
