import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api.dart';
import '../services/endpoints.dart';
import '../services/i18n.dart';
import '../services/lock.dart';
import '../theme/finn_tokens.dart';
import 'home_shell.dart';
import 'pin_screen.dart';

// OneID brend belgisi rangi (FINN dizayn tizimiga tegishli emas — davlat markasi).
const _oneidBlue = Color(0xFF0B57A4);

/// SMS-kod orqali kirish (2FA) — FINN dizayn tizimi (tokens + FinnText).
/// MAXSUS auth ekrani: markazlashgan kontent, o'z Scaffold'i (header/nav yo'q).
class LoginScreen extends StatefulWidget {
  final bool expired;
  const LoginScreen({super.key, this.expired = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  bool _codeStep = false, _busy = false;
  String? _err;
  int _seconds = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _code.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _seconds = 59);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _seconds--);
      if (_seconds <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return setState(() => _err = tr('login.errPhoneIncomplete'));
    setState(() { _busy = true; _err = null; });
    final r = await Api.sendCode('998$digits');
    if (!mounted) return;
    setState(() { _busy = false; _codeStep = r['ok'] == true; _err = r['ok'] == true ? null : r['message']; });
    if (r['ok'] == true) {
      _startCountdown();
      await Future.delayed(const Duration(milliseconds: 250));
      _codeFocus.requestFocus();
    }
  }

  Future<void> _verify() async {
    if (_code.text.length != 4) return;
    setState(() { _busy = true; _err = null; });
    final r = await Api.verify('998${_phone.text.replaceAll(RegExp(r'\D'), '')}', _code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r['ok'] == true) {
      TextInput.finishAutofillContext();
      _afterAuth();
    } else {
      setState(() { _err = r['message'] ?? tr('login.errWrongCode'); _code.clear(); });
    }
  }

  Future<void> _afterAuth() async {
    final hasPin = await Lock.hasPin();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => hasPin ? const HomeShell() : const PinScreen(mode: 'set')), (_) => false);
  }

  /// OneID — TASHQI BRAUZERDA (Chrome) ochamiz. WebView id.egov.uz'da ishonchsiz
  /// edi (kabinetda qolib "Ulanmadi"). Brauzer cookie/sessiyani to'g'ri saqlaydi;
  /// oxirida `finnai://oneid?token=` deep-link bilan ilovaga qaytadi
  /// (main.dart _onDeepLink token'ni saqlab HomeShell'ga o'tadi).
  Future<void> _oneid() async {
    final uri = Uri.parse(Ep.oneidApp);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('login.oneidFailed'))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('login.oneidFailed'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: t.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // Ambient glow orblari (device::before / ::after)
        Positioned(top: -150, left: -60, child: _orb(t.blue.withValues(alpha: dark ? .22 : .15), 460, 380)),
        Positioned(bottom: -120, right: -90, child: _orb(t.cyan.withValues(alpha: dark ? .12 : .10), 380, 360)),
        SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: _codeStep ? _smsView(context) : _phoneView(context),
          ),
        ),
      ]),
    );
  }

  Widget _orb(Color c, double w, double h) => IgnorePointer(child: Container(
        width: w, height: h,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c, c.withValues(alpha: 0)], stops: const [0, .66])),
      ));

  // ══════════════════════ KIRISH ══════════════════════
  Widget _phoneView(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
        key: const ValueKey('phone'),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 56),
            // Brend belgisi — logo.png (dizayn soyasi bilan)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FinnTokens.rLg),
                boxShadow: t.sh,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(FinnTokens.rLg),
                child: Image.asset('assets/logo.png', width: 60, height: 60, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 28),
            Text(tr('login.eyebrow'), style: FinnText.eyebrow(t.ink3)),
            const SizedBox(height: 12),
            Text(tr('login.welcome'), style: FinnText.screenTitle(t.ink).copyWith(fontSize: 30, letterSpacing: -1.2)),
            const SizedBox(height: 10),
            Text(tr('login.subtitle'), style: FinnText.body(t.ink2)),
            const SizedBox(height: 30),
            if (widget.expired) _banner(Icons.timer_off_rounded, t.amber, tr('login.expired')),
            if (_err != null) _banner(Icons.error_outline_rounded, t.red, _err!),
            Text(tr('login.phoneLabel'), style: FinnText.screenSub(t.ink2)),
            const SizedBox(height: 8),
            _field(child: Row(children: [
              Icon(Icons.smartphone_rounded, size: 19, color: t.ink3),
              const SizedBox(width: 12),
              Text('+998', style: FinnText.rowValue(t.ink3).copyWith(fontSize: 16)),
              const SizedBox(width: 12),
              Container(width: 1, height: 22, color: t.line),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                style: FinnText.rowValue(t.ink).copyWith(fontSize: 17, letterSpacing: 1),
                decoration: InputDecoration(hintText: '90 123 45 67', hintStyle: FinnText.rowValue(t.ink4).copyWith(fontSize: 17, letterSpacing: 1, fontWeight: FontWeight.w500), border: InputBorder.none, isCollapsed: true),
                onChanged: (_) { if (_err != null) setState(() => _err = null); },
                onSubmitted: (_) => _send(),
              )),
            ])),
            const SizedBox(height: 20),
            _cta(_busy ? null : _send, tr('login.sendCode'), Icons.arrow_forward_rounded),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Divider(color: t.line)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text(tr('login.or'), style: FinnText.label(t.ink3).copyWith(fontSize: 11))),
              Expanded(child: Divider(color: t.line)),
            ]),
            const SizedBox(height: 20),
            // OneID — alt uslub (karta foni + kichik ko'k OneID belgisi)
            _Magnetic(child: GestureDetector(
              onTap: _busy ? null : _oneid,
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(FinnTokens.rMd),
                  border: Border.all(color: t.line),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 40, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(FinnTokens.rSm),
                      border: Border.all(color: _oneidBlue.withValues(alpha: .14)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Image.asset('assets/oneid_blue.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 11),
                  Text(tr('login.oneidLogin'), style: FinnText.button(t.ink)),
                ]),
              ),
            )),
            const SizedBox(height: 11),
            Center(child: Text(tr('login.orgsAutoDetect'), style: FinnText.screenSub(t.ink3))),
            const Spacer(),
            const SizedBox(height: 24),
            Center(child: Text.rich(TextSpan(
              style: FinnText.screenSub(t.ink3).copyWith(height: 1.6),
              children: [
                TextSpan(text: tr('login.legal1')),
                TextSpan(text: tr('login.legalPrivacy'), style: const TextStyle(decoration: TextDecoration.underline)),
                TextSpan(text: tr('login.legal2')),
              ],
            ), textAlign: TextAlign.center)),
          ]),
        ),
      );
  }

  // ══════════════════════ SMS ══════════════════════
  Widget _smsView(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
        key: const ValueKey('sms'),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 22),
            _Magnetic(child: GestureDetector(
              onTap: () { _timer?.cancel(); setState(() { _codeStep = false; _err = null; _code.clear(); }); },
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, border: Border.all(color: t.line)),
                child: Icon(Icons.arrow_back_rounded, size: 18, color: t.ink2),
              ),
            )),
            const SizedBox(height: 30),
            Text(tr('login.enterCode'), style: FinnText.screenTitle(t.ink).copyWith(fontSize: 30, letterSpacing: -1.2)),
            const SizedBox(height: 10),
            Text.rich(TextSpan(
              style: FinnText.body(t.ink2),
              children: [
                TextSpan(text: tr('login.smsSentPrefix')),
                TextSpan(text: '+998 ${_phone.text}', style: FinnText.body(t.ink).copyWith(fontWeight: FontWeight.w600)),
                TextSpan(text: tr('login.smsSentSuffix')),
              ],
            )),
            const SizedBox(height: 30),
            if (_err != null) ...[_banner(Icons.error_outline_rounded, t.red, _err!)],
            // 4 ta OTP katak + ustidagi shaffof TextField
            Stack(children: [
              Row(children: List.generate(4, (i) {
                final filled = i < _code.text.length;
                final active = i == _code.text.length;
                final bad = _err != null;
                final borderColor = bad ? t.red : (active ? t.blue : (filled ? t.blue.withValues(alpha: .35) : t.line));
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 64,
                    alignment: Alignment.center,
                    transform: active ? Matrix4.diagonal3Values(1.04, 1.04, 1) : Matrix4.identity(),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(FinnTokens.rMd),
                      border: Border.all(color: borderColor, width: active || bad ? 2 : 1),
                    ),
                    child: Text(filled ? _code.text[i] : '', style: FinnText.cardTitle(bad ? t.red : t.ink).copyWith(fontSize: 26)),
                  ),
                ));
              })),
              Positioned.fill(child: Opacity(opacity: 0, child: TextField(
                controller: _code,
                focusNode: _codeFocus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 4,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(counterText: '', border: InputBorder.none),
                onChanged: (v) { setState(() { if (_err != null) _err = null; }); if (v.length == 4) _verify(); },
              ))),
            ]),
            const SizedBox(height: 24),
            _cta(_busy || _code.text.length != 4 ? null : _verify, tr('login.verify'), Icons.check_rounded),
            const SizedBox(height: 22),
            Center(child: _seconds > 0
                ? Text('${tr('login.resend')} — 0:${_seconds.toString().padLeft(2, '0')}', style: FinnText.rowSub(t.ink3).copyWith(fontSize: 13.5))
                : TextButton(onPressed: _busy ? null : _send, child: Text(tr('login.resendCode'), style: FinnText.pill(t.blue).copyWith(fontSize: 13.5, fontWeight: FontWeight.w600)))),
            const Spacer(),
            const SizedBox(height: 20),
            _altBtn(() { _timer?.cancel(); setState(() { _codeStep = false; _err = null; _code.clear(); }); }, tr('login.otherNumber')),
          ]),
        ),
      );
  }

  // ── umumiy bo'laklar ──
  Widget _field({required Widget child}) {
    final t = context.tokens;
    return Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(FinnTokens.rMd), border: Border.all(color: t.line)),
        child: child,
      );
  }

  Widget _banner(IconData icon, Color c, String text) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.withValues(alpha: .1), borderRadius: BorderRadius.circular(FinnTokens.rMd)),
        child: Row(children: [
          Icon(icon, color: c, size: 19), const SizedBox(width: 11),
          Expanded(child: Text(text, style: FinnText.rowSub(c).copyWith(fontSize: 12.5, fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _cta(VoidCallback? onTap, String label, IconData icon) {
    final t = context.tokens;
    return _Magnetic(child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: FinnTokens.brand,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            boxShadow: onTap == null ? null : [BoxShadow(color: t.blue2.withValues(alpha: .3), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: SizedBox(
            width: double.infinity, height: 56,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FinnTokens.rMd))),
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(label, style: FinnText.button(Colors.white).copyWith(fontSize: 16)),
                      const SizedBox(width: 9), Icon(icon, color: Colors.white, size: 18),
                    ]),
            ),
          ),
        ),
      ));
  }

  Widget _altBtn(VoidCallback onTap, String label) {
    final t = context.tokens;
    return _Magnetic(child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, height: 56, alignment: Alignment.center,
          decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(FinnTokens.rMd), border: Border.all(color: t.line)),
          child: Text(label, style: FinnText.button(t.ink)),
        ),
      ));
  }
}

class _Magnetic extends StatefulWidget {
  final Widget child;
  const _Magnetic({required this.child});
  @override
  State<_Magnetic> createState() => _MagneticState();
}

class _MagneticState extends State<_Magnetic> {
  double _s = 1;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _s = .975),
        onTapUp: (_) => setState(() => _s = 1),
        onTapCancel: () => setState(() => _s = 1),
        child: AnimatedScale(scale: _s, duration: const Duration(milliseconds: 130), curve: Curves.easeOut, child: widget.child),
      );
}

/// OneID orqali kirish — davlat autentifikatsiyasi. "Brauzer" ko'rinishisiz,
/// seamless (brendli loading + toza ekran). Parol faqat id.egov.uz'ga yuboriladi
/// (bu qonuniy talab — parol hech qachon Finn serveriga tegmaydi).
class OneIdLoginPage extends StatefulWidget {
  const OneIdLoginPage({super.key});
  @override
  State<OneIdLoginPage> createState() => _OneIdLoginPageState();
}

class _OneIdLoginPageState extends State<OneIdLoginPage> {
  WebViewController? _c;
  bool _ready = false;   // davlat login sahifasi ko'rindi — overlay olib tashlanadi
  bool _finishing = false; // token olinmoqda — brendli overlay
  String? _error;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _build();
  }

  /// WebView'dagi barcha qoldiqlarni o'chirish: cookie (veb-sessiya), kesh
  /// (/m-token javobi — ichida token matni) va localStorage.
  Future<void> _wipeWebView() async {
    try { await WebViewCookieManager().clearCookies(); } catch (_) {}
    try { await _c?.clearCache(); } catch (_) {}
    try { await _c?.clearLocalStorage(); } catch (_) {}
  }

  void _build() {
    _watchdog?.cancel();
    // ESKI id.egov.uz/finn sessiya cookie'lari OneID authorize oqimini buzib
    // (login'dan keyin kabinetda qoldirib) "Ulanmadi" beradi. Har boshlashda
    // TOZA holatdan boshlaymiz — shunda callback'ga to'g'ri qaytadi.
    WebViewCookieManager().clearCookies();
    // 45s ichida hech narsa yuklanmasa — muzlab qolmasin, xato ko'rsatamiz
    _watchdog = Timer(const Duration(seconds: 45), () {
      if (mounted && !_ready && !_finishing) setState(() => _error = tr('login.errSlow'));
    });
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // id.egov.uz WebView'ni oddiy brauzerdek ko'rsin (aks holda kabinetda
      // qolib, callback'ga qaytarmaydi). Standart Android Chrome UA.
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        // Yangi oyna/popup (target=_blank) ni SHU oynada ochamiz — aks holda
        // OneID "davom etish" bosilganda redirect bloklanib kabinetda qoladi.
        onNavigationRequest: (req) => NavigationDecision.navigate,
        onPageFinished: (u) async {
          // Har sahifada _blank/popup'ni bloklamaslik uchun same-window'ga o'tkazamiz.
          try {
            await _c!.runJavaScript(
                "document.querySelectorAll('a[target]').forEach(function(a){a.target='_self';});"
                "window.open=function(u){if(u){location.href=u;}return null;};");
          } catch (_) {}
          if (u.contains('/m-token')) {
            try {
              final res = await _c!.runJavaScriptReturningResult('document.body.innerText');
              final m = RegExp(r'"token"\s*:\s*"([^"]+)"').firstMatch(res.toString());
              if (m != null && mounted) {
                // Ekspertiza 2.2.4: token olingach WebView'da veb-sessiya va
                // sahifa nusxasi (token matni ham) qolmasin — ular ilova
                // papkasida shifrlanmagan holda saqlanadi. Token endi faqat
                // shifrlangan xotirada (Keystore/Keychain) bo'ladi.
                final token = m.group(1);
                await _wipeWebView();
                if (mounted) Navigator.of(context).pop(token);
                return;
              }
            } catch (_) {}
            if (mounted) setState(() => _error = tr('login.errAuthIncomplete'));
            return;
          }
          if (u.contains('/dashboard') || u.contains('/subscription') || u.contains('/profile') || RegExp(r'finn\.uz/?$').hasMatch(u)) {
            // Veb-sessiya autentifikatsiya bo'ldi — mobil token olamiz
            if (!_finishing) {
              _finishing = true;
              if (mounted) setState(() {});
              _c!.loadRequest(Uri.parse(Ep.mtoken));
            }
            return;
          }
          // Davlat login/parol sahifasi ko'rindi — brendli overlay'ni olib tashlaymiz
          if (!_ready && !_finishing && mounted) setState(() => _ready = true);
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted && !_ready) {
            setState(() => _error = tr('login.errPageFailed'));
          }
        },
      ))
      ..loadRequest(Uri.parse(Ep.oneid));
  }

  @override
  void dispose() { _watchdog?.cancel(); super.dispose(); }

  void _retry() { setState(() { _ready = false; _finishing = false; _error = null; }); _build(); }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final showOverlay = !_ready || _finishing || _error != null;
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Stack(children: [
          if (_c != null) Positioned.fill(child: WebViewWidget(controller: _c!)),
          // Yopish tugmasi — faqat davlat sahifasi ko'ringanda (overlay ustida kerak emas)
          if (_ready && !_finishing && _error == null)
            Positioned(top: 8, right: 8, child: _Magnetic(child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, border: Border.all(color: t.line), boxShadow: t.sh),
                child: Icon(Icons.close_rounded, size: 20, color: t.ink),
              ),
            ))),
          if (showOverlay) Positioned.fill(child: _overlay(context)),
        ]),
      ),
    );
  }

  Widget _overlay(BuildContext context) {
    final t = context.tokens;
    return Container(
        color: t.bg,
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Spacer(),
          // OneID belgisi (oq quti + ko'k logo)
          Container(
            width: 88, height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(FinnTokens.rMd), boxShadow: [BoxShadow(color: _oneidBlue.withValues(alpha: .18), blurRadius: 26, offset: const Offset(0, 10))]),
            padding: const EdgeInsets.all(14),
            child: Image.asset('assets/oneid_blue.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 28),
          if (_error != null) ...[
            Text(tr('login.oneidFailed'), style: FinnText.cardTitle(t.ink).copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: FinnText.body(t.ink2)),
            const SizedBox(height: 24),
            SizedBox(width: 200, child: _Magnetic(child: DecoratedBox(
              decoration: BoxDecoration(gradient: FinnTokens.brand, borderRadius: BorderRadius.circular(FinnTokens.rMd)),
              child: SizedBox(height: 50, child: TextButton(onPressed: _retry, child: Text(tr('common.retry'), style: FinnText.button(Colors.white).copyWith(fontWeight: FontWeight.w700, fontSize: 15)))),
            ))),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(tr('common.cancel'), style: FinnText.pill(t.ink2).copyWith(fontSize: 13.5, fontWeight: FontWeight.w600))),
          ] else ...[
            Text(_finishing ? tr('login.oneidLoggingIn') : tr('login.oneidSecure'),
                style: FinnText.cardTitle(t.ink).copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(_finishing ? tr('login.oneidDetectingOrgs') : tr('login.oneidConnecting'),
                textAlign: TextAlign.center, style: FinnText.rowSub(t.ink2).copyWith(fontSize: 13.5)),
            const SizedBox(height: 26),
            SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.6, valueColor: AlwaysStoppedAnimation(t.blue), backgroundColor: t.line)),
          ],
          const Spacer(),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.lock_rounded, size: 13, color: t.green),
            const SizedBox(width: 6),
            Text(tr('login.oneidPasswordNote'), style: FinnText.screenSub(t.ink3)),
          ]),
        ]),
      );
  }
}
