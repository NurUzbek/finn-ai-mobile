import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Hisobotlar ekrani — foydalanuvchining topshirilgan/jarayondagi hisobotlari.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.reports();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.reports());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        title: const Text('Hisobotlar',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: C.cyan));
          }

          final data = snap.data;
          final ok = data != null && data['ok'] == true;

          if (!ok) {
            return _ErrorState(onRetry: _refresh);
          }

          final raw = data['reports'];
          final reports = <Map<String, dynamic>>[
            if (raw is List)
              for (final e in raw)
                if (e is Map) e.map((k, v) => MapEntry(k.toString(), v)),
          ];

          return RefreshIndicator(
            color: C.cyan,
            backgroundColor: C.card(context),
            onRefresh: _refresh,
            child: reports.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      EmptyState(
                        icon: Icons.insert_chart_outlined_rounded,
                        color: C.blue,
                        text: 'Hisobot yo\'q',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => StaggerIn(
                      index: i,
                      child: _ReportCard(report: reports[i]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ReportCard({required this.report});

  String _s(dynamic v) => v == null ? '' : v.toString();

  @override
  Widget build(BuildContext context) {
    final title = _s(report['title']);
    final type = _s(report['type']);
    final date = _s(report['date']);
    final status = _s(report['status']);

    final dark = C.isDark(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (dark ? Colors.black : const Color(0xFF1B2A4A))
                .withValues(alpha: dark ? .25 : .06),
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
              color: C.blue.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_rounded, size: 22, color: C.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Hisobot' : title,
                  maxLines: 2,
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
                    style: TextStyle(fontSize: 12.5, color: C.muted(context, .5)),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (date.isNotEmpty) ...[
                      Icon(Icons.calendar_today_rounded,
                          size: 12, color: C.muted(context, .45)),
                      const SizedBox(width: 5),
                      Text(
                        date,
                        style:
                            TextStyle(fontSize: 12, color: C.muted(context, .5)),
                      ),
                    ],
                    const Spacer(),
                    if (status.isNotEmpty) _StatusChip(status: status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    Color color;
    if (s == 'topshirilgan' || s == 'submitted' || s == 'done') {
      color = C.green;
    } else if (s == 'pending' || s == 'jarayonda') {
      color = C.amber;
    } else if (s == 'rad' || s == 'overdue') {
      color = C.red;
    } else {
      color = C.muted(context, .5);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              child: const Icon(Icons.cloud_off_rounded, size: 32, color: C.red),
            ),
            const SizedBox(height: 16),
            Text(
              'Server bilan aloqa yo\'q',
              textAlign: TextAlign.center,
              style: TextStyle(color: C.muted(context, .55), fontSize: 13.5),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Qayta urinish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.blue,
                side: BorderSide(color: C.blue.withValues(alpha: .4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
