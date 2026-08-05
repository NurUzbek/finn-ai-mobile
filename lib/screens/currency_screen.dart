import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../services/api.dart';
import '../widgets/common.dart';

/// Valyuta kurslari ekrani — Markaziy bank rasmiy kurslari + konvertor.
/// Dizayn: finn-app-full.html `#v-valyuta` bilan 1:1.
class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.currency();
  }

  Future<void> _refresh() async {
    setState(() => _future = Api.currency());
    await _future;
  }

  /// Valyuta kodiga mos to'liq nom (o'zbekcha).
  static String _name(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return 'AQSH dollari';
      case 'EUR':
        return 'Yevro';
      case 'RUB':
        return 'Rossiya rubli';
      case 'KZT':
        return 'Qozog\'iston tengesi';
      case 'CNY':
        return 'Xitoy yuani';
      case 'GBP':
        return 'Angliya funt sterlingi';
      case 'JPY':
        return 'Yaponiya iyenasi';
      case 'CHF':
        return 'Shveytsariya franki';
      case 'TRY':
        return 'Turkiya lirasi';
      case 'KRW':
        return 'Janubiy Koreya voni';
      case 'AED':
        return 'BAA dirhami';
      case 'UAH':
        return 'Ukraina grivnasi';
      case 'KGS':
        return 'Qirg\'iziston somi';
      case 'TJS':
        return 'Tojikiston somoniysi';
      default:
        return code;
    }
  }

  /// Valyuta nishoni uchun akssent rangi.
  static Color _codeColor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return C.green;
      case 'EUR':
        return C.blue;
      case 'RUB':
        return C.red;
      case 'GBP':
        return C.cyan;
      case 'CNY':
        return C.amber;
      case 'KZT':
        return C.sky;
      case 'JPY':
        return C.violet;
      default:
        return C.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(future: _future),
            Expanded(
              child: Loader(
                future: _future,
                onRefresh: _refresh,
                builder: (data) {
                  final rates = <Map<String, dynamic>>[];
                  final raw = data['rates'];
                  if (raw is List) {
                    for (final r in raw) {
                      if (r is Map) rates.add(Map<String, dynamic>.from(r));
                    }
                  }

                  if (rates.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.currency_exchange_rounded,
                          text: 'Kurslar topilmadi',
                          color: C.amber,
                        ),
                      ],
                    );
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

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 122),
                    children: [
                      StaggerIn(
                        index: 0,
                        child: _Converter(code: convCode, rate: usdRate),
                      ),
                      const StaggerIn(index: 1, child: _Eyebrow('Rasmiy kurs')),
                      StaggerIn(
                        index: 2,
                        child: _RatesGroup(
                          rates: rates,
                          nameOf: _name,
                          colorOf: _codeColor,
                        ),
                      ),
                      StaggerIn(
                        index: 3,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            'Kurslar Markaziy bankdan har kuni soat 16:00 da yangilanadi.',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.5,
                              color: C.muted(context, .35),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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

// ── Sarlavha (orqaga tugmasi + kichik izoh) ──
class _Header extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  const _Header({required this.future});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: future,
              builder: (ctx, snap) {
                String date = '';
                final d = snap.data;
                if (d != null && d['rates'] is List && (d['rates'] as List).isNotEmpty) {
                  final first = (d['rates'] as List).first;
                  if (first is Map) date = (first['date'] ?? '').toString();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valyuta kurslari',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                        height: 1.1,
                        color: C.text(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date.isEmpty ? 'Markaziy bank' : 'Markaziy bank · $date',
                      style: TextStyle(fontSize: 12.5, color: C.muted(context, .5)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: C.card(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: C.border(context)),
          boxShadow: C.shadow(context),
        ),
        child: Icon(Icons.chevron_left_rounded, size: 24, color: C.text(context)),
      ),
    );
  }
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
    final uzs = _amount * widget.rate;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KONVERTOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Kiritish (valyuta)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: C.fill(context),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.code,
                        style: TextStyle(fontSize: 11, color: C.muted(context, .45)),
                      ),
                      const SizedBox(height: 3),
                      TextField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (_) => setState(() {}),
                        cursorColor: C.brand,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          color: C.text(context),
                        ),
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
              Icon(Icons.swap_horiz_rounded, size: 20, color: C.muted(context, .45)),
              const SizedBox(width: 10),
              // Natija (UZS)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: C.tint(context, C.brand),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UZS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: C.brand,
                        ),
                      ),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          money(uzs),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: C.brand,
                          ),
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

// ── Bo'lim sarlavhasi (matn + chiziq) ──
class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: C.muted(context, .45),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: C.border(context))),
        ],
      ),
    );
  }
}

// ── Kurslar guruhi (bitta karta ichida qatorlar) ──
class _RatesGroup extends StatelessWidget {
  final List<Map<String, dynamic>> rates;
  final String Function(String) nameOf;
  final Color Function(String) colorOf;
  const _RatesGroup({required this.rates, required this.nameOf, required this.colorOf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.border(context)),
        boxShadow: C.shadow(context),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rates.length; i++)
            _FxRow(
              data: rates[i],
              nameOf: nameOf,
              colorOf: colorOf,
              last: i == rates.length - 1,
            ),
        ],
      ),
    );
  }
}

class _FxRow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String Function(String) nameOf;
  final Color Function(String) colorOf;
  final bool last;
  const _FxRow({required this.data, required this.nameOf, required this.colorOf, required this.last});

  @override
  Widget build(BuildContext context) {
    final code = (data['code'] ?? '—').toString();
    final rate = _num(data['rate']);
    final diff = _num(data['diff']);
    final color = colorOf(code);

    final diffColor = diff > 0
        ? C.onGrn(context)
        : diff < 0
            ? C.onRed(context)
            : C.muted(context, .4);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: C.border(context, .045))),
      ),
      child: Row(
        children: [
          // Valyuta nishoni (rangli kod)
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: C.tint(context, color),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 13),
          // Nom + birlik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameOf(code),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: C.text(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 $code',
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .45)),
                ),
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: C.text(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _diffStr(diff),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: diffColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
