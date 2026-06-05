import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<DocumentSnapshot<Map<String, dynamic>>> ensureUserProfile(
  User user,
) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  final snapshot = await userDoc.get();

  if (snapshot.exists) {
    await userDoc.set({
      'email': user.email,
      'loginProvider': loginProviderOf(user),
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
    'loginProvider': loginProviderOf(user),
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  return userDoc.get();
}

String loginProviderOf(User user) {
  if (user.uid.startsWith('kakao_')) {
    return 'kakao';
  }

  if (user.uid.startsWith('naver_')) {
    return 'naver';
  }

  return 'email';
}