// building_compat_screen.dart — 건물 궁합 분석 + AI 심층 분석
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../core/services/claude_api_service.dart';
import '../../shared/models/saju_profile.dart';
import '../../features/map/kakao_address_service.dart';
import 'building_result_card.dart';

class BuildingCompatScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;
  const BuildingCompatScreen({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  State<BuildingCompatScreen> createState() => _BuildingCompatScreenState();
}

class _BuildingCompatScreenState extends State<BuildingCompatScreen> {
  final _addrCtrl = TextEditingController();
  DateTime? _approvalDate;
  BuildingCompatResult? _compatResult;
  bool _analyzed = false;

  // AI 분석
  String _aiAnalysis = '';
  bool _aiLoading = false;

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  // ─── 사주 분석 ───────────────────────────────────────

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
    setState(() {
      _compatResult = _calcCompat(bldCg, bldJi);
      _analyzed = true;
      _aiAnalysis = '';
    });
  }

  BuildingCompatResult _calcCompat(String bldCg, String bldJi) {
    final ilCg = widget.result.ilgan;
    final ilJi = widget.result.ilji;
    final cgRel = _cheonganRel(ilCg, bldCg);
    final jiRel = _jijiRel(ilJi, bldJi);
    final ss = SajuCalculator.calcSipSeong(ilCg, bldCg);
    final score = _baseScore(cgRel, jiRel, ss.name);
    return BuildingCompatResult(
      bldGanJi: '$bldCg$bldJi',
      sipseong: ss.name,
      cgRel: cgRel,
      jiRel: jiRel,
      score: score,
      title: _title(score),
      type: _compatType(score, ss.name, jiRel),
      advice: _advice(score, ss.name, jiRel, cgRel),
    );
  }

  String _cheonganRel(String il, String bld) {
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
    if (cgRel == '천간합(合)') s += 20;
    else if (cgRel == '건물이 나를 생(生)') s += 15;
    else if (cgRel == '건물이 생(生)함') s += 10;
    else if (cgRel == '오행 일치') s += 8;
    else if (cgRel == '건물이 나를 극(剋)') s -= 15;
    else if (cgRel == '건물이 극받음(剋)') s += 5;
    if (jiRel == '지지합(合)') s += 18;
    else if (jiRel == '지지 상생(生)') s += 12;
    else if (jiRel == '지지 동(同)') s += 8;
    else if (jiRel == '지지충(沖)') s -= 20;
    else if (jiRel == '지지 상극(剋)') s -= 10;
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

  // ─── AI 분석 ─────────────────────────────────────────

  Future<void> _runAiAnalysis() async {
    if (_compatResult == null) return;
    setState(() { _aiLoading = true; _aiAnalysis = ''; });
    final text = await ClaudeApiService.generateBuildingAnalysis(
      name: widget.profile.name,
      ilgan: widget.result.ilgan,
      ilji: widget.result.ilji,
      mainOe: widget.result.mainOehaeng,
      bldGanJi: _compatResult!.bldGanJi,
      sipseong: _compatResult!.sipseong,
      cgRel: _compatResult!.cgRel,
      jiRel: _compatResult!.jiRel,
      score: _compatResult!.score,
      compatType: _compatResult!.type,
      address: _addrCtrl.text.trim(),
    );
    if (mounted) setState(() { _aiAnalysis = text; _aiLoading = false; });
  }

  // ─── Kakao 주소 검색 ─────────────────────────────────

  Future<void> _showAddressSearch() async {
    if (!kakaoKeyConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 API 키를 설정하면 주소 자동완성이 활성화됩니다')),
      );
      return;
    }
    final query = ValueNotifier('');
    final results = ValueNotifier<List<AddressResult>>([]);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('주소 검색', style: TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 15,
              color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            autofocus: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '건물명 또는 주소 입력',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 18),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider, width: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.divider, width: 0.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.accent.withOpacity(0.6))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (v) async {
              query.value = v;
              if (v.length >= 2) {
                results.value = await searchKakaoAddress(v);
              } else {
                results.value = [];
              }
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<AddressResult>>(
            valueListenable: results,
            builder: (_, list, __) => SizedBox(
              height: list.isEmpty ? 0 : (list.length * 56.0).clamp(0, 224),
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(
                    height: 0.5, color: AppColors.divider.withOpacity(0.5)),
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.accent, size: 16),
                  title: Text(list[i].name,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary)),
                  subtitle: Text(list[i].address,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                  onTap: () {
                    _addrCtrl.text = list[i].address;
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  // ─── UI ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('건물 궁합',
              style: TextStyle(fontFamily: 'NotoSerifKR',
                  fontSize: 18, color: Colors.white, letterSpacing: 3)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 30),
        children: [
          _buildInputCard().animate().fadeIn(),
          const SizedBox(height: 12),
          if (_analyzed && _compatResult != null) ...[
            BuildingResultCard(
              result: _compatResult!,
              ilgan: widget.result.ilgan,
              ilji: widget.result.ilji,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
            const SizedBox(height: 12),
            _buildAiCard().animate().fadeIn(delay: 200.ms),
          ],
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

        // 주소 입력 + 검색 버튼
        Row(children: [
          Expanded(
            child: TextField(
              controller: _addrCtrl,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '예) 서울시 강남구 역삼동 000-00',
                hintStyle: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.location_on_outlined,
                    color: AppColors.textSecondary, size: 18),
                filled: true, fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.divider, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.divider, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: AppColors.accent.withOpacity(0.6))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showAddressSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: const Icon(Icons.search, color: AppColors.accent, size: 18),
            ),
          ),
        ]),
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
                    ? AppColors.accent.withOpacity(0.6) : AppColors.divider,
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
                style: TextStyle(fontSize: 13,
                    color: _approvalDate != null
                        ? AppColors.textPrimary : AppColors.textMuted),
              ),
              const Spacer(),
              if (_approvalDate != null)
                Text(
                  SajuCalculator.yearToGanJi(_approvalDate!.year)['cheongan']! +
                      SajuCalculator.yearToGanJi(_approvalDate!.year)['jiji']!,
                  style: const TextStyle(fontFamily: 'NotoSerifKR',
                      fontSize: 13, color: AppColors.accent,
                      fontWeight: FontWeight.bold),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        const Text('※ 등기부등본 또는 건축물대장의 "사용승인일"을 입력하세요',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
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
                  style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 15,
                      color: Colors.white, letterSpacing: 1.5,
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
      firstDate: DateTime(1950), lastDate: DateTime.now(),
      helpText: '준공일(사용승인일) 선택',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onSurface: AppColors.textPrimary, surface: AppColors.cardBg),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _approvalDate = picked);
  }

  Widget _buildAiCard() {
    if (!claudeApiConfigured) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Row(children: [
          const Text('🤖', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI 심층 분석',
                style: TextStyle(fontFamily: 'NotoSerifKR',
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            const Text('Claude API 키 설정 시 사용 가능합니다',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ])),
        ]),
      );
    }

    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🤖', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (b) => AppColors.goldGradient.createShader(b),
            child: const Text('AI 심층 분석',
                style: TextStyle(fontFamily: 'NotoSerifKR',
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 0.5)),
          ),
          const Spacer(),
          if (!_aiLoading && _aiAnalysis.isEmpty)
            GestureDetector(
              onTap: _runAiAnalysis,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFC9A84C), Color(0xFFE8D08A)]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('분석 시작',
                    style: TextStyle(fontSize: 12, color: Colors.black,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
        if (_aiLoading) ...[
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator(
              color: AppColors.accent, strokeWidth: 2)),
          const SizedBox(height: 8),
          const Center(child: Text('AI가 분석 중입니다...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
        ],
        if (_aiAnalysis.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Text(_aiAnalysis,
                style: const TextStyle(fontSize: 12.5,
                    color: AppColors.textPrimary, height: 1.7)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: _runAiAnalysis,
              child: const Text('↻ 재분석',
                  style: TextStyle(fontSize: 10, color: AppColors.accent)),
            ),
          ),
        ],
      ]),
    );
  }
}
