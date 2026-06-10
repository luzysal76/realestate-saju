// lifestyle_input_screen.dart — 생활패턴 프로필 입력
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import 'lifestyle_model.dart';
import 'lifestyle_result_screen.dart';

class LifestyleInputScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;
  final LifestyleProfile? existing;

  const LifestyleInputScreen({
    super.key,
    required this.result,
    required this.profile,
    this.existing,
  });

  @override
  State<LifestyleInputScreen> createState() => _LifestyleInputScreenState();
}

class _LifestyleInputScreenState extends State<LifestyleInputScreen> {
  late String _commute;
  late double _budgetSlider; // 0~15
  late int _children;
  late bool _hasPet;
  late String _homeType;
  bool _saving = false;

  // 슬라이더 값 → 억원
  static int _sliderToAk(double v) {
    const steps = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20];
    final i = v.round().clamp(0, steps.length - 1);
    return steps[i];
  }

  static String _sliderLabel(double v) {
    final ak = _sliderToAk(v);
    if (ak == 0) return '무관 (제한 없음)';
    if (ak >= 20) return '15억 이상';
    return '$ak억 이내';
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing ?? const LifestyleProfile();
    _commute = e.commuteDistrict;
    _hasPet = e.hasPet;
    _homeType = e.preferredHomeType;
    _children = e.childrenCount;
    // budgetAk → slider index
    const steps = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 15, 20];
    final idx = steps.indexWhere((s) => s >= e.budgetAk);
    _budgetSlider = (idx < 0 ? steps.length - 1 : idx).toDouble();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final lifestyle = LifestyleProfile(
      commuteDistrict: _commute,
      budgetAk: _sliderToAk(_budgetSlider),
      childrenCount: _children,
      hasPet: _hasPet,
      preferredHomeType: _homeType,
    );
    await lifestyle.save();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LifestyleResultScreen(
        result: widget.result,
        profile: widget.profile,
        lifestyle: lifestyle,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('생활패턴 설정',
              style: TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 18,
                  color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildIntroCard(),
          const SizedBox(height: 16),
          _buildBudgetSection(),
          const SizedBox(height: 14),
          _buildCommuteSection(),
          const SizedBox(height: 14),
          _buildFamilySection(),
          const SizedBox(height: 14),
          _buildHomeTypeSection(),
          const SizedBox(height: 24),
          GoldButton(
            label: '맞춤 분석 시작하기',
            onTap: _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.3),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('生', style: TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 36,
              fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('생활패턴 맞춤 분석',
              style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 14,
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text('사주 + 나의 생활조건을 결합해\n최적의 동네와 집 유형을 추천합니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
        ])),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ─── 예산 슬라이더 ────────────────────────────────────
  Widget _buildBudgetSection() {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '💰 주거 예산', showDivider: false),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _sliderLabel(_budgetSlider),
            style: const TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 22,
                fontWeight: FontWeight.bold, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.divider,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withOpacity(0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: _budgetSlider,
            min: 0, max: 13,
            divisions: 13,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              setState(() => _budgetSlider = v);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('무관', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('15억+', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ]),
    ).animate(delay: 80.ms).fadeIn();
  }

  // ─── 출근지 선택 ──────────────────────────────────────
  Widget _buildCommuteSection() {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '🚇 출근지 (자치구)', showDivider: false),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _commute,
              isExpanded: true,
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
              items: LifestyleProfile.seoulDistricts25.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d,
                    style: TextStyle(
                        color: d == '재택/없음' ? AppColors.textSecondary : AppColors.textPrimary)),
              )).toList(),
              onChanged: (v) => setState(() => _commute = v ?? '재택/없음'),
            ),
          ),
        ),
        if (_commute != '재택/없음')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('📍 $_commute 접근성이 높은 동네를 우선 추천합니다.',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ),
      ]),
    ).animate(delay: 120.ms).fadeIn();
  }

  // ─── 가족 구성 ────────────────────────────────────────
  Widget _buildFamilySection() {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '👨‍👩‍👧 가족 구성', showDivider: false),
        const SizedBox(height: 14),
        // 자녀수
        Row(children: [
          const Text('자녀수', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const Spacer(),
          _CountButton(
            icon: Icons.remove,
            onTap: _children > 0 ? () => setState(() => _children--) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('$_children명',
                style: const TextStyle(
                    fontFamily: 'NotoSerifKR', fontSize: 18,
                    fontWeight: FontWeight.bold, color: AppColors.accent)),
          ),
          _CountButton(
            icon: Icons.add,
            onTap: _children < 5 ? () => setState(() => _children++) : null,
          ),
        ]),
        const SizedBox(height: 16),
        // 반려동물
        Row(children: [
          const Text('반려동물', style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          const SizedBox(width: 6),
          const Text('(강아지·고양이 등)',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _hasPet = !_hasPet);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50, height: 26,
              decoration: BoxDecoration(
                color: _hasPet ? AppColors.accent : AppColors.cardBg2,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: _hasPet ? AppColors.accent : AppColors.divider),
              ),
              child: Stack(children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  left: _hasPet ? 26 : 2, top: 2,
                  child: Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasPet ? AppColors.surface : AppColors.textSecondary,
                    ),
                    child: Center(child: Text(
                      _hasPet ? '🐾' : '',
                      style: const TextStyle(fontSize: 12),
                    )),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ]),
    ).animate(delay: 160.ms).fadeIn();
  }

  // ─── 선호 집 유형 ─────────────────────────────────────
  Widget _buildHomeTypeSection() {
    const types = [
      ('무관', '🏠', '제한 없음'),
      ('아파트', '🏢', '단지형 생활'),
      ('오피스텔', '🏙️', '직주근접'),
      ('빌라', '🏘️', '소규모 생활'),
      ('단독', '🏡', '독립 공간'),
    ];
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '🏠 선호 집 유형', showDivider: false),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, childAspectRatio: 1.6,
          crossAxisSpacing: 8, mainAxisSpacing: 8,
          children: types.map((t) {
            final isSelected = _homeType == t.$1;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _homeType = t.$1);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.12)
                      : AppColors.cardBg2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.divider,
                    width: isSelected ? 1.5 : 0.8,
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(t.$2, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 3),
                  Text(t.$1,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.accent : AppColors.textPrimary)),
                  Text(t.$3,
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    ).animate(delay: 200.ms).fadeIn();
  }
}

class _CountButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CountButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.selectionClick();
          onTap!();
        }
      },
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.accent.withOpacity(0.12) : AppColors.cardBg2,
          shape: BoxShape.circle,
          border: Border.all(
            color: onTap != null ? AppColors.accent.withOpacity(0.5) : AppColors.divider),
        ),
        child: Icon(icon, size: 16,
            color: onTap != null ? AppColors.accent : AppColors.textMuted),
      ),
    );
  }
}
