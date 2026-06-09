import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/yundo_spinner.dart';
import '../../core/router/app_router.dart';
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
        AppRouter.slide(const InputScreen()),
      );
    } else if (box.length == 1) {
      Navigator.of(context).pushReplacement(
        AppRouter.slide(DashboardScreen(profile: box.getAt(0)!)),
      );
    } else {
      // 여러 프로필이 있을 때 선택 화면
      Navigator.of(context).pushReplacement(
        AppRouter.slide(const ProfileSelectScreen()),
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
                    // 앱 로고
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.30),
                            blurRadius: 28, spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          width: 110, height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ]),
                )
                .animate()
                .scale(duration: 700.ms, curve: Curves.elasticOut)
                .fade(duration: 500.ms),

                const SizedBox(height: 36),

                // 타이틀
                Column(children: [
                  // 메인 타이틀 (한글)
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: const Text(
                      '부동산 사주',
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 32, fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 서브타이틀
                  Text(
                    '나에게 맞는 동네와 집을 찾아드립니다',
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 13,
                      color: AppColors.textPrimary.withOpacity(0.75),
                      letterSpacing: 1,
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
                  '사주 기반 라이프스타일 주거 추천',
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ).animate(delay: 550.ms).fadeIn(),

                const SizedBox(height: 64),

                // 로딩 — 윤도(尹道) 스피너
                const YundoSpinner(size: 52)
                    .animate(delay: 800.ms).fadeIn(duration: 500.ms),

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
