import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/lock.dart';
import '../services/theme.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'pin_screen.dart';
import 'subscription_screen.dart';

/// Profil — hisob, tarif va sozlamalar (mavzu, til, xavfsizlik).
/// Dizayn: finn-app-screens.html #v-profil. Ma'lumot: `Api.me()`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
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
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: C.muted(c, .2), borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(children: [
              const Icon(Icons.language, size: 18, color: C.blue),
              const SizedBox(width: 10),
              Text('Ilova tili', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: C.text(c))),
            ]),
          ),
          for (final k in I18n.langs)
            ListTile(
              title: Text(I18n.langNames[k]!, style: TextStyle(color: C.text(c), fontWeight: FontWeight.w600)),
              subtitle: Text(I18n.langSub[k]!, style: TextStyle(color: C.muted(c, .5), fontSize: 12)),
              trailing: I18n.i.lang == k ? const Icon(Icons.check_circle, color: C.green, size: 20) : null,
              onTap: () => Navigator.pop(c, k),
            ),
          const SizedBox(height: 8),
        ]),
      ),
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: C.card(c),
        title: Text(tr('profile.logout'), style: TextStyle(fontSize: 17, color: C.text(c))),
        content: Text(tr('profile.logoutConfirm'), style: TextStyle(fontSize: 13.5, color: C.muted(c, .7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('common.cancel'))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('profile.logout'), style: const TextStyle(color: C.red))),
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

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          ScreenHeader(title: tr('nav.profile'), icon: Icons.person, subtitle: tr('profile.headerSub')),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final u = d['user'] as Map<String, dynamic>? ?? const {};
                final plan = d['plan'] as Map<String, dynamic>? ?? const {};
                final features = plan['features'] as Map<String, dynamic>? ?? const {};

                final name = (u['name'] ?? '').toString();
                final phone = _fmtPhone((u['phone'] ?? '').toString());
                final email = (u['email'] ?? '—').toString();
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

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                  children: [
                    // ── "Men" kartasi ──
                    StaggerIn(index: 0, child: _meCard(context, name, phone)),
                    const SizedBox(height: 11),

                    // ── Tarif kartasi ──
                    StaggerIn(index: 1, child: _planCard(context, planTitle, planSub)),

                    // ── Sozlamalar ──
                    StaggerIn(index: 2, child: _eyebrow(context, tr('profile.secSettings'))),
                    StaggerIn(index: 2, child: _group(context, [
                      _themeRow(context),
                      _row(context,
                          icon: Icons.language, color: C.blue,
                          title: tr('profile.language'), sub: I18n.langNames[I18n.i.lang] ?? "O'zbekcha",
                          onTap: _pickLocale),
                      _switchRow(context,
                          icon: Icons.notifications_none_rounded, color: C.green,
                          title: tr('profile.push'), sub: tr('profile.pushSub'),
                          value: _push, onChanged: (v) => setState(() => _push = v)),
                      _row(context,
                          icon: Icons.grid_view_rounded, color: C.brand,
                          title: tr('profile.allModules'), sub: tr('profile.modulesSub'),
                          onTap: () => homeScaffoldKey.currentState?.openDrawer()),
                    ])),

                    // ── Xavfsizlik ──
                    StaggerIn(index: 3, child: _eyebrow(context, tr('profile.secSecurity'))),
                    StaggerIn(index: 3, child: _group(context, [
                      _switchRow(context,
                          icon: Icons.face_retouching_natural, color: C.blue,
                          title: tr('profile.faceId'), sub: tr('profile.faceIdSub'),
                          value: _bioOn, onChanged: _toggleBio),
                      _row(context,
                          icon: Icons.lock_outline_rounded, color: C.violet,
                          title: tr('profile.changePin'), sub: tr('profile.changePinSub'),
                          onTap: _changePin),
                      _row(context,
                          icon: Icons.devices_rounded, color: C.amber,
                          title: tr('profile.devices'), sub: tr('profile.sessions').replaceAll('{n}', '$devices'),
                          onTap: () => _openDevices(devices)),
                      _row(context,
                          icon: Icons.timer_outlined, color: C.muted(context, .55),
                          title: tr('profile.sessionTimeout'), sub: tr('profile.sessionTimeoutSub'),
                          onTap: () => _toast(tr('profile.sessionToast'))),
                    ])),

                    // ── Hisob ──
                    StaggerIn(index: 4, child: _eyebrow(context, tr('profile.secAccount'))),
                    StaggerIn(index: 4, child: _group(context, [
                      _row(context,
                          icon: Icons.mail_outline_rounded, color: C.blue,
                          title: tr('profile.email'), sub: email),
                      _row(context,
                          icon: Icons.logout_rounded, color: C.red,
                          title: tr('profile.logout'), danger: true, onTap: _logout),
                    ])),

                    const SizedBox(height: 20),
                    Center(child: Text('FINN AI v1.0.0 · ONEDESK GROUP MChJ',
                        style: TextStyle(fontSize: 10.5, color: C.muted(context, .3)))),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  // ── Bo'laklar ────────────────────────────────────────────────────

  Widget _meCard(BuildContext c, String name, String phone) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(16),
        decoration: _cardBox(c, radius: 24),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: C.grad,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: Text(_mono(name),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? tr('profile.userFallback') : name,
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: C.text(c))),
            const SizedBox(height: 3),
            Text(phone, style: TextStyle(fontSize: 12.5, color: C.muted(c, .5))),
          ])),
          Icon(Icons.chevron_right, size: 20, color: C.muted(c, .3)),
        ]),
      );

  Widget _planCard(BuildContext c, String title, String sub) => Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardBox(c, radius: 20),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: C.tint(c, C.amber), borderRadius: BorderRadius.circular(13)),
            child: Icon(Icons.star_rounded, size: 22, color: C.onAmb(c)),
          ),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: C.text(c))),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 12, color: C.muted(c, .5))),
          ])),
          GestureDetector(
            onTap: () => Navigator.of(c).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(30)),
              child: Text(tr('common.expand'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      );

  Widget _eyebrow(BuildContext c, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 9),
        child: Row(children: [
          Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: C.muted(c, .5))),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: C.border(c, .06))),
        ]),
      );

  /// Bo'linadigan satrlardan iborat yumaloq guruh kartasi.
  Widget _group(BuildContext c, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(Divider(height: 1, thickness: 1, indent: 62, color: C.border(c, .06)));
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: _cardBox(c, radius: 24),
      child: Column(children: children),
    );
  }

  Widget _iconBox(BuildContext c, IconData i, Color color) => Container(
        width: 34, height: 34,
        decoration: BoxDecoration(color: color.withValues(alpha: .13), borderRadius: BorderRadius.circular(11)),
        child: Icon(i, size: 17, color: color),
      );

  /// Navigatsiya / oddiy satr (o'ng tomonda chevron yoki maxsus trailing).
  Widget _row(BuildContext c,
      {required IconData icon,
      required Color color,
      required String title,
      String? sub,
      Widget? trailing,
      bool danger = false,
      VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            _iconBox(c, icon, color),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: danger ? C.red : C.text(c))),
              if (sub != null) ...[
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11.5, color: C.muted(c, .45))),
              ],
            ])),
            if (trailing != null)
              trailing
            else if (onTap != null && !danger)
              Icon(Icons.chevron_right, size: 19, color: C.muted(c, .3)),
          ]),
        ),
      ),
    );
  }

  /// Toggle (switch) bilan satr.
  Widget _switchRow(BuildContext c,
      {required IconData icon,
      required Color color,
      required String title,
      required String sub,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    return _row(c, icon: icon, color: color, title: title, sub: sub,
        trailing: _Switch(value: value, onChanged: onChanged));
  }

  /// Mavzu satri — yorug'/qorong'i segmentli almashtirgich.
  Widget _themeRow(BuildContext c) {
    final dark = ThemeState.i.isDark;
    return _row(c,
        icon: Icons.contrast_rounded, color: C.violet,
        title: tr('profile.theme'), sub: dark ? tr('profile.themeDark') : tr('profile.themeLight'),
        trailing: _Segment(dark: dark));
  }

  BoxDecoration _cardBox(BuildContext c, {double radius = 20}) => BoxDecoration(
        color: C.card(c),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: C.border(c, .06)),
        boxShadow: C.isDark(c) ? null : C.shadow(c),
      );
}

/// Yorug'/qorong'i segmentli almashtirgich (sirg'aluvchi gradient tugma).
class _Segment extends StatelessWidget {
  final bool dark;
  const _Segment({required this.dark});

  @override
  Widget build(BuildContext context) {
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
            gradient: active ? C.grad : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: active ? Colors.white : C.muted(context, .5)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: C.fill(context, .08),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 46, height: 28,
        decoration: BoxDecoration(
          gradient: value ? C.grad : null,
          color: value ? null : C.fill(context, .12),
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .15), blurRadius: 4, offset: const Offset(0, 1))],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yengil "Aktiv qurilmalar" o'rin egallovchi ekrani (to'liq API hali yo'q).
class _DevicesScreen extends StatelessWidget {
  final int count;
  const _DevicesScreen({required this.count});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        body: SafeArea(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: C.text(context)),
                ),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('profile.devices'),
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: C.text(context))),
                  Text(tr('profile.sessions').replaceAll('{n}', '$count'), style: TextStyle(fontSize: 12, color: C.muted(context, .5))),
                ])),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: C.card(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.border(context, .06)),
                  boxShadow: C.isDark(context) ? null : C.shadow(context),
                ),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: C.tint(context, C.green), borderRadius: BorderRadius.circular(13)),
                    child: Icon(Icons.smartphone_rounded, size: 20, color: C.onGrn(context)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('profile.thisDevice'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.text(context))),
                    const SizedBox(height: 2),
                    Text(tr('profile.thisDeviceSub'), style: TextStyle(fontSize: 11.5, color: C.muted(context, .5))),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: C.tint(context, C.green), borderRadius: BorderRadius.circular(20)),
                    child: Text(tr('profile.active'), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: C.onGrn(context))),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(tr('profile.devicesSoon'),
                  style: TextStyle(fontSize: 12, color: C.muted(context, .4))),
            )),
          ]),
        ),
      );
}
