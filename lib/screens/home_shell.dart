import 'dart:ui';
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/plan.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'organizations_screen.dart';
import 'risk_screen.dart';
import 'tax_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'financial_screen.dart';
import 'wallet_screen.dart';
import 'documents_screen.dart';
import 'reports_screen.dart';
import 'didox_screen.dart';
import 'counterparty_screen.dart';
import 'enforcement_screen.dart';
import 'employees_screen.dart';
import 'team_screen.dart';
import 'audit_report_screen.dart';
import 'calendar_screen.dart';
import 'currency_screen.dart';
import 'subscription_screen.dart';

/// TZ 2-jadval: mobil ilova modullari — Asosiy, Mening tashkilotlarim,
/// Risk tahlil (tarifga bog'liq), Monitoring (soliq), Bildirishnomalar, Ma'lumotlar (profil).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  static const _tabs = [
    DashboardScreen(),
    OrganizationsScreen(),
    RiskScreen(),
    TaxScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Tarif ilova ochilishida bir marta yuklanadi — bo'limlar shunga qarab qulflanadi.
    PlanState.i.addListener(_onPlan);
    PlanState.i.load();
    // Dashboard tugmalari pastki tabni almashtira olishi uchun
    homeTab.addListener(_onTab);
    // Xavfsizlik taymeri: 8 soniyada yuklanmasa — majburan tugallangan deb belgilaymiz.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) PlanState.i.markLoaded();
    });
  }

  @override
  void dispose() {
    PlanState.i.removeListener(_onPlan);
    homeTab.removeListener(_onTab);
    super.dispose();
  }

  void _onPlan() { if (mounted) setState(() {}); }
  void _onTab() { if (mounted && homeTab.value >= 0 && homeTab.value < _tabs.length) setState(() => _i = homeTab.value); }

  Future<void> logout() async {
    await Api.logout();
    PlanState.i.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  /// AI konsultant — suzuvchi gradient tugma (nav ustida, o'ngda).
  Widget _fab(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: C.grad,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .4), blurRadius: 24, offset: const Offset(0, 8))],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
        ),
      );

  static const _nav = [
    (Icons.dashboard_rounded, 'Asosiy'),
    (Icons.apartment_rounded, 'Firmalar'),
    (Icons.speed_rounded, 'Risk'),
    (Icons.account_balance_rounded, 'Soliq'),
    (Icons.notifications_rounded, 'Xabar'),
    (Icons.person_rounded, 'Profil'),
  ];

  Widget _navIcon(IconData ic, bool active, bool locked) {
    final base = Icon(ic, size: 20, color: active ? Colors.white : C.muted(context, .5));
    if (!locked) return base;
    return Stack(clipBehavior: Clip.none, children: [
      base,
      Positioned(right: -4, top: -3, child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(color: C.amber, shape: BoxShape.circle),
        child: const Icon(Icons.lock, size: 7, color: Colors.white),
      )),
    ]);
  }

  /// Suzuvchi shisha (glass) pill navigatsiya — aktiv tab kengayib yorliqni ko'rsatadi.
  Widget _glassNav(BuildContext context, bool riskLocked) => ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 62,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: C.card(context).withValues(alpha: .72),
              borderRadius: BorderRadius.circular(31),
              border: Border.all(color: C.border(context, .09)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: C.isDark(context) ? .3 : .12), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(_nav.length, (i) {
              final active = _i == i;
              final locked = i == 2 && riskLocked;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () { homeTab.value = i; setState(() => _i = i); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic,
                  width: active ? 104 : 40, height: 44,
                  decoration: BoxDecoration(
                    gradient: active ? C.grad : null,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: active ? [BoxShadow(color: C.brand.withValues(alpha: .34), blurRadius: 12, offset: const Offset(0, 4))] : null,
                  ),
                  child: ClipRect(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _navIcon(_nav[i].$1, active, locked),
                    if (active) Flexible(child: Padding(
                      padding: const EdgeInsets.only(left: 7),
                      child: Text(_nav[i].$2, maxLines: 1, softWrap: false, overflow: TextOverflow.clip,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5, letterSpacing: -.2)),
                    )),
                  ])),
                ),
              );
            })),
          ),
        ),
      );

  /// Barcha modullar menyusi (veb bilan parity) — chiroyli native drawer.
  Widget _drawer(BuildContext context) {
    Widget item(IconData ic, String label, Widget screen, Color col) => ListTile(
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: col.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
            child: Icon(ic, color: col, size: 20),
          ),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: C.text(context))),
          trailing: Icon(Icons.chevron_right, size: 18, color: C.muted(context, .3)),
          onTap: () {
            Navigator.pop(context);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
          },
        );
    Widget section(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: C.muted(context, .45))),
        );

    return Drawer(
      backgroundColor: C.bg(context),
      child: SafeArea(
        child: ListView(padding: EdgeInsets.zero, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset('assets/logo.png', width: 44, height: 44, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Text('FINN AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.text(context))),
            ]),
          ),
          section('MOLIYA'),
          item(Icons.swap_vert_rounded, 'Kirim va chiqim', const FinancialScreen(), C.green),
          item(Icons.account_balance_wallet_outlined, 'Hamyon', const WalletScreen(), C.blue),
          item(Icons.currency_exchange_rounded, 'Valyuta kurslari', const CurrencyScreen(), C.cyan),
          section('HUJJATLAR'),
          item(Icons.description_outlined, 'Hujjatlar', const DocumentsScreen(), C.blue),
          item(Icons.receipt_long_outlined, 'E-hujjat (Didox)', const DidoxScreen(), C.violet),
          item(Icons.assessment_outlined, 'Hisobotlar', const ReportsScreen(), C.sky),
          item(Icons.event_note_outlined, 'Ish kalendari', const CalendarScreen(), C.amber),
          section('BIZNES'),
          item(Icons.people_alt_outlined, 'Xodimlar', const EmployeesScreen(), C.violet),
          item(Icons.groups_outlined, 'Jamoa va rollar', const TeamScreen(), C.blue),
          item(Icons.handshake_outlined, 'Kontragentlar', const CounterpartyScreen(), C.cyan),
          section('NAZORAT'),
          item(Icons.verified_outlined, 'Audit hisoboti', const AuditReportScreen(), C.green),
          item(Icons.gavel_rounded, 'Ijro hujjatlari', const EnforcementScreen(), C.red),
          section('HISOB'),
          item(Icons.workspace_premium_outlined, 'Obuna / Tarif', const SubscriptionScreen(), C.amber),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskLocked = PlanState.i.loaded && !PlanState.i.has('risk');

    return Scaffold(
      key: homeScaffoldKey,
      backgroundColor: C.bg(context),
      drawer: _drawer(context),
      body: Stack(children: [
        Positioned.fill(child: IndexedStack(index: _i, children: _tabs)),
        // Suzuvchi shisha navigatsiya
        Positioned(left: 14, right: 14, bottom: 20, child: _glassNav(context, riskLocked)),
        // AI konsultant tugmasi — nav ustida, o'ngda
        Positioned(right: 18, bottom: 96, child: _fab(context)),
      ]),
    );
  }
}
