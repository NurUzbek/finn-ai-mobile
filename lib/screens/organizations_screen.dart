import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Mening tashkilotlarim" moduli — kengayuvchi firma kartalari (TZ 2-jadval).
class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key});
  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  late Future<Map<String, dynamic>> _f = Api.organizations();
  int _filter = 0; // 0 = Hammasi, 1 = Qarzdor, 2 = Toza

  Future<void> _refresh() async => setState(() => _f = Api.organizations());

  bool _clean(Map<String, dynamic> o) => o['clean'] == true;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Loader(
          future: _f,
          onRefresh: _refresh,
          builder: (d) {
            final orgs = (d['organizations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
            final total = orgs.length;
            final cleanCount = orgs.where(_clean).length;
            final debtorCount = total - cleanCount;

            final filtered = orgs.where((o) {
              if (_filter == 1) return !_clean(o);
              if (_filter == 2) return _clean(o);
              return true;
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
              children: [
                _header(context, total, cleanCount),
                const SizedBox(height: 14),
                _chips(context, total, debtorCount, cleanCount),
                const SizedBox(height: 16),
                if (orgs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.apartment_rounded,
                      text: 'Hozircha tashkilot yo\'q',
                      color: C.brand,
                    ),
                  )
                else if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: _filter == 2 ? Icons.verified_outlined : Icons.error_outline_rounded,
                      text: _filter == 2 ? 'Toza firma topilmadi' : 'Qarzdor firma yo\'q',
                      color: C.brand,
                    ),
                  )
                else
                  for (var i = 0; i < filtered.length; i++)
                    StaggerIn(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OrgRow(key: ValueKey(filtered[i]['id'] ?? i), o: filtered[i]),
                      ),
                    ),
              ],
            );
          },
        ),
      );

  // ── Sarlavha: bino ikonkasi + "Tashkilotlarim" + N ta / M toza + "+" ──
  Widget _header(BuildContext c, int total, int clean) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [C.brand, C.brand2]),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tashkilotlarim',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -0.4, color: C.text(c))),
              Text('$total ta firma · $clean tasi toza',
                  style: TextStyle(fontSize: 12, color: C.muted(c, .5))),
            ]),
          ),
          _AddButton(onTap: () {
            ScaffoldMessenger.of(c).showSnackBar(
              const SnackBar(content: Text('Tez orada'), duration: Duration(seconds: 2)),
            );
          }),
        ],
      );

  // ── Filter chiplari ──
  Widget _chips(BuildContext c, int total, int debtor, int clean) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _chip(c, 0, 'Hammasi', total, null),
          const SizedBox(width: 8),
          _chip(c, 1, 'Qarzdor', debtor, C.red),
          const SizedBox(width: 8),
          _chip(c, 2, 'Toza', clean, C.green),
        ]),
      );

  Widget _chip(BuildContext c, int idx, String label, int count, Color? dot) {
    final sel = _filter == idx;
    return GestureDetector(
      onTap: () => setState(() => _filter = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: sel ? C.brand : C.fill(c, .05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: sel ? Colors.transparent : C.border(c, .06)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null && !sel) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: sel ? Colors.white : C.muted(c, .65))),
          const SizedBox(width: 5),
          Text('$count',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white.withValues(alpha: .8) : C.muted(c, .4))),
        ]),
      ),
    );
  }
}

// ── "+" ikon tugma ──
class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});
  @override
  Widget build(BuildContext c) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: C.fill(c, .05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border(c, .07)),
          ),
          child: Icon(Icons.add_rounded, size: 20, color: C.muted(c, .7)),
        ),
      );
}

// ── Kengayuvchi firma qatori ──
class _OrgRow extends StatefulWidget {
  final Map<String, dynamic> o;
  const _OrgRow({super.key, required this.o});
  @override
  State<_OrgRow> createState() => _OrgRowState();
}

class _OrgRowState extends State<_OrgRow> {
  bool _open = false;

  bool get _clean => widget.o['clean'] == true;

  String get _monogram {
    final name = (widget.o['name'] ?? '').toString().trim();
    if (name.isEmpty) return '—';
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
  }

  String? _s(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  @override
  Widget build(BuildContext c) {
    final o = widget.o;
    final tone = _clean ? C.green : C.red;
    final monoText = _clean ? C.onGrn(c) : C.onRed(c);
    final debt = (o['debt'] as num?) ?? 0;
    final penalty = (o['penalty'] as num?) ?? 0;

    // Akkordeon qatorlari (faqat mavjud maydonlar)
    final rows = <List<String>>[];
    final director = _s(o['director']);
    final account = _s(o['account']);
    final bank = _s(o['bank']);
    if (director != null) rows.add(['Rahbar', director]);
    if (account != null) rows.add(['Hisob raqam', account]);
    if (bank != null) rows.add(['Bank', bank]);
    if (rows.isEmpty) {
      rows.add(['Manzil', _s(o['address']) ?? 'Ma\'lumot yo\'q']);
    }

    return Container(
      decoration: BoxDecoration(
        color: C.card(c),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(c, .06)),
        boxShadow: C.shadow(c),
      ),
      child: Column(children: [
        // ── Bosiladigan yuqori qism ──
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C.tint(c, tone),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(_monogram,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: monoText)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((o['name'] ?? '—').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text(c))),
                  const SizedBox(height: 2),
                  Text('STIR ${_s(o['stir']) ?? '—'}',
                      style: TextStyle(fontSize: 11.5, color: C.muted(c, .42))),
                ]),
              ),
              const SizedBox(width: 8),
              if (_clean)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: C.tint(c, C.green),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Toza',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: C.onGrn(c))),
                )
              else
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(money(debt),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.red)),
                  const SizedBox(height: 2),
                  Text('penya ${money(penalty)}',
                      style: TextStyle(fontSize: 11, color: C.muted(c, .42))),
                ]),
              const SizedBox(width: 8),
              AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                turns: _open ? 0.5 : 0,
                child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: C.muted(c, .4)),
              ),
            ]),
          ),
        ),
        // ── Akkordeon ──
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 260),
          firstCurve: Curves.easeOut,
          secondCurve: Curves.easeOut,
          sizeCurve: Curves.easeOut,
          crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: C.fill(c, .05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (final r in rows) _kv(c, r[0], r[1]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _kv(BuildContext c, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 96,
            child: Text(k, style: TextStyle(fontSize: 12, color: C.muted(c, .45))),
          ),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.text(c))),
          ),
        ]),
      );
}
