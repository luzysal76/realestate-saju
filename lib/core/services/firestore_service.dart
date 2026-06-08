import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';
import 'auth_service.dart';
import '../../shared/models/saju_profile.dart';

/// Firestore REST API 기반 클라우드 동기화 서비스
class FirestoreService {
  static FirestoreService? _instance;
  static FirestoreService get instance => _instance ??= FirestoreService._();
  FirestoreService._();

  final _auth = AuthService.instance;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_auth.idToken != null) 'Authorization': 'Bearer ${_auth.idToken}',
  };

  // ─── 프로필 백업 ──────────────────────────────────

  /// 로컬 프로필 목록을 Firestore에 저장
  Future<SyncResult> backupProfiles(List<SajuProfile> profiles) async {
    if (!_auth.isSignedIn) return SyncResult.error('로그인이 필요합니다');

    try {
      final uid = _auth.uid!;
      int success = 0;

      for (final p in profiles) {
        final docId = _profileDocId(p);
        final url = '${BackendConfig.firestoreBaseUrl}/${BackendConfig.usersCollection}/$uid/${BackendConfig.profilesCollection}/$docId';
        final body = _profileToFirestore(p);

        final res = await http.patch(
          Uri.parse('$url?updateMask.fieldPaths=name&updateMask.fieldPaths=birthDate&updateMask.fieldPaths=birthHour&updateMask.fieldPaths=gender&updateMask.fieldPaths=createdAt&updateMask.fieldPaths=updatedAt'),
          headers: _headers,
          body: jsonEncode(body),
        );

        if (res.statusCode == 200) success++;
      }

      // 마지막 백업 시간 저장
      await _updateLastSync(uid);
      return SyncResult.success(count: success);
    } catch (e) {
      return SyncResult.error('백업 실패: $e');
    }
  }

  /// Firestore에서 프로필 목록 복원
  Future<RestoreResult> restoreProfiles() async {
    if (!_auth.isSignedIn) return RestoreResult.error('로그인이 필요합니다');

    try {
      final uid = _auth.uid!;
      final url = '${BackendConfig.firestoreBaseUrl}/${BackendConfig.usersCollection}/$uid/${BackendConfig.profilesCollection}';
      final res = await http.get(Uri.parse(url), headers: _headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final docs = data['documents'] as List<dynamic>? ?? [];
        final profiles = docs
            .map((d) => _firestoreToProfile(d))
            .whereType<SajuProfile>()
            .toList();
        return RestoreResult.success(profiles);
      } else if (res.statusCode == 404) {
        return RestoreResult.success([]);
      }
      return RestoreResult.error('복원 실패: ${res.statusCode}');
    } catch (e) {
      return RestoreResult.error('복원 실패: $e');
    }
  }

  /// 사용자 백업 메타데이터 조회 (마지막 백업 시간 등)
  Future<Map<String, dynamic>?> getUserMeta() async {
    if (!_auth.isSignedIn) return null;
    try {
      final uid = _auth.uid!;
      final url = '${BackendConfig.firestoreBaseUrl}/${BackendConfig.usersCollection}/$uid';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return _fromFirestoreFields(data['fields'] ?? {});
      }
    } catch (_) {}
    return null;
  }

  Future<void> _updateLastSync(String uid) async {
    try {
      final url = '${BackendConfig.firestoreBaseUrl}/${BackendConfig.usersCollection}/$uid';
      await http.patch(
        Uri.parse('$url?updateMask.fieldPaths=lastSync&updateMask.fieldPaths=email&updateMask.fieldPaths=uid'),
        headers: _headers,
        body: jsonEncode({
          'fields': {
            'lastSync': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
            'uid': {'stringValue': uid},
            'email': {'stringValue': _auth.email ?? '익명'},
          },
        }),
      );
    } catch (_) {}
  }

  // ─── 사주 분석 결과 저장 ───────────────────────────

  /// 분석 결과를 클라우드에 저장 (나중에 공유/PDF용)
  Future<bool> saveAnalysisResult({
    required String profileId,
    required Map<String, dynamic> analysisData,
  }) async {
    if (!_auth.isSignedIn) return false;
    try {
      final uid = _auth.uid!;
      final url = '${BackendConfig.firestoreBaseUrl}/${BackendConfig.usersCollection}/$uid/${BackendConfig.backupsCollection}/$profileId';
      final res = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(_mapToFirestoreFields(analysisData)),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── 변환 헬퍼 ────────────────────────────────────

  String _profileDocId(SajuProfile p) {
    final ts = p.createdAt.millisecondsSinceEpoch;
    return '${p.name}_$ts'.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_-]'), '_');
  }

  Map<String, dynamic> _profileToFirestore(SajuProfile p) {
    return {
      'fields': {
        'name': {'stringValue': p.name},
        'birthDate': {'timestampValue': p.birthDate.toUtc().toIso8601String()},
        'birthHour': {'integerValue': p.birthHour.toString()},
        'gender': {'stringValue': p.gender},
        'createdAt': {'timestampValue': p.createdAt.toUtc().toIso8601String()},
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      },
    };
  }

  SajuProfile? _firestoreToProfile(Map<String, dynamic> doc) {
    try {
      final fields = doc['fields'] as Map<String, dynamic>? ?? {};
      return SajuProfile(
        name: fields['name']?['stringValue'] ?? '',
        birthDate: DateTime.parse(fields['birthDate']?['timestampValue'] ?? '2000-01-01'),
        birthHour: int.tryParse(fields['birthHour']?['integerValue'] ?? '12') ?? 12,
        gender: fields['gender']?['stringValue'] ?? '남',
        createdAt: DateTime.parse(fields['createdAt']?['timestampValue'] ?? '2000-01-01'),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _mapToFirestoreFields(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};
    data.forEach((k, v) {
      if (v is String) fields[k] = {'stringValue': v};
      else if (v is int) fields[k] = {'integerValue': v.toString()};
      else if (v is double) fields[k] = {'doubleValue': v};
      else if (v is bool) fields[k] = {'booleanValue': v};
    });
    return {'fields': fields};
  }

  Map<String, dynamic> _fromFirestoreFields(Map<String, dynamic> fields) {
    final result = <String, dynamic>{};
    fields.forEach((k, v) {
      if (v is Map) {
        if (v.containsKey('stringValue')) result[k] = v['stringValue'];
        else if (v.containsKey('integerValue')) result[k] = int.tryParse(v['integerValue']);
        else if (v.containsKey('timestampValue')) result[k] = v['timestampValue'];
        else if (v.containsKey('booleanValue')) result[k] = v['booleanValue'];
      }
    });
    return result;
  }
}

// ─── 결과 타입 ────────────────────────────────────────

class SyncResult {
  final bool success;
  final int count;
  final String? error;
  const SyncResult._({required this.success, this.count = 0, this.error});
  factory SyncResult.success({int count = 0}) => SyncResult._(success: true, count: count);
  factory SyncResult.error(String msg) => SyncResult._(success: false, error: msg);
}

class RestoreResult {
  final bool success;
  final List<SajuProfile> profiles;
  final String? error;
  const RestoreResult._({required this.success, this.profiles = const [], this.error});
  factory RestoreResult.success(List<SajuProfile> p) => RestoreResult._(success: true, profiles: p);
  factory RestoreResult.error(String msg) => RestoreResult._(success: false, error: msg);
}
