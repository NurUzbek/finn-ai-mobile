import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/finn_tokens.dart';
import '../widgets/finn_screen.dart';
import '../services/api.dart';
import '../services/i18n.dart';
import '../widgets/common.dart';

/// Valyuta kurslari ekrani — Markaziy bank rasmiy kurslari + konvertor.
/// FINN dizayn tizimi bo'yicha (FinnScreen + tokens + FinnText). PUSH ekran.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late Future<Map<String, dynamic>> _f = Api.currency();
  String _sub = tr('cur.central_bank');

  Future<void> _refresh() async => setState(() => _f = Api.currency());

  /// Valyuta kodiga mos to'liq nom (joriy tilda). Noma'lum kod — kodning o'zi.
  static String _name(String code) {
    const known = {
      'USD', 'EUR', 'RUB', 'KZT', 'CNY', 'GBP', 'JPY', 'CHF',
      'TRY', 'KRW', 'AED', 'UAH', 'KGS', 'TJS',
    };
    final up = code.toUpperCase();
    if (!known.contains(up)) return code;
    return tr('cur.name.${up.toLowerCase()}');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return FinnScreen(
      title: tr('cur.title'),
      subtitle: _sub,
      showNav: false,
      leading: _iconBtn(t, Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop()),
      actions: [
        _iconBtn(t, Icons.refresh_rounded, onTap: _refresh),
      ],
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
            final d = snap.data ?? const {};
            if (d['ok'] != true) return _err(t);
            return _content(t, d);
          },
        ),
      ],
    );
  }

  Widget _content(FinnTokens t, Map<String, dynamic> d) {
    final rates = <Map<String, dynamic>>[];
    final raw = d['rates'];
    if (raw is List) {
      for (final r in raw) {
        if (r is Map) rates.add(Map<String, dynamic>.from(r));
      }
    }

    if (rates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.currency_exchange_rounded, size: 44, color: t.ink4),
            const SizedBox(height: 12),
            Text(tr('cur.no_rates'), style: FinnText.body(t.ink3)),
          ]),
        ),
      );
    }

    // Sarlavha izohi — sana (birinchi qatordan).
    final first = rates.first;
    final date = (first['date'] ?? '').toString();
    final cb = tr('cur.central_bank');
    final newSub = date.isEmpty ? cb : '$cb · $date';
    if (newSub != _sub) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _sub = newSub);
      });
    }

    // Konvertor uchun USD kursi (bo'lmasa birinchi valyuta).
    num usdRate = 0;
    String convCode = 'USD';
    for (final m in rates) {
      if ((m['code'] ?? '').toString().toUpperCase() == 'USD') {
        usdRate = _num(m['rate']);
        convCode = 'USD';
        break;
      }
    }
    if (usdRate == 0) {
      convCode = (rates.first['code'] ?? '').toString();
      usdRate = _num(rates.first['rate']);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        StaggerIn(index: 0, child: _Converter(code: convCode, rate: usdRate)),
        StaggerIn(index: 1, child: _eyebrow(t, tr('cur.official_rate'))),
        StaggerIn(index: 2, child: _ratesGroup(t, rates)),
        StaggerIn(
          index: 3,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              tr('cur.update_note'),
              style: FinnText.rowSub(t.ink3),
            ),
          ),
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
            Text(tr('cur.no_connection'), style: FinnText.body(t.ink3)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _refresh, child: Text(tr('cur.retry'))),
          ]),
        ),
      );

  Widget _iconBtn(FinnTokens t, IconData ic, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(FinnTokens.rMd),
            border: Border.all(color: t.line),
            boxShadow: t.sh,
          ),
          child: Icon(ic, size: 19, color: t.ink2),
        ),
      );

  Widget _eyebrow(FinnTokens t, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        child: Row(children: [
          Text(label.toUpperCase(), style: FinnText.eyebrow(t.ink3)),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: t.line)),
        ]),
      );

  // ── Kurslar guruhi (bitta karta ichida qatorlar) ──
  Widget _ratesGroup(FinnTokens t, List<Map<String, dynamic>> rates) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(FinnTokens.rXl),
          border: Border.all(color: t.line),
          boxShadow: t.sh,
        ),
        child: Column(
          children: [
            for (int i = 0; i < rates.length; i++)
              _fxRow(t, rates[i], last: i == rates.length - 1),
          ],
        ),
      );

  Widget _fxRow(FinnTokens t, Map<String, dynamic> data, {required bool last}) {
    final code = (data['code'] ?? '—').toString();
    final rate = _num(data['rate']);
    final diff = _num(data['diff']);

    final diffColor = diff > 0
        ? t.onGrn
        : diff < 0
            ? t.onRed
            : t.ink3;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.line2)),
      ),
      child: Row(
        children: [
          // Valyuta nishoni (.flag — umumiy kalit foni, kod matni)
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.key,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              code,
              style: FinnText.rowValue(t.ink2).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 13),
          // Nom + birlik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name(code), style: FinnText.rowTitle(t.ink)),
                const SizedBox(height: 2),
                Text('1 $code', style: FinnText.rowSub(t.ink3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Kurs + o'zgarish
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _dec(rate),
                style: FinnText.rowValue(t.ink)
                    .copyWith(fontSize: 15, letterSpacing: -0.375),
              ),
              const SizedBox(height: 3),
              Text(
                _diffStr(diff),
                style: FinnText.rowSub(diffColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

num _num(dynamic v) => v is num ? v : num.tryParse('$v') ?? 0;

/// Ikki xonali kasr + bo'shliqli minglik ajratuvchi (dizayndagi ko'rinish).
String _dec(num v) {
  final neg = v < 0;
  final a = v.abs();
  final whole = a.floor();
  final frac = ((a - whole) * 100).round().toString().padLeft(2, '0');
  return '${neg ? '−' : ''}${money(whole)}.$frac';
}

/// Kurs o'zgarishi (belgili).
String _diffStr(num d) {
  if (d == 0) return '0.00';
  return d > 0 ? '+${_dec(d.abs())}' : '−${_dec(d.abs())}';
}

// ── Konvertor kartasi ──
class _Converter extends StatefulWidget {
  final String code;
  final num rate;
  const _Converter({required this.code, required this.rate});

  @override
  State<_Converter> createState() => _ConverterState();
}

class _ConverterState extends State<_Converter> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '1000');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  num get _amount => _num(_ctrl.text.replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final uzs = _amount * widget.rate;
    return Container(
      padding: const EdgeInsets.all(FinnTokens.cardPad),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(FinnTokens.rXl),
        border: Border.all(color: t.line),
        boxShadow: t.sh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('cur.converter'), style: FinnText.label(t.ink3)),
          const SizedBox(height: 12),
          Row(
            children: [
              // Kiritish (valyuta)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.key,
                    borderRadius: BorderRadius.circular(FinnTokens.rMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.code,
                          style:
                              FinnText.rowSub(t.ink3).copyWith(fontSize: 11)),
                      const SizedBox(height: 3),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (_) => setState(() {}),
                        cursorColor: t.blue,
                        style: FinnText.bigValue(t.ink).copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.swap_horiz_rounded, size: 18, color: t.ink3),
              const SizedBox(width: 10),
              // Natija (UZS)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: t.tBlu,
                    borderRadius: BorderRadius.circular(FinnTokens.rMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UZS',
                          style:
                              FinnText.rowSub(t.blue).copyWith(fontSize: 11)),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          money(uzs),
                          style: FinnText.bigValue(t.blue).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
