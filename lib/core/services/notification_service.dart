// notification_service.dart — 로컬 푸시 알림 서비스 (Android / Web 스킵)
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../saju/saju_calculator.dart';
import '../saju/lucky_day.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── 채널 ────────────────────────────────────────────
  static const _channelId   = 'fortune_daily';
  static const _channelName = '오늘의 운세 알림';
  static const _channelDesc = '매일 아침 부동산 운세를 알려드립니다';

  static const _moveChannelId   = 'move_alert';
  static const _moveChannelName = '이사·계약 예정 알림';
  static const _moveChannelDesc = '이사·계약 예정일 전날 알려드립니다';

  // ── SharedPreferences 키 ────────────────────────────
  static const _keyEnabled      = 'notif_enabled';
  static const _keyMoveDate     = 'notif_move_date';   // ISO yyyy-MM-dd or ''
  static const _keyContractDate = 'notif_contract_date';

  // ── 알림 ID ─────────────────────────────────────────
  static const idDaily    = 1001;
  static const idTest     = 9999;
  static const idMove     = 2001;
  static const idContract = 2002;

  // ════════════════════════════════════════════════════
  //  초기화
  // ════════════════════════════════════════════════════

  static Future<void> initialize() async {
    if (kIsWeb) return;
    tz_data.initializeTimeZones();
    try { tz.setLocalLocation(tz.getLocation('Asia/Seoul')); } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _initialized = true;
  }

  // ════════════════════════════════════════════════════
  //  알림 활성화 상태 (SharedPreferences)
  // ════════════════════════════════════════════════════

  static Future<bool> isEnabled() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool v) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, v);
  }

  // ════════════════════════════════════════════════════
  //  예정일 저장 (이사 / 계약)
  // ════════════════════════════════════════════════════

  static Future<DateTime?> getMoveDate() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyMoveDate) ?? '';
    return s.isEmpty ? null : DateTime.tryParse(s);
  }

  static Future<void> saveMoveDate(DateTime? d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMoveDate, d == null ? '' : d.toIso8601String());
  }

  static Future<DateTime?> getContractDate() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_keyContractDate) ?? '';
    return s.isEmpty ? null : DateTime.tryParse(s);
  }

  static Future<void> saveContractDate(DateTime? d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContractDate, d == null ? '' : d.toIso8601String());
  }

  // ════════════════════════════════════════════════════
  //  일일 운세 알림 — 개인화
  // ════════════════════════════════════════════════════

  /// 대시보드 진입 시 호출: 내일 일진 기반 개인화 알림 갱신
  static Future<void> schedulePersonalizedReminder({
    required SajuResult result,
    required String name,
  }) async {
    if (kIsWeb || !_initialized) return;
    if (!await isEnabled()) return;

    // 내일 일진 계산
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final gj   = SajuCalculator.dayToGanJi(tomorrow);
    final cg   = gj['cheongan'] ?? '';
    final ji   = gj['jiji'] ?? '';
    final ss   = SajuCalculator.calcSipSeong(result.ilgan, cg);
    final isGm = result.shinSalResult.gongmang.contains(ji);

    // 이달 가장 가까운 손없는 날
    final now     = DateTime.now();
    final luckyDs = LuckyDayCalculator.getMonthlyLuckyDays(
      year: now.year, month: now.month, mainOehaeng: result.mainOehaeng);
    final nextLucky = luckyDs.firstWhere(
      (d) => d.date.isAfter(tomorrow),
      orElse: () => luckyDs.isNotEmpty ? luckyDs.first : LuckyDayResult(
        date: tomorrow, score: 0, grade: '', reasons: [],
        dayGanJi: '', isSonNone: false),
    );

    String body;
    if (isGm) {
      body = '$name님, 내일($cg$ji)은 공망일 — 큰 부동산 결정은 보류하세요 🕳';
    } else {
      const goodSs = ['정재', '정관', '식신', '정인'];
      final isGood = goodSs.contains(ss.name);
      final luckyInfo = nextLucky.isSonNone
          ? '  ☀️ ${nextLucky.date.month}/${nextLucky.date.day} 손없는 날!'
          : '';
      body = isGood
          ? '$name님, 내일은 ${ss.name}일 — 부동산 활동 좋은 날 ✨ 길방: ${result.luckyDirection}$luckyInfo'
          : '$name님, 내일($cg$ji)은 ${ss.name}일. 신중하게 접근하세요 🌧$luckyInfo';
    }

    // 기존 일일 알림만 취소 후 재예약
    await _plugin.cancel(idDaily);
    await _plugin.zonedSchedule(
      idDaily,
      '부동산 사주 — $name님의 내일 운세',
      body,
      _nextInstanceOf(8, 0),
      NotificationDetails(android: _androidDetails(_channelId, _channelName, _channelDesc)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 기본 일일 알림 (프로필 없이 설정 화면에서 켤 때)
  static Future<void> scheduleDailyReminder() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(idDaily);
    await _plugin.zonedSchedule(
      idDaily,
      '부동산 사주 ✨',
      '오늘의 운세를 확인하세요! 길한 방위와 집운을 알려드립니다.',
      _nextInstanceOf(8, 0),
      NotificationDetails(android: _androidDetails(_channelId, _channelName, _channelDesc)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ════════════════════════════════════════════════════
  //  이사 / 계약 예정일 D-1 알림
  // ════════════════════════════════════════════════════

  static Future<void> scheduleMoveAlert({
    required DateTime targetDate,
    required String label,    // '이사' / '계약'
    required String name,
    required int id,          // idMove or idContract
  }) async {
    if (kIsWeb || !_initialized) return;
    final alertDate = targetDate.subtract(const Duration(days: 1));
    if (alertDate.isBefore(DateTime.now())) return;

    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      '내일 $label 예정일입니다 ⏰',
      '$name님, 내일(${targetDate.month}월 ${targetDate.day}일)이 $label 예정일입니다. 준비 잘 되셨나요?',
      tz.TZDateTime(tz.local,
        alertDate.year, alertDate.month, alertDate.day, 9, 0),
      NotificationDetails(android: _androidDetails(
        _moveChannelId, _moveChannelName, _moveChannelDesc,
        important: true)),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelMoveAlert(int id) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(id);
  }

  // ════════════════════════════════════════════════════
  //  테스트 / 취소
  // ════════════════════════════════════════════════════

  static Future<void> showTestNotification() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.show(
      idTest,
      '부동산 사주 알림 설정 완료 ✨',
      '매일 오전 8시에 맞춤 운세를 보내드립니다!',
      NotificationDetails(android: _androidDetails(_channelId, _channelName, _channelDesc)),
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancelAll();
  }

  // ════════════════════════════════════════════════════
  //  내부 헬퍼
  // ════════════════════════════════════════════════════

  static AndroidNotificationDetails _androidDetails(
    String id, String name, String desc, {bool important = false}) {
    return AndroidNotificationDetails(
      id, name,
      channelDescription: desc,
      importance: important ? Importance.max : Importance.high,
      priority: important ? Priority.max : Priority.high,
      icon: '@mipmap/ic_launcher',
    );
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}
