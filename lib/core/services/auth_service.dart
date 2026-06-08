import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_config.dart';

/// Firebase Auth REST API 기반 인증 서비스
/// google-services.json 없이 동작 (REST API 직접 호출)
class AuthService {
  static const _tokenKey = 'firebase_id_token';
  static const _refreshKey = 'firebase_refresh_token';
  static const _uidKey = 'firebase_uid';
  static const _emailKey = 'user_email';

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  String? _idToken;
  String? _refreshToken;
  String? _uid;
  String? _email;
  bool _isAnonymous = true;

  String? get uid => _uid;
  String? get email => _email;
  String? get idToken => _idToken;
  bool get isSignedIn => _uid != null;
  bool get isAnonymous => _isAnonymous;
  bool get isLinked => !_isAnonymous && _email != null;

  /// 앱 시작 시 저장된 토큰 복원
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _idToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshKey);
    _uid = prefs.getString(_uidKey);
    _email = prefs.getString(_emailKey);
    _isAnonymous = _email == null;

    // 토큰이 있으면 갱신 시도
    if (_refreshToken != null) {
      await _refreshIdToken();
    }
  }

  /// 익명 로그인 (앱 첫 실행 시 자동 호출)
  Future<AuthResult> signInAnonymously() async {
    try {
      final res = await http.post(
        Uri.parse('${BackendConfig.authBaseUrl}/accounts:signUp?key=${BackendConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'returnSecureToken': true}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveAuth(data, isAnonymous: true);
        return AuthResult.success(_uid!);
      }
      return AuthResult.error(data['error']?['message'] ?? '익명 로그인 실패');
    } catch (e) {
      return AuthResult.error('네트워크 오류: $e');
    }
  }

  /// 이메일+비밀번호 회원가입
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${BackendConfig.authBaseUrl}/accounts:signUp?key=${BackendConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveAuth(data, isAnonymous: false, email: email);
        return AuthResult.success(_uid!);
      }
      return AuthResult.error(_parseError(data));
    } catch (e) {
      return AuthResult.error('네트워크 오류: $e');
    }
  }

  /// 이메일+비밀번호 로그인
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${BackendConfig.authBaseUrl}/accounts:signInWithPassword?key=${BackendConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        await _saveAuth(data, isAnonymous: false, email: email);
        return AuthResult.success(_uid!);
      }
      return AuthResult.error(_parseError(data));
    } catch (e) {
      return AuthResult.error('네트워크 오류: $e');
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<bool> sendPasswordReset(String email) async {
    try {
      final res = await http.post(
        Uri.parse('${BackendConfig.authBaseUrl}/accounts:sendOobCode?key=${BackendConfig.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    _idToken = null;
    _refreshToken = null;
    _uid = null;
    _email = null;
    _isAnonymous = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_emailKey);
  }

  /// 토큰 갱신
  Future<void> _refreshIdToken() async {
    if (_refreshToken == null) return;
    try {
      final res = await http.post(
        Uri.parse('https://securetoken.googleapis.com/v1/token?key=${BackendConfig.apiKey}'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'grant_type=refresh_token&refresh_token=$_refreshToken',
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _idToken = data['id_token'];
        _refreshToken = data['refresh_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _idToken!);
        await prefs.setString(_refreshKey, _refreshToken!);
      }
    } catch (_) {}
  }

  Future<void> _saveAuth(Map data, {required bool isAnonymous, String? email}) async {
    _idToken = data['idToken'];
    _refreshToken = data['refreshToken'];
    _uid = data['localId'];
    _email = email;
    _isAnonymous = isAnonymous;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _idToken!);
    await prefs.setString(_refreshKey, _refreshToken!);
    await prefs.setString(_uidKey, _uid!);
    if (email != null) await prefs.setString(_emailKey, email);
  }

  String _parseError(Map data) {
    final code = data['error']?['message'] ?? '';
    const messages = {
      'EMAIL_EXISTS': '이미 사용 중인 이메일입니다',
      'INVALID_EMAIL': '올바른 이메일 형식이 아닙니다',
      'WEAK_PASSWORD': '비밀번호가 너무 짧습니다 (6자 이상)',
      'EMAIL_NOT_FOUND': '등록되지 않은 이메일입니다',
      'INVALID_PASSWORD': '비밀번호가 틀렸습니다',
      'USER_DISABLED': '비활성화된 계정입니다',
      'INVALID_LOGIN_CREDENTIALS': '이메일 또는 비밀번호가 틀렸습니다',
    };
    return messages[code] ?? '오류가 발생했습니다 ($code)';
  }
}

class AuthResult {
  final bool success;
  final String? uid;
  final String? error;

  const AuthResult._({required this.success, this.uid, this.error});
  factory AuthResult.success(String uid) => AuthResult._(success: true, uid: uid);
  factory AuthResult.error(String msg) => AuthResult._(success: false, error: msg);
}
