import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

class TimingScreen extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;

  const TimingScreen({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('賣買 타이밍',
            style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 18, color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
          _buildInfoCard().animate().fadeIn(),
          const SizedBox(height: 10),
          _buildThisYearCard(currentYear).animate(delay: 80.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 10),
          _buildYearlyChart().animate(delay: 160.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 10),
          _buildDaeWunStrategy().animate(delay: 240.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 10),
          _buildMonthlyTiming().animate(delay: 320.ms).fadeIn().slideY(begin: 0.1),
        ],
      ),
    );
  }

  // ─── 인포 카드 ──────────────────────────────────

  Widget _buildInfoCard() {
    final oe = result.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);
    return TraditionalCard(
      borderColor: color.withOpacity(0.4),
      child: Row(children: [
        OehaengBadge(oe, large: true),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text('${profile.name}님의 부동산 타이밍',
                style: const TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 0.5,
                )),
            ),
            const SizedBox(height: 3),
            Text(
              '$oe(${_oeHanja(oe)}) 기운  ·  ${result.propertyInfo['timing']} 매수 유리',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        )),
      ]),
    );
  }

  // ─── 올해 운세 카드 ─────────────────────────────

  Widget _buildThisYearCard(int year) {
    final score = result.investmentScore;
    final color = getScoreColor(score);
    final currentDw = result.currentDaeWun(year, profile.birthDate.year);

    return TraditionalCard(
      doubleBorder: true,
      borderColor: color.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          KoreanSectionTitle(
            title: '$year년 올해 운세',
            subtitle: '세운(歲運) 기준 분석',
            showDivider: false,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(getScoreKorean(score), style: TextStyle(
              fontFamily: 'NotoSerifKR',
              color: color, fontSize: 11, fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            )),
          ),
        ]),
        Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(gradient: LinearGradient(
            colors: [color.withOpacity(0.5), Colors.transparent]))),

        // 점수 바
        Row(children: [
          const Text('투자 점수', style: TextStyle(
            fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.3)),
          const SizedBox(width: 10),
          Expanded(child: KoreanProgressBar(value: score / 100, color: color, height: 10)),
          const SizedBox(width: 8),
          Text('$score점', style: TextStyle(
            fontFamily: 'NotoSerifKR',
            color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),

        const SizedBox(height: 12),

        // 매수/매도 박스
        Row(children: [
          Expanded(child: _actionBox('買', '매수', _getBuyAdvice(score),
            score >= 50 ? AppColors.mokColor : AppColors.toColor)),
          const SizedBox(width: 8),
          Expanded(child: _actionBox('賣', '매도', _getSellAdvice(score),
            score < 50 ? AppColors.hwaColor : AppColors.textSecondary)),
        ]),

        if (currentDw != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Expanded(child: Text(currentDw.propertyTip,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.5))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _actionBox(String hanja, String label, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(hanja, style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 20, fontWeight: FontWeight.bold, color: color,
          shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 6)],
        )),
        Text(label, style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(desc, textAlign: TextAlign.center, style: const TextStyle(
          fontSize: 10, color: AppColors.textSecondary, height: 1.4)),
      ]),
    );
  }

  // ─── 세운 차트 ──────────────────────────────────

  Widget _buildYearlyChart() {
    final seWunList = result.seWunList;

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '세운(歲運) 연도별 분석',
          subtitle: '일간 기준 십성·지지 관계 종합',
        ),
        const SizedBox(height: 12),
        ...seWunList.map((sw) {
          final score = sw.investmentScore;
          final color = getScoreColor(score);
          final oeColor = AppColors.getOehaengColor(sw.oehaeng);
          final isNow = sw.year == DateTime.now().year;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(width: 54, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${sw.year}', style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 12,
                    color: isNow ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                  )),
                  Text(sw.ganJiStr, style: TextStyle(
                    fontFamily: 'NotoSerifKR', fontSize: 10, color: oeColor)),
                ],
              )),
              Expanded(child: KoreanProgressBar(
                value: score / 100,
                color: isNow ? AppColors.accent : color,
                height: isNow ? 12 : 8,
              )),
              const SizedBox(width: 6),
              SizedBox(width: 28, child: Text('$score', style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold))),
              SizedBox(width: 30, child: Text(sw.sipSeong.name,
                style: const TextStyle(fontSize: 9, color: AppColors.textSecondary))),
            ]),
          );
        }),
      ]),
    );
  }

  // ─── 대운 전략 ──────────────────────────────────

  Widget _buildDaeWunStrategy() {
    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '대운별 부동산 전략 (大運)',
          subtitle: '10년 단위 운세 흐름',
        ),
        const SizedBox(height: 12),
        ...result.daeWunList.take(4).map((dw) {
          final color = AppColors.getOehaengColor(dw.oehaeng);
          final isCurrent = DateTime.now().year >= dw.year &&
              DateTime.now().year < dw.year + 10;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: isCurrent ? color.withOpacity(0.08) : AppColors.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCurrent ? color.withOpacity(0.5) : AppColors.divider,
                width: isCurrent ? 1.2 : 0.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 40, height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withOpacity(0.35)),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dw.cheongan, style: TextStyle(
                    fontFamily: 'NotoSerifKR', fontSize: 14,
                    fontWeight: FontWeight.bold, color: color)),
                  Container(height: 0.5, color: color.withOpacity(0.3),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                  Text(dw.jiji, style: const TextStyle(
                    fontFamily: 'NotoSerifKR', fontSize: 14,
                    fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ]),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${dw.age}~${dw.endAge}세  ${dw.year}~${dw.year+9}년',
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrent ? color : AppColors.textSecondary,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      letterSpacing: 0.3,
                    )),
                  if (isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                      ),
                      child: const Text('현재', style: TextStyle(
                        fontSize: 8, color: AppColors.accent,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ],
                ]),
                const SizedBox(height: 3),
                Text(dw.propertyTip, style: const TextStyle(
                  fontSize: 11, color: AppColors.textPrimary, height: 1.4)),
              ])),
            ]),
          );
        }),
      ]),
    );
  }

  // ─── 월별 타이밍 ────────────────────────────────

  Widget _buildMonthlyTiming() {
    final info = result.propertyInfo;
    final goodMonths = _getGoodMonths();
    final badMonths = _getBadMonths();

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KoreanSectionTitle(
          title: '월별 타이밍 가이드',
          subtitle: '${result.mainOehaeng} 오행 기준  ·  최적: ${info['timing']}',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: List.generate(12, (i) {
            final month = i + 1;
            final isGood = goodMonths.contains(month);
            final isBad = badMonths.contains(month);
            final isNow = month == DateTime.now().month;
            final color = isGood ? AppColors.mokColor
                : isBad ? AppColors.hwaColor
                : AppColors.textSecondary;
            return Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isGood ? AppColors.mokColor.withOpacity(0.1)
                    : isBad ? AppColors.hwaColor.withOpacity(0.08)
                    : AppColors.surface.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isNow ? AppColors.accent
                      : isGood ? AppColors.mokColor.withOpacity(0.4)
                      : isBad ? AppColors.hwaColor.withOpacity(0.3)
                      : AppColors.divider,
                  width: isNow ? 1.5 : 0.8,
                ),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$month月', style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(
                  isGood ? '추천' : isBad ? '주의' : '보통',
                  style: TextStyle(fontSize: 8, color: color.withOpacity(0.8)),
                ),
              ]),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(children: [
          _legendDot(AppColors.mokColor), const SizedBox(width: 4),
          const Text('추천', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          _legendDot(AppColors.hwaColor), const SizedBox(width: 4),
          const Text('주의', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          _legendDot(AppColors.divider), const SizedBox(width: 4),
          const Text('보통', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _legendDot(Color color) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  // ─── 헬퍼 ───────────────────────────────────────

  List<int> _getGoodMonths() {
    const m = {
      '목': [2, 3, 11, 12], '화': [3, 4, 5, 6], '토': [3, 6, 9, 12],
      '금': [7, 8, 9, 10],  '수': [9, 10, 11, 12],
    };
    return m[result.mainOehaeng] ?? [3, 9];
  }

  List<int> _getBadMonths() {
    const m = {
      '목': [7, 8, 9], '화': [10, 11, 12], '토': [2, 3, 4],
      '금': [4, 5, 6],  '수': [6, 7, 8],
    };
    return m[result.mainOehaeng] ?? [6, 12];
  }

  String _getBuyAdvice(int score) {
    if (score >= 70) return '적극 매수\n추천';
    if (score >= 50) return '조건부\n매수 가능';
    return '신중 검토\n후 결정';
  }

  String _getSellAdvice(int score) {
    if (score < 40) return '매도 후\n현금 확보';
    if (score < 60) return '장기 보유\n고려';
    return '보유 유지\n추천';
  }

  String _oeHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}
