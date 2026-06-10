// family_analysis_screen.dart — 가족 합산 자치구 분석
// 가족 구성원(2~4명) 선택 → 사주 합산 → 최적 동네 TOP 5
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import '../map/district_map_data.dart';

class FamilyAnalysisScreen extends StatefulWidget {
  final SajuProfile currentProfile;
  const FamilyAnalysisScreen({super.key, required this.currentProfile});

  @override
  State<FamilyAnalysisScreen> createState() => _FamilyAnalysisScreenState();
}

class _FamilyAnalysisScreenState extends State<FamilyAnalysisScreen> {
  late List<_ProfileEntry> _entries;
  Set<int> _selectedIdx = {};
  List<_FamilyScore>? _results;
  bool _analyzing = false;

  @override
  void initState() {
    super.initState();
    final box = Hive.box<SajuProfile>('profiles');
    _entries = box.values.toList().asMap().entries
        .map((e) => _ProfileEntry(index: e.key, profile: e.value))
        .toList();
    // 현재 프로필 기본 선택
    final curIdx = _entries.indexWhere(
        (e) => e.profile.name == widget.currentProfile.name);
    if (curIdx >= 0) _selectedIdx.add(curIdx);
  }

  // SajuProfile → SajuResult 헬퍼
  SajuResult _calc(SajuProfile p) => SajuCalculator.calculate(
    birthDate: p.birthDate,
    birthHour: p.birthHour,
    birthMinute: p.birthMinute,
    birthLongitude: p.birthLongitude,
    gender: p.gender,
  );

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

  void _analyze() {
    if (_selectedIdx.length < 2) return;
    setState(() => _analyzing = true);

    final selected = _selectedIdx.map((i) => _entries[i].profile).toList();
    final results = <String, SajuResult>{};
    for (final p in selected) {
      results[p.name] = _calc(p);
    }

    final scores = <_FamilyScore>[];
    for (final d in seoulDistricts) {
      final individuals = selected.map((p) {
        final r = results[p.name]!;
        return (p.name, calcDistrictScore(d, r.mainOehaeng, r.weakOehaeng));
      }).toList();
      final avg = individuals.fold(0, (s, e) => s + e.$2) / individuals.length;
      scores.add(_FamilyScore(district: d, combined: avg, individuals: individuals));
    }
    scores.sort((a, b) => b.combined.compareTo(a.combined));

    setState(() {
      _results = scores;
      _analyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('가족 합산 분석',
              style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 18,
                  color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        children: [
          _buildIntro(),
          const SizedBox(height: 14),
          _buildMemberSelect(),
          const SizedBox(height: 14),
          if (_selectedIdx.length >= 2)
            _buildAnalyzeButton(),
          if (_results != null) ...[
            const SizedBox(height: 14),
            _buildOehaengSummary(),
            const SizedBox(height: 14),
            _buildTop5(),
          ],
        ],
      ),
    );
  }

  // ─── 안내 카드 ─────────────────────────────────────────
  Widget _buildIntro() {
    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.3),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('家', style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('가족 합산 입지 분석', style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('2~4명의 사주를 합산해\n온 가족에게 가장 좋은 동네를 찾습니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        ])),
      ]),
    ).animate().fadeIn(duration: 350.ms);
  }

  // ─── 구성원 선택 ─────────────────────────────────────
  Widget _buildMemberSelect() {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const KoreanSectionTitle(title: '가족 구성원 선택', showDivider: false),
          const Spacer(),
          Text('${_selectedIdx.length}명 선택',
              style: TextStyle(fontSize: 12,
                  color: _selectedIdx.length >= 2 ? AppColors.accent : AppColors.textMuted,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        const Text('2~4명을 선택하세요',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        if (_entries.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('저장된 프로필이 없습니다.\n가족 구성원을 먼저 등록해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
          ))
        else
          ..._entries.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value.profile;
            final isSelected = _selectedIdx.contains(i);
            final isCurrent = p.name == widget.currentProfile.name;
            return _MemberTile(
              profile: p,
              isSelected: isSelected,
              isCurrent: isCurrent,
              disabled: !isSelected && _selectedIdx.length >= 4,
              oeColor: _oeColor(_calc(p).mainOehaeng),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (isSelected && !isCurrent) {
                    _selectedIdx.remove(i);
                    _results = null;
                  } else if (!isSelected && _selectedIdx.length < 4) {
                    _selectedIdx.add(i);
                    _results = null;
                  }
                });
              },
            );
          }),
      ]),
    ).animate(delay: 80.ms).fadeIn();
  }

  // ─── 분석 버튼 ───────────────────────────────────────
  Widget _buildAnalyzeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _analyzing ? null : _analyze,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.accentDim, AppColors.accent, AppColors.accentLight]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3),
                blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: _analyzing
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('가족 합산 분석 시작',
                    style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 16,
                        fontWeight: FontWeight.bold, color: AppColors.surface,
                        letterSpacing: 1.5))),
          ),
        ),
      ),
    ).animate(delay: 100.ms).fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  // ─── 가족 오행 현황 ───────────────────────────────────
  Widget _buildOehaengSummary() {
    final selected = _selectedIdx.map((i) => _entries[i].profile).toList();
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '👨‍👩‍👧‍👦 가족 오행 현황', showDivider: false),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 8, children: selected.map((p) {
          final r = _calc(p);
          final oe = r.mainOehaeng;
          final color = _oeColor(oe);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(p.genderEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(p.name, style: const TextStyle(fontSize: 11,
                  color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              Text(oe, style: TextStyle(fontFamily: 'NotoSerifKR',
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ]),
          );
        }).toList()),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── TOP 5 자치구 ─────────────────────────────────────
  Widget _buildTop5() {
    final top5 = _results!.take(5).toList();
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '🏆 우리 가족 최적 동네 TOP 5', showDivider: false),
        const SizedBox(height: 10),
        ...top5.asMap().entries.map((e) {
          final rank = e.key + 1;
          final fs = e.value;
          final d = fs.district;
          final score = fs.combined.round();
          final oeColor = _oeColor(d.oehaeng);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // 순위 배지
                Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rank == 1 ? AppColors.accent.withOpacity(0.2) : AppColors.cardBg2,
                    border: Border.all(
                        color: rank == 1 ? AppColors.accent : AppColors.divider),
                  ),
                  child: Center(child: Text('$rank',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                          color: rank == 1 ? AppColors.accent : AppColors.textSecondary))),
                ),
                const SizedBox(width: 8),
                Text(d.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.bold, color: oeColor)),
                  Text('${d.oehaeng} · ${d.keyword}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: oeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: oeColor.withOpacity(0.4)),
                  ),
                  child: Text('$score점', style: TextStyle(fontSize: 14,
                      fontWeight: FontWeight.bold, color: oeColor,
                      fontFamily: 'NotoSerifKR')),
                ),
              ]),
              // 개인별 점수
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 5),
                child: Wrap(spacing: 8, children: fs.individuals.map((ind) {
                  final c = _oeColor(
                    _calc(_entries
                        .firstWhere((e) => e.profile.name == ind.$1).profile).mainOehaeng);
                  return Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
                    const SizedBox(width: 3),
                    Text('${ind.$1} ${ind.$2}점',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ]);
                }).toList()),
              ),
              if (rank < 5)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Divider(color: AppColors.divider, height: 1),
                ),
            ]),
          );
        }),
      ]),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1);
  }
}

// ─── 구성원 타일 위젯 ─────────────────────────────────
class _MemberTile extends StatelessWidget {
  final SajuProfile profile;
  final bool isSelected;
  final bool isCurrent;
  final bool disabled;
  final Color oeColor;
  final VoidCallback onTap;

  const _MemberTile({
    required this.profile, required this.isSelected, required this.isCurrent,
    required this.disabled, required this.oeColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? oeColor.withOpacity(0.08) : AppColors.cardBg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? oeColor : AppColors.divider,
            width: isSelected ? 1.4 : 0.8),
        ),
        child: Row(children: [
          Text(profile.genderEmoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(profile.name, style: TextStyle(fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? oeColor : AppColors.textPrimary)),
              if (isCurrent)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3)),
                  child: const Text('나', style: TextStyle(fontSize: 9,
                      color: AppColors.accent, fontWeight: FontWeight.bold)),
                ),
            ]),
            Text('${profile.displayAge} · ${profile.birthHourLabel} 생',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? oeColor : Colors.transparent,
              border: Border.all(
                color: isSelected ? oeColor : AppColors.divider, width: 1.5),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Colors.black)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─── 데이터 클래스 ────────────────────────────────────
class _ProfileEntry {
  final int index;
  final SajuProfile profile;
  const _ProfileEntry({required this.index, required this.profile});
}

class _FamilyScore {
  final DistrictData district;
  final double combined;
  final List<(String, int)> individuals;
  const _FamilyScore({required this.district, required this.combined, required this.individuals});
}
