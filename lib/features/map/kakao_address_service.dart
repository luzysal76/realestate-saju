// kakao_address_service.dart — 카카오 로컬 API 주소 검색
// https://developers.kakao.com → 내 애플리케이션 → REST API 키

import 'dart:convert';
import 'package:http/http.dart' as http;

// ▼ 카카오 디벨로퍼스에서 발급한 REST API 키를 입력하세요
const _kakaoKey = '';

bool get kakaoKeyConfigured => _kakaoKey.isNotEmpty;

// ─── 검색 결과 모델 ────────────────────────────────────
class AddressResult {
  final String name;
  final String address;
  final double lat;
  final double lng;

  const AddressResult({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
  });
}

// ─── 주소/장소 검색 (키워드 검색 API) ──────────────────
Future<List<AddressResult>> searchKakaoAddress(String query) async {
  if (!kakaoKeyConfigured || query.trim().length < 2) return [];

  try {
    final uri = Uri.parse(
      'https://dapi.kakao.com/v2/local/search/keyword.json'
      '?query=${Uri.encodeComponent(query)}&size=5',
    );
    final res = await http
        .get(uri, headers: {'Authorization': 'KakaoAK $_kakaoKey'})
        .timeout(const Duration(seconds: 5));

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (data['documents'] as List?) ?? [];

    return docs.map((d) {
      return AddressResult(
        name: (d['place_name'] ?? d['address_name'] ?? '') as String,
        address: (d['address_name'] ?? '') as String,
        lat: double.tryParse((d['y'] ?? '').toString()) ?? 0,
        lng: double.tryParse((d['x'] ?? '').toString()) ?? 0,
      );
    }).where((r) => r.lat != 0 && r.lng != 0).toList();
  } catch (_) {
    return [];
  }
}
