import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Ish kalendari — yillik ish kunlari, dam olish, bayram va yaqin muddatlar.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _monthsFull = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
  ];
  static const _dowShort = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  final int _year = DateTime.now().year;
  late Future<Map<String, dynamic>> _future;
  int _selectedMonth = DateTime.now().month; // 1-12

  @override
  void initState() {
    super.initState();
    _future = Api.calendar(year: _year);
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.calendar(year: _year));
    await _future;
  }

  int _asInt(dynamic v, [int def = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? def;
    return def;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: 'Ish kalendari',
            icon: Icons.calendar_month_rounded,
            subtitle: '${_monthsFull[_selectedMonth - 1]} $_year',
            action: _monthNav(context),
          ),
          Expanded(
            child: Loader(
              future: _future,
              onRefresh: _refresh,
              builder: (d) => _content(context, d),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _monthNav(BuildContext context) {
    Widget btn(IconData icon, VoidCallback? onTap) => GestureDetector(
          onTap: onTap,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: C.fill(context, C.isDark(context) ? .06 : .04),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: C.border(context)),
            ),
            child: Icon(icon, size: 18,
                color: onTap == null ? C.muted(context, .25) : C.text(context)),
          ),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.chevron_left_rounded,
          _selectedMonth > 1 ? () => setState(() => _selectedMonth--) : null),
      const SizedBox(width: 8),
      btn(Icons.chevron_right_rounded,
          _selectedMonth < 12 ? () => setState(() => _selectedMonth++) : null),
    ]);
  }

  Widget _content(BuildContext context, Map<String, dynamic> d) {
    final rawMonths = (d['months'] as List?) ?? const [];
    final byMonth = <int, Map<String, dynamic>>{};
    for (final m in rawMonths) {
      if (m is Map) {
        final mm = Map<String, dynamic>.from(m);
        byMonth[_asInt(mm['month'])] = mm;
      }
    }

    final current = byMonth[_selectedMonth];
    final days = <Map<String, dynamic>>[];
    for (final x in (current?['days'] as List?) ?? const []) {
      if (x is Map) days.add(Map<String, dynamic>.from(x));
    }

    final deadlines = days.where((x) {
      final note = x['note']?.toString();
      return note != null && note.trim().isNotEmpty;
    }).toList()
      ..sort((a, b) => _asInt(a['day']).compareTo(_asInt(b['day'])));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        StaggerIn(index: 0, child: _calendarCard(context, current, days)),
        const SizedBox(height: 22),
        _eyebrow(context, 'Yaqin muddatlar'),
        const SizedBox(height: 10),
        if (deadlines.isEmpty)
          const EmptyState(
              icon: Icons.event_available_rounded,
              text: 'Bu oyda muddat yo\'q',
              color: C.green)
        else
          ...List.generate(deadlines.length, (i) {
            return StaggerIn(
              index: i + 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _deadlineRow(context, deadlines[i]),
              ),
            );
          }),
      ],
    );
  }

  Widget _calendarCard(
      BuildContext context, Map<String, dynamic>? month, List<Map<String, dynamic>> days) {
    final workdays = _asInt(month?['workdays']);
    final normHours = _asInt(month?['norm_hours']);

    // Leading empty cells: first day-of-week (1=Mon..7=Sun) -> (dow-1) blanks.
    int leading = 0;
    if (days.isNotEmpty) {
      leading = (_asInt(days.first['dow'], 1).clamp(1, 7)) - 1;
    }

    final cells = <Widget>[];
    for (int i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (final day in days) {
      cells.add(_dayCell(context, day));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Day-of-week header
        Row(
          children: List.generate(7, (i) {
            final weekend = i >= 5;
            return Expanded(
              child: Center(
                child: Text(
                  _dowShort[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: weekend ? C.muted(context, .35) : C.muted(context, .55),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Center(
              child: Text('Ma\'lumot yo\'q',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context, .45))),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: cells,
          ),
        const SizedBox(height: 16),
        // Legend
        Wrap(spacing: 16, runSpacing: 8, children: [
          _legendItem(context, C.red, 'Soliq'),
          _legendItem(context, C.amber, 'Hisobot'),
          _legendItem(context, C.blue, 'Ichki'),
        ]),
        const SizedBox(height: 14),
        // Ish kunlari / norma
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: C.fill(context, C.isDark(context) ? .05 : .04),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.work_outline_rounded, size: 15, color: C.muted(context, .6)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Ish kunlari: $workdays  ·  Norma: $normHours soat',
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, color: C.text(context)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: C.muted(context, .7))),
    ]);
  }

  Widget _dayCell(BuildContext context, Map<String, dynamic> day) {
    final num = _asInt(day['day']);
    final dow = _asInt(day['dow'], 1);
    final holiday = _asBool(day['holiday']);
    final note = day['note']?.toString();
    final hasNote = note != null && note.trim().isNotEmpty;
    final weekend = dow >= 6;
    final isToday = num == DateTime.now().day &&
        _selectedMonth == DateTime.now().month &&
        _year == DateTime.now().year;

    Color fg;
    if (isToday) {
      fg = Colors.white;
    } else if (holiday) {
      fg = C.red;
    } else if (weekend) {
      fg = C.muted(context, .4);
    } else {
      fg = C.text(context);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: isToday ? const LinearGradient(colors: [C.blue, C.cyan]) : null,
        color: !isToday && holiday ? C.red.withValues(alpha: .14) : null,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$num',
            style: TextStyle(
              fontSize: 13,
              fontWeight: (holiday || isToday) ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
          if (hasNote)
            Positioned(
              bottom: 5,
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.white
                      : (holiday ? C.red : C.amber),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deadlineRow(BuildContext context, Map<String, dynamic> day) {
    final num = _asInt(day['day']);
    final holiday = _asBool(day['holiday']);
    final note = day['note']?.toString() ?? '';
    final color = holiday ? C.red : C.amber;
    final onColor = holiday ? C.onRed(context) : C.onAmb(context);

    // Kunlar farqi (bugundan)
    final today = DateTime.now();
    final target = DateTime(_year, _selectedMonth, num);
    final diff = target.difference(DateTime(today.year, today.month, today.day)).inDays;
    String pillText;
    if (diff == 0) {
      pillText = 'Bugun';
    } else if (diff > 0) {
      pillText = '$diff kun';
    } else {
      pillText = 'O\'tdi';
    }
    final pillColor = diff < 0 ? C.muted(context, .5) : color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.tint(context, color),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text('$num',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: onColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800, color: C.text(context))),
            const SizedBox(height: 2),
            Text('${_monthsFull[_selectedMonth - 1]} $num, $_year',
                style: TextStyle(fontSize: 12, color: C.muted(context, .5))),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: pillColor.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(pillText,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800, color: pillColor)),
        ),
      ]),
    );
  }

  Widget _eyebrow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: Row(children: [
        Text(text,
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .2,
                color: C.muted(context, .6))),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: C.border(context))),
      ]),
    );
  }
}
