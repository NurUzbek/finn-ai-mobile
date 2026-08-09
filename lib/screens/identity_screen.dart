import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Shaxsni tasdiqlash (OneID) — HTML prototip `#v-ident` bilan 1:1.
/// PUSH ekran: OneID hisob darajasini tasdiqlangan darajaga o'tkazish yo'riqnomasi.
class IdentityScreen extends StatefulWidget {
  const IdentityScreen({super.key});
  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  late Future<Map<String, dynamic>> _f = Api.me();
  Future<void> _refresh() async => setState(() => _f = Api.me());

  /// Shaxsni OneID orqali tasdiqlash — LOGIN bilan bir xil OAuth oqimi
  /// (tashqi brauzer → finnai://oneid?token=). Backend attachAndLogin PINFL/telefon
  /// bo'yicha DUBLIKAT akkauntlarni MERGE qiladi, so'ng tasdiqlangan akkaunt
  /// token'i deep-link bilan qaytadi (main.dart _onDeepLink). id.egov.uz kabinetiga
  /// tashlab qo'ymaydi.
  Future<void> _openEgov() async {
    final uri = Uri.parse('https://finn.uz/auth/oneid?app=1');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('ident.title'),
      subtitle: tr('ident.sub'),
      showNav: false,
      leading: _backBtn(t, () => Navigator.of(context).maybePop()),
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
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final id = (d['identity'] as Map?) ?? const {};
    final connected = id['connected'] == true;
    final verified = id['verified'] == true;
    final name = (id['fullname'] ?? '').toString().trim();
    final jshshir = (id['jshshir'] ?? '').toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaggerIn(index: 0, child: _hero(t, verified)),
        _eyebrow(t, tr('ident.steps')),
        StaggerIn(index: 1, child: _step1(t, connected, name, jshshir)),
        const SizedBox(height: 10),
        StaggerIn(index: 2, child: _step2(t, verified, connected)),
        _eyebrow(t, tr('ident.methods')),
        StaggerIn(
            index: 3,
            child: _group(t, [
              _row(t, Icons.credit_card_rounded, t.blue, t.tBlu,
                  tr('ident.mBank'), tr('ident.mBankSub')),
              _row(t, Icons.lock_outline_rounded, t.onPur, t.tPur,
                  tr('ident.mEri'), tr('ident.mEriSub')),
              _row(t, Icons.account_balance_rounded, t.onGrn, t.tGrn,
                  tr('ident.mDxm'), tr('ident.mDxmSub')),
            ])),
        _eyebrow(t, tr('ident.why')),
        StaggerIn(
            index: 4,
            child: _group(t, [
              _row(t, Icons.credit_card_rounded, t.blue, t.tBlu,
                  tr('ident.whyPay'), tr('ident.whyPaySub')),
              _row(t, Icons.people_outline, t.onPur, t.tPur,
                  tr('ident.whyTeam'), tr('ident.whyTeamSub')),
              _row(t, Icons.verified_user_outlined, t.onGrn, t.tGrn,
                  tr('ident.whyProtect'), tr('ident.whyProtectSub')),
            ])),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(tr('ident.note'), style: FinnText.rowSub(t.ink4)),
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
            FilledButton(
                onPressed: _refresh, child: Text(tr('common.retry'))),
          ]),
        ),
      );

  /// .back — 36×36, radius 12, chegara line, soyasiz
  Widget _backBtn(FinnTokens t, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: t.line),
          ),
          child: Icon(Icons.arrow_back_rounded, size: 17, color: t.ink2),
        ),
      );

  // ─────────────────────── HERO / SHIELD (.id-hero) ───────────────────────
  // Kartasiz, markazlashtirilgan. Halqa r40 · stroke 7 · 0→.502.
  Widget _hero(FinnTokens t, bool verified) {
    final ring = verified ? t.green : t.amber;
    final on = verified ? t.onGrn : t.onAmb;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 6),
      child: Column(children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(alignment: Alignment.center, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: verified ? 1 : .502),
              duration: const Duration(milliseconds: 1200),
              curve: FinnTokens.ease,
              builder: (_, v, __) => CustomPaint(
                size: const Size(96, 96),
                painter:
                    RingPainter(progress: v, color: ring, track: t.key, stroke: 7),
              ),
            ),
            Icon(
                verified ? Icons.verified_user_rounded : Icons.shield_outlined,
                color: on,
                size: 26),
          ]),
        ),
        const SizedBox(height: 16),
        Text(
            verified ? tr('ident.statusVerified') : tr('ident.statusIncomplete'),
            textAlign: TextAlign.center,
            style: FinnText.cardTitle(on)),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: Text(verified ? tr('ident.heroDescOk') : tr('ident.heroDesc'),
              textAlign: TextAlign.center, style: FinnText.body(t.ink2)),
        ),
      ]),
    );
  }

  // ─────────────────────── QADAMLAR (.idstep) ───────────────────────
  Widget _step1(FinnTokens t, bool connected, String name, String jshshir) =>
      _stepShell(
        t,
        done: connected,
        now: !connected,
        badge: connected
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : Text('1', style: FinnText.rowValue(connected ? Colors.white : t.ink2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('ident.step1'), style: FinnText.rowValue(t.ink)),
          const SizedBox(height: 4),
          Text(connected ? tr('ident.step1sub') : tr('ident.step1notConnected'),
              style: FinnText.rowSub(t.ink3)),
          if (connected) ...[
            _kv(t, tr('ident.fio'), name.isEmpty ? '—' : name, first: true),
            _kv(t, tr('ident.jshshir'), jshshir.isEmpty ? '—' : jshshir),
            _kv(t, tr('ident.level'), tr('ident.levelBasic'), valColor: t.onAmb),
          ],
        ]),
      );

  Widget _step2(FinnTokens t, bool verified, bool connected) => _stepShell(
        t,
        done: verified,
        now: !verified,
        badge: verified
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : Text('2', style: FinnText.rowValue(Colors.white)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('ident.step2'), style: FinnText.rowValue(t.ink)),
          const SizedBox(height: 4),
          Text(tr('ident.step2sub'), style: FinnText.rowSub(t.ink3)),
          if (!verified) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _openEgov,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    gradient: FinnTokens.brand,
                    borderRadius: BorderRadius.circular(FinnTokens.rMd),
                    boxShadow: [
                      BoxShadow(
                          color: t.blue2.withValues(alpha: .28),
                          blurRadius: 20,
                          offset: const Offset(0, 7))
                    ]),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.open_in_new_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 9),
                  Text(tr('ident.verifyBtn'),
                      style: FinnText.button(Colors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Text(tr('ident.verifyHint'), style: FinnText.rowSub(t.ink3)),
          ],
        ]),
      );

  /// .idstep — radius r-xl, chegara: now→blue, aks holda line
  Widget _stepShell(FinnTokens t,
          {required bool done,
          required bool now,
          required Widget badge,
          required Widget child}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: now ? t.blue : t.line),
          boxShadow: t.sh,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: done ? t.green : (now ? t.blue : t.key),
                  shape: BoxShape.circle),
              child: badge),
          const SizedBox(width: 13),
          Expanded(child: child),
        ]),
      );

  /// .is-kv — yuqori chegara (line2), 7px padding, birinchi kv 12px oraliq
  Widget _kv(FinnTokens t, String k, String v,
          {bool first = false, Color? valColor}) =>
      Padding(
        padding: EdgeInsets.only(top: first ? 12 : 8),
        child: Container(
          decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.line2, width: 1))),
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Text(k, style: FinnText.rowSub(t.ink3)),
            const Spacer(),
            Text(v, style: FinnText.chip(valColor ?? t.ink)),
          ]),
        ),
      );

  // ─────────────────────── GURUHLAR (.grp / .st) ───────────────────────
  Widget _group(FinnTokens t, List<Widget> rows) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: t.line),
          boxShadow: t.sh,
        ),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.line2),
            rows[i],
          ],
        ]),
      );

  Widget _row(FinnTokens t, IconData ic, Color c, Color tint, String title,
          String sub) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(ic, color: c, size: 17)),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title, style: FinnText.rowTitle(t.ink)),
                const SizedBox(height: 2),
                Text(sub, style: FinnText.rowSub(t.ink3)),
              ])),
        ]),
      );

  /// .eyebrow — margin 24 0 12
  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );
}
