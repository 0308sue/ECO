import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../model/ranking_user.dart';

class RankingService {
  RankingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Stream<List<RankingUser>> watchTopUsers({int limit = 30}) {
    return Stream.fromFuture(fetchTopUsers(limit: limit));
  }

  Future<List<RankingUser>> fetchTopUsers({int limit = 30}) async {
    final uri = Uri.parse(
      rankingUrl,
    ).replace(queryParameters: {'limit': '$limit'});
    final response = await _client.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('랭킹 조회에 실패했습니다. 상태 코드: ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! List) {
      throw Exception('랭킹 응답 형식이 올바르지 않습니다.');
    }

    return body
        .whereType<Map<String, dynamic>>()
        .map(RankingUser.fromJson)
        .toList();
  }
}
