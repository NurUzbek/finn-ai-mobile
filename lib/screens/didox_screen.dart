import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "E-hujjatlar (Didox)" moduli — elektron hisob-fakturalar ro'yxati.
/// Didox integratsiyasi orqali imzolangan/kutilayotgan hujjatlar holati.
class DidoxScreen extends StatefulWidget {
  const DidoxScreen({super.key});
  @override
  State<DidoxScreen> createState() => _DidoxScreenState();
}

class _DidoxScreenState extends State<DidoxScreen> {
  late Future<Map<String, dynamic>> _f = Api.didox();
  Future<void> _refresh() async => setState(() => _f = Api.didox());

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(title: const Text('E-hujjatlar (Didox)')),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }

              final d = snap.data ?? const {'ok': false};
              if (d['ok'] != true) {
                return _errorState();
              }

              final docs = ((d['documents'] as List?) ?? const [])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();

              return RefreshIndicator(
                color: C.cyan,
                backgroundColor: C.card(context),
                onRefresh: _refresh,
                child: docs.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          EmptyState(
                            icon: Icons.description_outlined,
                            color: C.violet,
                            text: 'E-hujjat yo\'q — Didox ulanmagan boʻlishi mumkin',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: docs.length,
                        itemBuilder: (c, i) => StaggerIn(
                          index: i,
                          child: _DocCard(doc: docs[i]),
                        ),
                      ),
              );
            },
          ),
        ),
      );

  Widget _errorState() => RefreshIndicator(
        color: C.cyan,
        backgroundColor: C.card(context),
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: C.red.withValues(alpha: .1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_off_rounded, size: 32, color: C.red),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Server bilan aloqa yo\'q',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: C.muted(context, .55), fontSize: 13.5),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Qayta urinish'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.cyan,
                      side: BorderSide(color: C.cyan.withValues(alpha: .4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
}

class _DocCard extends StatelessWidget {
  final Map<String, dynamic> doc;
  const _DocCard({required this.doc});

  ({Color color, String label}) _status(String raw, BuildContext context) {
    switch (raw.toLowerCase()) {
      case 'signed':
        return (color: C.green, label: 'Imzolangan');
      case 'accepted':
        return (color: C.green, label: 'Qabul qilindi');
      case 'pending':
        return (color: C.amber, label: 'Kutilmoqda');
      case 'rejected':
        return (color: C.red, label: 'Rad etildi');
      default:
        return (color: C.muted(context, .5), label: raw.isEmpty ? '—' : raw);
    }
  }

  @override
  Widget build(BuildContext context) {
    final number = (doc['number'] ?? '—').toString();
    final type = (doc['type'] ?? '').toString();
    final date = (doc['date'] ?? '').toString();
    final st = _status((doc['status'] ?? '').toString(), context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (C.isDark(context) ? Colors.black : const Color(0xFF1B2A4A))
                .withValues(alpha: C.isDark(context) ? .25 : .06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: C.violet.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.description_rounded, color: C.violet, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: C.text(context),
              ),
            ),
            if (type.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                type,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: C.muted(context, .5)),
              ),
            ],
            if (date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.event_rounded, size: 12, color: C.muted(context, .35)),
                const SizedBox(width: 5),
                Text(date, style: TextStyle(fontSize: 11.5, color: C.muted(context, .42))),
              ]),
            ],
          ]),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: st.color.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            st.label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: st.color),
          ),
        ),
      ]),
    );
  }
}
