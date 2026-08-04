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

  ({IconData icon, Color color}) _style(String slug) => switch (slug) {
        'test' => (icon: Icons.science_outlined, color: C.amber),
        'start' => (icon: Icons.verified_user_outlined, color: C.green),
        'standart' => (icon: Icons.bolt_outlined, color: C.blue),
        'optimal' => (icon: Icons.workspace_premium_outlined, color: C.cyan),
        'business' => (icon: Icons.apartment_outlined, color: C.violet),
        'enterprise' => (icon: Icons.diamond_outlined, color: C.sky),
        _ => (icon: Icons.star_outline, color: C.blue),
      };

  @override
  Widget build(BuildContext context) {
    final hasYearly = _plans.any((p) => ((p['yearly'] ?? 0) as num) > 0);
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
                      const SizedBox(height: 24),
                      if (hasYearly) _cycleToggle(),
                      if (hasYearly) const SizedBox(height: 16),
                      ..._plans.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _planCard(p as Map<String, dynamic>),
                          )),
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
    Widget seg(String v, String label) {
      final on = _cycle == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _cycle = v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: on ? C.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(
              color: on ? Colors.white : C.muted(context, .7),
              fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: C.fill(context, .05), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [seg('monthly', 'Oylik'), seg('yearly', 'Yillik  −20%')]),
    );
  }

  Widget _planCard(Map<String, dynamic> p) {
    final slug = p['slug']?.toString() ?? '';
    final st = _style(slug);
    final popular = p['popular'] == true;
    final isCurrent = p['is_current'] == true;
    final price = (_cycle == 'yearly' ? (p['yearly'] ?? 0) : (p['monthly'] ?? 0)) as num;
    final feats = ((p['features'] as List?) ?? []).cast<dynamic>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: C.card(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: popular ? st.color.withValues(alpha: .45) : C.border(context)),
        boxShadow: popular
            ? [BoxShadow(color: st.color.withValues(alpha: .18), blurRadius: 28, offset: const Offset(0, 12))]
            : [BoxShadow(color: Colors.black.withValues(alpha: C.isDark(context) ? .25 : .05), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: st.color.withValues(alpha: .14), borderRadius: BorderRadius.circular(15)),
            child: Icon(st.icon, color: st.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(p['name']?.toString() ?? slug,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text(context)))),
          if (popular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: st.color, borderRadius: BorderRadius.circular(999)),
              child: const Text('Ommabop', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(price > 0 ? _fmt(price) : 'Bepul',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: C.text(context),
                  letterSpacing: -1, fontFeatures: const [FontFeature.tabularFigures()])),
          if (price > 0) ...[
            const SizedBox(width: 6),
            Text(_cycle == 'yearly' ? 'so\'m/yil' : 'so\'m/oy',
                style: TextStyle(fontSize: 13, color: C.muted(context, .55), fontWeight: FontWeight.w600)),
          ],
        ]),
        if ((p['description']?.toString() ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(p['description'].toString(), style: TextStyle(fontSize: 13, color: C.muted(context, .6), height: 1.4)),
        ],
        if (feats.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...feats.take(5).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.check_circle, size: 17, color: C.green),
                  const SizedBox(width: 9),
                  Expanded(child: Text(f.toString(),
                      style: TextStyle(fontSize: 13.5, color: C.muted(context, .8), height: 1.35))),
                ]),
              )),
        ],
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity, height: 50,
          child: isCurrent
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: C.border(context, .12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Joriy tarif', style: TextStyle(color: C.muted(context, .5), fontWeight: FontWeight.w700)))
              : popular
                  ? FilledButton(
                      onPressed: _busy ? null : () => _openPaymentSheet(p),
                      style: FilledButton.styleFrom(
                        backgroundColor: st.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Tanlash', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)))
                  : OutlinedButton(
                      onPressed: _busy ? null : () => _openPaymentSheet(p),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: st.color.withValues(alpha: .5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Tanlash', style: TextStyle(color: st.color, fontWeight: FontWeight.w800, fontSize: 15))),
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
