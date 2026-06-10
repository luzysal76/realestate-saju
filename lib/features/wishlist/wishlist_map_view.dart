// wishlist_map_view.dart — 관심 매물 지도 뷰 위젯
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/saju/saju_calculator.dart';
import '../map/district_map_data.dart';
import 'wishlist_model.dart';

class WishlistMapView extends StatelessWidget {
  final List<WishlistItem> items;
  final SajuResult result;
  final int Function(WishlistItem) scoreFn;
  final Color Function(int) scoreColorFn;
  final void Function(WishlistItem) onEditItem;

  const WishlistMapView({
    super.key,
    required this.items,
    required this.result,
    required this.scoreFn,
    required this.scoreColorFn,
    required this.onEditItem,
  });

  Color _oeColor(String oe) {
    switch (oe) {
      case '목': return AppColors.mokColor;
      case '화': return AppColors.hwaColor;
      case '토': return AppColors.toColor;
      case '금': return AppColors.geumColor;
      case '수': return AppColors.suColor;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistDistricts = {for (final i in items) i.districtName};

    return Stack(children: [
      FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(37.5665, 126.9780),
          initialZoom: 11.0,
          minZoom: 10.0,
          maxZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            subdomains: const ['a', 'b', 'c', 'd'],
            userAgentPackageName: 'com.changemindsupport.realestateluckinsaju',
          ),
          // 자치구 히트맵 원
          CircleLayer(circles: seoulDistricts.map((d) {
            final score = calcDistrictScore(d, result.mainOehaeng, result.weakOehaeng);
            final oe = _oeColor(d.oehaeng);
            final hasWishlist = wishlistDistricts.contains(d.name);
            return CircleMarker(
              point: LatLng(d.lat, d.lng),
              radius: hasWishlist ? 28 + score * 0.18 : 18 + score * 0.12,
              color: oe.withOpacity(hasWishlist ? 0.45 : 0.18),
              borderColor: hasWishlist ? AppColors.accent : oe,
              borderStrokeWidth: hasWishlist ? 2.0 : 0.8,
            );
          }).toList()),
          // 자치구 라벨 + 관심 매물 뱃지
          MarkerLayer(markers: seoulDistricts.map((d) {
            final score = calcDistrictScore(d, result.mainOehaeng, result.weakOehaeng);
            final oe = _oeColor(d.oehaeng);
            final hasWishlist = wishlistDistricts.contains(d.name);
            final count = items.where((i) => i.districtName == d.name).length;
            return Marker(
              point: LatLng(d.lat, d.lng),
              width: 60, height: 52,
              child: GestureDetector(
                onTap: () => _showDistrictSheet(context, d),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (hasWishlist)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4)),
                      child: Text('★$count', style: const TextStyle(
                          fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  Text('$score', style: TextStyle(
                      fontFamily: 'NotoSerifKR', fontSize: 11,
                      fontWeight: FontWeight.bold, color: oe)),
                  Text(d.name.replaceAll('구', ''),
                      style: const TextStyle(fontSize: 8, color: Colors.white70)),
                ]),
              ),
            );
          }).toList()),
        ],
      ),
      // 범례
      Positioned(
        top: 10, right: 10,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withOpacity(0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 10, height: 10,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.accent)),
              const SizedBox(width: 4),
              const Text('관심 매물', style: TextStyle(
                  fontSize: 9, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 3),
            const Text('원 크기 = 점수', style: TextStyle(
                fontSize: 9, color: AppColors.textMuted)),
            const Text('탭 → 매물 확인', style: TextStyle(
                fontSize: 9, color: AppColors.textMuted)),
          ]),
        ),
      ),
    ]);
  }

  void _showDistrictSheet(BuildContext context, DistrictData d) {
    final distItems = items.where((i) => i.districtName == d.name).toList();
    final score = calcDistrictScore(d, result.mainOehaeng, result.weakOehaeng);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(d.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: TextStyle(fontFamily: 'NotoSerifKR',
                  fontSize: 16, fontWeight: FontWeight.bold, color: _oeColor(d.oehaeng))),
              Text('${d.oehaeng} · 사주 적합도 $score점',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ])),
          ]),
          if (distItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('이 동네에 저장된 매물이 없습니다.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            )
          else ...[
            const SizedBox(height: 10),
            const Divider(color: AppColors.divider),
            ...distItems.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.nickname, style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
              subtitle: Text([
                if (item.floor > 0) '${item.floor}층',
                if (item.direction != '미입력') item.direction,
                if (item.address.isNotEmpty) item.address,
              ].join(' · '),
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              trailing: Text('${scoreFn(item)}점', style: TextStyle(
                  fontWeight: FontWeight.bold, color: scoreColorFn(scoreFn(item)))),
              onTap: () { Navigator.pop(ctx); onEditItem(item); },
            )),
          ],
        ]),
      ),
    );
  }
}
