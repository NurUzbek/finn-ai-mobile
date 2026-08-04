import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/lock.dart';
import 'home_shell.dart';
import 'pin_screen.dart';

// Brend gradienti — prototip (finn-login-prototype.html) bilan bir xil.
const _grad = LinearGradient(
  begin: Alignment.topLeft, end: Alignment.bottomRight,
  colors: [Color(0xFF1745C9), Color(0xFF2A6DF5), Color(0xFF25C4E8)],
);
const _blue = Color(0xFF246BFD);
const _oneidBlue = Color(0xFF0B57A4);

/// SMS-kod orqali kirish (2FA) — editorial dizayn (prototip asosida).
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
    if (digits.length != 9) return setState(() => _err = 'Telefon raqamini to\'liq kiriting');
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
      setState(() { _err = r['message'] ?? 'Kod noto\'g\'ri'; _code.clear(); });
    }
  }

  Future<void> _afterAuth() async {
    final hasPin = await Lock.hasPin();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => hasPin ? const HomeShell() : const PinScreen(mode: 'set')), (_) => false);
  }

  Future<void> _oneid() async {
    final token = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const OneIdLoginPage()));
    if (token == null || !mounted) return;
    await Api.setToken(token);
    _afterAuth();
  }

  @override
  Widget build(BuildContext context) {
    final dark = C.isDark(context);
    return Scaffold(
      backgroundColor: C.bg(context),
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // Ambient glow orblari (device::before / ::after)
        Positioned(top: -150, left: -60, child: _orb(_blue.withValues(alpha: dark ? .22 : .15), 460, 380)),
        Positioned(bottom: -120, right: -90, child: _orb(const Color(0xFF25C4E8).withValues(alpha: dark ? .12 : .10), 380, 360)),
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
  Widget _phoneView(BuildContext context) => SingleChildScrollView(
        key: const ValueKey('phone'),
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 56),
            // Brend belgisi — logo.png (glow bilan)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFF080D1C).withValues(alpha: .18), blurRadius: 22, offset: const Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/logo.png', width: 60, height: 60, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 28),
            Text('FINN · SOLIQ MONITORING', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: C.muted(context, .45))),
            const SizedBox(height: 12),
            Text('Xush kelibsiz', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.3, height: 1.1, color: C.text(context))),
            const SizedBox(height: 10),
            Text('Telefon raqamingizni kiriting — SMS orqali tasdiqlash kodi yuboramiz.',
                style: TextStyle(fontSize: 15, height: 1.55, color: C.muted(context, .7))),
            const SizedBox(height: 30),
            if (widget.expired) _banner(Icons.timer_off_rounded, C.amber, 'Harakatsizlik tufayli chiqarildingiz. Qaytadan kiring.'),
            if (_err != null) _banner(Icons.error_outline_rounded, C.red, _err!),
            Text('Telefon raqam', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: C.muted(context, .7))),
            const SizedBox(height: 8),
            _field(child: Row(children: [
              Icon(Icons.smartphone_rounded, size: 19, color: C.muted(context, .45)),
              const SizedBox(width: 12),
              Text('+998', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.muted(context, .55))),
              const SizedBox(width: 12),
              Container(width: 1, height: 22, color: C.border(context, .12)),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                style: TextStyle(fontSize: 17, letterSpacing: 1, fontWeight: FontWeight.w600, color: C.text(context)),
                decoration: InputDecoration(hintText: '90 123 45 67', hintStyle: TextStyle(color: C.muted(context, .35), fontWeight: FontWeight.w500), border: InputBorder.none, isCollapsed: true),
                onChanged: (_) { if (_err != null) setState(() => _err = null); },
                onSubmitted: (_) => _send(),
              )),
            ])),
            const SizedBox(height: 20),
            _cta(_busy ? null : _send, 'Kodni yuborish', Icons.arrow_forward_rounded),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Divider(color: C.border(context, .12))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('YOKI', style: TextStyle(color: C.muted(context, .45), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.3))),
              Expanded(child: Divider(color: C.border(context, .12))),
            ]),
            const SizedBox(height: 20),
            // OneID — alt uslub (karta foni + kichik ko'k OneID belgisi)
            _Magnetic(child: GestureDetector(
              onTap: _busy ? null : _oneid,
              child: Container(
                width: double.infinity, height: 56,
                decoration: BoxDecoration(
                  color: C.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.border(context, .12)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 40, height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _oneidBlue.withValues(alpha: .14)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Image.asset('assets/oneid_blue.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 11),
                  Text('OneID bilan kirish', style: TextStyle(color: C.text(context), fontWeight: FontWeight.w600, fontSize: 15.5)),
                ]),
              ),
            )),
            const SizedBox(height: 11),
            Center(child: Text('Tashkilotlaringiz avtomatik aniqlanadi', style: TextStyle(fontSize: 12, color: C.muted(context, .45)))),
            const Spacer(),
            const SizedBox(height: 24),
            Center(child: Text.rich(TextSpan(
              style: TextStyle(fontSize: 12, height: 1.6, color: C.muted(context, .45)),
              children: const [
                TextSpan(text: 'Davom etish orqali foydalanish shartlari va\n'),
                TextSpan(text: 'maxfiylik siyosati', style: TextStyle(decoration: TextDecoration.underline)),
                TextSpan(text: 'ga rozilik bildirasiz.'),
              ],
            ), textAlign: TextAlign.center)),
          ]),
        ),
      );

  // ══════════════════════ SMS ══════════════════════
  Widget _smsView(BuildContext context) => SingleChildScrollView(
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
                decoration: BoxDecoration(color: C.card(context), shape: BoxShape.circle, border: Border.all(color: C.border(context, .12))),
                child: Icon(Icons.arrow_back_rounded, size: 18, color: C.muted(context, .7)),
              ),
            )),
            const SizedBox(height: 30),
            Text('Kodni kiriting', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.3, height: 1.1, color: C.text(context))),
            const SizedBox(height: 10),
            Text.rich(TextSpan(
              style: TextStyle(fontSize: 15, height: 1.55, color: C.muted(context, .7)),
              children: [
                const TextSpan(text: 'SMS '),
                TextSpan(text: '+998 ${_phone.text}', style: TextStyle(color: C.text(context), fontWeight: FontWeight.w600)),
                const TextSpan(text: ' raqamiga yuborildi.'),
              ],
            )),
            const SizedBox(height: 30),
            if (_err != null) ...[_banner(Icons.error_outline_rounded, C.red, _err!)],
            // 4 ta OTP katak + ustidagi shaffof TextField
            Stack(children: [
              Row(children: List.generate(4, (i) {
                final filled = i < _code.text.length;
                final active = i == _code.text.length;
                final bad = _err != null;
                final borderColor = bad ? C.red : (active ? _blue : (filled ? _blue.withValues(alpha: .35) : C.border(context, .12)));
                return Expanded(child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 64,
                    alignment: Alignment.center,
                    transform: active ? Matrix4.diagonal3Values(1.04, 1.04, 1) : Matrix4.identity(),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: C.card(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: active || bad ? 2 : 1),
                    ),
                    child: Text(filled ? _code.text[i] : '', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: bad ? C.red : C.text(context))),
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
            _cta(_busy || _code.text.length != 4 ? null : _verify, 'Tasdiqlash', Icons.check_rounded),
            const SizedBox(height: 22),
            Center(child: _seconds > 0
                ? Text('Qayta yuborish — 0:${_seconds.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 13.5, color: C.muted(context, .5)))
                : TextButton(onPressed: _busy ? null : _send, child: const Text('Kodni qayta yuborish', style: TextStyle(color: _blue, fontWeight: FontWeight.w600, fontSize: 13.5)))),
            const Spacer(),
            const SizedBox(height: 20),
            _altBtn(() { _timer?.cancel(); setState(() { _codeStep = false; _err = null; _code.clear(); }); }, 'Boshqa raqam kiritish'),
          ]),
        ),
      );

  // ── umumiy bo'laklar ──
  Widget _field({required Widget child}) => Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: C.card(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border(context, .12))),
        child: child,
      );

  Widget _banner(IconData icon, Color c, String text) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.withValues(alpha: .1), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Icon(icon, color: c, size: 19), const SizedBox(width: 11),
          Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _cta(VoidCallback? onTap, String label, IconData icon) => _Magnetic(child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _grad,
            borderRadius: BorderRadius.circular(16),
            boxShadow: onTap == null ? null : [BoxShadow(color: const Color(0xFF1745C9).withValues(alpha: .3), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: SizedBox(
            width: double.infinity, height: 56,
            child: TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -.2)),
                      const SizedBox(width: 9), Icon(icon, color: Colors.white, size: 18),
                    ]),
            ),
          ),
        ),
      ));

  Widget _altBtn(VoidCallback onTap, String label) => _Magnetic(child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity, height: 56, alignment: Alignment.center,
          decoration: BoxDecoration(color: C.card(context), borderRadius: BorderRadius.circular(16), border: Border.all(color: C.border(context, .12))),
          child: Text(label, style: TextStyle(color: C.text(context), fontWeight: FontWeight.w600, fontSize: 15.5)),
        ),
      ));
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

/// OneID orqali kirish — WebView'da davlat OneID oqimi, so'ng mobil token
/// olib ilovaga qaytadi (/m-token). Parol faqat id.egov.uz'ga yuboriladi.
class OneIdLoginPage extends StatefulWidget {
  const OneIdLoginPage({super.key});
  @override
  State<OneIdLoginPage> createState() => _OneIdLoginPageState();
}

class _OneIdLoginPageState extends State<OneIdLoginPage> {
  WebViewController? _c;
  int _p = 0;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _p = p) : null,
        onPageFinished: (u) async {
          if (u.contains('/m-token')) {
            try {
              final res = await _c!.runJavaScriptReturningResult('document.body.innerText');
              final m = RegExp(r'"token"\s*:\s*"([^"]+)"').firstMatch(res.toString());
              if (m != null && mounted) { Navigator.of(context).pop(m.group(1)); return; }
            } catch (_) {}
            if (mounted) Navigator.of(context).pop();
          } else if (!_fetching && (u.contains('/dashboard') || u.contains('/subscription') || u.contains('/profile') || RegExp(r'finn\.uz/?$').hasMatch(u))) {
            // Veb-sessiya autentifikatsiya bo'ldi — mobil token olamiz
            _fetching = true;
            _c!.loadRequest(Uri.parse('https://finn.uz/m-token'));
          }
        },
      ))
      ..loadRequest(Uri.parse('https://finn.uz/auth/oneid'));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        appBar: AppBar(
          backgroundColor: C.bg(context), elevation: 0,
          leading: IconButton(icon: Icon(Icons.close_rounded, color: C.text(context)), onPressed: () => Navigator.of(context).pop()),
          title: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_rounded, size: 14, color: C.green),
            const SizedBox(width: 6),
            const Text('id.egov.uz', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ]),
          centerTitle: true,
          bottom: _p < 100 ? PreferredSize(preferredSize: const Size.fromHeight(2), child: LinearProgressIndicator(value: _p / 100, minHeight: 2, backgroundColor: Colors.transparent)) : null,
        ),
        body: _c == null ? const SizedBox() : WebViewWidget(controller: _c!),
      );
}
