import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 화면 고정(Lock Task Mode)을 제어한다. 학생용 화면에 있는 동안
/// 홈/최근 앱 버튼으로 다른 앱으로 빠져나가지 못하게 막는 용도다.
/// Android 외 플랫폼에서는 아무 것도 하지 않는다 — iOS는 사용자가 직접
/// 설정 > 손쉬운 사용 > 가이드 접근 모드를 켜야 동등한 효과를 낼 수 있다.
class KioskService {
  KioskService._();
  static final KioskService instance = KioskService._();

  static const _channel = MethodChannel('com.bookey.bookey/kiosk');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> enable() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('startLockTask');
    } on PlatformException {
      // 기기 정책상 화면 고정이 막혀 있을 수 있다 — 앱 자체의 비밀번호 확인
      // 잠금은 이 실패와 무관하게 계속 동작한다.
    }
  }

  Future<void> disable() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod('stopLockTask');
    } on PlatformException {
      // 이미 고정 해제되어 있는 경우 등은 무시한다.
    }
  }
}
