import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Kontragentlarni tekshirish moduli — STIR bo'yicha risk tekshiruvlari ro'yxati.
class CounterpartyScreen extends StatefulWidget {
  const CounterpartyScreen({super.key});
  @override
  State<CounterpartyScreen> createState() => _CounterpartyScreenState();
}

class _CounterpartyScreenState extends State<CounterpartyScreen> {
  late Future<Map<String, dynamic>> _f = Api.counterparty();

  Future<void> _refresh() async => setState(() => _f = Api.counterparty());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(
          title: const Text('Kontragentlar'),
          backgroundColor: C.bg(context),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: RefreshIndicator(
          color: C.cyan,
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }
              if (snap.hasError || snap.data == null || snap.data!['ok'] != true) {
                return _errorState(context);
              }
              final checks = ((snap.data!['checks'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
              if (checks.isEmpty) return _emptyState(context);
              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: checks.length,
                itemBuilder: (context, i) => StaggerIn(
                  index: i,
                  child: _card(context, checks[i]),
                ),
              );
            },
          ),
        ),
      );

  Widget _card(BuildContext ctx, Map<String, dynamic> c) {
    final name = (c['name'] ?? '—').toString();
    final stir = (c['stir'] ?? '—').toString();
    final date = (c['date'] ?? '').toString();
    final risk = (c['risk'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(ctx),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (C.isDark(ctx) ? Colors.black : const Color(0xFF1B2A4A))
                .withValues(alpha: C.isDark(ctx) ? .25 : .06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [C.blue, C.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business_center_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: C.text(ctx)),
                ),
                const SizedBox(height: 4),
                Text(
                  'STIR: $stir',
                  style: TextStyle(fontSize: 12, color: C.muted(ctx, .5)),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.event_outlined, size: 13, color: C.muted(ctx, .4)),
                    const SizedBox(width: 5),
                    Text(date, style: TextStyle(fontSize: 11.5, color: C.muted(ctx, .42))),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _riskChip(ctx, risk),
        ],
      ),
    );
  }

  Widget _riskChip(BuildContext ctx, String risk) {
    final r = risk.toLowerCase();
    Color col;
    String label;
    if (r.contains('low') || r.contains('past') || r.contains('ok')) {
      col = C.green;
      label = 'Past';
    } else if (r.contains('medium') || r.contains('orta')) {
      col = C.amber;
      label = 'O\'rta';
    } else if (r.contains('high') || r.contains('yuqori')) {
      col = C.red;
      label = 'Yuqori';
    } else {
      col = C.muted(ctx, .5);
      label = risk.isEmpty ? '—' : risk;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: col),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext ctx) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(ctx).size.height * .28),
          Icon(Icons.cloud_off, size: 54, color: C.muted(ctx, .4)),
          const SizedBox(height: 16),
          Center(
            child: Text('Server bilan aloqa yo\'q',
                style: TextStyle(fontSize: 14, color: C.muted(ctx, .6))),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Qayta urinish'),
              style: TextButton.styleFrom(foregroundColor: C.blue),
            ),
          ),
        ],
      );

  Widget _emptyState(BuildContext ctx) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(ctx).size.height * .3),
          Icon(Icons.fact_check_outlined, size: 54, color: C.muted(ctx, .4)),
          const SizedBox(height: 16),
          Center(
            child: Text('Tekshiruv yo\'q',
                style: TextStyle(fontSize: 14, color: C.muted(ctx, .6))),
          ),
        ],
      );
}
