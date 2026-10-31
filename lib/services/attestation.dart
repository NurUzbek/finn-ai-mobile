import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'api.dart';

/// Server-side attestatsiya — RASP (freeRASP) himoyasining "langari".
///
/// Klientdagi root/Frida tekshiruvini Frida bilan chetlab o'tish mumkin
/// (Kiberxavfsizlik markazi xulosasi). Shuning uchun ishonch qarori serverda:
///   • Android → Google Play Integrity (Google imzolagan token)
///   • iOS     → Apple App Attest (Secure Enclave kaliti)
/// finn.uz tokenni o'zi tekshiradi; yaroqsiz bo'lsa API 428 qaytaradi va
/// ma'lumot bermaydi — klientni ochish hech narsa bermaydi.
///
/// Native qism: android/.../PlayIntegrityPlugin.kt, ios/Runner/AppDelegate.swift
/// (MethodChannel 'uz.finn.app/attest').
class Attestation {
  Attestation._();

  static const _ch = MethodChannel('uz.finn.app/attest');

  /// Server 6 soat ishonadi; mijoz 5 soatda yangilaydi.
  static DateTime? _lastOk;
  static const _ttl = Duration(hours: 5);

  /// Bir vaqtda bitta attestatsiya: server foydalanuvchiga bitta nonce
  /// saqlaydi, parallel urinishlar bir-birining nonce'ini buzardi.
  static Future<void>? _inflight;

  static Future<void> ensure({bool force = false}) {
    if (kIsWeb) return Future.value();
    if (!force && _lastOk != null && DateTime.now().difference(_lastOk!) < _ttl) {
      return Future.value();
    }
    return _inflight ??= _run().whenComplete(() => _inflight = null);
  }

  static Future<void> _run() async {
    final nonce = await Api.attestNonce();
    if (nonce.isEmpty) throw const AttestationException('nonce');

    if (Platform.isAndroid) {
      await _android(nonce);
    } else if (Platform.isIOS) {
      await _ios(nonce);
    } else {
      return;
    }
    _lastOk = DateTime.now();
  }

  // ── Android: Play Integrity (Standard request, requestHash = SHA-256(nonce)) ──
  static Future<void> _android(String nonce) async {
    final String token;
    try {
      token = await _ch.invokeMethod<String>('playIntegrityToken', {'requestHash': nonce}) ?? '';
    } on PlatformException catch (e) {
      // Google Play xizmatlari yo'q / Play Integrity ishlamadi — xavfsiz tomon
      throw AttestationException('android:${e.code}');
    }
    if (token.isEmpty) throw const AttestationException('android_empty');

    final ok = await Api.attestVerify('android', {'token': token, 'nonce': nonce});
    if (!ok) throw const AttestationException('android_rejected');
  }

  // ── iOS: App Attest (birinchi marta attest, keyin assert) ──
  static Future<void> _ios(String nonce) async {
    final supported = await _ch.invokeMethod<bool>('appAttestSupported') ?? false;
    if (!supported) throw const AttestationException('ios_unsupported');

    final keyId = await Api.attestKeyId();
    if (keyId == null) {
      final res = await _ch.invokeMapMethod<String, dynamic>('appAttestKey', {'challenge': nonce});
      final newKey = res?['keyId'] as String? ?? '';
      final attestation = res?['attestation'] as String? ?? '';
      if (newKey.isEmpty || attestation.isEmpty) throw const AttestationException('ios_attest_empty');

      final ok = await Api.attestVerify('ios_attest', {'keyId': newKey, 'attestation': attestation, 'nonce': nonce});
      if (!ok) throw const AttestationException('ios_attest_rejected');
      await Api.saveAttestKeyId(newKey);
      return;
    }

    final res = await _ch.invokeMapMethod<String, dynamic>('appAttestAssert', {'keyId': keyId, 'challenge': nonce});
    final assertion = res?['assertion'] as String? ?? '';
    if (assertion.isEmpty) throw const AttestationException('ios_assert_empty');

    final ok = await Api.attestVerify('ios_assert', {'keyId': keyId, 'assertion': assertion, 'nonce': nonce});
    if (!ok) {
      // Kalit serverda yo'q (masalan, boshqa akkaunt) — keyingi safar qayta attest
      await Api.saveAttestKeyId(null);
      throw const AttestationException('ios_assert_rejected');
    }
  }
}

class AttestationException implements Exception {
  final String reason;
  const AttestationException(this.reason);
  @override
  String toString() => 'AttestationException($reason)';
}
