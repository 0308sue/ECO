import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import 'eco_place.dart';

class EcoPlaceRepository {
  Future<List<EcoPlace>> fetchPlaces() async {
    final response = await http.get(Uri.parse(recommendationPlacesUrl));

    if (response.statusCode != 200) {
      throw Exception('장소 목록을 불러오지 못했습니다. status=${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! List) {
      throw Exception('장소 응답 형식이 올바르지 않습니다.');
    }

    return decoded
        .map((item) => EcoPlace.fromJson(item as Map<String, dynamic>))
        .where((place) => place.id.isNotEmpty)
        .where((place) => place.lat != 0 && place.lng != 0)
        .toList();
  }
}