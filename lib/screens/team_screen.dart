import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Jamoa va rollar — foydalanuvchilar ro'yxati va rol ta'riflari.
/// Dizayn: finn-app-full.html `#v-jamoa`.
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
    final f = Api.team();
    setState(() => _future = f);
    await f;
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  // Ismdan initsiallar
  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  // Telefonni '+998 XX XXX XX XX' ko'rinishida
  String _phone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12 && d.startsWith('998')) {
      return '+998 ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10, 12)}';
    }
    if (d.length == 9) {
      return '+998 ${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5, 7)} ${d.substring(7, 9)}';
    }
    return raw;
  }

  // Rol -> uslub (yorliq + akssent). Neytral rollar `fill/muted` ishlatadi.
  _RoleStyle _roleStyle(BuildContext c, String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'egasi':
        return const _RoleStyle('Egasi', C.blue, C.blue);
      case 'admin':
      case 'administrator':
        return _RoleStyle('Administrator', C.teal, C.onTea(c));
      case 'accountant':
      case 'buxgalter':
        return _RoleStyle('Buxgalter', C.violet, C.onPur(c));
      case 'observer':
      case 'viewer':
      case 'kuzatuvchi':
        return const _RoleStyle('Kuzatuvchi', null, null);
      default:
        // A'zo va boshqalar — neytral
        final label = role.isEmpty ? "A'zo" : role;
        return _RoleStyle(label[0].toUpperCase() + label.substring(1), null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: Loader(
                future: _future,
                onRefresh: _refresh,
                builder: (data) {
                  final raw = data['members'];
                  final members = (raw is List) ? raw : const [];

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    children: [
                      _eyebrow('Foydalanuvchilar', top: 8),
                      if (members.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: EmptyState(
                            icon: Icons.groups_rounded,
                            text: 'Jamoa a\'zolari yo\'q',
                            color: C.blue,
                          ),
                        )
                      else
                        for (int i = 0; i < members.length; i++)
                          StaggerIn(
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _memberRow(_asMap(members[i])),
                            ),
                          ),
                      const SizedBox(height: 10),
                      _inviteRow(),
                      _eyebrow('Rollar'),
                      _rolesCard(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                        child: Text(
                          'Har bir foydalanuvchining harakati audit jurnalida saqlanadi.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            color: C.muted(context, .4),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sarlavha (a'zolar/rollar hisobi bilan) ──
  Widget _header() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (ctx, snap) {
        String subtitle = 'Foydalanuvchilar va ruxsatlar';
        final data = snap.data;
        if (data != null && data['members'] is List) {
          final list = data['members'] as List;
          final roles = list
              .map((m) => (_asMap(m)['role'] ?? '').toString().toLowerCase())
              .where((r) => r.isNotEmpty)
              .toSet();
          subtitle =
              '${list.length} foydalanuvchi · ${roles.isEmpty ? 0 : roles.length} rol';
        }
        return ScreenHeader(
          title: 'Jamoa va rollar',
          subtitle: subtitle,
          icon: Icons.groups_rounded,
        );
      },
    );
  }

  // ── Eyebrow (bo'lim sarlavhasi + chiziq) ──
  Widget _eyebrow(String text, {double top = 24}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
        ],
      ),
    );
  }

  // ── A'zo qatori (.row) ──
  Widget _memberRow(Map<String, dynamic> m) {
    final name = (m['name']?.toString() ?? '').trim();
    final displayName = name.isEmpty ? 'Noma\'lum' : name;
    final phone = _phone(m['phone']?.toString() ?? '');
    final org = m['org']?.toString() ?? '';
    final rs = _roleStyle(context, m['role']?.toString() ?? 'member');

    final monoBg = rs.tintColor == null ? C.fill(context) : C.tint(context, rs.tintColor!);
    final monoFg = rs.onColor ?? C.muted(context, .7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: monoBg,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials(name),
              style: TextStyle(
                color: monoFg,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: C.text(context),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: C.muted(context, .55),
                    ),
                  ),
                ],
                if (org.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    org,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: C.muted(context, .4),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _rolePill(rs),
        ],
      ),
    );
  }

  // ── Rol pili (tinted / neytral) ──
  Widget _rolePill(_RoleStyle rs) {
    final bg = rs.tintColor == null ? C.fill(context) : C.tint(context, rs.tintColor!);
    final fg = rs.onColor ?? C.muted(context, .7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rs.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
          color: fg,
        ),
      ),
    );
  }

  // ── Taklif qilish qatori (dashed, fonsiz) ──
  Widget _inviteRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: C.border(context, .16),
          style: BorderStyle.solid,
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.fill(context),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, size: 22, color: C.muted(context, .5)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foydalanuvchi taklif qilish',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: C.muted(context, .75),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SMS orqali havola yuboriladi',
                  style: TextStyle(
                    fontSize: 12,
                    color: C.muted(context, .45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rollar kartasi (guruhlangan ta'riflar) ──
  Widget _rolesCard() {
    final roles = <_RoleDef>[
      const _RoleDef(
        icon: Icons.shield_rounded,
        title: 'Egasi',
        desc: 'Barcha huquqlar · to\'lov va o\'chirish',
        tintColor: C.blue,
        onColor: C.blue,
      ),
      _RoleDef(
        icon: Icons.description_rounded,
        title: 'Buxgalter',
        desc: 'Hujjat, hisobot, faktura · to\'lovsiz',
        tintColor: C.violet,
        onColor: C.onPur(context),
      ),
      const _RoleDef(
        icon: Icons.visibility_rounded,
        title: 'Kuzatuvchi',
        desc: 'Faqat ko\'rish · o\'zgartira olmaydi',
        tintColor: null,
        onColor: null,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(
        children: [
          for (int i = 0; i < roles.length; i++) ...[
            _roleDefRow(roles[i]),
            if (i != roles.length - 1)
              Divider(height: 1, thickness: 1, color: C.border(context, .05)),
          ],
        ],
      ),
    );
  }

  Widget _roleDefRow(_RoleDef r) {
    final bg = r.tintColor == null ? C.fill(context) : C.tint(context, r.tintColor!);
    final fg = r.onColor ?? C.muted(context, .7);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(r.icon, size: 20, color: fg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: C.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  r.desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: C.muted(context, .45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Rol pili/monogram uslubi. `tintColor == null` bo'lsa neytral (fill/muted).
class _RoleStyle {
  final String label;
  final Color? tintColor;
  final Color? onColor;
  const _RoleStyle(this.label, this.tintColor, this.onColor);
}

// Rol ta'rifi (statik ta'riflar bo'limi).
class _RoleDef {
  final IconData icon;
  final String title;
  final String desc;
  final Color? tintColor;
  final Color? onColor;
  const _RoleDef({
    required this.icon,
    required this.title,
    required this.desc,
    required this.tintColor,
    required this.onColor,
  });
}
