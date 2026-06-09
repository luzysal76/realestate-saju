// 이사 시뮬레이터 — "성수동으로 가면 어떨까?"
// 동네 검색 → 즉시 궁합 점수 + 동네 캐릭터 카드

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/chart_widgets.dart';
import '../../core/saju/district_data.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

class MovingSimulatorScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;

  const MovingSimulatorScreen({
    super.key, required this.result, required this.profile});

  @override
  State<MovingSimulatorScreen> createState() => _MovingSimulatorScreenState();
}

class _MovingSimulatorScreenState extends State<MovingSimulatorScreen> {
  final _controller = TextEditingController();
  String _query = '';
  DistrictData? _selected;

  List<DistrictData> get _results {
    if (_query.trim().isEmpty) return [];
    final q = _query.trim().toLowerCase();
    return seoulDistricts
        .where((d) =>
            d.name.toLowerCase().contains(q) ||
            d.landmark.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final sa = districtScore(a, widget.result.mainOehaeng, widget.result.weakOehaeng);
        final sb = districtScore(b, widget.result.mainOehaeng, widget.result.weakOehaeng);
        return sb.compareTo(sa);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('이사 시뮬레이터',
            style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 18, color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: Column(children: [
        _buildSearchBar(),
        Expanded(child: _selected != null
          ? _buildResultView()
          : _query.isEmpty
            ? _buildGuide()
            : _buildSearchResults()),
      ]),
    );
  }

  // ── 검색창 ───────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('어느 동네로 이사하면 어떨까요?',
          style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 13,
            color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          autofocus: false,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: '예) 성수동, 강남구, 한강변...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 20),
            suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                  onPressed: () {
                    _controller.clear();
                    setState(() { _query = ''; _selected = null; });
                  })
              : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1),
            ),
          ),
          onChanged: (v) => setState(() { _query = v; _selected = null; }),
        ),
      ]),
    );
  }

  // ── 안내 화면 (빈 상태) ──────────────────────────────

  Widget _buildGuide() {
    final char = getCharacter(widget.result.mainOehaeng);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        TraditionalCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          KoreanSectionTitle(title: '${widget.profile.name}님의 동네 유형', showDivider: false),
          const SizedBox(height: 12),
          Row(children: [
            Text(char.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${char.type} (${widget.result.mainOehaeng} 기운)',
                style: TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 16,
                  fontWeight: FontWeight.bold, color: char.color)),
              const SizedBox(height: 4),
              Text(char.tagline, style: TextStyle(
                fontSize: 11, color: char.color.withOpacity(0.8))),
              const SizedBox(height: 6),
              Text(char.desc, style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
            ])),
          ]),
        ])).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 14),
        const KoreanSectionTitle(title: '검색 예시', icon: '💡'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          '성수동', '강남구', '마포구', '여의도', '한강변', '잠실',
        ].map((hint) => GestureDetector(
          onTap: () {
            _controller.text = hint;
            setState(() { _query = hint; _selected = null; });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
            child: Text(hint, style: const TextStyle(
              fontSize: 12, color: AppColors.textPrimary)),
          ),
        )).toList()),
      ],
    );
  }

  // ── 검색 결과 목록 ───────────────────────────────────

  Widget _buildSearchResults() {
    final results = _results;
    if (results.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔍', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        const Text('검색 결과가 없습니다',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        const SizedBox(height: 4),
        Text('구 이름이나 랜드마크로 검색해보세요',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: results.length,
      itemBuilder: (ctx, i) {
        final d = results[i];
        final score = districtScore(d,
          widget.result.mainOehaeng, widget.result.weakOehaeng);
        final char = getCharacter(d.oehaeng);
        final color = AppColors.getOehaengColor(d.oehaeng);
        return GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _selected = d);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(children: [
              Text(d.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: const TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 14,
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${char.emoji} ${char.type} • ${d.landmark}',
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
              ])),
              Text('$score', style: AppFonts.score(22, color: getScoreColor(score))),
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
            ]),
          ).animate(delay: Duration(milliseconds: i * 40)).fadeIn().slideX(begin: 0.05),
        );
      },
    );
  }

  // ── 상세 결과 뷰 ────────────────────────────────────

  Widget _buildResultView() {
    final d = _selected!;
    final score = districtScore(d, widget.result.mainOehaeng, widget.result.weakOehaeng);
    final char = getCharacter(d.oehaeng);
    final color = AppColors.getOehaengColor(d.oehaeng);
    final comment = compatComment(score, d.oehaeng, widget.result.mainOehaeng);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // 결과 타이틀 카드
        TraditionalCard(
          borderColor: color.withOpacity(0.4),
          child: Column(children: [
            Row(children: [
              Text(d.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name, style: TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 20,
                  fontWeight: FontWeight.bold, color: color)),
                Text('${char.emoji} ${char.type} 지역',
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
                Text(d.landmark, style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('$score', style: AppFonts.score(36, color: getScoreColor(score))),
                Text(getScoreKorean(score),
                  style: TextStyle(fontSize: 10, color: getScoreColor(score).withOpacity(0.8))),
              ]),
            ]),
            const SizedBox(height: 14),
            // 진행 바
            KoreanProgressBar(
              value: score / 100, color: getScoreColor(score), height: 8),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Text(comment, style: const TextStyle(
                fontSize: 13, color: AppColors.textPrimary, height: 1.6)),
            ),
          ]),
        ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.96, 0.96)),

        const SizedBox(height: 12),

        // 동네 캐릭터 vs 내 캐릭터 비교
        _buildCompatComparison(char, color),

        const SizedBox(height: 12),

        // 다시 검색 버튼
        GestureDetector(
          onTap: () => setState(() { _selected = null; _query = ''; _controller.clear(); }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.search, color: AppColors.accent, size: 18),
              SizedBox(width: 8),
              Text('다른 동네 검색하기',
                style: TextStyle(color: AppColors.accent, fontSize: 14,
                  fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompatComparison(DistrictCharacter distChar, Color distColor) {
    final myChar = getCharacter(widget.result.mainOehaeng);
    final myColor = AppColors.getOehaengColor(widget.result.mainOehaeng);
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '동네 기운 vs 내 기운', showDivider: false),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _charChip(myChar, myColor, '나')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(children: [
              const Text('⚡', style: TextStyle(fontSize: 18)),
              Text('궁합', style: const TextStyle(
                fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
            ]),
          ),
          Expanded(child: _charChip(distChar, distColor, '동네')),
        ]),
      ]),
    );
  }

  Widget _charChip(DistrictCharacter char, Color color, String label) =>
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(char.emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(char.type, style: TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 12,
          fontWeight: FontWeight.bold, color: color)),
        Text(char.tagline, style: TextStyle(
          fontSize: 9, color: color.withOpacity(0.7)),
          textAlign: TextAlign.center),
      ]),
    );
}
