import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

class BuildingCompatScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;
  const BuildingCompatScreen({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  State<BuildingCompatScreen> createState() =>
      _BuildingCompatScreenState();
}

class _BuildingCompatScreenState extends State<BuildingCompatScreen> {
  final _addrCtrl = TextEditingController();
  DateTime? _approvalDate;
  _CompatResult? _compatResult;
  bool _analyzed = false;

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  // ─── 분석 ────────────────────────────────────────

  void _analyze() {
    if (_approvalDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('준공일(사용승인일)을 선택해 주세요')),
      );
      return;
    }
    final bldGj = SajuCalculator.yearToGanJi(_approvalDate!.year);
    final bldCg = bldGj['cheongan']!;
    final bldJi = bldGj['jiji']!;

    final result = _calcCompat(bldCg, bldJi);
    setState(() {
      _compatResult = result;
      _analyzed = true;
    });
  }

  _CompatResult _calcCompat(String bldCg, String bldJi) {
    final ilCg = widget.result.ilgan;
    final ilJi = widget.result.ilji;

    // 천간 관계
    final cgRel = _cheonganRel(ilCg, bldCg);
    // 지지 관계
    final jiRel = _jijiRel(ilJi, bldJi);
    // 십성
    final ss = SajuCalculator.calcSipSeong(ilCg, bldCg);

    // 점수 계산
    int score = _baseScore(cgRel, jiRel, ss.name);

    // 궁합 유형
    final type = _compatType(score, ss.name, jiRel);
    final advice = _advice(score, ss.name, jiRel, cgRel);
    final title = _title(score);

    return _CompatResult(
      bldGanJi: '$bldCg$bldJi',
      sipseong: ss.name,
      cgRel: cgRel,
      jiRel: jiRel,
      score: score,
      title: title,
      type: type,
      advice: advice,
    );
  }

  String _cheonganRel(String il, String bld) {
    // 천간합 (갑기 을경 병신 정임 무계)
    const cgHap = {
      '갑': '기', '기': '갑', '을': '경', '경': '을',
      '병': '신', '신': '병', '정': '임', '임': '정', '무': '계', '계': '무',
    };
    if (cgHap[il] == bld) return '천간합(合)';
    final ilOe = SajuCalculator.cheonganOehaeng[il]!;
    final bldOe = SajuCalculator.cheonganOehaeng[bld]!;
    if (SajuCalculator.saeng[ilOe] == bldOe) return '건물이 생(生)함';
    if (SajuCalculator.geuk[ilOe] == bldOe) return '건물이 극받음(剋)';
    if (SajuCalculator.saeng[bldOe] == ilOe) return '건물이 나를 생(生)';
    if (SajuCalculator.geuk[bldOe] == ilOe) return '건물이 나를 극(剋)';
    if (ilOe == bldOe) return '오행 일치';
    return '평관계';
  }

  String _jijiRel(String ilJi, String bldJi) {
    if (SajuCalculator.jijiChung[ilJi] == bldJi) return '지지충(沖)';
    if (SajuCalculator.jijiHap[ilJi]?.contains(bldJi) == true) return '지지합(合)';
    if (SajuCalculator.jijiOehaeng[ilJi] ==
        SajuCalculator.jijiOehaeng[bldJi]) return '지지 동(同)';
    if (SajuCalculator.saeng[SajuCalculator.jijiOehaeng[ilJi]!] ==
        SajuCalculator.jijiOehaeng[bldJi]) return '지지 상생(生)';
    if (SajuCalculator.geuk[SajuCalculator.jijiOehaeng[ilJi]!] ==
        SajuCalculator.jijiOehaeng[bldJi]) return '지지 상극(剋)';
    return '지지 평(平)';
  }

  int _baseScore(String cgRel, String jiRel, String ss) {
    int s = 60;
    // 천간 관계 보정
    if (cgRel == '천간합(合)') s += 20;
    else if (cgRel == '건물이 나를 생(生)') s += 15;
    else if (cgRel == '건물이 생(生)함') s += 10;
    else if (cgRel == '오행 일치') s += 8;
    else if (cgRel == '건물이 나를 극(剋)') s -= 15;
    else if (cgRel == '건물이 극받음(剋)') s += 5;

    // 지지 관계 보정
    if (jiRel == '지지합(合)') s += 18;
    else if (jiRel == '지지 상생(生)') s += 12;
    else if (jiRel == '지지 동(同)') s += 8;
    else if (jiRel == '지지충(沖)') s -= 20;
    else if (jiRel == '지지 상극(剋)') s -= 10;

    // 십성 보정
    if (const ['편재', '정재'].contains(ss)) s += 10;
    if (const ['정인', '편인'].contains(ss)) s += 8;
    if (const ['편관', '겁재'].contains(ss)) s -= 10;

    return s.clamp(20, 98);
  }

  String _compatType(int score, String ss, String jiRel) {
    if (jiRel == '지지합(合)') return '실거주 최적 🏡';
    if (score >= 80) {
      if (const ['편재', '정재'].contains(ss)) return '투자·매수 최적 💰';
      return '장기 보유 추천 🏠';
    }
    if (score >= 65) return '실거주 적합 🟢';
    if (jiRel == '지지충(沖)') return '단기 투자용 ⚡';
    if (score >= 50) return '보통 궁합 🟡';
    return '신중 검토 필요 ⚠️';
  }

  String _title(int score) {
    if (score >= 85) return '대길 — 천생연분 건물';
    if (score >= 72) return '길 — 좋은 궁합';
    if (score >= 58) return '평길 — 무난한 궁합';
    if (score >= 44) return '주의 — 조건부 거주';
    return '흉 — 신중한 검토 필요';
  }

  String _advice(int score, String ss, String jiRel, String cgRel) {
    final buf = StringBuffer();

    if (jiRel == '지지합(合)' || cgRel == '천간합(合)') {
      buf.write('건물의 기운이 귀하를 감싸 안아 안락한 거주가 예상됩니다. ');
    } else if (jiRel == '지지충(沖)') {
      buf.write('역동적인 기운이 강해 실거주보다는 단기 투자용으로 적합합니다. ');
    } else if (cgRel == '건물이 나를 생(生)') {
      buf.write('건물의 기운이 귀하를 보호하고 성장시켜 줍니다. ');
    } else if (cgRel == '건물이 나를 극(剋)') {
      buf.write('건물의 기운이 다소 강하게 작용하여 주의가 필요합니다. ');
    }

    if (const ['편재', '정재'].contains(ss)) {
      buf.write('재물운을 높여주는 건물로 투자 가치가 높습니다. ');
    } else if (const ['정인', '편인'].contains(ss)) {
      buf.write('학습·안정 기운이 강해 자녀 교육에 유리한 환경입니다. ');
    } else if (ss == '식신') {
      buf.write('생활이 풍요롭고 건강이 증진되는 기운입니다. ');
    } else if (ss == '편관') {
      buf.write('강한 기운이 충돌할 수 있어 인테리어나 배치에 주의하세요. ');
    }

    if (score >= 72) {
      buf.write('입주 후 재물운과 건강운이 상승할 것으로 예상됩니다.');
    } else if (score >= 50) {
      buf.write('적절한 비보(裨補)로 운세를 높일 수 있습니다.');
    } else {
      buf.write('입주 전 전문 풍수 상담을 권장합니다.');
    }

    return buf.toString();
  }

  // ─── UI ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('건물 궁합',
              style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 18,
                  color: Colors.white,
                  letterSpacing: 3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          _buildInputCard().animate().fadeIn(),
          const SizedBox(height: 12),
          if (_analyzed && _compatResult != null)
            _buildResultCard(_compatResult!)
                .animate()
                .fadeIn(delay: 100.ms)
                .slideY(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '건물 정보 입력',
          subtitle: '준공일(사용승인일)로 건물 사주를 계산합니다',
        ),
        const SizedBox(height: 14),

        // 주소 입력
        TextField(
          controller: _addrCtrl,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '예) 서울시 강남구 역삼동 000-00',
            hintStyle: const TextStyle(
                fontSize: 12, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: AppColors.textSecondary, size: 18),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.divider, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.divider, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.6)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 10),

        // 준공일 선택
        GestureDetector(
          onTap: _pickApprovalDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _approvalDate != null
                    ? AppColors.accent.withOpacity(0.6)
                    : AppColors.divider,
                width: _approvalDate != null ? 1 : 0.5,
              ),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_outlined,
                  color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Text(
                _approvalDate != null
                    ? '준공일: ${_approvalDate!.year}년 ${_approvalDate!.month}월 ${_approvalDate!.day}일'
                    : '준공일(사용승인일) 선택 ← 탭하여 입력',
                style: TextStyle(
                  fontSize: 13,
                  color: _approvalDate != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (_approvalDate != null)
                Text(
                  SajuCalculator.yearToGanJi(_approvalDate!.year)['cheongan']! +
                      SajuCalculator.yearToGanJi(_approvalDate!.year)['jiji']!,
                  style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '※ 등기부등본 또는 건축물대장의 "사용승인일"을 입력하세요',
          style: TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _analyze,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBg2,
              side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: const Text('건물 궁합 분석',
                  style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 15,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickApprovalDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: '준공일(사용승인일) 선택',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onSurface: AppColors.textPrimary,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _approvalDate = picked);
  }

  Widget _buildResultCard(_CompatResult r) {
    final color = _scoreColorFor(r.score);
    return TraditionalCard(
      doubleBorder: true,
      borderColor: color.withOpacity(0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 헤더
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text(r.title,
                  style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5)),
            ),
            const SizedBox(height: 3),
            Text(r.type,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold)),
          ]),
          const Spacer(),
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.25), blurRadius: 10)
              ],
            ),
            child: Center(
              child: Text('${r.score}',
                  style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Container(
          height: 1,
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.5), Colors.transparent])),
        ),
        const SizedBox(height: 12),

        // 비교 박스
        Row(children: [
          Expanded(child: _ganjiBox(
              '나의 일주',
              '${widget.result.ilgan}${widget.result.ilji}',
              AppColors.accent)),
          const SizedBox(width: 10),
          Expanded(child: _ganjiBox(
              '건물 년주',
              r.bldGanJi,
              color)),
        ]),
        const SizedBox(height: 10),

        // 관계 칩
        Wrap(spacing: 6, runSpacing: 6, children: [
          _chip(r.sipseong, color),
          _chip(r.cgRel, AppColors.accent.withOpacity(0.8)),
          _chip(r.jiRel, _jijiRelColor(r.jiRel)),
        ]),
        const SizedBox(height: 12),

        // 점수 바
        Row(children: [
          const Text('궁합 점수',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3)),
          const SizedBox(width: 10),
          Expanded(child: KoreanProgressBar(
              value: r.score / 100, color: color, height: 10)),
          const SizedBox(width: 8),
          Text('${r.score}점',
              style: TextStyle(
                  fontFamily: 'NotoSerifKR',
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ]),
        const SizedBox(height: 14),

        // 어드바이스
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: color.withOpacity(0.2), width: 0.8),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💬 ', style: TextStyle(fontSize: 13)),
            Expanded(
              child: Text(r.advice,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                      height: 1.65)),
            ),
          ]),
        ),

        // 추가 팁
        const SizedBox(height: 10),
        _buildTipBox(r),
      ]),
    );
  }

  Widget _ganjiBox(String label, String ganji, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(ganji,
            style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color)),
      ]),
    );
  }

  Widget _buildTipBox(_CompatResult r) {
    final tips = <String>[];
    if (r.jiRel == '지지충(沖)') tips.add('인테리어 소품에 나무(木) 오행 색상(초록·청색)을 더하면 충기를 완화할 수 있습니다.');
    if (r.score < 55) tips.add('현관 방향에 좋아하는 오행의 소품을 배치해 비보(裨補)하면 운세가 향상됩니다.');
    if (r.score >= 75) tips.add('이 건물과 오래 함께 할수록 인연이 깊어지는 상생 궁합입니다. 장기 보유를 추천합니다.');

    if (tips.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.divider.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 ', style: TextStyle(fontSize: 11)),
            Expanded(child: Text(t,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5))),
          ]),
        )).toList(),
      ),
    );
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

  Color _scoreColorFor(int score) {
    if (score >= 80) return const Color(0xFFCC3300);
    if (score >= 65) return AppColors.accent;
    if (score >= 50) return AppColors.mokColor;
    return AppColors.textSecondary;
  }

  Color _jijiRelColor(String rel) {
    if (rel.contains('합')) return AppColors.mokColor;
    if (rel.contains('충')) return AppColors.hwaColor;
    if (rel.contains('생')) return AppColors.suColor;
    return AppColors.textSecondary;
  }
}

// ─── 결과 데이터 클래스 ──────────────────────────

class _CompatResult {
  final String bldGanJi;
  final String sipseong;
  final String cgRel;
  final String jiRel;
  final int score;
  final String title;
  final String type;
  final String advice;

  const _CompatResult({
    required this.bldGanJi,
    required this.sipseong,
    required this.cgRel,
    required this.jiRel,
    required this.score,
    required this.title,
    required this.type,
    required this.advice,
  });
}
