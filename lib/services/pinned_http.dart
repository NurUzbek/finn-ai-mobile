import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// SSL pinning (ekspertiza 2.2.3 — «Xavfsiz bo'lmagan sertifikat tekshiruvi»).
///
/// FINN serveriga ketadigan ulanishlar tizimdagi umumiy CA ombori o'rniga
/// FAQAT FINN sertifikati chiqqan ildiz CA'larga ishonadi. Qurilmaga o'rnatilgan
/// begona CA (Burp Suite, mitmproxy, Charles) bilan imzolangan sertifikat rad
/// etiladi — trafikni ushlab o'qish (MITM) imkonsiz, hatto CA tizim omboriga
/// root orqali qo'shilgan bo'lsa ham.
///
/// QAMROV — finn.uz'ga ketadigan barcha trafik:
///   • API so'rovlari va token        → [client]
///   • avatar rasmlari                → PinnedImage (widgets/pinned_image.dart)
///   • OneID WebView                  → Android network_security_config pin-set
/// Uchinchi tomon hostlari (masalan, Google shriftlari) ataylab tegilmaydi —
/// global override ularni ham ISRG ildizlariga cheklab, buzib qo'yardi.
///
/// Nega barg sertifikat (finn.uz) pin qilinmaydi: Let's Encrypt uni har 90
/// kunda almashtiradi — barg pin qilinsa, ilova o'sha kuni ishlamay qolardi.
/// Buning o'rniga Let's Encrypt'ning to'rtta MUSTAQIL ildizi pin qilinadi —
/// bittasi o'zgarsa, qolganlari zaxira vazifasini bajaradi:
///   • ISRG Root X1  — 2035-yilgacha (RSA, eski avlod)
///   • ISRG Root X2  — 2040-yilgacha (ECDSA, eski avlod)
///   • Root YE       — 2045-yilgacha (ECDSA, Gen Y)
///   • Root YR       — 2045-yilgacha (RSA, Gen Y)
/// Joriy zanjir: finn.uz ← YE1 ← Root YE ← ISRG Root X2 ← ISRG Root X1.
/// Gen Y ildizlari kross-imzolar olib tashlansa ham ilova ishlashini kafolatlaydi.
/// Sinov: finn.uz → qabul; google.com / microsoft.com → rad (begona CA).
class PinnedHttp {
  PinnedHttp._();

  static const _roots = [
    'assets/certs/isrg_root_x1.pem',
    'assets/certs/isrg_root_x2.pem',
    'assets/certs/lets_encrypt_root_ye.pem',
    'assets/certs/lets_encrypt_root_yr.pem',
  ];

  static http.Client? _client;
  static Future<http.Client>? _building;

  /// Host FINN serverimi — shu hostlar uchun pinning majburiy.
  static bool isFinnHost(String host) => host == 'finn.uz' || host.endsWith('.finn.uz');

  /// FINN serveri uchun YAGONA pinned klient. Uni YOPMANG — ilova davomida
  /// qayta ishlatiladi (har so'rovda TLS kontekstini qayta qurmaslik uchun).
  static Future<http.Client> client() {
    final c = _client;
    if (c != null) return Future.value(c);
    // Bir vaqtda kelgan birinchi so'rovlar kontekstni ikki marta qurmasin.
    return _building ??= _build();
  }

  static Future<http.Client> _build() async {
    if (kIsWeb) return _client = http.Client(); // brauzer o'z TLS'ini boshqaradi

    final ctx = SecurityContext(withTrustedRoots: false);
    for (final path in _roots) {
      final data = await rootBundle.load(path);
      ctx.setTrustedCertificatesBytes(data.buffer.asUint8List());
    }

    final hc = HttpClient(context: ctx)
      ..connectionTimeout = const Duration(seconds: 20)
      // Yaroqsiz sertifikatni HECH QACHON qabul qilmaymiz — chetlab o'tish yo'q.
      // Lambda qavsda: aks holda keyingi `..` kaskad lambda tanasiga (bool'ga)
      // qo'llanib qolardi.
      ..badCertificateCallback = ((cert, host, port) => false);

    return _client = IOClient(hc);
  }
}
