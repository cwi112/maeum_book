import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:maeum_book/core/errors/network_exception.dart';
import 'package:maeum_book/firebase_options.dart';

/// 오류 기록(파이어베이스 Crashlytics) · 사용 분석(파이어베이스 Analytics)을 한곳에서 다룬다.
///
/// - **오류**: 앱이 멈추는 오류 · 화면 오류는 자동으로, 처리했지만 실패한 작업(저장 실패 등)은 [recordError]로 남긴다.
///   인터넷이 없어서 실패한 것([NetworkException])은 앱 문제가 아니라서 남기지 않는다.
/// - **사용 분석**: 어떤 화면 · 기능을 많이 쓰는지 [logScreen] · [logEvent]로 센다.
///
/// ## 개인정보
/// 이름 · 금액 · 메모 · 행사 이름 · 사진 같은 **기록 내용은 절대 보내지 않는다.** 보내는 건 "무엇을 했는지"(예: 기록 저장, 보냄/받음)뿐이다.
/// 계정 id도 보내지 않는다. 개인정보 처리방침 "2. 자동으로 모이는 정보"에 적혀 있다.
///
/// ## 개발 중 · 테스트
/// - 개발 모드(디버그)에서는 연결은 하되 **보내지 않는다.** (내 실수로 생긴 오류가 쌓이지 않게)
/// - 테스트 · 웹처럼 연결하지 않은 곳에서는 모든 함수가 아무것도 하지 않는다.
abstract final class AppMonitor {
  static bool _ready = false;

  /// 앱 시작 때 한 번. 연결에 실패해도 앱은 그대로 켜진다.
  static Future<void> init() async {
    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) return;
    try {
      await Firebase.initializeApp(options: options);
      const send = !kDebugMode;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(send);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(send);
    } catch (error) {
      debugPrint('오류 기록 · 사용 분석 연결 실패: $error');
      return;
    }
    _ready = true;

    // 화면을 그리다 난 오류 (빨간 화면 · 회색 화면)
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    // 그 밖에 아무도 처리하지 않은 오류 (비동기 작업 등)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// 처리했지만 실패한 작업을 남긴다. (앱은 계속 동작, "치명적이지 않은 오류"로 분류됨)
  /// [reason]: 어디서 났는지 짧게 (예: '기록 저장'). 기록 내용은 넣지 않는다.
  static void recordError(Object error, StackTrace? stack, {String? reason}) {
    if (!_ready || error is NetworkException) return;
    unawaited(FirebaseCrashlytics.instance.recordError(error, stack, reason: reason));
  }

  /// 화면 이동. [name]은 주소 모양(예: '/events/:eventId')이라 실제 번호 · 내용은 들어가지 않는다.
  static void logScreen(String name) {
    if (!_ready) return;
    unawaited(FirebaseAnalytics.instance.logScreenView(screenName: name));
    unawaited(FirebaseCrashlytics.instance.log('화면: $name')); // 오류가 나면 직전에 본 화면을 함께 볼 수 있다
  }

  /// 기능 사용. [name]은 영어 소문자 · 밑줄(분석 화면 규칙), [parameters]에는 종류 정도만 넣는다. (내용 금지)
  static void logEvent(String name, [Map<String, Object>? parameters]) {
    if (!_ready) return;
    unawaited(FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters));
  }
}

/// 사용 분석에 쓰는 기능 이름. 분석 화면에서 이 이름으로 보인다.
abstract final class AppEvents {
  static const String entrySave = 'entry_save'; // 기록 저장 {direction: sent/received, mode: new/edit}
  static const String eventSave = 'event_save'; // 행사 저장 {mode}
  static const String photoAdd = 'photo_add'; // 화환 사진 추가 {source: camera/gallery, count}
  static const String excelExport = 'excel_export'; // 엑셀 내보내기 {action: share/save}
  static const String sampleTour = 'sample_tour_start'; // 샘플 둘러보기 시작
  static const String themeMode = 'theme_mode_change'; // 화면 모드 {mode}
  static const String login = 'login'; // 로그인 {method: kakao/apple}
  static const String guestStart = 'guest_start'; // 로그인 없이 시작
}
