import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/common.dart';
import '../services/api.dart';
import '../services/i18n.dart';

/// "E-hujjat (Didox)" moduli — veb prototip `#v-didox` bilan 1:1.
/// Ulanish holati sarlavhada ("Didox integratsiyasi · ulangan"), yo'nalish
/// bo'yicha chiplar (Kiruvchi / Chiquvchi / Rad etilgan), QQS zanjiri
/// ogohlantirishi va faktura qatorlari. PUSH ekran — FINN dizayn tizimi.
class DidoxScreen extends StatefulWidget {
  const DidoxScreen({super.key});
  @override
  State<DidoxScreen> createState() => _DidoxScreenState();
}

/// Yo'nalish/holat bo'yicha filtr chiplari.
enum _Tab { kiruvchi, chiquvchi, rad }

String _tabLabel(_Tab tab) => tr('didox.tab.${tab.name}');
String _eyebrowLabel(_Tab tab) => tr('didox.eyebrow.${tab.name}');

/// Bitta normallashtirilgan Didox hujjati.
class _Doc {
  final String number, type, date, status, party;
  final int owner; // 0 = kiruvchi, 1 = chiquvchi
  final double amount;
  const _Doc(this.number, this.type, this.date, this.status, this.party,
      this.owner, this.amount);

  factory _Doc.of(Map<String, dynamic> m) => _Doc(
        (m['number'] ?? '—').toString(),
        (m['type'] ?? '').toString(),
        (m['date'] ?? '').toString(),
        (m['status'] ?? '').toString(),
        (m['party'] ?? m['partner_name'] ?? '').toString(),
        (m['owner'] as num?)?.toInt() ?? 0,
        (m['amount'] as num?)?.toDouble() ?? 0,
      );

  /// Xom holatni guruhga moslashtiradi.
  String get group {
    switch (status.toLowerCase()) {
      case 'signed':
      case 'accepted':
      case 'ok':
        return 'signed';
      case 'pending':
      case 'draft':
      case 'waiting':
      case 'unsigned':
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
}

class _DidoxScreenState extends State<DidoxScreen> {
  late Future<Map<String, dynamic>> _f = Api.didox();
  Future<void> _refresh() async => setState(() => _f = Api.didox());

  _Tab _tab = _Tab.kiruvchi;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('didox.title'),
      subtitle: tr('didox.subtitle'),
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context)),
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
    final docs = ((d['documents'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => _Doc.of(Map<String, dynamic>.from(e)))
        .toList();

    if (docs.isEmpty) {
      return _empty(t, Icons.description_outlined,
          tr('didox.emptyConnect'), 90);
    }

    // Chip sonlari.
    final kir = docs.where((x) => x.owner == 0).length;
    final chiq = docs.where((x) => x.owner == 1).length;
    final rad = docs.where((x) => x.group == 'rejected').length;

    // Faol filtr bo'yicha ro'yxat.
    final shown = docs.where((x) {
      switch (_tab) {
        case _Tab.kiruvchi:
          return x.owner == 0;
        case _Tab.chiquvchi:
          return x.owner == 1;
        case _Tab.rad:
          return x.group == 'rejected';
      }
    }).toList();

    // QQS ogohlantirishi — rad etilgan (risk) faktura bo'lsa.
    final risks = docs.where((x) => x.group == 'rejected').toList();
    Widget? alert;
    if (risks.isNotEmpty) {
      final party = risks.first.party.trim().isEmpty
          ? tr('didox.counterparty')
          : risks.first.party.trim();
      var n = docs.where((x) => x.party.trim() == party).length;
      if (n == 0) n = risks.length;
      alert = _alert(t, party, n);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // ── Filtr chiplari ──
        StaggerIn(index: 0, child: _chips(t, kir, chiq, rad)),
        // ── QQS zanjiri ogohlantirishi ──
        if (alert != null) ...[
          const SizedBox(height: 14),
          StaggerIn(index: 1, child: alert),
        ],
        // ── Eyebrow ──
        StaggerIn(index: 2, child: _eyebrow(t, _eyebrowLabel(_tab))),
        // ── Fakturalar ──
        if (shown.isEmpty)
          _empty(t, Icons.filter_alt_off_rounded,
              tr('didox.emptyFilter'), 40)
        else
          ...shown.asMap().entries.map((e) => StaggerIn(
                index: e.key + 3,
                child: _DocRow(doc: e.value),
              )),
      ],
    );
  }

  // ─────────────────────── CHIPLAR ───────────────────────
  Widget _chips(FinnTokens t, int kir, int chiq, int rad) {
    final counts = {
      _Tab.kiruvchi: kir,
      _Tab.chiquvchi: chiq,
      _Tab.rad: rad,
    };
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          for (final tab in _Tab.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(t, tab, _tabLabel(tab), counts[tab]!),
            ),
        ],
      ),
    );
  }

  Widget _chip(FinnTokens t, _Tab tab, String label, int count) {
    final on = _tab == tab;
    return GestureDetector(
      onTap: () => setState(() => _tab = tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? t.blue : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? t.blue : t.line),
          boxShadow: on ? null : t.sh,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: FinnText.chip(on ? Colors.white : t.ink2)),
          const SizedBox(width: 6),
          Text('$count',
              style: FinnText.chip(
                  on ? Colors.white.withValues(alpha: .8) : t.ink3)),
        ]),
      ),
    );
  }

  // ─────────────────────── QQS OGOHLANTIRISH ───────────────────────
  Widget _alert(FinnTokens t, String party, int n) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: t.tRed,
          borderRadius: BorderRadius.circular(FinnTokens.rLg),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child:
                Icon(Icons.warning_amber_rounded, size: 20, color: t.onRed),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('didox.alert.title'), style: FinnText.rowValue(t.onRed)),
              const SizedBox(height: 4),
              Text(
                tr('didox.alert.body')
                    .replaceAll('{party}', party)
                    .replaceAll('{n}', '$n'),
                style: FinnText.rowSub(t.ink2),
              ),
            ]),
          ),
        ]),
      );

  // ─────────────────────── EYEBROW ───────────────────────
  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );

  // ─────────────────────── BO'SH HOLAT ───────────────────────
  Widget _empty(FinnTokens t, IconData ic, String text, double top) => Padding(
        padding: EdgeInsets.only(top: top),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(color: t.tPur, shape: BoxShape.circle),
              child: Icon(ic, size: 32, color: t.purple),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: FinnText.body(t.ink3)),
          ]),
        ),
      );

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('didox.offline'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('didox.retry'))),
          ]),
        ),
      );

  // `.back` — 36×36, radius 12, chegara, soyasiz.
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

/// Bitta faktura qatori (.row) — monogram + kontragent/tavsif + holat pili.
class _DocRow extends StatelessWidget {
  final _Doc doc;
  const _DocRow({required this.doc});

  ({Color bg, Color on, String label}) _status(FinnTokens t) {
    switch (doc.group) {
      case 'signed':
        return (bg: t.tGrn, on: t.onGrn, label: tr('didox.status.accepted'));
      case 'pending':
        return (bg: t.tAmb, on: t.onAmb, label: tr('didox.status.sign'));
      case 'rejected':
        return (bg: t.tRed, on: t.onRed, label: tr('didox.status.risk'));
      default:
        return (bg: t.key, on: t.ink3, label: '');
    }
  }

  /// Kontragent nomidan monogram (2 harf).
  String _mono() {
    final words = doc.party
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  /// Summani bo'sh joy bilan ajratadi: 8400000 → "8 400 000".
  String _amount() {
    if (doc.amount <= 0) return '';
    final s = doc.amount.round().toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final st = _status(t);
    final mono = _mono();

    final title =
        doc.party.trim().isNotEmpty ? doc.party.trim() : tr('didox.title');
    final amount = _amount();
    final sub = <String>[
      '№ ${doc.number}',
      if (doc.date.trim().isNotEmpty) doc.date.trim(),
      if (amount.isNotEmpty) amount,
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
        // monogram — holat tinti bilan
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: st.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: mono.isNotEmpty
              ? Text(
                  mono,
                  style: TextStyle(
                    fontFamily: 'InterTight',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: st.on,
                  ),
                )
              : Icon(Icons.receipt_long_rounded, size: 18, color: st.on),
        ),
        const SizedBox(width: 13),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FinnText.rowTitle(t.ink)),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FinnText.rowSub(t.ink3).copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ]),
        ),
        if (st.label.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: st.bg,
              borderRadius: BorderRadius.circular(FinnTokens.rLg),
            ),
            child: Text(st.label, style: FinnText.pill(st.on)),
          ),
        ],
      ]),
    );
  }
}
