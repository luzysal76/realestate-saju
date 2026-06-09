import 'package:hive/hive.dart';

part 'fortune_log.g.dart';

/// 일일 운세 활동 로그 — Hive typeId: 1
@HiveType(typeId: 1)
class FortuneLog extends HiveObject {
  @HiveField(0)
  late DateTime date; // 날짜 (시간 제외, 00:00:00)

  @HiveField(1)
  late int dailyScore; // 오늘의 운세 점수 (0~99)

  @HiveField(2)
  late String dayGanJi; // 일진 간지 (예: "甲子")

  @HiveField(3)
  late String luckyDir; // 길한 방위 (예: "동")

  @HiveField(4)
  late String mainOehaeng; // 주 오행 (목/화/토/금/수)

  @HiveField(5)
  late String profileId; // SajuProfile.key.toString()

  @HiveField(6)
  int seWunScore; // 세운 투자지수 (없으면 0)

  FortuneLog({this.seWunScore = 0});
}
