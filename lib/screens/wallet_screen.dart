import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Hamyon — umumiy balans va tranzaksiyalar tarixi.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _future;

  static const _grad = LinearGradient(
    colors: [Color(0xFF246BFD), Color(0xFF00C6FF)],
  );

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

  List<BoxShadow> _shadow(BuildContext c) => [
        BoxShadow(
          color: (C.isDark(c) ? Colors.black : const Color(0xFF1B2A4A))
              .withValues(alpha: C.isDark(c) ? .25 : .06),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ];

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        backgroundColor: C.bg(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Hamyon',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: C.text(context),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data;
          final ok = data != null && data['ok'] == true;
          if (!ok) return _errorState();

          final balance = _toDouble(data['balance']);
          final rawTx = data['transactions'];
          final txs = (rawTx is List) ? rawTx : const [];

          return RefreshIndicator(
            color: C.cyan,
            backgroundColor: C.card(context),
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: txs.isEmpty ? 2 : txs.length + 1,
              separatorBuilder: (_, i) =>
                  SizedBox(height: i == 0 ? 20 : 12),
              itemBuilder: (c, i) {
                if (i == 0) return _balanceCard(balance);
                if (txs.isEmpty) return _emptyTx();
                final tx = _asMap(txs[i - 1]);
                return StaggerIn(index: i, child: _txCard(tx));
              },
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // ── Balans kartasi (gradient + count-up) ──
  Widget _balanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _grad,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF246BFD).withValues(alpha: .32),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Umumiy balans',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: .9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    TextSpan(
                      text: '  so\'m',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: .85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bo'sh holat (tranzaksiyalar yo'q) ──
  Widget _emptyTx() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: C.green.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 32, color: C.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Tranzaksiya yo\'q',
            textAlign: TextAlign.center,
            style: TextStyle(color: C.muted(context, .5), fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  // ── Tranzaksiya kartasi ──
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              incoming
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: C.text(context),
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: C.muted(context, .5),
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
                  fontSize: 15,
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

  // ── Xato holati ──
  Widget _errorState() {
    return LayoutBuilder(
      builder: (c, box) => RefreshIndicator(
        color: C.cyan,
        backgroundColor: C.card(context),
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: box.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: C.red.withValues(alpha: .1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_off,
                          size: 32, color: C.red),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Server bilan aloqa yo\'q',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: C.muted(context, .55),
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Qayta urinish'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: C.cyan,
                        side: BorderSide(color: C.cyan.withValues(alpha: .4)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
