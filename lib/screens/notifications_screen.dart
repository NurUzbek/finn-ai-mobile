import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// "Xabarlar" moduli — muhim bildirishnomalar, eslatmalar va risk signallari.
/// Dizayn: finn-app-screens.html #v-xabar.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<Map<String, dynamic>> _f = Api.notifications();
  int _filter = 0; // 0 Hammasi · 1 Muhim · 2 To'lov · 3 Risk

  Future<void> _refresh() async => setState(() => _f = Api.notifications());

  Future<void> _readAll() async {
    await Api.markRead();
    await _refresh();
  }

  // ── Yordamchilar ──
  bool _isHigh(Map<String, dynamic> n) =>
      (n['priority'] ?? '').toString().toLowerCase() == 'high';

  bool _isPay(Map<String, dynamic> n) {
    final t = (n['type'] ?? '').toString().toLowerCase();
    return t.contains('tax') || t.contains('debt') || t.contains('penalty');
  }

  bool _isRisk(Map<String, dynamic> n) =>
      (n['type'] ?? '').toString().toLowerCase().contains('risk');

  List<Map<String, dynamic>> _apply(List<Map<String, dynamic>> all) =>
      switch (_filter) {
        1 => all.where(_isHigh).toList(),
        2 => all.where(_isPay).toList(),
        3 => all.where(_isRisk).toList(),
        _ => all,
      };

  /// Turi/muhimligiga qarab rang, ikonka va oldingi (foreground) rang.
  (Color, IconData, Color) _style(BuildContext c, Map<String, dynamic> n) {
    final t = (n['type'] ?? '').toString().toLowerCase();
    final p = (n['priority'] ?? '').toString().toLowerCase();
    if (t.contains('security')) {
      return (C.violet, Icons.lock_outline_rounded, C.onPur(c));
    }
    if (t.contains('ai')) {
      return (C.brand, Icons.auto_awesome_rounded, C.brand);
    }
    if (t.contains('paid') || t.contains('success')) {
      return (C.green, Icons.check_rounded, C.onGrn(c));
    }
    if (t.contains('report') || t.contains('deadline')) {
      return (C.amber, Icons.warning_amber_rounded, C.onAmb(c));
    }
    if (p == 'high' || _isPay(n)) {
      return (C.red, Icons.account_balance_rounded, C.onRed(c));
    }
    return (C.brand, Icons.notifications_rounded, C.brand);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (ctx, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final d = snap.data ?? const {'ok': false};
            final ok = d['ok'] == true;
            final all = ok
                ? ((d['notifications'] as List?)?.cast<Map<String, dynamic>>() ??
                    const <Map<String, dynamic>>[])
                : const <Map<String, dynamic>>[];
            final unread = all.where((n) => n['read'] != true).length;

            return Column(children: [
              _header(ctx, unread, loading),
              Expanded(
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(color: C.brand))
                    : !ok
                        ? EmptyState(
                            icon: Icons.cloud_off_rounded,
                            color: C.red,
                            text: (d['message'] ?? tr('notif.noData'))
                                .toString())
                        : RefreshIndicator(
                            color: C.brand,
                            backgroundColor: C.card(ctx),
                            onRefresh: _refresh,
                            child: _body(ctx, all),
                          ),
              ),
            ]);
          },
        ),
      );

  // ── Sarlavha ──
  Widget _header(BuildContext c, int unread, bool loading) {
    final can = unread > 0 && !loading;
    return ScreenHeader(
      title: tr('notif.title'),
      icon: Icons.notifications_rounded,
      subtitle: loading ? tr('state.loading') : '$unread ${tr('notif.unread')}',
      action: TextButton(
        onPressed: can ? _readAll : null,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          tr('notif.markAllRead'),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: can ? C.brand : C.muted(c, .3),
          ),
        ),
      ),
    );
  }

  // ── Tana: chiplar + kartalar ──
  Widget _body(BuildContext c, List<Map<String, dynamic>> all) {
    final list = _apply(all);
    final muhim = all.where(_isHigh).length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: [
            _chip(c, label: tr('common.all'), idx: 0),
            const SizedBox(width: 8),
            _chip(c,
                label: muhim > 0
                    ? '${tr('notif.important')} $muhim'
                    : tr('notif.important'),
                idx: 1,
                dot: C.red),
            const SizedBox(width: 8),
            _chip(c, label: tr('notif.payment'), idx: 2),
            const SizedBox(width: 8),
            _chip(c, label: tr('nav.risk'), idx: 3),
          ]),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: EmptyState(
              icon: Icons.notifications_off_rounded,
              text: tr('notif.empty'),
              color: C.brand,
            ),
          )
        else
          ...List.generate(
            list.length,
            (i) => StaggerIn(index: i, child: _card(c, list[i])),
          ),
      ]),
    );
  }

  Widget _chip(BuildContext c,
      {required String label, required int idx, Color? dot}) {
    final on = _filter == idx;
    return GestureDetector(
      onTap: () => setState(() => _filter = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? C.brand : C.fill(c),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: on ? Colors.white : dot, shape: BoxShape.circle),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: on ? Colors.white : C.muted(c, .6),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card(BuildContext c, Map<String, dynamic> n) {
    final unread = n['read'] != true;
    final (color, icon, fg) = _style(c, n);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread ? C.card(c) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: unread ? C.shadow(c) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: unread
                ? C.tint(c, color)
                : C.tint(c, color, light: .05, dark: .09),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon,
              size: 20, color: unread ? fg : fg.withValues(alpha: .55)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Text(
                  (n['title'] ?? '').toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.3,
                    color: unread ? C.text(c) : C.muted(c, .42),
                  ),
                ),
              ),
              if (unread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8,
                  height: 8,
                  decoration:
                      const BoxDecoration(color: C.red, shape: BoxShape.circle),
                ),
            ]),
            const SizedBox(height: 5),
            Text(
              (n['body'] ?? '').toString(),
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: unread ? C.muted(c, .6) : C.muted(c, .35),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              (n['date'] ?? '').toString(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: C.muted(c, .3),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
