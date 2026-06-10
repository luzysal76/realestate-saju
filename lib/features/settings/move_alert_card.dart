// move_alert_card.dart — 이사·계약 예정일 D-day 알림 카드
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/services/notification_service.dart';

class MoveAlertCard extends StatefulWidget {
  final String profileName;
  const MoveAlertCard({super.key, this.profileName = '고객'});

  @override
  State<MoveAlertCard> createState() => _MoveAlertCardState();
}

class _MoveAlertCardState extends State<MoveAlertCard> {
  DateTime? _moveDate;
  DateTime? _contractDate;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await NotificationService.getMoveDate();
    final c = await NotificationService.getContractDate();
    if (mounted) setState(() { _moveDate = m; _contractDate = c; _loading = false; });
  }

  Future<void> _pickDate({required bool isMove}) async {
    final initial = isMove
        ? (_moveDate ?? DateTime.now().add(const Duration(days: 7)))
        : (_contractDate ?? DateTime.now().add(const Duration(days: 3)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.cardBg,
            onSurface: AppColors.textPrimary,
          ),
          dialogBackgroundColor: AppColors.cardBg,
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    if (isMove) {
      setState(() => _moveDate = picked);
      await NotificationService.saveMoveDate(picked);
      await NotificationService.scheduleMoveAlert(
        targetDate: picked,
        label: '이사',
        name: widget.profileName,
        id: NotificationService.idMove,
      );
      _showSnack('이사 예정일 ${_fmt(picked)} — 전날 알림이 예약됐습니다 🏠');
    } else {
      setState(() => _contractDate = picked);
      await NotificationService.saveContractDate(picked);
      await NotificationService.scheduleMoveAlert(
        targetDate: picked,
        label: '계약',
        name: widget.profileName,
        id: NotificationService.idContract,
      );
      _showSnack('계약 예정일 ${_fmt(picked)} — 전날 알림이 예약됐습니다 📋');
    }
  }

  Future<void> _clearDate({required bool isMove}) async {
    if (isMove) {
      setState(() => _moveDate = null);
      await NotificationService.saveMoveDate(null);
      await NotificationService.cancelMoveAlert(NotificationService.idMove);
    } else {
      setState(() => _contractDate = null);
      await NotificationService.saveContractDate(null);
      await NotificationService.cancelMoveAlert(NotificationService.idContract);
    }
    _showSnack(isMove ? '이사 알림이 취소됐습니다' : '계약 알림이 취소됐습니다');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.cardBg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  String _fmt(DateTime d) => '${d.month}월 ${d.day}일';

  String _dDay(DateTime d) {
    final diff = d.difference(DateTime.now()).inDays;
    if (diff == 0) return 'D-day';
    if (diff < 0) return '지남';
    return 'D-$diff';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox();
    return TraditionalCard(
      doubleBorder: true,
      padding: EdgeInsets.zero,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            const KoreanSectionTitle(title: '예정일 알림 (日程)', showDivider: false),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Text('D-1 알림', style: TextStyle(
                fontSize: 9, color: AppColors.accent)),
            ),
          ]),
        ),
        Container(height: 0.5, color: AppColors.divider),

        // 이사 예정일
        _alertTile(
          icon: '🏠',
          label: '이사 예정일',
          date: _moveDate,
          onSet: () => _pickDate(isMove: true),
          onClear: () => _clearDate(isMove: true),
        ),
        Container(height: 0.5, color: AppColors.divider.withOpacity(0.5)),

        // 계약 예정일
        _alertTile(
          icon: '📋',
          label: '계약 예정일',
          date: _contractDate,
          onSet: () => _pickDate(isMove: false),
          onClear: () => _clearDate(isMove: false),
        ),

        // 안내 텍스트
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Text(
            '예정일 전날 오전 9시에 알림을 보내드립니다',
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ),
      ]),
    ).animate(delay: 240.ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _alertTile({
    required String icon,
    required String label,
    required DateTime? date,
    required VoidCallback onSet,
    required VoidCallback onClear,
  }) {
    final isSet = date != null && date.isAfter(DateTime.now());
    return InkWell(
      onTap: onSet,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
              fontFamily: 'NotoSerifKR', fontSize: 13,
              fontWeight: FontWeight.w500, color: AppColors.textPrimary,
              letterSpacing: 0.3,
            )),
            const SizedBox(height: 1),
            Text(
              isSet && date != null ? '${_fmt(date)}  (${_dDay(date)})' : '날짜를 설정하세요',
              style: TextStyle(fontSize: 10,
                color: isSet ? AppColors.accent : AppColors.textSecondary),
            ),
          ])),
          if (isSet)
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.hwaColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.hwaColor.withOpacity(0.3)),
                ),
                child: const Text('취소', style: TextStyle(
                  fontSize: 10, color: AppColors.hwaColor)),
              ),
            )
          else
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 16),
        ]),
      ),
    );
  }
}
