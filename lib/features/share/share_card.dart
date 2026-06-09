import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/saju/saju_calculator.dart';

// ─────────────────────────────────────────────────────
// SNS 공유 카드 유틸
// ─────────────────────────────────────────────────────

class ShareCardUtil {
  static final ScreenshotController _ctrl = ScreenshotController();

  /// 공유 카드 이미지 생성 후 공유
  static Future<void> shareCard({
    required BuildContext context,
    required SajuResult result,
    required String name,
    required String cardType, // 'direction' | 'property' | 'saju'
  }) async {
    final widget = _buildCardWidget(result, name, cardType);
    try {
      final bytes = await _ctrl.captureFromWidget(
        widget,
        pixelRatio: 3.0,
        targetSize: const Size(400, 400),
      );
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: 'saju_card.png')],
        text: _shareText(result, name, cardType),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유 카드 생성 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  static String _shareText(SajuResult r, String name, String type) {
    final oe = r.mainOehaeng;
    const dir = {'목': '동쪽 🌿', '화': '남쪽 🔥', '토': '중앙 🏛', '금': '서쪽 💎', '수': '북쪽 🌊'};
    return '${name}님의 부동산 사주 분석\n'
        '주 오행: $oe  방위: ${dir[oe] ?? ''}\n'
        '📱 https://realestate-saju.surge.sh';
  }

  static Widget _buildCardWidget(SajuResult r, String name, String type) {
    return _SajuShareCardWidget(result: r, name: name, cardType: type);
  }
}

// ─────────────────────────────────────────────────────
// 공유 카드 위젯 (400×400 정사각형)
// ─────────────────────────────────────────────────────

class _SajuShareCardWidget extends StatelessWidget {
  final SajuResult result;
  final String name;
  final String cardType;

  const _SajuShareCardWidget({
    required this.result,
    required this.name,
    required this.cardType,
  });

  @override
  Widget build(BuildContext context) {
    final oe = result.mainOehaeng;
    final color = AppColors.getOehaengColor(oe);
    final dir = _directionData[oe]!;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 400, height: 400,
        decoration: BoxDecoration(
          color: const Color(0xFF100E08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.6), width: 2),
        ),
        child: Stack(children: [
          // 배경 패턴
          Positioned.fill(child: CustomPaint(
            painter: _CardPatternPainter(color: color),
          )),
          // 내부 이중 테두리
          Positioned(
            left: 8, right: 8, top: 8, bottom: 8,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2), width: 0.8),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(children: [
              // ── 헤더 ──
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                  child: const Text('✦ 부동산 사주 ✦', style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 3,
                  )),
                ),
              ]),
              const SizedBox(height: 6),
              Text('$name 님의 부동산 방위 궁합', style: TextStyle(
                fontSize: 11, color: color.withOpacity(0.8), letterSpacing: 1)),

              const Spacer(),

              // ── 오행 원형 ──
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [BoxShadow(
                    color: color.withOpacity(0.4), blurRadius: 24, spreadRadius: 2,
                  )],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dir['hanja']!, style: TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 48, fontWeight: FontWeight.bold, color: color,
                  )),
                  Text(oe, style: TextStyle(
                    fontSize: 11, color: color.withOpacity(0.9), letterSpacing: 2)),
                ]),
              ),

              const SizedBox(height: 20),

              // ── 방위 ──
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [color, AppColors.accent, color],
                ).createShader(b),
                child: Text(
                  '${dir['emoji']}  내 이사 방향: ${dir['direction']}',
                  style: const TextStyle(
                    fontFamily: 'NotoSerifKR',
                    fontSize: 17, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── 정보 행 ──
              _infoRow('📍', dir['districts']!),
              const SizedBox(height: 6),
              _infoRow('🏠', dir['propertyType']!),
              const SizedBox(height: 6),
              _infoRow('🗓', '매수 적기: ${dir['season']!}'),

              const Spacer(),

              // ── 푸터 ──
              Container(height: 0.5, color: color.withOpacity(0.3)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('realestate-saju.surge.sh', style: TextStyle(
                  fontSize: 10, color: color.withOpacity(0.6), letterSpacing: 0.5)),
                Text('부동산 사주 앱', style: TextStyle(
                  fontSize: 10, color: color.withOpacity(0.6))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoRow(String emoji, String text) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(
        fontFamily: 'NotoSerifKR',
        fontSize: 12, color: Color(0xFFD4C4A0), letterSpacing: 0.3)),
    ],
  );

  static const _directionData = <String, Map<String, String>>{
    '목': {
      'hanja': '木', 'direction': '동쪽 (東)', 'emoji': '🌿',
      'districts': '성동·광진·노원구',
      'propertyType': '신축 아파트 · 재개발 구역',
      'season': '봄 (3~5월)',
    },
    '화': {
      'hanja': '火', 'direction': '남쪽 (南)', 'emoji': '🔥',
      'districts': '강남·서초·송파구',
      'propertyType': '역세권 아파트 · 오피스텔',
      'season': '여름 (6~8월)',
    },
    '토': {
      'hanja': '土', 'direction': '중앙 (中)', 'emoji': '🏛',
      'districts': '종로·중구·용산구',
      'propertyType': '구도심 아파트 · 토지',
      'season': '환절기 (3·6·9·12월)',
    },
    '금': {
      'hanja': '金', 'direction': '서쪽 (西)', 'emoji': '💎',
      'districts': '양천·강서·영등포구',
      'propertyType': '프리미엄 아파트 · 브랜드 단지',
      'season': '가을 (9~11월)',
    },
    '수': {
      'hanja': '水', 'direction': '북쪽 (北)', 'emoji': '🌊',
      'districts': '마포·강북·성북구',
      'propertyType': '한강변 · 수변 아파트',
      'season': '겨울 (12~2월)',
    },
  };
}

// ─── 배경 패턴 페인터 ─────────────────────────────────

class _CardPatternPainter extends CustomPainter {
  final Color color;
  const _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 모서리 장식
    final corner = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const c = 20.0;
    for (final dx in [16.0, size.width - 16]) {
      for (final dy in [16.0, size.height - 16]) {
        final sx = dx < size.width / 2 ? 1 : -1;
        final sy = dy < size.height / 2 ? 1 : -1;
        canvas.drawLine(Offset(dx, dy), Offset(dx + sx * c, dy), corner);
        canvas.drawLine(Offset(dx, dy), Offset(dx, dy + sy * c), corner);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

