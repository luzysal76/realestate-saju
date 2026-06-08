import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/services/backend_service.dart';
import '../../core/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _backend = BackendService.instance;
  bool _isSyncing = false;
  bool _isAuthLoading = false;
  String? _message;
  bool _messageIsError = false;

  @override
  Widget build(BuildContext context) {
    final status = _backend.status;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('設 定',
            style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 18, color: Colors.white, letterSpacing: 4)),
        ),
      ),
      body: Stack(children: [
        // 배경 패턴
        Positioned.fill(
          child: CustomPaint(
            painter: const DancheongPatternPainter(opacity: 0.018)),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 32),
          children: [
            _buildAccountCard(status),
            const SizedBox(height: 10),
            _buildSyncCard(status),
            const SizedBox(height: 10),
            _buildAppInfoCard(),
            const SizedBox(height: 16),

            // 메시지
            if (_message != null)
              TraditionalCard(
                borderColor: _messageIsError
                    ? AppColors.hwaColor.withOpacity(0.5)
                    : AppColors.mokColor.withOpacity(0.5),
                child: Row(children: [
                  Text(_messageIsError ? '⚠️' : '✅',
                    style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_message!, style: TextStyle(
                    fontSize: 12,
                    color: _messageIsError
                        ? AppColors.hwaColor
                        : AppColors.mokColor,
                    height: 1.4,
                  ))),
                ]),
              ).animate().fadeIn(),
          ],
        ),
      ]),
    );
  }

  // ─── 계정 카드 ────────────────────────────────────

  Widget _buildAccountCard(BackendStatus status) {
    return TraditionalCard(
      doubleBorder: true,
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // 아바타
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.isAnonymous
                    ? AppColors.divider
                    : AppColors.accent.withOpacity(0.15),
                border: Border.all(
                  color: status.isAnonymous
                      ? AppColors.divider
                      : AppColors.accent.withOpacity(0.4),
                ),
              ),
              child: Center(child: Text(
                status.isAnonymous ? '👤' : '☁️',
                style: const TextStyle(fontSize: 20),
              )),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                status.isAnonymous ? '비로그인 상태' : status.email ?? '로그인됨',
                style: const TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 14,
                  fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.isAnonymous
                    ? '프로필이 이 기기에만 저장됩니다'
                    : '클라우드 백업 활성화됨',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ])),
          ]),
        ),

        Container(height: 0.5, color: AppColors.divider),

        if (status.isAnonymous) ...[
          _tile(icon: '📧', title: '이메일로 계정 만들기',
            sub: '프로필을 클라우드에 안전하게 백업',
            onTap: () => _showAuthDialog(isSignUp: true)),
          Container(height: 0.5, color: AppColors.divider.withOpacity(0.5)),
          _tile(icon: '🔑', title: '기존 계정으로 로그인',
            sub: '다른 기기의 데이터 불러오기',
            onTap: () => _showAuthDialog(isSignUp: false)),
        ] else ...[
          _tile(icon: '🚪', title: '로그아웃',
            sub: '로컬 데이터는 유지됩니다',
            onTap: _signOut, titleColor: AppColors.hwaColor),
        ],
      ]),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  // ─── 동기화 카드 ──────────────────────────────────

  Widget _buildSyncCard(BackendStatus status) {
    return TraditionalCard(
      doubleBorder: true,
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            const KoreanSectionTitle(title: '클라우드 동기화 (雲)', showDivider: false),
          ]),
        ),
        Container(height: 0.5, color: AppColors.divider),
        _tile(
          icon: '⬆️', title: '지금 백업하기',
          sub: status.isAnonymous
              ? '로그인 후 사용 가능'
              : '현재 기기의 프로필을 클라우드에 저장',
          onTap: status.isAnonymous ? null : _backup,
          trailing: _isSyncing
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
              : null,
        ),
        Container(height: 0.5, color: AppColors.divider.withOpacity(0.5)),
        _tile(
          icon: '⬇️', title: '백업 복원하기',
          sub: status.isAnonymous
              ? '로그인 후 사용 가능'
              : '클라우드에서 프로필 불러오기',
          onTap: status.isAnonymous ? null : _restore,
        ),
      ]),
    ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 앱 정보 카드 ─────────────────────────────────

  Widget _buildAppInfoCard() {
    return TraditionalCard(
      doubleBorder: true,
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            const KoreanSectionTitle(title: '앱 정보 (情報)', showDivider: false),
          ]),
        ),
        Container(height: 0.5, color: AppColors.divider),
        _tile(icon: '📱', title: '버전', sub: 'v1.0.0'),
        Container(height: 0.5, color: AppColors.divider.withOpacity(0.5)),
        _tile(
          icon: '⭐', title: '앱 평가하기', sub: 'Play Store에서 평가',
          onTap: () => launchUrl(
            Uri.parse('https://play.google.com/store/apps/details?id=com.changemindsupport.realestate_saju'),
            mode: LaunchMode.externalApplication,
          ),
        ),
        Container(height: 0.5, color: AppColors.divider.withOpacity(0.5)),
        _tile(
          icon: '🔒', title: '개인정보처리방침',
          sub: 'changemindsupport.surge.sh/privacy.html',
          onTap: () => launchUrl(
            Uri.parse('https://changemindsupport.surge.sh/privacy.html'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ]),
    ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1);
  }

  // ─── 인증 다이얼로그 ──────────────────────────────

  void _showAuthDialog({required bool isSignUp}) {
    final emailCtrl = TextEditingController();
    final pwCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ShaderMask(
              shaderCallback: (b) => AppColors.goldGradient.createShader(b),
              child: Text(
                isSignUp ? '계정 만들기' : '로그인',
                style: const TextStyle(
                  fontFamily: 'NotoSerifKR', fontSize: 18,
                  fontWeight: FontWeight.bold, color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const TraditionalDivider(indent: 0),
            const SizedBox(height: 14),
            Form(
              key: formKey,
              child: Column(children: [
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontFamily: 'NotoSerifKR', fontSize: 14),
                  decoration: _inputDeco('이메일'),
                  validator: (v) => (v?.contains('@') == true) ? null : '올바른 이메일을 입력하세요',
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: pwCtrl,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.textPrimary,
                    fontFamily: 'NotoSerifKR', fontSize: 14),
                  decoration: _inputDeco('비밀번호 (6자 이상)'),
                  validator: (v) => (v != null && v.length >= 6) ? null : '6자 이상 입력하세요',
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Center(child: Text('취소',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () async {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(ctx);
                  await _authenticate(
                    email: emailCtrl.text.trim(),
                    password: pwCtrl.text,
                    isSignUp: isSignUp,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(child: Text(
                    isSignUp ? '가입하기' : '로그인',
                    style: const TextStyle(
                      fontFamily: 'NotoSerifKR',
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A0804),
                    ),
                  )),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    filled: true,
    fillColor: AppColors.surface.withOpacity(0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      borderSide: const BorderSide(color: AppColors.accent),
    ),
  );

  // ─── 액션 ─────────────────────────────────────────

  Future<void> _authenticate({
    required String email, required String password, required bool isSignUp,
  }) async {
    setState(() { _isAuthLoading = true; _message = null; });
    try {
      final result = isSignUp
          ? await _backend.signUpWithEmail(email, password)
          : await _backend.signInWithEmail(email, password);
      if (mounted) setState(() {
        _isAuthLoading = false;
        _message = result.success
            ? isSignUp ? '계정이 생성되고 자동 백업됐습니다!' : '로그인 성공!'
            : result.error;
        _messageIsError = !result.success;
      });
    } catch (e) {
      if (mounted) setState(() {
        _isAuthLoading = false;
        _message = '오류: $e';
        _messageIsError = true;
      });
    }
  }

  Future<void> _backup() async {
    setState(() { _isSyncing = true; _message = null; });
    final result = await _backend.backup();
    if (mounted) setState(() {
      _isSyncing = false;
      _message = result.success ? '${result.count}개 프로필 백업 완료!' : result.error;
      _messageIsError = !result.success;
    });
  }

  Future<void> _restore() async {
    setState(() { _isSyncing = true; _message = null; });
    final result = await _backend.restore();
    if (mounted) setState(() {
      _isSyncing = false;
      _message = result.success
          ? result.profiles.isEmpty ? '백업된 프로필이 없습니다' : '${result.profiles.length}개 복원 완료!'
          : result.error;
      _messageIsError = !result.success && result.profiles.isEmpty;
    });
  }

  Future<void> _signOut() async {
    await _backend.signOut();
    if (mounted) setState(() {
      _message = '로그아웃됐습니다. 로컬 데이터는 유지됩니다.';
      _messageIsError = false;
    });
  }

  // ─── 타일 위젯 ────────────────────────────────────

  Widget _tile({
    required String icon, required String title,
    String? sub, VoidCallback? onTap,
    Color? titleColor, Widget? trailing,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 13, fontWeight: FontWeight.w500,
              color: !enabled ? AppColors.textMuted
                  : titleColor ?? AppColors.textPrimary,
              letterSpacing: 0.3,
            )),
            if (sub != null) ...[
              const SizedBox(height: 1),
              Text(sub, style: TextStyle(
                fontSize: 10,
                color: !enabled
                    ? AppColors.textMuted.withOpacity(0.5)
                    : AppColors.textSecondary,
              )),
            ],
          ])),
          trailing ?? (enabled
              ? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16)
              : const SizedBox()),
        ]),
      ),
    );
  }
}
