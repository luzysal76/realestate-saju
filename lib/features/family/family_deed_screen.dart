// 공동명의 궁합 화면 — 두 사람의 사주로 재물운·문서운 비교 → 명의 추천

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';

// ─── 결과 데이터 ────────────────────────────────────────
class _DeedResult {
  final SajuResult rB;
  final String nameA, nameB;
  final int jaeA, jaeB;
  final int munsoA, munsoB;
  final int totalA, totalB;
  final String recommendation;
  final String compatGrade;
  final String spaceStory;
  final Color recColor;
  const _DeedResult({
    required this.rB, required this.nameA, required this.nameB,
    required this.jaeA, required this.jaeB,
    required this.munsoA, required this.munsoB,
    required this.totalA, required this.totalB,
    required this.recommendation, required this.compatGrade,
    required this.spaceStory, required this.recColor,
  });
}

// ─── 화면 ──────────────────────────────────────────────
class FamilyDeedScreen extends StatefulWidget {
  final SajuResult resultA;
  final SajuProfile profileA;
  const FamilyDeedScreen({
    super.key, required this.resultA, required this.profileA});
  @override
  State<FamilyDeedScreen> createState() => _FamilyDeedScreenState();
}

class _FamilyDeedScreenState extends State<FamilyDeedScreen> {
  final _nameCtrl = TextEditingController();
  DateTime? _birthB;
  String _genderB = '남';
  _DeedResult? _result;
  List<SajuProfile> _others = [];

  @override
  void initState() {
    super.initState();
    final box = Hive.box<SajuProfile>('profiles');
    _others = box.values
        .where((p) => p.name != widget.profileA.name)
        .toList();
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  void _selectFromProfile(SajuProfile p) {
    setState(() {
      _nameCtrl.text = p.name;
      _birthB = p.birthDate;
      _genderB = p.gender;
    });
    Navigator.pop(context);
  }

  void _analyze() {
    if (_birthB == null || _nameCtrl.text.trim().isEmpty) return;
    final rA = widget.resultA;
    final rB = SajuCalculator.calculate(
      birthDate: _birthB!,
      birthHour: 25,
      birthMinute: 0,
      birthLongitude: 127.0,
      gender: _genderB,
    );
    final jaeA = _calcJaeScore(rA);
    final jaeB = _calcJaeScore(rB);
    final munsoA = _calcMunsoScore(rA);
    final munsoB = _calcMunsoScore(rB);
    final totalA = ((jaeA + munsoA) / 2).round();
    final totalB = ((jaeB + munsoB) / 2).round();
    final diff = totalA - totalB;
    String rec; Color recColor;
    if (diff.abs() <= 8) {
      rec = '공동명의 추천'; recColor = AppColors.toColor;
    } else if (diff > 0) {
      rec = '${widget.profileA.name} 명의 추천'; recColor = AppColors.geumColor;
    } else {
      rec = '${_nameCtrl.text.trim()} 명의 추천'; recColor = AppColors.mokColor;
    }
    setState(() {
      _result = _DeedResult(
        rB: rB,
        nameA: widget.profileA.name,
        nameB: _nameCtrl.text.trim(),
        jaeA: jaeA, jaeB: jaeB,
        munsoA: munsoA, munsoB: munsoB,
        totalA: totalA, totalB: totalB,
        recommendation: rec,
        compatGrade: _coupleCompat(rA, rB),
        spaceStory: _spaceStory(rA.mainOehaeng, rB.mainOehaeng),
        recColor: recColor,
      );
    });
  }

  // ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.accent),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('공동명의 궁합', style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 16,
            fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2,
          )),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildPersonACard(),
          const SizedBox(height: 12),
          _buildVsRow(),
          const SizedBox(height: 12),
          _buildPersonBForm(),
          const SizedBox(height: 20),
          _buildAnalyzeButton(),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _buildRecommendCard(_result!).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildScoreCompare(_result!).animate(delay: 80.ms).fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildCompatCard(_result!).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildSpaceCard(_result!).animate(delay: 240.ms).fadeIn().slideY(begin: 0.1),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ── Person A 카드 ─────────────────────────────────────
  Widget _buildPersonACard() {
    final oe = widget.resultA.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);
    return TraditionalCard(
      child: Row(children: [
        OehaengBadge(oe, large: true),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('나 (A)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(oe, style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 3),
          Text(widget.profileA.name, style: const TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 18, fontWeight: FontWeight.bold,
            color: AppColors.textPrimary, letterSpacing: 1,
          )),
          Text(
            '${widget.profileA.birthDate.year}.'
            '${widget.profileA.birthDate.month}.'
            '${widget.profileA.birthDate.day}  '
            '${widget.resultA.ilgan}${widget.resultA.ilji}일주',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ])),
        Column(children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: Text(
              widget.resultA.dayGj['cheongan']! + widget.resultA.dayGj['jiji']!,
              style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 22,
                fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
          ),
          const Text('일주', style: TextStyle(
            fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1)),
        ]),
      ]),
    );
  }

  Widget _buildVsRow() {
    return Row(children: [
      Expanded(child: Divider(color: AppColors.divider, height: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('VS', style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 18, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 4)),
        ),
      ),
      Expanded(child: Divider(color: AppColors.divider, height: 1)),
    ]);
  }

  // ── Person B 입력 폼 ──────────────────────────────────
  Widget _buildPersonBForm() {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('상대방 (B)', style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 13,
            fontWeight: FontWeight.bold, color: AppColors.accent, letterSpacing: 1)),
          const Spacer(),
          if (_others.isNotEmpty)
            GestureDetector(
              onTap: _showProfilePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Text('프로필에서 선택',
                  style: TextStyle(fontSize: 10, color: AppColors.accent, letterSpacing: 0.5)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        _inputField(controller: _nameCtrl, label: '이름'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickBirthDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(children: [
              const Text('생년월일', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Text(
                _birthB == null
                  ? '날짜를 선택하세요'
                  : '${_birthB!.year}년 ${_birthB!.month}월 ${_birthB!.day}일',
                style: TextStyle(fontSize: 14,
                  color: _birthB == null ? AppColors.textSecondary.withOpacity(0.5) : AppColors.textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.accent),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Text('성별', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          _genderBtn('남'),
          const SizedBox(width: 8),
          _genderBtn('여'),
        ]),
      ]),
    );
  }

  Widget _inputField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        filled: true, fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.accent)),
      ),
    );
  }

  Widget _genderBtn(String g) {
    final sel = _genderB == g;
    return GestureDetector(
      onTap: () => setState(() => _genderB = g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: sel ? AppColors.accent : AppColors.divider,
            width: sel ? 1.5 : 1),
        ),
        child: Text(g == '남' ? '남성' : '여성', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold,
          color: sel ? AppColors.accent : AppColors.textSecondary)),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1985, 1, 1),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent, surface: AppColors.cardBg)),
        child: child!),
    );
    if (picked != null) setState(() => _birthB = picked);
  }

  void _showProfilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 14),
        const Text('프로필 선택', style: TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 15,
          fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1)),
        const Divider(color: AppColors.divider, height: 20),
        ..._others.map((p) => ListTile(
          leading: const Icon(Icons.person_outline, color: AppColors.accent, size: 20),
          title: Text(p.name, style: const TextStyle(
            fontFamily: 'NotoSerifKR', color: AppColors.textPrimary, fontSize: 14)),
          subtitle: Text(
            '${p.birthDate.year}.${p.birthDate.month}.${p.birthDate.day}  ${p.gender}성',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          onTap: () => _selectFromProfile(p),
        )),
        const SizedBox(height: 12),
      ]),
    );
  }

  Widget _buildAnalyzeButton() {
    final ok = _birthB != null && _nameCtrl.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: ok ? _analyze : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: ok ? AppColors.goldGradient : null,
          color: ok ? null : AppColors.divider.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          boxShadow: ok ? [BoxShadow(color: AppColors.accent.withOpacity(0.25),
            blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Center(child: Text('명의 궁합 분석하기', style: TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 15, fontWeight: FontWeight.bold,
          color: ok ? const Color(0xFF1A0804) : AppColors.textSecondary,
          letterSpacing: 2))),
      ),
    );
  }

  // ── 결과: 명의 추천 ───────────────────────────────────
  Widget _buildRecommendCard(_DeedResult r) {
    return TraditionalCard(
      child: Column(children: [
        const Text('명의 추천', style: TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 11,
          color: AppColors.textSecondary, letterSpacing: 2)),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (b) => LinearGradient(
            colors: [r.recColor, r.recColor.withOpacity(0.6)]).createShader(b),
          child: Text(r.recommendation, style: const TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 22, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 2)),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _scorePill(r.nameA, r.totalA, AppColors.geumColor),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('vs', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          _scorePill(r.nameB, r.totalB, AppColors.mokColor),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.divider)),
          child: Text(
            r.totalA == r.totalB
              ? '두 분의 재물·문서운이 비슷합니다. 공동명의로 리스크를 분산하세요.'
              : r.totalA > r.totalB
                ? '${r.nameA}님의 재물·문서운이 현재 더 강합니다.\n단독명의 또는 대표명의로 진행하세요.'
                : '${r.nameB}님의 재물·문서운이 현재 더 강합니다.\n단독명의 또는 대표명의로 진행하세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.6)),
        ),
      ]),
    );
  }

  Widget _scorePill(String name, int score, Color color) {
    return Column(children: [
      Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5)),
        child: Center(child: Text('$score', style: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: color))),
      ),
      const SizedBox(height: 4),
      Text(name, style: const TextStyle(
        fontSize: 10, color: AppColors.textSecondary),
        overflow: TextOverflow.ellipsis),
    ]);
  }

  // ── 결과: 재물운·문서운 비교 ──────────────────────────
  Widget _buildScoreCompare(_DeedResult r) {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '재물운 · 문서운 비교'),
        const SizedBox(height: 14),
        _compareBlock('재물운', '부동산 재산 창출력', r.jaeA, r.jaeB, r.nameA, r.nameB),
        const SizedBox(height: 12),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 12),
        _compareBlock('문서운', '계약·등기 유리함', r.munsoA, r.munsoB, r.nameA, r.nameB),
      ]),
    );
  }

  Widget _compareBlock(String title, String sub,
      int sA, int sB, String nA, String nB) {
    final mx = (sA > sB ? sA : sB).toDouble().clamp(10.0, 99.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(title, style: const TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 12,
          fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 6),
        Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
      const SizedBox(height: 8),
      _barRow(nA, sA, mx, AppColors.geumColor),
      const SizedBox(height: 5),
      _barRow(nB, sB, mx, AppColors.mokColor),
    ]);
  }

  Widget _barRow(String name, int score, double mx, Color color) {
    return Row(children: [
      SizedBox(width: 50,
        child: Text(name, style: const TextStyle(
          fontSize: 10, color: AppColors.textSecondary),
          overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 6),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: score / mx,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8),
        ),
      ),
      const SizedBox(width: 6),
      Text('$score', style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  // ── 결과: 일주 궁합 ───────────────────────────────────
  Widget _buildCompatCard(_DeedResult r) {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '일주 궁합'),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _ilJuBox(r.nameA, widget.resultA.dayGj['cheongan']!,
            widget.resultA.dayGj['jiji']!, AppColors.geumColor),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('♥', style: TextStyle(color: AppColors.hwaColor, fontSize: 22))),
          _ilJuBox(r.nameB, r.rB.dayGj['cheongan']!,
            r.rB.dayGj['jiji']!, AppColors.mokColor),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: AppColors.divider)),
          child: Text(r.compatGrade,
            style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.6)),
        ),
      ]),
    );
  }

  Widget _ilJuBox(String name, String gan, String ji, Color color) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.4))),
        child: Column(children: [
          Text(gan + ji, style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 22,
            fontWeight: FontWeight.bold, color: color, letterSpacing: 2)),
          const SizedBox(height: 2),
          const Text('일주', style: TextStyle(
            fontSize: 9, color: AppColors.textSecondary, letterSpacing: 1)),
        ]),
      ),
      const SizedBox(height: 5),
      Text(name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }

  // ── 결과: 공간 심리 스토리 ────────────────────────────
  Widget _buildSpaceCard(_DeedResult r) {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '두 분을 위한 공간 심리'),
        const SizedBox(height: 8),
        Row(children: [
          OehaengBadge(widget.resultA.mainOehaeng),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('+', style: TextStyle(color: AppColors.textSecondary, fontSize: 14))),
          OehaengBadge(r.rB.mainOehaeng),
          const SizedBox(width: 8),
          Text('${widget.resultA.mainOehaeng}+${r.rB.mainOehaeng} 조합',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 10),
        Text(r.spaceStory,
          style: const TextStyle(
            fontSize: 12, color: AppColors.textPrimary, height: 1.7)),
      ]),
    );
  }
}

// ─── 헬퍼 함수 (파일 스코프) ────────────────────────────

int _calcJaeScore(SajuResult r) {
  final cnt = r.sipSeongAnalysis.count;
  int s = (cnt['정재'] ?? 0) * 22 + (cnt['편재'] ?? 0) * 18;
  final sw = r.seWunOfYear(DateTime.now().year);
  if (sw != null) {
    final ss = SajuCalculator.calcSipSeong(r.ilgan, sw.cheongan);
    if (ss.name == '정재') s += 15;
    else if (ss.name == '편재') s += 12;
  }
  return s.clamp(10, 99);
}

int _calcMunsoScore(SajuResult r) {
  final cnt = r.sipSeongAnalysis.count;
  int s = (cnt['정인'] ?? 0) * 22 + (cnt['편인'] ?? 0) * 18;
  final sw = r.seWunOfYear(DateTime.now().year);
  if (sw != null) {
    final ss = SajuCalculator.calcSipSeong(r.ilgan, sw.cheongan);
    if (ss.name == '정인') s += 15;
    else if (ss.name == '편인') s += 12;
  }
  return s.clamp(10, 99);
}

String _coupleCompat(SajuResult a, SajuResult b) {
  const cgHap = {
    '갑': '기', '기': '갑', '을': '경', '경': '을',
    '병': '신', '신': '병', '정': '임', '임': '정',
    '무': '계', '계': '무',
  };
  final hasCgHap = cgHap[a.ilgan] == b.ilgan;
  final hasJijiHap =
      SajuCalculator.jijiHap[a.ilji]?.contains(b.ilji) == true;
  final hasChung = SajuCalculator.jijiChung[a.ilji] == b.ilji;

  if (hasCgHap && hasJijiHap) {
    return '★ 천간합·지지합 모두 성립\n재물 목표와 생활 리듬이 일치하는 최상의 조합입니다. 공동명의가 두 분의 에너지를 배가시킵니다.';
  }
  if (hasCgHap) {
    return '● 천간합 성립 — 경제 가치관과 부동산 목표가 잘 맞습니다. 함께 결정하면 시너지가 납니다.';
  }
  if (hasJijiHap) {
    return '● 지지합 성립 — 일상 생활 리듬과 공간 감각이 잘 맞습니다. 집을 편안한 안식처로 함께 꾸밀 수 있습니다.';
  }
  if (hasChung) {
    return '△ 일지 충(沖) 관계\n부동산 결정 시 의견 충돌 가능성이 있습니다. 명의 결정 전 충분한 대화가 필요하며, 전문가 조율을 권장합니다.';
  }
  return '○ 무난한 조합 — 특별한 합충이 없습니다. 서로의 강점(재물운·문서운)을 역할 분담하면 좋은 파트너십이 됩니다.';
}

String _spaceStory(String oeA, String oeB) {
  final key = ([oeA, oeB]..sort()).join('-');
  const stories = {
    '금-목': '도전과 절제가 교차하는 조합. 각자의 독립 공간(서재·작업실)을 확보하면 심리적 여유가 생깁니다. 화이트+그린 투 톤 인테리어가 균형감을 줍니다.',
    '금-수': '사색과 절제가 어우러지는 조합. 서재·침실 분리 구조가 이상적. 블루·그레이 계열 인테리어가 두 분의 에너지를 안정시킵니다.',
    '금-토': '질서와 안정을 함께 추구하는 조합. 정돈된 수납 공간과 화이트·베이지 톤이 심리적 안정감을 높여줍니다. 미니멀 구조가 최적입니다.',
    '금-화': '열정과 결단이 공존하는 조합. 밝은 조명과 메탈릭 포인트가 두 분의 에너지를 조화시킵니다. 주방을 집의 중심에 두세요.',
    '목-목': '성장 에너지가 넘치는 조합. 높은 층수와 큰 창이 두 분의 비전을 자극합니다. 그린 계열과 우드 소재가 집의 생기를 높입니다.',
    '목-수': '창의성과 성장이 만나는 조합. 개방형 구조와 자연 소재 가구가 시너지를 극대화합니다. 테라스·발코니가 있으면 이상적입니다.',
    '목-토': '성장과 안정의 균형 조합. 발코니 텃밭이나 그린 인테리어가 의견 차이를 완화하고 가족 유대를 강화해 줍니다.',
    '목-화': '성장 에너지가 순환하는 상생 조합. 채광 좋은 남향 거실이 가족 소통의 중심이 됩니다. 식물 인테리어가 집의 활기를 배가시킵니다.',
    '수-수': '깊은 사유와 감성의 조합. 조용한 입지와 서재 공간 확보가 핵심입니다. 무채색 계열의 안정감 있는 공간이 두 분의 에너지를 충전시킵니다.',
    '수-토': '현실감각과 유연함의 조합. 중성적 색상과 미니멀 가구로 안정감 있는 공간을 만드세요. 주변 자연환경이 좋은 입지가 잘 맞습니다.',
    '수-화': '열정과 지혜가 교차하는 조합. 주방과 욕실 동선을 잘 설계하면 생활 에너지가 균형을 이룹니다. 물 관련 인테리어(수족관·분수)가 긍정적 효과를 냅니다.',
    '토-토': '깊은 안정 지향 조합. 낮은 층 또는 1층이 잘 맞으며, 마당이 있는 집이 이상적입니다. 어스 톤 인테리어가 두 분의 안정감을 높입니다.',
    '토-화': '활력과 안정이 조화로운 상생 조합. 따뜻한 조명과 편안한 소파가 핵심 아이템. 오픈 거실 구조가 가족 에너지를 한 곳에 모아줍니다.',
    '화-화': '강한 열정과 활력의 조합. 냉색 계열 포인트와 오픈 베란다로 과열을 방지하세요. 환기가 잘 되는 구조가 두 분의 관계를 상쾌하게 유지해 줍니다.',
  };
  return stories[key] ??
      '균형 잡힌 조합입니다. 두 분의 생활 패턴을 중심으로 공간을 설계하면 좋은 시너지가 납니다.';
}
