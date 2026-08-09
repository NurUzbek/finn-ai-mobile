import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api.dart';
import 'notifs.dart';

/// PUSH BILDIRISHNOMA (FCM) — TZ 4.2.2.
///
/// «Ma'lumotlar integratsiyasi — tizimga o'zgarish kuzatilganda push servis
/// shaklida.» Server (finn-ec317) NotificationService orqali FCM'ga yuboradi,
/// bu servis token oladi, /api/v1/push/register ga yozadi va kelgan xabarni
/// ilova old planda bo'lganda lokal bildirishnoma sifatida ko'rsatadi.
///
/// Firebase konfiguratsiyasi: android/app/google-services.json (uz.finn.app).
class PushService {
  static final _fm = FirebaseMessaging.instance;
  static String? _token;
  static bool _inited = false;

  /// Ilova ishga tushganda (main) bir marta chaqiriladi.
  static Future<void> init() async {
    if (_inited) return;
    try {
      await Firebase.initializeApp();
      _inited = true;
    } catch (_) {
      return; // Firebase yo'q bo'lsa jim o'tadi — ilova ishlayveradi
    }

    // Old planda kelgan xabarni lokal bildirishnoma qilib ko'rsatamiz
    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  /// Login MUVAFFAQIYATLI bo'lgach chaqiriladi — ruxsat so'rab, tokenni
  /// serverga bog'laydi. (Token faqat autentifikatsiyadan keyin yuboriladi.)
  static Future<void> registerAfterLogin() async {
    if (!_inited) await init();
    if (!_inited) return;

    try {
      await _fm.requestPermission(alert: true, badge: true, sound: true);

      _token = await _fm.getToken();
      if (_token != null) {
        await Api.registerPush(_token!, Platform.isIOS ? 'ios' : 'android');
      }

      // Token yangilansa — qayta ro'yxatdan o'tkazamiz
      FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
        _token = t;
        try {
          await Api.registerPush(t, Platform.isIOS ? 'ios' : 'android');
        } catch (_) {}
      });
    } catch (_) {
      // ruxsat berilmasa yoki token olinmasa — boshqa kanallar (ilova ichi/SMS) ishlaydi
    }
  }

  /// Chiqishda tokenni serverdan uzamiz (boshqa odam bu qurilmaga push olmasin).
  static Future<void> unregister() async {
    try {
      final t = _token ?? await _fm.getToken();
      if (t != null) await Api.unregisterPush(t);
      await _fm.deleteToken();
      _token = null;
    } catch (_) {}
  }

  static Future<void> _showForeground(RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return;
    await Notifs.i.init();
    await Notifs.i.showRaw(
      n.title ?? 'FINN AI',
      n.body ?? '',
    );
  }
}
