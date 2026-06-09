// 윤도(尹道) 스피너 — 전통 나침반 형태의 골드 로딩 인디케이터
// 브랜드 가이드: "골드 컬러의 윤도 형태 스피너가 회전하는 애니메이션"

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class YundoSpinner extends StatefulWidget {
  final double size;
  const YundoSpinner({super.key, this.size = 64});

  @override
  State<YundoSpinner> createState() => _YundoSpinnerState();
}

class _YundoSpinnerState extends State<YundoSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _YundoPainter(_ctrl.value),
      ),
    );
  }
}

class _YundoPainter extends CustomPainter {
  final double progress; // 0.0 ~ 1.0

  _YundoPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final center = Offset(cx, cy);

    // ── 외부 링 (32분할 나침반 눈금) ──
    for (int i = 0; i < 32; i++) {
      final angle = 2 * math.pi * i / 32;
      final isMajor = i % 4 == 0; // 8방위
      final outerPt = Offset(
        cx + (r - 2) * math.cos(angle),
        cy + (r - 2) * math.sin(angle),
      );
      final innerPt = Offset(
        cx + (r - (isMajor ? 10 : 6)) * math.cos(angle),
        cy + (r - (isMajor ? 10 : 6)) * math.sin(angle),
      );
      canvas.drawLine(
        outerPt, innerPt,
        Paint()
          ..color = AppColors.accent.withOpacity(isMajor ? 0.9 : 0.4)
          ..strokeWidth = isMajor ? 1.5 : 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── 회전하는 골드 아크 ──
    final rotateAngle = 2 * math.pi * progress;
    final sweepAngle = math.pi * 1.2;
    final arcRect = Rect.fromCircle(center: center, radius: r - 14);

    // 글로우
    canvas.drawArc(arcRect, rotateAngle, sweepAngle, false,
      Paint()
        ..color = AppColors.accent.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    // 메인 아크
    canvas.drawArc(arcRect, rotateAngle, sweepAngle, false,
      Paint()
        ..shader = SweepGradient(
          colors: [
            AppColors.accentDim.withOpacity(0),
            AppColors.accent,
            AppColors.accentLight,
          ],
          startAngle: rotateAngle,
          endAngle: rotateAngle + sweepAngle,
        ).createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);

    // ── 중앙 나침반 포인터 ──
    final needleAngle = rotateAngle;
    final needleLen = r - 22;
    canvas.drawLine(
      center,
      Offset(cx + needleLen * math.cos(needleAngle),
             cy + needleLen * math.sin(needleAngle)),
      Paint()
        ..color = AppColors.accent.withOpacity(0.8)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // ── 중앙 점 ──
    canvas.drawCircle(center, 3,
      Paint()
        ..color = AppColors.accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(center, 2, Paint()..color = AppColors.accentLight);
  }

  @override
  bool shouldRepaint(_YundoPainter old) => old.progress != progress;
}
