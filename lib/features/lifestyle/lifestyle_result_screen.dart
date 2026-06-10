// lifestyle_result_screen.dart — 생활패턴 맞춤 분석 결과
// 레이더 차트 (사주·교통·편의·예산) + 집 유형 추천 + 자치구 TOP5
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import '../map/district_map_data.dart';
import 'lifestyle_model.dart';
import 'lifestyle_input_screen.dart';

class LifestyleResultScreen extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;
  final LifestyleProfile lifestyle;

  const LifestyleResultScreen({
    super.key,
    required this.result,
    required this.profile,
    required this.lifestyle,
  });

  // ─── 자치구별 통합 점수 ───────────────────────────────
  Map<String, double> _compositeScores() {
    final scores = <String, double>{};
    for (final d in seoulDistricts) {
      final saju = calcDistrictScore(d, result.mainOehaeng, result.weakOehaeng).toDouble();
      final extra = districtExtras[d.name];
      if (extra == null) continue;
      final transit = extra.transit.toDouble();
      final amenity = extra.amenity.toDouble();
      final budget = calcBudgetScore(d.name, lifestyle.budgetAk).toDouble();
      // 출근지 보너스
      double commute = 0;
      if (lifestyle.commuteDistrict != '재택/없음') {
        commute = d.name == lifestyle.commuteDistrict ? 20 : (extra.transit - 50) * 0.2;
      }
      final total = (saju * 0.35 + transit * 0.25 + amenity * 0.2 + budget * 0.2) + commute;
      scores[d.name] = total.clamp(0, 100);
    }
    return scores;
  }

  Color _oeColor(String oe) {
    switch (oe) {
      case '목': return AppColors.mokColor;
      case '화': return AppColors.hwaColor;
      case '토': return AppColors.toColor;
      case '금': return AppColors.geumColor;
      case '수': return AppColors.suColor;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compositeScores = _compositeScores();
    final sorted = seoulDistricts
        .where((d) => compositeScores.containsKey(d.name))
        .toList()
      ..sort((a, b) =>
          compositeScores[b.name]!.compareTo(compositeScores[a.name]!));
    final top5 = sorted.take(5).toList();
    final bestDistrict = top5.isNotEmpty ? top5.first : null;
    final homeScores = lifestyle.homeTypeScores(result.mainOehaeng);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('맞춤 분석 결과',
              style: TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 18,
                  color: Colors.white, letterSpacing: 3)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LifestyleInputScreen(
                result: result, profile: profile, existing: lifestyle,
              )),
            ),
            child: const Text('수정', style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 32),
        children: [
          // 프로필 요약
          _buildProfileSummary(context),
          const SizedBox(height: 14),
          // 베스트 동네
          if (bestDistrict != null) _buildBestDistrict(bestDistrict, compositeScores),
          const SizedBox(height: 14),
          // 레이더 차트 (상위 자치구)
          if (bestDistrict != null) _buildRadarCard(bestDistrict),
          const SizedBox(height: 14),
          // 집 유형 추천
          _buildHomeTypeCard(homeScores),
          const SizedBox(height: 14),
          // TOP 5 자치구 랭킹
          _buildTop5Card(top5, compositeScores),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.2),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${profile.name}님의 생활패턴',
              style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 13,
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          _chip('💰 예산', lifestyle.budgetLabel),
          const SizedBox(height: 4),
          _chip('🚇 출근지', lifestyle.commuteDistrict),
          const SizedBox(height: 4),
          Row(children: [
            if (lifestyle.childrenCount > 0) _chip('👶 자녀', '${lifestyle.childrenCount}명'),
            if (lifestyle.childrenCount > 0) const SizedBox(width: 6),
            if (lifestyle.hasPet) _chip('🐾 반려동물', '있음'),
          ]),
        ]),
        const Spacer(),
        OehaengBadge(result.mainOehaeng),
      ]),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _chip(String label, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: ', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      Text(value, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary,
          fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildBestDistrict(DistrictData d, Map<String, double> scores) {
    final score = scores[d.name]!.round();
    final oeColor = _oeColor(d.oehaeng);
    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.5),
      child: Column(children: [
        Row(children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: const Text('🏆 최적 추천 동네',
                style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 13,
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(d.emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.name,
                style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 20,
                    fontWeight: FontWeight.bold, color: oeColor)),
            Text('${d.oehaeng} · ${d.keyword}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text(d.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.4)),
          ])),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
            ),
            child: Text('$score',
                style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 18,
                    fontWeight: FontWeight.bold, color: AppColors.accent)),
          ),
        ]),
      ]),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildRadarCard(DistrictData d) {
    final extra = districtExtras[d.name] ?? const DistrictExtra(70, 70, 5);
    final saju = calcDistrictScore(d, result.mainOehaeng, result.weakOehaeng).toDouble();
    final transit = extra.transit.toDouble();
    final amenity = extra.amenity.toDouble();
    final budget = calcBudgetScore(d.name, lifestyle.budgetAk).toDouble();
    final oeColor = _oeColor(d.oehaeng);

    return TraditionalCard(
      child: Column(children: [
        const KoreanSectionTitle(title: '입지 레이더 분석', showDivider: false),
        const SizedBox(height: 4),
        Text('${d.name} — 4가지 지표 종합',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              radarBorderData: BorderSide(color: oeColor.withOpacity(0.3), width: 1),
              gridBorderData: BorderSide(color: AppColors.divider, width: 0.8),
              tickBorderData: const BorderSide(color: Colors.transparent),
              tickCount: 4,
              ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
              radarBackgroundColor: Colors.transparent,
              titleTextStyle: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11,
                  fontFamily: 'NotoSerifKR'),
              getTitle: (index, angle) {
                const labels = ['사주 적합', '교통', '편의시설', '예산 적합'];
                return RadarChartTitle(text: labels[index], angle: 0);
              },
              dataSets: [
                RadarDataSet(
                  fillColor: oeColor.withOpacity(0.15),
                  borderColor: oeColor,
                  borderWidth: 2,
                  entryRadius: 4,
                  dataEntries: [
                    RadarEntry(value: saju),
                    RadarEntry(value: transit),
                    RadarEntry(value: amenity),
                    RadarEntry(value: budget),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 범례
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _radarLegend('사주 적합', saju.round(), oeColor),
          _radarLegend('교통', transit.round(), AppColors.jade),
          _radarLegend('편의시설', amenity.round(), AppColors.suColor),
          _radarLegend('예산', budget.round(), AppColors.accent),
        ]),
      ]),
    ).animate(delay: 200.ms).fadeIn();
  }

  Widget _radarLegend(String label, int score, Color color) {
    return Column(children: [
      Text('$score', style: TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 16,
          fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildHomeTypeCard(Map<String, int> scores) {
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    const icons = {
      '아파트': '🏢', '오피스텔': '🏙️', '빌라/다세대': '🏘️', '단독주택': '🏡',
    };
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '🏠 집 유형 추천', showDivider: false),
        const SizedBox(height: 10),
        ...sorted.asMap().entries.map((e) {
          final rank = e.key;
          final entry = e.value;
          final color = rank == 0 ? AppColors.accent : AppColors.textSecondary;
          final score = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Text(icons[entry.key] ?? '🏠', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(entry.key,
                      style: TextStyle(fontSize: 13,
                          fontWeight: rank == 0 ? FontWeight.bold : FontWeight.normal,
                          color: color)),
                  if (rank == 0)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('추천',
                          style: TextStyle(fontSize: 9, color: AppColors.accent,
                              fontWeight: FontWeight.bold)),
                    ),
                ]),
                const SizedBox(height: 3),
                KoreanProgressBar(value: score / 100, color: color, height: 5),
              ])),
              const SizedBox(width: 8),
              Text('$score',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ]),
          );
        }),
      ]),
    ).animate(delay: 300.ms).fadeIn();
  }

  Widget _buildTop5Card(List<DistrictData> top5, Map<String, double> scores) {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '📍 맞춤 추천 TOP 5', showDivider: false),
        const SizedBox(height: 10),
        ...top5.asMap().entries.map((e) {
          final rank = e.key + 1;
          final d = e.value;
          final score = scores[d.name]!.round();
          final oeColor = _oeColor(d.oehaeng);
          final extra = districtExtras[d.name];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rank == 1 ? AppColors.accent.withOpacity(0.2) : AppColors.cardBg2,
                  border: Border.all(
                    color: rank == 1 ? AppColors.accent : AppColors.divider),
                ),
                child: Center(child: Text('$rank',
                    style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: rank == 1 ? AppColors.accent : AppColors.textSecondary))),
              ),
              const SizedBox(width: 10),
              Text(d.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: oeColor)),
                if (extra != null)
                  Text('교통 ${extra.transit} · 편의 ${extra.amenity} · 평균 ${extra.avgPriceAk}억',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: oeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: oeColor.withOpacity(0.3)),
                ),
                child: Text('$score점',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: oeColor)),
              ),
            ]),
          );
        }),
      ]),
    ).animate(delay: 400.ms).fadeIn();
  }
}
