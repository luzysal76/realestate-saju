import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../core/saju/shinsal.dart';
import '../../shared/models/saju_profile.dart';
import 'shinsal_card.dart';

class SajuDetailScreen extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;
  const SajuDetailScreen({super.key, required this.result, required this.profile});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              '${profile.name} 사주 상세',
              style: const TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 16,
                color: Colors.white, letterSpacing: 1,
              ),
            ),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '八字'),
              Tab(text: '十星'),
              Tab(text: '大運'),
              Tab(text: '歲運'),
              Tab(text: '神煞'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _PillarTab(result: result),
          _SipSeongTab(result: result),
          _DaeWunTab(result: result, profile: profile),
          _SeWunTab(result: result),
          ShinSalDetailTab(shinSal: result.shinSalResult),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 八字 원국 탭
// ═══════════════════════════════════════════════════════
class _PillarTab extends StatelessWidget {
  final SajuResult result;
  const _PillarTab({required this.result});

  @override
  Widget build(BuildContext context) {
    final pillars = [
      {'label': '연주\n(年柱)', 'gj': result.yearGj, 'sub': '조상·초년'},
      {'label': '월주\n(月柱)', 'gj': result.monthGj, 'sub': '부모·청년'},
      {'label': '일주\n(日柱)', 'gj': result.dayGj, 'sub': '자신·배우자'},
      {'label': '시주\n(時柱)', 'gj': result.hourGj, 'sub': '자녀·말년'},
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
      children: [
        // ─── 사주 원국 그리드 ──────────────────────────
        TraditionalCard(
          doubleBorder: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KoreanSectionTitle(title: '사주원국 (四柱原局)'),
            const SizedBox(height: 14),

            // 천간 행
            Row(children: [
              const SizedBox(width: 48),
              ...pillars.map((p) => Expanded(child: _cganCell(p))),
            ]),

            const SizedBox(height: 4),

            // 지지 행
            Row(children: [
              const SizedBox(width: 48),
              ...pillars.map((p) => Expanded(child: _jijiCell(p))),
            ]),

            const SizedBox(height: 10),
            const TraditionalDivider(indent: 0),
            const SizedBox(height: 10),

            // 지장간 행
            Row(children: [
              const SizedBox(width: 48, child: Text('藏干', style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1))),
              ...pillars.map((p) {
                final gj = p['gj'] as Map<String, String>;
                final hidden = JijangGan.get(gj['jiji']!);
                final oe = gj['oehaeng_jiji']!;
                final color = AppColors.getOehaengColor(oe);
                return Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(children: hidden.map((s) => Text(s,
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 11, color: color.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  )).toList()),
                ));
              }),
            ]),

            const SizedBox(height: 6),
            const TraditionalDivider(indent: 0),
            const SizedBox(height: 6),

            // 납음오행 행 (원광만세력)
            Row(children: [
              const SizedBox(width: 48, child: Text('納音', style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1))),
              ...pillars.map((p) {
                final gj = p['gj'] as Map<String, String>;
                final naeum = gj['naeum'] ?? '';
                final nOe   = gj['naeum_oehaeng'] ?? '';
                final color = AppColors.getOehaengColor(nOe);
                return Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(children: [
                    Text(naeum, style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 9, color: color,
                      fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                    Text('($nOe)', style: TextStyle(
                      fontSize: 8, color: color.withOpacity(0.7)),
                      textAlign: TextAlign.center),
                  ]),
                ));
              }),
            ]),
          ]),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 12),

        // ─── 기둥별 설명 ──────────────────────────────
        ...pillars.asMap().entries.map((e) {
          final idx = e.key;
          final p = e.value;
          final gj = p['gj'] as Map<String, String>;
          final cg = gj['cheongan']!;
          final ji = gj['jiji']!;
          final oe = gj['oehaeng_cheongan']!;
          final color = AppColors.getOehaengColor(oe);
          final gongmang = result.shinSalResult.gongmang;
          final isGongmang = gongmang.contains(ji);

          return TraditionalCard(
            doubleBorder: true,
            borderColor: color.withOpacity(0.3),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 48, height: 54,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(cg, style: TextStyle(
                      fontFamily: 'NotoSerifKR', fontSize: 16,
                      fontWeight: FontWeight.bold, color: color)),
                    Container(height: 0.5, margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: color.withOpacity(0.3)),
                    Text(ji, style: const TextStyle(
                      fontFamily: 'NotoSerifKR', fontSize: 16,
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [color, color.withOpacity(0.7)]).createShader(b),
                    child: Text(
                      p['label'] as String,
                      style: const TextStyle(
                        fontFamily: 'NotoSerifKR', fontSize: 13,
                        fontWeight: FontWeight.bold, color: Colors.white,
                        letterSpacing: 0.5),
                    ),
                  ),
                  Text(p['sub'] as String, style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
                ])),
                if (isGongmang)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.hwaColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: AppColors.hwaColor.withOpacity(0.4)),
                    ),
                    child: const Text('공망', style: TextStyle(
                      fontSize: 10, color: AppColors.hwaColor,
                      fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 10),
              // 오행 + 지장간
              Row(children: [
                OehaengBadge(oe),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('천간 오행: $oe(${_oeHanja(oe)})',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text('지장간: ${JijangGan.get(ji).join(" · ")}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  // 원광만세력 납음오행
                  Text(
                    '납음오행: ${gj['naeum'] ?? ''} (${_oeHanja(gj['naeum_oehaeng'] ?? '')})',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.getOehaengColor(gj['naeum_oehaeng'] ?? '목')
                        .withOpacity(0.85)),
                  ),
                ]),
              ]),
            ]),
          ).animate(delay: Duration(milliseconds: idx * 60)).fadeIn().slideX(begin: 0.06);
        }),
      ],
    );
  }

  Widget _cganCell(Map<String, Object> p) {
    final gj = p['gj'] as Map<String, String>;
    final oe = gj['oehaeng_cheongan']!;
    final color = AppColors.getOehaengColor(oe);
    final isIlju = p['sub'] == '자신·배우자';
    return Column(children: [
      if (isIlju)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text('일간', style: TextStyle(
            fontSize: 7, color: AppColors.accent, letterSpacing: 0.5)),
        ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Center(child: Text(gj['cheongan']!, style: TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 20,
          fontWeight: FontWeight.bold, color: color))),
      ),
      Text(oe, style: TextStyle(fontSize: 8, color: color.withOpacity(0.8))),
    ]);
  }

  Widget _jijiCell(Map<String, Object> p) {
    final gj = p['gj'] as Map<String, String>;
    final oe = gj['oehaeng_jiji']!;
    final color = AppColors.getOehaengColor(oe);
    return Column(children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
          border: Border.all(color: AppColors.divider),
        ),
        child: Center(child: Text(gj['jiji']!, style: const TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 20,
          fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
      ),
      Text(oe, style: TextStyle(fontSize: 8, color: color.withOpacity(0.8))),
    ]);
  }

  String _oeHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}

// ═══════════════════════════════════════════════════════
// 십성 분석 탭
// ═══════════════════════════════════════════════════════
class _SipSeongTab extends StatelessWidget {
  final SajuResult result;
  const _SipSeongTab({required this.result});

  Color _ssColor(String ss) {
    const c = {
      '비견': Color(0xFF5B9BD5), '겁재': Color(0xFF3A7CC2),
      '식신': Color(0xFF4E9E6B), '상관': Color(0xFF3A8957),
      '편재': Color(0xFFD4A017), '정재': Color(0xFFC89010),
      '편관': Color(0xFFCC3300), '정관': Color(0xFFAA2200),
      '편인': Color(0xFF9B59A8), '정인': Color(0xFF8B4599),
    };
    return c[ss] ?? AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final ana = result.sipSeongAnalysis;
    final ilgan = result.ilgan;
    final domColor = _ssColor(ana.dominant);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // 격국 헤더
        TraditionalCard(
          borderColor: domColor.withOpacity(0.5),
          bgColor: Color.lerp(AppColors.cardBg, domColor.withOpacity(0.06), 0.5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // 주성 한자 뱃지
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: domColor.withOpacity(0.12),
                  border: Border.all(color: domColor.withOpacity(0.5), width: 1),
                ),
                child: Center(
                  child: Text(
                    ana.dominant.substring(0, 1),
                    style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: domColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => LinearGradient(
                      colors: [domColor, domColor.withOpacity(0.7)],
                    ).createShader(b),
                    child: Text(
                      ana.formatDesc,
                      style: const TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: Colors.white, letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(ana.personalityDesc, style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                ],
              )),
            ]),
            const SizedBox(height: 12),
            const TraditionalDivider(indent: 0),
            const SizedBox(height: 10),
            Row(children: [
              const Text('🏠', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              const Text('부동산 전략', style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 11, fontWeight: FontWeight.bold,
                color: AppColors.accent, letterSpacing: 0.5,
              )),
            ]),
            const SizedBox(height: 4),
            Text(ana.propertyTips, style: const TextStyle(
              fontSize: 12, color: AppColors.textPrimary, height: 1.6)),
          ]),
        ).animate().fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 10),

        // 기둥별 십성
        TraditionalCard(
          doubleBorder: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KoreanSectionTitle(title: '기둥별 십성 (柱別 十星)'),
            const SizedBox(height: 12),
            _pillarRow('연주(年)', result.yearGj, ilgan),
            const SizedBox(height: 4),
            _pillarRow('월주(月)', result.monthGj, ilgan),
            const SizedBox(height: 4),
            _pillarRow('일주(日)', result.dayGj, ilgan, isIlju: true),
            const SizedBox(height: 4),
            _pillarRow('시주(時)', result.hourGj, ilgan),
          ]),
        ).animate(delay: 120.ms).fadeIn(),

        const SizedBox(height: 10),

        // 십성 분포 그리드
        TraditionalCard(
          doubleBorder: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const KoreanSectionTitle(title: '십성 분포 (十星 分布)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: _allSipSeong.map((ss) {
                final cnt = ana.count[ss] ?? 0;
                final color = _ssColor(ss);
                final active = cnt > 0;
                return Container(
                  width: (MediaQuery.of(context).size.width - 80) / 5,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? color.withOpacity(0.1) : AppColors.surface.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: active ? color.withOpacity(0.4) : AppColors.divider,
                      width: active ? 1 : 0.5,
                    ),
                  ),
                  child: Column(children: [
                    Text(
                      ss.substring(0, 1),
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: active ? color : AppColors.textMuted,
                      ),
                    ),
                    Text(
                      ss.substring(1),
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 10,
                        color: active ? color.withOpacity(0.8) : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cnt > 0 ? '×$cnt' : '—',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: active ? color : AppColors.textMuted,
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ]),
        ).animate(delay: 230.ms).fadeIn(),
      ],
    );
  }

  Widget _pillarRow(String label, Map<String, String> gj, String ilgan,
      {bool isIlju = false}) {
    final cg = gj['cheongan']!;
    final ji = gj['jiji']!;
    final oe = gj['oehaeng_cheongan']!;
    final color = AppColors.getOehaengColor(oe);

    String ssName = '일간 (기준)';
    Color ssColor = AppColors.accent;
    String ssDesc = '사주의 중심 기준';
    if (!isIlju) {
      final ss = SajuCalculator.calcSipSeong(ilgan, cg);
      ssName = ss.name;
      ssColor = _ssColor(ss.name);
      ssDesc = ss.shortDesc;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Row(children: [
        SizedBox(
          width: 44,
          child: Text(label, style: const TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 10, color: AppColors.textSecondary, letterSpacing: 0.5,
          )),
        ),
        Container(
          width: 38, height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(cg, style: TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 14,
              fontWeight: FontWeight.bold, color: color)),
            Container(height: 0.5, color: color.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
            Text(ji, style: const TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 14,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ]),
        ),
        const SizedBox(width: 10),
        SipSeongBadge(name: ssName, color: ssColor),
        const SizedBox(width: 8),
        Expanded(child: Text(ssDesc, style: const TextStyle(
          fontSize: 10, color: AppColors.textSecondary, height: 1.3))),
      ]),
    );
  }

  static const _allSipSeong = [
    '비견', '겁재', '식신', '상관', '편재', '정재', '편관', '정관', '편인', '정인',
  ];
}

// ═══════════════════════════════════════════════════════
// 대운 흐름 탭
// ═══════════════════════════════════════════════════════
class _DaeWunTab extends StatelessWidget {
  final SajuResult result;
  final SajuProfile profile;
  const _DaeWunTab({required this.result, required this.profile});

  Color _ssColor(String ss) {
    const c = {
      '비견': Color(0xFF5B9BD5), '겁재': Color(0xFF3A7CC2),
      '식신': Color(0xFF4E9E6B), '상관': Color(0xFF3A8957),
      '편재': Color(0xFFD4A017), '정재': Color(0xFFC89010),
      '편관': Color(0xFFCC3300), '정관': Color(0xFFAA2200),
      '편인': Color(0xFF9B59A8), '정인': Color(0xFF8B4599),
    };
    return c[ss] ?? AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // 안내 헤더
        TraditionalCard(
          child: Row(children: [
            const TaegeukSymbol(size: 32),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '대운(大運)은 10년 단위의 운세 흐름입니다.\n현재 대운 기간이 부동산 투자 전략에 핵심입니다.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 10),

        ...result.daeWunList.asMap().entries.map((e) {
          final dw = e.value;
          final isCurrent = dw.isCurrent(currentYear, profile.birthDate.year);
          final color = AppColors.getOehaengColor(dw.oehaeng);
          final ssColor = _ssColor(dw.sipSeong.name);
          final scoreColor = getScoreColor(dw.investmentScore);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isCurrent ? color.withOpacity(0.08) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isCurrent ? color.withOpacity(0.6) : AppColors.divider,
                width: isCurrent ? 1.5 : 0.8,
              ),
              boxShadow: isCurrent ? [
                BoxShadow(color: color.withOpacity(0.15),
                    blurRadius: 8, spreadRadius: 1)
              ] : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                // 간지
                PillarCard(
                  cheongan: dw.cheongan,
                  jiji: dw.jiji,
                  label: '${dw.age}세',
                  color: color,
                  sipSeongLabel: dw.sipSeong.name,
                  sipSeongColor: ssColor,
                ),
                const SizedBox(width: 12),
                // 내용
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        '${dw.year}~${dw.year + 9}년',
                        style: TextStyle(
                          fontFamily: 'NotoSerifKR',
                          fontSize: 12,
                          color: isCurrent ? color : AppColors.textSecondary,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: color.withOpacity(0.4)),
                          ),
                          child: Text('현재',
                            style: TextStyle(
                              fontSize: 9, fontWeight: FontWeight.bold,
                              color: color, letterSpacing: 0.5,
                            )),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      '${dw.sipSeong.name} — ${dw.sipSeong.shortDesc}',
                      style: TextStyle(
                        fontSize: 10, color: ssColor.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 4),
                    Text(dw.propertyTip, style: const TextStyle(
                      fontSize: 11, color: AppColors.textPrimary, height: 1.4)),
                    const SizedBox(height: 6),
                    KoreanProgressBar(
                      value: dw.investmentScore / 100,
                      color: scoreColor, height: 5,
                    ),
                  ],
                )),
                // 점수
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(children: [
                    Text('${dw.investmentScore}', style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                      color: scoreColor,
                      fontFamily: 'NotoSerifKR',
                    )),
                    Text('점', style: TextStyle(
                      fontSize: 9, color: scoreColor.withOpacity(0.7),
                      letterSpacing: 0.3,
                    )),
                  ]),
                ),
              ]),
            ),
          ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn().slideX(begin: 0.08);
        }),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// 세운 10년 탭
// ═══════════════════════════════════════════════════════
class _SeWunTab extends StatelessWidget {
  final SajuResult result;
  const _SeWunTab({required this.result});

  Color _ssColor(String ss) {
    const c = {
      '비견': Color(0xFF5B9BD5), '겁재': Color(0xFF3A7CC2),
      '식신': Color(0xFF4E9E6B), '상관': Color(0xFF3A8957),
      '편재': Color(0xFFD4A017), '정재': Color(0xFFC89010),
      '편관': Color(0xFFCC3300), '정관': Color(0xFFAA2200),
      '편인': Color(0xFF9B59A8), '정인': Color(0xFF8B4599),
    };
    return c[ss] ?? AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        // 안내 카드
        TraditionalCard(
          child: const Text(
            '세운(歲運)은 해마다의 천간·지지가 일주(日柱)와 맺는 십성·합충 관계입니다. '
            '이를 종합해 매년의 부동산 매수·매도 적기를 분석합니다.',
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 11, color: AppColors.textSecondary, height: 1.6),
          ),
        ).animate().fadeIn(),
        const SizedBox(height: 10),

        ...result.seWunList.asMap().entries.map((e) {
          final sw = e.value;
          final isNow = sw.year == DateTime.now().year;
          final color = AppColors.getOehaengColor(sw.oehaeng);
          final ssColor = _ssColor(sw.sipSeong.name);
          final scoreColor = getScoreColor(sw.investmentScore);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isNow ? color.withOpacity(0.08) : AppColors.cardBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isNow ? color.withOpacity(0.6) : AppColors.divider,
                width: isNow ? 1.5 : 0.8,
              ),
              boxShadow: isNow ? [
                BoxShadow(color: color.withOpacity(0.15), blurRadius: 8)
              ] : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 연도 헤더
                  Row(children: [
                    Text(
                      '${sw.year}년',
                      style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: isNow ? color : AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(sw.ganJiStr, style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 13, color: color,
                    )),
                    if (isNow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        child: Text('올해', style: TextStyle(
                          fontFamily: 'NotoSerifKR',
                          fontSize: 9, fontWeight: FontWeight.bold,
                          color: color, letterSpacing: 0.5,
                        )),
                      ),
                    ],
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(sw.scoreLabel, style: const TextStyle(
                        fontSize: 9, color: AppColors.textSecondary)),
                      Text('${sw.investmentScore}점', style: TextStyle(
                        fontFamily: 'NotoSerifKR',
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: scoreColor)),
                    ]),
                  ]),
                  const SizedBox(height: 7),
                  // 뱃지 행
                  Row(children: [
                    SipSeongBadge(
                      name: '${sw.sipSeong.name} — ${sw.sipSeong.shortDesc}',
                      color: ssColor, small: true,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: AppColors.divider, width: 0.5),
                      ),
                      child: Text('일지와 ${sw.jijiRelation}',
                        style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 7),
                  // 매수/매도
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _actionColor(sw.buyOrSell).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _actionColor(sw.buyOrSell).withOpacity(0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Text(sw.buyOrSell, style: TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: _actionColor(sw.buyOrSell), letterSpacing: 0.3,
                    )),
                  ),
                  const SizedBox(height: 6),
                  Text(sw.propertyAdvice, style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 6),
                  KoreanProgressBar(
                    value: sw.investmentScore / 100,
                    color: scoreColor, height: 4,
                  ),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: e.key * 40)).fadeIn().slideY(begin: 0.06);
        }),
      ],
    );
  }

  Color _actionColor(String action) {
    if (action.contains('매수') || action.contains('적극')) return AppColors.mokColor;
    if (action.contains('매도') || action.contains('현금')) return AppColors.hwaColor;
    return AppColors.accent;
  }
}
