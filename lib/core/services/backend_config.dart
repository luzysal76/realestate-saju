/// Firebase 프로젝트 설정
/// 부동산사주앱 전용 Firebase 프로젝트로 분리 권장
/// 현재는 changemindsupport-center 프로젝트 사용
class BackendConfig {
  static const String apiKey = 'AIzaSyDm-fox5wDa8GLJ5su4HHQin_CKvp74djk';
  static const String projectId = 'changemindsupport-center';
  static const String storageBucket = 'changemindsupport-center.firebasestorage.app';

  // Firebase Auth REST endpoint
  static const String authBaseUrl =
      'https://identitytoolkit.googleapis.com/v1';
  // Firestore REST endpoint
  static const String firestoreBaseUrl =
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  // Firestore 컬렉션
  static const String usersCollection = 'saju_users';
  static const String profilesCollection = 'profiles';
  static const String backupsCollection = 'backups';
}
