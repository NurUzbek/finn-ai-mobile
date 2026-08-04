import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../services/plan.dart';
import '../widgets/common.dart';
import '../widgets/locked.dart';

/// "Risk tahlil" moduli. Tarifda `risk` yo'q bo'lsa — qulflangan ekran + kengaytirish taklifi.
class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});
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
  void _onPlan() { if (mounted) setState(() {}); }

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

  LockedFeature get _locked => LockedFeature(
        icon: Icons.shield_outlined,
        title: tr('risk.title'),
        description: tr('risk.locked.desc'),
        perks: [
          tr('risk.locked.perk1'),
          tr('risk.locked.perk2'),
          tr('risk.locked.perk3'),
          tr('risk.locked.perk4'),
          tr('risk.locked.perk5'),
        ],
      );

  /// Risk darajasiga mos rang: past → yashil, o'rta → sariq, yuqori → qizil.
  /// Ball qanchalik past bo'lsa, shunchalik yaxshi.
  Color _levelColor(int score) =>
      score <= 30 ? C.green : (score <= 60 ? C.amber : C.red);

  Color _onColor(BuildContext c, int score) =>
      score <= 30 ? C.onGrn(c) : (score <= 60 ? C.onAmb(c) : C.onRed(c));

  String _levelLabel(int score) =>
      score <= 30 ? tr('risk.level.low') : (score <= 60 ? tr('risk.level.mid') : tr('risk.level.high'));

  @override
  Widget build(BuildContext context) {
    // Tarif hali yuklanmagan — qulf ekranini chaqnatib yubormaymiz
    if (!PlanState.i.loaded) {
      return const Center(child: CircularProgressIndicator(color: C.cyan));
    }
    if (!PlanState.i.has('risk')) return _locked;

    return SafeArea(
      child: Column(children: [
        ScreenHeader(
          title: tr('risk.title'),
          icon: Icons.shield_outlined,
          subtitle: tr('risk.subtitle'),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }
              final d = snap.data ?? {'ok': false};

              // Server tarifni qulflagan bo'lsa (obuna muddati tugagan bo'lishi mumkin)
              if (d['locked'] == true) return _locked;

              if (d['ok'] != true) {
                return EmptyState(icon: Icons.cloud_off_rounded, color: C.red, text: d['message'] ?? tr('risk.noData'));
              }

              final orgs = ((d['organizations'] ?? []) as List).cast<Map<String, dynamic>>();
              final a = d['analysis'] as Map<String, dynamic>?;
              if (a == null || orgs.isEmpty) {
                return EmptyState(icon: Icons.business_outlined, text: tr('risk.empty.noOrg'));
              }

              final selectedId = _org ?? (d['selected'] as int?) ?? orgs.first['id'] as int;
              final score = (a['score'] as num).round().clamp(0, 100);
              final risks = ((a['risks'] ?? []) as List).cast<Map<String, dynamic>>();
              final c = _levelColor(score);

              return RefreshIndicator(
                color: C.cyan,
                backgroundColor: C.card(context),
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  children: [
                    const PlanBanner(),

                    if (orgs.length > 1) _orgChips(context, orgs, selectedId),

                    // Ball halqasi
                    StaggerIn(index: 0, child: _ringCard(context, score, c)),
                    const SizedBox(height: 12),

                    // Statistika kartalari
                    StaggerIn(
                      index: 1,
                      child: Row(children: [
                        Expanded(child: StatCard(label: tr('risk.stat.flags'), value: '${a['flags'] ?? 0}', icon: Icons.error_outline_rounded, color: C.red)),
                        const SizedBox(width: 12),
                        Expanded(child: StatCard(label: tr('risk.stat.warns'), value: '${a['warns'] ?? 0}', icon: Icons.warning_amber_rounded, color: C.amber)),
                      ]),
                    ),

                    const SizedBox(height: 22),
                    _eyebrow(context, tr('risk.detected')),
                    const SizedBox(height: 10),
                    if (risks.isEmpty)
                      EmptyState(icon: Icons.verified_outlined, color: C.green, text: tr('risk.empty.noRisk'))
                    else
                      ...risks.asMap().entries.map(
                        (e) => StaggerIn(index: 2 + e.key, child: _riskRow(context, e.value)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ─── Ball halqasi ───────────────────────────────────────────────
  Widget _ringCard(BuildContext context, int score, Color c) {
    final fraction = (score / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(
                size: const Size(160, 160),
                painter: _RingPainter(fraction: v, color: c, track: C.fill(context, .08)),
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$score',
                  style: TextStyle(fontSize: 46, fontWeight: FontWeight.w700, height: 1, letterSpacing: -1, color: c)),
              const SizedBox(height: 4),
              Text(tr('risk.outOf100'), style: TextStyle(fontSize: 12, color: C.muted(context, .45))),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: C.tint(context, c),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(_levelLabel(score),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _onColor(context, score))),
        ),
      ]),
    );
  }

  // ─── Tashkilot chiplari ─────────────────────────────────────────
  Widget _orgChips(BuildContext context, List<Map<String, dynamic>> orgs, int selectedId) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
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
                    color: sel ? C.tint(context, C.brand) : C.fill(context, .04),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: sel ? C.brand.withValues(alpha: .5) : Colors.transparent),
                  ),
                  child: Text('${o['name']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: sel ? C.brand : C.muted(context, .7),
                      )),
                ),
              );
            },
          ),
        ),
      );

  // ─── Bo'lim sarlavhasi ──────────────────────────────────────────
  Widget _eyebrow(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 2),
        child: Text(text,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: .2, color: C.muted(context, .5))),
      );

  // ─── Risk qatori ────────────────────────────────────────────────
  Widget _riskRow(BuildContext context, Map<String, dynamic> r) {
    final st = r['status'];
    final Color c;
    final Color on;
    final IconData ic;
    if (st == 'flag') {
      c = C.red; on = C.onRed(context); ic = Icons.error_outline_rounded;
    } else if (st == 'warn') {
      c = C.amber; on = C.onAmb(context); ic = Icons.warning_amber_rounded;
    } else {
      c = C.green; on = C.onGrn(context); ic = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 34, height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: C.tint(context, c), borderRadius: BorderRadius.circular(11)),
          child: Icon(ic, color: on, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r['title']}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: C.text(context))),
            if ((r['detail'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('${r['detail']}',
                  style: TextStyle(fontSize: 11.5, height: 1.4, color: C.muted(context, .45))),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, size: 20, color: C.muted(context, .3)),
      ]),
    );
  }
}

/// Ball halqasi: fon doirasi + rangli yoy (tepadan boshlanadi, uchlari yumaloq).
class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final Color track;
  _RingPainter({required this.fraction, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, bg);

    if (fraction > 0) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * fraction, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}
