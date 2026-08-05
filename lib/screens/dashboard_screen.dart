import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import 'financial_screen.dart';
import 'chat_screen.dart';
import 'currency_screen.dart';
import 'documents_screen.dart';
import 'didox_screen.dart';
import 'counterparty_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _f = Api.dashboard();
  Future<void> _refresh() async => setState(() => _f = Api.dashboard());

  void _push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

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
              final totalBalance = orgs.fold<double>(
                  0, (a, o) => a + ((o['balance'] ?? 0) as num).toDouble());
              final orgCount = orgs.length;
              final overdue = ((s['overdue_count'] ?? 0) as num).toInt();
              final clean = (orgCount - overdue).clamp(0, orgCount);
              final debt = (s['debts_total'] ?? 0) as num;
              final penalty = (s['penalty_total'] ?? 0) as num;
              final daily = (d['daily'] ?? 0) as num;

              final cf = (d['cashflow'] as Map?) ?? {};
              final income = (cf['income'] ?? 0) as num;
              final expense = (cf['expense'] ?? 0) as num;
              final net = (cf['net'] ?? (income - expense)) as num;

              final deadlines = ((d['deadlines'] as List?) ?? []).cast<dynamic>();
              final risk = d['risk'] as Map?;

              final pad = 110 + MediaQuery.of(context).viewPadding.bottom;

              return ListView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(20, 6, 20, pad),
                children: [
                  StaggerIn(index: 0, child: _header()),
                  const SizedBox(height: 18),
                  StaggerIn(
                      index: 1,
                      child: _hero(totalBalance, orgCount, clean, overdue)),
                  const SizedBox(height: 11),
                  StaggerIn(index: 2, child: _live(penalty, daily)),

                  if (deadlines.isNotEmpty) ...[
                    StaggerIn(
                        index: 3,
                        child: _eyebrow('Yaqin muddatlar',
                            action: 'Kalendar', onAction: () => homeTab.value = 1)),
                    StaggerIn(index: 4, child: _deadlineStrip(deadlines)),
                  ],

                  StaggerIn(
                      index: 5,
                      child: _eyebrow('Pul oqimi',
                          action: 'Batafsil',
                          onAction: () => _push(const FinancialScreen()))),
                  StaggerIn(
                      index: 6, child: _cashflow(net, income, expense)),

                  StaggerIn(index: 7, child: _eyebrow('Holat')),
                  StaggerIn(
                      index: 8,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _riskCard(risk)),
                          const SizedBox(width: 11),
                          Expanded(child: _debtCard(debt, overdue)),
                        ],
                      )),

                  StaggerIn(index: 9, child: _eyebrow('Finn AI')),
                  StaggerIn(index: 10, child: _ai(overdue, penalty, daily)),

                  StaggerIn(index: 11, child: _eyebrow('Tez kirish')),
                  StaggerIn(index: 12, child: _quick()),
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
              Text('Aloqa yo\'q',
                  style: TextStyle(color: C.muted(context, .6))),
              const SizedBox(height: 16),
              FilledButton(onPressed: _refresh, child: const Text('Qayta urinish')),
            ]),
          ),
        ],
      );

  // ─────────────────────────── HEADER ───────────────────────────
  Widget _header() => Row(
        children: [
          _iconBtn(Icons.menu_rounded,
              onTap: () => homeScaffoldKey.currentState?.openDrawer()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Asosiy',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                      height: 1.05,
                      color: C.text(context))),
              const SizedBox(height: 2),
              Text('Umumiy holat bir ko\'rishda',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: C.muted(context, .5))),
            ]),
          ),
          _iconBtn(Icons.notifications_none_rounded,
              onTap: () => homeTab.value = 4),
        ],
      );

  Widget _iconBtn(IconData ic, {VoidCallback? onTap}) => GestureDetector(
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
          child: Icon(ic, size: 19, color: C.muted(context, .8)),
        ),
      );

  // ─────────────────────────── HERO / BALANS ───────────────────────────
  Widget _hero(double bal, int orgs, int clean, int overdue) => GestureDetector(
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
                child: DecoratedBox(decoration: BoxDecoration(gradient: C.grad)),
              ),
              // Oq radial nur (o'ng-yuqori).
              Positioned(
                right: -110,
                top: -140,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      Colors.white.withValues(alpha: .26),
                      Colors.white.withValues(alpha: 0),
                    ], stops: const [0, .6]),
                  ),
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UMUMIY BALANS',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: Colors.white.withValues(alpha: .66))),
                        const SizedBox(height: 10),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: bal),
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
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.7,
                                        height: 1)),
                                TextSpan(
                                    text: '  so\'m',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: .68),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500)),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                ),
                // Sparkline (chekkadan chekkaga).
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 46,
                    width: double.infinity,
                    child: CustomPaint(painter: _SparkPainter()),
                  ),
                ),
                // Statistika qatori.
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: .2))),
                  ),
                  child: Row(children: [
                    _hstat('$orgs', 'Tashkilot'),
                    _hstat('$clean', 'Toza'),
                    _hstat('$overdue', 'Kechikkan'),
                  ]),
                ),
              ]),
            ]),
          ),
        ),
      );

  Widget _hstat(String v, String l) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.6)),
          const SizedBox(height: 3),
          Text(l,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .66),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  // ─────────────────────────── JONLI PENYA ───────────────────────────
  Widget _live(num penalty, num daily) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => homeTab.value = 3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: C.tint(context, C.red),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const _Beat(),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penya hozir hisoblanmoqda',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: C.onRed(context).withValues(alpha: .9))),
                    const SizedBox(height: 3),
                    Text(money(penalty),
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.8,
                            height: 1,
                            color: C.onRed(context))),
                  ]),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('+${money(daily)}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.4,
                      color: C.onRed(context))),
              const SizedBox(height: 2),
              Text('so\'m/kun',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: C.onRed(context).withValues(alpha: .7))),
            ]),
          ]),
        ),
      );

  // ─────────────────────────── MUDDATLAR ───────────────────────────
  Widget _deadlineStrip(List deadlines) => SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: deadlines.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _deadlineCard(deadlines[i] as Map),
        ),
      );

  Widget _deadlineCard(Map dl) {
    final title = (dl['title'] ?? '').toString();
    final date = (dl['date'] ?? '').toString();
    final days = ((dl['days'] ?? 0) as num).toInt();
    final col = days <= 7
        ? C.red
        : days <= 30
            ? C.amber
            : C.green;
    // Kam kun → to'liqroq / qizilroq halqa.
    final frac = (1 - days / 60).clamp(.08, 1.0).toDouble();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => homeTab.value = 1,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(alignment: Alignment.center, children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: frac),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => CustomPaint(
                      size: const Size(44, 44),
                      painter: _RingPainter(
                          fraction: v,
                          color: col,
                          track: C.muted(context, .12),
                          stroke: 4),
                    ),
                  ),
                  Text('$days',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.5,
                          color: C.text(context))),
                ]),
              ),
              const SizedBox(height: 12),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.2,
                      color: C.text(context))),
              const SizedBox(height: 3),
              Text(date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: C.muted(context, .45))),
            ]),
      ),
    );
  }

  // ─────────────────────────── PUL OQIMI ───────────────────────────
  Widget _cashflow(num net, num income, num expense) {
    final pos = net >= 0;
    final pct = income > 0 ? (net / income * 100).round() : 0;
    return _card(
      onTap: () => _push(const FinancialScreen()),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SOF FOYDA',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                          color: C.muted(context, .4))),
                  const SizedBox(height: 9),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('${pos ? '+' : ''}${money(net)}',
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1,
                            color: pos ? C.onGrn(context) : C.onRed(context))),
                  ),
                ]),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: C.tint(context, pos ? C.green : C.red),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${pct >= 0 ? '+' : ''}$pct%',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pos ? C.onGrn(context) : C.onRed(context))),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 92,
          width: double.infinity,
          child: CustomPaint(painter: _AreaPainter()),
        ),
        const SizedBox(height: 14),
        Row(children: [
          _legend(C.green, 'Kirim ${money(income)}'),
          const SizedBox(width: 16),
          _legend(C.red, 'Chiqim ${money(expense)}'),
        ]),
      ]),
    );
  }

  Widget _legend(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Flexible(
          child: Text(t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: C.muted(context, .6))),
        ),
      ]);

  // ─────────────────────────── RISK + QARZ ───────────────────────────
  Widget _riskCard(Map? risk) {
    final has = risk != null;
    final score = ((risk?['score'] ?? 0) as num).toInt();
    final col = score <= 30
        ? C.green
        : score <= 60
            ? C.amber
            : C.red;
    final onCol = score <= 30
        ? C.onGrn(context)
        : score <= 60
            ? C.onAmb(context)
            : C.onRed(context);
    final level = (risk?['level'] ?? '').toString().isNotEmpty
        ? risk!['level'].toString()
        : (score <= 30
            ? 'Past'
            : score <= 60
                ? 'O\'rta'
                : 'Yuqori');
    return _card(
      onTap: () => homeTab.value = 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: has ? score / 100 : 0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(
                size: const Size(96, 96),
                painter: _RingPainter(
                    fraction: v,
                    color: has ? col : C.muted(context, .3),
                    track: C.muted(context, .1),
                    stroke: 8),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(has ? '$score' : '—',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1,
                      color: has ? onCol : C.muted(context, .55))),
              const SizedBox(height: 2),
              Text('ball',
                  style: TextStyle(fontSize: 10, color: C.muted(context, .45))),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Text('RISK DARAJASI',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: C.muted(context, .4))),
        const SizedBox(height: 5),
        Text(has ? level : 'Batafsil',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -.3,
                color: has ? onCol : C.muted(context, .55))),
      ]),
    );
  }

  Widget _debtCard(num debt, int overdue) {
    return _card(
      onTap: () => homeTab.value = 3,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: C.tint(context, C.red),
              borderRadius: BorderRadius.circular(11)),
          child: Icon(Icons.account_balance_rounded,
              size: 17, color: C.onRed(context)),
        ),
        const SizedBox(height: 14),
        Text('UMUMIY QARZ',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: C.muted(context, .4))),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: debt.toDouble()),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(v),
                style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                    height: 1,
                    color: C.red)),
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Stack(children: [
              Positioned.fill(child: ColoredBox(color: C.muted(context, .1))),
              FractionallySizedBox(
                widthFactor: debt > 0 ? 1 : 0,
                child: const ColoredBox(color: C.red),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text('$overdue ta kechikkan to\'lov',
            style: TextStyle(fontSize: 11.5, color: C.muted(context, .5))),
      ]),
    );
  }

  // ─────────────────────────── FINN AI ───────────────────────────
  Widget _ai(int overdue, num penalty, num daily) {
    final title = overdue > 0 ? 'Kechikkan to\'lovni yoping' : 'Moliya barqaror';
    final bodySpans = overdue > 0
        ? <TextSpan>[
            const TextSpan(text: 'Kuniga '),
            TextSpan(
                text: '${money(daily)} so\'m',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.white)),
            const TextSpan(
                text:
                    ' — penya shu qarzdan o\'sib bormoqda. Yopsangiz kunlik o\'sish to\'xtaydi.'),
          ]
        : <TextSpan>[
            const TextSpan(
                text:
                    'Barcha to\'lovlar joyida, hozircha jarima yo\'q. Shu holatni saqlab qoling.'),
          ];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _push(const ChatScreen()),
      child: Container(
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
              left: -100,
              bottom: -150,
              child: Container(
                width: 260,
                height: 260,
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
                          size: 16, color: Colors.white.withValues(alpha: .8)),
                      const SizedBox(width: 9),
                      Text('BUGUNGI TAVSIYA',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.4,
                              color: Colors.white.withValues(alpha: .55))),
                    ]),
                    const SizedBox(height: 15),
                    Text(title,
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
                            color: Colors.white.withValues(alpha: .64)),
                        children: bodySpans,
                      ),
                    ),
                    const SizedBox(height: 17),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Ko\'rib chiqish',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 7),
                        Icon(Icons.arrow_forward_rounded,
                            size: 15, color: Colors.white.withValues(alpha: .9)),
                      ]),
                    ),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────── TEZ KIRISH ───────────────────────────
  Widget _quick() {
    final items = <(IconData, String, Color, Widget)>[
      (Icons.description_outlined, 'Hujjatlar', C.blue, const DocumentsScreen()),
      (Icons.receipt_long_outlined, 'Didox', C.violet, const DidoxScreen()),
      (Icons.currency_exchange_rounded, 'Valyuta', C.teal, const CurrencyScreen()),
      (Icons.handshake_outlined, 'Kontragent', C.amber, const CounterpartyScreen()),
    ];
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 9),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _push(items[i].$4),
            child: Column(children: [
              _MagneticTap(
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: C.tint(context, items[i].$3),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(items[i].$1, color: items[i].$3, size: 23),
                ),
              ),
              const SizedBox(height: 8),
              Text(items[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: C.muted(context, .7))),
            ]),
          ),
        ),
      ],
    ]);
  }

  // ─────────────────────────── SHARED ───────────────────────────
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

  Widget _eyebrow(String label, {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
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
}

// ══════════════════════════ PAINTERS ══════════════════════════

/// Aylana halqa (progress). Yuqoridan boshlanadi, soat yo'nalishida.
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;
  final double stroke;
  const _RingPainter(
      {required this.fraction,
      required this.color,
      required this.track,
      required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (size.shortestSide - stroke) / 2;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(center, r, bg);
    if (fraction <= 0) return;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -math.pi / 2,
        2 * math.pi * fraction.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.fraction != fraction || o.color != color || o.track != track;
}

/// Balans hero sparkline (oq maydon + chiziq).
class _SparkPainter extends CustomPainter {
  static const _xs = [0.0, .123, .25, .373, .5, .623, .75, .873, 1.0];
  static const _ys = [.826, .696, .761, .522, .609, .370, .457, .196, .087];

  @override
  void paint(Canvas canvas, Size size) {
    final pts = <Offset>[
      for (var i = 0; i < _xs.length; i++)
        Offset(_xs[i] * size.width, _ys[i] * size.height),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final area = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = Colors.white.withValues(alpha: .16));
    canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white.withValues(alpha: .9));
  }

  @override
  bool shouldRepaint(_SparkPainter o) => false;
}

/// Pul oqimi: kirim (yashil, to'ldirilgan) + chiqim (qizil) chiziqlari.
class _AreaPainter extends CustomPainter {
  static const _xs = [0.0, .167, .333, .5, .667, .833, 1.0];
  static const _in = [.674, .587, .630, .457, .522, .326, .239];
  static const _out = [.804, .761, .717, .739, .652, .630, .565];

  Path _line(Size s, List<double> ys) {
    final p = Path()..moveTo(0, ys.first * s.height);
    for (var i = 1; i < _xs.length; i++) {
      p.lineTo(_xs[i] * s.width, ys[i] * s.height);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final inLine = _line(size, _in);
    final fill = Path.from(inLine)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              C.green.withValues(alpha: .26),
              C.green.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        inLine,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = C.green);
    canvas.drawPath(
        _line(size, _out),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = C.red);
  }

  @override
  bool shouldRepaint(_AreaPainter o) => false;
}

// ══════════════════════════ WIDGETS ══════════════════════════

/// Jonli penya nishoni — pulsatsiyalanuvchi qizil nuqta.
class _Beat extends StatefulWidget {
  const _Beat();
  @override
  State<_Beat> createState() => _BeatState();
}

class _BeatState extends State<_Beat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 9,
        height: 9,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -6,
                top: -6,
                right: -6,
                bottom: -6,
                child: Opacity(
                  opacity: (1 - _c.value).clamp(0, 1) * .6,
                  child: Transform.scale(
                    scale: .4 + _c.value * 1.2,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: C.red, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration:
                    const BoxDecoration(color: C.red, shape: BoxShape.circle),
              ),
            ],
          ),
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
          setState(() => _s = .92);
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
