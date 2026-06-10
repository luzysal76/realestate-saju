// wishlist_model.dart — 관심 매물 모델 (SharedPreferences JSON 저장)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistItem {
  final String id;
  final String nickname;     // 매물 별명 (예: "잠실 34평")
  final String districtName; // 서울 자치구 (예: "송파구")
  final String address;      // 상세 주소/메모
  final int floor;           // 층수 (0 = 미입력)
  final String direction;    // 향 (남향/북향/동향/서향/미입력)
  final String memo;         // 자유 메모
  final DateTime savedAt;

  WishlistItem({
    required this.id,
    required this.nickname,
    required this.districtName,
    this.address = '',
    this.floor = 0,
    this.direction = '미입력',
    this.memo = '',
    DateTime? savedAt,
  }) : savedAt = savedAt ?? DateTime.now();

  // ─── 직렬화 ────────────────────────────────────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'districtName': districtName,
    'address': address,
    'floor': floor,
    'direction': direction,
    'memo': memo,
    'savedAt': savedAt.toIso8601String(),
  };

  factory WishlistItem.fromJson(Map<String, dynamic> j) => WishlistItem(
    id: j['id'] as String,
    nickname: j['nickname'] as String,
    districtName: j['districtName'] as String,
    address: (j['address'] as String?) ?? '',
    floor: (j['floor'] as int?) ?? 0,
    direction: (j['direction'] as String?) ?? '미입력',
    memo: (j['memo'] as String?) ?? '',
    savedAt: DateTime.tryParse(j['savedAt'] as String? ?? '') ?? DateTime.now(),
  );

  WishlistItem copyWith({
    String? nickname, String? districtName, String? address,
    int? floor, String? direction, String? memo,
  }) => WishlistItem(
    id: id, savedAt: savedAt,
    nickname: nickname ?? this.nickname,
    districtName: districtName ?? this.districtName,
    address: address ?? this.address,
    floor: floor ?? this.floor,
    direction: direction ?? this.direction,
    memo: memo ?? this.memo,
  );

  // ─── 향 → 각도 (나침반 표시용) ─────────────────────
  double get directionAngle {
    const m = {'남향': 180.0, '북향': 0.0, '동향': 90.0, '서향': 270.0,
               '남동향': 135.0, '남서향': 225.0, '북동향': 45.0, '북서향': 315.0};
    return m[direction] ?? -1.0;
  }

  static const List<String> directions = [
    '미입력', '남향', '북향', '동향', '서향',
    '남동향', '남서향', '북동향', '북서향'
  ];

  // ─── SharedPreferences 저장소 ──────────────────────
  static const _key = 'wishlist_items_v1';

  static Future<List<WishlistItem>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => WishlistItem.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<WishlistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<void> add(WishlistItem item) async {
    final items = await loadAll();
    items.insert(0, item);
    await saveAll(items);
  }

  static Future<void> delete(String id) async {
    final items = await loadAll();
    items.removeWhere((e) => e.id == id);
    await saveAll(items);
  }

  static Future<void> update(WishlistItem updated) async {
    final items = await loadAll();
    final idx = items.indexWhere((e) => e.id == updated.id);
    if (idx >= 0) items[idx] = updated;
    await saveAll(items);
  }
}
