import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';

// ─────────────────────────────────────────────────────
// 숫자 → 오행 변환 (낙서/하도 수리오행)
// ─────────────────────────────────────────────────────

class _NumberOehaeng {
  static String fromDigit(int d) {
    // 1,2=水 → 3,4=木 → 5,6=土(중앙) → 7,8=火 → 9,0=金
    // 낙서 수리: 1·6=水, 2·7=火, 3·8=木, 4·9=金, 5·10(0)=土
    const map = {1: '수', 6: '수', 2: '화', 7: '화', 3: '목', 8: '목', 4: '금', 9: '금', 5: '토', 0: '토'};
    return map[d] ?? '토';
  }

  static Map<String, int> digitSum(int number) {
    final scores = <String, int>{'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};
    final digits = number.toString().split('').map(int.parse);
    for (final d in digits) {
      final oe = fromDigit(d);
      scores[oe] = (scores[oe] ?? 0) + 1;
    }
    return scores;
  }

  static String dominant(Map<String, int> scores) {
    return scores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

// ─────────────────────────────────────────────────────
// 궁합 점수 계산
// ─────────────────────────────────────────────────────

class _CompatScore {
  final int score;
  final String label;
  final String emoji;
  final Color color;
  final String reason;

  const _CompatScore({
    required this.score, required this.label,
    required this.emoji, required this.color, required this.reason,
  });
}

_CompatScore calcCompat(String myOe, String numberOe) {
  // 오행 상생/상극 관계
  const saengMap = {
    '목': '화', '화': '토', '토': '금', '금': '수', '수': '목',
  };
  const geukMap = {
    '목': '토', '토': '수', '수': '화', '화': '금', '금': '목',
  };

  if (myOe == numberOe) {
    return _CompatScore(
      score: 92, label: '최고 궁합', emoji: '🌟',
      color: const Color(0xFF4E9E6B),
      reason: '같은 오행($numberOe)으로 기운이 일치합니다. 내 사주와 완벽하게 어울리는 호수입니다.',
    );
  }
  if (saengMap[numberOe] == myOe) {
    // 호수 오행이 나를 생(生)해줌
    return _CompatScore(
      score: 85, label: '상생 길수', emoji: '✨',
      color: const Color(0xFF5B9BD5),
      reason: '$numberOe 기운이 $myOe 기운을 생(生)해줍니다. 이 호수에서 에너지를 보완받습니다.',
    );
  }
  if (saengMap[myOe] == numberOe) {
    // 내가 호수 오행을 생해줌 — 나의 에너지 소모
    return _CompatScore(
      score: 68, label: '보통 (기운 소모)', emoji: '⚪',
      color: AppColors.textSecondary,
      reason: '내 $myOe 기운이 $numberOe 기운을 지원합니다. 안정적이나 다소 에너지 소모가 있습니다.',
    );
  }
  if (geukMap[myOe] == numberOe) {
    // 내가 극(剋)함 — 내가 강하게 제어
    return _CompatScore(
      score: 62, label: '제어 관계', emoji: '🔶',
      color: const Color(0xFFD4A017),
      reason: '내 $myOe 기운이 $numberOe 기운을 극(剋)합니다. 내가 주도하는 공간이지만 긴장감이 있습니다.',
    );
  }
  // 호수가 나를 극함
  return _CompatScore(
    score: 42, label: '주의 (극 관계)', emoji: '🔴',
    color: const Color(0xFFCC3300),
    reason: '$numberOe 기운이 내 $myOe 기운을 극(剋)합니다. 이 호수는 사주와 충돌할 수 있어 신중히 검토하세요.',
  );
}

// ─────────────────────────────────────────────────────
// 층수·호수 궁합 화면
// ─────────────────────────────────────────────────────

class FloorUnitScreen extends StatefulWidget {
  final SajuResult result;
  final String name;

  const FloorUnitScreen({
    super.key,
    required this.result,
    required this.name,
  });

  @override
  State<FloorUnitScreen> createState() => _FloorUnitScreenState();
}

class _FloorUnitScreenState extends State<FloorUnitScreen> {
  final _floorCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _screenshotCtrl = ScreenshotController();

  _Result? _result;

  @override
  void dispose() {
    _floorCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _analyze() {
    final floorText = _floorCtrl.text.trim();
    final unitText = _unitCtrl.text.trim();
    if (floorText.isEmpty || unitText.isEmpty) return;

    final floor = int.tryParse(floorText);
    final unit = int.tryParse(unitText);
    if (floor == null || unit == null) return;

    final myOe = widget.result.mainOehaeng;

    final floorScores = _NumberOehaeng.digitSum(floor);
    final unitScores = _NumberOehaeng.digitSum(unit);
    final floorOe = _NumberOehaeng.dominant(floorScores);
    final unitOe = _NumberOehaeng.dominant(unitScores);

    final floorCompat = calcCompat(myOe, floorOe);
    final unitCompat = calcCompat(myOe, unitOe);
    final totalScore = ((floorCompat.score + unitCompat.score) / 2).round();

    setState(() {
      _result = _Result(
        floor: floor, unit: unit,
        floorOe: floorOe, unitOe: unitOe,
        floorCompat: floorCompat, unitCompat: unitCompat,
        totalScore: totalScore, myOe: myOe,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('층수·호수 궁합', style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 16, fontWeight: FontWeight.bold,
            color: Colors.white, letterSpacing: 1.5,
          )),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildInputCard(),
          const SizedBox(height: 14),
          if (_result != null) ...[
            _buildResultCard(_result!),
            const SizedBox(height: 14),
            _buildShareButton(),
          ],
        ]),
      ),
    );
  }

  Widget _buildInputCard() {
    final myOe = widget.result.mainOehaeng;
    final myColor = AppColors.getOehaengColor(myOe);

    return TraditionalCard(
      doubleBorder: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '층수·호수 입력', icon: '🏢'),
        const SizedBox(height: 4),
        // 내 오행 정보
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: myColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: myColor.withOpacity(0.3)),
          ),
          child: Row(children: [
            OehaengBadge(myOe),
            const SizedBox(width: 8),
            Text('${widget.name}님의 주 오행: $myOe', style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 13, color: myColor, fontWeight: FontWeight.bold,
            )),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _inputField(
            controller: _floorCtrl,
            label: '층수',
            hint: '예: 12',
          )),
          const SizedBox(width: 10),
          Expanded(child: _inputField(
            controller: _unitCtrl,
            label: '호수',
            hint: '예: 1205',
          )),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _analyze,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.accent.withOpacity(0.8), AppColors.accent,
                ]),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(child: Text('궁합 분석', style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 14, fontWeight: FontWeight.bold,
                color: Colors.black, letterSpacing: 1,
              ))),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 18,
          color: AppColors.textPrimary, fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: AppColors.accent.withOpacity(0.6)),
          ),
        ),
        onSubmitted: (_) => _analyze(),
      ),
    ]);
  }

  Widget _buildResultCard(_Result r) {
    return Screenshot(
      controller: _screenshotCtrl,
      child: Container(
        color: AppColors.surface,
        child: TraditionalCard(
          doubleBorder: true,
          borderColor: _scoreColor(r.totalScore).withOpacity(0.5),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── 총 궁합 점수 ──
            Row(children: [
              const KoreanSectionTitle(title: '궁합 결과', icon: '🎯', showDivider: false),
              const Spacer(),
              Text('${r.floor}층 ${r.unit}호', style: const TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 13,
                color: AppColors.textSecondary, letterSpacing: 0.5,
              )),
            ]),
            Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(gradient: LinearGradient(
                colors: [_scoreColor(r.totalScore).withOpacity(0.5), Colors.transparent]))),

            Center(child: Column(children: [
              Text('${r.totalScore}', style: TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 56,
                fontWeight: FontWeight.bold, color: _scoreColor(r.totalScore),
                shadows: [Shadow(color: _scoreColor(r.totalScore).withOpacity(0.4),
                  blurRadius: 16)],
              )),
              Text(_scoreLabel(r.totalScore), style: TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 16,
                color: _scoreColor(r.totalScore), letterSpacing: 1,
              )),
            ])),

            const SizedBox(height: 16),
            KoreanProgressBar(
              value: r.totalScore / 100,
              color: _scoreColor(r.totalScore),
              height: 10,
            ),
            const SizedBox(height: 16),

            // ── 층수·호수 개별 분석 ──
            _numberRow('층수 ${r.floor}층', r.floorOe, r.floorCompat),
            const SizedBox(height: 10),
            _numberRow('호수 ${r.unit}호', r.unitOe, r.unitCompat),

            const SizedBox(height: 14),

            // ── 명리학 해석 ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _scoreColor(r.totalScore).withOpacity(0.07),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _scoreColor(r.totalScore).withOpacity(0.25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('층수: ${r.floorCompat.reason}', style: const TextStyle(
                  fontSize: 12, color: AppColors.textPrimary, height: 1.5)),
                const SizedBox(height: 6),
                Text('호수: ${r.unitCompat.reason}', style: const TextStyle(
                  fontSize: 12, color: AppColors.textPrimary, height: 1.5)),
              ]),
            ),

            const SizedBox(height: 10),
            // 앱 브랜딩
            Center(child: Text('부동산 사주 · realestate-saju.surge.sh',
              style: const TextStyle(
                fontSize: 10, color: AppColors.textMuted, letterSpacing: 0.5))),
          ]),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _numberRow(String label, String oe, _CompatScore compat) {
    final oeColor = AppColors.getOehaengColor(oe);
    const hanja = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: compat.color.withOpacity(0.3)),
      ),
      child: Row(children: [
        // 오행 원
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: oeColor.withOpacity(0.12),
            border: Border.all(color: oeColor.withOpacity(0.5)),
          ),
          child: Center(child: Text(hanja[oe] ?? oe, style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 16,
            fontWeight: FontWeight.bold, color: oeColor,
          ))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(
            fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.3)),
          Text('$oe 기운  ${compat.emoji} ${compat.label}', style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 13,
            fontWeight: FontWeight.bold, color: compat.color,
          )),
        ])),
        Text('${compat.score}점', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: compat.color)),
      ]),
    );
  }

  Widget _buildShareButton() {
    return GestureDetector(
      onTap: _share,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.share_outlined, size: 16, color: AppColors.accent),
          SizedBox(width: 8),
          Text('결과 카드 공유하기', style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 13,
            color: AppColors.accent, letterSpacing: 0.5,
          )),
        ]),
      ),
    );
  }

  Future<void> _share() async {
    if (_result == null) return;
    try {
      final bytes = await _screenshotCtrl.capture(pixelRatio: 3.0);
      if (bytes == null) return;
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'floor_unit.png')],
        text: '${_result!.floor}층 ${_result!.unit}호 궁합 ${_result!.totalScore}점 '
            '— ${widget.name}님의 부동산 사주 분석\n'
            'https://realestate-saju.surge.sh',
      );
    } catch (_) {}
  }

  Color _scoreColor(int score) {
    if (score >= 85) return const Color(0xFF4E9E6B);
    if (score >= 70) return const Color(0xFF5B9BD5);
    if (score >= 55) return const Color(0xFFD4A017);
    return const Color(0xFFCC3300);
  }

  String _scoreLabel(int score) {
    if (score >= 85) return '최고 궁합 ★★★★★';
    if (score >= 70) return '좋은 궁합 ★★★★';
    if (score >= 55) return '보통 궁합 ★★★';
    return '주의 필요 ★★';
  }
}

// ─── 결과 모델 ─────────────────────────────────────────

class _Result {
  final int floor, unit;
  final String floorOe, unitOe, myOe;
  final _CompatScore floorCompat, unitCompat;
  final int totalScore;

  const _Result({
    required this.floor, required this.unit,
    required this.floorOe, required this.unitOe, required this.myOe,
    required this.floorCompat, required this.unitCompat,
    required this.totalScore,
  });
}
