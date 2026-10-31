import 'package:flutter/material.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/common.dart' show StaggerIn;

/// Ish kalendari — HTML prototip (`#v-kalendar`) bilan 1:1.
///
/// Karta: hafta kunlari + oy to'ri + izoh. So'ng "Yaqin muddatlar" ro'yxati.
/// FINN dizayn tizimi (FinnScreen + tokens + FinnText). PUSH ekran.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Oy nomi (1-12) va hafta kuni (1=Du..7=Ya) — joriy tilga tarjima qilinadi.
  String _monthName(int m) => tr('cal.mon.$m');
  String _dowName(int dow) => tr('cal.dow.$dow');

  final int _year = DateTime.now().year;
  final int _month = DateTime.now().month; // joriy oy (1-12)
  late Future<Map<String, dynamic>> _future = Api.calendar(year: _year);

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
    final t = context.tokens;
    return FinnScreen(
      govSources: true,
      title: tr('cal.title'),
      subtitle: '${_monthName(_month)} $_year',
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context)),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final d = snap.data ?? {};
            if (d['ok'] != true) return _err(t);
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('cal.errLoad'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('cal.retry'))),
          ]),
        ),
      );

  // Prototip .back / .iconbtn: 36×36, radius 12, chegara, kart fon, soyasiz.
  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Icon(ic, size: 18, color: t.ink2),
        ),
      );

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final rawMonths = (d['months'] as List?) ?? const [];
    final byMonth = <int, Map<String, dynamic>>{};
    for (final m in rawMonths) {
      if (m is Map) {
        final mm = Map<String, dynamic>.from(m);
        byMonth[_asInt(mm['month'])] = mm;
      }
    }

    final current = byMonth[_month];
    final days = <Map<String, dynamic>>[];
    for (final x in (current?['days'] as List?) ?? const []) {
      if (x is Map) days.add(Map<String, dynamic>.from(x));
    }

    final deadlines = days.where((x) {
      final note = x['note']?.toString();
      return note != null && note.trim().isNotEmpty;
    }).toList()
      ..sort((a, b) => _asInt(a['day']).compareTo(_asInt(b['day'])));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StaggerIn(index: 0, child: _calendarCard(t, days)),
        _eyebrow(t, tr('cal.upcoming')),
        if (deadlines.isEmpty)
          _emptyDeadlines(t)
        else
          ...List.generate(deadlines.length, (i) {
            return StaggerIn(
              index: i + 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: FinnTokens.gapList),
                child: _deadlineRow(t, deadlines[i]),
              ),
            );
          }),
      ],
    );
  }

  Widget _calendarCard(FinnTokens t, List<Map<String, dynamic>> days) {
    // Boshdagi bo'sh kataklar: oyning 1-kuni hafta kuni (1=Du..7=Ya) -> (dow-1).
    int leading = 0;
    if (days.isNotEmpty) {
      leading = (_asInt(days.first['dow'], 1).clamp(1, 7)) - 1;
    }
    // Oldingi oyning oxirgi kunlari (xira ko'rsatiladi).
    final prevMonthDays = DateTime(_year, _month, 0).day;

    final cells = <Widget>[];
    for (int i = 0; i < leading; i++) {
      cells.add(_muteCell(t, prevMonthDays - leading + 1 + i));
    }
    for (final day in days) {
      cells.add(_dayCell(t, day));
    }

    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 14), // .cal margin-top
        // Hafta kunlari sarlavhasi (prototipda barchasi bir xil: ink-3)
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Center(
                child: Text(
                  _dowName(i + 1),
                  style: FinnText.rowSub(t.ink3)
                      .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10), // .dow padding-bottom + .cal gap
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Center(
              child: Text(tr('cal.noData'), style: FinnText.rowSub(t.ink3)),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            padding: EdgeInsets.zero,
            children: cells,
          ),
        const SizedBox(height: 16), // .legend margin-top
        // Izoh
        Wrap(spacing: 16, runSpacing: 8, children: [
          _legendItem(t, t.red, tr('cal.legendTax')),
          _legendItem(t, t.amber, tr('cal.legendReport')),
          _legendItem(t, t.blue, tr('cal.legendInternal')),
        ]),
      ]),
    );
  }

  Widget _legendItem(FinnTokens t, Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(label, style: FinnText.rowSub(t.ink2).copyWith(fontSize: 12)),
    ]);
  }

  // Oldingi oy kunlari — xira, tanlab bo'lmaydi.
  Widget _muteCell(FinnTokens t, int num) {
    return Center(
      child: Text(
        '$num',
        style: FinnText.rowValue(t.ink4)
            .copyWith(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _dayCell(FinnTokens t, Map<String, dynamic> day) {
    final num = _asInt(day['day']);
    final holiday = _asBool(day['holiday']);
    final note = day['note']?.toString();
    final hasNote = note != null && note.trim().isNotEmpty;
    final now = DateTime.now();
    final isToday =
        num == now.day && _month == now.month && _year == now.year;

    final fg = isToday ? Colors.white : t.ink2;

    return Container(
      decoration: BoxDecoration(
        color: isToday ? t.blue : null,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '$num',
            style: FinnText.rowValue(fg).copyWith(
              fontSize: 13,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          if (hasNote)
            Positioned(
              bottom: 6,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isToday ? Colors.white : (holiday ? t.red : t.amber),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _deadlineRow(FinnTokens t, Map<String, dynamic> day) {
    final num = _asInt(day['day']);
    final holiday = _asBool(day['holiday']);
    final note = day['note']?.toString() ?? '';
    final tint = holiday ? t.tRed : t.tAmb;
    final onColor = holiday ? t.onRed : t.onAmb;

    // Kunlar farqi (bugundan)
    final today = DateTime.now();
    final target = DateTime(_year, _month, num);
    final diff =
        target.difference(DateTime(today.year, today.month, today.day)).inDays;
    String pillText;
    if (diff == 0) {
      pillText = tr('cal.today');
    } else if (diff > 0) {
      pillText = '$diff ${tr('cal.days')}';
    } else {
      pillText = tr('cal.overdue');
    }
    final overdue = diff < 0;
    final pillBg = overdue ? t.key : tint;
    final pillFg = overdue ? t.ink3 : onColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$num',
              style: FinnText.rowValue(onColor).copyWith(fontSize: 12.5)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FinnText.rowTitle(t.ink)),
            const SizedBox(height: 2),
            Text('${_monthName(_month)} $num, $_year',
                style: FinnText.rowSub(t.ink3)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(pillText, style: FinnText.pill(pillFg)),
        ),
      ]),
    );
  }

  Widget _emptyDeadlines(FinnTokens t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_available_rounded, size: 34, color: t.green),
            const SizedBox(height: 12),
            Text(tr('cal.noDeadlines'), style: FinnText.rowSub(t.ink3)),
          ]),
        ),
      );

  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );
}
