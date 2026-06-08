import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EcoPlaceMapPage extends StatefulWidget {
  const EcoPlaceMapPage({
    super.key,
    required this.places,
  });

  final List<dynamic> places;

  @override
  State<EcoPlaceMapPage> createState() => _EcoPlaceMapPageState();
}

class _EcoPlaceMapPageState extends State<EcoPlaceMapPage> {
  static const String _kakaoJavaScriptKey =
      String.fromEnvironment('KAKAO_JAVASCRIPT_KEY');

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final validPlaces = widget.places.where((place) {
      if (place is! Map<String, dynamic>) {
        return false;
      }

      final lat = _toDouble(place['lat']);
      final lng = _toDouble(place['lng']);

      return lat != null && lng != null;
    }).toList();

    final html = _buildMapHtml(validPlaces);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            debugPrint('WEBVIEW ERROR: ${error.description}');
            debugPrint('WEBVIEW ERROR CODE: ${error.errorCode}');
            debugPrint('WEBVIEW ERROR TYPE: ${error.errorType}');
          },
          onPageFinished: (url) {
            debugPrint('WEBVIEW PAGE FINISHED: $url');
          },
        ),
      )
      ..loadHtmlString(
        html,
        baseUrl: 'http://localhost',
      );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  String _escapeHtml(dynamic value) {
    return value
        .toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }

  String _buildMapHtml(List<dynamic> places) {
    final placeData = places.map((place) {
      final map = place as Map<String, dynamic>;

      return {
        'name': _escapeHtml(map['placeName'] ?? '-'),
        'type': _escapeHtml(map['placeType'] ?? '-'),
        'address': _escapeHtml(map['address'] ?? '-'),
        'description': _escapeHtml(map['reason'] ?? ''),
        'lat': _toDouble(map['lat']),
        'lng': _toDouble(map['lng']),
      };
    }).toList();

    final encodedPlaces = jsonEncode(placeData);

    final defaultLat = placeData.isNotEmpty ? placeData.first['lat'] : 37.5665;
    final defaultLng = placeData.isNotEmpty ? placeData.first['lng'] : 126.9780;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta
    name="viewport"
    content="width=device-width, initial-scale=1.0, maximum-scale=1.0"
  />
  <style>
    html, body, #map {
      width: 100%;
      height: 100%;
      margin: 0;
      padding: 0;
    }

    .message {
      padding: 16px;
      font-size: 14px;
      line-height: 1.5;
    }

    .info {
      padding: 8px 10px;
      font-size: 13px;
      line-height: 1.4;
      max-width: 240px;
    }

    .title {
      font-weight: 700;
      margin-bottom: 4px;
    }

    .type {
      color: #555;
      margin-bottom: 4px;
    }

    .address {
      color: #333;
      margin-bottom: 4px;
    }

    .desc {
      color: #666;
    }
  </style>
  <script src="https://dapi.kakao.com/v2/maps/sdk.js?appkey=$_kakaoJavaScriptKey&autoload=false"></script>
</head>
<body>
  <div id="map"></div>

  <script>
    const places = $encodedPlaces;

    function showMessage(message) {
      document.body.innerHTML =
        '<div class="message">' + message + '</div>';
    }

    function drawMap() {
      if (!places || places.length === 0) {
        showMessage('표시할 친환경 장소가 없습니다.');
        return;
      }

      const mapContainer = document.getElementById('map');

      const mapOption = {
        center: new kakao.maps.LatLng($defaultLat, $defaultLng),
        level: 7
      };

      const map = new kakao.maps.Map(mapContainer, mapOption);
      const bounds = new kakao.maps.LatLngBounds();

      places.forEach(function(place) {
        const position = new kakao.maps.LatLng(place.lat, place.lng);

        const marker = new kakao.maps.Marker({
          map: map,
          position: position,
          title: place.name
        });

        bounds.extend(position);

        const content =
          '<div class="info">' +
            '<div class="title">' + place.name + '</div>' +
            '<div class="type">' + place.type + '</div>' +
            '<div class="address">' + place.address + '</div>' +
            (place.description
              ? '<div class="desc">' + place.description + '</div>'
              : '') +
          '</div>';

        const infoWindow = new kakao.maps.InfoWindow({
          content: content
        });

        kakao.maps.event.addListener(marker, 'click', function() {
          infoWindow.open(map, marker);
        });
      });

      map.setBounds(bounds);
    }

    if (typeof kakao === 'undefined') {
      showMessage(
        '카카오맵 SDK를 불러오지 못했습니다. JavaScript 키 또는 Web 플랫폼 도메인을 확인해 주세요.'
      );
    } else {
      kakao.maps.load(function() {
        drawMap();
      });
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_kakaoJavaScriptKey.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('친환경 장소 지도'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '카카오 JavaScript 키가 설정되지 않았습니다.\n'
              'KAKAO_JAVASCRIPT_KEY를 실행 옵션에 추가해 주세요.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('친환경 장소 지도'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}