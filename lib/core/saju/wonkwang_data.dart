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

// ══════════════════════════════════════════════════════════
// 원광식 진태양시 보정 (眞太陽時)
// = 경도 보정(지방시) + 균시차(Equation of Time)
// ══════════════════════════════════════════════════════════
class TrueSolarTime {
  // ─── 한국 주요 도시 경도 (WGS84) ──────────────────────
  static const Map<String, double> cityLongitudes = {
    '서울':  126.978,
    '인천':  126.705,
    '수원':  127.019,
    '대전':  127.385,
    '청주':  127.489,
    '세종':  127.289,
    '광주':  126.852,
    '전주':  127.148,
    '목포':  126.388,
    '여수':  127.662,
    '대구':  128.601,
    '부산':  129.075,
    '울산':  129.312,
    '창원':  128.682,
    '강릉':  128.876,
    '춘천':  127.729,
    '원주':  127.920,
    '제주':  126.531,
    '서귀포': 126.560,
  };

  /// 도시명 목록 ('보정 안 함' 포함)
  static List<String> get cityNames =>
      ['보정 안 함', ...cityLongitudes.keys];

  /// 진태양시 보정값 계산 (분 단위, 음수 가능)
  ///
  /// = 경도 보정 + 균시차 (Spencer 1971, 정밀도 ±1분)
  ///
  /// 서울 예시:
  ///  · 경도보정: (126.978 - 135) × 4 = -32.1분
  ///  · 균시차: -14분(2월) ~ +16분(11월)
  ///  · 최종 범위: 약 -46분 ~ -16분
  static int correctionMinutes(DateTime date, double longitude) {
    // 1. 경도 보정 — KST 기준자오선 135°E 대비
    final longitudeOffset = (longitude - 135.0) * 4.0;

    // 2. 균시차 (Spencer, 1971)
    //    B = 2π × (N−1) / 365, N = 연중 일수
    final n = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final B = 2 * pi * (n - 1) / 365;
    final eot = 229.18 * (
        0.000075
        + 0.001868 * cos(B)  - 0.032077 * sin(B)
        - 0.014615 * cos(2 * B) - 0.040890 * sin(2 * B));

    return (longitudeOffset + eot).round();
  }

  /// 도시명 → 경도 (도시 미등록이면 null)
  static double? longitude(String cityName) => cityLongitudes[cityName];

  /// 보정 후 KST 시각 문자열 반환 — 예: "진태양시 02:28"
  static String correctedTimeLabel(
      int kstHour, int kstMinute, DateTime date, double longitude) {
    final correction = correctionMinutes(date, longitude);
    final total = ((kstHour * 60 + kstMinute + correction) % 1440 + 1440) % 1440;
    final h = total ~/ 60;
    final m = total % 60;
    final sign = correction >= 0 ? '+' : '';
    return '진태양시 ${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')} ($sign${correction}분)';
  }
}
