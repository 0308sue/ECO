import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

import '../../core/constants/api_constants.dart';
import '../../core/widgets/auth_scaffold.dart';
import '../profile/user_profile_service.dart';

const MethodChannel nativeConfigChannel = MethodChannel('eco/native_config');

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isKakaoLoading = false;
  bool _isNaverLoading = false;
  String? _errorMessage;

  Future<void> _loginWithKakao() async {
    if (kakaoNativeAppKey.isEmpty) {
      setState(() {
        _errorMessage = '카카오 Native App Key가 설정되지 않았습니다.';
      });
      return;
    }

    setState(() {
      _isKakaoLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _requestKakaoToken();

      final response = await http.post(
        Uri.parse('$authApiBaseUrl/api/auth/kakao'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': token.accessToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('카카오 로그인 서버 요청에 실패했습니다.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final customToken = body['customToken'] as String?;

      if (customToken == null || customToken.isEmpty) {
        throw Exception('Firebase 로그인 토큰을 받지 못했습니다.');
      }

      final credential =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);

      final user = credential.user;
      if (user != null) {
        await ensureUserProfile(user);
      }
    } catch (error) {
      setState(() {
        _errorMessage = '카카오 로그인에 실패했습니다. $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isKakaoLoading = false;
        });
      }
    }
  }

  Future<void> _loginWithNaver() async {
    setState(() {
      _isNaverLoading = true;
      _errorMessage = null;
    });

    try {
      final naverConfigDebug = await _readNaverConfigDebug();
      if (naverConfigDebug != null) {
        debugPrint('NAVER_CONFIG_DEBUG: $naverConfigDebug');
        final clientIdLength = naverConfigDebug['clientIdLength'] as int? ?? 0;
        final hasClientSecret =
            naverConfigDebug['hasClientSecret'] as bool? ?? false;
        final looksLikeExample =
            naverConfigDebug['looksLikeExample'] as bool? ?? false;

        if (clientIdLength == 0 || !hasClientSecret || looksLikeExample) {
          throw Exception(
            '네이버 설정값이 앱에 제대로 들어가지 않았습니다. '
            'package=${naverConfigDebug['packageName']}, '
            'clientId=${naverConfigDebug['clientIdPreview']}, '
            'name=${naverConfigDebug['clientName']}',
          );
        }
      }

      final loginResult = await FlutterNaverLogin.logIn();

      if (loginResult.status != NaverLoginStatus.loggedIn) {
        throw Exception('네이버 로그인이 취소되었거나 실패했습니다.');
      }

      final token = await FlutterNaverLogin.getCurrentAccessToken();

      final response = await http.post(
        Uri.parse('$authApiBaseUrl/api/auth/naver'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': token.accessToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('네이버 로그인 서버 요청에 실패했습니다.');
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final customToken = body['customToken'] as String?;

      if (customToken == null || customToken.isEmpty) {
        throw Exception('Firebase 로그인 토큰을 받지 못했습니다.');
      }

      final credential =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);

      final user = credential.user;
      if (user != null) {
        await ensureUserProfile(user);
      }
    } catch (error) {
      setState(() {
        _errorMessage = '네이버 로그인에 실패했습니다. $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isNaverLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _readNaverConfigDebug() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final raw = await nativeConfigChannel.invokeMethod<Map<dynamic, dynamic>>(
      'getNaverConfigDebug',
    );
    if (raw == null) {
      return null;
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<kakao.OAuthToken> _requestKakaoToken() async {
    if (await kakao.isKakaoTalkInstalled()) {
      try {
        return kakao.UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        return kakao.UserApi.instance.loginWithKakaoAccount();
      }
    }

    return kakao.UserApi.instance.loginWithKakaoAccount();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '로그인',
      subtitle: 'SNS로 로그인한 뒤 별명을 입력하면 ECO를 이용할 수 있어요.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.tonal(
            onPressed: _isKakaoLoading ? null : _loginWithKakao,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF191919),
            ),
            child: Text(_isKakaoLoading ? '카카오 로그인 중...' : '카카오 로그인'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _isNaverLoading ? null : _loginWithNaver,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF03C75A),
              foregroundColor: Colors.white,
            ),
            child: Text(_isNaverLoading ? '네이버 로그인 중...' : '네이버 로그인'),
          ),
        ],
      ),
    );
  }
}
