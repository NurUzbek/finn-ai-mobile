import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Hisobotlar ekrani — soliq hisobotlari va muddatlar.
/// PUSH ekran: FinnScreen (showNav:false) + tokens + FinnText.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.asTab = false});
  /// true — pastki nav tab'i (TZ "Ma'lumotlar" moduli), orqaga tugmasi yo'q.
  final bool asTab;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _Cat { submitted, overdue, pending }

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<Map<String, dynamic>> _f = Api.reports();

  Future<void> _refresh() async => setState(() => _f = Api.reports());

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
    final t = context.tokens;
    final now = DateTime.now();
    final q = ((now.month - 1) ~/ 3) + 1;

    return FinnScreen(
      title: widget.asTab ? tr('nav.data') : tr('rep.title'),
      subtitle: tr('rep.subtitle')
          .replaceFirst('{year}', '${now.year}')
          .replaceFirst('{q}', '$q'),
      showNav: false,
      reserveNav: widget.asTab,
      leading: widget.asTab
          ? null
          : _iconBtn(t, Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop()),
      actions: [
        _iconBtn(t, Icons.refresh_rounded, onTap: _refresh),
      ],
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final d = snap.data ?? {};
            if (d['ok'] != true) return _err(t);
            return _content(t, d, now, q);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d, DateTime now, int q) {
    final raw = d['reports'];
    final reports = <Map<String, dynamic>>[
      if (raw is List)
        for (final e in raw)
          if (e is Map) e.map((k, v) => MapEntry(k.toString(), v)),
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
    final progress = (elapsed / totalDays).clamp(0.0, 1.0).toDouble();

    var i = 0;
    final children = <Widget>[
      const SizedBox(height: 12),
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
      children.add(_Eyebrow(tr('rep.eyebrowPending')));
      for (final r in pending) {
        children.add(StaggerIn(
          index: i++,
          child: _ReportRow(report: r, cat: _cat(_s(r['status']))),
        ));
      }
    }

    if (submitted.isNotEmpty) {
      children.add(_Eyebrow(tr('rep.eyebrowSubmitted')));
      for (final r in submitted) {
        children.add(StaggerIn(
          index: i++,
          child: _ReportRow(report: r, cat: _Cat.submitted),
        ));
      }
    }

    if (reports.isEmpty) {
      children.add(_empty(t));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _empty(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: t.tBlu, shape: BoxShape.circle),
              child: Icon(Icons.insert_chart_outlined_rounded,
                  size: 32, color: t.blue),
            ),
            const SizedBox(height: 16),
            Text(tr('rep.empty'),
                textAlign: TextAlign.center, style: FinnText.body(t.ink3)),
          ]),
        ),
      );

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('rep.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('rep.retry'))),
          ]),
        ),
      );

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );
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
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('rep.quarterEndsIn'), style: FinnText.label(t.ink3)),
          const SizedBox(height: 8),
          // .val — proto: font-size:30px (bir xil), Inter Tight 700.
          Text(
            '${remaining < 0 ? 0 : remaining} ${tr('rep.days')}',
            style: FinnText.heroValue(t.ink)
                .copyWith(fontSize: 30, letterSpacing: -1.35),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Stack(children: [
                Positioned.fill(child: ColoredBox(color: t.key)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 850),
                  curve: FinnTokens.ease,
                  builder: (_, v, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v <= 0 ? 0.001 : v,
                    child: ColoredBox(color: t.blue),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? tr('rep.empty')
                : tr('rep.summaryCount')
                    .replaceFirst('{total}', '$total')
                    .replaceFirst('{done}', '$submitted'),
            style: FinnText.rowSub(t.ink3),
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
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(children: [
        Text(text.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: t.line)),
      ]),
    );
  }
}

/// Bitta hisobot qatori (.row) — ikonka + sarlavha + muddat + holat pili.
class _ReportRow extends StatelessWidget {
  final Map<String, dynamic> report;
  final _Cat cat;
  const _ReportRow({required this.report, required this.cat});

  String _s(dynamic v) => v == null ? '' : v.toString();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final title = trReport(_s(report['title']));
    final type = trReport(_s(report['type']));
    final date = _s(report['date']);
    final status = _s(report['status']);

    late final Color tint;
    late final Color onColor;
    late final IconData icon;
    late final String pillDefault;
    switch (cat) {
      case _Cat.submitted:
        tint = t.tGrn;
        onColor = t.onGrn;
        icon = Icons.check_rounded;
        pillDefault = tr('rep.pillAccepted');
        break;
      case _Cat.overdue:
        tint = t.tRed;
        onColor = t.onRed;
        icon = Icons.priority_high_rounded;
        pillDefault = tr('rep.pillOverdue');
        break;
      case _Cat.pending:
        tint = t.tAmb;
        onColor = t.onAmb;
        icon = Icons.show_chart_rounded;
        pillDefault = tr('rep.pillPending');
        break;
    }

    final subtitle = cat == _Cat.submitted
        ? (date.isNotEmpty
            ? tr('rep.submittedOn').replaceFirst('{date}', date)
            : tr('rep.submittedShort'))
        : (type.isNotEmpty
            ? type
            : (date.isNotEmpty
                ? tr('rep.deadline').replaceFirst('{date}', date)
                : tr('rep.noDeadline')));

    // Holatni joriy tilga o'giramiz (accepted/pending/submitted…). Topilmasa — pillDefault.
    final raw = status.trim();
    var pillText = raw.isEmpty ? pillDefault : trStatus(raw);
    if (pillText == raw && raw.isNotEmpty) {
      pillText = raw[0].toUpperCase() + raw.substring(1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint,
              // proto: .row .m border-radius:12px
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
                  title.isEmpty ? tr('rep.reportFallback') : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FinnText.rowTitle(t.ink),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FinnText.rowSub(t.ink3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Pill(text: pillText, tint: tint, on: onColor),
        ],
      ),
    );
  }
}

/// Holat pili (.pill p-*).
class _Pill extends StatelessWidget {
  final String text;
  final Color tint;
  final Color on;
  const _Pill({required this.text, required this.tint, required this.on});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(FinnTokens.rLg),
        ),
        child: Text(text, style: FinnText.pill(on)),
      );
}
