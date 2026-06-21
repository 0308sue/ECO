import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/api_constants.dart';
import '../../core/theme/eco_design_system.dart';
import 'eco_place.dart';
import 'eco_place_repository.dart';

class EcoPlaceMapPage extends StatefulWidget {
  const EcoPlaceMapPage({
    super.key,
    this.onBack,
    this.bottomInset = 32,
  });

  final VoidCallback? onBack;
  final double bottomInset;

  @override
  State<EcoPlaceMapPage> createState() =>
      _EcoPlaceMapPageState();
}

class _EcoPlaceMapPageState extends State<EcoPlaceMapPage> {
  final EcoPlaceRepository _repository =
      EcoPlaceRepository();

  WebViewController? _webViewController;

  List<EcoPlace> _places = [];
  EcoPlace? _selectedPlace;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlacesAndMap();
  }

  Future<void> _loadPlacesAndMap() async {
    try {
      if (kakaoJavascriptAppKey.isEmpty) {
        throw Exception(
          'KAKAO_JAVASCRIPT_APP_KEY가 비어 있습니다.',
        );
      }

      final places = await _repository.fetchPlaces();

      final controller = WebViewController()
        ..setJavaScriptMode(
          JavaScriptMode.unrestricted,
        )
        ..setBackgroundColor(
          const Color(0x00000000),
        )
        ..addJavaScriptChannel(
          'EcoPlaceChannel',
          onMessageReceived: (message) {
            _selectPlace(message.message);
          },
        );

      final html = _buildMapHtml(places);

      await controller.loadHtmlString(
        html,
        baseUrl: 'http://localhost',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _places = places;
        _webViewController = controller;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _selectPlace(String placeId) {
    final matches = _places.where(
      (place) => place.id == placeId,
    );

    if (matches.isEmpty) {
      return;
    }

    setState(() {
      _selectedPlace = matches.first;
    });
  }

  void _handleBack() {
    final onBack = widget.onBack;

    if (onBack != null) {
      onBack();
      return;
    }

    Navigator.of(context).maybePop();
  }

  String _buildMapHtml(
    List<EcoPlace> places,
  ) {
    final placesJson = jsonEncode(
      places.map((place) {
        return {
          'id': place.id,
          'placeName': place.placeName,
          'placeType': place.placeType,
          'address': place.address,
          'lat': place.lat,
          'lng': place.lng,
          'reason': place.reason,
        };
      }).toList(),
    );

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
  />

  <style>
    html, body {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
      overflow: hidden;
      background: #f9faf7;
    }

    #map {
      width: 100%;
      height: 100%;
    }

    .error-box {
      padding: 16px;
      font-family: sans-serif;
      color: #222;
      line-height: 1.5;
    }
  </style>

  <script
    type="text/javascript"
    src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$kakaoJavascriptAppKey&autoload=false&libraries=clusterer">
  </script>
</head>

<body>
  <div id="map"></div>

  <script>
    const places = $placesJson;

    function showError(message) {
      document.body.innerHTML =
        '<div class="error-box">' + message + '</div>';
    }

    function escapeHtml(text) {
      if (!text) return '';

      return String(text)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    }

    if (typeof kakao === 'undefined') {
      showError(
        '카카오 지도 SDK를 불러오지 못했습니다.<br>' +
        'JavaScript 키, 카카오맵 사용 설정, JavaScript SDK 도메인을 확인해주세요.'
      );
    } else {
      kakao.maps.load(function () {
        const container =
          document.getElementById('map');

        const map = new kakao.maps.Map(
          container,
          {
            center: new kakao.maps.LatLng(
              36.5,
              127.8
            ),
            level: 13
          }
        );

        const bounds =
          new kakao.maps.LatLngBounds();

        const infoWindow =
          new kakao.maps.InfoWindow({
            zIndex: 1
          });

        const clusterer =
          new kakao.maps.MarkerClusterer({
            map: map,
            averageCenter: true,
            minLevel: 8
          });

        const markers = [];

        places.forEach(function (place) {
          if (!place.lat || !place.lng) {
            return;
          }

          const position =
            new kakao.maps.LatLng(
              place.lat,
              place.lng
            );

          bounds.extend(position);

          const marker =
            new kakao.maps.Marker({
              position: position,
              title: place.placeName
            });

          kakao.maps.event.addListener(
            marker,
            'click',
            function () {
              const content =
                '<div style="padding:8px 10px;font-size:13px;white-space:nowrap;">' +
                '<strong>' +
                escapeHtml(place.placeName) +
                '</strong><br/>' +
                escapeHtml(place.placeType) +
                '</div>';

              infoWindow.setContent(content);
              infoWindow.open(map, marker);

              map.panTo(position);

              if (window.EcoPlaceChannel) {
                window.EcoPlaceChannel.postMessage(
                  place.id
                );
              }
            }
          );

          markers.push(marker);
        });

        clusterer.addMarkers(markers);

        if (markers.length > 0) {
          map.setBounds(bounds);
        }
      });
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: EcoColors.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: EcoColors.primary,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                '지도를 불러오지 못했습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EcoColors.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: EcoColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _handleBack,
                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),
                label: const Text(
                  '돌아가기',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_webViewController == null) {
      return const Center(
        child: Text(
          '지도를 불러오지 못했습니다.',
          style: TextStyle(
            color: EcoColors.muted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(
            controller: _webViewController!,
          ),
        ),

        Positioned(
          left: 20,
          right: 20,
          top: 54,
          child: _MapTopPanel(
            count: _places.length,
            onTapBack: _handleBack,
          ),
        ),

        if (_selectedPlace != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: widget.bottomInset,
            child: _EcoPlaceDetailCard(
              place: _selectedPlace!,
              onClose: () {
                setState(() {
                  _selectedPlace = null;
                });
              },
            ),
          ),
      ],
    );
  }
}

class _MapTopPanel extends StatelessWidget {
  const _MapTopPanel({
    required this.count,
    required this.onTapBack,
  });

  final int count;
  final VoidCallback onTapBack;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.fromLTRB(
        14,
        14,
        15,
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EcoColors.primary.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onTapBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: EcoColors.secondary,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '친환경 장소',
                  style: TextStyle(
                    color: EcoColors.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '등록된 제로웨이스트 장소를 확인해요.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EcoColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: EcoColors.primary.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count곳',
              style: const TextStyle(
                color: EcoColors.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcoPlaceDetailCard extends StatelessWidget {
  const _EcoPlaceDetailCard({
    required this.place,
    required this.onClose,
  });

  final EcoPlace place;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return EcoCard(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        12,
        18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: EcoColors.primary.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: EcoColors.secondary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  place.placeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: EcoColors.text,
                    height: 1.25,
                  ),
                ),
              ),

              IconButton(
                onPressed: onClose,
                color: EcoColors.muted,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: EcoColors.primary.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              place.placeType,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EcoColors.secondary,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: EcoColors.muted,
                size: 17,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  place.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: EcoColors.muted,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          if (place.reason.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              place.reason,
              style: const TextStyle(
                fontSize: 13,
                color: EcoColors.text,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}