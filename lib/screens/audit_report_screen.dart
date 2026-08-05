import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Audit jurnali" — tashkilotlar bo'yicha audit ballari (composite score).
/// Dizayn: finn-app-full.html `#v-audit` (chiplar + eyebrow guruhlar + timeline).
class AuditReportScreen extends StatefulWidget {
  const AuditReportScreen({super.key});
  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

/// Ball diapazoni: yuqori ball = past risk (yaxshi), past ball = yuqori risk.
class _Band {
  final String key, label;
  final Color? color; // null → neytral (baholanmagan)
  final Color Function(BuildContext)? on;
  final IconData icon;
  final bool Function(num?) match;
  const _Band(this.key, this.label, this.color, this.on, this.icon, this.match);

  Color col(BuildContext c) => color ?? C.muted(c, .6);
  Color onCol(BuildContext c) => on?.call(c) ?? C.muted(c, .7);
  Color tint(BuildContext c) => color != null ? C.tint(c, color!) : C.fill(c, .06);
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  late Future<Map<String, dynamic>> _f = Api.auditReport();
  String _sel = 'all';

  Future<void> _refresh() async => setState(() => _f = Api.auditReport());

  num? _score(dynamic v) => v is num ? v : null;

  final List<_Band> _bands = [
    _Band('good', 'Past risk', C.green, C.onGrn, Icons.verified_rounded,
        (s) => s != null && s >= 70),
    _Band('mid', "O'rta risk", C.amber, C.onAmb, Icons.warning_amber_rounded,
        (s) => s != null && s >= 40 && s < 70),
    _Band('high', 'Yuqori risk', C.red, C.onRed, Icons.error_outline_rounded,
        (s) => s != null && s < 40),
    _Band('none', 'Baholanmagan', null, null, Icons.help_outline_rounded,
        (s) => s == null),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _header(context),
            Expanded(
              child: Loader(
                future: _f,
                onRefresh: _refresh,
                builder: (d) {
                  final items = (d['items'] as List? ?? const [])
                      .cast<Map<String, dynamic>>();
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.history_toggle_off_rounded,
                      color: C.cyan,
                      text: 'Audit yozuvlari topilmadi',
                    );
                  }
                  return _list(context, items);
                },
              ),
            ),
          ]),
        ),
      );

  // ─── Sarlavha (orqaga + yuklab olish) ───────────────────────────
  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Row(children: [
          _iconBtn(context, Icons.chevron_left_rounded, () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Audit jurnali',
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                      height: 1.1,
                      color: C.text(context))),
              const SizedBox(height: 3),
              Text('Barcha harakatlar tarixi',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context, .45))),
            ]),
          ),
          _iconBtn(context, Icons.file_download_outlined, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CSV eksport tez orada')),
            );
          }),
        ]),
      );

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.card(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.border(context)),
          ),
          child: Icon(icon, size: 20, color: C.muted(context, .7)),
        ),
      );

  // ─── Ro'yxat (chiplar + guruhlangan timeline) ───────────────────
  Widget _list(BuildContext context, List<Map<String, dynamic>> items) {
    // Guruhlash: har band → tegishli tashkilotlar
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final it in items) {
      final s = _score(it['score']);
      final band = _bands.firstWhere((b) => b.match(s));
      grouped.putIfAbsent(band.key, () => []).add(it);
    }
    final present = _bands.where((b) => (grouped[b.key] ?? const []).isNotEmpty).toList();

    // Chiplar: Hammasi + mavjud bandlar
    final chips = <_Chip>[const _Chip('all', 'Hammasi')];
    for (final b in present) {
      chips.add(_Chip(b.key, b.label));
    }
    // Tanlangan chip endi mavjud emas bo'lsa — Hammasi
    if (_sel != 'all' && chips.every((c) => c.key != _sel)) _sel = 'all';

    final visible = present.where((b) => _sel == 'all' || _sel == b.key).toList();

    var idx = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        _chipsRow(context, chips),
        for (final b in visible) ...[
          _eyebrow(context, b.label),
          StaggerIn(index: idx++, child: _group(context, b, grouped[b.key]!)),
        ],
        const SizedBox(height: 18),
        Text(
          'Audit ballari tashkilot risk profili asosida hisoblanadi va '
          '24 oy saqlanadi. CSV shaklida yuklab olish mumkin.',
          style: TextStyle(fontSize: 11.5, height: 1.5, color: C.muted(context, .38)),
        ),
      ],
    );
  }

  // ─── Chiplar qatori ─────────────────────────────────────────────
  Widget _chipsRow(BuildContext context, List<_Chip> chips) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = chips[i];
              final on = _sel == c.key;
              return GestureDetector(
                onTap: () => setState(() => _sel = c.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: on ? C.blue : C.card(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: on ? C.blue : C.border(context)),
                  ),
                  child: Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? Colors.white : C.muted(context, .65),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  // ─── Bo'lim sarlavhasi (eyebrow) ────────────────────────────────
  Widget _eyebrow(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
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

  // ─── Guruh (grp) — timeline kartasi ─────────────────────────────
  Widget _group(BuildContext context, _Band b, List<Map<String, dynamic>> rows) => Container(
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: C.border(context, .05)),
            _st(context, b, rows[i]),
          ],
        ]),
      );

  // ─── Timeline qatori (.st) ──────────────────────────────────────
  Widget _st(BuildContext context, _Band b, Map<String, dynamic> it) {
    final org = (it['org'] ?? '').toString().trim();
    final stir = (it['stir'] ?? '').toString().trim();
    final score = _score(it['score']);
    final label = score == null ? '—' : score.round().toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: b.tint(context),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(b.icon, size: 17, color: b.onCol(context)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              org.isEmpty ? 'Nomsiz tashkilot' : org,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -.2,
                color: C.text(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stir.isEmpty ? b.label : 'STIR $stir · ${b.label}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: C.muted(context, .42)),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
              color: b.col(context),
            ),
          ),
          Text('ball', style: TextStyle(fontSize: 10, color: C.muted(context, .35))),
        ]),
      ]),
    );
  }
}

class _Chip {
  final String key, label;
  const _Chip(this.key, this.label);
}
