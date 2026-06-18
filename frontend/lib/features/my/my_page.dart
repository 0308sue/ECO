import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../utils/validators.dart';
import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';
import '../profile/user_profile_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.user});

  final User user;

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final AuthService _authService = AuthService();
  late Future<_MyPageData> _myPageFuture;

  @override
  void initState() {
    super.initState();
    _myPageFuture = _loadMyPage();
  }

  Future<_MyPageData> _loadMyPage() async {
    await ensureUserProfile(widget.user);

    final url = Uri.parse(
      '$authApiBaseUrl/api/my-page/${Uri.encodeComponent(widget.user.uid)}',
    );
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('마이페이지 정보를 불러오지 못했습니다.');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw Exception('마이페이지 응답 형식이 올바르지 않습니다.');
    }

    return _MyPageData.fromJson(body, fallbackEmail: widget.user.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MyPageColors.background,
      body: FutureBuilder<_MyPageData>(
        future: _myPageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MyPageError(
              onRetry: () {
                setState(() {
                  _myPageFuture = _loadMyPage();
                });
              },
            );
          }

          final data = snapshot.data ?? _MyPageData.empty(widget.user.email);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 32),
              children: [
                const _MyPageHeader(),
                const SizedBox(height: 24),
                _CarbonHeroCard(data: data),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfoCard(
                        icon: Icons.workspace_premium_rounded,
                        title: '등급',
                        value: data.grade,
                        helper: '${data.nickname}님의 현재 레벨',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiniInfoCard(
                        icon: Icons.eco_rounded,
                        title: '이번 달 친환경 소비',
                        value: '${data.monthlyEcoConsumptionCount}회',
                        helper: '이번 달 실천 기록',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: '획득 배지',
                  trailing: '${data.badges.length}개',
                ),
                const SizedBox(height: 12),
                _BadgeList(badges: data.badges),
                const SizedBox(height: 28),
                const _SectionHeader(title: '내 활동 통계'),
                const SizedBox(height: 12),
                _StatsPanel(data: data),
                const SizedBox(height: 28),
                const _SectionHeader(title: '계정'),
                const SizedBox(height: 12),
                _AccountPanel(
                  onUserInfoTap: () =>
                      _showUserInfo(context, data.nickname, data.email),
                  onDeleteTap: () => _confirmDeleteAccount(context),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _signOut(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD94C3D),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('로그아웃'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUserInfo(BuildContext context, String nickname, String email) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '회원 정보',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              _UserInfoRow(label: '닉네임', value: nickname),
              _UserInfoRow(label: '이메일', value: email.isEmpty ? '미등록' : email),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('계정과 사용자 정보가 삭제됩니다. 정말 탈퇴할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    await _deleteAccount(context, widget.user);
  }

  Future<void> _signOut(BuildContext context) async {
    await _authService.signOut();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context, User user) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _authService.deleteAccount(user);

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        messenger.showSnackBar(
          const SnackBar(content: Text('보안을 위해 다시 로그인한 뒤 탈퇴해주세요.')),
        );

        if (!context.mounted) {
          return;
        }

        await _signOut(context);
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('회원 탈퇴에 실패했습니다. ${authErrorMessage(error)}')),
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('회원 탈퇴에 실패했습니다. $error')));
    }
  }
}

class _MyPageColors {
  static const Color background = Color(0xFFF7FAF1);
  static const Color deepGreen = Color(0xFF1F522B);
  static const Color mutedGreen = Color(0xFF47704C);
  static const Color text = Color(0xFF1B241C);
  static const Color subText = Color(0xFF5B675D);
  static const Color card = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE2E8DE);
}

class _MyPageHeader extends StatelessWidget {
  const _MyPageHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ECO',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: _MyPageColors.deepGreen,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '나의 탄소 소비를 한눈에 확인해요',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: _MyPageColors.subText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CarbonHeroCard extends StatelessWidget {
  const _CarbonHeroCard({required this.data});

  final _MyPageData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _MyPageColors.deepGreen,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: _MyPageColors.deepGreen.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '현재 탄소 점수',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${data.ecoPoint}점',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 28),
          _HeroStatStrip(
            icon: Icons.emoji_events_rounded,
            label: '내 에코 포인트',
            value: '${data.totalSavedScore} pts',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroSmallStat(
                  label: '누적 분석',
                  value: '${data.receiptAnalysisCount}회',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroSmallStat(
                  label: '주요 카테고리',
                  value: data.mostConsumedCategory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Text(
              data.rankingMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: _MyPageColors.deepGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatStrip extends StatelessWidget {
  const _HeroStatStrip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
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

class _HeroSmallStat extends StatelessWidget {
  const _HeroSmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
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

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String title;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _MyPageColors.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _MyPageColors.mutedGreen, size: 30),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _MyPageColors.subText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _MyPageColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _MyPageColors.subText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _MyPageColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _MyPageColors.mutedGreen,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.data});

  final _MyPageData data;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        children: [
          _StatRow(
            label: '누적 영수증 분석 횟수',
            value: '${data.receiptAnalysisCount}회',
          ),
          _StatRow(label: '누적 절감 점수', value: '${data.totalSavedScore}점'),
          _StatRow(label: '가장 많이 소비한 카테고리', value: data.mostConsumedCategory),
          _StatRow(
            label: '이번 달 친환경 소비 횟수',
            value: '${data.monthlyEcoConsumptionCount}회',
          ),
          const SizedBox(height: 8),
          _RankingMessage(message: data.rankingMessage),
        ],
      ),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.onUserInfoTap, required this.onDeleteTap});

  final VoidCallback onUserInfoTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        children: [
          _AccountButton(
            icon: Icons.person_outline_rounded,
            label: '회원 정보',
            onTap: onUserInfoTap,
          ),
          const Divider(height: 18, color: _MyPageColors.line),
          _AccountButton(
            icon: Icons.no_accounts_outlined,
            label: '회원 탈퇴',
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _MyPageColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _MyPageColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingMessage extends StatelessWidget {
  const _RankingMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BadgeList extends StatelessWidget {
  const _BadgeList({required this.badges});

  final List<_BadgeData> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Text(
        '아직 획득한 배지가 없습니다.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: badges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BadgeTile(badge: badge),
            ),
          )
          .toList(),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final _BadgeData badge;

  @override
  Widget build(BuildContext context) {
    final palette = _BadgePalette.fromTone(badge.tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image.asset(
                badge.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.eco_rounded, color: palette.icon);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  badge.description,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
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

class _BadgePalette {
  const _BadgePalette({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color iconBackground;
  final Color icon;

  factory _BadgePalette.fromTone(String tone) {
    switch (tone) {
      case 'gold':
        return const _BadgePalette(
          background: Color(0xFFFFF7DE),
          border: Color(0xFFE8C85A),
          iconBackground: Color(0xFFFFE28A),
          icon: Color(0xFF7A5A00),
        );
      case 'silver':
        return const _BadgePalette(
          background: Color(0xFFF3F5F7),
          border: Color(0xFFC6CDD5),
          iconBackground: Color(0xFFDDE3EA),
          icon: Color(0xFF4F5B66),
        );
      case 'bronze':
        return const _BadgePalette(
          background: Color(0xFFFFEFE4),
          border: Color(0xFFD99A6C),
          iconBackground: Color(0xFFE8B084),
          icon: Color(0xFF74411E),
        );
      case 'mint':
        return const _BadgePalette(
          background: Color(0xFFEAF8F1),
          border: Color(0xFFB9E5D0),
          iconBackground: Color(0xFFCFF2DE),
          icon: Color(0xFF24724E),
        );
      case 'blue':
        return const _BadgePalette(
          background: Color(0xFFEAF3FF),
          border: Color(0xFFBDD5F6),
          iconBackground: Color(0xFFD3E5FF),
          icon: Color(0xFF2D5F99),
        );
      default:
        return const _BadgePalette(
          background: Color(0xFFEEF7EA),
          border: Color(0xFFC8E7BF),
          iconBackground: Color(0xFFDDF4D6),
          icon: Color(0xFF3B713B),
        );
    }
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPageError extends StatelessWidget {
  const _MyPageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              '마이페이지 정보를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyPageData {
  const _MyPageData({
    required this.nickname,
    required this.email,
    required this.ecoPoint,
    required this.grade,
    required this.receiptAnalysisCount,
    required this.totalSavedScore,
    required this.mostConsumedCategory,
    required this.monthlyEcoConsumptionCount,
    required this.rankingMessage,
    required this.badges,
  });

  final String nickname;
  final String email;
  final int ecoPoint;
  final String grade;
  final int receiptAnalysisCount;
  final int totalSavedScore;
  final String mostConsumedCategory;
  final int monthlyEcoConsumptionCount;
  final String rankingMessage;
  final List<_BadgeData> badges;

  factory _MyPageData.fromJson(
    Map<String, dynamic> json, {
    required String fallbackEmail,
  }) {
    return _MyPageData(
      nickname: _readString(json['nickname'], fallback: '사용자'),
      email: _readString(json['email'], fallback: fallbackEmail),
      ecoPoint: _readInt(json['ecoPoint']),
      grade: _readString(json['grade'], fallback: 'Seed'),
      receiptAnalysisCount: _readInt(json['receiptAnalysisCount']),
      totalSavedScore: _readInt(json['totalSavedScore']),
      mostConsumedCategory: _readString(
        json['mostConsumedCategory'],
        fallback: '아직 분석된 카테고리가 없습니다.',
      ),
      monthlyEcoConsumptionCount: _readInt(json['monthlyEcoConsumptionCount']),
      rankingMessage: _readString(
        json['rankingMessage'],
        fallback: '이번 달 친환경 소비 기록을 쌓으면 랭킹 비교가 표시됩니다.',
      ),
      badges: _readBadges(json['badges']),
    );
  }

  factory _MyPageData.empty(String? email) {
    return _MyPageData(
      nickname: '사용자',
      email: email ?? '',
      ecoPoint: 0,
      grade: 'Seed',
      receiptAnalysisCount: 0,
      totalSavedScore: 0,
      mostConsumedCategory: '아직 분석된 카테고리가 없습니다.',
      monthlyEcoConsumptionCount: 0,
      rankingMessage: '이번 달 친환경 소비 기록을 쌓으면 랭킹 비교가 표시됩니다.',
      badges: const [],
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.id,
    required this.name,
    required this.description,
    required this.tone,
  });

  final String id;
  final String name;
  final String description;
  final String tone;

  String get imagePath {
    if (id.startsWith('monthly_gold_leaf')) {
      return 'assets/badges/gold_leaf.png';
    }
    if (id.startsWith('monthly_silver_leaf')) {
      return 'assets/badges/silver_leaf.png';
    }
    if (id.startsWith('monthly_bronze_leaf')) {
      return 'assets/badges/bronze_leaf.png';
    }
    if (id.startsWith('low_carbon_routine')) {
      return 'assets/badges/low_carbon_routine.png';
    }
    if (id.startsWith('top_ten')) {
      return 'assets/badges/top_ten.png';
    }
    if (id.startsWith('rising_rank')) {
      return 'assets/badges/rising_rank.png';
    }
    if (id.startsWith('monthly_focus')) {
      return 'assets/badges/monthly_focus.png';
    }
    if (id.startsWith('comeback_practitioner')) {
      return 'assets/badges/comeback_practitioner.png';
    }

    return 'assets/badges/$id.png';
  }

  factory _BadgeData.fromJson(Map<String, dynamic> json) {
    return _BadgeData(
      id: _readString(json['id'], fallback: ''),
      name: _readString(json['name'], fallback: '배지'),
      description: _readString(json['description'], fallback: ''),
      tone: _readString(json['tone'], fallback: 'green'),
    );
  }
}

List<_BadgeData> _readBadges(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map<String, dynamic>>()
      .map(_BadgeData.fromJson)
      .toList();
}

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

String _readString(Object? value, {required String fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }

  return fallback;
}
