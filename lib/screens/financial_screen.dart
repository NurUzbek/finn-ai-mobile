import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

const _accent = LinearGradient(colors: [Color(0xFF246BFD), Color(0xFF00C6FF)]);

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.financial();
  }

  Future<void> _reload() async {
    setState(() => _future = Api.financial());
    await _future;
  }

  BoxShadow _softShadow(BuildContext c) => BoxShadow(
        color: (C.isDark(c) ? Colors.black : const Color(0xFF1B2A4A))
            .withValues(alpha: C.isDark(c) ? .25 : .06),
        blurRadius: 30,
        offset: const Offset(0, 14),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        title: const Text('Moliya',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        backgroundColor: C.bg(context),
        foregroundColor: C.text(context),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data;
          final ok = data != null && data['ok'] == true && !snap.hasError;
          if (!ok) return _error();

          final summary = (data['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
          final income = (summary['income'] as num?)?.toDouble() ?? 0;
          final expense = (summary['expense'] as num?)?.toDouble() ?? 0;
          final net = (summary['net'] as num?)?.toDouble() ?? (income - expense);

          final ops = (data['operations'] as List?)
                  ?.whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList() ??
              const <Map<String, dynamic>>[];

          return RefreshIndicator(
            color: C.cyan,
            backgroundColor: C.card(ctx),
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                StaggerIn(index: 0, child: _hero(net, income, expense)),
                const SizedBox(height: 20),
                if (ops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.receipt_long_rounded,
                      color: C.cyan,
                      text: 'Hali operatsiya yo\'q',
                    ),
                  )
                else
                  for (int i = 0; i < ops.length; i++) ...[
                    StaggerIn(index: i + 1, child: _opCard(ops[i])),
                    if (i != ops.length - 1) const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(double net, double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _accent,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF246BFD).withValues(alpha: .32),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Sof balans',
            style: TextStyle(
                color: Colors.white.withValues(alpha: .8),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '${money(net)} so\'m',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
        ),
        const SizedBox(height: 18),
        Row(children: [
          _heroChip(Icons.arrow_upward_rounded, 'Kirim', income),
          const SizedBox(width: 10),
          _heroChip(Icons.arrow_downward_rounded, 'Chiqim', expense),
        ]),
      ]),
    );
  }

  Widget _heroChip(IconData icon, String label, double value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(money(value),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _opCard(Map<String, dynamic> op) {
    final isIncome = (op['type']?.toString() ?? 'expense') == 'income';
    final color = isIncome ? C.green : C.red;
    final amount = (op['amount'] as num?)?.toDouble() ?? 0;
    final category = op['category']?.toString() ?? '';
    final description = op['description']?.toString() ?? '';
    final date = op['date']?.toString() ?? '';
    final title = category.isNotEmpty ? category : (description.isNotEmpty ? description : 'Operatsiya');
    final sub = category.isNotEmpty && description.isNotEmpty ? description : date;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_softShadow(context)],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: C.text(context))),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: C.muted(context, .5))),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        Text(
          '${isIncome ? '+' : '-'}${money(amount)}',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: color),
        ),
      ]),
    );
  }

  Widget _error() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: C.red.withValues(alpha: .1), shape: BoxShape.circle),
            child: const Icon(Icons.cloud_off_rounded, size: 32, color: C.red),
          ),
          const SizedBox(height: 16),
          Text('Server bilan aloqa yo\'q',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted(context, .6), fontSize: 13.5)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: C.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _reload,
            child: const Text('Qayta urinish'),
          ),
        ]),
      ),
    );
  }
}
