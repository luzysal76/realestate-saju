import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../shared/models/saju_profile.dart';
import '../input/input_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotCtrl;

  @override
  void initState() {
    super.initState();
    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _navigate();
  }

  @override
  void dispose() {
    _rotCtrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;
    final box = Hive.box<SajuProfile>('profiles');
    if (box.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InputScreen()),
      );
    } else if (box.length == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardScreen(profile: box.getAt(0)!)),
      );
    } else {
      // 여러 프로필이 있을 때 선택 화면
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSelectScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0E8D5), Color(0xFFF7F2EA), Color(0xFFEDE5D5)],
          ),
        ),
        child: Stack(children: [
          // 배경 단청 패턴
          Positioned.fill(
            child: CustomPaint(
              painter: const DancheongPatternPainter(opacity: 0.035),
            ),
          ),

          // 상단 장식 라인
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 2, color: AppColors.accent.withOpacity(0.4))
                .animate(delay: 600.ms).scaleX(begin: 0, end: 1),
          ),
          Positioned(
            top: 4, left: 40, right: 40,
            child: Container(height: 0.5, color: AppColors.accent.withOpacity(0.2))
                .animate(delay: 800.ms).scaleX(begin: 0, end: 1),
          ),

          // 하단 장식 라인
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 2, color: AppColors.accent.withOpacity(0.4)),
          ),
          Positioned(
            bottom: 4, left: 40, right: 40,
            child: Container(height: 0.5, color: AppColors.accent.withOpacity(0.2)),
          ),

          // 메인 콘텐츠
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 태극 문양 + 회전 원
                SizedBox(
                  width: 140, height: 140,
                  child: Stack(alignment: Alignment.center, children: [
                    // 회전하는 외부 원
                    AnimatedBuilder(
                      animation: _rotCtrl,
                      builder: (_, __) => Transform.rotate(
                        angle: _rotCtrl.value * 2 * 3.14159,
                        child: Container(
                          width: 140, height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.15), width: 1),
                          ),
                          child: const CustomPaint(
                            painter: _RotatingDotsPainter(),
                          ),
                        ),
                      ),
                    ),
                    // 고정 내부 원
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardBg,
                        border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.15),
                            blurRadius: 20, spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    // 태극 문양
                    const TaegeukSymbol(size: 72),
                  ]),
                )
                .animate()
                .scale(duration: 700.ms, curve: Curves.elasticOut)
                .fade(duration: 500.ms),

                const SizedBox(height: 36),

                // 한자 제목
                Column(children: [
                  // 한자 큰 글씨
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: const Text(
                      '不動産四柱',
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 한글 부제
                  Text(
                    '부동산 사주',
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 18,
                      color: AppColors.textPrimary.withOpacity(0.9),
                      letterSpacing: 4,
                    ),
                  ),
                ])
                .animate(delay: 250.ms)
                .fadeIn(duration: 700.ms)
                .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 16),

                // 구분선
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 40, height: 0.5, color: AppColors.accent.withOpacity(0.4)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('✦', style: TextStyle(color: AppColors.accent, fontSize: 10)),
                  ),
                  Container(width: 40, height: 0.5, color: AppColors.accent.withOpacity(0.4)),
                ]).animate(delay: 450.ms).fadeIn(),

                const SizedBox(height: 14),

                Text(
                  '천명(天命)으로 보는 나의 부동산 운세',
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ).animate(delay: 550.ms).fadeIn(),

                const SizedBox(height: 64),

                // 로딩 — 전통 스타일 도트
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withOpacity(0.3 + i * 0.15),
                    ),
                  )
                  .animate(
                    delay: Duration(milliseconds: 900 + i * 100),
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .scaleXY(begin: 0.5, end: 1.2, duration: 600.ms)
                  .fadeIn()),
                ),

                const SizedBox(height: 14),

                Text(
                  '사주 데이터 분석 중...',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ).animate(delay: 1000.ms).fadeIn(),
              ],
            ),
          ),

          // 좌우 모서리 장식
          Positioned(top: 20, left: 16, child: _corner()),
          Positioned(top: 20, right: 16, child: Transform(
            transform: Matrix4.rotationY(3.14159),
            alignment: Alignment.center,
            child: _corner(),
          )),
          Positioned(bottom: 20, left: 16, child: Transform(
            transform: Matrix4.rotationX(3.14159),
            alignment: Alignment.center,
            child: _corner(),
          )),
          Positioned(bottom: 20, right: 16, child: Transform(
            transform: Matrix4.rotationZ(3.14159),
            alignment: Alignment.center,
            child: _corner(),
          )),
        ]),
      ),
    );
  }

  Widget _corner() => SizedBox(
    width: 20, height: 20,
    child: CustomPaint(painter: _CornerPainter()),
  );
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

class _RotatingDotsPainter extends CustomPainter {
  const _RotatingDotsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    const count = 8;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * 3.14159;
      final x = center.dx + radius * (0 + 0.98 * (angle.isNaN ? 0 : 1)) * _cos(angle);
      final y = center.dy + radius * _sin(angle);
      canvas.drawCircle(Offset(x, y), i % 2 == 0 ? 2.5 : 1.5, paint);
    }
  }
  double _cos(double angle) => (angle < 6.28) ? _approxCos(angle) : 1;
  double _sin(double angle) => (angle < 6.28) ? _approxSin(angle) : 0;
  double _approxCos(double a) {
    // Simple approximation
    final pi2 = 2 * 3.14159;
    final normalized = a % pi2;
    if (normalized < 1.5708) return 1 - (normalized / 1.5708) * (1 - 0);
    if (normalized < 3.14159) return -(normalized - 1.5708) / 1.5708;
    if (normalized < 4.7124) return -1 + (normalized - 3.14159) / 1.5708;
    return (normalized - 4.7124) / 1.5708;
  }
  double _approxSin(double a) => _approxCos(a - 1.5708);
  @override bool shouldRepaint(covariant CustomPainter _) => false;
}
