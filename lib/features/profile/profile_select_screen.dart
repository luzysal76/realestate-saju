// 프로필 선택 화면 — 여러 사주 프로필 관리

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import '../dashboard/dashboard_screen.dart';
import '../input/input_screen.dart';

class ProfileSelectScreen extends StatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  State<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends State<ProfileSelectScreen> {
  late Box<SajuProfile> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<SajuProfile>('profiles');
  }

  void _openProfile(SajuProfile profile) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => DashboardScreen(profile: profile),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _deleteProfile(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.divider),
        ),
        title: const Text('프로필 삭제',
          style: TextStyle(fontFamily: 'NotoSerifKR',
            color: AppColors.textPrimary, fontSize: 16)),
        content: const Text('이 프로필을 삭제하시겠습니까?\n삭제된 프로필은 복구할 수 없습니다.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소',
              style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제',
              style: TextStyle(color: AppColors.hwaColor,
                fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _box.deleteAt(index);
      setState(() {});
      if (_box.isEmpty && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InputScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(children: [
        Positioned.fill(
          child: CustomPaint(
            painter: const DancheongPatternPainter(opacity: 0.02)),
        ),
        SafeArea(
          child: Column(children: [
            // ─── 헤더 ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF0E8D5), Color(0xFFF7F2EA)],
                ),
              ),
              child: Column(children: [
                const TaegeukSymbol(size: 44),
                const SizedBox(height: 14),
                ShaderMask(
                  shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                  child: const Text('프로필 선택',
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 4,
                    )),
                ),
                const SizedBox(height: 4),
                const Text('사주 프로필 선택',
                  style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 12, color: AppColors.textSecondary,
                    letterSpacing: 2,
                  )),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 30, height: 0.5,
                    color: AppColors.accent.withOpacity(0.4)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('✦',
                      style: TextStyle(color: AppColors.accent, fontSize: 9))),
                  Container(width: 30, height: 0.5,
                    color: AppColors.accent.withOpacity(0.4)),
                ]),
              ]),
            ),

            // ─── 프로필 목록 ──────────────────────────────
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, box, _) {
                  final profiles = box.values.toList();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: profiles.length,
                    itemBuilder: (ctx, i) {
                      final p = profiles[i];
                      return _buildProfileCard(p, i)
                          .animate(delay: Duration(milliseconds: i * 80))
                          .fadeIn().slideX(begin: 0.1);
                    },
                  );
                },
              ),
            ),
          ]),
        ),

        // ─── 하단 추가 버튼 ──────────────────────────────
        Positioned(
          bottom: 24, left: 16, right: 16,
          child: _buildAddButton(),
        ),
      ]),
    );
  }

  Widget _buildProfileCard(SajuProfile profile, int index) {
    final result = SajuCalculator.calculate(
      birthDate: profile.birthDate,
      birthHour: profile.birthHour == 25 ? 12 : profile.birthHour,
      birthMinute: profile.birthMinute,
      birthLongitude: profile.birthLongitude,
      gender: profile.gender,
    );
    final oe = result.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);

    return GestureDetector(
      onTap: () => _openProfile(profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Stack(children: [
          // 이중 테두리 내부
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: color.withOpacity(0.15), width: 0.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // 오행 배지
              OehaengBadge(oe, large: true),
              const SizedBox(width: 14),
              // 정보
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: Text(profile.name, style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: Colors.white, letterSpacing: 1,
                    )),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${profile.birthDate.year}년 ${profile.birthDate.month}월'
                    ' ${profile.birthDate.day}일  ${profile.gender}성',
                    style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(result.sipSeongAnalysis.formatDesc,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 10, color: color.withOpacity(0.8),
                      letterSpacing: 0.3,
                    )),
                ],
              )),
              // 아이콘
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Text('분석 →', style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: color, letterSpacing: 0.5,
                  )),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _deleteProfile(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.hwaColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppColors.hwaColor.withOpacity(0.25)),
                    ),
                    child: const Text('삭제', style: TextStyle(
                      fontSize: 10, color: AppColors.hwaColor)),
                  ),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const InputScreen())).then((_) {
          setState(() {});
        }),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.accentLight.withOpacity(0.5)),
          boxShadow: [BoxShadow(
            color: AppColors.accent.withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: const Center(
          child: Text('＋  새 프로필 추가',
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 15, fontWeight: FontWeight.bold,
              color: Color(0xFF1A0804),
              letterSpacing: 2,
            )),
        ),
      ),
    );
  }
}
