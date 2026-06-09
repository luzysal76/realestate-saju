import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/fortune_log.dart';
import '../../shared/models/saju_profile.dart';

/// 일일 운세 로그 서비스 — Hive 기반
class FortuneLogService {
  static const _boxName = 'fortune_logs';

  static Box<FortuneLog> get _box => Hive.box<FortuneLog>(_boxName);

  /// 오늘 로그 저장 (프로필 + 날짜 기준 중복 방지)
  static Future<void> saveLog({
    required SajuProfile profile,
    required int dailyScore,
    required String dayGanJi,
    required String luckyDir,
    required String mainOehaeng,
    int seWunScore = 0,
  }) async {
    final pid = profile.key.toString();
    final now = DateTime.now();
    final key = '${pid}_${now.year}_${now.month}_${now.day}';

    if (_box.containsKey(key)) return; // 오늘 이미 기록됨

    await _box.put(
      key,
      FortuneLog()
        ..date        = DateTime(now.year, now.month, now.day)
        ..dailyScore  = dailyScore
        ..dayGanJi    = dayGanJi
        ..luckyDir    = luckyDir
        ..mainOehaeng = mainOehaeng
        ..profileId   = pid
        ..seWunScore  = seWunScore,
    );
  }

  /// 특정 프로필의 최근 N일 로그 (날짜 오름차순)
  static List<FortuneLog> getLogs(SajuProfile profile, {int days = 90}) {
    final pid = profile.key.toString();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _box.values
        .where((l) => l.profileId == pid && l.date.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 최근 30일 운세 평균 점수
  static double avgScore(SajuProfile profile) {
    final logs = getLogs(profile, days: 30);
    if (logs.isEmpty) return 0;
    return logs.map((l) => l.dailyScore).reduce((a, b) => a + b) / logs.length;
  }

  /// 최고 점수 로그
  static FortuneLog? bestLog(SajuProfile profile) {
    final logs = getLogs(profile, days: 90);
    if (logs.isEmpty) return null;
    return logs.reduce((a, b) => a.dailyScore > b.dailyScore ? a : b);
  }

  /// 현재 연속 방문 일수 (streak)
  static int streak(SajuProfile profile) {
    final logs = getLogs(profile, days: 365)
      ..sort((a, b) => b.date.compareTo(a.date));
    if (logs.isEmpty) return 0;
    int count = 0;
    DateTime check = DateTime.now();
    for (final log in logs) {
      final diff = DateTime(check.year, check.month, check.day)
          .difference(DateTime(log.date.year, log.date.month, log.date.day))
          .inDays;
      if (diff <= 1) {
        count++;
        check = log.date;
      } else {
        break;
      }
    }
    return count;
  }
}
