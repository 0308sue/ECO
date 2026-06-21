import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';

class RecommendationResultSection extends StatefulWidget {
  const RecommendationResultSection({
    super.key,
    required this.savedResult,
    required this.onTapEcoPlaceMap,
  });

  final Map<String, dynamic> savedResult;
  final VoidCallback onTapEcoPlaceMap;

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
      'userID': widget.savedResult['userId'],
      'items': items,
      'summary': summary,
      'lat': null,
      'lng': null,
    };

    try {
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
          itemError = '추천 상품 응답 형식이 올바르지 않습니다.';
        }
      } else {
        itemError =
            '추천 상품을 불러오지 못했습니다. '
            '(${itemResponse.statusCode})';
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
            '추천 장소를 불러오지 못했습니다. '
            '(${placeResponse.statusCode})';
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
        _recommendedItems = [];
        _recommendedPlaces = [];
        _itemError = '추천 상품 요청 중 오류가 발생했습니다.';
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

  void _openEcoPlaceMap() {
    widget.onTapEcoPlaceMap();
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
        const SizedBox(height: 28),
        _buildRecommendedPlacesSection(),
        if (_itemError != null || _placeError != null) ...[
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _retryRecommendations,
              style: TextButton.styleFrom(
                foregroundColor: EcoColors.secondary,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 19,
              ),
              label: const Text('추천 다시 불러오기'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingView() {
    return EcoCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: EcoColors.primary,
            backgroundColor:
                EcoColors.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 18),
          const Text(
            '추천 결과를 불러오는 중이에요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EcoColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '저장된 품목을 기준으로 친환경 상품과 장소를 찾고 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EcoColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '제품 추천',
          style: TextStyle(
            color: EcoColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          '소비 품목을 바탕으로 친환경 대체 제품을 추천했어요.',
          style: TextStyle(
            color: EcoColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        if (_recommendedItems.isEmpty)
          _EmptyCard(
            icon: Icons.eco_outlined,
            message: _itemError ?? '추천 상품이 없습니다.',
          )
        else
          SizedBox(
            height: 276,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedItems.length,
              separatorBuilder: (_, __) {
                return const SizedBox(width: 12);
              },
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

    final cardWidth = (screenWidth * 0.76)
        .clamp(260.0, 340.0)
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
      child: EcoCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EcoPill(
              label: originalItem.isEmpty
                  ? '친환경 추천'
                  : '$originalItem 대안',
              icon: Icons.autorenew_rounded,
              background:
                  EcoColors.primary.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 15),
            Text(
              recommendedItem.isEmpty
                  ? '친환경 추천 상품'
                  : recommendedItem,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EcoColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
                height: 1.3,
              ),
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                reason,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EcoColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  height: 1.45,
                ),
              ),
            ],
            const Spacer(),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (companyName.isNotEmpty)
                  _MetaChip(
                    label: companyName,
                    icon: Icons.business_outlined,
                  ),
                if (certificationNo.isNotEmpty)
                  _MetaChip(
                    label: certificationNo,
                    icon: Icons.verified_outlined,
                  ),
                if (sourceName.isNotEmpty)
                  _MetaChip(
                    label: sourceName,
                    icon: Icons.source_outlined,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EcoSectionHeader(
          title: '추천 장소',
          onTapTrailing: _openEcoPlaceMap,
        ),
        const SizedBox(height: 5),
        const Text(
          '소비 품목과 관련된 제로웨이스트 장소를 모아봤어요.',
          style: TextStyle(
            color: EcoColors.muted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        if (_recommendedPlaces.isEmpty)
          _EmptyCard(
            icon: Icons.location_on_outlined,
            message:
                _placeError ?? '관련 제로웨이스트 장소가 없습니다.',
          )
        else ...[
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedPlaces.length,
              separatorBuilder: (_, __) {
                return const SizedBox(width: 12);
              },
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
          _MapCtaButton(
            onTap: _openEcoPlaceMap,
          ),
        ],
      ],
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> map,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final cardWidth = (screenWidth * 0.8)
        .clamp(275.0, 350.0)
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
      child: EcoCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: EcoColors.primary.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.place_outlined,
                    color: EcoColors.secondary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    placeName.isEmpty
                        ? '친환경 장소'
                        : placeName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EcoColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (placeType.isNotEmpty) ...[
              const SizedBox(height: 13),
              EcoPill(
                label: placeType,
                icon: Icons.eco_outlined,
                background:
                    EcoColors.primary.withValues(alpha: 0.12),
              ),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: EcoColors.muted,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EcoColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 11),
              Text(
                reason,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: EcoColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EcoColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: EcoColors.muted,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 130,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EcoColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapCtaButton extends StatelessWidget {
  const _MapCtaButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: EcoColors.secondary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: EcoColors.secondary.withValues(
                  alpha: 0.16,
                ),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '더 많은 제로웨이스트 장소 보기',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 23,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            icon,
            color: EcoColors.primary.withValues(alpha: 0.7),
            size: 36,
          ),
          const SizedBox(height: 11),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}