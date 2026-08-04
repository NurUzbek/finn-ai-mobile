import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Ish kalendari — yillik ish kunlari, dam olish va bayramlar.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _monthsShort = [
    'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn',
    'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek',
  ];
  static const _dowShort = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];

  late Future<Map<String, dynamic>> _future;
  int _selectedMonth = DateTime.now().month; // 1-12

  @override
  void initState() {
    super.initState();
    _future = Api.calendar();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.calendar());
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (ctx, snap) {
            final year = snap.hasData ? _asInt(snap.data!['year'], DateTime.now().year) : DateTime.now().year;
            return Column(
              children: [
                _appBar(context, year),
                Expanded(child: _body(ctx, snap)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _appBar(BuildContext context, int year) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.blue, C.cyan]),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ish kalendari',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: C.text(context))),
            Text('$year-yil', style: TextStyle(fontSize: 12, color: C.muted(context, .5))),
          ]),
        ),
      ]),
    );
  }

  Widget _body(BuildContext context, AsyncSnapshot<Map<String, dynamic>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: C.cyan));
    }
    final d = snap.data ?? {'ok': false};
    if (d['ok'] != true) {
      return RefreshIndicator(
        color: C.cyan,
        backgroundColor: C.card(context),
        onRefresh: _refresh,
        child: ListView(children: [
          SizedBox(height: MediaQuery.of(context).size.height * .55, child: Center(child: _errorState(context))),
        ]),
      );
    }

    final rawMonths = (d['months'] as List?) ?? const [];
    if (rawMonths.isEmpty) {
      return RefreshIndicator(
        color: C.cyan,
        backgroundColor: C.card(context),
        onRefresh: _refresh,
        child: ListView(children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .55,
            child: const Center(child: EmptyState(icon: Icons.event_busy_rounded, text: 'Kalendar yo\'q', color: C.amber)),
          ),
        ]),
      );
    }

    // month(1-12) -> data map
    final byMonth = <int, Map<String, dynamic>>{};
    for (final m in rawMonths) {
      if (m is Map) {
        final mm = Map<String, dynamic>.from(m);
        byMonth[_asInt(mm['month'])] = mm;
      }
    }

    if (!byMonth.containsKey(_selectedMonth)) {
      _selectedMonth = byMonth.keys.reduce((a, b) => a < b ? a : b);
    }
    final current = byMonth[_selectedMonth];

    return RefreshIndicator(
      color: C.cyan,
      backgroundColor: C.card(context),
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _monthChips(context, byMonth),
          const SizedBox(height: 16),
          if (current != null) StaggerIn(index: 0, child: _monthCard(context, current)),
        ],
      ),
    );
  }

  Widget _monthChips(BuildContext context, Map<int, Map<String, dynamic>> byMonth) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final month = i + 1;
          final available = byMonth.containsKey(month);
          final selected = month == _selectedMonth;
          return GestureDetector(
            onTap: available ? () => setState(() => _selectedMonth = month) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: selected ? const LinearGradient(colors: [C.blue, C.cyan]) : null,
                color: selected ? null : C.fill(context, C.isDark(context) ? .05 : .04),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                _monthsShort[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? Colors.white
                      : (available ? C.text(context) : C.muted(context, .3)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _monthCard(BuildContext context, Map<String, dynamic> month) {
    final monthNum = _asInt(month['month']);
    final workdays = _asInt(month['workdays']);
    final normHours = _asInt(month['norm_hours']);

    final rawDays = (month['days'] as List?) ?? const [];
    final days = <Map<String, dynamic>>[];
    for (final x in rawDays) {
      if (x is Map) days.add(Map<String, dynamic>.from(x));
    }

    // Leading empty cells: dow of the first day (1=Mon..7=Sun) -> (dow-1) empty cells.
    int leading = 0;
    if (days.isNotEmpty) {
      final firstDow = _asInt(days.first['dow'], 1).clamp(1, 7);
      leading = firstDow - 1;
    }

    final cells = <Widget>[];
    for (int i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (final day in days) {
      cells.add(_dayCell(context, day));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (C.isDark(context) ? Colors.black : const Color(0xFF1B2A4A))
                .withValues(alpha: C.isDark(context) ? .25 : .06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            monthNum >= 1 && monthNum <= 12 ? _monthsShort[monthNum - 1] : '—',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: C.text(context)),
          ),
        ),
        // Dow headers
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
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: cells,
        ),
        const SizedBox(height: 16),
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
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: C.text(context)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _dayCell(BuildContext context, Map<String, dynamic> day) {
    final num = _asInt(day['day']);
    final dow = _asInt(day['dow'], 1);
    final holiday = _asBool(day['holiday']);
    final note = day['note']?.toString();
    final weekend = dow >= 6;

    Color bg;
    Color fg;
    if (holiday) {
      bg = C.red.withValues(alpha: .14);
      fg = C.red;
    } else if (weekend) {
      bg = Colors.transparent;
      fg = C.muted(context, .4);
    } else {
      bg = Colors.transparent;
      fg = C.text(context);
    }

    final cell = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$num',
            style: TextStyle(
              fontSize: 13,
              fontWeight: holiday ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
          if (note != null && note.isNotEmpty)
            Positioned(
              bottom: 5,
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: holiday ? C.red : C.cyan,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    if (note != null && note.isNotEmpty) {
      return Tooltip(message: note, child: cell);
    }
    return cell;
  }

  Widget _errorState(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: C.red.withValues(alpha: .1), shape: BoxShape.circle),
        child: const Icon(Icons.cloud_off_rounded, size: 32, color: C.red),
      ),
      const SizedBox(height: 16),
      Text('Server bilan aloqa yo\'q',
          textAlign: TextAlign.center, style: TextStyle(color: C.muted(context, .6), fontSize: 13.5)),
      const SizedBox(height: 16),
      TextButton.icon(
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded, size: 18, color: C.cyan),
        label: const Text('Qayta urinish', style: TextStyle(color: C.cyan, fontWeight: FontWeight.w800)),
      ),
    ]);
  }
}
