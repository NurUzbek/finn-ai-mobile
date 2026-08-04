import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// FINN AI backend API klienti (Laravel Sanctum Bearer token).
/// Token Keychain (iOS) / Keystore (Android) da shifrlangan holda saqlanadi — TZ talabi.
class Api {
  static const String base = 'https://finn.uz/api/v1';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static String? _token;

  static Future<String?> get token async => _token ??= await _storage.read(key: 'token');
  static Future<void> setToken(String t) async {
    _token = t;
    await _storage.write(key: 'token', value: t);
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: 'token');
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
    try {
      switch (method) {
        case 'POST':
          r = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(timeout);
          break;
        default:
          r = await http.get(uri, headers: headers).timeout(timeout);
      }
    } catch (e) {
      return {'ok': false, 'message': 'Internetga ulanib bo\'lmadi'};
    }

    if (r.statusCode == 401) {
      await clearToken();
      return {'ok': false, 'message': 'Sessiya tugadi. Qaytadan kiring.', 'unauthorized': true};
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
    await _req('POST', '/auth/logout');
    await clearToken();
  }

  // ── Ma'lumotlar ──
  static Future<Map<String, dynamic>> me() => _req('GET', '/me');
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
  static Future<Map<String, dynamic>> dashboard() => _req('GET', '/dashboard');
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
