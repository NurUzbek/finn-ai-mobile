import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';

/// Profil + sozlamalar (mavzu, til) + xavfsizlik ma'lumotlari (TZ: qurilma, sessiya).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _f = Api.me();
  Future<void> _refresh() async => setState(() => _f = Api.me());

  static const _locales = {'uz': "O'zbekcha", 'ru': 'Русский', 'en': 'English'};
  String _locale = 'uz';

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getString('finn_locale');
    if (v != null && _locales.containsKey(v) && mounted) {
      setState(() => _locale = v);
    }
  }

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
              const Icon(Icons.language, size: 18, color: C.cyan),
              const SizedBox(width: 10),
              Text('Ilova tili', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: C.text(c))),
            ]),
          ),
          for (final e in _locales.entries)
            ListTile(
              title: Text(e.value, style: TextStyle(color: C.text(c), fontWeight: FontWeight.w600)),
              trailing: _locale == e.key ? const Icon(Icons.check_circle, color: C.green, size: 20) : null,
              onTap: () => Navigator.pop(c, e.key),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked == null) return;
    setState(() => _locale = picked);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('finn_locale', picked);
    if (!mounted) return;
    // Avvalgi snackbar'ni tozalaymiz — takrorlanib/yig'ilib qolmasligi uchun.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Til saqlandi: ${_locales[picked]}')));
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: C.card(c),
        title: Text('Chiqish', style: TextStyle(fontSize: 17, color: C.text(c))),
        content: Text('Hisobingizdan chiqmoqchimisiz?', style: TextStyle(fontSize: 13.5, color: C.muted(c, .7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Bekor')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Chiqish', style: TextStyle(color: C.red))),
        ],
      ),
    );
    if (ok != true) return;
    await Api.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          const ScreenHeader(title: 'Profil', icon: Icons.person, subtitle: 'Hisob va sozlamalar'),
          Expanded(
            child: Loader(
              future: _f,
              onRefresh: _refresh,
              builder: (d) {
                final u = d['user'] as Map<String, dynamic>;
                final initials = (u['name'] as String).trim().isEmpty
                    ? '?' : (u['name'] as String).trim().substring(0, 1).toUpperCase();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    // ── Profil kartasi ──
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: _cardBox(context),
                      child: Row(children: [
                        Container(
                          width: 62, height: 62,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [C.blue, C.cyan]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(child: Text(initials,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(u['name'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text(context))),
                          const SizedBox(height: 3),
                          Text('+${u['phone']}', style: TextStyle(fontSize: 12.5, color: C.muted(context, .5))),
                          const SizedBox(height: 2),
                          Text('${u['orgs_count']} tashkilot', style: const TextStyle(fontSize: 11.5, color: C.cyan)),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 18),

                    // ── SOZLAMALAR ──
                    _section('SOZLAMALAR'),
                    _themeTile(context),
                    _tile(context, Icons.language, 'Til', _locales[_locale] ?? "O'zbekcha", C.cyan,
                        onTap: _pickLocale),

                    const SizedBox(height: 14),
                    _section('XAVFSIZLIK'),
                    _tile(context, Icons.devices_other, 'Aktiv qurilmalar', '${u['devices_count']} ta faol', C.sky),
                    _tile(context, Icons.timer_outlined, 'Sessiya muddati', '3 daqiqa harakatsizlik', C.amber),
                    _tile(context, Icons.sms_outlined, 'Yangi qurilma ogohlantirishi', 'SMS yoqilgan', C.green),

                    const SizedBox(height: 14),
                    _section('HISOB'),
                    _tile(context, Icons.email_outlined, 'Email', u['email'] ?? '—', C.violet),
                    _tile(context, Icons.workspace_premium_outlined, 'Tarif', 'Ko\'rish va to\'lash', C.amber,
                        onTap: () => openSubscription(context)),

                    const SizedBox(height: 20),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, size: 18, color: C.red),
                        label: const Text('Chiqish', style: TextStyle(color: C.red, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: C.red.withValues(alpha: .35)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text('FINN AI v1.0.0 · ONEDESK GROUP MChJ',
                        style: TextStyle(fontSize: 10.5, color: C.muted(context, .3)))),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  BoxDecoration _cardBox(BuildContext context, {double radius = 18}) => BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: C.border(context, .06)),
        boxShadow: C.isDark(context)
            ? null
            : [BoxShadow(color: C.inkLight.withValues(alpha: .04), blurRadius: 12, offset: const Offset(0, 4))],
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
        child: Builder(builder: (c) => Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900,
            letterSpacing: 1.1, color: C.muted(c, .4)))),
      );

  /// Mavzu almashtirgich — yorug'/qorong'i segmentli tugma.
  Widget _themeTile(BuildContext context) {
    final dark = ThemeState.i.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: _cardBox(context, radius: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: C.violet.withValues(alpha: .13), borderRadius: BorderRadius.circular(10)),
          child: Icon(dark ? Icons.dark_mode : Icons.light_mode, size: 16, color: C.violet),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mavzu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text(context))),
          const SizedBox(height: 2),
          Text(dark ? 'Qorong\'i rejim' : 'Yorug\' rejim',
              style: TextStyle(fontSize: 11, color: C.muted(context, .45))),
        ])),
        _segment(context),
      ]),
    );
  }

  Widget _segment(BuildContext context) {
    final dark = ThemeState.i.isDark;
    Widget opt(bool isDark, IconData icon) {
      final active = dark == isDark;
      return GestureDetector(
        onTap: () => ThemeState.i.setMode(isDark ? ThemeMode.dark : ThemeMode.light),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: active ? const LinearGradient(colors: [C.blue, C.cyan]) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16,
              color: active ? Colors.white : C.muted(context, .5)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: C.fill(context, .05),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        opt(false, Icons.light_mode),
        const SizedBox(width: 3),
        opt(true, Icons.dark_mode),
      ]),
    );
  }

  Widget _tile(BuildContext context, IconData i, String title, String sub, Color c, {VoidCallback? onTap}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: _cardBox(context, radius: 14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(10)),
                  child: Icon(i, size: 16, color: c),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text(context))),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 11, color: C.muted(context, .45))),
                ])),
                if (onTap != null)
                  Icon(Icons.chevron_right, size: 18, color: C.muted(context, .3)),
              ]),
            ),
          ),
        ),
      );
}
