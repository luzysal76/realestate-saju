// Design System 2.0 — Deep Midnight × Antique Gold × Jade Green
// 명리학 신비 + 자산 관리 신뢰감

import 'package:flutter/material.dart';

class AppColors {
  // ─── Background ─────────────────────────────────────
  static const Color surface   = Color(0xFF0A0E17); // Deep Midnight
  static const Color cardBg    = Color(0xFF0D1220); // 카드 베이스
  static const Color cardBg2   = Color(0xFF111828); // 보조 카드
  static const Color divider   = Color(0xFF1E2535); // 구분선

  // ─── Primary — Antique Gold ──────────────────────────
  static const Color accent      = Color(0xFFD4AF37); // Antique Gold
  static const Color accentLight = Color(0xFFF0CC60); // 밝은 골드
  static const Color accentDim   = Color(0xFF9A7E20); // 어두운 골드
  static const Color primary     = surface;
  static const Color primaryLight = cardBg;

  // ─── Secondary — Jade Green ──────────────────────────
  static const Color jade      = Color(0xFF00A86B); // Jade Green
  static const Color jadeLight = Color(0xFF00CC85);
  static const Color jadeDim   = Color(0xFF007A50);
  static const Color teal      = jade;

  // ─── Text ────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFF8E8E93); // System Gray
  static const Color textMuted     = Color(0xFF5A5A6A);

  // ─── Glassmorphism ───────────────────────────────────
  static const Color glassBg     = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x1AFFFFFF); // 10% white

  // ─── 포인트 ───────────────────────────────────────────
  static const Color red = Color(0xFFE84020);

  // ─── 오행색 — 디자인 시스템 최적화 ─────────────────────
  static const Color mokColor  = jade;                 // 木 → Jade Green
  static const Color hwaColor  = Color(0xFFE84020);   // 火 적 — 남
  static const Color toColor   = accent;               // 土 → Antique Gold
  static const Color geumColor = Color(0xFFA8B8C8);   // 金 실버
  static const Color suColor   = Color(0xFF2288EE);   // 水 블루

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

  /// Antique Gold 그라디언트
  static LinearGradient get goldGradient => const LinearGradient(
    colors: [
      Color(0xFF8B6914),
      Color(0xFFD4AF37),
      Color(0xFFF0CC60),
      Color(0xFFD4AF37),
      Color(0xFF8B6914),
    ],
  );

  /// Gold → Jade 그라디언트 (긍정 운세)
  static LinearGradient get positiveGradient => const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFD4AF37), Color(0xFF00A86B)],
  );

  /// 메인 배경
  static LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0E17), Color(0xFF0D1220)],
  );

  /// 카드 글로우 그라디언트
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1525), Color(0xFF0A0E17)],
  );

  /// 헤더 그라디언트
  static LinearGradient get headerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1525), Color(0xFF0A0E17)],
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surface,
    fontFamily: 'NotoSerifKR',
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.jade,
      surface: AppColors.cardBg,
      onPrimary: Color(0xFF0A0E17),
      onSurface: AppColors.textPrimary,
    ),
    textTheme: const TextTheme(
      // H1: 24pt Bold
      displayLarge: TextStyle(
        fontSize: 24, fontWeight: FontWeight.bold,
        color: AppColors.textPrimary, letterSpacing: 0.5, height: 1.4),
      // H2: 18pt Semi-bold
      displayMedium: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.3, height: 1.4),
      // Body1: 16pt Regular
      bodyLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.normal,
        color: AppColors.textPrimary, height: 1.6),
      // Body2: 14pt Regular
      bodyMedium: TextStyle(
        fontSize: 14, fontWeight: FontWeight.normal,
        color: AppColors.textSecondary, height: 1.6),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: 0.3),
      iconTheme: IconThemeData(color: AppColors.accent),
      shape: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
    ),
    // Primary Button: Gold bg, Dark text
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Color(0xFF0A0E17),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    // Outline Button: Secondary Button
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.glassBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.glassBorder, width: 1)),
    ),
    tabBarTheme: const TabBarTheme(
      indicatorColor: AppColors.accent,
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.glassBorder)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
  );

  static ThemeData get dark => light;
}
