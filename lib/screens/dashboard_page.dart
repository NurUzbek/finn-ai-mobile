import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/finn_tokens.dart';
import '../services/notifs.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import 'dashboard_screen.dart';
import 'chat_screen.dart';

/// Asosiy ekran uchun ma'lumot + funksiya ulovchi (wrapper).
/// `dashboard_screen.dart` (dizayn) sof ko'rinish — bu yerda Api javobi
/// `DashboardData` ga o'giriladi va tugmalar harakatga ulanadi.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.navIndex = 0, this.onNavChanged});
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _f = Api.dashboard();
  bool _notifSynced = false;
  void _reload() => setState(() => _f = Api.dashboard());

  /// Deadline'larni telefon bildirishnomasiga (joriy tilda) rejalaydi — bir marta.
  void _syncNotifs(Map<String, dynamic> d) {
    if (kIsWeb || _notifSynced) return;
    _notifSynced = true;
    final raw = ((d['deadlines'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => {
              'title': (m['title'] ?? '').toString(),
              'days': ((m['days'] ?? 0) as num).toInt(),
            })
        .toList();
    if (raw.isNotEmpty) Notifs.i.syncDeadlines(raw);
  }

  void _push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  DashboardData _map(Map<String, dynamic> d, FinnTokens t) {
    final s = (d['stats'] as Map?) ?? const {};
    final orgs = (d['organizations'] as List?) ?? const [];
    final balance = orgs.fold<double>(
        0, (a, o) => a + ((o['balance'] ?? 0) as num).toDouble());
    final orgCount = orgs.length;
    final overdue = ((s['overdue_count'] ?? 0) as num).toInt();

    final cf = (d['cashflow'] as Map?) ?? const {};
    final income = ((cf['income'] ?? 0) as num).toInt();
    final expense = ((cf['expense'] ?? 0) as num).toInt();
    final net = ((cf['net'] ?? (income - expense)) as num).toInt();

    Color dc(int days) => days < 0 || days <= 7
        ? t.red
        : days <= 20
            ? t.amber
            : days <= 45
                ? t.blue
                : t.green;
    final dls = (d['deadlines'] as List?) ?? const [];
    final deadlines = dls.take(4).map((e) {
      final m = e as Map;
      final days = ((m['days'] ?? 0) as num).toInt();
      return DeadlineData(
        days: days,
        title: trReport((m['title'] ?? '').toString()),
        date: (m['date'] ?? '').toString(),
        progress: days < 0 ? 1.0 : (1 - days / 90).clamp(0.06, 1.0).toDouble(),
        color: dc(days),
      );
    }).toList();

    final risk = d['risk'] as Map?;

    return DashboardData(
      balance: balance.toInt(),
      orgCount: orgCount,
      cleanCount: (orgCount - overdue).clamp(0, orgCount),
      lateCount: overdue,
      penyaTotal: ((s['penalty_total'] ?? 0) as num).toDouble(),
      penyaPerDay: ((d['daily'] ?? 0) as num).toInt(),
      deadlines: deadlines,
      profit: net,
      growth: income > 0 ? (net / income * 100).round() : 0,
      income: income,
      expense: expense,
      flowPoints: const [0.30, 0.44, 0.40, 0.60, 0.55, 0.70, 0.76],
      riskScore: ((risk?['score'] ?? 0) as num).toInt(),
      debtTotal: ((s['debts_total'] ?? 0) as num).toInt(),
      overdueCount: overdue,
      aiTitle: overdue > 0 ? tr('dash.aiOverdueTitle') : tr('dash.aiStableTitle'),
      aiBody: overdue > 0 ? tr('dash.aiOverdueBody') : tr('dash.aiStableBody'),
      // TZ modullariga tez o'tish (pastki nav tab'lariga) — ortiqcha ekran push emas.
      quickActions: [
        QuickAction(Icons.swap_vert_rounded, tr('nav.monitoring'), (t) => t.tGrn,
            (t) => t.green, onTap: () => _go(2)),
        QuickAction(Icons.assessment_outlined, tr('nav.data'), (t) => t.tBlu,
            (t) => t.blue, onTap: () => _go(3)),
        QuickAction(Icons.apartment_rounded, tr('nav.orgs'), (t) => t.tTea,
            (t) => t.teal, onTap: () => _go(1)),
        QuickAction(Icons.notifications_rounded, tr('nav.notif'), (t) => t.tAmb,
            (t) => t.amber, onTap: () => _go(4)),
      ],
    );
  }

  void _go(int i) {
    if (i != widget.navIndex) HapticFeedback.selectionClick();
    widget.onNavChanged?.call(i);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _shell(const Center(child: CircularProgressIndicator()));
        }
        final d = snap.data ?? const {};
        if (d['ok'] != true) {
          return _shell(Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('state.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _reload, child: Text(tr('common.retry'))),
          ]));
        }
        _syncNotifs(d);
        return DashboardScreen(
          data: _map(d, t),
          navIndex: widget.navIndex,
          onNavChanged: _go,
          onRefresh: _reload,
          onNotif: () => _go(4),
          onAiTap: () => _push(const ChatScreen()),
          onKalendar: () => _go(3), // Ma'lumotlar
          onBatafsil: () => _go(2), // Monitoring
          onBalance: () => _go(1),
          onPenya: () => _go(3),
        );
      },
    );
  }

  Widget _shell(Widget body) => FinnScreen(
        govSources: true,
      demoData: const ['soliq'],
        title: tr('nav.home'),
        subtitle: tr('dash.subtitle'),
        navIndex: widget.navIndex,
        onNavChanged: widget.onNavChanged,
        children: [Padding(padding: const EdgeInsets.only(top: 130), child: body)],
      );
}
