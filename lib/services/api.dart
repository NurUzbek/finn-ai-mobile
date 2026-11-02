import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'push_service.dart';
import 'pinned_http.dart';
import 'endpoints.dart';
import 'attestation.dart';

/// FINN AI backend API klienti (Laravel Sanctum Bearer token).
/// Token Keychain (iOS) / Keystore (Android, EncryptedSharedPreferences) da
/// shifrlangan holda saqlanadi — ekspertiza 2.2.4 / TZ talabi.
/// Barcha so'rovlar SSL pinning qilingan klient orqali ketadi — ekspertiza 2.2.3.
class Api {
  /// Manzil kodda ochiq yozilmaydi — ekspertiza 2.2.7 (endpoints.dart).
  static final String base = Ep.api;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? _token;

  static Future<String?> get token async => _token ??= await _storage.read(key: 'token');
  static Future<void> setToken(String t) async {
    _token = t;
    // Server attestatsiyani sessiya (token) ga bog'laydi — yangi token o'zi o'tsin.
    Attestation.reset();
    await _storage.write(key: 'token', value: t);
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'token');
    // App Attest kaliti serverda foydalanuvchiga bog'langan — boshqa akkaunt
    // kirganda yangi kalit attest qilinsin.
    await _storage.delete(key: 'attest_key');
  }

  // ── Server-side attestatsiya (attestation.dart) ──
  static Future<String> attestNonce() async =>
      (await _req('GET', '/attest/nonce', attest: false))['nonce'] as String? ?? '';

  /// {'attested': bool, 'code'?: 'tampered'|'device'} — code faqat Google
  /// tasdiqlagan hukmda keladi (server sessiyani allaqachon o'chirgan).
  static Future<Map<String, dynamic>> attestVerify(String platform, Map<String, dynamic> payload) =>
      _req('POST', '/attest/verify', body: {'platform': platform, ...payload}, attest: false);

  static Future<String?> attestKeyId() => _storage.read(key: 'attest_key');
  static Future<void> saveAttestKeyId(String? id) =>
      id == null ? _storage.delete(key: 'attest_key') : _storage.write(key: 'attest_key', value: id);

  /// Profil rasmini yuklash (multipart). bytes + fayl nomi (png/jpg/heic).
  /// Format tekshiruvi backendda ham bor — qolgan formatlar rad etiladi.
  static Future<Map<String, dynamic>> uploadAvatar(
      List<int> bytes, String filename) async {
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$base${Ep.avatar}'));
      req.headers['Accept'] = 'application/json';
      final t = await token;
      if (t != null) req.headers['Authorization'] = 'Bearer $t';
      // Aniq Content-Type — web'da server mime'ni to'g'ri aniqlashi uchun.
      final ext = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'jpg';
      const mimes = {
        'png': ['image', 'png'], 'jpg': ['image', 'jpeg'], 'jpeg': ['image', 'jpeg'],
        'heic': ['image', 'heic'], 'heif': ['image', 'heif'],
      };
      final mt = mimes[ext] ?? ['image', 'jpeg'];
      req.files.add(http.MultipartFile.fromBytes('image', bytes,
          filename: filename, contentType: MediaType(mt[0], mt[1])));
      final client = await PinnedHttp.client();
      final streamed = await client.send(req).timeout(const Duration(seconds: 45));
      final resp = await http.Response.fromStream(streamed);
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {'ok': false, 'message': 'Rasm yuklashda xato'};
    }
  }

  /// Qurilma identifikatori va nomi — yangi qurilmadan kirishda SMS ogohlantirish uchun.
  static Future<Map<String, String>> deviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return {'device_id': a.id, 'device_name': '${a.manufacturer} ${a.model} (Android ${a.version.release})'};
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return {'device_id': i.identifierForVendor ?? 'ios', 'device_name': '${i.name} (iOS ${i.systemVersion})'};
      }
    } catch (_) {}
    return {'device_id': 'unknown', 'device_name': 'Mobil qurilma'};
  }

  static Future<Map<String, dynamic>> _req(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool attest = true,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final uri = Uri.parse('$base$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }

    late http.Response r;
    // Yagona pinned klient — YOPILMAYDI (ilova davomida qayta ishlatiladi).
    final client = await PinnedHttp.client();
    try {
      // followRedirects: false — POST redirect'ga tushib GET'ga aylanishini oldini olamiz
      // (aks holda "GET method not supported" xatosi chiqadi).
      final request = http.Request(method, uri)
        ..headers.addAll(headers)
        ..followRedirects = false;
      if (method == 'POST') request.body = jsonEncode(body ?? {});
      final streamed = await client.send(request).timeout(timeout);
      r = await http.Response.fromStream(streamed);
    } catch (e) {
      return {'ok': false, 'message': 'Internetga ulanib bo\'lmadi'};
    }
    // Server noto'g'ri redirect qilsa (Accept yo'qligidan) — aniq xabar
    if (r.statusCode >= 300 && r.statusCode < 400) {
      return {'ok': false, 'message': 'Server javobi noto\'g\'ri. Ilovani yangilang.'};
    }

    if (r.statusCode == 401) {
      await clearToken();
      return {'ok': false, 'message': 'Sessiya tugadi. Qaytadan kiring.', 'unauthorized': true};
    }
    // 428 — server qurilma attestatsiyasini so'rayapti: bir marta attest qilib,
    // so'rovni qayta yuboramiz. Muvaffaqiyatsiz bo'lsa ma'lumot berilmaydi.
    if (r.statusCode == 428 && attest) {
      try {
        await Attestation.ensure(force: true);
      } catch (_) {
        return {'ok': false, 'message': 'Qurilma xavfsizlik tekshiruvidan o\'tmadi.', 'attestation': false};
      }
      return _req(method, path, body: body, auth: auth, attest: false, timeout: timeout);
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(r.body));
    } catch (_) {
      return {'ok': false, 'message': 'Server xatosi (${r.statusCode})'};
    }
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> sendCode(String phone) =>
      _req('POST', '/auth/send-code', body: {'phone': phone}, auth: false);

  static Future<Map<String, dynamic>> verify(String phone, String code) async {
    final d = await deviceInfo();
    final res = await _req('POST', '/auth/verify',
        body: {'phone': phone, 'code': code, ...d}, auth: false);
    if (res['ok'] == true && res['token'] != null) await setToken(res['token']);
    return res;
  }

  static Future<void> logout() async {
    try { await PushService.unregister(); } catch (_) {}
    await _req('POST', '/auth/logout');
    await clearToken();
  }

  // ── Ma'lumotlar ──
  static Future<Map<String, dynamic>> me() => _req('GET', '/me');
  static Future<Map<String, dynamic>> devices() async {
    // O'z qurilma ma'lumotini yuboramiz — joriy qurilma BATAFSIL model bilan ko'rinadi.
    final di = await deviceInfo();
    final did = Uri.encodeComponent(di['device_id'] ?? '');
    final dn = Uri.encodeComponent(di['device_name'] ?? '');
    return _req('GET', '/devices?did=$did&dn=$dn');
  }
  static Future<Map<String, dynamic>> revokeDevice(int id) =>
      _req('POST', '/devices/$id/revoke');

  /// Ism/familiya + email tahrirlash. Telefon va JSHSHIR OneID orqali — o'zgartirilmaydi.
  static Future<Map<String, dynamic>> updateProfile({required String name, String? email}) =>
      _req('POST', '/profile', body: {'name': name, if (email != null) 'email': email});
  static Future<Map<String, dynamic>> plan() => _req('GET', '/plan');
  static Future<Map<String, dynamic>> plans() => _req('GET', '/plans');
  // ── Veb parity modullari ──
  static Future<Map<String, dynamic>> financial() => _req('GET', '/financial');
  static Future<Map<String, dynamic>> wallet() => _req('GET', '/wallet');
  static Future<Map<String, dynamic>> documents() => _req('GET', '/documents');
  static Future<Map<String, dynamic>> currency() => _req('GET', '/currency');
  static Future<Map<String, dynamic>> didox() => _req('GET', '/didox');
  static Future<Map<String, dynamic>> counterparty() => _req('GET', '/counterparty');
  static Future<Map<String, dynamic>> enforcement() => _req('GET', '/enforcement');
  static Future<Map<String, dynamic>> reports() => _req('GET', '/reports');
  static Future<Map<String, dynamic>> employees() => _req('GET', '/employees');
  static Future<Map<String, dynamic>> team() => _req('GET', '/team');
  static Future<Map<String, dynamic>> auditReport() => _req('GET', '/audit-report');
  static Future<Map<String, dynamic>> calendar({int? year}) => _req('GET', year == null ? '/calendar' : '/calendar?year=$year');
  static Future<Map<String, dynamic>> checkout({
    required String plan, required String cycle, required String provider, int? organizationId,
  }) => _req('POST', '/checkout', body: {
    'plan': plan, 'cycle': cycle, 'provider': provider,
    if (organizationId != null) 'organization_id': organizationId,
  });
  // WebView'da veb-sessiyani ochish uchun bir martalik chipta
  static Future<Map<String, dynamic>> webTicket() => _req('POST', '/web-ticket');

  // ── Push (TZ 4.2.2) ──
  static Future<Map<String, dynamic>> registerPush(String fcmToken, String platform) async {
    final di = await deviceInfo();
    return _req('POST', '/push/register',
        body: {'token': fcmToken, 'platform': platform, 'device_id': di['device_id'] ?? ''});
  }

  static Future<Map<String, dynamic>> unregisterPush(String fcmToken) =>
      _req('POST', '/push/unregister', body: {'token': fcmToken});
  static Future<Map<String, dynamic>> dashboard() => _req('GET', '/dashboard');

  // ── Qo'shish (yaratish) ──
  static Future<Map<String, dynamic>> addFinancial({
    required String type, required num amount, String? category, String? description,
  }) => _req('POST', '/financial', body: {
    'type': type, 'amount': amount,
    if (category != null) 'category': category,
    if (description != null && description.isNotEmpty) 'description': description,
  });
  static Future<Map<String, dynamic>> addEmployee({required String fullName, String? position}) =>
      _req('POST', '/employees', body: {'full_name': fullName, if (position != null) 'position': position});
  static Future<Map<String, dynamic>> addOrganization({required String name, String? stir}) =>
      _req('POST', '/organizations', body: {'name': name, if (stir != null && stir.isNotEmpty) 'stir': stir});
  static Future<Map<String, dynamic>> organizations() => _req('GET', '/organizations');
  static Future<Map<String, dynamic>> tax() => _req('GET', '/tax');
  static Future<Map<String, dynamic>> risk({int? org}) =>
      _req('GET', org == null ? '/risk' : '/risk?org=$org');
  static Future<Map<String, dynamic>> notifications() => _req('GET', '/notifications');
  static Future<Map<String, dynamic>> markRead() => _req('POST', '/notifications/read');

  // ── AI konsultant (lokal Ollama + RAG) ──
  /// Suhbat tarixini yuboradi. CPU inferens sekin (~10-30s) — 120s timeout.
  static Future<Map<String, dynamic>> aiChat(List<Map<String, String>> messages) =>
      _req('POST', '/ai', body: {'messages': messages}, timeout: const Duration(seconds: 120));
}
