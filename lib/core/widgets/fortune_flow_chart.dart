// 대운/세운 흐름 그래프 — fl_chart LineChart
// 사주 투자 점수를 시간 흐름으로 시각화

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../saju/saju_calculator.dart';
import 'chart_widgets.dart' show getScoreColor;

// ─── 대운 흐름 라인 차트 ──────────────────────────────────
/// 대운 10년 주기 투자점수 흐름 (LineChart)
class DaeWunFlowChart extends StatefulWidget {
  final List<DaeWun> daeWunList;
  final int birthYear;
  final double height;

  const DaeWunFlowChart({
    super.key,
    required this.daeWunList,
    required this.birthYear,
    this.height = 200,
  });

  @override
  State<DaeWunFlowChart> createState() => _DaeWunFlowChartState();
}

class _DaeWunFlowChartState extends State<DaeWunFlowChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final list = widget.daeWunList;
    if (list.isEmpty) return const SizedBox.shrink();

    // 데이터 포인트
    final spots = list.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.investmentScore.toDouble());
    }).toList();

    // 현재 대운 인덱스
    final nowIdx = list.indexWhere(
        (d) => d.isCurrent(currentYear, widget.birthYear));

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return LineChart(
            LineChartData(
              minX: 0,
              maxX: (list.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.accent.withOpacity(0.08),
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 25,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= list.length) return const SizedBox();
                      final dw = list[idx];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('${dw.age}세',
                            style: TextStyle(
                              fontSize: 7,
                              color: idx == nowIdx
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              fontWeight: idx == nowIdx
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            )),
                        ]),
                      );
                    },
                  ),
                ),
              ),
              // 현재 대운 세로 라인
              extraLinesData: nowIdx >= 0
                  ? ExtraLinesData(verticalLines: [
                      VerticalLine(
                        x: nowIdx.toDouble(),
                        color: AppColors.accent.withOpacity(0.5),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: VerticalLineLabel(
                          show: true,
                          labelResolver: (_) => '현재',
                          style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold),
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ])
                  : null,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.cardBg,
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= list.length) return null;
                    final dw = list[idx];
                    return LineTooltipItem(
                      '${dw.year}~${dw.year + 9}년\n${dw.cheongan}${dw.jiji} ${dw.age}세\n${dw.investmentScore}점',
                      TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 10,
                        color: getScoreColor(dw.investmentScore),
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: AppColors.accent,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.18 * _anim.value),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, idx) {
                      final score = spot.y.toInt();
                      final isNow = idx == nowIdx;
                      return FlDotCirclePainter(
                        radius: isNow ? 5 : 3,
                        color: isNow
                            ? AppColors.accent
                            : getScoreColor(score).withOpacity(0.8),
                        strokeWidth: isNow ? 2 : 0,
                        strokeColor: AppColors.surface,
                      );
                    },
                  ),
                ),
              ],
            ),
            duration: Duration(milliseconds: (800 * _anim.value).toInt()),
          );
        },
      ),
    );
  }
}

// ─── 세운 흐름 라인 차트 ──────────────────────────────────
/// 세운 연도별 투자점수 흐름 (LineChart, 영역 채우기)
class SeWunFlowChart extends StatefulWidget {
  final List<SeWun> seWunList;
  final double height;

  const SeWunFlowChart({
    super.key,
    required this.seWunList,
    this.height = 180,
  });

  @override
  State<SeWunFlowChart> createState() => _SeWunFlowChartState();
}

class _SeWunFlowChartState extends State<SeWunFlowChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.seWunList;
    if (list.isEmpty) return const SizedBox.shrink();
    final currentYear = DateTime.now().year;
    final nowIdx = list.indexWhere((s) => s.year == currentYear);

    final spots = list.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.investmentScore.toDouble());
    }).toList();

    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          return LineChart(
            LineChartData(
              minX: 0,
              maxX: (list.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.jade.withOpacity(0.08),
                  strokeWidth: 0.5,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 25,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: const TextStyle(
                          fontSize: 8, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: (list.length / 5).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= list.length) return const SizedBox();
                      return Text(
                        '${list[idx].year}',
                        style: TextStyle(
                          fontSize: 7,
                          color: idx == nowIdx
                              ? AppColors.jade
                              : AppColors.textSecondary,
                          fontWeight: idx == nowIdx
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ),
              ),
              extraLinesData: nowIdx >= 0
                  ? ExtraLinesData(verticalLines: [
                      VerticalLine(
                        x: nowIdx.toDouble(),
                        color: AppColors.jade.withOpacity(0.5),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: VerticalLineLabel(
                          show: true,
                          labelResolver: (_) => '올해',
                          style: const TextStyle(
                              fontSize: 8,
                              color: AppColors.jade,
                              fontWeight: FontWeight.bold),
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ])
                  : null,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.cardBg,
                  getTooltipItems: (spots) => spots.map((s) {
                    final idx = s.x.toInt();
                    if (idx < 0 || idx >= list.length) return null;
                    final sw = list[idx];
                    return LineTooltipItem(
                      '${sw.year}년 ${sw.ganJiStr}\n${sw.investmentScore}점 ${sw.scoreLabel}',
                      TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 10,
                        color: getScoreColor(sw.investmentScore),
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                      ),
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.jade.withOpacity(0.7),
                      AppColors.accent,
                      AppColors.jade,
                    ],
                  ),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.jade.withOpacity(0.15 * _anim.value),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, _, __, idx) {
                      final isNow = idx == nowIdx;
                      return FlDotCirclePainter(
                        radius: isNow ? 5 : 2.5,
                        color: isNow
                            ? AppColors.jade
                            : getScoreColor(spot.y.toInt()).withOpacity(0.7),
                        strokeWidth: isNow ? 2 : 0,
                        strokeColor: AppColors.surface,
                      );
                    },
                  ),
                ),
              ],
            ),
            duration: Duration(milliseconds: (800 * _anim.value).toInt()),
          );
        },
      ),
    );
  }
}

// ─── 대운+세운 복합 차트 ──────────────────────────────────
/// 대운(금빛 굵음)과 세운(녹색 얇음)을 같이 그리는 복합 차트
/// 대운 점수를 세운 연도 인덱스에 맞춰 보간
class CombinedFortuneChart extends StatelessWidget {
  final List<DaeWun> daeWunList;
  final List<SeWun> seWunList;
  final int birthYear;
  final double height;

  const CombinedFortuneChart({
    super.key,
    required this.daeWunList,
    required this.seWunList,
    required this.birthYear,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (seWunList.isEmpty) return const SizedBox.shrink();
    final currentYear = DateTime.now().year;
    final nowIdx = seWunList.indexWhere((s) => s.year == currentYear);

    // 세운 스팟
    final seSpots = seWunList.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.investmentScore.toDouble());
    }).toList();

    // 대운 점수를 세운 인덱스에 맞게 매핑
    final dwSpots = <FlSpot>[];
    for (int i = 0; i < seWunList.length; i++) {
      final year = seWunList[i].year;
      for (final dw in daeWunList) {
        if (year >= dw.year && year < dw.year + 10) {
          dwSpots.add(FlSpot(i.toDouble(), dw.investmentScore.toDouble()));
          break;
        }
      }
    }

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (seWunList.length - 1).toDouble(),
          minY: 0,
          maxY: 100,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.accent.withOpacity(0.07),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(
                      fontSize: 8, color: AppColors.textSecondary),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (seWunList.length / 5).ceilToDouble(),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= seWunList.length) {
                    return const SizedBox();
                  }
                  return Text(
                    '${seWunList[idx].year}',
                    style: TextStyle(
                      fontSize: 7,
                      color: idx == nowIdx
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: nowIdx >= 0
              ? ExtraLinesData(verticalLines: [
                  VerticalLine(
                    x: nowIdx.toDouble(),
                    color: AppColors.accent.withOpacity(0.4),
                    strokeWidth: 1,
                    dashArray: [3, 3],
                    label: VerticalLineLabel(
                      show: true,
                      labelResolver: (_) => '현재',
                      style: const TextStyle(
                          fontSize: 8,
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold),
                      alignment: Alignment.topRight,
                    ),
                  ),
                ])
              : null,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardBg,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                  final idx = s.x.toInt();
                  if (idx < 0 || idx >= seWunList.length) return null;
                  final sw = seWunList[idx];
                  final label = s.barIndex == 0
                      ? '세운 ${sw.year}년\n${sw.ganJiStr}  ${sw.investmentScore}점'
                      : '대운 흐름  ${s.y.toInt()}점';
                  return LineTooltipItem(
                    label,
                    TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 10,
                      color: s.barIndex == 0
                          ? getScoreColor(sw.investmentScore)
                          : AppColors.accent,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            // 세운 (Jade Green, 얇음)
            LineChartBarData(
              spots: seSpots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.jade,
              barWidth: 1.5,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.jade.withOpacity(0.06),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) => FlDotCirclePainter(
                  radius: idx == nowIdx ? 4.5 : 2,
                  color: idx == nowIdx
                      ? AppColors.jade
                      : getScoreColor(spot.y.toInt()).withOpacity(0.6),
                  strokeWidth: idx == nowIdx ? 1.5 : 0,
                  strokeColor: AppColors.surface,
                ),
              ),
            ),
            // 대운 (Antique Gold, 굵음)
            if (dwSpots.isNotEmpty)
              LineChartBarData(
                spots: dwSpots,
                isCurved: false,
                color: AppColors.accent.withOpacity(0.8),
                barWidth: 3,
                isStrokeCapRound: true,
                dashArray: [8, 4],
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.accent.withOpacity(0.05),
                ),
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
}

