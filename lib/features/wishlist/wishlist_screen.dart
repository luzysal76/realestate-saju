// wishlist_screen.dart — 관심 매물 목록 + 사주 점수 비교
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/saju/saju_calculator.dart';
import '../../shared/models/saju_profile.dart';
import '../map/district_map_data.dart';
import 'wishlist_model.dart';
import 'add_wishlist_screen.dart';

class WishlistScreen extends StatefulWidget {
  final SajuResult result;
  final SajuProfile profile;

  const WishlistScreen({super.key, required this.result, required this.profile});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<WishlistItem> _items = [];
  bool _loading = true;
  bool _sortByScore = true; // true = 사주점수순, false = 저장순

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await WishlistItem.loadAll();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  // 사주 점수 계산 (자치구 + 층수 + 향 보정)
  int _score(WishlistItem item) {
    final d = seoulDistricts.firstWhere(
      (d) => d.name == item.districtName,
      orElse: () => seoulDistricts.first,
    );
    int score = calcDistrictScore(d, widget.result.mainOehaeng, widget.result.weakOehaeng);

    // 층수 보정: 오행별 길한 층수 +5, 흉한 층수 -5
    if (item.floor > 0) {
      score += _floorBonus(item.floor, widget.result.mainOehaeng);
    }
    // 향 보정: 오행별 길한 방향 +5
    if (item.direction != '미입력') {
      score += _directionBonus(item.direction, widget.result.mainOehaeng);
    }
    return score.clamp(0, 100);
  }

  int _floorBonus(int floor, String oe) {
    // 오행별 길한 층수 (수리오행)
    const luckyFloors = {
      '목': [3, 4, 8, 9, 13, 14, 18, 19, 23, 24],
      '화': [7, 8, 12, 13, 17, 18, 22, 23],
      '토': [5, 6, 10, 11, 15, 16, 20, 21, 25, 26],
      '금': [4, 9, 14, 19, 24, 29],
      '수': [1, 6, 11, 16, 21, 26],
    };
    const unluckyFloors = {
      '목': [1, 2, 6, 7],
      '화': [1, 6, 11, 16],
      '토': [3, 4, 8, 9],
      '금': [2, 3, 7, 8],
      '수': [5, 10, 15, 20],
    };
    final lucky = luckyFloors[oe] ?? [];
    final unlucky = unluckyFloors[oe] ?? [];
    if (lucky.contains(floor)) return 5;
    if (unlucky.contains(floor)) return -5;
    return 0;
  }

  int _directionBonus(String dir, String oe) {
    const luckyDir = {
      '목': ['동향', '남동향'],
      '화': ['남향', '남동향'],
      '토': ['서남향', '남향'],
      '금': ['서향', '북서향'],
      '수': ['북향', '북동향'],
    };
    const unluckyDir = {
      '목': ['서향', '북서향'],
      '화': ['북향', '북동향'],
      '토': ['동향', '북동향'],
      '금': ['남향', '남동향'],
      '수': ['서남향', '서향'],
    };
    final lucky = luckyDir[oe] ?? [];
    final unlucky = unluckyDir[oe] ?? [];
    if (lucky.contains(dir)) return 5;
    if (unlucky.contains(dir)) return -5;
    return 0;
  }

  List<WishlistItem> get _sorted {
    final list = [..._items];
    if (_sortByScore) {
      list.sort((a, b) => _score(b).compareTo(_score(a)));
    }
    return list;
  }

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

  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.mokColor;
    if (score >= 60) return AppColors.accent;
    if (score >= 40) return AppColors.textSecondary;
    return AppColors.hwaColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('관심 매물',
              style: TextStyle(fontFamily: 'NotoSerifKR', fontSize: 18,
                  color: Colors.white, letterSpacing: 3)),
        ),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _sortByScore = !_sortByScore),
              child: Text(_sortByScore ? '저장순' : '점수순',
                  style: const TextStyle(color: AppColors.accent, fontSize: 12)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toAdd,
        backgroundColor: AppColors.accentDim,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('매물 추가', style: TextStyle(
            fontFamily: 'NotoSerifKR', fontSize: 13, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _items.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Future<void> _toAdd() async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => const AddWishlistScreen()));
    if (ok == true) _load();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('物件', style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 52, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 16),
        const Text('관심 매물을 추가해보세요', style: TextStyle(
            fontSize: 15, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        const Text('자치구·층수·향을 입력하면\n사주 점수로 비교해드립니다',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.6)),
        const SizedBox(height: 24),
        GoldButton(label: '첫 매물 추가하기', onTap: _toAdd),
      ]),
    );
  }

  Widget _buildList() {
    final sorted = _sorted;
    final best = _score(sorted.first);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 100),
      itemCount: sorted.length + 1,
      itemBuilder: (ctx, i) {
        if (i == 0) return _buildSummaryBanner(sorted, best);
        final item = sorted[i - 1];
        final rank = i;
        return _buildItemCard(item, rank, best).animate(
            delay: Duration(milliseconds: i * 60)).fadeIn().slideY(begin: 0.08);
      },
    );
  }

  Widget _buildSummaryBanner(List<WishlistItem> sorted, int best) {
    return TraditionalCard(
      borderColor: AppColors.accent.withOpacity(0.3),
      child: Row(children: [
        ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('物件', style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${sorted.length}개 매물 분석 완료', style: const TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 13,
              fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 3),
          Text('${widget.result.mainOehaeng}(${widget.result.mainOehaeng}) 기준 '
              '최고 ${best}점 · 평균 ${_avgScore(sorted)}점',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }

  int _avgScore(List<WishlistItem> items) {
    if (items.isEmpty) return 0;
    return (items.fold(0, (s, e) => s + _score(e)) / items.length).round();
  }

  Widget _buildItemCard(WishlistItem item, int rank, int best) {
    final score = _score(item);
    final d = seoulDistricts.firstWhere(
      (d) => d.name == item.districtName, orElse: () => seoulDistricts.first);
    final oeColor = _oeColor(d.oehaeng);
    final scoreColor = _scoreColor(score);
    final isBest = score == best && rank == 1;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.hwaColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: AppColors.hwaColor),
      ),
      confirmDismiss: (_) async {
        HapticFeedback.lightImpact();
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text('삭제', style: TextStyle(color: AppColors.textPrimary)),
            content: Text('「${item.nickname}」을 삭제할까요?',
                style: const TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소', style: TextStyle(color: AppColors.textSecondary))),
              TextButton(onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('삭제', style: TextStyle(color: AppColors.hwaColor))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        await WishlistItem.delete(item.id);
        setState(() => _items.removeWhere((e) => e.id == item.id));
      },
      child: GestureDetector(
        onTap: () => _toEdit(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isBest ? AppColors.accent.withOpacity(0.06) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isBest ? AppColors.accent.withOpacity(0.5) : AppColors.divider,
              width: isBest ? 1.4 : 0.8,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // 순위
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBest ? AppColors.accent.withOpacity(0.2) : AppColors.cardBg2,
                  border: Border.all(
                    color: isBest ? AppColors.accent : AppColors.divider),
                ),
                child: Center(child: Text('$rank',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                        color: isBest ? AppColors.accent : AppColors.textSecondary))),
              ),
              const SizedBox(width: 8),
              Text(d.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(item.nickname, style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (isBest) Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3)),
                    child: const Text('최고', style: TextStyle(fontSize: 9,
                        color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ),
                ]),
                Text('${item.districtName} · ${d.oehaeng} 기운',
                    style: TextStyle(fontSize: 11, color: oeColor)),
              ])),
              // 점수
              Column(children: [
                Text('$score', style: TextStyle(fontFamily: 'NotoSerifKR',
                    fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor)),
                Text('점', style: TextStyle(fontSize: 10, color: scoreColor)),
              ]),
            ]),
            // 상세 정보 행
            Padding(
              padding: const EdgeInsets.only(left: 38, top: 8),
              child: Wrap(spacing: 10, runSpacing: 4, children: [
                if (item.floor > 0) _chip('🔢 ${item.floor}층',
                    bonus: _floorBonus(item.floor, widget.result.mainOehaeng)),
                if (item.direction != '미입력') _chip('🧭 ${item.direction}',
                    bonus: _directionBonus(item.direction, widget.result.mainOehaeng)),
                if (item.address.isNotEmpty)
                  _chip('📍 ${item.address}', bonus: 0),
              ]),
            ),
            if (item.memo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 38, top: 6),
                child: Text('📝 ${item.memo}', style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, {required int bonus}) {
    Color color = AppColors.textMuted;
    String prefix = '';
    if (bonus > 0) { color = AppColors.mokColor; prefix = '▲ '; }
    if (bonus < 0) { color = AppColors.hwaColor; prefix = '▼ '; }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text('$prefix$label',
          style: TextStyle(fontSize: 10, color: color)),
    );
  }

  Future<void> _toEdit(WishlistItem item) async {
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => AddWishlistScreen(existing: item)));
    if (ok == true) _load();
  }
}
