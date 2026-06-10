// fortune_map_screen.dart — 서울 자치구 오행 히트맵
// 목록(그리드) ↔ 지도(flutter_map) 토글
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import 'district_map_data.dart';
import 'real_map_view.dart';

class FortuneMapScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;
  const FortuneMapScreen({super.key, required this.result, required this.profile});

  @override
  State<FortuneMapScreen> createState() => _FortuneMapScreenState();
}

class _FortuneMapScreenState extends State<FortuneMapScreen> {
  String _selectedFilter = '전체';
  DistrictData? _selectedDistrict;
  bool _mapMode = false; // false=목록, true=지도

  static const _filters = ['전체', '목(木)', '화(火)', '토(土)', '금(金)', '수(水)'];

  int _score(DistrictData d) =>
      calcDistrictScore(d, widget.result.mainOehaeng, widget.result.weakOehaeng);

  List<DistrictData> get _filtered {
    if (_selectedFilter == '전체') return seoulDistricts;
    final oe = _selectedFilter.replaceAll(RegExp(r'\(.+\)'), '').trim();
    return seoulDistricts.where((d) => d.oehaeng == oe).toList();
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

  @override
  Widget build(BuildContext context) {
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
        actions: [
          // 목록 ↔ 지도 토글
          Container(
            margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _ModeTab(label: '목록', icon: Icons.grid_view_rounded,
                  active: !_mapMode, onTap: () => setState(() => _mapMode = false)),
              _ModeTab(label: '지도', icon: Icons.map_rounded,
                  active: _mapMode, onTap: () => setState(() => _mapMode = true)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        _buildProfileChip(),
        if (!_mapMode) _buildFilterBar(),
        Expanded(
          child: _mapMode
              ? RealMapView(result: widget.result, profile: widget.profile)
              : _buildGridView(),
        ),
      ]),
    );
  }

  // ─── 프로필 칩 ─────────────────────────────────────
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
        Text('보완: ', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        Text(widget.result.weakOehaeng,
            style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 12,
                color: _oeColor(widget.result.weakOehaeng))),
      ]),
    );
  }

  // ─── 필터 바 ───────────────────────────────────────
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

  // ─── 그리드 뷰 ─────────────────────────────────────
  Widget _buildGridView() {
    final sorted = [..._filtered]
      ..sort((a, b) => _score(b).compareTo(_score(a)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        _buildHeatGrid(sorted),
        const SizedBox(height: 14),
        if (_selectedDistrict != null)
          _buildDetailCard(_selectedDistrict!).animate().fadeIn(duration: 250.ms),
        const SizedBox(height: 10),
        _buildOehaengGuide(),
      ],
    );
  }

  Widget _buildHeatGrid(List<DistrictData> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 1.3, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final d = items[i];
        final score = _score(d);
        final oeColor = _oeColor(d.oehaeng);
        final heat = score / 100;
        final isSelected = _selectedDistrict?.name == d.name;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedDistrict = _selectedDistrict?.name == d.name ? null : d;
          }),
          child: Container(
            decoration: BoxDecoration(
              color: oeColor.withOpacity(0.05 + heat * 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? oeColor : oeColor.withOpacity(0.3 + heat * 0.3),
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
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: oeColor)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      d.name.replaceAll('·청담', '').replaceAll('압구정', '압구정'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: oeColor),
                    ),
                    Text(d.oehaeng,
                        style: TextStyle(
                            fontFamily: 'NotoSerifKR', fontSize: 8,
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

  Widget _buildDetailCard(DistrictData d) {
    final oeColor = _oeColor(d.oehaeng);
    final score = _score(d);
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
                      fontFamily: 'NotoSerifKR', fontSize: 15,
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Text('${d.oehaeng}(${_oeHanja(d.oehaeng)}) · ${d.keyword}',
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
                    fontFamily: 'NotoSerifKR', color: scoreColor,
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
        KoreanProgressBar(value: score / 100, color: scoreColor, height: 8),
        const SizedBox(height: 10),
        Text(d.description,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.6)),
        const SizedBox(height: 8),
        Text(_compatAdvice(d.oehaeng, score),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
      ]),
    );
  }

  String _compatAdvice(String distOe, int score) {
    final myOe = widget.result.mainOehaeng;
    if (distOe == myOe) return '✅ 주 오행($myOe)과 일치 — 에너지가 강하게 시너지를 냅니다.';
    if (SajuCalculator.saeng[myOe] == distOe) return '⭐ 귀하의 오행을 생조(生助) — 성장·발전 기운이 있습니다.';
    if (SajuCalculator.saeng[widget.result.weakOehaeng] == distOe)
      return '🔷 약한 오행(${widget.result.weakOehaeng})을 보완 — 균형 있는 지역입니다.';
    if (SajuCalculator.geuk[myOe] == distOe) return '⚠️ 주 오행과 상극 관계 — 장기 거주보다 단기 활용이 적합합니다.';
    return '🔹 중립적인 기운 — 인테리어로 운세를 조율할 수 있습니다.';
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
                    fontFamily: 'NotoSerifKR', fontSize: 11,
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                    letterSpacing: 0.3)),
            const SizedBox(width: 6),
            Expanded(child: Text(t.$2,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.5))),
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

// ─── 모드 탭 버튼 ──────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label, required this.icon,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? AppColors.accent : AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ]),
      ),
    );
  }
}
