import 'package:flutter/material.dart';

/// 따뜻한 크림/베이지 라이트 테마 — Change Mind 앱 스타일
class AppColors {
  // ─── 배경계 (크림/베이지 계열) ────────────────────────
  static const Color surface   = Color(0xFFF7F2EA);  // 따뜻한 크림
  static const Color cardBg    = Color(0xFFFFFFFF);  // 흰 카드
  static const Color cardBg2   = Color(0xFFF0EAE0);  // 연한 크림 카드
  static const Color divider   = Color(0xFFE5D9C8);  // 따뜻한 베이지 구분선

  // ─── 주 색채 (갈색/금색 계열) ─────────────────────────
  static const Color primary      = Color(0xFF2C1A0E); // 짙은 따뜻한 갈색 (배경용)
  static const Color primaryLight = Color(0xFFF0EAE0); // 연한 크림
  static const Color accent       = Color(0xFFC8921A); // 전통 금(黃金) 유지
  static const Color accentLight  = Color(0xFFE0A830); // 밝은 금
  static const Color accentDim    = Color(0xFF9A6E10); // 어두운 금

  // ─── 텍스트 (갈색 계열) ──────────────────────────────
  static const Color textPrimary   = Color(0xFF2C1A0E); // 짙은 갈색
  static const Color textSecondary = Color(0xFF7A6248); // 중간 갈색
  static const Color textMuted     = Color(0xFFA89882); // 밝은 갈색

  // ─── 포인트 컬러 ──────────────────────────────────────
  static const Color red   = Color(0xFF9B2010); // 전통 적(赤)
  static const Color teal  = Color(0xFF2E7A5A); // 밝은 초록
  static const Color jade  = Color(0xFF3D8A4A); // 비취 녹(綠)

  // ─── 오행색 (五行色) — 오방색 기반, 약간 더 선명하게 ────
  // 목(木) 청색(靑) — 동쪽, 봄, 나무
  static const Color mokColor  = Color(0xFF3D8A5A);
  // 화(火) 적색(赤) — 남쪽, 여름, 불
  static const Color hwaColor  = Color(0xFFCC3311);
  // 토(土) 황색(黃) — 중앙, 환절기, 흙
  static const Color toColor   = Color(0xFFC88810);
  // 금(金) 백색(白) — 서쪽, 가을, 쇠
  static const Color geumColor = Color(0xFF9AA0A8);
  // 수(水) 흑색(黑) — 북쪽, 겨울, 물
  static const Color suColor   = Color(0xFF2266AA);

  static Color getOehaengColor(String oe) {
    switch (oe) {
      case '목': return mokColor;
      case '화': return hwaColor;
      case '토': return toColor;
      case '금': return geumColor;
      case '수': return suColor;
      default: return accent;
    }
  }

  // ─── 그라디언트 ───────────────────────────────────────

  /// 배경 그라디언트 — 따뜻한 크림 톤
  static LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F2EA), Color(0xFFEDE5D5)],
  );

  /// 카드 그라디언트 — 흰색 → 연한 크림
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5EFE5)],
  );

  /// 금빛 그라디언트 — 전통 금박 효과 (기존 유지)
  static LinearGradient get goldGradient => const LinearGradient(
    colors: [
      Color(0xFF7A5810),
      Color(0xFFC8921A),
      Color(0xFFE8C060),
      Color(0xFFC8921A),
      Color(0xFF7A5810),
    ],
  );

  /// 헤더 그라디언트 — 따뜻한 베이지
  static LinearGradient get headerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF0E8D5), Color(0xFFE8DCC5)],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      secondary: AppColors.teal,
      surface: AppColors.cardBg,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 32,
        fontWeight: FontWeight.bold, color: AppColors.textPrimary,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 26,
        fontWeight: FontWeight.bold, color: AppColors.textPrimary,
        letterSpacing: 1.5,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 20,
        fontWeight: FontWeight.bold, color: AppColors.textPrimary,
        letterSpacing: 1,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 16,
        color: AppColors.textPrimary, height: 1.7,
      ),
      bodyMedium: TextStyle(
        fontSize: 14, color: AppColors.textSecondary, height: 1.6,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 18, fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 1.5,
      ),
      iconTheme: const IconThemeData(color: AppColors.accent),
      shape: const Border(
        bottom: BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.accentDim, width: 1),
        ),
        textStyle: const TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 16, fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        elevation: 2,
        shadowColor: Colors.black26,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    tabBarTheme: const TabBarTheme(
      indicatorColor: AppColors.accent,
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontFamily: 'NotoSerifKR', fontWeight: FontWeight.bold,
        fontSize: 13, letterSpacing: 1,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.accent,
      textColor: AppColors.textPrimary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
    ),
  );

  /// main.dart 호환성 유지 — dark getter는 light 테마를 반환
  static ThemeData get dark => light;
}
