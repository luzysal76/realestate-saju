import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

/// 서울 자치구 오행 히트맵
/// 각 자치구를 오행으로 분류 → 사용자 오행 점수 기반 히트맵 표시
class FortuneMapScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;
  const FortuneMapScreen({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  State<FortuneMapScreen> createState() => _FortuneMapScreenState();
}

class _FortuneMapScreenState extends State<FortuneMapScreen> {
  String _selectedFilter = '전체';
  _DistrictDetail? _selectedDistrict;

  static const _filters = ['전체', '목(木)', '화(火)', '토(土)', '금(金)', '수(水)'];

  // ─── 자치구 오행 데이터 ──────────────────────────

  static const _districts = [
    // 목(木) — 숲세권, 공원, 녹지 중심
    _DistrictData('강동구', '목', '어린이대공원·천호공원', '🌳', '도시숲·생태공원 풍부'),
    _DistrictData('노원구', '목', '불암산·수락산 인근', '🌿', '자연환경 우수, 주거 쾌적'),
    _DistrictData('도봉구', '목', '북한산·도봉산', '🏔️', '청정 자연, 에너지 맑음'),
    _DistrictData('양천구', '목', '목동·안양천 인근', '🌱', '학군+녹지 결합'),
    _DistrictData('중랑구', '목', '용마산·망우산', '🍃', '조용한 주거지, 산록 기운'),

    // 화(火) — 학군지, 번화가, 남향, 상권
    _DistrictData('강남구', '화', '대치동 학군·강남역', '🔥', '최상위 학군, 역동적 기운'),
    _DistrictData('서초구', '화', '반포·교육타운', '⭐', '안정적 학군, 남향 단지'),
    _DistrictData('마포구', '화', '홍대·망원·상암', '✨', '문화·상권 활발, 젊은 기운'),
    _DistrictData('용산구', '화', '이태원·한남·미군기지', '🌟', '국제적 분위기, 고급화'),
    _DistrictData('성동구', '화', '왕십리·성수 핫플', '🔆', '재개발+상권 활성'),

    // 토(土) — 평지, 신도시, 중심부, 안정
    _DistrictData('송파구', '토', '잠실·올림픽공원', '🏙️', '균형잡힌 주거·상권'),
    _DistrictData('성북구', '토', '길음·석관·장위', '🏘️', '재개발 활발, 안정 기운'),
    _DistrictData('서대문구', '토', '신촌·홍은·은평', '🏫', '교육·주거 균형'),
    _DistrictData('관악구', '토', '신림·봉천·서울대', '📚', '교육 기운 강함'),
    _DistrictData('은평구', '토', '불광·녹번·역촌', '🏡', '평온한 주거, 안정 기운'),

    // 금(金) — 금융, 고층, 비즈니스
    _DistrictData('영등포구', '금', '여의도 금융타운', '💎', '국내 금융 1번지'),
    _DistrictData('중구', '금', '명동·을지로·종로', '💰', '역사+금융 중심부'),
    _DistrictData('강서구', '금', '마곡산업단지', '⚙️', '첨단산업 기운, 성장세'),
    _DistrictData('구로구', '금', '구로디지털단지', '🔩', '산업·IT 기운'),
    _DistrictData('동대문구', '금', '청량리·회기 개발', '🏗️', '재개발 집중, 변화 기운'),

    // 수(水) — 수변, 한강, 흐름
    _DistrictData('강북구', '수', '북한강 수변·우이천', '💧', '자연 수계 풍부'),
    _DistrictData('광진구', '수', '한강변·자양·건대', '🌊', '한강 조망 우수'),
    _DistrictData('동작구', '수', '반포·흑석 한강변', '🏞️', '한강 접근성 최고'),
    _DistrictData('강남구(한강)', '수', '압구정·청담 한강뷰', '🌉', '최고급 수변 라이프'),
    _DistrictData('종로구', '수', '청계천·경복궁 수계', '💦', '역사적 수기 흐름'),
  ];

  // ─── 점수 계산 ────────────────────────────────────

  int _districtScore(_DistrictData d) {
    final myMain = widget.result.mainOehaeng;
    final myWeak = widget.result.weakOehaeng;
    // 보완 오행 (약한 오행을 보완하는 것)
    final supplement = SajuCalculator.saeng[myWeak] ?? '';

    int score = 50;
    if (d.oehaeng == myMain) score += 25; // 주 오행 일치
    else if (d.oehaeng == supplement) score += 20; // 보완 오행
    else if (SajuCalculator.saeng[myMain] == d.oehaeng) score += 15;
    else if (SajuCalculator.geuk[myMain] == d.oehaeng) score -= 10;

    return score.clamp(25, 98);
  }

  List<_DistrictData> get _filtered {
    if (_selectedFilter == '전체') return _districts;
    final oe = _selectedFilter.replaceAll(RegExp(r'\(.+\)'), '').trim();
    return _districts.where((d) => d.oehaeng == oe).toList();
  }

  Color _oeColor(String oe) {
    switch (oe) {
      case '목': return AppColors.mokColor;
      case '화': return AppColors.hwaColor;
      case '토': return AppColors.toColor;
      case '금': return AppColors.geumColor;
      case '수': return AppColors.suColor;
      default: return AppColors.textSecondary;
    }
  }

  // ─── UI ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sorted = [..._filtered]
      ..sort((a, b) => _districtScore(b).compareTo(_districtScore(a)));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('입지 히트맵',
              style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 3)),
        ),
      ),
      body: Column(children: [
        _buildProfileChip(),
        _buildFilterBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              _buildHeatGrid(sorted),
              const SizedBox(height: 14),
              if (_selectedDistrict != null)
                _buildDetailCard(_selectedDistrict!).animate().fadeIn(duration: 250.ms),
              const SizedBox(height: 10),
              _buildOehaengGuide(),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildProfileChip() {
    final oe = widget.result.mainOehaeng;
    final color = _oeColor(oe);
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        OehaengBadge(oe),
        const SizedBox(width: 10),
        Text('${widget.profile.name}님의 주 오행: ',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text('$oe(${_oeHanja(oe)})',
            style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
        const Spacer(),
        Text('보완 오행: ',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(widget.result.weakOehaeng,
            style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 12,
                color: _oeColor(widget.result.weakOehaeng))),
      ]),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 38,
      color: AppColors.cardBg2,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final f = _filters[i];
          final isActive = _selectedFilter == f;
          final oe = f == '전체' ? '' : f.replaceAll(RegExp(r'\(.+\)'), '').trim();
          final color = oe.isEmpty ? AppColors.accent : _oeColor(oe);
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? color : AppColors.divider,
                  width: isActive ? 1.2 : 0.5,
                ),
              ),
              child: Text(f,
                  style: TextStyle(
                      fontSize: 11,
                      color: isActive ? color : AppColors.textSecondary,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeatGrid(List<_DistrictData> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 1.3, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final d = items[i];
        final score = _districtScore(d);
        final oeColor = _oeColor(d.oehaeng);
        final heat = score / 100;
        final isSelected = _selectedDistrict?.data.name == d.name;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDistrict = _selectedDistrict?.data.name == d.name
                ? null
                : _DistrictDetail(data: d, score: score);
          }),
          child: Container(
            decoration: BoxDecoration(
              color: oeColor.withOpacity(0.05 + heat * 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? oeColor
                    : oeColor.withOpacity(0.3 + heat * 0.3),
                width: isSelected ? 1.8 : 0.8,
              ),
              boxShadow: score >= 75
                  ? [BoxShadow(color: oeColor.withOpacity(0.25), blurRadius: 8)]
                  : null,
            ),
            child: Stack(children: [
              Positioned(
                top: 4, right: 5,
                child: Text('$score',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: oeColor)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      d.name.replaceAll('(한강)', ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: oeColor),
                    ),
                    Text(d.oehaeng,
                        style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 8,
                            color: oeColor.withOpacity(0.7))),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(_DistrictDetail detail) {
    final d = detail.data;
    final oeColor = _oeColor(d.oehaeng);
    final score = detail.score;
    final scoreColor = score >= 80 ? const Color(0xFFCC3300)
        : score >= 65 ? AppColors.accent
        : score >= 50 ? AppColors.mokColor
        : AppColors.textSecondary;

    return TraditionalCard(
      borderColor: oeColor.withOpacity(0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(d.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text(d.name,
                  style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            Text('${d.oehaeng}(${_oeHanja(d.oehaeng)}) 기운  ·  ${d.keyword}',
                style: TextStyle(fontSize: 11, color: oeColor)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: scoreColor.withOpacity(0.4)),
            ),
            child: Text('$score점',
                style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    color: scoreColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const SizedBox(width: 5),
          Expanded(child: KoreanProgressBar(value: score / 100, color: scoreColor, height: 8)),
        ]),
        const SizedBox(height: 10),
        Text(d.description,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.6)),
        const SizedBox(height: 8),
        Text(_compatAdvice(d.oehaeng, score),
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5)),
      ]),
    );
  }

  String _compatAdvice(String distOe, int score) {
    final myOe = widget.result.mainOehaeng;
    if (distOe == myOe) return '✅ 귀하의 주 오행($myOe)과 일치 — 에너지가 강하게 시너지를 냅니다.';
    if (SajuCalculator.saeng[myOe] == distOe) return '⭐ 귀하의 오행을 생조(生助)하는 지역 — 성장·발전 기운이 있습니다.';
    if (SajuCalculator.saeng[widget.result.weakOehaeng] == distOe) return '🔷 약한 오행(${ widget.result.weakOehaeng})을 보완 — 결핍을 채워주는 균형 있는 지역입니다.';
    if (SajuCalculator.geuk[myOe] == distOe) return '⚠️ 주 오행과 상극 관계 — 장기 거주보다 단기 활용이 적합합니다.';
    return '🔹 중립적인 기운 — 입주 후 인테리어로 운세를 조율할 수 있습니다.';
  }

  Widget _buildOehaengGuide() {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '오행별 입지 특성 가이드',
          subtitle: '서울 자치구 오행 분류 기준',
          showDivider: false,
        ),
        const SizedBox(height: 10),
        ...[
          ('목(木) 🌳', '숲세권, 공원, 자연녹지 — 건강·성장 기운. 가족 주거에 적합.'),
          ('화(火) 🔥', '학군지, 번화가, 남향 — 활발한 기운. 자녀 교육·사회활동에 유리.'),
          ('토(土) 🏙️', '평지, 신도시, 균형 — 안정·중심 기운. 장기 거주·자산 보전에 적합.'),
          ('금(金) 💰', '금융가, 산업단지, 고층 — 재물·수익 기운. 투자·임대 수익에 유리.'),
          ('수(水) 💧', '한강변, 수변공원 — 유연·흐름 기운. 조망권·힐링 거주에 최적.'),
        ].map((t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.$1,
                style: const TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.3)),
            const SizedBox(width: 6),
            Expanded(child: Text(t.$2,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5))),
          ]),
        )),
      ]),
    );
  }

  String _oeHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}

// ─── 데이터 클래스 ──────────────────────────────

class _DistrictData {
  final String name;
  final String oehaeng;
  final String keyword;
  final String emoji;
  final String description;

  const _DistrictData(
      this.name, this.oehaeng, this.keyword, this.emoji, this.description);
}

class _DistrictDetail {
  final _DistrictData data;
  final int score;
  const _DistrictDetail({required this.data, required this.score});
}
