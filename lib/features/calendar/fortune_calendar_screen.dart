import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

class FortuneCalendarScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;
  const FortuneCalendarScreen({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  State<FortuneCalendarScreen> createState() =>
      _FortuneCalendarScreenState();
}

class _FortuneCalendarScreenState extends State<FortuneCalendarScreen> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  final Map<DateTime, _DayFortune> _cache = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _buildMonthCache(_focusedMonth);
  }

  // ─── 캐시 빌드 ──────────────────────────────────

  void _buildMonthCache(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      _cache.putIfAbsent(date, () => _compute(date));
    }
  }

  _DayFortune _compute(DateTime date) {
    final gj = SajuCalculator.dayToGanJi(date);
    final dayCg = gj['cheongan']!;
    final dayJi = gj['jiji']!;
    final ss = SajuCalculator.calcSipSeong(widget.result.ilgan, dayCg);
    final jijiRel = _jijiRel(widget.result.ilji, dayJi);
    final isSon = const [9, 10, 19, 20, 29, 30].contains(date.day);
    final score = _score(ss.name, jijiRel, isSon);
    return _DayFortune(
      ganJi: '${gj['cheongan']}${gj['jiji']}',
      sipseong: ss.name,
      jijiRel: jijiRel,
      score: score,
      isSonNone: isSon,
      category: _category(ss.name, isSon, jijiRel),
    );
  }

  String _jijiRel(String ilji, String dayJi) {
    if (SajuCalculator.jijiChung[ilji] == dayJi) return '충(沖)';
    if (SajuCalculator.jijiHap[ilji]?.contains(dayJi) == true) return '합(合)';
    if (SajuCalculator.jijiOehaeng[ilji] ==
        SajuCalculator.jijiOehaeng[dayJi]) return '동(同)';
    if (SajuCalculator.saeng[SajuCalculator.jijiOehaeng[ilji]!] ==
        SajuCalculator.jijiOehaeng[dayJi]) return '생(生)';
    if (SajuCalculator.geuk[SajuCalculator.jijiOehaeng[ilji]!] ==
        SajuCalculator.jijiOehaeng[dayJi]) return '극(剋)';
    return '평(平)';
  }

  int _score(String ss, String jijiRel, bool isSon) {
    const t = {
      '편재': 82, '정재': 79, '정인': 76, '편인': 70, '식신': 72,
      '상관': 58, '정관': 69, '편관': 50, '비견': 55, '겁재': 46,
    };
    int s = t[ss] ?? 60;
    if (jijiRel == '합(合)') s += 12;
    if (jijiRel == '충(沖)') s -= 12;
    if (jijiRel == '생(生)') s += 8;
    if (jijiRel == '극(剋)') s -= 8;
    if (isSon) s += 15;
    return s.clamp(10, 99);
  }

  String _category(String ss, bool isSon, String jijiRel) {
    if (isSon) return '손없는날 ✨';
    if (const ['편재', '정재'].contains(ss)) return '계약·매수 💰';
    if (const ['정인', '편인'].contains(ss)) return '문서·서명 📄';
    if (jijiRel == '합(合)') return '합운·안정 🤝';
    if (jijiRel == '충(沖)') return '변화·이동 ⚡';
    if (const ['편관', '겁재'].contains(ss)) return '분쟁 주의 ⚠️';
    if (const ['식신', '상관'].contains(ss)) return '협상 🗣️';
    return '보통';
  }

  Color _scoreColor(int score) {
    if (score >= 82) return const Color(0xFFCC3300);
    if (score >= 68) return AppColors.accent;
    if (score >= 52) return AppColors.mokColor;
    return AppColors.textSecondary;
  }

  Color _jijiRelColor(String rel) {
    switch (rel) {
      case '합(合)': return AppColors.mokColor;
      case '충(沖)': return AppColors.hwaColor;
      case '생(生)': return AppColors.suColor;
      default: return AppColors.textSecondary;
    }
  }

  // ─── UI ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('운세 캘린더',
              style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 3)),
        ),
      ),
      body: Column(children: [
        _buildLegend(),
        _buildMonthHeader(),
        _buildWeekRow(),
        Expanded(child: _buildGrid()),
        if (_selectedDate != null) _buildDetailPanel(),
      ]),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: AppColors.cardBg2,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legendDot(const Color(0xFFCC3300)), const SizedBox(width: 3),
        const Text('대길', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        _legendDot(AppColors.accent), const SizedBox(width: 3),
        const Text('길', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        _legendDot(AppColors.mokColor), const SizedBox(width: 3),
        const Text('평길', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        _legendDot(AppColors.textSecondary), const SizedBox(width: 3),
        const Text('보통', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text('손', style: TextStyle(fontSize: 7, color: AppColors.accent, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 3),
        const Text('손없는날', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _legendDot(Color color) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(
            bottom: BorderSide(color: AppColors.divider.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 22),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              _buildMonthCache(_focusedMonth);
            }),
          ),
          Column(children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text(
                '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                style: const TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5),
              ),
            ),
            Text(
              '${widget.result.ilgan}일간 기준  ·  일진 운세',
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ]),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 22),
            onPressed: () => setState(() {
              _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              _buildMonthCache(_focusedMonth);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow() {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    return Container(
      color: AppColors.cardBg2,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: days.asMap().entries.map((e) {
          final color = e.key == 0
              ? AppColors.hwaColor
              : e.key == 6
                  ? AppColors.suColor
                  : AppColors.textSecondary;
          return Expanded(
              child: Text(e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold)));
        }).toList(),
      ),
    );
  }

  Widget _buildGrid() {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWd = first.weekday % 7; // 0=일
    final today = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, childAspectRatio: 0.72),
      itemCount: startWd + daysInMonth,
      itemBuilder: (ctx, idx) {
        if (idx < startWd) return const SizedBox.shrink();
        final day = idx - startWd + 1;
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
        final fortune = _cache[date];
        final isToday = date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
        final isSel = _selectedDate != null &&
            date.year == _selectedDate!.year &&
            date.month == _selectedDate!.month &&
            date.day == _selectedDate!.day;
        final wday = date.weekday % 7;
        final color = fortune != null
            ? _scoreColor(fortune.score)
            : AppColors.textSecondary;

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: isSel
                  ? color.withOpacity(0.15)
                  : AppColors.cardBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSel
                    ? color
                    : isToday
                        ? AppColors.accent.withOpacity(0.7)
                        : AppColors.divider.withOpacity(0.3),
                width: isSel ? 1.5 : isToday ? 1.2 : 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday || isSel
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: wday == 0
                        ? AppColors.hwaColor.withOpacity(0.85)
                        : wday == 6
                            ? AppColors.suColor.withOpacity(0.85)
                            : AppColors.textPrimary,
                  ),
                ),
                if (fortune != null) ...[
                  const SizedBox(height: 1),
                  Text(fortune.ganJi,
                      style: TextStyle(
                          fontFamily: 'NotoSerifKR',
                          fontSize: 7.5,
                          color: color)),
                  const SizedBox(height: 2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: fortune.score >= 68
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.45),
                                  blurRadius: 5)
                            ]
                          : null,
                    ),
                  ),
                  if (fortune.isSonNone)
                    Container(
                      margin: const EdgeInsets.only(top: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const Text('손',
                          style: TextStyle(
                              fontSize: 6,
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 하단 상세 패널 ──────────────────────────────

  Widget _buildDetailPanel() {
    final fortune = _cache[_selectedDate!];
    if (fortune == null) return const SizedBox.shrink();
    final color = _scoreColor(fortune.score);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: color.withOpacity(0.45), width: 1.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, -3))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              '${_selectedDate!.month}月 ${_selectedDate!.day}日  ${fortune.ganJi}일',
              style: const TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text('${fortune.score}점',
                style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 5, children: [
          _chip('${fortune.sipseong}일', color),
          _chip(fortune.jijiRel, _jijiRelColor(fortune.jijiRel)),
          _chip(fortune.category, color),
        ]),
        const SizedBox(height: 9),
        Text(_advice(fortune),
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.65)),
      ]),
    ).animate().slideY(begin: 0.15, duration: 200.ms);
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold)),
      );

  String _advice(_DayFortune f) {
    if (f.isSonNone) {
      return '손 없는 날 — 이사·계약 모두 길한 날입니다. 이사나 잔금 치르기에 가장 좋습니다. ✨';
    }
    const m = {
      '편재': '편재일 — 적극적 재물 기운. 부동산 투자 계약 체결에 최적입니다. 빠른 결단이 이득을 가져옵니다. 💰',
      '정재': '정재일 — 안정된 재물운. 실거주 매수 계약이나 장기 임대차 계약에 좋은 날입니다. 🏠',
      '정인': '정인일 — 문서·인감 운이 강합니다. 계약서 서명, 등기 이전, 대출 서류 제출에 최적입니다. 📄',
      '편인': '편인일 — 직관이 예리한 날. 숨겨진 매물 발굴이나 새 정보 수집·임장에 좋습니다. 🔍',
      '식신': '식신일 — 여유롭고 협상력이 높은 날. 매물 조건 조율, 중개인 미팅에 유리합니다. 🤝',
      '상관': '상관일 — 변화를 추구하는 기운. 기존 계약 조건 재협상이나 매도 검토에 적합합니다.',
      '정관': '정관일 — 법적 안정성이 높습니다. 공식 서류 제출, 대출 심사 진행에 좋습니다. ⚖️',
      '편관': '편관일 — 경쟁·압박이 강한 날. 무리한 결정보다 현황 분석에 집중하세요. ⚠️',
      '비견': '비견일 — 경쟁자가 많은 날. 서두르지 말고 조건을 꼼꼼히 검토하세요.',
      '겁재': '겁재일 — 손재·분쟁 가능성. 큰 금전 거래나 계약 체결은 피하는 것이 좋습니다. 🚫',
    };
    String base = m[f.sipseong] ?? '평운의 날. 부동산 정보 수집이나 임장 활동에 활용하세요.';
    if (f.jijiRel == '합(合)') base += ' 지지합으로 운세가 더욱 강화됩니다.';
    if (f.jijiRel == '충(沖)') base += ' 지지충으로 변동 가능성이 있어 신중하게 임하세요.';
    return base;
  }
}

// ─── 데이터 클래스 ──────────────────────────────

class _DayFortune {
  final String ganJi;
  final String sipseong;
  final String jijiRel;
  final int score;
  final bool isSonNone;
  final String category;

  const _DayFortune({
    required this.ganJi,
    required this.sipseong,
    required this.jijiRel,
    required this.score,
    required this.isSonNone,
    required this.category,
  });
}
