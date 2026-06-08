// 사주 계산 엔진 v2 — 천간/지지/오행/십성/대운/세운/신살 완전 구현

import 'shinsal.dart';

class SajuCalculator {
  // ─── 기본 상수 ───────────────────────────────────────
  static const List<String> cheongan = [
    '갑', '을', '병', '정', '무', '기', '경', '신', '임', '계'
  ];
  static const List<String> jiji = [
    '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해'
  ];

  // 음양 (0=양, 1=음)
  static const Map<String, int> cheonganYinYang = {
    '갑': 0, '을': 1, '병': 0, '정': 1, '무': 0,
    '기': 1, '경': 0, '신': 1, '임': 0, '계': 1,
  };
  static const Map<String, int> jijiYinYang = {
    '자': 1, '축': 1, '인': 0, '묘': 1, '진': 0, '사': 0,
    '오': 0, '미': 1, '신': 0, '유': 1, '술': 0, '해': 1,
  };

  // 오행
  static const Map<String, String> cheonganOehaeng = {
    '갑': '목', '을': '목', '병': '화', '정': '화', '무': '토',
    '기': '토', '경': '금', '신': '금', '임': '수', '계': '수',
  };
  static const Map<String, String> jijiOehaeng = {
    '자': '수', '축': '토', '인': '목', '묘': '목', '진': '토', '사': '화',
    '오': '화', '미': '토', '신': '금', '유': '금', '술': '토', '해': '수',
  };

  // 오행 상생 (내가 생하는 오행)
  static const Map<String, String> saeng = {
    '목': '화', '화': '토', '토': '금', '금': '수', '수': '목',
  };
  // 오행 상극 (내가 극하는 오행)
  static const Map<String, String> geuk = {
    '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
  };
  // 오행 역생 (나를 생하는 오행)
  static const Map<String, String> saengMy = {
    '목': '수', '화': '목', '토': '화', '금': '토', '수': '금',
  };
  // 오행 역극 (나를 극하는 오행)
  static const Map<String, String> geukMy = {
    '목': '금', '화': '수', '토': '목', '금': '화', '수': '토',
  };

  // 지지 합충 (부동산 운세 해석용)
  static const Map<String, List<String>> jijiHap = {
    '자': ['축'], '축': ['자', '인'], '인': ['축', '해'], '묘': ['술'],
    '진': ['유'], '사': ['신'], '오': ['미'], '미': ['오', '오'],
    '신': ['사'], '유': ['진'], '술': ['묘'], '해': ['인'],
  };
  static const Map<String, String> jijiChung = {
    '자': '오', '축': '미', '인': '신', '묘': '유', '진': '술', '사': '해',
    '오': '자', '미': '축', '신': '인', '유': '묘', '술': '진', '해': '사',
  };

  // 부동산 방위/특성
  static const Map<String, String> oehaengDirection = {
    '목': '동쪽 (東)', '화': '남쪽 (南)', '토': '중앙 (中)',
    '금': '서쪽 (西)', '수': '북쪽 (北)',
  };
  static const Map<String, Map<String, String>> oehaengProperty = {
    '목': {
      'keyword': '성장·발전', 'type': '신축·재개발 지역',
      'timing': '봄 (3~5월)', 'color': '초록·파랑',
      'desc': '성장 가능성이 높은 신흥 개발지, 숲·공원 인근이 길합니다.',
    },
    '화': {
      'keyword': '열정·번영', 'type': '상업·번화가 인근',
      'timing': '여름 (6~8월)', 'color': '빨강·주황',
      'desc': '유동인구 많은 상업지역, 역세권 고층 아파트가 맞습니다.',
    },
    '토': {
      'keyword': '안정·지속', 'type': '중심지·구도심',
      'timing': '환절기 (3, 6, 9, 12월)', 'color': '노랑·황토',
      'desc': '안정적인 구도심 아파트나 토지 투자가 가장 유리합니다.',
    },
    '금': {
      'keyword': '결실·수확', 'type': '프리미엄·고급 주거',
      'timing': '가을 (9~11월)', 'color': '흰색·은색',
      'desc': '고급 아파트·빌라, 서쪽 방향 집이 사주와 잘 맞습니다.',
    },
    '수': {
      'keyword': '유연·지혜', 'type': '수변·강변 주거지',
      'timing': '겨울 (12~2월)', 'color': '파랑·검정',
      'desc': '한강변·수변 아파트, 북쪽 지역 투자가 유리합니다.',
    },
  };

  // ─── 간지 계산 ───────────────────────────────────────

  static Map<String, String> yearToGanJi(int year) {
    final ci = (year - 4) % 10;
    final ji = (year - 4) % 12;
    return _ganjiMap(ci, ji);
  }

  // ─── 절기 기준일 (양력 평균치 ±1일) ────────────────
  // [월, 절기일, 해당 지지 인덱스]
  static const List<List<int>> _jeolgiDates = [
    [1,  6,  1],  // 소한(小寒)  → 축월(丑月)
    [2,  4,  2],  // 입춘(立春)  → 인월(寅月)
    [3,  6,  3],  // 경칩(驚蟄)  → 묘월(卯月)
    [4,  5,  4],  // 청명(淸明)  → 진월(辰月)
    [5,  6,  5],  // 입하(立夏)  → 사월(巳月)
    [6,  6,  6],  // 망종(芒種)  → 오월(午月)
    [7,  7,  7],  // 소서(小暑)  → 미월(未月)
    [8,  7,  8],  // 입추(立秋)  → 신월(申月)
    [9,  8,  9],  // 백로(白露)  → 유월(酉月)
    [10, 8,  10], // 한로(寒露)  → 술월(戌月)
    [11, 7,  11], // 입동(立冬)  → 해월(亥月)
    [12, 7,  0],  // 대설(大雪)  → 자월(子月)
  ];

  /// 절기 기반 정확한 월주 계산
  /// [day] 를 전달하면 절기 전후를 구분합니다 (기본값 15 = 월 중순)
  static Map<String, String> monthToGanJi(int year, int month, [int day = 15]) {
    // 절기 기준 지지 결정: 위 배열을 앞에서부터 순회하며 조건 충족 시 갱신
    // 초기값 0 (자월) = 1월 소한 이전, 12월 대설 이전의 경우
    int jijiIdx = 0;
    for (final jd in _jeolgiDates) {
      final jMonth = jd[0], jDay = jd[1], newJi = jd[2];
      if (month > jMonth || (month == jMonth && day >= jDay)) {
        jijiIdx = newJi;
      }
    }

    // 오호둔법(五虎遁法): 년간 기준 인월(寅月) 천간 결정
    final yearCgIdx = (year - 4) % 10;
    // 갑기년→병인, 을경년→무인, 병신년→경인, 정임년→임인, 무계년→갑인
    const inMonthBaseCg = [2, 4, 6, 8, 0]; // 병, 무, 경, 임, 갑
    final inBase = inMonthBaseCg[yearCgIdx % 5];

    // 인(2)→묘(3)→...→해(11)→자(0)→축(1) 순서로 오프셋
    const jijiOrder = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1];
    final offset = jijiOrder.indexOf(jijiIdx);
    final cgIdx = (inBase + offset) % 10;

    return _ganjiMap(cgIdx, jijiIdx);
  }

  static Map<String, String> dayToGanJi(DateTime date) {
    final base = DateTime(2000, 1, 1);
    final diff = date.difference(base).inDays;
    final ci = diff % 10;
    final ji = (diff + 4) % 12; // 2000-01-01 = 갑진
    return _ganjiMap(ci, ji);
  }

  static Map<String, String> hourToGanJi(int hour, String dayCg) {
    final ji = (hour + 1) ~/ 2 % 12;
    final dayCi = cheongan.indexOf(dayCg);
    final base = (dayCi % 5) * 2;
    final ci = (base + ji) % 10;
    return _ganjiMap(ci, ji);
  }

  static Map<String, String> _ganjiMap(int ci, int ji) {
    final cg = cheongan[ci];
    final jj = jiji[ji];
    return {
      'cheongan': cg,
      'jiji': jj,
      'oehaeng_cheongan': cheonganOehaeng[cg]!,
      'oehaeng_jiji': jijiOehaeng[jj]!,
      'yinyang_cheongan': cheonganYinYang[cg].toString(),
      'yinyang_jiji': jijiYinYang[jj].toString(),
    };
  }

  // ─── 십성 계산 ───────────────────────────────────────

  /// 일간(日干) 기준으로 대상 천간의 십성 계산
  static SipSeong calcSipSeong(String ilgan, String target) {
    final ilOe = cheonganOehaeng[ilgan]!;
    final tgOe = cheonganOehaeng[target]!;
    final ilYy = cheonganYinYang[ilgan]!;
    final tgYy = cheonganYinYang[target]!;
    final sameYy = ilYy == tgYy;

    String name;
    if (tgOe == ilOe) {
      name = sameYy ? '비견' : '겁재';
    } else if (tgOe == saeng[ilOe]) {
      name = sameYy ? '식신' : '상관';
    } else if (tgOe == geuk[ilOe]) {
      name = sameYy ? '편재' : '정재';
    } else if (tgOe == geukMy[ilOe]) {
      name = sameYy ? '편관' : '정관';
    } else {
      // saengMy
      name = sameYy ? '편인' : '정인';
    }
    return SipSeong(name: name, target: target, oehaeng: tgOe);
  }

  /// 사주 전체 십성 분석
  static SipSeongAnalysis analyzeSipSeong(String ilgan, List<String> allCheongan) {
    final Map<String, int> count = {
      '비견': 0, '겁재': 0, '식신': 0, '상관': 0, '편재': 0,
      '정재': 0, '편관': 0, '정관': 0, '편인': 0, '정인': 0,
    };
    final List<SipSeong> list = [];

    for (final cg in allCheongan) {
      if (cg == ilgan) continue;
      final ss = calcSipSeong(ilgan, cg);
      list.add(ss);
      count[ss.name] = (count[ss.name] ?? 0) + 1;
    }

    // 격국(格局) 판별 - 가장 많은 십성
    final dominant = count.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    return SipSeongAnalysis(
      list: list,
      count: count,
      dominant: dominant,
      propertyTips: _getSipSeongPropertyTips(dominant),
      personalityDesc: _getSipSeongPersonality(dominant),
      formatDesc: _getSipSeongFormat(dominant),
    );
  }

  static String _getSipSeongPropertyTips(String ss) {
    const tips = {
      '비견': '독립 투자에 강함 — 공동 명의보다 단독 매수 유리. 자수성가형 부동산 전략.',
      '겁재': '경쟁 강함 — 경매·공매 입찰에서 강점. 단, 충동 매수 주의.',
      '식신': '안정 지향 — 실거주 위주 투자 적합. 수익형 부동산(상가·월세)도 길.',
      '상관': '창의적 접근 — 리모델링·인테리어 후 매도 전략 유리. 틈새시장 포착력 강.',
      '편재': '다재다능 — 여러 물건 동시 검토, 갭투자·레버리지 활용에 능함.',
      '정재': '실속형 — 착실한 저축·전세 레버리지 전략. 장기 보유 후 안전 매도.',
      '편관': '도전적 — 개발 호재 지역 선점, 재건축·재개발 초기 진입에 강점.',
      '정관': '원칙형 — 입지 좋은 안전 자산 선호. 브랜드 아파트 장기 보유가 최적.',
      '편인': '직관형 — 남들이 모르는 숨은 지역 조기 발굴에 탁월한 직감.',
      '정인': '학습형 — 꼼꼼한 조사 후 결정. 입지 분석·공부 후 안전 매수 전략.',
    };
    return tips[ss] ?? '종합적 판단으로 신중하게 투자하세요.';
  }

  static String _getSipSeongPersonality(String ss) {
    const desc = {
      '비견': '독립심이 강하고 자신의 판단을 믿는 타입',
      '겁재': '경쟁을 즐기며 추진력이 강한 타입',
      '식신': '안정을 중시하며 꾸준히 일하는 타입',
      '상관': '창의적이고 표현력이 풍부한 타입',
      '편재': '사교적이고 다방면에 관심이 많은 타입',
      '정재': '성실하고 실용적인 것을 중시하는 타입',
      '편관': '도전적이고 강한 의지력을 가진 타입',
      '정관': '원칙을 중시하고 책임감이 강한 타입',
      '편인': '직관력이 뛰어나고 독창적인 타입',
      '정인': '배우기를 좋아하고 사려 깊은 타입',
    };
    return desc[ss] ?? '';
  }

  static String _getSipSeongFormat(String ss) {
    const fmt = {
      '비견': '비겁格 — 개인 역량 중심',
      '겁재': '비겁格 — 경쟁·도전 중심',
      '식신': '식상格 — 식신格',
      '상관': '식상格 — 상관格',
      '편재': '재성格 — 편재格',
      '정재': '재성格 — 정재格',
      '편관': '관성格 — 편관格(칠살格)',
      '정관': '관성格 — 정관格',
      '편인': '인성格 — 편인格',
      '정인': '인성格 — 정인格(인수格)',
    };
    return fmt[ss] ?? '';
  }

  // ─── 대운 계산 ───────────────────────────────────────

  static List<DaeWun> calcDaeWun({
    required DateTime birthDate,
    required String gender,
    required Map<String, String> yearGj,
    required Map<String, String> monthGj,
    required String ilgan,
  }) {
    final yearCi = cheongan.indexOf(yearGj['cheongan']!);
    final isYang = yearCi % 2 == 0;
    final forward = (isYang && gender == '남') || (!isYang && gender == '여');

    int moCi = cheongan.indexOf(monthGj['cheongan']!);
    int moJi = jiji.indexOf(monthGj['jiji']!);
    final startAge = _calcDaeWunStartAge(birthDate, forward);
    final birthYear = birthDate.year;

    final List<DaeWun> list = [];
    for (int i = 0; i < 8; i++) {
      if (forward) {
        moCi = (moCi + 1) % 10;
        moJi = (moJi + 1) % 12;
      } else {
        moCi = (moCi - 1 + 10) % 10;
        moJi = (moJi - 1 + 12) % 12;
      }
      final cg = cheongan[moCi];
      final ji = jiji[moJi];
      final oe = cheonganOehaeng[cg]!;
      final age = startAge + i * 10;
      final ss = calcSipSeong(ilgan, cg);

      list.add(DaeWun(
        age: age,
        endAge: age + 9,
        cheongan: cg,
        jiji: ji,
        oehaeng: oe,
        year: birthYear + age,
        sipSeong: ss,
        propertyTip: _getDaeWunTip(ss.name, oe),
        investmentScore: _getDaeWunScore(ss.name),
      ));
    }
    return list;
  }

  static int _calcDaeWunStartAge(DateTime birth, bool forward) {
    // 실제는 절입일 기준이나 근사치 사용
    return 3 + (birth.month % 6);
  }

  static String _getDaeWunTip(String ss, String oe) {
    const tips = {
      '비견': '독립 투자 강세 — 단독 매수·경매 직접 참여 적기',
      '겁재': '경쟁 심화 — 신중한 입찰, 충동 매수 절대 자제',
      '식신': '수익 창출 운 — 월세·임대 수익형 부동산 투자 길',
      '상관': '창의 전략 — 리모델링 후 매도, 비주류 지역 선점',
      '편재': '재물 확장 운 — 갭투자·레버리지 활용 적극 고려',
      '정재': '안정 재물 운 — 실거주 매수, 장기 보유 전략 최적',
      '편관': '변화·도전 운 — 재건축 초기 지역 선점, 리스크 감수',
      '정관': '명예·안정 운 — 브랜드 대단지 아파트 장기 보유 권장',
      '편인': '직관 예지 운 — 숨은 지역 조기 발굴, 소수의견에 귀기울이기',
      '정인': '학습·준비 운 — 충분한 공부 후 안전한 매수 결정',
    };
    return tips[ss] ?? '종합 판단으로 투자하세요.';
  }

  static int _getDaeWunScore(String ss) {
    const scores = {
      '편재': 85, '정재': 80, '식신': 78, '편인': 72, '정인': 70,
      '비견': 65, '겁재': 55, '정관': 75, '편관': 60, '상관': 62,
    };
    return scores[ss] ?? 60;
  }

  // ─── 세운 계산 ───────────────────────────────────────

  static List<SeWun> calcSeWun({
    required int startYear,
    required int years,
    required String ilgan,
    required String ilji,
  }) {
    final List<SeWun> list = [];
    for (int i = 0; i < years; i++) {
      final year = startYear + i;
      final gj = yearToGanJi(year);
      final cg = gj['cheongan']!;
      final ji = gj['jiji']!;
      final ss = calcSipSeong(ilgan, cg);
      final jijRel = _calcJijiRelation(ilji, ji);
      final score = _calcSeWunScore(ss.name, jijRel);

      list.add(SeWun(
        year: year,
        cheongan: cg,
        jiji: ji,
        oehaeng: cheonganOehaeng[cg]!,
        sipSeong: ss,
        jijiRelation: jijRel,
        investmentScore: score,
        propertyAdvice: _getSeWunAdvice(ss.name, jijRel, score),
        buyOrSell: _getBuySellAction(ss.name, score),
      ));
    }
    return list;
  }

  static String _calcJijiRelation(String ilji, String yearJi) {
    if (jijiChung[ilji] == yearJi) return '충(沖)';
    if (jijiHap[ilji]?.contains(yearJi) == true) return '합(合)';
    if (jijiOehaeng[ilji] == jijiOehaeng[yearJi]) return '동(同)';
    if (saeng[jijiOehaeng[ilji]!] == jijiOehaeng[yearJi]) return '생(生)';
    if (geuk[jijiOehaeng[ilji]!] == jijiOehaeng[yearJi]) return '극(剋)';
    return '평(平)';
  }

  static int _calcSeWunScore(String ss, String jijiRel) {
    const ssScore = {
      '편재': 82, '정재': 80, '식신': 75, '정인': 72, '편인': 68,
      '비견': 63, '정관': 78, '편관': 55, '겁재': 52, '상관': 60,
    };
    int base = ssScore[ss] ?? 60;
    // 지지 관계 보정
    if (jijiRel == '합(合)') base += 10;
    if (jijiRel == '충(沖)') base -= 15;
    if (jijiRel == '생(生)') base += 8;
    if (jijiRel == '극(剋)') base -= 8;
    return base.clamp(15, 98);
  }

  static String _getSeWunAdvice(String ss, String jijiRel, int score) {
    final tip = _getDaeWunTip(ss, '');
    String jijiNote = '';
    if (jijiRel == '합(合)') jijiNote = ' ✨ 지지합으로 운세 강화.';
    if (jijiRel == '충(沖)') jijiNote = ' ⚠️ 지지충으로 변동 주의.';
    if (jijiRel == '극(剋)') jijiNote = ' 🔻 지지극으로 압박감 있음.';
    return '$tip$jijiNote';
  }

  static String _getBuySellAction(String ss, int score) {
    if (score >= 75) {
      return ['편재', '식신'].contains(ss) ? '매수·투자 적극 추천' : '매수 또는 보유 유지';
    } else if (score >= 55) {
      return '현상 유지 · 신중 검토';
    } else {
      return ['편관', '겁재'].contains(ss) ? '매도·현금화 고려' : '큰 결정 자제';
    }
  }

  // ─── 전체 계산 ───────────────────────────────────────

  static SajuResult calculate({
    required DateTime birthDate,
    required int birthHour,
    required String gender,
  }) {
    final yearGj = yearToGanJi(birthDate.year);
    final monthGj = monthToGanJi(birthDate.year, birthDate.month, birthDate.day);
    final dayGj = dayToGanJi(birthDate);
    final hourGj = hourToGanJi(birthHour, dayGj['cheongan']!);

    final ilgan = dayGj['cheongan']!;
    final ilji = dayGj['jiji']!;

    // 오행 점수
    final Map<String, int> oehaengScore = {
      '목': 0, '화': 0, '토': 0, '금': 0, '수': 0
    };
    for (final gj in [yearGj, monthGj, dayGj, hourGj]) {
      final cgOe = gj['oehaeng_cheongan']!;
      final jiOe = gj['oehaeng_jiji']!;
      oehaengScore[cgOe] = (oehaengScore[cgOe] ?? 0) + 1;
      oehaengScore[jiOe] = (oehaengScore[jiOe] ?? 0) + 1;
    }

    final mainOehaeng = oehaengScore.entries
        .reduce((a, b) => a.value >= b.value ? a : b).key;
    final weakOehaeng = oehaengScore.entries
        .reduce((a, b) => a.value <= b.value ? a : b).key;

    // 십성 분석
    final allCg = [
      yearGj['cheongan']!, monthGj['cheongan']!,
      hourGj['cheongan']!, // 일간 제외하고 나머지 3개
    ];
    final sipSeongAnalysis = analyzeSipSeong(ilgan, allCg);

    // 대운
    final daeWunList = calcDaeWun(
      birthDate: birthDate,
      gender: gender,
      yearGj: yearGj,
      monthGj: monthGj,
      ilgan: ilgan,
    );

    // 세운 (현재부터 10년)
    final currentYear = DateTime.now().year;
    final seWunList = calcSeWun(
      startYear: currentYear,
      years: 10,
      ilgan: ilgan,
      ilji: ilji,
    );

    // 신살 분석
    final shinSalResult = ShinSalCalculator.calculate(
      yearJiji: yearGj['jiji']!,
      dayCheongan: ilgan,
      dayJiji: ilji,
      currentYear: currentYear,
    );

    return SajuResult(
      yearGj: yearGj, monthGj: monthGj, dayGj: dayGj, hourGj: hourGj,
      ilgan: ilgan, ilji: ilji,
      oehaengScore: oehaengScore,
      mainOehaeng: mainOehaeng,
      weakOehaeng: weakOehaeng,
      propertyInfo: oehaengProperty[mainOehaeng]!,
      luckyDirection: oehaengDirection[mainOehaeng]!,
      sipSeongAnalysis: sipSeongAnalysis,
      daeWunList: daeWunList,
      seWunList: seWunList,
      shinSalResult: shinSalResult,
      gender: gender,
    );
  }
}

// ─── 데이터 모델 ─────────────────────────────────────

/// 십성 (十星)
class SipSeong {
  final String name;   // 비견, 겁재, 식신...
  final String target; // 천간
  final String oehaeng;

  const SipSeong({
    required this.name,
    required this.target,
    required this.oehaeng,
  });

  String get group {
    if (name == '비견' || name == '겁재') return '비겁';
    if (name == '식신' || name == '상관') return '식상';
    if (name == '편재' || name == '정재') return '재성';
    if (name == '편관' || name == '정관') return '관성';
    return '인성';
  }

  String get groupEmoji {
    const emojis = {
      '비겁': '💪', '식상': '🎨', '재성': '💰', '관성': '⚖️', '인성': '📚',
    };
    return emojis[group] ?? '✨';
  }

  String get shortDesc {
    const desc = {
      '비견': '자립·독립', '겁재': '경쟁·투쟁', '식신': '안정·복록',
      '상관': '창의·표현', '편재': '재물·확장', '정재': '실속·성실',
      '편관': '도전·변화', '정관': '원칙·명예', '편인': '직관·예술',
      '정인': '학습·배려',
    };
    return desc[name] ?? '';
  }
}

/// 십성 분석 결과
class SipSeongAnalysis {
  final List<SipSeong> list;
  final Map<String, int> count;
  final String dominant;          // 가장 많은 십성
  final String propertyTips;
  final String personalityDesc;
  final String formatDesc;        // 격국

  const SipSeongAnalysis({
    required this.list,
    required this.count,
    required this.dominant,
    required this.propertyTips,
    required this.personalityDesc,
    required this.formatDesc,
  });

  /// 오행 그룹별 count
  Map<String, int> get groupCount {
    final Map<String, int> g = {
      '비겁': 0, '식상': 0, '재성': 0, '관성': 0, '인성': 0,
    };
    for (final ss in list) {
      g[ss.group] = (g[ss.group] ?? 0) + 1;
    }
    return g;
  }
}

/// 대운 (10년 운세)
class DaeWun {
  final int age;
  final int endAge;
  final String cheongan;
  final String jiji;
  final String oehaeng;
  final int year;
  final SipSeong sipSeong;   // ← 십성 추가
  final String propertyTip;
  final int investmentScore;

  const DaeWun({
    required this.age,
    required this.endAge,
    required this.cheongan,
    required this.jiji,
    required this.oehaeng,
    required this.year,
    required this.sipSeong,
    required this.propertyTip,
    required this.investmentScore,
  });

  bool isCurrent(int currentYear, int birthYear) {
    final age = currentYear - birthYear;
    return age >= this.age && age <= endAge;
  }
}

/// 세운 (연도별 운세)
class SeWun {
  final int year;
  final String cheongan;
  final String jiji;
  final String oehaeng;
  final SipSeong sipSeong;    // ← 일간 기준 십성
  final String jijiRelation;  // 일지와의 관계 (합/충/생/극/평)
  final int investmentScore;
  final String propertyAdvice;
  final String buyOrSell;

  const SeWun({
    required this.year,
    required this.cheongan,
    required this.jiji,
    required this.oehaeng,
    required this.sipSeong,
    required this.jijiRelation,
    required this.investmentScore,
    required this.propertyAdvice,
    required this.buyOrSell,
  });

  String get ganJiStr => '$cheongan$jiji';
  String get scoreLabel {
    if (investmentScore >= 80) return '대길 🔴';
    if (investmentScore >= 65) return '길 🟠';
    if (investmentScore >= 50) return '평길 🟡';
    if (investmentScore >= 35) return '보통 🟢';
    return '주의 ⚪';
  }
}

/// 전체 사주 결과
class SajuResult {
  final Map<String, String> yearGj, monthGj, dayGj, hourGj;
  final String ilgan;   // 일간 (日干)
  final String ilji;    // 일지 (日支)
  final Map<String, int> oehaengScore;
  final String mainOehaeng;
  final String weakOehaeng;
  final Map<String, String> propertyInfo;
  final String luckyDirection;
  final SipSeongAnalysis sipSeongAnalysis;  // 십성
  final List<DaeWun> daeWunList;
  final List<SeWun> seWunList;              // 세운
  final ShinSalResult shinSalResult;        // 신살
  final String gender;

  const SajuResult({
    required this.yearGj, required this.monthGj,
    required this.dayGj, required this.hourGj,
    required this.ilgan, required this.ilji,
    required this.oehaengScore,
    required this.mainOehaeng, required this.weakOehaeng,
    required this.propertyInfo, required this.luckyDirection,
    required this.sipSeongAnalysis,
    required this.daeWunList, required this.seWunList,
    required this.shinSalResult,
    required this.gender,
  });

  DaeWun? currentDaeWun(int currentYear, int birthYear) {
    try {
      return daeWunList.firstWhere((d) => d.isCurrent(currentYear, birthYear));
    } catch (_) {
      return daeWunList.isNotEmpty ? daeWunList.first : null;
    }
  }

  SeWun? seWunOfYear(int year) {
    try {
      return seWunList.firstWhere((s) => s.year == year);
    } catch (_) {
      return null;
    }
  }

  int get investmentScore {
    final main = oehaengScore[mainOehaeng] ?? 0;
    final total = oehaengScore.values.reduce((a, b) => a + b);
    if (total == 0) return 50;
    final balance = (main / total * 100).round();
    return (100 - (balance - 25).abs() * 2).clamp(30, 95);
  }
}
