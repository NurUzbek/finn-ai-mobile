import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Hamyon — umumiy balans va tranzaksiyalar tarixi.
/// Dizayn: finn-app-full.html `#v-hamyon`.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.wallet();
  }

  Future<void> _refresh() async {
    final f = Api.wallet();
    setState(() => _future = f);
    await f;
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(
              title: 'Hamyon',
              subtitle: 'Hisob raqamlar va balans',
              icon: Icons.account_balance_wallet_rounded,
            ),
            Expanded(
              child: Loader(
                future: _future,
                onRefresh: _refresh,
                builder: (data) {
                  final balance = _toDouble(data['balance']);
                  final rawTx = data['transactions'];
                  final txs = (rawTx is List) ? rawTx : const [];

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    children: [
                      _balanceCard(balance, txs.length),
                      _eyebrow('Tranzaksiyalar'),
                      if (txs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: EmptyState(
                            icon: Icons.receipt_long_rounded,
                            text: 'Tranzaksiya yo\'q',
                            color: C.green,
                          ),
                        )
                      else
                        for (int i = 0; i < txs.length; i++)
                          StaggerIn(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _txCard(_asMap(txs[i])),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Eyebrow (bo'lim sarlavhasi + chiziq) ──
  Widget _eyebrow(String text, {String? action, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
          if (action != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onTap,
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: C.brand,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Balans kartasi (gradient + count-up) ──
  Widget _balanceCard(double balance, int txCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: C.grad,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: C.brand.withValues(alpha: C.isDark(context) ? .34 : .26),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JAMI MABLAG\'',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.4,
                        color: Colors.white.withValues(alpha: .66),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: balance),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (c, v, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: money(v),
                                style: const TextStyle(
                                  fontSize: 33,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.4,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                              TextSpan(
                                text: '  so\'m',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 26),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            txCount == 0
                ? 'Tranzaksiyalar tarixi'
                : '$txCount ta tranzaksiya',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tranzaksiya kartasi (.row uslubida) ──
  Widget _txCard(Map<String, dynamic> tx) {
    final amount = _toDouble(tx['amount']);
    final balanceAfter = _toDouble(tx['balance_after']);
    final type = '${tx['type'] ?? ''}'.toLowerCase();
    final desc = '${tx['description'] ?? 'Tranzaksiya'}';
    final date = '${tx['date'] ?? ''}';

    final incoming = amount > 0 ||
        type.contains('in') ||
        type.contains('deposit') ||
        type.contains('credit') ||
        type.contains('kirim');
    final color = incoming ? C.green : C.red;
    final sign = incoming ? '+' : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: C.tint(context, color),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: C.text(context),
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: C.muted(context, .45),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${money(amount.abs())}',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                money(balanceAfter),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: C.muted(context, .45),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
