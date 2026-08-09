import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// O'rnatishdan keyingi ruxsatlar.
/// FAQAT kamera so'raladi. Galereya — Photo Picker orqali ruxsatsiz.
/// Bildirishnoma/SMS/media ruxsatlari sideload (finn.uz/app) APK'da SO'RALMAYDI:
/// Google Play Protect ularni "moliyaviy firibgarlik" deb bloklaydi.
/// Bu ruxsatlar Play Market versiyasida qo'shiladi.
class Permits {
  Permits._();
  static const _askedKey = 'perms_asked_v1';

  static Future<void> requestOnFirstLaunch() async {
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(_askedKey) == true) return;
    await Permission.camera.request();
    await sp.setBool(_askedKey, true);
  }

  /// Kamera ruxsati (avatarga rasmga tushishdan oldin).
  static Future<bool> ensureCamera() async {
    final s = await Permission.camera.request();
    return s.isGranted || s.isLimited;
  }
}
