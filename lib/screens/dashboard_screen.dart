import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';
import 'subscription_screen.dart';
import 'chat_screen.dart';
import 'financial_screen.dart';
import 'wallet_screen.dart';
import 'currency_screen.dart';
import 'documents_screen.dart';
import 'didox_screen.dart';
import 'reports_screen.dart';
import 'calendar_screen.dart';
import 'employees_screen.dart';
import 'team_screen.dart';
import 'counterparty_screen.dart';
import 'audit_report_screen.dart';
import 'enforcement_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _f = Api.dashboard();
  Future<void> _refresh() async => setState(() => _f = Api.dashboard());

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return tr('greet.morning');
    if (h < 18) return tr('greet.day');
    return tr('greet.evening');
  }

  /// Ism birinchi so'zi; agar telefon raqami bo'lsa "FINN".
  String _firstName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return 'FINN';
    final first = name.split(RegExp(r'\s+')).first;
    if (RegExp(r'^[+\d]').hasMatch(first)) return 'FINN';
    return first;
  }

  void _openChat() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
  void _openSub() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.brand));
              }
              final d = snap.data ?? {};
              if (d['ok'] != true) return _err();

              final s = (d['stats'] as Map?) ?? {};
              final orgs = ((d['organizations'] as List?) ?? []).cast<dynamic>();
              final first = _firstName((d['user_name'] ?? '').toString());
              final totalBalance = orgs.fold<double>(
                  0, (a, o) => a + ((o['balance'] ?? 0) as num).toDouble());
              final orgCount = orgs.length;
              final overdue = ((s['overdue_count'] ?? 0) as num).toInt();
              final clean = (orgCount - overdue).clamp(0, orgCount);
              final debt = (s['debts_total'] ?? 0) as num;
              final penalty = (s['penalty_total'] ?? 0) as num;
              final unread = ((s['unread_notifications'] ?? 0) as num).toInt();
              final recent = ((d['recent'] as List?) ?? []).cast<dynamic>();

              return ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                    20, 4, 20, 110 + MediaQuery.of(context).viewPadding.bottom),
                children: [
                  StaggerIn(index: 0, child: _header(first, unread)),
                  const SizedBox(height: 14),
                  StaggerIn(
                      index: 1,
                      child: _balance(totalBalance, orgCount, clean, overdue)),
                  StaggerIn(index: 2, child: _quickActions()),
                  StaggerIn(index: 3, child: _upsell()),
                  if (overdue > 0)
                    StaggerIn(index: 4, child: _alert(overdue, penalty)),
                  StaggerIn(
                      index: 5,
                      child: _eyebrow(tr('dash.financialStatus'),
                          action: tr('common.details'), onAction: () => homeTab.value = 3)),
                  StaggerIn(index: 6, child: _financials(debt, penalty)),
                  StaggerIn(index: 7, child: _eyebrow(tr('dash.sections'))),
                  StaggerIn(index: 8, child: _modulesGrid(context)),
                  StaggerIn(
                      index: 7,
                      child: _eyebrow(tr('dash.yourFirms'),
                          action: orgCount > 0 ? tr('common.all') : null,
                          onAction: () => homeTab.value = 1)),
                  StaggerIn(index: 8, child: _orgSection(orgs)),
                  if (recent.isNotEmpty) ...[
                    StaggerIn(
                        index: 9,
                        child: _eyebrow(tr('dash.recentAlerts'),
                            action: tr('common.all'), onAction: () => homeTab.value = 4)),
                    StaggerIn(index: 10, child: _recentSection(recent)),
                  ],
                  StaggerIn(index: 11, child: _eyebrow(tr('dash.recommendation'))),
                  StaggerIn(index: 12, child: _ai(overdue, penalty)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _err() => ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          const SizedBox(height: 220),
          Center(
            child: Column(children: [
              Icon(Icons.cloud_off_rounded, size: 44, color: C.muted(context, .35)),
              const SizedBox(height: 12),
              Text(tr('state.noConnection'),
                  style: TextStyle(color: C.muted(context, .6))),
              const SizedBox(height: 16),
              FilledButton(onPressed: _refresh, child: Text(tr('common.retry'))),
            ]),
          ),
        ],
      );

  // ─────────────────────────── HEADER ───────────────────────────
  Widget _header(String first, int unread) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greet(),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: C.muted(context, .5))),
              const SizedBox(height: 3),
              Text(first,
                  style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.1,
                      color: C.text(context))),
            ]),
          ),
          _iconBtn(Icons.search_rounded),
          const SizedBox(width: 8),
          _iconBtn(Icons.notifications_none_rounded,
              badge: unread, onTap: () => homeTab.value = 4),
        ],
      );

  Widget _iconBtn(IconData ic, {int badge = 0, VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: C.card(context),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: C.border(context)),
            boxShadow: C.shadow(context),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Icon(ic, size: 19, color: C.muted(context, .8)),
            if (badge > 0)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: C.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: C.card(context), width: 1.5),
                  ),
                ),
              ),
          ]),
        ),
      );

  // ─────────────────────────── BALANCE ───────────────────────────
  Widget _balance(double bal, int orgs, int clean, int overdue) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => homeTab.value = 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF1440A0).withValues(alpha: .28),
                  blurRadius: 40,
                  offset: const Offset(0, 18)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1745C9),
                        Color(0xFF2A6DF5),
                        Color(0xFF1FA8E8),
                        Color(0xFF25C4E8),
                      ],
                      stops: [0, .44, .82, 1],
                    ),
                  ),
                ),
              ),
              // Oq radial nur (o'ng-yuqori).
              Positioned(
                right: -90,
                top: -110,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withValues(alpha: .28),
                      Colors.white.withValues(alpha: 0),
                    ], stops: const [0, .62]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('dash.totalBalance'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: .66))),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: bal),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: money(v),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.6,
                                    height: 1)),
                            TextSpan(
                                text: '  ${tr('common.som')}',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: .68),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: .18)),
                      const SizedBox(height: 17),
                      Row(children: [
                        _bstat('$orgs', tr('dash.orgs')),
                        _bstat('$clean', tr('dash.clean')),
                        _bstat('$overdue', tr('dash.overdue')),
                      ]),
                    ]),
              ),
            ]),
          ),
        ),
      );

  Widget _bstat(String v, String l) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6)),
          const SizedBox(height: 3),
          Text(l,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .66),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  // ─────────────────────────── UPSELL ───────────────────────────
  Widget _upsell() => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _openSub,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: C.tint(context, C.amber),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: C.onAmb(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                    tr('dash.freePlan'),
                    style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: C.onAmb(context))),
              ),
              const SizedBox(width: 10),
              Text(tr('common.expand'),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: C.onAmb(context))),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: C.onAmb(context)),
            ]),
          ),
        ),
      );

  // ─────────────────────────── ALERT ───────────────────────────
  Widget _alert(int overdue, num penalty) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => homeTab.value = 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: C.tint(context, C.red),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: C.red, shape: BoxShape.circle)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$overdue ${tr('dash.overduePayments')}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -.3,
                              color: C.onRed(context))),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                              fontSize: 12.5, color: C.muted(context, .6)),
                          children: [
                            TextSpan(text: '${tr('dash.total')} '),
                            TextSpan(
                                text: '+${money(penalty)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: C.onRed(context))),
                            TextSpan(text: ' ${tr('common.som')} ${tr('dash.penalty')}'),
                          ],
                        ),
                      ),
                    ]),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: C.onRed(context)),
            ]),
          ),
        ),
      );

  // ─────────────────────────── EYEBROW ───────────────────────────
  Widget _eyebrow(String label, {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 26, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: C.muted(context, .4))),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
          if (action != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text(action,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: C.brand)),
            ),
          ],
        ]),
      );

  // ─────────────────────────── FINANCIALS GRID ───────────────────────────
  Widget _card({required Widget child, VoidCallback? onTap}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: C.card(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.border(context)),
            boxShadow: C.shadow(context),
          ),
          child: child,
        ),
      );

  Widget _lab(String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
          color: C.muted(context, .4)));

  Widget _financials(num debt, num penalty) => Column(children: [
        // Umumiy qarz (to'liq kenglik + mini bar chart)
        _card(
          onTap: () => homeTab.value = 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _lab(tr('dash.totalDebt')),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: debt.toDouble()),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                        text: money(v),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.4,
                            height: 1,
                            color: C.red)),
                    TextSpan(
                        text: '  so\'m',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: C.muted(context, .45))),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 15),
            _barChart(),
            const SizedBox(height: 12),
            Text(tr('dash.chartCaption'),
                style: TextStyle(fontSize: 12, color: C.muted(context, .45))),
          ]),
        ),
        const SizedBox(height: 11),
        Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Jami penya
          Expanded(
            child: _card(
              onTap: () => homeTab.value = 3,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lab(tr('dash.totalPenalty')),
                    const SizedBox(height: 9),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(money(penalty),
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8,
                              height: 1,
                              color: C.text(context))),
                    ),
                    const SizedBox(height: 8),
                    Text(tr('common.som'),
                        style:
                            TextStyle(fontSize: 12, color: C.onAmb(context))),
                  ]),
            ),
          ),
          const SizedBox(width: 11),
          // O'rtacha risk
          Expanded(
            child: _card(
              onTap: () => homeTab.value = 2,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lab(tr('dash.avgRisk')),
                    const SizedBox(height: 9),
                    Text('—',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                            height: 1,
                            color: C.muted(context, .55))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(tr('common.details'),
                          style: TextStyle(
                              fontSize: 12, color: C.muted(context, .45))),
                      const SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded,
                          size: 14, color: C.muted(context, .45)),
                    ]),
                  ]),
            ),
          ),
        ]),
      ]);

  /// Dekorativ mini bar chart (API seriyasi yo'q — dizayn ko'rinishi).
  Widget _barChart() {
    const heights = [.34, .46, .40, .58, .52, .70, .64, .88, 1.0];
    return SizedBox(
      height: 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < heights.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: FractionallySizedBox(
                heightFactor: heights[i],
                child: Container(
                  decoration: BoxDecoration(
                    color: i >= heights.length - 2
                        ? C.red
                        : C.muted(context, .18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── QUICK ACTIONS ───────────────────────────
  Widget _quickActions() {
    final items = <(IconData, String, Color, int)>[
      (Icons.apartment_rounded, tr('nav.orgs'), C.brand, 1),
      (Icons.account_balance_rounded, tr('nav.tax'), C.red, 3),
      (Icons.speed_rounded, tr('nav.risk'), C.green, 2),
      (Icons.notifications_rounded, tr('nav.notif'), C.violet, 4),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => homeTab.value = items[i].$4,
                child: Column(children: [
                  _MagneticTap(
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: C.tint(context, items[i].$3),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Icon(items[i].$1, color: items[i].$3, size: 25),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(items[i].$2,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: C.muted(context, .7))),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── BO'LIMLAR (barcha modullar) ───────────────────────────
  Widget _modulesGrid(BuildContext context) {
    final mods = <(IconData, String, Color, Widget)>[
      (Icons.swap_vert_rounded, tr('mod.financial'), C.green, const FinancialScreen()),
      (Icons.account_balance_wallet_outlined, tr('mod.wallet'), C.brand, const WalletScreen()),
      (Icons.currency_exchange_rounded, tr('mod.currency'), C.cyan, const CurrencyScreen()),
      (Icons.description_outlined, tr('mod.documents'), C.blue, const DocumentsScreen()),
      (Icons.receipt_long_outlined, tr('mod.didox'), C.violet, const DidoxScreen()),
      (Icons.assessment_outlined, tr('mod.reports'), C.sky, const ReportsScreen()),
      (Icons.event_note_outlined, tr('mod.calendar'), C.amber, const CalendarScreen()),
      (Icons.people_alt_outlined, tr('mod.employees'), C.violet, const EmployeesScreen()),
      (Icons.groups_outlined, tr('mod.team'), C.brand, const TeamScreen()),
      (Icons.handshake_outlined, tr('mod.counterparty'), C.cyan, const CounterpartyScreen()),
      (Icons.verified_outlined, tr('mod.audit'), C.green, const AuditReportScreen()),
      (Icons.gavel_rounded, tr('mod.enforcement'), C.red, const EnforcementScreen()),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 10,
      childAspectRatio: .84,
      children: [
        for (final m in mods)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => m.$4)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _MagneticTap(
                child: Container(
                  width: 56, height: 56, alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.tint(context, m.$3), borderRadius: BorderRadius.circular(18)),
                  child: Icon(m.$1, color: m.$3, size: 24),
                ),
              ),
              const SizedBox(height: 7),
              Text(m.$2,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: C.muted(context, .72))),
            ]),
          ),
      ],
    );
  }

  // ─────────────────────────── FIRMALAR ───────────────────────────
  Widget _orgSection(List orgs) {
    if (orgs.isEmpty) {
      return _card(
        onTap: () => homeTab.value = 1,
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: C.tint(context, C.brand),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.add_business_rounded, color: C.brand, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('dash.addFirm'),
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: C.text(context))),
              const SizedBox(height: 2),
              Text(tr('dash.startTracking'),
                  style: TextStyle(fontSize: 12, color: C.muted(context, .5))),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: C.muted(context, .4)),
        ]),
      );
    }
    return Column(
      children: [
        for (final o in orgs.take(5)) ...[
          _orgRow(o as Map),
          const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget _orgRow(Map o) {
    final name = (o['name'] ?? '').toString();
    final stir = (o['stir'] ?? '').toString();
    final debt = (o['debt'] ?? 0) as num;
    final clean = debt <= 0;
    final col = clean ? C.green : C.red;
    final words = name.trim().split(RegExp(r'\s+'));
    final mono = (words.length >= 2
            ? '${words[0][0]}${words[1][0]}'
            : (name.length >= 2 ? name.substring(0, 2) : name))
        .toUpperCase();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => homeTab.value = 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42, alignment: Alignment.center,
            decoration: BoxDecoration(
                color: C.tint(context, col),
                borderRadius: BorderRadius.circular(13)),
            child: Text(mono,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: clean ? C.onGrn(context) : C.onRed(context))),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: C.text(context))),
              if (stir.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('STIR $stir',
                    style: TextStyle(fontSize: 11.5, color: C.muted(context, .5))),
              ],
            ]),
          ),
          const SizedBox(width: 10),
          if (clean)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: C.tint(context, C.green),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(tr('dash.clean'),
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: C.onGrn(context))),
            )
          else
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(money(debt),
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.3,
                      color: C.red)),
              const SizedBox(height: 1),
              Text(tr('dash.debt'),
                  style: TextStyle(fontSize: 11, color: C.muted(context, .45))),
            ]),
        ]),
      ),
    );
  }

  // ─────────────────────────── SO'NGGI XABARLAR ───────────────────────────
  (IconData, Color) _notifStyle(String type, String priority) {
    if (type.contains('security')) return (Icons.lock_outline_rounded, C.violet);
    if (priority == 'high' || type.contains('tax') || type.contains('debt') || type.contains('penalty')) {
      return (Icons.account_balance_rounded, C.red);
    }
    if (type.contains('ai')) return (Icons.auto_awesome_rounded, C.brand);
    if (type.contains('paid') || type.contains('success')) return (Icons.check_rounded, C.green);
    if (type.contains('report') || type.contains('deadline')) return (Icons.warning_amber_rounded, C.amber);
    return (Icons.notifications_rounded, C.brand);
  }

  Widget _recentSection(List recent) => Column(
        children: [
          for (final n in recent.take(3)) ...[
            _recentRow(n as Map),
            const SizedBox(height: 9),
          ],
        ],
      );

  Widget _recentRow(Map n) {
    final st = _notifStyle((n['type'] ?? '').toString(), (n['priority'] ?? '').toString());
    final unread = n['read'] != true;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => homeTab.value = 4,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38, alignment: Alignment.center,
            decoration: BoxDecoration(color: C.tint(context, st.$2), borderRadius: BorderRadius.circular(12)),
            child: Icon(st.$1, color: st.$2, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text((n['title'] ?? '').toString(),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.text(context))),
              const SizedBox(height: 2),
              Text((n['date'] ?? '').toString(),
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .45))),
            ]),
          ),
          if (unread)
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: C.red, shape: BoxShape.circle)),
        ]),
      ),
    );
  }

  // ─────────────────────────── FINN AI ───────────────────────────
  Widget _ai(int overdue, num penalty) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF080D1C).withValues(alpha: .22),
                blurRadius: 32,
                offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF101728), Color(0xFF0A0F1E), Color(0xFF121B33)],
                    stops: [0, .6, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -120,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    C.brand.withValues(alpha: .4),
                    C.brand.withValues(alpha: 0),
                  ], stops: const [0, .64]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: .8)),
                      const SizedBox(width: 9),
                      Text(tr('dash.finnAi'),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: .55))),
                    ]),
                    const SizedBox(height: 15),
                    Text(
                        overdue > 0
                            ? tr('dash.aiOverdueTitle')
                            : tr('dash.aiStableTitle'),
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.5,
                            height: 1.28,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.55,
                            color: Colors.white.withValues(alpha: .62)),
                        children: overdue > 0
                            ? [
                                TextSpan(text: '${tr('dash.total')} '),
                                TextSpan(
                                    text: '+${money(penalty)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white)),
                                TextSpan(
                                    text:
                                        ' ${tr('common.som')} ${tr('dash.penalty')}. ${tr('dash.aiOverdueBody')}'),
                              ]
                            : [
                                TextSpan(
                                    text: tr('dash.aiStableBody')),
                              ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    _MagneticTap(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openChat,
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .94),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(tr('common.review'),
                                style: const TextStyle(
                                    color: Color(0xFF0A0F1E),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                  ]),
            ),
          ]),
        ),
      );
}

/// Bosilganda arziyol siqiladigan (magnetic) effekt.
class _MagneticTap extends StatefulWidget {
  final Widget child;
  const _MagneticTap({required this.child});
  @override
  State<_MagneticTap> createState() => _MagneticTapState();
}

class _MagneticTapState extends State<_MagneticTap> {
  double _s = 1;
  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          HapticFeedback.selectionClick();
          setState(() => _s = .96);
        },
        onPointerUp: (_) => setState(() => _s = 1),
        onPointerCancel: (_) => setState(() => _s = 1),
        child: AnimatedScale(
            scale: _s,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            child: widget.child),
      );
}
