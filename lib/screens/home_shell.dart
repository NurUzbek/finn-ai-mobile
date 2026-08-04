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
    // Xavfsizlik taymeri: 8 soniyada yuklanmasa — majburan tugallangan deb belgilaymiz.
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) PlanState.i.markLoaded();
    });
  }

  @override
  void dispose() {
    PlanState.i.removeListener(_onPlan);
    super.dispose();
  }

  void _onPlan() { if (mounted) setState(() {}); }

  Future<void> logout() async {
    await Api.logout();
    PlanState.i.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  /// AI konsultant tugmasi — brend gradientli doira, o'ng-past burchakda.
  Widget _chatFab(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [C.blue, C.cyan],
            ),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: C.blue.withValues(alpha: .45), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
        ),
      );

  /// Tarifda yo'q bo'lim ikonkasi ustida qulf belgisi ko'rinadi.
  Widget _lockable(IconData icon, {required bool locked, Color? color}) {
    final base = Icon(icon, color: color);
    if (!locked) return base;
    return Stack(clipBehavior: Clip.none, children: [
      base,
      Positioned(
        right: -5, top: -4,
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(color: C.amber, shape: BoxShape.circle),
          child: const Icon(Icons.lock, size: 8, color: Colors.white),
        ),
      ),
    ]);
  }

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
      drawer: _drawer(context),
      body: IndexedStack(index: _i, children: _tabs),
      // AI konsultant — barcha tablarda ko'rinadigan suzuvchi tugma.
      floatingActionButton: _chatFab(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: C.card(context),
          border: Border(top: BorderSide(color: C.border(context, .06))),
          boxShadow: C.isDark(context)
              ? null
              : [BoxShadow(color: C.inkLight.withValues(alpha: .05), blurRadius: 16, offset: const Offset(0, -3))],
        ),
        child: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          backgroundColor: Colors.transparent,
          indicatorColor: C.blue.withValues(alpha: .18),
          height: 66,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard, color: C.cyan), label: 'Asosiy'),
            const NavigationDestination(icon: Icon(Icons.business_outlined), selectedIcon: Icon(Icons.business, color: C.cyan), label: 'Firmalar'),
            NavigationDestination(
              icon: _lockable(Icons.speed_outlined, locked: riskLocked),
              selectedIcon: _lockable(Icons.speed_rounded, locked: riskLocked, color: C.cyan),
              label: 'Risk',
            ),
            const NavigationDestination(icon: Icon(Icons.account_balance_outlined), selectedIcon: Icon(Icons.account_balance, color: C.cyan), label: 'Soliq'),
            const NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications, color: C.cyan), label: 'Xabarlar'),
            const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: C.cyan), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
