import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';

// ─────────────────────────────────────────────────────
// 오행별 입지 데이터
// ─────────────────────────────────────────────────────

class _LocationData {
  final String oehaeng;
  final String direction;
  final String hanja;
  final String emoji;
  final List<String> districts;    // 서울 자치구 예시
  final String terrain;            // 지형 특성
  final String propertyType;       // 주택 유형
  final String bestSeason;         // 매수 적기
  final String tip;                // 명리학 설명

  const _LocationData({
    required this.oehaeng,
    required this.direction,
    required this.hanja,
    required this.emoji,
    required this.districts,
    required this.terrain,
    required this.propertyType,
    required this.bestSeason,
    required this.tip,
  });
}

const _locationMap = <String, _LocationData>{
  '목': _LocationData(
    oehaeng: '목',
    direction: '동쪽 (東)',
    hanja: '木',
    emoji: '🌿',
    districts: ['성동구', '광진구', '노원구', '도봉구', '중랑구'],
    terrain: '산·공원·숲 인근, 재개발 진행 지역',
    propertyType: '신축 아파트 · 재개발 구역',
    bestSeason: '봄 (3~5월)',
    tip: '목(木) 기운은 성장과 발전을 상징합니다. 동쪽 방위의 신흥 개발지나 자연환경이 풍부한 지역이 길합니다. 상승 잠재력이 큰 재개발 구역이나 공원 인근 신축이 어울립니다.',
  ),
  '화': _LocationData(
    oehaeng: '화',
    direction: '남쪽 (南)',
    hanja: '火',
    emoji: '🔥',
    districts: ['강남구', '서초구', '송파구', '강동구', '관악구'],
    terrain: '역세권 · 상업지역 · 고층 개발지',
    propertyType: '역세권 아파트 · 오피스텔',
    bestSeason: '여름 (6~8월)',
    tip: '화(火) 기운은 열정과 번영을 상징합니다. 유동인구가 많고 활기찬 남쪽 상업지역이 사주와 잘 공명합니다. 역세권 고층 아파트나 오피스텔이 특히 길합니다.',
  ),
  '토': _LocationData(
    oehaeng: '토',
    direction: '중앙 (中)',
    hanja: '土',
    emoji: '🏛',
    districts: ['종로구', '중구', '용산구', '마포구', '성북구'],
    terrain: '평지 · 교통 중심지 · 구도심',
    propertyType: '구도심 아파트 · 오래된 토지',
    bestSeason: '환절기 (3·6·9·12월)',
    tip: '토(土) 기운은 안정과 지속을 상징합니다. 도심 중앙에 위치한 안정적인 구도심 아파트나 교통 요지의 토지 투자가 가장 유리합니다.',
  ),
  '금': _LocationData(
    oehaeng: '금',
    direction: '서쪽 (西)',
    hanja: '金',
    emoji: '💎',
    districts: ['양천구', '강서구', '구로구', '영등포구', '금천구'],
    terrain: '교통 요지 · 정돈된 주거단지',
    propertyType: '프리미엄 아파트 · 신규 브랜드 단지',
    bestSeason: '가을 (9~11월)',
    tip: '금(金) 기운은 결실과 수확을 상징합니다. 서쪽 방위의 정돈된 주거단지나 프리미엄 아파트가 사주와 잘 맞습니다. 서향·서남향 집이 특히 길합니다.',
  ),
  '수': _LocationData(
    oehaeng: '수',
    direction: '북쪽 (北)',
    hanja: '水',
    emoji: '🌊',
    districts: ['마포구', '강북구', '성북구', '은평구', '도봉구'],
    terrain: '한강변 · 수변 · 고지대 조망',
    propertyType: '한강변 아파트 · 수변 주거지',
    bestSeason: '겨울 (12~2월)',
    tip: '수(水) 기운은 유연함과 지혜를 상징합니다. 북쪽 방위의 수변 아파트나 한강 인근 주거지가 길합니다. 조용하고 생각이 깊은 지역이 어울립니다.',
  ),
};

// ─────────────────────────────────────────────────────
// 입지 추천 카드 위젯
// ─────────────────────────────────────────────────────

class LocationRecommendCard extends StatefulWidget {
  final SajuResult result;

  const LocationRecommendCard({super.key, required this.result});

  @override
  State<LocationRecommendCard> createState() => _LocationRecommendCardState();
}

class _LocationRecommendCardState extends State<LocationRecommendCard> {
  bool _showWeak = false; // false=강한 오행 궁합, true=부족 오행 보완

  @override
  Widget build(BuildContext context) {
    final mainOe = widget.result.mainOehaeng;
    final weakOe = widget.result.weakOehaeng;
    final mainData = _locationMap[mainOe]!;
    final weakData = _locationMap[weakOe] ?? mainData;
    final oehaengScore = widget.result.oehaengScore;

    // 부족/강한 오행 점수
    final mainScore = oehaengScore[mainOe] ?? 0;
    final weakScore = oehaengScore[weakOe] ?? 0;

    final selectedData = _showWeak ? weakData : mainData;
    final selectedColor = AppColors.getOehaengColor(selectedData.oehaeng);

    return TraditionalCard(
      doubleBorder: true,
      borderColor: selectedColor.withOpacity(0.35),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── 헤더 ──
        Row(children: [
          const KoreanSectionTitle(
            title: '맞춤 입지 추천 (立地)',
            icon: '📍',
            showDivider: false,
          ),
          const Spacer(),
          // 강한/부족 토글
          GestureDetector(
            onTap: () => setState(() => _showWeak = !_showWeak),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(children: [
                Text(
                  _showWeak ? '보완 기운' : '궁합 기운',
                  style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.swap_horiz, size: 12, color: AppColors.textSecondary),
              ]),
            ),
          ),
        ]),
        Container(height: 1, margin: const EdgeInsets.only(top: 8, bottom: 12),
          decoration: BoxDecoration(gradient: LinearGradient(
            colors: [selectedColor.withOpacity(0.5), Colors.transparent]))),

        // ── 오행 선택 탭 ──
        _buildOehaengTabs(mainOe, weakOe, mainScore, weakScore),
        const SizedBox(height: 14),

        // ── 추천 카드 ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildRecommendContent(selectedData, selectedColor, _showWeak),
        ),

        const SizedBox(height: 12),

        // ── 명리학 설명 ──
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selectedColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selectedColor.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(selectedData.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(child: Text(
              selectedData.tip,
              style: const TextStyle(
                fontSize: 12, color: AppColors.textPrimary, height: 1.5),
            )),
          ]),
        ),
      ]),
    ).animate(delay: 310.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildOehaengTabs(
      String mainOe, String weakOe, int mainScore, int weakScore) {
    return Row(children: [
      _OehaengTab(
        oehaeng: mainOe,
        label: '궁합',
        score: mainScore,
        selected: !_showWeak,
        onTap: () => setState(() => _showWeak = false),
      ),
      const SizedBox(width: 8),
      _OehaengTab(
        oehaeng: weakOe,
        label: '보완',
        score: weakScore,
        selected: _showWeak,
        onTap: () => setState(() => _showWeak = true),
      ),
    ]);
  }

  Widget _buildRecommendContent(
      _LocationData data, Color color, bool isWeak) {
    return Column(
      key: ValueKey(data.oehaeng + isWeak.toString()),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 방위 + 기운 배지 행
        Row(children: [
          // 방위 원형 표시
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(data.hanja, style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 22, fontWeight: FontWeight.bold, color: color,
              )),
              Text(data.oehaeng, style: TextStyle(
                fontSize: 9, color: color.withOpacity(0.8), letterSpacing: 1,
              )),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 방위
              Row(children: [
                const Text('📌 ', style: TextStyle(fontSize: 12)),
                Text(data.direction, style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 13, fontWeight: FontWeight.bold, color: color,
                  letterSpacing: 0.5,
                )),
              ]),
              const SizedBox(height: 4),
              // 매수 적기
              Row(children: [
                const Text('🗓 ', style: TextStyle(fontSize: 11)),
                Text('매수 적기: ${data.bestSeason}',
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
              ]),
              const SizedBox(height: 4),
              // 주택 유형
              Row(children: [
                const Text('🏠 ', style: TextStyle(fontSize: 11)),
                Expanded(child: Text(data.propertyType,
                  style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary))),
              ]),
            ],
          )),
        ]),

        const SizedBox(height: 12),

        // 지형 특성
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(children: [
            Icon(Icons.landscape_outlined, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(data.terrain, style: TextStyle(
              fontSize: 11, color: color.withOpacity(0.9), letterSpacing: 0.3,
            ))),
          ]),
        ),

        const SizedBox(height: 10),

        // 추천 자치구 (서울)
        _buildDistrictChips(data.districts, color),
      ],
    );
  }

  Widget _buildDistrictChips(List<String> districts, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.location_city_outlined, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        const Text('서울 추천 자치구', style: TextStyle(
          fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5)),
      ]),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6, runSpacing: 6,
        children: districts.map((d) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Text(d, style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 11, color: color, fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          )),
        )).toList(),
      ),
    ]);
  }
}

// ─── 오행 탭 버튼 ──────────────────────────────────────

class _OehaengTab extends StatelessWidget {
  final String oehaeng;
  final String label;
  final int score;
  final bool selected;
  final VoidCallback onTap;

  const _OehaengTab({
    required this.oehaeng,
    required this.label,
    required this.score,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getOehaengColor(oehaeng);
    const hanja = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? color.withOpacity(0.6) : AppColors.divider,
            width: selected ? 1.5 : 0.8,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(hanja[oehaeng] ?? oehaeng, style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 16, fontWeight: FontWeight.bold,
            color: selected ? color : AppColors.textSecondary,
          )),
          const SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
              fontSize: 9,
              color: selected ? color.withOpacity(0.9) : AppColors.textMuted,
              letterSpacing: 0.5,
            )),
            Text('$oehaeng 기운 $score점', style: TextStyle(
              fontSize: 9,
              color: selected ? color.withOpacity(0.7) : AppColors.textMuted,
            )),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// 대시보드용 가로 스크롤 입지 카드
// ─────────────────────────────────────────────────────

class LocationScrollCard extends StatelessWidget {
  final SajuResult result;
  const LocationScrollCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final mainOe = result.mainOehaeng;
    final weakOe = result.weakOehaeng;
    // 세 번째: 메인 기준 다음 상생 오행
    const saeng = {'목': '화', '화': '토', '토': '금', '금': '수', '수': '목'};
    final thirdOe = saeng[mainOe] ?? weakOe;

    final items = [mainOe, weakOe, thirdOe];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 14, height: 1, color: AppColors.accent),
        const SizedBox(width: 6),
        const Text('맞춤 입지 추천 (立地)', style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 13, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary, letterSpacing: 1,
        )),
        const Spacer(),
        Text('전체 ›', style: TextStyle(
          fontSize: 11, color: AppColors.accent.withOpacity(0.8))),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 148,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final oe = items[i];
            final data = _locationMap[oe]!;
            final color = AppColors.getOehaengColor(oe);
            return _LocationScrollItem(
              data: data, color: color, isRecommended: i == 0);
          },
        ),
      ),
    ]);
  }
}

class _LocationScrollItem extends StatelessWidget {
  final _LocationData data;
  final Color color;
  final bool isRecommended;

  const _LocationScrollItem({
    required this.data, required this.color, required this.isRecommended,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isRecommended
          ? Color.lerp(AppColors.cardBg, color, 0.12)!
          : AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRecommended ? color.withOpacity(0.4) : AppColors.divider,
          width: isRecommended ? 1.5 : 0.8,
        ),
        boxShadow: isRecommended ? [BoxShadow(
          color: color.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2),
        )] : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(data.hanja, style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 26, fontWeight: FontWeight.w900,
            color: color,
            shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 8)],
          )),
          if (isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('추천', style: TextStyle(
                fontSize: 8, color: color, fontWeight: FontWeight.bold)),
            ),
        ]),
        Text(data.direction, style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 11, fontWeight: FontWeight.bold,
          color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(data.districts.take(2).join(' · '), style: const TextStyle(
          fontSize: 9, color: AppColors.textSecondary, height: 1.3)),
        const Spacer(),
        Container(height: 0.5, color: color.withOpacity(0.2)),
        const SizedBox(height: 5),
        Text('🗓 ${data.bestSeason}', style: const TextStyle(
          fontSize: 9, color: AppColors.textMuted)),
      ]),
    );
  }
}
