import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

// ─── 전통 카드 ─────────────────────────────────────────

/// 단청 테두리 전통 카드
class TraditionalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? bgColor;
  final bool doubleBorder;

  const TraditionalCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.bgColor,
    this.doubleBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.divider;
    final bg = bgColor ?? AppColors.cardBg;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: doubleBorder
          ? Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: border.withOpacity(0.4), width: 0.5),
              ),
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            )
          : Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
    );
  }
}

// ─── 전통 구분선 ──────────────────────────────────────

/// 봉황 문양 구분선
class TraditionalDivider extends StatelessWidget {
  final double indent;
  const TraditionalDivider({super.key, this.indent = 20});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: indent, vertical: 4),
      child: Row(children: [
        Expanded(
          child: Container(height: 0.5, color: AppColors.divider),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '◈',
            style: TextStyle(
              color: AppColors.accent.withOpacity(0.6),
              fontSize: 10,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5, color: AppColors.divider),
        ),
      ]),
    );
  }
}

// ─── 금빛 섹션 타이틀 ─────────────────────────────────

/// 단청 스타일 섹션 제목
class KoreanSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? icon;
  final bool showDivider;

  const KoreanSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
          ],
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 14, fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ]),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: const TextStyle(
            fontSize: 10, color: AppColors.textSecondary,
            letterSpacing: 0.5,
          )),
        ],
        if (showDivider) ...[
          const SizedBox(height: 8),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.accent, Colors.transparent,
              ]),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── 오행 뱃지 ────────────────────────────────────────

class OehaengBadge extends StatelessWidget {
  final String oehaeng;
  final bool large;
  const OehaengBadge(this.oehaeng, {super.key, this.large = false});

  static const Map<String, String> _hanja = {
    '목': '木', '화': '火', '토': '土', '금': '金', '수': '水',
  };

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getOehaengColor(oehaeng);
    final size = large ? 48.0 : 32.0;
    final fontSize = large ? 20.0 : 14.0;

    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Center(
        child: Text(
          _hanja[oehaeng] ?? oehaeng,
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─── 전통 십성 뱃지 ───────────────────────────────────

class SipSeongBadge extends StatelessWidget {
  final String name;
  final Color color;
  final bool small;

  const SipSeongBadge({
    super.key,
    required this.name,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── 사주 기둥 카드 ────────────────────────────────────

class PillarCard extends StatelessWidget {
  final String cheongan;
  final String jiji;
  final String label;
  final Color color;
  final String? sipSeongLabel;
  final Color? sipSeongColor;

  const PillarCard({
    super.key,
    required this.cheongan,
    required this.jiji,
    required this.label,
    required this.color,
    this.sipSeongLabel,
    this.sipSeongColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 기둥 라벨
      Text(label, style: const TextStyle(
        fontSize: 10, color: AppColors.textSecondary,
        letterSpacing: 1,
      )),
      const SizedBox(height: 6),
      // 간지 박스
      Container(
        width: 58, height: 76,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(cheongan, style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 22, fontWeight: FontWeight.bold,
            color: color,
            shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 6)],
          )),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Container(height: 0.5, color: color.withOpacity(0.4)),
          ),
          Text(jiji, style: const TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 22, fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          )),
        ]),
      ),
      const SizedBox(height: 5),
      // 십성 뱃지
      if (sipSeongLabel != null)
        SipSeongBadge(
          name: sipSeongLabel!,
          color: sipSeongColor ?? AppColors.accent,
          small: true,
        )
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: const Text('일간', style: TextStyle(
            fontSize: 9, color: AppColors.accent,
            fontFamily: 'NotoSerifKR', letterSpacing: 0.5,
          )),
        ),
    ]);
  }
}

// ─── 진행률 바 (한국풍) ──────────────────────────────

class KoreanProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;

  const KoreanProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
      FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color, color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 4),
            ],
          ),
        ),
      ),
    ]);
  }
}

// ─── 단청 배경 패턴 페인터 ────────────────────────────

class DancheongPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const DancheongPatternPainter({
    this.color = AppColors.accent,
    this.opacity = 0.04,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    // 격자 패턴
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // 사선 패턴
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 태극 문양 위젯 ──────────────────────────────────

class TaegeukSymbol extends StatelessWidget {
  final double size;
  const TaegeukSymbol({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _TaegeukPainter(),
      ),
    );
  }
}

class _TaegeukPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 외부 원
    final outerPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 2, outerPaint);

    // 음(陰) — 파랑/흑
    final yinPaint = Paint()
      ..color = AppColors.suColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // 양(陽) — 빨강
    final yangPaint = Paint()
      ..color = AppColors.hwaColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final r = radius - 4;
    final sr = r / 2;

    // 위쪽 반원 (양)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      math.pi, math.pi, true, yangPaint,
    );
    // 아래쪽 반원 (음)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      0, math.pi, true, yinPaint,
    );
    // 위쪽 작은 원 (음 안의 양)
    canvas.drawCircle(
      Offset(center.dx, center.dy - sr),
      sr, yinPaint,
    );
    // 아래쪽 작은 원 (양 안의 음)
    canvas.drawCircle(
      Offset(center.dx, center.dy + sr),
      sr, yangPaint,
    );
    // 외곽선
    canvas.drawCircle(center, r, outerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── 세운 점수 색상 헬퍼 ─────────────────────────────

Color getScoreColor(int score) {
  if (score >= 80) return const Color(0xFFCC3300); // 단청 적 — 대길
  if (score >= 65) return const Color(0xFFC08010); // 황금 — 길
  if (score >= 50) return const Color(0xFF2E7D5A); // 녹청 — 평길
  if (score >= 35) return AppColors.textSecondary;
  return const Color(0xFF5A5A6A); // 회색 — 주의
}

String getScoreKorean(int score) {
  if (score >= 80) return '대길 (大吉)';
  if (score >= 65) return '길 (吉)';
  if (score >= 50) return '평길 (平吉)';
  if (score >= 35) return '보통 (普通)';
  return '주의 (注意)';
}
