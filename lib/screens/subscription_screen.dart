import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../services/plan.dart';

/// Ilova ichidagi tarif/to'lov ekrani.
/// finn.uz obuna sahifasini WebView'da ochadi — foydalanuvchi tariflarni ko'rib,
/// ilovadan chiqmasdan to'lovni amalga oshira oladi.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});
  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final WebViewController _c;
  int _progress = 0;
  bool _error = false;

  String get _url => PlanState.i.upgradeUrl;

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
        onPageStarted: (_) => mounted ? setState(() { _progress = 0; _error = false; }) : null,
        onPageFinished: (_) => mounted ? setState(() => _progress = 100) : null,
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) setState(() => _error = true);
        },
      ))
      ..loadRequest(Uri.parse(_url));
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(_url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _reload() {
    setState(() { _error = false; _progress = 0; });
    _c.loadRequest(Uri.parse(_url));
  }

  @override
  Widget build(BuildContext context) {
    final p = PlanState.i;
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
          IconButton(icon: const Icon(Icons.open_in_new), tooltip: 'Brauzerda ochish', onPressed: _openExternal),
        ],
      ),
      body: Column(children: [
        // Joriy tarif konteksti
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
              : WebViewWidget(controller: _c),
        ),
      ]),
    );
  }

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
            const SizedBox(height: 10),
            TextButton(onPressed: _openExternal, child: const Text('Brauzerda ochish')),
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
