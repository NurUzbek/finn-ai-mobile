import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Kontragentlarni tekshirish moduli — STIR bo'yicha risk tekshiruvlari ro'yxati.
class CounterpartyScreen extends StatefulWidget {
  const CounterpartyScreen({super.key});
  @override
  State<CounterpartyScreen> createState() => _CounterpartyScreenState();
}

class _CounterpartyScreenState extends State<CounterpartyScreen> {
  late Future<Map<String, dynamic>> _f = Api.counterparty();
  final _search = TextEditingController();
  int _chip = 0; // 0 Hammasi · 1 Riskli · 2 Yetkazuvchi · 3 Xaridor
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async => setState(() => _f = Api.counterparty());

  // ── Risk klassifikatsiyasi ──
  // 0 = yuqori (red), 1 = e'tibor (amber), 2 = toza (green), 3 = noma'lum
  int _riskClass(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('high') || r.contains('yuqori') || r.contains('critical')) return 0;
    if (r.contains('medium') || r.contains('orta') || r.contains('warn') || r.contains('e\'tibor')) return 1;
    if (r.contains('low') || r.contains('past') || r.contains('toza') || r.contains('clean') || r.contains('ok') || r.contains('safe')) return 2;
    return 3;
  }

  Color _riskColor(BuildContext ctx, int cls) => switch (cls) {
        0 => C.red,
        1 => C.amber,
        2 => C.green,
        _ => C.muted(ctx, .5),
      };

  Color _riskOn(BuildContext ctx, int cls) => switch (cls) {
        0 => C.onRed(ctx),
        1 => C.onAmb(ctx),
        2 => C.onGrn(ctx),
        _ => C.muted(ctx, .7),
      };

  String _riskLabel(int cls, String raw) => switch (cls) {
        0 => 'Yuqori risk',
        1 => 'E\'tibor',
        2 => 'Toza',
        _ => raw.isEmpty ? 'Noma\'lum' : raw,
      };

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        body: SafeArea(
          bottom: false,
          child: Loader(
            future: _f,
            onRefresh: _refresh,
            builder: (d) {
              final all = ((d['checks'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
              final riskyCount = all.where((c) {
                final cls = _riskClass((c['risk'] ?? '').toString());
                return cls == 0 || cls == 1;
              }).length;

              // Qidiruv + chip filtri
              var list = all;
              if (_q.isNotEmpty) {
                final q = _q.toLowerCase();
                list = list.where((c) {
                  final n = (c['name'] ?? '').toString().toLowerCase();
                  final s = (c['stir'] ?? '').toString().toLowerCase();
                  return n.contains(q) || s.contains(q);
                }).toList();
              }
              if (_chip == 1) {
                list = list.where((c) {
                  final cls = _riskClass((c['risk'] ?? '').toString());
                  return cls == 0 || cls == 1;
                }).toList();
              } else if (_chip == 2 || _chip == 3) {
                // Yetkazuvchi / Xaridor — ma'lumotda tur belgisi yo'q
                list = const [];
              }

              // Guruhlash: diqqat talab qiladi (0,1) va ishonchli (2,3)
              final attention = list.where((c) => _riskClass((c['risk'] ?? '').toString()) <= 1).toList();
              final trusted = list.where((c) => _riskClass((c['risk'] ?? '').toString()) >= 2).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    sliver: SliverList.list(children: [
                      _header(context, all.length, riskyCount),
                      const SizedBox(height: 16),
                      _searchField(context),
                      const SizedBox(height: 14),
                      _chips(context, all.length, riskyCount),
                      const SizedBox(height: 8),
                      if (list.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: EmptyState(
                            icon: Icons.fact_check_rounded,
                            color: C.cyan,
                            text: _q.isNotEmpty || _chip > 1
                                ? 'Mos kontragent topilmadi'
                                : 'Hozircha tekshiruv yo\'q',
                          ),
                        )
                      else ...[
                        if (attention.isNotEmpty) ...[
                          _eyebrow(context, 'Diqqat talab qiladi'),
                          ...attention.asMap().entries.map(
                                (e) => StaggerIn(index: e.key, child: _row(context, e.value)),
                              ),
                        ],
                        if (trusted.isNotEmpty) ...[
                          _eyebrow(context, 'Ishonchli'),
                          ...trusted.asMap().entries.map(
                                (e) => StaggerIn(index: attention.length + e.key, child: _row(context, e.value)),
                              ),
                        ],
                      ],
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
      );

  Widget _header(BuildContext ctx, int total, int risky) => Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [C.blue, C.cyan]),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Kontragentlar',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: C.text(ctx))),
            Text('$total ta · $risky tasi risk ro\'yxatida',
                style: TextStyle(fontSize: 12, color: C.muted(ctx, .5))),
          ]),
        ),
      ]);

  Widget _searchField(BuildContext ctx) => TextField(
        controller: _search,
        onChanged: (v) => setState(() => _q = v.trim()),
        style: TextStyle(fontSize: 14, color: C.text(ctx), fontWeight: FontWeight.w600),
        cursorColor: C.brand,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'STIR yoki nom bo\'yicha qidirish',
          hintStyle: TextStyle(fontSize: 13.5, color: C.muted(ctx, .4), fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: C.muted(ctx, .45)),
          suffixIcon: _q.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: C.muted(ctx, .5)),
                  onPressed: () => setState(() {
                    _search.clear();
                    _q = '';
                  }),
                )
              : null,
          filled: true,
          fillColor: C.fill(ctx),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.border(ctx)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.border(ctx)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: C.brand.withValues(alpha: .5), width: 1.4),
          ),
        ),
      );

  Widget _chips(BuildContext ctx, int total, int risky) {
    final items = ['Hammasi $total', 'Riskli $risky', 'Yetkazuvchi', 'Xaridor'];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = _chip == i;
          return GestureDetector(
            onTap: () => setState(() => _chip = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? C.brand : C.card(ctx),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: on ? Colors.transparent : C.border(ctx)),
                boxShadow: on ? null : C.shadow(ctx, y: 4, blur: 14),
              ),
              child: Text(
                items[i],
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : C.muted(ctx, .7),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _eyebrow(BuildContext ctx, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
        child: Row(children: [
          Text(text.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: C.muted(ctx, .45),
              )),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: C.border(ctx))),
        ]),
      );

  Widget _row(BuildContext ctx, Map<String, dynamic> c) {
    final name = (c['name'] ?? '—').toString();
    final stir = (c['stir'] ?? '').toString();
    final date = (c['date'] ?? '').toString();
    final cls = _riskClass((c['risk'] ?? '').toString());
    final col = _riskColor(ctx, cls);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card(ctx),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(ctx)),
        boxShadow: C.shadow(ctx),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.tint(ctx, col),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            _initials(name),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: _riskOn(ctx, cls)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: C.text(ctx)),
            ),
            const SizedBox(height: 3),
            Text(
              [
                if (stir.isNotEmpty) 'STIR $stir',
                if (date.isNotEmpty) date,
              ].join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: C.muted(ctx, .5)),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        _pill(ctx, cls, (c['risk'] ?? '').toString()),
      ]),
    );
  }

  Widget _pill(BuildContext ctx, int cls, String raw) {
    final col = _riskColor(ctx, cls);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: C.tint(ctx, col),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _riskLabel(cls, raw),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _riskOn(ctx, cls)),
      ),
    );
  }
}
