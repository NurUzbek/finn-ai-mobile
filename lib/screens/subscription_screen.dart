import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/plan.dart';

/// Native tarif/to'lov ekrani — WebView emas. Tariflar API'dan (`/plans`),
/// to'lov `/checkout` orqali yaratiladi. Faqat provayder to'lov sahifasi
/// (Payme/Click, PCI) minimal WebView'da ochiladi.
/// Subscription ekranini ochish (profile / locked widgetlar ishlatadi).
void openSubscription(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _current;
  String _cycle = 'monthly';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Api.plans();
      if (r['ok'] == true) {
        setState(() {
          _plans = (r['plans'] as List?) ?? [];
          _current = r['current'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        setState(() { _error = r['message']?.toString() ?? 'Xatolik'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Internet aloqasi yo\'q'; _loading = false; });
    }
  }

  String _fmt(num v) {
    final s = v.round().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  Widget _gradBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: _busy ? null : onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: C.grad,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: C.brand.withValues(alpha: .3), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Center(child: Text(label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        backgroundColor: C.bg(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Tariflar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [IconButton(onPressed: _load, icon: Icon(Icons.refresh, color: C.muted(context, .7)))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      _currentHeader(),
                      const SizedBox(height: 20),
                      _cycleToggle(),
                      const SizedBox(height: 16),
                      ..._plans.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _planCard(p as Map<String, dynamic>),
                          )),
                      const SizedBox(height: 6),
                      Text(
                        'Istalgan vaqtda bekor qilasiz. To\'lov Payme, Click yoki Uzum orqali.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, height: 1.6, color: C.muted(context, .5)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off, size: 44, color: C.muted(context, .4)),
          const SizedBox(height: 12),
          Text(_error ?? 'Xatolik', style: TextStyle(color: C.muted(context, .7))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Qayta urinish')),
        ]),
      );

  Widget _currentHeader() {
    final name = _current?['name']?.toString() ?? 'FREE';
    final days = _current?['days_left'];
    final isTrial = _current?['is_trial'] == true;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [C.blue.withValues(alpha: .18), C.cyan.withValues(alpha: .08)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        border: Border.all(color: C.cyan.withValues(alpha: .22)),
      ),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: C.cyan.withValues(alpha: .16), borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.workspace_premium_outlined, color: C.cyan, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Joriy tarif', style: TextStyle(fontSize: 12, color: C.muted(context, .6), fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: C.text(context), letterSpacing: -.5)),
          ]),
        ),
        if (isTrial && days != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: C.amber.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
            child: Text('$days kun', style: TextStyle(color: C.amber, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
      ]),
    );
  }

  Widget _cycleToggle() {
    Widget seg(String v, String label, {bool locked = false}) {
      final on = _cycle == v && !locked;
      return Expanded(
        child: GestureDetector(
          onTap: locked ? null : () => setState(() => _cycle = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: on ? C.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: locked
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.lock_outline_rounded, size: 13, color: C.muted(context, .4)),
                    const SizedBox(width: 5),
                    Text('Yillik · Tez kunda',
                        style: TextStyle(color: C.muted(context, .4), fontWeight: FontWeight.w600, fontSize: 13)),
                  ])
                : Text(label, style: TextStyle(
                    color: on ? Colors.white : C.muted(context, .7),
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: C.fill(context, .05), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [seg('monthly', 'Oylik'), seg('yearly', 'Yillik', locked: true)]),
    );
  }

  /// Tariflar bo'yicha ko'rsatiladigan xususiyatlar matritsasi (belgi/xoch).
  static const _matrix = [
    ('orgs', 'Tashkilotlar kuzatuvi'),
    ('risk', 'Risk balli va tekshiruv prognozi'),
    ('ai', 'Finn AI tavsiyalari'),
    ('counterparty', 'Kontragent tekshiruvi'),
    ('cadastre', 'Kadastr va mulk ma\'lumotlari'),
    ('audit', 'Audit jurnali va hisobotlar'),
    ('team', 'Jamoa uchun ko\'p foydalanuvchi'),
  ];

  Widget _planCard(Map<String, dynamic> p) {
    final slug = p['slug']?.toString() ?? '';
    final popular = p['popular'] == true;
    final isCurrent = p['is_current'] == true;
    final price = (p['monthly'] ?? 0) as num;
    final feats = ((p['features'] as List?) ?? []).map((e) => e.toString()).toSet();
    final free = price <= 0;
    final trial = free && slug != 'free' && (p['is_trial'] == true || slug == 'start');
    final borderColor = isCurrent ? C.green : (popular ? C.brand : C.border(context));

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor, width: (isCurrent || popular) ? 1.5 : 1),
        boxShadow: popular
            ? [BoxShadow(color: C.brand.withValues(alpha: .18), blurRadius: 28, offset: const Offset(0, 12))]
            : C.shadow(context),
      ),
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(p['name']?.toString() ?? slug,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -.4, color: C.text(context))),
              const SizedBox(width: 10),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: C.tint(context, C.green), borderRadius: BorderRadius.circular(20)),
                  child: Text('Joriy', style: TextStyle(color: C.onGrn(context), fontWeight: FontWeight.w600, fontSize: 11.5)),
                ),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text(free ? '0' : _fmt(price),
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: C.text(context),
                      letterSpacing: -1.4, fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(width: 6),
              Text('so\'m/oy', style: TextStyle(fontSize: 13, color: C.muted(context, .5), fontWeight: FontWeight.w500)),
            ]),
            if ((p['description']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(p['description'].toString(), style: TextStyle(fontSize: 13, color: C.muted(context, .6), height: 1.5)),
            ],
            const SizedBox(height: 16),
            ..._matrix.map((m) {
              final has = feats.contains(m.$1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(children: [
                  Container(
                    width: 19, height: 19, alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: has ? C.tint(context, C.green) : C.fill(context, .06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(has ? Icons.check_rounded : Icons.close_rounded,
                        size: 12, color: has ? C.onGrn(context) : C.muted(context, .35)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(m.$2,
                      style: TextStyle(fontSize: 13.5, height: 1.3,
                          color: has ? C.muted(context, .8) : C.muted(context, .4)))),
                ]),
              );
            }),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity, height: 48,
              child: isCurrent
                  ? DecoratedBox(
                      decoration: BoxDecoration(color: C.fill(context, .06), borderRadius: BorderRadius.circular(15)),
                      child: Center(child: Text('Joriy rejim',
                          style: TextStyle(color: C.muted(context, .55), fontWeight: FontWeight.w600, fontSize: 14.5))),
                    )
                  : (popular || trial)
                      ? _gradBtn(trial ? '14 kun bepul sinash' : 'Tanlash', () => _openPaymentSheet(p))
                      : GestureDetector(
                          onTap: _busy ? null : () => _openPaymentSheet(p),
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: C.fill(context, .06), borderRadius: BorderRadius.circular(15)),
                            child: Center(child: Text('Tanlash',
                                style: TextStyle(color: C.text(context), fontWeight: FontWeight.w600, fontSize: 14.5))),
                          ),
                        ),
            ),
            if (trial) ...[
              const SizedBox(height: 10),
              Center(child: Text('Karta talab qilinmaydi',
                  style: TextStyle(fontSize: 11.5, color: C.muted(context, .5)))),
            ],
          ]),
        ),
        if (popular)
          Positioned(
            top: 0, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
              decoration: const BoxDecoration(
                gradient: C.grad,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(9), bottomRight: Radius.circular(9)),
              ),
              child: const Text('KO\'P TANLANADI',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: .8)),
            ),
          ),
      ]),
    );
  }

  void _openPaymentSheet(Map<String, dynamic> plan) {
    final methods = [
      (id: 'payme', label: 'Payme', color: const Color(0xFF33CCCC), icon: Icons.credit_card),
      (id: 'click', label: 'Click', color: const Color(0xFF00A5EC), icon: Icons.credit_card),
      (id: 'uzum', label: 'Uzum Bank', color: const Color(0xFF7C3AED), icon: Icons.account_balance_wallet_outlined),
      (id: 'paynet', label: 'Paynet', color: const Color(0xFF1BA0E2), icon: Icons.account_balance_wallet_outlined),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.muted(context, .2), borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 16),
            Text('To\'lov usulini tanlang', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text(context))),
            const SizedBox(height: 4),
            Text('${plan['name']} · ${_fmt((_cycle == 'yearly' ? plan['yearly'] : plan['monthly']) as num)} so\'m',
                style: TextStyle(fontSize: 13, color: C.muted(context, .6))),
            const SizedBox(height: 16),
            ...methods.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () { Navigator.pop(ctx); _pay(plan, m.id); },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: C.fill(context, .04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: C.border(context)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: m.color.withValues(alpha: .15), borderRadius: BorderRadius.circular(11)),
                          child: Icon(m.icon, color: m.color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(m.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.text(context)))),
                        Icon(Icons.chevron_right, color: C.muted(context, .4)),
                      ]),
                    ),
                  ),
                )),
          ]),
        ),
      ),
    );
  }

  Future<void> _pay(Map<String, dynamic> plan, String provider) async {
    setState(() => _busy = true);
    try {
      final r = await Api.checkout(plan: plan['slug'].toString(), cycle: _cycle, provider: provider);
      if (r['ok'] != true) {
        _snack(r['message']?.toString() ?? 'To\'lovni yaratib bo\'lmadi');
        return;
      }
      final url = r['url']?.toString();
      if (url == null || url.isEmpty) {
        _snack('To\'lov havolasi olinmadi');
        return;
      }
      if (provider == 'uzum' || provider == 'paynet') {
        // To'lov ilovasini ochamiz (deep-link)
        final uri = Uri.tryParse(url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _snack('${provider == 'uzum' ? 'Uzum' : 'Paynet'} ilovasi topilmadi');
        }
      } else {
        // Payme/Click/bank — minimal to'lov sahifasi (WebView, faqat provayder)
        if (!mounted) return;
        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => _PaymentPage(url: url)),
        );
        if (paid == true) {
          await PlanState.i.load();
          _snack('To\'lov qabul qilindi ✓', ok: true);
          _load();
        }
      }
    } catch (e) {
      _snack('Xatolik yuz berdi');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m, {bool ok = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: ok ? C.green : null,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

/// Minimal to'lov sahifasi — faqat provayder checkout (PCI). Muvaffaqiyatda pop(true).
class _PaymentPage extends StatefulWidget {
  final String url;
  const _PaymentPage({required this.url});
  @override
  State<_PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<_PaymentPage> {
  WebViewController? _c;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onPageStarted: (u) {
          if (u.contains('/subscription/success')) Navigator.of(context).pop(true);
        },
        onNavigationRequest: (req) {
          if (req.url.contains('/subscription/success')) { Navigator.of(context).pop(true); return NavigationDecision.prevent; }
          final s = Uri.tryParse(req.url)?.scheme ?? '';
          if (s.isNotEmpty && s != 'http' && s != 'https') { launchUrl(Uri.parse(req.url), mode: LaunchMode.externalApplication); return NavigationDecision.prevent; }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        backgroundColor: C.bg(context),
        elevation: 0,
        title: const Text('To\'lov', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100, minHeight: 2, backgroundColor: Colors.transparent))
            : null,
      ),
      body: _c == null ? const SizedBox() : WebViewWidget(controller: _c!),
    );
  }
}
