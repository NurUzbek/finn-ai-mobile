import 'package:flutter/material.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// Profil + xavfsizlik ma'lumotlari (TZ: aktiv qurilmalar, sessiya siyosati).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _f = Api.me();
  Future<void> _refresh() async => setState(() => _f = Api.me());

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: C.cardDark,
        title: const Text('Chiqish', style: TextStyle(fontSize: 17)),
        content: const Text('Hisobingizdan chiqmoqchimisiz?', style: TextStyle(fontSize: 13.5)),
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
          const ScreenHeader(title: 'Profil', icon: Icons.person, subtitle: 'Hisob va xavfsizlik'),
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
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: C.cardDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: .06)),
                      ),
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
                          Text(u['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text('+${u['phone']}', style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: .5))),
                          const SizedBox(height: 2),
                          Text('${u['orgs_count']} tashkilot', style: TextStyle(fontSize: 11.5, color: C.cyan.withValues(alpha: .8))),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 18),

                    _section('XAVFSIZLIK'),
                    _tile(Icons.devices_other, 'Aktiv qurilmalar', '${u['devices_count']} ta faol', C.sky),
                    _tile(Icons.timer_outlined, 'Sessiya muddati', '3 daqiqa harakatsizlik', C.amber),
                    _tile(Icons.sms_outlined, 'Yangi qurilma ogohlantirishi', 'SMS yoqilgan', C.green),

                    const SizedBox(height: 14),
                    _section('HISOB'),
                    _tile(Icons.email_outlined, 'Email', u['email'] ?? '—', C.violet),
                    _tile(Icons.language, 'Til', (u['locale'] ?? 'uz').toString().toUpperCase(), C.cyan),

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
                        style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: .28)))),
                  ],
                );
              },
            ),
          ),
        ]),
      );

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 0, 8),
        child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900,
            letterSpacing: 1.1, color: Colors.white.withValues(alpha: .35))),
      );

  Widget _tile(IconData i, String title, String sub, Color c) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: C.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: .05)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: c.withValues(alpha: .13), borderRadius: BorderRadius.circular(10)),
            child: Icon(i, size: 16, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: .42))),
          ])),
        ]),
      );
}
