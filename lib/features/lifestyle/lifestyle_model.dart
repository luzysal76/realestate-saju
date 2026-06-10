// lifestyle_model.dart — 생활패턴 프로필 (SharedPreferences 저장)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LifestyleProfile {
  final String commuteDistrict; // 출근 자치구 or '재택/없음'
  final int budgetAk;           // 예산 (억원, 0=무관)
  final int childrenCount;      // 자녀수
  final bool hasPet;            // 반려동물
  final String preferredHomeType; // '무관','아파트','오피스텔','빌라','단독'

  const LifestyleProfile({
    this.commuteDistrict = '재택/없음',
    this.budgetAk = 0,
    this.childrenCount = 0,
    this.hasPet = false,
    this.preferredHomeType = '무관',
  });

  static const _key = 'lifestyle_profile_v1';

  bool get isConfigured =>
      commuteDistrict != '재택/없음' || budgetAk > 0 ||
      childrenCount > 0 || hasPet;

  LifestyleProfile copyWith({
    String? commuteDistrict,
    int? budgetAk,
    int? childrenCount,
    bool? hasPet,
    String? preferredHomeType,
  }) => LifestyleProfile(
    commuteDistrict: commuteDistrict ?? this.commuteDistrict,
    budgetAk: budgetAk ?? this.budgetAk,
    childrenCount: childrenCount ?? this.childrenCount,
    hasPet: hasPet ?? this.hasPet,
    preferredHomeType: preferredHomeType ?? this.preferredHomeType,
  );

  Map<String, dynamic> toJson() => {
    'commuteDistrict': commuteDistrict,
    'budgetAk': budgetAk,
    'childrenCount': childrenCount,
    'hasPet': hasPet,
    'preferredHomeType': preferredHomeType,
  };

  factory LifestyleProfile.fromJson(Map<String, dynamic> j) => LifestyleProfile(
    commuteDistrict: (j['commuteDistrict'] as String?) ?? '재택/없음',
    budgetAk: (j['budgetAk'] as int?) ?? 0,
    childrenCount: (j['childrenCount'] as int?) ?? 0,
    hasPet: (j['hasPet'] as bool?) ?? false,
    preferredHomeType: (j['preferredHomeType'] as String?) ?? '무관',
  );

  static Future<LifestyleProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const LifestyleProfile();
    try {
      return LifestyleProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const LifestyleProfile();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }

  // 집 유형 추천 점수 (오행 + 생활조건 기반)
  Map<String, int> homeTypeScores(String mainOe) {
    int apt = 50, officetel = 50, villa = 50, detached = 50;

    // 예산 반영
    if (budgetAk >= 10) { apt += 20; detached += 15; }
    else if (budgetAk >= 5) { apt += 10; villa += 10; }
    else if (budgetAk >= 2) { officetel += 15; villa += 10; }
    else if (budgetAk > 0) { officetel += 20; villa += 15; apt -= 10; }

    // 자녀수 반영
    if (childrenCount >= 2) { apt += 20; detached += 15; officetel -= 15; }
    else if (childrenCount == 1) { apt += 10; villa += 5; officetel -= 5; }

    // 반려동물 반영
    if (hasPet) { detached += 25; villa += 15; officetel -= 10; apt -= 5; }

    // 오행 반영
    switch (mainOe) {
      case '목': detached += 15; villa += 10; break;
      case '화': officetel += 15; apt += 10; break;
      case '토': apt += 20; break;
      case '금': apt += 15; officetel += 10; break;
      case '수': detached += 10; villa += 10; break;
    }

    return {
      '아파트': apt.clamp(10, 99),
      '오피스텔': officetel.clamp(10, 99),
      '빌라/다세대': villa.clamp(10, 99),
      '단독주택': detached.clamp(10, 99),
    };
  }

  // 예산 표시 텍스트
  String get budgetLabel {
    if (budgetAk == 0) return '무관';
    if (budgetAk >= 15) return '15억 이상';
    return '$budgetAk억 이내';
  }

  static const List<String> seoulDistricts25 = [
    '재택/없음', '강남구', '서초구', '송파구', '마포구', '용산구',
    '성동구', '영등포구', '중구', '종로구', '강동구', '광진구',
    '동작구', '서대문구', '성북구', '노원구', '강서구', '양천구',
    '도봉구', '은평구', '관악구', '구로구', '동대문구', '중랑구',
    '강북구', '압구정·청담',
  ];
}
