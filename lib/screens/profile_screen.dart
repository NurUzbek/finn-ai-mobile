import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../theme/finn_tokens.dart';
import '../services/permits.dart';
import '../widgets/finn_screen.dart';
import '../widgets/common.dart';
import '../services/api.dart';
import '../services/lock.dart';
import '../services/theme.dart';
import '../services/i18n.dart';
import 'login_screen.dart';
import 'pin_screen.dart';
import 'subscription_screen.dart';
import 'identity_screen.dart';

/// Profil — hisob, tarif va sozlamalar (mavzu, til, xavfsizlik).
/// FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText).
/// Nav shell'dan keladi: navIndex + onNavChanged. Ma'lumot: `Api.me()`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.navIndex = 5, this.onNavChanged});
  final int navIndex;
  final ValueChanged<int>? onNavChanged;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _f = Api.me();
  Future<void> _refresh() async => setState(() => _f = Api.me());

  bool _push = true; // faqat lokal — endpoint yo'q
  bool _bioOn = false;
  bool _bioAvail = false;

  @override
  void initState() {
    super.initState();
    _loadLock();
  }

  Future<void> _loadLock() async {
    final avail = await Lock.bioAvailable();
    final on = await Lock.bioOn();
    if (mounted) setState(() { _bioAvail = avail; _bioOn = on && avail; });
  }

  // ── Xatti-harakatlar ─────────────────────────────────────────────

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickLocale() async {
    final t = context.tokens;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(FinnTokens.rXl)),
      ),
      builder: (c) {
        final t = c.tokens;
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(
                color: t.line2, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
              child: Row(children: [
                Icon(Icons.language, size: 18, color: t.blue),
                const SizedBox(width: 10),
                Text(tr('profile.langSheetTitle'), style: FinnText.cardTitle(t.ink).copyWith(fontSize: 15)),
              ]),
            ),
            for (final k in I18n.langs)
              ListTile(
                title: Text(I18n.langNames[k]!, style: FinnText.rowTitle(t.ink)),
                subtitle: Text(I18n.langSub[k]!, style: FinnText.rowSub(t.ink3)),
                trailing: I18n.i.lang == k ? Icon(Icons.check_circle, color: t.green, size: 20) : null,
                onTap: () => Navigator.pop(c, k),
              ),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
    if (picked == null) return;
    await I18n.i.setLang(picked); // butun ilova qayta quriladi
    if (mounted) setState(() {});
  }

  Future<void> _toggleBio(bool v) async {
    if (v) {
      if (!_bioAvail) { _toast(tr('profile.bioUnavailable')); return; }
      // PIN bo'lmasa — avval o'rnatamiz (PinScreen 'set' o'zi biometrikani so'raydi).
      if (!await Lock.hasPin()) {
        await Lock.setBio(true);
        if (!mounted) return;
        setState(() => _bioOn = true);
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PinScreen(mode: 'set')));
        return;
      }
      await Lock.setBio(true);
    } else {
      await Lock.setBio(false);
    }
    if (mounted) setState(() => _bioOn = v);
  }

  void _changePin() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PinScreen(mode: 'set')));

  void _openDevices(int count) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _DevicesScreen(count: count)));

  Future<void> _logout() async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: c.tokens.card,
        title: Text(tr('profile.logout'), style: FinnText.cardTitle(c.tokens.ink)),
        content: Text(tr('profile.logoutConfirm'), style: FinnText.body(c.tokens.ink2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('profile.logout'), style: FinnText.button(t.red))),
        ],
      ),
    );
    if (ok != true) return;
    await Api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  // ── Yordamchilar ─────────────────────────────────────────────────

  static String _fmtPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 12) {
      return '+${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, 10)} ${d.substring(10, 12)}';
    }
    return raw.startsWith('+') ? raw : '+$raw';
  }

  static String _mono(String name) {
    final t = name.trim();
    if (t.isEmpty) return 'F';
    if (RegExp(r'[0-9+]').hasMatch(t[0])) return 'F';
    return t[0].toUpperCase();
  }

  // ── Build ────────────────────────────────────────────────────────

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('nav.profile'),
      subtitle: tr('profile.headerSub'),
      showNav: false,
      reserveNav: true,
      actions: [
        _iconBtn(t, Icons.refresh_rounded, onTap: _refresh),
      ],
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
            if (d['ok'] != true) return _err(t);
            return _content(context, d);
          },
        ),
      ],
    );
  }

  Widget _err(FinnTokens t) => Padding(
        padding: const EdgeInsets.only(top: 140),
        child: Center(
          child: Column(children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('state.noConnection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('common.retry'))),
          ]),
        ),
      );

  Widget _content(BuildContext context, Map<String, dynamic> d) {
    final u = d['user'] as Map<String, dynamic>? ?? const {};
    final plan = d['plan'] as Map<String, dynamic>? ?? const {};
    final features = plan['features'] as Map<String, dynamic>? ?? const {};

    final name = (u['name'] ?? '').toString();
    final phone = _fmtPhone((u['phone'] ?? '').toString());
    final rawEmail = (u['email'] ?? '').toString();
    final email = rawEmail.isEmpty ? '—' : rawEmail;
    final jshshir = ((d['identity'] as Map?)?['jshshir'] ?? '').toString();
    final avatar = (u['avatar'] ?? '').toString();
    final orgsCount = u['orgs_count'] ?? 0;
    final devices = (u['devices_count'] is int) ? u['devices_count'] as int : 1;

    final slug = (plan['slug'] ?? '').toString().toLowerCase();
    final isTrial = plan['is_trial'] == true;
    final rawName = (plan['name'] ?? '').toString();
    final planTitle = isTrial
        ? tr('profile.planTrial')
        : (slug == 'free' || rawName.toUpperCase() == 'FREE')
            ? tr('profile.planFree')
            : (rawName.isEmpty ? tr('profile.planCurrent') : rawName);
    final orgsLimit = features['orgs_limit'];
    final planSub = orgsLimit == null
        ? tr('profile.orgsWatched').replaceAll('{n}', '$orgsCount')
        : tr('profile.orgsWatchedLimit')
            .replaceAll('{limit}', '$orgsLimit')
            .replaceAll('{n}', '$orgsCount');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── "Men" kartasi (bosilganda → shaxsiy ma'lumotlarni tahrirlash) ──
        StaggerIn(index: 0, child: _meCard(context, name, phone, avatar: avatar, onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => _EditProfileScreen(
                name: name,
                phone: phone,
                email: rawEmail,
                jshshir: jshshir,
                avatar: avatar,
                onSaved: _refresh,
              )));
        })),
        const SizedBox(height: 11),

        // ── Tarif kartasi ──
        StaggerIn(index: 1, child: _planCard(context, planTitle, planSub)),
        const SizedBox(height: 11),

        // ── Shaxsni tasdiqlash (OneID) ──
        StaggerIn(index: 1, child: _identityCard(context, (d['identity'] as Map?)?['verified'] == true)),

        // ── Sozlamalar ──
        StaggerIn(index: 2, child: _eyebrow(context, tr('profile.secSettings'))),
        StaggerIn(index: 2, child: _group(context, [
          _themeRow(context),
          _row(context,
              icon: Icons.language, color: context.tokens.blue, tint: context.tokens.tBlu,
              title: tr('profile.language'), sub: I18n.langNames[I18n.i.lang] ?? "O'zbekcha",
              onTap: _pickLocale),
          _switchRow(context,
              icon: Icons.notifications_none_rounded, color: context.tokens.green, tint: context.tokens.tGrn,
              title: tr('profile.push'), sub: tr('profile.pushSub'),
              value: _push, onChanged: (v) => setState(() => _push = v)),
        ])),

        // ── Xavfsizlik ──
        StaggerIn(index: 3, child: _eyebrow(context, tr('profile.secSecurity'))),
        StaggerIn(index: 3, child: _group(context, [
          _switchRow(context,
              icon: Icons.face_retouching_natural, color: context.tokens.blue, tint: context.tokens.tBlu,
              title: tr('profile.faceId'), sub: tr('profile.faceIdSub'),
              value: _bioOn, onChanged: _toggleBio),
          _row(context,
              icon: Icons.lock_outline_rounded, color: context.tokens.purple, tint: context.tokens.tPur,
              title: tr('profile.changePin'), sub: tr('profile.changePinSub'),
              onTap: _changePin),
          _row(context,
              icon: Icons.devices_rounded, color: context.tokens.amber, tint: context.tokens.tAmb,
              title: tr('profile.devices'), sub: tr('profile.sessions').replaceAll('{n}', '$devices'),
              onTap: () => _openDevices(devices)),
          _row(context,
              icon: Icons.timer_outlined, color: context.tokens.ink3, tint: context.tokens.key,
              title: tr('profile.sessionTimeout'), sub: tr('profile.sessionTimeoutSub'),
              onTap: () => _toast(tr('profile.sessionToast'))),
        ])),

        // ── Hisob ──
        StaggerIn(index: 4, child: _eyebrow(context, tr('profile.secAccount'))),
        StaggerIn(index: 4, child: _group(context, [
          _row(context,
              icon: Icons.mail_outline_rounded, color: context.tokens.blue, tint: context.tokens.tBlu,
              title: tr('profile.email'), sub: email),
          _row(context,
              icon: Icons.logout_rounded, color: context.tokens.red, tint: context.tokens.tRed,
              title: tr('profile.logout'), danger: true, onTap: _logout),
        ])),

        const SizedBox(height: 20),
        Center(child: Text(tr('profile.version'),
            style: FinnText.rowSub(context.tokens.ink4))),
      ],
    );
  }

  // ── Bo'laklar ────────────────────────────────────────────────────

  BoxDecoration _cardBox(FinnTokens t, {double radius = FinnTokens.rLg}) => BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      );

  Widget _meCard(BuildContext c, String name, String phone,
      {String avatar = '', VoidCallback? onTap}) {
    final t = c.tokens;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(FinnTokens.rXl),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: _cardBox(t, radius: FinnTokens.rXl),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: avatar.isEmpty ? FinnTokens.brand : null,
                color: t.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: avatar.isEmpty
                  ? Center(child: Text(_mono(name),
                      style: FinnText.bigValue(Colors.white).copyWith(fontSize: 22)))
                  : Image.network(avatar, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(child: Text(_mono(name),
                          style: FinnText.bigValue(Colors.white).copyWith(fontSize: 22)))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name.isEmpty ? tr('profile.userFallback') : name,
                  style: FinnText.cardTitle(t.ink).copyWith(fontSize: 16.5)),
              const SizedBox(height: 3),
              Text(phone, style: FinnText.rowSub(t.ink3)),
            ])),
            Icon(Icons.chevron_right, size: 20, color: t.ink4),
          ]),
        ),
      ),
    );
  }

  Widget _planCard(BuildContext c, String title, String sub) {
    final t = c.tokens;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardBox(t, radius: FinnTokens.rLg),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: t.tAmb, borderRadius: BorderRadius.circular(13)),
          child: Icon(Icons.star_rounded, size: 22, color: t.onAmb),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: FinnText.rowTitle(t.ink)),
          const SizedBox(height: 2),
          Text(sub, style: FinnText.rowSub(t.ink3)),
        ])),
        GestureDetector(
          onTap: () => Navigator.of(c).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(gradient: FinnTokens.brand, borderRadius: BorderRadius.circular(30)),
            child: Text(tr('common.expand'), style: FinnText.pill(Colors.white)),
          ),
        ),
      ]),
    );
  }

  Widget _identityCard(BuildContext context, bool verified) {
    final t = context.tokens;
    final tintCol = verified ? t.tGrn : t.tAmb;
    final on = verified ? t.onGrn : t.onAmb;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IdentityScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardBox(t, radius: FinnTokens.rXl),
        child: Row(children: [
          Container(
            width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(color: tintCol, borderRadius: BorderRadius.circular(13)),
            child: Icon(verified ? Icons.verified_rounded : Icons.shield_outlined, color: on, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr('ident.profileRow'), style: FinnText.rowTitle(t.ink)),
            const SizedBox(height: 2),
            Text(tr('ident.sub'), style: FinnText.rowSub(t.ink3)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: tintCol, borderRadius: BorderRadius.circular(20)),
            child: Text(verified ? tr('ident.statusVerified') : tr('ident.statusIncomplete'),
                style: FinnText.pill(on)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, size: 18, color: t.ink4),
        ]),
      ),
    );
  }

  Widget _eyebrow(BuildContext c, String label) {
    final t = c.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(children: [
        Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: t.line)),
      ]),
    );
  }

  /// Bo'linadigan satrlardan iborat yumaloq guruh kartasi.
  Widget _group(BuildContext c, List<Widget> rows) {
    final t = c.tokens;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(Divider(height: 1, thickness: 1, indent: 62, color: t.line));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardBox(t, radius: FinnTokens.rXl),
      child: Column(children: children),
    );
  }

  Widget _iconBox(FinnTokens t, IconData i, Color color, Color tint) => Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(11)),
        child: Icon(i, size: 17, color: color),
      );

  /// Navigatsiya / oddiy satr (o'ng tomonda chevron yoki maxsus trailing).
  Widget _row(BuildContext c,
      {required IconData icon,
      required Color color,
      required Color tint,
      required String title,
      String? sub,
      Widget? trailing,
      bool danger = false,
      VoidCallback? onTap}) {
    final t = c.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            _iconBox(t, icon, color, tint),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: FinnText.rowTitle(danger ? t.red : t.ink)),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub, style: FinnText.rowSub(t.ink3)),
              ],
            ])),
            if (trailing != null)
              trailing
            else if (onTap != null && !danger)
              Icon(Icons.chevron_right, size: 19, color: t.ink4),
          ]),
        ),
      ),
    );
  }

  /// Toggle (switch) bilan satr.
  Widget _switchRow(BuildContext c,
      {required IconData icon,
      required Color color,
      required Color tint,
      required String title,
      required String sub,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return _row(c, icon: icon, color: color, tint: tint, title: title, sub: sub,
        trailing: _Switch(value: value, onChanged: onChanged));
  }

  /// Mavzu satri — yorug'/qorong'i segmentli almashtirgich.
  Widget _themeRow(BuildContext c) {
    final t = c.tokens;
    final dark = ThemeState.i.isDark;
    return _row(c,
        icon: Icons.contrast_rounded, color: t.purple, tint: t.tPur,
        title: tr('profile.theme'), sub: dark ? tr('profile.themeDark') : tr('profile.themeLight'),
        trailing: _Segment(dark: dark));
  }
}

/// Yorug'/qorong'i segmentli almashtirgich (sirg'aluvchi gradient tugma).
class _Segment extends StatelessWidget {
  final bool dark;
  const _Segment({required this.dark});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget opt(bool isDark, IconData icon) {
      final active = dark == isDark;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ThemeState.i.setMode(isDark ? ThemeMode.dark : ThemeMode.light),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            gradient: active ? FinnTokens.brand : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: active ? Colors.white : t.ink3),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.line2,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        opt(false, Icons.light_mode),
        const SizedBox(width: 3),
        opt(true, Icons.dark_mode),
      ]),
    );
  }
}

/// Maxsus switch — pill track + sirg'aluvchi knob (dizaynga mos).
class _Switch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Switch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 46, height: 28,
        decoration: BoxDecoration(
          gradient: value ? FinnTokens.brand : null,
          color: value ? null : t.ink4,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: t.sh,
            ),
          ),
        ),
      ),
    );
  }
}

/// Aktiv qurilmalar (sessiyalar) — /devices dan JONLI ro'yxat, joriy qurilma
/// belgilanadi, boshqasini "Chiqarish" (revoke) mumkin.
class _DevicesScreen extends StatefulWidget {
  final int count;
  const _DevicesScreen({required this.count});
  @override
  State<_DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<_DevicesScreen> {
  late Future<Map<String, dynamic>> _f = Api.devices();
  int? _busyId;
  void _reload() => setState(() => _f = Api.devices());

  Future<void> _revoke(int id) async {
    setState(() => _busyId = id);
    final res = await Api.revokeDevice(id);
    if (!mounted) return;
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
          content: Text(res['ok'] == true
              ? tr('profile.deviceRevoked')
              : (res['message']?.toString() ?? tr('profile.deviceRevokeErr')))));
    if (res['ok'] == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: t.ink),
              ),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('profile.devices'), style: FinnText.cardTitle(t.ink)),
                Text(tr('profile.devicesSub'), style: FinnText.rowSub(t.ink3)),
              ])),
              IconButton(
                onPressed: _reload,
                icon: Icon(Icons.refresh_rounded, size: 20, color: t.ink2),
              ),
            ]),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _f,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final d = snap.data ?? const {};
                final list = ((d['devices'] as List?) ?? const [])
                    .whereType<Map>()
                    .toList();
                if (d['ok'] != true) {
                  return _msg(t, Icons.cloud_off_rounded,
                      d['message']?.toString() ?? tr('state.noConnection'));
                }
                if (list.isEmpty) {
                  return _msg(t, Icons.devices_rounded, tr('profile.noDevices'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _card(t, list[i].cast<String, dynamic>()),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _msg(FinnTokens t, IconData ic, String text) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(ic, size: 44, color: t.ink4),
          const SizedBox(height: 12),
          Text(text, style: FinnText.body(t.ink3), textAlign: TextAlign.center),
        ]),
      );

  Widget _card(FinnTokens t, Map<String, dynamic> d) {
    final current = d['current'] == true;
    final model = (d['model'] ?? '').toString().toLowerCase();
    final isComputer = model.contains('komp') || model.contains('pc') ||
        (d['os'] ?? '').toString().toLowerCase().contains('windows');
    final sub = [
      if ((d['os'] ?? '').toString().isNotEmpty) d['os'],
      if ((d['ip'] ?? '').toString().isNotEmpty) d['ip'],
      if ((d['last_active'] ?? '').toString().isNotEmpty) d['last_active'],
    ].join(' · ');
    final id = (d['id'] as num?)?.toInt() ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rLg),
        border: Border.all(color: current ? t.green : t.line, width: current ? 1.4 : 1),
        boxShadow: t.sh,
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40, alignment: Alignment.center,
          decoration: BoxDecoration(
              color: current ? t.tGrn : t.tBlu,
              borderRadius: BorderRadius.circular(13)),
          child: Icon(isComputer ? Icons.computer_rounded : Icons.smartphone_rounded,
              size: 20, color: current ? t.onGrn : t.blue),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((d['name'] ?? tr('profile.devices')).toString(),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: FinnText.rowTitle(t.ink)),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: FinnText.rowSub(t.ink3)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        if (current)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: t.tGrn, borderRadius: BorderRadius.circular(20)),
            child: Text(tr('profile.thisDevice'), style: FinnText.pill(t.onGrn)),
          )
        else if (_busyId == id)
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
        else
          GestureDetector(
            onTap: () => _revoke(id),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: t.tRed, borderRadius: BorderRadius.circular(FinnTokens.rSm)),
              child: Text(tr('profile.deviceRevoke'), style: FinnText.pill(t.onRed)),
            ),
          ),
      ]),
    );
  }
}

/// Shaxsiy ma'lumotlar — ism/familiya + email tahrirlash (proto: `v-hisob`).
/// PUSH ekran: telefon va JSHSHIR OneID orqali — qulflangan, faqat ko'rsatiladi.
class _EditProfileScreen extends StatefulWidget {
  const _EditProfileScreen({
    required this.name,
    required this.phone,
    required this.email,
    required this.jshshir,
    required this.avatar,
    required this.onSaved,
  });

  final String name;
  final String phone;
  final String email;
  final String jshshir;
  final String avatar;
  final Future<void> Function() onSaved;

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.name);
  late final TextEditingController _email = TextEditingController(text: widget.email);
  bool _saving = false;

  // Rasm holati
  late String? _avatar = widget.avatar.isEmpty ? null : widget.avatar;
  Uint8List? _picked;
  bool _upBusy = false;

  // Faqat PNG, JPG/JPEG, HEIC/HEIF ruxsat — qolgani rad etiladi.
  static const _allowedExt = {'png', 'jpg', 'jpeg', 'heic', 'heif'};

  /// Manba tanlash: rasmga tushish (kamera) yoki galereyadan.
  Future<void> _pickAvatar() async {
    if (_upBusy) return;
    final t = context.tokens;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(FinnTokens.rXl)),
          border: Border.all(color: t.line),
        ),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: t.ink4, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Align(alignment: Alignment.centerLeft, child: Text(tr('profile.photoSource'), style: FinnText.cardTitle(t.ink))),
            ),
            _sourceRow(t, Icons.photo_camera_rounded, tr('profile.photoCamera'), () => Navigator.pop(ctx, ImageSource.camera)),
            _sourceRow(t, Icons.photo_library_rounded, tr('profile.photoGallery'), () => Navigator.pop(ctx, ImageSource.gallery)),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
    if (source == null) return;
    // Kamera uchun ruxsat so'raymiz. Galereya — Photo Picker orqali ruxsatsiz ishlaydi.
    if (!kIsWeb && source == ImageSource.camera) {
      final ok = await Permits.ensureCamera();
      if (!ok) {
        _toast(tr('profile.permCamera'));
        return;
      }
    }
    await _pickFrom(source);
  }

  Widget _sourceRow(FinnTokens t, IconData icon, String label, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Container(
              width: 40, height: 40, alignment: Alignment.center,
              decoration: BoxDecoration(color: t.blue.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(FinnTokens.rMd)),
              child: Icon(icon, color: t.blue, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: FinnText.rowTitle(t.ink)),
          ]),
        ),
      );

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(
          source: source, maxWidth: 1200, imageQuality: 92);
      if (x == null) return;
      final ext = x.name.contains('.') ? x.name.split('.').last.toLowerCase() : '';
      if (!_allowedExt.contains(ext)) {
        _toast(tr('profile.photoFormat'));
        return;
      }
      final bytes = await x.readAsBytes();
      setState(() {
        _picked = bytes;
        _upBusy = true;
      });
      final res = await Api.uploadAvatar(bytes, x.name);
      if (!mounted) return;
      setState(() => _upBusy = false);
      if (res['ok'] == true) {
        setState(() => _avatar = res['avatar']?.toString());
        await widget.onSaved();
        _toast(tr('profile.photoUpdated'));
      } else {
        _toast(res['message']?.toString() ?? tr('profile.photoError'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _upBusy = false);
        _toast(tr('profile.photoError'));
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _toast(tr('profile.nameRequired'));
      return;
    }
    setState(() => _saving = true);
    final email = _email.text.trim();
    final res = await Api.updateProfile(name: name, email: email.isEmpty ? null : email);
    if (!mounted) return;
    setState(() => _saving = false);
    if (res['ok'] == true) {
      await widget.onSaved();
      if (!mounted) return;
      _toast(tr('profile.saved'));
      Navigator.of(context).maybePop();
    } else {
      _toast((res['message'] ?? tr('profile.saveError')).toString());
    }
  }

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final initial = _ProfileScreenState._mono(widget.name);
    return FinnScreen(
      title: tr('profile.editTitle'),
      subtitle: tr('profile.editSub'),
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop()),
      children: [
        const SizedBox(height: 4),
        // ── Avatar + "Rasmni o'zgartirish" ──
        Center(
          child: Column(children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pickAvatar,
              child: Container(
                width: 88, height: 88,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: _picked == null && _avatar == null
                      ? FinnTokens.brand
                      : null,
                  color: t.card,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(fit: StackFit.expand, children: [
                  if (_picked != null)
                    Image.memory(_picked!, fit: BoxFit.cover)
                  else if (_avatar != null)
                    Image.network(_avatar!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                            child: Text(initial,
                                style: FinnText.heroValue(Colors.white)
                                    .copyWith(fontSize: 34))))
                  else
                    Center(child: Text(initial,
                        style: FinnText.heroValue(Colors.white).copyWith(fontSize: 34))),
                  if (_upBusy)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                          child: SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white))),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 13),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _pickAvatar,
              child: Text(tr('profile.changePhoto'),
                  style: FinnText.rowTitle(t.blue).copyWith(fontSize: 13.5, letterSpacing: 0)),
            ),
          ]),
        ),
        const SizedBox(height: 22),

        // ── Maydonlar ──
        _fieldLabel(t, tr('profile.fieldName')),
        _input(t, _name, keyboard: TextInputType.name, capitalization: TextCapitalization.words),
        const SizedBox(height: 11),

        _fieldLabel(t, tr('profile.fieldPhone')),
        _lockedField(t, widget.phone, mono: true),
        _fieldHint(t, tr('profile.phoneLockHint')),
        const SizedBox(height: 11),

        _fieldLabel(t, tr('profile.fieldEmail')),
        _input(t, _email, keyboard: TextInputType.emailAddress),
        _fieldHint(t, tr('profile.emailHint')),

        if (widget.jshshir.isNotEmpty) ...[
          const SizedBox(height: 11),
          _fieldLabel(t, tr('profile.fieldJshshir')),
          _lockedField(t, widget.jshshir, mono: true),
        ],

        // ── Saqlash ──
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _saving ? null : _save,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: FinnTokens.brand,
                borderRadius: BorderRadius.circular(FinnTokens.rMd),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : Text(tr('profile.save'), style: FinnText.button(Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(label,
            style: FinnText.rowSub(t.ink2).copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
      );

  Widget _fieldHint(FinnTokens t, String hint) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(hint,
            style: FinnText.rowSub(t.ink3).copyWith(fontSize: 11.5, height: 1.45)),
      );

  Widget _input(FinnTokens t, TextEditingController c,
      {TextInputType? keyboard,
      TextCapitalization capitalization = TextCapitalization.none}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      textCapitalization: capitalization,
      cursorColor: t.blue,
      style: const TextStyle(fontFamily: 'Inter', fontSize: 15).copyWith(color: t.ink),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: t.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinnTokens.rMd),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FinnTokens.rMd),
          borderSide: BorderSide(color: t.blue, width: 1.6),
        ),
      ),
    );
  }

  Widget _lockedField(FinnTokens t, String value, {bool mono = false}) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: t.key,
        borderRadius: BorderRadius.circular(FinnTokens.rMd),
      ),
      child: Row(children: [
        Expanded(
          child: Text(value,
              style: TextStyle(
                fontFamily: mono ? 'InterTight' : 'Inter',
                fontSize: 15,
                color: t.ink2,
                fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
              )),
        ),
        Icon(Icons.lock_outline_rounded, size: 16, color: t.ink3),
      ]),
    );
  }
}
