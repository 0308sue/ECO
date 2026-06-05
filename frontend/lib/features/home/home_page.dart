import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/info_tile.dart';
import '../../utils/validators.dart';
import '../auth/auth_gate.dart';
import '../auth/auth_service.dart';
import '../profile/user_profile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _ensureUserDocument();
  }

  Future<void> _ensureUserDocument() async {
    await ensureUserProfile(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(widget.user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ECO 마이페이지'),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_account') {
                _confirmDeleteAccount(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete_account',
                child: Text('회원 탈퇴'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() ?? {};
          final nickname = data['nickname'] as String? ?? '사용자';
          final email = data['email'] as String? ?? widget.user.email ?? '';
          final ecoPoint = data['ecoPoint'] as int? ?? 0;
          final grade = data['grade'] as String? ?? 'Seed';
          final badges = List<String>.from(data['badges'] ?? const []);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '$nickname님',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(email),
              const SizedBox(height: 24),
              InfoTile(
                title: '현재 탄소 점수',
                value: '$ecoPoint Eco Point',
                icon: Icons.eco,
              ),
              InfoTile(
                title: '등급',
                value: grade,
                icon: Icons.workspace_premium,
              ),
              InfoTile(
                title: '획득 배지',
                value: badges.isEmpty ? '아직 획득한 배지가 없습니다.' : badges.join(', '),
                icon: Icons.military_tech,
              ),
            ],
          );
        },
      ),
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
      messenger.showSnackBar(
        SnackBar(content: Text('회원 탈퇴에 실패했습니다. $error')),
      );
    }
  }
}