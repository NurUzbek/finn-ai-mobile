import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Audit hisoboti" — tashkilotlar bo'yicha audit ballari.
class AuditReportScreen extends StatefulWidget {
  const AuditReportScreen({super.key});
  @override
  State<AuditReportScreen> createState() => _AuditReportScreenState();
}

class _AuditReportScreenState extends State<AuditReportScreen> {
  late Future<Map<String, dynamic>> _f = Api.auditReport();

  Future<void> _refresh() async => setState(() => _f = Api.auditReport());

  /// Ballni xavfsiz num? ga aylantirish (int/double/null).
  num? _score(dynamic v) => v is num ? v : null;

  Color _color(num? s) {
    if (s == null) return C.muted(context, .5);
    if (s >= 70) return C.green;
    if (s >= 40) return C.amber;
    return C.red;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(
          title: const Text('Audit hisoboti'),
          backgroundColor: C.bg(context),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: C.cyan,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }
              if (snap.hasError || snap.data == null || snap.data!['ok'] != true) {
                return _error();
              }
              final items = (snap.data!['items'] as List? ?? const [])
                  .cast<Map<String, dynamic>>();
              if (items.isEmpty) return _empty();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final it = items[i];
                  final score = _score(it['score']);
                  return StaggerIn(index: i, child: _card(it, score));
                },
              );
            },
          ),
        ),
      );

  Widget _card(Map<String, dynamic> it, num? score) {
    final color = _color(score);
    final org = (it['org'] ?? '').toString();
    final stir = (it['stir'] ?? '').toString();
    final label = score == null ? '—' : score.round().toString();
    final frac = score == null ? 0.0 : (score / 100).clamp(0.0, 1.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: (C.isDark(context) ? Colors.black : const Color(0xFF1B2A4A))
                .withValues(alpha: C.isDark(context) ? .25 : .06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  org,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                    color: C.text(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'STIR: $stir',
                  style: TextStyle(fontSize: 12.5, color: C.muted(context, .5)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: .14),
                  border: Border.all(color: color.withValues(alpha: .5), width: 2),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 56,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: frac,
                    minHeight: 5,
                    backgroundColor: C.fill(context, .08),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _error() => ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .28),
          Icon(Icons.cloud_off, size: 56, color: C.muted(context, .35)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Server bilan aloqa yo\'q',
              style: TextStyle(fontSize: 14.5, color: C.muted(context, .6)),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.tonal(
              onPressed: _refresh,
              child: const Text('Qayta urinish'),
            ),
          ),
        ],
      );

  Widget _empty() => ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * .3),
          Icon(Icons.inbox_outlined, size: 56, color: C.muted(context, .3)),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Ma\'lumot yo\'q',
              style: TextStyle(fontSize: 14.5, color: C.muted(context, .5)),
            ),
          ),
        ],
      );
}
