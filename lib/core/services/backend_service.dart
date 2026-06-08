import 'package:hive_flutter/hive_flutter.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import '../../shared/models/saju_profile.dart';

/// 백엔드 통합 서비스 — Auth + Firestore + Hive 오케스트레이션
class BackendService {
  static BackendService? _instance;
  static BackendService get instance => _instance ??= BackendService._();
  BackendService._();

  final auth = AuthService.instance;
  final firestore = FirestoreService.instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// 앱 시작 시 초기화
  Future<void> initialize() async {
    if (_initialized) return;
    // 저장된 토큰 복원 시도
    await auth.restore();

    // 로그인 상태가 아니면 익명 로그인
    if (!auth.isSignedIn) {
      await auth.signInAnonymously();
    }

    _initialized = true;
  }

  /// 현재 상태 요약
  BackendStatus get status => BackendStatus(
    isSignedIn: auth.isSignedIn,
    isAnonymous: auth.isAnonymous,
    email: auth.email,
    uid: auth.uid,
  );

  /// 클라우드에 프로필 백업
  Future<SyncResult> backup() async {
    if (!auth.isSignedIn) {
      final res = await auth.signInAnonymously();
      if (!res.success) return SyncResult.error('로그인 실패');
    }

    final box = Hive.box<SajuProfile>('profiles');
    final profiles = box.values.toList();
    if (profiles.isEmpty) return SyncResult.error('백업할 프로필이 없습니다');

    return firestore.backupProfiles(profiles);
  }

  /// 클라우드에서 프로필 복원
  Future<RestoreResult> restore() async {
    if (!auth.isSignedIn) return RestoreResult.error('로그인이 필요합니다');

    final result = await firestore.restoreProfiles();
    if (!result.success) return result;
    if (result.profiles.isEmpty) return RestoreResult.error('백업된 프로필이 없습니다');

    // Hive에 병합 (중복 방지: name+birthDate 기준)
    final box = Hive.box<SajuProfile>('profiles');
    int added = 0;
    for (final p in result.profiles) {
      final exists = box.values.any(
        (existing) => existing.name == p.name &&
            existing.birthDate.year == p.birthDate.year &&
            existing.birthDate.month == p.birthDate.month &&
            existing.birthDate.day == p.birthDate.day,
      );
      if (!exists) {
        await box.add(p);
        added++;
      }
    }

    return RestoreResult.success(
      result.profiles..retainWhere((_) => added > 0),
    );
  }

  /// 이메일 회원가입 + 기존 익명 데이터 연결
  Future<AuthResult> signUpWithEmail(String email, String password) async {
    final result = await auth.signUpWithEmail(email, password);
    if (result.success) {
      // 이전 익명 데이터 바로 백업
      await backup();
    }
    return result;
  }

  /// 이메일 로그인
  Future<AuthResult> signInWithEmail(String email, String password) async {
    return auth.signInWithEmail(email, password);
  }

  /// 로그아웃
  Future<void> signOut() async {
    await auth.signOut();
    // 익명으로 다시 자동 로그인
    await auth.signInAnonymously();
  }
}

class BackendStatus {
  final bool isSignedIn;
  final bool isAnonymous;
  final String? email;
  final String? uid;

  const BackendStatus({
    required this.isSignedIn,
    required this.isAnonymous,
    this.email,
    this.uid,
  });

  String get displayName => isAnonymous ? '비로그인 (임시)' : email ?? '로그인됨';
  String get syncLabel => isAnonymous ? '로그인 후 백업 가능' : '클라우드 동기화 사용 중';
  bool get canBackup => isSignedIn;
}
