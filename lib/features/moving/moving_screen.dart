import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/korean_decorations.dart';
import '../../core/saju/saju_calculator.dart';
import '../../core/saju/lucky_day.dart';

class MovingScreen extends StatefulWidget {
  final SajuResult result;
  const MovingScreen({super.key, required this.result});

  @override
  State<MovingScreen> createState() => _MovingScreenState();
}

class _MovingScreenState extends State<MovingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<LuckyDayResult> _luckyDays = [];
  List<LuckyDayResult> _contractDays = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadDays();
  }

  void _loadDays() {
    setState(() {
      _luckyDays = LuckyDayCalculator.getMonthlyLuckyDays(
        year: _focusedDay.year,
        month: _focusedDay.month,
        mainOehaeng: widget.result.mainOehaeng,
      );
      _contractDays = LuckyDayCalculator.getContractLuckyDays(
        year: _focusedDay.year,
        month: _focusedDay.month,
        mainOehaeng: widget.result.mainOehaeng,
      );
    });
  }

  bool _isLuckyDay(DateTime day) =>
      _luckyDays.any((d) => isSameDay(d.date, day));

  bool _isContractDay(DateTime day) =>
      _contractDays.any((d) => isSameDay(d.date, day));

  LuckyDayResult? _getDayResult(DateTime day) {
    try {
      return _luckyDays.firstWhere((d) => isSameDay(d.date, day));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => AppColors.goldGradient.createShader(b),
          child: const Text('移徙 吉日',
            style: TextStyle(fontFamily: 'NotoSerifKR',
              fontSize: 18, color: Colors.white, letterSpacing: 3)),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: '이사 길일'),
            Tab(text: '계약 길일'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildMovingTab(),
          _buildContractTab(),
        ],
      ),
    );
  }

  Widget _buildMovingTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 오행 안내
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: TraditionalCard(
              borderColor: AppColors.getOehaengColor(widget.result.mainOehaeng).withOpacity(0.4),
              child: Row(children: [
                OehaengBadge(widget.result.mainOehaeng),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${widget.result.mainOehaeng}(${_oehaengHanja(widget.result.mainOehaeng)}) 기운 기준 길일  ·  大吉/吉/平吉',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, letterSpacing: 0.3),
                )),
              ]),
            ),
          ),

          // 달력
          TableCalendar(
            firstDay: DateTime(2024),
            lastDay: DateTime(2030, 12),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            onDaySelected: (sel, foc) => setState(() {
              _selectedDay = sel;
              _focusedDay = foc;
            }),
            onPageChanged: (foc) {
              _focusedDay = foc;
              _loadDays();
            },
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
              weekendTextStyle: const TextStyle(color: Color(0xFFFF7B7B)),
              outsideTextStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.4)),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 16, fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              weekendStyle: TextStyle(fontSize: 12, color: Color(0xFFFF7B7B)),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (ctx, day, focusedDay) {
                final result = _getDayResult(day);
                if (result == null) return null;
                final isGrade = result.grade.contains('대길');
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isGrade
                        ? Colors.red.withOpacity(0.15)
                        : Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isGrade
                          ? Colors.red.withOpacity(0.5)
                          : Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: isGrade ? Colors.red[300] : Colors.amber[300],
                          ),
                        ),
                        if (result.isSonNone)
                          Text('손', style: TextStyle(fontSize: 7, color: Colors.amber[400])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 선택된 날 상세
          if (_selectedDay != null)
            _buildSelectedDayDetail(_selectedDay!),

          // 이달 대길일 목록
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(children: [
              const KoreanSectionTitle(title: '이달 推薦 이사일', showDivider: false),
              const Spacer(),
              Text('총 ${_luckyDays.length}일',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ]),
          ),
          ..._luckyDays.take(8).map((d) => _buildDayListTile(d)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildContractTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Text(
            '계약서 작성, 잔금 지급 등 부동산 계약에 좋은 날입니다.\n손 없는 날과 사주 길일을 우선으로 추천합니다.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
          ),
        ),
        const SizedBox(height: 16),
        ..._contractDays.map((d) => _buildDayListTile(d)),
      ],
    );
  }

  Widget _buildSelectedDayDetail(DateTime day) {
    final result = _getDayResult(day);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.month}월 ${day.day}일 (${_weekdayLabel(day.weekday)})',
            style: const TextStyle(
              fontFamily: 'NotoSerifKR',
              fontSize: 16, fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (result != null) ...[
            Text(result.grade, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              result.reasons.join(' · '),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '일진: ${result.dayGanJi}',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ] else
            const Text('특별한 길일이 아닌 날입니다.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildDayListTile(LuckyDayResult d) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: d.isSonNone
                ? Colors.amber.withOpacity(0.15)
                : AppColors.primaryLight.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${d.date.day}',
              style: TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 16, fontWeight: FontWeight.bold,
                color: d.isSonNone ? Colors.amber : AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${d.date.month}월 ${d.date.day}일 (${_weekdayLabel(d.date.weekday)})',
              style: const TextStyle(
                fontFamily: 'NotoSerifKR',
                fontSize: 14, fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              d.reasons.join(' · '),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
        ),
        Text(
          d.grade,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ]),
    );
  }

  String _weekdayLabel(int w) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[w - 1];
  }

  String _oehaengHanja(String oe) {
    const m = {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'};
    return m[oe] ?? oe;
  }
}
