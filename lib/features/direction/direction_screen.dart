import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DirectionScreen extends StatefulWidget {
  final SajuResult result;
  const DirectionScreen({super.key, required this.result});

  @override
  State<DirectionScreen> createState() => _DirectionScreenState();
}

class _DirectionScreenState extends State<DirectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinCtrl;

  static const Map<String, double> directionAngles = {
    '동쪽 (東)': 90,
    '남쪽 (南)': 180,
    '서쪽 (西)': 270,
    '북쪽 (北)': 0,
    '중앙 (中)': -1,
  };

  static const Map<String, String> directionDesc = {
    '동쪽 (東)': '목(木) 기운이 강한 동쪽 방향. 성장과 발전의 에너지. 새벽 햇살이 드는 동향집이 길합니다.',
    '남쪽 (南)': '화(火) 기운의 남쪽. 밝고 활기찬 에너지. 남향집의 햇볕과 온기가 사주를 보완해줍니다.',
    '서쪽 (西)': '금(金) 기운의 서쪽. 결실과 수확의 에너지. 석양빛이 드는 서향 고급 주거가 맞습니다.',
    '북쪽 (北)': '수(水) 기운의 북쪽. 지혜와 유연함의 에너지. 한강 북쪽 또는 수변 지역이 길합니다.',
    '중앙 (中)': '토(土) 기운의 중심. 안정과 포용의 에너지. 도심 중앙, 지역 중심지 거주가 길합니다.',
  };

  static const Map<String, String> avoidDirection = {
    '목': '서쪽 (金이 木을 극)',
    '화': '북쪽 (水가 火를 극)',
    '토': '동쪽 (木이 土를 극)',
    '금': '남쪽 (火가 金을 극)',
    '수': '중앙 (土가 水를 극)',
  };

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = widget.result.luckyDirection;
    final oe = widget.result.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);
    final angle = directionAngles[dir] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('方位 推薦',
            style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 18, color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 나침반 UI
            _buildCompass(angle, color).animate().scale(
              duration: 800.ms, curve: Curves.elasticOut,
            ),
            const SizedBox(height: 24),

            // 길한 방향 카드
            TraditionalCard(
              borderColor: color.withOpacity(0.5),
              bgColor: Color.lerp(AppColors.cardBg, color.withOpacity(0.08), 0.5),
              child: Column(children: [
                Text('나의 길한 방향 (吉方)',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary,
                    letterSpacing: 0.5)),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (b) => LinearGradient(
                    colors: [color, color.withOpacity(0.7)]).createShader(b),
                  child: Text(dir, style: const TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 24, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 2,
                  )),
                ),
                const SizedBox(height: 10),
                Text(directionDesc[dir] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary, height: 1.7)),
              ]),
            ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 10),

            // 피할 방향
            TraditionalCard(
              borderColor: AppColors.hwaColor.withOpacity(0.3),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.hwaColor.withOpacity(0.1),
                    border: Border.all(color: AppColors.hwaColor.withOpacity(0.4)),
                  ),
                  child: const Center(child: Text('忌',
                    style: TextStyle(fontFamily: 'NotoSerifKR',
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: AppColors.hwaColor))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('피하면 좋은 방향 (忌方)',
                    style: TextStyle(fontFamily: 'NotoSerifKR',
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, letterSpacing: 0.5)),
                  const SizedBox(height: 3),
                  Text(avoidDirection[oe] ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ])),
              ]),
            ).animate(delay: 400.ms).fadeIn(),

            const SizedBox(height: 16),

            // 5방위 설명
            _buildDirectionGrid(color),

            const SizedBox(height: 20),

            // 실용 팁
            _buildPracticalTips(dir),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass(double angle, Color luckyColor) {
    return SizedBox(
      width: 240, height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          Container(
            width: 240, height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.divider, width: 2),
              boxShadow: [
                BoxShadow(
                  color: luckyColor.withOpacity(0.1),
                  blurRadius: 30, spreadRadius: 5,
                ),
              ],
            ),
          ),
          // 방위 텍스트
          ...['북', '동', '남', '서'].asMap().entries.map((e) {
            final a = e.key * math.pi / 2;
            final r = 95.0;
            return Positioned(
              left: 120 + r * math.sin(a) - 10,
              top: 120 - r * math.cos(a) - 10,
              child: Text(
                e.value,
                style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }),
          // 길한 방향 화살표
          if (angle >= 0)
            AnimatedBuilder(
              animation: _spinCtrl,
              builder: (_, __) {
                final progress = Curves.elasticOut.transform(
                  _spinCtrl.value.clamp(0.0, 1.0),
                );
                return Transform.rotate(
                  angle: (angle * math.pi / 180) * progress,
                  child: Container(
                    width: 8, height: 120,
                    child: Column(children: [
                      Container(
                        width: 0, height: 0,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.transparent, width: 8),
                            right: BorderSide(color: Colors.transparent, width: 8),
                            bottom: BorderSide(color: luckyColor, width: 20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(width: 4, color: luckyColor),
                      ),
                    ]),
                  ),
                );
              },
            ),
          // 중앙 도트
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: luckyColor,
              boxShadow: [BoxShadow(
                color: luckyColor.withOpacity(0.5),
                blurRadius: 8,
              )],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionGrid(Color luckyColor) {
    final directions = ['북쪽 (北)', '동쪽 (東)', '남쪽 (南)', '서쪽 (西)'];
    final oehaengMap = {'북쪽 (北)': '수', '동쪽 (東)': '목', '남쪽 (南)': '화', '서쪽 (西)': '금'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KoreanSectionTitle(title: '방위별 특성 (方位 特性)'),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 2.4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: directions.map((dir) {
            final oe = oehaengMap[dir] ?? '토';
            final c = AppColors.getOehaengColor(oe);
            final isLucky = dir == widget.result.luckyDirection;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isLucky ? c.withOpacity(0.15) : AppColors.cardBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isLucky ? c : AppColors.divider,
                  width: isLucky ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Text(dir.substring(0, 2), style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 13, fontWeight: FontWeight.bold, color: c,
                )),
                const SizedBox(width: 6),
                Text(oe, style: TextStyle(fontSize: 11, color: c.withOpacity(0.8))),
                if (isLucky) ...[
                  const Spacer(),
                  const Text('✨', style: TextStyle(fontSize: 12)),
                ],
              ]),
            );
          }).toList(),
        ),
      ],
    ).animate(delay: 500.ms).fadeIn();
  }

  Widget _buildPracticalTips(String dir) {
    final tips = {
      '동쪽 (東)': ['동향 또는 동남향 집 선택', '창문이 동쪽을 향한 방 사용', '동쪽 지역 (강동, 성동 등) 매수 고려'],
      '남쪽 (南)': ['남향 집 최우선 선택', '거실이 남쪽을 향한 구조', '서울 강남·송파 등 남부 지역 관심'],
      '서쪽 (西)': ['서향 또는 남서향 집 선택', '창문이 서쪽을 향한 방 사용', '서울 마포·은평·양천 등 서부 고려'],
      '북쪽 (北)': ['한강 이북 지역 투자 고려', '수변·강변 아파트 매수', '북한산·도봉 인근 주거지 추천'],
      '중앙 (中)': ['서울 중심가·도심 거주', '지역 중심 상업지구 인근', '교통 허브 인근 역세권 선택'],
    };

    final tipList = tips[dir] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const KoreanSectionTitle(title: '실용 팁 (實用 秘訣)'),
        const SizedBox(height: 10),
        ...tipList.map((t) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            const Text('✦', style: TextStyle(color: AppColors.accent, fontSize: 12)),
            const SizedBox(width: 10),
            Expanded(child: Text(t, style: const TextStyle(
              fontSize: 13, color: AppColors.textPrimary,
            ))),
          ]),
        )),
      ],
    ).animate(delay: 600.ms).fadeIn();
  }
}
