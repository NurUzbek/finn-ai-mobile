import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Hisobotlar ekrani — soliq hisobotlari va muddatlar (dizayn: v-hisobot).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _Cat { submitted, overdue, pending }

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.reports();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.reports());
    await _future;
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  _Cat _cat(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'topshirilgan' ||
        s == 'submitted' ||
        s == 'done' ||
        s == 'qabul' ||
        s == 'accepted' ||
        s == 'sent' ||
        s == 'tayyor') {
      return _Cat.submitted;
    }
    if (s == 'overdue' ||
        s == 'kechikkan' ||
        s == 'rad' ||
        s == 'rad etilgan' ||
        s.contains("muddati o'tgan")) {
      return _Cat.overdue;
    }
    return _Cat.pending;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final q = ((now.month - 1) ~/ 3) + 1;

    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Hisobotlar',
              subtitle: '${now.year}-yil · $q-chorak',
              icon: Icons.description_rounded,
            ),
            Expanded(
              child: Loader(
                future: _future,
                onRefresh: _refresh,
                builder: (data) {
                  final raw = data['reports'];
                  final reports = <Map<String, dynamic>>[
                    if (raw is List)
                      for (final e in raw)
                        if (e is Map)
                          e.map((k, v) => MapEntry(k.toString(), v)),
                  ];

                  final submitted = <Map<String, dynamic>>[];
                  final pending = <Map<String, dynamic>>[];
                  for (final r in reports) {
                    if (_cat(_s(r['status'])) == _Cat.submitted) {
                      submitted.add(r);
                    } else {
                      pending.add(r);
                    }
                  }

                  // Chorak muddati hisob-kitobi.
                  final qStart = DateTime(now.year, (q - 1) * 3 + 1, 1);
                  final qEnd = DateTime(now.year, q * 3 + 1, 1);
                  final totalDays = qEnd.difference(qStart).inDays;
                  final elapsed = now.difference(qStart).inDays;
                  final remaining = qEnd.difference(now).inDays;
                  final progress =
                      (elapsed / totalDays).clamp(0.0, 1.0).toDouble();

                  var i = 0;
                  final children = <Widget>[
                    const SizedBox(height: 4),
                    StaggerIn(
                      index: i++,
                      child: _SummaryCard(
                        remaining: remaining,
                        progress: progress,
                        total: reports.length,
                        submitted: submitted.length,
                      ),
                    ),
                  ];

                  if (pending.isNotEmpty) {
                    children.add(const _Eyebrow('Topshirilishi kerak'));
                    for (final r in pending) {
                      children.add(StaggerIn(
                        index: i++,
                        child: _ReportRow(report: r, cat: _cat(_s(r['status']))),
                      ));
                    }
                  }

                  if (submitted.isNotEmpty) {
                    children.add(const _Eyebrow('Topshirilgan'));
                    for (final r in submitted) {
                      children.add(StaggerIn(
                        index: i++,
                        child: _ReportRow(report: r, cat: _Cat.submitted),
                      ));
                    }
                  }

                  if (reports.isEmpty) {
                    children.add(const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(
                        icon: Icons.insert_chart_outlined_rounded,
                        color: C.blue,
                        text: 'Hozircha hisobot yo\'q',
                      ),
                    ));
                  }

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    children: children,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yuqoridagi umumiy karta — chorak yakuniga qolgan kunlar + progress.
class _SummaryCard extends StatelessWidget {
  final int remaining;
  final double progress;
  final int total;
  final int submitted;
  const _SummaryCard({
    required this.remaining,
    required this.progress,
    required this.total,
    required this.submitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHORAK YAKUNLANISHIGA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${remaining < 0 ? 0 : remaining} kun',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              height: 1,
              color: C.text(context),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              color: C.fill(context, .06),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v <= 0 ? 0.001 : v,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: C.blue,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total == 0
                ? 'Hozircha hisobot yo\'q'
                : '$total tadan $submitted tasi topshirilgan',
            style: TextStyle(fontSize: 12, color: C.muted(context, .45)),
          ),
        ],
      ),
    );
  }
}

/// Bo'lim sarlavhasi — matn + ajratuvchi chiziq (.eyebrow).
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(
          children: [
            Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: C.muted(context, .45),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Container(height: 1, color: C.border(context))),
          ],
        ),
      );
}

/// Bitta hisobot qatori (.row) — ikonka + sarlavha + muddat + holat pili.
class _ReportRow extends StatelessWidget {
  final Map<String, dynamic> report;
  final _Cat cat;
  const _ReportRow({required this.report, required this.cat});

  String _s(dynamic v) => v == null ? '' : v.toString();

  @override
  Widget build(BuildContext context) {
    final title = _s(report['title']);
    final type = _s(report['type']);
    final date = _s(report['date']);
    final status = _s(report['status']);

    late final Color accent;
    late final Color onColor;
    late final IconData icon;
    late final String pillDefault;
    switch (cat) {
      case _Cat.submitted:
        accent = C.green;
        onColor = C.onGrn(context);
        icon = Icons.check_rounded;
        pillDefault = 'Qabul';
        break;
      case _Cat.overdue:
        accent = C.red;
        onColor = C.onRed(context);
        icon = Icons.priority_high_rounded;
        pillDefault = 'Muddati o\'tgan';
        break;
      case _Cat.pending:
        accent = C.amber;
        onColor = C.onAmb(context);
        icon = Icons.insert_chart_outlined_rounded;
        pillDefault = 'Jarayonda';
        break;
    }

    final subtitle = cat == _Cat.submitted
        ? (date.isNotEmpty ? '$date da topshirilgan' : 'Topshirilgan')
        : (type.isNotEmpty
            ? type
            : (date.isNotEmpty ? 'Muddat: $date' : 'Muddat belgilanmagan'));

    var pillText = status.trim();
    if (pillText.isEmpty) {
      pillText = pillDefault;
    } else {
      pillText = pillText[0].toUpperCase() + pillText.substring(1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: C.tint(context, accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: onColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Hisobot' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: C.text(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .45)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Pill(text: pillText, color: accent, on: onColor),
        ],
      ),
    );
  }
}

/// Holat pili (.pill p-*).
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color on;
  const _Pill({required this.text, required this.color, required this.on});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: C.tint(context, color),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: on,
          ),
        ),
      );
}
