import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../core/saju/shinsal.dart';
import '../../shared/models/saju_profile.dart';
import '../moving/moving_screen.dart';
import '../direction/direction_screen.dart';
import '../timing/timing_screen.dart';
import '../input/input_screen.dart';
import '../profile/profile_select_screen.dart';
import '../settings/settings_screen.dart';
import 'saju_detail_screen.dart';
import 'shinsal_card.dart';
import '../location/location_card.dart';
import '../share/share_card.dart';
import '../share/floor_unit_screen.dart';
import '../calendar/fortune_calendar_screen.dart';
import '../building/building_compat_screen.dart';
import '../map/fortune_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  final SajuProfile profile;
  const DashboardScreen({super.key, required this.profile});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late SajuResult _result;

  @override
  void initState() {
    super.initState();
    _result = SajuCalculator.calculate(
      birthDate: widget.profile.birthDate,
      birthHour: widget.profile.birthHour == 25 ? 12 : widget.profile.birthHour,
      birthMinute: widget.profile.birthMinute,
      birthLongitude: widget.profile.birthLongitude,
      gender: widget.profile.gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              expandedHeight: 160,
              floating: false, pinned: true,
              backgroundColor: AppColors.surface,
              flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
              actions: [
                // 공유 카드 버튼
                IconButton(
                  icon: const Icon(Icons.card_giftcard_outlined, size: 20),
                  tooltip: 'SNS 공유 카드',
                  onPressed: () => ShareCardUtil.shareCard(
                    context: context,
                    result: _result,
                    name: widget.profile.name,
                    cardType: 'direction',
                  ),
                ),
                // 텍스트 공유 버튼
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: '사주 공유',
                  onPressed: _shareSaju,
                ),
                // 프로필 목록 (여러 프로필이 있을 때)
                if (Hive.box<SajuProfile>('profiles').length > 1)
                  IconButton(
                    icon: const Icon(Icons.people_outline, size: 20),
                    tooltip: '프로필 선택',
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const ProfileSelectScreen())),
                  ),
                IconButton(
                  icon: const Icon(Icons.cloud_outlined, size: 20),
                  tooltip: '설정/백업',
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: '프로필 변경',
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const InputScreen())),
                ),
              ],
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
            children: [
              _buildTodayCard(),
              const SizedBox(height: 8),
              _buildQuickStats(),
              const SizedBox(height: 10),
              _buildSajuPillar(),
              const SizedBox(height: 10),
              _buildSipSeongCard(),
              const SizedBox(height: 10),
              _buildOehaengBar(),
              const SizedBox(height: 10),
              _buildPropertyCard(),
              const SizedBox(height: 10),
              _buildLocationCard(),
              const SizedBox(height: 10),
              _buildDaeWunCard(),
              const SizedBox(height: 10),
              _buildSeWunCard(),
              const SizedBox(height: 10),
              _buildShinSalCard(),
              const SizedBox(height: 10),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 오늘 일진 히어로 카드 ────────────────────────

  Widget _buildTodayCard() {
    final today = DateTime.now();
    final todayGj = SajuCalculator.dayToGanJi(today);
    final cg = todayGj['cheongan']!;
    final ji = todayGj['jiji']!;
    final oe = todayGj['oehaeng_cheongan']!;
    final color = AppColors.getOehaengColor(oe);
    final ss = SajuCalculator.calcSipSeong(_result.ilgan, cg);
    final gongmang = _result.shinSalResult.gongmang;
    final isGongmang = gongmang.contains(ji);
    final jijiRelation = _getJijiRelation(_result.ilji, ji);
    final verdict = _getTodayVerdict(ss.name, jijiRelation, isGongmang);
    final score = _getTodayScore(ss.name, jijiRelation, isGongmang);

    return GestureDetector(
      onTap: () => _showTodayDetail(context, cg, ji, oe, ss, jijiRelation, isGongmang, color),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(AppColors.cardBg, color, 0.18)!,
              Color.lerp(AppColors.cardBg, AppColors.surface, 0.35)!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 4),
          )],
        ),
        child: Stack(children: [
          // 배경 광원
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── 라벨 ──
              Row(children: [
                Container(width: 14, height: 1, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('오늘의 부동산 일진', style: TextStyle(
                  fontSize: 10, color: AppColors.accent, letterSpacing: 2)),
              ]),
              const SizedBox(height: 12),
              // ── 메인 영역 ──
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // 간지 박스
                Container(
                  width: 60, height: 68,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.45)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(cg, style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 22, fontWeight: FontWeight.bold, color: color,
                      shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 8)],
                    )),
                    Container(width: 28, height: 0.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: color.withOpacity(0.4)),
                    Text(ji, style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
                  ]),
                ),
                const SizedBox(width: 12),
                // 판정 내용
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(verdict.emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Expanded(child: Text(verdict.label, style: const TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 12, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary, letterSpacing: 0.3,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 5),
                    Wrap(spacing: 4, runSpacing: 4, children: [
                      SipSeongBadge(name: ss.name,
                        color: _sipSeongColorFor(ss.name), small: true),
                      if (isGongmang) _miniTag('공망', AppColors.hwaColor),
                      if (jijiRelation.isNotEmpty)
                        _miniTag(jijiRelation,
                          jijiRelation.contains('합') ? AppColors.mokColor : AppColors.hwaColor),
                    ]),
                    const SizedBox(height: 6),
                    Text(verdict.tip, style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                )),
                const SizedBox(width: 8),
                // 점수 숫자
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$score', style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 42, fontWeight: FontWeight.w900,
                    color: _scoreColorForToday(score), height: 1,
                    shadows: [Shadow(
                      color: _scoreColorForToday(score).withOpacity(0.4),
                      blurRadius: 12)],
                  )),
                  Text('TODAY', style: TextStyle(
                    fontSize: 8,
                    color: _scoreColorForToday(score).withOpacity(0.7),
                    letterSpacing: 2)),
                ]),
              ]),
              const SizedBox(height: 10),
              // ── 하단 날짜 ──
              Row(children: [
                Text('${today.month}월 ${today.day}일',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                const Spacer(),
                const Text('상세 ›',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ]),
            ]),
          ),
        ]),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05);
  }

  String _getJijiRelation(String ilji, String todayJi) {
    // 주요 합·충 체크 (간략화)
    const hap = {
      '자': '축', '축': '자', '인': '해', '해': '인',
      '묘': '술', '술': '묘', '진': '유', '유': '진',
      '사': '신', '신': '사', '오': '미', '미': '오',
    };
    const chung = {
      '자': '오', '오': '자', '축': '미', '미': '축',
      '인': '신', '신': '인', '묘': '유', '유': '묘',
      '진': '술', '술': '진', '사': '해', '해': '사',
    };
    if (hap[ilji] == todayJi) return '합(合)';
    if (chung[ilji] == todayJi) return '충(沖)';
    return '';
  }

  _TodayVerdict _getTodayVerdict(String ssName, String jijiRel, bool isGongmang) {
    if (isGongmang) {
      return _TodayVerdict(
        label: '오늘은 공망일 — 큰 결정 보류',
        emoji: '🕳',
        tip: '공망(空亡)일입니다. 계약서 서명, 계약금 지급 등 중요한 부동산 결정은 다음날로 미루세요.',
        borderColor: AppColors.hwaColor.withOpacity(0.6),
      );
    }
    if (jijiRel == '충(沖)') {
      return _TodayVerdict(
        label: '충(沖) 주의 — 활동 자제',
        emoji: '⚡',
        tip: '오늘 일지가 내 일지와 충(沖)합니다. 새로운 계약이나 큰 결정보다 정보 수집에 집중하세요.',
        borderColor: const Color(0xFFCC6600).withOpacity(0.7),
      );
    }
    // 십성 기반 판단
    const goodSs = ['식신', '정재', '정관', '정인'];
    const badSs = ['겁재', '편관', '상관'];
    const goodLabel = '부동산 활동에 좋은 날';
    const badLabel = '신중하게 접근하는 날';

    if (goodSs.contains(ssName)) {
      final tip = ssName == '정재'
          ? '재성(財星)이 강한 날. 매물 탐색, 가격 협상에 유리합니다. 계약 진행도 길합니다.'
          : ssName == '정관'
          ? '관성(官星)이 강한 날. 권리분석, 등기부 확인 등 법적 절차 진행에 좋습니다.'
          : ssName == '식신'
          ? '식신(食神)일. 창의적 발상이 살아나는 날. 새로운 매물 탐색, 임장 활동에 최적입니다.'
          : '인성(印星)일. 계약서 검토, 정보 분석, 전문가 상담에 적합한 날입니다.';
      return _TodayVerdict(
        label: goodLabel,
        emoji: '🟢',
        tip: tip,
        borderColor: AppColors.mokColor.withOpacity(0.7),
      );
    }
    if (badSs.contains(ssName)) {
      final tip = ssName == '겁재'
          ? '겁재(劫財)일. 경쟁자 출현 가능성이 높습니다. 중요 결정보다 시장 동향 파악에 집중하세요.'
          : ssName == '편관'
          ? '편관(偏官)일. 변수와 돌발 상황이 생길 수 있습니다. 기존 계획 재검토를 권합니다.'
          : '상관(傷官)일. 언행이 과해질 수 있습니다. 협상 자리에서 과도한 주장을 삼가세요.';
      return _TodayVerdict(
        label: badLabel,
        emoji: '🟡',
        tip: tip,
        borderColor: const Color(0xFFB8860B).withOpacity(0.6),
      );
    }
    // 합인 경우
    if (jijiRel == '합(合)') {
      return _TodayVerdict(
        label: '지지합(合) — 좋은 인연의 날',
        emoji: '🤝',
        tip: '오늘 지지가 내 일지와 합(合)을 이룹니다. 중개인·파트너와 인연이 잘 맺어지는 날입니다.',
        borderColor: AppColors.accent.withOpacity(0.6),
      );
    }
    return _TodayVerdict(
      label: '평범한 날 — 꾸준히 진행',
      emoji: '⚪',
      tip: '오늘은 특별한 길흉이 없는 평일입니다. 꾸준한 매물 탐색과 정보 수집을 이어가세요.',
      borderColor: AppColors.divider,
    );
  }

  void _showTodayDetail(BuildContext ctx, String cg, String ji, String oe,
      SipSeong ss, String jijiRel, bool isGongmang, Color color) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: AppColors.divider),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // 핸들
          Container(width: 36, height: 3,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: const Text('오늘 일진 상세',
              style: TextStyle(fontFamily: 'NotoSerifKR',
                fontSize: 16, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 2)),
          ),
          const SizedBox(height: 12),
          // 간지 + 오행 정보
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 60, height: 66,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(cg, style: TextStyle(fontFamily: 'NotoSerifKR',
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: color.withOpacity(0.3)),
                Text(ji, style: const TextStyle(fontFamily: 'NotoSerifKR',
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
              ]),
            ),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _detailRow('오행', oe, color),
              _detailRow('일간과 십성', ss.name, _sipSeongColorFor(ss.name)),
              if (jijiRel.isNotEmpty)
                _detailRow('일지와의 관계', jijiRel,
                  jijiRel.contains('합') ? AppColors.mokColor : AppColors.hwaColor),
              if (isGongmang)
                _detailRow('공망', '공망일 ⚠️', AppColors.hwaColor),
            ]),
          ]),
          const SizedBox(height: 14),
          Container(height: 0.5, color: AppColors.divider),
          const SizedBox(height: 12),
          Text(ss.shortDesc, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          const SizedBox(height: 8),
          Text('지장간: ${JijangGan.get(ji).join(" · ")}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5)),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text('$label  ', style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary)),
      Text(value, style: TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    ]),
  );

  Color _sipSeongColorFor(String ss) {
    const c = {
      '비견': Color(0xFF5B9BD5), '겁재': Color(0xFF3A7CC2),
      '식신': Color(0xFF4E9E6B), '상관': Color(0xFF3A8957),
      '편재': Color(0xFFD4A017), '정재': Color(0xFFC89010),
      '편관': Color(0xFFCC3300), '정관': Color(0xFFAA2200),
      '편인': Color(0xFF9B59A8), '정인': Color(0xFF8B4599),
    };
    return c[ss] ?? AppColors.textSecondary;
  }

  // ─── 공유 ─────────────────────────────────────────

  void _shareSaju() {
    final r = _result;
    final p = widget.profile;
    final currentYear = DateTime.now().year;
    final dw = r.currentDaeWun(currentYear, p.birthDate.year);
    final sw = r.seWunList.isEmpty
        ? null
        : r.seWunList.firstWhere(
            (s) => s.year == currentYear,
            orElse: () => r.seWunList.first,
          );

    final buf = StringBuffer();
    buf.writeln('🏠 부동산 사주 분석 — ${p.name}');
    buf.writeln('─' * 24);
    buf.writeln('📅 생년: ${p.birthDate.year}년 ${p.birthDate.month}월 ${p.birthDate.day}일  ${p.gender}성');
    buf.writeln();
    buf.writeln('【사주팔자】');
    buf.writeln('연주: ${r.yearGj['cheongan']}${r.yearGj['jiji']}  '
        '월주: ${r.monthGj['cheongan']}${r.monthGj['jiji']}  '
        '일주: ${r.dayGj['cheongan']}${r.dayGj['jiji']}  '
        '시주: ${r.hourGj['cheongan']}${r.hourGj['jiji']}');
    buf.writeln('주 오행: ${r.mainOehaeng}  격국: ${r.sipSeongAnalysis.formatDesc}');
    buf.writeln();
    buf.writeln('【부동산 궁합】');
    final info = r.propertyInfo;
    buf.writeln('유형: ${info['type']}');
    buf.writeln('타이밍: ${info['timing']}');
    buf.writeln('길한 방향: ${r.luckyDirection}');
    buf.writeln();
    if (dw != null) {
      buf.writeln('【현재 대운 (${dw.age}~${dw.endAge}세)】');
      buf.writeln('${dw.cheongan}${dw.jiji} — ${dw.sipSeong.name}  투자지수: ${dw.investmentScore}');
      buf.writeln(dw.propertyTip);
      buf.writeln();
    }
    if (sw != null) {
      buf.writeln('【$currentYear년 세운】');
      buf.writeln('${sw.ganJiStr} — ${sw.sipSeong.name}  투자지수: ${sw.investmentScore}');
      buf.writeln(sw.buyOrSell);
      buf.writeln();
    }
    if (r.shinSalResult.isSamjaeYear) {
      buf.writeln('⚠️ 올해 삼재(三災)입니다. 큰 거래는 신중히.');
    }
    if (r.shinSalResult.gongmang.isNotEmpty) {
      buf.writeln('🕳 공망: ${r.shinSalResult.gongmang.join("·")}');
    }
    buf.writeln();
    buf.writeln('📱 부동산 사주 앱에서 생성된 분석 결과입니다.');

    Share.share(buf.toString(), subject: '${p.name}님의 부동산 사주 분석');
  }

  // ─── 헤더 ─────────────────────────────────────────

  Widget _buildHeader() {
    final oe = _result.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);
    return Container(
      decoration: BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 14),
      child: Stack(children: [
        // 배경 단청 패턴 (미묘하게)
        Positioned.fill(
          child: CustomPaint(
            painter: const DancheongPatternPainter(opacity: 0.02),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // 오행 원형 뱃지
              OehaengBadge(oe, large: true),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 이름 (금빛)
                  ShaderMask(
                    shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                    child: Text(
                      widget.profile.name,
                      style: const TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 20, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.profile.birthDate.year}년생  ${widget.profile.gender}성'
                    '${widget.profile.birthCity != null ? '  📍${widget.profile.birthCity}' : ''}',
                    style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _result.sipSeongAnalysis.formatDesc,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 11, color: color.withOpacity(0.8),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              )),
              // 격국 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(children: [
                  Text(_oehaengHanja(oe), style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: color,
                  )),
                  Text('$oe 기운', style: TextStyle(
                    fontSize: 9, color: color.withOpacity(0.8),
                    letterSpacing: 0.5,
                  )),
                ]),
              ),
            ]),
          ],
        ),
      ]),
    );
  }

  // ─── 사주팔자 + 십성 배지 ──────────────────────────

  Widget _buildSajuPillar() {
    final pillars = [
      {'label': '연주(年柱)', 'data': _result.yearGj},
      {'label': '월주(月柱)', 'data': _result.monthGj},
      {'label': '일주(日柱)', 'data': _result.dayGj},
      {'label': '시주(時柱)', 'data': _result.hourGj},
    ];
    final ilgan = _result.ilgan;

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => SajuDetailScreen(
            result: _result, profile: widget.profile))),
      child: TraditionalCard(
        doubleBorder: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const KoreanSectionTitle(title: '사주팔자 (四柱八字)', showDivider: false),
            const Spacer(),
            Text('상세 ›', style: TextStyle(
              fontSize: 11, color: AppColors.accent.withOpacity(0.8),
              letterSpacing: 0.5,
            )),
          ]),
          const SizedBox(height: 4),
          Container(height: 1, decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.accent, Colors.transparent]),
          )),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: pillars.asMap().entries.map((e) {
              final idx = e.key;
              final p = e.value;
              final data = p['data'] as Map<String, String>;
              final oe = data['oehaeng_cheongan']!;
              final color = AppColors.getOehaengColor(oe);
              final cg = data['cheongan']!;

              String ssLabel = '일간';
              Color ssColor = AppColors.accent;
              String? jijiSsLabel;
              Color? jijiSsColor;

              if (idx != 2) {
                // 천간 십성
                final ss = SajuCalculator.calcSipSeong(ilgan, cg);
                ssLabel = ss.name;
                ssColor = _sipSeongColor(ss.name);
                // 지지 십성 (주기 기준)
                final jijiStr = data['jiji']!;
                final mainCg = SajuCalculator.jijiMainCg[jijiStr];
                if (mainCg != null) {
                  final jijiSs = SajuCalculator.calcSipSeong(ilgan, mainCg);
                  jijiSsLabel = jijiSs.name;
                  jijiSsColor = _sipSeongColor(jijiSs.name);
                }
              }

              return PillarCard(
                cheongan: cg,
                jiji: data['jiji']!,
                label: (p['label'] as String).split('(')[0],
                color: color,
                sipSeongLabel: ssLabel,
                sipSeongColor: ssColor,
                jijiSipSeongLabel: jijiSsLabel,
                jijiSipSeongColor: jijiSsColor,
              );
            }).toList(),
          ),
        ]),
      ),
    ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.1);
  }

  Color _sipSeongColor(String ss) {
    const c = {
      '비견': Color(0xFF5B9BD5), '겁재': Color(0xFF3A7CC2),
      '식신': Color(0xFF4E9E6B), '상관': Color(0xFF3A8957),
      '편재': Color(0xFFD4A017), '정재': Color(0xFFC89010),
      '편관': Color(0xFFCC3300), '정관': Color(0xFFAA2200),
      '편인': Color(0xFF9B59A8), '정인': Color(0xFF8B4599),
    };
    return c[ss] ?? AppColors.textSecondary;
  }

  // ─── 십성 격국 카드 ──────────────────────────────

  Widget _buildSipSeongCard() {
    final ana = _result.sipSeongAnalysis;
    final dom = ana.dominant;
    final color = _sipSeongColor(dom);

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '십성 분석 (十星)'),
        const SizedBox(height: 12),
        Row(children: [
          // 격국 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(children: [
              Text(_sipSeongEmoji(dom), style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text(ana.formatDesc, style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 12, fontWeight: FontWeight.bold, color: color,
                letterSpacing: 0.5,
              )),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(ana.personalityDesc, style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary, height: 1.4))),
        ]),
        const SizedBox(height: 10),
        // 십성 분포
        Wrap(
          spacing: 5, runSpacing: 5,
          children: ana.count.entries
              .where((e) => e.value > 0)
              .map((e) => SipSeongBadge(
                name: '${e.key} ×${e.value}',
                color: _sipSeongColor(e.key),
                small: true,
              )).toList(),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🏠', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 7),
            Expanded(child: Text(ana.propertyTips, style: const TextStyle(
              fontSize: 12, color: AppColors.textPrimary, height: 1.5))),
          ]),
        ),
      ]),
    ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1);
  }

  String _sipSeongEmoji(String ss) {
    const e = {
      '비견': '💪', '겁재': '⚔️', '식신': '🍀', '상관': '🎨',
      '편재': '💰', '정재': '💎', '편관': '🔥', '정관': '⚖️',
      '편인': '🔮', '정인': '📚',
    };
    return e[ss] ?? '✨';
  }

  // ─── 오행 분포 ───────────────────────────────────

  Widget _buildOehaengBar() {
    final scores = _result.oehaengScore;
    final oeOrder = ['목', '화', '토', '금', '수'];
    final maxScore = scores.values.fold(0, (a, b) => a > b ? a : b);
    final mainOe = _result.mainOehaeng;
    final mainColor = AppColors.getOehaengColor(mainOe);

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '오행 분포 (五行)'),
        const SizedBox(height: 12),

        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // ─── 레이더 차트 ─────────────────────────
          SizedBox(
            width: 130, height: 130,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                dataSets: [
                  RadarDataSet(
                    dataEntries: oeOrder.map((oe) =>
                      RadarEntry(value: (scores[oe] ?? 0).toDouble())).toList(),
                    fillColor: mainColor.withOpacity(0.25),
                    borderColor: mainColor,
                    borderWidth: 1.5,
                    entryRadius: 2,
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: AppColors.divider.withOpacity(0.5), width: 0.5),
                tickCount: 2,
                ticksTextStyle: const TextStyle(fontSize: 0, color: Colors.transparent),
                tickBorderData: BorderSide(
                  color: AppColors.divider.withOpacity(0.3), width: 0.5),
                gridBorderData: BorderSide(
                  color: AppColors.divider.withOpacity(0.3), width: 0.5),
                getTitle: (idx, angle) {
                  const oeHanja = ['木', '火', '土', '金', '水'];
                  const oeKor   = ['목',  '화',  '토',  '금',  '수'];
                  final oe = oeKor[idx];
                  final color = AppColors.getOehaengColor(oe);
                  return RadarChartTitle(
                    text: oeHanja[idx],
                    angle: 0,
                    positionPercentageOffset: 0.1,
                  );
                },
                titleTextStyle: const TextStyle(
                  fontFamily: 'NotoSerifKR',
                  fontSize: 10, color: AppColors.textSecondary),
                titlePositionPercentageOffset: 0.12,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ─── 바 리스트 ───────────────────────────
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: oeOrder.map((oe) {
              final val = scores[oe] ?? 0;
              final ratio = maxScore > 0 ? val / maxScore : 0.0;
              final color = AppColors.getOehaengColor(oe);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  OehaengBadge(oe),
                  const SizedBox(width: 6),
                  Expanded(child: KoreanProgressBar(value: ratio, color: color, height: 6)),
                  const SizedBox(width: 6),
                  SizedBox(width: 18, child: Text('$val',
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold))),
                ]),
              );
            }).toList(),
          )),
        ]),
      ]),
    ).animate(delay: 230.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 부동산 궁합 ─────────────────────────────────

  Widget _buildPropertyCard() {
    final info = _result.propertyInfo;
    final color = AppColors.getOehaengColor(_result.mainOehaeng);
    return TraditionalCard(
      borderColor: color.withOpacity(0.4),
      bgColor: Color.lerp(AppColors.cardBg, color.withOpacity(0.08), 0.5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          KoreanSectionTitle(
            title: '부동산 궁합',
            icon: '🏡',
            showDivider: false,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(info['keyword']!, style: TextStyle(
              fontFamily: 'NotoSerifKR',
              color: color, fontSize: 11, fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            )),
          ),
        ]),
        Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(gradient: LinearGradient(
            colors: [color.withOpacity(0.5), Colors.transparent]))),
        _infoRow('유형', info['type']!),
        _infoRow('타이밍', info['timing']!),
        _infoRow('방향', _result.luckyDirection),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Text(info['desc']!, style: const TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 12, color: AppColors.textPrimary, height: 1.6)),
        ),
      ]),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 입지 추천 가로 스크롤 ──────────────────────────

  Widget _buildLocationCard() {
    return TraditionalCard(
      doubleBorder: true,
      child: LocationScrollCard(result: _result),
    ).animate(delay: 310.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 현재 대운 ───────────────────────────────────

  Widget _buildDaeWunCard() {
    final currentYear = DateTime.now().year;
    final dw = _result.currentDaeWun(currentYear, widget.profile.birthDate.year);
    if (dw == null) return const SizedBox();
    final color = AppColors.getOehaengColor(dw.oehaeng);
    final ssColor = _sipSeongColor(dw.sipSeong.name);

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        KoreanSectionTitle(
          title: '현재 대운 (${dw.age}~${dw.endAge}세)',
          subtitle: '${dw.year}년 ~ ${dw.year + 9}년',
        ),
        const SizedBox(height: 12),
        Row(children: [
          // 간지 카드
          PillarCard(
            cheongan: dw.cheongan,
            jiji: dw.jiji,
            label: '대운',
            color: color,
            sipSeongLabel: dw.sipSeong.name,
            sipSeongColor: ssColor,
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SipSeongBadge(name: dw.sipSeong.name, color: ssColor),
            const SizedBox(height: 6),
            Text(dw.propertyTip, style: const TextStyle(
              fontSize: 12, color: AppColors.textPrimary, height: 1.5)),
            const SizedBox(height: 8),
            // 점수 바
            Row(children: [
              Expanded(child: KoreanProgressBar(
                value: dw.investmentScore / 100,
                color: getScoreColor(dw.investmentScore),
              )),
              const SizedBox(width: 8),
              Text('${dw.investmentScore}', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: getScoreColor(dw.investmentScore),
              )),
            ]),
            const SizedBox(height: 2),
            Text(getScoreKorean(dw.investmentScore), style: TextStyle(
              fontSize: 10, color: getScoreColor(dw.investmentScore).withOpacity(0.8),
              letterSpacing: 0.5,
            )),
          ])),
        ]),
      ]),
    ).animate(delay: 370.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 세운 (연도별 운세) — 컴팩트 테이블 ────────────

  Widget _buildSeWunCard() {
    final seWunList = _result.seWunList;
    if (seWunList.isEmpty) return const SizedBox();

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const KoreanSectionTitle(
            title: '세운 — 연도별 운세 (歲運)',
            subtitle: '가까운 6년간 부동산 흐름',
            showDivider: false,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TimingScreen(result: _result, profile: widget.profile))),
            child: Text('더보기 ›', style: TextStyle(
              fontSize: 11, color: AppColors.accent.withOpacity(0.8))),
          ),
        ]),
        Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [AppColors.accent, Colors.transparent]))),
        ...seWunList.take(6).map((sw) {
          final color = AppColors.getOehaengColor(sw.oehaeng);
          final ssColor = _sipSeongColor(sw.sipSeong.name);
          final isNow = sw.year == DateTime.now().year;
          return Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isNow
                ? color.withOpacity(0.1)
                : AppColors.surface.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isNow ? color.withOpacity(0.4) : AppColors.divider.withOpacity(0.5),
                width: isNow ? 1 : 0.5,
              ),
            ),
            child: Row(children: [
              SizedBox(width: 44, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${sw.year}', style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold,
                    color: isNow ? color : AppColors.textPrimary)),
                  Text(sw.ganJiStr, style: TextStyle(
                    fontFamily: 'NotoSerifKR', fontSize: 10, color: color)),
                ],
              )),
              SipSeongBadge(name: sw.sipSeong.name, color: ssColor, small: true),
              const SizedBox(width: 8),
              Expanded(child: Text(sw.buyOrSell, style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary, height: 1.2))),
              Text('${sw.investmentScore}', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: getScoreColor(sw.investmentScore))),
            ]),
          );
        }),
      ]),
    ).animate(delay: 440.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 신살 카드 ──────────────────────────────────

  Widget _buildShinSalCard() {
    return ShinSalCard(shinSal: _result.shinSalResult)
        .animate(delay: 500.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 빠른 메뉴 ──────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': '移徙', 'title': '이사 길일', 'sub': '손 없는 날',
       'screen': MovingScreen(result: _result)},
      {'label': '方位', 'title': '방위 추천', 'sub': '길한 방향',
       'screen': DirectionScreen(result: _result)},
      {'label': '賣買', 'title': '매매 타이밍', 'sub': '운세 분석',
       'screen': TimingScreen(result: _result, profile: widget.profile)},
      {'label': '層數', 'title': '층수·호수', 'sub': '궁합 분석',
       'screen': FloorUnitScreen(result: _result, name: widget.profile.name)},
      {'label': '曆', 'title': '운세 캘린더', 'sub': '일진 분석', 'isNew': true,
       'screen': FortuneCalendarScreen(result: _result, profile: widget.profile)},
      {'label': '建物', 'title': '건물 궁합', 'sub': '준공일 분석', 'isNew': true,
       'screen': BuildingCompatScreen(result: _result, profile: widget.profile)},
      {'label': '地圖', 'title': '입지 히트맵', 'sub': '자치구 분석', 'isNew': true,
       'screen': FortuneMapScreen(result: _result, profile: widget.profile)},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const KoreanSectionTitle(title: '천명 메뉴 (天命)'),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 6, mainAxisSpacing: 6,
        childAspectRatio: 0.82,
        children: actions.asMap().entries.map((e) {
          final idx = e.key;
          final a = e.value;
          return GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => a['screen'] as Widget)),
            child: TraditionalCard(
              padding: EdgeInsets.zero,
              child: Stack(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ShaderMask(
                      shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                      child: Text(a['label'] as String, style: const TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 2,
                      )),
                    ),
                    const SizedBox(height: 6),
                    Text(a['title'] as String, style: const TextStyle(
                      fontFamily: 'NotoSerifKR', fontSize: 12,
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    )),
                    const SizedBox(height: 2),
                    Text(a['sub'] as String, style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
                  ]),
                ),
                if (a['isNew'] == true)
                  Positioned(
                    top: 5, right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.hwaColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('NEW',
                        style: TextStyle(fontSize: 7, color: Colors.white,
                          fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  ),
              ]),
            ),
          ).animate(delay: Duration(milliseconds: 500 + idx * 80))
            .fadeIn().scale(begin: const Offset(0.92, 0.92));
        }).toList(),
      ),
    ]);
  }

  // ─── 빠른 지표 3열 ──────────────────────────────────

  Widget _buildQuickStats() {
    final currentYear = DateTime.now().year;
    final dw = _result.currentDaeWun(currentYear, widget.profile.birthDate.year);
    final sw = _result.seWunList.isEmpty ? null :
      _result.seWunList.firstWhere(
        (s) => s.year == currentYear, orElse: () => _result.seWunList.first);
    final oe = _result.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);
    const dirHanja = {'목': '東', '화': '南', '토': '中', '금': '西', '수': '北'};

    return Row(children: [
      Expanded(child: _statCard(
        icon: '🧭', label: '길한 방위',
        value: dirHanja[oe] ?? '',
        sub: oe,
        color: color,
      )),
      const SizedBox(width: 8),
      Expanded(child: _statCard(
        icon: '📈', label: '대운 지수',
        value: dw != null ? '${dw.investmentScore}' : '-',
        sub: dw != null ? getScoreKorean(dw.investmentScore).split(' ').first : '',
        color: dw != null ? getScoreColor(dw.investmentScore) : AppColors.textSecondary,
      )),
      const SizedBox(width: 8),
      Expanded(child: _statCard(
        icon: '⭐', label: '$currentYear년',
        value: sw != null ? '${sw.investmentScore}' : '-',
        sub: sw != null ? getScoreKorean(sw.investmentScore).split(' ').first : '',
        color: sw != null ? getScoreColor(sw.investmentScore) : AppColors.textSecondary,
      )),
    ]).animate(delay: 80.ms).fadeIn();
  }

  Widget _statCard({
    required String icon, required String label,
    required String value, required String sub, required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 6, offset: const Offset(0, 2),
        )],
      ),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(
          fontSize: 9, color: AppColors.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 22, fontWeight: FontWeight.w900,
          color: color,
          shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 8)],
        )),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8))),
      ]),
    );
  }

  int _getTodayScore(String ssName, String jijiRel, bool isGongmang) {
    if (isGongmang) return 28;
    if (jijiRel == '충(沖)') return 44;
    const scores = {
      '정재': 88, '정관': 85, '식신': 82, '정인': 80,
      '비견': 66, '편재': 72, '편인': 70,
      '겁재': 52, '상관': 48, '편관': 45,
    };
    int base = scores[ssName] ?? 65;
    if (jijiRel == '합(合)') base = (base + 5).clamp(0, 99);
    return base;
  }

  Color _scoreColorForToday(int score) {
    if (score >= 80) return const Color(0xFF4DAA72);
    if (score >= 65) return const Color(0xFFD4A017);
    return const Color(0xFFCC4400);
  }

  Widget _miniTag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(text, style: TextStyle(
      fontSize: 8, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
  );

  // ─── 공용 헬퍼 ───────────────────────────────────

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5)),
      const SizedBox(width: 8),
      Container(width: 0.5, height: 12, color: AppColors.divider),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
    ]),
  );

  String _oehaengHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}

// ─────────────────────────────────────────────────────
// 오늘 일진 판단 결과
// ─────────────────────────────────────────────────────
class _TodayVerdict {
  final String label;
  final String emoji;
  final String tip;
  final Color borderColor;

  const _TodayVerdict({
    required this.label,
    required this.emoji,
    required this.tip,
    required this.borderColor,
  });
}
