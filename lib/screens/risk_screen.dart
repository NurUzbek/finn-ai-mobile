import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
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

  static const _locked = LockedFeature(
    icon: Icons.speed_rounded,
    title: 'Risk tahlili',
    description:
        'Tashkilotingizning soliq, moliyaviy va hujjat risklarini 100 ballik shkalada baholaydi.',
    perks: [
      'Umumiy risk balli va rangli zona',
      'Soliq intizomi va qarzdorlik tahlili',
      'E-faktura va kontragent risklari',
      'Hisob bloklash xavfi haqida ogohlantirish',
      'PDF hisobot yuklab olish',
    ],
  );

  /// Risk darajasiga mos rang: past → yashil, yuqori → qizil.
  Color _levelColor(int score) =>
      score >= 70 ? C.red : (score >= 40 ? C.amber : C.green);

  @override
  Widget build(BuildContext context) {
    // Tarif hali yuklanmagan — qulf ekranini chaqnatib yubormaymiz
    if (!PlanState.i.loaded) {
      return const Center(child: CircularProgressIndicator(color: C.cyan));
    }
    if (!PlanState.i.has('risk')) return _locked;

    return SafeArea(
      child: Column(children: [
        const ScreenHeader(title: 'Risk tahlil', icon: Icons.speed_rounded, subtitle: 'Tashkilot risk balli'),
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
                return EmptyState(icon: Icons.cloud_off_rounded, color: C.red, text: d['message'] ?? 'Ma\'lumot olinmadi');
              }

              final a = d['analysis'] as Map<String, dynamic>?;
              if (a == null) {
                return const EmptyState(icon: Icons.business_outlined, text: 'Avval tashkilot qo\'shing');
              }

              final orgs = ((d['organizations'] ?? []) as List).cast<Map<String, dynamic>>();
              final score = (a['score'] as num).round();
              final risks = (a['risks'] as List).cast<Map<String, dynamic>>();
              final c = _levelColor(score);

              return RefreshIndicator(
                color: C.cyan,
                backgroundColor: C.cardDark,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    const PlanBanner(),

                    if (orgs.length > 1) _orgPicker(orgs),

                    // Ball halqasi
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: C.cardDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.withValues(alpha: .3)),
                      ),
                      child: Column(children: [
                        SizedBox(
                          width: 132, height: 132,
                          child: Stack(alignment: Alignment.center, children: [
                            SizedBox(
                              width: 132, height: 132,
                              child: CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 10,
                                strokeCap: StrokeCap.round,
                                color: c,
                                backgroundColor: Colors.white.withValues(alpha: .06),
                              ),
                            ),
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('$score', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: c, height: 1)),
                              Text('100 dan', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .4))),
                            ]),
                          ]),
                        ),
                        const SizedBox(height: 14),
                        Text('${a['level']}'.toUpperCase(),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1, color: c)),
                        if (a['segment'] != null) ...[
                          const SizedBox(height: 4),
                          Text('Segment: ${a['segment']}',
                              style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: .4))),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 12),

                    Row(children: [
                      Expanded(child: StatCard(label: 'Jiddiy risklar', value: '${a['flags']}', icon: Icons.error_outline, color: C.red)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(label: 'Ogohlantirish', value: '${a['warns']}', icon: Icons.warning_amber_rounded, color: C.amber)),
                    ]),

                    const SizedBox(height: 22),
                    const Text('Risk ko\'rsatkichlari', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 10),
                    ...risks.map(_riskRow),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _orgPicker(List<Map<String, dynamic>> orgs) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: orgs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final o = orgs[i];
              final sel = (_org ?? orgs.first['id']) == o['id'];
              return GestureDetector(
                onTap: () => setState(() { _org = o['id'] as int; _f = Api.risk(org: _org); }),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? C.blue.withValues(alpha: .18) : Colors.white.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: sel ? C.cyan.withValues(alpha: .5) : Colors.transparent),
                  ),
                  child: Text('${o['name']}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? C.cyan : Colors.white70)),
                ),
              );
            },
          ),
        ),
      );

  Widget _riskRow(Map<String, dynamic> r) {
    final st = r['status'];
    final c = st == 'flag' ? C.red : (st == 'warn' ? C.amber : C.green);
    final ic = st == 'flag' ? Icons.error_outline : (st == 'warn' ? Icons.warning_amber_rounded : Icons.check_circle_outline);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
          child: Icon(ic, color: c, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${r['title']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
            if ((r['detail'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('${r['detail']}',
                  style: TextStyle(fontSize: 11.5, height: 1.45, color: Colors.white.withValues(alpha: .45))),
            ],
          ]),
        ),
      ]),
    );
  }
}
