import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/common.dart';
import '../services/api.dart';
import '../services/i18n.dart';

/// "Hujjatlar" moduli — shartnomalar + fakturalar (veb `#v-hujjat` bilan 1:1).
/// Filtr chiplari (Hammasi / Shartnoma / Akt / Hisob-faktura) va holat bo'yicha
/// guruhlar: "Imzo kutmoqda" va "Yaqinda". PUSH ekran — FINN dizayn tizimi.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

/// Filtr turlari.
enum _Kind { hammasi, shartnoma, akt, faktura }

/// Filtr chipi yorlig'i — joriy tilda (`tr`).
String _kindLabel(_Kind k) {
  switch (k) {
    case _Kind.hammasi:
      return tr('doc.filter.all');
    case _Kind.shartnoma:
      return tr('doc.filter.contract');
    case _Kind.akt:
      return tr('doc.filter.act');
    case _Kind.faktura:
      return tr('doc.filter.invoice');
  }
}

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
    final t = context.tokens;
    return FinnScreen(
      title: tr('doc.title'),
      subtitle: tr('doc.subtitle'),
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context)),
      actions: [
        _iconBtn(t, Icons.search_rounded),
        const SizedBox(width: 8),
        _iconBtn(t, Icons.refresh_rounded, onTap: _refresh),
      ],
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final d = snap.data ?? {};
            if (d['ok'] != true) return _err(t);
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final all = <_Doc>[
      ...((d['contracts'] as List?)?.cast<Map<String, dynamic>>() ?? const [])
          .map(_Doc.contract),
      ...((d['invoices'] as List?)?.cast<Map<String, dynamic>>() ?? const [])
          .map(_Doc.invoice),
    ];
    final shown = _filter == _Kind.hammasi
        ? all
        : all.where((x) => x.kind == _filter).toList();
    final pending = shown.where((x) => x.isPending).toList();
    final recent = shown.where((x) => !x.isPending).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // Filtr chiplari.
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              for (final k in _Kind.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(
                    label: _kindLabel(k),
                    on: _filter == k,
                    onTap: () => setState(() => _filter = k),
                  ),
                ),
            ],
          ),
        ),
        if (shown.isEmpty) _empty(t),
        if (pending.isNotEmpty) ...[
          _eyebrow(t, tr('doc.group.pending')),
          for (var i = 0; i < pending.length; i++)
            StaggerIn(index: i, child: _Row(doc: pending[i])),
        ],
        if (recent.isNotEmpty) ...[
          _eyebrow(t, tr('doc.group.recent')),
          for (var i = 0; i < recent.length; i++)
            StaggerIn(index: pending.length + i, child: _Row(doc: recent[i])),
        ],
      ],
    );
  }

  Widget _empty(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.description_outlined, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('doc.empty'), style: FinnText.body(t.ink3)),
          ]),
        ),
      );

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('doc.offline'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('doc.retry'))),
          ]),
        ),
      );

  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );

  // `.iconbtn,.back` — 36×36, radius 12, chegara, soyasiz.
  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Icon(ic, size: 18, color: t.ink2),
        ),
      );
}

/// Filtr chipi (--chip / .chip.on).
class _Chip extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? t.blue : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? t.blue : t.line),
        ),
        child: Text(label, style: FinnText.chip(on ? Colors.white : t.ink2)),
      ),
    );
  }
}

/// Hujjat qatori (.row) — ikonka + sarlavha/tavsif + holat pili.
class _Row extends StatelessWidget {
  final _Doc doc;
  const _Row({required this.doc});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final st = _style(t, doc);
    final sub = [
      if (doc.party.trim().isNotEmpty) doc.party.trim(),
      if (doc.date.trim().isNotEmpty) doc.date.trim(),
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
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
                style: FinnText.rowTitle(t.ink),
              ),
              if (sub.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FinnText.rowSub(t.ink3),
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

_RowStyle _style(FinnTokens t, _Doc d) {
  final s = d.status.toLowerCase();
  switch (s) {
    case 'signed':
    case 'paid':
    case 'active':
    case 'accepted':
    case 'completed':
    case 'done':
      return _RowStyle(t.tGrn, t.onGrn, Icons.check_rounded,
          s == 'accepted' || s == 'paid' ? tr('doc.pill.accepted') : tr('doc.pill.signed'));
    case 'rejected':
    case 'cancelled':
      return _RowStyle(t.tRed, t.onRed, Icons.description_rounded, tr('doc.pill.risk'));
    case 'pending':
    case 'draft':
    case 'new':
    case 'sent':
    case 'unsigned':
    case 'awaiting':
      return _RowStyle(t.tAmb, t.onAmb, Icons.description_rounded, tr('doc.pill.sign'));
    default:
      return _RowStyle(t.key, t.ink3, Icons.description_rounded, null);
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
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(FinnTokens.rLg)),
        child: Text(text, style: FinnText.pill(fg)),
      );
}
