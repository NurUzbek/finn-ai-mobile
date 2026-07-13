import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Monitoring" moduli — soliq qarzdorligi, kechikkan kunlar, penya (TZ 2-jadval).
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
          const ScreenHeader(title: 'Soliq qarzdorligi', icon: Icons.account_balance, subtitle: 'Penya real vaqtda hisoblanadi'),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final debts = (d['debts'] as List).cast<Map<String, dynamic>>();
                final rate = d['rate'];
                if (debts.isEmpty) {
                  return const EmptyState(icon: Icons.verified_rounded, text: 'Qarzdorlik yo\'q — hammasi joyida');
                }
                final total = debts.fold<double>(0, (a, b) => a + (b['amount'] as num).toDouble());
                final pen = debts.fold<double>(0, (a, b) => a + (b['penalty'] as num).toDouble());

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [C.red.withValues(alpha: .14), C.amber.withValues(alpha: .07)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: C.red.withValues(alpha: .25)),
                      ),
                      child: Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Umumiy qarz', style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .55))),
                          const SizedBox(height: 4),
                          Text(money(total), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.red)),
                        ])),
                        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: .08)),
                        Expanded(child: Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Penya (MB $rate%)', style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .55))),
                            const SizedBox(height: 4),
                            Text(money(pen), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: C.amber)),
                          ]),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 18),

                    ...debts.map((t) {
                      final od = t['days_overdue'] as int;
                      final c = od > 30 ? C.red : (od > 0 ? C.amber : C.cyan);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: C.cardDark,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: c.withValues(alpha: .22)),
                        ),
                        child: Column(children: [
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(t['tax_type'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(t['org'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .42))),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
                              child: Text(od > 0 ? '$od kun' : 'muddatida',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c)),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _mini('Qarz', money(t['amount']), Colors.white),
                            _mini('Penya', money(t['penalty']), C.amber),
                            _mini('Kuniga', '+${money(t['daily'])}', C.red),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(Icons.event, size: 12, color: Colors.white.withValues(alpha: .35)),
                            const SizedBox(width: 5),
                            Text('Muddat: ${t['due_date'] ?? '—'}',
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .4))),
                          ]),
                        ]),
                      );
                    }),
                    const SizedBox(height: 10),
                    Text('Penya = qarz × (MB stavka / 365) × kechikkan kunlar. Qarz summasidan oshmaydi (SK 110-modda).',
                        style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: .32), height: 1.5)),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  Widget _mini(String k, String v, Color c) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: .4))),
          const SizedBox(height: 2),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
              child: Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c))),
        ]),
      );
}
