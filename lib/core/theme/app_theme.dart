import 'package:flutter/material.dart';

/// 전통 한국 색채 팔레트 — 단청(丹靑) + 한지(韓紙) + 오방색(五方色)
class AppColors {
  // ─── 배경계 (먹빛 계열) ────────────────────────────
  static const Color surface   = Color(0xFF0D0804);  // 먹색 (濃墨)
  static const Color cardBg    = Color(0xFF1C100A);  // 한지 그림자
  static const Color cardBg2   = Color(0xFF261508);  // 한지 카드
  static const Color divider   = Color(0xFF4A2010);  // 단청 선

  // ─── 주 색채 (단청 금/적) ─────────────────────────
  static const Color primary      = Color(0xFF1A0A05); // 흑색 베이스
  static const Color primaryLight = Color(0xFF3D1A08); // 짙은 적갈
  static const Color accent       = Color(0xFFC8921A); // 전통 금(黃金)
  static const Color accentLight  = Color(0xFFE0A830); // 밝은 금
  static const Color accentDim    = Color(0xFF7A5810); // 어두운 금

  // ─── 텍스트 (한지색) ─────────────────────────────
  static const Color textPrimary   = Color(0xFFF0E4C2); // 한지 크림
  static const Color textSecondary = Color(0xFF9A7840); // 황토 갈색
  static const Color textMuted     = Color(0xFF5A3820); // 어두운 갈색

  // ─── 단청 포인트 컬러 ─────────────────────────────
  static const Color red   = Color(0xFF9B2010); // 단청 적(赤)
  static const Color teal  = Color(0xFF1B5E50); // 단청 청(靑)
  static const Color jade  = Color(0xFF2D6B3A); // 비취 녹(綠)

  // ─── 오행색 (五行色) — 전통 오방색 기반 ─────────────
  // 목(木) 청색(靑) — 동쪽, 봄, 나무
  static const Color mokColor  = Color(0xFF2E7D5A);
  // 화(火) 적색(赤) — 남쪽, 여름, 불
  static const Color hwaColor  = Color(0xFFBB2E0E);
  // 토(土) 황색(黃) — 중앙, 환절기, 흙
  static const Color toColor   = Color(0xFFC08010);
  // 금(金) 백색(白) — 서쪽, 가을, 쇠
  static const Color geumColor = Color(0xFFC0B090);
  // 수(水) 흑색(黑) — 북쪽, 겨울, 물
  static const Color suColor   = Color(0xFF1A5880);

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

  // ─── 그라디언트 ───────────────────────────────────

  /// 배경 그라디언트 — 먹빛 옻칠 효과
  static LinearGradient get mainGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0A05), Color(0xFF0D0804)],
  );

  /// 카드 그라디언트 — 단청 적갈 톤
  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF261508), Color(0xFF1C100A)],
  );

  /// 금빛 그라디언트 — 전통 금박 효과
  static LinearGradient get goldGradient => const LinearGradient(
    colors: [
      Color(0xFF7A5810),
      Color(0xFFC8921A),
      Color(0xFFE8C060),
      Color(0xFFC8921A),
      Color(0xFF7A5810),
    ],
  );

  /// 단청 헤더 그라디언트
  static LinearGradient get headerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1005), Color(0xFF1A0804), Color(0xFF0D0804)],
  );
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.surface,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.teal,
      surface: AppColors.cardBg,
      onPrimary: AppColors.primary,
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
      // 앱바 하단 금빛 구분선
      shape: const Border(
        bottom: BorderSide(color: AppColors.divider, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentDim,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.accent, width: 1),
        ),
        textStyle: const TextStyle(
          fontFamily: 'NotoSerifKR',
          fontSize: 16, fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
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
  );
}
