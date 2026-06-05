import 'package:firebase_auth/firebase_auth.dart';

String? validateNickname(String? value) {
  final nickname = value?.trim() ?? '';

  if (nickname.isEmpty) {
    return '별명을 입력해주세요.';
  }

  if (nickname.length < 2) {
    return '별명은 2자 이상이어야 합니다.';
  }

  return null;
}

String authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'user-not-found':
    case 'invalid-credential':
      return '로그인 정보가 유효하지 않습니다.';
    default:
      return error.message ?? '요청을 처리하지 못했습니다.';
  }
}