import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/plan.dart';
import '../services/i18n.dart';

/// Native tarif/to'lov ekrani — WebView emas. Tariflar API'dan (`/plans`),
/// to'lov `/checkout` orqali yaratiladi. Faqat provayder to'lov sahifasi
/// (Payme/Click, PCI) minimal WebView'da ochiladi. PUSH ekran — FINN dizayn tizimi.
///
/// KO'RINISH: HTML prototip `v-tarif` bo'limiga 1:1 — limit banneri (.lim),
/// oylik/yillik toggle (.tr-per), akkordeon tarif ro'yxati (.pl-list),
/// solishtirish jadvali (.cmp), izoh (.tr-note). Ma'lumot/to'lov mantig'i saqlanadi.
void openSubscription(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Future<Map<String, dynamic>> _f = Api.plans();
  String _cycle = 'monthly';
  bool _busy = false;

  /// Akkordeonda ochiq tarif (joriy tarifdan tashqari — u doim ochiq).
  String? _selected;
  bool _compareOpen = false;

  bool get _yearly => _cycle == 'yearly';

  Future<void> _refresh() async => setState(() => _f = Api.plans());

  String _fmt(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// Joriy tildagi shablonga qiymatlarni qo'yadi.
  String _fill(String key, Map<String, String> vars) {
    var s = tr(key);
    vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('sub.pickTitle'),
      subtitle: tr('sub.pickSub'),
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context)),
      actions: [
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
    final plans = ((d['plans'] as List?) ?? []).cast<Map<String, dynamic>>();
    final current = d['current'] as Map<String, dynamic>?;

    // Standart tanlov: mashhur tarif, aks holda joriy bo'lmagan birinchisi.
    if (_selected == null) {
      final popular = plans.firstWhere(
        (p) => p['popular'] == true && p['is_current'] != true,
        orElse: () => <String, dynamic>{},
      );
      _selected = (popular['slug'] ??
              plans.firstWhere((p) => p['is_current'] != true,
                  orElse: () => <String, dynamic>{})['slug'])
          ?.toString();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12), // .lim margin-top
        _limBanner(t, current),
        const SizedBox(height: 14), // .tr-per margin-top
        _cycleToggle(t),
        const SizedBox(height: 9), // .save-hint margin-top
        SizedBox(
          height: 16, // .save-hint min-height
          child: _yearly
              ? Center(
                  child: Text(tr('sub.saveHint'),
                      style: FinnText.rowSub(t.onGrn)
                          .copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
                )
              : null,
        ),
        const SizedBox(height: 12), // .pl-list margin-top
        for (int i = 0; i < plans.length; i++) ...[
          if (i > 0) const SizedBox(height: 10), // .pl-list gap
          _planCard(t, plans[i]),
        ],
        const SizedBox(height: 14), // .cmp margin-top
        _compareBox(t, plans),
        const SizedBox(height: 14), // .tr-note margin-top
        Text(
          tr('sub.trNote'),
          textAlign: TextAlign.center,
          style: FinnText.rowSub(t.ink4).copyWith(fontSize: 11.5, height: 1.55),
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
            Text(tr('state.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('common.retry'))),
          ]),
        ),
      );

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );

  // ══════════════════════════ .lim — limit banneri ══════════════════════════
  Widget _limBanner(FinnTokens t, Map<String, dynamic>? current) {
    final name = current?['name']?.toString() ?? 'FREE';
    final feats = (current?['features'] as Map?) ?? {};
    final limit = ((feats['orgs_limit'] as num?) ?? 1).toInt();
    final total = limit < 1 ? 1 : limit;
    final segCount = total.clamp(1, 8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.tAmb,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.amber.withValues(alpha: .28)),
              ),
              child: Icon(Icons.lock_outline_rounded, size: 18, color: t.onAmb),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$name ${tr('sub.mode')}',
                      style: FinnText.rowValue(t.ink).copyWith(
                          fontSize: 14.5, letterSpacing: -0.29)),
                  const SizedBox(height: 2),
                  Text(
                    _fill('sub.orgsBand',
                        {'n': '$total', 'u': '$total'}),
                    style: FinnText.rowSub(t.ink3).copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('$total/$total',
                style: FinnText.rowValue(t.onAmb)
                    .copyWith(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.51)),
          ]),
          const SizedBox(height: 13),
          Row(children: [
            for (int i = 0; i < segCount; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: t.amber,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.warning_amber_rounded, size: 14, color: t.onAmb),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(tr('sub.limNote'),
                    style: FinnText.rowSub(t.onAmb)
                        .copyWith(fontSize: 12, height: 1.45)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════ .tr-per — sikl toggle ══════════════════════════
  Widget _cycleToggle(FinnTokens t) {
    Widget seg(String v, Widget child) {
      final on = _cycle == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _cycle = v),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: FinnTokens.ease,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? t.card : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: on ? t.sh : null,
            ),
            child: child,
          ),
        ),
      );
    }

    final monStyle = FinnText.button(_cycle == 'monthly' ? t.ink : t.ink2)
        .copyWith(fontSize: 13.5, letterSpacing: -0.2);
    final yrStyle = FinnText.button(_cycle == 'yearly' ? t.ink : t.ink2)
        .copyWith(fontSize: 13.5, letterSpacing: -0.2);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.key,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        seg('monthly', Text(tr('sub.monthly'), style: monStyle)),
        const SizedBox(width: 3),
        seg(
          'yearly',
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(tr('sub.yearly'), style: yrStyle),
            const SizedBox(width: 6),
            Text('−20%',
                style: FinnText.pill(t.onGrn)
                    .copyWith(fontSize: 11.5, fontWeight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }

  /// Tariflar bo'yicha ko'rsatiladigan xususiyatlar matritsasi (belgi/xoch).
  /// (feature_flag, tarjima_kaliti) — matn tr() orqali build vaqtida hal qilinadi.
  static const _matrix = [
    ('orgs', 'sub.feat.orgs'),
    ('risk', 'sub.feat.risk'),
    ('ai', 'sub.feat.ai'),
    ('counterparty', 'sub.feat.counterparty'),
    ('cadastre', 'sub.feat.cadastre'),
    ('audit', 'sub.feat.audit'),
    ('team', 'sub.feat.team'),
  ];

  String _amount(Map<String, dynamic> p) {
    final price = ((_yearly ? p['yearly'] : p['monthly']) as num?) ?? 0;
    final slug = p['slug']?.toString() ?? '';
    if (price <= 0) return slug == 'free' ? '0' : tr('sub.custom');
    return _fmt(price);
  }

  String _unit(Map<String, dynamic> p) {
    final price = ((_yearly ? p['yearly'] : p['monthly']) as num?) ?? 0;
    final slug = p['slug']?.toString() ?? '';
    if (price <= 0) {
      return slug == 'free' ? tr('sub.trialUnit') : tr('sub.individual');
    }
    return _yearly ? tr('sub.somPerYear') : tr('sub.somPerMonth');
  }

  // ══════════════════════════ .pl — tarif kartasi ══════════════════════════
  Widget _planCard(FinnTokens t, Map<String, dynamic> p) {
    final slug = p['slug']?.toString() ?? '';
    final popular = p['popular'] == true;
    final isCurrent = p['is_current'] == true;
    final isCustom = (((p['monthly'] as num?) ?? 0) <= 0) && slug != 'free';
    final feats =
        ((p['features'] as List?) ?? []).map((e) => e.toString()).toSet();

    final expanded = isCurrent || _selected == slug;
    final accent = isCurrent ? t.green : t.blue;
    final borderColor = expanded ? accent : t.line;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isCurrent ? null : () => setState(() => _selected = slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: FinnTokens.ease,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: t.sh,
        ),
        child: Stack(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── .pl-h — sarlavha ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                child: Row(children: [
                  _radio(t, expanded, accent),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p['name']?.toString() ?? slug,
                            style: FinnText.button(t.ink)
                                .copyWith(fontSize: 15.5, letterSpacing: -0.37)),
                        const SizedBox(height: 2),
                        Text(
                          p['description']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FinnText.rowSub(t.ink3).copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_amount(p),
                          style: FinnText.rowValue(t.ink).copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.68)),
                      const SizedBox(height: 2),
                      Text(_unit(p),
                          style:
                              FinnText.rowSub(t.ink3).copyWith(fontSize: 10.5)),
                    ],
                  ),
                ]),
              ),
              // ── .pl-b — akkordeon tana ──
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: FinnTokens.ease,
                alignment: Alignment.topCenter,
                child: expanded
                    ? _planBody(t, p, feats, isCurrent, isCustom)
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
          // ── .pl-tag ──
          if (isCurrent)
            _tag(t, tr('sub.current'), t.green)
          else if (popular)
            _tag(t, tr('sub.popular'), t.blue),
        ]),
      ),
    );
  }

  Widget _radio(FinnTokens t, bool on, Color accent) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: FinnTokens.ease,
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: on ? accent : t.ink4,
            width: on ? 7 : 1.5,
          ),
        ),
      );

  Widget _planBody(FinnTokens t, Map<String, dynamic> p, Set<String> feats,
      bool isCurrent, bool isCustom) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in _matrix) _featRow(t, m.$1, tr(m.$2), feats.contains(m.$1)),
          const SizedBox(height: 14), // .pl-go margin-top
          isCurrent
              ? _planButton(t, tr('sub.currentMode'), ghost: true, onTap: null)
              : _planButton(
                  t,
                  isCustom ? tr('sub.contact') : tr('common.select'),
                  ghost: false,
                  onTap: _busy ? null : () => _openPaymentSheet(t, p),
                ),
        ],
      ),
    );
  }

  Widget _featRow(FinnTokens t, String flag, String label, bool has) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line2)),
      ),
      child: Row(children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: has ? t.tGrn : t.key,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(has ? Icons.check_rounded : Icons.close_rounded,
              size: 12, color: has ? t.onGrn : t.ink4),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: FinnText.chip(has ? t.ink : t.ink3)
                  .copyWith(fontWeight: FontWeight.w400)),
        ),
      ]),
    );
  }

  Widget _planButton(FinnTokens t, String label,
      {required bool ghost, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ghost ? t.key : null,
          gradient: ghost ? null : FinnTokens.brand,
          borderRadius: BorderRadius.circular(FinnTokens.rMd),
          boxShadow: ghost
              ? null
              : [
                  BoxShadow(
                      color: t.blue2.withValues(alpha: .28),
                      blurRadius: 20,
                      offset: const Offset(0, 7))
                ],
        ),
        child: Text(label,
            style: FinnText.button(ghost ? t.ink2 : Colors.white)
                .copyWith(fontSize: 14.5, letterSpacing: -0.22)),
      ),
    );
  }

  Widget _tag(FinnTokens t, String label, Color bg) => Positioned(
        top: 0,
        right: 16,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
          ),
          child: Text(label.toUpperCase(),
              style: FinnText.label(Colors.white).copyWith(
                  fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.81)),
        ),
      );

  // ══════════════════════════ .cmp — solishtirish jadvali ══════════════════════════
  Widget _compareBox(FinnTokens t, List<Map<String, dynamic>> plans) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _compareOpen = !_compareOpen),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(children: [
              Expanded(
                child: Text(tr('sub.compare'),
                    style: FinnText.cardTitle(t.ink)
                        .copyWith(fontSize: 14, letterSpacing: -0.28)),
              ),
              AnimatedRotation(
                turns: _compareOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 400),
                curve: FinnTokens.spring,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: t.ink3),
              ),
            ]),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: FinnTokens.ease,
          alignment: Alignment.topCenter,
          child: _compareOpen
              ? _compareTable(t, plans)
              : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }

  Widget _compareTable(FinnTokens t, List<Map<String, dynamic>> plans) {
    String short(String n) {
      if (n.toLowerCase().startsWith('enter')) return 'Ent.';
      return n.length > 4 ? n.substring(0, 4) : n;
    }

    final headStyle = FinnText.rowValue(t.ink)
        .copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0);
    final nameStyle = FinnText.rowSub(t.ink2).copyWith(fontSize: 11.5);
    final yStyle = FinnText.rowSub(t.onGrn)
        .copyWith(fontSize: 11.5, fontWeight: FontWeight.w700);
    final nStyle = FinnText.rowSub(t.ink4).copyWith(fontSize: 11.5);

    Widget cell(Widget child, {bool first = false}) => Container(
          height: 34,
          alignment: first ? Alignment.centerLeft : Alignment.center,
          padding: first
              ? const EdgeInsets.only(left: 16, right: 6)
              : const EdgeInsets.symmetric(horizontal: 6),
          child: child,
        );

    TableRow row(List<Widget> cells, {bool header = false}) => TableRow(
          decoration: header
              ? null
              : BoxDecoration(border: Border(top: BorderSide(color: t.line2))),
          children: cells,
        );

    final colWidths = <int, TableColumnWidth>{
      0: const FixedColumnWidth(140),
      for (int i = 0; i < plans.length; i++)
        i + 1: const FixedColumnWidth(62),
    };

    final rows = <TableRow>[
      row(header: true, [
        cell(const SizedBox(), first: true),
        for (final p in plans)
          cell(Text(short(p['name']?.toString() ?? ''), style: headStyle)),
      ]),
      for (final m in _matrix)
        row([
          cell(Text(tr(m.$2), style: nameStyle, maxLines: 2), first: true),
          for (final p in plans)
            cell(() {
              final has = ((p['features'] as List?) ?? [])
                  .map((e) => e.toString())
                  .contains(m.$1);
              return Text(has ? '✓' : '—',
                  style: has ? yStyle : nStyle);
            }()),
        ]),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 140 + plans.length * 62,
        child: Table(columnWidths: colWidths, children: rows),
      ),
    );
  }

  void _openPaymentSheet(FinnTokens t, Map<String, dynamic> plan) {
    final methods = [
      (id: 'payme', label: 'Payme', color: t.teal, icon: Icons.credit_card),
      (id: 'click', label: 'Click', color: t.blue, icon: Icons.credit_card),
      (id: 'uzum', label: 'Uzum Bank', color: t.purple, icon: Icons.account_balance_wallet_outlined),
      (id: 'paynet', label: 'Paynet', color: t.cyan, icon: Icons.account_balance_wallet_outlined),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: t.ink4, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text(tr('sub.choosePayment'), style: FinnText.cardTitle(t.ink)),
            const SizedBox(height: 4),
            Text('${plan['name']} · ${_fmt((_cycle == 'yearly' ? plan['yearly'] : plan['monthly']) as num)} ${tr('common.som')}',
                style: FinnText.rowSub(t.ink2)),
            const SizedBox(height: 16),
            ...methods.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () { Navigator.pop(ctx); _pay(plan, m.id); },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: t.line2,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.line),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: m.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(11)),
                          child: Icon(m.icon, color: m.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(m.label, style: FinnText.rowTitle(t.ink))),
                        Icon(Icons.chevron_right, color: t.ink3),
                      ]),
                    ),
                  ),
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _pay(Map<String, dynamic> plan, String provider) async {
    setState(() => _busy = true);
    try {
      final r = await Api.checkout(plan: plan['slug'].toString(), cycle: _cycle, provider: provider);
      if (r['ok'] != true) {
        _snack(r['message']?.toString() ?? tr('sub.paymentFailed'));
        return;
      }
      final url = r['url']?.toString();
      if (url == null || url.isEmpty) {
        _snack(tr('sub.linkFailed'));
        return;
      }
      // BARCHA provayderlar (Payme/Click/Uzum/Paynet) — avval TASHQI BRAUZER (Chrome).
      // Provayder sahifasidagi "Ilovada ochish" tugmasi (deep-link/intent) FAQAT
      // brauzerda ishlaydi; ichki WebView uni bloklaydi — shuning uchun WebView
      // faqat OXIRGI zaxira. (Avval Payme/Click doim WebView'da ochilib, deep-link
      // ishlamas edi — asosiy muammo shu edi.)
      final uri = Uri.tryParse(url);
      var launched = false;
      if (uri != null) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          launched = false;
        }
        if (!launched) {
          try {
            launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
          } catch (_) {
            launched = false;
          }
        }
      }
      if (!launched && !kIsWeb && mounted) {
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => _PaymentPage(url: url)),
        );
        if (paid == true) {
          await PlanState.i.load();
          _snack(tr('sub.paid'), ok: true);
          _refresh();
        }
      } else if (!launched) {
        _snack(tr('sub.linkFailed'));
      }
    } catch (e) {
      _snack(tr('state.error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m, {bool ok = false}) {
    if (!mounted) return;
    final t = context.tokens;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: ok ? t.green : null,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

/// Minimal to'lov sahifasi — faqat provayder checkout (PCI). Muvaffaqiyatda pop(true).
class _PaymentPage extends StatefulWidget {
  final String url;
  const _PaymentPage({required this.url});
  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  WebViewController? _c;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onPageStarted: (u) {
          if (u.contains('/subscription/success')) Navigator.of(context).pop(true);
        },
        onNavigationRequest: (req) {
          if (req.url.contains('/subscription/success')) { Navigator.of(context).pop(true); return NavigationDecision.prevent; }
          final s = Uri.tryParse(req.url)?.scheme ?? '';
          if (s.isNotEmpty && s != 'http' && s != 'https') { launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication); return NavigationDecision.prevent; }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: t.ink2),
        title: Text(tr('sub.payment'), style: FinnText.cardTitle(t.ink).copyWith(fontSize: 17)),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                    color: t.blue,
                    backgroundColor: Colors.transparent))
            : null,
      ),
      body: _c == null ? const SizedBox() : WebViewWidget(controller: _c!),
    );
  }
}
