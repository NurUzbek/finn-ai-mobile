import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.team();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.team());
    await _future;
  }

  // Ismdan initsiallar (bo'sh nomdan himoyalangan)
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Telefonni '+998 XX XXX XX XX' ko'rinishida formatlash (aks holda xom holida)
  String _phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('998')) {
      final d = digits;
      return '+998 ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10, 12)}';
    }
    if (digits.length == 9) {
      return '+998 ${digits.substring(0, 2)} ${digits.substring(2, 5)} ${digits.substring(5, 7)} ${digits.substring(7, 9)}';
    }
    return raw;
  }

  // Rol chipi rangi
  Color _roleColor(String role) {
    final r = role.toLowerCase();
    if (r == 'owner' || r == 'admin') return C.violet;
    if (r == 'accountant' || r == 'buxgalter') return C.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        title: const Text('Jamoa va rollar'),
      ),
      body: RefreshIndicator(
        color: C.cyan,
        backgroundColor: C.card(context),
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: C.cyan));
            }

            final data = snap.data;
            if (snap.hasError || data == null || data['ok'] != true) {
              return _ErrorView(onRetry: _refresh);
            }

            final rawList = data['members'];
            final members = (rawList is List) ? rawList : const [];

            if (members.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.groups_rounded,
                    text: 'Jamoa a\'zolari yo\'q',
                    color: C.blue,
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final raw = members[i];
                final m = (raw is Map) ? raw : const {};
                final name = (m['name']?.toString() ?? '').trim();
                final displayName = name.isEmpty ? 'Noma\'lum' : name;
                final phone = m['phone']?.toString() ?? '';
                final role = m['role']?.toString() ?? 'member';
                final org = m['org']?.toString() ?? '';

                return StaggerIn(
                  index: i,
                  child: _MemberCard(
                    initials: _initials(name),
                    name: displayName,
                    phone: _phone(phone),
                    org: org,
                    role: role,
                    roleColor: _roleColor(role),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String initials, name, phone, org, role;
  final Color roleColor;
  const _MemberCard({
    required this.initials,
    required this.name,
    required this.phone,
    required this.org,
    required this.role,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF246BFD), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: C.text(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _RoleChip(role: role, color: roleColor),
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: C.muted(context, .75),
                    ),
                  ),
                ],
                if (org.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    org,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: C.muted(context, .5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleChip({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.isEmpty ? 'member' : role,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Center(
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
                  style: TextStyle(color: C.muted(context, .6), fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Qayta urinish'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
