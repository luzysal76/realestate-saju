import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

// ─── 진입점: 4개 카드 묶음 ─────────────────────────

class DailyFortuneSection extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;

  const DailyFortuneSection({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TodayHomeFortuneCard(result: result)
          .animate(delay: 50.ms).fadeIn().slideY(begin: 0.08),
      const SizedBox(height: 10),
      WeeklyMovingCard(result: result)
          .animate(delay: 100.ms).fadeIn().slideY(begin: 0.08),
      const SizedBox(height: 10),
      ContractIndexCard(result: result)
          .animate(delay: 150.ms).fadeIn().slideY(begin: 0.08),
      const SizedBox(height: 10),
      InteriorFortuneCard(result: result)
          .animate(delay: 200.ms).fadeIn().slideY(begin: 0.08),
    ]);
  }
}

// ─── 공통 헬퍼 ───────────────────────────────────

int _dayScore(String ilgan, String ilji, DateTime date) {
  final gj = SajuCalculator.dayToGanJi(date);
  final ss = SajuCalculator.calcSipSeong(ilgan, gj['cheongan']!);
  final isSon = const [9, 10, 19, 20, 29, 30].contains(date.day);
  const t = {
    '편재': 88, '정재': 84, '정인': 82, '편인': 76, '식신': 70,
    '상관': 58, '정관': 74, '편관': 50, '비견': 56, '겁재': 42,
  };
  int s = t[ss.name] ?? 62;
  if (_jijiRel(ilji, gj['jiji']!) == '합(合)') s += 10;
  if (_jijiRel(ilji, gj['jiji']!) == '충(沖)') s -= 12;
  if (isSon) s += 18;
  return s.clamp(10, 99);
}

String _jijiRel(String il, String day) {
  if (SajuCalculator.jijiChung[il] == day) return '충(沖)';
  if (SajuCalculator.jijiHap[il]?.contains(day) == true) return '합(合)';
  return '평(平)';
}

Color _scoreColor(int s) {
  if (s >= 82) return const Color(0xFFCC3300);
  if (s >= 68) return AppColors.accent;
  if (s >= 52) return AppColors.mokColor;
  return AppColors.textSecondary;
}

Widget _chip(String text, Color c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
  decoration: BoxDecoration(
    color: c.withOpacity(0.1),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: c.withOpacity(0.35)),
  ),
  child: Text(text, style: TextStyle(fontSize: 10, color: c, fontWeight: FontWeight.bold)),
);

// ─── 1. 오늘의 집운 ─────────────────────────────

class TodayHomeFortuneCard extends StatelessWidget {
  final SajuResult result;
  const TodayHomeFortuneCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final gj = SajuCalculator.dayToGanJi(today);
    final dayCg = gj['cheongan']!;
    final dayJi = gj['jiji']!;
    final ss = SajuCalculator.calcSipSeong(result.ilgan, dayCg);
    final isSon = const [9, 10, 19, 20, 29, 30].contains(today.day);
    final score = _dayScore(result.ilgan, result.ilji, today);
    final color = _scoreColor(score);

    return TraditionalCard(
      doubleBorder: true,
      borderColor: color.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🏠', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Expanded(child: Text('오늘의 집운',
            style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text('$dayCg$dayJi  $score점',
              style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 12,
                color: color, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          // 원형 점수
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.5), width: 2.5),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
            ),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$score', style: TextStyle(fontFamily: 'NotoSerifKR',
                fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              Text('집운', style: TextStyle(fontSize: 7, color: color.withOpacity(0.8))),
            ])),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 5, children: [
              _chip(ss.name + '일', color),
              if (isSon) _chip('손없는날 ✨', AppColors.accent),
            ]),
            const SizedBox(height: 7),
            Text(_todayAdvice(ss.name, isSon),
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.58)),
          ])),
        ]),
      ]),
    );
  }

  String _todayAdvice(String ss, bool isSon) {
    if (isSon) return '손 없는 날! 이사·계약 모두 길합니다. ✨';
    const m = {
      '편재': '재물 기운 최고조. 적극적 매수 계약에 최적입니다. 💰',
      '정재': '안정된 재물운. 실거주 매수·전세 계약에 좋습니다. 🏠',
      '정인': '문서운 강함. 계약서 서명·등기 이전에 최적입니다. 📄',
      '편인': '직관력이 높은 날. 좋은 매물 발굴에 유리합니다. 🔍',
      '식신': '협상력이 좋은 날. 조건 조율·미팅에 적합합니다. 🤝',
      '상관': '변화를 원하는 날. 조건 재협상·매도 검토에 어울립니다.',
      '정관': '법적 안정성 높음. 대출 심사·공식 서류 제출에 좋습니다. ⚖️',
      '편관': '경쟁이 강한 날. 무리한 결정보다 분석 집중을 권합니다. ⚠️',
      '비견': '경쟁자가 많은 날. 꼼꼼하게 조건을 검토하세요.',
      '겁재': '손재 가능성. 큰 금전 거래·계약은 피하세요. 🚫',
    };
    return m[ss] ?? '평운의 날. 부동산 정보 수집이나 임장에 활용하세요.';
  }
}

// ─── 2. 이번 주 이사운 ───────────────────────────

class WeeklyMovingCard extends StatelessWidget {
  final SajuResult result;
  const WeeklyMovingCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.add(Duration(days: i)));
    const wday = ['일', '월', '화', '수', '목', '금', '토'];

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📦', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('이번 주 이사운',
            style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 4),
        const Text('오늘부터 7일 · 이사하기 좋은 날',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (ctx, i) {
              final d = days[i];
              final gj = SajuCalculator.dayToGanJi(d);
              final score = _dayScore(result.ilgan, result.ilji, d);
              final isSon = const [9, 10, 19, 20, 29, 30].contains(d.day);
              final color = _scoreColor(score);
              final isToday = i == 0;
              final wd = d.weekday % 7;

              return Container(
                width: 54,
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isToday ? color.withOpacity(0.12)
                      : score >= 68 ? color.withOpacity(0.06)
                      : AppColors.cardBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday ? color : color.withOpacity(0.3),
                    width: isToday ? 1.5 : 0.7,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(wday[wd], style: TextStyle(
                      fontSize: 10,
                      color: wd == 0 ? AppColors.hwaColor.withOpacity(0.8)
                          : wd == 6 ? AppColors.suColor.withOpacity(0.8)
                          : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    )),
                    Text('${d.day}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                        color: isToday ? color : AppColors.textPrimary)),
                    Text(gj['cheongan']! + gj['jiji']!,
                      style: TextStyle(fontFamily: 'NotoSerifKR',
                        fontSize: 8, color: color)),
                    const SizedBox(height: 3),
                    Container(width: 6, height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color,
                        boxShadow: score >= 68 ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)] : null)),
                    if (isSon)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text('손', style: TextStyle(
                          fontSize: 6, color: AppColors.accent, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // 이번 주 최고의 날
        Builder(builder: (_) {
          final best = List.generate(7, (i) {
            final d = today.add(Duration(days: i));
            return MapEntry(d, _dayScore(result.ilgan, result.ilji, d));
          })..sort((a, b) => b.value.compareTo(a.value));
          final top = best.first;
          final color = _scoreColor(top.value);
          return Row(children: [
            const Text('⭐ 이번 주 최고: ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${top.key.month}/${top.key.day}일 (${top.value}점)',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ]);
        }),
      ]),
    );
  }
}

// ─── 3. 계약운 지수 ─────────────────────────────

class ContractIndexCard extends StatelessWidget {
  final SajuResult result;
  const ContractIndexCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(5, (i) => today.add(Duration(days: i)));

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('📝', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('계약운 지수',
            style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 4),
        const Text('향후 5일 계약·서명 적합도',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ...days.map((d) {
          final gj = SajuCalculator.dayToGanJi(d);
          final ss = SajuCalculator.calcSipSeong(result.ilgan, gj['cheongan']!);
          final isSon = const [9, 10, 19, 20, 29, 30].contains(d.day);
          final score = _dayScore(result.ilgan, result.ilji, d);
          final color = _scoreColor(score);
          final isToday = d.day == today.day && d.month == today.month;
          const wday = ['일', '월', '화', '수', '목', '금', '토'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 38, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isToday ? '오늘' : '${d.month}/${d.day}',
                    style: TextStyle(fontSize: 11,
                      color: isToday ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                  Text(wday[d.weekday % 7],
                    style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ],
              )),
              const SizedBox(width: 6),
              Text(gj['cheongan']! + gj['jiji']!,
                style: TextStyle(fontFamily: 'NotoSerifKR',
                  fontSize: 11, color: color)),
              const SizedBox(width: 8),
              Expanded(child: KoreanProgressBar(value: score / 100, color: color, height: 8)),
              const SizedBox(width: 8),
              SizedBox(width: 28, child: Text('$score',
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))),
              SizedBox(width: 36, child: Text(
                isSon ? '손없는날' : ss.name,
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted))),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── 4. 인테리어 운세 ────────────────────────────

class InteriorFortuneCard extends StatelessWidget {
  final SajuResult result;
  const InteriorFortuneCard({super.key, required this.result});

  static const _data = {
    '목': _InteriorData(
      color: Color(0xFF4E9E6B), hanja: '木',
      palette: '초록·청녹·원목', direction: '동쪽',
      items: ['화분·실내 식물', '원목 가구', '청록색 쿠션'],
      avoid: '붉은 계열 강조, 금속 소품 과다',
      tip: '거실 동쪽에 화분을 두면 목 기운이 강화됩니다.',
    ),
    '화': _InteriorData(
      color: Color(0xFFD45C3D), hanja: '火',
      palette: '주황·산호·베이지', direction: '남쪽',
      items: ['조명 강화', '캔들·아로마', '따뜻한 톤 패브릭'],
      avoid: '파란·검정 계열 과다, 창문 가림',
      tip: '남향 창문을 밝게 유지하면 화 기운이 살아납니다.',
    ),
    '토': _InteriorData(
      color: Color(0xFFB8954A), hanja: '土',
      palette: '황토·크림·테라코타', direction: '중앙·중심',
      items: ['도자기·토기 소품', '황토 계열 패브릭', '원형 러그'],
      avoid: '파란·청색 강조, 무늬 복잡한 패턴',
      tip: '거실 중앙을 넓게 비우면 토 기운이 안정됩니다.',
    ),
    '금': _InteriorData(
      color: Color(0xFF8899AA), hanja: '金',
      palette: '흰색·은색·아이보리', direction: '서쪽',
      items: ['금속 프레임 소품', '미니멀 선반', '흰색 패브릭'],
      avoid: '붉은 계열, 목재 과다 노출',
      tip: '서쪽 벽을 흰색으로 정리하면 금 기운이 높아집니다.',
    ),
    '수': _InteriorData(
      color: Color(0xFF5577AA), hanja: '水',
      palette: '네이비·파랑·청회색', direction: '북쪽',
      items: ['수족관·분수 소품', '파란 계열 쿠션', '유리 소품'],
      avoid: '황토·노란 계열 과다, 물기 제거 소홀',
      tip: '현관 북쪽에 거울을 두면 수 기운이 활성화됩니다.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final oe = result.mainOehaeng;
    final weak = result.weakOehaeng;
    final d = _data[oe]!;
    final dWeak = _data[weak]!;

    return TraditionalCard(
      doubleBorder: true,
      borderColor: d.color.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🛋️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Expanded(child: Text('인테리어 운세',
            style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: d.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: d.color.withOpacity(0.35)),
            ),
            child: Text('${oe}(${d.hanja}) 기운',
              style: TextStyle(fontFamily: 'NotoSerifKR',
                fontSize: 11, color: d.color, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),

        // 추천 색상 팔레트
        _infoRow('🎨 추천 색상', d.palette, d.color),
        const SizedBox(height: 6),
        _infoRow('🧭 길한 방향', '${d.direction} 벽면·창문', d.color),
        const SizedBox(height: 10),

        // 추천 소품
        const Text('✅ 추천 소품', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        Wrap(spacing: 6, runSpacing: 5, children: d.items
          .map((item) => _chip(item, d.color)).toList()),
        const SizedBox(height: 10),

        // 비보 팁
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: d.color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: d.color.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 ', style: TextStyle(fontSize: 12)),
            Expanded(child: Text(d.tip,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.55))),
          ]),
        ),
        const SizedBox(height: 10),

        // 약한 오행 보완
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cardBg2,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppColors.divider.withOpacity(0.5)),
          ),
          child: Row(children: [
            Text('🔷 ${weak}(${dWeak.hanja}) 보완: ',
              style: TextStyle(fontSize: 11, color: dWeak.color, fontWeight: FontWeight.bold)),
            Expanded(child: Text(dWeak.palette + ' 소품을 소량 배치하면 균형이 잡힙니다.',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          ]),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value, Color color) => Row(children: [
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    const SizedBox(width: 8),
    Text(value, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
  ]);
}

class _InteriorData {
  final Color color;
  final String hanja;
  final String palette;
  final String direction;
  final List<String> items;
  final String avoid;
  final String tip;

  const _InteriorData({
    required this.color,
    required this.hanja,
    required this.palette,
    required this.direction,
    required this.items,
    required this.avoid,
    required this.tip,
  });
}
