// 프리미엄 결제 모달
// 혜택 체크리스트 + Gold CTA

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ─── 공개 진입점 ──────────────────────────────────────────

void showPremiumModal(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PremiumSheet(),
  );
}

// ─── 혜택 항목 정의 ──────────────────────────────────────

class _Benefit {
  final String emoji;
  final String title;
  final String desc;
  final bool isFree;

  const _Benefit({
    required this.emoji,
    required this.title,
    required this.desc,
    this.isFree = false,
  });
}

const _benefits = [
  _Benefit(
    emoji: '🏠',
    title: '기본 사주 분석',
    desc: '천간·지지·오행·십성 원국 분석',
    isFree: true,
  ),
  _Benefit(
    emoji: '📍',
    title: '서울 TOP 10 입지 랭킹',
    desc: '25개 자치구 사주 궁합 점수 순위',
    isFree: true,
  ),
  _Benefit(
    emoji: '🔮',
    title: 'AI 상세 매칭 리포트',
    desc: '동네·집 유형을 사주와 정밀 분석한 맞춤 리포트',
  ),
  _Benefit(
    emoji: '🌿',
    title: '풍수 인테리어 팁',
    desc: '오행별 색상·가구·소품 배치 가이드',
  ),
  _Benefit(
    emoji: '📅',
    title: '이사·계약 길일 캘린더',
    desc: '월간 일진 기반 최적 계약일 + 이사일 자동 추출',
  ),
  _Benefit(
    emoji: '🏗️',
    title: '건물 궁합 심층 분석',
    desc: '준공일 × 사주 천간합·지지합·생극 완전 분석',
  ),
  _Benefit(
    emoji: '👨‍👩‍👧',
    title: '가족 모드',
    desc: '다중 프로필로 가족 합산 운세·최적 동네 도출',
  ),
  _Benefit(
    emoji: '🗺️',
    title: '지도 히트맵',
    desc: 'Google Maps 기반 운세 점수 입지 히트맵',
  ),
];

// ─── 모달 시트 ────────────────────────────────────────────

class _PremiumSheet extends StatefulWidget {
  const _PremiumSheet();

  @override
  State<_PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<_PremiumSheet> {
  bool _monthly = true; // true = 월간, false = 연간

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: AppColors.divider, width: 0.5),
            ),
          ),
          child: Column(children: [
            // 드래그 핸들
            const SizedBox(height: 10),
            Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildPlanToggle(),
                  const SizedBox(height: 20),
                  _buildPriceCard(),
                  const SizedBox(height: 20),
                  _buildBenefitList(),
                  const SizedBox(height: 24),
                  _buildCTAButton(),
                  const SizedBox(height: 12),
                  _buildFooterNote(),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  // ── 헤더 ──────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(children: [
      // 금빛 아이콘 배지
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [AppColors.accentLight, AppColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20, spreadRadius: 4,
            ),
          ],
        ),
        child: const Center(
          child: Text('✨', style: TextStyle(fontSize: 28)),
        ),
      ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

      const SizedBox(height: 14),

      ShaderMask(
        shaderCallback: (b) => AppColors.goldGradient.createShader(b),
        child: const Text(
          '부동산 사주 프리미엄',
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 22, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 1.5,
          ),
        ),
      ).animate(delay: 100.ms).fadeIn(),

      const SizedBox(height: 6),

      const Text(
        '사주가 이끄는 완벽한 부동산 결정',
        style: TextStyle(
          fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.3,
        ),
      ).animate(delay: 200.ms).fadeIn(),
    ]);
  }

  // ── 월간/연간 토글 ────────────────────────────────────

  Widget _buildPlanToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(children: [
        _toggleBtn('월간 구독', true),
        _toggleBtn('연간 구독', false),
      ]),
    );
  }

  Widget _toggleBtn(String label, bool isMonthly) {
    final selected = _monthly == isMonthly;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _monthly = isMonthly);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: selected
                ? Border.all(color: AppColors.accent.withOpacity(0.5))
                : null,
          ),
          child: Column(children: [
            Text(label, style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 13, fontWeight: FontWeight.bold,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            )),
            if (!isMonthly)
              const Text('2개월 무료', style: TextStyle(
                fontSize: 9, color: AppColors.jade, fontWeight: FontWeight.bold,
              )),
          ]),
        ),
      ),
    );
  }

  // ── 가격 카드 ─────────────────────────────────────────

  Widget _buildPriceCard() {
    final price = _monthly ? '₩9,900' : '₩99,000';
    final perMonth = _monthly ? '월 9,900원' : '월 8,250원 (연 99,000원)';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.12),
            AppColors.jade.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _monthly ? '월간 플랜' : '연간 플랜',
            style: const TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 12, color: AppColors.textSecondary, letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(price, style: const TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 28, fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
          ),
          Text(perMonth, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary,
          )),
        ])),
        if (!_monthly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.jade.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.jade.withOpacity(0.4)),
            ),
            child: const Text(
              '17% 절약',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold,
                color: AppColors.jade,
              ),
            ),
          ),
      ]),
    ).animate(key: ValueKey(_monthly)).fadeIn(duration: 200.ms);
  }

  // ── 혜택 리스트 ───────────────────────────────────────

  Widget _buildBenefitList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('포함 혜택', style: TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 13, fontWeight: FontWeight.bold,
        color: AppColors.textPrimary, letterSpacing: 0.5,
      )),
      const SizedBox(height: 10),
      ..._benefits.asMap().entries.map((e) =>
        _buildBenefitRow(e.value, e.key)
          .animate(delay: Duration(milliseconds: 50 + e.key * 40))
          .fadeIn().slideX(begin: 0.05),
      ),
    ]);
  }

  Widget _buildBenefitRow(_Benefit b, int idx) {
    final isPremium = !b.isFree;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        // 체크 아이콘
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: b.isFree
                ? AppColors.textSecondary.withOpacity(0.15)
                : AppColors.accent.withOpacity(0.15),
            border: Border.all(
              color: b.isFree
                  ? AppColors.textSecondary.withOpacity(0.3)
                  : AppColors.accent.withOpacity(0.5),
            ),
          ),
          child: Icon(
            b.isFree ? Icons.lock_open_rounded : Icons.check_rounded,
            size: 13,
            color: b.isFree ? AppColors.textSecondary : AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        // 이모지 + 제목 + 설명
        Text(b.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(b.title, style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 13, fontWeight: FontWeight.bold,
              color: isPremium ? AppColors.textPrimary : AppColors.textSecondary,
            )),
            if (b.isFree) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text('무료', style: TextStyle(
                  fontSize: 8, color: AppColors.textSecondary,
                )),
              ),
            ],
          ]),
          const SizedBox(height: 2),
          Text(b.desc, style: TextStyle(
            fontSize: 10,
            color: isPremium
                ? AppColors.textSecondary
                : AppColors.textMuted,
            height: 1.4,
          )),
        ])),
      ]),
    );
  }

  // ── CTA 버튼 ─────────────────────────────────────────

  Widget _buildCTAButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // TODO: 인앱결제 연동
        Navigator.pop(context);
        _showComingSoonSnackBar(context);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accentDim, AppColors.accent, AppColors.accentLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 16, spreadRadius: 2, offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '지금 시작하기 — 7일 무료 체험',
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 15, fontWeight: FontWeight.bold,
              color: AppColors.surface, letterSpacing: 0.5,
            ),
          ),
        ),
      ).animate().shimmer(
        duration: 2000.ms,
        delay: 600.ms,
        color: Colors.white.withOpacity(0.2),
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext ctx) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: const Text('프리미엄 결제는 곧 오픈됩니다! 기다려주세요 🙏',
          style: TextStyle(fontFamily: 'NotoSerifKR')),
        backgroundColor: AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.accent, width: 0.5),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── 하단 주석 ─────────────────────────────────────────

  Widget _buildFooterNote() {
    return Column(children: [
      const Text(
        '언제든 해지 가능 · 구독 전 결제 없음 · Google Play 결제',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
      ),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _footerLink('이용약관'),
        const Text(' · ', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
        _footerLink('개인정보처리방침'),
        const Text(' · ', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
        _footerLink('구독 복원'),
      ]),
    ]);
  }

  Widget _footerLink(String label) => GestureDetector(
    onTap: () {},
    child: Text(label,
      style: const TextStyle(
        fontSize: 9, color: AppColors.textSecondary,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textSecondary,
      )),
  );
}
