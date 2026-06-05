import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

import '../profile/user_profile_service.dart';

class AuthService {
  Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    final provider = user == null ? null : loginProviderOf(user);

    await FirebaseAuth.instance.signOut();

    if (provider != null) {
      Future.microtask(() => _clearSocialSession(provider));
    }
  }

  Future<void> deleteAccount(User user) async {
    final provider = loginProviderOf(user);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    await user.delete();

    Future.microtask(() => _unlinkSocialLogin(provider));
  }

  Future<void> _clearSocialSession(String provider) async {
    try {
      if (provider == 'kakao') {
        await kakao.UserApi.instance
            .logout()
            .timeout(const Duration(seconds: 3));
      } else if (provider == 'naver') {
        await FlutterNaverLogin.logOut().timeout(const Duration(seconds: 3));
      }
    } catch (_) {}
  }

  Future<void> _unlinkSocialLogin(String provider) async {
    if (provider == 'kakao') {
      try {
        await kakao.UserApi.instance
            .unlink()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        try {
          await kakao.UserApi.instance
              .logout()
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      return;
    }

    if (provider == 'naver') {
      try {
        await FlutterNaverLogin.logOutAndDeleteToken()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        try {
          await FlutterNaverLogin.logOut().timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
    }
  }
}