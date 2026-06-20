import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../place/eco_place_map_page.dart';


class RecommendationResultSection extends StatefulWidget {
  const RecommendationResultSection({
    super.key,
    required this.savedResult,
  });

  final Map<String, dynamic> savedResult;

  @override
  State<RecommendationResultSection> createState() =>
      _RecommendationResultSectionState();
}

class _RecommendationResultSectionState
    extends State<RecommendationResultSection> {
  bool _isLoading = true;

  List<dynamic> _recommendedItems = [];
  List<dynamic> _recommendedPlaces = [];

  String? _itemError;
  String? _placeError;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final items = widget.savedResult['items'];
    final summary = widget.savedResult['summary'];

    if (items is! List || items.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _itemError = '추천에 사용할 저장 품목이 없습니다.';
        _placeError = '추천에 사용할 저장 품목이 없습니다.';
      });

      return;
    }

    final requestBody = {
      // 기존 백엔드 요청 형식을 그대로 유지합니다.
      'userID': widget.savedResult['userId'],
      'items': items,
      'summary': summary,
      'lat': null,
      'lng': null,
    };

    try {
      // 아이템 추천과 장소 추천을 동시에 요청합니다.
      final responses = await Future.wait([
        http.post(
          Uri.parse(recommendationItemsUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        ),
        http.post(
          Uri.parse(recommendationPlacesUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestBody),
        ),
      ]);

      final itemResponse = responses[0];
      final placeResponse = responses[1];

      final itemBody = utf8.decode(
        itemResponse.bodyBytes,
      );

      final placeBody = utf8.decode(
        placeResponse.bodyBytes,
      );

      debugPrint(
        '추천 아이템 응답 status: ${itemResponse.statusCode}',
      );
      debugPrint(
        '추천 아이템 응답 body: $itemBody',
      );
      debugPrint(
        '추천 장소 응답 status: ${placeResponse.statusCode}',
      );
      debugPrint(
        '추천 장소 응답 body: $placeBody',
      );

      List<dynamic> recommendedItems = [];
      List<dynamic> recommendedPlaces = [];

      String? itemError;
      String? placeError;

      if (itemResponse.statusCode >= 200 &&
          itemResponse.statusCode < 300) {
        final decodedItems = jsonDecode(itemBody);

        if (decodedItems is List) {
          recommendedItems = decodedItems;
        } else {
          itemError = '추천 아이템 응답 형식이 올바르지 않습니다.';
        }
      } else {
        itemError =
            '추천 아이템을 불러오지 못했습니다. (${itemResponse.statusCode})';
      }

      if (placeResponse.statusCode >= 200 &&
          placeResponse.statusCode < 300) {
        final decodedPlaces = jsonDecode(placeBody);

        if (decodedPlaces is List) {
          recommendedPlaces = decodedPlaces;
        } else {
          placeError = '추천 장소 응답 형식이 올바르지 않습니다.';
        }
      } else {
        placeError =
            '추천 장소를 불러오지 못했습니다. (${placeResponse.statusCode})';
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _recommendedItems = recommendedItems;
        _recommendedPlaces = recommendedPlaces;
        _itemError = itemError;
        _placeError = placeError;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _itemError = '추천 아이템 요청 중 오류가 발생했습니다.';
        _placeError = '추천 장소 요청 중 오류가 발생했습니다.';
        _isLoading = false;
      });

      debugPrint('추천 요청 오류: $e');
    }
  }

  void _retryRecommendations() {
    setState(() {
      _isLoading = true;
      _recommendedItems = [];
      _recommendedPlaces = [];
      _itemError = null;
      _placeError = null;
    });

    _loadRecommendations();
  }

  String _readText(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];

    if (value == null) {
      return '';
    }

    return '$value'.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingView();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRecommendedItemsSection(),
        const SizedBox(height: 34),
        _buildRecommendedPlacesSection(),
        if (_itemError != null || _placeError != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _retryRecommendations,
              icon: const Icon(Icons.refresh),
              label: const Text('추천 다시 불러오기'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '지구를 위한 친환경 아이템',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '저장된 품목을 기준으로 추천을 준비하고 있어요.',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 2,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 12),
            itemBuilder: (_, __) {
              return Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '지구를 위한 친환경 아이템',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '소비한 품목을 기준으로 친환경 대안을 골라봤어요.',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_recommendedItems.isEmpty)
          _buildEmptyCard(
            icon: Icons.eco_outlined,
            message: _itemError ?? '추천 아이템이 없습니다.',
          )
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedItems.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = _recommendedItems[index];

                final map = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};

                return _buildItemCard(map);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(
    Map<String, dynamic> map,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final cardWidth = (screenWidth * 0.74)
        .clamp(250.0, 330.0)
        .toDouble();

    final originalItem = _readText(
      map,
      'originalItem',
    );

    final recommendedItem = _readText(
      map,
      'recommendedItem',
    );

    final reason = _readText(
      map,
      'reason',
    );

    final companyName = _readText(
      map,
      'companyName',
    );

    final certificationNo = _readText(
      map,
      'certificationNo',
    );

    final sourceName = _readText(
      map,
      'sourceName',
    );

    return SizedBox(
      width: cardWidth,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                    ),
                    child: Icon(
                      Icons.eco_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  if (originalItem.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$originalItem 대안',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Text(
                recommendedItem.isEmpty
                    ? '친환경 추천 아이템'
                    : recommendedItem,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reason,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              if (companyName.isNotEmpty)
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (certificationNo.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  '인증번호 $certificationNo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
              if (sourceName.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  '출처 $sourceName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이런 장소도 방문해 보세요',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '소비 품목과 관련된 친환경 장소를 모아봤어요.',
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_recommendedPlaces.isEmpty)
          _buildEmptyCard(
            icon: Icons.location_on_outlined,
            message:
                _placeError ?? '관련 친환경 장소가 없습니다.',
          )
        else ...[
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedPlaces.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final place = _recommendedPlaces[index];

                final map = place is Map
                    ? Map<String, dynamic>.from(place)
                    : <String, dynamic>{};

                return _buildPlaceCard(map);
              },
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EcoPlaceMapPage(),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('전체 지도에서 보기'),
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> map,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final cardWidth = (screenWidth * 0.78)
        .clamp(270.0, 350.0)
        .toDouble();

    final placeName = _readText(
      map,
      'placeName',
    );

    final placeType = _readText(
      map,
      'placeType',
    );

    final address = _readText(
      map,
      'address',
    );

    final reason = _readText(
      map,
      'reason',
    );

    return SizedBox(
      width: cardWidth,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Theme.of(context)
                          .colorScheme
                          .onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      placeName.isEmpty
                          ? '친환경 장소'
                          : placeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (placeType.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    placeType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                ),
              ],
              if (address.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}