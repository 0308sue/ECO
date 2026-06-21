import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';
import '../../utils/validators.dart';
import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';
import '../profile/user_profile_service.dart';

class MyPage extends StatefulWidget {
  const MyPage({
    super.key,
    required this.user,
  });

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
      '$authApiBaseUrl/api/my-page/'
      '${Uri.encodeComponent(widget.user.uid)}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        '마이페이지 정보를 불러오지 못했습니다.',
      );
    }

    final body = jsonDecode(
      utf8.decode(response.bodyBytes),
    );

    if (body is! Map<String, dynamic>) {
      throw Exception(
        '마이페이지 응답 형식이 올바르지 않습니다.',
      );
    }

    return _MyPageData.fromJson(
      body,
      fallbackEmail: widget.user.email ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _MyPageColors.background,
      body: FutureBuilder<_MyPageData>(
        future: _myPageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: EcoColors.primary,
              ),
            );
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

          final data = snapshot.data ??
              _MyPageData.empty(
                widget.user.email,
              );

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                128,
              ),
              children: [
                _CarbonHeroCard(
                  data: data,
                ),

                const SizedBox(height: 28),

                _SectionHeader(
                  title: '획득 배지',
                  trailing: '${data.badges.length}개',
                ),

                const SizedBox(height: 14),

                _BadgeList(
                  badges: data.badges,
                ),

                const SizedBox(height: 28),

                const _SectionHeader(
                  title: '이번 달 활동',
                ),

                const SizedBox(height: 12),

                _ActivityPanel(
                  data: data,
                ),

                const SizedBox(height: 28),

                const _SectionHeader(
                  title: '계정',
                ),

                const SizedBox(height: 12),

                _AccountPanel(
                  onUserInfoTap: () {
                    _showUserInfo(
                      context,
                      data.nickname,
                      data.email,
                    );
                  },
                  onDeleteTap: () {
                    _confirmDeleteAccount(
                      context,
                    );
                  },
                ),

                const SizedBox(height: 14),

                FilledButton.icon(
                  onPressed: () {
                    _signOut(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFD94C3D),
                    foregroundColor: Colors.white,
                    minimumSize:
                        const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                  ),
                  label: const Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showUserInfo(
    BuildContext context,
    String nickname,
    String email,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: EcoColors.background,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            4,
            20,
            28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                '회원 정보',
                style: TextStyle(
                  color: EcoColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 18),

              _UserInfoRow(
                label: '닉네임',
                value: nickname,
              ),

              _UserInfoRow(
                label: '이메일',
                value: email.isEmpty
                    ? '미등록'
                    : email,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            '회원 탈퇴',
          ),
          content: const Text(
            '계정과 사용자 정보가 삭제됩니다. '
            '정말 탈퇴할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .error,
                foregroundColor:
                    Theme.of(context)
                        .colorScheme
                        .onError,
              ),
              child: const Text('탈퇴'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true ||
        !context.mounted) {
      return;
    }

    await _deleteAccount(
      context,
      widget.user,
    );
  }

  Future<void> _signOut(
    BuildContext context,
  ) async {
    await _authService.signOut();

    if (context.mounted) {
      Navigator.of(context)
          .pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    User user,
  ) async {
    final messenger =
        ScaffoldMessenger.of(context);

    try {
      await _authService.deleteAccount(
        user,
      );

      if (context.mounted) {
        Navigator.of(context)
            .pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const AuthGate(),
          ),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (error.code ==
          'requires-recent-login') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              '보안을 위해 다시 로그인한 뒤 탈퇴해주세요.',
            ),
          ),
        );

        if (!context.mounted) {
          return;
        }

        await _signOut(context);
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '회원 탈퇴에 실패했습니다. '
            '${authErrorMessage(error)}',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '회원 탈퇴에 실패했습니다. $error',
          ),
        ),
      );
    }
  }
}

class _MyPageColors {
  static const Color background =
      EcoColors.background;

  static const Color deepGreen =
      EcoColors.secondary;

  static const Color mutedGreen =
      EcoColors.primary;

  static const Color text =
      EcoColors.text;

  static const Color card =
      Color(0xFFFFFFFF);

  static const Color line =
      EcoColors.line;
}

class _CarbonHeroCard extends StatelessWidget {
  const _CarbonHeroCard({
    required this.data,
  });

  final _MyPageData data;

  @override
  Widget build(BuildContext context) {
    final nickname = data.nickname.trim();

    final initial = nickname.isEmpty
        ? 'E'
        : nickname.characters.first;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _MyPageColors.deepGreen,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _MyPageColors.deepGreen
                .withValues(
              alpha: 0.18,
            ),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -55,
            top: -75,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: -55,
            bottom: -90,
            child: Container(
              width: 170,
              height: 170,
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
              20,
              20,
              20,
              22,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: EcoColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.18,
                          ),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color:
                              EcoColors.secondary,
                          fontSize: 24,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.eco_outlined,
                                color: Color(
                                  0xFFCDE2D4,
                                ),
                                size: 13,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'MY ECO PROFILE',
                                style: TextStyle(
                                  color: Color(
                                    0xFFCDE2D4,
                                  ),
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 5),

                          Text(
                            data.nickname,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.w800,
                              letterSpacing: -0.7,
                              height: 1.1,
                            ),
                          ),

                          const SizedBox(height: 7),

                          EcoPill(
                            label: data.grade,
                            icon: Icons
                                .workspace_premium_rounded,
                            background:
                                EcoColors.accent,
                            foreground:
                                EcoColors.text,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    _LevelCharacter(
                      grade: data.grade,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  height: 1,
                  color: Colors.white.withValues(
                    alpha: 0.14,
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _HeroMetric(
                        label: '절감 점수',
                        value:
                            '${data.totalSavedScore}점',
                      ),
                    ),

                    const _HeroDivider(),

                    Expanded(
                      child: _HeroMetric(
                        label: '영수증 분석',
                        value:
                            '${data.receiptAnalysisCount}회',
                      ),
                    ),

                    const _HeroDivider(),

                    Expanded(
                      child: _HeroMetric(
                        label: '에코 포인트',
                        value:
                            '${_formatNumber(data.ecoPoint)} P',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFCDE2D4),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(
        horizontal: 7,
      ),
      color: Colors.white.withValues(
        alpha: 0.14,
      ),
    );
  }
}

class _LevelCharacter extends StatelessWidget {
  const _LevelCharacter({
    required this.grade,
  });

  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 84,
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.13,
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Image.asset(
          _characterImagePath(grade),
          fit: BoxFit.contain,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return const Icon(
              Icons.eco_rounded,
              color: Colors.white,
              size: 42,
            );
          },
        ),
      ),
    );
  }

  String _characterImagePath(
    String grade,
  ) {
    switch (grade.toLowerCase()) {
      case 'sprout':
        return 'assets/characters/sprout.png';

      case 'tree':
        return 'assets/characters/tree.png';

      case 'forest':
        return 'assets/characters/forest.png';

      case 'seed':
      default:
        return 'assets/characters/seed.png';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.trailing,
  });

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _MyPageColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),

        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: EcoColors.primary.withValues(
                alpha: 0.1,
              ),
              borderRadius:
                  BorderRadius.circular(999),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                color: EcoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.data,
  });

  final _MyPageData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: Row(
        children: [
          Expanded(
            child: _ActivityCard(
              icon: Icons.calendar_month_outlined,
              label: '이번 달 친환경 소비',
              value:
                  '${data.monthlyEcoConsumptionCount}회',
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: _ActivityCard(
              icon: Icons.category_outlined,
              label: '주요 소비 카테고리',
              value: data.mostConsumedCategory,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
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
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: EcoColors.primary.withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: EcoColors.secondary,
              size: 19,
            ),
          ),

          const Spacer(),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EcoColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.15,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeList extends StatelessWidget {
  const _BadgeList({
    required this.badges,
  });

  final List<_BadgeData> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.military_tech_outlined,
              color: EcoColors.primary,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '아직 획득한 배지가 없습니다.',
                style: TextStyle(
                  color: EcoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        return _BadgeTile(
          badge: badges[index],
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
  });

  final _BadgeData badge;

  @override
  Widget build(BuildContext context) {
    final palette =
        _BadgePalette.fromTone(
      badge.tone,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.iconBackground
                  .withValues(
                alpha: 0.68,
              ),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                badge.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Icon(
                    Icons.eco_rounded,
                    color: palette.icon,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            badge.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePalette {
  const _BadgePalette({
    required this.iconBackground,
    required this.icon,
  });

  final Color iconBackground;
  final Color icon;

  factory _BadgePalette.fromTone(
    String tone,
  ) {
    switch (tone) {
      case 'gold':
        return const _BadgePalette(
          iconBackground:
              Color(0xFFFFE28A),
          icon: Color(0xFF7A5A00),
        );

      case 'silver':
        return const _BadgePalette(
          iconBackground:
              Color(0xFFDDE3EA),
          icon: Color(0xFF4F5B66),
        );

      case 'bronze':
        return const _BadgePalette(
          iconBackground:
              Color(0xFFE8B084),
          icon: Color(0xFF74411E),
        );

      case 'mint':
        return const _BadgePalette(
          iconBackground:
              Color(0xFFCFF2DE),
          icon: Color(0xFF24724E),
        );

      case 'blue':
        return const _BadgePalette(
          iconBackground:
              Color(0xFFD3E5FF),
          icon: Color(0xFF2D5F99),
        );

      default:
        return const _BadgePalette(
          iconBackground:
              Color(0xFFDDF4D6),
          icon: Color(0xFF3B713B),
        );
    }
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({
    required this.onUserInfoTap,
    required this.onDeleteTap,
  });

  final VoidCallback onUserInfoTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        children: [
          _AccountButton(
            icon: Icons.badge_outlined,
            label: '회원 정보',
            onTap: onUserInfoTap,
          ),

          const Divider(
            height: 18,
            color: _MyPageColors.line,
          ),

          _AccountButton(
            icon: Icons.no_accounts_outlined,
            label: '회원 탈퇴',
            onTap: onDeleteTap,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _MyPageColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _MyPageColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.025,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context)
            .colorScheme
            .error
        : EcoColors.secondary;

    return InkWell(
      borderRadius:
          BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.09,
                ),
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 19,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: destructive
                      ? color
                      : EcoColors.text,
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Icon(
              Icons.chevron_right_rounded,
              color: destructive
                  ? color.withValues(
                      alpha: 0.7,
                    )
                  : EcoColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: EcoColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: EcoColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyPageError extends StatelessWidget {
  const _MyPageError({
    required this.onRetry,
  });

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
              color: Theme.of(context)
                  .colorScheme
                  .error,
            ),

            const SizedBox(height: 12),

            const Text(
              '마이페이지 정보를 불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EcoColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                '다시 시도',
              ),
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
      nickname: _readString(
        json['nickname'],
        fallback: '사용자',
      ),
      email: _readString(
        json['email'],
        fallback: fallbackEmail,
      ),
      ecoPoint: _readInt(
        json['ecoPoint'],
      ),
      grade: _readString(
        json['grade'],
        fallback: 'Seed',
      ),
      receiptAnalysisCount: _readInt(
        json['receiptAnalysisCount'],
      ),
      totalSavedScore: _readInt(
        json['totalSavedScore'],
      ),
      mostConsumedCategory:
          _readString(
        json['mostConsumedCategory'],
        fallback: '기록 없음',
      ),
      monthlyEcoConsumptionCount:
          _readInt(
        json[
            'monthlyEcoConsumptionCount'],
      ),
      rankingMessage: _readString(
        json['rankingMessage'],
        fallback:
            '이번 달 친환경 소비 기록을 쌓으면 랭킹 비교가 표시됩니다.',
      ),
      badges: _readBadges(
        json['badges'],
      ),
    );
  }

  factory _MyPageData.empty(
    String? email,
  ) {
    return _MyPageData(
      nickname: '사용자',
      email: email ?? '',
      ecoPoint: 0,
      grade: 'Seed',
      receiptAnalysisCount: 0,
      totalSavedScore: 0,
      mostConsumedCategory: '기록 없음',
      monthlyEcoConsumptionCount: 0,
      rankingMessage:
          '이번 달 친환경 소비 기록을 쌓으면 랭킹 비교가 표시됩니다.',
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
    if (id.startsWith(
      'monthly_gold_leaf',
    )) {
      return 'assets/badges/gold_leaf.png';
    }

    if (id.startsWith(
      'monthly_silver_leaf',
    )) {
      return 'assets/badges/silver_leaf.png';
    }

    if (id.startsWith(
      'monthly_bronze_leaf',
    )) {
      return 'assets/badges/bronze_leaf.png';
    }

    if (id.startsWith(
      'low_carbon_routine',
    )) {
      return 'assets/badges/low_carbon_routine.png';
    }

    if (id.startsWith(
      'top_ten',
    )) {
      return 'assets/badges/top_ten.png';
    }

    if (id.startsWith(
      'rising_rank',
    )) {
      return 'assets/badges/rising_rank.png';
    }

    if (id.startsWith(
      'monthly_focus',
    )) {
      return 'assets/badges/monthly_focus.png';
    }

    if (id.startsWith(
      'comeback_practitioner',
    )) {
      return 'assets/badges/comeback_practitioner.png';
    }

    return 'assets/badges/$id.png';
  }

  factory _BadgeData.fromJson(
    Map<String, dynamic> json,
  ) {
    return _BadgeData(
      id: _readString(
        json['id'],
        fallback: '',
      ),
      name: _readString(
        json['name'],
        fallback: '배지',
      ),
      description: _readString(
        json['description'],
        fallback: '',
      ),
      tone: _readString(
        json['tone'],
        fallback: 'green',
      ),
    );
  }
}

List<_BadgeData> _readBadges(
  Object? value,
) {
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

String _readString(
  Object? value, {
  required String fallback,
}) {
  if (value is String &&
      value.trim().isNotEmpty) {
    return value.trim();
  }

  return fallback;
}

String _formatNumber(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    final remaining = text.length - i;

    buffer.write(text[i]);

    if (remaining > 1 &&
        remaining % 3 == 1) {
      buffer.write(',');
    }
  }

  return buffer.toString();
}