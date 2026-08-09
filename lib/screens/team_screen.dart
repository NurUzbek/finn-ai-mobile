import 'package:flutter/material.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Jamoa va rollar — foydalanuvchilar ro'yxati va rol ta'riflari.
/// HTML prototip (v-jamoa) bilan 1:1. PUSH ekran: showNav=false, orqaga tugma.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late Future<Map<String, dynamic>> _f;
  String _subtitle = tr('team.subtitle');

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _f = Api.team();
    _f.then((d) {
      if (!mounted) return;
      final raw = d['members'];
      if (raw is List) {
        final roles = raw
            .map((m) => (_asMap(m)['role'] ?? '').toString().toLowerCase())
            .where((r) => r.isNotEmpty)
            .toSet();
        setState(() => _subtitle =
            '${raw.length} ${tr('team.usersWord')} · ${roles.isEmpty ? 0 : roles.length} ${tr('team.rolesWord')}');
      }
    });
  }

  Future<void> _refresh() async => setState(_load);

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

  // Rol -> uslub. Monogram (avatar) DOIM rangli; pil esa neytral bo'lishi mumkin
  // (Kuzatuvchi: avatar tea, pil key/ink2). Prototipdagi holat 1:1.
  _RoleStyle _roleStyle(FinnTokens t, String role) {
    switch (role.toLowerCase()) {
      case 'owner':
      case 'egasi':
        return _RoleStyle(tr('team.role.owner'), t.tBlu, t.blue, t.tBlu, t.blue);
      case 'admin':
      case 'administrator':
        return _RoleStyle(
            tr('team.role.admin'), t.tTea, t.onTea, t.tTea, t.onTea);
      case 'accountant':
      case 'buxgalter':
        return _RoleStyle(
            tr('team.role.accountant'), t.tPur, t.onPur, t.tPur, t.onPur);
      case 'observer':
      case 'viewer':
      case 'kuzatuvchi':
        // avatar tea, pil neytral
        return _RoleStyle(tr('team.role.observer'), t.tTea, t.onTea, null, null);
      default:
        final label = role.isEmpty ? tr('team.role.member') : role;
        return _RoleStyle(
            label[0].toUpperCase() + label.substring(1), null, null, null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('team.title'),
      subtitle: _subtitle,
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context)),
      actions: [_iconBtn(t, Icons.add_rounded, onTap: () {})],
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _f,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final d = snap.data ?? {};
            if (d['ok'] != true && d['members'] == null) return _err(t);
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final raw = d['members'];
    final members = (raw is List) ? raw : const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _eyebrow(t, tr('team.usersSection'), top: 8),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: _empty(t),
          )
        else
          for (int i = 0; i < members.length; i++)
            StaggerIn(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _memberRow(t, _asMap(members[i])),
              ),
            ),
        _inviteRow(t),
        _eyebrow(t, tr('team.rolesSection')),
        _rolesCard(t),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
          child: Text(
            tr('team.auditNote'),
            style: FinnText.rowSub(t.ink4),
          ),
        ),
      ],
    );
  }

  Widget _empty(FinnTokens t) => Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: t.tBlu, shape: BoxShape.circle),
            child: Icon(Icons.groups_rounded, size: 32, color: t.blue),
          ),
          const SizedBox(height: 16),
          Text(tr('team.emptyMembers'),
              textAlign: TextAlign.center, style: FinnText.body(t.ink3)),
        ]),
      );

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('team.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('team.retry'))),
          ]),
        ),
      );

  // ── Ikonli tugma (.iconbtn / .back — 36×36, radius 12) ──
  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line, width: 1),
          ),
          child: Icon(ic, size: 18, color: t.ink2),
        ),
      );

  // ── Eyebrow (bo'lim sarlavhasi + chiziq) ──
  Widget _eyebrow(FinnTokens t, String text, {double top = 24}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, top, 0, 12),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ],
      ),
    );
  }

  // ── Monogram (.m — 38×38, radius 12) ──
  Widget _mono(FinnTokens t, {required Color bg, required Widget child}) =>
      Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  // ── A'zo qatori (.row) ──
  Widget _memberRow(FinnTokens t, Map<String, dynamic> m) {
    final name = (m['name']?.toString() ?? '').trim();
    final displayName = name.isEmpty ? tr('team.unknown') : name;
    final phone = _phone(m['phone']?.toString() ?? '');
    final org = m['org']?.toString() ?? '';
    final rs = _roleStyle(t, m['role']?.toString() ?? 'member');

    final avatarBg = rs.avatarTint ?? t.key;
    final avatarFg = rs.avatarOn ?? t.ink2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Row(
        children: [
          _mono(t,
              bg: avatarBg,
              child: Text(_initials(name), style: FinnText.rowValue(avatarFg))),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FinnText.rowTitle(t.ink)),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FinnText.rowSub(t.ink3)),
                ],
                if (org.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(org,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FinnText.rowSub(t.ink3)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 13),
          _rolePill(t, rs),
        ],
      ),
    );
  }

  // ── Rol pili (.pill — rangli yoki neytral key/ink2) ──
  Widget _rolePill(FinnTokens t, _RoleStyle rs) {
    final bg = rs.pillTint ?? t.key;
    final fg = rs.pillOn ?? t.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(rs.label, style: FinnText.pill(fg)),
    );
  }

  // ── Taklif qilish qatori (fonsiz, uzuq-uzuq ramka) ──
  Widget _inviteRow(FinnTokens t) {
    return CustomPaint(
      painter: _DashedRRectPainter(color: t.line, radius: FinnTokens.rLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            _mono(t,
                bg: t.key,
                child: Icon(Icons.add_rounded, size: 18, color: t.ink3)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('team.invite'),
                      style: FinnText.rowTitle(t.ink2)),
                  const SizedBox(height: 2),
                  Text(tr('team.inviteSub'),
                      style: FinnText.rowSub(t.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Rollar kartasi (.grp — guruhlangan ta'riflar) ──
  Widget _rolesCard(FinnTokens t) {
    final roles = <_RoleDef>[
      _RoleDef(
        icon: Icons.shield_rounded,
        title: tr('team.role.owner'),
        desc: tr('team.roleDef.ownerDesc'),
        tint: t.tBlu,
        on: t.blue,
      ),
      _RoleDef(
        icon: Icons.description_rounded,
        title: tr('team.role.accountant'),
        desc: tr('team.roleDef.accountantDesc'),
        tint: t.tPur,
        on: t.onPur,
      ),
      _RoleDef(
        icon: Icons.visibility_rounded,
        title: tr('team.role.observer'),
        desc: tr('team.roleDef.observerDesc'),
        tint: null,
        on: null,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(
        children: [
          for (int i = 0; i < roles.length; i++) ...[
            _roleDefRow(t, roles[i]),
            if (i != roles.length - 1)
              Divider(height: 1, thickness: 1, color: t.line2),
          ],
        ],
      ),
    );
  }

  Widget _roleDefRow(FinnTokens t, _RoleDef r) {
    final bg = r.tint ?? t.key;
    final fg = r.on ?? t.ink2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(r.icon, size: 18, color: fg),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: FinnText.rowTitle(t.ink)),
                const SizedBox(height: 2),
                Text(r.desc, style: FinnText.rowSub(t.ink3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Rol uslubi. Monogram (avatar) DOIM rangli bo'lishi mumkin; pil `pillTint == null`
// bo'lsa neytral (key/ink2) — masalan Kuzatuvchi.
class _RoleStyle {
  final String label;
  final Color? avatarTint;
  final Color? avatarOn;
  final Color? pillTint;
  final Color? pillOn;
  const _RoleStyle(
      this.label, this.avatarTint, this.avatarOn, this.pillTint, this.pillOn);
}

// Rol ta'rifi (statik ta'riflar bo'limi).
class _RoleDef {
  final IconData icon;
  final String title;
  final String desc;
  final Color? tint;
  final Color? on;
  const _RoleDef({
    required this.icon,
    required this.title,
    required this.desc,
    required this.tint,
    required this.on,
  });
}

/// Uzuq-uzuq (dashed) yumaloq-burchakli ramka — taklif qilish qatori uchun.
/// HTML `.row{border-style:dashed;box-shadow:none;background:none}` ekvivalenti.
class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;
  static const double dash = 5, gap = 4, strokeWidth = 1.4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      const Offset(strokeWidth / 2, strokeWidth / 2) &
          Size(size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dash), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
