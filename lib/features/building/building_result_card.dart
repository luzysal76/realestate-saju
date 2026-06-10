// building_result_card.dart — 건물 궁합 결과 카드 위젯
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';

// ─── 결과 모델 ──────────────────────────────────────────

class BuildingCompatResult {
  final String bldGanJi;
  final String sipseong;
  final String cgRel;
  final String jiRel;
  final int score;
  final String title;
  final String type;
  final String advice;

  const BuildingCompatResult({
    required this.bldGanJi,
    required this.sipseong,
    required this.cgRel,
    required this.jiRel,
    required this.score,
    required this.title,
    required this.type,
    required this.advice,
  });
}

// ─── 결과 카드 위젯 ─────────────────────────────────────

class BuildingResultCard extends StatelessWidget {
  final BuildingCompatResult result;
  final String ilgan;
  final String ilji;

  const BuildingResultCard({
    super.key,
    required this.result,
    required this.ilgan,
    required this.ilji,
  });

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(result.score);
    return TraditionalCard(
      doubleBorder: true,
      borderColor: color.withOpacity(0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text(result.title,
                  style: const TextStyle(
                      fontFamily: 'NotoSerifKR', fontSize: 15,
                      fontWeight: FontWeight.bold, color: Colors.white,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 3),
            Text(result.type,
                style: TextStyle(fontSize: 12, color: color,
                    fontWeight: FontWeight.bold)),
          ])),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10)],
            ),
            child: Center(child: Text('${result.score}',
                style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 22,
                    fontWeight: FontWeight.w900, color: color))),
          ),
        ]),
        const SizedBox(height: 12),
        Container(height: 1,
            decoration: BoxDecoration(gradient: LinearGradient(
                colors: [color.withOpacity(0.5), Colors.transparent]))),
        const SizedBox(height: 12),

        // 일주 vs 건물
        Row(children: [
          Expanded(child: _ganjiBox('나의 일주', '$ilgan$ilji', AppColors.accent)),
          const SizedBox(width: 10),
          Expanded(child: _ganjiBox('건물 년주', result.bldGanJi, color)),
        ]),
        const SizedBox(height: 10),

        // 관계 칩
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip(result.sipseong, color),
          _chip(result.cgRel, AppColors.accent.withOpacity(0.8)),
          _chip(result.jiRel, _jijiRelColor(result.jiRel)),
        ]),
        const SizedBox(height: 12),

        // 점수 바
        Row(children: [
          const Text('궁합 점수',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary,
                  letterSpacing: 0.3)),
          const SizedBox(width: 10),
          Expanded(child: KoreanProgressBar(
              value: result.score / 100, color: color, height: 10)),
          const SizedBox(width: 8),
          Text('${result.score}점',
              style: TextStyle(fontFamily: 'NotoSerifKR', color: color,
                  fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 14),

        // 기본 어드바이스
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.2), width: 0.8),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💬 ', style: TextStyle(fontSize: 13)),
            Expanded(child: Text(result.advice,
                style: const TextStyle(fontSize: 12,
                    color: AppColors.textPrimary, height: 1.65))),
          ]),
        ),
        const SizedBox(height: 10),
        _buildTipBox(result),
      ]),
    );
  }

  Widget _ganjiBox(String label, String ganji, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(ganji, style: TextStyle(fontFamily: 'NotoSerifKR',
            fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Text(text, style: TextStyle(fontSize: 10, color: color,
        fontWeight: FontWeight.bold)),
  );

  Widget _buildTipBox(BuildingCompatResult r) {
    final tips = <String>[];
    if (r.jiRel == '지지충(沖)') {
      tips.add('인테리어에 나무(木) 오행 색상(초록·청색)을 더하면 충기를 완화할 수 있습니다.');
    }
    if (r.score < 55) {
      tips.add('현관 방향에 좋아하는 오행의 소품을 배치해 비보(裨補)하면 운세가 향상됩니다.');
    }
    if (r.score >= 75) {
      tips.add('이 건물과 오래 함께 할수록 인연이 깊어지는 상생 궁합입니다. 장기 보유를 추천합니다.');
    }
    if (tips.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.cardBg2,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.divider.withOpacity(0.5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: tips.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡 ', style: TextStyle(fontSize: 11)),
              Expanded(child: Text(t, style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.5))),
            ]),
          )).toList()),
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFFCC3300);
    if (score >= 65) return AppColors.accent;
    if (score >= 50) return AppColors.mokColor;
    return AppColors.textSecondary;
  }

  Color _jijiRelColor(String rel) {
    if (rel.contains('합')) return AppColors.mokColor;
    if (rel.contains('충')) return AppColors.hwaColor;
    if (rel.contains('생')) return AppColors.suColor;
    return AppColors.textSecondary;
  }
}
