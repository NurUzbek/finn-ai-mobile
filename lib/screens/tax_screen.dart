import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// "Soliq qarzi" moduli — soliq qarzdorligi, kechikkan kunlar, real vaqtda penya.
class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});
  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late Future<Map<String, dynamic>> _f = Api.tax();
  Future<void> _refresh() async => setState(() => _f = Api.tax());

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: tr('tax.header'),
            icon: Icons.account_balance_rounded,
            subtitle: tr('tax.subtitle'),
          ),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final debts = (d['debts'] as List).cast<Map<String, dynamic>>();
                if (debts.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 80),
                      EmptyState(
                        icon: Icons.verified_rounded,
                        text: tr('tax.emptyState'),
                        color: C.green,
                      ),
                    ],
                  );
                }

                final total = debts.fold<double>(0, (a, b) => a + (b['amount'] as num).toDouble());
                final pen = debts.fold<double>(0, (a, b) => a + (b['penalty'] as num).toDouble());
                final daily = debts.fold<double>(0, (a, b) => a + (b['daily'] as num).toDouble());

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    // ── Umumiy qarz | Jami penya ──
                    StaggerIn(
                      index: 0,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: C.tint(context, C.red),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(children: [
                          Expanded(child: _summary(context, tr('tax.totalDebt'), money(total), C.red, C.onRed(context))),
                          Container(width: 1, height: 44, color: C.red.withValues(alpha: .2)),
                          const SizedBox(width: 16),
                          Expanded(child: _summary(context, tr('tax.totalPenalty'), money(pen), C.amber, C.onAmb(context))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Har kuni qo'shilmoqda ──
                    StaggerIn(
                      index: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: C.card(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: C.border(context)),
                          boxShadow: C.shadow(context),
                        ),
                        child: Row(children: [
                          Container(width: 7, height: 7,
                              decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle)),
                          const SizedBox(width: 9),
                          Text(tr('tax.dailyAdd'),
                              style: TextStyle(fontSize: 13, color: C.muted(context, .7))),
                          const Spacer(),
                          Text('+${money(daily)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: C.red)),
                          const SizedBox(width: 4),
                          Text(tr('common.som'), style: TextStyle(fontSize: 12, color: C.muted(context, .45))),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Eyebrow ──
                    Row(children: [
                      Text(tr('tax.eyebrow'),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: C.muted(context, .4))),
                      const SizedBox(width: 10),
                      Expanded(child: Container(height: 1, color: C.border(context))),
                      const SizedBox(width: 10),
                      Text(tr('tax.sort'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700, color: C.brand)),
                    ]),
                    const SizedBox(height: 12),

                    // ── Soliq kartalari ──
                    ...debts.asMap().entries.map((e) {
                      final t = e.value;
                      final od = (t['days_overdue'] as num).toInt();
                      final isHot = od > 60;
                      final pillColor = isHot ? C.red : C.amber;
                      final pillTxt = isHot ? C.onRed(context) : C.onAmb(context);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: StaggerIn(
                          index: e.key + 2,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: C.card(context),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: C.border(context)),
                              boxShadow: C.shadow(context),
                            ),
                            child: Column(children: [
                              // header
                              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(t['tax_type']?.toString() ?? '—',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.2,
                                            color: C.text(context))),
                                    const SizedBox(height: 3),
                                    Text(t['org']?.toString() ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: C.muted(context, .45))),
                                  ]),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: C.tint(context, pillColor),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('$od ${tr('tax.daysWord')}',
                                      style: TextStyle(
                                          fontSize: 11.5, fontWeight: FontWeight.w800, color: pillTxt)),
                                ),
                              ]),
                              const SizedBox(height: 14),
                              // tri-stat
                              Row(children: [
                                _tri(context, tr('tax.debt'), money(t['amount'] as num), C.text(context)),
                                _divider(context),
                                _tri(context, tr('tax.penalty'), money(t['penalty'] as num), C.amber),
                                _divider(context),
                                _tri(context, tr('tax.daily'), '+${money(t['daily'] as num)}', C.red),
                              ]),
                              const SizedBox(height: 14),
                              Row(children: [
                                Icon(Icons.event_rounded, size: 13, color: C.muted(context, .35)),
                                const SizedBox(width: 6),
                                Text('${tr('tax.dueLabel')}: ${t['due_date']?.toString() ?? '—'}',
                                    style: TextStyle(fontSize: 11.5, color: C.muted(context, .42))),
                              ]),
                            ]),
                          ),
                        ),
                      );
                    }),
                    // ── МЖтК jarimalari (BHM asosida) ──
                    ..._finesSection(context, d),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  Widget _summary(BuildContext context, String label, String value, Color valColor, Color labColor) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: labColor.withValues(alpha: .8))),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: valColor)),
        ),
      ]);

  /// МЖтК ma'muriy jarimalari — BHM karralarida (backend PenaltyService bilan bir manba).
  List<Widget> _finesSection(BuildContext context, Map<String, dynamic> d) {
    final fines = (d['fines'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (fines.isEmpty) return const [];
    final bhm = (d['bhm'] as num?) ?? 412000;
    return [
      const SizedBox(height: 24),
      Row(children: [
        Text(tr('tax.finesTitle'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: C.muted(context, .4))),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: C.border(context))),
      ]),
      const SizedBox(height: 4),
      Text('${tr('tax.finesNote')} · BHM ${money(bhm)} ${tr('common.som')}',
          style: TextStyle(fontSize: 11.5, color: C.muted(context, .45))),
      const SizedBox(height: 12),
      ...fines.asMap().entries.map((e) {
        final f = e.value;
        final rows = (f['rows'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        final maxSum = rows.fold<double>(0, (a, r) => (r['max_sum'] as num).toDouble() > a ? (r['max_sum'] as num).toDouble() : a);
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: StaggerIn(
            index: e.key,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.card(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: C.border(context)),
                boxShadow: C.shadow(context),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 34, height: 34, alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.tint(context, C.amber), borderRadius: BorderRadius.circular(11)),
                  child: Icon(Icons.gavel_rounded, size: 17, color: C.onAmb(context)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f['label']?.toString() ?? '',
                        style: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600, color: C.text(context))),
                    const SizedBox(height: 3),
                    Text(f['art']?.toString() ?? '',
                        style: TextStyle(fontSize: 11, color: C.muted(context, .45))),
                  ]),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(tr('tax.finesUpto'), style: TextStyle(fontSize: 10, color: C.muted(context, .4))),
                  const SizedBox(height: 1),
                  Text(money(maxSum),
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: C.red)),
                ]),
              ]),
            ),
          ),
        );
      }),
    ];
  }

  Widget _divider(BuildContext context) => Container(width: 1, height: 34, color: C.border(context, .1));

  Widget _tri(BuildContext context, String k, String v, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: TextStyle(fontSize: 11, color: C.muted(context, .45))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(v,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: c)),
          ),
        ]),
      );
}
