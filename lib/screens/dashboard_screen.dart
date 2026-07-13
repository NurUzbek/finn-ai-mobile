import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import '../widgets/locked.dart';

/// "Asosiy" moduli — umumiy statistik ma'lumotlar (TZ 2-jadval).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _f = Api.dashboard();
  Future<void> _refresh() async => setState(() => _f = Api.dashboard());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        const ScreenHeader(title: 'Asosiy', icon: Icons.dashboard, subtitle: 'Umumiy holat bir ko\'rishda'),
        Expanded(
          child: Loader(
            future: _f,
            onRefresh: _refresh,
            builder: (d) {
              final s = d['stats'] as Map<String, dynamic>;
              final orgs = (d['organizations'] as List).cast<Map<String, dynamic>>();
              final hasDebt = (s['debts_total'] as num) > 0;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const PlanBanner(),

                  // Ogohlantirish banneri
                  if (hasDebt)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [C.red.withValues(alpha: .16), C.amber.withValues(alpha: .08)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: C.red.withValues(alpha: .3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: C.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${s['overdue_count']} ta muddati o\'tgan to\'lov',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text('Penya hisoblanmoqda — Soliq bo\'limiga qarang',
                                style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .6))),
                          ]),
                        ),
                      ]),
                    ),

                  // 4 stat karta
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.32,
                    children: [
                      StatCard(label: 'Tashkilotlar', value: '${s['orgs']}', icon: Icons.business, color: C.sky),
                      StatCard(label: 'Umumiy qarz', value: money(s['debts_total']), unit: 'so\'m', icon: Icons.account_balance_wallet, color: C.red),
                      StatCard(label: 'Jami penya', value: money(s['penalty_total']), unit: 'so\'m', icon: Icons.trending_up, color: C.amber),
                      StatCard(label: 'O\'qilmagan xabar', value: '${s['unread_notifications']}', icon: Icons.notifications_active, color: C.violet),
                    ],
                  ),

                  const SizedBox(height: 22),
                  Row(children: [
                    const Text('Tashkilotlarim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const Spacer(),
                    Text('${orgs.length} ta', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: .4))),
                  ]),
                  const SizedBox(height: 10),

                  ...orgs.map((o) {
                    final debt = (o['debt'] as num).toDouble();
                    final ok = debt == 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: C.cardDark,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withValues(alpha: .06)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: (ok ? C.green : C.red).withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(ok ? Icons.check_circle : Icons.error_outline,
                              color: ok ? C.green : C.red, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(o['name'], maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text('STIR ${o['stir'] ?? '—'}',
                                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .4))),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(ok ? 'Qarz yo\'q' : money(debt),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ok ? C.green : C.red)),
                          Text('balans ${money(o['balance'])}',
                              style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: .4))),
                        ]),
                      ]),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}
