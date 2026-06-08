// 신살 (神煞) 계산 엔진 — 부동산 특화 분석
// 역마살·도화살·화개살·천을귀인·삼재살·공망 포함

import 'saju_calculator.dart';

enum ShinSalType { lucky, caution, mixed }

/// 신살 항목
class ShinSalItem {
  final String name;
  final String hanja;
  final String emoji;
  final ShinSalType type;
  final String desc;
  final String realEstateTip;
  final List<String> activeJijis; // 활성화되는 지지

  const ShinSalItem({
    required this.name,
    required this.hanja,
    required this.emoji,
    required this.type,
    required this.desc,
    required this.realEstateTip,
    this.activeJijis = const [],
  });

  String get typeLabel {
    switch (type) {
      case ShinSalType.lucky:   return '길신 ✨';
      case ShinSalType.caution: return '흉살 ⚠️';
      case ShinSalType.mixed:   return '중립 ◎';
    }
  }
}

/// 신살 분석 결과
class ShinSalResult {
  final List<ShinSalItem> items;
  final List<String> gongmang;     // 공망 지지 목록 (일주 기준)
  final List<String> yearGongmang; // 공망 지지 목록 (년주 기준)
  final bool isSamjaeYear;         // 현재 삼재살 여부
  final List<String> chuneulJijis; // 천을귀인 지지
  final String gongmangDesc;       // 공망 설명

  const ShinSalResult({
    required this.items,
    required this.gongmang,
    required this.yearGongmang,
    required this.isSamjaeYear,
    required this.chuneulJijis,
    required this.gongmangDesc,
  });

  List<ShinSalItem> get luckyItems =>
      items.where((i) => i.type == ShinSalType.lucky).toList();

  List<ShinSalItem> get cautionItems =>
      items.where((i) => i.type == ShinSalType.caution).toList();

  List<ShinSalItem> get mixedItems =>
      items.where((i) => i.type == ShinSalType.mixed).toList();
}

/// 지장간 (藏干) 데이터 — 지지 안의 숨은 천간
class JijangGan {
  static const Map<String, List<String>> data = {
    '자': ['임', '계'],
    '축': ['기', '신', '계'],
    '인': ['무', '병', '갑'],
    '묘': ['갑', '을'],
    '진': ['을', '계', '무'],
    '사': ['무', '경', '병'],
    '오': ['기', '정'],
    '미': ['정', '을', '기'],
    '신': ['무', '임', '경'],
    '유': ['경', '신'],
    '술': ['신', '정', '무'],
    '해': ['무', '갑', '임'],
  };

  static const Map<String, String> mainStem = {
    '자': '계', '축': '기', '인': '갑', '묘': '을',
    '진': '무', '사': '병', '오': '정', '미': '기',
    '신': '경', '유': '신', '술': '무', '해': '임',
  };

  static List<String> get(String jiji) => data[jiji] ?? [];
  static String? main(String jiji) => mainStem[jiji];
}

/// 신살 계산기
class ShinSalCalculator {

  // ─── 역마살 (驛馬殺) ─────────────────────────────
  static const Map<String, String> _yeokma = {
    '인': '신', '오': '신', '술': '신',
    '신': '인', '자': '인', '진': '인',
    '해': '사', '묘': '사', '미': '사',
    '사': '해', '유': '해', '축': '해',
  };

  // ─── 도화살 (桃花殺) ─────────────────────────────
  static const Map<String, String> _dohwa = {
    '인': '묘', '오': '묘', '술': '묘',
    '신': '유', '자': '유', '진': '유',
    '해': '자', '묘': '자', '미': '자',
    '사': '오', '유': '오', '축': '오',
  };

  // ─── 화개살 (華蓋殺) ─────────────────────────────
  static const Map<String, String> _hwagae = {
    '인': '술', '오': '술', '술': '술',
    '신': '진', '자': '진', '진': '진',
    '해': '미', '묘': '미', '미': '미',
    '사': '축', '유': '축', '축': '축',
  };

  // ─── 삼재살 (三災殺) ─────────────────────────────
  static const Map<String, List<String>> _samjae = {
    '인': ['신', '유', '술'], '오': ['신', '유', '술'], '술': ['신', '유', '술'],
    '신': ['인', '묘', '진'], '자': ['인', '묘', '진'], '진': ['인', '묘', '진'],
    '해': ['사', '오', '미'], '묘': ['사', '오', '미'], '미': ['사', '오', '미'],
    '사': ['해', '자', '축'], '유': ['해', '자', '축'], '축': ['해', '자', '축'],
  };

  // ─── 천을귀인 (天乙貴人) ─────────────────────────
  static const Map<String, List<String>> _chuneul = {
    '갑': ['축', '미'], '무': ['축', '미'],
    '을': ['자', '신'], '기': ['자', '신'],
    '병': ['해', '유'], '정': ['해', '유'],
    '경': ['축', '오'], '신': ['축', '오'],
    '임': ['사', '묘'], '계': ['사', '묘'],
  };

  // ─── 공망 계산 ────────────────────────────────────
  /// 일주(日柱) 기준 공망 지지 계산
  /// 60갑자에서 해당 순(旬)의 공망 지지 반환
  static List<String> calcGongmang(String cg, String jj) {
    final cgIdx = SajuCalculator.cheongan.indexOf(cg);
    final jiIdx = SajuCalculator.jiji.indexOf(jj);

    // 순수(旬首) 지지 = 갑(甲)으로 시작하는 순의 지지
    // startingJi = (jiIdx - cgIdx + 12) % 12
    // 결과는 0, 2, 4, 6, 8, 10 중 하나
    final startingJi = (jiIdx - cgIdx + 12) % 12;

    // 각 순의 공망: startingJi + 10, startingJi + 11 (mod 12)
    const pairs = {
      0:  [10, 11], // 갑자순(甲子旬) → 술·해 공망
      2:  [0,  1],  // 갑인순(甲寅旬) → 자·축 공망
      4:  [2,  3],  // 갑진순(甲辰旬) → 인·묘 공망
      6:  [4,  5],  // 갑오순(甲午旬) → 진·사 공망
      8:  [6,  7],  // 갑신순(甲申旬) → 오·미 공망
      10: [8,  9],  // 갑술순(甲戌旬) → 신·유 공망
    };

    final gm = pairs[startingJi] ?? [];
    return gm.map((i) => SajuCalculator.jiji[i]).toList();
  }

  // ─── 전체 신살 계산 ───────────────────────────────
  static ShinSalResult calculate({
    required String yearJiji,
    required String dayCheongan,
    required String dayJiji,
    required int currentYear,
  }) {
    final items = <ShinSalItem>[];
    final currentJiji = SajuCalculator.jiji[(currentYear - 4) % 12];

    // 1. 역마살 (驛馬殺)
    final yeokmaTarget = _yeokma[yearJiji];
    if (yeokmaTarget != null) {
      final activeYears = _getActiveYears(yeokmaTarget, currentYear);
      items.add(ShinSalItem(
        name: '역마살',
        hanja: '驛馬殺',
        emoji: '🐎',
        type: ShinSalType.mixed,
        activeJijis: [yeokmaTarget],
        desc: '이동·이사·이직 운이 강합니다. 활동 반경이 넓고 환경 변화가 잦습니다.',
        realEstateTip: '이사·부동산 매매 기회가 자주 찾아옵니다. '
            '운세 좋은 해에 이사하면 대길(大吉). '
            '활성화 예정: ${activeYears.join(", ")}',
      ));
    }

    // 2. 도화살 (桃花殺)
    final dohwaTarget = _dohwa[yearJiji];
    if (dohwaTarget != null) {
      final activeYears = _getActiveYears(dohwaTarget, currentYear);
      items.add(ShinSalItem(
        name: '도화살',
        hanja: '桃花殺',
        emoji: '🌸',
        type: ShinSalType.lucky,
        activeJijis: [dohwaTarget],
        desc: '인기와 매력 운이 강합니다. 사람들이 먼저 찾아오는 운입니다.',
        realEstateTip: '부동산 매도·임대 시 좋은 조건의 상대를 쉽게 만납니다. '
            '내 매물이 빠르게 인기를 얻는 시기. '
            '활성화: ${activeYears.join(", ")}',
      ));
    }

    // 3. 화개살 (華蓋殺)
    final hwagaeTarget = _hwagae[yearJiji];
    if (hwagaeTarget != null) {
      items.add(ShinSalItem(
        name: '화개살',
        hanja: '華蓋殺',
        emoji: '🏮',
        type: ShinSalType.mixed,
        activeJijis: [hwagaeTarget],
        desc: '독창적·예술적 감각이 뛰어납니다. 개성 있는 공간을 선호합니다.',
        realEstateTip: '리모델링·인테리어 후 매도 전략이 탁월합니다. '
            '독특한 설계 또는 빈티지 건물에서 숨은 가치를 발견하는 안목 보유.',
      ));
    }

    // 4. 천을귀인 (天乙貴人)
    final chuneulJijis = _chuneul[dayCheongan] ?? [];
    if (chuneulJijis.isNotEmpty) {
      final activeYears = chuneulJijis.expand(
        (jj) => _getActiveYears(jj, currentYear),
      ).take(3).toList();
      items.add(ShinSalItem(
        name: '천을귀인',
        hanja: '天乙貴人',
        emoji: '⭐',
        type: ShinSalType.lucky,
        activeJijis: chuneulJijis,
        desc: '위기에서 귀인이 나타나 도와주는 강한 길성(吉星)입니다.',
        realEstateTip: '좋은 중개인·법무사·파트너가 나타납니다. '
            '${chuneulJijis.join("·")}년·월에 귀인의 도움으로 좋은 거래가 성사됩니다. '
            '가까운 활성화: ${activeYears.join(", ")}',
      ));
    }

    // 5. 삼재살 (三災殺) — 현재 년도 해당 여부
    final samjaeYears = _samjae[yearJiji] ?? [];
    final isSamjaeYear = samjaeYears.contains(currentJiji);
    if (isSamjaeYear) {
      items.add(ShinSalItem(
        name: '삼재 (올해)',
        hanja: '三災殺',
        emoji: '🔺',
        type: ShinSalType.caution,
        activeJijis: samjaeYears,
        desc: '삼재(三災) 기간은 수성(守成)에 집중해야 합니다.',
        realEstateTip: '삼재 3년 동안 큰 부동산 투자·이사를 최대한 자제하세요. '
            '기존 보유 자산을 잘 관리하고, 꼭 해야 한다면 전문가와 충분히 상담하세요.',
      ));
    }

    // 공망 계산 (일주 기준)
    final gongmang = calcGongmang(dayCheongan, dayJiji);
    final gongmangDesc = gongmang.isNotEmpty
        ? '${gongmang.join("·")}이 공망(空亡). '
          '${gongmang.join("·")}년·월·일에는 계약·큰 결정을 피하세요.'
        : '';

    // 년주 공망 (참고용)
    final yearJijangMain = JijangGan.main(yearJiji) ?? '';
    final yearGongmang = yearJijangMain.isNotEmpty
        ? calcGongmang(yearJijangMain, yearJiji)
        : <String>[];

    return ShinSalResult(
      items: items,
      gongmang: gongmang,
      yearGongmang: yearGongmang,
      isSamjaeYear: isSamjaeYear,
      chuneulJijis: chuneulJijis,
      gongmangDesc: gongmangDesc,
    );
  }

  // ─── 내부 헬퍼 ───────────────────────────────────

  /// 특정 지지가 활성화되는 가까운 년도 반환
  static List<String> _getActiveYears(String jiji, int currentYear) {
    final result = <String>[];
    for (int i = 0; i <= 12 && result.length < 2; i++) {
      final yr = currentYear + i;
      final ji = SajuCalculator.jiji[(yr - 4) % 12];
      if (ji == jiji) result.add('${yr}년');
    }
    return result;
  }
}
