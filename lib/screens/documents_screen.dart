import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// "Hujjatlar" moduli — shartnomalar va fakturalar (veb parity).
/// Ikki tab: Shartnomalar / Fakturalar. Har biri alohida holat (bo'sh/xato) bilan.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<Map<String, dynamic>> _f = Api.documents();
  Future<void> _refresh() async => setState(() => _f = Api.documents());

  /// Holatga qarab chip rangi.
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'signed':
      case 'paid':
      case 'active':
        return C.green;
      case 'pending':
        return C.amber;
      case 'rejected':
      case 'cancelled':
        return C.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(
          backgroundColor: C.bg(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Hujjatlar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: C.text(context),
            ),
          ),
          bottom: TabBar(
            labelColor: C.blue,
            unselectedLabelColor: C.muted(context, .5),
            indicatorColor: C.blue,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
            unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Shartnomalar'),
              Tab(text: 'Fakturalar'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: C.cyan));
            }
            final d = snap.data ?? const {'ok': false};
            if (d['ok'] != true) {
              return _ErrorView(onRetry: _refresh);
            }
            final contracts = (d['contracts'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
            final invoices = (d['invoices'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
            return TabBarView(
              children: [
                _DocList(items: contracts, statusColor: _statusColor, onRefresh: _refresh),
                _DocList(items: invoices, statusColor: _statusColor, onRefresh: _refresh),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bitta tab ro'yxati (RefreshIndicator + bo'sh holat).
class _DocList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Color Function(String) statusColor;
  final Future<void> Function() onRefresh;
  const _DocList({required this.items, required this.statusColor, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: C.cyan,
      backgroundColor: C.card(context),
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                EmptyState(icon: Icons.description_outlined, text: 'Hujjat yo\'q'),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final it = items[i];
                return StaggerIn(
                  index: i,
                  child: _DocCard(item: it, statusColor: statusColor),
                );
              },
            ),
    );
  }
}

/// Hujjat kartasi.
class _DocCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color Function(String) statusColor;
  const _DocCard({required this.item, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final number = (item['number'] ?? '—').toString();
    final party = (item['party'] ?? '').toString();
    final date = (item['date'] ?? '').toString();
    final status = (item['status'] ?? '').toString();
    final amount = (item['amount'] as num?)?.toDouble() ?? 0;
    final chipColor = statusColor(status);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: C.blue.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.insert_drive_file_rounded, size: 22, color: C.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: C.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      party.isEmpty ? '—' : party,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: C.muted(context, .5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusChip(status: status, color: chipColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.event, size: 13, color: C.muted(context, .38)),
              const SizedBox(width: 5),
              Text(
                date.isEmpty ? '—' : date,
                style: TextStyle(fontSize: 12, color: C.muted(context, .45)),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${money(amount)} so\'m',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: C.text(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Holat chipi.
class _StatusChip extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusChip({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty ? '—' : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

/// Server bilan aloqa yo'q — qayta urinish.
class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

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
              style: TextStyle(color: C.muted(context, .5), fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.blue,
                side: BorderSide(color: C.blue.withValues(alpha: .4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              label: const Text('Qayta urinish', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
