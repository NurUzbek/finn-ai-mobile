import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/add_forms.dart';
import '../services/i18n.dart';
import '../theme/finn_tokens.dart';
import '../widgets/common.dart';
import '../widgets/finn_screen.dart';

/// "Tashkilotlarim" moduli — HTML prototip (`#v-firmalar`) bilan 1:1.
///
/// Brend sarlavha belgisi + firma kartalari (monogramma, nom, STIR,
/// qarz/toza holat, ochiluvchi akkordeon) + filtr chiplari.
/// Nav shell'dan keladi: navIndex + onNavChanged.
class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key, this.navIndex = 1, this.onNavChanged});
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  late Future<Map<String, dynamic>> _f = Api.organizations();
  int _filter = 0; // 0 = Hammasi, 1 = Qarzdor, 2 = Toza

  Future<void> _refresh() async => setState(() => _f = Api.organizations());

  bool _clean(Map<String, dynamic> o) => o['clean'] == true;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FutureBuilder<Map<String, dynamic>>(
      future: _f,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final d = snap.data ?? const {};
        final ok = d['ok'] == true;
        final orgs = ok
            ? ((d['organizations'] as List?)?.cast<Map<String, dynamic>>() ?? [])
            : <Map<String, dynamic>>[];
        final total = orgs.length;
        final cleanCount = orgs.where(_clean).length;

        // "5 ta firma · 2 tasi toza" — sonlar Dart'da, so'zlar tarjimada.
        final subtitle = ok
            ? '$total ${tr('org.firmsWord')} · $cleanCount ${tr('org.cleanWord')}'
            : tr('org.subtitleFallback');

        return FinnScreen(
          title: tr('org.title'),
          subtitle: subtitle,
          showNav: false,
          reserveNav: true,
          // Brend belgisi (☰ modullar menyusi TZ bo'yicha OLIB TASHLANGAN).
          leading: _brandBadge(t),
          actions: [
            _iconBtn(t, Icons.add_rounded, onTap: () async {
              if (await showAddOrganization(context)) _refresh();
            }),
          ],
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!ok)
              _err(t)
            else
              _content(t, orgs.cast<Map<String, dynamic>>()),
          ],
        );
      },
    );
  }

  Widget _content(FinnTokens t, List<Map<String, dynamic>> orgs) {
    final total = orgs.length;
    final cleanCount = orgs.where(_clean).length;
    final debtorCount = total - cleanCount;

    final filtered = orgs.where((o) {
      if (_filter == 1) return !_clean(o);
      if (_filter == 2) return _clean(o);
      return true;
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        _chips(t, total, debtorCount, cleanCount),
        const SizedBox(height: 16),
        if (orgs.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.apartment_rounded,
              text: tr('org.empty'),
              color: t.blue,
            ),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: _filter == 2
                  ? Icons.verified_outlined
                  : Icons.error_outline_rounded,
              text: _filter == 2 ? tr('org.noCleanFound') : tr('org.noDebtor'),
              color: t.blue,
            ),
          )
        else
          for (var i = 0; i < filtered.length; i++)
            StaggerIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _OrgRow(
                    key: ValueKey(filtered[i]['id'] ?? i), o: filtered[i]),
              ),
            ),
      ],
    );
  }

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('org.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('common.retry'))),
          ]),
        ),
      );

  // ── Brend sarlavha belgisi (.hd-ic) ──
  Widget _brandBadge(FinnTokens t) => Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: FinnTokens.brand,
          borderRadius: BorderRadius.circular(FinnTokens.rMd),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 6),
              blurRadius: 18,
              color: t.blue2.withValues(alpha: .28),
            ),
          ],
        ),
        child: const Icon(Icons.apartment_rounded, size: 21, color: Colors.white),
      );

  // ── Harakat tugmasi (.iconbtn) ──
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

  // ── Filter chiplari (.chips / .chip) ──
  Widget _chips(FinnTokens t, int total, int debtor, int clean) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: [
          _chip(t, 0, tr('common.all'), total, null),
          const SizedBox(width: 8),
          _chip(t, 1, tr('org.debtor'), debtor, t.red),
          const SizedBox(width: 8),
          _chip(t, 2, tr('org.clean'), clean, t.green),
        ]),
      );

  Widget _chip(FinnTokens t, int idx, String label, int count, Color? dot) {
    final sel = _filter == idx;
    final fg = sel ? Colors.white : t.ink2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _filter = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: FinnTokens.ease,
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: sel ? t.blue : t.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sel ? t.blue : t.line),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot != null) ...[
            Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                    color: sel ? Colors.white : dot, shape: BoxShape.circle)),
            const SizedBox(width: 7),
          ],
          Text(label,
              style: FinnText.chip(fg)
                  .copyWith(fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
          const SizedBox(width: 6),
          Text('$count',
              style: FinnText.chip(
                  sel ? Colors.white.withValues(alpha: .7) : t.ink3)),
        ]),
      ),
    );
  }
}

// ═══════════ Kengayuvchi firma qatori (.row + .acc) ═══════════
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
    final t = c.tokens;
    final o = widget.o;
    final tone = _clean ? t.tGrn : t.tRed;
    final monoText = _clean ? t.onGrn : t.onRed;
    final debt = (o['debt'] as num?) ?? 0;
    final penalty = (o['penalty'] as num?) ?? 0;

    // Akkordeon qatorlari (faqat mavjud maydonlar).
    final rows = <List<String>>[];
    final director = _s(o['director']);
    final account = _s(o['account']);
    final bank = _s(o['bank']);
    if (director != null) rows.add([tr('org.director'), director]);
    if (account != null) rows.add([tr('org.account'), account]);
    if (bank != null) rows.add([tr('org.bank'), bank]);
    if (rows.isEmpty) {
      rows.add([tr('org.address'), _s(o['address']) ?? tr('org.noData')]);
    }

    return Column(children: [
      // ── Karta qatori (.row) ──
      Material(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(FinnTokens.rLg),
          onTap: () => setState(() => _open = !_open),
          child: Ink(
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(FinnTokens.rLg),
              border: Border.all(color: t.line),
              boxShadow: t.sh,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(children: [
                // monogramma (.m)
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_monogram,
                      style: TextStyle(
                        fontFamily: 'InterTight',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: monoText,
                      )),
                ),
                const SizedBox(width: 13),
                // nom + STIR
                Expanded(
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((o['name'] ?? '—').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FinnText.rowTitle(t.ink)),
                    const SizedBox(height: 2),
                    Text('${tr('org.stir')} ${_s(o['stir']) ?? '—'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FinnText.rowSub(t.ink3)),
                  ]),
                ),
                const SizedBox(width: 13),
                // o'ng tomon (.rt): qarz/penya yoki "Toza" pill
                if (_clean)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.tGrn,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tr('org.clean'), style: FinnText.pill(t.onGrn)),
                  )
                else
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(money(debt), style: FinnText.rowValue(t.red)),
                    const SizedBox(height: 2),
                    Text('${tr('org.penalty')} ${money(penalty)}',
                        style: FinnText.rowSub(t.ink3).copyWith(fontSize: 11)),
                  ]),
                const SizedBox(width: 11),
                // chevron (.cv)
                AnimatedRotation(
                  duration: const Duration(milliseconds: 400),
                  curve: FinnTokens.ease,
                  turns: _open ? 0.5 : 0,
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: t.ink4),
                ),
              ]),
            ),
          ),
        ),
      ),
      // ── Akkordeon (.acc / .acc-in) ──
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 400),
        firstCurve: FinnTokens.ease,
        secondCurve: FinnTokens.ease,
        sizeCurve: FinnTokens.ease,
        crossFadeState:
            _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: t.key,
              borderRadius: BorderRadius.circular(FinnTokens.rLg),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _kv(t, rows[i][0], rows[i][1], top: i > 0),
              ],
            ),
          ),
        ),
      ),
    ]);
  }

  // ── kalit-qiymat qatori (.kv) ──
  Widget _kv(FinnTokens t, String k, String v, {required bool top}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: top
            ? BoxDecoration(
                border: Border(top: BorderSide(color: t.line2)),
              )
            : null,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k,
              style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 13, height: 1.3)
                  .copyWith(color: t.ink3)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(v,
                textAlign: TextAlign.right,
                style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3)
                    .copyWith(color: t.ink)),
          ),
        ]),
      );
}
