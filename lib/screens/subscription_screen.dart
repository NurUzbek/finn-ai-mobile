import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/api.dart';
import '../services/plan.dart';

/// Ilova ichidagi tarif/to'lov ekrani.
///
/// Muhim: mobil ilova Bearer token bilan kiradi, WebView'da esa veb-sessiya yo'q.
/// Shuning uchun to'g'ridan-to'g'ri finn.uz/subscription ochilsa — login sahifasi
/// chiqadi (qayta SMS). Buning oldini olamiz: /api/v1/web-ticket bir martalik
/// chipta beradi, WebView `/app-auth?ticket=...` orqali AVTOMAT login bo'ladi.
/// To'lovdan keyin (`/subscription/success`) ilovaga qaytadi.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  WebViewController? _c;
  int _progress = 0;
  bool _error = false;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Chipta olib, avtomat login URL'ini yuklaymiz.
  Future<void> _bootstrap() async {
    String startUrl = PlanState.i.upgradeUrl; // zaxira: chipta bo'lmasa oddiy sahifa
    try {
      final r = await Api.webTicket();
      if (r['ok'] == true && r['ticket'] != null) {
        final base = (r['auth_url'] ?? 'https://finn.uz/app-auth').toString();
        startUrl = '$base?ticket=${r['ticket']}&to=${Uri.encodeComponent('/subscription?app=1')}';
      }
    } catch (_) {/* chipta bo'lmasa oddiy URL bilan davom etamiz */}

    final c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onPageStarted: (u) => mounted ? setState(() { _progress = 0; _error = false; }) : null,
        onPageFinished: (u) {
          if (mounted) setState(() => _progress = 100);
          if (_isSuccess(u)) _onPaid();
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) setState(() => _error = true);
        },
        onNavigationRequest: _onNav,
      ))
      ..loadRequest(Uri.parse(startUrl));

    if (mounted) setState(() => _c = c);
  }

  bool _isSuccess(String url) => url.contains('/subscription/success');

  /// Navigatsiyani boshqaramiz:
  ///  • To'lov muvaffaqiyatli — ilovaga qaytamiz
  ///  • Uzum/Paynet ilova havolalari — TASHQI ilovada ochamiz (WebView'da emas)
  ///  • Boshqa http/https (payme, click, finn.uz) — WebView ichida qoladi
  NavigationDecision _onNav(NavigationRequest req) {
    final url = req.url;
    if (_isSuccess(url)) { _onPaid(); return NavigationDecision.prevent; }

    final uri = Uri.tryParse(url);
    final scheme = uri?.scheme ?? '';
    final host = uri?.host ?? '';

    // http/https bo'lmagan sxemalar (uzum://, tel:, intent:) — tashqi
    final isAppScheme = scheme.isNotEmpty && scheme != 'http' && scheme != 'https';
    // Uzum/Paynet to'lov ilovasini ochadigan havolalar
    final isPayApp = host == 'app.paynet.uz' ||
        (host.contains('uzumbank.uz') && url.contains('open-service'));

    if (isAppScheme || isPayApp) {
      _launchExternal(url);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _launchExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// To'lov o'tdi — tarifni yangilab, ilovaga qaytamiz.
  Future<void> _onPaid() async {
    if (_paid) return;
    _paid = true;
    await PlanState.i.load(); // yangi tarif tortiladi
    if (!mounted) return;
    setState(() {});
  }

  void _reload() {
    setState(() { _error = false; _progress = 0; });
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    final p = PlanState.i;

    // To'lovdan keyin — tabrik ekrani
    if (_paid) return _paidView(context);

    return Scaffold(
      backgroundColor: C.bg(context),
      appBar: AppBar(
        backgroundColor: C.card(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Tariflar va to\'lov',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: C.text(context))),
        iconTheme: IconThemeData(color: C.text(context)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Yangilash', onPressed: _reload),
        ],
      ),
      body: Column(children: [
        if (p.loaded)
          Container(
            width: double.infinity,
            color: C.card(context),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: C.blue.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.workspace_premium, size: 16, color: C.cyan),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Joriy tarif', style: TextStyle(fontSize: 11, color: C.muted(context, .5))),
                Text(p.name + (p.daysLeft != null ? ' · ${p.daysLeft} kun qoldi' : ''),
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.text(context))),
              ])),
            ]),
          ),
        if (_progress < 100)
          LinearProgressIndicator(
            value: _progress == 0 ? null : _progress / 100,
            minHeight: 2.5,
            backgroundColor: C.fill(context, .06),
            color: C.cyan,
          ),
        Expanded(
          child: _error
              ? _errorView(context)
              : (_c == null
                  ? const Center(child: CircularProgressIndicator(color: C.cyan))
                  : WebViewWidget(controller: _c!)),
        ),
      ]),
    );
  }

  Widget _paidView(BuildContext context) => Scaffold(
        backgroundColor: C.bg(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: C.green.withValues(alpha: .12), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, size: 44, color: C.green),
              ),
              const SizedBox(height: 18),
              Text('To\'lov qabul qilindi',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.text(context))),
              const SizedBox(height: 6),
              Text('Tarifingiz faollashtirildi. Rahmat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: C.muted(context, .5))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.blue, C.cyan]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Ilovaga qaytish',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _errorView(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: C.red.withValues(alpha: .1), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 32, color: C.red),
            ),
            const SizedBox(height: 16),
            Text('Sahifa yuklanmadi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.text(context))),
            const SizedBox(height: 6),
            Text('Internet aloqasini tekshiring va qayta urinib ko\'ring',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: C.muted(context, .5))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [C.blue, C.cyan]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  label: const Text('Qayta urinish',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        ),
      );
}

/// Tarif ekranini ochish uchun yordamchi — barcha "Kengaytirish" tugmalari shuni chaqiradi.
void openSubscription(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
  );
}
