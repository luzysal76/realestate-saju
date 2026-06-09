import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/lunar_converter.dart';
import '../../core/saju/wonkwang_data.dart';
import '../../shared/models/saju_profile.dart';
import '../dashboard/dashboard_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: '1990-01-01');

  DateTime _birthDate = DateTime(1990, 1, 1);
  int _birthHour = 12;
  int _birthMinute = 0;
  String _gender = '남';
  bool _unknownHour = false;
  bool _isLunar = false;      // 음력 입력 모드
  bool _isLeapMonth = false;  // 윤달 여부
  // 원광식 진태양시 보정
  bool _useTrueSolarTime = false;
  String? _birthCity;

  final List<String> _hourLabels = List.generate(24, (i) =>
    '${i.toString().padLeft(2, '0')}시 (${_hourToJiji(i)}시)');

  static String _hourToJiji(int h) {
    const jijiHours = [
      '자', '축', '축', '인', '인', '묘',
      '묘', '진', '진', '사', '사', '오',
      '오', '미', '미', '신', '신', '유',
      '유', '술', '술', '해', '해', '자',
    ];
    return jijiHours[h];
  }

  @override
  void initState() {
    super.initState();
    _dateCtrl.addListener(_onDateTextChanged);
  }

  void _onDateTextChanged() {
    if (_isLunar) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  /// 날짜 텍스트(YYYY-MM-DD) → DateTime 변환 (유효성 검사 포함)
  DateTime? _parseBirthDate() {
    final digits = _dateCtrl.text.replaceAll('-', '');
    if (digits.length != 8) return null;
    final y = int.tryParse(digits.substring(0, 4));
    final m = int.tryParse(digits.substring(4, 6));
    final d = int.tryParse(digits.substring(6, 8));
    if (y == null || m == null || d == null) return null;
    if (y < 1930 || y > DateTime.now().year) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > (_isLunar ? 30 : 31)) return null;

    if (_isLunar) {
      return LunarConverter.lunarToSolar(y, m, d, isLeap: _isLeapMonth);
    }

    try {
      final dt = DateTime(y, m, d);
      if (dt.isAfter(DateTime.now())) return null;
      return dt;
    } catch (_) { return null; }
  }

  /// 음력 모드일 때 변환된 양력 날짜를 안내 문자열로 반환
  String? _lunarPreviewText() {
    if (!_isLunar) return null;
    final solar = _parseBirthDate();
    if (solar == null) return null;
    return '→ 양력 ${solar.year}년 ${solar.month}월 ${solar.day}일';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final parsed = _parseBirthDate();
    if (parsed == null) return; // validator가 이미 막음
    _birthDate = parsed;

    final cityLon = (_useTrueSolarTime && _birthCity != null)
        ? TrueSolarTime.longitude(_birthCity!)
        : null;

    final profile = SajuProfile(
      name: _nameCtrl.text.trim(),
      birthDate: _birthDate,
      birthHour: _unknownHour ? 25 : _birthHour,
      birthMinute: _unknownHour ? 0 : _birthMinute,
      birthLongitude: cityLon,
      gender: _gender,
    );

    final box = Hive.box<SajuProfile>('profiles');
    // 동일한 이름+생년월일 프로필이 이미 있으면 업데이트, 없으면 추가
    final existingIdx = box.values.toList().indexWhere(
      (p) => p.name == profile.name &&
          p.birthDate.year == profile.birthDate.year &&
          p.birthDate.month == profile.birthDate.month &&
          p.birthDate.day == profile.birthDate.day,
    );
    if (existingIdx >= 0) {
      box.putAt(existingIdx, profile);
    } else {
      box.add(profile);
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a1, a2) => DashboardScreen(profile: profile),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0E8D5), Color(0xFFF7F2EA)],
          ),
        ),
        child: Stack(children: [
          // 배경 단청 패턴
          Positioned.fill(
            child: CustomPaint(
              painter: const DancheongPatternPainter(opacity: 0.025),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 헤더 ──────────────────────────────────────
                    Center(
                      child: Column(children: [
                        const SizedBox(height: 8),
                        const TaegeukSymbol(size: 56),
                        const SizedBox(height: 14),
                        ShaderMask(
                          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                          child: const Text(
                            '命理 入力',
                            style: TextStyle(
                              fontFamily: 'NotoSerifKR',
                              fontSize: 22, fontWeight: FontWeight.bold,
                              color: Colors.white, letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '명리 입력',
                          style: TextStyle(
                            fontFamily: 'NotoSerifKR',
                            fontSize: 13, color: AppColors.textSecondary,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(width: 30, height: 0.5,
                              color: AppColors.accent.withOpacity(0.4)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('✦',
                              style: TextStyle(color: AppColors.accent, fontSize: 9)),
                          ),
                          Container(width: 30, height: 0.5,
                              color: AppColors.accent.withOpacity(0.4)),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          '생년월일시로 나의 부동산 천명을 확인합니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ]),
                    )
                    .animate(delay: 100.ms).fadeIn().slideY(begin: 0.15),

                    const SizedBox(height: 24),

                    // ─── 이름 ──────────────────────────────────────
                    TraditionalCard(
                      doubleBorder: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('姓名', '성명 (이름 또는 닉네임)'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _nameCtrl,
                            style: const TextStyle(
                              fontFamily: 'NotoSerifKR',
                              color: AppColors.textPrimary, fontSize: 16,
                              letterSpacing: 1,
                            ),
                            decoration: _inputDeco('예: 홍길동'),
                            validator: (v) => (v == null || v.isEmpty)
                                ? '이름을 입력해주세요' : null,
                          ),
                        ],
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),

                    const SizedBox(height: 12),

                    // ─── 생년월일 (숫자 직접 입력) ──────────────────
                    TraditionalCard(
                      doubleBorder: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 라벨 + 양력/음력 토글
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _fieldLabel('生年月日', '생년월일'),
                              Row(children: [
                                _calTypeBtn('양력', '陽曆', false),
                                const SizedBox(width: 4),
                                _calTypeBtn('음력', '陰曆', true),
                              ]),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _dateCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_DateInputFormatter()],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'NotoSerifKR',
                              color: AppColors.textPrimary,
                              fontSize: 20, letterSpacing: 3,
                            ),
                            decoration: _inputDeco('').copyWith(
                              hintText: 'YYYY-MM-DD',
                              hintStyle: TextStyle(
                                fontSize: 17, letterSpacing: 3,
                                color: AppColors.textSecondary.withOpacity(0.35),
                              ),
                            ),
                            onTap: () => _dateCtrl.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: _dateCtrl.text.length,
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (_) {
                              if (_parseBirthDate() == null) {
                                return _isLunar
                                    ? '음력 날짜를 확인해주세요 (예: 1976-10-02)'
                                    : '날짜를 확인해주세요 (예: 1976-10-02)';
                              }
                              return null;
                            },
                          ),

                          // 음력 모드: 윤달 체크 + 변환 미리보기
                          if (_isLunar) ...[
                            const SizedBox(height: 8),
                            Row(children: [
                              // 윤달 체크박스
                              GestureDetector(
                                onTap: () => setState(() {
                                  _isLeapMonth = !_isLeapMonth;
                                }),
                                child: Row(children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    width: 18, height: 18,
                                    decoration: BoxDecoration(
                                      color: _isLeapMonth
                                          ? AppColors.accent.withOpacity(0.2)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(
                                        color: _isLeapMonth
                                            ? AppColors.accent
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: _isLeapMonth
                                      ? const Icon(Icons.check,
                                          size: 13, color: AppColors.accent)
                                      : null,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '윤달 (閏月)',
                                    style: TextStyle(
                                      fontFamily: 'NotoSerifKR',
                                      fontSize: 12,
                                      color: _isLeapMonth
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ]),
                              ),
                              const Spacer(),
                              // 변환된 양력 날짜 미리보기
                              Builder(builder: (_) {
                                final preview = _lunarPreviewText();
                                if (preview == null) return const SizedBox.shrink();
                                return Text(
                                  preview,
                                  style: const TextStyle(
                                    fontFamily: 'NotoSerifKR',
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    letterSpacing: 0.3,
                                  ),
                                );
                              }),
                            ]),
                          ],
                        ],
                      ),
                    ).animate(delay: 280.ms).fadeIn().slideX(begin: -0.1),

                    const SizedBox(height: 12),

                    // ─── 성별 ───────────────────────────────────────
                    TraditionalCard(
                      doubleBorder: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('性別', '성별'),
                          const SizedBox(height: 10),
                          Row(children: [
                            _genderBtn('남', '乾', '하늘·양(陽)'),
                            const SizedBox(width: 10),
                            _genderBtn('여', '坤', '땅·음(陰)'),
                          ]),
                        ],
                      ),
                    ).animate(delay: 360.ms).fadeIn(),

                    const SizedBox(height: 12),

                    // ─── 시각 ───────────────────────────────────────
                    TraditionalCard(
                      doubleBorder: true,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: _fieldLabel('時辰', '태어난 시각')),
                            // 모름 체크박스
                            GestureDetector(
                              onTap: () => setState(() => _unknownHour = !_unknownHour),
                              child: Row(children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: _unknownHour
                                        ? AppColors.accent.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: _unknownHour
                                          ? AppColors.accent
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: _unknownHour
                                    ? const Icon(Icons.check,
                                        size: 13, color: AppColors.accent)
                                    : null,
                                ),
                                const SizedBox(width: 6),
                                Text('모름',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _unknownHour
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  )),
                              ]),
                            ),
                          ]),
                          if (!_unknownHour) ...[
                            const SizedBox(height: 10),
                            // 시 드롭다운 + 분 입력
                            Row(children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.divider),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      value: _birthHour,
                                      isExpanded: true,
                                      dropdownColor: AppColors.cardBg,
                                      style: const TextStyle(
                                        fontFamily: 'NotoSerifKR',
                                        color: AppColors.textPrimary,
                                        fontSize: 15, letterSpacing: 0.5,
                                      ),
                                      icon: const Icon(
                                          Icons.expand_more, color: AppColors.accent),
                                      items: List.generate(24, (i) => DropdownMenuItem(
                                        value: i,
                                        child: Text(_hourLabels[i]),
                                      )),
                                      onChanged: (v) => setState(() => _birthHour = v!),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 분 드롭다운
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _birthMinute,
                                    dropdownColor: AppColors.cardBg,
                                    style: const TextStyle(
                                      fontFamily: 'NotoSerifKR',
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                    ),
                                    icon: const Icon(Icons.expand_more,
                                        color: AppColors.accent, size: 18),
                                    items: [0, 15, 30, 45].map((m) =>
                                      DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          '${m.toString().padLeft(2,'0')}분',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ).toList(),
                                    onChanged: (v) =>
                                        setState(() => _birthMinute = v!),
                                  ),
                                ),
                              ),
                            ]),

                            const SizedBox(height: 10),

                            // ─── 원광식 진태양시 보정 ───────────────────
                            GestureDetector(
                              onTap: () => setState(() {
                                _useTrueSolarTime = !_useTrueSolarTime;
                                if (!_useTrueSolarTime) _birthCity = null;
                              }),
                              child: Row(children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: _useTrueSolarTime
                                        ? AppColors.accent.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: _useTrueSolarTime
                                          ? AppColors.accent : AppColors.divider,
                                    ),
                                  ),
                                  child: _useTrueSolarTime
                                    ? const Icon(Icons.check,
                                        size: 13, color: AppColors.accent)
                                    : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '원광식 진태양시 보정 (眞太陽時)',
                                  style: TextStyle(
                                    fontFamily: 'NotoSerifKR',
                                    fontSize: 12,
                                    color: _useTrueSolarTime
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ]),
                            ),

                            if (_useTrueSolarTime) ...[
                              const SizedBox(height: 8),
                              // 도시 선택 드롭다운
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _birthCity ?? '보정 안 함',
                                    isExpanded: true,
                                    dropdownColor: AppColors.cardBg,
                                    style: const TextStyle(
                                      fontFamily: 'NotoSerifKR',
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                    ),
                                    icon: const Icon(Icons.expand_more,
                                        color: AppColors.accent),
                                    items: TrueSolarTime.cityNames.map((c) =>
                                      DropdownMenuItem(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    ).toList(),
                                    onChanged: (v) => setState(() =>
                                        _birthCity = v == '보정 안 함' ? null : v),
                                  ),
                                ),
                              ),
                              // 보정 결과 미리보기
                              if (_birthCity != null) ...[
                                const SizedBox(height: 6),
                                Builder(builder: (_) {
                                  final lon = TrueSolarTime.longitude(_birthCity!);
                                  if (lon == null) return const SizedBox.shrink();
                                  final parsed = _parseBirthDate();
                                  final date = parsed ?? DateTime(1990, 1, 1);
                                  final label = TrueSolarTime.correctedTimeLabel(
                                    _birthHour, _birthMinute, date, lon);
                                  return Row(children: [
                                    const Icon(Icons.solar_power,
                                        size: 13, color: AppColors.accent),
                                    const SizedBox(width: 5),
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontFamily: 'NotoSerifKR',
                                        fontSize: 12,
                                        color: AppColors.accent,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ]);
                                }),
                              ],
                            ],
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              '시각을 모르시면 대략적인 운세만 분석됩니다',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ).animate(delay: 440.ms).fadeIn(),

                    const SizedBox(height: 28),

                    // ─── 분석 시작 버튼 ───────────────────────────
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accentDim,
                            AppColors.accent,
                            AppColors.accentDim,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.accentLight.withOpacity(0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2),
                            blurRadius: 12, spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _submit,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                '天 命 分 析 開 始',
                                style: TextStyle(
                                  fontFamily: 'NotoSerifKR',
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A0804),
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate(delay: 520.ms).fadeIn().slideY(begin: 0.2),

                    const SizedBox(height: 6),

                    Center(
                      child: Text(
                        '천명 분석 개시',
                        style: TextStyle(
                          fontFamily: 'NotoSerifKR',
                          fontSize: 11,
                          color: AppColors.accent.withOpacity(0.5),
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.lock_outline, size: 11,
                            color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '입력 정보는 기기 내에만 저장됩니다',
                          style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _fieldLabel(String hanja, String korean) => Row(children: [
    Text(
      hanja,
      style: const TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 13, fontWeight: FontWeight.bold,
        color: AppColors.accent, letterSpacing: 1,
      ),
    ),
    const SizedBox(width: 8),
    Text(
      korean,
      style: const TextStyle(
        fontSize: 11, color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  ]);

  /// 양력/음력 선택 버튼
  Widget _calTypeBtn(String label, String hanja, bool isLunarBtn) {
    final sel = _isLunar == isLunarBtn;
    return GestureDetector(
      onTap: () => setState(() {
        _isLunar = isLunarBtn;
        _isLeapMonth = false;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel
              ? AppColors.accent.withOpacity(0.13)
              : AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: sel ? AppColors.accent : AppColors.divider,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            hanja,
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 11,
              color: sel ? AppColors.accent : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 12, fontWeight: FontWeight.bold,
              color: sel ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _genderBtn(String value, String hanja, String sub) {
    final sel = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel
                ? AppColors.accent.withOpacity(0.12)
                : AppColors.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: sel ? AppColors.accent : AppColors.divider,
              width: sel ? 1.5 : 1,
            ),
            boxShadow: sel
                ? [BoxShadow(
                    color: AppColors.accent.withOpacity(0.15),
                    blurRadius: 8)]
                : null,
          ),
          child: Column(children: [
            Text(
              hanja,
              style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 24, fontWeight: FontWeight.bold,
                color: sel ? AppColors.accent : AppColors.textSecondary,
                shadows: sel
                    ? [Shadow(color: AppColors.accent.withOpacity(0.4),
                        blurRadius: 6)]
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value == '남' ? '남성' : '여성',
              style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 13, fontWeight: FontWeight.bold,
                color: sel ? AppColors.textPrimary : AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 10,
                color: sel
                    ? AppColors.accent.withOpacity(0.7)
                    : AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
        color: AppColors.textSecondary.withOpacity(0.4),
        fontFamily: 'NotoSerifKR', fontSize: 14),
    filled: true,
    fillColor: AppColors.surface.withOpacity(0.5),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: AppColors.hwaColor),
    ),
  );
}

/// 날짜 자동 포맷: 숫자 8자리 입력 → YYYY-MM-DD
/// 백스페이스로 대시(-) 삭제 시 앞 숫자까지 함께 제거
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldDigits = oldValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    var newDigits  = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 삭제(백스페이스) 중인데 숫자 수가 그대로 → 대시를 지운 것
    // 앞 숫자 하나도 함께 제거해야 실제로 지워지는 느낌
    final isDeleting = newValue.text.length < oldValue.text.length;
    if (isDeleting && newDigits.length == oldDigits.length && newDigits.isNotEmpty) {
      newDigits = newDigits.substring(0, newDigits.length - 1);
    }

    if (newDigits.length > 8) return oldValue;

    final buf = StringBuffer();
    for (int i = 0; i < newDigits.length; i++) {
      if (i == 4 || i == 6) buf.write('-');
      buf.write(newDigits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
