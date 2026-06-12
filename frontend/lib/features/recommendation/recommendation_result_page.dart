import 'dart:convert';
import '../place/eco_place_map_page.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';

class RecommendationResultPage extends StatefulWidget {
  const RecommendationResultPage({
    super.key,
    required this.savedResult,
  });

  final Map<String, dynamic> savedResult;

  @override
  State<RecommendationResultPage> createState() =>
      _RecommendationResultPageState();
}

class _RecommendationResultPageState extends State<RecommendationResultPage> {
  bool _isLoading = true;
  List<dynamic> _recommendedItems = [];
  List<dynamic> _recommendedPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final items = widget.savedResult['items'];
    final summary = widget.savedResult['summary'];

    if (items is! List || items.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final requestBody = {
      'userID': widget.savedResult['userId'],
      'items': items,
      'summary': summary,
      'lat': null,
      'lng': null,
    };

    try {
      final itemResponse = await http.post(
        Uri.parse(recommendationItemsUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final placeResponse = await http.post(
        Uri.parse(recommendationPlacesUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      final itemBody = utf8.decode(itemResponse.bodyBytes);
      final placeBody = utf8.decode(placeResponse.bodyBytes);

      debugPrint('추천 아이템 응답 status: ${itemResponse.statusCode}');
      debugPrint('추천 아이템 응답 body: $itemBody');

      if (itemResponse.statusCode >= 200 && itemResponse.statusCode < 300) {
        final decodedItems = jsonDecode(itemBody);
        if (decodedItems is List) {
          _recommendedItems = decodedItems;
          debugPrint('추천 아이템 개수: ${_recommendedItems.length}');
        }
      } else {
        _showMessage('추천 아이템 조회 실패: ${itemResponse.statusCode}');
      }

      if (placeResponse.statusCode >= 200 && placeResponse.statusCode < 300) {
        final decodedPlaces = jsonDecode(placeBody);
        if (decodedPlaces is List) {
          _recommendedPlaces = decodedPlaces;
        }
      } else {
        _showMessage('추천 장소 조회 실패: ${placeResponse.statusCode}');
      }
    } catch (e) {
      _showMessage('추천 요청 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Map<String, dynamic>? get _summary {
    final summary = widget.savedResult['summary'];
    if (summary is Map<String, dynamic>) {
      return summary;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('추천 결과'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReceiptInfoCard(),
            const SizedBox(height: 12),

            if (summary != null) ...[
              _buildSummaryCard(summary),
              const SizedBox(height: 12),
            ],

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildRecommendedItemsCard(),
              const SizedBox(height: 12),
              _buildRecommendedPlacesCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptInfoCard() {
    return Card(
      child: ListTile(
        title: const Text('저장된 영수증'),
        subtitle: Text(
          'receiptId: ${widget.savedResult['receiptId'] ?? '-'}\n'
          'userId: ${widget.savedResult['userId'] ?? '-'}',
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '영수증 요약',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('총 금액: ${summary['totalPrice'] ?? '-'}원'),
            Text('총 추정 탄소량: ${summary['totalEstimatedCarbonGram'] ?? '-'}g CO₂-eq'),
            Text('총 추정 탄소량: ${summary['totalEstimatedCarbonKg'] ?? '-'}kg CO₂-eq'),
            Text('평균 탄소 점수: ${summary['averageCarbonScore'] ?? '-'}'),
            Text('품목 수: ${summary['itemCount'] ?? '-'}개'),
            Text('주요 카테고리: ${summary['topCategory'] ?? '-'}'),
            Text('주요 세부 카테고리: ${summary['topSubCategory'] ?? '-'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedItemsCard() {
    if (_recommendedItems.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('추천 아이템이 없습니다.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '추천 아이템',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ..._recommendedItems.map((item) {
              final map = item as Map<String, dynamic>;

              final originalItem = map['originalItem'] ?? '-';
              final recommendedItem = map['recommendedItem'] ?? '-';
              final reason = map['reason'] ?? '';
              final companyName = map['companyName'];
              final certificationNo = map['certificationNo'];
              final sourceName = map['sourceName'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '추천: $recommendedItem',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if ('$reason'.isNotEmpty) Text('이유: $reason'),
                    if (companyName != null) Text('업체명: $companyName'),
                    if (certificationNo != null) Text('인증번호: $certificationNo'),
                    if (sourceName != null) Text('출처: $sourceName'),
                    const Divider(),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedPlacesCard() {
    if (_recommendedPlaces.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('관련 친환경 장소 정보가 없습니다.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '친환경 장소 모아보기',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '현재 위치 기반 추천이 아닌, 소비 품목과 관련된 친환경 장소 유형입니다.',
            ),
            const SizedBox(height: 12),

            ..._recommendedPlaces.map((place) {
              final map = place as Map<String, dynamic>;

              final placeName = map['placeName'] ?? '-';
              final placeType = map['placeType'] ?? '-';
              final address = map['address'] ?? '-';
              final reason = map['reason'] ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$placeName',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('장소 유형: $placeType'),
                    Text('주소: $address'),
                    if ('$reason'.isNotEmpty) Text('설명: $reason'),
                    const Divider(),
                  ],
                ),
              );
            }),

            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EcoPlaceMapPage(),
                  ),
                );
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('친환경 장소 지도 보기'),
            ),
          ],
        ),
      ),
    );
  }
 }