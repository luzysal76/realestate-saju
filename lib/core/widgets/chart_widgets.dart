// 차트 위젯 — 오행 레이더 + 반원 게이지
// 참고 디자인: Real Estate Saju 2.0 다크 럭셔리 테마

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── 오행 레이더 차트 ─────────────────────────────────
/// 오방위(수·목·화·토·금) 오각형 레이더 차트 (글로우 금빛)
class OhaengRadarWidget extends StatelessWidget {
  final Map<String, int> scores; // {'목':2,'화':1,'토':1,'금':1,'수':3}
  final double size;

  const OhaengRadarWidget({
    super.key, required this.scores, this.size = 160});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: CustomPaint(painter: _RadarPainter(scores)),
  );
}

class _RadarPainter extends CustomPainter {
  final Map<String, int> scores;
  _RadarPainter(this.scores);

  // 시계방향, 12시부터: 수→목→화→토→금
  static const _axes  = ['수', '목', '화', '토', '금'];
  // 브랜드 가이드 오행 컬러 코드
  static const _colors = {
    '수': Color(0xFF007AFF), // Azure Blue
    '목': Color(0xFF00A86B), // Jade Green
    '화': Color(0xFFFF4D4D), // Coral Red
    '토': Color(0xFFFFD700), // Amber Gold
    '금': Color(0xFFE5E5E5), // Platinum
  };

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final maxR = size.width / 2 - 22.0;

    // 꼭짓점 각도 (12시 방향부터 시계방향)
    final angles = List.generate(5,
      (i) => -math.pi / 2 + 2 * math.pi * i / 5);

    // ── 배경 격자 (3단계 링) ──
    for (int ring = 1; ring <= 3; ring++) {
      final r = maxR * ring / 3;
      final path = Path();
      for (int i = 0; i < 5; i++) {
        final x = cx + r * math.cos(angles[i]);
        final y = cy + r * math.sin(angles[i]);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      path.close();
      canvas.drawPath(path, Paint()
        ..color = AppColors.accent.withOpacity(0.05 + ring * 0.04)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5);
    }

    // ── 축선 ──
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(center, Offset(
        cx + maxR * math.cos(angles[i]),
        cy + maxR * math.sin(angles[i]),
      ), Paint()..color = AppColors.accent.withOpacity(0.15)..strokeWidth = 0.5);
    }

    // ── 값 다각형 ──
    final mx = scores.values.fold(0, (m, v) => v > m ? v : m);
    final safeMax = mx < 1 ? 1.0 : mx.toDouble();

    final pts = List.generate(5, (i) {
      final oe = _axes[i];
      final ratio = (scores[oe] ?? 0) / safeMax;
      final r = maxR * (0.15 + ratio * 0.85);
      return Offset(cx + r * math.cos(angles[i]), cy + r * math.sin(angles[i]));
    });

    final vPath = Path();
    for (int i = 0; i < 5; i++) {
      if (i == 0) vPath.moveTo(pts[i].dx, pts[i].dy);
      else vPath.lineTo(pts[i].dx, pts[i].dy);
    }
    vPath.close();

    // 글로우 채우기
    canvas.drawPath(vPath, Paint()
      ..color = AppColors.accent.withOpacity(0.12)
      ..style = PaintingStyle.fill);

    // 글로우 외곽선
    canvas.drawPath(vPath, Paint()
      ..color = AppColors.accent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // 메인 외곽선
    canvas.drawPath(vPath, Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // ── 꼭짓점 점 + 라벨 ──
    for (int i = 0; i < 5; i++) {
      final oe = _axes[i];
      final color = _colors[oe] ?? AppColors.accent;

      // 글로우 점
      canvas.drawCircle(pts[i], 5, Paint()
        ..color = color.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      // 점
      canvas.drawCircle(pts[i], 2.5, Paint()..color = color);

      // 라벨
      final lx = cx + (maxR + 14) * math.cos(angles[i]);
      final ly = cy + (maxR + 14) * math.sin(angles[i]);
      final tp = TextPainter(
        text: TextSpan(text: oe, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── 반원 게이지 (Count-up 애니메이션) ──────────────────
/// 0~100 점수를 반원 글로우 게이지로 표시
/// 브랜드 가이드: "0에서 최종 점수까지 빠르게 올라가는 Count-up 효과"
/// font-display-score: 40pt / Bold
class SemiCircleGauge extends StatelessWidget {
  final int score;
  final double width;
  final String label;

  const SemiCircleGauge({
    super.key,
    required this.score,
    this.width = 150,
    this.label = '재물운 점수',
  });

  @override
  Widget build(BuildContext context) {
    final h = width / 2 + 36.0;
    // Count-up: 0 → score, 1000ms ease-out
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: score),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (_, animated, __) {
        return SizedBox(
          width: width, height: h,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            // 게이지 (애니메이션 점수 연동)
            CustomPaint(size: Size(width, h), painter: _GaugePainter(animated)),
            // 숫자 + 라벨
            Column(mainAxisSize: MainAxisSize.min, children: [
              ShaderMask(
                shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                // font-display-score: 40pt Bold (Montserrat)
                child: Text('$animated', style: GoogleFonts.montserrat(
                  fontSize: 40, fontWeight: FontWeight.w700,
                  color: Colors.white, height: 1.2, letterSpacing: -1)),
              ),
              const SizedBox(height: 2),
              Text(label, style: GoogleFonts.montserrat(
                fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1.5)),
            ]),
          ]),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  _GaugePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 32;
    final r = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // 배경 호
    canvas.drawArc(rect, math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round);

    final sweep = math.pi * score.clamp(0, 100) / 100;

    // 글로우 호
    canvas.drawArc(rect, math.pi, sweep, false, Paint()
      ..shader = LinearGradient(
        colors: [AppColors.accentDim, AppColors.accentLight],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // 메인 호
    canvas.drawArc(rect, math.pi, sweep, false, Paint()
      ..shader = LinearGradient(
        colors: [AppColors.accent, AppColors.accentLight],
        begin: Alignment.centerLeft, end: Alignment.centerRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round);

    // 눈금 (11개, 5배수 = 대눈금)
    for (int i = 0; i <= 10; i++) {
      final angle = math.pi + math.pi * i / 10;
      final isMajor = i % 5 == 0;
      final inner = r - 13;
      final outer = r - (isMajor ? 22 : 16);
      canvas.drawLine(
        Offset(cx + inner * math.cos(angle), cy + inner * math.sin(angle)),
        Offset(cx + outer * math.cos(angle), cy + outer * math.sin(angle)),
        Paint()
          ..color = AppColors.accent.withOpacity(isMajor ? 0.65 : 0.3)
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    // '0' / '100' 레이블
    _drawText(canvas, '0',
      Offset(cx - r - 6, cy - 7), 9, AppColors.textSecondary);
    _drawText(canvas, '100',
      Offset(cx + r - 6, cy - 7), 9, AppColors.textSecondary);
  }

  void _drawText(Canvas c, String text, Offset pos, double fs, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text,
        style: TextStyle(color: color, fontSize: fs)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, pos);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─── 점수 색상 헬퍼 (다크 테마용) ────────────────────
Color getScoreColor(int score) {
  if (score >= 80) return AppColors.accent;       // Antique Gold
  if (score >= 65) return AppColors.jade;         // Jade Green
  if (score >= 50) return AppColors.textSecondary;
  if (score >= 35) return AppColors.textMuted;
  return const Color(0xFF6A7080);
}

String getScoreKorean(int score) {
  if (score >= 80) return '대길 (大吉)';
  if (score >= 65) return '길 (吉)';
  if (score >= 50) return '평길 (平吉)';
  if (score >= 35) return '보통 (普通)';
  return '주의 (注意)';
}
