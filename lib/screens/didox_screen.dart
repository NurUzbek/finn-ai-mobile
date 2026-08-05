import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "E-hujjat (Didox)" moduli — Didox integratsiyasi orqali elektron
/// hisob-fakturalar ro'yxati, holat bo'yicha filt르 va risk ogohlantirishi.
class DidoxScreen extends StatefulWidget {
  const DidoxScreen({super.key});
  @override
  State<DidoxScreen> createState() => _DidoxScreenState();
}

/// Holat guruhi tavsifi (chip filtri + pill uchun).
class _Grp {
  final String key, label;
  final Color color;
  const _Grp(this.key, this.label, this.color);
}

class _DidoxScreenState extends State<DidoxScreen> {
  late Future<Map<String, dynamic>> _f = Api.didox();
  Future<void> _refresh() async => setState(() => _f = Api.didox());

  int _filter = 0; // 0 = hammasi

  static const _groups = <_Grp>[
    _Grp('signed', 'Imzolangan', C.green),
    _Grp('pending', 'Kutilmoqda', C.amber),
    _Grp('rejected', 'Rad etilgan', C.red),
  ];

  /// Xom holat qatorini guruhga moslashtiradi.
  String _group(String raw) {
    switch (raw.toLowerCase()) {
      case 'signed':
      case 'accepted':
      case 'ok':
        return 'signed';
      case 'pending':
      case 'draft':
      case 'waiting':
        return 'pending';
      case 'rejected':
      case 'declined':
      case 'canceled':
      case 'cancelled':
        return 'rejected';
      default:
        return 'other';
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          const ScreenHeader(
            title: 'E-hujjat',
            icon: Icons.description_rounded,
            subtitle: 'Didox integratsiyasi · ulangan',
          ),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final docs = ((d['documents'] as List?) ?? const [])
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();

                if (docs.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 90),
                      EmptyState(
                        icon: Icons.description_outlined,
                        color: C.violet,
                        text: 'E-hujjat yo\'q — Didox ulanmagan boʻlishi mumkin',
                      ),
                    ],
                  );
                }

                // Guruh bo'yicha sonlar.
                final counts = <String, int>{};
                for (final doc in docs) {
                  final g = _group((doc['status'] ?? '').toString());
                  counts[g] = (counts[g] ?? 0) + 1;
                }
                final rejected = counts['rejected'] ?? 0;

                // Faol filtr bo'yicha ro'yxat.
                final shown = _filter == 0
                    ? docs
                    : docs
                        .where((doc) =>
                            _group((doc['status'] ?? '').toString()) == _groups[_filter - 1].key)
                        .toList();

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    // ── Filtr chiplari ──
                    StaggerIn(index: 0, child: _chips(context, docs.length, counts)),
                    const SizedBox(height: 14),

                    // ── Risk ogohlantirishi (rad etilgan bo'lsa) ──
                    if (rejected > 0) ...[
                      StaggerIn(index: 1, child: _alert(context, rejected)),
                      const SizedBox(height: 4),
                    ],

                    // ── Eyebrow ──
                    _eyebrow(context, 'Fakturalar', '${shown.length} ta'),

                    // ── Hujjatlar ──
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          color: C.violet,
                          text: 'Ushbu holatda hujjat topilmadi',
                        ),
                      )
                    else
                      ...shown.asMap().entries.map((e) => StaggerIn(
                            index: e.key + 2,
                            child: _DocRow(doc: e.value, group: _group((e.value['status'] ?? '').toString())),
                          )),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  // ── Chiplar qatori ──
  Widget _chips(BuildContext context, int total, Map<String, int> counts) {
    final items = <Widget>[_chip(context, 0, 'Hammasi', total)];
    for (var i = 0; i < _groups.length; i++) {
      final c = counts[_groups[i].key] ?? 0;
      if (c == 0) continue;
      items.add(const SizedBox(width: 8));
      items.add(_chip(context, i + 1, _groups[i].label, c));
    }
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: items,
      ),
    );
  }

  Widget _chip(BuildContext context, int idx, String label, int count) {
    final on = _filter == idx;
    return GestureDetector(
      onTap: () => setState(() => _filter = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? C.brand : C.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? C.brand : C.border(context)),
          boxShadow: on ? null : C.shadow(context, blur: 14, a: .03),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: on ? FontWeight.w700 : FontWeight.w600,
              color: on ? Colors.white : C.muted(context, .75),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white.withValues(alpha: .8) : C.muted(context, .4),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Ogohlantirish kartasi ──
  Widget _alert(BuildContext context, int n) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: C.tint(context, C.red),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded, size: 20, color: C.onRed(context)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'QQS zanjiri xavf ostida',
                style: TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: C.onRed(context)),
              ),
              const SizedBox(height: 4),
              Text(
                '$n ta faktura rad etilgan. Ushbu hujjatlar bo\'yicha QQS chegirmasi rad etilishi mumkin — qayta koʻrib chiqing.',
                style: TextStyle(fontSize: 12.5, height: 1.5, color: C.muted(context, .7)),
              ),
            ]),
          ),
        ]),
      );

  // ── Eyebrow ajratuvchi ──
  Widget _eyebrow(BuildContext context, String label, String trailing) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
        child: Row(children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: C.muted(context, .4)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.brand),
          ),
        ]),
      );
}

/// Bitta hujjat qatori (monogram + ma'lumot + holat pilli).
class _DocRow extends StatelessWidget {
  final Map<String, dynamic> doc;
  final String group;
  const _DocRow({required this.doc, required this.group});

  ({Color color, Color on, String label}) _status(BuildContext context) {
    switch (group) {
      case 'signed':
        return (color: C.green, on: C.onGrn(context), label: 'Imzolangan');
      case 'pending':
        return (color: C.amber, on: C.onAmb(context), label: 'Kutilmoqda');
      case 'rejected':
        return (color: C.red, on: C.onRed(context), label: 'Rad etilgan');
      default:
        final raw = (doc['status'] ?? '').toString();
        return (color: C.muted(context, .5), on: C.muted(context, .7), label: raw.isEmpty ? 'Holat yoʻq' : raw);
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = (doc['number'] ?? '—').toString();
    final type = (doc['type'] ?? '').toString();
    final date = (doc['date'] ?? '').toString();
    final st = _status(context);

    final title = type.isNotEmpty ? type : 'E-hujjat';
    final subParts = <String>['№ $number', if (date.isNotEmpty) date];

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(children: [
        // monogram — holat rangi bilan
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.tint(context, st.color),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.receipt_long_rounded, size: 19, color: st.on),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: C.text(context),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subParts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: C.muted(context, .45)),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        // holat pilli
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: C.tint(context, group == 'other' ? C.violet : st.color),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            st.label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: st.on),
          ),
        ),
      ]),
    );
  }
}
