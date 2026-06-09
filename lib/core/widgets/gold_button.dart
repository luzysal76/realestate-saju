// GoldButton — 재사용 가능한 골드 그라디언트 버튼
// RN design direction: PremiumButton (backgroundColor: theme.colors.primary,
//   borderRadius: 12, shadows.gold)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

// ─── Gold CTA 버튼 ────────────────────────────────────────
/// 브랜드 골드 그라디언트 버튼
/// borderRadius: 12 (RN design direction 기준)
class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final double? width;
  final double verticalPadding;
  final double fontSize;
  final double borderRadius;

  const GoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.width,
    this.verticalPadding = 18,
    this.fontSize = 16,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onTap?.call();
                },
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.accentLight.withOpacity(0.2),
          child: Ink(
            decoration: BoxDecoration(
              gradient: loading
                  ? LinearGradient(
                      colors: [
                        AppColors.accentDim.withOpacity(0.5),
                        AppColors.accent.withOpacity(0.5),
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        AppColors.accentDim,
                        AppColors.accent,
                        AppColors.accentLight,
                        AppColors.accent,
                        AppColors.accentDim,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.accentLight.withOpacity(loading ? 0.2 : 0.5),
              ),
              boxShadow: loading
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.surface.withOpacity(0.7),
                          ),
                        ),
                      )
                    : ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF1A0804), Color(0xFF2A1208)],
                        ).createShader(b),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    ).animate().shimmer(
      duration: 3000.ms,
      delay: 800.ms,
      color: Colors.white.withOpacity(0.15),
    );
  }
}

// ─── 분석 로딩 오버레이 ────────────────────────────────────
/// "당신의 기운을 읽는 중..." 전체화면 오버레이
/// RN OnboardingScreen loading state와 동일한 UX
class FortuneLoadingOverlay extends StatefulWidget {
  const FortuneLoadingOverlay({super.key});

  @override
  State<FortuneLoadingOverlay> createState() => _FortuneLoadingOverlayState();
}

class _FortuneLoadingOverlayState extends State<FortuneLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  final List<String> _messages = [
    '당신의 기운을 읽는 중...',
    '천간과 지지를 분석합니다...',
    '사주 오행을 계산합니다...',
    '부동산 궁합을 도출합니다...',
  ];
  int _msgIdx = 0;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // 1초마다 메시지 순환
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return false;
      setState(() => _msgIdx = (_msgIdx + 1) % _messages.length);
      return true;
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Stack(children: [
        // 배경 글로우
        Positioned(
          top: MediaQuery.of(context).size.height * 0.2,
          left: MediaQuery.of(context).size.width / 2 - 100,
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent
                    .withOpacity(0.04 + _pulseCtrl.value * 0.03),
              ),
            ),
          ),
        ),
        // 콘텐츠
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 나침반 스피너 (YundoSpinner 대신 간단한 구현)
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  return Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent
                            .withOpacity(0.3 + _pulseCtrl.value * 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent
                              .withOpacity(0.1 + _pulseCtrl.value * 0.15),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (b) =>
                            AppColors.goldGradient.createShader(b),
                        child: const Text(
                          '命',
                          style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // 메시지
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  _messages[_msgIdx],
                  key: ValueKey(_msgIdx),
                  style: const TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                '나침반이 우주의 데이터를 동기화합니다',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 32),

              // 점 로딩 인디케이터
              _DotsLoader(),
            ],
          ),
        ),
      ]),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final t = (_ctrl.value - delay).clamp(0.0, 1.0);
            final scale = 0.6 + 0.4 * (t < 0.5 ? t * 2 : (1 - t) * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7 * scale,
              height: 7 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent
                    .withOpacity(0.4 + 0.6 * (scale - 0.6) / 0.4),
              ),
            );
          }),
        );
      },
    );
  }
}
