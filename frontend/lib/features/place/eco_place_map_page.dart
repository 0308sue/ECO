import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/constants/api_constants.dart';
import 'eco_place.dart';
import 'eco_place_repository.dart';

class EcoPlaceMapPage extends StatefulWidget {
  const EcoPlaceMapPage({super.key});

  @override
  State<EcoPlaceMapPage> createState() => _EcoPlaceMapPageState();
}

class _EcoPlaceMapPageState extends State<EcoPlaceMapPage> {
  final EcoPlaceRepository _repository = EcoPlaceRepository();

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
        throw Exception('KAKAO_JAVASCRIPT_APP_KEY가 비어 있습니다.');
      }

      final places = await _repository.fetchPlaces();

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
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

      setState(() {
        _places = places;
        _webViewController = controller;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectPlace(String placeId) {
    final matches = _places.where((place) => place.id == placeId);

    if (matches.isEmpty) {
      return;
    }

    setState(() {
      _selectedPlace = matches.first;
    });
  }

  String _buildMapHtml(List<EcoPlace> places) {
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
      background: #f8fbf2;
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
        const container = document.getElementById('map');

        const map = new kakao.maps.Map(container, {
          center: new kakao.maps.LatLng(36.5, 127.8),
          level: 13
        });

        const bounds = new kakao.maps.LatLngBounds();

        const infoWindow = new kakao.maps.InfoWindow({
          zIndex: 1
        });

        const clusterer = new kakao.maps.MarkerClusterer({
          map: map,
          averageCenter: true,
          minLevel: 8
        });

        const markers = [];

        places.forEach(function (place) {
          if (!place.lat || !place.lng) return;

          const position = new kakao.maps.LatLng(place.lat, place.lng);
          bounds.extend(position);

          const marker = new kakao.maps.Marker({
            position: position,
            title: place.placeName
          });

          kakao.maps.event.addListener(marker, 'click', function () {
            const content =
              '<div style="padding:8px 10px;font-size:13px;white-space:nowrap;">' +
              '<strong>' + escapeHtml(place.placeName) + '</strong><br/>' +
              escapeHtml(place.placeType) +
              '</div>';

            infoWindow.setContent(content);
            infoWindow.open(map, marker);
            map.panTo(position);

            if (window.EcoPlaceChannel) {
              window.EcoPlaceChannel.postMessage(place.id);
            }
          });

          markers.push(marker);
        });

        clusterer.addMarkers(markers);

        if (markers.length > 0) {
          map.setBounds(bounds);
        }

        if (places.length > 0) {
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
      appBar: AppBar(
        title: const Text('친환경 장소 지도'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_webViewController == null) {
      return const Center(
        child: Text('지도를 불러오지 못했습니다.'),
      );
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),

        Positioned(
          left: 16,
          right: 16,
          top: 16,
          child: _PlaceCountBadge(count: _places.length),
        ),

        if (_selectedPlace != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
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

class _PlaceCountBadge extends StatelessWidget {
  final int count;

  const _PlaceCountBadge({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            '전체 장소 $count개',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EcoPlaceDetailCard extends StatelessWidget {
  final EcoPlace place;
  final VoidCallback onClose;

  const _EcoPlaceDetailCard({
    required this.place,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.placeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              place.placeType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              place.address,
              style: const TextStyle(fontSize: 14),
            ),
            if (place.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                place.reason,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}