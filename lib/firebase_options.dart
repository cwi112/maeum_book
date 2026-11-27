// 파이어베이스 연결 설정. 파이어베이스 관리 화면에서 받은 설정 파일 2개
// (ios/Runner/GoogleService-Info.plist, android/app/google-services.json)의 값을 옮겨 적은 것이다.
//
// 이 값들은 "어느 프로젝트로 보낼지"를 알려 주는 공개 값이라 앱 안에 들어가도 된다. (비밀 키 아님)
// 앱을 새로 등록하거나 프로젝트를 바꾸면 이 파일도 다시 만들어야 한다.
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class DefaultFirebaseOptions {
  /// 지금 플랫폼의 설정. 웹 · 데스크톱은 연결하지 않는다. (null)
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return null;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => ios,
      TargetPlatform.android => android,
      _ => null,
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANAKTifhNw2pUvZ0LZ04u4ClNn25CJNeo',
    appId: '1:54750086041:android:bb4ca2ff56927046ac8908',
    messagingSenderId: '54750086041',
    projectId: 'maeum-book-412fe',
    storageBucket: 'maeum-book-412fe.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD0pYgt7wC-hN6LHRQgIv5VBqoEPeZZUzU',
    appId: '1:54750086041:ios:b5faab1c9c2f694dac8908',
    messagingSenderId: '54750086041',
    projectId: 'maeum-book-412fe',
    storageBucket: 'maeum-book-412fe.firebasestorage.app',
    iosBundleId: 'com.maeumbook.maeumBook',
  );
}
