import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Bildirishnomalar" moduli — muhim xabarlar va eslatmalar (TZ 2-jadval).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<Map<String, dynamic>> _f = Api.notifications();
  Future<void> _refresh() async => setState(() => _f = Api.notifications());

  Future<void> _readAll() async {
    await Api.markRead();
    _refresh();
  }

  Color _c(String p) => switch (p) {
        'critical' => C.red,
        'high' => C.amber,
        'low' => C.cyan,
        _ => C.sky,
      };

  IconData _i(String t) => switch (t) {
        'security' => Icons.shield_outlined,
        'tax_debt' => Icons.account_balance,
        'subscription' => Icons.card_membership,
        'org_archived' => Icons.archive_outlined,
        _ => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          ScreenHeader(
            title: 'Bildirishnomalar', icon: Icons.notifications,
            subtitle: 'Muddat va risklar haqida',
            action: TextButton(onPressed: _readAll, child: const Text('O\'qildi', style: TextStyle(fontSize: 12, color: C.cyan))),
          ),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final list = (d['notifications'] as List).cast<Map<String, dynamic>>();
                if (list.isEmpty) {
                  return const EmptyState(icon: Icons.notifications_off_outlined, text: 'Bildirishnoma yo\'q');
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final n = list[i];
                    final unread = n['read'] != true;
                    final c = _c(n['priority'] ?? 'normal');
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: unread ? c.withValues(alpha: .07) : C.cardDark,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: unread ? c.withValues(alpha: .3) : Colors.white.withValues(alpha: .05)),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: c.withValues(alpha: .14), borderRadius: BorderRadius.circular(11)),
                          child: Icon(_i(n['type'] ?? ''), size: 17, color: c),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(n['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))),
                            if (unread) Container(width: 7, height: 7,
                                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                          ]),
                          const SizedBox(height: 5),
                          Text(n['body'] ?? '', style: TextStyle(fontSize: 12, height: 1.45, color: Colors.white.withValues(alpha: .6))),
                          const SizedBox(height: 7),
                          Text(n['date'] ?? '', style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: .32))),
                        ])),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      );
}
