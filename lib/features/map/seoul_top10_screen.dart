// 서울 TOP 10 — 나와 가장 맞는 자치구 랭킹
// 25개 자치구를 사주 궁합 점수순 정렬 → 상위 10개 표시 + 공유

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/chart_widgets.dart';
import '../../core/saju/district_data.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

class SeoulTop10Screen extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;

  const SeoulTop10Screen({super.key, required this.result, required this.profile});

  List<MapEntry<DistrictData, int>> _ranked() {
    return seoulDistricts
        .map((d) => MapEntry(d, districtScore(d, result.mainOehaeng, result.weakOehaeng)))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  Widget build(BuildContext context) {
    final ranked = _ranked();
    final top10 = ranked.take(10).toList();
    final myChar = getCharacter(result.mainOehaeng);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('서울 TOP 10',
            style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 18, color: Colors.white, letterSpacing: 3)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () => _share(top10),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _buildMyCharacterCard(myChar),
          const SizedBox(height: 14),
          _buildSectionTitle('나와 맞는 서울 TOP 10'),
          const SizedBox(height: 10),
          ...top10.asMap().entries.map((e) =>
            _buildRankCard(context, e.key + 1, e.value.key, e.value.value)
              .animate(delay: Duration(milliseconds: e.key * 60))
              .fadeIn().slideX(begin: 0.05),
          ),
        ],
      ),
    );
  }

  // ── 내 캐릭터 카드 ──────────────────────────────────

  Widget _buildMyCharacterCard(DistrictCharacter char) {
    return TraditionalCard(
      borderColor: char.color.withOpacity(0.4),
      child: Row(children: [
        // 캐릭터 원형 뱃지
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: char.color.withOpacity(0.1),
            border: Border.all(color: char.color.withOpacity(0.5), width: 1.5),
            boxShadow: [BoxShadow(
              color: char.color.withOpacity(0.2),
              blurRadius: 12, spreadRadius: 2,
            )],
          ),
          child: Center(child: Text(char.emoji,
            style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(char.tagline, style: TextStyle(
            fontSize: 10, color: char.color.withOpacity(0.8), letterSpacing: 1)),
          const SizedBox(height: 2),
          Row(children: [
            Text(profile.name, style: const TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 15,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Text('님은  ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text(char.type, style: TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 15,
              fontWeight: FontWeight.bold, color: char.color)),
          ]),
          const SizedBox(height: 4),
          Text(char.desc, style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
        ])),
      ]),
    );
  }

  // ── 순위 카드 ───────────────────────────────────────

  Widget _buildRankCard(BuildContext ctx, int rank, DistrictData d, int score) {
    final char = getCharacter(d.oehaeng);
    final color = AppColors.getOehaengColor(d.oehaeng);
    final isTop3 = rank <= 3;
    final medal = ['🥇', '🥈', '🥉'];

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showDistrictDetail(ctx, rank, d, score, char);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isTop3
            ? color.withOpacity(0.07)
            : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTop3 ? color.withOpacity(0.3) : AppColors.divider,
            width: isTop3 ? 1 : 0.5,
          ),
        ),
        child: Row(children: [
          // 순위
          SizedBox(width: 36, child: Text(
            isTop3 ? medal[rank - 1] : '$rank',
            style: TextStyle(
              fontSize: isTop3 ? 20 : 14,
              fontWeight: FontWeight.bold,
              color: isTop3 ? null : AppColors.textMuted),
            textAlign: TextAlign.center,
          )),
          const SizedBox(width: 8),
          // 이모지 + 오행
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(child: Text(d.emoji,
              style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 10),
          // 지역명 + 캐릭터
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(d.name, style: TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 14,
                fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
                color: isTop3 ? color : AppColors.textPrimary)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text('${char.emoji} ${char.type}', style: TextStyle(
                  fontSize: 9, color: color, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(d.landmark, style: const TextStyle(
              fontSize: 10, color: AppColors.textSecondary)),
          ])),
          // 점수
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$score', style: AppFonts.score(22,
              color: getScoreColor(score))),
            Text(getScoreKorean(score).split(' ').first,
              style: TextStyle(fontSize: 9,
                color: getScoreColor(score).withOpacity(0.8))),
          ]),
        ]),
      ),
    );
  }

  // ── 상세 바텀시트 ────────────────────────────────────

  void _showDistrictDetail(BuildContext ctx, int rank, DistrictData d, int score, DistrictCharacter char) {
    final color = AppColors.getOehaengColor(d.oehaeng);
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: AppColors.divider),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 3,
            decoration: BoxDecoration(color: AppColors.divider,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(children: [
            Text(d.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 20,
                fontWeight: FontWeight.bold, color: color)),
              Text('${char.emoji} ${char.type} • ${d.oehaeng}(${_oeHanja(d.oehaeng)}) 기운',
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$score', style: AppFonts.score(32, color: getScoreColor(score))),
              Text('TOP $rank', style: TextStyle(
                fontSize: 10, color: AppColors.accent.withOpacity(0.7))),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(height: 0.5, color: AppColors.divider),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📍 ${d.landmark}', style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(compatComment(score, d.oehaeng, result.mainOehaeng),
                style: const TextStyle(fontSize: 12,
                  color: AppColors.textPrimary, height: 1.5)),
              const SizedBox(height: 6),
              Text(char.desc, style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── 공유 ────────────────────────────────────────────

  void _share(List<MapEntry<DistrictData, int>> top10) {
    final char = getCharacter(result.mainOehaeng);
    final buf = StringBuffer();
    buf.writeln('🏠 ${profile.name}님의 서울 궁합 TOP 10');
    buf.writeln('${char.emoji} 유형: ${char.type} (${result.mainOehaeng} 기운)');
    buf.writeln('─' * 24);
    for (int i = 0; i < top10.length; i++) {
      final d = top10[i].key;
      final s = top10[i].value;
      buf.writeln('${i + 1}위  ${d.emoji} ${d.name}  $s점');
    }
    buf.writeln();
    buf.writeln('📱 부동산 사주 앱에서 생성됨');
    Share.share(buf.toString(), subject: '${profile.name}님의 서울 궁합 TOP 10');
  }

  Widget _buildSectionTitle(String title) =>
    KoreanSectionTitle(title: title, icon: '🏆', showDivider: true);

  String _oeHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}
