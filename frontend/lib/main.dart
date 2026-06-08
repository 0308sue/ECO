import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;

import 'app.dart';
import 'core/constants/api_constants.dart';
import 'firebase_options.dart';
import 'ranking/screen/ranking_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    await Firebase.initializeApp();
  }

  if (kakaoNativeAppKey.isNotEmpty) {
    kakao.KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);
  }

  runApp(const EcoApp());
}
