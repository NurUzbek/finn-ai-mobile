import 'package:flutter/material.dart';
import '../main.dart' show homeTab;
import '../theme/finn_tokens.dart';
import '../services/perm.dart';
import '../services/i18n.dart';
import '../screens/financial_screen.dart';
import '../screens/wallet_screen.dart';
import '../screens/currency_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/didox_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/employees_screen.dart';
import '../screens/team_screen.dart';
import '../screens/counterparty_screen.dart';
import '../screens/audit_report_screen.dart';
import '../screens/enforcement_screen.dart';
import '../screens/subscription_screen.dart';

/// Barcha modullar menyusi — eski Drawer o'rniga (FinnScreen'da drawer yo'q).
/// Header'dagi menu tugmasidan chaqiriladi.
void showModulesSheet(BuildContext context) {
  final t = context.tokens;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ModulesSheet(t: t),
  );
}

class _Mod {
  const _Mod(this.icon, this.label, this.color, this.builder, {this.perm, this.tab});
  final IconData icon;
  final String label;
  final Color color;
  final WidgetBuilder builder;
  final String? perm; // ko'rish ruxsati (null = doim ochiq)
  final int? tab; // null bo'lmasa — pastki nav tab'iga o'tadi (push emas)
}

class _ModulesSheet extends StatelessWidget {
  const _ModulesSheet({required this.t});
  final FinnTokens t;

  @override
  Widget build(BuildContext context) {
    // ── Texnik topshiriq (TZ) modullariga MOSLANGAN ──
    // Bo'lim sarlavhalari = TZ mobil modullari (Mening tashkilotlarim / Monitoring /
    // Ma'lumotlar). Har bir quyi-modul shu 5 tadan biriga taqsimlangan.
    // "Asosiy" va "Bildirishnomalar" — pastki navigatsiya tab'lari.
    final dummy = (BuildContext _) => const SizedBox();
    final allSections = <(String, List<_Mod>)>[
      // TZ: "Mening tashkilotlarim"
      (tr('mods.secOrgs'), [
        _Mod(Icons.apartment_rounded, tr('mods.orgs'), t.blue, dummy, tab: 1),
        _Mod(Icons.handshake_outlined, tr('mods.counterparties'), t.cyan, (_) => const CounterpartyScreen()),
        _Mod(Icons.groups_outlined, tr('mods.team'), t.purple, (_) => const TeamScreen(), perm: 'users.view'),
      ]),
      // TZ: "Monitoring" (kirim/chiqim va boshqa ma'lumotlar)
      (tr('mods.secMonitoring'), [
        _Mod(Icons.swap_vert_rounded, tr('mods.income'), t.green, (_) => const FinancialScreen(), perm: 'financial.view'),
        _Mod(Icons.account_balance_wallet_outlined, tr('mods.wallet'), t.blue, (_) => const WalletScreen(), perm: 'financial.view'),
        _Mod(Icons.currency_exchange_rounded, tr('mods.currencyRates'), t.cyan, (_) => const CurrencyScreen()),
        _Mod(Icons.description_outlined, tr('mods.documents'), t.blue, (_) => const DocumentsScreen(), perm: 'documents.view'),
        _Mod(Icons.receipt_long_outlined, tr('mods.didox'), t.purple, (_) => const DidoxScreen(), perm: 'documents.view'),
        _Mod(Icons.gavel_rounded, tr('mods.enforcement'), t.red, (_) => const EnforcementScreen()),
      ]),
      // TZ: "Ma'lumotlar" (foyda/zarar, soliq & QQS hisobotlari, ish haqi)
      (tr('mods.secData'), [
        _Mod(Icons.account_balance_rounded, tr('mods.taxDebt'), t.red, dummy, tab: 3),
        _Mod(Icons.speed_rounded, tr('mods.riskAnalysis'), t.amber, dummy, tab: 2),
        _Mod(Icons.assessment_outlined, tr('mods.reports'), t.blue, (_) => const ReportsScreen(), perm: 'reports.view'),
        _Mod(Icons.people_alt_outlined, tr('mods.employees'), t.purple, (_) => const EmployeesScreen(), perm: 'employees.view'),
        _Mod(Icons.verified_outlined, tr('mods.audit'), t.green, (_) => const AuditReportScreen(), perm: 'audit.view'),
        _Mod(Icons.event_note_outlined, tr('mods.workCalendar'), t.amber, (_) => const CalendarScreen()),
      ]),
      // Akkaunt
      (tr('mods.secAccount'), [
        _Mod(Icons.workspace_premium_outlined, tr('mods.subscription'), t.amber, (_) => const SubscriptionScreen(), perm: 'subscriptions.view'),
      ]),
    ];
    // RBAC — foydalanuvchi ruxsatiga qarab modullarni filtrlaymiz.
    final sections = allSections
        .map((s) => (s.$1, s.$2.where((m) => PermState.i.canView(m.perm)).toList()))
        .where((s) => s.$2.isNotEmpty)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(FinnTokens.rXl)),
          border: Border.all(color: t.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: t.ink4, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(children: [
                Text(tr('mods.all'), style: FinnText.cardTitle(t.ink)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(FinnTokens.rSm),
                        border: Border.all(color: t.line)),
                    child: Icon(Icons.close_rounded, size: 18, color: t.ink2),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                children: [
                  for (final (title, mods) in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 16, 6, 8),
                      child: Text(title, style: FinnText.eyebrow(t.ink3)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(FinnTokens.rLg),
                        border: Border.all(color: t.line),
                        boxShadow: t.sh,
                      ),
                      child: Column(children: [
                        for (var i = 0; i < mods.length; i++) ...[
                          if (i > 0)
                            Divider(height: 1, thickness: 1, color: t.line2, indent: 62),
                          _row(context, mods[i]),
                        ],
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, _Mod m) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(context);
          if (m.tab != null) {
            homeTab.value = m.tab!; // pastki nav tab'iga o'tamiz
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: m.builder));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: m.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(FinnTokens.rMd)),
              child: Icon(m.icon, color: m.color, size: 19),
            ),
            const SizedBox(width: 13),
            Expanded(child: Text(m.label, style: FinnText.rowTitle(t.ink))),
            Icon(Icons.chevron_right_rounded, size: 18, color: t.ink4),
          ]),
        ),
      );
}
