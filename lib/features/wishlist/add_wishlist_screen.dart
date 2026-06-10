// add_wishlist_screen.dart — 관심 매물 추가/수정 화면
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/widgets/gold_button.dart';
import '../map/district_map_data.dart';
import 'wishlist_model.dart';

class AddWishlistScreen extends StatefulWidget {
  final WishlistItem? existing; // null = 신규

  const AddWishlistScreen({super.key, this.existing});

  @override
  State<AddWishlistScreen> createState() => _AddWishlistScreenState();
}

class _AddWishlistScreenState extends State<AddWishlistScreen> {
  late TextEditingController _nicknameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _memoCtrl;
  late TextEditingController _floorCtrl;

  String _district = '강남구';
  String _direction = '미입력';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nicknameCtrl = TextEditingController(text: e?.nickname ?? '');
    _addressCtrl  = TextEditingController(text: e?.address ?? '');
    _memoCtrl     = TextEditingController(text: e?.memo ?? '');
    _floorCtrl    = TextEditingController(
        text: (e != null && e.floor > 0) ? '${e.floor}' : '');
    _district  = e?.districtName ?? seoulDistricts.first.name;
    _direction = e?.direction ?? '미입력';
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _addressCtrl.dispose();
    _memoCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nick = _nicknameCtrl.text.trim();
    if (nick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('매물 이름을 입력해주세요')));
      return;
    }
    setState(() => _saving = true);

    final floor = int.tryParse(_floorCtrl.text.trim()) ?? 0;
    if (widget.existing != null) {
      await WishlistItem.update(widget.existing!.copyWith(
        nickname: nick, districtName: _district, address: _addressCtrl.text.trim(),
        floor: floor, direction: _direction, memo: _memoCtrl.text.trim(),
      ));
    } else {
      await WishlistItem.add(WishlistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nickname: nick, districtName: _district, address: _addressCtrl.text.trim(),
        floor: floor, direction: _direction, memo: _memoCtrl.text.trim(),
      ));
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: Text(widget.existing == null ? '관심 매물 추가' : '매물 수정',
              style: const TextStyle(fontFamily: 'NotoSerifKR', fontSize: 17,
                  color: Colors.white, letterSpacing: 2)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
        children: [
          _buildSection('🏷️ 매물 이름', '예: 잠실 30평, 마포 오피스텔',
              child: _field(_nicknameCtrl, '매물 이름 (필수)')),
          const SizedBox(height: 14),
          _buildSection('📍 자치구', '서울 25개 자치구에서 선택',
              child: _districtPicker()),
          const SizedBox(height: 14),
          _buildSection('🏠 상세 주소', '동/아파트명 (선택)',
              child: _field(_addressCtrl, '예: 잠실동 잠실엘스 101동')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _buildSection('🔢 층수', '선택',
                child: _field(_floorCtrl, '예: 15',
                    inputType: TextInputType.number))),
            const SizedBox(width: 10),
            Expanded(child: _buildSection('🧭 향', '집의 방향',
                child: _directionPicker())),
          ]),
          const SizedBox(height: 14),
          _buildSection('📝 메모', '방문 소감, 특이사항 등 (선택)',
              child: _field(_memoCtrl, '자유롭게 입력', maxLines: 3)),
          const SizedBox(height: 24),
          GoldButton(
            label: widget.existing == null ? '저장하기' : '수정 완료',
            onTap: _save,
            loading: _saving,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, {required Widget child}) {
    return TraditionalCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13,
            fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        Text(subtitle, style: const TextStyle(fontSize: 11,
            color: AppColors.textMuted)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true, fillColor: AppColors.cardBg2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accent, width: 1.4)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.divider)),
      ),
    );
  }

  Widget _districtPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _district,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent, size: 18),
          items: seoulDistricts.map((d) => DropdownMenuItem(
            value: d.name,
            child: Row(children: [
              Text(d.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(d.name),
            ]),
          )).toList(),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _district = v!);
          },
        ),
      ),
    );
  }

  Widget _directionPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _direction,
          isExpanded: true,
          dropdownColor: AppColors.cardBg,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.accent, size: 18),
          items: WishlistItem.directions.map((d) => DropdownMenuItem(
            value: d,
            child: Text(d),
          )).toList(),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => _direction = v!);
          },
        ),
      ),
    );
  }
}
