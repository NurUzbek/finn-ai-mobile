import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';
import '../widgets/locked.dart';
import 'subscription_screen.dart';

const _g1 = Color(0xFF246BFD);
const _g2 = Color(0xFF00C6FF);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _f = Api.dashboard();
  Future<void> _refresh() async => setState(() => _f = Api.dashboard());

  String _greet() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Xayrli tong';
    if (h < 18) return 'Xayrli kun';
    return 'Xayrli kech';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _g1));
              }
              final d = snap.data ?? {};
              if (d['ok'] != true) {
                return _err();
              }
              final s = (d['stats'] as Map?) ?? {};
              final orgs = ((d['organizations'] as List?) ?? []).cast<dynamic>();
              final name = (d['user_name'] ?? '').toString().trim();
              final first = name.isEmpty ? '' : name.split(' ').first;
              final totalBalance = orgs.fold<double>(0, (a, o) => a + ((o['balance'] ?? 0) as num).toDouble());
              final overdue = ((s['overdue_count'] ?? 0) as num).toInt();
              final clean = (orgs.length - overdue).clamp(0, orgs.length);
              final debt = (s['debts_total'] ?? 0) as num;
              final penalty = (s['penalty_total'] ?? 0) as num;
              final unread = ((s['unread_notifications'] ?? 0) as num).toInt();

              return ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  StaggerIn(index: 0, child: _header(first, unread)),
                  const SizedBox(height: 24),
                  StaggerIn(index: 1, child: _balance(totalBalance, orgs.length, clean, overdue)),
                  const SizedBox(height: 24),
                  StaggerIn(index: 2, child: _quick()),
                  if (overdue > 0) ...[
                    const SizedBox(height: 24),
                    StaggerIn(index: 3, child: _alert(overdue)),
                  ],
                  const SizedBox(height: 24),
                  StaggerIn(index: 4, child: _companies(orgs.length, clean)),
                  const SizedBox(height: 12),
                  StaggerIn(index: 5, child: Row(children: [
                    Expanded(child: _stat('Umumiy qarz', debt, 'so\'m', Icons.trending_down_rounded, C.red, up: false)),
                    const SizedBox(width: 12),
                    Expanded(child: _stat('Jami penya', penalty, 'so\'m', Icons.warning_amber_rounded, C.amber, up: true)),
                  ])),
                  const SizedBox(height: 12),
                  StaggerIn(index: 6, child: _notif(unread)),
                  const SizedBox(height: 24),
                  StaggerIn(index: 7, child: _ai()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _err() => ListView(children: [
        const SizedBox(height: 220),
        Center(child: Column(children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: C.muted(context, .35)),
          const SizedBox(height: 12),
          Text('Server bilan aloqa yo\'q', style: TextStyle(color: C.muted(context, .6))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _refresh, child: const Text('Qayta urinish')),
        ])),
      ]);

  // ── Soft shadow (yumshoq, tinted — chegara yo'q) ──
  List<BoxShadow> _soft(BuildContext c, {Color? tint, double y = 18, double blur = 40, double a = .10}) => [
        BoxShadow(color: (tint ?? const Color(0xFF1B2A4A)).withValues(alpha: C.isDark(c) ? a * 2 : a), blurRadius: blur, offset: Offset(0, y)),
      ];

  Widget _iconBtn(IconData ic, {int badge = 0, VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: C.card(context), borderRadius: BorderRadius.circular(15), boxShadow: _soft(context, blur: 20, y: 8, a: .07)),
          child: Stack(alignment: Alignment.center, children: [
            Icon(ic, size: 20, color: C.text(context)),
            if (badge > 0)
              Positioned(top: 10, right: 11, child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x668B5CF6), blurRadius: 8)]),
              )),
          ]),
        ),
      );

  Widget _header(String first, int unread) => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_greet()} 👋', style: TextStyle(fontSize: 15, color: C.muted(context, .55), fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(first.isEmpty ? 'FINN' : first, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.8, color: C.text(context), height: 1.05)),
          const SizedBox(height: 4),
          Text('Biznesingiz bugun nazoratda', style: TextStyle(fontSize: 13.5, color: C.muted(context, .5))),
        ])),
        _iconBtn(Icons.grid_view_rounded, onTap: () => homeScaffoldKey.currentState?.openDrawer()),
        const SizedBox(width: 10),
        _iconBtn(Icons.notifications_none_rounded, badge: unread),
      ]);

  Widget _balance(double bal, int orgs, int clean, int overdue) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_g1, _g2], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: _g1.withValues(alpha: .38), blurRadius: 40, offset: const Offset(0, 18))],
        ),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22)),
              const SizedBox(height: 18),
              const Text('Umumiy balans', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: bal), duration: const Duration(milliseconds: 1200), curve: Curves.easeOutCubic,
                builder: (_, v, __) => RichText(text: TextSpan(children: [
                  TextSpan(text: money(v), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1)),
                  const TextSpan(text: '  so\'m', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600)),
                ])),
              ),
            ])),
            SizedBox(width: 84, height: 84, child: CustomPaint(painter: _RingPainter(orgs == 0 ? 0 : clean / orgs), child: Center(
              child: Text('${orgs == 0 ? 0 : (clean / orgs * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ))),
          ]),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: .16)),
          const SizedBox(height: 16),
          Row(children: [
            _bchip('$orgs', 'firma'),
            _bdiv(), _bchip('$clean', 'sog\'lom'),
            _bdiv(), _bchip('$overdue', 'kechik'),
          ]),
        ]),
      );

  Widget _bchip(String v, String l) => Expanded(child: Column(children: [
        Text(v, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w500)),
      ]));
  Widget _bdiv() => Container(width: 1, height: 30, color: Colors.white.withValues(alpha: .16));

  Widget _quick() {
    final items = [
      (ic: Icons.receipt_long_rounded, l: 'Soliq', c: _g1),
      (ic: Icons.apartment_rounded, l: 'Firmalar', c: const Color(0xFF8B5CF6)),
      (ic: Icons.insights_rounded, l: 'Analitika', c: C.green),
      (ic: Icons.auto_awesome_rounded, l: 'AI', c: C.cyan),
    ];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: items.map((i) => Column(children: [
          _MagneticTap(child: Container(
            width: 62, height: 62,
            decoration: BoxDecoration(color: i.c.withValues(alpha: C.isDark(context) ? .18 : .12), borderRadius: BorderRadius.circular(20)),
            child: Icon(i.ic, color: i.c, size: 26),
          )),
          const SizedBox(height: 9),
          Text(i.l, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: C.muted(context, .75))),
        ])).toList());
  }

  Widget _alert(int overdue) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: C.red.withValues(alpha: C.isDark(context) ? .13 : .07),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Container(width: 46, height: 46, decoration: BoxDecoration(color: C.red.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.priority_high_rounded, color: C.red, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$overdue ta muddati o\'tgan to\'lov', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text(context))),
            const SizedBox(height: 3),
            Text('Penya oshib bormoqda — ko\'rib chiqing', style: TextStyle(fontSize: 12.5, color: C.muted(context, .6))),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 15, color: C.red),
        ]),
      );

  Widget _card(BuildContext c, {required Widget child, EdgeInsets? pad}) => Container(
        padding: pad ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.card(c), borderRadius: BorderRadius.circular(24), boxShadow: _soft(c)),
        child: child,
      );

  Widget _companies(int count, int clean) => _card(context, child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: _g1.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.apartment_rounded, color: _g1, size: 26)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Firmalar', style: TextStyle(fontSize: 14, color: C.muted(context, .55), fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: C.text(context), height: 1, letterSpacing: -1)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: C.green.withValues(alpha: .14), borderRadius: BorderRadius.circular(999)),
            child: Row(children: [Icon(Icons.check_circle_rounded, size: 15, color: C.green), const SizedBox(width: 5), Text('$clean sog\'lom', style: TextStyle(color: C.green, fontWeight: FontWeight.w700, fontSize: 12.5))])),
      ]));

  Widget _stat(String label, num val, String unit, IconData ic, Color col, {required bool up}) => _card(context, pad: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: col.withValues(alpha: .13), borderRadius: BorderRadius.circular(12)), child: Icon(ic, color: col, size: 19)),
          const Spacer(),
          Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded, size: 16, color: col),
        ]),
        const SizedBox(height: 14),
        Text(label, style: TextStyle(fontSize: 12.5, color: C.muted(context, .55))),
        const SizedBox(height: 3),
        TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: val.toDouble()), duration: const Duration(milliseconds: 1100), curve: Curves.easeOutCubic,
            builder: (_, v, __) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: RichText(text: TextSpan(children: [
              TextSpan(text: money(v), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: C.text(context), letterSpacing: -.5)),
              TextSpan(text: ' $unit', style: TextStyle(fontSize: 12, color: C.muted(context, .5), fontWeight: FontWeight.w600)),
            ])))),
      ]));

  Widget _notif(int n) => _card(context, pad: const EdgeInsets.all(18), child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: .14), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: .25), blurRadius: 14)]),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF8B5CF6), size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Text('O\'qilmagan bildirishnoma', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: C.text(context)))),
        Text('$n', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6))),
      ]));

  Widget _ai() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_g1.withValues(alpha: C.isDark(context) ? .18 : .1), C.cyan.withValues(alpha: C.isDark(context) ? .12 : .07)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(26),
          boxShadow: _soft(context, tint: _g1, a: .12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [_g1, _g2]), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21)),
            const SizedBox(width: 12),
            Text('AI tahlil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text(context))),
          ]),
          const SizedBox(height: 16),
          Text('AI 2 ta soliq riskini aniqladi.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.text(context), height: 1.35)),
          const SizedBox(height: 6),
          Text('Tavsiya: eng yaqin muddatni bugun yoping — penya to\'xtaydi.', style: TextStyle(fontSize: 13.5, color: C.muted(context, .65), height: 1.45)),
          const SizedBox(height: 18),
          _MagneticTap(child: Container(
            height: 46,
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [_g1, _g2]), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: _g1.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 8))]),
            child: const Center(child: Text('Ko\'rib chiqish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
          )),
        ]),
      );
}

/// Balans kartadagi doiraviy analitika halqasi.
class _RingPainter extends CustomPainter {
  final double pct;
  _RingPainter(this.pct);
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    final bg = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = Colors.white.withValues(alpha: .22)..strokeCap = StrokeCap.round;
    final fg = Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = Colors.white..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, bg);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * pct.clamp(0, 1), false, fg);
  }
  @override
  bool shouldRepaint(covariant _RingPainter o) => o.pct != pct;
}

/// Bosilganda arziyol siqiladigan (magnetic) effekt.
class _MagneticTap extends StatefulWidget {
  final Widget child;
  const _MagneticTap({required this.child});
  @override
  State<_MagneticTap> createState() => _MagneticTapState();
}

class _MagneticTapState extends State<_MagneticTap> {
  double _s = 1;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) { HapticFeedback.selectionClick(); setState(() => _s = .93); },
        onTapUp: (_) => setState(() => _s = 1),
        onTapCancel: () => setState(() => _s = 1),
        child: AnimatedScale(scale: _s, duration: const Duration(milliseconds: 130), curve: Curves.easeOut, child: widget.child),
      );
}
