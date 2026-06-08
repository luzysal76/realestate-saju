// 이사 길일 / 부동산 계약 길일 계산기

import 'saju_calculator.dart';

class LuckyDayCalculator {
  // 손 없는 날 (음력 9, 10, 19, 20, 29, 30일) — 이사 최길일
  static const List<int> sonNoneDays = [9, 10, 19, 20, 29, 30];

  // 오행별 길일 지지
  static const Map<String, List<String>> oehaengLuckyJiji = {
    '목': ['인', '묘', '해', '자'],  // 목 생조
    '화': ['사', '오', '인', '묘'],  // 화 생조
    '토': ['진', '술', '축', '미'],  // 토 왕지
    '금': ['신', '유', '진', '술'],  // 금 생조
    '수': ['해', '자', '신', '유'],  // 수 생조
  };

  // 이사 흉일 지지
  static const List<String> movingBadJiji = ['충', '파', '해'];

  /// 특정 월의 이사 추천 날짜 계산
  static List<LuckyDayResult> getMonthlyLuckyDays({
    required int year,
    required int month,
    required String mainOehaeng,
  }) {
    final List<LuckyDayResult> results = [];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday == DateTime.sunday) continue; // 일요일 제외

      final dayGj = SajuCalculator.dayToGanJi(date);
      final dayJiji = dayGj['jiji']!;
      final dayOehaeng = dayGj['oehaeng_jiji']!;

      int score = 0;
      final List<String> reasons = [];
      String grade = '보통';

      // 손 없는 날 (양력 기준 근사치: 매월 9, 10, 19, 20, 29, 30일)
      if (sonNoneDays.contains(day)) {
        score += 40;
        reasons.add('손 없는 날 ✨');
      }

      // 오행 상생 여부
      final luckyJijiList = oehaengLuckyJiji[mainOehaeng] ?? [];
      if (luckyJijiList.contains(dayJiji)) {
        score += 30;
        reasons.add('$mainOehaeng 오행 길일');
      }

      // 오행 일치
      if (dayOehaeng == mainOehaeng) {
        score += 20;
        reasons.add('오행 일치 (${mainOehaeng}일)');
      }

      // 요일 보정
      if (date.weekday == DateTime.wednesday ||
          date.weekday == DateTime.thursday) {
        score += 5;
        reasons.add('길요일');
      }

      if (score >= 60) {
        grade = '대길 🔴';
      } else if (score >= 40) {
        grade = '길 🟡';
      } else if (score >= 20) {
        grade = '평길 🟢';
      }

      if (score >= 20) {
        results.add(LuckyDayResult(
          date: date,
          score: score,
          grade: grade,
          reasons: reasons,
          dayGanJi: '${dayGj['cheongan']}${dayGj['jiji']}',
          isSonNone: sonNoneDays.contains(day),
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// 계약 추천일 (이사보다 범위 넓게)
  static List<LuckyDayResult> getContractLuckyDays({
    required int year,
    required int month,
    required String mainOehaeng,
  }) {
    final List<LuckyDayResult> results = [];
    final daysInMonth = DateTime(year, month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayGj = SajuCalculator.dayToGanJi(date);
      final dayJiji = dayGj['jiji']!;

      int score = 0;
      final List<String> reasons = [];

      // 사주 길신일: 천을귀인 — 간략화
      if (['자', '축', '인', '묘'].contains(dayJiji)) {
        score += 25;
        reasons.add('귀인 일 ✨');
      }

      // 손 없는 날
      if (sonNoneDays.contains(day)) {
        score += 35;
        reasons.add('손 없는 날');
      }

      final luckyJijiList = oehaengLuckyJiji[mainOehaeng] ?? [];
      if (luckyJijiList.contains(dayJiji)) {
        score += 25;
        reasons.add('사주 길일');
      }

      if (score >= 30) {
        results.add(LuckyDayResult(
          date: date,
          score: score,
          grade: score >= 50 ? '최적 🔴' : '추천 🟡',
          reasons: reasons,
          dayGanJi: '${dayGj['cheongan']}${dayGj['jiji']}',
          isSonNone: sonNoneDays.contains(day),
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(10).toList();
  }
}

class LuckyDayResult {
  final DateTime date;
  final int score;
  final String grade;
  final List<String> reasons;
  final String dayGanJi;
  final bool isSonNone;

  const LuckyDayResult({
    required this.date,
    required this.score,
    required this.grade,
    required this.reasons,
    required this.dayGanJi,
    required this.isSonNone,
  });
}
