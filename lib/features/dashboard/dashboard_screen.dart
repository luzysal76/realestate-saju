import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import '../moving/moving_screen.dart';
import '../direction/direction_screen.dart';
import '../timing/timing_screen.dart';
import '../input/input_screen.dart';
import '../profile/profile_select_screen.dart';
import '../settings/settings_screen.dart';
import 'saju_detail_screen.dart';
import 'shinsal_card.dart';

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
                // 공유 버튼
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
              _buildSajuPillar(),
              const SizedBox(height: 10),
              _buildSipSeongCard(),
              const SizedBox(height: 10),
              _buildOehaengBar(),
              const SizedBox(height: 10),
              _buildPropertyCard(),
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
                    '${widget.profile.birthDate.year}년생  ${widget.profile.gender}성',
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
              if (idx != 2) {
                final ss = SajuCalculator.calcSipSeong(ilgan, cg);
                ssLabel = ss.name;
                ssColor = _sipSeongColor(ss.name);
              }

              return PillarCard(
                cheongan: cg,
                jiji: data['jiji']!,
                label: (p['label'] as String).split('(')[0],
                color: color,
                sipSeongLabel: ssLabel,
                sipSeongColor: ssColor,
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

  // ─── 오행 바 ────────────────────────────────────

  Widget _buildOehaengBar() {
    final scores = _result.oehaengScore;
    final maxScore = scores.values.reduce((a, b) => a > b ? a : b).toDouble();

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '오행 분포 (五行)'),
        const SizedBox(height: 12),
        ...scores.entries.map((e) {
          final color = AppColors.getOehaengColor(e.key);
          final ratio = maxScore > 0 ? e.value / maxScore : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              OehaengBadge(e.key),
              const SizedBox(width: 8),
              Expanded(child: KoreanProgressBar(value: ratio, color: color)),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text('${e.value}', style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ),
            ]),
          );
        }),
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

  // ─── 세운 (연도별 운세) ──────────────────────────

  Widget _buildSeWunCard() {
    final seWunList = _result.seWunList;
    if (seWunList.isEmpty) return const SizedBox();

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(
          title: '세운 — 연도별 운세 (歲運)',
          subtitle: '가까운 6년간 부동산 흐름',
        ),
        const SizedBox(height: 12),
        ...seWunList.take(6).map((sw) {
          final color = AppColors.getOehaengColor(sw.oehaeng);
          final ssColor = _sipSeongColor(sw.sipSeong.name);
          final isNow = sw.year == DateTime.now().year;
          return Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isNow ? color.withOpacity(0.1) : AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isNow ? color.withOpacity(0.5) : AppColors.divider,
                width: isNow ? 1.5 : 0.8,
              ),
            ),
            child: Row(children: [
              SizedBox(width: 48, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${sw.year}', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold,
                    color: isNow ? color : AppColors.textPrimary)),
                  Text(sw.ganJiStr, style: TextStyle(
                    fontFamily: 'NotoSerifKR', fontSize: 11, color: color)),
                ],
              )),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SipSeongBadge(name: sw.sipSeong.name, color: ssColor, small: true),
                const SizedBox(height: 2),
                Text(sw.jijiRelation, style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
              ]),
              const SizedBox(width: 6),
              Expanded(child: Text(sw.buyOrSell, style: const TextStyle(
                fontSize: 11, color: AppColors.textPrimary, height: 1.3))),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(sw.scoreLabel, style: const TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
                Text('${sw.investmentScore}', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: getScoreColor(sw.investmentScore))),
              ]),
            ]),
          );
        }),
        if (seWunList.length > 6)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('나머지 ${seWunList.length - 6}년은 매매타이밍 메뉴에서 확인하세요.',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
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
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const KoreanSectionTitle(title: '천명 메뉴 (天命)'),
      const SizedBox(height: 10),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 8, mainAxisSpacing: 8,
        childAspectRatio: 0.9,
        children: actions.asMap().entries.map((e) {
          final idx = e.key;
          final a = e.value;
          return GestureDetector(
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => a['screen'] as Widget)),
            child: TraditionalCard(
              padding: EdgeInsets.zero,
              child: Padding(
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
            ),
          ).animate(delay: Duration(milliseconds: 500 + idx * 80))
            .fadeIn().scale(begin: const Offset(0.92, 0.92));
        }).toList(),
      ),
    ]);
  }

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
