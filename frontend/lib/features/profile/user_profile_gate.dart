import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/nickname_setup_page.dart';
import '../home/home_page.dart';
import 'user_profile_service.dart';

class UserProfileGate extends StatelessWidget {
  const UserProfileGate({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: ensureUserProfile(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        final nickname = (data?['nickname'] as String?)?.trim() ?? '';

        final needsNickname =
            !snapshot.hasData ||
            !snapshot.data!.exists ||
            nickname.isEmpty ||
            nickname == '사용자' ||
            nickname == '카카오 사용자' ||
            nickname == '네이버 사용자';

        if (needsNickname) {
          return NicknameSetupPage(user: user);
        }

        return HomePage(user: user);
      },
    );
  }
}