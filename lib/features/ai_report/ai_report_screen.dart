// ai_report_screen.dart — AI 동네 리포트 화면
// 자치구 선택 → Claude API → 사주 맞춤 설명 생성
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/saju/saju_calculator.dart';
import '../../core/services/claude_api_service.dart';
import '../../shared/models/saju_profile.dart';
import '../map/district_map_data.dart';
import '../lifestyle/lifestyle_model.dart';

class AiReportScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;

  const AiReportScreen({super.key, required this.result, required this.profile});

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> {
  DistrictData? _selected;
  String? _reportText;
  bool _loading = false;
  LifestyleProfile? _lifestyle;
  String? _error;

  @override
  void initState() {
    super.initState();
    LifestyleProfile.load().then((l) => setState(() => _lifestyle = l));
    // 기본: 사주 점수 1위 자치구 자동 선택
    _autoSelectBest();
  }

  void _autoSelectBest() {
    final sorted = [...seoulDistricts]
      ..sort((a, b) => calcDistrictScore(b, widget.result.mainOehaeng,
              widget.result.weakOehaeng)
          .compareTo(calcDistrictScore(a, widget.result.mainOehaeng,
              widget.result.weakOehaeng)));
    if (sorted.isNotEmpty) _selected = sorted.first;
  }

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

  Future<void> _generate() async {
    if (_selected == null || _loading) return;
    setState(() { _loading = true; _reportText = null; _error = null; });
    final d = _selected!;
    final extra = districtExtras[d.name];
    final score = calcDistrictScore(d, widget.result.mainOehaeng, widget.result.weakOehaeng);

    final text = await ClaudeApiService.generateDistrictReport(
      districtName: d.name,
      districtDesc: d.description,
      mainOe: widget.result.mainOehaeng,
      weakOe: widget.result.weakOehaeng,
      name: widget.profile.name,
      sajuScore: score,
      transitScore: extra?.transit ?? 70,
      amenityScore: extra?.amenity ?? 70,
      commuteDistrict: _lifestyle?.commuteDistrict,
      budgetAk: _lifestyle?.budgetAk,
      childrenCount: _lifestyle?.childrenCount,
      hasPet: _lifestyle?.hasPet ?? false,
    );

    setState(() {
      _loading = false;
      if (text.startsWith('❌') || text.startsWith('⚠️')) {
        _error = text;
      } else {
        _reportText = text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('AI 동네 리포트',
              style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 18,
                  color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
        children: [
          _buildApiKeyNotice(),
          const SizedBox(height: 14),
          _buildDistrictPicker(),
          const SizedBox(height: 14),
          if (_selected != null) _buildSelectedCard(),
          const SizedBox(height: 14),
          GoldButton(
            label: 'AI 리포트 생성하기',
            onTap: _selected != null ? _generate : null,
            loading: _loading,
          ),
          if (_loading) ...[
            const SizedBox(height: 24),
            _buildLoadingState(),
          ],
          if (_error != null) ...[
            const SizedBox(height: 14),
            _buildErrorCard(),
          ],
          if (_reportText != null) ...[
            const SizedBox(height: 14),
            _buildReportCard(),
          ],
        ],
      ),
    );
  }

  // ─── API 키 안내 ───────────────────────────────────
  Widget _buildApiKeyNotice() {
    if (claudeApiConfigured) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.jade.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.jade.withOpacity(0.3)),
        ),
        child: Row(children: const [
          Icon(Icons.check_circle_outline, size: 16, color: AppColors.jade),
          SizedBox(width: 8),
          Text('Claude AI 연결됨', style: TextStyle(fontSize: 12, color: AppColors.jade)),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Text(
        '⚠️ Claude API 키 미설정\nclaude_api_service.dart의 _claudeApiKey에 키를 입력하면 AI 리포트가 활성화됩니다.\nhttps://console.anthropic.com/settings/keys',
        style: TextStyle(fontSize: 11, color: Colors.orange, height: 1.5),
      ),
    );
  }

  // ─── 자치구 선택 드롭다운 ──────────────────────────
  Widget _buildDistrictPicker() {
    final sorted = [...seoulDistricts]
      ..sort((a, b) => calcDistrictScore(b, widget.result.mainOehaeng,
              widget.result.weakOehaeng)
          .compareTo(calcDistrictScore(a, widget.result.mainOehaeng,
              widget.result.weakOehaeng)));

    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const KoreanSectionTitle(title: '📍 분석할 동네 선택', showDivider: false),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DistrictData>(
              value: _selected,
              isExpanded: true,
              dropdownColor: AppColors.cardBg,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent),
              items: sorted.map((d) {
                final score = calcDistrictScore(d, widget.result.mainOehaeng,
                    widget.result.weakOehaeng);
                return DropdownMenuItem(
                  value: d,
                  child: Row(children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(d.name, style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text('$score점', style: TextStyle(
                        fontSize: 11, color: _oeColor(d.oehaeng),
                        fontWeight: FontWeight.bold)),
                  ]),
                );
              }).toList(),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() { _selected = v; _reportText = null; _error = null; });
              },
            ),
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── 선택된 자치구 카드 ────────────────────────────
  Widget _buildSelectedCard() {
    final d = _selected!;
    final score = calcDistrictScore(d, widget.result.mainOehaeng, widget.result.weakOehaeng);
    final oeColor = _oeColor(d.oehaeng);
    final extra = districtExtras[d.name];

    return TraditionalCard(
      borderColor: oeColor.withOpacity(0.4),
      child: Row(children: [
        Text(d.emoji, style: const TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.name, style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 16,
              fontWeight: FontWeight.bold, color: oeColor)),
          Text('${d.oehaeng} · ${d.keyword}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          if (extra != null)
            Text('교통 ${extra.transit} · 편의 ${extra.amenity} · 평균 ${extra.avgPriceAk}억',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ])),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: oeColor.withOpacity(0.1), shape: BoxShape.circle,
            border: Border.all(color: oeColor.withOpacity(0.4)),
          ),
          child: Text('$score', style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 16, fontWeight: FontWeight.bold, color: oeColor)),
        ),
      ]),
    ).animate(delay: 50.ms).fadeIn();
  }

  Widget _buildLoadingState() {
    return TraditionalCard(
      child: Column(children: [
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('命', style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
        ).animate().then().shimmer(duration: 1500.ms, color: AppColors.accentLight),
        const SizedBox(height: 12),
        const Text('AI가 사주와 지역 기운을 분석하는 중...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.3)),
      ),
      child: Text(_error!, style: const TextStyle(fontSize: 13,
          color: AppColors.red, height: 1.6)),
    ).animate().fadeIn();
  }

  // ─── AI 리포트 카드 ─────────────────────────────────
  Widget _buildReportCard() {
    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: const Text('✦ AI 맞춤 리포트', style: TextStyle(
                fontFamily: 'NotoSerifKR', fontSize: 13,
                fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: _reportText!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('클립보드에 복사됐습니다'),
                    duration: Duration(seconds: 2)));
            },
            child: const Icon(Icons.copy_outlined, size: 16,
                color: AppColors.textSecondary),
          ),
        ]),
        const SizedBox(height: 10),
        Divider(color: AppColors.accent.withOpacity(0.2)),
        const SizedBox(height: 10),
        Text(_reportText!, style: const TextStyle(fontSize: 14,
            color: AppColors.textPrimary, height: 1.8, letterSpacing: 0.2)),
        const SizedBox(height: 12),
        GoldButton(
          label: '다른 동네 분석하기',
          onTap: () => setState(() { _reportText = null; _error = null; }),
          verticalPadding: 12,
          fontSize: 13,
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
}
