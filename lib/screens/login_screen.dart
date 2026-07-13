import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api.dart';
import 'home_shell.dart';

/// SMS-kod orqali kirish (2FA). `expired: true` — sessiya harakatsizlikdan tugagan.
class LoginScreen extends StatefulWidget {
  final bool expired;
  const LoginScreen({super.key, this.expired = false});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeStep = false, _busy = false;
  String? _err;

  Future<void> _send() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 9) return setState(() => _err = 'Telefon raqamini to\'liq kiriting');
    setState(() { _busy = true; _err = null; });
    final r = await Api.sendCode('998$digits');
    setState(() { _busy = false; _codeStep = r['ok'] == true; _err = r['ok'] == true ? null : r['message']; });
  }

  Future<void> _verify() async {
    if (_code.text.length != 4) return setState(() => _err = '4 xonali kodni kiriting');
    setState(() { _busy = true; _err = null; });
    final r = await Api.verify('998${_phone.text.replaceAll(RegExp(r'\D'), '')}', _code.text);
    setState(() => _busy = false);
    if (r['ok'] == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
    } else {
      setState(() => _err = r['message'] ?? 'Kod noto\'g\'ri');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [C.bgDark, Color(0xFF0A1B33), C.bgDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [C.blue, C.cyan]),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [BoxShadow(color: C.blue.withValues(alpha: .4), blurRadius: 30, offset: const Offset(0, 10))],
                    ),
                    child: const Center(child: Text('Fi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
                  ),
                  const SizedBox(height: 20),
                  const Text('FINN AI', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text('Soliq va hisobot muddatlaringiz nazoratda',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: .55), fontSize: 13)),
                  const SizedBox(height: 28),

                  if (widget.expired)
                    _banner(Icons.timer_off_rounded, C.amber,
                        'Harakatsizlik tufayli sessiya tugatildi (xavfsizlik talabi). Qaytadan kiring.'),
                  if (_err != null) _banner(Icons.error_outline_rounded, C.red, _err!),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _codeStep ? _codeForm() : _phoneForm(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Kirish bilan siz ommaviy oferta shartlariga rozilik bildirasiz',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: .35), fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(IconData icon, Color c, String text) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.withValues(alpha: .1),
          border: Border.all(color: c.withValues(alpha: .3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: c, fontSize: 12))),
        ]),
      );

  Widget _phoneForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Telefon raqamingiz', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('SMS orqali tasdiqlash kodi yuboriladi',
            style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
          style: const TextStyle(fontSize: 17, letterSpacing: 1),
          decoration: InputDecoration(
            prefixText: '+998 ',
            prefixStyle: const TextStyle(color: C.cyan, fontSize: 17, fontWeight: FontWeight.w600),
            hintText: '90 123 45 67',
            filled: true,
            fillColor: Colors.white.withValues(alpha: .04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 18),
        _btn(_busy ? null : _send, 'Kod olish'),
      ]);

  Widget _codeForm() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(onPressed: () => setState(() { _codeStep = false; _err = null; }),
              icon: const Icon(Icons.arrow_back, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
          const Text('Tasdiqlash kodi', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        Text('+998 ${_phone.text} raqamiga yuborilgan 4 xonali kod',
            style: TextStyle(color: Colors.white.withValues(alpha: .45), fontSize: 12)),
        const SizedBox(height: 16),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 4,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 14),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••',
            filled: true,
            fillColor: Colors.white.withValues(alpha: .04),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
          onChanged: (v) { if (v.length == 4) _verify(); },
        ),
        const SizedBox(height: 18),
        _btn(_busy ? null : _verify, 'Kirish'),
      ]);

  Widget _btn(VoidCallback? onTap, String label) => SizedBox(
        width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: onTap == null ? [Colors.grey.shade800, Colors.grey.shade700] : [C.blue, C.sky]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextButton(
            onPressed: onTap,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      );
}
