// district_map_data.dart — 서울 25개 자치구 오행+좌표 데이터
// 점수 계산 함수 포함 (fortune_map_screen + real_map_view 공용)

import '../../core/saju/saju_calculator.dart';

// ─── 자치구 데이터 모델 ─────────────────────────────────
class DistrictData {
  final String name;
  final String oehaeng;
  final String keyword;
  final String emoji;
  final String description;
  final double lat;
  final double lng;

  const DistrictData(
    this.name, this.oehaeng, this.keyword, this.emoji,
    this.description, this.lat, this.lng,
  );
}

// ─── 점수 계산 (공용) ──────────────────────────────────
int calcDistrictScore(DistrictData d, String mainOe, String weakOe) {
  final supplement = SajuCalculator.saeng[weakOe] ?? '';
  int score = 50;
  if (d.oehaeng == mainOe) score += 25;
  else if (d.oehaeng == supplement) score += 20;
  else if (SajuCalculator.saeng[mainOe] == d.oehaeng) score += 15;
  else if (SajuCalculator.geuk[mainOe] == d.oehaeng) score -= 10;
  return score.clamp(25, 98);
}

// ─── 자치구 부가 데이터 (교통·편의·평균시세) ──────────
class DistrictExtra {
  final int transit;     // 교통 편의성 0~100
  final int amenity;     // 생활 편의시설 0~100
  final int avgPriceAk;  // 평균 시세 (억원)
  const DistrictExtra(this.transit, this.amenity, this.avgPriceAk);
}

const districtExtras = <String, DistrictExtra>{
  '강동구':    DistrictExtra(72, 70, 6),
  '노원구':    DistrictExtra(70, 65, 4),
  '도봉구':    DistrictExtra(65, 58, 3),
  '양천구':    DistrictExtra(75, 75, 6),
  '중랑구':    DistrictExtra(65, 62, 3),
  '강남구':    DistrictExtra(95, 95, 12),
  '서초구':    DistrictExtra(88, 90, 11),
  '마포구':    DistrictExtra(88, 85, 7),
  '용산구':    DistrictExtra(83, 83, 9),
  '성동구':    DistrictExtra(80, 78, 8),
  '송파구':    DistrictExtra(85, 85, 9),
  '성북구':    DistrictExtra(70, 70, 5),
  '서대문구':  DistrictExtra(73, 72, 5),
  '관악구':    DistrictExtra(75, 70, 4),
  '은평구':    DistrictExtra(65, 65, 4),
  '영등포구':  DistrictExtra(88, 83, 6),
  '중구':      DistrictExtra(93, 87, 8),
  '강서구':    DistrictExtra(72, 70, 5),
  '구로구':    DistrictExtra(75, 68, 4),
  '동대문구':  DistrictExtra(78, 73, 5),
  '강북구':    DistrictExtra(60, 58, 3),
  '광진구':    DistrictExtra(75, 70, 6),
  '동작구':    DistrictExtra(78, 72, 6),
  '압구정·청담': DistrictExtra(80, 92, 22),
  '종로구':    DistrictExtra(90, 85, 7),
};

// 예산 적합성 점수
int calcBudgetScore(String districtName, int budgetAk) {
  if (budgetAk == 0) return 50; // 무관
  final extra = districtExtras[districtName];
  if (extra == null) return 50;
  final ratio = budgetAk / extra.avgPriceAk;
  if (ratio >= 1.5) return 95;
  if (ratio >= 1.0) return 80;
  if (ratio >= 0.7) return 60;
  if (ratio >= 0.5) return 40;
  return 20;
}

// ─── 서울 25개 자치구 데이터 ───────────────────────────
const seoulDistricts = [
  // 목(木) — 숲세권, 공원, 녹지
  DistrictData('강동구', '목', '어린이대공원·천호공원', '🌳', '도시숲·생태공원 풍부', 37.5301, 127.1238),
  DistrictData('노원구', '목', '불암산·수락산 인근', '🌿', '자연환경 우수, 주거 쾌적', 37.6541, 127.0568),
  DistrictData('도봉구', '목', '북한산·도봉산', '🏔️', '청정 자연, 에너지 맑음', 37.6688, 127.0471),
  DistrictData('양천구', '목', '목동·안양천 인근', '🌱', '학군+녹지 결합', 37.5170, 126.8665),
  DistrictData('중랑구', '목', '용마산·망우산', '🍃', '조용한 주거지, 산록 기운', 37.6063, 127.0924),

  // 화(火) — 학군지, 번화가, 역동
  DistrictData('강남구', '화', '대치동 학군·강남역', '🔥', '최상위 학군, 역동적 기운', 37.5172, 127.0473),
  DistrictData('서초구', '화', '반포·교육타운', '⭐', '안정적 학군, 남향 단지', 37.4837, 127.0324),
  DistrictData('마포구', '화', '홍대·망원·상암', '✨', '문화·상권 활발, 젊은 기운', 37.5638, 126.9084),
  DistrictData('용산구', '화', '이태원·한남·미군기지', '🌟', '국제적 분위기, 고급화', 37.5384, 126.9654),
  DistrictData('성동구', '화', '왕십리·성수 핫플', '🔆', '재개발+상권 활성', 37.5634, 127.0369),

  // 토(土) — 평지, 신도시, 안정
  DistrictData('송파구', '토', '잠실·올림픽공원', '🏙️', '균형잡힌 주거·상권', 37.5145, 127.1059),
  DistrictData('성북구', '토', '길음·석관·장위', '🏘️', '재개발 활발, 안정 기운', 37.5894, 127.0167),
  DistrictData('서대문구', '토', '신촌·홍은·은평', '🏫', '교육·주거 균형', 37.5791, 126.9368),
  DistrictData('관악구', '토', '신림·봉천·서울대', '📚', '교육 기운 강함', 37.4784, 126.9516),
  DistrictData('은평구', '토', '불광·녹번·역촌', '🏡', '평온한 주거, 안정 기운', 37.6027, 126.9290),

  // 금(金) — 금융, 고층, 산업
  DistrictData('영등포구', '금', '여의도 금융타운', '💎', '국내 금융 1번지', 37.5264, 126.8962),
  DistrictData('중구', '금', '명동·을지로·종로', '💰', '역사+금융 중심부', 37.5641, 126.9979),
  DistrictData('강서구', '금', '마곡산업단지', '⚙️', '첨단산업 기운, 성장세', 37.5509, 126.8495),
  DistrictData('구로구', '금', '구로디지털단지', '🔩', '산업·IT 기운', 37.4955, 126.8874),
  DistrictData('동대문구', '금', '청량리·회기 개발', '🏗️', '재개발 집중, 변화 기운', 37.5744, 127.0396),

  // 수(水) — 수변, 한강, 흐름
  DistrictData('강북구', '수', '북한강 수변·우이천', '💧', '자연 수계 풍부', 37.6398, 127.0254),
  DistrictData('광진구', '수', '한강변·자양·건대', '🌊', '한강 조망 우수', 37.5385, 127.0823),
  DistrictData('동작구', '수', '반포·흑석 한강변', '🏞️', '한강 접근성 최고', 37.5124, 126.9393),
  DistrictData('압구정·청담', '수', '압구정·청담 한강뷰', '🌉', '최고급 수변 라이프', 37.5265, 127.0311),
  DistrictData('종로구', '수', '청계천·경복궁 수계', '💦', '역사적 수기 흐름', 37.5730, 126.9794),
];
