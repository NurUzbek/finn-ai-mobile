import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Mening tashkilotlarim" moduli (TZ 2-jadval).
class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key});
  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  late Future<Map<String, dynamic>> _f = Api.organizations();
  Future<void> _refresh() async => setState(() => _f = Api.organizations());

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          const ScreenHeader(title: 'Tashkilotlarim', icon: Icons.business, subtitle: 'Rekvizit va balans'),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final orgs = (d['organizations'] as List).cast<Map<String, dynamic>>();
                if (orgs.isEmpty) {
                  return const EmptyState(icon: Icons.business_outlined, text: 'Tashkilot qo\'shilmagan');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: orgs.length,
                  itemBuilder: (ctx, i) {
                    final o = orgs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: C.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: .06)),
                      ),
                      child: Theme(
                        data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          shape: const Border(),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [C.blue, C.cyan]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.apartment, color: Colors.white, size: 19),
                          ),
                          title: Text(o['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text('STIR ${o['stir'] ?? '—'}',
                              style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .42))),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              child: Column(children: [
                                _row('Direktor', o['director']),
                                _row('Manzil', o['address']),
                                _row('Bank', o['bank']),
                                _row('MFO', o['mfo']),
                                _row('Hisob raqam', o['account']),
                                const Divider(height: 22),
                                Row(children: [
                                  const Icon(Icons.account_balance_wallet_outlined, size: 15, color: C.green),
                                  const SizedBox(width: 8),
                                  const Text('Balans', style: TextStyle(fontSize: 12.5)),
                                  const Spacer(),
                                  Text('${money(o['balance'])} so\'m',
                                      style: const TextStyle(fontWeight: FontWeight.w800, color: C.green, fontSize: 13.5)),
                                ]),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      );

  Widget _row(String k, dynamic v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 100, child: Text(k, style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .4)))),
          Expanded(child: Text('${v ?? '—'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500))),
        ]),
      );
}
