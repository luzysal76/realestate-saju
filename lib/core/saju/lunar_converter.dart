// 음양력 변환기 — Meeus 천문 알고리즘 기반
// 합삭(朔) 계산 + 중기(中氣) 유무로 윤달 판정 → 음력→양력 변환

import 'dart:math';

/// 음력 ↔ 양력 변환
class LunarConverter {

  // ─── JDE 유틸리티 ──────────────────────────────────────
  /// 그레고리력 → 율리우스 일수(JDE)
  static double _toJDE(int y, int m, int d) {
    int yr = y, mo = m;
    if (mo <= 2) { yr--; mo += 12; }
    final A = yr ~/ 100;
    final B = 2 - A + A ~/ 4;
    return (365.25 * (yr + 4716)).floor() +
           (30.6001 * (mo + 1)).floor() +
           d + B - 1524.5;
  }

  /// 율리우스 일수(JDE) → KST(UTC+9) 날짜
  static DateTime _toKST(double jde) {
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

  // ─── 태양 황경 ──────────────────────────────────────────
  /// 간략 태양 황경 (Meeus, 정밀도 ≈ 0.01°)
  static double _sunLon(double jde) {
    final d = jde - 2451545.0;
    final L = (280.460 + 0.9856474 * d) % 360;
    final Mrad = ((357.528 + 0.9856003 * d) % 360) * pi / 180;
    final lon = L + 1.915 * sin(Mrad) + 0.020 * sin(2 * Mrad);
    return ((lon % 360) + 360) % 360;
  }

  // ─── 합삭(新月) 계산 ────────────────────────────────────
  /// k번째 합삭 JDE (Meeus Ch.49, 정밀도 ≈ 15분)
  static double _newMoonJDE(double k) {
    final T  = k / 1236.85;
    final T2 = T * T;
    final T3 = T2 * T;
    double jde = 2451550.09766 + 29.530588861 * k
        + 0.00015437 * T2
        - 0.000000150 * T3;
    final M  = (2.5534  + 29.10535670  * k             ) * pi / 180;
    final Mp = (201.5643 + 385.81693528 * k + 0.0107582 * T2) * pi / 180;
    final F  = (160.7108 + 390.67050284 * k - 0.0016118 * T2) * pi / 180;
    jde += -0.40720 * sin(Mp)
        +  0.17241 * sin(M)
        +  0.01608 * sin(2 * Mp)
        +  0.01039 * sin(2 * F)
        +  0.00739 * sin(Mp - M)
        -  0.00514 * sin(Mp + M)
        +  0.00208 * sin(2 * M)
        -  0.00111 * sin(Mp - 2 * F)
        -  0.00057 * sin(Mp + 2 * F)
        +  0.00056 * sin(2 * Mp + M)
        -  0.00042 * sin(3 * Mp)
        +  0.00038 * sin(M - 2 * F);
    return jde;
  }

  /// jde 직전의 합삭 k 값
  static double _kBefore(double jde) {
    double k = ((jde - 2451550.09766) / 29.530588861).floorToDouble();
    while (_newMoonJDE(k + 1) <= jde) k += 1;
    while (_newMoonJDE(k) > jde) k -= 1;
    return k;
  }

  // ─── 동지(冬至) 계산 ────────────────────────────────────
  /// 특정 연도 동지(太陽黃經 270°) JDE — Newton 반복법
  static double _dongjiJDE(int year) {
    double jde = _toJDE(year, 12, 1);
    for (int i = 0; i < 50; i++) {
      final lon = _sunLon(jde);
      double diff = 270.0 - lon;
      while (diff >  180) diff -= 360;
      while (diff < -180) diff += 360;
      if (diff.abs() < 0.00001) break;
      jde += diff / 360.0;   // 1° ≈ 1일로 근사
    }
    return jde;
  }

  // ─── 중기(中氣) 포함 여부 ───────────────────────────────
  /// [nmJDE, nextNmJDE) 기간에 중기(30° 간격)가 있는지 확인
  static bool _hasMidTerm(double nmJDE, double nextNmJDE) {
    final ls = _sunLon(nmJDE);
    final le = _sunLon(nextNmJDE - 0.5 / 24.0); // 30분 전 기준
    // 360°→0° 순환 처리
    final leAdj = le < ls ? le + 360.0 : le;
    // ls 이상의 최소 30° 배수
    final next30 = ((ls / 30).ceil()) * 30.0;
    return next30 <= leAdj + 0.15; // 0.15° ≈ 약 3시간 허용 오차
  }

  // ─── 음력 달 시퀀스 구성 ────────────────────────────────
  /// 음력 [lunarYear] 의 달 구조를 구성
  /// 반환: 음력11월(전년)부터 시작, 최대 16달
  static List<_LunarMonth> _buildMonths(int lunarYear) {
    // 전년도 동지 → 음력 11월 시작 합삭
    final dong = _dongjiJDE(lunarYear - 1);
    final kDong = _kBefore(dong);

    // 16개의 합삭 JDE 계산
    final nms = List.generate(17, (i) => _newMoonJDE(kDong + i.toDouble()));

    int mNum = 11;
    bool hadLeap = false;
    final result = <_LunarMonth>[];

    for (int i = 0; i < 16; i++) {
      final has = _hasMidTerm(nms[i], nms[i + 1]);
      if (!has && !hadLeap) {
        // 윤달: 이전 달과 같은 번호
        final prev = result.isNotEmpty ? result.last.num : 10;
        result.add(_LunarMonth(prev, true, nms[i]));
        hadLeap = true;
        // mNum은 유지 (윤달은 번호 진행 없음)
      } else {
        result.add(_LunarMonth(mNum, false, nms[i]));
        mNum = mNum == 12 ? 1 : mNum + 1;
        // 새 주기 시작 시 윤달 플래그 리셋
        if (mNum == 11 && result.length > 12) hadLeap = false;
      }
    }
    return result;
  }

  // ─── 음력 → 양력 변환 (공개 API) ───────────────────────

  /// 음력 날짜 → 양력(그레고리력) 날짜 변환
  ///
  /// [lYear]  : 음력 연도 (예: 1990)
  /// [lMonth] : 음력 월 1~12
  /// [lDay]   : 음력 일 1~30
  /// [isLeap] : 윤달 여부 (기본 false)
  ///
  /// 유효하지 않은 날짜이면 null 반환
  static DateTime? lunarToSolar(
    int lYear,
    int lMonth,
    int lDay, {
    bool isLeap = false,
  }) {
    if (lYear < 1900 || lYear > 2100) return null;
    if (lMonth < 1 || lMonth > 12) return null;
    if (lDay < 1 || lDay > 30) return null;

    try {
      final months = _buildMonths(lYear);

      // 음력 1월 1일(설날) 인덱스 찾기
      final nyIdx = months.indexWhere((m) => m.num == 1 && !m.isLeap);
      if (nyIdx < 0) return null;

      // 설날 이후에서 목표 달 검색
      for (int i = nyIdx; i < months.length - 1; i++) {
        final m = months[i];
        if (m.num == lMonth && m.isLeap == isLeap) {
          // 해당 달의 일수 확인 (29 또는 30일)
          final monthLen = (months[i + 1].jde - m.jde).round();
          if (lDay > monthLen) return null; // 해당 달에 존재하지 않는 날

          final targetJDE = m.jde + (lDay - 1).toDouble();
          final result = _toKST(targetJDE);
          if (result.year < 1900 || result.year > 2100) return null;
          return result;
        }
        // 목표 달을 지나쳤으면 중단
        if (!m.isLeap && m.num > lMonth) break;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 양력 날짜 → 음력 날짜 변환
  /// 반환: [음력연도, 음력월, 음력일, 윤달여부(1/0)]
  static List<int>? solarToLunar(DateTime solar) {
    if (solar.year < 1900 || solar.year > 2100) return null;
    try {
      final solarJDE = _toJDE(solar.year, solar.month, solar.day);

      // 이 양력 날짜가 포함될 음력 해(lYear)를 탐색
      // 대략 solar.year ±1 범위
      for (int lYear in [solar.year, solar.year + 1]) {
        final months = _buildMonths(lYear);
        final nyIdx = months.indexWhere((m) => m.num == 1 && !m.isLeap);
        if (nyIdx < 0) continue;

        for (int i = nyIdx; i < months.length - 1; i++) {
          final m = months[i];
          final mStart = m.jde;
          final mEnd   = months[i + 1].jde;
          if (solarJDE >= mStart && solarJDE < mEnd) {
            final day = (solarJDE - mStart).round() + 1;
            return [lYear, m.num, day, m.isLeap ? 1 : 0];
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 해당 연도에 윤달이 있는지, 있다면 몇 월인지 반환
  /// 없으면 0 반환
  static int leapMonthOf(int lYear) {
    try {
      final months = _buildMonths(lYear);
      final leap = months.firstWhere(
        (m) => m.isLeap,
        orElse: () => _LunarMonth(0, false, 0),
      );
      return leap.isLeap ? leap.num : 0;
    } catch (_) { return 0; }
  }
}

/// 내부 달 데이터
class _LunarMonth {
  final int num;      // 음력 월 번호 (1~12)
  final bool isLeap;  // 윤달 여부
  final double jde;   // 합삭 JDE

  const _LunarMonth(this.num, this.isLeap, this.jde);
}
