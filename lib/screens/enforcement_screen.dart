import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// "Ijro hujjatlari" moduli — davlat ijro hujjatlari ro'yxati va ogohlantirish.
/// FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText). PUSH ekran.
class EnforcementScreen extends StatefulWidget {
  const EnforcementScreen({super.key});

  @override
  State<EnforcementScreen> createState() => _EnforcementScreenState();
}

class _EnforcementScreenState extends State<EnforcementScreen> {
  late Future<Map<String, dynamic>> _f = Api.enforcement();

  Future<void> _refresh() async => setState(() => _f = Api.enforcement());

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      govSources: true,
      title: tr('enf.title'),
      subtitle: tr('enf.subtitle'),
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
            if (snap.hasError || snap.data == null || snap.data!['ok'] != true) {
              return _err(t);
            }

            final docs = ((snap.data!['documents'] as List?) ?? const [])
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList();

            if (docs.isEmpty) return _empty(t);

            return _content(t, docs);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, List<Map<String, dynamic>> docs) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          StaggerIn(index: 0, child: _warningBanner(t)),
          const SizedBox(height: 16),
          for (var i = 0; i < docs.length; i++)
            StaggerIn(
              index: i + 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _docCard(t, docs[i]),
              ),
            ),
        ],
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

  // ── Ogohlantirish banneri ──
  Widget _warningBanner(FinnTokens t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.tRed,
          borderRadius: BorderRadius.circular(FinnTokens.rMd),
        ),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, color: t.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('enf.warning'),
              style: FinnText.rowTitle(t.onRed),
            ),
          ),
        ]),
      );

  // ── Hujjat kartasi ──
  Widget _docCard(FinnTokens t, Map<String, dynamic> d) {
    final number = (d['number'] ?? '—').toString();
    final date = (d['date'] ?? '').toString();
    final status = (d['status'] ?? '').toString();
    final amount = (d['amount'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.tRed,
              borderRadius: BorderRadius.circular(FinnTokens.rMd),
            ),
            child: Icon(Icons.gavel_rounded, color: t.onRed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(number,
                    style: FinnText.rowValue(t.ink).copyWith(fontSize: 15)),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.event, size: 12, color: t.ink3),
                    const SizedBox(width: 5),
                    Text(date, style: FinnText.rowSub(t.ink3)),
                  ]),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        "${money(amount)} ${tr('common.som')}",
                        style: FinnText.rowValue(t.red).copyWith(fontSize: 18),
                      ),
                    ),
                    if (status.isNotEmpty) _statusChip(t, status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(FinnTokens t, String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: t.tRed,
          borderRadius: BorderRadius.circular(FinnTokens.rLg),
        ),
        child: Text(trStatus(status), style: FinnText.pill(t.onRed)),
      );

  // ── Xato holati ──
  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('enf.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _refresh, child: Text(tr('common.retry'))),
          ]),
        ),
      );

  // ── Bo'sh (ijobiy) holat ──
  Widget _empty(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 120),
        child: Center(
          child: Column(children: [
            Icon(Icons.verified_rounded, size: 48, color: t.green),
            const SizedBox(height: 16),
            Text(
              tr('enf.empty'),
              textAlign: TextAlign.center,
              style: FinnText.body(t.ink3),
            ),
          ]),
        ),
      );
}
