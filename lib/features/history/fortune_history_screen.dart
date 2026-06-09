import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/chart_widgets.dart';
import '../../core/services/fortune_log_service.dart';
import '../../shared/models/saju_profile.dart';
import '../../shared/models/fortune_log.dart';

class FortuneHistoryScreen extends StatelessWidget {
  final SajuProfile profile;

  const FortuneHistoryScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final logs = FortuneLogService.getLogs(profile, days: 90);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('운세 히스토리'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: logs.isEmpty
          ? _buildEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _buildTrendChart(logs),
                const SizedBox(height: 12),
                _buildStatsRow(logs),
                const SizedBox(height: 16),
                _buildSectionTitle('기록 목록'),
                const SizedBox(height: 8),
                ..._buildLogList(logs.reversed.toList()),
              ],
            ),
    );
  }

  // ── 빈 상태 ──────────────────────────────────────────

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('📊', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 16),
      const Text('아직 기록이 없습니다',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('대시보드를 방문하면 운세가 자동으로 기록됩니다',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    ]),
  );

  // ── 추이 차트 ─────────────────────────────────────────

  Widget _buildTrendChart(List<FortuneLog> logs) {
    final recent = logs.length > 30 ? logs.sublist(logs.length - 30) : logs;
    final spots = recent.asMap().entries.map((e) =>
      FlSpot(e.key.toDouble(), e.value.dailyScore.toDouble()),
    ).toList();

    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KoreanSectionTitle(
          title: '운세 점수 추이',
          subtitle: '최근 ${recent.length}일',
          icon: '📈',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: 0, maxY: 100,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: AppColors.divider,
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 25,
                    getTitlesWidget: (v, m) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 9),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: (recent.length / 5).ceilToDouble(),
                    getTitlesWidget: (v, m) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= recent.length) {
                        return const SizedBox.shrink();
                      }
                      final d = recent[idx].date;
                      return Text(
                        '${d.month}/${d.day}',
                        style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 8),
                      );
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    final log = idx < recent.length ? recent[idx] : null;
                    return LineTooltipItem(
                      '${log?.dayGanJi ?? ''}\n${s.y.toInt()}점',
                      TextStyle(
                        color: getScoreColor(s.y.toInt()),
                        fontSize: 11, fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                // 채우기 영역
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.accent.withOpacity(0.0),
                  barWidth: 0,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.accent.withOpacity(0.18),
                        AppColors.accent.withOpacity(0.0),
                      ],
                    ),
                  ),
                  dotData: const FlDotData(show: false),
                ),
                // 메인 라인
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  gradient: LinearGradient(
                    colors: [AppColors.accentDim, AppColors.accentLight],
                  ),
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                      radius: 2.5,
                      color: getScoreColor(s.y.toInt()),
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ── 통계 3열 ─────────────────────────────────────────

  Widget _buildStatsRow(List<FortuneLog> logs) {
    final avg = logs.isNotEmpty
        ? logs.map((l) => l.dailyScore).reduce((a, b) => a + b) / logs.length
        : 0.0;
    final best = logs.isNotEmpty
        ? logs.reduce((a, b) => a.dailyScore > b.dailyScore ? a : b)
        : null;
    final strk = FortuneLogService.streak(profile);

    return Row(children: [
      Expanded(child: _statCard('평균 점수', avg.round().toString(), '점', AppColors.accent)),
      const SizedBox(width: 8),
      Expanded(child: _statCard(
        '최고 점수', best?.dailyScore.toString() ?? '-', '점', AppColors.jade)),
      const SizedBox(width: 8),
      Expanded(child: _statCard('연속 방문', strk.toString(), '일', AppColors.geumColor)),
    ]);
  }

  Widget _statCard(String label, String value, String unit, Color color) =>
    TraditionalCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [color, color.withOpacity(0.7)]).createShader(b),
          child: Text(value, style: AppFonts.score(28, color: Colors.white)),
        ),
        Text(unit, style: AppFonts.montserrat(10, color: color.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(
          fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.3)),
      ]),
    );

  // ── 섹션 타이틀 ──────────────────────────────────────

  Widget _buildSectionTitle(String title) => KoreanSectionTitle(
    title: title, icon: '📋', showDivider: true);

  // ── 로그 리스트 ──────────────────────────────────────

  List<Widget> _buildLogList(List<FortuneLog> logs) {
    return logs.map((log) {
      final color = getScoreColor(log.dailyScore);
      final d = log.date;
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final wd = weekdays[d.weekday - 1];
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: TraditionalCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            // 날짜
            Column(crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, children: [
              Text('${d.month}/${d.day}',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
              Text('($wd)',
                style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
            ]),
            const SizedBox(width: 12),
            // 일진
            Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
              Text(log.dayGanJi,
                style: const TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, letterSpacing: 2)),
              Text('길한 방위: ${log.luckyDir}',
                style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            // 오행 뱃지
            OehaengBadge(log.mainOehaeng),
            const SizedBox(width: 10),
            // 점수
            Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, children: [
              Text('${log.dailyScore}',
                style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: color)),
              Text(getScoreKorean(log.dailyScore).split(' ').first,
                style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
            ]),
          ]),
        ),
      );
    }).toList();
  }
}
