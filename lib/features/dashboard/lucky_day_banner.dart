// lucky_day_banner.dart — 대시보드용 이달의 이사길일 요약 배너
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/saju/saju_calculator.dart';
import '../../core/saju/lucky_day.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../shared/models/saju_profile.dart';
import '../moving/moving_screen.dart';
import '../../core/router/app_router.dart';

class LuckyDayBanner extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;

  const LuckyDayBanner({super.key, required this.result, required this.profile});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final luckyDays = LuckyDayCalculator.getMonthlyLuckyDays(
      year: now.year,
      month: now.month,
      mainOehaeng: result.mainOehaeng,
    );

    // 오늘 포함 이후의 길일만 필터
    final upcoming = luckyDays
        .where((d) => !d.date.isBefore(DateTime(now.year, now.month, now.day)))
        .take(4)
        .toList();

    // 오늘이 길일인지 확인
    final todayLucky = luckyDays.where((d) =>
      d.date.year == now.year && d.date.month == now.month && d.date.day == now.day
    ).firstOrNull;

    final color = AppColors.getOehaengColor(result.mainOehaeng);

    return GestureDetector(
      onTap: () => Navigator.push(context,
        AppRouter.slide(MovingScreen(result: result))),
      child: TraditionalCard(
        borderColor: todayLucky != null
            ? AppColors.accent.withOpacity(0.5)
            : color.withOpacity(0.25),
        bgColor: todayLucky != null
            ? AppColors.accent.withOpacity(0.04)
            : null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 헤더
          Row(children: [
            KoreanSectionTitle(
              title: '${now.month}월 이사길일',
              icon: '📅',
              showDivider: false,
            ),
            const Spacer(),
            Text('전체 보기 ›', style: TextStyle(
              fontSize: 11, color: AppColors.accent.withOpacity(0.8))),
          ]),

          // 오늘 길일 강조 배너
          if (todayLucky != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Row(children: [
                const Text('✨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: const Text('오늘이 길일입니다!',
                      style: TextStyle(fontFamily: 'NotoSerifKR',
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: Colors.white)),
                  ),
                  Text(todayLucky.reasons.join(' · '),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ])),
                Text('${todayLucky.score}점', style: const TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 18,
                  fontWeight: FontWeight.bold, color: AppColors.accent)),
              ]),
            ),
          ],

          // 다가오는 길일 목록
          if (upcoming.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: upcoming.map((d) {
                final isToday = d.date.year == now.year &&
                    d.date.month == now.month && d.date.day == now.day;
                final daysLeft = d.date.difference(now).inDays;
                return Expanded(child: Container(
                  margin: const EdgeInsets.only(right: 5),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.accent.withOpacity(0.15)
                        : AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? AppColors.accent.withOpacity(0.5)
                          : AppColors.divider.withOpacity(0.6),
                      width: isToday ? 1.2 : 0.7,
                    ),
                  ),
                  child: Column(children: [
                    Text('${d.date.day}일',
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR', fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.accent : AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_weekdayKor(d.date.weekday),
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                    const SizedBox(height: 3),
                    Text(d.isSonNone ? '손없는날' : d.reasons.first.replaceAll(' ✨', '').replaceAll(' 오행 길일', '').trim(),
                      style: const TextStyle(fontSize: 8, color: AppColors.accent),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (!isToday && daysLeft >= 0)
                      Text('D-$daysLeft', style: const TextStyle(
                        fontSize: 8, color: AppColors.textMuted)),
                  ]),
                ));
              }).toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('이번 달 남은 길일이 없습니다',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ),
        ]),
      ),
    ).animate(delay: 460.ms).fadeIn().slideY(begin: 0.08);
  }

  String _weekdayKor(int w) {
    const d = ['월', '화', '수', '목', '금', '토', '일'];
    return d[(w - 1) % 7];
  }
}
