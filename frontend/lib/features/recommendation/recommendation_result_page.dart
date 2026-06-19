import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';
import '../place/eco_place_map_page.dart';

class RecommendationResultPage extends StatefulWidget {
  const RecommendationResultPage({super.key, required this.savedResult});

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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final placeResponse = await http.post(
        Uri.parse(recommendationPlacesUrl),
        headers: {'Content-Type': 'application/json'},
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildHeroCard(summary),
              const SizedBox(height: 22),
              if (_isLoading)
                _buildLoadingCard()
              else ...[
                _buildRecommendedItemsCard(),
                const SizedBox(height: 22),
                _buildRecommendedPlacesCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '추천 결과',
                style: TextStyle(
                  color: EcoColors.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '이번 소비를 더 친환경적으로 바꿔봐요',
                style: TextStyle(
                  color: EcoColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Map<String, dynamic>? summary) {
    final totalPrice = summary?['totalPrice'] ?? '-';
    final carbonScore = summary?['averageCarbonScore'] ?? '-';
    final topCategory = summary?['topCategory'] ?? '-';
    final itemCount = summary?['itemCount'] ?? '-';

    return EcoCard(
      color: EcoColors.secondary,
      radius: 28,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '소비 분석 완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '추천 상품과 장소를 확인해요',
                      style: TextStyle(
                        color: Color(0xFFD5E7DA),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _DarkMetric(label: '총 금액', value: '$totalPrice원'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkMetric(label: '탄소 점수', value: '$carbonScore'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DarkMetric(label: '품목', value: '$itemCount개'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DarkMetric(label: '주요 카테고리', value: '$topCategory'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return EcoCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircularProgressIndicator(
            color: EcoColors.primary,
            backgroundColor: EcoColors.primary.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 18),
          const Text(
            '추천 결과를 불러오는 중이에요',
            style: TextStyle(
              color: EcoColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '품목과 카테고리를 기준으로 친환경 대안을 찾고 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EcoColors.muted,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRecommendedItemsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EcoSectionHeader(title: '추천 상품'),
        const SizedBox(height: 10),
        if (_recommendedItems.isEmpty)
          const _EmptyCard(message: '추천 상품이 없습니다.')
        else
          ..._recommendedItems.map((item) {
            final map = item as Map<String, dynamic>;

            final originalItem = map['originalItem'] ?? '-';
            final recommendedItem = map['recommendedItem'] ?? '-';
            final reason = '${map['reason'] ?? ''}';
            final companyName = map['companyName'];
            final certificationNo = map['certificationNo'];
            final sourceName = map['sourceName'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EcoCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EcoPill(
                      label: '대체 추천',
                      icon: Icons.autorenew_rounded,
                      background: EcoColors.primary.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '$recommendedItem',
                      style: const TextStyle(
                        color: EcoColors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '기존 품목: $originalItem',
                      style: const TextStyle(
                        color: EcoColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        reason,
                        style: const TextStyle(
                          color: EcoColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (companyName != null)
                          _MetaChip(label: '업체 $companyName'),
                        if (certificationNo != null)
                          _MetaChip(label: '인증 $certificationNo'),
                        if (sourceName != null)
                          _MetaChip(label: '출처 $sourceName'),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecommendedPlacesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EcoSectionHeader(
          title: '추천 장소',
          trailing: '지도 보기',
          onTapTrailing: _openEcoPlaceMap,
        ),
        const SizedBox(height: 10),
        if (_recommendedPlaces.isEmpty)
          const _EmptyCard(message: '관련 친환경 장소 정보가 없습니다.')
        else ...[
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '소비 품목과 관련된 친환경 장소 유형을 보여드려요.',
              style: TextStyle(
                color: EcoColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ..._recommendedPlaces.map((place) {
            final map = place as Map<String, dynamic>;

            final placeName = map['placeName'] ?? '-';
            final placeType = map['placeType'] ?? '-';
            final address = map['address'] ?? '-';
            final reason = '${map['reason'] ?? ''}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EcoCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: EcoColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.place_outlined,
                        color: EcoColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$placeName',
                            style: const TextStyle(
                              color: EcoColors.text,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '$placeType · $address',
                            style: const TextStyle(
                              color: EcoColors.muted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                          if (reason.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              reason,
                              style: const TextStyle(
                                color: EcoColors.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          _MapCtaButton(onTap: _openEcoPlaceMap),
        ],
      ],
    );
  }

  void _openEcoPlaceMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EcoPlaceMapPage()),
    );
  }
}

class _DarkMetric extends StatelessWidget {
  const _DarkMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD5E7DA),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: EcoColors.line),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: EcoColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MapCtaButton extends StatelessWidget {
  const _MapCtaButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: EcoColors.secondary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: EcoColors.secondary.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Text(
                  '친환경 장소 지도 보기',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            color: EcoColors.primary.withValues(alpha: 0.7),
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: EcoColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: EcoColors.line),
          boxShadow: EcoShadow.soft,
        ),
        child: Icon(icon, color: EcoColors.text, size: 28),
      ),
    );
  }
}
