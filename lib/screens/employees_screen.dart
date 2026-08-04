import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Xodimlar moduli — jamoa a'zolari ro'yxati (avatar, lavozim, oylik, holat).
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  late Future<Map<String, dynamic>> _f = Api.employees();
  Future<void> _refresh() async => setState(() => _f = Api.employees());

  /// Ismning bosh harflari (maks. 2 ta), bo'sh bo'lsa '—'.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts[0].characters.first + parts[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(
          title: const Text('Xodimlar', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.4)),
        ),
        body: SafeArea(
          top: false,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: C.cyan));
              }
              final d = snap.data;
              if (snap.hasError || d == null || d['ok'] != true) {
                return _ErrorState(onRetry: _refresh);
              }

              final raw = (d['employees'] as List?) ?? const [];
              final employees = raw
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();

              return RefreshIndicator(
                color: C.cyan,
                backgroundColor: C.card(ctx),
                onRefresh: _refresh,
                child: employees.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          EmptyState(icon: Icons.people_outline_rounded, text: 'Xodim yo\'q'),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: employees.length + 1,
                        itemBuilder: (c, i) {
                          if (i == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
                              child: Text(
                                '${employees.length} xodim',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: C.muted(c, .5),
                                ),
                              ),
                            );
                          }
                          final e = employees[i - 1];
                          return StaggerIn(
                            index: i - 1,
                            child: _EmployeeCard(
                              name: (e['name'] ?? '').toString(),
                              position: (e['position'] ?? '').toString(),
                              salary: (e['salary'] as num?)?.toDouble() ?? 0,
                              status: (e['status'] ?? '').toString(),
                              initials: _initials((e['name'] ?? '').toString()),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      );
}

class _EmployeeCard extends StatelessWidget {
  final String name, position, status, initials;
  final double salary;
  const _EmployeeCard({
    required this.name,
    required this.position,
    required this.salary,
    required this.status,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final active = status.toLowerCase() == 'active' || status.toLowerCase() == 'faol';
    final dotColor = active ? C.green : C.muted(context, .3);

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
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF246BFD), Color(0xFF00C6FF)]),
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(
                  name.isEmpty ? '—' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text(context)),
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 9, height: 9, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            ]),
            if (position.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                position,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: C.muted(context, .5)),
              ),
            ],
            if (salary > 0) ...[
              const SizedBox(height: 8),
              Text(
                '${money(salary)} so\'m',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.green),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: C.red.withValues(alpha: .1), shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 32, color: C.red),
            ),
            const SizedBox(height: 16),
            Text('Server bilan aloqa yo\'q',
                textAlign: TextAlign.center,
                style: TextStyle(color: C.muted(context, .55), fontSize: 13.5)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Qayta urinish'),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.cyan,
                side: BorderSide(color: C.cyan.withValues(alpha: .4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      );
}
