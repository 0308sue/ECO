import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/ranking_user.dart';

class RankingService {
  RankingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<RankingUser>> watchTopUsers({int limit = 30}) {
    return _firestore
        .collection('users')
        .orderBy('ecoPoint', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.indexed.map((entry) {
            final index = entry.$1;
            final doc = entry.$2;
            final data = doc.data();

            return RankingUser(
              id: doc.id,
              nickname: _readNickname(data, index),
              ecoPoint: _readEcoPoint(data),
              grade: (data['grade'] as String?)?.trim().isEmpty == false
                  ? data['grade'] as String
                  : 'Seed',
              rank: index + 1,
            );
          }).toList();
        });
  }

  String _readNickname(Map<String, dynamic> data, int index) {
    final nickname = (data['nickname'] as String?)?.trim();
    if (nickname != null && nickname.isNotEmpty) {
      return nickname;
    }
    return 'ECO 유저 ${index + 1}';
  }

  int _readEcoPoint(Map<String, dynamic> data) {
    final rawPoint = data['ecoPoint'];
    if (rawPoint is int) {
      return rawPoint;
    }
    if (rawPoint is num) {
      return rawPoint.toInt();
    }
    return 0;
  }
}
