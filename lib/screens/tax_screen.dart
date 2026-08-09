import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/modules_sheet.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// "Soliq qarzi" moduli — soliq qarzdorligi, kechikkan kunlar, real vaqtda penya.
/// FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText).
class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key, this.navIndex = 3, this.onNavChanged});
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  late Future<Map<String, dynamic>> _f = Api.tax();
  Future<void> _refresh() async => setState(() => _f = Api.tax());

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('tax.header'),
      subtitle: tr('tax.subtitle'),
      showNav: false,
      reserveNav: true,
      leading: _iconBtn(t, Icons.menu_rounded, onTap: () => showModulesSheet(context)),
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
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final debts = (d['debts'] as List).cast<Map<String, dynamic>>();
    if (debts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: EmptyState(
          icon: Icons.verified_rounded,
          text: tr('tax.emptyState'),
          color: t.green,
        ),
      );
    }

    final total = debts.fold<double>(0, (a, b) => a + (b['amount'] as num).toDouble());
    final pen = debts.fold<double>(0, (a, b) => a + (b['penalty'] as num).toDouble());
    final daily = debts.fold<double>(0, (a, b) => a + (b['daily'] as num).toDouble());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        // ── Umumiy qarz | Jami penya ──
        StaggerIn(
          index: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: t.tRed,
              borderRadius: BorderRadius.circular(FinnTokens.rXl),
            ),
            child: Row(children: [
              Expanded(child: _summary(t, tr('tax.totalDebt'), money(total), t.red, t.onRed)),
              const SizedBox(width: 16),
              Container(width: 1, height: 44, color: t.red.withValues(alpha: .2)),
              const SizedBox(width: 16),
              Expanded(child: _summary(t, tr('tax.totalPenalty'), money(pen), t.amber, t.onAmb)),
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
              color: t.card,
              borderRadius: BorderRadius.circular(FinnTokens.rLg),
              border: Border.all(color: t.line2),
              boxShadow: t.sh,
            ),
            child: Row(children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: t.red, shape: BoxShape.circle)),
              const SizedBox(width: 9),
              Text(tr('tax.dailyAdd'), style: FinnText.rowSub(t.ink2)),
              const Spacer(),
              Text('+${money(daily)}',
                  style: FinnText.rowValue(t.red).copyWith(fontSize: 16)),
              const SizedBox(width: 4),
              Text(tr('common.som'), style: FinnText.rowSub(t.ink3)),
            ]),
          ),
        ),
        const SizedBox(height: 24),

        // ── Eyebrow ──
        Row(children: [
          Text(tr('tax.eyebrow').toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: t.line)),
          const SizedBox(width: 10),
          Text(tr('tax.sort'), style: FinnText.pill(t.blue)),
        ]),
        const SizedBox(height: 12),

        // ── Soliq kartalari ──
        ...debts.asMap().entries.map((e) {
          final tx = e.value;
          final od = (tx['days_overdue'] as num).toInt();
          final isHot = od > 60;
          final pillColor = isHot ? t.tRed : t.tAmb;
          final pillTxt = isHot ? t.onRed : t.onAmb;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StaggerIn(
              index: e.key + 2,
              child: Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(FinnTokens.rXl),
                  border: Border.all(color: t.line2),
                  boxShadow: t.sh,
                ),
                child: Column(children: [
                  // header
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tx['tax_type']?.toString() ?? '—',
                            style: FinnText.cardTitle(t.ink).copyWith(fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(tx['org']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FinnText.rowSub(t.ink3)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(FinnTokens.rLg),
                      ),
                      child: Text('$od ${tr('tax.daysWord')}', style: FinnText.pill(pillTxt)),
                    ),
                  ]),
                  // tri-stat (yuqorida ajratuvchi chiziq bilan)
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    padding: const EdgeInsets.only(top: 13),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: t.line2)),
                    ),
                    child: Row(children: [
                      _tri(t, tr('tax.debt'), money(tx['amount'] as num), t.ink),
                      _divider(t),
                      _tri(t, tr('tax.penalty'), money(tx['penalty'] as num), t.amber),
                      _divider(t),
                      _tri(t, tr('tax.daily'), '+${money(tx['daily'] as num)}', t.red),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${tr('tax.dueLabel')}: ${tx['due_date']?.toString() ?? '—'}',
                        style: FinnText.rowSub(t.ink3)),
                  ),
                ]),
              ),
            ),
          );
        }),
        // ── МЖтК jarimalari (BHM asosida) ──
        ..._finesSection(t, d),
      ],
    );
  }

  Widget _summary(FinnTokens t, String label, String value, Color valColor, Color labColor) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: FinnText.label(labColor.withValues(alpha: .75))),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: FinnText.bigValue(valColor).copyWith(fontSize: 27)),
        ),
      ]);

  /// МЖтК ma'muriy jarimalari — BHM karralarida (backend PenaltyService bilan bir manba).
  List<Widget> _finesSection(FinnTokens t, Map<String, dynamic> d) {
    final fines = (d['fines'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (fines.isEmpty) return const [];
    final bhm = (d['bhm'] as num?) ?? 412000;
    return [
      const SizedBox(height: 24),
      Row(children: [
        Text(tr('tax.finesTitle'), style: FinnText.eyebrow(t.ink3)),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: t.line)),
      ]),
      const SizedBox(height: 4),
      Text('${tr('tax.finesNote')} · BHM ${money(bhm)} ${tr('common.som')}',
          style: FinnText.rowSub(t.ink3)),
      const SizedBox(height: 12),
      ...fines.asMap().entries.map((e) {
        final f = e.value;
        final rows = (f['rows'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
        final maxSum = rows.fold<double>(
            0, (a, r) => (r['max_sum'] as num).toDouble() > a ? (r['max_sum'] as num).toDouble() : a);
        return Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: StaggerIn(
            index: e.key,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(FinnTokens.rLg),
                border: Border.all(color: t.line),
                boxShadow: t.sh,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: t.tAmb, borderRadius: BorderRadius.circular(FinnTokens.rSm)),
                  child: Icon(Icons.gavel_rounded, size: 17, color: t.onAmb),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f['label']?.toString() ?? '', style: FinnText.rowTitle(t.ink)),
                    const SizedBox(height: 3),
                    Text(f['art']?.toString() ?? '', style: FinnText.rowSub(t.ink3)),
                  ]),
                ),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(tr('tax.finesUpto'), style: FinnText.rowSub(t.ink3)),
                  const SizedBox(height: 1),
                  Text(money(maxSum),
                      style: FinnText.rowValue(t.red).copyWith(fontSize: 13.5)),
                ]),
              ]),
            ),
          ),
        );
      }),
    ];
  }

  Widget _divider(FinnTokens t) => Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 6.5),
      color: t.line2);

  Widget _tri(FinnTokens t, String k, String v, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k.toUpperCase(), style: FinnText.label(t.ink3)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(v, style: FinnText.rowValue(c).copyWith(fontSize: 16)),
          ),
        ]),
      );

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('tax.errNoConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('tax.retry'))),
          ]),
        ),
      );

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) => GestureDetector(
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
