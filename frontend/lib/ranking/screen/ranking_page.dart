import 'package:flutter/material.dart';

import '../model/ranking_user.dart';
import '../service/ranking_service.dart';

class RankingPage extends StatelessWidget {
  RankingPage({
    super.key,
    required this.currentUserId,
    RankingService? rankingService,
  }) : _rankingService = rankingService ?? RankingService();

  final String currentUserId;
  final RankingService _rankingService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Ranking',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<RankingUser>>(
        stream: _rankingService.watchTopUsers(limit: 120),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _RankingEmptyState(
              icon: Icons.error_outline,
              title: '랭킹을 불러오지 못했습니다.',
              message: '${snapshot.error}',
            );
          }

          final users = snapshot.data ?? const [];
          if (users.isEmpty) {
            return const _RankingEmptyState(
              icon: Icons.emoji_events_outlined,
              title: '아직 랭킹이 없습니다.',
              message: '첫 ECO 점수가 쌓이면 여기에 표시됩니다.',
            );
          }

          final currentUser = _findCurrentUser(users);
          final displayUser = currentUser ?? users.first;
          final topUsers = users.take(5).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'My Rank',
                      value: currentUser == null ? '-' : '${currentUser.rank}',
                      suffix: '/ ${users.length}',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Eco Points',
                      value: _formatNumber(displayUser.ecoPoint),
                      suffix: 'pts',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Top Users',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _TopUsersPanel(users: topUsers),
              if (currentUser != null) ...[
                const SizedBox(height: 16),
                _CurrentUserPanel(user: currentUser),
              ],
            ],
          );
        },
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.suffix,
  });

  final String title;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  suffix,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _TopUsersPanel extends StatelessWidget {
  const _TopUsersPanel({required this.users});

  final List<RankingUser> users;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: users
            .map(
              (user) =>
                  _RankingListRow(user: user, showDivider: user != users.last),
            )
            .toList(),
      ),
    );
  }
}

class _RankingListRow extends StatelessWidget {
  const _RankingListRow({required this.user, required this.showDivider});

  final RankingUser user;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 18),
              SizedBox(width: 28, child: _RankIcon(rank: user.rank)),
              SizedBox(
                width: 34,
                child: Text(
                  '${user.rank}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user.nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatNumber(user.ecoPoint)} pts',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 18),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
      ],
    );
  }
}

class _RankIcon extends StatelessWidget {
  const _RankIcon({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank > 3) {
      return const SizedBox.shrink();
    }

    return Icon(
      Icons.emoji_events_outlined,
      size: 24,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}

class _CurrentUserPanel extends StatelessWidget {
  const _CurrentUserPanel({required this.user});

  final RankingUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '${user.rank}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              user.nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${_formatNumber(user.ecoPoint)} pts',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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
