import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/auth_scaffold.dart';
import '../../utils/validators.dart';
import '../profile/user_profile_service.dart';
import 'auth_gate.dart';

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
        'loginProvider': loginProviderOf(widget.user),
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
              validator: validateNickname,
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