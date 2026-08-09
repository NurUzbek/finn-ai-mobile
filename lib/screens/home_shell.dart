import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../main.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/finn_bead_nav.dart';
import '../services/sfx.dart';
import '../services/api.dart';
import '../services/plan.dart';
import '../services/perm.dart';
import '../services/push_service.dart';
import 'login_screen.dart';
import 'dashboard_page.dart';
import 'organizations_screen.dart';
import 'financial_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';

/// Ilova karkasi — 6 ta asosiy tab.
///
/// Har tab endi FINN dizayn tizimi bo'yicha `FinnScreen` (o'z header + navi
/// bilan). Shell faqat joriy tabni boshqaradi va `navIndex`/`onNavChanged` ni
/// uzatadi. Eski MENISCUS nav / drawer / FAB FinnBeadNav va modul-sheet bilan
/// almashtirildi.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    // Tarif ilova ochilishida bir marta yuklanadi — bo'limlar shunga qarab qulflanadi.
    PlanState.i.addListener(_onPlan);
    PlanState.i.load();
    // RBAC — rol va ruxsatlarni yuklaymiz (modul/tugmalar shunga qarab).
    PermState.i.load().then((_) { if (mounted) setState(() {}); });
    // TZ 4.2.2 — foydalanuvchi kirgach push tokenni serverga bog'laymiz.
    if (!kIsWeb) PushService.registerAfterLogin();
    // Boshqa ekranlar (push) homeTab orqali tabga sakray oladi.
    homeTab.addListener(_onTab);
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
  void _onTab() {
    if (mounted && homeTab.value >= 0 && homeTab.value < 6) {
      setState(() => _i = homeTab.value);
    }
  }

  /// Nav yoki dashboard tugmalari tabni almashtiradi.
  void _go(int i) {
    if (i == _i) return;
    Sfx.i.pop();
    HapticFeedback.selectionClick();
    homeTab.value = i;
    setState(() => _i = i);
  }

  Future<void> logout() async {
    await Api.logout();
    PlanState.i.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  /// AI konsultant — suzuvchi gradient tugma (nav ustida, o'ngda).
  Widget _aiFab(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ChatScreen())),
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: FinnTokens.brand,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1745C9).withValues(alpha: .42),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 24),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Stack(
      children: [
        IndexedStack(
          index: _i,
          children: [
            DashboardPage(navIndex: 0, onNavChanged: _go),
            OrganizationsScreen(navIndex: 1, onNavChanged: _go),
            const FinancialScreen(asTab: true), // TZ: Monitoring
            const ReportsScreen(asTab: true),   // TZ: Ma'lumotlar
            NotificationsScreen(navIndex: 4, onNavChanged: _go),
            ProfileScreen(navIndex: 5, onNavChanged: _go),
          ],
        ),
        // YAGONA persistent nav — barcha tab'lar uchun bitta. Shu sabab tab
        // bosilganda bead qotib qolmasdan yangi joyga SIRG'ALIB o'tadi.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // Material ajdodi — aks holda nav yorlig'i ostida Flutter'ning sariq
          // "Material yo'q" debug tag chizig'i chiqadi (nav Scaffold tashqarisida).
          child: Material(
            type: MaterialType.transparency,
            child: FinnBeadNav(
              index: _i,
              onChanged: _go,
              items: finnNavItems(),
            ),
          ),
        ),
        // Nav ustida, o'ngda (dizayn: .fabai).
        Positioned(
          right: 16,
          bottom: 112 + bottomInset,
          child: _aiFab(context),
        ),
      ],
    );
  }
}
