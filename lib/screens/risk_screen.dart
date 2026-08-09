import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/modules_sheet.dart';
import '../widgets/common.dart';
import '../widgets/locked.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../services/plan.dart';
import 'subscription_screen.dart';

/// "Risk tahlil" moduli — FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText).
/// Tarifda `risk` yo'q bo'lsa — ekran ichida kengaytirish taklifi (nav qulflanmaydi).
class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key, this.navIndex = 2, this.onNavChanged});
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  int? _org;
  late Future<Map<String, dynamic>> _f = Api.risk();
  Future<void> _refresh() async => setState(() => _f = Api.risk(org: _org));

  void _selectOrg(int id) {
    if (_org == id) return;
    setState(() {
      _org = id;
      _f = Api.risk(org: _org);
    });
  }

  // Tarif yuklanishi tugagach ekran qayta qurilishi kerak — aks holda
  // dastlab spinner ko'rsatib, keyin qulf/tafsilotga o'tmay qolib ketadi.
  void _onPlan() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    PlanState.i.addListener(_onPlan);
  }

  @override
  void dispose() {
    PlanState.i.removeListener(_onPlan);
    super.dispose();
  }

  // Risk darajasiga mos rang: past → yashil, o'rta → sariq, yuqori → qizil.
  // Ball qanchalik past bo'lsa, shunchalik yaxshi.
  Color _levelColor(FinnTokens t, int s) =>
      s <= 30 ? t.green : (s <= 60 ? t.amber : t.red);
  Color _onColor(FinnTokens t, int s) =>
      s <= 30 ? t.onGrn : (s <= 60 ? t.onAmb : t.onRed);
  Color _tintColor(FinnTokens t, int s) =>
      s <= 30 ? t.tGrn : (s <= 60 ? t.tAmb : t.tRed);

  String _levelLabel(int s) => s <= 30
      ? tr('risk.level.low')
      : (s <= 60 ? tr('risk.level.mid') : tr('risk.level.high'));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('risk.title'),
      subtitle: tr('risk.subtitle'),
      showNav: false,
      reserveNav: true,
      leading: _iconBtn(t, Icons.menu_rounded, onTap: () => showModulesSheet(context)),
      actions: [
        _iconBtn(t, Icons.refresh_rounded, onTap: _refresh),
      ],
      children: [_body(t)],
    );
  }

  Widget _body(FinnTokens t) {
    // Tarif hali yuklanmagan — qulf ekranini chaqnatib yubormaymiz
    if (!PlanState.i.loaded) return _loading(t);
    if (!PlanState.i.has('risk')) return _lockedBody(t);

    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loading(t);
        final d = snap.data ?? {'ok': false};

        // Server tarifni qulflagan bo'lsa (obuna muddati tugagan bo'lishi mumkin)
        if (d['locked'] == true) return _lockedBody(t);

        if (d['ok'] != true) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
                icon: Icons.cloud_off_rounded,
                color: t.red,
                text: d['message'] ?? tr('risk.noData')),
          );
        }

        final orgs =
            ((d['organizations'] ?? []) as List).cast<Map<String, dynamic>>();
        final a = d['analysis'] as Map<String, dynamic>?;
        if (a == null || orgs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
                icon: Icons.business_outlined, text: tr('risk.empty.noOrg')),
          );
        }

        final selectedId =
            _org ?? (d['selected'] as int?) ?? orgs.first['id'] as int;
        final score = (a['score'] as num).round().clamp(0, 100);
        final risks = ((a['risks'] ?? []) as List).cast<Map<String, dynamic>>();

        final factors = risks
            .where((r) => r['status'] == 'flag' || r['status'] == 'warn')
            .toList()
          ..sort((x, y) => ((y['severity'] ?? 0) as num)
              .compareTo((x['severity'] ?? 0) as num));

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const PlanBanner(),
            if (orgs.length > 1) ...[
              _orgChips(t, orgs, selectedId),
              const SizedBox(height: 12),
            ],

            // MIUI ghost/ustma-ust render'ni kamaytirish uchun bu ekranda animatsiya
            // (StaggerIn, ring/bar TweenAnimation) va ortiqcha qatlam ISHLATILMAYDI —
            // hamma karta oddiy, statik chiziladi (kam compositing qatlami = kam ghost).
            _ringCard(t, score),
            const SizedBox(height: 11),
            Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                  child: _stat(t, tr('risk.stat.flags'), '${a['flags'] ?? 0}',
                      Icons.error_outline_rounded, t.red, t.tRed, t.onRed)),
              const SizedBox(width: 11),
              Expanded(
                  child: _stat(t, tr('risk.stat.warns'), '${a['warns'] ?? 0}',
                      Icons.warning_amber_rounded, t.amber, t.tAmb, t.onAmb)),
            ]),

            // Ballga nima ta'sir qildi — omillar (severity bo'yicha)
            if (factors.isNotEmpty) ...[
              _eyebrow(t, tr('risk.factors')),
              _barsCard(t, factors.take(6).toList()),
            ],

            _eyebrow(t, tr('risk.detected')),
            if (risks.isEmpty)
              EmptyState(
                  icon: Icons.verified_outlined,
                  color: t.green,
                  text: tr('risk.empty.noRisk'))
            else
              ...risks.map((r) => _riskRow(t, r)),
          ],
        );
      },
    );
  }

  Widget _loading(FinnTokens t) => const Padding(
        padding: EdgeInsets.only(top: 120),
        child: Center(child: CircularProgressIndicator()),
      );

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
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );

  // ─────────────────────── BALL HALQASI ───────────────────────
  Widget _ringCard(FinnTokens t, int score) {
    final c = _levelColor(t, score);
    final fraction = (score / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(children: [
        SizedBox(
          width: 172,
          height: 172,
          child: Stack(alignment: Alignment.center, children: [
            // Statik (animatsiyasiz) — MIUI ghost'ni kamaytirish uchun.
            CustomPaint(
              size: const Size(160, 160),
              painter: RingPainter(
                  progress: fraction, color: c, track: t.key, stroke: 13),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$score',
                  style: FinnText.heroValue(c).copyWith(fontSize: 52)),
              const SizedBox(height: 6),
              Text(tr('risk.outOf100'),
                  style: FinnText.rowSub(t.ink3).copyWith(fontSize: 12)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _tintColor(t, score),
            borderRadius: BorderRadius.circular(FinnTokens.rLg),
          ),
          child: Text(_levelLabel(score),
              style: FinnText.pill(_onColor(t, score)).copyWith(fontSize: 13)),
        ),
        const SizedBox(height: 11),
        Text(
          score <= 30
              ? tr('risk.meta.low')
              : (score <= 60 ? tr('risk.meta.mid') : tr('risk.meta.high')),
          textAlign: TextAlign.center,
          style: FinnText.rowSub(t.ink3),
        ),
      ]),
    );
  }

  // ─────────────────────── STAT KARTA ───────────────────────
  Widget _stat(FinnTokens t, String label, String value, IconData ic,
          Color col, Color tint, Color on) =>
      Container(
        padding: const EdgeInsets.all(FinnTokens.cardPad),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: t.line),
          boxShadow: t.sh,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: tint, borderRadius: BorderRadius.circular(11)),
            child: Icon(ic, size: 16, color: on),
          ),
          const SizedBox(height: 12),
          Text(value, style: FinnText.bigValue(t.ink).copyWith(fontSize: 26)),
          const SizedBox(height: 8),
          Text(label, style: FinnText.rowSub(t.ink3).copyWith(fontSize: 12)),
        ]),
      );

  // ─────────────────── BALLGA TA'SIR QILGAN OMILLAR ───────────────────
  Widget _barsCard(FinnTokens t, List<Map<String, dynamic>> factors) {
    final maxSev = factors.fold<double>(
        1, (m, f) => math.max(m, ((f['severity'] ?? 0) as num).toDouble()));
    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(children: [
        for (var i = 0; i < factors.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _bar(t, factors[i], maxSev),
        ],
      ]),
    );
  }

  Widget _bar(FinnTokens t, Map<String, dynamic> f, double maxSev) {
    final sev = ((f['severity'] ?? 0) as num).toDouble();
    // Fill hech qachon ko'rinmas darajada kichik bo'lmasin (min 0.1).
    final frac = (sev / maxSev).clamp(0.1, 1.0);
    final col = f['status'] == 'flag' ? t.red : t.amber;
    // Sarlavha TO'LIQ kenglikda (kesilmaydi), bar + qiymat ostida.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text('${f['title']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FinnText.rowSub(t.ink2)
                    .copyWith(fontSize: 13, height: 1.25)),
          ),
          const SizedBox(width: 10),
          Text('+${sev.toInt()}',
              style: FinnText.rowValue(col).copyWith(fontSize: 13)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Stack(children: [
              Positioned.fill(child: ColoredBox(color: t.key)),
              // Statik (animatsiyasiz) — MIUI ghost'ni kamaytirish uchun.
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: frac,
                child: ColoredBox(color: col),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── TASHKILOT CHIPLARI ───────────────────────
  Widget _orgChips(
          FinnTokens t, List<Map<String, dynamic>> orgs, int selectedId) =>
      SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: orgs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final o = orgs[i];
            final sel = o['id'] == selectedId;
            return GestureDetector(
              onTap: () => _selectOrg(o['id'] as int),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: sel ? t.blue : t.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: sel ? t.blue : t.line),
                ),
                child: Text('${o['name']}',
                    style: FinnText.chip(sel ? Colors.white : t.ink2).copyWith(
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
              ),
            );
          },
        ),
      );

  // ─────────────────────── BO'LIM SARLAVHASI ───────────────────────
  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );

  // ─────────────────────── RISK QATORI ───────────────────────
  Widget _riskRow(FinnTokens t, Map<String, dynamic> r) {
    final st = r['status'];
    final Color tint;
    final Color on;
    final IconData ic;
    if (st == 'flag') {
      tint = t.tRed;
      on = t.onRed;
      ic = Icons.error_outline_rounded;
    } else if (st == 'warn') {
      tint = t.tAmb;
      on = t.onAmb;
      ic = Icons.warning_amber_rounded;
    } else {
      tint = t.tGrn;
      on = t.onGrn;
      ic = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: tint, borderRadius: BorderRadius.circular(12)),
          child: Icon(ic, color: on, size: 17),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${r['title']}', style: FinnText.rowTitle(t.ink)),
                if ((r['detail'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text('${r['detail']}', style: FinnText.rowSub(t.ink3)),
                ],
              ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 18, color: t.ink4),
      ]),
    );
  }

  // ─────────────────────── QULF / KENGAYTIRISH ───────────────────────
  Widget _lockedBody(FinnTokens t) {
    final perks = [
      tr('risk.locked.perk1'),
      tr('risk.locked.perk2'),
      tr('risk.locked.perk3'),
      tr('risk.locked.perk4'),
      tr('risk.locked.perk5'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 28),
        // Qulf ikonkasi — bo'lim ikonkasi ustida
        SizedBox(
          width: 104,
          height: 104,
          child: Stack(children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.card,
                borderRadius: BorderRadius.circular(FinnTokens.rXl),
                border: Border.all(color: t.line),
                boxShadow: t.sh,
              ),
              child: Icon(Icons.shield_outlined, size: 40, color: t.ink4),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.amber,
                  borderRadius: BorderRadius.circular(FinnTokens.rMd),
                  border: Border.all(color: t.bg, width: 3),
                ),
                child: const Icon(Icons.lock, size: 16, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 22),
        Text(tr('risk.title'),
            textAlign: TextAlign.center, style: FinnText.cardTitle(t.ink)),
        const SizedBox(height: 8),
        Text(tr('risk.locked.desc'),
            textAlign: TextAlign.center, style: FinnText.body(t.ink3)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(FinnTokens.cardPad),
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rLg),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Column(children: [
            for (final p in perks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: t.tGrn,
                        borderRadius: BorderRadius.circular(FinnTokens.rSm)),
                    child: Icon(Icons.check_rounded, size: 13, color: t.onGrn),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Text(p, style: FinnText.rowTitle(t.ink))),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 24),
        // Joriy tarif
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: t.line2,
            borderRadius: BorderRadius.circular(FinnTokens.rLg),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.workspace_premium_outlined, size: 15, color: t.ink3),
            const SizedBox(width: 7),
            Text(tr('risk.locked.currentPlan'), style: FinnText.rowSub(t.ink3)),
            Text(PlanState.i.name, style: FinnText.rowValue(t.ink)),
          ]),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openSubscription(context),
          child: Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: FinnTokens.brand,
              borderRadius: BorderRadius.circular(FinnTokens.rMd),
              boxShadow: [
                BoxShadow(
                    color: t.blue.withValues(alpha: .35),
                    blurRadius: 22,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.rocket_launch_outlined,
                  size: 18, color: Colors.white),
              const SizedBox(width: 9),
              Text(tr('risk.locked.upgrade'), style: FinnText.button(Colors.white)),
            ]),
          ),
        ),
        const SizedBox(height: 10),
        Text(tr('risk.locked.upgradeHint'),
            textAlign: TextAlign.center, style: FinnText.rowSub(t.ink4)),
      ],
    );
  }
}
