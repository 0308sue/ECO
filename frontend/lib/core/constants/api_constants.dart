import 'dart:io';

const String kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

const String configuredAuthApiBaseUrl = String.fromEnvironment(
  'AUTH_API_BASE_URL',
);

String get authApiBaseUrl {
  if (configuredAuthApiBaseUrl.isNotEmpty) {
    return configuredAuthApiBaseUrl;
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080';
  }

  return 'http://localhost:8080';
}

String get receiptOcrTextUrl {
  return '$authApiBaseUrl/api/receipts/ocr-text';
}

String get receiptSaveUrl {
  return '$authApiBaseUrl/api/receipts';
}



String get recommendationItemsUrl {
  return '$authApiBaseUrl/api/recommendations/items';
}

String get recommendationPlacesUrl {
  return '$authApiBaseUrl/api/recommendations/places';
}