// real_map_view.dart — flutter_map 실제 지도 히트맵
// CartoDB Dark Matter 타일 + 자치구 원형 히트맵 + 카카오 주소 검색

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import 'district_map_data.dart';
import 'kakao_address_service.dart';

class RealMapView extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;

  const RealMapView({
    super.key,
    required this.result,
    required this.profile,
  });

  @override
  State<RealMapView> createState() => _RealMapViewState();
}

class _RealMapViewState extends State<RealMapView> {
  final _mapCtrl = MapController();
  final _searchCtrl = TextEditingController();

  DistrictData? _selectedDistrict;
  List<AddressResult> _searchResults = [];
  LatLng? _pinLocation;
  String? _pinLabel;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _score(DistrictData d) =>
      calcDistrictScore(d, widget.result.mainOehaeng, widget.result.weakOehaeng);

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

  Future<void> _onSearch(String text) async {
    if (text.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    final results = await searchKakaoAddress(text);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _goTo(AddressResult r) {
    final loc = LatLng(r.lat, r.lng);
    _mapCtrl.move(loc, 15.0);
    setState(() {
      _pinLocation = loc;
      _pinLabel = r.name;
      _searchResults = [];
      _searchCtrl.text = r.name;
      _selectedDistrict = null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // ── 지도 ──────────────────────────────────────────
      FlutterMap(
        mapController: _mapCtrl,
        options: const MapOptions(
          initialCenter: LatLng(37.5665, 126.9780),
          initialZoom: 11.2,
          minZoom: 10.0,
          maxZoom: 17.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
            userAgentPackageName:
                'com.changemindsupport.realestate_saju',
          ),
          // 자치구 원형 히트맵
          CircleLayer(
            circles: seoulDistricts.map((d) {
              final score = _score(d);
              final color = _oeColor(d.oehaeng);
              return CircleMarker(
                point: LatLng(d.lat, d.lng),
                radius: 600 + score * 4.0,
                useRadiusInMeter: true,
                color: color.withOpacity(0.12 + (score / 100) * 0.28),
                borderColor: color.withOpacity(score >= 75 ? 0.7 : 0.35),
                borderStrokeWidth: score >= 75 ? 1.8 : 0.8,
              );
            }).toList(),
          ),
          // 자치구 라벨 마커
          MarkerLayer(
            markers: seoulDistricts.map((d) {
              final score = _score(d);
              final color = _oeColor(d.oehaeng);
              final isSelected = _selectedDistrict?.name == d.name;
              return Marker(
                point: LatLng(d.lat, d.lng),
                width: 70,
                height: 44,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedDistrict =
                        isSelected ? null : d;
                  }),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: color.withOpacity(isSelected ? 1.0 : 0.5),
                            width: isSelected ? 1.5 : 0.8,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
                              : null,
                        ),
                        child: Text(
                          '${d.emoji}$score',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        d.name.replaceAll('·청담', '').replaceAll('압구정', '압구정'),
                        style: TextStyle(
                          fontSize: 8,
                          color: color.withOpacity(0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // 검색 핀
          if (_pinLocation != null)
            MarkerLayer(markers: [
              Marker(
                point: _pinLocation!,
                width: 44,
                height: 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _pinLabel ?? '',
                        style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const Icon(Icons.location_pin, color: AppColors.accent, size: 28),
                  ],
                ),
              ),
            ]),
        ],
      ),

      // ── 검색 바 ────────────────────────────────────────
      Positioned(
        top: 12, left: 12, right: 12,
        child: Column(children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 10),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: '주소·장소 검색 (예: 강남역, 성수동)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                      )
                    : _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _searchResults = [];
                              _pinLocation = null;
                            }),
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              ),
            ),
          ),

          // 검색 결과 목록
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBg.withOpacity(0.97),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _searchResults.map((r) => InkWell(
                  onTap: () => _goTo(r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(children: [
                      const Icon(Icons.place_outlined, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.name, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                        if (r.address.isNotEmpty && r.address != r.name)
                          Text(r.address, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ])),
                    ]),
                  ),
                )).toList(),
              ),
            ).animate().fadeIn(duration: 200.ms),

          // 카카오 키 미설정 안내
          if (!kakaoKeyConfigured)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.35)),
              ),
              child: const Text(
                '🔑 kakao_address_service.dart에 REST API 키 입력 시 주소 검색 활성화',
                style: TextStyle(fontSize: 10, color: Colors.orange, height: 1.4),
              ),
            ),
        ]),
      ),

      // ── 선택된 자치구 카드 ─────────────────────────────
      if (_selectedDistrict != null)
        Positioned(
          bottom: 16, left: 12, right: 12,
          child: _DistrictCard(
            data: _selectedDistrict!,
            score: _score(_selectedDistrict!),
            color: _oeColor(_selectedDistrict!.oehaeng),
            onClose: () => setState(() => _selectedDistrict = null),
          ).animate().slideY(begin: 0.3, duration: 250.ms),
        ),
    ]);
  }
}

// ─── 자치구 선택 카드 ──────────────────────────────────
class _DistrictCard extends StatelessWidget {
  final DistrictData data;
  final int score;
  final Color color;
  final VoidCallback onClose;

  const _DistrictCard({
    required this.data,
    required this.score,
    required this.color,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.97),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5), width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 14)],
      ),
      child: Row(children: [
        Text(data.emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            data.name,
            style: TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${data.oehaeng} · ${data.keyword}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            data.description,
            style: const TextStyle(fontSize: 11, color: AppColors.textPrimary, height: 1.4),
          ),
        ])),
        const SizedBox(width: 8),
        Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Column(children: [
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontFamily: 'NotoSerifKR',
                ),
              ),
              Text('점', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
            ]),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
          ),
        ]),
      ]),
    );
  }
}
