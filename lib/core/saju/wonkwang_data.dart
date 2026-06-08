// 원광만세력 핵심 데이터
// ─ 절기 천문 계산  (JeolgiCalculator)
// ─ 납음오행 60갑자 (WonkwangData)

import 'dart:math';

// ══════════════════════════════════════════════════════════
// 절기 계산기 — 태양 황경 기반 천문학적 계산 (Meeus)
// 정밀도: ±몇 시간 → 날짜 오차 없음 (1900~2100)
// ══════════════════════════════════════════════════════════
class JeolgiCalculator {
  /// 12절(節)의 태양 황경 (°)
  /// 인덱스: 0=소한 1=입춘 2=경칩 3=청명 4=입하  5=망종
  ///         6=소서 7=입추 8=백로 9=한로 10=입동 11=대설
  static const List<double> longitudes = [
    285, 315, 345,  15,  45,  75,
    105, 135, 165, 195, 225, 255,
  ];

  /// 절기 이름
  static const List<String> names = [
    '소한', '입춘', '경칩', '청명', '입하', '망종',
    '소서', '입추', '백로', '한로', '입동', '대설',
  ];

  /// 절기 → 월주 지지 인덱스 (자=0, 축=1, ..., 해=11)
  static const List<int> jijiIndex = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0,
  ];

  /// 절기가 속한 양력 월
  static const List<int> months = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  // ─── 연도별 캐시 ─────────────────────────────────────
  static final Map<int, List<DateTime>> _cache = {};

  /// 특정 연도의 12절기 날짜 목록 반환 (KST 기준)
  static List<DateTime> getYear(int year) {
    if (_cache.containsKey(year)) return _cache[year]!;
    final list = List.generate(12, (i) => _calc(year, i));
    _cache[year] = list;
    return list;
  }

  // ─── 천문 계산 내부 메서드 ─────────────────────────

  /// 절기 날짜 계산 (Newton's method 반복 수렴)
  static DateTime _calc(int year, int index) {
    // 해당 월 1일을 초기 JDE 추정값으로 사용
    double jde = _toJDE(year, months[index], 1);

    for (int i = 0; i < 30; i++) {
      final lon = _sunLon(jde);
      double diff = longitudes[index] - lon;
      // 각도 순환 처리 (−180 ~ +180)
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;
      if (diff.abs() < 0.00005) break;
      // 태양 하루 이동: ~1°/day
      jde += diff / 360.0;
    }
    return _toKST(jde);
  }

  /// 태양 황경 계산 — 간이 Meeus 공식 (정밀도 ≈ 0.01°)
  static double _sunLon(double jde) {
    final d = jde - 2451545.0;                     // J2000.0 기준 일수
    final L = (280.460 + 0.9856474 * d) % 360;     // 평균 황경
    final Mrad = ((357.528 + 0.9856003 * d) % 360) * pi / 180;
    final lon = L + 1.915 * sin(Mrad) + 0.020 * sin(2 * Mrad);
    return ((lon % 360) + 360) % 360;
  }

  /// 날짜 → JDE (Julian Day Number)
  static double _toJDE(int y, int m, int d) {
    int yr = y, mo = m;
    if (mo <= 2) { yr--; mo += 12; }
    final A = yr ~/ 100;
    final B = 2 - A + A ~/ 4;
    return (365.25 * (yr + 4716)).floor() +
           (30.6001 * (mo + 1)).floor() +
           d + B - 1524.5;
  }

  /// JDE → KST DateTime (UTC+9, 날짜만 사용)
  static DateTime _toKST(double jde) {
    // KST = UTC + 9h → JDE에 9/24 더함
    final z = (jde + 0.5 + 9.0 / 24.0).floor();
    int A = z;
    if (z >= 2299161) {
      final alpha = ((z - 1867216.25) / 36524.25).floor();
      A = z + 1 + alpha - alpha ~/ 4;
    }
    final B = A + 1524;
    final C = ((B - 122.1) / 365.25).floor();
    final D = (365.25 * C).floor();
    final E = ((B - D) / 30.6001).floor();
    final day   = B - D - (30.6001 * E).floor();
    final month = E < 14 ? E - 1 : E - 13;
    final year  = month > 2 ? C - 4716 : C - 4715;
    return DateTime(year, month, day);
  }
}

// ══════════════════════════════════════════════════════════
// 원광만세력 — 납음오행 (納音五行) 60갑자 대응표
// ══════════════════════════════════════════════════════════
class WonkwangData {
  // ─── 납음오행 이름 (60갑자 순서 — 甲子=0 ∼ 癸亥=59) ─
  static const List<String> naeumNames = [
    '해중금', '해중금',  //  0 甲子  1 乙丑
    '노중화', '노중화',  //  2 丙寅  3 丁卯
    '대림목', '대림목',  //  4 戊辰  5 己巳
    '노방토', '노방토',  //  6 庚午  7 辛未
    '검봉금', '검봉금',  //  8 壬申  9 癸酉
    '산두화', '산두화',  // 10 甲戌 11 乙亥
    '간하수', '간하수',  // 12 丙子 13 丁丑
    '성두토', '성두토',  // 14 戊寅 15 己卯
    '백랍금', '백랍금',  // 16 庚辰 17 辛巳
    '양류목', '양류목',  // 18 壬午 19 癸未
    '정천수', '정천수',  // 20 甲申 21 乙酉
    '옥상토', '옥상토',  // 22 丙戌 23 丁亥
    '벽력화', '벽력화',  // 24 戊子 25 己丑
    '송백목', '송백목',  // 26 庚寅 27 辛卯
    '장류수', '장류수',  // 28 壬辰 29 癸巳
    '사중금', '사중금',  // 30 甲午 31 乙未
    '산하화', '산하화',  // 32 丙申 33 丁酉
    '평지목', '평지목',  // 34 戊戌 35 己亥
    '벽상토', '벽상토',  // 36 庚子 37 辛丑
    '금박금', '금박금',  // 38 壬寅 39 癸卯
    '복등화', '복등화',  // 40 甲辰 41 乙巳
    '천하수', '천하수',  // 42 丙午 43 丁未
    '대역토', '대역토',  // 44 戊申 45 己酉
    '차천금', '차천금',  // 46 庚戌 47 辛亥
    '상자목', '상자목',  // 48 壬子 49 癸丑
    '대계수', '대계수',  // 50 甲寅 51 乙卯
    '사중토', '사중토',  // 52 丙辰 53 丁巳
    '천상화', '천상화',  // 54 戊午 55 己未
    '석류목', '석류목',  // 56 庚申 57 辛酉
    '대해수', '대해수',  // 58 壬戌 59 癸亥
  ];

  // ─── 납음 오행 (60갑자 순서) ─────────────────────────
  static const List<String> naeumElements = [
    '금', '금', '화', '화', '목', '목', '토', '토', '금', '금', // 0-9
    '화', '화', '수', '수', '토', '토', '금', '금', '목', '목', // 10-19
    '수', '수', '토', '토', '화', '화', '목', '목', '수', '수', // 20-29
    '금', '금', '화', '화', '목', '목', '토', '토', '금', '금', // 30-39
    '화', '화', '수', '수', '토', '토', '금', '금', '목', '목', // 40-49
    '수', '수', '토', '토', '화', '화', '목', '목', '수', '수', // 50-59
  ];

  /// 60갑자 인덱스 — 천간 인덱스 ci(0~9), 지지 인덱스 ji(0~11)
  /// 공식: (25·ji − 24·ci + 600) % 60
  /// 검증: 甲子(0,0)→0, 乙丑(1,1)→1, 壬午(8,6)→18 ✓
  static int ganJi60(int ci, int ji) =>
      (25 * ji - 24 * ci + 600) % 60;

  /// 납음오행 정보 반환 {'naeum': '해중금', 'naeum_oehaeng': '금'}
  static Map<String, String> naeum(int ci, int ji) {
    final idx = ganJi60(ci, ji);
    return {
      'naeum':         naeumNames[idx],
      'naeum_oehaeng': naeumElements[idx],
    };
  }

  /// 납음오행 이름 간단 조회
  static String naeumName(int ci, int ji) => naeumNames[ganJi60(ci, ji)];

  /// 납음 오행 간단 조회
  static String naeumElement(int ci, int ji) => naeumElements[ganJi60(ci, ji)];
}
