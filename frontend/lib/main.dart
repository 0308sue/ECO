import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

import 'firebase_options.dart';

const String kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');
const String configuredAuthApiBaseUrl = String.fromEnvironment(
  'AUTH_API_BASE_URL',
);

String get authApiBaseUrl {
  if (configuredAuthApiBaseUrl.isNotEmpty) {
    return configuredAuthApiBaseUrl;
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }
  if (kakaoNativeAppKey.isNotEmpty) {
    kakao.KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }
  runApp(const EcoApp());
}

class EcoApp extends StatelessWidget {
  const EcoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECO',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }

        return UserProfileGate(user: user);
      },
    );
  }
}

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
        await _ensureUserProfile(user);
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
        await _ensureUserProfile(user);
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

class UserProfileGate extends StatelessWidget {
  const UserProfileGate({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _ensureUserProfile(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data?.data();
        final nickname = (data?['nickname'] as String?)?.trim() ?? '';
        final needsNickname = !snapshot.hasData ||
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

class NicknameSetupPage extends StatefulWidget {
  const NicknameSetupPage({super.key, required this.user});

  final User user;

  @override
  State<NicknameSetupPage> createState() => _NicknameSetupPageState();
}

class _NicknameSetupPageState extends State<NicknameSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final nickname = _nicknameController.text.trim();

    try {
      await widget.user.updateDisplayName(nickname);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'email': widget.user.email,
        'nickname': nickname,
        'ecoPoint': 0,
        'grade': 'Seed',
        'badges': <String>[],
        'loginProvider': _loginProviderOf(widget.user),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AuthGate(),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _errorMessage = '별명 저장에 실패했습니다. $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: '별명 입력',
      subtitle: 'ECO에서 사용할 별명을 입력하세요.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: '별명'),
              validator: _validateNickname,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isLoading ? null : _saveNickname,
              child: Text(_isLoading ? '저장 중...' : '로그인 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});

  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _ensureUserDocument();
  }

  Future<void> _ensureUserDocument() async {
    await _ensureUserProfile(widget.user);
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
              _InfoTile(
                title: '현재 탄소 점수',
                value: '$ecoPoint Eco Point',
                icon: Icons.eco,
              ),
              _InfoTile(
                title: '등급',
                value: grade,
                icon: Icons.workspace_premium,
              ),
              _InfoTile(
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
}

Future<void> _signOut(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final provider = user == null ? null : _loginProviderOf(user);

  await FirebaseAuth.instance.signOut();

  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  if (provider != null) {
    Future.microtask(() => _clearSocialSession(provider));
  }
}

Future<void> _deleteAccount(BuildContext context, User user) async {
  final messenger = ScaffoldMessenger.of(context);
  final provider = _loginProviderOf(user);

  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .delete();
    await user.delete();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
    Future.microtask(() => _unlinkSocialLogin(provider));
  } on FirebaseAuthException catch (error) {
    if (error.code == 'requires-recent-login') {
      messenger.showSnackBar(
        const SnackBar(content: Text('보안을 위해 다시 로그인한 뒤 탈퇴해주세요.')),
      );
      await _signOut(context);
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text('회원 탈퇴에 실패했습니다. ${_authErrorMessage(error)}')),
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('회원 탈퇴에 실패했습니다. $error')),
    );
  }
}

Future<DocumentSnapshot<Map<String, dynamic>>> _ensureUserProfile(
  User user,
) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await userDoc.get();

  if (snapshot.exists) {
    await userDoc.set({
      'email': user.email,
      'loginProvider': _loginProviderOf(user),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return userDoc.get();
  }

  await userDoc.set({
    'email': user.email,
    'nickname': user.uid.startsWith('kakao_') || user.uid.startsWith('naver_')
        ? ''
        : user.displayName ?? '사용자',
    'ecoPoint': 0,
    'grade': 'Seed',
    'badges': <String>[],
    'loginProvider': _loginProviderOf(user),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  return userDoc.get();
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
      await kakao.UserApi.instance.unlink().timeout(const Duration(seconds: 5));
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

String _loginProviderOf(User user) {
  if (user.uid.startsWith('kakao_')) {
    return 'kakao';
  }
  if (user.uid.startsWith('naver_')) {
    return 'naver';
  }
  return 'email';
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.eco,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}

String? _validateNickname(String? value) {
  final nickname = value?.trim() ?? '';
  if (nickname.isEmpty) {
    return '별명을 입력해주세요.';
  }
  if (nickname.length < 2) {
    return '별명은 2자 이상이어야 합니다.';
  }
  return null;
}

String _authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'user-not-found':
    case 'invalid-credential':
      return '로그인 정보가 유효하지 않습니다.';
    default:
      return error.message ?? '요청을 처리하지 못했습니다.';
  }
}
