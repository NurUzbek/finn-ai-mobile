import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../widgets/common.dart';
import '../services/api.dart';
import '../services/i18n.dart';

/// Kontragentlarni tekshirish moduli — STIR bo'yicha risk tekshiruvlari ro'yxati.
/// PUSH ekran — FINN dizayn tizimi (FinnScreen + tokens + FinnText).
class CounterpartyScreen extends StatefulWidget {
  const CounterpartyScreen({super.key});
  @override
  State<CounterpartyScreen> createState() => _CounterpartyScreenState();
}

class _CounterpartyScreenState extends State<CounterpartyScreen> {
  late Future<Map<String, dynamic>> _f;
  final _search = TextEditingController();
  int _chip = 0; // 0 Hammasi · 1 Riskli · 2 Yetkazuvchi · 3 Xaridor
  String _q = '';
  String _sub = ''; // sarlavha ostidagi hisob — yuklangach to'ladi

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Ma'lumotni yuklaydi va "N ta · M tasi risk ro'yxatida" hisobini yangilaydi.
  void _load() {
    final f = Api.counterparty();
    _f = f;
    f.then((d) {
      if (!mounted || d['ok'] != true) return;
      final all = ((d['checks'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
      final risky = all.where((c) {
        final cls = _riskClass((c['risk'] ?? '').toString());
        return cls == 0 || cls == 1;
      }).length;
      setState(() => _sub = '${all.length} ${tr('cp.count')} · $risky ${tr('cp.inRiskList')}');
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async => setState(_load);

  // ── Risk klassifikatsiyasi ──
  // 0 = yuqori (red), 1 = e'tibor (amber), 2 = toza (green), 3 = noma'lum
  int _riskClass(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('high') || r.contains('yuqori') || r.contains('critical')) return 0;
    if (r.contains('medium') || r.contains('orta') || r.contains('warn') || r.contains('e\'tibor')) return 1;
    if (r.contains('low') || r.contains('past') || r.contains('toza') || r.contains('clean') || r.contains('ok') || r.contains('safe')) return 2;
    return 3;
  }

  Color _riskOn(FinnTokens t, int cls) => switch (cls) {
        0 => t.onRed,
        1 => t.onAmb,
        2 => t.onGrn,
        _ => t.ink2,
      };

  Color _riskTint(FinnTokens t, int cls) => switch (cls) {
        0 => t.tRed,
        1 => t.tAmb,
        2 => t.tGrn,
        _ => t.key,
      };

  String _riskLabel(int cls, String raw) => switch (cls) {
        0 => tr('cp.risk.high'),
        1 => tr('cp.risk.attention'),
        2 => tr('cp.risk.clean'),
        _ => raw.isEmpty ? tr('cp.risk.unknown') : raw,
      };

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) return parts.first.characters.take(2).toString().toUpperCase();
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('cp.title'),
      subtitle: _sub.isEmpty ? tr('cp.subtitle') : _sub,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _searchField(t),
        const SizedBox(height: 14),
        _chips(t, all.length, riskyCount),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.fact_check_rounded,
              color: t.cyan,
              text: _q.isNotEmpty || _chip > 1
                  ? tr('cp.empty.notFound')
                  : tr('cp.empty.none'),
            ),
          )
        else ...[
          if (attention.isNotEmpty) ...[
            _eyebrow(t, tr('cp.group.attention')),
            for (var i = 0; i < attention.length; i++)
              StaggerIn(index: i, child: _row(t, attention[i])),
          ],
          if (trusted.isNotEmpty) ...[
            _eyebrow(t, tr('cp.group.trusted')),
            for (var i = 0; i < trusted.length; i++)
              StaggerIn(index: attention.length + i, child: _row(t, trusted[i])),
          ],
        ],
      ],
    );
  }

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('cp.err.offline'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('cp.err.retry'))),
          ]),
        ),
      );

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
          child: Icon(ic, size: 17, color: t.ink2),
        ),
      );

  Widget _searchField(FinnTokens t) => TextField(
        controller: _search,
        onChanged: (v) => setState(() => _q = v.trim()),
        style: FinnText.rowTitle(t.ink),
        cursorColor: t.blue,
        decoration: InputDecoration(
          isDense: true,
          hintText: tr('cp.search.hint'),
          hintStyle: FinnText.rowTitle(t.ink3),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: t.ink3),
          suffixIcon: _q.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18, color: t.ink3),
                  onPressed: () => setState(() {
                    _search.clear();
                    _q = '';
                  }),
                )
              : null,
          filled: true,
          fillColor: t.card,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            borderSide: BorderSide(color: t.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            borderSide: BorderSide(color: t.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            borderSide: BorderSide(color: t.blue.withValues(alpha: .5), width: 1.4),
          ),
        ),
      );

  Widget _chips(FinnTokens t, int total, int risky) {
    final items = [
      '${tr('cp.chip.all')} $total',
      '${tr('cp.chip.risky')} $risky',
      tr('cp.chip.supplier'),
      tr('cp.chip.buyer'),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final on = _chip == i;
          return GestureDetector(
            onTap: () => setState(() => _chip = i),
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
              child: Text(
                items[i],
                style: FinnText.chip(on ? Colors.white : t.ink2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );

  Widget _row(FinnTokens t, Map<String, dynamic> c) {
    final name = (c['name'] ?? '—').toString();
    final stir = (c['stir'] ?? '').toString();
    final date = (c['date'] ?? '').toString();
    final cls = _riskClass((c['risk'] ?? '').toString());

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
            color: _riskTint(t, cls),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _initials(name),
            style: FinnText.rowValue(_riskOn(t, cls)),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FinnText.rowTitle(t.ink),
            ),
            const SizedBox(height: 2),
            Text(
              [
                if (stir.isNotEmpty) '${tr('cp.stir')} $stir',
                if (date.isNotEmpty) date,
              ].join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: FinnText.rowSub(t.ink3),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        _pill(t, cls, (c['risk'] ?? '').toString()),
      ]),
    );
  }

  Widget _pill(FinnTokens t, int cls, String raw) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _riskTint(t, cls),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _riskLabel(cls, raw),
          style: FinnText.pill(_riskOn(t, cls)),
        ),
      );
}
