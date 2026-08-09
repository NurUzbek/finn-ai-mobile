import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/common.dart';
import '../services/api.dart';
import '../services/i18n.dart';

/// "Xabarlar" moduli — muhim bildirishnomalar, eslatmalar va risk signallari.
/// FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText).
/// Nav shell'dan keladi: navIndex + onNavChanged.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.navIndex = 4, this.onNavChanged});
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

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

  /// Turi/muhimligiga qarab ikonka, oldingi (foreground) rang va tint fon.
  (IconData, Color, Color) _style(FinnTokens t, Map<String, dynamic> n) {
    final ty = (n['type'] ?? '').toString().toLowerCase();
    final p = (n['priority'] ?? '').toString().toLowerCase();
    if (ty.contains('security')) {
      return (Icons.lock_outline_rounded, t.onPur, t.tPur);
    }
    if (ty.contains('ai')) {
      return (Icons.auto_awesome_rounded, t.blue, t.tBlu);
    }
    if (ty.contains('paid') || ty.contains('success')) {
      return (Icons.check_rounded, t.onGrn, t.tGrn);
    }
    if (ty.contains('report') || ty.contains('deadline')) {
      return (Icons.warning_amber_rounded, t.onAmb, t.tAmb);
    }
    if (p == 'high' || _isPay(n)) {
      return (Icons.account_balance_rounded, t.onRed, t.tRed);
    }
    return (Icons.notifications_rounded, t.blue, t.tBlu);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FutureBuilder<Map<String, dynamic>>(
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

        return FinnScreen(
          title: tr('notif.title'),
          subtitle:
              loading ? tr('state.loading') : '$unread ${tr('notif.unread')}',
          showNav: false,
          reserveNav: true,
          actions: [
            _iconBtn(t, Icons.refresh_rounded, onTap: _refresh),
            const SizedBox(width: 8),
            _readAllBtn(t, enabled: unread > 0 && !loading),
          ],
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!ok)
              _empty(
                t,
                Icons.cloud_off_rounded,
                (d['message'] ?? tr('notif.noData')).toString(),
                t.red,
                onRetry: _refresh,
              )
            else
              _content(t, all),
          ],
        );
      },
    );
  }

  Widget _content(FinnTokens t, List<Map<String, dynamic>> all) {
    final list = _apply(all);
    final muhim = all.where(_isHigh).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // ── Filtr chiplari ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(children: [
            _chip(t, label: tr('common.all'), idx: 0),
            const SizedBox(width: 8),
            _chip(t,
                label: muhim > 0
                    ? '${tr('notif.important')} $muhim'
                    : tr('notif.important'),
                idx: 1,
                dot: t.red),
            const SizedBox(width: 8),
            _chip(t, label: tr('notif.payment'), idx: 2),
            const SizedBox(width: 8),
            _chip(t, label: tr('nav.risk'), idx: 3),
          ]),
        ),
        const SizedBox(height: 16),
        if (list.isEmpty)
          _empty(t, Icons.notifications_off_rounded, tr('notif.empty'), t.blue)
        else
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) const SizedBox(height: FinnTokens.gapList),
            StaggerIn(index: i, child: _card(t, list[i])),
          ],
      ],
    );
  }

  // ── Sarlavha ikonka tugmasi ──
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
          child: Icon(ic, size: 19, color: onTap == null ? t.ink4 : t.ink2),
        ),
      );

  // ── "Hammasi o'qildi" matnli tugmasi (HTML: #readAll) ──
  Widget _readAllBtn(FinnTokens t, {required bool enabled}) => GestureDetector(
        onTap: enabled ? _readAll : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            tr('notif.markAllRead'),
            style: FinnText.chip(enabled ? t.blue : t.ink4),
          ),
        ),
      );

  // ── Filtr chipi ──
  Widget _chip(FinnTokens t,
      {required String label, required int idx, Color? dot}) {
    final on = _filter == idx;
    return GestureDetector(
      onTap: () => setState(() => _filter = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: FinnTokens.ease,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: on ? t.blue : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? t.blue : t.line),
          boxShadow: on ? null : t.sh,
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
          Text(label, style: FinnText.chip(on ? Colors.white : t.ink2)),
        ]),
      ),
    );
  }

  // ── Bildirishnoma kartasi (HTML: .nt) ──
  Widget _card(FinnTokens t, Map<String, dynamic> n) {
    final unread = n['read'] != true;
    final (icon, fg, tint) = _style(t, n);

    return Container(
      decoration: BoxDecoration(
        color: unread ? t.card : Colors.transparent,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: unread ? t.line2 : Colors.transparent),
        boxShadow: unread ? t.sh : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // .nt-ic — o'qilganda butun ikonka 50% shaffof
              Opacity(
                opacity: unread ? 1 : .5,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 17, color: fg),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // h4 — dot bilan to'qnashmasligi uchun o'ng bo'shliq
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(
                          (n['title'] ?? '').toString(),
                          style: FinnText.rowTitle(unread ? t.ink : t.ink3),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        (n['body'] ?? '').toString(),
                        style: FinnText.screenSub(unread ? t.ink2 : t.ink3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (n['date'] ?? '').toString(),
                        style: FinnText.rowSub(t.ink3),
                      ),
                    ]),
              ),
            ]),
          ),
          // .dot — o'qilmagan belgisi (top:17 right:15)
          if (unread)
            Positioned(
              top: 17,
              right: 15,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: t.red, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  // ── Bo'sh / xato holati ──
  Widget _empty(FinnTokens t, IconData icon, String text, Color color,
      {Future<void> Function()? onRetry}) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: .1), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center, style: FinnText.body(t.ink3)),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onRetry(),
              child: Text(tr('common.retry')),
            ),
          ],
        ]),
      ),
    );
  }
}
