import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Shaxsni tasdiqlash (OneID) — dizayn: finn-app-full oneid.html #v-ident.
/// OneID hisob darajasini tasdiqlangan darajaga o'tkazish yo'riqnomasi.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});
  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  late Future<Map<String, dynamic>> _f = Api.me();
  Future<void> _refresh() async => setState(() => _f = Api.me());

  Future<void> _openEgov() async {
    final uri = Uri.parse('https://id.egov.uz');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        body: SafeArea(
          child: Column(children: [
            ScreenHeader(title: tr('ident.title'), icon: Icons.verified_user_outlined, subtitle: tr('ident.sub')),
            Expanded(
              child: Loader(
                future: _f,
                onRefresh: _refresh,
                builder: (d) {
                  final id = (d['identity'] as Map?) ?? const {};
                  final connected = id['connected'] == true;
                  final verified = id['verified'] == true;
                  final name = (id['fullname'] ?? '').toString().trim();
                  final jshshir = (id['jshshir'] ?? '').toString();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
                    children: [
                      StaggerIn(index: 0, child: _hero(verified)),
                      const SizedBox(height: 4),
                      _eyebrow(tr('ident.steps')),
                      StaggerIn(index: 1, child: _step1(connected, name, jshshir)),
                      const SizedBox(height: 10),
                      StaggerIn(index: 2, child: _step2(verified)),
                      _eyebrow(tr('ident.methods')),
                      StaggerIn(index: 3, child: _group([
                        _row(Icons.credit_card_rounded, C.brand, tr('ident.mBank'), tr('ident.mBankSub')),
                        _row(Icons.lock_outline_rounded, C.violet, tr('ident.mEri'), tr('ident.mEriSub')),
                        _row(Icons.account_balance_rounded, C.green, tr('ident.mDxm'), tr('ident.mDxmSub')),
                      ])),
                      _eyebrow(tr('ident.why')),
                      StaggerIn(index: 4, child: _group([
                        _row(Icons.payments_outlined, C.brand, tr('ident.whyPay'), tr('ident.whyPaySub')),
                        _row(Icons.group_add_outlined, C.violet, tr('ident.whyTeam'), tr('ident.whyTeamSub')),
                        _row(Icons.shield_outlined, C.green, tr('ident.whyProtect'), tr('ident.whyProtectSub')),
                      ])),
                      const SizedBox(height: 16),
                      Text(tr('ident.note'),
                          style: TextStyle(fontSize: 12, height: 1.6, color: C.muted(context, .5))),
                    ],
                  );
                },
              ),
            ),
          ]),
        ),
      );

  Widget _hero(bool verified) {
    final c = verified ? C.green : C.amber;
    final on = verified ? C.onGrn(context) : C.onAmb(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(children: [
        SizedBox(
          width: 96, height: 96,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: verified ? 1 : .58),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => CustomPaint(size: const Size(96, 96), painter: _Ring(v, c, C.fill(context, .08))),
            ),
            Container(
              width: 52, height: 52, alignment: Alignment.center,
              decoration: BoxDecoration(color: C.tint(context, c), shape: BoxShape.circle),
              child: Icon(verified ? Icons.verified_rounded : Icons.shield_outlined, color: on, size: 26),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Text(verified ? tr('ident.statusVerified') : tr('ident.statusIncomplete'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -.3, color: C.text(context))),
        const SizedBox(height: 8),
        Text(verified ? tr('ident.heroDescOk') : tr('ident.heroDesc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.55, color: C.muted(context, .6))),
      ]),
    );
  }

  Widget _step1(bool connected, String name, String jshshir) => _stepShell(
        done: connected,
        badge: connected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        color: connected ? C.green : C.muted(context, .4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('ident.step1'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: C.text(context))),
          const SizedBox(height: 3),
          Text(connected ? tr('ident.step1sub') : tr('ident.step1notConnected'),
              style: TextStyle(fontSize: 12, height: 1.4, color: C.muted(context, .5))),
          if (connected) ...[
            const SizedBox(height: 12),
            _kv(tr('ident.fio'), name.isEmpty ? '—' : name),
            _kv(tr('ident.jshshir'), jshshir.isEmpty ? '—' : jshshir),
            _kv(tr('ident.level'), tr('ident.levelBasic'), valColor: C.onAmb(context)),
          ],
        ]),
      );

  Widget _step2(bool verified) => _stepShell(
        done: verified,
        badge: verified ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        color: verified ? C.green : C.brand,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('ident.step2'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: C.text(context))),
          const SizedBox(height: 4),
          Text(tr('ident.step2sub'), style: TextStyle(fontSize: 12, height: 1.5, color: C.muted(context, .55))),
          if (!verified) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _openEgov,
              child: Container(
                height: 48, alignment: Alignment.center,
                decoration: BoxDecoration(gradient: C.grad, borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .3), blurRadius: 16, offset: const Offset(0, 6))]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.open_in_new_rounded, size: 17, color: Colors.white),
                  const SizedBox(width: 9),
                  Text(tr('ident.verifyBtn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                ]),
              ),
            ),
            const SizedBox(height: 9),
            Text(tr('ident.verifyHint'), style: TextStyle(fontSize: 11.5, height: 1.4, color: C.muted(context, .45))),
          ],
        ]),
      );

  Widget _stepShell({required bool done, required Widget badge, required Color color, required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: done ? C.green.withValues(alpha: .35) : C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 26, height: 26, alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: badge),
          const SizedBox(width: 13),
          Expanded(child: child),
        ]),
      );

  Widget _kv(String k, String v, {Color? valColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(k, style: TextStyle(fontSize: 12.5, color: C.muted(context, .5))),
          const Spacer(),
          Text(v, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: valColor ?? C.text(context))),
        ]),
      );

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: C.border(context, .06), indent: 58),
            rows[i],
          ],
        ]),
      );

  Widget _row(IconData ic, Color c, String title, String sub) => Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 34, height: 34, alignment: Alignment.center,
              decoration: BoxDecoration(color: C.tint(context, c), borderRadius: BorderRadius.circular(11)),
              child: Icon(ic, color: c, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: C.text(context))),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 11.5, height: 1.35, color: C.muted(context, .45))),
          ])),
        ]),
      );

  Widget _eyebrow(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
        child: Row(children: [
          Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: .5, color: C.muted(context, .4))),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: C.border(context))),
        ]),
      );
}

class _Ring extends CustomPainter {
  final double frac;
  final Color color, track;
  _Ring(this.frac, this.color, this.track);
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = track..strokeCap = StrokeCap.round);
    if (frac > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * frac, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = color..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_Ring o) => o.frac != frac || o.color != color;
}
