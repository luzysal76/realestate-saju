import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/services/backend_service.dart';
import 'features/splash/splash_screen.dart';
import 'shared/models/saju_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 화면 세로 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 상태바 투명 처리
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(SajuProfileAdapter());
  await Hive.openBox<SajuProfile>('profiles');

  // 백엔드 초기화 (익명 자동 로그인 + 토큰 복원)
  // 네트워크 없어도 앱은 정상 동작 (로컬 모드)
  BackendService.instance.initialize().catchError((_) {});

  runApp(const RealEstateLuckApp());
}

class RealEstateLuckApp extends StatelessWidget {
  const RealEstateLuckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Estate Luck in Saju',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
