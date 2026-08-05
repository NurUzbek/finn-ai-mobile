import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  static const _months = [
    'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun',
    'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr',
  ];
  // Diagramma namunasi (kirim %, chiqim %) — API oylik seriya bermaydi.
  static const _series = [
    ['Mar', 34, 26], ['Apr', 42, 30], ['May', 38, 36],
    ['Iyn', 52, 32], ['Iyl', 46, 40], ['Avg', 58, 42],
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
    return '${_months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: Loader(
                future: _future,
                onRefresh: _reload,
                builder: (d) {
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

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    children: [
                      StaggerIn(index: 0, child: _chips()),
                      const SizedBox(height: 14),
                      StaggerIn(index: 1, child: _summaryCard(income, expense, net)),
                      const SizedBox(height: 24),
                      StaggerIn(index: 2, child: _eyebrow('Oxirgi operatsiyalar', 'Hammasi')),
                      const SizedBox(height: 12),
                      if (ops.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: EmptyState(
                            icon: Icons.receipt_long_rounded,
                            color: C.green,
                            text: 'Hali operatsiya yo\'q',
                          ),
                        )
                      else
                        for (int i = 0; i < ops.length; i++) ...[
                          StaggerIn(index: 3 + i, child: _opRow(ops[i])),
                          if (i != ops.length - 1) const SizedBox(height: 8),
                        ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sarlavha (.hd) ──────────────────────────────────────────────
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
      child: Row(children: [
        _iconBtn(Icons.chevron_left_rounded, () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kirim va chiqim',
                style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                    height: 1.1,
                    color: C.text(context))),
            const SizedBox(height: 3),
            Text(_monthLabel,
                style: TextStyle(fontSize: 12.5, color: C.muted(context, .45))),
          ]),
        ),
        const SizedBox(width: 8),
        _iconBtn(Icons.add_rounded, () {}),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border(context)),
        ),
        child: Icon(icon, size: 22, color: C.muted(context, .7)),
      ),
    );
  }

  // ── Segmentlar (.chips) ─────────────────────────────────────────
  Widget _chips() {
    const labels = ['Oy', 'Chorak', 'Yil'];
    return Row(children: [
      for (int i = 0; i < labels.length; i++) ...[
        _chip(labels[i], i == _period, () => setState(() => _period = i)),
        if (i != labels.length - 1) const SizedBox(width: 8),
      ],
    ]);
  }

  Widget _chip(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? C.brand : C.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? C.brand : C.border(context)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                color: on ? Colors.white : C.muted(context, .7))),
      ),
    );
  }

  // ── Xulosa kartasi (.card) ──────────────────────────────────────
  Widget _summaryCard(double income, double expense, double net) {
    final netPos = net >= 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: _sumCol('Kirim', income, C.onGrn(context))),
          Container(width: 1, height: 44, color: C.border(context), margin: const EdgeInsets.symmetric(horizontal: 14)),
          Expanded(child: _sumCol('Chiqim', expense, C.onRed(context))),
        ]),
        _bars(),
        const SizedBox(height: 14),
        Row(children: [
          _legend('Kirim', C.green),
          const SizedBox(width: 16),
          _legend('Chiqim', C.red),
        ]),
        const SizedBox(height: 12),
        Text(
          'Sof foyda: ${netPos ? '+' : '−'}${money(net.abs())} so\'m',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: netPos ? C.onGrn(context) : C.onRed(context)),
        ),
      ]),
    );
  }

  Widget _sumCol(String label, double value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
              color: C.muted(context, .45))),
      const SizedBox(height: 8),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(money(value),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.9,
                height: 1,
                color: color)),
      ),
    ]);
  }

  Widget _bars() {
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
                  padding: EdgeInsets.only(right: i == _series.length - 1 ? 0 : 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _bar((_series[i][1] as int) / 100 * base, C.green),
                      const SizedBox(height: 3),
                      _bar((_series[i][2] as int) / 100 * base, C.red),
                      const SizedBox(height: 6),
                      Text(_series[i][0] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9.5, color: C.muted(context, .45))),
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
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => Container(
        height: h * t,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, color: C.muted(context, .7))),
    ]);
  }

  // ── Bo'lim sarlavhasi (.eyebrow) ────────────────────────────────
  Widget _eyebrow(String title, String? action) {
    return Row(children: [
      Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: C.muted(context, .45))),
      const SizedBox(width: 12),
      Expanded(child: Container(height: 1, color: C.border(context))),
      if (action != null) ...[
        const SizedBox(width: 12),
        Text(action,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: C.brand)),
      ],
    ]);
  }

  // ── Operatsiya qatori (.row) ────────────────────────────────────
  Widget _opRow(Map<String, dynamic> op) {
    final isIncome = (op['type']?.toString() ?? 'expense') == 'income';
    final onColor = isIncome ? C.onGrn(context) : C.onRed(context);
    final accent = isIncome ? C.green : C.red;
    final amount = (op['amount'] as num?)?.toDouble() ?? 0;
    final category = op['category']?.toString() ?? '';
    final description = op['description']?.toString() ?? '';
    final date = op['date']?.toString() ?? '';

    final String title;
    final List<String> subParts;
    if (category.isNotEmpty) {
      title = category;
      subParts = [description, date];
    } else {
      title = description.isNotEmpty ? description : 'Operatsiya';
      subParts = [date];
    }
    final sub = subParts.where((e) => e.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context, .045)),
        boxShadow: C.shadow(context),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: C.tint(context, accent),
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
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: C.text(context))),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .45))),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        Text(
          '${isIncome ? '+' : '−'}${money(amount)}',
          style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: onColor),
        ),
      ]),
    );
  }
}
