import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Ilova qulfi — 4 xonali PIN + biometrika (Face ID / barmoq izi).
/// Yangi o'rnatishda: SMS orqali kirish. Keyingi ochishlarda: PIN yoki biometrika.
class Lock {
  static const _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _pinKey = 'app_pin';
  static const _bioKey = 'app_bio';
  static final _auth = LocalAuthentication();

  static String _h(String s) => sha256.convert(utf8.encode('finn.lock.$s')).toString();

  static Future<bool> hasPin() async => (await _ss.read(key: _pinKey)) != null;
  static Future<void> setPin(String pin) async => _ss.write(key: _pinKey, value: _h(pin));
  static Future<bool> verify(String pin) async => (await _ss.read(key: _pinKey)) == _h(pin);
  static Future<void> clear() async {
    await _ss.delete(key: _pinKey);
    await _ss.delete(key: _bioKey);
  }

  static Future<bool> bioOn() async => (await _ss.read(key: _bioKey)) == '1';
  static Future<void> setBio(bool v) async => _ss.write(key: _bioKey, value: v ? '1' : '0');

  static Future<bool> bioAvailable() async {
    try {
      return (await _auth.isDeviceSupported()) && (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> bioAuth() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'FINN AI — kirish uchun tasdiqlang',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}
