import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import '../widgets/locked.dart';

/// "Asosiy" moduli — analitik boshqaruv paneli (TZ 2-jadval).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _f = Api.dashboard();
  Future<void> _refresh() async => setState(() => _f = Api.dashboard());

  int _period = 2; // 0=Kun, 1=Hafta, 2=Oy (vizual filtr)
  static const _periods = ['Kun', 'Hafta', 'Oy'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        const ScreenHeader(title: 'Asosiy', icon: Icons.dashboard, subtitle: 'Umumiy holat bir ko\'rishda'),
        Expanded(
          child: Loader(
            future: _f,
            onRefresh: _refresh,
            builder: (d) {
              final s = d['stats'] as Map<String, dynamic>;
              final orgs = (d['organizations'] as List).cast<Map<String, dynamic>>();
              final hasDebt = (s['debts_total'] as num) > 0;
              final overdue = (s['overdue_count'] as num?)?.toInt() ?? 0;
              final totalBalance = orgs.fold<double>(0, (a, o) => a + (o['balance'] as num).toDouble());
              final cleanCount = orgs.where((o) => (o['debt'] as num) == 0).length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const PlanBanner(),

                  // Davr tanlagich (pill segmentli)
                  _periodPills(context),
                  const SizedBox(height: 14),

                  // ── Hero karta ──
                  StaggerIn(index: 0, child: _hero(context, totalBalance, orgs.length, hasDebt, overdue, cleanCount)),
                  const SizedBox(height: 16),

                  // Ogohlantirish banneri
                  if (hasDebt)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [C.red.withValues(alpha: .16), C.amber.withValues(alpha: .08)]),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: C.red.withValues(alpha: .3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: C.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('$overdue ta muddati o\'tgan to\'lov',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text('Penya hisoblanmoqda — Soliq bo\'limiga qarang',
                                style: TextStyle(fontSize: 11.5, color: C.muted(context, .6))),
                          ]),
                        ),
                      ]),
                    ),

                  // 4 KPI karta
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.28,
                    children: [
                      StaggerIn(index: 1, child: StatCard(
                        label: 'Tashkilotlar', animateValue: (s['orgs'] as num), value: '${s['orgs']}', icon: Icons.business, color: C.sky,
                        badge: cleanCount > 0 ? TrendChip(text: '$cleanCount toza', color: C.green, icon: Icons.check) : null,
                      )),
                      StaggerIn(index: 2, child: StatCard(
                        label: 'Umumiy qarz', animateValue: (s['debts_total'] as num), valueFormat: money, value: money(s['debts_total']), unit: 'so\'m', icon: Icons.account_balance_wallet, color: C.red,
                        badge: hasDebt ? const TrendChip(text: 'qarz bor', color: C.red, icon: Icons.arrow_upward) : const TrendChip(text: 'toza', color: C.green, icon: Icons.check),
                      )),
                      StaggerIn(index: 3, child: StatCard(
                        label: 'Jami penya', animateValue: (s['penalty_total'] as num), valueFormat: money, value: money(s['penalty_total']), unit: 'so\'m', icon: Icons.trending_up, color: C.amber,
                        badge: overdue > 0 ? TrendChip(text: '$overdue kechik', color: C.amber, icon: Icons.schedule) : null,
                      )),
                      StaggerIn(index: 4, child: StatCard(
                        label: 'O\'qilmagan xabar', animateValue: (s['unread_notifications'] as num), value: '${s['unread_notifications']}', icon: Icons.notifications_active, color: C.violet,
                        badge: (s['unread_notifications'] as num) > 0 ? const TrendChip(text: 'yangi', color: C.violet, icon: Icons.circle) : null,
                      )),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Diagramma ──
                  if (orgs.isNotEmpty) StaggerIn(index: 5, child: _chartCard(context, orgs, hasDebt)),

                  const SizedBox(height: 22),
                  Row(children: [
                    Text('Tashkilotlarim', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: C.text(context))),
                    const Spacer(),
                    Text('${orgs.length} ta', style: TextStyle(fontSize: 12, color: C.muted(context, .4))),
                  ]),
                  const SizedBox(height: 10),

                  ...orgs.asMap().entries.map((e) {
                    final o = e.value;
                    final debt = (o['debt'] as num).toDouble();
                    final ok = debt == 0;
                    return StaggerIn(index: 6 + e.key, child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: C.card(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: C.border(context, .06)),
                        boxShadow: C.isDark(context)
                            ? null
                            : [BoxShadow(color: C.inkLight.withValues(alpha: .04), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: (ok ? C.green : C.red).withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(ok ? Icons.check_circle : Icons.error_outline,
                              color: ok ? C.green : C.red, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(o['name'], maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: C.text(context))),
                            const SizedBox(height: 2),
                            Text('STIR ${o['stir'] ?? '—'}',
                                style: TextStyle(fontSize: 11, color: C.muted(context, .4))),
                          ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text(ok ? 'Qarz yo\'q' : money(debt),
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: ok ? C.green : C.red)),
                          Text('balans ${money(o['balance'])}',
                              style: TextStyle(fontSize: 10.5, color: C.muted(context, .4))),
                        ]),
                      ]),
                    ));
                  }),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── Davr tanlagich ──
  Widget _periodPills(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: C.fill(context, .05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: C.border(context, .05)),
        ),
        child: Row(children: [
          for (var i = 0; i < _periods.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _period = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    gradient: _period == i ? const LinearGradient(colors: [C.blue, C.cyan]) : null,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(_periods[i],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _period == i ? Colors.white : C.muted(context, .5),
                      )),
                ),
              ),
            ),
        ]),
      );

  // ── Hero karta (gradient) ──
  Widget _hero(BuildContext context, double totalBalance, int orgCount, bool hasDebt, int overdue, int cleanCount) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [C.blue, C.cyan],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: C.blue.withValues(alpha: .35), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Umumiy balans', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(hasDebt ? Icons.arrow_downward : Icons.check_circle, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(hasDebt ? '$overdue kechik' : 'Barqaror',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalBalance),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (c, v, _) => Text(money(v),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1)),
              ),
              const SizedBox(width: 6),
              const Text('so\'m', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _heroChip(Icons.business, '$orgCount tashkilot'),
            const SizedBox(width: 10),
            _heroChip(Icons.verified_outlined, '$cleanCount toza'),
          ]),
        ]),
      );

  Widget _heroChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ]),
      );

  // ── Diagramma kartasi ──
  Widget _chartCard(BuildContext context, List<Map<String, dynamic>> orgs, bool useDebt) {
    // Barcha qarz nol bo'lsa — balans bo'yicha ko'rsatamiz (haqqoniy).
    final showDebt = useDebt;
    final vals = orgs.map((o) => ((showDebt ? o['debt'] : o['balance']) as num).toDouble()).toList();
    final maxV = vals.fold<double>(0, (a, b) => b > a ? b : a);
    final safeMax = maxV <= 0 ? 1.0 : maxV;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 12),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: C.border(context, .06)),
        boxShadow: C.isDark(context)
            ? null
            : [BoxShadow(color: C.inkLight.withValues(alpha: .05), blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (showDebt ? C.red : C.cyan).withValues(alpha: .14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(showDebt ? Icons.bar_chart_rounded : Icons.insights_rounded,
                size: 16, color: showDebt ? C.red : C.cyan),
          ),
          const SizedBox(width: 10),
          Text(showDebt ? 'Tashkilotlar bo\'yicha qarz' : 'Tashkilotlar balansi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: C.text(context))),
        ]),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          child: BarChart(
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: safeMax * 1.18,
              barTouchData: BarTouchData(enabled: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: safeMax / 3,
                getDrawingHorizontalLine: (v) => FlLine(color: C.muted(context, .07), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= orgs.length) return const SizedBox.shrink();
                      final name = (orgs[i]['name'] as String).trim();
                      final short = name.length > 6 ? name.substring(0, 6) : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(short, style: TextStyle(fontSize: 9.5, color: C.muted(context, .5))),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < vals.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: vals[i],
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: showDebt ? [C.red.withValues(alpha: .5), C.amber] : [C.blue, C.cyan],
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true, toY: safeMax * 1.18, color: C.muted(context, .05),
                      ),
                    ),
                  ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
