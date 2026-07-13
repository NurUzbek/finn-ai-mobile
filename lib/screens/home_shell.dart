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

  @override
  Widget build(BuildContext context) {
    final riskLocked = PlanState.i.loaded && !PlanState.i.has('risk');

    return Scaffold(
      body: IndexedStack(index: _i, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: C.cardDark,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: .06))),
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
