import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// 로컬 푸시 알림 서비스 (Android 전용 — Web은 자동 스킵)
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'fortune_daily';
  static const _channelName = '오늘의 운세 알림';
  static const _channelDesc = '매일 아침 부동산 운세를 알려드립니다';

  /// 앱 시작 시 초기화 (Web에서는 no-op)
  static Future<void> initialize() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // 위치 정보 없으면 UTC 사용
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// 매일 오전 8시 알림 예약
  static Future<void> scheduleDailyReminder() async {
    if (kIsWeb || !_initialized) return;
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.zonedSchedule(
      1001,
      '부동산 사주 ✨',
      '오늘의 운세를 확인하세요! 길한 방위와 집운을 알려드립니다.',
      _nextInstanceOf(8, 0),
      const NotificationDetails(android: android),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 알림 즉시 발송 (설정 확인용)
  static Future<void> showTestNotification() async {
    if (kIsWeb || !_initialized) return;
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      9999,
      '부동산 사주 알림 설정 완료 ✨',
      '매일 오전 8시에 운세를 알려드립니다!',
      const NotificationDetails(android: android),
    );
  }

  /// 모든 예약 알림 취소
  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  // ── 내부 헬퍼 ──────────────────────────────────────

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
