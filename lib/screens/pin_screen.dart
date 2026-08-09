import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/finn_tokens.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../services/lock.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// PIN ekrani — mode: 'set' (yangi PIN o'rnatish) yoki 'unlock' (kirish).
class PinScreen extends StatefulWidget {
  final String mode; // 'set' | 'unlock'
  const PinScreen({super.key, required this.mode});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String? _first; // set-mode: birinchi kiritilgan PIN
  bool _confirm = false;
  String? _error;
  bool _shake = false;

  bool get _isSet => widget.mode == 'set';

  @override
  void initState() {
    super.initState();
    if (!_isSet) _tryBio();
  }

  /// Biometrika (barmoq izi / Face ID) — qurilmada MAVJUD bo'lsa doim taklif qilinadi
  /// (auto ochilishda + barmoq izi tugmasi bosilganda). bioOn sozlamasiga bog'liq emas.
  Future<void> _tryBio() async {
    if (!await Lock.bioAvailable()) return;
    final ok = await Lock.bioAuth();
    if (ok && mounted) _enter();
  }

  void _enter() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeShell()), (_) => false);
  }

  Future<void> _onDigit(String d) async {
    if (_pin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() { _pin += d; _error = null; });
    if (_pin.length == 4) await _submit();
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _fail(String msg) async {
    setState(() { _error = msg; _shake = true; });
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() { _pin = ''; _shake = false; });
  }

  Future<void> _submit() async {
    if (_isSet) {
      if (!_confirm) {
        setState(() { _first = _pin; _confirm = true; _pin = ''; });
      } else {
        if (_pin == _first) {
          await Lock.setPin(_pin);
          await _askBio();
          if (mounted) _enter();
        } else {
          setState(() { _confirm = false; _first = null; });
          await _fail(tr('pin.mismatch'));
        }
      }
    } else {
      if (await Lock.verify(_pin)) {
        _enter();
      } else {
        await _fail(tr('pin.wrong'));
      }
    }
  }

  Future<void> _askBio() async {
    if (!await Lock.bioAvailable()) return;
    if (!mounted) return;
    final on = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: c.tokens.card,
        title: Text(tr('pin.bioTitle')),
        content: Text(tr('pin.bioBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('pin.bioLater'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(tr('pin.bioEnable'))),
        ],
      ),
    );
    if (on == true) await Lock.setBio(true);
  }

  Future<void> _logout() async {
    await Api.clearToken();
    await Lock.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final title = _isSet ? (_confirm ? tr('pin.titleConfirm') : tr('pin.titleSet')) : tr('pin.titleUnlock');
    final sub = _isSet
        ? (_confirm ? tr('pin.subConfirm') : tr('pin.subSet'))
        : tr('pin.subUnlock');
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Column(children: [
          const Spacer(flex: 2),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FinnTokens.rLg),
              boxShadow: [BoxShadow(color: t.cyan.withValues(alpha: .4), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FinnTokens.rLg),
              child: Image.asset('assets/logo.png', width: 66, height: 66, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: FinnText.screenTitle(t.ink)),
          const SizedBox(height: 6),
          Text(sub, style: FinnText.screenSub(t.ink2)),
          const SizedBox(height: 28),
          AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            transform: Matrix4.translationValues(_shake ? 8 : 0, 0, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
              final filled = i < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16, height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? (_error != null ? t.red : t.blue) : Colors.transparent,
                  border: Border.all(color: _error != null ? t.red : (filled ? t.blue : t.ink4), width: 2),
                ),
              );
            })),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 18, child: _error != null
              ? Text(_error!, style: FinnText.chip(t.red))
              : null),
          const Spacer(flex: 1),
          _keypad(t),
          const SizedBox(height: 8),
          if (!_isSet)
            TextButton(onPressed: _logout, child: Text(tr('pin.otherNumber'), style: FinnText.button(t.ink2))),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _keypad(FinnTokens t) {
    Widget key(String d) => _KeyBtn(label: d, onTap: () => _onDigit(d));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(children: [
        Row(children: [key('1'), key('2'), key('3')]),
        Row(children: [key('4'), key('5'), key('6')]),
        Row(children: [key('7'), key('8'), key('9')]),
        Row(children: [
          Expanded(child: !_isSet
              ? _KeyBtn(icon: Icons.fingerprint, onTap: _tryBio)
              : const SizedBox()),
          key('0'),
          Expanded(child: _KeyBtn(icon: Icons.backspace_outlined, onTap: _back)),
        ]),
      ]),
    );
  }
}

class _KeyBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _KeyBtn({this.label, this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Material(
          color: label != null ? t.key : Colors.transparent,
          borderRadius: BorderRadius.circular(FinnTokens.rLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(FinnTokens.rLg),
            onTap: onTap,
            child: SizedBox(
              height: 62,
              child: Center(child: label != null
                  ? Text(label!, style: FinnText.bigValue(t.ink))
                  : Icon(icon, size: 24, color: t.ink2)),
            ),
          ),
        ),
      ),
    );
  }
}
