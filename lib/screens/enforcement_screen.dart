import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Ijro hujjatlari" moduli — davlat ijro hujjatlari ro'yxati va ogohlantirish.
class EnforcementScreen extends StatefulWidget {
  const EnforcementScreen({super.key});

  @override
  State<EnforcementScreen> createState() => _EnforcementScreenState();
}

class _EnforcementScreenState extends State<EnforcementScreen> {
  late Future<Map<String, dynamic>> _f = Api.enforcement();

  Future<void> _refresh() async => setState(() => _f = Api.enforcement());

  BoxShadow get _shadow => BoxShadow(
        color: (C.isDark(context) ? Colors.black : const Color(0xFF1B2A4A))
            .withValues(alpha: C.isDark(context) ? .25 : .06),
        blurRadius: 30,
        offset: const Offset(0, 14),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(title: const Text('Ijro hujjatlari')),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: C.blue,
            child: FutureBuilder<Map<String, dynamic>>(
              future: _f,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError || snap.data == null || snap.data!['ok'] != true) {
                  return _error();
                }

                final docs = ((snap.data!['documents'] as List?) ?? const [])
                    .whereType<Map>()
                    .map((e) => e.cast<String, dynamic>())
                    .toList();

                if (docs.isEmpty) return _empty();

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _warningBanner(),
                    const SizedBox(height: 16),
                    for (var i = 0; i < docs.length; i++)
                      StaggerIn(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _docCard(docs[i]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

  // ── Ogohlantirish banneri ──
  Widget _warningBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.red.withValues(alpha: C.isDark(context) ? .16 : .10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: C.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ijro hujjatlari mavjud — e\'tibor bering',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: C.isDark(context) ? C.red : const Color(0xFFB91C1C),
              ),
            ),
          ),
        ]),
      );

  // ── Hujjat kartasi ──
  Widget _docCard(Map<String, dynamic> d) {
    final number = (d['number'] ?? '—').toString();
    final date = (d['date'] ?? '').toString();
    final status = (d['status'] ?? '').toString();
    final amount = (d['amount'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_shadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: C.red.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.gavel_rounded, color: C.red, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: C.text(context),
                  ),
                ),
                if (date.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.event, size: 12, color: C.muted(context, .38)),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: TextStyle(fontSize: 11.5, color: C.muted(context, .5)),
                    ),
                  ]),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '${money(amount)} so\'m',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: C.red,
                        ),
                      ),
                    ),
                    if (status.isNotEmpty) _statusChip(status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: C.red.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: C.red,
          ),
        ),
      );

  // ── Xato holati ──
  Widget _error() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .28),
          Icon(Icons.cloud_off_rounded, size: 54, color: C.muted(context, .35)),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Server bilan aloqa yo\'q',
              style: TextStyle(fontSize: 14, color: C.muted(context, .6)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Qayta urinish'),
            ),
          ),
        ],
      );

  // ── Bo'sh (ijobiy) holat ──
  Widget _empty() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .28),
          const Icon(Icons.verified_rounded, size: 58, color: C.green),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Ijro hujjatlari yo\'q — hammasi joyida',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: C.muted(context, .6)),
            ),
          ),
        ],
      );
}
