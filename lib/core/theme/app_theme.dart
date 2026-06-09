import 'package:flutter/material.dart';

/// 다크 럭셔리 테마 — "Real Estate Saju 2.0"
class AppColors {
  // ─── 배경계 (딥 다크) ─────────────────────────────────
  static const Color surface   = Color(0xFF0D0D0D);   // 최심 다크
  static const Color cardBg    = Color(0xFF1A1A1A);   // 카드 다크
  static const Color cardBg2   = Color(0xFF242424);   // 보조 카드
  static const Color divider   = Color(0xFF2E2E2E);   // 구분선

  // ─── 주 색채 (골드 계열 유지) ─────────────────────────
  static const Color primary      = Color(0xFF0D0D0D);
  static const Color primaryLight = Color(0xFF1A1A1A);
  static const Color accent       = Color(0xFFC8921A); // 전통 金황 유지
  static const Color accentLight  = Color(0xFFE0A830); // 밝은 금
  static const Color accentDim    = Color(0xFF9A6E10); // 어두운 금

  // ─── 텍스트 (웜 화이트 계열) ──────────────────────────
  static const Color textPrimary   = Color(0xFFF0E8D0); // 웜 오프화이트
  static const Color textSecondary = Color(0xFF9A8A6A); // 웜 미디엄 그레이
  static const Color textMuted     = Color(0xFF5A4E40); // 어두운 웜 그레이

  // ─── 포인트 ───────────────────────────────────────────
  static const Color red  = Color(0xFFE04030);
  static const Color teal = Color(0xFF30AA70);
  static const Color jade = Color(0xFF45BA60);

  // ─── 오행색 — 다크 배경 최적화 (선명하게) ───────────────
  static const Color mokColor  = Color(0xFF45C070); // 木 청록 — 동
  static const Color hwaColor  = Color(0xFFE84020); // 火 적 — 남
  static const Color toColor   = Color(0xFFD49020); // 土 황 — 중
  static const Color geumColor = Color(0xFFA8B8C8); // 金 은 — 서
  static const Color suColor   = Color(0xFF2288EE); // 水 청 — 북

  static Color getOehaengColor(String oe) {
    switch (oe) {
      case '목': return mokColor;
      case '화': return hwaColor;
      case '토': return toColor;
      case '금': return geumColor;
      case '수': return suColor;
      default:   return accent;
    }
  }

  // ─── 그라디언트 ───────────────────────────────────────

  /// 메인 배경 — 딥 다크
  static LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D0D0D), Color(0xFF141414)],
  );

  /// 카드 그라디언트
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF202020)],
  );

  /// 금빛 그라디언트 — 전통 금박
  static LinearGradient get goldGradient => const LinearGradient(
    colors: [
      Color(0xFF7A5810),
      Color(0xFFC8921A),
      Color(0xFFE8C060),
      Color(0xFFC8921A),
      Color(0xFF7A5810),
    ],
  );

  /// 헤더 그라디언트
  static LinearGradient get headerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.teal,
      surface: AppColors.cardBg,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 32,
        fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 2),
      displayMedium: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 26,
        fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1.5),
      headlineMedium: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 20,
        fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 1),
      bodyLarge: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 16,
        color: AppColors.textPrimary, height: 1.7),
      bodyMedium: TextStyle(
        fontSize: 14, color: AppColors.textSecondary, height: 1.6),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSerifKR', fontSize: 18, fontWeight: FontWeight.bold,
        color: AppColors.textPrimary, letterSpacing: 1.5),
      iconTheme: IconThemeData(color: AppColors.accent),
      shape: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.accentDim, width: 1)),
        textStyle: const TextStyle(
          fontFamily: 'NotoSerifKR', fontSize: 16,
          fontWeight: FontWeight.bold, letterSpacing: 1),
        elevation: 2,
        shadowColor: Colors.black54,
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.divider, width: 1)),
    ),
    tabBarTheme: const TabBarTheme(
      indicatorColor: AppColors.accent,
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(
        fontFamily: 'NotoSerifKR', fontWeight: FontWeight.bold,
        fontSize: 13, letterSpacing: 1),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.accent,
      textColor: AppColors.textPrimary,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider, thickness: 1),
    dialogTheme: const DialogTheme(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: AppColors.divider)),
    ),
  );

  static ThemeData get dark => light;
}
