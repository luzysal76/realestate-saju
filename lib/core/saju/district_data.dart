// 서울 자치구 오행 데이터 — 공유 모듈
// fortune_map, seoul_top10, moving_simulator 에서 공통 사용

import '../theme/app_theme.dart';
import 'saju_calculator.dart';
import 'package:flutter/material.dart';

// ─── 자치구 기본 데이터 ─────────────────────────────────

class DistrictData {
  final String name;
  final String oehaeng;
  final String landmark;
  final String emoji;
  final String desc;

  const DistrictData(this.name, this.oehaeng, this.landmark, this.emoji, this.desc);
}

// ─── 동네 캐릭터 타입 ────────────────────────────────────

class DistrictCharacter {
  final String type;       // 숲속형, 성장형, 자유형, 안정형, 도전형
  final String emoji;
  final String tagline;
  final String desc;
  final Color color;

  const DistrictCharacter({
    required this.type,
    required this.emoji,
    required this.tagline,
    required this.desc,
    required this.color,
  });
}

const _characters = {
  '목': DistrictCharacter(
    type: '숲속형',
    emoji: '🌳',
    tagline: '자연과 함께 숨쉬는',
    desc: '녹지와 공원이 풍부한 쾌적한 주거지. 목(木) 기운이 성장과 건강을 이끕니다.',
    color: AppColors.mokColor,
  ),
  '화': DistrictCharacter(
    type: '성장형',
    emoji: '🔥',
    tagline: '역동적 에너지가 넘치는',
    desc: '학군·상권·문화가 발달한 핫플레이스. 화(火) 기운이 명예와 성취를 이끕니다.',
    color: AppColors.hwaColor,
  ),
  '수': DistrictCharacter(
    type: '자유형',
    emoji: '🌊',
    tagline: '한강을 품은 자유로운',
    desc: '수변과 흐름이 아름다운 지역. 수(水) 기운이 지혜와 유연함을 이끕니다.',
    color: AppColors.suColor,
  ),
  '토': DistrictCharacter(
    type: '안정형',
    emoji: '⛰️',
    tagline: '든든하고 균형잡힌',
    desc: '평지·신도시·주거 인프라가 탄탄한 지역. 토(土) 기운이 안정과 신뢰를 이끕니다.',
    color: AppColors.toColor,
  ),
  '금': DistrictCharacter(
    type: '도전형',
    emoji: '⚡',
    tagline: '금융과 혁신이 빛나는',
    desc: '비즈니스·금융·IT의 중심지. 금(金) 기운이 결단력과 성공을 이끕니다.',
    color: AppColors.geumColor,
  ),
};

DistrictCharacter getCharacter(String oehaeng) =>
    _characters[oehaeng] ??
    const DistrictCharacter(
      type: '균형형', emoji: '✨', tagline: '모든 기운이 조화로운',
      desc: '오행이 고루 갖춰진 지역입니다.', color: AppColors.accent,
    );

// ─── 서울 25개 자치구 데이터 ─────────────────────────────

const seoulDistricts = [
  // 목(木)
  DistrictData('강동구', '목', '어린이대공원·천호공원', '🌳', '도시숲·생태공원 풍부'),
  DistrictData('노원구', '목', '불암산·수락산 인근', '🌿', '자연환경 우수, 주거 쾌적'),
  DistrictData('도봉구', '목', '북한산·도봉산', '🏔️', '청정 자연, 에너지 맑음'),
  DistrictData('양천구', '목', '목동·안양천 인근', '🌱', '학군+녹지 결합'),
  DistrictData('중랑구', '목', '용마산·망우산', '🍃', '조용한 주거지, 산록 기운'),
  // 화(火)
  DistrictData('강남구', '화', '대치동 학군·강남역', '🔥', '최상위 학군, 역동적 기운'),
  DistrictData('서초구', '화', '반포·교육타운', '⭐', '안정적 학군, 남향 단지'),
  DistrictData('마포구', '화', '홍대·망원·상암', '✨', '문화·상권 활발, 젊은 기운'),
  DistrictData('용산구', '화', '이태원·한남·미군기지', '🌟', '국제적 분위기, 고급화'),
  DistrictData('성동구', '화', '왕십리·성수 핫플', '🔆', '재개발+상권 활성'),
  // 토(土)
  DistrictData('송파구', '토', '잠실·올림픽공원', '🏙️', '균형잡힌 주거·상권'),
  DistrictData('성북구', '토', '길음·석관·장위', '🏘️', '재개발 활발, 안정 기운'),
  DistrictData('서대문구', '토', '신촌·홍은·은평', '🏫', '교육·주거 균형'),
  DistrictData('관악구', '토', '신림·봉천·서울대', '📚', '교육 기운 강함'),
  DistrictData('은평구', '토', '불광·녹번·역촌', '🏡', '평온한 주거, 안정 기운'),
  // 금(金)
  DistrictData('영등포구', '금', '여의도 금융타운', '💎', '국내 금융 1번지'),
  DistrictData('중구', '금', '명동·을지로·종로', '💰', '역사+금융 중심부'),
  DistrictData('강서구', '금', '마곡산업단지', '⚙️', '첨단산업 기운, 성장세'),
  DistrictData('구로구', '금', '구로디지털단지', '🔩', '산업·IT 기운'),
  DistrictData('동대문구', '금', '청량리·회기 개발', '🏗️', '재개발 집중, 변화 기운'),
  // 수(水)
  DistrictData('강북구', '수', '북한강 수변·우이천', '💧', '자연 수계 풍부'),
  DistrictData('광진구', '수', '한강변·자양·건대', '🌊', '한강 조망 우수'),
  DistrictData('동작구', '수', '반포·흑석 한강변', '🏞️', '한강 접근성 최고'),
  DistrictData('압구정·청담', '수', '압구정·청담 한강뷰', '🌉', '최고급 수변 라이프'),
  DistrictData('종로구', '수', '청계천·경복궁 수계', '💦', '역사적 수기 흐름'),
];

// ─── 궁합 점수 계산 ─────────────────────────────────────

int districtScore(DistrictData d, String myMain, String myWeak) {
  final supplement = SajuCalculator.saeng[myWeak] ?? '';
  int score = 50;
  if (d.oehaeng == myMain)                           score += 25;
  else if (d.oehaeng == supplement)                  score += 20;
  else if (SajuCalculator.saeng[myMain] == d.oehaeng) score += 15;
  else if (SajuCalculator.geuk[myMain] == d.oehaeng)  score -= 10;
  return score.clamp(25, 98);
}

// ─── 궁합 코멘트 ─────────────────────────────────────────

String compatComment(int score, String distOe, String myOe) {
  if (score >= 85) return '$distOe 기운이 나의 $myOe 기운과 완벽하게 어우러집니다. 강력 추천!';
  if (score >= 75) return '$distOe 기운이 나의 기운을 보완하고 성장시킵니다.';
  if (score >= 65) return '나쁘지 않은 궁합입니다. 개인 노력으로 충분히 극복 가능해요.';
  if (score >= 50) return '평범한 궁합. 특별한 장단점 없이 무난한 지역입니다.';
  return '$distOe 기운이 나의 $myOe 기운과 다소 충돌합니다. 신중하게 검토하세요.';
}
