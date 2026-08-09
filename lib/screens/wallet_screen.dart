import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Hamyon — balans, hisob raqamlar va kutilayotgan to'lovlar (PUSH ekran).
///
/// HTML manba: DART/proto.html `id="v-hamyon"` (1:1 moslangan).
/// FINN dizayn tizimi: FinnScreen + tokens + FinnText.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _f = Api.wallet();
  Future<void> _refresh() async => setState(() => _f = Api.wallet());

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  // Prototip (v-hamyon) demo hisob raqamlari — redizayndagi yangi bo'lim.
  static final List<_Acct> _accounts = [
    _Acct('IB', 'wal.bankIpoteka', '2020 8000 1234 5678 9001',
        (t) => t.tBlu, (t) => t.blue, 52100000),
    _Acct('KB', 'wal.bankKapital', '2020 8000 9876 5432 1002',
        (t) => t.tGrn, (t) => t.onGrn, 24320000),
    _Acct('\$', 'wal.acctUsd', '2020 8400 5566 7788 0003',
        (t) => t.tPur, (t) => t.onPur, 10000000,
        amount: '\$ 812', amountSub: '≈ 10 000 000'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('wal.title'),
      subtitle: tr('wal.subtitle'),
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop()),
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
    // Balans — API'dan (mavjud bo'lsa), aks holda hisoblar yig'indisi.
    final sum = _accounts.fold<double>(0, (s, a) => s + a.som);
    final apiBalance = _toDouble(d['balance']);
    final total = apiBalance > 0 ? apiBalance : sum;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StaggerIn(index: 0, child: _balanceCard(t, total)),

        _eyebrow(t, tr('wal.accounts'), action: tr('wal.add')),
        for (int i = 0; i < _accounts.length; i++)
          StaggerIn(
            index: 1 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: FinnTokens.gapList),
              child: _acctRow(t, _accounts[i]),
            ),
          ),

        _eyebrow(t, tr('wal.pending')),
        StaggerIn(
          index: 1 + _accounts.length,
          child: _pendingCard(t),
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
            Text(tr('wal.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('wal.retry'))),
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

  // ─────────────────────── BALANS ───────────────────────
  Widget _balanceCard(FinnTokens t, double total) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: FinnTokens.brand,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          boxShadow: [
            BoxShadow(
                color: t.blue2.withValues(alpha: .28),
                blurRadius: 30,
                offset: const Offset(0, 14)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tr('wal.totalFunds'),
                              style: FinnText.eyebrow(
                                  Colors.white.withValues(alpha: .66))),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: total),
                            duration: const Duration(milliseconds: 1000),
                            curve: FinnTokens.ease,
                            builder: (_, v, __) => FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(money(v),
                                  style: FinnText.heroValue(Colors.white)),
                            ),
                          ),
                        ]),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white, size: 26),
                ]),
                const SizedBox(height: 12),
                Text(
                  '${_accounts.length} ${tr('wal.acctsWord')} · 5 ${tr('wal.orgsWord')}',
                  style: FinnText.rowSub(Colors.white.withValues(alpha: .7)),
                ),
              ]),
        ),
      );

  // ─────────────────────── HISOB RAQAM ───────────────────────
  Widget _acctRow(FinnTokens t, _Acct a) => Container(
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
              color: a.tint(t),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(a.mono, style: FinnText.rowValue(a.on(t))),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr(a.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FinnText.rowTitle(t.ink)),
                  const SizedBox(height: 2),
                  Text(a.number, style: FinnText.rowSub(t.ink3)),
                ]),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(a.amount ?? money(a.som), style: FinnText.rowValue(t.ink)),
            if (a.amountSub != null) ...[
              const SizedBox(height: 2),
              Text(a.amountSub!, style: FinnText.rowSub(t.ink3)),
            ],
          ]),
        ]),
      );

  // ─────────────────── KUTILAYOTGAN TO'LOV ───────────────────
  Widget _pendingCard(FinnTokens t) => Container(
        padding: const EdgeInsets.all(FinnTokens.cardPad),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: t.line),
          boxShadow: t.sh,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: t.red, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(tr('wal.taxPayments'),
                      style: FinnText.button(t.ink)),
                ),
                const SizedBox(width: 10),
                Text(money(20000000), style: FinnText.rowValue(t.red)),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 6,
                  color: t.key,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: .43),
                    duration: const Duration(milliseconds: 900),
                    curve: FinnTokens.spring,
                    builder: (_, v, __) => FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: v.clamp(0, 1),
                      child: DecoratedBox(
                          decoration: BoxDecoration(color: t.red)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(tr('wal.coversText'),
                  style: FinnText.rowSub(t.ink3)),
            ]),
      );

  // ─────────────────────── EYEBROW ───────────────────────
  Widget _eyebrow(FinnTokens t, String label,
          {String? action, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
          if (action != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Text(action, style: FinnText.pill(t.blue)),
            ),
          ],
        ]),
      );
}

/// Hisob raqam ma'lumoti (prototip demo).
class _Acct {
  const _Acct(this.mono, this.name, this.number, this.tint, this.on, this.som,
      {this.amount, this.amountSub});

  final String mono, name, number;
  final Color Function(FinnTokens) tint, on;
  final double som;

  /// Ochiq ko'rsatiladigan summa (null bo'lsa `money(som)`).
  final String? amount;
  final String? amountSub;
}
