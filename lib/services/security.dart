import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:freerasp/freerasp.dart';

import 'api.dart';
import 'lock.dart';

/// Ilova ishlash muhitini himoyalash — RASP (Runtime Application Self-Protection).
///
/// Ekspertiza bandlari, bitta native kutubxona (freeRASP / Talsec) bilan:
///   2.2.1  Root tekshiruvi            → onPrivilegedAccess
///   2.3.2  Jailbreak tekshiruvi       → onPrivilegedAccess
///   2.2.2  Hook'dan himoya (Android)  → onHooks   (Frida, Xposed, LSPosed...)
///   2.3.1  Hook'dan himoya (iOS)      → onHooks
///   2.2.5  Ilova yaxlitligi           → onAppIntegrity (qayta yig'ish/imzolash)
///   2.2.6  Emulyator tekshiruvi       → onSimulator
///
/// Tekshiruvlar Dart'da emas, native (C/C++/Kotlin/Swift) darajada bajariladi.
/// `killOnBypass` yoqilgan: kimdir callback'larni hook bilan o'chirib qo'ysa,
/// ilova o'zini to'xtatadi.
///
/// IKKINCHI, MUSTAQIL QATLAM (Android, DeviceSecurityPlugin.kt): himoya bitta
/// kutubxonaga (Talsec) bog'lanib qolmasligi uchun native Kotlin o'z-o'zi
/// root/debugger/hook/imzo yaxlitligini qaytadan tekshiradi. Bitta Frida hook
/// faqat freeRASP'ni nishonga olsa, bu qatlam baribir ishlaydi (va aksincha).
/// Uchinchi — eng kuchli — qatlam: server-side attestatsiya (attestation.dart).
///
/// Xavf aniqlanganda: token va PIN darhol o'chiriladi (server sessiyasi ham
/// yaroqsiz bo'ladi), ilova esa bloklovchi ekranni ko'rsatadi.
class Security {
  Security._();

  /// Aniqlangan xavf turi; null — muhit toza. UI shuni tinglaydi.
  static final ValueNotifier<String?> threat = ValueNotifier(null);

  static bool _started = false;

  static Future<void> init() async {
    // Web'da RASP yo'q; debug'da esa debugger/emulyator doim bor — o'chiq.
    if (kIsWeb || kDebugMode || _started) return;
    _started = true;

    Future<void> block(String type) async {
      if (threat.value != null) return;
      threat.value = type;
      try {
        await Api.clearToken();
        await Lock.clear();
      } catch (_) {}
    }

    // ── Ikkinchi, MUSTAQIL qatlam (Android) ──
    // freeRASP'ga qo'shimcha: native Kotlin o'z tekshiruvini bajaradi
    // (root, debugger, hook, imzo yaxlitligi). Himoya bitta kutubxonaga
    // bog'lanib qolmaydi — bir hook bilan hammasini o'chirib bo'lmaydi.
    _nativeCheck(block);

    await Talsec.instance.attachListener(ThreatCallback(
      // ── bloklanadi ──
      onPrivilegedAccess: () => block('root'),
      onHooks: () => block('hook'),
      onAppIntegrity: () => block('integrity'),
      onSimulator: () => block('emulator'),
      onDebug: () => block('debug'),

      // Ilova ma'lumotlari boshqa qurilmaga ko'chirilgan (zaxira nusxadan
      // tiklash, klonlash) — tokenni o'g'irlash belgisi. Bloklamaymiz, lekin
      // sessiyani yopamiz: foydalanuvchi qaytadan kiradi.
      onDeviceBinding: () {
        Api.clearToken();
        Lock.clear();
      },

      // ── ATAYLAB bloklanmaydi ──
      // APK finn.uz/app orqali tarqatiladi (Play Store emas) — bu signal
      // barcha haqiqiy foydalanuvchilarda chiqadi.
      onUnofficialStore: () {},
      // Dasturchi rejimi / ADB / VPN / ochiq Wi-Fi oddiy foydalanuvchilarda
      // ham keng tarqalgan; ular hujum belgisi emas.
      onDevMode: () {},
      onADBEnabled: () {},
      onSystemVPN: () {},
      onUnsecureWiFi: () {},
      onPasscode: () {},
      onSecureHardwareNotAvailable: () {},
    ));

    await Talsec.instance.start(TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'uz.finn.app',
        // Upload-keystore SHA-256 (base64). DIQQAT: ilova Google Play'ga
        // "Play App Signing" bilan yuklansa, Google o'z kaliti bilan qayta
        // imzolaydi — o'shanda Play Console → App integrity'dagi SHA-256 ni
        // ham shu ro'yxatga QO'SHISH SHART, aks holda yaxlitlik tekshiruvi
        // barcha Play foydalanuvchilarini bloklaydi.
        signingCertHashes: const [
          'j7mLhbvRfbzqX6c2akR9l1g3l6lPT8sbCsdPT9TY4xk=', // finn.uz upload kaliti (sideload)
          'bZCeu8rBIOqfWyQyQnHCPB/GMtEU+PZuUPaJ23+Qwdo=', // Play App Signing kaliti
        ],
      ),
      iosConfig: IOSConfig(
        bundleIds: const ['uz.finn.app'],
        teamId: 'P3M4C953PC',
      ),
      watcherMail: 'info@finn.uz',
      isProd: true,
      killOnBypass: true,
    ));
  }

  static const _devsec = MethodChannel('uz.finn.app/devsec');

  /// freeRASP'dan mustaqil native tekshiruv (DeviceSecurityPlugin.kt).
  /// Android-only; natija — aniqlangan xavflar ro'yxati. Topilsa bloklanadi.
  static Future<void> _nativeCheck(Future<void> Function(String) block) async {
    if (!Platform.isAndroid) return;
    try {
      final flags = await _devsec.invokeListMethod<String>('check') ?? const [];
      // integrity/root/debug/hook — freeRASP bilan bir xil turlar, bloklaydi
      for (final f in flags) {
        await block(f);
      }
    } catch (_) {
      // native qatlam javob bermasa, freeRASP qatlami ishlashda davom etadi
    }
  }
}
