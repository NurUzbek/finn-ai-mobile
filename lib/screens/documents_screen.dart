import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Hujjatlar" moduli — shartnomalar + fakturalar (veb `#v-hujjat` bilan 1:1).
/// Filtr chiplari (Hammasi / Shartnoma / Akt / Hisob-faktura) va holat bo'yicha
/// guruhlar: "Imzo kutmoqda" va "Yaqinda".
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

/// Filtr turlari.
enum _Kind { hammasi, shartnoma, akt, faktura }

const _kindLabels = {
  _Kind.hammasi: 'Hammasi',
  _Kind.shartnoma: 'Shartnoma',
  _Kind.akt: 'Akt',
  _Kind.faktura: 'Hisob-faktura',
};

/// Bitta normallashtirilgan hujjat.
class _Doc {
  final String title, party, date, status;
  final double amount;
  final _Kind kind;
  const _Doc(this.title, this.party, this.date, this.status, this.amount, this.kind);

  factory _Doc.contract(Map<String, dynamic> m) => _Doc(
        (m['number'] ?? '—').toString(),
        (m['party'] ?? '').toString(),
        (m['date'] ?? '').toString(),
        (m['status'] ?? '').toString(),
        (m['amount'] as num?)?.toDouble() ?? 0,
        _Kind.shartnoma,
      );

  factory _Doc.invoice(Map<String, dynamic> m) {
    final type = (m['type'] ?? '').toString().toLowerCase();
    final isAkt = type.contains('act') || type.contains('akt');
    return _Doc(
      (m['number'] ?? '—').toString(),
      (m['party'] ?? '').toString(),
      (m['date'] ?? '').toString(),
      (m['status'] ?? '').toString(),
      (m['amount'] as num?)?.toDouble() ?? 0,
      isAkt ? _Kind.akt : _Kind.faktura,
    );
  }

  /// Holat kutilayotgan (imzo/rad) bo'lsa `true` — "Imzo kutmoqda" guruhi.
  bool get isPending {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'draft':
      case 'new':
      case 'sent':
      case 'unsigned':
      case 'awaiting':
      case 'rejected':
      case 'cancelled':
        return true;
      default:
        return false;
    }
  }
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<Map<String, dynamic>> _f = Api.documents();
  _Kind _filter = _Kind.hammasi;

  Future<void> _refresh() async => setState(() => _f = Api.documents());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: Loader(
          future: _f,
          onRefresh: _refresh,
          builder: (d) {
            final all = <_Doc>[
              ...((d['contracts'] as List?)?.cast<Map<String, dynamic>>() ?? const [])
                  .map(_Doc.contract),
              ...((d['invoices'] as List?)?.cast<Map<String, dynamic>>() ?? const [])
                  .map(_Doc.invoice),
            ];
            final pendingTotal = all.where((x) => x.isPending).length;
            final shown = _filter == _Kind.hammasi
                ? all
                : all.where((x) => x.kind == _filter).toList();
            final pending = shown.where((x) => x.isPending).toList();
            final recent = shown.where((x) => !x.isPending).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                ScreenHeader(
                  title: 'Hujjatlar',
                  icon: Icons.folder_rounded,
                  subtitle:
                      '${all.length} ta hujjat · $pendingTotal tasi imzo kutmoqda',
                  action: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: C.card(context),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: C.border(context)),
                    ),
                    child: Icon(Icons.search_rounded,
                        size: 19, color: C.muted(context, .6)),
                  ),
                ),
                // Filtr chiplari.
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final k in _Kind.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _Chip(
                            label: _kindLabels[k]!,
                            on: _filter == k,
                            onTap: () => setState(() => _filter = k),
                          ),
                        ),
                    ],
                  ),
                ),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.description_outlined,
                      text: 'Hujjat yo\'q',
                      color: C.blue,
                    ),
                  ),
                if (pending.isNotEmpty) ...[
                  const _Eyebrow('Imzo kutmoqda'),
                  for (var i = 0; i < pending.length; i++)
                    StaggerIn(index: i, child: _Row(doc: pending[i])),
                ],
                if (recent.isNotEmpty) ...[
                  const _Eyebrow('Yaqinda'),
                  for (var i = 0; i < recent.length; i++)
                    StaggerIn(
                        index: pending.length + i, child: _Row(doc: recent[i])),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Filtr chipi (--chip / .chip.on).
class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? C.blue : C.card(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? C.blue : C.border(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: on ? FontWeight.w700 : FontWeight.w600,
            color: on ? Colors.white : C.muted(context, .6),
          ),
        ),
      ),
    );
  }
}

/// Bo'lim sarlavhasi (.eyebrow) — matn + ajratuvchi chiziq.
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
        ]),
      );
}

/// Hujjat qatori (.row) — ikonka + sarlavha/tavsif + holat pili.
class _Row extends StatelessWidget {
  final _Doc doc;
  const _Row({required this.doc});

  @override
  Widget build(BuildContext context) {
    final st = _style(context, doc);
    final sub = [
      if (doc.party.trim().isNotEmpty) doc.party.trim(),
      if (doc.date.trim().isNotEmpty) doc.date.trim(),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: st.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(st.icon, size: 18, color: st.fg),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doc.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: C.text(context),
                ),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .45)),
                ),
              ],
            ],
          ),
        ),
        if (st.pill != null) ...[
          const SizedBox(width: 10),
          _Pill(text: st.pill!, bg: st.bg, fg: st.fg),
        ],
      ]),
    );
  }
}

/// Qator ko'rinishi (rang / ikonka / pil matni).
class _RowStyle {
  final Color bg, fg;
  final IconData icon;
  final String? pill;
  const _RowStyle(this.bg, this.fg, this.icon, this.pill);
}

_RowStyle _style(BuildContext c, _Doc d) {
  final s = d.status.toLowerCase();
  switch (s) {
    case 'signed':
    case 'paid':
    case 'active':
    case 'accepted':
    case 'completed':
    case 'done':
      return _RowStyle(C.tint(c, C.green), C.onGrn(c), Icons.check_rounded,
          s == 'accepted' || s == 'paid' ? 'Qabul' : 'Imzolangan');
    case 'rejected':
    case 'cancelled':
      return _RowStyle(
          C.tint(c, C.red), C.onRed(c), Icons.description_rounded, 'Risk');
    case 'pending':
    case 'draft':
    case 'new':
    case 'sent':
    case 'unsigned':
    case 'awaiting':
      return _RowStyle(
          C.tint(c, C.amber), C.onAmb(c), Icons.description_rounded, 'Imzo');
    default:
      return _RowStyle(
          C.fill(c), C.muted(c, .5), Icons.description_rounded, null);
  }
}

/// Holat pili (.pill).
class _Pill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          text,
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
        ),
      );
}
