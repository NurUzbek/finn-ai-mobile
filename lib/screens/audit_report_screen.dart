import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// "Audit jurnali" — barcha harakatlar tarixi (activity timeline).
///
/// HTML prototip `#v-audit` (proto.html) ga 1:1 moslangan: kategoriya chiplari
/// (Hammasi / Hujjat / To'lov / Sozlama), kunlar bo'yicha guruhlar (Bugun /
/// Kecha) va `.st` qatorlari (rangli ikonka + sarlavha + izoh).
///
/// FINN dizayn tizimi: FinnScreen (PUSH) + tokens + FinnText.
class AuditReportScreen extends StatefulWidget {
  const AuditReportScreen({super.key});
  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  final Future<Map<String, dynamic>> _f = Api.auditReport();
  String _sel = 'all';

  // ─── Chiplar (prototipdagi qat'iy ro'yxat) ──────────────────────
  List<_Chip> get _chips => [
        _Chip('all', tr('audit.chipAll')),
        _Chip('hujjat', tr('audit.chipDoc')),
        _Chip('tolov', tr('audit.chipPay')),
        _Chip('sozlama', tr('audit.chipSetting')),
      ];

  // ─── Prototipdagi namuna yozuvlari (API bo'sh bo'lsa ko'rsatiladi) ─
  List<_DayGroup> get _sample => [
        _DayGroup(tr('audit.today'), [
          _Entry('contract', tr('audit.s1Title'), tr('audit.s1Sub')),
          _Entry('payment', tr('audit.s2Title'), tr('audit.s2Sub')),
          _Entry('invite', tr('audit.s3Title'), tr('audit.s3Sub')),
        ]),
        _DayGroup(tr('audit.yesterday'), [
          _Entry('setting', tr('audit.s4Title'), tr('audit.s4Sub')),
          _Entry('device', tr('audit.s5Title'), tr('audit.s5Sub')),
        ]),
      ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('audit.title'),
      subtitle: tr('audit.subtitle'),
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).maybePop()),
      actions: [
        _iconBtn(t, Icons.file_download_outlined, onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('audit.csvSoon'))),
          );
        }),
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
            final groups = _resolve(snap.data);
            return _content(t, groups);
          },
        ),
      ],
    );
  }

  // ─── Ma'lumot manbasi: API → namuna ─────────────────────────────
  List<_DayGroup> _resolve(Map<String, dynamic>? d) {
    if (d != null && d['ok'] == true) {
      final parsed = _fromApi(d);
      if (parsed.isNotEmpty) return parsed;
    }
    return _sample;
  }

  List<_DayGroup> _fromApi(Map<String, dynamic> d) {
    final raw = (d['items'] as List?) ?? const [];
    final buckets = <String, List<_Entry>>{};
    final order = <String>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final title = (m['title'] ?? m['action'] ?? '').toString().trim();
      if (title.isEmpty) continue; // eski (risk-score) shakl — namunaga qaytamiz
      final kind =
          _normKind((m['kind'] ?? m['type'] ?? m['category'] ?? '').toString());
      final subtitle = (m['subtitle'] ?? m['meta'] ?? '').toString().trim();
      final group =
          (m['group'] ?? m['day'] ?? m['date'] ?? tr('audit.otherGroup'))
              .toString()
              .trim();
      final g = group.isEmpty ? tr('audit.otherGroup') : group;
      if (!buckets.containsKey(g)) {
        buckets[g] = [];
        order.add(g);
      }
      buckets[g]!.add(_Entry(kind, title, subtitle));
    }
    return [for (final g in order) _DayGroup(g, buckets[g]!)];
  }

  String _normKind(String k) {
    const known = {'contract', 'payment', 'invite', 'setting', 'device'};
    return known.contains(k) ? k : 'setting';
  }

  // ─── Kontent (chiplar + guruhlangan timeline) ───────────────────
  Widget _content(FinnTokens t, List<_DayGroup> groups) {
    // Tanlangan chipga ko'ra guruhlarni filtrlash
    final visible = <_DayGroup>[];
    for (final g in groups) {
      final entries = g.entries
          .where((e) => _sel == 'all' || _kind(e.kind).category == _sel)
          .toList();
      if (entries.isNotEmpty) visible.add(_DayGroup(g.label, entries));
    }

    var idx = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chipsRow(t),
        for (final g in visible) ...[
          _eyebrow(t, g.label),
          StaggerIn(index: idx++, child: _group(t, g.entries)),
        ],
        const SizedBox(height: 16),
        Text(
          tr('audit.footer'),
          style: FinnText.rowSub(t.ink3),
        ),
      ],
    );
  }

  // ─── Chiplar qatori ─────────────────────────────────────────────
  Widget _chipsRow(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 2),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = _chips[i];
              final on = _sel == c.key;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _sel = c.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: FinnTokens.ease,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: on ? t.blue : t.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: on ? t.blue : t.line),
                    boxShadow: on ? null : t.sh,
                  ),
                  child: Text(
                    c.label,
                    style: on
                        ? FinnText.chip(Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)
                        : FinnText.chip(t.ink2),
                  ),
                ),
              );
            },
          ),
        ),
      );

  // ─── Bo'lim sarlavhasi (eyebrow) ────────────────────────────────
  Widget _eyebrow(FinnTokens t, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(text.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );

  // ─── Guruh (grp) — timeline kartasi ─────────────────────────────
  Widget _group(FinnTokens t, List<_Entry> rows) => Container(
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: t.line),
          boxShadow: t.sh,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.line2),
            _st(t, rows[i]),
          ],
        ]),
      );

  // ─── Timeline qatori (.st) ──────────────────────────────────────
  Widget _st(FinnTokens t, _Entry e) {
    final k = _kind(e.kind);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: k.tint(t),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(k.icon, size: 17, color: k.on(t)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              e.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FinnText.rowTitle(t.ink),
            ),
            if (e.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                e.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FinnText.rowSub(t.ink3),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  // ─── Ikonka tugmasi (.iconbtn / .back) ──────────────────────────
  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Icon(ic, size: 18, color: t.ink2),
        ),
      );

  // ─── Yozuv turi → ikonka + kategoriya + rang ────────────────────
  _Kind _kind(String key) {
    switch (key) {
      case 'contract':
        return _Kind(Icons.check_rounded, 'hujjat', (t) => t.tGrn, (t) => t.onGrn);
      case 'payment':
        return _Kind(
            Icons.credit_card_rounded, 'tolov', (t) => t.tBlu, (t) => t.blue);
      case 'invite':
        return _Kind(Icons.person_outline_rounded, 'sozlama', (t) => t.tPur,
            (t) => t.onPur);
      case 'device':
        return _Kind(
            Icons.smartphone_rounded, 'sozlama', (t) => t.key, (t) => t.ink2);
      case 'setting':
      default:
        return _Kind(
            Icons.settings_outlined, 'sozlama', (t) => t.tAmb, (t) => t.onAmb);
    }
  }
}

/// Yozuv turi ta'rifi: ikonka, chip kategoriyasi va ranglar.
class _Kind {
  final IconData icon;
  final String category; // 'hujjat' | 'tolov' | 'sozlama'
  final Color Function(FinnTokens) tint;
  final Color Function(FinnTokens) on;
  const _Kind(this.icon, this.category, this.tint, this.on);
}

class _Entry {
  final String kind, title, subtitle;
  const _Entry(this.kind, this.title, this.subtitle);
}

class _DayGroup {
  final String label;
  final List<_Entry> entries;
  const _DayGroup(this.label, this.entries);
}

class _Chip {
  final String key, label;
  const _Chip(this.key, this.label);
}
