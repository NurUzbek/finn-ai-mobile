import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../widgets/add_forms.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Kirim va chiqim (Moliya). TZ "Monitoring" moduli — pastki nav tab'i (asTab).
class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key, this.asTab = false});
  /// true — pastki nav tab'i sifatida (orqaga tugmasi yo'q, TZ nomi bilan).
  final bool asTab;

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  // Diagramma namunasi (tr kaliti, kirim %, chiqim %) — proto `.bars` bilan bir xil.
  static const _series = [
    ['fin.bar.3', 34, 26], ['fin.bar.4', 42, 30], ['fin.bar.5', 38, 36],
    ['fin.bar.6', 52, 32], ['fin.bar.7', 46, 40], ['fin.bar.8', 58, 42],
  ];

  late Future<Map<String, dynamic>> _future;
  int _period = 0; // 0 Oy, 1 Chorak, 2 Yil

  @override
  void initState() {
    super.initState();
    _future = Api.financial();
  }

  Future<void> _reload() async {
    setState(() => _future = Api.financial());
    await _future;
  }

  String get _monthLabel {
    final now = DateTime.now();
    return '${tr('fin.mon.${now.month}')} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: widget.asTab ? tr('nav.monitoring') : tr('fin.title'),
      subtitle: _monthLabel,
      showNav: false,
      reserveNav: widget.asTab,
      leading: widget.asTab
          ? null
          : _iconBtn(t, Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop()),
      actions: [
        _iconBtn(t, Icons.add_rounded, onTap: () async {
          if (await showAddFinancial(context)) _reload();
        }),
      ],
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

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final summary =
        (d['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final income = (summary['income'] as num?)?.toDouble() ?? 0;
    final expense = (summary['expense'] as num?)?.toDouble() ?? 0;
    final net = (summary['net'] as num?)?.toDouble() ?? (income - expense);

    final ops = (d['operations'] as List?)
            ?.whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList() ??
        const <Map<String, dynamic>>[];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StaggerIn(index: 0, child: _chips(t)),
        const SizedBox(height: 14),
        StaggerIn(index: 1, child: _summaryCard(t, income, expense, net)),
        StaggerIn(index: 2, child: _eyebrow(t, tr('fin.recentOps'), action: tr('fin.all'))),
        if (ops.isEmpty)
          StaggerIn(
            index: 3,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                color: t.green,
                text: tr('fin.empty'),
              ),
            ),
          )
        else
          for (int i = 0; i < ops.length; i++) ...[
            StaggerIn(index: 3 + i, child: _opRow(t, ops[i])),
            if (i != ops.length - 1)
              const SizedBox(height: FinnTokens.gapList),
          ],
      ],
    );
  }

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('fin.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: Text(tr('common.retry'))),
          ]),
        ),
      );

  // ── Sarlavha tugmasi (.iconbtn / .back): 36×36, radius 12 ───────
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
            border: Border.all(color: t.line, width: 1),
          ),
          child: Icon(ic, size: 18, color: t.ink2),
        ),
      );

  // ── Segmentlar (.chips / .chip) ─────────────────────────────────
  Widget _chips(FinnTokens t) {
    final labels = [tr('fin.month'), tr('fin.quarter'), tr('fin.year')];
    return Row(children: [
      for (int i = 0; i < labels.length; i++) ...[
        _chip(t, labels[i], i == _period, () => setState(() => _period = i)),
        if (i != labels.length - 1) const SizedBox(width: 8),
      ],
    ]);
  }

  Widget _chip(FinnTokens t, String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: FinnTokens.ease,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? t.blue : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? t.blue : t.line),
        ),
        child: Text(
          label,
          style: on
              ? FinnText.chip(Colors.white).copyWith(fontWeight: FontWeight.w600)
              : FinnText.chip(t.ink2),
        ),
      ),
    );
  }

  // ── Xulosa kartasi (.card) ──────────────────────────────────────
  Widget _summaryCard(FinnTokens t, double income, double expense, double net) {
    final netPos = net >= 0;
    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _sumCol(t, tr('fin.income'), income, t.onGrn)),
          Container(
              width: 1,
              height: 44,
              color: t.line,
              margin: const EdgeInsets.symmetric(horizontal: 14)),
          Expanded(child: _sumCol(t, tr('fin.expense'), expense, t.onRed)),
        ]),
        // .bars — margin-top:16
        _bars(t),
        // .legend — margin-top:14
        const SizedBox(height: 14),
        Row(children: [
          _legend(t, t.green, tr('fin.income')),
          const SizedBox(width: 16),
          _legend(t, t.red, tr('fin.expense')),
        ]),
        // .meta — margin-top:8
        const SizedBox(height: 8),
        Text(
          '${tr('fin.netProfit')}: ${netPos ? '+' : '−'}${money(net.abs())} ${tr('common.som')}',
          style: FinnText.rowSub(netPos ? t.onGrn : t.onRed)
              .copyWith(fontSize: 12),
        ),
      ]),
    );
  }

  // .lab + .val (font-size:22)
  Widget _sumCol(FinnTokens t, String label, double value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: FinnText.label(t.ink3)),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          money(value),
          style: FinnText.bigValue(color)
              .copyWith(fontSize: 22, letterSpacing: -0.99),
        ),
      ),
    ]);
  }

  // .bars — balandligi 96px, ustunlar orasida 6, ichida 3, em ostida 6
  Widget _bars(FinnTokens t) {
    const base = 96.0;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: base + 22,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (int i = 0; i < _series.length; i++)
              Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: i == _series.length - 1 ? 0 : 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _bar((_series[i][1] as int) / 100 * base, t.green),
                      const SizedBox(height: 3),
                      _bar((_series[i][2] as int) / 100 * base, t.red),
                      const SizedBox(height: 6),
                      Text(tr(_series[i][0] as String),
                          textAlign: TextAlign.center,
                          style: FinnText.rowSub(t.ink3)
                              .copyWith(fontSize: 9.5)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double h, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: FinnTokens.spring,
      builder: (_, v, __) => Container(
        height: h * v,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  // .legend div — nuqta 8×8 + matn 12px ink-2
  Widget _legend(FinnTokens t, Color color, String label) {
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

  // ── Bo'lim sarlavhasi (.eyebrow) ────────────────────────────────
  Widget _eyebrow(FinnTokens t, String label,
          {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
          if (action != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text(action,
                  style: FinnText.pill(t.blue).copyWith(fontSize: 12)),
            ),
          ],
        ]),
      );

  // ── Operatsiya qatori (.row) ────────────────────────────────────
  Widget _opRow(FinnTokens t, Map<String, dynamic> op) {
    final isIncome = (op['type']?.toString() ?? 'expense') == 'income';
    final onColor = isIncome ? t.onGrn : t.onRed;
    final tint = isIncome ? t.tGrn : t.tRed;
    final amount = (op['amount'] as num?)?.toDouble() ?? 0;
    final category = op['category']?.toString() ?? '';
    final description = op['description']?.toString() ?? '';
    final date = op['date']?.toString() ?? '';

    final String title;
    final List<String> subParts;
    // "Operatsiya #N" tavsifidagi so'zni ham joriy tilga o'giramiz.
    final locDesc = description.replaceFirst('Operatsiya', tr('fin.operation'));
    if (category.isNotEmpty) {
      title = trTxnCat(category);
      subParts = [locDesc, date];
    } else {
      title = locDesc.isNotEmpty ? locDesc : tr('fin.operation');
      subParts = [date];
    }
    final sub = subParts.where((e) => e.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(children: [
        // .row .m — 38×38, radius 12
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.north_rounded : Icons.south_rounded,
            color: onColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FinnText.rowTitle(t.ink)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FinnText.rowSub(t.ink3)),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        Text(
          '${isIncome ? '+' : '−'}${money(amount)}',
          style: FinnText.rowValue(onColor),
        ),
      ]),
    );
  }
}
