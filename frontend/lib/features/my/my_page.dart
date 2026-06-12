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
      appBar: AppBar(title: const Text('ECO 마이페이지')),
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Text(
                '${data.nickname}님',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _SummaryCard(ecoPoint: data.ecoPoint, grade: data.grade),
              const SizedBox(height: 14),
              _SectionCard(
                title: '내 활동 통계',
                icon: Icons.bar_chart_rounded,
                child: Column(
                  children: [
                    _StatRow(
                      label: '누적 영수증 분석 횟수',
                      value: '${data.receiptAnalysisCount}회',
                    ),
                    _StatRow(
                      label: '누적 절감 점수',
                      value: '${data.totalSavedScore}점',
                    ),
                    _StatRow(
                      label: '가장 많이 소비한 카테고리',
                      value: data.mostConsumedCategory,
                    ),
                    _StatRow(
                      label: '이번 달 친환경 소비 횟수',
                      value: '${data.monthlyEcoConsumptionCount}회',
                    ),
                    _RankingMessage(message: data.rankingMessage),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: '계정',
                icon: Icons.manage_accounts_rounded,
                child: Column(
                  children: [
                    _AccountButton(
                      icon: Icons.person_outline_rounded,
                      label: '회원 정보',
                      onTap: () =>
                          _showUserInfo(context, data.nickname, data.email),
                    ),
                    const Divider(height: 18),
                    _AccountButton(
                      icon: Icons.no_accounts_outlined,
                      label: '회원 탈퇴',
                      onTap: () => _confirmDeleteAccount(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => _signOut(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('로그아웃'),
              ),
            ],
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.ecoPoint, required this.grade});

  final int ecoPoint;
  final String grade;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              icon: Icons.eco_rounded,
              title: '현재 탄소 점수',
              value: '$ecoPoint Eco Point',
            ),
          ),
          Container(
            width: 1,
            height: 56,
            color: colorScheme.primary.withValues(alpha: 0.18),
          ),
          Expanded(
            child: _SummaryMetric(
              icon: Icons.workspace_premium_rounded,
              title: '등급',
              value: grade,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
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
    );
  }
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
