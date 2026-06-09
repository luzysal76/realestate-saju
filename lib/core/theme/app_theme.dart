// Design System 2.0 — Brand Guide Compliant
// Mission: 명리학 통찰 × 현대적 부동산 자산 관리
// Keywords: Mystic · Trust · Expertise · Premium

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ─── Background ─────────────────────────────────────
  static const Color surface   = Color(0xFF0A0E17); // Midnight Navy
  static const Color cardBg    = Color(0xFF0D1220); // 카드 베이스
  static const Color cardBg2   = Color(0xFF111828); // 보조 카드
  static const Color divider   = Color(0xFF1E2535); // 구분선

  // ─── Primary — Antique Gold (브랜드 로고 / 핵심 버튼) ──
  static const Color accent      = Color(0xFFD4AF37); // Antique Gold
  static const Color accentLight = Color(0xFFF0CC60); // 밝은 골드
  static const Color accentDim   = Color(0xFF9A7E20); // 어두운 골드
  static const Color primary     = surface;
  static const Color primaryLight = cardBg;

  // ─── Secondary — Jade Green (긍정 운세 / 성장 지표) ──
  static const Color jade      = Color(0xFF00A86B); // Jade Green
  static const Color jadeLight = Color(0xFF00CC85);
  static const Color jadeDim   = Color(0xFF007A50);
  static const Color teal      = jade;

  // ─── Text ────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF); // Pure White
  static const Color textSecondary = Color(0xFF8E8E93); // Silver Gray
  static const Color textMuted     = Color(0xFF5A5A6A);

  // ─── Glassmorphism (Glass White — rgba 5% white) ─────
  static const Color glassBg     = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x0DFFFFFF); // 5% white (0.5px 라인)

  // ─── 포인트 ───────────────────────────────────────────
  static const Color red = Color(0xFFFF4D4D);

  // ─── 오행색 — Brand Guide 오행 컬러 코드 ─────────────
  // 木(목): Jade Green   — 성장 / 긍정 지표
  // 火(화): Coral Red    — 강열 / 주의
  // 土(토): Amber Gold   — 안정 / Antique Gold와 구분
  // 金(금): Platinum     — 금속 / 가치
  // 水(수): Azure Blue   — 흐름 / 직관
  static const Color mokColor  = Color(0xFF00A86B); // Jade
  static const Color hwaColor  = Color(0xFFFF4D4D); // Coral Red ← 브랜드 가이드
  static const Color toColor   = Color(0xFFFFD700); // Amber Gold ← accent와 분리
  static const Color geumColor = Color(0xFFE5E5E5); // Platinum ← 브랜드 가이드
  static const Color suColor   = Color(0xFF007AFF); // Azure Blue ← 브랜드 가이드

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

  /// 카드 그라디언트
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D1525), Color(0xFF0A0E17)],
  );

  static LinearGradient get headerGradient => cardGradient;
}

// ─── 타이포그래피 헬퍼 ─────────────────────────────────
// 브랜드 가이드: Pretendard(body), Montserrat(숫자), Playfair Display(영문 포인트)
// Pretendard → google_fonts NotoSansKr로 대체 (시스템 레벨)
// NotoSerifKR → 한자/전통 장식 텍스트 유지

class AppFonts {
  /// 운세 점수 / 자산 숫자 — Montserrat + Gold
  static TextStyle score(double size, {
    FontWeight weight = FontWeight.w900,
    Color? color,
  }) => GoogleFonts.montserrat(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.accent,
    letterSpacing: -0.5,
  );

  /// 영문 키워드 포인트 — Playfair Display
  static TextStyle playfair(double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    FontStyle style = FontStyle.normal,
  }) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    color: color ?? AppColors.textPrimary,
  );

  /// Montserrat 일반 (숫자 외 영문)
  static TextStyle montserrat(double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) => GoogleFonts.montserrat(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.textPrimary,
  );
}

class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surface,
    // Body 기본 폰트: Noto Sans KR (Pretendard 대체)
    fontFamily: GoogleFonts.notoSansKr().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.jade,
      surface: AppColors.cardBg,
      onPrimary: Color(0xFF0A0E17),
      onSurface: AppColors.textPrimary,
    ),
    textTheme: TextTheme(
      // H1: 24pt Bold / 자간 -2%
      displayLarge: GoogleFonts.notoSansKr(
        fontSize: 24, fontWeight: FontWeight.bold,
        color: AppColors.textPrimary, letterSpacing: -0.48, height: 1.4),
      // H2: 18pt Semi-bold / 자간 -1%
      displayMedium: GoogleFonts.notoSansKr(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: -0.18, height: 1.4),
      // Body1: 15pt Regular / 행간 160%
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 15, fontWeight: FontWeight.normal,
        color: AppColors.textPrimary, height: 1.6),
      // Body2: 13pt Regular / 행간 160%
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 13, fontWeight: FontWeight.normal,
        color: AppColors.textSecondary, height: 1.6),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.notoSansKr(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary, letterSpacing: -0.18),
      iconTheme: const IconThemeData(color: AppColors.accent),
      shape: const Border(
        bottom: BorderSide(color: AppColors.divider, width: 1)),
    ),
    // Primary Button: Gold bg + Dark text, Radius 12px
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF0A0E17),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // ← 12px
        textStyle: GoogleFonts.notoSansKr(
          fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    // Secondary Button: Gold 1px 라인 + 투명 배경, Radius 12px
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent, width: 1),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // ← 12px
      ),
    ),
    cardTheme: const CardTheme(
      color: AppColors.glassBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: AppColors.glassBorder, width: 0.5)), // ← 0.5px
    ),
    tabBarTheme: TabBarTheme(
      indicatorColor: AppColors.accent,
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.notoSansKr(
        fontWeight: FontWeight.w600, fontSize: 13),
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
        side: BorderSide(color: AppColors.glassBorder, width: 0.5)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
  );

  static ThemeData get dark => light;
}
