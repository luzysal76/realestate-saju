// 신살 분석 카드 위젯

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/shinsal.dart';

/// 대시보드용 신살 요약 카드
class ShinSalCard extends StatelessWidget {
  final ShinSalResult shinSal;

  const ShinSalCard({super.key, required this.shinSal});

  @override
  Widget build(BuildContext context) {
    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '신살 분석 (神煞)',
          subtitle: '부동산 관련 특수 기운 — 역마·도화·귀인·공망',
        ),
        const SizedBox(height: 12),

        // 삼재 경고 배너
        if (shinSal.isSamjaeYear) _buildSamjaeBanner(),

        // 공망 뱃지
        if (shinSal.gongmang.isNotEmpty) _buildGongmangRow(),

        const SizedBox(height: 8),

        // 신살 항목들 (간략 버전)
        ...shinSal.items
            .where((i) => i.name != '삼재 (올해)')
            .map((item) => _buildItemRow(item)),
      ]),
    );
  }

  // ─── 삼재 배너 ────────────────────────────────────

  Widget _buildSamjaeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.hwaColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.hwaColor.withOpacity(0.45)),
      ),
      child: Row(children: [
        const Text('🔺', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '올해는 삼재살(三災殺) 기간입니다.\n큰 부동산 투자·이사를 자제하고 수성(守成)에 집중하세요.',
            style: TextStyle(
              fontSize: 11, color: AppColors.hwaColor, height: 1.45),
          ),
        ),
      ]),
    );
  }

  // ─── 공망 행 ──────────────────────────────────────

  Widget _buildGongmangRow() {
    final gm = shinSal.gongmang;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Row(children: [
        const Text('⬜', style: TextStyle(fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('공망 (空亡)', style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 11, fontWeight: FontWeight.bold,
              color: AppColors.textPrimary, letterSpacing: 0.5,
            )),
            const SizedBox(height: 1),
            Text(
              '${gm.join("·")}년·월·일 = 계약·큰 결정은 피하세요',
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(gm.join('·'), style: const TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 12, fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          )),
        ),
      ]),
    );
  }

  // ─── 신살 항목 행 ─────────────────────────────────

  Widget _buildItemRow(ShinSalItem item) {
    final isLucky = item.type == ShinSalType.lucky;
    final isCaution = item.type == ShinSalType.caution;
    final color = isLucky ? AppColors.mokColor
        : isCaution ? AppColors.hwaColor
        : AppColors.toColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더 행
        Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 7),
          Text(item.name, style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 12, fontWeight: FontWeight.bold,
            color: color, letterSpacing: 0.5,
          )),
          const SizedBox(width: 4),
          Text('(${item.hanja})', style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 9, color: color.withOpacity(0.7),
          )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              isLucky ? '길신 ✨' : isCaution ? '주의 ⚠️' : '중립 ◎',
              style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ]),
        const SizedBox(height: 5),
        // 부동산 팁
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🏠 ', style: TextStyle(fontSize: 10)),
            Expanded(child: Text(item.realEstateTip, style: const TextStyle(
              fontSize: 10, color: AppColors.textPrimary, height: 1.5))),
          ]),
        ),
      ]),
    );
  }
}

/// 상세화면용 신살 탭 위젯
class ShinSalDetailTab extends StatelessWidget {
  final ShinSalResult shinSal;

  const ShinSalDetailTab({super.key, required this.shinSal});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // 안내
        TraditionalCard(
          child: const Text(
            '신살(神煞)은 사주의 특수 기운입니다. 년지(年支)와 일간(日干)을 기준으로 '
            '역마·도화·화개·천을귀인·삼재·공망을 분석하여 부동산 운세에 적용합니다.',
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 11, color: AppColors.textSecondary, height: 1.6),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 10),

        // 공망 상세 카드
        _buildGongmangCard().animate(delay: 60.ms).fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 8),

        // 삼재 카드
        if (shinSal.isSamjaeYear)
          _buildSamjaeCard().animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
        if (shinSal.isSamjaeYear) const SizedBox(height: 8),

        // 신살 상세
        ...shinSal.items.asMap().entries.map((e) =>
          _buildDetailCard(e.value)
            .animate(delay: Duration(milliseconds: 140 + e.key * 60))
            .fadeIn().slideY(begin: 0.1),
        ),
      ],
    );
  }

  Widget _buildGongmangCard() {
    final gm = shinSal.gongmang;
    return TraditionalCard(
      doubleBorder: true,
      borderColor: AppColors.divider,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '공망 (空亡)',
          subtitle: '비어있는 시기 — 계약·결정 회피',
        ),
        const SizedBox(height: 12),
        if (gm.isEmpty)
          const Text('공망 해당 없음 (길한 일주)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: gm.map((jj) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.divider.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
              ),
              child: Text(jj, style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 18, fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              )),
            )).toList()),
            const SizedBox(height: 10),
            _tipBox(
              '${gm.join("·")}년·월·일은 부동산 계약, 잔금 지급, 등기 등 큰 결정의 날을 피하세요. '
              '하지만 이사 짐을 옮기거나 집을 보러 다니는 날로는 활용 가능합니다.',
              Colors.grey,
            ),
          ]),
      ]),
    );
  }

  Widget _buildSamjaeCard() {
    return TraditionalCard(
      doubleBorder: true,
      borderColor: AppColors.hwaColor.withOpacity(0.4),
      bgColor: AppColors.hwaColor.withOpacity(0.05),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '삼재살 (三災殺) — 올해 해당',
          subtitle: '3년간 큰 결정 자제 권고',
        ),
        const SizedBox(height: 10),
        _tipBox(
          '삼재(三災)는 해(亥)·자(子)·축(丑)의 수재, 인(寅)·묘(卯)·진(辰)의 풍재, '
          '사(巳)·오(午)·미(未)의 화재를 상징하는 3년 주기 흉살입니다. '
          '이 기간에는 무리한 투자, 대규모 이사, 고액 계약을 피하고 '
          '기존 자산을 잘 지키는 수성(守成) 전략이 최선입니다.',
          AppColors.hwaColor,
        ),
      ]),
    );
  }

  Widget _buildDetailCard(ShinSalItem item) {
    final isLucky = item.type == ShinSalType.lucky;
    final isCaution = item.type == ShinSalType.caution;
    final color = isLucky ? AppColors.mokColor
        : isCaution ? AppColors.hwaColor
        : AppColors.toColor;

    return TraditionalCard(
      borderColor: color.withOpacity(0.35),
      bgColor: color.withOpacity(0.05),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.name, style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 15, fontWeight: FontWeight.bold,
              color: color, letterSpacing: 0.5,
            )),
            Text('${item.hanja}', style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 10, color: color.withOpacity(0.7),
            )),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color.withOpacity(0.35)),
            ),
            child: Text(item.typeLabel, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(item.desc, style: const TextStyle(
          fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        const SizedBox(height: 8),
        _tipBox(item.realEstateTip, color),
        if (item.activeJijis.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Text('활성 지지: ', style: TextStyle(
              fontSize: 10, color: AppColors.textSecondary)),
            ...item.activeJijis.map((jj) => Container(
              margin: const EdgeInsets.only(right: 5),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: color.withOpacity(0.35)),
              ),
              child: Text(jj, style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            )),
          ]),
        ],
      ]),
    );
  }

  Widget _tipBox(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🏠 ', style: TextStyle(fontSize: 11)),
        Expanded(child: Text(text, style: const TextStyle(
          fontSize: 11, color: AppColors.textPrimary, height: 1.55))),
      ]),
    );
  }
}
